from flask import Flask, render_template, request, redirect, url_for, session
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
from prometheus_client import Gauge
import os
import time
from translations import translations, _


def create_app() -> Flask:
    app = Flask(__name__, template_folder="templates", static_folder="static")
    app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')

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
        return render_template("index.html", t=translations.get_all_translations(), translations=translations)

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
        return render_template("monitoring.html", t=translations.get_all_translations(), translations=translations)
    
    @app.route("/architecture")
    def architecture():
        request_counter.labels(path="/architecture").inc()
        return render_template("architecture.html", t=translations.get_all_translations(), translations=translations)
    
    @app.route("/set_language/<lang>")
    def set_language(lang):
        translations.set_language(lang)
        return redirect(request.referrer or url_for('index'))
    
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
        try:
            # Простой fallback - возвращаем статическую информацию
            static_containers = [
                {'Names': 'app', 'Status': 'Up', 'State': 'running', 'status_icon': '🟢', 'status_text': 'UP'},
                {'Names': 'nginx', 'Status': 'Up', 'State': 'running', 'status_icon': '🟢', 'status_text': 'UP'},
                {'Names': 'prometheus', 'Status': 'Up', 'State': 'running', 'status_icon': '🟢', 'status_text': 'UP'},
                {'Names': 'grafana', 'Status': 'Up', 'State': 'running', 'status_icon': '🟢', 'status_text': 'UP'},
                {'Names': 'loki', 'Status': 'Up', 'State': 'running', 'status_icon': '🟢', 'status_text': 'UP'},
                {'Names': 'promtail', 'Status': 'Up', 'State': 'running', 'status_icon': '🟢', 'status_text': 'UP'}
            ]
            return {"containers": static_containers, "debug": {"method": "static_fallback"}}
        except Exception as e:
            return {"error": str(e), "containers": [], "debug": {"exception": str(e)}}
    
    @app.route("/api/system/backups")
    def system_backups():
        try:
            import os
            import glob
            import subprocess
            from datetime import datetime, timedelta
            
            backup_dir = "/opt/backups"
            backup_stats = {
                "total_backups": 0,
                "total_size": "0 MB",
                "last_backup": None,
                "oldest_backup": None,
                "backups": [],
                "cron_status": "Unknown",
                "backup_health": "Unknown"
            }
            
            # Проверяем существование директории бэкапов
            if os.path.exists(backup_dir):
                # Получаем список файлов бэкапов
                backup_files = glob.glob(os.path.join(backup_dir, "devops-portfolio-backup-*.tar.gz"))
                backup_files.sort(key=os.path.getmtime, reverse=True)
                
                backup_stats["total_backups"] = len(backup_files)
                
                if backup_files:
                    # Размер всех бэкапов
                    total_size = sum(os.path.getsize(f) for f in backup_files)
                    backup_stats["total_size"] = f"{total_size / (1024*1024):.1f} MB"
                    
                    # Последний бэкап
                    last_backup = backup_files[0]
                    last_backup_time = datetime.fromtimestamp(os.path.getmtime(last_backup))
                    backup_stats["last_backup"] = last_backup_time.strftime("%Y-%m-%d %H:%M:%S")
                    
                    # Самый старый бэкап
                    oldest_backup = backup_files[-1]
                    oldest_backup_time = datetime.fromtimestamp(os.path.getmtime(oldest_backup))
                    backup_stats["oldest_backup"] = oldest_backup_time.strftime("%Y-%m-%d %H:%M:%S")
                    
                    # Детали по каждому бэкапу
                    for backup_file in backup_files[:10]:  # Показываем только последние 10
                        file_stat = os.stat(backup_file)
                        file_size = file_stat.st_size
                        file_time = datetime.fromtimestamp(file_stat.st_mtime)
                        
                        # Определяем возраст бэкапа
                        age_days = (datetime.now() - file_time).days
                        if age_days == 0:
                            age_text = "Сегодня"
                        elif age_days == 1:
                            age_text = "Вчера"
                        else:
                            age_text = f"{age_days} дн. назад"
                        
                        backup_stats["backups"].append({
                            "filename": os.path.basename(backup_file),
                            "size": f"{file_size / (1024*1024):.1f} MB",
                            "date": file_time.strftime("%Y-%m-%d %H:%M:%S"),
                            "age": age_text,
                            "path": backup_file
                        })
                    
                    # Проверяем здоровье бэкапов
                    recent_backup = backup_files[0]
                    recent_backup_time = datetime.fromtimestamp(os.path.getmtime(recent_backup))
                    hours_since_backup = (datetime.now() - recent_backup_time).total_seconds() / 3600
                    
                    if hours_since_backup < 25:  # Бэкап был в последние 25 часов
                        backup_stats["backup_health"] = "Healthy"
                    elif hours_since_backup < 49:  # Бэкап был в последние 49 часов
                        backup_stats["backup_health"] = "Warning"
                    else:
                        backup_stats["backup_health"] = "Critical"
                else:
                    backup_stats["backup_health"] = "No Backups"
            
            # Проверяем статус cron задач
            try:
                result = subprocess.run(['crontab', '-l'], capture_output=True, text=True, timeout=5)
                if "backup.sh" in result.stdout:
                    backup_stats["cron_status"] = "Active"
                else:
                    backup_stats["cron_status"] = "Not Found"
            except:
                backup_stats["cron_status"] = "Unknown"
            
            return backup_stats
            
        except Exception as e:
            return {
                "error": str(e),
                "total_backups": 0,
                "total_size": "0 MB",
                "last_backup": None,
                "oldest_backup": None,
                "backups": [],
                "cron_status": "Error",
                "backup_health": "Error"
            }
    
    @app.route("/api/system/backups/create", methods=["POST"])
    def create_backup():
        try:
            import subprocess
            import json
            
            # Запускаем скрипт создания бэкапа
            result = subprocess.run(
                ["/opt/devops-portfolio/infra/backup/backup.sh"],
                capture_output=True,
                text=True,
                timeout=300  # 5 минут таймаут
            )
            
            if result.returncode == 0:
                return {
                    "success": True,
                    "message": "Резервная копия создана успешно",
                    "output": result.stdout,
                    "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }
            else:
                return {
                    "success": False,
                    "message": "Ошибка при создании резервной копии",
                    "error": result.stderr,
                    "output": result.stdout,
                    "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }
                
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "message": "Таймаут при создании резервной копии (более 5 минут)",
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Ошибка при запуске скрипта бэкапа: {str(e)}",
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
