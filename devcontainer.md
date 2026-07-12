```bash
chmod +x run-sandbox.sh

# First-time setup or after Dockerfile changes — build then run:
./run-sandbox.sh --build

# Subsequent launches — skip the build, just run:
./run-sandbox.sh
```

The run script starts the firewall and the Docker daemon automatically
(`init-firewall.sh` then `init-docker.sh` — order matters: the firewall
flushes iptables, dockerd re-creates its rules on startup).

Test the firewall:
```bash
curl --connect-timeout 5 https://api.github.com/zen   # should succeed
curl --connect-timeout 5 https://example.com          # should be blocked
```

## Docker (docker-in-docker)

The container runs `--privileged` with its own dockerd; image layers persist
in the `claude-code-docker` volume. Nested containers are subject to the same
egress allowlist via the DOCKER-USER chain.

```bash
docker run --rm hello-world
docker compose version
```

## PostgreSQL

A native PG server is installed; `pg-dev` manages a user-owned cluster at
`~/.pgdata` (socket in `/tmp`, port 5432):

```bash
pg-dev start
pg-dev psql -c 'select 1'
pg-dev stop
```

## Python (uv)

`uv` and `uvx` are in `/usr/local/bin`. PyPI (`pypi.org`,
`files.pythonhosted.org`) is on the firewall allowlist.

## GitHub CLI

The sandbox acts as the `kdeforth-bot` machine account, not your personal
identity: `run-sandbox.sh` injects `GH_TOKEN` from
`~/.config/claude-sandbox/gh-token` on the host (the bot's fine-grained PAT),
the image bakes the bot's git author identity (system gitconfig), and `gh` is
the git credential helper — so `gh` and HTTPS `git push` work out of the box,
attributed to the bot.

Sanity checks:
```bash
whoami
pwd
echo $DEVCONTAINER
which claude
claude --version
```
