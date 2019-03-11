#!/bin/sh

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if base directory exists
if [ ! -d "${BASEDIR}" ]; then
    echo "${RED}Please create a volume for the ${BASEDIR} folder${NC}"
    exit 1
fi

# Check if config file exists
if [ ! -f "${BASEDIR}/config" ]; then
    echo "Copying default config"

    cp default.config "${BASEDIR}/config"
fi

# Check if we should register a new account
if [ "${REGISTER}" = "true" ]; then
    echo "${GREEN}Registering with Let's Encrypt${NC}"
    exec ./dehydrated -f "${BASEDIR}/config" --register --accept-terms

    exit 0
fi

# Check if we should repeat the command
if [ "${REPEAT}" = "true" ] && [ -v "${REPEAT_INTERVAL}" ]; then
    echo "${GREEN}Starting in repeating mode${NC}"

    while true; do
        exec "$@"
        sleep $REPEAT_INTERVAL
    done
else
    echo "${GREEN}Starting${NC}"

    exec "$@"
fi
