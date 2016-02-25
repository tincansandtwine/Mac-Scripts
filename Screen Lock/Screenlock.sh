#!/bin/sh
# grab current user
curUser=`ls -l /dev/console | cut -d " " -f 4`

# grab the system's uuid
if [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` != "00000000-0000-1000-8000-" ]]; then
    macUUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62`
fi

defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist CleanExit "YES"
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist PrefsVersion -int 100
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist idleTime -int 840
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist moduleDict -dict displayName "Computer Name" moduleName "Computer Name" path "/System/Library/Frameworks/ScreenSaver.framework/Resources/Computer Name.saver" type -int 0
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist showClock -bool 1
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist askForPassword -bool 1
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist askForPasswordDelay -int 1

killall cfprefsd