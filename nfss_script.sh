#!/bin/bash

su -
apt install nfs-kernel-server
mkdir -p /srv/share/upload 
chown -R nobody:nogroup /srv/share 
chmod 0777 /srv/share/upload 
cat << EOF > /etc/exports 
/srv/share 192.168.56.18(rw,sync,root_squash)
EOF
exportfs -r 
