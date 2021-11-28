FROM alpine/helm:3.7.1 as builder

FROM bash:5.1.8

COPY --from=builder /usr/bin/helm /usr/local/bin/helm
COPY entrypoint /usr/local/bin/entrypoint

ENTRYPOINT ["/usr/local/bin/entrypoint"]
