# ADR-0001: Platform Selection - Kubernetes on OpenShift

## Status
Accepted

## Date
2025-10-17

## Context

The automated braking ML system requires a robust, enterprise-grade Kubernetes platform that provides consistent cluster behavior, built-in security features, operator-based management, and compliance with organizational standards. The project constraints explicitly require OpenShift as the target platform.

Key requirements:
- Consistent cluster behavior across development, staging, and production environments
- Built-in security features and compliance controls
- Operator-based management for streamlined operations
- Enterprise support and regular security updates
- Integrated monitoring, logging, and developer tools

This decision standardizes infrastructure across all environments to avoid cluster drift and leverage Red Hat's enterprise support model.

## Decision

We will standardize on **Red Hat OpenShift** as the sole Kubernetes platform for all environments (development, staging, production). All deployments will utilize OpenShift-specific features including:

- Operators for application lifecycle management
- Security Context Constraints (SCC) for pod security
- Integrated container registry
- Native networking capabilities (SDN/OVN)
- Built-in monitoring and logging stacks

## Consequences

### Positive

- **Consistency**: Uniform cluster behavior across all environments with standardized RBAC, network policies, and security configurations
- **Enterprise Support**: Access to Red Hat enterprise support with regular security updates and patches
- **Built-in Features**: Integrated monitoring (Prometheus/Grafana), logging (EFK/Loki), and developer console
- **Security**: Advanced security features including SCC, network policies, and compliance scanning out of the box
- **Operator Ecosystem**: Rich ecosystem of operators for common middleware and databases

### Negative

- **Learning Curve**: Team requires OpenShift-specific knowledge and training
- **Licensing Cost**: Potential licensing and governance overhead compared to vanilla Kubernetes
- **Vendor Lock-in**: Limited flexibility for running on other Kubernetes distributions without modifications
- **Resource Overhead**: OpenShift requires more resources than minimal Kubernetes distributions

## Alternatives Considered

### 1. Vanilla Upstream Kubernetes
**Pros**: Maximum flexibility, no licensing costs, works on any infrastructure
**Cons**: Requires manual security hardening, no enterprise support, complex to manage at scale
**Why Rejected**: Lacks enterprise features and support required for production ML systems

### 2. Managed Kubernetes Services (AWS EKS, Google GKE, Azure AKS)
**Pros**: Managed control plane, cloud-native integration, lower operational overhead
**Cons**: Cloud vendor lock-in, less control over cluster configuration, may not meet compliance requirements
**Why Rejected**: Project requires on-premises/hybrid deployment capability

### 3. Rancher-Managed Kubernetes Clusters
**Pros**: Multi-cluster management, works with various Kubernetes distributions, good UI
**Cons**: Additional management layer, less integrated than OpenShift, requires Rancher expertise
**Why Rejected**: Organization already standardized on Red Hat/OpenShift ecosystem

## Implementation Notes

### Deployed Version
- **OpenShift**: 4.18.21
- **Kubernetes**: v1.31.10
- **Platform**: Red Hat Enterprise Linux CoreOS 418.94
- **Container Runtime**: CRI-O 1.31.10
- **Cluster**: Multi-node (2 control-plane, 2 workers) on AWS us-east-2

### Current Status
- ✅ OpenShift cluster deployed and operational
- ✅ All existing manifests use OpenShift-specific resources
- ✅ ArgoCD configurations target OpenShift clusters
- ✅ Organizational requirement for Red Hat support is satisfied

## References

- [Project manifests](/manifests) - Uses OpenShift resources
- [ArgoCD configuration](/argocd) - Targets OpenShift clusters
- [Red Hat OpenShift Documentation](https://docs.openshift.com/)

