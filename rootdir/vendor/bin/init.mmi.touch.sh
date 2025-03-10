#!/vendor/bin/sh

PATH=/sbin:/vendor/sbin:/vendor/bin:/vendor/xbin
export PATH

while getopts ds op;
do
	case $op in
		d)  dbg_on=1;;
		s)  dump_statistics=1;;
	esac
done
shift $(($OPTIND-1))

# Globals
scriptname=${0##*/}
touch_class_path=/sys/class/touchscreen
touch_status_prop=vendor.hw.touch.status
touch_update_prop=vendor.hw.touch.update
touch_calibration_done_version=persist.vendor.touch.cal_ver
touch_vendor=
touch_path=
panel_path=/sys/devices/virtual/graphics/fb0
oem_panel_script=/vendor/bin/init.oem.panel.sh
dlkm_path=/vendor/lib/modules
device_property=ro.vendor.hw.device
hwrev_property=ro.vendor.hw.revision
firmware_path=/vendor/firmware
let dec_cfg_id_boot=0
let dec_cfg_id_latest=0
typeset -l product_id
panel_ver=
supplier=
property=
config_id=
build_id=
hwrev_id=
str_cfg_id_new=
str_cfg_id_boot=
str_cfg_id_latest=
build_id_new=

debug()
{
	[ $dbg_on ] && echo "Debug: $*"
}

notice()
{
	echo "$*"
	echo "$scriptname: $*" > /dev/kmsg
}

sanity_check()
{
	read_touch_property flashprog || return 1
	[[ ( -z "$property" ) || ( "$property" == "1" ) ]] && return 2
	read_touch_property productinfo || return 1
	[[ ( -z "$property" ) || ( "$property" == "0" ) ]] && return 2
	read_touch_property buildid || return 1
	config_id=${property#*-}
	[[ ( -z "$config_id" ) || ( "$config_id" == "0" ) ]] && return 2
	build_id=${property%-*}
	[[ ( -z "$build_id" ) || ( "$build_id" == "0" ) ]] && return 2
	return 0
}

error_msg()
{
	local err_msg
	local err_code=$1
	case $err_code in
		1)  err_msg="Error: No response from touch IC";;
		2)  err_msg="Error: Cannot read property $2";;
		3)  err_msg="Error: No matching firmware file found";;
		4)  err_msg="Error: Touch IC is in bootloader mode";;
		5)  err_msg="Error: Touch provides no reflash interface";;
		6)  err_msg="Error: Touch driver is not running";;
		7)  err_msg="Warning: Touch firmware is not the latest";;
		8)  err_msg="Info: Touch class does not exist";;
		9)  err_msg="Error: Touch IC is not ready to flash";;
	esac
	notice "$err_msg"
}

error_and_leave()
{
	local err_code=$1
	local touch_status="unknown"
	error_msg $err_code
	case $err_code in
		1|4)  touch_status="dead";;
		5|6|8)  touch_status="absent";;
	esac

	# perform sanity check and declare touch ready if error is not fatal
	if [ "$touch_status" == "unknown" ]; then
		sanity_check
		case "$?" in
			0) touch_status="ready";;
			2) touch_status="dead";;
			1) touch_status="absent";;
		esac
	fi

	# perform recovery if touch is declared dead
	if [ "$touch_status" == "dead" ]; then
		notice "Touch needs to go through recovery!!!"
		reboot_cnt=$(getprop $touch_status_prop 2>/dev/null)
		[ -z "$reboot_cnt" ] && reboot_cnt=0
		debug "current reboot counter [$reboot_cnt]"
	fi

	setprop $touch_status_prop $touch_status
	notice "property [$touch_status_prop] set to [`getprop $touch_status_prop`]"

	if [ "$touch_status" == "dead" ]; then
		notice "Touch is not responding; no further action!!!"
		#if [ $((reboot_cnt)) -lt 2 ]; then
		#	notice "Touch is not working; rebooting..."
		#	debug "sleep 3s to allow touch-dead-sh service to run"
		#	sleep 3
		#	[ -z "$dbg_on" ] && setprop sys.powerctl reboot
		#else
		#	notice "Although touch is not working, no more reboots"
		#fi
	fi

	exit $err_code
}

prepend()
{
	local list=""
	local prefix=$1
	shift
	for name in $*; do
		list="$list$prefix/$name "
	done
	echo $list
}

dump_statistics()
{
	debug "dumping touch statistics"
	cat $touch_path/ic_ver
	[ -f $touch_path/stats ] && cat $touch_path/stats
	return 0
}

wait_for_poweron()
{
	local wait_nomore
	local readiness
	local count
	debug "wait until driver reports <ready to flash>..."
	wait_nomore=60
	count=0
	while true; do
		readiness=$(cat $touch_path/poweron)
		if [ "$readiness" == "1" ]; then
			debug "ready to flash!!!"
			break;
		fi
		count=$((count+1))
		[ $count -eq $wait_nomore ] && break
		sleep 1
		debug "not ready; keep waiting..."
	done
	if [ $count -eq $wait_nomore ]; then
		error_msg 9
		return 1
	fi
	return 0
}

setup_permissions()
{
	local selinux=$(getprop ro.boot.selinux 2> /dev/null)
	local key_path
	local key_files
	local entry
	if [ "$selinux" == "permissive" ]; then
		debug "loosen permissions to $touch_vendor files"
		case $touch_vendor in
			  samsung)	key_path="/sys/devices/virtual/sec/sec_ts/"
						key_files=$(ls $key_path 2>/dev/null)
						# Set optional permissions to LSI touch tests
						[ -f $touch_path/size ] && chown root:oem_5004 $touch_path/size
						[ -f $touch_path/address ] && chown root:oem_5004 $touch_path/address
						[ -f $touch_path/write ] && chown root:oem_5004 $touch_path/write
						;;
			synaptics)	key_path=$touch_path
						key_files=$(prepend f54 `ls $touch_path/f54/ 2>/dev/null`)
						key_files=$key_files"reporting query stats";;
			focaltech)	key_path="/proc/"
						key_files="ftxxxx-debug";;
			   ilitek)	key_path="/proc/ilitek"
						key_files="ioctl";;
			   goodix)	key_path="/proc/"
						key_files="gmnode"
						if [[ "$touch_product_string" == "GTx5" ]] || [[ "$touch_product_string" == "GTx8" ]]; then
							key_path="/dev/"
							key_files="gtp_tools"
						fi
						;;
		esac
		for entry in $key_files; do
			chmod 0666 $key_path/$entry
			debug "change permissions of $key_path/$entry"
		done
	fi
	# Set permissions to enable factory touch tests
	chown root:oem_5004 $touch_path/drv_irq
	chown root:oem_5004 $touch_path/hw_irqstat
	chown root:oem_5004 $touch_path/reset

	# Set permissions to allow Bug2Go access to touch statistics
	chown root:log $touch_path/stats
	# Erase is optional
	[ -f $touch_path/erase_all ] && chown root:oem_5004 $touch_path/erase_all
}

read_touch_property()
{
	property=""
	debug "retrieving property: [$touch_path/$1]"
	property=$(cat $touch_path/$1 2> /dev/null)
	debug "touch property [$1] is: [$property]"
	[ -z "$property" ] && return 1
	return 0
}

read_panel_property()
{
	property=""
	debug "retrieving panel property: [$panel_path/$1]"
	property=$(cat $panel_path/$1 2> /dev/null)
	debug "panel property [$1] is: [$property]"
	[ -z "$property" ] && return 1
	return 0
}

find_latest_config_id()
{
	local fw_mask=$1
	local skip_fields=$2
	local dec max z str_hex i
	str_cfg_id_latest=""
	debug "scanning dir for files matching [$fw_mask]"
	let dec=0; max=0;
	for file in $(ls $fw_mask 2>/dev/null); do
		z=$file
		i=0
		while [ ! $i -eq $skip_fields ]; do
			z=${z#*-}
			i=$((i+1))
		done
		str_hex=${z%%-*};
		let dec=0x$str_hex
		if [ $dec -gt $max ]; then
			let max=$dec; dec_cfg_id_latest=$dec;
			str_cfg_id_latest=$str_hex
		fi
	done
	[ -z "$str_cfg_id_latest" ] && return 1
	return 0
}

find_best_match()
{
	local hw_mask=$1
	local panel_supplier=$2
	local skip_fields fw_mask
	while [ ! -z "$hw_mask" ]; do
		if [ "$hw_mask" == "-" ]; then
			hw_mask=""
		fi
		if [ ! -z "$panel_supplier" ]; then
			skip_fields=3
			fw_mask="$touch_vendor-$panel_supplier-$touch_product_id-*-$product_id$hw_mask.*"
		else
			skip_fields=2
			fw_mask="$touch_vendor-$touch_product_id-*-$product_id$hw_mask.*"
		fi
		find_latest_config_id "$fw_mask" "$skip_fields" && break
		hw_mask=${hw_mask%?}
	done
	[ -z "$str_cfg_id_latest" ] && return 1
	if [ -z "$panel_supplier" ]; then
		firmware_file=$(ls $touch_vendor-$touch_product_id-$str_cfg_id_latest-*-$product_id$hw_mask.*)
	else
		firmware_file=$(ls $touch_vendor-$panel_supplier-$touch_product_id-$str_cfg_id_latest-*-$product_id$hw_mask.*)
	fi
	notice "Firmware file for upgrade $firmware_file"
	return 0
}

query_touch_info()
{
	read_touch_property flashprog
	bl_mode=$property
	debug "bl mode: $bl_mode"
	read_touch_property productinfo
	touch_product_id=$property
	if [ -z "$touch_product_id" ] || [ "$touch_product_id" == "0" ]; then
		debug "touch ic reports invalid product id"
		error_msg 1
		return 1
	fi
	debug "touch product id: $touch_product_id"
	read_touch_property buildid
	str_cfg_id_boot=${property#*-}
	let dec_cfg_id_boot=0x$str_cfg_id_boot
	debug "touch config id: $str_cfg_id_boot"
	build_id_boot=${property%-*}
	debug "touch build id: $build_id_boot"
	return 0
}

query_panel_info()
{
	supplier=""
	read_touch_property "panel_supplier"
	[ -z "$property" ] && read_panel_property "panel_supplier"
	supplier=$property
	if [ "$supplier" ]; then
		read_panel_property "controller_drv_ver"
		panel_ver=${property#${property%?}}
		debug "panel supplier: $supplier, ver $panel_ver"
	else
		debug "driver does not report panel supplier"
	fi
}

load_driver_modules()
{
	if [ "$supplier" ]; then
		if [ -f $oem_panel_script ]; then
			debug "load_driver_modules()"
			$oem_panel_script -s $supplier
		fi
	fi
}

search_firmware_file()
{
	local match_not_found
	match_not_found=1
	if [ "$supplier" ]; then
		for pattern in "$supplier$panel_ver" "$supplier"; do
			debug "search for best hw revision match with supplier"
			find_best_match "-$hwrev_id" "$pattern"
			match_not_found=$?
			[ "$match_not_found" == "0" ] && break
		done
	fi
	if [ "$match_not_found" != "0" ]; then
		debug "search for best hw revision match without supplier"
		find_best_match "-$hwrev_id"
		if [ "$?" != "0" ]; then
			error_msg 3
			return 1
		fi
	fi
	return 0
}

run_firmware_upgrade()
{
	local recovery
	recovery=0
	if [ "$bl_mode" == "1" ] || [ "$build_id_boot" == "0" ]; then
		recovery=1
		notice "Initiating touch firmware recovery"
		notice "  bl mode = $bl_mode"
		notice "  build id = $build_id_boot"
	fi
	if [ $dec_cfg_id_boot -ne $dec_cfg_id_latest ] || [ "$recovery" == "1" ]; then
		wait_for_poweron
		debug "forcing firmware upgrade"
		echo 1 > $touch_path/forcereflash
		debug "sending reflash command"
		echo $firmware_file > $touch_path/doreflash
		read_touch_property flashprog
		if [ "$?" != "0" ]; then
			error_msg 1
			return 1
		fi
		bl_mode=$property
		if [ "$bl_mode" == "1" ]; then
			error_msg 4
			return 1
		fi
		read_touch_property buildid
		if [ "$?" != "0" ]; then
			error_msg 1
			return 1
		fi
		str_cfg_id_new=${property#*-}
		build_id_new=${property%-*}
		notice "Touch firmware config id at boot time $str_cfg_id_boot"
		notice "Touch firmware config id in the file $str_cfg_id_latest"
		notice "Touch firmware config id currently programmed $str_cfg_id_new"
		[ "$str_cfg_id_latest" != "$str_cfg_id_new" ] && error_msg 7 && return 1
		# indicate that update has been completed
		setprop $touch_update_prop "completed"
		notice "property [$touch_update_prop] set to [`getprop $touch_update_prop`]"
		if [ -f $touch_path/f54/force_update ]; then
			notice "forcing F54 registers update"
			echo 1 > $touch_path/f54/force_update
		fi
	fi
	return 0
}

reload_modules()
{
	local rc
	local module
	for module in $*; do
		[ -f $dlkm_path/$module.ko ] || continue
		notice "Reloading [$module.ko]..."
		rmmod $module
		rc=$?
		[ $rc != 0 ] && notice "Unloading [$module] failed: $rc"
		insmod $dlkm_path/$module.ko
		rc=$?
		[ $rc != 0 ] && notice "Loading [$module] failed: $rc"
	done
}

do_sec_calibration()
{
	local rc

	sleep 3
	echo run_force_calibration > /sys/devices/virtual/sec/tsp/cmd
	rc=$(cat /sys/devices/virtual/sec/tsp/cmd_result)
	if [[ "$rc" != "run_force_calibration:OK" ]]; then
		return 1
	fi
	return 0
}

do_calibration()
{
	local rc
	local cal_version_old=$(getprop $touch_calibration_done_version 2> /dev/null)

	rc=$(echo $firmware_file | grep "recal")
	if [[ "$rc" != "" ]]; then
		if [ "$cal_version_old" != "$str_cfg_id_latest" ]; then
			notice "Do force touch calibration."

			case $touch_vendor in
				samsung)	do_sec_calibration
							rc=$?
							;;
			esac

			notice "touch calibration result $rc."
			if [[ $rc == 0 ]]; then
				setprop $touch_calibration_done_version $str_cfg_id_latest
			fi
		fi
	fi
}

process_touch_instance()
{
	touch_vendor=$(cat $touch_class_path/$touch_product_string/vendor)
	debug "touch vendor [$touch_vendor]"
	touch_path=/sys$(cat $touch_class_path/$touch_product_string/path)
	debug "sysfs touch path: $touch_path"
	if [ ! -f $touch_path/doreflash ] ||
		[ ! -f $touch_path/poweron ] ||
		[ ! -f $touch_path/flashprog ] ||
		[ ! -f $touch_path/productinfo ] ||
		[ ! -f $touch_path/buildid ]; then
		error_msg 5
		continue
	fi
	if [ $dump_statistics ]; then
		dump_statistics
	fi
	notice "Checking touch ID [$touch_product_string] FW upgrade"
	touch_vendor=$(cat $touch_class_path/$touch_product_string/vendor)
	debug "touch vendor [$touch_vendor]"
	touch_path=/sys$(cat $touch_class_path/$touch_product_string/path)
	debug "sysfs touch path: $touch_path"
	query_touch_info
	query_panel_info
	search_firmware_file
	[ "$?" == "0" ] && run_firmware_upgrade
	do_calibration
	notice "Touch firmware is up to date"
	setprop $touch_status_prop "ready"
	notice "property [$touch_status_prop] set to [`getprop $touch_status_prop`]"
}

# Main starts here
query_panel_info
load_driver_modules
[ -d $touch_class_path ] || error_and_leave 8
debug "sysfs panel path: $panel_path"
product_id=$(getprop $device_property 2> /dev/null)
[ -z "$product_id" ] && error_and_leave 2 $device_property
product_id=${product_id%-*}
product_id=${product_id%_*}
debug "product id: $product_id"
hwrev_id=$(getprop $hwrev_property 2> /dev/null)
[ -z "$hwrev_id" ] && notice "hw revision undefined"
debug "hw revision: $hwrev_id"
cd $firmware_path
# Run asynchronously for each instance
for touch_product_string in $(ls $touch_class_path); do
	process_touch_instance &
done

# check if need to reload modules
wait
debug "all background processes completed"
if [ "x`getprop $touch_update_prop`" == "xcompleted" ] && [ "$touch_vendor" == "synaptics" ]; then
	notice "need to reload F54"
	reload_modules "synaptics_dsx_test_reporting"
fi

for touch_product_string in $(ls $touch_class_path); do
	touch_vendor=$(cat $touch_class_path/$touch_product_string/vendor)
	touch_path=/sys$(cat $touch_class_path/$touch_product_string/path)
	notice "Handling touch ID [$touch_product_string] permissions"
	setup_permissions
done
return 0
