from flask import Flask, request
import requests
import os
import logging
import time
import threading
from collections import namedtuple
from datetime import datetime, timezone, timedelta
from kubernetes import client, config

app = Flask(__name__)

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO)

# --- GCP Metadata Auto-Discovery ---
def fetch_gcp_metadata():
    headers = {"Metadata-Flavor": "Google"}
    project_id = "N/A"
    cluster_name = "N/A"

    try:
        res = requests.get("http://metadata.google.internal/computeMetadata/v1/project/project-id", headers=headers, timeout=2)
        if res.status_code == 200:
            project_id = res.text.strip()
    except Exception as e:
        logging.info(f"Metadata project-id lookup skipped or non-GCP environment: {e}")

    try:
        # First check for GKE cluster name attribute
        res = requests.get("http://metadata.google.internal/computeMetadata/v1/instance/attributes/cluster-name", headers=headers, timeout=2)
        if res.status_code == 200:
            cluster_name = res.text.strip()
        else:
            # Fallback to instance name
            res2 = requests.get("http://metadata.google.internal/computeMetadata/v1/instance/name", headers=headers, timeout=2)
            if res2.status_code == 200:
                cluster_name = res2.text.strip()
    except Exception as e:
        logging.info(f"Metadata cluster-name lookup skipped or non-GCP environment: {e}")

    return project_id, cluster_name

# --- Configuration ---
GCHAT_WEBHOOK_URL = os.environ.get("GCHAT_WEBHOOK_URL")
AUTO_PROJECT_ID, AUTO_CLUSTER_NAME = fetch_gcp_metadata()
GCP_PROJECT_ID = os.environ.get("GCP_PROJECT_ID", AUTO_PROJECT_ID)
CLUSTER_NAME = os.environ.get("CLUSTER_NAME", AUTO_CLUSTER_NAME)

ALERT_COOLDOWN_SECONDS = int(os.environ.get("ALERT_COOLDOWN_SECONDS", "900"))  # 15 minutes default
IST = timezone(timedelta(hours=5, minutes=30))

def get_ist_timestamp():
    return datetime.now(IST).strftime("%d-%m-%Y %H:%M:%S IST")

# Initialize Kubernetes client
try:
    config.load_incluster_config()
except:
    try:
        config.load_kube_config()
    except:
        logging.warning("Could not load Kubernetes config - pod status checking will be limited")

k8s_v1 = client.CoreV1Api()

# --- In-Memory Cache for De-duplication ---
AlertRecord = namedtuple('AlertRecord', ['timestamp', 'message'])
recent_alerts = {}
cache_lock = threading.Lock()

PROBLEMATIC_WAITING_REASONS = [
    'CrashLoopBackOff', 
    'ImagePullBackOff', 
    'ErrImagePull',
    'CreateContainerConfigError',
    'InvalidImageName',
    'CreateContainerError'
]

PROBLEMATIC_TERMINATED_REASONS = [
    'Error', 
    'OOMKilled',
    'ContainerCannotRun',
    'DeadlineExceeded'
]

PROBLEMATIC_PHASES = ['Failed', 'Unknown']

def is_alert_on_cooldown(alert_key):
    with cache_lock:
        if alert_key in recent_alerts:
            last_alert_time = recent_alerts[alert_key].timestamp
            if time.time() - last_alert_time < ALERT_COOLDOWN_SECONDS:
                logging.info(f"Alert on cooldown for key: {alert_key}")
                return True
        return False

def update_alert_cache(alert_key, message):
    with cache_lock:
        recent_alerts[alert_key] = AlertRecord(timestamp=time.time(), message=message)
        logging.info(f"Updated alert cache for key: {alert_key}")

def get_pod_status_from_k8s(namespace, pod_name):
    try:
        pod = k8s_v1.read_namespaced_pod(name=pod_name, namespace=namespace)
        phase = pod.status.phase
        if phase in PROBLEMATIC_PHASES:
            return (None, phase, phase, f"Pod is in {phase} state")
        
        if pod.status.container_statuses:
            for container in pod.status.container_statuses:
                if container.state.waiting:
                    reason = container.state.waiting.reason
                    message = container.state.waiting.message or ""
                    if reason in PROBLEMATIC_WAITING_REASONS:
                        return (container.name, reason, phase, message)
                
                if container.state.terminated:
                    reason = container.state.terminated.reason
                    message = container.state.terminated.message or ""
                    exit_code = container.state.terminated.exit_code
                    if reason in PROBLEMATIC_TERMINATED_REASONS or exit_code != 0:
                        return (container.name, reason or f"Exit {exit_code}", phase, message)
        
        if pod.status.init_container_statuses:
            for container in pod.status.init_container_statuses:
                if container.state.waiting:
                    reason = container.state.waiting.reason
                    message = container.state.waiting.message or ""
                    if reason in PROBLEMATIC_WAITING_REASONS:
                        return (f"init:{container.name}", reason, phase, message)
                
                if container.state.terminated:
                    reason = container.state.terminated.reason
                    exit_code = container.state.terminated.exit_code
                    if exit_code != 0:
                        return (f"init:{container.name}", reason or f"Exit {exit_code}", phase, "")
        
        return (None, None, None, None)
    
    except client.exceptions.ApiException as e:
        if e.status == 404:
            logging.info(f"Pod {namespace}/{pod_name} not found (may have been deleted)")
            return (None, None, None, None)
        logging.error(f"Error fetching pod status: {e}")
        return (None, None, None, None)
    except Exception as e:
        logging.error(f"Unexpected error fetching pod status: {e}")
        return (None, None, None, None)

@app.route('/webhook', methods=['POST'])
def adapter():
    if not GCHAT_WEBHOOK_URL:
        logging.error("GCHAT_WEBHOOK_URL is not configured.")
        return "Adapter misconfigured", 500

    try:
        kubewatch_payload = request.get_json()
        event_meta = kubewatch_payload.get('eventmeta', {})
        kind = event_meta.get('kind', '').lower()
        pod_name = event_meta.get('name', 'N/A')
        namespace = event_meta.get('namespace', 'N/A')

        if kind != 'pod':
            return "OK", 200

        container_name, problem_reason, phase, error_message = get_pod_status_from_k8s(namespace, pod_name)

        if not problem_reason:
            return "OK", 200

        alert_key = f"{namespace}/{pod_name}/{container_name or 'pod'}/{problem_reason}"

        if is_alert_on_cooldown(alert_key):
            return "OK (on cooldown)", 200

        severity_emoji = "🚨"
        if problem_reason in ['OOMKilled', 'Error', 'Failed']:
            severity_emoji = "🔴"
        elif problem_reason in ['CrashLoopBackOff']:
            severity_emoji = "⚠️"

        timestamp_ist = get_ist_timestamp()

        formatted_message = f"{severity_emoji} *KubeWatch Alert* {severity_emoji}\n\n"
        formatted_message += f"*Time:* `{timestamp_ist}`\n"
        if GCP_PROJECT_ID != "N/A":
            formatted_message += f"*Project:* `{GCP_PROJECT_ID}`\n"
        if CLUSTER_NAME != "N/A":
            formatted_message += f"*Cluster:* `{CLUSTER_NAME}`\n"
        formatted_message += f"*Pod:* `{pod_name}`\n"
        formatted_message += f"*Namespace:* `{namespace}`\n"
        
        if container_name:
            formatted_message += f"*Container:* `{container_name}`\n"
        
        formatted_message += f"*Status:* `{problem_reason}`\n"
        formatted_message += f"*Phase:* `{phase}`\n"
        
        if error_message:
            display_message = error_message[:200] + "..." if len(error_message) > 200 else error_message
            formatted_message += f"*Message:* ```{display_message}```"

        gchat_payload = {"text": formatted_message}
        response = requests.post(GCHAT_WEBHOOK_URL, json=gchat_payload, timeout=10)
        response.raise_for_status()

        update_alert_cache(alert_key, formatted_message)
        logging.info(f"Alert sent to Google Chat successfully for {pod_name}.")
        return "OK", 200

    except Exception as e:
        logging.error(f"Error processing webhook: {e}", exc_info=True)
        return "Error", 500

@app.route('/health', methods=['GET'])
def health():
    return {"status": "healthy", "cooldown_seconds": ALERT_COOLDOWN_SECONDS}, 200

def cleanup_cache():
    while True:
        time.sleep(ALERT_COOLDOWN_SECONDS)
        with cache_lock:
            cutoff_time = time.time() - ALERT_COOLDOWN_SECONDS
            stale_keys = [
                key for key, record in recent_alerts.items()
                if record.timestamp < cutoff_time
            ]
            for key in stale_keys:
                del recent_alerts[key]

if __name__ == '__main__':
    cleanup_thread = threading.Thread(target=cleanup_cache, daemon=True)
    cleanup_thread.start()
    app.run(host='0.0.0.0', port=8080)
else:
    cleanup_thread = threading.Thread(target=cleanup_cache, daemon=True)
    cleanup_thread.start()