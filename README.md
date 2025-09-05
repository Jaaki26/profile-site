# Profile Website — GitOps on AKS with Jenkins, Docker, ACR, Argo CD, SonarQube

This repo contains:
- A static profile website (served by NGINX in Docker)
- Jenkins pipeline (Jenkinsfile) to build, scan with SonarQube, push to Azure Container Registry (ACR), and update k8s manifests
- Kubernetes manifests managed by **Kustomize**
- **Argo CD** Application manifest to continuously deploy from this repo
- SonarQube configuration file

## High-level Flow

1. Developer pushes to `main`.
2. Jenkins:
   - Runs SonarQube scan
   - Builds Docker image and pushes to ACR
   - Updates image tag in `deploy/overlays/prod/kustomization.yaml`
   - Commits and pushes changes back to this repo
3. Argo CD watches `deploy/overlays/prod` and applies the change to AKS.

## Quick Start

### Prerequisites
- Azure: ACR + AKS (and network access from AKS to ACR)
- Jenkins with Docker-in-Docker or Docker on agent
- SonarQube Server & a token
- Argo CD installed and accessible to your AKS
- Git credentials that allow Jenkins to push to this repository

### Configure Jenkins (suggested)
- **Credentials**:
  - `acr-username` / `acr-password` (Username/Password for ACR or a service principal)
  - `sonar-token` (Secret text)
  - `git-creds` (Username/Password or Personal Access Token) to push back to repo
- **Environment Variables** (Jenkinsfile expects these as parameters or pipeline env):
  - `ACR_LOGIN_SERVER` e.g. `myregistry.azurecr.io`
  - `ACR_REPO` e.g. `profile-site`
  - `GIT_CREDENTIALS_ID` e.g. `git-creds`
  - `SONAR_HOST_URL` e.g. `https://sonar.mycompany.com`

> If using AutoSync in Argo CD, the deploy happens automatically. Otherwise, enable autosync on the Application.

### Argo CD
- Update the `repoURL` in `argocd/application.yaml` to point to your GitHub repo.
- Apply the Application: `kubectl apply -n argocd -f argocd/application.yaml`

### Accessing the site
- An Ingress definition is included. Configure your Ingress Controller (Nginx or Azure Application Gateway).
- Set a DNS record for the `host` in `deploy/overlays/prod/ingress.yaml` (default: `profile.example.com`).

