#!/vendor/bin/sh
type=`getprop vendor.asus.dongletype`
if [ "$type" != "8" ] && [ "$type" != "9" ]; then
	echo "[AURA_INBOX] FANDG6 of FANDG7 didn't exist. Type is $type" > /dev/kmsg
	setprop vendor.fandg.mcu_fwupdate 0
    exit
fi

asusfw_inbox_ver=`getprop vendor.asusfw.fandg6.inbox_fwver`
fw_ver=`cat /sys/class/leds/aura_inbox/NUC1261_fw_ver`

if [ "asusfw_inbox_ver" == "fw_ver" ]; then
	echo "[AURA_INBOX] MCU no need update" > /dev/kmsg
	setprop vendor.fandg.mcu_fwupdate 0
fi


echo 1 > /sys/class/leds/aura_inbox/NUC1261_ap2ld
echo "[AURA_INBOX] NUC1261 enter LD mode" > /dev/kmsg
sleep 5
echo "[AURA_INBOX] NUC1261 update fw from $fw_ver to $asusfw_inbox_ver" > /dev/kmsg
fandg_fw_update
echo "[AURA_INBOX] NUC1261 update end, $update_result" > /dev/kmsg
sleep 5

update_result=` getprop vendor.fandg.mcu_fwupdate`

if [ "$update_result" == "2" ]; then
	echo "[AURA_INBOX] NUC1261 update failed." > /dev/kmsg
	exit
fi

#waitfor fandongle reconnect
type=`getprop vendor.asus.dongletype`
while [ "$type" != "8" ] && [ "$count" -le "10" ]
do
	type=`getprop vendor.asus.dongletype`
	sleep 1
	count=$(($count+1))
	echo "[AURA_INBOX] Wait for fandg reconnect...." > /dev/kmsg

	if ["$count" == "10"]; then
		echo "[AURA_INBOX] Wait for fandg reconnect timeout, maybe device plug out or update failed" > /dev/kmsg
		exit
	fi
done

fw_ver=`cat /sys/class/leds/aura_inbox/NUC1261_fw_ver`
count=0
while [ "$fw_ver" = "0x0000" ] && [ "$count" -le "10" ]
do
	fw_ver=`cat /sys/class/leds/aura_inbox/NUC1261_fw_ver`
	sleep 1
	count=$(($count+1))
done

if [ "$asusfw_inbox_ver" != "$fw_ver" ]; then
	echo "[AURA_INBOX] NUC1261 ver: $fw_ver, should be $asusfw_inbox_ver" > /dev/kmsg
	#setprop vendor.fandg.mcu_fwupdate 2
else
	echo "[AURA_INBOX] NUC1261 ver: $fw_ver" > /dev/kmsg
	#setprop vendor.fandg.mcu_fwupdate 0
	setprop vendor.asus.accy.fw_status 000000
fi
