FROM alpine:edge

MAINTAINER Scott Smith <scott.smith@gmail.com>

RUN apk update && \
    apk upgrade && \
    apk add --update bash rsync jq openssh

COPY ./assets/* /opt/resource/
