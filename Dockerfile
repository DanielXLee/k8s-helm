FROM alpine/helm:3.7.1

COPY entrypoint /usr/local/bin/entrypoint
COPY clusternet-hub-0.2.0.tgz /
COPY clusternet-agent-0.2.0.tgz /
COPY clusternet-syncer-0.2.0.tgz /

WORKDIR /
ENTRYPOINT ["/usr/local/bin/entrypoint"]
