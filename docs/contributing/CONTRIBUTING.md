# Contributing to Automated Braking Pattern

## 📁 Repository Organization Rules

### What Goes Where?

#### ✅ Root Directory (Committed to GitHub)

**User-Facing Documentation:**
- `README.md` - Main project documentation
- `README_VALIDATED_PATTERNS.md` - Deployment quick start
- `SECURITY.md` - Security practices and guidelines
- `S3_STORAGE_SOLUTION.md` - Technical architecture docs
- `LICENSE` - Project license

**Validated Patterns Configuration:**
- `values-global.yaml` - Pattern-wide configuration
- `values-hub.yaml` - Application definitions
- `values-secret.yaml.template` - Secrets template (placeholders only!)
- `pattern-metadata.yaml` - Pattern metadata
- `Makefile.vp` - Framework entry point (symlink)
- `pattern.sh` - Pattern utilities (symlink)

**Production Scripts:**
- `validate_bootstrap.sh` - Deployment validation (useful for users)

**Infrastructure:**
- `charts/` - Helm charts for all components
- `docs/` - Documentation including ADRs
- `common/` - Validated Patterns framework (git submodule)

#### 🔒 dev-notes/ Directory (NOT Committed)

**Purpose**: Local development context and process documentation

**What Belongs Here:**
- Migration documentation (MIGRATION_*.md)
- Decision matrices (DEPLOYMENT_DECISION.md)
- Audit reports (CHARTS_AUDIT.md)
- AI context files (.mcp-server-context.md)
- Development scripts (bootstrap.sh, bootstrap-smart.sh)
- Personal notes and todos
- Session logs and debug output

**Rule of Thumb**: 
- **PRODUCT** documentation → Root directory (committed)
- **PROCESS** documentation → dev-notes/ (not committed)

**Examples:**
- ✅ "How to deploy" → Root (users need this)
- 🔒 "How we decided to migrate" → dev-notes/ (internal process)
- ✅ "Security best practices" → Root (users need this)
- 🔒 "GitLeaks setup process" → dev-notes/ (internal process)

---

## 🔐 Security Rules

### NEVER Commit:
1. **Actual secrets** - `values-secret.yaml` (without .template)
2. **Credentials** - Passwords, API keys, tokens
3. **Local paths** - `.mcp-server-context.md`
4. **Personal data** - Your notes, todos, logs

### Protection:
- ✅ GitLeaks pre-commit hook (automatic scanning)
- ✅ `.gitignore` (blocks sensitive files)
- ✅ `dev-notes/` folder (for development artifacts)

---

## 📝 Documentation Guidelines

### User-Facing Docs (Root Directory)

**Requirements:**
- Clear and concise
- Focused on "how to use" not "how we built"
- Production-ready information
- Well-structured with examples

**Examples:**
```markdown
# Good (Root): 
"Deploy with: make -f common/Makefile install"

# Bad (Should be in dev-notes/):
"After 3 hours of debugging, we decided Makefile is better than bootstrap.sh because..."
```

### Developer Notes (dev-notes/ Directory)

**Purpose:**
- Document decision-making process
- Track migration progress
- Keep audit trails
- Store development context

**Freedom:**
- No formatting requirements
- Can be verbose
- Include all context
- Keep historical decisions

---

## 🎯 File Naming Conventions

### Root Directory Files:
- `README*.md` - User documentation
- `SECURITY.md` - Security guide
- `LICENSE` - Project license
- `*_SOLUTION.md` - Technical architecture docs

### dev-notes/ Files:
- `MIGRATION_*.md` - Migration docs
- `DEPLOYMENT_*.md` - Deployment decisions
- `*_AUDIT.md` - Audit reports
- `NOTES.md` - Personal notes
- `.mcp-*` - AI context files

---

## 🔄 Moving Files

### When to Move Files to dev-notes/:

Ask yourself:
1. **Is this about the development process?** → dev-notes/
2. **Does a user need this to deploy/use?** → Root
3. **Is this internal decision documentation?** → dev-notes/
4. **Is this a troubleshooting guide for users?** → Root

### How to Move:
```bash
# Move development doc to dev-notes/
mv SOME_PROCESS_DOC.md dev-notes/

# Verify it's in .gitignore
git status | grep SOME_PROCESS_DOC
# Should not appear (it's ignored)
```

---

## ✅ Pre-Commit Checklist

Before committing:

- [ ] Run `gitleaks detect` (automatic via pre-commit hook)
- [ ] Check `git status` - no secrets visible
- [ ] Verify dev notes in `dev-notes/` folder
- [ ] User-facing docs in root directory
- [ ] No hardcoded passwords (use templates)
- [ ] Documentation is clear and production-ready

---

## 📦 Validated Patterns Structure

```
automated-braking/
├── README.md                    ✅ Main docs
├── SECURITY.md                  ✅ Security guide
├── values-global.yaml           ✅ Pattern config
├── values-hub.yaml              ✅ Apps config
├── values-secret.yaml.template  ✅ Secrets template
├── pattern-metadata.yaml        ✅ Metadata
├── charts/                      ✅ Helm charts
│   └── hub/
│       ├── mysql/
│       ├── minio/
│       ├── postgresql/
│       ├── model-registry/
│       ├── pipelines/
│       └── workbenches/
├── docs/                        ✅ Documentation
│   └── adrs/                    ✅ ADRs
├── common/                      ✅ VP framework (submodule)
└── dev-notes/                   🔒 NOT COMMITTED
    ├── README.md                ✅ (Index only)
    ├── MIGRATION_*.md           🔒 Process docs
    ├── DEPLOYMENT_*.md          🔒 Decisions
    ├── *_AUDIT.md              🔒 Audits
    └── .mcp-*                   🔒 AI context
```

---

## 🤝 Contributing Code

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** with validation scripts
5. **Ensure** GitLeaks passes
6. **Submit** a pull request

---

## 📚 Resources

- **Validated Patterns**: https://validatedpatterns.io/
- **GitLeaks**: https://github.com/gitleaks/gitleaks
- **ADRs**: See `docs/adrs/` directory

---

**Maintainer**: Automated Braking Team  
**Last Updated**: 2025-10-17

