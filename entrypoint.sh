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
}
trap cleanup EXIT

log "DOCKER_COMPOSE_FILENAME: $DOCKER_COMPOSE_FILENAME"
log "DOCKER_COMPOSE_PREFIX: $DOCKER_COMPOSE_PREFIX"
log "PWD: $PWD"
ls -l .
ls -l ./nginx*
cat $DOCKER_COMPOSE_FILENAME

log "Launching ssh agent."

eval `ssh-agent -s`
ssh-add <(echo "$SSH_PRIVATE_KEY")

log "Creating docker context"
docker context create --docker host=ssh://$SSH_USER@$SSH_HOST ssh-docker
docker context use ssh-docker

if [ -n "$REGISTRY_LOGIN" ] && [ -n "$REGISTRY_SECRET" ]; then
  log "Login to docker registry"
  [ -z "$REGISTRY" ] && $REGISTRY=ghcr.io
  echo $REGISTRY_SECRET | docker login $REGISTRY -u $REGISTRY_LOGIN --password-stdin
fi

log "Down compose"
docker compose -f "$DOCKER_COMPOSE_FILENAME" -p "$DOCKER_COMPOSE_PREFIX" down
log "Remove containers"
docker compose -f "$DOCKER_COMPOSE_FILENAME" -p "$DOCKER_COMPOSE_PREFIX" rm -s -f
docker system prune -a -f
if $PULL; then
  docker compose -f "$DOCKER_COMPOSE_FILENAME" -p "$DOCKER_COMPOSE_PREFIX" pull
fi
log "Launching docker compose"
docker compose -f "$DOCKER_COMPOSE_FILENAME" -p "$DOCKER_COMPOSE_PREFIX" up -d --build --force-recreate
