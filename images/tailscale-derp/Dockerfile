# Tailscale Drep基础镜像
FROM golang:alpine
ARG VERSION=main

RUN apk add git

RUN go install tailscale.com/cmd/derper@${VERSION}

ENTRYPOINT [ "/go/bin/derper" ]