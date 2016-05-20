-- Mail/Dispatch/OmniFocus workaround
--
-- Requires app on OS X that interprets 'x-dispatch' URLs, eg., http://www.dispatchapp.net/faq.html#openDispatchLinksOnMac
--
-- Modified from https://gist.github.com/jrarseneau/e0abe8edfaff9965305c


tell application "Mail"
set AppleScript's text item delimiters to {","}
set theSelectedMessages to selection
set the theMessage to item 1 ¬
of the theSelectedMessages
set theMessageID to the message id of the theMessage
set theMessageSubject to the subject of the theMessage
set theMessageBody to the content of the theMessage
set theMessageSender to the sender of the theMessage
set messageMailbox to mailbox of theMessage
set messageAccount to account of messageMailbox
set messageRecipientList to {}
set messageRecipientList to email addresses of messageAccount
set theMessageRecipient to messageRecipientList as string
if theMessageRecipient contains "," then
  repeat until theMessageRecipient does not contain ","
  set theMessageRecipient to rich text 1 thru -2 of theMessageRecipient
end repeat
end if
set theMessageDate to the date sent of the theMessage

set theMessageURL to "x-dispatch://" & theMessageRecipient & "/" & "%3c" & theMessageID & "%3e" & "

" & "From: " & theMessageSender & "
" & "Subject: " & theMessageSubject & "
" & "Date: " & theMessageDate & "
" & "To: " & theMessageRecipient & "

" & theMessageBody

tell application "OmniFocus"
tell quick entry
make new inbox task with properties {name:theMessageSubject, note:theMessageURL}
open
end tell
-- Make sure task name is selected for easy editing
tell application "System Events"
keystroke tab
end tell
end tell

end tell
