FROM alpine:3.20

RUN apk add --no-cache bash gcc musl-dev make git

# Build mcrcon from source (works on any architecture)
RUN git clone --depth 1 https://github.com/Tiiffi/mcrcon.git /tmp/mcrcon && \
    cd /tmp/mcrcon && \
    make && \
    cp mcrcon /usr/local/bin/ && \
    rm -rf /tmp/mcrcon

COPY init-worlds.sh /init-worlds.sh
RUN chmod +x /init-worlds.sh

ENTRYPOINT ["/init-worlds.sh"]
