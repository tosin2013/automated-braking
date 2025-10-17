# S3 Storage Solution for Automated Braking

## ✅ Problem Solved: MinIO S3 Storage Added

### The Issue
The original Validated Patterns migration was configured to use **external S3 storage** but wasn't deploying it. This would cause DSPA (Data Science Pipelines) to fail because it couldn't store pipeline artifacts.

### The Solution
**Added MinIO Helm Chart** - S3-compatible object storage deployed as part of the pattern.

---

## 📦 What's Deployed

### MinIO Configuration

**Chart**: `charts/hub/minio/`  
**Purpose**: S3-compatible object storage for ML pipeline artifacts and models  
**Status**: ✅ Created and validated (`helm lint` passed)

**Components**:
- MinIO Server (S3 API on port 9000)
- MinIO Console (Web UI on port 9001)
- Persistent storage (20Gi PVC)
- OpenShift Routes (TLS-enabled)
- Pre-configured buckets:
  - `pipeline-artifacts` - For DSPA pipeline runs
  - `model-artifacts` - For trained models

**Resources**:
- CPU: 500m request, 1000m limit
- Memory: 512Mi request, 1Gi limit
- Storage: 20Gi persistent volume

---

## 🔗 Integration

### DSPA Connection

The Data Science Pipelines Application automatically connects to MinIO:

```yaml
objectStorage:
  externalStorage:
    bucket: pipeline-artifacts
    host: minio-s3.distance-prediction.svc.cluster.local  # Internal service
    # Or via route: minio-s3-distance-prediction.apps.<cluster-domain>
    scheme: https
    s3CredentialsSecret:
      secretName: aws-connection-pipeline-artifacts  # Auto-created by MinIO chart
```

**Credentials Secret**: `aws-connection-pipeline-artifacts`
- Automatically created by MinIO chart
- Contains AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
- Used by DSPA to authenticate to MinIO

---

## 🚀 Deployment Order

The pattern deploys in this sequence:

```
Sync Wave 0:
├── MySQL        ✅ Database for Model Registry
└── MinIO        ✅ S3 storage for pipelines (NEW!)

Sync Wave 1:
└── Model Registry  ✅ Connects to MySQL

Sync Wave 2:
└── DSPA  ✅ Connects to MinIO and MariaDB

Sync Wave 3:
└── Workbenches  ✅ Access to pipelines and storage
```

---

## 🔐 Security & Access

### Default Credentials (Change in Production!)

**Root User**: `minio`  
**Root Password**: `minio123`

⚠️ **IMPORTANT**: Update credentials in production!

**To change credentials**:

1. Edit `charts/hub/minio/values.yaml`:
```yaml
auth:
  rootUser: your-username
  rootPassword: your-secure-password
```

2. Or use `values-secret.yaml`:
```yaml
secrets:
  minio:
    rootUser: your-username
    rootPassword: your-secure-password
```

### Access Methods

**Internal (within cluster)**:
```
http://minio-s3.distance-prediction.svc.cluster.local:9000
```

**External (via OpenShift Route)**:
```
https://minio-s3-distance-prediction.apps.<cluster-domain>
```

**Console UI**:
```
https://minio-console-distance-prediction.apps.<cluster-domain>
```

---

## 🎯 Buckets

### Pre-configured Buckets

1. **pipeline-artifacts**
   - Purpose: Store DSPA pipeline run artifacts
   - Used by: Data Science Pipelines
   - Auto-created on deployment

2. **model-artifacts**
   - Purpose: Store trained ML models
   - Used by: Model training notebooks
   - Available for custom use

### Creating Additional Buckets

**Via Console UI**:
1. Access MinIO Console via route
2. Login with credentials
3. Create bucket via UI

**Via MinIO Client (mc)**:
```bash
# Install mc client
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc

# Configure alias
./mc alias set myminio https://minio-s3-distance-prediction.apps.<cluster-domain> minio minio123

# Create bucket
./mc mb myminio/my-new-bucket
```

---

## 🆚 MinIO vs ODF (OpenShift Data Foundation)

| Feature | MinIO (Our Choice) | ODF S3 |
|---------|-------------------|---------|
| **Deployment** | Simple Helm chart | Complex operator + noobaa |
| **Resources** | 1Gi RAM, 20Gi storage | 3+ nodes, 100Gi+ storage |
| **Setup Time** | 2 minutes | 30+ minutes |
| **Cost** | Minimal | Higher (cluster resources) |
| **Use Case** | Dev/Test, Small workloads | Production, Enterprise |
| **S3 Compatible** | ✅ Yes | ✅ Yes |

**Why MinIO?**
- ✅ Lightweight and fast
- ✅ Perfect for ML pipeline artifacts
- ✅ Easy to deploy via Helm
- ✅ S3-compatible API
- ✅ Can migrate to ODF later if needed

**When to use ODF instead?**
- Large-scale production (TB+ data)
- Need multi-tenancy
- Require advanced backup/replication
- Enterprise compliance requirements

---

## 📊 Storage Usage

### Expected Usage

**Pipeline Artifacts** (~1-5GB per run):
- Input datasets
- Intermediate processing files
- Logs and metrics
- Pipeline cache

**Model Artifacts** (~100MB-2GB per model):
- Trained model files
- Model metadata
- Training configuration
- Validation results

**Total**: 20Gi storage should handle:
- ~10-15 pipeline runs
- ~20-30 model versions
- Can be expanded as needed

### Expanding Storage

**Option 1: Increase PVC Size**
```bash
# Edit values
vim charts/hub/minio/values.yaml
# Change: size: 20Gi → size: 100Gi

# Redeploy
make -f common/Makefile upgrade
```

**Option 2: Migrate to ODF**
- Deploy OpenShift Data Foundation
- Update DSPA to point to ODF S3
- Migrate data from MinIO to ODF

---

## ✅ Validation

### Check MinIO Deployment

```bash
# Check pod
oc get pods -n distance-prediction | grep minio

# Check service
oc get service minio-s3 -n distance-prediction

# Check routes
oc get route -n distance-prediction | grep minio

# Check PVC
oc get pvc minio-pvc -n distance-prediction

# Check credentials secret
oc get secret aws-connection-pipeline-artifacts -n distance-prediction
```

### Test S3 Connectivity

```bash
# From within cluster
oc run -it --rm s3-test --image=amazon/aws-cli --restart=Never -- \
  s3 --endpoint-url=http://minio-s3.distance-prediction.svc.cluster.local:9000 \
  ls s3://pipeline-artifacts
```

### Access Console

```bash
# Get console URL
oc get route minio-console -n distance-prediction -o jsonpath='{.spec.host}'

# Open in browser
# Login: minio / minio123
```

---

## 🔄 Migration Path to ODF

If you later need ODF for production:

### Phase 1: Deploy ODF
```bash
# Install ODF operator
# Create StorageSystem
# Deploy NooBaa for S3
```

### Phase 2: Update Pattern
```yaml
# values-hub.yaml - disable MinIO
applications:
  minio:
    enabled: false

# Update DSPA to use ODF
objectStorage:
  externalStorage:
    host: s3.openshift-storage.svc.cluster.local
```

### Phase 3: Migrate Data
```bash
# Use rclone or mc to sync
mc mirror myminio/pipeline-artifacts odf/pipeline-artifacts
```

---

## 📝 Summary

| Aspect | Value |
|--------|-------|
| **Solution** | MinIO S3-compatible storage |
| **Deployment** | Helm chart in VP pattern |
| **Storage** | 20Gi PVC (expandable) |
| **Buckets** | pipeline-artifacts, model-artifacts |
| **Integration** | Auto-configured with DSPA |
| **Access** | Internal service + OpenShift routes |
| **Status** | ✅ Ready to deploy |

---

## 🚀 Ready to Deploy

MinIO is now part of the Validated Patterns deployment:

```bash
# Deploy entire pattern (includes MinIO)
make -f common/Makefile install

# Verify MinIO deployed
oc get pods -n distance-prediction | grep minio

# Access console
echo "https://$(oc get route minio-console -n distance-prediction -o jsonpath='{.spec.host}')"
```

**MinIO will deploy automatically with sync-wave 0 (alongside MySQL)**

---

**Created**: 2025-10-17  
**Chart Location**: `charts/hub/minio/`  
**Updated**: `values-hub.yaml` to include MinIO application


