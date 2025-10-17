# ADR-0002: GitOps-Based Deployment with Argo CD

## Status
Accepted

## Date
2025-10-17

## Context

The automated braking system requires a declarative, auditable, and automated deployment mechanism that ensures consistency between Git repository state and cluster state. 

Current challenges:
- Manual deployments via kubectl/oc commands introduce risk of configuration drift
- Imperative commands lack complete audit trails
- No automated self-healing capabilities for configuration drift
- Difficult to track and rollback changes

The infrastructure-as-code philosophy demands that Git serves as the single source of truth for all application and configuration deployments.

## Decision

We will adopt **Argo CD** as the exclusive GitOps engine for all application and configuration rollouts across all environments. 

Key implementation details:
- All Kubernetes manifests will be stored in Git repositories
- Argo CD will automatically synchronize cluster state to match Git state
- Automated drift correction and self-healing will be enabled
- Separate Argo CD applications for development and production environments
- Kustomize overlays for environment-specific configurations

## Consequences

### Positive

- **Single Source of Truth**: Git serves as the authoritative source with complete audit trail of all changes
- **Automated Synchronization**: Argo CD continuously monitors and synchronizes cluster state with Git
- **Self-Healing**: Automatic drift correction when manual changes are made to the cluster
- **Easy Rollbacks**: Simple rollbacks via Git history (revert commits)
- **Declarative Model**: Reduces human error in deployments
- **OpenShift Integration**: Native integration with OpenShift for enhanced security and RBAC
- **Visibility**: Clear view of deployment status and sync state via Argo CD UI

### Negative

- **Operational Overhead**: Additional infrastructure to manage and maintain (Argo CD server, controllers)
- **Learning Curve**: Team needs training on GitOps workflows and Argo CD troubleshooting
- **Git Discipline Required**: Requires strict Git workflow and branch management discipline
- **Debugging Complexity**: Troubleshooting requires understanding both Git state and cluster state
- **Initial Setup**: Requires initial effort to configure Argo CD and migrate existing deployments

## Alternatives Considered

### 1. OpenShift GitOps (Red Hat's Managed Argo CD)
**Pros**: Red Hat supported, integrated with OpenShift, less operational overhead
**Cons**: Potentially slower release cycle, may lag behind upstream Argo CD features
**Why Not Chosen**: Vanilla Argo CD provides latest features; team comfortable managing it

### 2. Jenkins Pipelines with Imperative oc CLI Commands
**Pros**: Team familiarity, flexible scripting, existing Jenkins infrastructure
**Cons**: Imperative approach, harder to track state, no automatic drift correction, lacks declarative benefits
**Why Rejected**: Doesn't provide GitOps benefits and single source of truth

### 3. Flux CD
**Pros**: CNCF graduated project, GitOps-native, Helm-centric
**Cons**: Less mature UI, different operational model, team lacks Flux expertise
**Why Rejected**: Argo CD has better UI and team has some existing Argo CD knowledge

### 4. Manual Deployments via kubectl/oc
**Pros**: Simple, no additional tools needed, direct control
**Cons**: Error-prone, no audit trail, no drift detection, not scalable
**Why Rejected**: Does not meet requirements for production reliability and audit

## Implementation Notes

### Deployed Version
- **OpenShift GitOps Operator**: v1.15.4
- **Namespace**: openshift-gitops

### Configuration
- Argo CD applications exist for both production (`app-production.yaml`) and development (`app-development.yaml`)
- Sync policies configured with:
  - `automated.prune: true` - Auto-delete resources not in Git
  - `automated.selfHeal: true` - Auto-sync on drift detection
- Kustomize used for environment overlays (development, production)
- Repository: `https://github.com/tosin2013/automated-braking.git`
- Target revision: `main` branch

### Current Status
- ✅ OpenShift GitOps operator installed
- ⚠️  No ArgoCD applications deployed yet (ready for deployment)

## References

- [Argo CD Production App](/argocd/app-production.yaml)
- [Argo CD Development App](/argocd/app-development.yaml)
- [Kustomize Overlays](/manifests/overlays)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)

