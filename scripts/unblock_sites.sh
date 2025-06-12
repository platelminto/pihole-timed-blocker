#!/bin/bash
source "$(dirname "$0")/timed_domains.list"

# This is the corrected command to DELETE the wildcards.
# The -d flag works with the --wild command.
/usr/local/bin/pihole --wild -d "${DOMAINS[@]}"

# Reload lists to apply the change immediately.
/usr/local/bin/pihole reloaddns
