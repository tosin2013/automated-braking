# ADR-0005: Model Registry Architecture and Integration

## Status
Accepted

## Date
2025-10-17

## Context

Machine learning models in the automated braking system require:
- **Versioning**: Track different versions of models with metadata
- **Lineage**: Understand data and code used to train each model
- **Governance**: Control which models are promoted to production
- **Discovery**: Find and compare models across the organization
- **Serving Integration**: Seamless integration with model serving infrastructure

Without a model registry, models are:
- Stored in ad-hoc locations (local files, S3 buckets)
- Difficult to version and compare
- Lack metadata about training data and parameters
- Hard to govern and audit
- Complex to integrate with serving infrastructure

Red Hat OpenShift AI provides a Model Registry component based on ML Metadata that integrates with the RHOAI ecosystem.

## Decision

We will use the **Red Hat OpenShift AI Model Registry** as the centralized model registry for all ML models.

Key architecture decisions:
- **Namespace**: `rhoai-model-registries` (separate from application namespace)
- **MySQL Backend**: Dedicated MySQL 8.3.0 instance for registry metadata
- **gRPC API**: Port 9090 for high-performance model metadata operations
- **REST API**: Port 8080 for HTTP-based access (route disabled by default)
- **OAuth Proxy**: Port 8443 with enabled service route for authenticated access
- **Skip DB Creation**: False (registry manages database schema)

## Consequences

### Positive

- **Centralized Governance**: Single source of truth for all model versions and metadata
- **Integration**: Native integration with RHOAI pipelines and serving infrastructure
- **Versioning**: Automatic version tracking with metadata
- **Security**: OAuth-based authentication and OpenShift RBAC integration
- **Lineage**: Track training data, code, and parameters for each model
- **Discoverability**: Easy to find and compare models across teams
- **Audit Trail**: Complete history of model registrations and promotions

### Negative

- **Single Point of Failure**: If registry is down, model operations are blocked
- **Learning Curve**: Team needs to learn model registry APIs and workflows
- **Database Dependency**: Requires MySQL backend (additional infrastructure)
- **Network Latency**: Cross-namespace communication adds minor latency
- **Operator Dependency**: Requires RHOAI operator to be running

## Alternatives Considered

### 1. MLflow Model Registry
**Pros**: Industry standard, open source, rich UI, experiment tracking
**Cons**: Not OpenShift-native, requires separate deployment, less integrated with RHOAI
**Why Rejected**: RHOAI provides integrated solution with enterprise support

### 2. S3 Bucket with Naming Conventions
**Pros**: Simple, no additional infrastructure, direct access
**Cons**: No metadata, no versioning support, no governance, manual naming enforcement
**Why Rejected**: Doesn't provide governance and versioning capabilities needed for production

### 3. DVC (Data Version Control)
**Pros**: Git-based versioning, lightweight, integrates with code
**Cons**: Primarily for data versioning, not model registry, lacks serving integration
**Why Rejected**: Not designed for production model serving workflows

### 4. Custom Model Repository Service
**Pros**: Full control, customized to specific needs
**Cons**: Development and maintenance burden, reinventing the wheel, no enterprise support
**Why Rejected**: RHOAI provides production-ready solution

## Implementation Notes

### Deployed Version
- **ModelRegistry CRD**: components.platform.opendatahub.io/v1alpha1
- **KServe TrainedModel CRD**: serving.kserve.io/v1alpha1
- **Part of**: Red Hat OpenShift AI v2.22.2

### Current Status
- ✅ ModelRegistry CRD available
- ✅ KServe CRDs available for model serving
- ⚠️  rhoai-model-registries namespace not created yet
- ⚠️  Model Registry instance not deployed yet (ready for deployment)

### Planned Model Registry Deployment

Location: `/manifests/base/model-registry.yaml`

```yaml
apiVersion: components.platform.opendatahub.io/v1alpha1
kind: ModelRegistry
metadata:
  name: distance-prediction
  namespace: rhoai-model-registries
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  grpc:
    port: 9090
  rest:
    port: 8080
    serviceRoute: disabled
  oauthProxy:
    port: 8443
    routePort: 443
    serviceRoute: enabled
  mysql:
    host: mysql.distance-prediction.svc.cluster.local
    port: 3306
    database: modelregistry
    username: registryuser
    skipDBCreation: false
    passwordSecret:
      name: distance-prediction-db
      key: database-password
```

### Architecture

```
┌─────────────────────────────────────────┐
│   rhoai-model-registries namespace      │
│                                          │
│  ┌───────────────────────────────────┐  │
│  │   Model Registry Service          │  │
│  │   - gRPC API (9090)              │  │
│  │   - REST API (8080, disabled)    │  │
│  │   - OAuth Proxy (8443)           │  │
│  └─────────────┬─────────────────────┘  │
│                │                         │
│                ▼                         │
│  ┌───────────────────────────────────┐  │
│  │   MySQL (cross-namespace)         │  │
│  │   distance-prediction namespace   │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
          │
          │ Model Registration
          ▼
┌─────────────────────────────────────────┐
│   distance-prediction namespace         │
│                                          │
│  Pipeline → Model Training → Registry   │
│                                          │
│  Registry → Model Serving Infrastructure│
└─────────────────────────────────────────┘
```

### Model Registration Workflow

1. **Training Pipeline** completes model training
2. **Model Artifacts** saved to S3-compatible storage
3. **Registration Step** calls Model Registry API via `register_model.ipynb`
4. **Metadata Storage** in MySQL backend
5. **Model Serving** pulls model path from registry
6. **Version Management** handled by registry API

### Notebook Integration

- `register_model.ipynb`: Registers trained models with metadata
- `endpoint.ipynb`: Retrieves model endpoint from registry
- Pipeline notebooks automatically integrate with registry

## Security Considerations

1. **Authentication**: OAuth proxy enforces OpenShift authentication
2. **Authorization**: RBAC controls who can register/read models
3. **Network**: Service routes only exposed where needed (OAuth proxy only)
4. **Secrets**: Database credentials stored in Kubernetes secrets
5. **Cross-Namespace**: MySQL in different namespace provides isolation

## Model Deployment Path

Per README.md documentation:
> When you deploy the model, make sure that the path is `models/distance/`. Do not include the model version folder! When you run the inference, the name of the deployed model will include the version and somehow OpenVINO will match it up.

This indicates a specific convention for model paths in the registry.

## Future Improvements

1. **High Availability**: Add MySQL replication for registry backend
2. **Backup Strategy**: Implement automated backup of registry metadata
3. **Monitoring**: Add registry-specific metrics and alerts
4. **REST API**: Consider enabling REST API if external integrations need it
5. **Model Approval Workflow**: Implement governance workflow for production promotions
6. **Model Comparison UI**: Add dashboards for comparing model performance

## References

- [Model Registry Manifest](/manifests/base/model-registry.yaml)
- [MySQL Backend Configuration](/manifests/base/mysql.yaml)
- [Register Model Notebook](/build-model/register_model.ipynb)
- [Model Endpoint Notebook](/build-model/endpoint.ipynb)
- [RHOAI Model Registry Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/)

