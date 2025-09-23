DevOps Portfolio Showcase
=========================

Production-ready personal site for a DevOps engineer with full lifecycle: IaC (Terraform), configuration management (Ansible), containerization (Docker), CI/CD (GitHub Actions), monitoring (Prometheus, Grafana), logging (Loki, Promtail), web server (Nginx), backups, and notifications.

Inspired by: `https://khaustovtech.club/`

Features
- Static-like Flask site with 3 pages: Home, About/Docs, Metrics
- Prometheus metrics endpoint and embedded Grafana (optional)
- Dockerized app with Nginx reverse proxy
- Local docker-compose for app + monitoring + logging stack
- Terraform for Yandex Cloud VM provisioning (Ubuntu 24.04 LTS)
- Ansible to install Docker and deploy stack
- GitHub Actions pipeline: build, test, push, deploy
- Telegram notifications (pipeline and alerts)

Quick start (local)
1. Prereqs: Docker Desktop, Git
2. Clone repository and copy env sample
   - `cp infra/ansible/group_vars/all.yml infra/ansible/group_vars/all.local.yml`
3. Build and run
   - `docker compose up -d --build`
4. App: http://localhost:8080
5. Prometheus: http://localhost:9090, Grafana: http://localhost:3000 (admin/admin)

Deploy (Yandex Cloud)
1. Create YC service account and auth; export credentials
2. `cd infra/terraform && cp terraform.tfvars.example terraform.tfvars` and fill vars
3. `terraform init && terraform apply`
4. Output will show `public_ip` and ssh info
5. `cd ../ansible && ansible-playbook -i inventory.ini site.yml`

Repository structure
```
app/                    # Flask app, templates, static, metrics
infra/
  terraform/            # YC VM provisioning
  ansible/              # Roles: docker, app; site.yml
  monitoring/           # Prometheus, Grafana configs
  logging/              # Loki, Promtail configs
.github/workflows/      # CI pipeline
Dockerfile
docker-compose.yml
```

License
MIT
v_9