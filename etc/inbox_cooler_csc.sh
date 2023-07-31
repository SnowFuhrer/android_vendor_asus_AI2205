#!/vendor/bin/sh

dongle_type=`getprop vendor.asus.dongletype`

if [ "$dongle_type" == "9" -o "$dongle_type" == "8" ]; then
	cooler_stage_csc=`getprop persist.vendor.asus.coolerstage_csc`
	
	if [ "$cooler_stage_csc" == "-1" ]; then
		cooler_stage=`getprop persist.vendor.asus.coolerstage`
		echo "[ROG6_INBOX] CSC test end, recovery cooler stage to $cooler_stage" > /dev/kmsg
		if [ "$cooler_stage" == "0" ]; then
			echo 0 > /sys/class/leds/aura_inbox/cooling_en
		else
			echo 1 > /sys/class/leds/aura_inbox/cooling_en
			sleep 0.1
			echo $cooler_stage > /sys/class/leds/aura_inbox/cooling_stage
		fi
	else
		if [ "$cooler_stage_csc" == "0" ]; then
			echo 0 > /sys/class/leds/aura_inbox/cooling_en
		else
			echo 1 > /sys/class/leds/aura_inbox/cooling_en
			sleep 0.1
			echo $cooler_stage_csc > /sys/class/leds/aura_inbox/cooling_stage
			echo "[ROG6_INBOX][CSC] set cooler stage = $cooler_stage_csc" > /dev/kmsg
		fi
	fi
fi

