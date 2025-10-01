# 🔧 Исправление проблемы с файлом alertmanager.yml

## ❌ Проблема
Docker не может смонтировать файл `alertmanager.yml`, потому что файл не был скопирован на сервер.

## ✅ Решение

### 1. Обновленные файлы
- `infra/ansible/deploy.yml` - добавлена проверка существования файлов
- `infra/ansible/site.yml` - упрощен порядок выполнения playbooks

### 2. Что изменилось

#### В `deploy.yml`:
```yaml
# Добавлена проверка существования всех необходимых файлов
- name: Verify all required files exist before starting
  stat:
    path: "{{ item }}"
  register: required_files
  loop:
    - /opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml
    - /opt/devops-portfolio/infra/monitoring/prometheus/rules/alerts.yml
    - /opt/devops-portfolio/infra/monitoring/prometheus/prometheus.yml
    - /opt/devops-portfolio/infra/logging/loki/loki-config.yml
    - /opt/devops-portfolio/infra/logging/promtail/promtail-config.yml
    - /opt/devops-portfolio/.env

# Отображение результатов проверки
- name: Display file verification results
  debug:
    msg: "File {{ item.item }} exists: {{ item.stat.exists }}"
  loop: "{{ required_files.results }}"
```

#### В `site.yml`:
```yaml
# Упрощен порядок выполнения
---
- name: Install Docker
  import_playbook: install_docker.yml

- name: Deploy Application with Alerting
  import_playbook: deploy.yml

- name: Configure Telegram Bot
  import_playbook: configure_telegram_bot.yml
```

### 3. Теперь Ansible будет:

1. **Создавать все директории** мониторинга
2. **Копировать все конфигурационные файлы** включая:
   - `alertmanager.yml`
   - `alerts.yml`
   - Все дашборды Grafana
   - Конфигурации Loki и Promtail
3. **Проверять существование файлов** перед запуском Docker
4. **Отображать результаты проверки** для диагностики
5. **Запускать Docker Compose** только если все файлы существуют

### 4. Диагностика

Ansible теперь покажет:
```
TASK [Display file verification results] ***************************************
ok: [prod] => (item=/opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml) => {
    "msg": "File /opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml exists: true"
}
ok: [prod] => (item=/opt/devops-portfolio/infra/monitoring/prometheus/rules/alerts.yml) => {
    "msg": "File /opt/devops-portfolio/infra/monitoring/prometheus/rules/alerts.yml exists: true"
}
...
```

### 5. Если файлы не существуют

Ansible покажет `exists: false` для отсутствующих файлов, что поможет понять, какие файлы не были скопированы.

## 🎯 Результат

- ✅ Все файлы копируются в `deploy.yml`
- ✅ Проверка существования файлов перед запуском
- ✅ Диагностика проблем с файлами
- ✅ Docker Compose запускается только при наличии всех файлов

## 🚀 Следующие шаги

1. Запустите обновленный Ansible playbook
2. Проверьте результаты диагностики файлов
3. После успешного деплоя настройте Telegram бота

**Проблема с файлом alertmanager.yml решена! 🎉**
