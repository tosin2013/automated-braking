PIPELINES_URL=$(oc get route ds-pipeline-dspa -n distance-prediction -o go-template='{{if .spec.tls}}https://{{else}}http://{{end}}{{.spec.host}}{{"\n"}}')
BASE_URL=.apps$(echo $PIPELINES_URL | sed 's/^.*apps//g')
oc create secret generic -n distance-prediction urls --from-literal=PIPELINES_URL=$PIPELINES_URL --from-literal=BASE_URL=$BASE_URL
TOKEN=$(oc whoami -t)
oc create secret generic -n distance-prediction my-token --from-literal=TOKEN=$TOKEN