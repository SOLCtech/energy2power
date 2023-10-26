#!/bin/env bash

set -euo pipefail
#set -x

# package
# /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj
# /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj

# core
# /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj
# /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/max_energy_range_uj

SRC="${1:-0}"

readonly SRC

case "$SRC" in
	package)
		ENERGY_SRC="/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj"
		ENERGY_MAX="$(cat /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj)"
		ENERGY_LAST_SRC="/tmp/cpu_energy_package_last"
		;;
	core)
		ENERGY_SRC="/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj"
		ENERGY_MAX="$(cat /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/max_energy_range_uj)"
		ENERGY_LAST_SRC="/tmp/cpu_energy_core_last"
		;;
	*)
		echo "You must specify source: package, core"
		exit 1
		;;
esac

readonly ENERGY_SRC ENERGY_MAX ENERGY_LAST_SRC

function get_energy() {
	cat "$ENERGY_SRC"
}

function get_time_diff_us() {
	echo "${TIME_DIFF:="$(echo "($(date '+%s%N')-$(date '+%s%N' -r "$ENERGY_LAST_SRC"))/1000" | bc)"}"
}

function need_to_init_last() {
	[[ ! -f "$ENERGY_LAST_SRC" || $(get_time_diff_us) -gt 120000000 ]]
}

function store_last_energy() {
	local ENERGY
	ENERGY="$1"
	readonly ENERGY

	echo "$ENERGY" > "$ENERGY_LAST_SRC"
	unset TIME_DIFF
}

function calc_power() {
	local ENERGY ENERGY_LAST
	ENERGY="$1"
	ENERGY_LAST="$(cat "$ENERGY_LAST_SRC")"
	readonly ENERGY ENERGY_LAST

	ENERGY_DIFF="$(echo "$ENERGY-$ENERGY_LAST" | bc)"

	if [ "$(echo "$ENERGY_DIFF>0" | bc)" -eq 1 ]; then
		echo "scale=1;$ENERGY_DIFF/$(get_time_diff_us)" | bc -l
	else
		COMPLEMENT="$(echo "$ENERGY_MAX-$ENERGY_LAST" | bc)"

		if [ "$(echo "$COMPLEMENT<0" | bc)" -eq 1 ]; then
			echo 'Fatal error! Last stored energy value is greater than max_energy_range_uj!'
			exit 2
		fi

		echo "scale=1;($ENERGY+$COMPLEMENT)/$(get_time_diff_us)" | bc -l
	fi
}


ENERGY="$(get_energy)"

if need_to_init_last; then
	store_last_energy "$ENERGY"
	sleep 1
	ENERGY="$(get_energy)"
fi


calc_power "$ENERGY" && store_last_energy "$ENERGY"
