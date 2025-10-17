# File Organization Rules

## 🎯 The Golden Rule

**PRODUCT vs PROCESS**:
- **PRODUCT** documentation (how to use) → Root directory → Committed
- **PROCESS** documentation (how we built) → dev-notes/ → Not committed

---

## ✅ Commit to GitHub (Root Directory)

### User-Facing Documentation
Files that help users **deploy and use** the system:
- `README.md` - Main documentation
- `README_VALIDATED_PATTERNS.md` - Deployment guide
- `SECURITY.md` - Security practices
- `S3_STORAGE_SOLUTION.md` - Architecture docs
- `LICENSE` - Project license

### Configuration Files
Required for the pattern to work:
- `values-global.yaml`
- `values-hub.yaml`
- `values-secret.yaml.template` (template only!)
- `pattern-metadata.yaml`

### Production Code
- `charts/` - Helm charts
- `docs/adrs/` - Architecture Decision Records
- `validate_bootstrap.sh` - Validation script
- Symlinks: `Makefile.vp`, `pattern.sh`

---

## 🔒 Keep Local (dev-notes/ Directory)

### Development Process Documentation
Files that explain **how we got here**:
- `MIGRATION_*.md` - Migration process
- `DEPLOYMENT_DECISION.md` - Decision matrices
- `*_AUDIT.md` - Audit reports
- AI context files

### Legacy Scripts
Superseded by Validated Patterns:
- `bootstrap.sh` - Old deployment method
- `bootstrap-smart.sh` - Development script

### Personal Files
Your development context:
- Personal notes and todos
- Debug logs
- Local configurations

---

## 🤔 Decision Matrix

Ask yourself these questions:

| Question | Yes → Root | No → dev-notes/ |
|----------|------------|-----------------|
| Do users need this to deploy? | ✅ | 🔒 |
| Is this production documentation? | ✅ | 🔒 |
| Does this explain HOW TO USE? | ✅ | 🔒 |
| Is this required by the framework? | ✅ | 🔒 |
| Does this document a decision process? | 🔒 | ✅ |
| Is this about development/migration? | 🔒 | ✅ |
| Contains local paths or context? | 🔒 | ✅ |
| Is this a legacy/superseded file? | 🔒 | ✅ |

---

## 📝 Examples

### ✅ ROOT (Committed):
```
"To deploy: make -f common/Makefile install"
"Security: Use GitLeaks pre-commit hook"
"Architecture: 6 Helm charts deployed via ArgoCD"
```

### 🔒 DEV-NOTES (Not Committed):
```
"After analyzing bootstrap.sh vs Makefile, we chose VP framework"
"Migration took 3 hours, here's what we learned..."
"Audit revealed PostgreSQL chart was missing"
```

---

**See**: `.github/CONTRIBUTING.md` for full guidelines
