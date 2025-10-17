# Architectural Decision Records (ADRs)

This directory contains Architectural Decision Records (ADRs) for the Automated Braking ML System.

## What are ADRs?

An Architectural Decision Record (ADR) captures an important architectural decision made along with its context and consequences. ADRs help teams understand why systems are built the way they are and provide historical context for future changes.

## Format

We use the [Nygard format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) for ADRs, which includes:

- **Title**: Short noun phrase describing the decision
- **Status**: Proposed, Accepted, Deprecated, or Superseded
- **Context**: Forces at play (technical, political, social, project)
- **Decision**: The architectural decision and its justification
- **Consequences**: Positive and negative outcomes of the decision

## Index of ADRs

### Infrastructure & Platform

- [ADR-0001: Platform Selection - Kubernetes on OpenShift](0001-platform-selection-kubernetes-on-openshift.md)
  - **Status**: Accepted
  - **Summary**: Standardize on Red Hat OpenShift for all environments
  - **Impact**: Critical - defines entire infrastructure foundation

- [ADR-0002: GitOps-Based Deployment with Argo CD](0002-gitops-deployment-with-argocd.md)
  - **Status**: Accepted
  - **Summary**: Adopt Argo CD as exclusive GitOps engine for all deployments
  - **Impact**: High - defines deployment methodology and workflows

### Machine Learning Infrastructure

- [ADR-0003: ML Pipeline Orchestration with Red Hat OpenShift AI](0003-ml-pipeline-orchestration-rhoai.md)
  - **Status**: Accepted
  - **Summary**: Use RHOAI Data Science Pipelines for ML workflow orchestration
  - **Impact**: High - defines ML development and training workflows

- [ADR-0005: Model Registry Architecture and Integration](0005-model-registry-architecture.md)
  - **Status**: Accepted
  - **Summary**: Use RHOAI Model Registry for centralized model governance
  - **Impact**: High - defines model lifecycle management

### Data & Storage

- [ADR-0004: Database Strategy - MySQL, PostgreSQL, and MariaDB Usage](0004-database-strategy-mysql-postgres-mariadb.md)
  - **Status**: Accepted
  - **Summary**: Multi-database strategy with specific purposes for each technology
  - **Impact**: Medium - defines data persistence strategy

### Deployment Framework

- [ADR-0006: Adopt OpenShift Validated Patterns Framework](0006-validated-patterns-framework.md)
  - **Status**: Proposed
  - **Summary**: Adopt Red Hat's Validated Patterns framework for standardized GitOps deployment
  - **Impact**: High - restructures entire deployment architecture
  - **Enhances**: ADR-0002 (GitOps)

## ADR Lifecycle

1. **Proposed**: Decision is under discussion
2. **Accepted**: Decision has been agreed upon and is being implemented
3. **Deprecated**: Decision is no longer recommended but still in use
4. **Superseded**: Decision has been replaced by a newer ADR

## Creating New ADRs

When creating a new ADR:

1. Copy the template from an existing ADR
2. Number it sequentially (e.g., `0006-your-decision-title.md`)
3. Fill in all sections with complete information
4. Include alternatives considered and why they were rejected
5. Document consequences (both positive and negative)
6. Update this README index
7. Submit for review before marking as "Accepted"

## Review Process

1. Author creates ADR as "Proposed"
2. Share with relevant stakeholders (DevOps, ML Engineering, Security)
3. Gather feedback and iterate on the ADR
4. Architecture review meeting to discuss
5. Mark as "Accepted" once consensus is reached
6. Implement the decision
7. Update ADR with implementation notes as needed

## Tools & Automation

This project uses the **MCP ADR Analysis Server** for:
- Automated ADR suggestion based on codebase analysis
- ADR validation and compliance checking
- Bootstrap validation to ensure deployed code follows ADR requirements
- Research-driven architectural recommendations

## References

- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) by Michael Nygard
- [ADR GitHub Organization](https://adr.github.io/)
- [MCP ADR Analysis Server Documentation](../.mcp-server-context.md)

## Statistics

- **Total ADRs**: 6
- **Accepted**: 5
- **Proposed**: 1 (ADR-0006: Validated Patterns Framework)
- **Deprecated**: 0
- **Superseded**: 0

Last Updated: 2025-10-17


## ADR-0007: MinIO S3 Storage External Exposure Strategy

**Status**: Accepted | **Date**: 2025-10-17

Defines the strategy for exposing MinIO S3 storage externally via OpenShift Routes while maintaining security and Validated Patterns alignment.

**Key Decisions**:
- Dual-endpoint exposure: Internal Service + External Routes
- Both S3 API and Console accessible via TLS-terminated Routes
- MinIO console served from S3 API endpoint (/minio/ui/*)
- Routes properly configured to reference service ports by name
- TLS edge termination automatic via OpenShift

**Linked Components**:
- Service: `charts/hub/minio/templates/service.yaml` (ports: s3=9000, console=9001)
- Routes: `charts/hub/minio/templates/route.yaml` (both use s3 targetPort)

**References**: [Full Decision Record](0007-minio-s3-external-exposure-strategy.md)

