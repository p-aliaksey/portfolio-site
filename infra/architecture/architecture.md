# 🏗️ Архитектура DevOps Portfolio

## Схема инфраструктуры

```mermaid
graph TB
    subgraph "Пользователь"
        U[👤 Пользователь]
    end
    
    subgraph "Yandex Cloud"
        subgraph "VM Instance"
            subgraph "Docker Network"
                subgraph "Web Layer"
                    N[🌐 Nginx<br/>Port 80<br/>Reverse Proxy]
                end
                
                subgraph "Application Layer"
                    A[🚀 Flask App<br/>Port 8000<br/>Portfolio Site]
                end
                
                subgraph "Monitoring Layer"
                    P[📊 Prometheus<br/>Port 9090<br/>Metrics Collection]
                    G[📈 Grafana<br/>Port 3001<br/>Dashboards]
                end
                
                subgraph "Logging Layer"
                    L[📝 Loki<br/>Port 3100<br/>Log Aggregation]
                    PT[📋 Promtail<br/>Log Collection]
                end
            end
        end
        
        subgraph "Storage"
            GD[(💾 Grafana Data<br/>SQLite)]
            LD[(💾 Loki Data<br/>Filesystem)]
        end
    end
    
    subgraph "External Services"
        GH[🐙 GitHub<br/>CI/CD]
        GHCR[📦 GHCR<br/>Container Registry]
    end
    
    %% User connections
    U -->|HTTP/HTTPS| N
    
    %% Nginx routing
    N -->|/| A
    N -->|/prometheus/| P
    N -->|/grafana/| G
    N -->|/loki/| L
    
    %% Monitoring connections
    P -->|Scrape| A
    P -->|Scrape| P
    G -->|Query| P
    G -->|Query| L
    
    %% Logging connections
    PT -->|Collect| A
    PT -->|Collect| N
    PT -->|Collect| P
    PT -->|Collect| G
    PT -->|Collect| L
    PT -->|Send| L
    
    %% Data storage
    G --> GD
    L --> LD
    
    %% CI/CD
    GH -->|Deploy| A
    GHCR -->|Pull| A
    
    %% Styling
    classDef userClass fill:#e1f5fe
    classDef webClass fill:#f3e5f5
    classDef appClass fill:#e8f5e8
    classDef monitorClass fill:#fff3e0
    classDef logClass fill:#fce4ec
    classDef storageClass fill:#f1f8e9
    classDef externalClass fill:#e0f2f1
    
    class U userClass
    class N webClass
    class A appClass
    class P,G monitorClass
    class L,PT logClass
    class GD,LD storageClass
    class GH,GHCR externalClass
```

## Компоненты системы

### 🌐 **Web Layer**
- **Nginx**: Reverse proxy, маршрутизация запросов
- **Порты**: 80 (HTTP), 443 (HTTPS)

### 🚀 **Application Layer**
- **Flask App**: Основное приложение портфолио
- **Порты**: 8000
- **Функции**: Веб-интерфейс, API, метрики

### 📊 **Monitoring Layer**
- **Prometheus**: Сбор метрик
- **Grafana**: Визуализация и дашборды
- **Порты**: 9090 (Prometheus), 3001 (Grafana)

### 📝 **Logging Layer**
- **Loki**: Агрегация логов
- **Promtail**: Сбор логов с контейнеров
- **Порты**: 3100 (Loki)

### 🔄 **CI/CD Pipeline**
- **GitHub Actions**: Автоматическое развертывание
- **GHCR**: Реестр контейнеров
- **Ansible**: Конфигурационное управление
- **Terraform**: Инфраструктура как код

## Потоки данных

1. **Пользовательский трафик**: Nginx → Flask App
2. **Метрики**: Все сервисы → Prometheus → Grafana
3. **Логи**: Все контейнеры → Promtail → Loki → Grafana
4. **Развертывание**: GitHub → Ansible → Docker → Сервисы

## Безопасность

- **Firewall**: Настроен через Yandex Cloud Security Groups
- **HTTPS**: Let's Encrypt сертификаты
- **Изоляция**: Docker контейнеры в отдельной сети
- **Доступ**: SSH ключи для административного доступа
