#!/bin/bash

# Path to the domain list file inside the container, mapped via docker-compose.
DOMAIN_FILE="/etc/pihole/timed_domains.list"

# Check if the domain file exists.
if [ ! -f "$DOMAIN_FILE" ]; then
    echo "Error: Domain list file not found at $DOMAIN_FILE"
    exit 1
fi

# Read domains into an array, ignoring comments and blank lines.
mapfile -t DOMAINS < <(grep -vE '^\s*#|^\s*$' "$DOMAIN_FILE")

# Exit if the list is empty.
if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "No domains to process. Exiting."
    exit 0
fi

# Add the domains as wildcards.
/usr/local/bin/pihole --wild "${DOMAINS[@]}"
/usr/local/bin/pihole reloaddns
