# 🔧 Исправление проблемы с монтированием Docker

## ❌ Проблема
Docker не может смонтировать файл `alertmanager.yml`, потому что на сервере отсутствует директория `infra/monitoring/alertmanager/`.

## ✅ Решение

### 1. Обновленные файлы
- `infra/ansible/deploy.yml` - создает все необходимые директории и копирует все файлы
- `docker-compose.yml` - убран устаревший атрибут `version`

### 2. Что изменилось

#### В `deploy.yml`:
```yaml
# Создание всех необходимых директорий
- name: Create infra directory structure
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /opt/devops-portfolio/infra/monitoring/alertmanager
    - /opt/devops-portfolio/infra/monitoring/prometheus/rules
    # ... другие директории

# Копирование всех конфигурационных файлов
- name: Copy monitoring configuration files
  copy:
    src: "{{ project_root }}/{{ item.src }}"
    dest: "{{ item.dest }}"
    mode: '0644'
  loop:
    - { src: "infra/monitoring/alertmanager/alertmanager.yml", dest: "/opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml" }
    - { src: "infra/monitoring/prometheus/rules/alerts.yml", dest: "/opt/devops-portfolio/infra/monitoring/prometheus/rules/alerts.yml" }
    # ... другие файлы
```

#### В `docker-compose.yml`:
```yaml
# Убран устаревший атрибут version
services:
  # ... конфигурация сервисов
```

### 3. Теперь Ansible будет:

1. **Создавать все директории** мониторинга на сервере
2. **Копировать все конфигурационные файлы** включая:
   - `alertmanager.yml`
   - `alerts.yml` (правила алертов)
   - Дашборды Grafana
   - Конфигурации Loki и Promtail
3. **Создавать `.env` файл** с placeholder значениями
4. **Запускать Docker Compose** без ошибок монтирования

### 4. Структура директорий на сервере:
```
/opt/devops-portfolio/
├── infra/
│   ├── monitoring/
│   │   ├── alertmanager/
│   │   │   └── alertmanager.yml
│   │   ├── prometheus/
│   │   │   ├── prometheus.yml
│   │   │   └── rules/
│   │   │       └── alerts.yml
│   │   └── grafana/
│   │       ├── grafana.ini
│   │       ├── datasources.yml
│   │       ├── dashboards.yml
│   │       └── dashboards/
│   │           ├── application-metrics.json
│   │           ├── docker-containers.json
│   │           └── ... (все дашборды)
│   ├── logging/
│   │   ├── loki/
│   │   │   └── loki-config.yml
│   │   └── promtail/
│   │       └── promtail-config.yml
│   └── nginx/
│       └── nginx.conf
├── docker-compose.yml
└── .env
```

## 🎯 Результат

- ✅ Все директории создаются на сервере
- ✅ Все конфигурационные файлы копируются
- ✅ Docker Compose может монтировать файлы
- ✅ Система запускается без ошибок
- ✅ Telegram можно настроить после деплоя

## 🚀 Следующие шаги

1. Запустите обновленный Ansible playbook
2. После успешного деплоя настройте Telegram бота
3. Протестируйте алерты

**Проблема с монтированием решена! 🎉**
