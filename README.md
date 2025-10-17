# Automated Braking

ML-based automated braking distance prediction system using Red Hat OpenShift AI.

## Architecture

This project follows enterprise architectural best practices documented in **[Architectural Decision Records (ADRs)](docs/adrs/)**:
- **Platform**: Red Hat OpenShift 4.18.21 ([ADR-0001](docs/adrs/0001-platform-selection-kubernetes-on-openshift.md))
- **Deployment**: GitOps with ArgoCD ([ADR-0002](docs/adrs/0002-gitops-deployment-with-argocd.md))
- **ML Pipelines**: Red Hat OpenShift AI v2.22.2 ([ADR-0003](docs/adrs/0003-ml-pipeline-orchestration-rhoai.md))
- **Deployment Framework**: OpenShift Validated Patterns ([ADR-0006](docs/adrs/0006-validated-patterns-framework.md)) - *Proposed*

📖 **[View All ADRs](docs/adrs/README.md)**

## Setup


```sh
oc apply -f manifests/
```

This requires setting up an S3-like connection for use by the model registry. The quickest way is to run the following:
```sh
oc apply -n distance-prediction -f https://github.com/rh-aiservices-bu/fraud-detection/raw/main/setup/setup-s3.yaml
```

Next we enable pipelines:
```sh
oc apply -f pipeline-server/
```

Then we get the URL of the cluster for use in setting up workbenches and calling pipelines:
```sh
oc apply -k url-getter/
```

Finally we create workbenches:
```sh
cd workbenches
helm install workbenches .
cd ...
```

## for ArgoCD ensure RHACM with helm 
```sh
oc apply -k https://github.com/tosin2013/sno-quickstarts/gitops/cluster-config/openshift-gitops
```

### To deploy a development env
```
 oc apply -f argocd/app-development.yaml
```

### To deploy a production env
```
 oc apply -f argocd/app-production.yaml
```

### Workbenches
This requires two workbenches with the SQL connection information mounted as secrets. The two folders `build-model` and `data-generation` each go in a separate workbench.

Data generation must be run first.

Then build model can be run. `pipeline` is the full, independent object that shows the automated running. `endpoint` hits the served model once it exists. The other 3 notebooks are all the components of the pipeline.

### How to Run

Once everything is set up, you can run the pipeline (published by running the `pipeline` notebook first), which will publish a model to the registry. From there, you can serve the model via the button to serve the models. Then you can hit it from the endpoint to show how you would progress from a photo of a car to how much you should be braking.

### Model Deployment

When you deploy the model, make sure that the path is `models/distance/`. Do not include the model version folder! When you run the inference, the name of the deployed model will include the version and somehow OpenVINO will match it up. Be sure to update the endpoint `notebook` to match the version being served.

## Bootstrap & Validation

We provide automated deployment and validation scripts that align with our ADRs:

```bash
# Deploy infrastructure (validates ADR compliance)
./bootstrap.sh

# Validate deployment against ADRs
./validate_bootstrap.sh
```

### Validated Patterns Framework (Recommended)

For production deployments, we recommend adopting the [OpenShift Validated Patterns](https://validatedpatterns.io/) framework:

- **Benefits**: Production-tested, standardized structure, multi-site support
- **Migration Guide**: See [docs/VALIDATED_PATTERNS_MIGRATION.md](docs/VALIDATED_PATTERNS_MIGRATION.md)
- **Status**: Proposed in [ADR-0006](docs/adrs/0006-validated-patterns-framework.md)

## Documentation

- **[ADRs](docs/adrs/)**: Architectural Decision Records documenting key decisions
- **[Migration Guide](docs/VALIDATED_PATTERNS_MIGRATION.md)**: Moving to Validated Patterns framework
- **[MCP Context](.mcp-server-context.md)**: AI-assisted architectural analysis context