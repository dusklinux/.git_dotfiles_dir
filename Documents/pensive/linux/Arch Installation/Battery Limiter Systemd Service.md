31.	BATTERY LIMITER TO 60%
	this is persistant

sudo nvim /etc/systemd/system/bat.service

	save this in the newly created nvim file
	
[Unit]
Description=Set Battery Charge Threshold for BAT1 to 60%
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/bash -c 'echo 60 > /sys/class/power_supply/BAT1/charge_control_end_threshold'

[Install]
WantedBy=multi-user.target
