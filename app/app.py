from flask import Flask, render_template, request, redirect, url_for
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from prometheus_client import Gauge
import os
import time


def create_app() -> Flask:
    app = Flask(__name__, template_folder="templates", static_folder="static")

    request_counter = Counter("http_requests_total", "HTTP requests total", ["path"]) 
    app_uptime_seconds = Gauge("app_uptime_seconds", "Application uptime in seconds")
    
    # Дополнительные метрики
    active_connections = Gauge("app_active_connections", "Number of active connections")
    response_time = Gauge("app_response_time_seconds", "Response time in seconds", ["path"])
    
    # Время запуска приложения
    start_time = time.time()

    @app.before_request
    def _before_request():
        app_uptime_seconds.set(time.time() - start_time)
        active_connections.inc()
        request.start_time = time.time()
    
    @app.after_request
    def _after_request(response):
        active_connections.dec()
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
            response_time.labels(path=request.path).set(duration)
        return response

    @app.route("/")
    def index():
        request_counter.labels(path="/").inc()
        return render_template("index.html")

    @app.route("/about")
    def about():
        request_counter.labels(path="/about").inc()
        return render_template("about.html")

    @app.route("/metrics")
    def metrics():
        # Do not increment counter here to keep metrics endpoint clean
        return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

    @app.route("/query")
    def query_redirect():
        # Redirect /query to /prometheus/ for Prometheus UI
        return redirect("/prometheus/", code=302)

    @app.route("/loki")
    def loki():
        request_counter.labels(path="/loki").inc()
        return render_template("loki.html")
    
    @app.route("/monitoring")
    def monitoring():
        request_counter.labels(path="/monitoring").inc()
        return render_template("monitoring.html")
    
    @app.route("/api/system/disk")
    def system_disk():
        import shutil
        disk_usage = shutil.disk_usage('/')
        return {
            "total": disk_usage.total,
            "used": disk_usage.used,
            "free": disk_usage.free,
            "percent_used": round((disk_usage.used / disk_usage.total) * 100, 2)
        }
    
    @app.route("/api/system/docker")
    def system_docker():
        import subprocess
        import json
        try:
            result = subprocess.run(['docker', 'ps', '--format', 'json'], 
                                  capture_output=True, text=True, timeout=10)
            containers = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    try:
                        container = json.loads(line)
                        # Добавляем дополнительную информацию
                        container['status_icon'] = '🟢' if container.get('State') == 'running' else '🔴'
                        container['status_text'] = 'UP' if container.get('State') == 'running' else 'DOWN'
                        containers.append(container)
                    except json.JSONDecodeError:
                        continue
            return {"containers": containers}
        except Exception as e:
            return {"error": str(e), "containers": []}

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
