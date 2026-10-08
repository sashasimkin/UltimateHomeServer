FROM golang:1.23.9-alpine AS build
ARG TUYA_COMMIT=d65b3e9babb4829176290b4d53195d62636f00bf
RUN apk add --no-cache ca-certificates git
WORKDIR /src
RUN git init && git remote add origin https://github.com/seydx/tuya-ipc-terminal.git \
    && git fetch --depth=1 origin "${TUYA_COMMIT}" \
    && git checkout --detach FETCH_HEAD
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/tuya-ipc-terminal .

FROM alpine:3.22
RUN addgroup -S -g 10001 app && adduser -S -D -H -u 10001 -G app app \
    && mkdir -p /data && chown 10001:10001 /data
COPY --from=build /out/tuya-ipc-terminal /usr/local/bin/tuya-ipc-terminal
COPY entrypoint.sh /usr/local/bin/tuya-ipc-entrypoint
RUN chmod 0555 /usr/local/bin/tuya-ipc-entrypoint
USER 10001:10001
WORKDIR /data
ENTRYPOINT ["/usr/local/bin/tuya-ipc-entrypoint"]
