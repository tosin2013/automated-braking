# Migration to OpenShift Validated Patterns Framework

This guide walks through migrating the Automated Braking ML System to use the [OpenShift Validated Patterns framework](https://validatedpatterns.io/).

**Status**: Implementation guide for [ADR-0006](adrs/0006-validated-patterns-framework.md)

## Prerequisites

- OpenShift 4.12+ cluster (✅ Currently running 4.18.21)
- OpenShift GitOps operator installed (✅ Already installed v1.15.4)
- Red Hat OpenShift AI installed (✅ Already installed v2.22.2)
- `oc` CLI authenticated to cluster
- Git repository access
- Helm 3.x installed

## Why Validated Patterns?

According to [Red Hat's documentation](https://validatedpatterns.io/learn/vp_openshift_framework/):

> The OpenShift validated patterns framework uses OpenShift GitOps (ArgoCD) as the primary driver for deploying patterns and keeping them up to date. Validated patterns use Helm charts as the primary artifacts for GitOps.

**Key Benefits**:
- ✅ Production-tested by Red Hat
- ✅ Standardized structure across patterns
- ✅ Built-in multi-site support (hub/edge)
- ✅ Integrated secrets management (HashiCorp Vault)
- ✅ Community patterns to learn from ([Industrial Edge](https://validatedpatterns.io/patterns/industrial-edge/))

## Migration Phases

### Phase 1: Add Validated Patterns Framework (30 minutes)

#### Step 1.1: Add common submodule

```bash
cd /home/lab-user/automated-braking

# Add the common framework as a git submodule
git submodule add https://github.com/validatedpatterns/common.git

# Initialize and update submodules
git submodule init
git submodule update

# Create symlinks to framework utilities
ln -s common/Makefile Makefile.vp
ln -s common/scripts/pattern-util.sh pattern.sh
```

#### Step 1.2: Create pattern metadata

```bash
cat > pattern-metadata.yaml << 'EOF'
apiVersion: v1alpha1
kind: Pattern
metadata:
  name: automated-braking
  displayName: "Automated Braking ML System"
  description: "ML-based automated braking distance prediction with RHOAI"
spec:
  framework: "openshift"
  tier: "tested"
  cloudProviders:
    - name: aws
      tested: true
    - name: azure
      tested: false
    - name: gcp
      tested: false
  operators:
    - name: openshift-gitops
      required: true
    - name: rhods-operator
      required: true
  clusterGroups:
    - name: hub
      description: "ML Pipeline and Model Registry Hub"
EOF
```

#### Step 1.3: Create global values

```bash
cat > values-global.yaml << 'EOF'
global:
  pattern: automated-braking
  namespace: distance-prediction
  
  git:
    repoURL: https://github.com/tosin2013/automated-braking.git
    revision: main
    
  options:
    useCSV: false
    syncPolicy: Automatic
    installPlanApproval: Automatic
    
  imageRegistry:
    hostname: quay.io
    
  datacenter:
    clustername: cluster-fzqdg
    domain: fzqdg.sandbox3272.opentlc.com
EOF
```

### Phase 2: Create Helm Charts Structure (2-3 hours)

#### Step 2.1: Create charts directory structure

```bash
mkdir -p charts/hub/{mysql,model-registry,pipelines,workbenches}
```

#### Step 2.2: Convert MySQL to Helm chart

```bash
# Create Chart.yaml
cat > charts/hub/mysql/Chart.yaml << 'EOF'
apiVersion: v2
name: mysql
description: MySQL database for Model Registry
type: application
version: 0.1.0
appVersion: "8.3.0"
EOF

# Create values.yaml
cat > charts/hub/mysql/values.yaml << 'EOF'
enabled: true

image:
  repository: mysql
  tag: "8.3.0"
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 500m
    memory: 1Gi

persistence:
  size: 10Gi
  storageClass: ""  # Use default

database:
  name: modelregistry
  user: registryuser
  # Password from secret

service:
  port: 3306
  type: ClusterIP

args:
  - --datadir
  - /var/lib/mysql/datadir
  - --default-authentication-plugin=mysql_native_password
EOF

# Convert existing manifests/base/mysql.yaml to templates/
mkdir -p charts/hub/mysql/templates
# ... (this would involve converting the YAML with Helm templating)
```

#### Step 2.3: Create values-hub.yaml

```bash
cat > values-hub.yaml << 'EOF'
clusterGroup:
  name: hub
  isHubCluster: true
  
  namespaces:
    - distance-prediction
    - rhoai-model-registries
  
  applications:
    mysql:
      name: mysql
      namespace: distance-prediction
      project: default
      path: charts/hub/mysql
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
    
    model-registry:
      name: model-registry
      namespace: rhoai-model-registries
      project: default
      path: charts/hub/model-registry
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
    
    data-science-pipelines:
      name: dspa
      namespace: distance-prediction
      project: default
      path: charts/hub/pipelines
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
    
    workbenches:
      name: workbenches
      namespace: distance-prediction
      project: default
      path: charts/hub/workbenches
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
  
  operatorGroups:
    - name: distance-prediction-og
      namespace: distance-prediction
      targetNamespaces:
        - distance-prediction
EOF
```

### Phase 3: Secrets Management (1 hour)

#### Step 3.1: Create secrets template

```bash
cat > values-secret.yaml.template << 'EOF'
# Copy this file to ~/.config/validatedpatterns/values-secret-automated-braking.yaml
# Update with your actual credentials
# DO NOT commit this file with real credentials!

secrets:
  # Database credentials
  database:
    mysql:
      root_password: CHANGEME
      user_password: CHANGEME
  
  # S3/Minio credentials
  s3:
    access_key: CHANGEME
    secret_key: CHANGEME
    endpoint: minio-s3-distance-prediction.apps.CHANGEME
  
  # Git credentials (if needed)
  git:
    username: CHANGEME
    token: CHANGEME
  
  # Container registry (if needed)
  quay:
    username: CHANGEME
    password: CHANGEME
EOF
```

#### Step 3.2: Setup secrets directory

```bash
mkdir -p ~/.config/validatedpatterns

# Copy template and edit with real values
cp values-secret.yaml.template \
   ~/.config/validatedpatterns/values-secret-automated-braking.yaml

# Edit with real credentials (use your favorite editor)
# vim ~/.config/validatedpatterns/values-secret-automated-braking.yaml

# Optional: Encrypt with ansible-vault
ansible-vault encrypt \
  ~/.config/validatedpatterns/values-secret-automated-braking.yaml
```

### Phase 4: Deploy via Validated Patterns (30 minutes)

#### Step 4.1: Validate configuration

```bash
# Check Helm charts syntax
helm lint charts/hub/mysql
helm lint charts/hub/model-registry
helm lint charts/hub/pipelines
helm lint charts/hub/workbenches

# Dry-run to see what would be deployed
helm template automated-braking charts/hub/mysql -f values-global.yaml -f values-hub.yaml
```

#### Step 4.2: Deploy pattern

```bash
# Using the Validated Patterns Makefile
make -f Makefile.vp install

# This will:
# 1. Validate prerequisites
# 2. Create namespaces
# 3. Deploy ArgoCD applications
# 4. Configure secrets management
# 5. Sync all applications
```

#### Step 4.3: Monitor deployment

```bash
# Watch ArgoCD applications
oc get applications -n openshift-gitops -w

# Check application sync status
make -f Makefile.vp status

# View detailed application status
oc get applications automated-braking-mysql -n openshift-gitops -o yaml
```

## Validation Checklist

After migration, verify:

- [ ] `common/` submodule added and initialized
- [ ] All Helm charts created in `charts/hub/`
- [ ] `values-global.yaml` configured with cluster details
- [ ] `values-hub.yaml` configured with applications
- [ ] Secrets configured in `~/.config/validatedpatterns/`
- [ ] Pattern deploys successfully with `make install`
- [ ] All ArgoCD applications show "Synced" and "Healthy"
- [ ] MySQL pod running
- [ ] Model Registry service available
- [ ] DSPA deployed and ready
- [ ] Workbenches accessible
- [ ] Original `bootstrap.sh` validation still passes

## Rollback Plan

If migration fails:

```bash
# Remove Validated Patterns ArgoCD applications
oc delete applications -n openshift-gitops -l pattern=automated-braking

# Revert to original bootstrap approach
./bootstrap.sh

# Or use original ArgoCD applications
oc apply -f argocd/app-development.yaml
```

## Incremental Adoption Strategy

You can adopt Validated Patterns incrementally:

### Option 1: Dual-Track (Recommended for Testing)
- Keep existing `manifests/` and `argocd/` structure
- Add Validated Patterns in parallel
- Test in development environment
- Switch production after validation

### Option 2: Component-by-Component
1. Week 1: Migrate MySQL to Helm chart
2. Week 2: Migrate Model Registry
3. Week 3: Migrate DSPA
4. Week 4: Migrate Workbenches
5. Week 5: Remove old structure

### Option 3: Big Bang (Higher Risk)
- Complete full migration in one push
- Test thoroughly in development
- Deploy to production after validation

## Comparing Approaches

| Aspect | Current (Kustomize) | Validated Patterns (Helm) |
|--------|---------------------|----------------------------|
| **Structure** | Custom | Standardized |
| **Deployment** | Custom scripts | `make install` |
| **Templating** | Kustomize overlays | Helm values |
| **Secrets** | Manual Kubernetes secrets | Vault integration |
| **Multi-site** | Manual setup | Built-in support |
| **Community** | None | Active Red Hat community |
| **Support** | Self-supported | Red Hat validated |

## Useful Commands

```bash
# Validated Patterns Framework
make install          # Deploy entire pattern
make upgrade          # Upgrade pattern
make uninstall        # Remove pattern
make status           # Check application status

# Traditional Approach (for comparison)
./bootstrap.sh        # Deploy with custom script
./validate_bootstrap.sh  # Validate deployment

# ArgoCD
oc get applications -n openshift-gitops
oc describe application automated-braking-mysql -n openshift-gitops

# Pattern utilities
./pattern.sh status   # Check pattern status
./pattern.sh help     # Show available commands
```

## References

- [Validated Patterns Framework Documentation](https://validatedpatterns.io/learn/vp_openshift_framework/)
- [Industrial Edge Pattern](https://validatedpatterns.io/patterns/industrial-edge/) (similar ML use case)
- [Validated Patterns GitHub](https://github.com/validatedpatterns)
- [Common Framework Repository](https://github.com/validatedpatterns/common)
- [ADR-0006: Validated Patterns Framework](adrs/0006-validated-patterns-framework.md)

## Getting Help

- **Validated Patterns Slack**: [#validated-patterns](https://kubernetes.slack.com/archives/C02TYNJ8J0G)
- **Mailing List**: [validated-patterns@redhat.com](mailto:validated-patterns@redhat.com)
- **GitHub Issues**: [validatedpatterns/common](https://github.com/validatedpatterns/common/issues)

---

**Next Steps**: Review [ADR-0006](adrs/0006-validated-patterns-framework.md) and decide on adoption timeline.

