FROM alpine:3.20 AS builder

RUN apk add --no-cache gcc musl-dev make git
RUN git clone --depth 1 https://github.com/Tiiffi/mcrcon.git /tmp/mcrcon && \
    cd /tmp/mcrcon && make

FROM alpine:3.20

RUN apk add --no-cache bash
COPY --from=builder /tmp/mcrcon/mcrcon /usr/local/bin/
COPY init-worlds.sh /init-worlds.sh
RUN chmod +x /init-worlds.sh

ENTRYPOINT ["/init-worlds.sh"]
