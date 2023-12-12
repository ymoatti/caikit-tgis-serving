#!/bin/bash
set -o pipefail
set -o nounset
set -o errtrace
# set -x   #Uncomment this to debug script.

# Performs inference using HTTP

PREFIX="-"
INF_PROTO="grpc"

source "$(dirname "$(realpath "$0")")/../env.sh"
source "$(dirname "$(realpath "$0")")/../utils.sh"

echo
echo "Wait until $INF_PROTO runtime is READY"

ISVC_NAME=caikit-tgis-isvc"${PREFIX}${INF_PROTO}"
wait_for_pods_ready "serving.kserve.io/inferenceservice=$ISVC_NAME" "${TEST_NS}"
oc wait --for=condition=ready pod -l serving.kserve.io/inferenceservice=$ISVC_NAME -n ${TEST_NS} --timeout=300s

echo
echo "Testing all token in a single call"
echo

export KSVC_HOSTNAME=$(oc get ksvc "$ISVC_NAME"-predictor -n ${TEST_NS} -o jsonpath='{.status.url}' | cut -d'/' -f3)
#export THE_QUESTION="At what temperature does Nitrogen boil?"
# export THE_MODEL="flan-t5-small-caikit"

### Invoke the inferences:
grpcurl -insecure -d '{"text": "At what temperature does Nitrogen boil?"}' -H "mm-model-id: flan-t5-small-caikit" ${KSVC_HOSTNAME}:443 caikit.runtime.Nlp.NlpService/TextGenerationTaskPredict

echo
echo "Testing streams of token"
echo

grpcurl -insecure -d '{"text": "At what temperature does Nitrogen boil?"}' -H "mm-model-id: flan-t5-small-caikit" ${KSVC_HOSTNAME}:443 caikit.runtime.Nlp.NlpService/ServerStreamingTextGenerationTaskPredict

