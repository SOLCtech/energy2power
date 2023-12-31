# energy2power
Bash script to calculate average power of CPU by repeatedly reading sysfs's intel-rapl energy_uj.

```
# package
/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj
/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj

# core
/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj
/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/max_energy_range_uj
```

Must be executed with root privileges because in default system settings energy information is allowed read only by root.

UPDATE: Or use _sysfsutils_ (if you know what you are doing):
```script
# cat /etc/sysfs.d/powercap.conf
mode devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj = 0440
owner devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj = root:powercap

mode devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj = 0440
owner devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj = root:powercap
```
Then run as user with _powercap_ group.

## Features
* Using bc for precise math operations
* Output in Watts with single decimal precision
* Energy counter overrun detection with max_energy_range_uj
* Max. measuring interval hardcoded to 120 sec, after that saved last counter invalidates
* Measures even at first run with no last data saved

## Usage
```script
# ./cpu-power.sh package
28.6

# ./cpu-power.sh core
0.3
```
