#!/vendor/bin/sh

type=`cat /sys/class/ec_hid/dongle/device/gDongleType`

FW_VER=`cat /vendor/firmware/FW_version.txt | grep Aura_FW | cut -d ':' -f 2`
setprop vendor.asusfw.phone.aura_fwver $FW_VER

#if [ "$type" != "0" ]; then
#	echo "[AURA_SYNC] In accy $type, skip update." > /dev/kmsg
#	setprop vendor.phone.aura_fwupdate 0
#	exit
#fi

echo "[AURA_MS51] gDongleType is $type" > /dev/kmsg
echo "[AURA_MS51] Enable VDD" > /dev/kmsg
echo 1 > /sys/class/leds/aura_sync/VDD
sleep 1

FW_PATH="/vendor/asusfw/aura_sync/Asus_ROG_LED_MS51.bin"
FW_PATH_TMP="/vendor/firmware/Asus_ROG_LED_MS51.bin"
fw_ver=`cat /sys/class/leds/aura_sync/fw_ver`
aura_fw=`getprop vendor.asusfw.phone.aura_fwver`

echo "[AURA_MS51] aura_fw : ${aura_fw}" > /dev/kmsg
echo "[AURA_MS51] fw_ver : ${fw_ver}" > /dev/kmsg

function Update() {
	fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
	if [ "${fw_mode}" == "2" ]; then
		echo "[AURA_MS51] It is in LD mode, we will try to flash the AP FW" > /dev/kmsg
		echo "[AURA_MS51] Start MS51 FW update" > /dev/kmsg
	    echo $FW_PATH_TMP > /sys/class/leds/aura_sync/fw_update
	else # AP mode,fw_mode=1
		echo 1 > /sys/class/leds/aura_sync/ap2ld
		sleep 1
		fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
		if [ "${fw_mode}" == "2" ]; then
			echo "[AURA_MS51] It is in LD mode, we will try to update the AP FW" > /dev/kmsg
			echo "[AURA_MS51] Start MS51 FW update" > /dev/kmsg
	        echo $FW_PATH_TMP > /sys/class/leds/aura_sync/fw_update
		else
			echo "[AURA_MS51] AP mode -> LD mode failed" > /dev/kmsg
		fi
	fi
	sleep 1
}

function Check_last_fwupdate() {
	fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
	if [ "${fw_mode}" == "2" ]; then
		echo "[AURA_MS51] MS51 update failed for 2 times, it is still in ld mode" > /dev/kmsg
		setprop vendor.phone.aura_fwupdate 2
	elif [ "${fw_mode}" == "1" ]; then
		fw_ver=`cat /sys/class/leds/aura_sync/fw_ver`
		echo "[AURA_MS51] after second update fw_ver = $fw_ver" > /dev/kmsg
		echo "[AURA_MS51] aura_fw= $aura_fw" > /dev/kmsg
		if [ "${fw_ver}" != "${aura_fw}" ]; then
			echo "[AURA_MS51] MS51 update failed for 2 times, and it is now in ap mode." > /dev/kmsg
			setprop vendor.phone.aura_fwupdate 2
		else
			setprop vendor.phone.aura_fwver $fw_ver
			setprop vendor.phone.aura_fwupdate 0
		fi
	else
		echo "[AURA_MS51] MS51 update failed for 2 times, and it is now in unknown mode." > /dev/kmsg
		setprop vendor.phone.aura_fwupdate 2
	fi
}

retry=0

while [ "$retry" -le 5 ]  # the most retry times is 5
do
	fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`

	if [ "${fw_mode}" == "2" ]; then
		echo "[AURA_MS51] LD mode,aura_fw= $aura_fw, 1st update start." > /dev/kmsg
		Update;
		fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
		if [ "${fw_mode}" == "1" ]; then
			fw_ver=`cat /sys/class/leds/aura_sync/fw_ver`
			echo "[AURA_MS51] after first update fw_ver = $fw_ver" > /dev/kmsg
			echo "[AURA_MS51] aura_fw= $aura_fw" > /dev/kmsg
			if [ "${fw_ver}" != "${aura_fw}" ]; then
				echo "[AURA_MS51] MS51 update fail, we will retry a time." > /dev/kmsg

				#Todo: reset 
				echo 0 > /sys/class/leds/aura_sync/VDD
				sleep 0.2
				echo 1 > /sys/class/leds/aura_sync/VDD
				sleep 0.5

				fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
				if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
					Update;
					Check_last_fwupdate;
					exit 0;
				else #no need second update
					echo "[AURA_MS51]it is now in an unknown mode after the first failure and reset" > /dev/kmsg
					setprop vendor.phone.aura_fwupdate 2
					exit 0;
				fi	
			else
				setprop vendor.phone.aura_fwver $fw_ver
				setprop vendor.phone.aura_fwupdate 0  #update success at the first time
				exit 0;
			fi

		else # in ld mode or in an known mode. we will retry
			echo "[AURA_MS51] MS51 update fail. Second update start."> /dev/kmsg

			#Todo: reset
			echo 0 > /sys/class/leds/aura_sync/VDD
			sleep 0.2
			echo 1 > /sys/class/leds/aura_sync/VDD
			sleep 0.5

			fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
			if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
				Update;
				Check_last_fwupdate;
				exit 0;
			else #no need second update
				echo "[AURA_MS51]it is now in an unknown mode after the first failure and reset" > /dev/kmsg
				setprop vendor.phone.aura_fwupdate 2
				exit 0;
			fi
		fi

	elif [ "${fw_mode}" == "1" ]; then
		fw_ver=`cat /sys/class/leds/aura_sync/fw_ver`

		if [ "${fw_ver}" != "${aura_fw}" ]; then
			echo "[AURA_MS51] fw_ver = $fw_ver" > /dev/kmsg
			echo "[AURA_MS51] aura_fw= $aura_fw. 1st update start." > /dev/kmsg

			Update;
			fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
			if [ "${fw_mode}" == "1" ]; then
				fw_ver=`cat /sys/class/leds/aura_sync/fw_ver`
				echo "[AURA_MS51] after first update fw_ver = $fw_ver" > /dev/kmsg
				echo "[AURA_MS51] aura_fw= $aura_fw" > /dev/kmsg
				if [ "${fw_ver}" != "${aura_fw}" ]; then
					echo "[AURA_MS51] MS51 update fail, we will retry a time." > /dev/kmsg

					#Todo: reset 
					echo 0 > /sys/class/leds/aura_sync/VDD
					sleep 0.2
					echo 1 > /sys/class/leds/aura_sync/VDD
					sleep 0.5

					fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
					if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
						Update;
						Check_last_fwupdate;
						exit 0;
					else #no need second update
						echo "[AURA_MS51]it is now in an unknown mode after the first failure and reset" > /dev/kmsg
						setprop vendor.phone.aura_fwupdate 2
						exit 0;
					fi
				else
					setprop vendor.phone.aura_fwver $fw_ver
					setprop vendor.phone.aura_fwupdate 0  #update success at the first time
					exit 0;
				fi
			else # in ld mode or in an known mode. we will retry
				echo "[AURA_MS51] MS51 update fail. Second update start."> /dev/kmsg

				#Todo:reset
				echo 0 > /sys/class/leds/aura_sync/VDD
				sleep 0.2
				echo 1 > /sys/class/leds/aura_sync/VDD
				sleep 0.5

				fw_mode=`cat /sys/class/leds/aura_sync/fw_mode`
				if [ "${fw_mode}" == "2" -o "${fw_mode}" == "1" ]; then
					Update;
					Check_last_fwupdate;
					exit 0;
				else #no need second update
					echo "[AURA_MS51]it is now in an unknown mode after the first failure and reset" > /dev/kmsg
					setprop vendor.phone.aura_fwupdate 2
					exit 0;
				fi
			fi

		else
			echo "[AURA_MS51] No need update" > /dev/kmsg
			setprop vendor.phone.aura_fwver $fw_ver
			setprop vendor.phone.aura_fwupdate 0
			exit 0;
		fi
	else
		echo "[AURA_MS51] The wrong fw_mode $fw_mode retry time is ${retry}" > /dev/kmsg

		#Todo: reset
		echo 0 > /sys/class/leds/aura_sync/VDD
		sleep 0.2
		echo 1 > /sys/class/leds/aura_sync/VDD
		sleep 0.5

		retry=$((retry + 1 ))
	fi
done
echo "[AURA_MS51] MS51 fw_mode is wrong" > /dev/kmsg   # in this way, the ic may be destroyed.
setprop vendor.phone.aura_fwupdate 2

