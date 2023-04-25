#!/bin/bash
PATH="/usr/sbin:/usr/bin:/sbin:/bin"
#---- Example crontab
# SHELL=/bin/bash
#-- Custom snapshot call works like this
# snapshot.sh (pool you want) (filesystem you want) (unique name) (unique id, incase we have same name twice) (how many to keep)
 
## Snapshots for pool/data (example setup for pool/data)
#0,15,30,45 * * * * /var/scripts/zfs/snapshot.sh pool data minutes 100 5
#0 * * * * /var/scripts/zfs/snapshot.sh pool data hourly 101 24
#45 23 * * * /var/scripts/zfs/snapshot.sh pool data daily 102 31
#45 23 * * 5 /var/scripts/zfs/snapshot.sh pool data weekly 103 7
#45 23 1 * * /var/scripts/zfs/snapshot.sh pool data monthly 104 12
#45 23 31 12 * /var/scripts/zfs/snapshot.sh pool data yearly 105 2
## --- The above setup would keep five 15 minute intervals, roll that into 24 hourly intervals, roll that into 31 daily, then 7 weekly, then 12 monthly, then 2 yearly
 
#-- User settings for snapshots called from command line
pool=$1
filesystem=$2
name=$3
jobid=$4
keep=$5
 
## Get timestamped name for new snapshot
snap="$(echo $pool)/$(echo $filesystem)@$(echo $name)-$(echo $jobid)_$(date +%Y).$(date +%m).$(date +%d).$(date +%H).$(date +%M).$(date +%S)"
 
## Create snapshot (which includes user settings)
zfs snapshot $snap
 
## Get full list of snapshots that fall under user specified group
snaps=( $(zfs list -o name -t snapshot | grep $pool/$filesystem@$name-$jobid) )
 
## Count how many snaps we have total under their grep
elements=${#snaps[@]}
 
## Mark where to stop, based on how many they want to keep
stop=$((elements-keep))
 
## Delete every snap that they don't want to keep
for (( i=0; i<stop; i++ ))
do
        zfs destroy ${snaps[$i]}
done
