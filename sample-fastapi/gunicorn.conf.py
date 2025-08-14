# Gunicorn configuration file
import multiprocessing

max_requests = 1000
max_requests_jitter = 50

log_file = "-"

bind = "0.0.0.0:80"
timeout = 600
worker_class = "uvicorn.workers.UvicornWorker"
workers = 1