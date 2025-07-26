FROM docker:dind
LABEL maintainer="humberto.cunha.crispim@gmail.com"
RUN apk add --no-cache openssh bash
ADD entrypoint.sh /entrypoint.sh
WORKDIR /github/workspace
ENTRYPOINT /bin/bash /entrypoint.sh
