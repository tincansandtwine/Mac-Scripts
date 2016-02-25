#!/bin/bash
echo ""
date
#####################
# Setting variables #
#####################

# Munkireport server path
MRWEB=$"munkireport.server.url"
# User running script; must be root.
SCRIPTUSER=$(whoami)
# Currently logged in user.
ENCRYPTUSER=$(stat -f%Su /dev/console)
# Location and name of plist with recovery info. plist file extenstion omitted.
PLISTFILE=$"/usr/local/fvresults"
# Checks if FileVault is already set to deferred, but not yet enabled.
DEFERSTATUS=$(fdesetup status | grep -E -o 'Deferred')
# Checks if MunkiReport is pingable.
MRSTATUS=$(ping -c1 ${MRWEB} | grep icmp* | wc -l)
# Admin user/s exempt from Filevault enablement
ADMINUSER1=$"admin"


######################
# MunkiReport Upload #
######################

echo "***** Checking for FileVault Results ***** "

# Runs first, since FileVault checks will exit if FileVault is on.

# Check for existence of results plist and upload to munkireport server

if [ -a "${PLISTFILE}.plist" ]
  then
  echo "***** Submitting FileVault Escrow Report *****"

  # Ensure Munki repository and MunkiReport is available
  if [ "${MRSTATUS}" -eq 0 ]; then
    echo "MunkiReport server not found. Exiting."
    exit 1
  else
    echo "MunkiReport available. Uploading results..."
  fi

  # Add hard drive serial number to /local/usr/fvresults.plist just in case the hard drive separates from the Mac
  HDD_SERIAL=`/usr/sbin/system_profiler SPSerialATADataType | grep "Serial Number:" | awk '{print $3}' | sed '1 ! d'`

  # Convert plists binary .plist into XML so it can be easily edited:
  /usr/bin/plutil -convert xml1 ${PLISTFILE}.plist

  /usr/bin/defaults write ${PLISTFILE} HddSerial $HDD_SERIAL

  # Add filevault_escrow pref to MunkiReport configuration
  /usr/bin/defaults write /Library/Preferences/MunkiReport ReportItems -dict-add filevault_escrow ${PLISTFILE}.plist

  # Submitting FileVault Escrow report to Munkireport server
  /usr/local/munki/postflight

  # Remove filevault_escrow pref from the MunkiReport configuration plist and delete results file
  /usr/libexec/PlistBuddy -c "Delete :ReportItems:filevault_escrow" /Library/Preferences/MunkiReport.plist
  /usr/bin/srm -f ${PLISTFILE}.plist

  # Filevault excrow complete. Change enforcement to check every 30 minutes instead of 1. Will take effect after reboot.
  /usr/bin/defaults write /Library/LaunchDaemons/local.filevaultenforcement.plist StartInterval -int 1800

  echo "FileVault results found and uploaded to MunkiReport."
  echo "Please confirm the Recovery Key is on the MunkiReport server."
  echo ""

  exit 0
else
  echo "No FileVault results found. Continuing checks..."
fi


########################################
# Script used from http://git.io/vZMN9 #
#          Modified to enforce         #
#       FileVault as launchdaemon      #
########################################

echo ""
echo "***** Checking Dependencies *****"

# Handful of sanity checks:

# Verify that encryption deferment isn't already active
if [ "${DEFERSTATUS}" == "Deferred" ]; then
  echo "FileVault deferred enablement pending. Exiting."
  echo ""; exit 1
fi

# Must run this script as root
	if [ "${SCRIPTUSER}" != "root" ]; then
		echo "*** Please run this script with root privileges, exiting ***"
    echo ""; exit 1
	fi

# Confirm there is a recovery partition present 
# recoveryHDPresent=`/usr/sbin/diskutil list | grep "Recovery HD" | awk '{ print $3, $4 }'`
# This covers Fusions and non Fusion drives
recoveryHDPresent=`/usr/sbin/diskutil list | grep "Apple_Boot" | awk '{ print $2 }'`
	if [ "$recoveryHDPresent" = "" ]; then
		echo "*** Recovery Partition not found. FileVault requires the Recovery Partition, exiting ***"
    echo ""; exit 1
	fi

# Check if BootCamp partition is present
bootcamp_detect=$(/usr/sbin/diskutil list | grep -c "Microsoft Basic Data")
	if [ "${bootcamp_detect}" == "1" ]; then
        echo "*** Warning: BootCamp partition detected. FileVault doesn't encrypt BootCamp partitions ***"
	fi 

# Confirm we are running at least 10.8
osversionlong=$(uname -r)
osvers=${osversionlong/.*/}
    if [ ${osvers} -lt 12 ]; then
    	echo "*** Upgrade time! You need at least 10.8 to run this script, exiting ***"
      echo ""; exit 1
    fi

# Confirm Munkireport postflight is installed
if [ ! -e /Library/Preferences/MunkiReport.plist ]; then 
	echo "*** Munkireport is not installed exiting ***"
  echo ""; exit 1
fi

echo "Dependencies met. Continuing checks..."

######################
# Script by rtrouton #
#    git.io/vnTLC    #
######################

echo ""
echo "***** Checking if FileVault is Enabled *****"

# Confirm current FileVault status. If on or in the process of encrypting exit 1

CORESTORAGESTATUS="/private/tmp/corestorage.txt"
ENCRYPTSTATUS="/private/tmp/encrypt_status.txt"
ENCRYPTDIRECTION="/private/tmp/encrypt_direction.txt"

osvers_major=$(sw_vers -productVersion | awk -F. '{print $1}')
osvers_minor=$(sw_vers -productVersion | awk -F. '{print $2}')

# Checks to see if the OS on the Mac is 10.x.x. If it is not, the 
# following message is displayed without quotes:
#
# "Unknown Version Of Mac OS X"

if [[ ${osvers_major} -ne 10 ]]; then
  echo "Unknown Version Of Mac OS X"; exit 1
fi

# Checks to see if the OS on the Mac is 10.7 or higher.
# If it is not, the following message is displayed without quotes:
#
# "FileVault 2 Encryption Not Available For This Version Of Mac OS X"

if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -lt 7 ]]; then
  echo "FileVault 2 Encryption Not Available For This Version Of Mac OS X"; exit 1
fi

if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -ge 7 ]]; then
  diskutil cs info / >> $CORESTORAGESTATUS 2>&1
  
    # If the Mac is running 10.7 or higher, but the boot volume
    # is not a CoreStorage volume, the following message is 
    # displayed without quotes:
    #
    # "FileVault 2 Encryption Not Enabled"
    
    if grep -iE '/ is not a CoreStorage disk' $CORESTORAGESTATUS 1>/dev/null; then
       echo "FileVault 2 Encryption Not Enabled"
       rm -f "$CORESTORAGESTATUS"
    fi
    
    # If the Mac is running 10.7 or higher and the boot volume
    # is a CoreStorage volume, the script then checks to see if 
    # the machine is encrypted, encrypting, or decrypting.
    # 
    # If encrypted, the following message is 
    # displayed without quotes:
    # "FileVault 2 Encryption Complete"
    #
    # If encrypting, the following message is 
    # displayed without quotes:
    # "FileVault 2 Encryption Proceeding."
    # How much has been encrypted of of the total
    # amount of space is also displayed. If the
    # amount of encryption is for some reason not
    # known, the following message is 
    # displayed without quotes:
    # "FileVault 2 Encryption Status Unknown. Please check."
    #
    # If decrypting, the following message is 
    # displayed without quotes:
    # "FileVault 2 Decryption Proceeding"
    # How much has been decrypted of of the total
    # amount of space is also displayed
    #
    # If fully decrypted, the following message is 
    # displayed without quotes:
    # "FileVault 2 Decryption Complete"
    #

    # Get the Logical Volume UUID (aka "UUID" in diskutil cs info)
    # for the boot drive's CoreStorage volume.
    
    LV_UUID=`diskutil cs info / | awk '/UUID/ {print $2;exit}'`
    
    # Get the Logical Volume Family UUID (aka "Parent LVF UUID" in diskutil cs info)
    # for the boot drive's CoreStorage volume.
    
    LV_FAMILY_UUID=`diskutil cs info / | awk '/Parent LVF UUID/ {print $4;exit}'`
    
    CONTEXT=`diskutil cs list $LV_FAMILY_UUID | awk '/Encryption Context/ {print $3;exit}'`
    
    if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -eq 7 || ${osvers_minor} -eq 8 ]]; then
        CONVERTED=`diskutil cs list $LV_UUID | awk '/Size \(Converted\)/ {print $5,$6;exit}'`
    fi
    
    if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -ge 9 ]]; then
        CONVERTED=`diskutil cs list $LV_UUID | awk '/Conversion Progress/ {print $3;exit}'`    
    fi
    
    ENCRYPTIONEXTENTS=`diskutil cs list $LV_FAMILY_UUID | awk '/Has Encrypted Extents/ {print $4;exit}'`
    ENCRYPTION=`diskutil cs list $LV_FAMILY_UUID | awk '/Encryption Type/ {print $3;exit}'`
    SIZE=`diskutil cs list $LV_UUID | awk '/Size \(Total\)/ {print $5,$6;exit}'`

    # This section does 10.7-specific checking of the Mac's
    # FileVault 2 status

   if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -eq 7 ]]; then
      if [ "$CONTEXT" = "Present" ]; then
        if [ "$ENCRYPTION" = "AES-XTS" ]; then
          diskutil cs list $LV_FAMILY_UUID | awk '/Conversion Status/ {print $3;exit}' >> $ENCRYPTSTATUS
        if grep -iE 'Complete' $ENCRYPTSTATUS 1>/dev/null; then 
          echo "FileVault 2 Encryption Complete. Exiting."; exit 1
            else
          if  grep -iE 'Converting' $ENCRYPTSTATUS 1>/dev/null; then
            diskutil cs list $LV_FAMILY_UUID | awk '/Conversion Direction/ {print $3;exit}' >> $ENCRYPTDIRECTION
              if grep -iE 'Forward' $ENCRYPTDIRECTION 1>/dev/null; then
                echo "FileVault 2 Encryption Proceeding. $CONVERTED of $SIZE Encrypted. Exiting."; exit 1
                  else
                echo "FileVault 2 Encryption Status Unknown. Please check. Exiting."; exit 1
                fi
               fi
             fi
        else
            if [ "$ENCRYPTION" = "None" ]; then
              diskutil cs list $LV_FAMILY_UUID | awk '/Conversion Direction/ {print $3;exit}' >> $ENCRYPTDIRECTION
                if grep -iE 'Backward' $ENCRYPTDIRECTION 1>/dev/null; then
                  echo "FileVault 2 Decryption Proceeding. $CONVERTED of $SIZE Decrypted. Exiting."; exit 1
                elif grep -iE '-none-' $ENCRYPTDIRECTION 1>/dev/null; then
                  echo "FileVault 2 Decryption Completed. Exiting."; exit 1
                fi
            fi 
        fi
      fi  
    fi
   fi



    # This section does checking of the Mac's FileVault 2 status
    # on 10.8.x through 10.10.x
    
    if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -ge 8 ]] && [[ ${osvers_minor} -lt 11 ]]; then
      if [[ "$ENCRYPTIONEXTENTS" = "No" ]]; then
          echo "FileVault 2 Encryption Not Enabled"
      elif [[ "$ENCRYPTIONEXTENTS" = "Yes" ]]; then
        diskutil cs list $LV_FAMILY_UUID | awk '/Fully Secure/ {print $3;exit}' >> $ENCRYPTSTATUS
        if grep -iE 'Yes' $ENCRYPTSTATUS 1>/dev/null; then 
          echo "FileVault 2 Encryption Complete. Exiting."; exit 1
            else
          if  grep -iE 'No' $ENCRYPTSTATUS 1>/dev/null; then
            diskutil cs list $LV_FAMILY_UUID | awk '/Conversion Direction/ {print $3;exit}' >> $ENCRYPTDIRECTION
              if grep -iE 'forward' $ENCRYPTDIRECTION 1>/dev/null; then
                echo "FileVault 2 Encryption Proceeding. $CONVERTED of $SIZE Encrypted. Exiting."; exit 1
                  else
                if grep -iE 'backward' $ENCRYPTDIRECTION 1>/dev/null; then
                        echo "FileVault 2 Decryption Proceeding. $CONVERTED of $SIZE Decrypted. Exiting."; exit 1
                elif grep -iE 'none' $ENCRYPTDIRECTION 1>/dev/null; then
                        echo "FileVault 2 Decryption Completed. Exiting."; exit 1
                  fi
                  fi
          fi
        fi  
      fi
    fi

    # This section does checking of the Mac's FileVault 2 status
    # on 10.11.x and higher
    
    if [[ ${osvers_major} -eq 10 ]] && [[ ${osvers_minor} -ge 11 ]]; then
      if [[ "$ENCRYPTION" = "None" ]] && [[ $(diskutil cs list "$LV_UUID" | awk '/Conversion Progress/ {print $3;exit}') == "" ]]; then
        echo "FileVault 2 Encryption Not Enabled"
      elif [[ "$ENCRYPTION" = "None" ]] && [[ $(diskutil cs list "$LV_UUID" | awk '/Conversion Progress/ {print $3;exit}') == "Complete" ]]; then
        echo "FileVault 2 Decryption Completed. Exiting."; exit 1
      elif [[ "$ENCRYPTION" = "AES-XTS" ]]; then
        diskutil cs list $LV_FAMILY_UUID | awk '/High Level Queries/ {print $4,$5;exit}' >> $ENCRYPTSTATUS
        if grep -iE 'Fully Secure' $ENCRYPTSTATUS 1>/dev/null; then 
          echo "FileVault 2 Encryption Complete. Exiting."; exit 1
            else
          if grep -iE 'Not Fully' $ENCRYPTSTATUS 1>/dev/null; then
            if [[ $(diskutil cs list "$LV_FAMILY_UUID" | awk '/Conversion Status/ {print $4;exit}') != "" ]]; then 
              diskutil cs list $LV_FAMILY_UUID | awk '/Conversion Status/ {print $4;exit}' >> $ENCRYPTDIRECTION
                if grep -iE 'forward' $ENCRYPTDIRECTION 1>/dev/null; then
                  echo "FileVault 2 Encryption Proceeding. $CONVERTED of $SIZE Encrypted. Exiting."; exit 1
                elif grep -iE 'backward' $ENCRYPTDIRECTION 1>/dev/null; then
                  echo "FileVault 2 Decryption Proceeding. $CONVERTED of $SIZE Decrypted. Exiting."; exit 1
                fi
            elif [[ $(diskutil cs list "$LV_FAMILY_UUID" | awk '/Conversion Status/ {print $4;exit}') == "" ]]; then
              if [[ $(diskutil cs list "$LV_FAMILY_UUID" | awk '/Conversion Status/ {print $3;exit}') == "Complete" ]]; then
                  echo "FileVault 2 Decryption Completed. Exiting."; exit 1
              fi
            fi
          fi
      fi  
    fi
fi

# Remove the temp files created during the script

if [ -f "$CORESTORAGESTATUS" ]; then
   rm -f "$CORESTORAGESTATUS"
fi

if [ -f "$ENCRYPTSTATUS" ]; then
   rm -f "$ENCRYPTSTATUS"
fi

if [ -f "$ENCRYPTDIRECTION" ]; then
   rm -f "$ENCRYPTDIRECTION"
fi


# End of sanity checks


#####################
# Kickoff FileVault #
#####################

echo ""
echo "***** Enabling FileVault *****"

echo ${ENCRYPTUSER}" is the currently logged in user."

if [[ ${ENCRYPTUSER} == "root"  ||  ${ENCRYPTUSER} == ${ADMINUSER1} ]]; then
	  echo "User" ${ENCRYPTUSER} "does not require encryption. Exiting."
    echo ""; exit 1
else
  echo "User" ${ENCRYPTUSER} "requires encryption. Enabling..."
	fdesetup enable -user ${ENCRYPTUSER} -defer ${PLISTFILE}.plist -forceatlogin 0	
fi

exit 0