#!/vendor/bin/sh

#prop_type=`getprop vendor.asus.dongletype`

FW_VER=`cat /vendor/firmware/FW_version.txt | grep FAN6_FW | cut -d ':' -f 2`
setprop vendor.asusfw.fandg6.inbox_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep FAN6_AURA_FW | cut -d ':' -f 2`
setprop vendor.asusfw.fandg6.aura_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep FAN6_PD_FW | cut -d ':' -f 2`
setprop vendor.asusfw.fandg6.pd_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep FAN7_2LED_FW | cut -d ':' -f 2`
setprop vendor.asusfw.fandg7.2led_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep FAN7_3LED_FW | cut -d ':' -f 2`
setprop vendor.asusfw.fandg7.3led_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep FAN7_PD_FW | cut -d ':' -f 2`
setprop vendor.asusfw.fandg7.pd_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep gamepad_left | cut -d ':' -f 2`
setprop vendor.asusfw.gamepad.left_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep gamepad_holder | cut -d ':' -f 2`
setprop vendor.asusfw.gamepad.holder_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep gamepad_dongle | cut -d ':' -f 2`
setprop vendor.asusfw.gamepad.wireless_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep gamepad3_left | cut -d ':' -f 2`
setprop vendor.asusfw.gamepad3.left_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep gamepad3_middle | cut -d ':' -f 2`
setprop vendor.asusfw.gamepad3.middle_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep gamepad3_right | cut -d ':' -f 2`
setprop vendor.asusfw.gamepad3.right_fwver $FW_VER

FW_VER=`cat /vendor/firmware/FW_version.txt | grep gamepad3_bt | cut -d ':' -f 2`
setprop vendor.asusfw.gamepad3.bt_fwver $FW_VER

echo "[ACCY] Check Accy AsusFW Ver Done" > /dev/kmsg
