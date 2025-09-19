# Automated Braking

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