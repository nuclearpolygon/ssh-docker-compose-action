# Run Docker Compose on a Remote Server through SSH with GitHub Actions

This GitHub action allows you to run `docker compose` on a remote server through an SSH connection. The process involves compressing the workspace into a file, transferring it via SSH to the remote server, and then running the `docker compose up -d` command.

This action stands out because it doesn't require the use of unknown Docker images. Instead, the action is built from a Dockerfile that uses the `alpine` base.

## Inputs

- `ssh_private_key` - Private SSH key for authentication on the remote system. It is recommended to keep this key secure in GitHub secrets.
- `ssh_host` - SSH Host Name.
- `ssh_port` - Remote port, default is 22.
- `ssh_user` - Remote username with permissions to access Docker.
- `script` - Bash script to execute with remote Docker context.
- `registry_login` - Docker registry login. Optional. Defaults to `${{ github.actor }}`
- `registry_secret` - Docker registry secret. Optional. Defaults to `${{ secrets.GITHUB_TOKEN }}`
- `registry` - Docker registry. Default: 'ghcr.io'

# Usage Example
```
name: Deploy
on:
  push:
    branches: [ master ]
jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v6

    - uses: nuclearpolygon/ssh-docker-compose-action@v1
      name: Remote Deployment with Docker-Compose
      with:
        ssh_host: ${{ vars.SSH_HOST }}
        ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
        ssh_user: ${{ vars.SSH_USER }}
        registry_login: ${{ github.actor }}
        registry_secret: ${{ secrets.GITHUB_TOKEN }}
        script: |
            docker compose up -d

```
