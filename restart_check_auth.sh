#!/bin/bash
USER=""
while true; do
cd /home/$USER/server/bin
./authserver
wait
done
