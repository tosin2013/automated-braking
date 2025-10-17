# Documentation

Welcome to the Automated Braking ML System documentation!

## 📚 Quick Links

### Getting Started
- **[Deployment Guide](deployment-guide.md)** - How to deploy with Validated Patterns
- **[Storage Architecture](storage-architecture.md)** - MinIO S3 storage explained
- **[Security Guide](security-guide.md)** - Security best practices

### Architecture
- **[ADRs](adrs/)** - Architectural Decision Records
  - [Platform Selection](adrs/0001-platform-selection-kubernetes-on-openshift.md)
  - [GitOps with ArgoCD](adrs/0002-gitops-deployment-with-argocd.md)
  - [ML Pipeline Orchestration](adrs/0003-ml-pipeline-orchestration-rhoai.md)
  - [Database Strategy](adrs/0004-database-strategy-mysql-postgres-mariadb.md)
  - [Model Registry](adrs/0005-model-registry-architecture.md)
  - [Validated Patterns Framework](adrs/0006-validated-patterns-framework.md)

### Contributing
- **[Contributing Guide](contributing/CONTRIBUTING.md)** - How to contribute
- **[Organization Rules](contributing/organization.md)** - File organization guidelines

---

## 🎯 Where to Start

**New to the project?** → Start with the main [README](../README.md)

**Ready to deploy?** → Follow the [Deployment Guide](deployment-guide.md)

**Want to understand the architecture?** → Read the [ADRs](adrs/)

**Need to troubleshoot storage?** → Check [Storage Architecture](storage-architecture.md)

**Security concerns?** → Review the [Security Guide](security-guide.md)

---

## 📖 Documentation Structure

```
docs/
├── README.md                   This file
├── deployment-guide.md         Quick start deployment
├── storage-architecture.md     S3/MinIO documentation
├── security-guide.md           Security practices
├── adrs/                       Architecture decisions
│   ├── README.md
│   └── 000X-*.md
└── contributing/               Contribution guidelines
    ├── CONTRIBUTING.md
    └── organization.md
```

---

## 🔍 Finding Information

| What You Need | Where to Look |
|---------------|---------------|
| Deploy the system | [deployment-guide.md](deployment-guide.md) |
| Architecture decisions | [adrs/](adrs/) |
| Storage/S3 info | [storage-architecture.md](storage-architecture.md) |
| Security setup | [security-guide.md](security-guide.md) |
| How to contribute | [contributing/CONTRIBUTING.md](contributing/CONTRIBUTING.md) |
| File organization | [contributing/organization.md](contributing/organization.md) |

---

**Last Updated**: 2025-10-17

