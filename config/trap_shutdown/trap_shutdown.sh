#!/bin/bash
# Script for flashing warnings on shutdown

# Disable keyboard before message, escape is already in kiosk,
# but without this, users can interfere with feh hotkeys
KB_INDEX="$(/usr/bin/xinput list --id-only 'AT Translated Set 2 keyboard')"
/usr/bin/xinput disable "${KB_INDEX}"

# Shut down no matter what, then fake a countdown with trap_shutdown
(/usr/bin/sleep 5s && /usr/bin/sudo /usr/sbin/shutdown -P now) &
/usr/bin/feh -Fr -D 1 /home/${BCLD_USER}/trap_shutdown/${1} --on-last-slide=hold
