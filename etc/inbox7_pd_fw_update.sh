#!/vendor/bin/sh
trigger_type=`getprop vendor.fandg7.pd_fwupdate`
fw_ver=`cat /sys/class/leds/aura_inbox/pd_fw_date`
pd_asusfw_ver=`getprop vendor.asusfw.fandg7.pd_fwver`
stop rpm_monitor

# wakeup pdic
echo 0 > /sys/class/leds/aura_inbox/HDC2010_INT_as_GPIO

echo "[PD_INBOX7] update PD from $fw_ver to $pd_asusfw_ver" > /dev/kmsg
echo 1 > /sys/class/leds/aura_inbox/pd_ISP
sleep 1
echo "[PD_INBOX7] ready to update PD firmware" > /dev/kmsg
update_result=`cat /sys/class/leds/aura_inbox/pd_update`

if [ "$update_result" == "0" ]; then
	setprop vendor.fandg7.pd_fwupdate 0
	fw_ver=`cat /sys/class/leds/aura_inbox/pd_fw_date`
	echo "[PD_INBOX7] update PD firmware complete! version is $fw_ver" > /dev/kmsg
else
	echo "[PD_INBOX7] update PD firmware failed!" > /dev/kmsg
	setprop vendor.fandg7.pd_fwupdate 2
fi

echo 1 > /sys/class/leds/aura_inbox/HDC2010_INT_as_GPIO

start rpm_monitor
exit
