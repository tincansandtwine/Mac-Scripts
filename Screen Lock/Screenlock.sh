#!/bin/sh
# grab current user
curUser=`ls -l /dev/console | cut -d " " -f 4`

# grab the system's uuid
if [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` != "00000000-0000-1000-8000-" ]]; then
    macUUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62`
fi

defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist CleanExit "YES"
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist PrefsVersion -int 100
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist idleTime -int 600
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.screensaver.$macUUID.plist moduleDict -dict moduleName "iLifeSlideshows" path "/System/Library/Frameworks/ScreenSaver.framework/Resources/iLifeSlideshows.saver" type -int 0
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.ScreenSaverPhotoChooser.$macUUID.plist identifier "/Library/Screen Savers/CORP"
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.ScreenSaverPhotoChooser.$macUUID.plist LastViewedPhotoPath "/Library/Screen Savers/CORP"
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.ScreenSaverPhotoChooser.$macUUID.plist SelectedFolderPath "/Library/Screen Savers/CORP"
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.ScreenSaverPhotoChooser.$macUUID.plist SelectedSource -int 4
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.ScreenSaverPhotoChooser.$macUUID.plist ShufflesPhotos -int 1
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.ScreenSaver.iLifeSlideShows.$macUUID styleKey \"ShiftingTiles\"
defaults write /Users/$curUser/Library/Preferences/ByHost/com.apple.ScreenSaver.iLifeSlideShows styleKey \"ShiftingTiles\"

killall cfprefsd