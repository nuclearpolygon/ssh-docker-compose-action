#!/usr/bin/env bash
set -e

log() {
  echo ">> [local]" "$@"
}

error() {
  echo "❌ [ERROR]" "$@" >&2
  exit 1
}

cleanup() {
  set +e
  log "Cleaning up..."
  if [ -n "$SSH_AGENT_PID" ]; then
    log "Killing ssh agent (PID: $SSH_AGENT_PID)"
    ssh-agent -k
  fi
  # Optionally remove docker context
  if docker context inspect remote-context &>/dev/null; then
    log "Removing docker context"
    docker context rm -f remote-context
  fi
}
trap cleanup EXIT

# Validate required variables
[ -z "$SSH_PRIVATE_KEY" ] && error "SSH_PRIVATE_KEY is not set"
[ -z "$SSH_HOST" ] && error "SSH_HOST is not set"
[ -z "$SSH_USER" ] && error "SSH_USER is not set"
[ -z "$SCRIPT" ] && error "SCRIPT is not set"

log "PWD: $PWD"
ls -l .

# Setup SSH
log "Setting up SSH agent..."
eval "$(ssh-agent -s)"
ssh-add <(echo "$SSH_PRIVATE_KEY")

# Test SSH connection
log "Testing SSH connection to $SSH_USER@$SSH_HOST:$SSH_PORT..."
ssh-keyscan -p "$SSH_PORT" "$SSH_HOST" >> ~/.ssh/known_hosts 2>/dev/null
ssh -p "$SSH_PORT" -o ConnectTimeout=5 "$SSH_USER@$SSH_HOST" "echo '✅ SSH connection successful'" || error "SSH connection failed"

# Create Docker context
log "Creating remote Docker context..."
docker context create remote-context --docker "host=ssh://$SSH_USER@$SSH_HOST:$SSH_PORT"
docker context use remote-context

# Login to registry if credentials provided
if [ -n "$REGISTRY_LOGIN" ] && [ -n "$REGISTRY_SECRET" ]; then
  REGISTRY_URL="${REGISTRY:-ghcr.io}"
  log "Logging into Docker registry: $REGISTRY_URL"
  echo "$REGISTRY_SECRET" | docker login "$REGISTRY_URL" -u "$REGISTRY_LOGIN" --password-stdin || error "Registry login failed"
fi

# Execute the provided script
log "Executing deployment script..."
echo "$SCRIPT" | bash -e