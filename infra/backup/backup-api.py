#!/usr/bin/env python3
"""
Простой HTTP API для создания бэкапов на хосте
Запуск: python3 /opt/devops-portfolio/infra/backup/backup-api.py
"""

from flask import Flask, request, jsonify
import subprocess
import os
import glob
from datetime import datetime
import json

app = Flask(__name__)

@app.route('/api/backup/create', methods=['POST'])
def create_backup():
    """Создает бэкап через скрипт backup.sh"""
    try:
        backup_script = "/opt/devops-portfolio/infra/backup/backup.sh"
        
        if not os.path.exists(backup_script):
            return jsonify({
                "success": False,
                "message": "Скрипт бэкапа не найден",
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }), 404
        
        # Запускаем скрипт бэкапа
        result = subprocess.run(
            [backup_script],
            capture_output=True,
            text=True,
            timeout=300,  # 5 минут таймаут
            cwd=os.path.dirname(backup_script)
        )
        
        if result.returncode == 0:
            return jsonify({
                "success": True,
                "message": "Резервная копия создана успешно",
                "output": result.stdout,
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            })
        else:
            return jsonify({
                "success": False,
                "message": "Ошибка при создании резервной копии",
                "error": result.stderr,
                "output": result.stdout,
                "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }), 500
            
    except subprocess.TimeoutExpired:
        return jsonify({
            "success": False,
            "message": "Таймаут при создании резервной копии (более 5 минут)",
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }), 500
    except Exception as e:
        return jsonify({
            "success": False,
            "message": f"Ошибка при создании резервной копии: {str(e)}",
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }), 500

@app.route('/api/backup/stats', methods=['GET'])
def backup_stats():
    """Возвращает статистику бэкапов"""
    try:
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
        
        return jsonify(backup_stats)
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "total_backups": 0,
            "total_size": "0 MB",
            "last_backup": None,
            "oldest_backup": None,
            "backups": [],
            "cron_status": "Error",
            "backup_health": "Error"
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001, debug=False)
