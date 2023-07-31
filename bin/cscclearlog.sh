#!/vendor/bin/sh

echo "Start clear csc log"
LOG_MODEM_FOLDER='/data/vendor/ramdump/diag_logs'

#rm wlan_logs log
wait_cmd=`rm -rf /data/vendor/wifi/wlan_logs/*`
sync
echo "rm -rf /data/vendor/wifi/wlan_logs/*"

#rm QXDM logs
if [ -d "/data/vendor/ramdump/diag_logs" ]; then
	#add to stop and then capture modem log problem
	enableQXDM=`getprop persist.logd.qxdmlog.enable`
	echo "$0: persist.logd.qxdmlog.enable=$enableQXDM"
	if [ "${enableQXDM}" = "1" ]; then
		setprop vendor.logd.qxdmlog.enable 0
		echo "Turn off QXDM log for clear log" > /dev/kmsg
		sleep 1
		sync
	fi

	#rm QXDM log
	chmod -R 777 $LOG_MODEM_FOLDER
	wait_cmd=`rm -rf /data/vendor/ramdump/diag_logs`
	sync

	#add to stop and then capture modem log problem
	if [ "${enableQXDM}" = "1" ]; then
		setprop vendor.logd.qxdmlog.enable 1
		echo "Turn on QXDM log for clear log" > /dev/kmsg
	fi
	setprop vendor.logd.qxdmlog.enable ""
	QXDM_tag=`getprop vendor.logd.qxdmlog.enable`
	echo "$0: vendor.logd.qxdmlog.enable=$QXDM_tag"
fi

start cscclearlog_sys
