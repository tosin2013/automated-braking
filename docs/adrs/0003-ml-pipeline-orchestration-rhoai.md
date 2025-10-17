# ADR-0003: ML Pipeline Orchestration with Red Hat OpenShift AI

## Status
Accepted

## Date
2025-10-17

## Context

The automated braking system requires orchestration of complex ML workflows including:
- Data generation from sensor inputs
- Model training with hyperparameter tuning
- Model validation and testing
- Model registration in model registry
- Model deployment to serving infrastructure

Requirements:
- Workflows must be reproducible and versioned
- Integration with Kubernetes/OpenShift infrastructure
- Enterprise support for production ML operations
- Artifact storage and lineage tracking
- Jupyter notebook integration for development

Red Hat OpenShift AI (formerly OpenShift Data Science/Open Data Hub) provides enterprise-supported ML pipeline capabilities on OpenShift with DataSciencePipelinesApplication CRDs based on Kubeflow Pipelines v2.

## Decision

We will use **Red Hat OpenShift AI Services** to author, schedule, and manage end-to-end ML pipelines.

Key components:
- **Data Science Pipeline Applications (DSPA)** for workflow orchestration
- **MariaDB** for pipeline metadata storage
- **S3-compatible storage** for pipeline artifacts
- **Jupyter workbenches** for pipeline development and debugging
- **DSP version 2** for modern pipeline capabilities

## Consequences

### Positive

- **Enterprise Support**: Red Hat provides support, regular updates, and security patches
- **Native Integration**: Seamless integration with OpenShift security, networking, and RBAC
- **Model Registry Integration**: Built-in integration with model registry and serving capabilities
- **Consistent Telemetry**: Unified monitoring via OpenShift observability stack (Prometheus/Grafana)
- **Operator-Based Management**: Pipeline infrastructure managed via Kubernetes operators
- **Pod-to-Pod TLS**: Secure communication between pipeline components
- **OAuth Integration**: Secure authentication via OpenShift OAuth

### Negative

- **Ecosystem Lock-in**: Tied to Red Hat's ML ecosystem and update cycles
- **Learning Curve**: Requires learning RHOAI/Kubeflow APIs and SDKs for custom pipeline steps
- **Limited Flexibility**: Less flexible than fully custom orchestration solutions
- **Version Dependencies**: Dependent on Red Hat's release schedule for new features
- **Resource Requirements**: DSPA requires MariaDB, artifact storage, and multiple services

## Alternatives Considered

### 1. Tekton Pipelines with Custom ML Tasks
**Pros**: Native to OpenShift, general-purpose CI/CD, flexible
**Cons**: Not ML-specific, requires building ML abstractions from scratch, no model registry integration
**Why Rejected**: Lacks ML-specific features like experiment tracking and model versioning

### 2. Kubeflow Pipelines (Upstream) Without Red Hat Support
**Pros**: Latest features, large community, ML-native, open source
**Cons**: No enterprise support, complex to deploy and maintain, may have breaking changes
**Why Rejected**: Production ML systems require enterprise support and stability

### 3. Apache Airflow for ML Orchestration
**Pros**: Mature, flexible, Python-native, large ecosystem
**Cons**: Not Kubernetes-native, requires separate deployment, complex DAG management
**Why Rejected**: Less integrated with Kubernetes ecosystem, team lacks Airflow expertise

### 4. Custom Python Orchestration with Kubernetes Jobs
**Pros**: Maximum flexibility, no new tools to learn, simple
**Cons**: Requires building orchestration from scratch, no UI, no experiment tracking, maintenance burden
**Why Rejected**: Reinventing the wheel, lacks production-grade features

## Implementation Notes

### Deployed Version
- **Red Hat OpenShift AI (rhods-operator)**: v2.22.2
- **DataSciencePipelinesApplication API**: datasciencepipelinesapplications.opendatahub.io/v1
- **Namespace**: rhods-notebooks (operator namespace)

### Current Status
- ✅ RHOAI operator installed and operational
- ✅ DataSciencePipelinesApplication CRD available
- ⚠️  distance-prediction namespace not created yet
- ⚠️  DSPA not deployed yet (ready for deployment)

### Planned Configuration (`pipeline-server/pipelines.yaml`):
- **Namespace**: `distance-prediction`
- **DSP Version**: v2
- **API Server**: Enabled with OAuth and caching
- **Database**: MariaDB with 10Gi PVC
- **Object Storage**: External S3 (Minio) with bucket `pipeline-artifacts`
- **Persistence Agent**: 2 workers for artifact collection
- **Scheduled Workflow**: Enabled with UTC timezone

Workbenches (deployed via Helm):
- **data-generation**: For generating training data
- **build-model**: For model training and registration

Notebooks:
- `initial_development.ipynb` - Initial model exploration
- `pipeline.ipynb` - Full automated pipeline
- `endpoint.ipynb` - Model serving endpoint testing
- `register_model.ipynb` - Model registration workflow

## References

- [Pipeline Server Configuration](/pipeline-server/pipelines.yaml)
- [Workbenches Helm Chart](/workbenches)
- [Data Generation Workbench](/data-generation)
- [Build Model Workbench](/build-model)
- [Red Hat OpenShift AI Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/)

