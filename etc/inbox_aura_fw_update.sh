#!/vendor/bin/sh

type=`getprop vendor.asus.dongletype`

if [ "$type" != "1" ] && [ "$type" != "8" ]; then
	echo "[AURA_INBOX] Inbox didn't exist. Type is type$" > /dev/kmsg
	setprop vendor.fandg.aura_fwupdate 0
    exit
fi

stop rpm_monitor
aura_fw=`getprop vendor.asusfw.fandg6.aura_fwver`

function Update() {
	fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
	if [ "${fw_mode}" == "2" ]; then
		echo "[AURA_INBOX] It is in LD mode, we will try to flash the AP FW" > /dev/kmsg
		echo "[AURA_INBOX] Start MS51 FW update" > /dev/kmsg
		echo 1 > /sys/class/leds/aura_inbox/ap2ld
		echo 1 > /sys/class/leds/aura_inbox/fw_update
		sleep 2;
		echo 1 > /sys/class/leds/aura_inbox/ld2ap
		echo 2 > /sys/class/leds/aura_inbox/ic_switch
	else # AP mode,fw_mode=1
		echo 1 > /sys/class/leds/aura_inbox/ap2ld
		sleep 1
		# check ms51 enter LD mode or not
		fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
		get_mode_retry=5;
		while [ "$fw_mode" != "2" ] && [ $get_mode_retry -gt 0 ]
		do
			sleep 1
			fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
			(( get_mode_retry-- ))
			echo "[AURA_INBOX] get fw_mode = $fw_mode, retry = $get_mode_retry" > /dev/kmsg
		done

		if [ "$get_mode_retry" == "0" ] && [ "fw_mode" != "2" ]; then
			echo "[AURA_INBOX] MS51 enter LD mode failed after retry, fw_mode = $fw_mode" > /dev/kmsg
		fi

		if [ "${fw_mode}" == "2" ]; then
			echo "[AURA_INBOX] It is in LD mode, we will try to update the AP FW" > /dev/kmsg
			echo "[AURA_INBOX] Start MS51 FW update" > /dev/kmsg
			echo 1 > /sys/class/leds/aura_inbox/fw_update
			sleep 2;
			echo 1 > /sys/class/leds/aura_inbox/ld2ap
			echo 2 > /sys/class/leds/aura_inbox/ic_switch #APROM addres is 0x18
		else
			echo "[AURA_INBOX] AP mode -> LD mode failed, mode=$fw_mode" > /dev/kmsg
		fi
	fi
	sleep 3
}

function Check_last_fwupdate() {

	# check ms51 enter LD mode or not
	fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
	get_mode_retry=5;
	while [ "$fw_mode" != "1" ] && [ "$fw_mode" != "2" ] && [ $get_mode_retry -gt 0 ]
	do
		sleep 1
		fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
		(( get_mode_retry-- ))
		echo "[AURA_INBOX] get fw_mode = $fw_mode, retry = $get_mode_retry" > /dev/kmsg
	done

	if [ "${fw_mode}" == "2" ]; then
		echo "[AURA_INBOX] MS51 update failed for 2 times, it is still in ld mode" > /dev/kmsg
		setprop vendor.fandg.aura_fwupdate 2
	elif [ "${fw_mode}" == "1" ]; then
		fw_ver=`cat /sys/class/leds/aura_inbox/fw_ver`
		echo "[AURA_INBOX] after second update fw_ver = $fw_ver" > /dev/kmsg
		echo "[AURA_INBOX] aura_fw= $aura_fw" > /dev/kmsg
		if [ "${fw_ver}" != "${aura_fw}" ]; then
			echo "[AURA_INBOX] MS51 update failed for 2 times, and it is now in ap mode." > /dev/kmsg
			setprop vendor.fandg.aura_fwupdate 2
		else
			setprop vendor.inbox.aura_fwver $fw_ver
			setprop vendor.fandg.aura_fwupdate 0
		fi
	else
		echo "[AURA_INBOX] MS51 update failed for 2 times, and it is now in unknown mode." > /dev/kmsg
		setprop vendor.fandg.aura_fwupdate 2
	fi
}

retry=0

while [ "$retry" -le 5 ]  # the most retry times is 5
do
	fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
	if [ "${fw_mode}" == "2" ]; then
		echo "[AURA_INBOX] LD mode,aura_fw= $aura_fw, 1st update start." > /dev/kmsg
		Update;
		sleep 1
		fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
		if [ "${fw_mode}" == "1" ]; then
			fw_ver=`cat /sys/class/leds/aura_inbox/fw_ver`
			echo "[AURA_INBOX] after first update fw_ver = $fw_ver" > /dev/kmsg
			echo "[AURA_INBOX] aura_fw= $aura_fw" > /dev/kmsg
			if [ "${fw_ver}" != "${aura_fw}" ]; then
				echo "[AURA_INBOX] MS51 update fail, we will retry a time." > /dev/kmsg
				fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
				if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
					Update;
					Check_last_fwupdate;
					exit 0;
				else #no need second update
					echo "[AURA_INBOX]it is now in an unknown mode $fw_mode after the first failure and reset" > /dev/kmsg
					setprop vendor.fandg.aura_fwupdate 2
					exit 0;
				fi	
			else
				setprop vendor.inbox.aura_fwver $fw_ver
				setprop vendor.fandg.aura_fwupdate 0  #update success at the first time
				exit 0;
			fi

		else # in ld mode or in an known mode. we will retry
			echo "[AURA_INBOX] MS51 update fail. Second update start."> /dev/kmsg
			fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
			if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
				Update;
				Check_last_fwupdate;
				exit 0;
			else #no need second update
				echo "[AURA_INBOX]it is now in an unknown mode $fw_mode after the first failure and reset" > /dev/kmsg
				setprop vendor.fandg.aura_fwupdate 2
				exit 0;
			fi
		fi

	elif [ "${fw_mode}" == "1" ]; then
		fw_ver=`cat /sys/class/leds/aura_inbox/fw_ver`

		if [ "${fw_ver}" != "${aura_fw}" ]; then
			echo "[AURA_INBOX] fw_ver = $fw_ver" > /dev/kmsg
			echo "[AURA_INBOX] aura_fw= $aura_fw. 1st update start." > /dev/kmsg

			Update;
			fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
			if [ "${fw_mode}" == "1" ]; then
				fw_ver=`cat /sys/class/leds/aura_inbox/fw_ver`
				echo "[AURA_INBOX] after first update fw_ver = $fw_ver" > /dev/kmsg
				echo "[AURA_INBOX] aura_fw= $aura_fw" > /dev/kmsg
				if [ "${fw_ver}" != "${aura_fw}" ]; then
					echo "[AURA_INBOX] MS51 update fail, we will retry a time." > /dev/kmsg
					fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
					if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
						Update;
						Check_last_fwupdate;
						exit 0;
					else #no need second update
						echo "[AURA_INBOX]it is now in an unknown mode $fw_mode after the first failure and reset" > /dev/kmsg
						setprop vendor.fandg.aura_fwupdate 2
						exit 0;
					fi
				else
					setprop vendor.inbox.aura_fwver $fw_ver
					setprop vendor.fandg.aura_fwupdate 0  #update success at the first time
					exit 0;
				fi
			else # in ld mode or in an known mode. we will retry
				echo "[AURA_INBOX] MS51 update fail. Second update start."> /dev/kmsg

				fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
				if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
					Update;
					Check_last_fwupdate;
					exit 0;
				else #no need second update
					echo "[AURA_INBOX]it is now in an unknown mode $fw_mode after the first failure and reset" > /dev/kmsg
					setprop vendor.fandg.aura_fwupdate 2
					exit 0;
				fi
			fi

		else
			echo "[AURA_INBOX] No need update" > /dev/kmsg
			setprop vendor.fandg.aura_fwupdate 0
			exit 0;
		fi
	elif [ "${fw_mode}" == "0" ]; then
	echo 1 > /sys/class/leds/aura_inbox/ap2ld
		LPM_mode=`cat /sys/class/leds/aura_inbox/aura_lpm_mode`
		if [ "${LPM_mode}" == "1" ]; then
			echo "[AURA_INBOX] LPM exit" > /dev/kmsg
			echo 0 > /sys/class/leds/aura_inbox/aura_lpm_mode
			sleep 2
		else
			echo "[AURA_INBOX] Not LPM, Try to Reset MS51." > /dev/kmsg
			echo 1 > /sys/class/leds/aura_inbox/MS51_reset
			sleep 0.2
			echo 0 > /sys/class/leds/aura_inbox/MS51_reset
			sleep 0.2
			echo 1 > /sys/class/leds/aura_inbox/MS51_reset
			sleep 2
		fi
		sleep 1

		echo 1 > /sys/class/leds/aura_inbox/ap2ld
		(( retry++ ))
	else
		echo "[AURA_INBOX] The wrong fw_mode $fw_mode retry time is ${retry}" > /dev/kmsg
		sleep 1
		(( retry++ ))
	fi
done
echo "[AURA_INBOX] MS51 fw_mode is wrong" > /dev/kmsg   # in this way, the ic may be destroyed.
setprop vendor.fandg.aura_fwupdate 2
