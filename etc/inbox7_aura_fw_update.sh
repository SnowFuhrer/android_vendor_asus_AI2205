#!/vendor/bin/sh

type=`getprop vendor.asus.dongletype`
latch_status=`cat /sys/class/leds/aura_inbox/get_hall_status`

if [ "$type" != "9" ] || [ "$latch_status" != "1" ]; then
	echo "[AURA_INBOX] Inbox 7 diconnect, terminate the update process!" > /dev/kmsg
	setprop vendor.fandg7.2led_fwupdate 2
	setprop vendor.fandg7.3led_fwupdate 2
	exit
fi

stop rpm_monitor
#get current version
#aura_2led_current_ver=`getprop vendor.inbox7.2led_fwver`
#aura_3led_current_ver=`getprop vendor.inbox7.3led_fwver`

#get target version
aura_2led_target_ver=`getprop vendor.asusfw.fandg7.2led_fwver`
aura_3led_target_ver=`getprop vendor.asusfw.fandg7.3led_fwver`

#which aura should update
aura_2led_update=`getprop vendor.fandg7.2led_fwupdate`
aura_3led_update=`getprop vendor.fandg7.3led_fwupdate`

if [ "$aura_2led_update" == "1" ]; then
	echo "[AURA_INBOX] Prepare to update 2led to $aura_2led_target_ver" > /dev/kmsg
	aura_id=1
elif [ "$aura_3led_update" == "1" ]; then
	echo "[AURA_INBOX] Prepare to update 3led to $aura_3led_target_ver" > /dev/kmsg
	aura_id=2
fi

if [ "$aura_id" == "1" ]; then
	echo "[AURA_INBOX] Start update 2led" > /dev/kmsg
elif [ "$aura_id" == "2" ]; then
	echo "[AURA_INBOX] Start update 3led" > /dev/kmsg
fi

echo "$aura_id" > /sys/class/leds/aura_inbox/ap2ld
sleep 1
echo "$aura_id" > /sys/class/leds/aura_inbox/fw_update
sleep 1
echo "$aura_id" > /sys/class/leds/aura_inbox/ld2ap
#wakeup ms51 and pd
echo 0 > /sys/class/leds/aura_inbox/HDC2010_INT_as_GPIO

sleep 1

echo "$aura_id" > /sys/class/leds/aura_inbox/ic_switch
current_ver=`cat /sys/class/leds/aura_inbox/fw_ver`

if [ "$aura_id" == "1" ]; then
	if [ "$current_ver" == "$aura_2led_target_ver" ]; then
		echo "[AURA_INBOX] update 2led complete! version = $current_ver" > /dev/kmsg
		setprop vendor.inbox7.2led_fwver $current_ver
		setprop vendor.fandg7.2led_fwupdate 0
		exit 0
	else
		echo "[AURA_INBOX] update 2led failed" > /dev/kmsg
		setprop vendor.fandg7.2led_fwupdate 2
		exit 0
	fi
elif [ "$aura_id" == "2" ]; then
	if [ "$current_ver" == "$aura_3led_target_ver" ]; then
		echo "[AURA_INBOX] update 3led complete! version = $current_ver" > /dev/kmsg
		setprop vendor.inbox7.3led_fwver $current_ver
		setprop vendor.fandg7.3led_fwupdate 0
		exit 0
	else
		echo "[AURA_INBOX] update 3led failed" > /dev/kmsg
		setprop vendor.fandg7.3led_fwupdate 2
		exit 0
	fi
fi

#if [ "$aura_2led_update" == "1" ]; then
#	echo "[AURA_INBOX] Fail to update 2led" > /dev/kmsg
#	setprop vendor.fandg7.2led_fwupdate 2
#elif [ "$aura_3led_update" == "1" ]; then
#	echo "[AURA_INBOX] Fail to update 3led" > /dev/kmsg
#	setprop vendor.fandg7.3led_fwupdate 2
#fi
