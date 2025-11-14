remove previous stuff with 

```bash
sudo pacman -Rns ollama
```

```bash
sudo rm -rf /usr/lib/ollama
```

```bash
curl -LO https://ollama.com/download/ollama-linux-amd64.tgz
sudo tar -C /usr -xzf ollama-linux-amd64.tgz
```

```bash
ollama serve
```

```bash
ollama -v
```

```bash
sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
sudo usermod -a -G ollama $(whoami)
```

```bash
sudo nvim /etc/systemd/system/ollama.service
```

```ini
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=$PATH"

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl start ollama
```

to fix gpu acceleration 

the problem is that the runners end up under 
`/usr/lib/ollama/` and not `/usr/local/lib/ollama/`. (Isn't that a problem in the way the tar ball is organized, or a problem with the installer?)

fix that like by creating a symbolic link

```bash
sudo ln -nfs /usr/lib/ollama /usr/local/lib/ollama
```

Now GPU acceleration should work