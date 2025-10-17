#!/bin/bash
#
# Validation Script for Automated Braking ML System
# Verifies deployed infrastructure matches ADR requirements
#
# References:
# - ADR-0001: OpenShift Platform
# - ADR-0002: GitOps with ArgoCD
# - ADR-0003: RHOAI ML Pipelines
# - ADR-0004: Database Strategy
# - ADR-0005: Model Registry

set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE_DISTANCE="distance-prediction"
NAMESPACE_MODEL_REGISTRY="rhoai-model-registries"
NAMESPACE_GITOPS="openshift-gitops"

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_fail() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# ADR-0001: Validate OpenShift Platform
validate_adr_0001() {
    log_section "ADR-0001: Platform Selection - OpenShift"
    
    # Check OpenShift version
    local server_version=$(oc version -o json 2>/dev/null | grep -o '"gitVersion":"v[^"]*"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
    if [ -n "$server_version" ]; then
        log_success "OpenShift cluster accessible (version: $server_version)"
    else
        log_fail "Cannot retrieve OpenShift version"
        return
    fi
    
    # Check container runtime (should be CRI-O)
    local runtime=$(oc get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}' 2>/dev/null)
    if echo "$runtime" | grep -q "cri-o"; then
        log_success "Container runtime: $runtime (CRI-O as per ADR)"
    else
        log_warning "Container runtime: $runtime (Expected CRI-O)"
    fi
    
    # Check OS (should be Red Hat Enterprise Linux CoreOS)
    local os=$(oc get nodes -o jsonpath='{.items[0].status.nodeInfo.osImage}' 2>/dev/null)
    if echo "$os" | grep -q "Red Hat Enterprise Linux CoreOS"; then
        log_success "Operating System: $os"
    else
        log_warning "Operating System: $os (Expected RHEL CoreOS)"
    fi
    
    # Check node count
    local node_count=$(oc get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$node_count" -ge 3 ]; then
        log_success "Cluster has $node_count nodes (production-ready)"
    elif [ "$node_count" -ge 1 ]; then
        log_warning "Cluster has $node_count nodes (consider adding more for HA)"
    else
        log_fail "Cannot determine node count"
    fi
}

# ADR-0002: Validate GitOps with ArgoCD
validate_adr_0002() {
    log_section "ADR-0002: GitOps-Based Deployment with Argo CD"
    
    # Check OpenShift GitOps operator
    if oc get csv -n openshift-gitops-operator 2>/dev/null | grep -q "openshift-gitops-operator.*Succeeded"; then
        local version=$(oc get csv -n openshift-gitops-operator | grep openshift-gitops-operator | awk '{print $1}')
        log_success "OpenShift GitOps operator installed: $version"
    else
        log_fail "OpenShift GitOps operator not installed or not healthy"
    fi
    
    # Check ArgoCD server deployment
    if oc get deployment openshift-gitops-server -n "$NAMESPACE_GITOPS" >/dev/null 2>&1; then
        local replicas=$(oc get deployment openshift-gitops-server -n "$NAMESPACE_GITOPS" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
        if [ "$replicas" -ge 1 ]; then
            log_success "ArgoCD server deployment healthy (replicas: $replicas)"
        else
            log_fail "ArgoCD server deployment not available"
        fi
    else
        log_fail "ArgoCD server deployment not found"
    fi
    
    # Check ArgoCD applications
    local app_count=$(oc get applications -n "$NAMESPACE_GITOPS" --no-headers 2>/dev/null | wc -l)
    if [ "$app_count" -ge 1 ]; then
        log_success "ArgoCD applications deployed: $app_count"
        
        # Check sync status
        oc get applications -n "$NAMESPACE_GITOPS" --no-headers 2>/dev/null | while read -r line; do
            local app_name=$(echo "$line" | awk '{print $1}')
            local sync_status=$(echo "$line" | awk '{print $2}')
            local health_status=$(echo "$line" | awk '{print $3}')
            
            if [ "$sync_status" = "Synced" ] && [ "$health_status" = "Healthy" ]; then
                log_success "Application $app_name: Synced and Healthy"
            else
                log_warning "Application $app_name: $sync_status / $health_status"
            fi
        done
    else
        log_warning "No ArgoCD applications deployed yet"
    fi
}

# ADR-0003: Validate RHOAI ML Pipelines
validate_adr_0003() {
    log_section "ADR-0003: ML Pipeline Orchestration with RHOAI"
    
    # Check RHOAI operator
    if oc get csv -A 2>/dev/null | grep -q "rhods-operator.*Succeeded"; then
        local version=$(oc get csv -A | grep rhods-operator | head -1 | awk '{print $2}')
        log_success "Red Hat OpenShift AI operator installed: $version"
    else
        log_fail "Red Hat OpenShift AI operator not installed or not healthy"
    fi
    
    # Check DataSciencePipelinesApplication CRD
    if oc get crd datasciencepipelinesapplications.opendatahub.io >/dev/null 2>&1; then
        log_success "DataSciencePipelinesApplication CRD available"
    else
        log_fail "DataSciencePipelinesApplication CRD not found"
    fi
    
    # Check DSPA instance
    if oc get dspa -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        local dspa_count=$(oc get dspa -n "$NAMESPACE_DISTANCE" --no-headers 2>/dev/null | wc -l)
        log_success "DSPA instances deployed: $dspa_count"
        
        # Check DSPA components
        if oc get deployment ds-pipeline-dspa -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
            log_success "DSPA API server deployment exists"
        else
            log_warning "DSPA API server deployment not found (may still be creating)"
        fi
    else
        log_warning "No DSPA instance found in $NAMESPACE_DISTANCE"
    fi
    
    # Check workbenches
    if oc get notebooks -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        local notebook_count=$(oc get notebooks -n "$NAMESPACE_DISTANCE" --no-headers 2>/dev/null | wc -l)
        if [ "$notebook_count" -ge 1 ]; then
            log_success "Jupyter workbenches deployed: $notebook_count"
        else
            log_warning "No Jupyter workbenches found"
        fi
    else
        log_warning "No Jupyter workbenches found (notebooks CRD may not be available)"
    fi
}

# ADR-0004: Validate Database Strategy
validate_adr_0004() {
    log_section "ADR-0004: Database Strategy"
    
    # Check MySQL deployment (for Model Registry)
    if oc get deployment mysql -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        local replicas=$(oc get deployment mysql -n "$NAMESPACE_DISTANCE" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
        if [ "$replicas" -ge 1 ]; then
            log_success "MySQL deployment healthy (for Model Registry)"
            
            # Check MySQL version
            local mysql_version=$(oc get deployment mysql -n "$NAMESPACE_DISTANCE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
            log_info "  MySQL image: $mysql_version"
        else
            log_fail "MySQL deployment not available"
        fi
    else
        log_warning "MySQL deployment not found"
    fi
    
    # Check MySQL PVC
    if oc get pvc mysql-data -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        local pvc_status=$(oc get pvc mysql-data -n "$NAMESPACE_DISTANCE" -o jsonpath='{.status.phase}' 2>/dev/null)
        if [ "$pvc_status" = "Bound" ]; then
            log_success "MySQL PVC bound and available"
        else
            log_fail "MySQL PVC status: $pvc_status"
        fi
    else
        log_warning "MySQL PVC not found"
    fi
    
    # Check MariaDB (DSPA-managed)
    if oc get deployment mariadb-dspa -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        log_success "MariaDB deployment exists (DSPA-managed)"
    else
        log_warning "MariaDB deployment not found (DSPA may not be fully deployed)"
    fi
    
    # Check PostgreSQL deployment
    if oc get deployment postgres -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        log_success "PostgreSQL deployment exists"
    else
        log_warning "PostgreSQL deployment not found (may not be deployed yet)"
    fi
    
    # Check database credentials secrets
    if oc get secret distance-prediction-db -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        log_success "Database credentials secret exists"
    else
        log_warning "Database credentials secret not found"
    fi
}

# ADR-0005: Validate Model Registry
validate_adr_0005() {
    log_section "ADR-0005: Model Registry Architecture"
    
    # Check ModelRegistry CRD
    if oc get crd modelregistries.components.platform.opendatahub.io >/dev/null 2>&1; then
        log_success "ModelRegistry CRD available"
    else
        log_fail "ModelRegistry CRD not found"
    fi
    
    # Check KServe CRDs
    if oc get crd trainedmodels.serving.kserve.io >/dev/null 2>&1; then
        log_success "KServe TrainedModel CRD available"
    else
        log_warning "KServe TrainedModel CRD not found"
    fi
    
    # Check Model Registry namespace
    if oc get namespace "$NAMESPACE_MODEL_REGISTRY" >/dev/null 2>&1; then
        log_success "Model Registry namespace exists: $NAMESPACE_MODEL_REGISTRY"
    else
        log_warning "Model Registry namespace not found: $NAMESPACE_MODEL_REGISTRY"
    fi
    
    # Check Model Registry instance
    if oc get modelregistry -n "$NAMESPACE_MODEL_REGISTRY" >/dev/null 2>&1; then
        local registry_count=$(oc get modelregistry -n "$NAMESPACE_MODEL_REGISTRY" --no-headers 2>/dev/null | wc -l)
        log_success "Model Registry instances: $registry_count"
    else
        log_warning "No Model Registry instances found"
    fi
    
    # Check Model Registry service
    if oc get service distance-prediction -n "$NAMESPACE_MODEL_REGISTRY" >/dev/null 2>&1; then
        log_success "Model Registry service exists"
        
        # Check if service has endpoints
        local endpoints=$(oc get endpoints distance-prediction -n "$NAMESPACE_MODEL_REGISTRY" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
        if [ -n "$endpoints" ]; then
            log_success "Model Registry service has endpoints"
        else
            log_warning "Model Registry service has no endpoints yet"
        fi
    else
        log_warning "Model Registry service not found"
    fi
}

# Check S3 Storage Configuration
validate_s3_storage() {
    log_section "S3 Storage Configuration"
    
    # Check S3 credentials secret
    if oc get secret aws-connection-pipeline-artifacts -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        log_success "S3 credentials secret exists"
    else
        log_warning "S3 credentials secret not found"
    fi
    
    # Check if Minio is deployed
    if oc get deployment minio -n "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        log_success "Minio deployment exists"
    else
        log_info "External S3 storage expected (Minio not deployed locally)"
    fi
}

# Check Overall Namespace Health
validate_namespace_health() {
    log_section "Namespace Health"
    
    # Check distance-prediction namespace
    if oc get namespace "$NAMESPACE_DISTANCE" >/dev/null 2>&1; then
        log_success "Namespace exists: $NAMESPACE_DISTANCE"
        
        # Count deployments
        local deploy_count=$(oc get deployments -n "$NAMESPACE_DISTANCE" --no-headers 2>/dev/null | wc -l)
        log_info "  Deployments: $deploy_count"
        
        # Count pods
        local pod_count=$(oc get pods -n "$NAMESPACE_DISTANCE" --no-headers 2>/dev/null | wc -l)
        local running_pods=$(oc get pods -n "$NAMESPACE_DISTANCE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
        log_info "  Pods: $running_pods/$pod_count running"
        
        # Check for failed pods
        local failed_pods=$(oc get pods -n "$NAMESPACE_DISTANCE" --field-selector=status.phase=Failed --no-headers 2>/dev/null | wc -l)
        if [ "$failed_pods" -gt 0 ]; then
            log_warning "  Failed pods: $failed_pods"
        fi
    else
        log_fail "Namespace not found: $NAMESPACE_DISTANCE"
    fi
}

# Generate validation report
generate_report() {
    log_section "Validation Summary"
    
    echo ""
    echo -e "${CYAN}Total Checks: $TOTAL_CHECKS${NC}"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo ""
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    if [ "$FAILED_CHECKS" -eq 0 ]; then
        echo -e "${GREEN}✓ All critical validations passed!${NC}"
        if [ "$WARNING_CHECKS" -gt 0 ]; then
            echo -e "${YELLOW}⚠ Review warnings above for optimization opportunities${NC}"
        fi
        return 0
    elif [ "$success_rate" -ge 70 ]; then
        echo -e "${YELLOW}⚠ Partial deployment detected (${success_rate}% success)${NC}"
        echo -e "${YELLOW}  Review failed checks and complete deployment${NC}"
        return 1
    else
        echo -e "${RED}✗ Deployment validation failed (${success_rate}% success)${NC}"
        echo -e "${RED}  Review errors above and run bootstrap.sh${NC}"
        return 2
    fi
}

# Main validation workflow
main() {
    echo "================================================"
    echo "Automated Braking ML System - Bootstrap Validation"
    echo "================================================"
    echo ""
    log_info "Validating deployed infrastructure against ADRs..."
    
    # Run all validation checks
    validate_adr_0001
    validate_adr_0002
    validate_adr_0003
    validate_adr_0004
    validate_adr_0005
    validate_s3_storage
    validate_namespace_health
    
    # Generate report
    generate_report
}

# Run main function
main "$@"


