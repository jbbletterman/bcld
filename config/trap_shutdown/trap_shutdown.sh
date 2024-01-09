#!/bin/bash
# Script for flashing warnings on shutdown

# Disable keyboard before message, escape is already in kiosk,
# but without this, users can interfere with feh hotkeys
KB_INDEX="$(/usr/bin/xinput list --id-only 'AT Translated Set 2 keyboard')"
/usr/bin/xinput disable "${KB_INDEX}"

# Flash screen with keyboard disabled, then shut down
/usr/bin/feh -Fr -D 1 /home/${BCLD_USER}/trap_shutdown/${1} --on-last-slide=quit
/usr/bin/sudo /usr/sbin/shutdown -P now & > /dev/null 2>&1
