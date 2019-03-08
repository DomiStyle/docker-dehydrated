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

# Make dehydrated, hook and entrypoint executable
RUN chmod +x /app/dehydrated && \
    chmod +x /app/hook.sh && \
    chmod +x /entrypoint.sh

WORKDIR /app

# Add default values
ENV PARAM_CHALLENGETYPE=http-01 \
    PARAM_HOOK=/app/hook.sh \
    BASEDIR=/data

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ./dehydrated -f ${BASEDIR}/config -c
