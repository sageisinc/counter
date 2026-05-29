# Counter App

A full-stack counter application with user authentication, PostgreSQL backend, deployed to OpenStack via Terraform and Ansible.

## Features
- User registration and login
- Create multiple named counters
- Count up / down / reset
- Set counter to a specific number
- Persistent storage with PostgreSQL

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Backend | Python / Flask |
| Database | PostgreSQL |
| Frontend | HTML / CSS / Vanilla JS |
| IaC | Terraform (OpenStack provider) |
| Config Management | Ansible |
| CI/CD | GitHub Actions |

## Local Development

```bash
# Start with Docker Compose
docker-compose up -d

# App available at http://localhost:5000
```

## Project Structure
```
counter-app/
├── app/                    # Flask application
│   ├── app.py             # Main application
│   ├── requirements.txt
│   ├── Dockerfile
│   └── templates/
├── terraform/              # OpenStack infrastructure
│   ├── main.tf
│   └── variables.tf
├── ansible/                # Server configuration
│   ├── deploy.yml
│   ├── inventory.ini.tpl
│   ├── group_vars/all.yml
│   └── roles/
│       ├── postgresql/
│       ├── app/
│       └── nginx/
├── .github/workflows/
│   └── deploy.yml          # CI/CD pipeline
└── docker-compose.yml
```

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `OS_PASSWORD` | OpenStack admin password |
| `SSH_PRIVATE_KEY` | Deploy SSH private key |
| `SSH_PUBLIC_KEY` | Deploy SSH public key |
| `DB_PASSWORD` | PostgreSQL password |
| `APP_SECRET_KEY` | Flask secret key |

## Deployment Flow

1. Push to `main` → triggers GitHub Actions
2. **Test** job runs app smoke tests against PostgreSQL
3. **Deploy** job:
   - Terraform provisions OpenStack VM + floating IP
   - Ansible installs PostgreSQL, app, Nginx
   - Health check verifies deployment
