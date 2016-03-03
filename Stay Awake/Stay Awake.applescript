-- set sleep options
set sleepOptions to {"1 hour", "2 hours", "3 hours", "4 hours", "Return to normal sleep schedule."}

-- display options in a list for user to select from
set selectedTime to {choose from list sleepOptions with title "Keep Me Awake!" with prompt "How long should your computer stay awake?"}

try
	selectedTime
on error
	return "User cancelled."
end try
set myDate to current date

-- run appropriate bash script based on selection
if (selectedTime as string) is equal to "1 hour" then
	do shell script "caffeinate -di -t 3600 > /dev/null 2>&1 &"
	set awakeUntil to myDate + (1 * hours)
else if (selectedTime as string) = "2 hours" then
	do shell script "caffeinate -di -t 7200 > /dev/null 2>&1 &"
	set awakeUntil to myDate + (2 * hours)
else if (selectedTime as string) = "3 hours" then
	do shell script "caffeinate -di -t 10800 > /dev/null 2>&1 &"
	set awakeUntil to myDate + (3 * hours)
else if (selectedTime as string) = "4 hours" then
	do shell script "caffeinate -di -t 14400 > /dev/null 2>&1 &"
	set awakeUntil to myDate + (4 * hours)
else if (selectedTime as string) = "Return to normal sleep schedule." then
	do shell script "/usr/bin/killall caffeinate > /dev/null 2>&1 &"
	return "User restored default settings."
else
	return "User cancelled selection. No changes made."
end if

set userConfirm to button returned of (display dialog "Your computer will stay awake until " & time string of awakeUntil & "." buttons {"Return to normal sleep schedule.", "Close (run again to cancel)."} with title "Computer is Caffeinated!")

if userConfirm is equal to "Return to normal sleep schedule." then
	do shell script "/usr/bin/killall caffeinate > /dev/null 2>&1 &"
end if