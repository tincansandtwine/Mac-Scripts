#!/bin/sh
# Current user
curUser=`ls -l /dev/console | cut -d " " -f 4`

# Current screensaver settings
ssIdle=`defaults -currentHost read /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist | grep idleTime | sed 's/[^0-9]//g'`
ssPwRequired=`defaults -currentHost read /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist | grep "askForPassword " | sed 's/[^0-9]//g'`
ssPwDelay=`defaults -currentHost read /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist | grep "askForPasswordDelay" | sed 's/[^0-9]//g'`
ssFvToken=`defaults -currentHost read /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist | grep tokenRemoval

# grab the system's uuid
if [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` != "00000000-0000-1000-8000-" ]]; then
    macUUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62`
fi


# Still Testing...
# Determine if screensaver is enabled, if it is set to the correct time, and if it requires a password.

#if [[ "$ssIdle" <= "840" ]]; then
	#if [[ "$ssPwRequired" == "1" ]]; then
#		if [[ "$ssPwDelay" == "1" ]]; then


# Create or change plist to reflect screen lock policy. Use Computer Name screen saver by default, but won't run again if screensaver is changed.

/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist CleanExit "YES"
/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist PrefsVersion -int 100
/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist idleTime -int 840
/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist moduleDict -dict displayName "Computer Name" moduleName "Computer Name" path "/System/Library/Frameworks/ScreenSaver.framework/Resources/Computer Name.saver" type -int 0
/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist showClock -bool 1
/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist askForPassword -bool 1
/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist askForPasswordDelay -int 1
/usr/bin/defaults -currentHost write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist tokenRemovalAction -int 1

killall cfprefsd