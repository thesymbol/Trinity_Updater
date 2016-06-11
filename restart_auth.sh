#!/bin/bash
USER=""
SESSION="authserver"
DAEMON="screen -d -m -S $SESSION /home/$USER/restart_check_auth.sh"
screen -r $SESSION -ls -q 2>&1 >/dev/null
echo -e ""
echo "Authserver has been launched into the background."
echo -e ""
if [ $? -le 10 ]; then
	echo "Restarting $DAEMON"
	$DAEMON
fi
wait
