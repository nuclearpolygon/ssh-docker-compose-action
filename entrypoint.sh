#!/usb/bin/env bash
set -e

log() {
  echo ">> [local]" $@
}

cleanup() {
  set +e
  log "Killing ssh agent."
  ssh-agent -k
  log "Removing workspace archive."
  rm -f /tmp/workspace.tar.bz2
}
trap cleanup EXIT

log "Packing workspace into archive to transfer onto remote machine."
tar cjvf /tmp/workspace.tar.bz2 --exclude .git .

log "Launching ssh agent."
eval `ssh-agent -s`

remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...'; rm -rf \"\$HOME/.workspace\" ; } ; log DOCKER_COMPOSE_FILENAME \"$DOCKER_COMPOSE_FILENAME\" ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/.workspace\" ; trap cleanup EXIT ; log 'Unpacking workspace...' ; tar -C \"\$HOME/.workspace\" -xjv ; log DOCKER_COMPOSE_FILENAME: \"$DOCKER_COMPOSE_FILENAME\" ; log HOME: \"\$HOME/.workspace\" ; log DOCKER_COMPOSE_PREFIX: \"$DOCKER_COMPOSE_PREFIX\" ; log 'Launching docker compose...' ; cd \"\$HOME/.workspace\" ; docker compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" down --rmi all ; docker compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" up -d --build --force-recreate"
if $PULL; then
  remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...' ; rm -rf \"\$HOME/.workspace\" ; } ; log DOCKER_COMPOSE_FILENAME \"$DOCKER_COMPOSE_FILENAME\" ; log DOCKER_COMPOSE_PREFIX \"$DOCKER_COMPOSE_PREFIX\" ; log HOME \"\$HOME\" ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/.workspace\" ; trap cleanup EXIT ; log 'Unpacking workspace...' ; tar -C \"\$HOME/.workspace\" -xjv ; log 'Launching docker compose...' ; log DOCKER_COMPOSE_FILENAME: \"$DOCKER_COMPOSE_FILENAME\" ; log HOME: \"\$HOME/.workspace\" ; log DOCKER_COMPOSE_PREFIX: \"$DOCKER_COMPOSE_PREFIX\" ; cd \"\$HOME/.workspace\" ; log 'Pull images...'  ; docker compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" down --rmi all ; docker compose -f \"$DOCKER_COMPOSE_FILENAME\" pull ; docker compose -f \"$DOCKER_COMPOSE_FILENAME\" -p \"$DOCKER_COMPOSE_PREFIX\" up -d --build --force-recreate" ;
fi
if $USE_DOCKER_STACK ; then
  remote_command="set -e ; log() { echo '>> [remote]' \$@ ; } ; cleanup() { log 'Removing workspace...'; rm -rf \"\$HOME/.workspace\" ; } ; log DOCKER_COMPOSE_FILENAME \"$DOCKER_COMPOSE_FILENAME\" ; log 'Creating workspace directory...' ; mkdir -p \"\$HOME/.workspace/$DOCKER_COMPOSE_PREFIX\" ; trap cleanup EXIT ; log 'Unpacking workspace...' ; tar -C \"\$HOME/.workspace/$DOCKER_COMPOSE_PREFIX\" -xjv ; log 'Launching docker stack deploy...' ; cd \"\$HOME/.workspace/$DOCKER_COMPOSE_PREFIX\" ; docker stack deploy -c \"$DOCKER_COMPOSE_FILENAME\" --prune \"$DOCKER_COMPOSE_PREFIX\""
fi

#
ssh-add <(echo "$SSH_PRIVATE_KEY")

echo ">> [local] Connecting to remote host."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  "$SSH_USER@$SSH_HOST" -p "$SSH_PORT" \
  "$remote_command" \
  < /tmp/workspace.tar.bz2
