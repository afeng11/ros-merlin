#!/bin/sh

wget_timeout=`nvram get apps_wget_timeout`
#wget_options="-nv -t 2 -T $wget_timeout --dns-timeout=120"
wget_options="-q -t 2 -T $wget_timeout --no-check-certificate"
wget_options_HTTP="-q -t 2 -T $wget_timeout"

nvram set webs_state_update=0 # INITIALIZING
nvram set webs_state_flag=0   # 0: Don't do upgrade  1: Do upgrade	
nvram set webs_state_error=0
nvram set webs_state_url=""

# current firmware information
current_firm=`nvram get firmver`
current_firm=`echo $current_firm | sed s/'\.'//g;`
current_buildno=`nvram get buildno`
current_extendno=`nvram get extendno`
current_extendno=`echo $current_extendno | sed s/-g.*//;`

#support Live Update normally
live_update=`nvram show | grep rc_support | grep update`

# get firmware information
forsq=`nvram get apps_sq`
model=`nvram get productid`
model="$model#"
model_31="0"
model_30="0"
if [ "$model" == "RT-N18U#" ]; then
	model_31="1"
elif [ "$model" == "R6300_V2#" ] || [ "$model" == "RT-AC68U#" ] || [ "$model" == "RT-AC56S#" ] || [ "$model" == "RT-AC56U#" ]; then
	model_30="1"	#Use another info after middle firmware
fi

if [ "$forsq" == "1" ]; then
	if [ "$model_31" == "1" ]; then
		echo "---- update sq normal for model_31 ----" > /tmp/webs_upgrade.log
		wget $wget_options https://dlcdnets.asus.com/pub/ASUS/LiveUpdate/Release/Wireless_SQ/wlan_update_31.zip -O /tmp/wlan_update.txt
	elif [ "$model_30" == "1" ]; then
		echo "---- update sq normal for model_30 ----" > /tmp/webs_upgrade.log
		wget $wget_options https://dlcdnets.asus.com/pub/ASUS/LiveUpdate/Release/Wireless_SQ/wlan_update_30.zip -O /tmp/wlan_update.txt
	else
		if [ "$live_update" == "" ]; then
			echo "---- update sq normal only HTTP----" > /tmp/webs_upgrade.log
			wget $wget_options_HTTP http://dlcdnet.asus.com/pub/ASUS/LiveUpdate/Release/Wireless_SQ/wlan_update_v2.zip -O /tmp/wlan_update.txt
		else
	                echo "---- update sq normal----" > /tmp/webs_upgrade.log
	                wget $wget_options https://dlcdnets.asus.com/pub/ASUS/LiveUpdate/Release/Wireless_SQ/wlan_update_v2.zip -O /tmp/wlan_update.txt
		fi
	fi
else
	if [ "$model_31" == "1" ]; then
		echo "---- update real normal for model_31 ----" > /tmp/webs_upgrade.log
		wget $wget_options https://dlcdnets.asus.com/pub/ASUS/LiveUpdate/Release/Wireless/wlan_update_31.zip -O /tmp/wlan_update.txt
	elif [ "$model_30" == "1" ]; then
		echo "---- update real normal for model_30 ----" > /tmp/webs_upgrade.log
		wget $wget_options https://dlcdnets.asus.com/pub/ASUS/LiveUpdate/Release/Wireless/wlan_update_30.zip -O /tmp/wlan_update.txt
	else
		if [ "$live_update" == "" ]; then
			echo "---- update real normal only HTTP----" > /tmp/webs_upgrade.log
                        wget $wget_options_HTTP http://dlcdnet.asus.com/pub/ASUS/LiveUpdate/Release/Wireless/wlan_update_v2.zip -O /tmp/wlan_update.txt
		else
	                echo "---- update real normal----" > /tmp/webs_upgrade.log
        	        wget $wget_options https://dlcdnets.asus.com/pub/ASUS/LiveUpdate/Release/Wireless/wlan_update_v2.zip -O /tmp/wlan_update.txt
		fi
	fi
fi	

if [ "$?" != "0" ]; then
	nvram set webs_state_error=1
else
	# TODO get and parse information
	firmver=`grep $model /tmp/wlan_update.txt | sed s/.*#FW//;`
	firmver=`echo $firmver | sed s/#.*//;`
	buildno=`echo $firmver | sed s/....//;`
	firmver=`echo $firmver | sed s/$buildno$//;`
	extendno=`grep $model /tmp/wlan_update.txt | sed s/.*#EXT//;`
	extendno=`echo $extendno | sed s/#.*//;`
	lextendno=`echo $extendno | sed s/-g.*//;`
	nvram set webs_state_info=${firmver}_${buildno}_${extendno}
	urlpath=`grep $model /tmp/wlan_update.txt | sed s/.*#URL//;`	
	urlpath=`echo $urlpath | sed s/#.*//;`	
	nvram set webs_state_url=${urlpath}
	rm -f /tmp/wlan_update.*
fi

echo "---- $current_firm $current_buildno $current_extendno----" >> /tmp/webs_upgrade.log
if [ "$firmver" == "" ] || [ "$buildno" == "" ] || [ "$lextendno" == "" ]; then
	nvram set webs_state_error=1	# exist no Info
else
	if [ "$current_buildno" -lt "$buildno" ]; then
		echo "---- buildno: $buildno ----" >> /tmp/webs_upgrade.log
		nvram set webs_state_flag=1	# Do upgrade
	elif [ "$current_buildno" -eq "$buildno" ]; then
		if [ "$current_firm" -lt "$firmver"]; then 
				echo "---- firmver: $firmver ----" >> /tmp/webs_upgrade.log
				nvram set webs_state_flag=1	# Do upgrade
		elif [ "$current_firm" -eq "$firmver" ]; then
			if [ "$current_extendno" -lt "$lextendno" ]; then
				echo "---- lextendno: $lextendno ----" >> /tmp/webs_upgrade.log
				nvram set webs_state_flag=1	# Do upgrade
			fi
		fi	
	fi	
fi

nvram set webs_state_update=1
