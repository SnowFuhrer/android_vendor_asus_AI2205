#!/vendor/bin/sh

type=`getprop vendor.asus.dongletype`

echo "[ROG_ACCY] ROG DongleRemove, type $type" > /dev/kmsg
echo "[ROG_ACCY][Remove] No Dongle" > /dev/kmsg
echo "[ROG_ACCY][Remove] stop ROGaccySwitch" > /dev/kmsg
stop ROGaccySwitch

# Define rmmod function
function remove_mod(){

	if [ -n "$1" ]; then
		echo "[ROG_ACCY] remove_mod $1" > /dev/kmsg
	else
		exit
	fi

	test=1
	retry=1
	while [ "$test" == 1 -a "$retry" -le "5" ]
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
		((retry++))
	done
}

# Remove all driver
#remove_mod ms51_backcover

# do not add any action behind here
setprop vendor.asus.donglechmod 0

# Fandongle7: if remove when firmware updating reset fwupdate
#aura_2led_update_status=`getprop vendor.fandg7.2led_fwupdate`
#aura_3led_update_status=`getprop vendor.fandg7.3led_fwupdate`
#pd_update_status=`getprop vendor.fandg7.pd_fwupdate`

#if [ "$aura_2led_update_status" == "1" ]; then
#	setprop vendor.fandg7.2led_fwupdate 0
#fi
#if [ "$aura_3led_update_status" == "1" ]; then
#	setprop vendor.fandg7.3led_fwupdate 0
#fi
#if [ "$pd_update_status" == "1" ]; then
#	setprop vendor.fandg7.pd_fwupdate 0
#fi
# Fandongle7: if remove when firmware updating reset fwupdate
#setprop vendor.fandg7.2led_fwupdate -1
#setprop vendor.fandg7.3led_fwupdate -1
#setprop vendor.fandg7.pd_fwupdate -1


# reset fandongle 7 firmware version
setprop vendor.inbox7.2led_fwver 0
setprop vendor.inbox7.3led_fwver 0
setprop vendor.inbox7.pd_fwver 0

# force reset accy FW
setprop vendor.inbox.aura_fwver 0
setprop vendor.inbox.inbox_fwver 0
setprop vendor.inbox.pd_fwver 0
setprop vendor.asus.accy.fw_status 000000
setprop vendor.asus.accy.fw_status2 000000
#setprop vendor.oem.asus.inboxid 0

# CSC reset
setprop persist.vendor.asus.coolerstage_csc -1
# Send uevent to FrameWork
#echo 0 > /sys/class/ec_hid/dongle/device/sync_state
