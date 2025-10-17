# Automated Braking - Validated Patterns Deployment

🎉 **Migration Complete!** This project now uses the [OpenShift Validated Patterns](https://validatedpatterns.io/) framework.

## Quick Start

### 1. Configure Secrets (Required)

```bash
# Copy template
mkdir -p ~/.config/validatedpatterns
cp values-secret.yaml.template ~/.config/validatedpatterns/values-secret-automated-braking.yaml

# Edit with your credentials
vim ~/.config/validatedpatterns/values-secret-automated-braking.yaml

# Update these values:
# - database.mysql.root_password
# - database.mysql.user_password
# - s3.access_key
# - s3.secret_key
```

### 2. Deploy Pattern

```bash
# Deploy entire pattern
make -f common/Makefile install

# Monitor deployment
watch oc get applications -n openshift-gitops
```

### 3. Verify Deployment

```bash
# Check application sync status
oc get applications -n openshift-gitops

# Check pods
oc get pods -n distance-prediction

# Run validation
./validate_bootstrap.sh
```

## Architecture

This pattern deploys:

1. **MySQL 8.3.0** - Model Registry backend
2. **RHOAI Model Registry** - ML model governance
3. **Data Science Pipelines (DSPA)** - ML workflow orchestration
4. **Jupyter Workbenches** - ML development environments
   - data-generation: Generate training data
   - build-model: Train and register models

## Pattern Structure

```
automated-braking/
├── common/                    # VP Framework (submodule)
├── charts/hub/               # Helm charts
│   ├── mysql/
│   ├── model-registry/
│   ├── pipelines/
│   └── workbenches/
├── values-global.yaml        # Pattern config
├── values-hub.yaml           # Applications
└── pattern-metadata.yaml     # Metadata
```

## Management Commands

```bash
# Status
make -f common/Makefile status
./pattern.sh status

# Update
make -f common/Makefile upgrade

# Uninstall
make -f common/Makefile uninstall
```

## Documentation

- **Migration Complete**: [MIGRATION_COMPLETE.md](MIGRATION_COMPLETE.md)
- **ADRs**: [docs/adrs/](docs/adrs/)
- **Validated Patterns**: [https://validatedpatterns.io/](https://validatedpatterns.io/)

## Support

- **Issues**: [GitHub Issues](https://github.com/tosin2013/automated-braking/issues)
- **Validated Patterns**: [#validated-patterns on Slack](https://kubernetes.slack.com/archives/C02TYNJ8J0G)

---

**Framework**: OpenShift Validated Patterns  
**Pattern Version**: 1.0.0  
**Last Updated**: 2025-10-17


