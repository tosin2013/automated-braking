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
# Note: Routes use the cluster's ingress domain (NOT .local domain)
oc get routes -n distance-prediction | grep minio
# minio-s3          minio-s3-distance-prediction.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com    edge/Redirect
# minio-console     minio-console-distance-prediction.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com    edge/Redirect

# IMPORTANT: Domain Naming Convention
# OpenShift routes use: <route-name>-<namespace>.apps.<ingress-domain>
# Example ingress domain: cluster-fzqdg.fzqdg.sandbox3272.opentlc.com
# Full URL: https://minio-console-distance-prediction.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com
#
# NOTE: "cluster.local" is an internal Kubernetes DNS alias
# For external access, always use the full ingress domain (ends with .opentlc.com, .com, etc.)

# Test external connectivity (use actual ingress domain)
INGRESS_DOMAIN=$(oc get ingresscontroller -n openshift-ingress-operator -o jsonpath='{.items[0].status.domain}')
curl -kvvv https://minio-console-distance-prediction.apps.${INGRESS_DOMAIN}
# Should show 200 OK or MinIO HTML response

# Access the console in browser
https://minio-console-distance-prediction.apps.${INGRESS_DOMAIN}
# Login with: minio / minio123
```

### Access Points (Production Example)

```
Internal In-Cluster Access:
  S3 API: minio.distance-prediction.svc.cluster.local:9000
  S3 API: minio.distance-prediction.svc:9000

External Access via Route (Actual FQDN):
  Console: https://minio-console-distance-prediction.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com
  S3 API: https://minio-s3-distance-prediction.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com

Credentials:
  Username: minio
  Password: minio123
```

## Implementation

### Service Template: `charts/hub/minio/templates/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: {{ .Values.namespace | default "distance-prediction" }}
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
{{- if .Values.enabled }}
{{- if .Values.route.enabled }}
---
# S3 API Route
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: minio-s3
  namespace: {{ .Values.namespace | default "distance-prediction" }}
spec:
  # Route URL will be: minio-s3-<namespace>.apps.<ingress-domain>
  # Example: minio-s3-distance-prediction.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com
  port:
    targetPort: s3        # References service port name
  to:
    kind: Service
    name: minio
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
---
# Console Route (MinIO console served from S3 API endpoint)
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: minio-console
  namespace: {{ .Values.namespace | default "distance-prediction" }}
spec:
  # Route URL will be: minio-console-<namespace>.apps.<ingress-domain>
  # Example: minio-console-distance-prediction.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com
  port:
    targetPort: s3  # Console served from S3 API (port 9000)
  to:
    kind: Service
    name: minio
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
{{- end }}
{{- end }}
```

## Domain Naming in OpenShift Routes

### Key Concepts

1. **Route Name Format**:
   - Route name: `minio-console`
   - Namespace: `distance-prediction`
   - Route URL: `minio-console-distance-prediction.apps.<ingress-domain>`

2. **Ingress Domain** (discovered from cluster):
   ```bash
   oc get ingresscontroller -n openshift-ingress-operator -o jsonpath='{.items[0].status.domain}'
   # Output: cluster-fzqdg.fzqdg.sandbox3272.opentlc.com
   ```

3. **DNS Resolution**:
   - `.local` domains (e.g., `minio-console-distance-prediction.apps.cluster.local`): Internal Kubernetes DNS
   - `.opentlc.com` or public domains: External OpenShift ingress controller
   - External access requires the full ingress domain

4. **TLS Certificates**:
   - OpenShift generates wildcard certificates for `*.apps.<ingress-domain>`
   - All routes under this domain automatically get valid HTTPS certificates
   - Example: `*.apps.cluster-fzqdg.fzqdg.sandbox3272.opentlc.com`

### Testing URL Accessibility

```bash
# Get ingress domain
INGRESS_DOMAIN=$(oc get ingresscontroller -n openshift-ingress-operator -o jsonpath='{.items[0].status.domain}')

# Verify external access
curl -k https://minio-console-distance-prediction.apps.${INGRESS_DOMAIN}
# Should respond with 200 or MinIO HTML

# Check certificate validity
curl -v https://minio-console-distance-prediction.apps.${INGRESS_DOMAIN} 2>&1 | grep -E "subject:|CN="
# Should show valid OpenShift wildcard certificate
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
