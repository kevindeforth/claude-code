```bash
chmod +x run-sandbox.sh

# First-time setup or after Dockerfile changes — build then run:
./run-sandbox.sh --build

# Subsequent launches — skip the build, just run:
./run-sandbox.sh
```

Inside the container, run the firewall script:
```bash
sudo /usr/local/bin/init-firewall.sh
```

and test it:
```bash
curl --connect-timeout 5 https://api.github.com/zen
curl --connect-timeout 5 https://example.com
```
compare:
```bash
whoami
pwd
echo $DEVCONTAINER
which claude
claude --version
```
