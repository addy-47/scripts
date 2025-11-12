from flask import Flask, request
import requests
import os
import logging
import time
import threading
from collections import namedtuple
from kubernetes import client, config

app = Flask(__name__)

# --- Configuration ---
logging.basicConfig(level=logging.INFO)
GCHAT_WEBHOOK_URL = os.environ.get("GCHAT_WEBHOOK_URL")
# Cooldown period in seconds before sending a repeat alert for the same issue
ALERT_COOLDOWN_SECONDS = int(os.environ.get("ALERT_COOLDOWN_SECONDS", "900"))  # 15 minutes default

# Initialize Kubernetes client (for fetching pod details)
try:
    config.load_incluster_config()  # Use when running inside cluster
except:
    try:
        config.load_kube_config()  # Use when running locally
    except:
        logging.warning("Could not load Kubernetes config - pod status checking will be limited")

k8s_v1 = client.CoreV1Api()

# --- In-Memory Cache for De-duplication ---
AlertRecord = namedtuple('AlertRecord', ['timestamp', 'message'])
recent_alerts = {}
cache_lock = threading.Lock()

# --- Problematic States to Alert On ---
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

# Pod phases that indicate problems
PROBLEMATIC_PHASES = ['Failed', 'Unknown']

# --- Helper Functions ---

def is_alert_on_cooldown(alert_key):
    """Checks if an alert for the given key is on cooldown."""
    with cache_lock:
        if alert_key in recent_alerts:
            last_alert_time = recent_alerts[alert_key].timestamp
            if time.time() - last_alert_time < ALERT_COOLDOWN_SECONDS:
                logging.info(f"Alert on cooldown for key: {alert_key}")
                return True
        return False

def update_alert_cache(alert_key, message):
    """Updates the cache with the current timestamp and message for the given alert key."""
    with cache_lock:
        recent_alerts[alert_key] = AlertRecord(timestamp=time.time(), message=message)
        logging.info(f"Updated alert cache for key: {alert_key}")

def get_pod_status_from_k8s(namespace, pod_name):
    """
    Fetches the actual pod status from Kubernetes API.
    Returns (container_name, reason, phase, message) if problematic, else (None, None, None, None)
    """
    try:
        pod = k8s_v1.read_namespaced_pod(name=pod_name, namespace=namespace)
        
        # Check pod phase first
        phase = pod.status.phase
        if phase in PROBLEMATIC_PHASES:
            return (None, phase, phase, f"Pod is in {phase} state")
        
        # Check container statuses
        if pod.status.container_statuses:
            for container in pod.status.container_statuses:
                # Check waiting state
                if container.state.waiting:
                    reason = container.state.waiting.reason
                    message = container.state.waiting.message or ""
                    if reason in PROBLEMATIC_WAITING_REASONS:
                        return (container.name, reason, phase, message)
                
                # Check terminated state
                if container.state.terminated:
                    reason = container.state.terminated.reason
                    message = container.state.terminated.message or ""
                    exit_code = container.state.terminated.exit_code
                    if reason in PROBLEMATIC_TERMINATED_REASONS or exit_code != 0:
                        return (container.name, reason or f"Exit {exit_code}", phase, message)
        
        # Check init container statuses
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

def should_alert_on_kubewatch_event(event_reason):
    """
    Determines if we should investigate a kubewatch event based on its reason.
    Returns True for events that might indicate problems.
    """
    # Alert on all pod updates - we'll check the actual status
    # Don't alert on normal creation unless there's a problem
    return event_reason.lower() in ['updated', 'deleted', 'backoff']

# --- Main Application Logic ---

@app.route('/webhook', methods=['POST'])
def adapter():
    if not GCHAT_WEBHOOK_URL:
        logging.error("GCHAT_WEBHOOK_URL is not configured.")
        return "Adapter misconfigured", 500

    try:
        kubewatch_payload = request.get_json()
        event_meta = kubewatch_payload.get('eventmeta', {})
        kind = event_meta.get('kind', '').lower()
        reason = event_meta.get('reason', '').lower()
        pod_name = event_meta.get('name', 'N/A')
        namespace = event_meta.get('namespace', 'N/A')

        # Only process pod events
        if kind != 'pod':
            logging.debug(f"Ignoring event for kind: {kind}")
            return "OK", 200

        # Skip certain events unless they indicate potential problems
        if not should_alert_on_kubewatch_event(reason):
            logging.debug(f"Skipping event with reason: {reason}")
            return "OK", 200

        # Fetch actual pod status from Kubernetes API
        container_name, problem_reason, phase, error_message = get_pod_status_from_k8s(namespace, pod_name)

        if not problem_reason:
            logging.info(f"No problematic status found for pod {namespace}/{pod_name}")
            return "OK", 200

        # --- De-duplication Check ---
        alert_key = f"{namespace}/{pod_name}/{container_name or 'pod'}/{problem_reason}"

        if is_alert_on_cooldown(alert_key):
            return "OK (on cooldown)", 200

        # --- Build Alert Message ---
        logging.info(f"New alert condition detected: {alert_key}")

        # Determine severity emoji
        severity_emoji = "🚨"
        if problem_reason in ['OOMKilled', 'Error', 'Failed']:
            severity_emoji = "🔴"
        elif problem_reason in ['CrashLoopBackOff']:
            severity_emoji = "⚠️"

        formatted_message = f"{severity_emoji} *KubeWatch Alert* {severity_emoji}\n\n"
        formatted_message += f"*Pod:* `{pod_name}`\n"
        formatted_message += f"*Namespace:* `{namespace}`\n"
        
        if container_name:
            formatted_message += f"*Container:* `{container_name}`\n"
        
        formatted_message += f"*Status:* `{problem_reason}`\n"
        formatted_message += f"*Phase:* `{phase}`\n"
        
        if error_message:
            # Truncate long error messages
            display_message = error_message[:200] + "..." if len(error_message) > 200 else error_message
            formatted_message += f"*Message:* ```{display_message}```"

        gchat_payload = {"text": formatted_message}
        response = requests.post(GCHAT_WEBHOOK_URL, json=gchat_payload, timeout=10)
        response.raise_for_status()

        # Update cache only after successful sending
        update_alert_cache(alert_key, formatted_message)
        logging.info("Alert sent to Google Chat successfully.")
        return "OK", 200

    except requests.exceptions.RequestException as e:
        logging.error(f"Error sending to Google Chat: {e}")
        return "Error sending notification", 500
    except Exception as e:
        logging.error(f"Error processing webhook: {e}", exc_info=True)
        return "Error", 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return {"status": "healthy", "cooldown_seconds": ALERT_COOLDOWN_SECONDS}, 200

# --- Background Task for Cache Cleanup ---

def cleanup_cache():
    """Periodically cleans up stale entries from the alert cache."""
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
            if stale_keys:
                logging.info(f"Cache cleanup: Removed {len(stale_keys)} stale alert(s).")

# --- Server Initialization ---

if __name__ == '__main__':
    # Start the cache cleanup thread
    cleanup_thread = threading.Thread(target=cleanup_cache, daemon=True)
    cleanup_thread.start()
    # Start the Flask app
    app.run(host='0.0.0.0', port=8080)
else:
    # If running with Gunicorn, start the cleanup thread here
    if not any([app.debug, os.environ.get("WERKZEUG_RUN_MAIN") == "true"]):
        cleanup_thread = threading.Thread(target=cleanup_cache, daemon=True)
        cleanup_thread.start()