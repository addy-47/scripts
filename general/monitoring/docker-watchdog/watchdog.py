#!/usr/bin/env python3
import os
import sys
import time
import json
import logging
import threading
import requests
import docker
from datetime import datetime, timezone, timedelta

# --- Logging Setup ---
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)

# --- GCP Metadata Server Auto-Discovery ---
def fetch_gcp_metadata():
    headers = {"Metadata-Flavor": "Google"}
    project_id = "N/A"
    vm_name = os.uname().nodename

    try:
        res = requests.get("http://metadata.google.internal/computeMetadata/v1/project/project-id", headers=headers, timeout=2)
        if res.status_code == 200:
            project_id = res.text.strip()
    except Exception as e:
        logging.info(f"Metadata project-id lookup skipped or non-GCP environment: {e}")

    try:
        res = requests.get("http://metadata.google.internal/computeMetadata/v1/instance/name", headers=headers, timeout=2)
        if res.status_code == 200:
            vm_name = res.text.strip()
    except Exception as e:
        logging.info(f"Metadata instance/name lookup skipped or non-GCP environment: {e}")

    return project_id, vm_name

# --- Configuration ---
GCHAT_WEBHOOK_URL = os.environ.get("GCHAT_WEBHOOK_URL")
AUTO_PROJECT_ID, AUTO_VM_NAME = fetch_gcp_metadata()
GCP_PROJECT_ID = os.environ.get("GCP_PROJECT_ID", AUTO_PROJECT_ID)
VM_NAME = os.environ.get("VM_NAME", AUTO_VM_NAME)

ALERT_COOLDOWN_SECONDS = int(os.environ.get("ALERT_COOLDOWN_SECONDS", "900"))  # 15 minutes default
MAX_LOG_LINES = int(os.environ.get("MAX_LOG_LINES", "15"))
IST = timezone(timedelta(hours=5, minutes=30))

if not GCHAT_WEBHOOK_URL:
    logging.error("CRITICAL: GCHAT_WEBHOOK_URL environment variable is not set!")
    sys.exit(1)

# --- In-Memory Cooldown Cache ---
recent_alerts = {}
cache_lock = threading.Lock()

def get_ist_timestamp():
    return datetime.now(IST).strftime("%d-%m-%Y %H:%M:%S IST")

def is_on_cooldown(alert_key):
    with cache_lock:
        if alert_key in recent_alerts:
            last_time = recent_alerts[alert_key]
            if time.time() - last_time < ALERT_COOLDOWN_SECONDS:
                logging.info(f"Alert on cooldown for key: {alert_key}")
                return True
        return False

def update_cooldown(alert_key):
    with cache_lock:
        recent_alerts[alert_key] = time.time()

def send_gchat_alert(container_name, image, event_type, exit_code, logs):
    alert_key = f"{VM_NAME}/{container_name}/{event_type}"
    if is_on_cooldown(alert_key):
        return

    severity_emoji = "🚨" if event_type in ["die", "oom"] else "⚠️"
    timestamp_ist = get_ist_timestamp()
    
    formatted_message = f"{severity_emoji} *Docker Watchdog Alert* {severity_emoji}\n\n"
    formatted_message += f"*Time:* `{timestamp_ist}`\n"
    if GCP_PROJECT_ID != "N/A":
        formatted_message += f"*Project:* `{GCP_PROJECT_ID}`\n"
    formatted_message += f"*VM:* `{VM_NAME}`\n"
    formatted_message += f"*Container:* `{container_name}`\n"
    formatted_message += f"*Image:* `{image}`\n"
    formatted_message += f"*Event:* `{event_type}`\n"
    
    if exit_code is not None:
        formatted_message += f"*Exit Code:* `{exit_code}`\n"
        
    if logs:
        display_logs = logs[:800] + "..." if len(logs) > 800 else logs
        formatted_message += f"\n*Recent Logs (Last {MAX_LOG_LINES} lines):*\n```{display_logs}```"

    try:
        res = requests.post(GCHAT_WEBHOOK_URL, json={"text": formatted_message}, timeout=10)
        res.raise_for_status()
        update_cooldown(alert_key)
        logging.info(f"Alert sent to Google Chat for container {container_name}")
    except Exception as e:
        logging.error(f"Failed to send alert to Google Chat: {e}")

def get_container_logs(client, container_id):
    try:
        container = client.containers.get(container_id)
        raw_logs = container.logs(tail=MAX_LOG_LINES, stdout=True, stderr=True)
        return raw_logs.decode('utf-8', errors='replace').strip()
    except Exception as e:
        logging.warning(f"Could not fetch logs for container {container_id}: {e}")
        return ""

def main():
    logging.info(f"Starting Docker Watchdog on host '{VM_NAME}' (Auto-detected Project: {GCP_PROJECT_ID})...")
    try:
        client = docker.from_env()
        client.ping()
        logging.info("Successfully connected to Docker daemon.")
    except Exception as e:
        logging.error(f"Failed to connect to Docker daemon via socket: {e}")
        sys.exit(1)

    for event in client.events(decode=True):
        try:
            if event.get("Type") != "container":
                continue

            action = event.get("Action", "")
            actor = event.get("Actor", {})
            attributes = actor.get("Attributes", {})
            container_name = attributes.get("name", actor.get("ID", "N/A")[:12])
            image = attributes.get("image", "unknown")
            container_id = actor.get("ID")

            if "docker-watchdog" in container_name or "watchdog" in container_name:
                continue

            if action == "die":
                exit_code = attributes.get("exitCode", "unknown")
                if str(exit_code) == "0":
                    continue

                logging.info(f"Container die event detected: {container_name} (Exit code {exit_code})")
                logs = get_container_logs(client, container_id)
                send_gchat_alert(container_name, image, f"die (Exit Code {exit_code})", exit_code, logs)

            elif action == "oom":
                logging.info(f"Container OOM event detected: {container_name}")
                logs = get_container_logs(client, container_id)
                send_gchat_alert(container_name, image, "OOMKilled", 137, logs)

            elif "health_status: unhealthy" in action:
                logging.info(f"Container unhealthy event detected: {container_name}")
                logs = get_container_logs(client, container_id)
                send_gchat_alert(container_name, image, "Unhealthy Healthcheck", None, logs)

        except Exception as e:
            logging.error(f"Error handling Docker event: {e}")

if __name__ == "__main__":
    main()
