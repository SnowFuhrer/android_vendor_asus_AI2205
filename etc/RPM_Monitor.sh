#!/vendor/bin/sh

dongle_type=`getprop vendor.asus.dongletype`

while [ $dongle_type -eq 8 -o $dongle_type -eq 9 ]
do
	sleep 6
	dongle_type=`getprop vendor.asus.dongletype`

	if [ "$dongle_type" == "8" ] || [ "$dongle_type" == "9" ]; then
		FAN_RPM=`getprop persist.vendor.asus.userfanrpm`
		fan_rpm=`cat /sys/class/leds/aura_inbox/fan_RPM`
		fan_pwm=`cat /sys/class/leds/aura_inbox/fan_PWM`
		echo "[ROG6_INBOX] FanMonitor: RPM=$fan_rpm PWM=$fan_pwm setting=$FAN_RPM" > /dev/kmsg
		mic_type=`getprop vendor.asus.fan.mic`
		if [ "$mic_type" != "1" ]; then
			#work when mic off
			#sleep 0.1
			diff=`expr $FAN_RPM - $fan_rpm`
			abs_diff=${diff#-}
			echo "[ROG6_INBOX] FanMonitor: $FAN_RPM - $fan_rpm , diff = $abs_diff" > /dev/kmsg
			if [ "$abs_diff" -gt "500" ]; then
				echo $FAN_RPM > /sys/class/leds/aura_inbox/fan_RPM
				echo "[ROG6_INBOX] FanMonitor: set fan RPM = $FAN_RPM" > /dev/kmsg
			fi
		fi
	else
		echo "[ROG6_INBOX] FanMonitor: Fan disconnect" > /dev/kmsg
		exit
	fi
done

echo "[ROG6_INBOX] FanMonitor: Fan disconnect" > /dev/kmsg
exit
