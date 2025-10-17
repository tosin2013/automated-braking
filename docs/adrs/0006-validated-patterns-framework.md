# ADR-0006: Adopt OpenShift Validated Patterns Framework

## Status
Proposed

## Date
2025-10-17

## Context

The automated braking ML system currently uses a custom deployment structure with:
- Manual Kustomize overlays in `manifests/base/` and `manifests/overlays/`
- Handcrafted ArgoCD application definitions
- Custom bootstrap scripts without standardized framework

While functional, this approach has several limitations:
1. **Reinventing the wheel**: Building deployment automation from scratch
2. **No standardization**: Custom structure makes it harder for new team members
3. **Limited multi-site support**: Current structure doesn't scale to edge deployments
4. **Manual secrets management**: No integrated secrets framework
5. **Maintenance burden**: Custom scripts require ongoing maintenance

Red Hat's [OpenShift Validated Patterns](https://validatedpatterns.io/) provides a production-ready, battle-tested framework that:
- Uses OpenShift GitOps (ArgoCD) as the primary deployment driver
- Provides standardized directory structure (`common/`, `charts/`, `values-` files)
- Supports multi-site deployments (hub, datacenter, edge)
- Includes integrated secrets management via HashiCorp Vault
- Offers reusable patterns from the community (Industrial Edge, Multicloud GitOps)
- Uses Helm charts for powerful templating and repeatability

## Decision

We will **adopt the OpenShift Validated Patterns framework** as the foundation for our GitOps deployment architecture.

Key implementation decisions:
1. **Restructure repository** to follow Validated Patterns directory conventions
2. **Add `common/` submodule** from `validatedpatterns/common` repository
3. **Convert manifests to Helm charts** organized by deployment site
4. **Use Validated Patterns Makefile** for deployment orchestration
5. **Adopt values-file pattern** for environment configuration
6. **Integrate HashiCorp Vault** for secrets management

### Deployment Topology

```
Hub Cluster (distance-prediction):
- RHOAI ML Pipelines (DSPA)
- Model Registry
- MySQL/MariaDB databases
- Jupyter Workbenches
- S3 Storage (Minio)
```

Future edge deployments can be added using Red Hat ACM.

## Consequences

### Positive

- **Production-Ready Framework**: Leverage Red Hat's validated, supported patterns
- **Standardization**: Follow industry best practices and common structure
- **Community Patterns**: Learn from and adapt existing patterns (Industrial Edge is conceptually similar)
- **Multi-Site Ready**: Built-in support for hub/edge topologies when we need edge inference
- **Secrets Management**: Integrated Vault support for secure credential handling
- **Reduced Maintenance**: Framework maintained by Red Hat Validated Patterns team
- **Better Documentation**: Well-documented framework with examples
- **Helm Templating**: More powerful than Kustomize for complex scenarios
- **Values Overrides**: Easy cloud-specific and version-specific overrides

### Negative

- **Migration Effort**: Need to restructure existing manifests into Helm charts
- **Learning Curve**: Team needs to learn Validated Patterns conventions and Helm
- **Framework Dependency**: Tied to Validated Patterns update cycle
- **Helm vs Kustomize**: Moving away from existing Kustomize knowledge
- **Additional Complexity**: More directories and conventions to understand initially
- **Git Submodule**: Requires managing `common/` as a git submodule

### Neutral

- **Helm Requirement**: Validated Patterns strongly prefer Helm over Kustomize
- **Directory Reorganization**: Significant restructuring but one-time cost
- **Makefile-Driven**: Deployment orchestrated via Make (already familiar pattern)

## Migration Path

### Phase 1: Framework Setup (Week 1)
1. Add `common/` submodule: `git submodule add https://github.com/validatedpatterns/common.git`
2. Create `values-global.yaml` with pattern configuration
3. Create `values-hub.yaml` for ML pipeline configuration
4. Create `values-secret.yaml.template` for credentials

### Phase 2: Convert to Helm Charts (Week 2-3)
1. Create `charts/hub/` directory structure
2. Convert MySQL deployment to Helm chart: `charts/hub/mysql/`
3. Convert Model Registry to Helm chart: `charts/hub/model-registry/`
4. Convert DSPA to Helm chart: `charts/hub/data-science-pipelines/`
5. Convert workbenches to Helm chart: `charts/hub/workbenches/`

### Phase 3: ArgoCD Integration (Week 4)
1. Update ArgoCD applications to use Validated Patterns structure
2. Configure OpenShift GitOps to sync from new chart structure
3. Test deployment in development environment

### Phase 4: Secrets & Production (Week 5)
1. Deploy HashiCorp Vault via Validated Patterns
2. Migrate secrets to Vault
3. Deploy to production using framework
4. Update documentation

## Alternatives Considered

### 1. Continue with Custom Kustomize Structure
**Pros**: No migration effort, team already familiar, working today
**Cons**: No standardization, limited scalability, manual secrets management, maintenance burden
**Why Rejected**: Technical debt accumulates; doesn't scale to multi-site

### 2. Pure Helm without Validated Patterns Framework
**Pros**: Flexibility, modern approach, powerful templating
**Cons**: Still custom structure, no Red Hat validation, manual ArgoCD setup
**Why Rejected**: Misses the standardization and community benefits

### 3. Ansible-Based Deployment (AAP)
**Pros**: Team may have Ansible knowledge, procedural approach
**Cons**: Not GitOps-native, different paradigm from ArgoCD, less declarative
**Why Rejected**: Conflicts with ADR-0002 (GitOps commitment)

### 4. FluxCD with Kustomize
**Pros**: Keeps Kustomize, modern GitOps tool
**Cons**: Conflicts with ADR-0002 (ArgoCD decision), no Red Hat support
**Why Rejected**: Already committed to OpenShift GitOps (ArgoCD)

## Implementation Notes

### Validated Patterns Directory Structure

```
automated-braking/
├── common/                          # Git submodule
│   ├── Makefile
│   ├── scripts/
│   └── ansible/
├── charts/
│   └── hub/
│       ├── mysql/
│       │   ├── Chart.yaml
│       │   ├── templates/
│       │   └── values.yaml
│       ├── model-registry/
│       ├── data-science-pipelines/
│       └── workbenches/
├── values-global.yaml               # Pattern-wide configuration
├── values-hub.yaml                  # Hub-specific config
├── values-secret.yaml.template      # Secrets template (DO NOT COMMIT REAL VALUES)
├── Makefile -> common/Makefile      # Symlink to common Makefile
└── pattern.sh -> common/scripts/    # Pattern utility script
```

### Key Files

**values-global.yaml**:
```yaml
global:
  pattern: automated-braking
  namespace: distance-prediction
  git:
    repoURL: https://github.com/tosin2013/automated-braking.git
    revision: main
  options:
    useCSV: false
    syncPolicy: Automatic
```

**values-hub.yaml**:
```yaml
clusterGroup:
  name: hub
  applications:
    mysql:
      name: mysql
      namespace: distance-prediction
      chart: charts/hub/mysql
    model-registry:
      name: model-registry
      namespace: rhoai-model-registries
      chart: charts/hub/model-registry
```

### Deployment Command

```bash
make install  # Deploys entire pattern via framework
```

## Supersedes

This ADR enhances but does not supersede:
- **ADR-0001**: Still using OpenShift (required by Validated Patterns)
- **ADR-0002**: Still using ArgoCD (enhanced by Validated Patterns)
- **ADR-0003**: Still using RHOAI (deployed via Validated Patterns)

## Related Patterns

- [Industrial Edge Pattern](https://validatedpatterns.io/patterns/industrial-edge/) - Similar ML/IoT use case
- [Multicloud GitOps Pattern](https://validatedpatterns.io/patterns/multicloud-gitops/) - Multi-environment management

## References

- [Validated Patterns Framework Documentation](https://validatedpatterns.io/learn/vp_openshift_framework/)
- [Validated Patterns GitHub](https://github.com/validatedpatterns)
- [Industrial Edge Pattern](https://validatedpatterns.io/patterns/industrial-edge/)
- [Common Framework Repository](https://github.com/validatedpatterns/common)
- [ADR-0001: OpenShift Platform](0001-platform-selection-kubernetes-on-openshift.md)
- [ADR-0002: GitOps with ArgoCD](0002-gitops-deployment-with-argocd.md)

## Risk Assessment

**Migration Risk**: Medium
- One-time restructuring effort
- Can be done incrementally (phase by phase)
- Development environment can test before production

**Adoption Risk**: Low
- Framework is production-proven
- Red Hat supported and maintained
- Active community with examples

**Lock-in Risk**: Low
- Framework is open source
- Can extract Helm charts if needed
- ArgoCD and Helm are portable

## Success Criteria

1. ✅ Repository restructured to Validated Patterns format
2. ✅ All components deployed via `make install`
3. ✅ Secrets managed via HashiCorp Vault
4. ✅ ArgoCD applications auto-syncing from framework
5. ✅ Development and production environments deployed identically
6. ✅ Team trained on Validated Patterns workflow

## Review & Approval

- **Proposed By**: Architecture Team
- **Reviewers Needed**: DevOps Lead, ML Team Lead, Security Architect
- **Target Approval Date**: 2025-10-24
- **Implementation Start**: Upon approval

