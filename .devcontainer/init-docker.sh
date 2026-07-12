#!/bin/bash
set -euo pipefail

# Must run AFTER init-firewall.sh: the firewall flushes all iptables rules,
# and dockerd only re-creates its NAT/forward rules on startup.

if docker info >/dev/null 2>&1; then
    echo "Docker daemon already running"
    exit 0
fi

echo "Starting dockerd..."
dockerd >/var/log/dockerd.log 2>&1 &

for i in $(seq 1 30); do
    if docker info >/dev/null 2>&1; then
        echo "Docker daemon is ready"
        exit 0
    fi
    sleep 1
done

echo "ERROR: dockerd failed to start; see /var/log/dockerd.log" >&2
tail -20 /var/log/dockerd.log >&2 || true
exit 1
