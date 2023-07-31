#!/vendor/bin/sh

binder_setting=`getprop persist.vendor.asus.binderdebug.enable`
if [ "$binder_setting" != "" ]; then
    echo ${binder_setting}>/sys/module/binder/parameters/debug_mask
else
    var=$( cat /sys/module/binder/parameters/debug_mask )
    setprop persist.vendor.asus.binderdebug.enable $var
fi
