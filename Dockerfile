FROM docker:dind
LABEL maintainer="humberto.cunha.crispim@gmail.com"
RUN apk add --no-cache openssh bash
ADD entrypoint.sh /entrypoint.sh
COPY ssh_config /etc/ssh/ssh_config
WORKDIR /github/workspace
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
