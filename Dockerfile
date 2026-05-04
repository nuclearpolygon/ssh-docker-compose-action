FROM docker:28.2.1-dind-alpine3.21
RUN apk add --no-cache openssh bash
ADD entrypoint.sh /entrypoint.sh
WORKDIR /github/workspace
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
