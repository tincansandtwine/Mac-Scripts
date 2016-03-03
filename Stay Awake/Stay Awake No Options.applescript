set myDate to current date

-- No options mode; default to two hours
do shell script "caffeinate -di -t 7200 > /dev/null 2>&1 &"
set awakeUntil to myDate + (2 * hours)


-- Throw up a user confirmation
set userConfirm to button returned of (display dialog "Your computer will stay awake until " & time string of awakeUntil & "." buttons {"Return to normal sleep schedule.", "OK (run again to cancel)."} default button "OK (run again to cancel)." with title "Computer is Caffeinated!" giving up after 20)

-- If user chooses to cancel caffeine, kill any running caffeinate process
if userConfirm is equal to "Return to normal sleep schedule." then
	do shell script "/usr/bin/killall caffeinate > /dev/null 2>&1 &"
end if