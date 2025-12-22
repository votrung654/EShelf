# Jenkins Configuration

Jenkins pipeline configuration for eShelf (Lab 2).

## Setup Jenkins

### Option 1: Docker

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

### Option 2: Kubernetes

```bash
# Add Jenkins Helm repo
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Install Jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  -f jenkins-values.yaml
```

## Configure Jenkins

### 1. Install Plugins

Required plugins:
- Docker Pipeline
- Kubernetes
- SonarQube Scanner
- Slack Notification
- Git

### 2. Add Credentials

**Harbor Registry:**
- ID: `harbor-credentials`
- Type: Username with password

**Kubernetes:**
- ID: `kubeconfig`
- Type: Secret file

**SonarQube:**
- ID: `sonarqube-token`
- Type: Secret text

### 3. Configure SonarQube

1. Go to Manage Jenkins → Configure System
2. Add SonarQube server:
   - Name: SonarQube
   - URL: http://sonarqube:9000
   - Token: Add from credentials

### 4. Create Pipeline Job

1. New Item → Pipeline
2. Pipeline script from SCM
3. Repository URL: https://github.com/levanvux/eShelf
4. Script Path: jenkins/Jenkinsfile
5. Branch: main

## Pipeline Stages

| Stage | Description | Tools |
|-------|-------------|-------|
| Checkout | Clone repository | Git |
| Lint & Test | Code quality checks | ESLint, npm test |
| SonarQube | Code analysis | SonarQube |
| Build | Docker image build | Docker |
| Security Scan | Vulnerability scan | Trivy |
| Push | Push to registry | Harbor |
| Deploy Staging | Deploy to K8s staging | kubectl, kustomize |
| Integration Tests | API tests | Postman/Newman |
| Deploy Production | Deploy to K8s prod | kubectl (manual approval) |

## Triggering Pipeline

### Automatic (Webhook)

Configure GitHub webhook:
- URL: http://jenkins:8080/github-webhook/
- Events: Push, Pull Request

### Manual

Click "Build Now" in Jenkins UI.

## Monitoring Pipeline

### View Logs

```bash
# Get Jenkins pod logs
kubectl logs -f jenkins-0 -n jenkins

# View specific build logs in UI
# http://jenkins:8080/job/eshelf/lastBuild/console
```

## Troubleshooting

### Docker build fails

Check Docker daemon is accessible:
```bash
docker ps
```

### Kubernetes deployment fails

Check kubeconfig:
```bash
kubectl get nodes
kubectl get pods -n eshelf-staging
```

### SonarQube connection fails

Check SonarQube is running:
```bash
curl http://sonarqube:9000/api/system/status
```

