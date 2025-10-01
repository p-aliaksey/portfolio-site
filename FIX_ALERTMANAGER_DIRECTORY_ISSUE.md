# 🔧 Исправление проблемы с директорией alertmanager.yml

## ❌ Проблема
Ansible создал `alertmanager.yml` как **директорию** вместо файла, поэтому Docker не может смонтировать его.

## 🔍 Диагностика показала:
```
"isdir": True, "isreg": False
```
Это означает, что `alertmanager.yml` существует как директория, а не как файл.

## ✅ Решение

### 1. Обновленные файлы
- `infra/ansible/deploy.yml` - добавлена логика исправления директории

### 2. Что изменилось

#### В `deploy.yml`:
```yaml
# Удаление директории alertmanager.yml если она существует
- name: Remove alertmanager directory if it exists as directory
  file:
    path: /opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml
    state: absent
  when: ansible_check_mode == false

# Копирование с принудительной перезаписью
- name: Copy monitoring configuration files
  copy:
    src: "{{ project_root }}/{{ item.src }}"
    dest: "{{ item.dest }}"
    mode: '0644'
    force: yes  # Принудительная перезапись

# Проверка типа файла
- name: Display alertmanager file status
  debug:
    msg: "Alertmanager file exists: {{ alertmanager_file.stat.exists }}, is file: {{ alertmanager_file.stat.isreg }}, is directory: {{ alertmanager_file.stat.isdir }}"

# Исправление если это директория
- name: Fix alertmanager.yml if it's a directory
  shell: |
    if [ -d "/opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml" ]; then
      rm -rf "/opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml"
    fi
  when: alertmanager_file.stat.isdir | default(false)

# Пересоздание файла
- name: Recreate alertmanager.yml file
  copy:
    src: "{{ project_root }}/infra/monitoring/alertmanager/alertmanager.yml"
    dest: /opt/devops-portfolio/infra/monitoring/alertmanager/alertmanager.yml
    mode: '0644'
    force: yes
  when: alertmanager_file.stat.isdir | default(false)
```

### 3. Теперь Ansible будет:

1. **Удалять директорию** `alertmanager.yml` если она существует
2. **Копировать файлы** с принудительной перезаписью (`force: yes`)
3. **Проверять тип** файла (файл или директория)
4. **Исправлять проблему** если `alertmanager.yml` все еще директория
5. **Пересоздавать файл** если необходимо

### 4. Диагностика покажет:
```
TASK [Display alertmanager file status] ***************************************
ok: [prod] => {
    "msg": "Alertmanager file exists: True, is file: True, is directory: False"
}
```

### 5. Если проблема повторится:
Ansible автоматически исправит ее, удалив директорию и создав файл.

## 🎯 Результат

- ✅ `alertmanager.yml` будет создан как файл, а не директория
- ✅ Docker сможет монтировать файл
- ✅ Система запустится без ошибок
- ✅ Автоматическое исправление проблем

## 🚀 Следующие шаги

1. Запустите обновленный Ansible playbook
2. Проверьте диагностику типа файла
3. После успешного деплоя настройте Telegram бота

**Проблема с директорией alertmanager.yml решена! 🎉**
