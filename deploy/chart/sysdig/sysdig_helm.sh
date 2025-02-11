#!/bin/bash

# ============================================================================
# Sysdig requires this file to apply remediation patches to your Helm chart.
# Run "helm install --post-renderer=sysdig_helm.sh" to use Sysdig patches.
# For more information, follow the link: https://docs.sysdig.com/en/docs/sysdig-secure
# ============================================================================
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cat <&0 > "$DIR"/all.yaml
kustomize build "$DIR" && rm "$DIR"/all.yaml
