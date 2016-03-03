set myDate to current date

do shell script "caffeinate -di -t 7200 > /dev/null 2>&1 &"
set awakeUntil to myDate + (2 * hours)

set userConfirm to button returned of (display dialog "Your computer will stay awake until " & time string of awakeUntil & "." buttons {"Return to normal sleep schedule.", "OK (run again to cancel)."} default button "OK (run again to cancel)." with title "Computer is Caffeinated!")

if userConfirm is equal to "Return to normal sleep schedule." then
	do shell script "/usr/bin/killall caffeinate > /dev/null 2>&1 &"
end if