download warp with the Aur helper, paru
```bash
paru -S cloudflare-warp-nox-bin
```

start the service. 
```bash
sudo systemctl start warp-svc
```

configure registration

```
warp-cli registration new
```

connect to it. 

```bash
warp-cli connect
```

to disconnect later
```bash
warp-cli disconnect
```