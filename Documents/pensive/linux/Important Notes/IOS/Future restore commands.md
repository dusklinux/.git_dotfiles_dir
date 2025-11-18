
```
sudo pacman -Syu usbmuxd
```

```
sudo systemctl start usbmuxd
```

pelrain recovery mode: 
```
sudo /mnt/zram1/future_restore/iphonee/palera1n-linux-x86_64 -D
```


gaster : (to boot untrusted images)
```
sudo /mnt/zram1/future_restore/iphonee/gaster pwn
```

gaster " to find the usb handle
```
sudo /mnt/zram1/future_restore/iphonee/gaster reset
```

to set nonce
```
sudo ./futurerestore -t /mnt/zram1/future_restore/iphonee/4878275665063854_iPhone10,2_d21ap_16.6-20G75_27325c8258be46e69d9ee57fa9a8fbc28b873df434e5e702a8b27999551138ae.shsh2 --use-pwndfu --set-nonce --latest-sep --latest-baseband /mnt/zram1/future_restore/iphonee/iPhone_5.5_P3_16.6_20G75_Restore.ipsw
```

now, if it doesn't automatcially go into recovery mode, go into it manually by button combo. vol up vol down and power hold. and you should see the pc and cable logo on the iphone. 

restart usbmxd service and leve the terminal open
```
sudo systemctl stop usbmuxd && sudo usbmuxd -p -f
```

futurerestoring main 
```
sudo ./futurerestore -t /mnt/zram1/future_restore/iphonee/4878275665063854_iPhone10,2_d21ap_16.6-20G75_27325c8258be46e69d9ee57fa9a8fbc28b873df434e5e702a8b27999551138ae.shsh2 --latest-sep --latest-baseband /mnt/zram1/future_restore/iphonee/iPhone_5.5_P3_16.6_20G75_Restore.ipsw
```
