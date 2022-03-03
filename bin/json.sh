#!/bin/bash


logfile="/tmp/smart_report.json"

email="cristianv.paraschiv@gmail.com"

### Global table colors
okColor="#c9ffcc"       # Hex code for color to use in SMART Status column if drives pass (default is light green, #c9ffcc)
warnColor="#ffd6d6"     # Hex code for WARN color (default is light red, #ffd6d6)
critColor="#ff0000"     # Hex code for CRITICAL color (default is bright red, #ff0000)
altColor="#f4f4f4"      # Table background alternates row colors between white and this color (default is light gray, #f4f4f4)

### zpool status summary table settings
usedWarn=90             # Pool used percentage for CRITICAL color to be used
scrubAgeWarn=30         # Maximum age (in days) of last pool scrub before CRITICAL color will be used

### SMART status summary table settings
includeSSD="false"      # [NOTE: Currently this is pretty much useless] Change to "true" to include SSDs in SMART status summary table; "false" to disable
tempWarn=40             # Drive temp (in C) at which WARNING color will be used
tempCrit=45             # Drive temp (in C) at which CRITICAL color will be used
sectorsCrit=10          # Number of sectors per drive with errors before CRITICAL color will be used
testAgeWarn=5           # Maximum age (in days) of last SMART test before CRITICAL color will be used
powerTimeFormat="ymdh"  # Format for power-on hours string, valid options are "ymdh", "ymd", "ym", or "y" (year month day hour)

### FreeNAS config backup settings
configBackup="true"     # Change to "false" to skip config backup (which renders next two options meaningless); "true" to keep config backups enabled
saveBackup="true"       # Change to "false" to delete FreeNAS config backup after mail is sent; "true" to keep it in dir below
backupLocation="/backup"   # Directory in which to save FreeNAS config backups

drives=$(for drive in $(sysctl -n kern.disks); do
        if [ "$(smartctl -i /dev/"${drive}" | grep "SMART support is: Enabled")" ] && ! [ "$(smartctl -i /dev/"${drive}" | grep "Solid State Device")" ]; then
            printf "%s " "${drive}"
        fi
    done | awk '{for (i=NF; i!=0 ; i--) print $i }')

(
    echo "["
) > "$logfile"

for drive in $drives; do
    (
        # For each drive detected, run "smartctl -A -i" and parse its output. This whole section is a single, long statement, so I'll make all comments here.
        # Start by passing awk variables (all the -v's) used in other parts of the script. Other variables are calculated in-line with other smartctl calls.
        # Next, pull values out of the original "smartctl -A -i" statement by searching for the text between the //'s.
        # After parsing the output, compute other values (last test's age, on time in YY-MM-DD-HH).
        # After these computations, determine the row's background color (alternating as above, subbing in other colors from the palate as needed).
        # Finally, print the HTML code for the current row of the table with all the gathered data.
        smartctl -A -i /dev/"$drive" | \
        awk -v device="$drive" -v tempWarn="$tempWarn" -v tempCrit="$tempCrit" -v sectorsCrit="$sectorsCrit" -v testAgeWarn="$testAgeWarn" \
        -v okColor="$okColor" -v warnColor="$warnColor" -v critColor="$critColor" -v altColor="$altColor" -v powerTimeFormat="$powerTimeFormat" \
        -v lastTestHours="$(smartctl -l selftest /dev/"$drive" | grep "# 1" | awk '{print $9}')" \
        -v lastTestType="$(smartctl -l selftest /dev/"$drive" | grep "# 1" | awk '{print $3}')" \
        -v smartStatus="$(smartctl -H /dev/"$drive" | grep "SMART overall-health" | awk '{print $6}')" \
		-v capacity="$(smartctl -i /dev/"$drive" | grep "User Capacity" | awk '{print $5,$6}' | sed 's/\[//' | sed 's/\]//')" \
		-v modelFamily="$(smartctl -i /dev/"$drive" | grep "Model Family" | awk '{print $3,$4}')" '\
        /Serial Number:/{serial=$3} \
        /Temperature_Celsius/{temp=($10 + 0)} \
        /Power_On_Hours/{onHours=$10} \
        /Start_Stop_Count/{startStop=$10} \
        /Spin_Retry_Count/{spinRetry=$10} \
        /Reallocated_Sector/{reAlloc=$10} \
        /Reallocated_Event_Count/{reAllocEvent=$10} \
        /Current_Pending_Sector/{pending=$10} \
        /Offline_Uncorrectable/{offlineUnc=$10} \
        /UDMA_CRC_Error_Count/{crcErrors=$10} \
        /Seek_Error_Rate/{seekErrorHealth=$4} \
        END {
            testAge=int((onHours - lastTestHours) / 24);
            yrs=int(onHours / 8760);
            mos=int((onHours % 8760) / 730);
            dys=int(((onHours % 8760) % 730) / 24);
            hrs=((onHours % 8760) % 730) % 24;
            if (powerTimeFormat == "ymdh") onTime=yrs "y " mos "m " dys "d " hrs "h";
            else if (powerTimeFormat == "ymd") onTime=yrs "y " mos "m " dys "d";
            else if (powerTimeFormat == "ym") onTime=yrs "y " mos "m";
            else if (powerTimeFormat == "y") onTime=yrs "y";
            else onTime=yrs "y " mos "m " dys "d " hrs "h ";
            if ((substr(device,3) + 0) % 2 == 1) bgColor = "#ffffff"; else bgColor = altColor;
            if (smartStatus != "PASSED") smartStatusColor = critColor; else smartStatusColor = okColor;
            if (temp >= tempCrit) tempColor = critColor; else if (temp >= tempWarn) tempColor = warnColor; else tempColor = bgColor;
            if (spinRetry != "0") spinRetryColor = warnColor; else spinRetryColor = bgColor;
            if ((reAlloc + 0) > sectorsCrit) reAllocColor = critColor; else if (reAlloc != 0) reAllocColor = warnColor; else reAllocColor = bgColor;
            if (reAllocEvent != "0") reAllocEventColor = warnColor; else reAllocEventColor = bgColor;
            if ((pending + 0) > sectorsCrit) pendingColor = critColor; else if (pending != 0) pendingColor = warnColor; else pendingColor = bgColor;
            if ((offlineUnc + 0) > sectorsCrit) offlineUncColor = critColor; else if (offlineUnc != 0) offlineUncColor = warnColor; else offlineUncColor = bgColor;
            if (crcErrors != "0") crcErrorsColor = warnColor; else crcErrorsColor = bgColor;
            if ((seekErrorHealth + 0) < 100) seekErrorHealthColor = warnColor; else seekErrorHealthColor = bgColor;
            if (testAge > testAgeWarn) testAgeColor = warnColor; else testAgeColor = bgColor;
			printf "\{\"device\":\"%s\",\"serial\":\"%s\",\"name\":\"%s\",\"smart_status\":\"%s\",\"temperature\":\"%s\",\"capacity\":\"%s\",\"powered_on\":\"%s\",\"start_stop\":\"%s\",\"spin_retry\":\"%s\",\"reallocated_sectors\":\"%s\",\"reallocated_events\":\"%s\",\"current_pending_sectors\":\"%s\",\"offline_uncorrectable_sectors\":\"%s\",\"ultradma_crc_errors\":\"%s\",\"seek_error_health\":\"%s\",\"last_test_age\":\"%s\"\},",device, serial,modelFamily,smartStatus,temp,capacity,onTime,startStop,spinRetry,reAlloc,reAllocEvent,pending,offlineUnc,crcErrors,seekErrorHealth,testAge;
            
        }'
    ) >> "$logfile"
done

(
    echo "{}]"
) >> "$logfile"

curl -X POST -H "Content-Type: application/json" -d @/tmp/smart_report.json http://192.168.68.113:3005/add -o /dev/null

