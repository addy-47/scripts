FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir docker requests

COPY watchdog.py /app/watchdog.py

ENV PYTHONUNBUFFERED=1

CMD ["python", "/app/watchdog.py"]
