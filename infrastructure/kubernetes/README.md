# Kubernetes Manifests

Kubernetes deployment configurations for eShelf.

## Directory Structure

```
kubernetes/
├── base/                    # Base manifests
│   ├── namespace.yaml
│   ├── *-deployment.yaml
│   └── kustomization.yaml
│
├── overlays/               # Environment-specific configs
│   ├── dev/
│   ├── staging/
│   └── prod/
│
└── helm/                   # Helm charts (alternative)
    └── eshelf/
```

## Deployment

### Using Kustomize

```bash
# Deploy to dev
kubectl apply -k overlays/dev

# Deploy to staging
kubectl apply -k overlays/staging

# Deploy to production
kubectl apply -k overlays/prod
```

### Using kubectl

```bash
# Apply base manifests
kubectl apply -f base/

# Check deployments
kubectl get deployments -n eshelf
kubectl get pods -n eshelf
kubectl get services -n eshelf
```

## Services

| Service | Port | Replicas |
|---------|------|----------|
| api-gateway | 3000 | 2 |
| auth-service | 3001 | 2 |
| book-service | 3002 | 2 |
| user-service | 3003 | 2 |
| ml-service | 8000 | 1 |

## Monitoring

```bash
# Watch pods
kubectl get pods -n eshelf -w

# View logs
kubectl logs -f deployment/api-gateway -n eshelf

# Describe pod
kubectl describe pod <pod-name> -n eshelf
```

## Scaling

```bash
# Manual scaling
kubectl scale deployment api-gateway --replicas=3 -n eshelf

# Autoscaling (HPA)
kubectl autoscale deployment api-gateway \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n eshelf
```

## Rollback

```bash
# View rollout history
kubectl rollout history deployment/api-gateway -n eshelf

# Rollback to previous version
kubectl rollout undo deployment/api-gateway -n eshelf

# Rollback to specific revision
kubectl rollout undo deployment/api-gateway --to-revision=2 -n eshelf
```

## Troubleshooting

### Pods not starting

```bash
# Check events
kubectl get events -n eshelf --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs <pod-name> -n eshelf

# Describe pod for details
kubectl describe pod <pod-name> -n eshelf
```

### Service not accessible

```bash
# Check service
kubectl get svc -n eshelf

# Check endpoints
kubectl get endpoints -n eshelf

# Port forward for testing
kubectl port-forward svc/api-gateway 3000:3000 -n eshelf
```

## Next Steps

1. Setup Ingress for external access
2. Configure HPA for autoscaling
3. Setup ArgoCD for GitOps
4. Add monitoring (Prometheus, Grafana)

