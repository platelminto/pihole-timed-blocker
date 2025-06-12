#!/bin/bash

# Path to the domain list file inside the container.
DOMAIN_FILE="/etc/pihole/timed_domains.list"

if [ ! -f "$DOMAIN_FILE" ]; then
    echo "Error: Domain list file not found at $DOMAIN_FILE"
    exit 1
fi

mapfile -t DOMAINS < <(grep -vE '^\s*#|^\s*$' "$DOMAIN_FILE")

if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "No domains to process. Exiting."
    exit 0
fi

# Delete the wildcards from the blocklist.
/usr/local/bin/pihole --wild -d "${DOMAINS[@]}"
/usr/local/bin/pihole reloaddns
