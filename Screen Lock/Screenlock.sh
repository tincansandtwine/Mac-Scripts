#!/bin/sh

###################
#  Set variables  #
###################

# Set default minimums if requirements aren't met.
# Default time in seconds until screensaver is enabled; permitted values are 60,120,300,600,1200,1800,3600
defaultIdle="600"

# Default time in seconds after screensaver is enabled that a password is required; permitted values are 0(immediate),5,60,300,900,3600,14400,28800
defaultPasswordDelay="300"

# Default password requirement; true is required, false is not required
defaultPwRequired="true"


# Current user and group
curUser="$(ls -l /dev/console | cut -d " " -f 4)"
curGroup="$(id -g -n $curUser)"

# System's uuid
clippedMacUUID="$(ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50)"

if [[ "$clippedMacUUID" != "00000000-0000-1000-8000-" ]]; then
    macUUID="$(ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62)"
else
	exit 0		# Pre-2008 machine; find and send to incinerator.
fi

# Current screensaver settings
currentIdle="$(/usr/bin/defaults read /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist | grep idleTime | sed 's/[^0-9]//g')"
currentPwRequired="$(/usr/bin/defaults read /Users/$curUser/Library/Preferences/com.apple.screensaver.plist | grep "askForPassword " | sed 's/[^0-9]//g')"
currentPwDelay="$(/usr/bin/defaults read /Users/$curUser/Library/Preferences/com.apple.screensaver.plist | grep "askForPasswordDelay" | sed 's/[^0-9]//g')"
currentFvToken="$(/usr/bin/defaults read /Users/$curUser/Library/Preferences/com.apple.screensaver.plist | grep tokenRemovalAction | sed 's/[^0-9]//g')"

# Set the total time to lockout (in seconds) as the sum of the current idle time plus the time until a password is required.
currentTotalLockTime=`expr $currentIdle + $currentPwDelay`


#######################################################
#  Test for correct minimum screensaver requirements  #  
#######################################################

# Determine if screensaver is enabled, if it is set to the correct time, and if it requires a password.
if [[ "$currentTotalLockTime" -le "900" ]]; then
	if [[ "$currentPwRequired" == "1" ]]; then
		echo "Screensaver settings meet requirements. Exiting."
		exit 0
	fi
fi

echo "Screensaver policy requirements not met. Applying defaults."


#####################################################
#  Set to defaults if minimum requirements not met  #
#####################################################

# Create or change plist to reflect screen lock policy. Use Computer Name screen saver by default, but won't run again if screensaver is changed.
/usr/bin/touch /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist
/usr/bin/defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist CleanExit "YES"
/usr/bin/defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist PrefsVersion -int 100
/usr/bin/defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist idleTime -int $defaultIdle
/usr/bin/defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist moduleDict -dict displayName "Computer Name" moduleName "Computer Name" path "/System/Library/Frameworks/ScreenSaver.framework/Resources/Computer Name.saver" type -int 0
/usr/bin/defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist showClock -bool true
/usr/bin/defaults write /Users/$curUser/Library/Preferences/com.apple.screensaver.plist askForPassword -bool true
/usr/bin/defaults write /Users/$curUser/Library/Preferences/com.apple.screensaver.plist askForPasswordDelay -int $defaultPasswordDelay
/usr/bin/defaults write /Users/$curUser/Library/Preferences/com.apple.screensaver.plist tokenRemovalAction -int 1
/usr/bin/defaults write /Users/$curUser/Library/Preferences/com.apple.screensaver.plist idleTime -int 10

chown "$curUser":"$curGroup" /Users/$curUser/Library/Preferences/com.apple.screensaver.plist
chown "$curUser":"$curGroup" /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist

killall cfprefsd



