# ADR-0004: Database Strategy - MySQL, PostgreSQL, and MariaDB Usage

## Status
Accepted

## Date
2025-10-17

## Context

The automated braking ML system requires multiple database systems for different purposes:
1. **Model Registry** requires a relational database for storing model metadata, versions, and lineage
2. **Pipeline Metadata** needs persistent storage for Data Science Pipeline execution history
3. **Application Data** may require structured data storage

Current implementation uses three different database technologies:
- **MySQL 8.3.0** for Model Registry backend
- **PostgreSQL** deployed in manifests (purpose TBD)
- **MariaDB** for Data Science Pipeline metadata (via DSPA)

This creates complexity in terms of operations, backups, and expertise required.

## Decision

We will maintain the current multi-database strategy with specific purposes:

1. **MySQL 8.3.0**: Exclusive backend for Model Registry
   - Deployed in `distance-prediction` namespace
   - 10Gi persistent storage
   - Credentials: `distance-prediction-db` secret
   - Default authentication plugin: `mysql_native_password`

2. **MariaDB**: Managed by DSPA operator for pipeline metadata
   - Automatically deployed and managed by DataSciencePipelinesApplication
   - 10Gi PVC for pipeline database
   - Database name: `mlpipeline`
   - Managed lifecycle by RHOAI operators

3. **PostgreSQL**: Reserved for future application data needs
   - Currently deployed but not actively used
   - Available for application-specific data storage

## Consequences

### Positive

- **Optimized Performance**: Each database is optimized for its specific use case
- **Operator Management**: MariaDB is fully managed by RHOAI operators (no manual maintenance)
- **Isolation**: Different concerns (model registry, pipelines, app data) are isolated
- **Version Control**: Can upgrade/patch databases independently based on requirements
- **MySQL Native Password**: Ensures compatibility with Model Registry requirements

### Negative

- **Operational Complexity**: Multiple database systems to monitor, backup, and maintain
- **Expertise Requirements**: Team needs knowledge of multiple database systems
- **Resource Overhead**: Each database requires separate compute, memory, and storage resources
- **Backup Strategy Complexity**: Need different backup strategies for different database systems
- **Security Surface**: More attack surface with multiple database technologies

## Alternatives Considered

### 1. Single PostgreSQL Database for All Services
**Pros**: Single database to manage, team expertise consolidation, unified backups
**Cons**: Model Registry requires MySQL, RHOAI operator manages MariaDB automatically, potential single point of failure
**Why Rejected**: Model Registry specifically requires MySQL; RHOAI uses operator-managed MariaDB

### 2. Cloud-Managed Databases (RDS, Cloud SQL)
**Pros**: Reduced operational overhead, automatic backups, high availability
**Cons**: Vendor lock-in, egress costs, latency, may not meet on-premises requirements
**Why Rejected**: Project requires on-premises/OpenShift deployment capability

### 3. Unified MySQL for All Services
**Pros**: Single database technology, simplified operations
**Cons**: RHOAI DSPA operator automatically provisions MariaDB, would require significant customization
**Why Rejected**: RHOAI operator opinionated about using MariaDB for pipelines

## Implementation Notes

### MySQL Configuration
Location: `/manifests/base/mysql.yaml`

```yaml
Container Image: mysql:8.3.0
Resources:
  CPU: 500m (request/limit)
  Memory: 1Gi (request/limit)
Storage: 10Gi ReadWriteOnce PVC
Environment:
  - MYSQL_USER: registryuser
  - MYSQL_PASSWORD: registrypass
  - MYSQL_DATABASE: modelregistry
  - MYSQL_ROOT_PASSWORD: registrypass
Args:
  - --datadir /var/lib/mysql/datadir
  - --default-authentication-plugin=mysql_native_password
```

### Model Registry Connection
Location: `/manifests/base/model-registry.yaml`

```yaml
MySQL Configuration:
  host: mysql.distance-prediction.svc.cluster.local
  port: 3306
  database: modelregistry
  username: registryuser
  passwordSecret:
    name: distance-prediction-db
    key: database-password
```

### MariaDB (DSPA-Managed)
Location: `/pipeline-server/pipelines.yaml`

```yaml
Database:
  mariaDB:
    deploy: true
    pipelineDBName: mlpipeline
    pvcSize: 10Gi
    username: mlpipeline
```

## Security Considerations

1. **Credentials**: All database credentials stored in Kubernetes secrets
2. **Network**: Databases exposed only via ClusterIP services (not external)
3. **RBAC**: Access controlled via OpenShift RBAC to specific namespaces
4. **Encryption**: Consider enabling encryption at rest for sensitive data
5. **Password Rotation**: Implement regular password rotation policy (TODO)

## Future Improvements

1. **Consolidation**: Evaluate if PostgreSQL is needed or can be removed
2. **Backup Strategy**: Implement automated backup strategy for MySQL and MariaDB
3. **High Availability**: Consider MySQL/MariaDB replication for production
4. **Monitoring**: Add database-specific monitoring dashboards
5. **Password Management**: Move to Vault or external secrets management

## References

- [MySQL Deployment](/manifests/base/mysql.yaml)
- [PostgreSQL Deployment](/manifests/base/postgres.yaml)
- [Model Registry Configuration](/manifests/base/model-registry.yaml)
- [DSPA Pipeline Configuration](/pipeline-server/pipelines.yaml)
- [Database Credentials](/manifests/base/database-creds.yaml)

