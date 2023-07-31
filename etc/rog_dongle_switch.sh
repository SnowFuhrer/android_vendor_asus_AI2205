#!/vendor/bin/sh

type=`getprop vendor.asus.dongletype`
event=`getprop vendor.asus.dongleevent`
accy_gen=`getprop vendor.asus.accy.generation`
disable_inbox7_fw_update=`getprop vendor.asus.DisableInbox7Fwupdate`
disable_inbox6_fw_update=`getprop vendor.asus.DisableInbox6Fwupdate`

inbox_fwmode_path="/sys/class/leds/aura_inbox/fw_mode"
echo "[ROG_ACCY] DongleSwitch, type $type, accy_gen $accy_gen" > /dev/kmsg
retry=0
retry_tp=0
pdretry=0

function reset_accy_fw_ver(){
	setprop vendor.inbox.aura_fwver 0
	setprop vendor.asus.accy.fw_status 000000
	setprop vendor.asus.accy.fw_status2 000000
	setprop vendor.oem.asus.inboxid 0
}

# Define rmmod function
function remove_mod(){

	if [ -n "$1" ]; then
		echo "[ROG_ACCY] remove_mod $1" > /dev/kmsg
	else
		exit
	fi

	test=1
	while [ "$test" == 1 ]
	do
		rmmod $1
		ret=`lsmod | grep $1`
		if [ "$ret" == "" ]; then
			echo "[ROG_ACCY] rmmod $1 success" > /dev/kmsg
			test=0
		else
			echo "[ROG_ACCY] rmmod $1 fail" > /dev/kmsg
			test=1
			sleep 0.5
		fi
	done
}

function check_accy_fw_ver(){

	echo "[ROG_ACCY] Get Dongle FW Ver, type $type" > /dev/kmsg

	if [ "$type" == "1" ]; then
		if [ "$accy_gen" == "1" ]; then			# for factory test, it will be deleted later.
			setprop vendor.asus.accy.fw_status 000000
		else
			fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
			echo "[ROG_ACCY] InBox fw_mode =$fw_mode " > /dev/kmsg
			if [ "$fw_mode" == "1" ]; then
				inbox_unique_id=`cat /sys/class/leds/aura_inbox/unique_id`
				setprop vendor.oem.asus.inboxid $inbox_unique_id
				inbox_aura=`cat /sys/class/leds/aura_inbox/fw_ver`
				if [ "$inbox_aura" == "0x0000" ]; then
					sleep 0.35
				fi
				inbox_aura=`cat /sys/class/leds/aura_inbox/fw_ver`
				setprop vendor.inbox.aura_fwver $inbox_aura

				# check FW need update or not
				aura_fw=`getprop vendor.asusfw.inbox.aura_fwver`
				echo "[ROG_ACCY] InBox inbox_aura = $inbox_aura  aura_fw = $aura_fw"  > /dev/kmsg
				if [ "$inbox_aura" == "$aura_fw" ]; then
					setprop vendor.asus.accy.fw_status 000000
				elif [ "$inbox_aura" == "i2c_error" ]; then
					echo "[ROG_ACCY] InBox AURA_SYNC FW Ver Error" > /dev/kmsg
					setprop vendor.asus.accy.fw_status 000000
				else
					setprop vendor.asus.accy.fw_status 100000
				fi
			elif [ "$fw_mode" == "2" ]; then
				setprop vendor.asus.accy.fw_status 100000
			else # the wrong mode
				#Todo:reset
				fw_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
				if [ "$fw_mode" == "1" ]; then
					inbox_aura=`cat /sys/class/leds/aura_inbox/fw_ver`
					setprop vendor.inbox.aura_fwver $inbox_aura

					# check FW need update or not
					aura_fw=`getprop vendor.asusfw.inbox.aura_fwver`
					if [ "$inbox_aura" == "$aura_fw" ]; then
						setprop vendor.asus.accy.fw_status 000000
					elif [ "$inbox_aura" == "i2c_error" ]; then
						echo "[ROG_ACCY] InBox AURA_SYNC FW Ver Error" > /dev/kmsg
						setprop vendor.asus.accy.fw_status 000000
					else
						setprop vendor.asus.accy.fw_status 100000
					fi
				elif [ "$fw_mode" == "2" ]; then
					setprop vendor.asus.accy.fw_status 100000
				else
					echo "[ROG_ACCY] inbox fw_mode is wrong." > /dev/kmsg
				fi
			fi
		fi
	elif [ "$type" == "8" ]; then
		sleep 1
		inbox_unique_id=`cat /sys/class/leds/aura_inbox/unique_id`
		if [ "$inbox_unique_id" != "0x000000000000000000000000" ]; then
			echo "[ROG_ACCY] set Unique ID as $inbox_unique_id" > /dev/kmsg
			setprop vendor.oem.asus.inboxid $inbox_unique_id
		else
			echo "[ROG_ACCY] skip set Unique ID as $inbox_unique_id" > /dev/kmsg
		fi
		mcu_download_mode=`cat /sys/class/leds/aura_inbox/NUC1261_ap2ld`
		echo "[ROG_ACCY] get mcu_download_mode = $mcu_download_mode" > /dev/kmsg

		if [ "$mcu_download_mode" == "1" ]; then
			echo "[ROG_ACCY] MCU damage, force to update firmware" > /dev/kmsg
			setprop vendor.asus.accy.fw_status 010000
		else
			inbox_aura=`cat /sys/class/leds/aura_inbox/fw_ver`
			setprop vendor.inbox.aura_fwver $inbox_aura
			sleep 0.1
			inbox_mcu1261=`cat /sys/class/leds/aura_inbox/NUC1261_fw_ver`
			setprop vendor.inbox.inbox_fwver $inbox_mcu1261
			sleep 0.1
			inbox_pd=`cat /sys/class/leds/aura_inbox/pd_fw_ver`
			setprop vendor.inbox.pd_fwver $inbox_pd
			echo "[ROG_ACCY] Fandongle 6 ver: $inbox_mcu1261 $inbox_aura $inbox_pd" > /dev/kmsg

			# check FW need update or not
			aura_fw=`getprop vendor.asusfw.fandg6.aura_fwver`
			inbox_fw=`getprop vendor.asusfw.fandg6.inbox_fwver`
			pd_fw=`getprop vendor.asusfw.fandg6.pd_fwver`

			echo "[ROG_ACCY] asusfw = $aura_fw-$inbox_fw-$pd_fw" > /dev/kmsg
			echo "[ROG_ACCY] inboxfw = $inbox_aura-$inbox_mcu1261-$inbox_pd" > /dev/kmsg
			if [ "$inbox_aura" != "$aura_fw" ]; then
				#echo "[ROG_ACCY] update inbox Aura from [$inbox_aura] to [$aura_fw]" > /dev/kmsg
				inbox_aura_update="1"
			else
				inbox_aura_update="0"
			fi

			if [ "$inbox_mcu1261" != "$inbox_fw" ]; then
				#echo "[ROG_ACCY] update inbox MCU from [$inbox_mcu1261] to [$inbox_fw]" > /dev/kmsg
				inbox_mcu1261_update="1"
			else
				inbox_mcu1261_update="0"
			fi

			#if [ "$inbox_pd" != "$pd_fw" ]; then
			#	echo "[ROG_ACCY] update inbox PD" > /dev/kmsg
			#	inbox_pd_update="1"
			#else
			#	inbox_pd_update="0"
			#fi
			echo "[ROG_ACCY] PD update not support" > /dev/kmsg
			inbox_pd_update="0"

			#check fandg6 still exit or not
			sleep 0.2
			type=`getprop vendor.asus.dongletype`
			if [ "$type" != "8" ]; then
				echo "[ROG_ACCY] Fandongle disconnect, skip update firmware" > /dev/kmsg
				if [ "inbox_mcu1261" == "0x0000" ]; then
					inbox_mcu1261_update="0"
				fi
				if [ "inbox_aura_update" == "0x0000" ]; then
					inbox_aura_update="0"
				fi
			fi

			if [ "$disable_inbox6_fw_update" == "1" ]; then
				setprop vendor.asus.accy.fw_status  000000
				setprop vendor.asus.accy.fw_status2 000000
			else
				setprop vendor.asus.accy.fw_status "$inbox_aura_update""$inbox_mcu1261_update"0000
				setprop vendor.asus.accy.fw_status2 000000
			fi
		fi
	elif [ "$type" == "9" ]; then #Fandongle 7
		sleep 1
		inbox_unique_id=`cat /sys/class/leds/aura_inbox/unique_id`
		if [ "$inbox_unique_id" != "0x000000000000000000000000" ]; then
			echo "[ROG_ACCY] set Unique ID as $inbox_unique_id" > /dev/kmsg
			setprop vendor.oem.asus.inboxid $inbox_unique_id
		else
			echo "[ROG_ACCY] skip set Unique ID as $inbox_unique_id" > /dev/kmsg
		fi
		# get aura version
		echo 1 > /sys/class/leds/aura_inbox/ic_switch
		inbox7_aura_2led=`cat /sys/class/leds/aura_inbox/fw_ver`
		check_2led_version=`echo $inbox7_aura_2led | cut -c4-4`

		while [ "$check_2led_version" != 7 ]
		do
			echo "[ROG_ACCY] get 2led version $inbox7_aura_2led failed" > /dev/kmsg
			echo 1 > /sys/class/leds/aura_inbox/ic_switch
			inbox7_aura_2led=`cat /sys/class/leds/aura_inbox/fw_ver`
			check_2led_version=`echo $inbox7_aura_2led | cut -c4-4`
			if [ "$inbox7_aura_2led" == "0x0000" ]; then
				echo "[ROG_ACCY] 2led in download mode" > /dev/kmsg
				break;
			fi
		done

		echo 2 > /sys/class/leds/aura_inbox/ic_switch
		inbox7_aura_3led=`cat /sys/class/leds/aura_inbox/fw_ver`
		check_3led_version=`echo $inbox7_aura_3led | cut -c4-4`

		while [ "$check_3led_version" != 6 ]
		do
			echo "[ROG_ACCY] get 3led version $inbox7_aura_3led failed" > /dev/kmsg
			echo 2 > /sys/class/leds/aura_inbox/ic_switch
			inbox7_aura_3led=`cat /sys/class/leds/aura_inbox/fw_ver`
			check_3led_version=`echo $inbox7_aura_3led | cut -c4-4`
			if [ "$inbox7_aura_3led" == "0x0000" ]; then
				echo "[ROG_ACCY] 3led in download mode" > /dev/kmsg
				break;
			fi
		done

		# get pd version
		inbox7_pd=`cat /sys/class/leds/aura_inbox/pd_fw_date`

		echo "[ROG_ACCY] Fandongle 7 ver: $inbox7_aura_2led $inbox7_aura_3led $inbox7_pd" > /dev/kmsg
		# set inbox version
		setprop vendor.inbox7.2led_fwver $inbox7_aura_2led
		setprop vendor.inbox7.3led_fwver $inbox7_aura_3led
		setprop vendor.inbox7.pd_fwver $inbox7_pd

		aura_2led_fw=`getprop vendor.asusfw.fandg7.2led_fwver`
		aura_3led_fw=`getprop vendor.asusfw.fandg7.3led_fwver`
		pd_fw=`getprop vendor.asusfw.fandg7.pd_fwver`

		if [ "$inbox7_pd" != "$pd_fw" ]; then
			echo "[ROG_ACCY] should update inbox PD from $inbox7_pd to $pd_fw" > /dev/kmsg
			inbox_pd_update="1"
		else
			inbox_pd_update="0"
		fi

		check_3led_version=`echo $inbox7_aura_3led | cut -c4-4`
		if [ "$inbox7_aura_3led" == "0x0000" ]; then
			echo "[ROG_ACCY] force update 3led" > /dev/kmsg
			inbox7_3led_update="1"
		elif [ "$inbox7_aura_3led" == "0xffff" ]; then
			echo "[ROG_ACCY] MS51_3led maybe in LPM mode, skip firmware check" > /dev/kmsg
			inbox7_3led_update="0"
		elif [ "$check_3led_version" != "6" ]; then
			echo "[ROG_ACCY] get 3led version error, skip update firmware" > /dev/kmsg
			inbox7_3led_update="0"
		elif [ "$inbox7_aura_3led" != "$aura_3led_fw" ]; then
			echo "[ROG_ACCY] should update inbox 3LED from $inbox7_aura_3led to $aura_3led_fw" > /dev/kmsg
			inbox7_3led_update="1"
		else
			inbox7_3led_update="0"
		fi

		check_2led_version=`echo $inbox7_aura_2led | cut -c4-4`
		if [ "$inbox7_aura_2led" == "0x0000" ]; then
			echo "[ROG_ACCY] force update 2led" > /dev/kmsg
			inbox7_2led_update="1"
		elif [ "$inbox7_aura_2led" == "0xffff" ]; then
			echo "[ROG_ACCY] MS51_2led maybe in LPM mode, skip firmware check" > /dev/kmsg
			inbox7_2led_update="0"
		elif [ "$check_2led_version" != "7" ]; then
			echo "[ROG_ACCY] get 2led version error, skip update firmware" > /dev/kmsg
			inbox7_2led_update="0"
		elif [ "$inbox7_aura_2led" != "$aura_2led_fw" ] && [ "$inbox7_aura_2led" != "0xffff" ]; then
			echo "[ROG_ACCY] should update inbox 2LED from $inbox7_aura_2led to $aura_2led_fw" > /dev/kmsg
			inbox7_2led_update="1"
		else
			inbox7_2led_update="0"
		fi

		if [ "$disable_inbox7_fw_update" == "1" ]; then
			echo "[ROG_ACCY] Inbox7 Firmware update is disable!!!!!!!" > /dev/kmsg
			setprop vendor.asus.accy.fw_status 000000
			setprop vendor.asus.accy.fw_status2 000000
		else
			setprop vendor.asus.accy.fw_status "$inbox7_2led_update""$inbox7_3led_update""$inbox_pd_update"000
			setprop vendor.asus.accy.fw_status2 000000
		fi
	fi

	# initial autosuspend delay
	autosuspend_delay_ms=`getprop vendor.asus.autosuspend.delayms`
	echo $autosuspend_delay_ms > /sys/bus/usb/devices/2-1.1/power/autosuspend_delay_ms
	echo "[ROG_ACCY] set inbox autosuspend delay as $autosuspend_delay_ms ms" > /dev/kmsg

	fw_status=`getprop vendor.asus.accy.fw_status`
	fw_status2=`getprop vendor.asus.accy.fw_status2`

	echo "[ROG_ACCY] fw_status $fw_status, fw_status2 $fw_status2" > /dev/kmsg
	#echo "[ROG_ACCY] Get Dongle FW Ver done." > /dev/kmsg
}

if [ "$type" == "0" ]; then
	exit

elif [ "$type" == "1" ]; then
	echo "[ROG_ACCY][Switch] InBox" > /dev/kmsg

	if [ "$accy_gen" == "1" ]; then			# For JEDI dongle
		echo "[ROG_ACCY][Switch] This is ROG1 Inbox" > /dev/kmsg
	elif [ "$accy_gen" == "2" ]; then		# For YODA dongle
		echo "[ROG_ACCY][Switch] This is ROG2 Inbox" > /dev/kmsg
	elif [ "$accy_gen" == "3" ]; then		# For OBIWAN dongle
		echo "[ROG_ACCY][Switch] This is ROG3 Inbox" > /dev/kmsg
	elif [ "$accy_gen" == "5" ]; then		# For ANAKIN dongle
		echo "[ROG_ACCY][Switch] This is ROG5 Inbox" > /dev/kmsg
	else
		echo "[ROG_ACCY][Switch] Generation wrong, $accy_gen!!!!" > /dev/kmsg
		#echo 14 > /sys/class/ec_hid/dongle/device/sync_state	// Disabled at ROG6
		exit 0
	fi

	# Detect Inbox driver sysfs node
	if [ ! -f "$inbox_fwmode_path" ]; then
		echo "[ROG_ACCY][Switch] Inbox driver occur error!!! Maybe it is not 5nd inbox." > /dev/kmsg
		#echo 14 > /sys/class/ec_hid/dongle/device/sync_state	// Disabled at ROG6
		exit 0
	fi

	# Close Phone aura
	#echo 0 > /sys/class/leds/aura_sync/mode
	#echo 1 > /sys/class/leds/aura_sync/apply
	#echo 0 > /sys/class/leds/aura_sync/VDD

	# do not add any action behind here
	setprop vendor.asus.donglechmod 1
	#start DongleFWCheck
	check_accy_fw_ver;
	#echo 1 > /sys/class/ec_hid/dongle/device/sync_state	// Disabled at ROG6

elif [ "$type" == "7" ]; then
	echo "[ROG_ACCY][Switch] Not suuport ROG5 BackCover $type" > /dev/kmsg

elif [ "$type" == "8" ]; then
	echo "[ROG_ACCY][Switch] FANDG 6" > /dev/kmsg
	# do not add any action behind here
	setprop vendor.asus.donglechmod 8
	#start DongleFWCheck
	check_accy_fw_ver;
	start rpm_monitor
elif [ "$type" == "9" ]; then
	echo "[ROG_ACCY][Switch] FANDG 7" > /dev/kmsg
	# do not add any action behind here
	setprop vendor.asus.donglechmod 9
	#start DongleFWCheck
	check_accy_fw_ver;
	start rpm_monitor
else
	echo "[ROG_ACCY][Switch] Error Type $type" > /dev/kmsg
	#echo 0 > /sys/class/ec_hid/dongle/device/pogo_mutex
fi
