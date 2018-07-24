#!/bin/bash
#
# [Ansible Role]
#
# GitHub:   https://github.com/Admin9705/PlexGuide.com-The-Awesome-Plex-Server
# Author:   Admin9705 & FlickerRate
# URL:      https://plexguide.com
#
# PlexGuide Copyright (C) 2018 PlexGuide.com
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################
echo "INFO - PGBlitz: Starting Valadiation Process" > /var/plexguide/pg.log && bash /opt/plexguide/roles/log/log.sh

mkdir -p /opt/pgops 1>/dev/null 2>&1
mkdir -p /mnt/gdrive/plexguide/checks 1>/dev/null 2>&1
tdrive=$( cat /root/.config/rclone/rclone.conf | grep team_drive )
tdrive="${tdrive:13}"

while read p; do
#  p=$(echo "${p::-1}")
p2=GDSA-TEST
echo "INFO - PGBlitz: Valadating $p2" > /var/plexguide/pg.log && bash /opt/plexguide/roles/log/log.sh

rm -r /root/.config/rclone/rclone.tmp 1>/dev/null 2>&1

tee "/root/.config/rclone/rclone.tmp" > /dev/null <<EOF
[$p2]
type = drive
client_id =
client_secret =
scope = drive
root_folder_id =
service_account_file = /opt/appdata/pgblitz/keys/unprocessed/$p
team_drive = $tdrive
EOF

mkdir -p /opt/pgops/$p2

rclone move --tpslimit 6 --checkers=20 \
  --config /root/.config/rclone/rclone.tmp \
  --transfers=8 \
  --log-file=/opt/appdata/pgblitz/rclone.log --log-level INFO --stats 10s \
  --exclude="**partial~" --exclude="**_HIDDEN~" \
  --exclude=".unionfs-fuse/**" --exclude=".unionfs/**" \
  --drive-chunk-size=32M \
  /opt/pgops/ $p2:plexguide/checks && rclone_fin_flag=1

echo "next part"

checker=$(rclone lsd \
  --config /root/.config/rclone/rclone.tmp \
$p2:plexguide/checks/ | grep "$p" | awk '{print $5}')

  if [ "$p" == "$checker" ]; then
      echo "JSON: $checker - Valid"
      echo "INFO - PGBlitz: $p2 - $p is good!" > /var/plexguide/pg.log && bash /opt/plexguide/roles/log/log.sh
    else
      echo "JSON: $checker - Invalid | Sending to /opt/appdata/pgblitz/keys/badjson/ "
      echo "INFO - PGBlitz: $p2 - is a bad JSON File - Sending Bad JSON to /opt/appdata/pgblitz/keys/badjson" > /var/plexguide/pg.log && bash /opt/plexguide/roles/log/log.sh
      mv /opt/appdata/pgblitz/keys/unprocessed/$p /opt/appdata/pgblitz/keys/badjson/ 1>/dev/null 2>&1
  fi

done </tmp/pg.keys.temp
echo "INFO - PGBlitz: Finished Validating JSON Files" > /var/plexguide/pg.log && bash /opt/plexguide/roles/log/log.sh