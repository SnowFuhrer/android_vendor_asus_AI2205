#!/vendor/bin/sh

#echo $0 > /dev/kmsg

#[Setup log & env]
log_head='ASDF'
action_log='/dev/console'		#set /dev/null to turn off log
log_root='/asdf/ASDF'	#Abnormal Shutdown Data Files
trigger_log="$log_root/Total_Recall.txt"
trigger_old="$log_root.old/Total_Recall.txt"
log_dir="$log_root/ASDF"
log_old="$log_root.old/ASDF"
max_log=20

#build_type=`getprop ro.build.type`
#logupload=`getprop persist.asus.autoupload.enable`
android_boot=`getprop sys.boot_completed`
is_factory=`getprop ro.boot.ftm`

android_reboot_prop='vendor.debug.asus.android_reboot'
android_reboot=`getprop $android_reboot_prop`

slot_suffix=`getprop ro.boot.slot_suffix`
csc_version=`getprop ro.vendor.build.csc.version`

version_number_prob='ro.vendor.build.version.incremental'
version_number=`getprop $version_number_prob`

if [ ".$android_reboot" == "." ]; then
	if [ -e $log_root ]; then
		echo "$log_head: found log_root=$log_root" > $action_log
	else
		echo "$log_head: creating log_root=$log_root" > $action_log
		mkdir $log_root
	fi
fi

if [ ".$android_boot" == ".1" ]; then
	if [ ".$android_reboot" == "." ]; then
		setprop $android_reboot_prop 0
		echo "Booting from:"$slot_suffix > /proc/asusevtlog
# [KEY] +++ Remove key.xml and KMKEY
		if [ -f "/mnt/vendor/persist/key.xml" ]; then
			rm /mnt/vendor/persist/key.xml
		fi

		if [ -f "/mnt/vendor/persist/KMKEY" ]; then
			rm /mnt/vendor/persist/KMKEY
		fi
# [KEY] --- Remove key.xml and KMKEY
		echo "$log_head: 1st boot_completed...." > $action_log
		echo "$log_head: 1st boot_completed...." > /proc/asusevtlog
		if [ "$is_factory" == "1" ]; then
			echo "Image version: $version_number" > /proc/asusevtlog
		else
			echo "CSC version: $csc_version" > /proc/asusevtlog
		fi

		# Check bootcount
		if test -e "/asdf/bootcount"; then
			var=$( cat /asdf/bootcount )
			var=$(($var+1))
			echo ${var}>/asdf/bootcount
			setprop vendor.asus.bootcount ${var}
		else
			echo 1 >/asdf/bootcount
			setprop vendor.asus.bootcount 1
		fi

		fcount=0
		lastShutdownCount=0
		for fname in /asdf/LastShutdown* /asdf/rtb* /asdf/LastTZ*
		do
			if [ -e $fname ]; then
				fcount=$(($fcount+1))
			fi
		done

		for fname in /asdf/LastShutdown*
		do
			if [ -e $fname ]; then
				lastShutdownCount=$(($lastShutdownCount+1))
			fi
		done

		if [ $lastShutdownCount -gt 10 ]; then
			count=$lastShutdownCount
			for fname in /asdf/LastShutdown* 
			do
				if [ -e $fname ]; then
					if [ $count -gt 2 ]; then
						count=$(($count-1))
						rm $fname
					fi
				fi
			done
			count=$lastShutdownCount
			for fname in /asdf/ASUSSlowg*
			do
				if [ -e $fname ]; then
					if [ $count -gt 2 ]; then
						$count=$(($count-1))
						rm $fname
					fi
				fi
			done
		fi

		asdflogcatCount=0
		for asdflogcat in /asdf/asdf-logcat.*
		do
			asdflogcatCount=$(($asdflogcatCount+1))
			if [ ".$asdflogcatCount" == ".1" ]; then
				continue
			fi
			if [ ".$asdflogcatCount" == ".2" ]; then
				continue
			fi
			if [ -e /asdf/asdf-logcat.txt.0$asdflogcatCount ]; then
				rm /asdf/asdf-logcat.txt.0$asdflogcatCount
			fi
		done
		echo "==========>ASDF count: $fcount" > $action_log

#for atcmd checksum

		if [ -e /asdf/$version_number ]; then
			md5sum /dev/block/platform/msm_sdcc.1/by-name/boot > /asdf/md5checksum_now
			chmod 755 /asdf/md5checksum_now
		else
			echo 0 > /asdf/$version_number
			chmod 700 /asdf/$version_number
			md5sum /dev/block/platform/msm_sdcc.1/by-name/boot > /asdf/md5checksum_init
			chmod 755 /asdf/md5checksum_init
			cp /asdf/md5checksum_init /asdf/md5checksum_now
		fi
#for atcmd checksum

		if [ $fcount -gt 0 ]; then
			echo "$log_head: <$(date +%F_%T)>Abnormal shutdown logs found!" > $action_log

			#ASDF rotation
			if [ -e $log_dir.1 ]; then
				echo "$log_head: Start rotating log_dir!" > $action_log
				#mv $log_root $log_root.old
				mkdir $log_root.old
				cp -rf $log_root/* $log_root.old
				rm -rf $log_root/*
				mkdir $log_root
				mv $trigger_old $trigger_log
				i=$(($max_log-1))
				while [ $i -gt 0 ]; do
					if [ -e $log_old.$i ]; then
						echo "$log_head: rotate log_dir.$i to log_dir.$(($i+1))" > $action_log
						#mv $log_old.$i $log_dir.$(($i+1))
						mkdir $log_dir.$(($i+1))
						cp -rf $log_old.$i/* $log_dir.$(($i+1))
						rm -rf $log_old.$i/*
					fi
					i=$(($i-1))
				done
				#rm -rf $log_root.old
				rm -r /asdf/ASDF.old
			fi

			#create new ASDF
			echo "$log_head: Creating new log_dir" > $action_log
			mkdir $log_dir.1

			#backup ASDF
			echo "$log_head: Backup log files...." > $action_log

			fcount=0
			fext="$(date +%Y%m%d-%H%M%S).txt"
			cd /asdf
			for fname in ASUSSlowg* LastShutdown* rtb* LastTZ*
			do
				if [ -e $fname ]; then
					echo "$log_head: $PWD/$fname found!" > $action_log
					cat $fname > $log_dir.1/${fname%${fname:(-4)}}_$fext && rm $fname
					fcount=$(($fcount+1))
				fi
			done

			cd /data/anr
			for fname in traces*
			do
				if [ -e $fname ]; then
					echo "$log_head: $PWD/$fname found!" > $action_log
					cat $fname > $log_dir.1/$fname && rm $fname
					fcount=$(($fcount+1))
				fi
			done

			echo "$log_head: <$(date +%F_%T)>Job done!" > $action_log

			echo "$(date +%F_%T)> backup $fcount log(s)" >> $trigger_log
			echo "ASDF: backup $fcount log(s)" > /proc/asusevtlog
			am broadcast -a "com.asus.loguploader.action.ASDF_ABNORMAL_REBOOT"
			am broadcast -a "com.asus.loguploader.action.ASDF_ABNORMAL_REBOOT_ciq"
		fi

	else
		android_reboot=$(($android_reboot+1))
		setprop $android_reboot_prop $android_reboot
		echo "$log_head: Android restart....($android_reboot)" > $action_log
		echo "$(date +%F_%T)> Android restart!($android_reboot)" >> $trigger_log
		echo "[Debug]: Android restart....($android_reboot)" > /proc/asusevtlog
	fi
fi

#echo "init.asus.check_asdf.sh EXIT" > /dev/kmsg
