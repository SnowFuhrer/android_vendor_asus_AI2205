#!/vendor/bin/sh

#echo $0 > /dev/kmsg
echo "ASDF: Check LastShutdown log." > /dev/kmsg

#Check if there is an abnormal shutdown occured
abnormal_restart_prop='vendor.asus.abnormal_restart'
dd if=/dev/block/bootdevice/by-name/ftm of=/data/vendor/logcat_log/miniramdump_header.txt bs=4 count=2
var=$(cat /data/vendor/logcat_log/miniramdump_header.txt)
if test "$var" = "Raw_Dmp!"
then
	setprop $abnormal_restart_prop "warm"
	fext="$(date +%Y%m%d-%H%M%S).txt"
	dd if=/dev/block/bootdevice/by-name/ftm of=/asdf/LastShutdownCrash_$fext skip=5500184 ibs=1 count=262144
	cat /asdf/LastShutdownCrash_$fext | grep -C 500 "Kernel panic" > /asdf/last_kmsg
	chmod 666 /asdf/last_kmsg
	chown system:system /asdf/last_kmsg

	kernel_panic_flag=`grep -c "Kernel panic" /asdf/last_kmsg`
	if [ "${kernel_panic_flag}" != "0" ]; then
		setprop $abnormal_restart_prop "kernel_panic"
	fi

	echo "ASDF: Found Mini Dump!" > /proc/asusevtlog
	echo "MiniDump" > /data/vendor/logcat_log/miniramdump_header.txt
	dd if=/data/vendor/logcat_log/miniramdump_header.txt of=/dev/block/bootdevice/by-name/ftm bs=4 count=2
	rm /data/vendor/logcat_log/miniramdump_header.txt
else
	# Remove old logs
	if [ -e /asdf/last_kmsg ]; then
		rm /asdf/last_kmsg
	fi
fi

rawdump_enable=`getprop ro.boot.rawdump_en`
if [ "${rawdump_enable}" = "1" ]; then
	dd if=/dev/block/bootdevice/by-name/rawdump of=/data/vendor/logcat_log/ramdump_header.txt bs=4 count=2
	var=$(cat /data/vendor/logcat_log/ramdump_header.txt)
	if test "$var" = "Raw_Dmp!"
	then
		echo "ASDF: Found Full Dump!" > /dev/kmsg
	fi
fi

#echo "$0 EXIT" > /dev/kmsg
