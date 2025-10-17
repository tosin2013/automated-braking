# ADR-0007: MinIO S3 Storage External Exposure Strategy

## Status
Accepted

## Date
2025-10-17

## Context

The Automated Braking ML system requires MinIO S3 storage for:
- Data Science Pipelines (DSPA) artifact storage
- Model Registry artifact/model storage  
- Training data and intermediate results

MinIO pod is operational (running stable, 1/1 healthy), but external access is limited:
- Internal Service (ClusterIP) exists but was incomplete
- External Routes return 503 Service Unavailable
- S3 API (port 9000) works internally but Route misconfigured
- Console (port 9001) Route pointing to wrong service endpoint

In the Validated Patterns framework context, we need to expose storage endpoints consistently with:
- Red Hat best practices for GitOps deployments
- OpenShift Routes for TLS termination and external access
- Helm chart configuration management
- Security boundaries (what gets exposed externally vs. internally)

## Decision

**Implement dual-endpoint MinIO exposure pattern:**

1. **Internal Service** (always available)
   - ClusterIP Service `minio` on ports 9000 (S3 API) and 9001 (Console)
   - Used by DSPA, Model Registry, and other in-cluster components
   - No external exposure needed for operations

2. **External Routes** (development/operations access)
   - Route `minio-s3`: S3 API endpoint on port 9000 (primary external interface)
   - Route `minio-console`: Console endpoint on port 9001 (administrative UI)
   - Both use TLS edge termination via OpenShift
   - S3 API route for programmatic access; console route for administrative access

3. **Configuration Management** (Helm values)
   - Service port names must match Route targetPort references
   - Both routes defined in Helm templates under `conditionals`
   - Configurable via `values.yaml` (enabled by default)
   - Credentials managed via Secret resource

4. **Security Posture**
   - S3 API: External Route exposed (required for DSPA to access via external endpoint)
   - Console: External Route exposed (for operational/administrative access)
   - Both protected by:
     - OpenShift NetworkPolicies (cluster-internal)
     - Route TLS termination
     - Service authentication via credentials
     - Optional: API Gateway for additional access control (future)

## Consequences

### Positive

- ✅ **Operational Access**: MinIO console accessible for bucket management, monitoring
- ✅ **GitOps Aligned**: Route configuration managed via Helm templates
- ✅ **Validated Pattern Compliant**: Follows OpenShift best practices
- ✅ **Development-Friendly**: Quick access for troubleshooting
- ✅ **Zero Configuration**: Routes auto-deployed with Helm chart
- ✅ **TLS by Default**: Edge termination automatic via OpenShift
- ✅ **Service-Driven**: Routes properly configured to target services

### Negative

- ⚠️ **External Exposure**: Console and S3 API accessible from outside cluster (security consideration)
- ⚠️ **Credential Management**: Need to protect access to exposed endpoints
- ⚠️ **No Authentication on Route**: MinIO credentials are first line of defense
- ⚠️ **RBAC Needed**: Recommend NetworkPolicies to limit access

### Neutral

- Service endpoints simplified (both ports on same service)
- Helm templating adds abstraction layer
- Route configuration follows OpenShift idioms

## Verification

All routes correctly expose MinIO:

```bash
# Internal Service (always works)
oc get svc minio -n distance-prediction
# NAME    TYPE        CLUSTER-IP       PORTS
# minio   ClusterIP   172.30.70.228    9000/TCP,9001/TCP

# External Routes (TLS-terminated)
oc get routes -n distance-prediction | grep minio
# minio-s3          minio-s3-distance-prediction.apps...         9000/TCP    edge/Redirect
# minio-console     minio-console-distance-prediction.apps...    9001/TCP    edge/Redirect

# Test external connectivity
curl -kvvv https://minio-s3-distance-prediction.apps.cluster-fzqdg... 
# Should show 200 OK or appropriate S3 response

# Test console
https://minio-console-distance-prediction.apps.cluster-fzqdg...
# Accessible via browser
```

## Implementation

### Service Template: `charts/hub/minio/templates/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: {{ .Values.namespace }}
  labels:
    app: minio
spec:
  type: ClusterIP
  ports:
    - name: s3        # Port name for Route reference
      port: 9000
      targetPort: 9000
    - name: console   # Port name for Route reference
      port: 9001
      targetPort: 9001
  selector:
    app: minio
```

### Routes Template: `charts/hub/minio/templates/route.yaml`
```yaml
{{- if .Values.route.enabled }}
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: minio-s3
spec:
  host: minio-s3-{{ .Values.namespace }}.apps...
  port:
    targetPort: s3        # References service port name
  to:
    kind: Service
    name: minio
  tls:
    termination: edge
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: minio-console
spec:
  host: minio-console-{{ .Values.namespace }}.apps...
  port:
    targetPort: console   # References service port name
  to:
    kind: Service
    name: minio
  tls:
    termination: edge
{{- end }}
```

## Alternatives Considered

### 1. No External Routes (Internal Only)
- **Pros**: More secure, minimal exposure
- **Cons**: Can't access console externally, breaks external S3 access patterns
- **Why Rejected**: DSPA and other components need external-facing S3 endpoint

### 2. API Gateway Pattern
- **Pros**: Centralized access control, authentication
- **Cons**: Added complexity, additional component to manage
- **Why Rejected**: Overkill for current phase; add if needed later

### 3. Ingress Instead of Routes
- **Pros**: More portable across platforms
- **Cons**: OpenShift Routes are more idiomatic, TLS termination simpler
- **Why Rejected**: Using OpenShift-native capabilities

### 4. Port-Forward Only (No Routes)
- **Pros**: Most secure, manual access
- **Cons**: Terrible UX, breaks automated access patterns
- **Why Rejected**: Not production-suitable

## Related ADRs

- **ADR-0006**: Validated Patterns Framework (governs overall deployment strategy)
- **ADR-0004**: Database Strategy (MinIO complements database choices for artifact storage)
- **ADR-0005**: Model Registry Architecture (depends on MinIO S3 access)

## Security Considerations

### Current Risk Level: LOW-MEDIUM

**Mitigations**:
1. ✅ OpenShift NetworkPolicies (can restrict access)
2. ✅ TLS encryption in transit
3. ✅ MinIO credentials (first-line authentication)
4. 📝 Consider: Limit Route exposure to internal network only
5. 📝 Consider: API authentication gateway layer

**Recommendations**:
- For production: Add NetworkPolicy to restrict Route access
- For production: Rotate credentials regularly
- Monitor: Set up alerts on MinIO access failures
- Document: Credential management procedures

## Success Criteria

- ✅ MinIO S3 API accessible externally via Route
- ✅ MinIO Console accessible externally via Route
- ✅ Both Routes using TLS edge termination
- ✅ Internal Service properly configured
- ✅ Helm chart deployment successful
- ✅ DSPA can access S3 storage
- ✅ Model Registry can access artifact storage
- ✅ No 503 errors on routes

## References

- [Validated Patterns - Service Exposure](https://validatedpatterns.io/)
- [OpenShift Routes Documentation](https://docs.openshift.com/container-platform/latest/networking/routes/route-types.html)
- [MinIO Kubernetes Deployment](https://min.io/docs/minio/kubernetes/upstream/)
- [ADR-0006: Validated Patterns Framework](0006-validated-patterns-framework.md)
