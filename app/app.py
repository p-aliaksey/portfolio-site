from flask import Flask, render_template, request, redirect, url_for
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from prometheus_client import Gauge
import os


def create_app() -> Flask:
    app = Flask(__name__, template_folder="templates", static_folder="static")

    request_counter = Counter("http_requests_total", "HTTP requests total", ["path"]) 
    app_uptime_seconds = Gauge("app_uptime_seconds", "Application uptime in seconds")

    @app.before_request
    def _before_request():
        app_uptime_seconds.set(max(0, os.times().elapsed))

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

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
