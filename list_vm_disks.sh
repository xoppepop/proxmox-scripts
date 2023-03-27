#!/bin/sh


currentDate=$(date '+%Y-%m-%d')
Tag="daily"
backupsNumber=7
myIp=$(curl -s ifconfig.me)
zfsPoolName="local-zfs"
zpoolName=$(zpool list -H | awk '{split($0,a); print a[1]}')
#echo "$zpoolName"
datasetName=$(cat /etc/pve/storage.cfg | grep "$zpoolName/" | awk -F "$zpoolName/" '{print $NF}')
#echo "$datasetName"
#exit 0
errFileName="storage-errors.$myIp"

if [ -f "$errFileName" ]
then
rm "$errFileName"
fi


# get VMID of all VMs
VMIDS=$(pvesh get /cluster/resources --type vm --output-format yaml | grep vmid | awk '{split($0,a,": "); print a[2]}')
# foreach ID in ALL
for VMID in $(echo "$VMIDS")
do
  #echo "DISKS FOR VMID $VMID"
  # get all disks for current ID
  DISKS=$(qm config "$VMID" | egrep disk- | awk '{split($0,a,":");printf "%s:", a[2];print a[3]}' | awk '{split($0,a,",");print a[1]}')
  diskCount=0
  for DISK in $(echo "$DISKS")
  do
    storageName=""
    diskName=""
    vmName=""
    storageName=$(echo "$DISK" | awk '{split($0,a,":");print a[1]}')
    diskName=$(echo "$DISK" | awk '{split($0,a,":");print a[2]}')
    vmName=$(qm config "$VMID" | grep '^name:' | awk '{print $2}')

#    echo "$storageName"
#    echo "$diskName"
    if [ "$zfsPoolName" = "$storageName" ]; then
     cronline=""
     cronline=$(echo "51 23 * * * $(pwd)/snap.sh $zpoolName $datasetName/$diskName $Tag vm${VMID}d${diskCount} $backupsNumber")
     echo "$cronline"
#addind line to crontab
     (crontab -l;echo "$cronline") | crontab
    else
      if [ ! -f "$errFileName" ]
      then
       echo "IP;VMID;VMNAME;DISK" > "$errFileName"
      fi
      echo "${myIp};${VMID};${vmName};${diskName}" >> "$errFileName"
    fi
    diskCount=$(($diskCount + 1))
  done
done

