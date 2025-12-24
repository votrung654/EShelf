#!/bin/bash

# Validation script for new features
# Checks syntax, structure, and safety of new implementations

set -e

ERRORS=0
WARNINGS=0

echo "=== Validating New Features ==="
echo ""

# Check YAML syntax
echo "1. Validating YAML files..."
YAML_FILES=(
  ".github/workflows/pr-only.yml"
  ".github/workflows/sonarqube-scan.yml"
  "infrastructure/kubernetes/jenkins/deployment.yaml"
  "infrastructure/kubernetes/jenkins/service.yaml"
  "infrastructure/kubernetes/jenkins/ingress.yaml"
  "infrastructure/kubernetes/sonarqube/deployment.yaml"
  "infrastructure/kubernetes/sonarqube/service.yaml"
  "infrastructure/kubernetes/sonarqube/ingress.yaml"
  "infrastructure/kubernetes/argocd/applications/api-gateway-app.yaml"
  "infrastructure/kubernetes/argocd/applications/auth-service-app.yaml"
  "infrastructure/kubernetes/argocd/applications/book-service-app.yaml"
  "infrastructure/kubernetes/argocd/applications/user-service-app.yaml"
  "infrastructure/kubernetes/argocd/applications/ml-service-app.yaml"
)

for file in "${YAML_FILES[@]}"; do
  if [ -f "$file" ]; then
    if command -v yamllint &> /dev/null; then
      if ! yamllint "$file" &> /dev/null; then
        echo "  ERROR: $file has YAML syntax errors"
        ((ERRORS++))
      else
        echo "  OK: $file"
      fi
    elif command -v python3 &> /dev/null; then
      if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo "  ERROR: $file has YAML syntax errors"
        ((ERRORS++))
      else
        echo "  OK: $file"
      fi
    else
      echo "  WARNING: No YAML validator found, skipping $file"
      ((WARNINGS++))
    fi
  else
    echo "  WARNING: $file not found"
    ((WARNINGS++))
  fi
done

echo ""

# Check Terraform syntax
echo "2. Validating Terraform files..."
if command -v terraform &> /dev/null; then
  for env in staging prod; do
    if [ -d "infrastructure/terraform/environments/$env" ]; then
      cd "infrastructure/terraform/environments/$env"
      if terraform init -backend=false &> /dev/null && terraform validate &> /dev/null; then
        echo "  OK: $env environment"
      else
        echo "  ERROR: $env environment has Terraform errors"
        ((ERRORS++))
      fi
      cd - &> /dev/null
    fi
  done
else
  echo "  WARNING: Terraform not found, skipping validation"
  ((WARNINGS++))
fi

echo ""

# Check shell scripts
echo "3. Validating shell scripts..."
SHELL_SCRIPTS=(
  "scripts/aws-shutdown.sh"
  "scripts/aws-startup.sh"
  "scripts/setup-harbor-credentials.sh"
)

for script in "${SHELL_SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    if command -v shellcheck &> /dev/null; then
      if shellcheck "$script" &> /dev/null; then
        echo "  OK: $script"
      else
        echo "  WARNING: $script has shellcheck warnings"
        ((WARNINGS++))
      fi
    else
      if bash -n "$script" 2>/dev/null; then
        echo "  OK: $script (syntax check)"
      else
        echo "  ERROR: $script has syntax errors"
        ((ERRORS++))
      fi
    fi
  fi
done

echo ""

# Check workflow syntax
echo "4. Validating GitHub Actions workflows..."
if command -v actionlint &> /dev/null; then
  for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
      if actionlint "$workflow" &> /dev/null; then
        echo "  OK: $workflow"
      else
        echo "  WARNING: $workflow has actionlint warnings"
        ((WARNINGS++))
      fi
    fi
  done
else
  echo "  WARNING: actionlint not found, skipping workflow validation"
  ((WARNINGS++))
fi

echo ""

# Check for Harbor registry references
echo "5. Checking Harbor registry migration..."
if grep -r "docker.io" .github/workflows/*.yml 2>/dev/null | grep -v "registry-1.docker.io" | grep -v "#"; then
  echo "  WARNING: Found DockerHub references in workflows"
  ((WARNINGS++))
else
  echo "  OK: No DockerHub references found (Harbor migration complete)"
fi

echo ""

# Check ArgoCD Image Updater annotations
echo "6. Checking ArgoCD Image Updater annotations..."
MISSING_ANNOTATIONS=0
for app in infrastructure/kubernetes/argocd/applications/*.yaml; do
  if [ -f "$app" ]; then
    if ! grep -q "argocd-image-updater.argoproj.io/image-list" "$app"; then
      echo "  WARNING: Missing Image Updater annotations in $app"
      ((MISSING_ANNOTATIONS++))
    fi
  fi
done

if [ $MISSING_ANNOTATIONS -eq 0 ]; then
  echo "  OK: All ArgoCD applications have Image Updater annotations"
else
  echo "  WARNING: $MISSING_ANNOTATIONS applications missing annotations"
  ((WARNINGS++))
fi

echo ""

# Summary
echo "=== Validation Summary ==="
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "VALIDATION FAILED: Please fix errors before proceeding"
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo ""
  echo "VALIDATION PASSED with warnings"
  exit 0
else
  echo ""
  echo "VALIDATION PASSED: All checks successful"
  exit 0
fi

