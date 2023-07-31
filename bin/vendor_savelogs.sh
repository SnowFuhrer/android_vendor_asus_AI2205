#!/vendor/bin/sh

# For UTS/LogUploader save vendor logs 
#echo $0 > /dev/kmsg

# check mount file
	umask 0;
	sync

savelogs_prop=`getprop persist.vendor.asus.savelogs`
echo "$0: persist.vendor.asus.savelogs= $savelogs_prop"

# which folder sepolicy type is file_type
VENDOR_DATA_TMP=/logbuf
mkdir -p $VENDOR_DATA_TMP
chmod -R 777 $VENDOR_DATA_TMP

# copy vendor data file function
function move_vendor_logs(){
	chmod -R 777 $VENDOR_FOLDER
	echo "$0: type $1"
	cat $LOG_LIST | while read line; do
		mkdir -p $VENDOR_DATA_TMP/$1
		chmod -R 777 $VENDOR_DATA_TMP/$1
		echo "UTS: move_vendor_logs: file $line" > /dev/kmsg
		cp $line $VENDOR_DATA_TMP/$1/
		start log_mover
		#check log_mover stopped
		while : ; do
			sleep 1
			if test -e "$VENDOR_DATA_TMP/ls_vendor_data_tmp.txt"; then
				echo "$0: log_mover is running..."
			else
				if test -d "$VENDOR_DATA_TMP/$1"; then
					echo "$0: log_mover is running.."
				else
					echo "$0: log_mover is stopped."
					break
				fi
			fi
		done
		echo "$0: -------"
	done
}
###########################################################################################
# Minidump
function cp_minidump(){
dd if=/dev/block/bootdevice/by-name/ftm of=/data/vendor/logcat_log/miniramdump_header.txt bs=4 count=2
var=$(cat /data/vendor/logcat_log/miniramdump_header.txt)
if test "$var" = "MiniDump"
then
	echo "ASDF: Capture Mini Dump!" > /proc/asusevtlog
	echo "Raw_Dmp!" > /data/vendor/logcat_log/miniramdump_header.txt
	dd if=/data/vendor/logcat_log/miniramdump_header.txt of=/dev/block/bootdevice/by-name/ftm bs=4 count=2

	dd if=/dev/block/bootdevice/by-name/ftm of=/data/vendor/logcat_log/MiniRawRamDump.bin
	tar -czvf /data/vendor/logcat_log/MiniRawRamDump.tgz /data/vendor/logcat_log/MiniRawRamDump.bin

	rm /data/vendor/logcat_log/MiniRawRamDump.bin
	rm /data/vendor/logcat_log/miniramdump_header.txt
	dd if=/dev/zero of=/dev/block/bootdevice/by-name/ftm bs=4 count=2

echo "UTS: cp_minidump" > /dev/kmsg
VENDOR_FOLDER=/data/vendor/logcat_log
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
find $VENDOR_FOLDER -type f > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
chmod -R 777 $VENDOR_FOLDER
# start log_mover
move_vendor_logs minidump
echo "$0: cp -r /data/vendor/logcat_log/"
fi
rm -r /data/vendor/logcat_log/*
}
###########################################################################################
# TZ logs
function cp_tz_logs(){
timeout 5 cat /proc/tzdbg/log > /data/vendor/logcat_log/tz_log.txt
timeout 5 cat /proc/tzdbg/qsee_log > /data/vendor/logcat_log/qsee_log.txt
timeout 5 cat /proc/tzdbg/hyp_log > /data/vendor/logcat_log/hyp_log.txt
echo "UTS: cp_tz_logs" > /dev/kmsg
VENDOR_FOLDER=/data/vendor/logcat_log
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
find $VENDOR_FOLDER -type f > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
chmod -R 777 $VENDOR_FOLDER
# start log_mover
move_vendor_logs tz_logs
echo "$0: cp -r /data/vendor/logcat_log/"
rm -r /data/vendor/logcat_log/*
}
###########################################################################################
# WIFI/wlan_logs
function cp_wlan_logs(){
echo "UTS: cp_wlan_logs" > /dev/kmsg
VENDOR_FOLDER=/data/vendor/wifi/wlan_logs
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
find $VENDOR_FOLDER -type f > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
chmod -R 777 $VENDOR_FOLDER
# start log_mover
move_vendor_logs wlan_logs
echo "$0: cp -r /data/vendor/wifi/wlan_logs"
rm -rf /data/vendor/wifi/wlan_logs/*
}

function cp_wifi_config(){
echo "UTS: cp_wifi_config" > /dev/kmsg
#WIFI/hostapd
VENDOR_FOLDER=/data/vendor/wifi/hostapd
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
find $VENDOR_FOLDER -type f -name "*.conf" > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
chmod -R 777 $VENDOR_FOLDER
# start log_mover
move_vendor_logs wifi_config
echo "$0: cp -r /data/vendor/wifi/hostapd"

#WIFI/wpa
VENDOR_FOLDER=/data/vendor/wifi/wpa
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
find $VENDOR_FOLDER -type f -name "*.conf" > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
chmod -R 777 $VENDOR_FOLDER
# start log_mover
move_vendor_logs wifi_config
echo "$0: cp -r /data/vendor/wifi/wpa"
}
###########################################################################################
# Bluetooth/ssrdump
function cp_bt_ssrdump(){
echo "UTS: cp_bt_ssrdump" > /dev/kmsg
VENDOR_FOLDER=/data/vendor/ssrdump
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
find $VENDOR_FOLDER -type f > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
chmod -R 777 $VENDOR_FOLDER
# start log_mover
move_vendor_logs btsnoop
rm -rf /data/vendor/ssrdump/*.*
echo "$0: cp -r /data/vendor/ssrramdump"
}
###########################################################################################
# SSR ramdump
function cp_ssr_ramdump(){
echo "UTS: cp_ssr_ramdump" > /dev/kmsg
VENDOR_FOLDER=/data/vendor/ramdump/ssr_ramdump
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
chmod -R 777 $VENDOR_FOLDER
find $VENDOR_FOLDER -type f > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
# start log_mover
move_vendor_logs ssr_ramdump
rm -rf /data/vendor/ramdump/ssr_ramdump/
echo "$0: cp -r /data/vendor/ramdump/ssr_ramdump"
}
###########################################################################################
# QXDM/diag_logs
function cp_diag_logs(){
echo "UTS: cp_diag_logs" > /dev/kmsg
VENDOR_FOLDER=/data/vendor/ramdump/diag_logs
echo "$0: ++++ VENDOR_FOLDER=$VENDOR_FOLDER ++++"
chmod -R 777 $VENDOR_FOLDER
find $VENDOR_FOLDER -type f > $VENDOR_FOLDER/filelist.txt
LOG_LIST=$VENDOR_FOLDER/filelist.txt
# start log_mover
move_vendor_logs diag_logs
rm -rf /data/vendor/ramdump/diag_logs/*
echo "$0: cp -r /data/vendor/ramdump/diag_logs"
}
###########################################################################################
function clean_internal_folder(){
	echo "UTS: clean_internal_folder" > /dev/kmsg
	rm -rf /data/vendor/wifi/wlan_logs/*
	rm -rf /data/vendor/ramdump/diag_logs/QXDM_logs/*.*
	rm -rf /data/vendor/tombstones/SDX55M/*.*
	rm -rf /data/vendor/ssrdump/*.*
	rm -r /data/vendor/ramdump/bluetooth/*.*
}
###########################################################################################
#add to stop and then capture modem log problem
function stop_qxdmlog(){
	enableQXDM=`getprop persist.logd.qxdmlog.enable`
	echo "$0: persist.logd.qxdmlog.enable=$enableQXDM"
	if [ "${enableQXDM}" = "1" ]; then
		setprop vendor.logd.qxdmlog.enable 0
		echo "UTS: Turn off QXDM log for savelog" > /dev/kmsg
		sleep 1
		sync
	fi
}

function start_qxdmlog(){
	if [ "${enableQXDM}" = "1" ]; then
		setprop vendor.logd.qxdmlog.enable 1
		echo "UTS: Turn on QXDM log for savelog" > /dev/kmsg
	fi
	setprop vendor.logd.qxdmlog.enable ""
	QXDM_tag=`getprop vendor.logd.qxdmlog.enable`
	echo "$0: vendor.logd.qxdmlog.enable=$QXDM_tag"
}
##############################################################################################
if [ ".$savelogs_prop" == ".5" ]; then
	# Phone, signal and mobile networks
	stop_qxdmlog
	cp_diag_logs
	cp_ssr_ramdump
	start_qxdmlog

	cp_wlan_logs
	cp_wifi_config

	cp_minidump
	cp_tz_logs
elif [ ".$savelogs_prop" == ".6" ]; then
	# WIFI
	stop_qxdmlog
	cp_diag_logs
	cp_ssr_ramdump
	start_qxdmlog

	cp_wlan_logs
	cp_wifi_config

	cp_minidump
	cp_tz_logs
elif [ ".$savelogs_prop" == ".7" ]; then
	# BT
	stop_qxdmlog
	cp_diag_logs
	start_qxdmlog

	cp_bt_ssrdump
	cp_wlan_logs
	cp_wifi_config

	cp_minidump
	cp_tz_logs
elif [ ".$savelogs_prop" == ".8" ]; then
	# Location services
	stop_qxdmlog
	cp_diag_logs
	start_qxdmlog

	cp_minidump
	cp_tz_logs
elif [ ".$savelogs_prop" == ".9" ]; then
	# Audio, scound recording, call audio
	stop_qxdmlog
	cp_diag_logs
	start_qxdmlog

	cp_minidump
	cp_tz_logs
elif [ ".$savelogs_prop" == ".10" ]; then
	# General
	cp_bt_ssrdump
	cp_wlan_logs
	cp_wifi_config

	cp_minidump
	cp_tz_logs
elif [ ".$savelogs_prop" == ".99" ]; then
	clean_internal_folder
fi
###########################################################################################
sync
start savelogs
echo "$0: DONE!!!"
exit
