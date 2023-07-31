#!/vendor/bin/sh

type=`getprop vendor.asus.dongletype`
sleep 3
echo "[ROG_ACCY] Get Dongle FW Ver, type $type" > /dev/kmsg

function aura_i2c_addr_check() {
	echo "[AURA_INBOX] i2c_addr_check" > /dev/kmsg
	echo 1 > /sys/class/leds/aura_inbox/ap2ld

	#choose 0x16 address
	echo 5 > /sys/class/leds/aura_inbox/ic_switch
	sleep 4
	ms51_mode=`cat /sys/class/leds/aura_inbox/fw_mode`
	if [ "${ms51_mode}" == "2" ]; then
		echo "[AURA_INBOX] ms51 i2c address is 0x16" > /dev/kmsg
		echo 1 > /sys/class/leds/aura_inbox/ld2ap
		ms51_addr=16
	else
		echo "[AURA_INBOX] ms51 i2c address is 0x18" > /dev/kmsg
		echo 1 > /sys/class/leds/aura_inbox/ld2ap
		echo 2 > /sys/class/leds/aura_inbox/ic_switch
		ms51_addr=18
	fi
}

if [ "$type" == "0" ]; then
#	phone_aura=`cat /sys/class/leds/aura_sync/fw_ver`
#	setprop sys.phone.aura_fwver $phone_aura

	setprop vendor.inbox.aura_fwver 0
	
	setprop vendor.asus.accy.fw_status 000000
	setprop vendor.asus.accy.fw_status2 000000
elif [ "$type" == "1" ]; then
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
elif [ "$type" == "8" ]; then
	mcu_download_mode=`cat /sys/class/leds/aura_inbox/NUC1261_ap2ld`
	echo "[ROG_ACCY] get mcu_download_mode = $mcu_download_mode" > /dev/kmsg

	if [ "$mcu_download_mode" == "1" ]; then
		echo "[ROG_ACCY] MCU damage, force to update firmware" > /dev/kmsg
		setprop vendor.asus.accy.fw_status 010000
	else
		aura_i2c_addr_check;
		inbox_aura=`cat /sys/class/leds/aura_inbox/fw_ver`
		setprop vendor.inbox.aura_fwver $inbox_aura
		sleep 0.5
		inbox_mcu1261=`cat /sys/class/leds/aura_inbox/NUC1261_fw_ver`
		setprop vendor.inbox.inbox_fwver $inbox_mcu1261
		sleep 0.5
		inbox_pd=`cat /sys/class/leds/aura_inbox/pd_fw_ver`
		setprop vendor.inbox.pd_fwver $inbox_pd
		sleep 0.5
		inbox_unique_id=`cat /sys/class/leds/aura_inbox/unique_id`
		setprop vendor.oem.asus.inboxid $inbox_unique_id
		echo "[ROG_ACCY] Fandongle 6 ver: $inbox_mcu1261 $inbox_aura $inbox_pd" > /dev/kmsg

		# check FW need update or not
		aura_fw=`getprop vendor.asusfw.fandg6.aura_fwver`
		inbox_fw=`getprop vendor.asusfw.fandg6.inbox_fwver`
		pd_fw=`getprop vendor.asusfw.fandg6.pd_fwver`

		#echo "[ROG_ACCY] asusfw = $aura_fw-$inbox_fw-$pd_fw" > /dev/kmsg
		#echo "[ROG_ACCY] inboxfw = $inbox_aura-$inbox_mcu1261-$inbox_pd" > /dev/kmsg
		if [ "$inbox_aura" == "$aura_fw" ] && [ "$inbox_mcu1261" == "$inbox_fw" ] && [ "$inbox_pd" == "$pd_fw" ]; then
			echo "[ROG_ACCY] InBox no need to update" > /dev/kmsg
			setprop vendor.asus.accy.fw_status 000000
			exit
		fi

		#=======================================================================
		#Check MS51 firmware need update or not
		#=======================================================================
		if [ "$inbox_aura" == "i2c_error" ] || [ ! -n "$inbox_aura" ] || [ ! -n "$aura_fw" ]; then
			echo "[ROG_ACCY] get aura version error" > /dev/kmsg
			Aura_need_update=0
		elif [ "$inbox_aura" == "0x0000" ]; then
			inbox_aura=`cat /sys/class/leds/aura_inbox/fw_ver`
			get_mode_retry=5;
			while [ "$inbox_aura" == "0x0000" ] && [ $get_mode_retry -gt 0 ]
			do
				sleep 1
				inbox_aura=`cat /sys/class/leds/aura_inbox/fw_ver`
				(( get_mode_retry-- ))
				echo "[AURA_INBOX] get ms51 = $inbox_aura, retry = $get_mode_retry" > /dev/kmsg
			done

			if [ "$inbox_aura" == "0x0000" ] && [ $get_mode_retry -eq 0 ]; then
				echo "[ROG_ACCY] ms51 couldn't enter APROM, need update" > /dev/kmsg
				Aura_need_update=1
			else
				Aura_need_update=0
			fi
		elif [ "$inbox_aura" != "$aura_fw" ]; then
			echo "[ROG_ACCY] update inbox Aura from [$inbox_aura] to [$aura_fw]" > /dev/kmsg
			Aura_need_update=1
		elif [ "$inbox_aura" == "$aura_fw" ]; then
			echo "[ROG_ACCY] AURA isn't need update" > /dev/kmsg
			Aura_need_update=0
		fi
		#=======================================================================

		#=======================================================================
		#Check MCU firmware need update or not
		#=======================================================================
		if [ "$inbox_mcu1261" == "i2c_error" ] || [ ! -n "$inbox_mcu1261" ] || [ ! -n "$inbox_fw" ]; then
			echo "[ROG_ACCY] get mcu version error" > /dev/kmsg
			Mcu_need_update=0
		elif [ "$inbox_mcu1261" != "$inbox_fw" ]; then
			echo "[ROG_ACCY] update inbox MCU from [$inbox_mcu1261] to [$inbox_fw]" > /dev/kmsg
			Mcu_need_update=1
		elif [ "$inbox_mcu1261" == "$inbox_fw" ]; then
			echo "[ROG_ACCY] MCU isn't need update" > /dev/kmsg
			Mcu_need_update=0
		fi
		#=======================================================================

		#=======================================================================
		#Check PD firmware need update or not
		#=======================================================================
		if [ "$inbox_pd" == "i2c_error" ] || [ ! -n "$inbox_pd" ] || [ ! -n "$pd_fw" ]; then
			echo "[ROG_ACCY] get pd version error, current ver: $inbox_pd, target ver: $pd_fw" > /dev/kmsg
			PD_need_update=0
		elif [ "$inbox_pd" != "$pd_fw" ]; then
			echo "[ROG_ACCY] update inbox PD" > /dev/kmsg
			PD_need_update=1
		elif [ "$inbox_pd" == "$pd_fw" ]; then
			echo "[ROG_ACCY] PD isn't need update" > /dev/kmsg
			PD_need_update=0
		fi
		#=======================================================================

#		if [ "$Aura_need_update" == "1" ] && [ "$Mcu_need_update" == "1" ] && [ "$PD_need_update" == "1" ]; then
#			setprop vendor.asus.accy.fw_status 111000
#		elif [ "$Aura_need_update" == "1" ] && [ "$Mcu_need_update" == "1" ] && [ "$PD_need_update" == "0" ]; then
#			setprop vendor.asus.accy.fw_status 110000
#		elif [ "$Aura_need_update" == "1" ] && [ "$Mcu_need_update" == "0" ] && [ "$PD_need_update" == "1" ]; then
#			setprop vendor.asus.accy.fw_status 101000
#		elif [ "$Aura_need_update" == "0" ] && [ "$Mcu_need_update" == "1" ] && [ "$PD_need_update" == "1" ]; then
#			setprop vendor.asus.accy.fw_status 011000
#		elif [ "$Aura_need_update" == "1" ] && [ "$Mcu_need_update" == "0" ] && [ "$PD_need_update" == "0" ]; then
#			setprop vendor.asus.accy.fw_status 100000
#		elif [ "$Aura_need_update" == "0" ] && [ "$Mcu_need_update" == "1" ] && [ "$PD_need_update" == "0" ]; then
#			setprop vendor.asus.accy.fw_status 010000
#		elif [ "$Aura_need_update" == "0" ] && [ "$Mcu_need_update" == "0" ] && [ "$PD_need_update" == "1" ]; then
#			setprop vendor.asus.accy.fw_status 001000
#		else
#			echo "[ROG_ACCY] InBox no need to update" > /dev/kmsg
#			setprop vendor.asus.accy.fw_status 000000
#		fi

		if [ "$Aura_need_update" == "1" ] && [ "$Mcu_need_update" == "1" ]; then
			setprop vendor.asus.accy.fw_status 110000
		elif [ "$Aura_need_update" == "1" ]; then
			setprop vendor.asus.accy.fw_status 100000
		elif [ "$Mcu_need_update" == "1" ]; then
			setprop vendor.asus.accy.fw_status 010000
		else
			echo "[ROG_ACCY] InBox no need to update" > /dev/kmsg
			setprop vendor.asus.accy.fw_status 000000
		fi

		fw_status=`getprop vendor.asus.accy.fw_status`
		echo "[ROG_ACCY] set fw_status=$fw_status" > /dev/kmsg

	fi
fi

echo "[ROG_ACCY] Get Dongle FW Ver done." > /dev/kmsg
