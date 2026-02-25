```bash
chmod +x run-sandbox.sh
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
claude --version
whoami
pwd
echo $DEVCONTAINER
which claude
claude --version
```
