FROM python:3

# Install lexicon and dependencies
RUN apt-get update && \
    apt-get install -y bash && \
    rm -rf /var/lib/apt/lists/* && \
    pip install requests[security] dns-lexicon

# Copy dehydrated and lexicon hook
COPY dehydrated LICENSE /app/
ADD https://raw.githubusercontent.com/AnalogJ/lexicon/master/examples/dehydrated.default.sh /app/hook.sh

# Copy entrypoint to root
COPY docker/entrypoint.sh /entrypoint.sh

# Copy default config
COPY docker/default.config /app/default.config

RUN chmod +x /app/dehydrated

WORKDIR /app

ENV CA=https://acme-v01.api.letsencrypt.org/directory \
    CHALLENGETYPE=http-01 \
    BASEDIR=/data \
    KEYSIZE=4096 \
    HOOK=/app/hook.sh \
    RENEW_DAYS=30 \
    KEY_ALGO=rsa \
    AUTO_CLEANUP=no

ENTRYPOINT ["/entrypoint.sh"]
CMD ./dehydrated -f ${BASEDIR}/config -c
