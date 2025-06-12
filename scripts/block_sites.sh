#!/bin/bash
source "$(dirname "$0")/timed_domains.list"

# This is the corrected command. It adds the domains as wildcards.
/usr/local/bin/pihole --wild "${DOMAINS[@]}"

# Reload lists to apply the change immediately.
/usr/local/bin/pihole reloaddns
