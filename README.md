# NFS
Working with NFS

#Дано: ВМ1 - server(nfss) c ip: 192.168.56.17 - запуск скрипта nfss_script.sh; ВМ2 - client(nfsc) c ip: 192.168.56.18 - запуск скрипта nfsс_script.sh

#Настраиваем сервер NFS 
su -
apt install nfs-kernel-server

#Настройки сервера находятся в файле /etc/nfs.conf

#Проверяем наличие слушающих портов 2049/udp, 2049/tcp,111/udp, 111/tcp
ss -tnplu

#Создаём и настраиваем директорию, которая будет экспортирована в будущем
mkdir -p /srv/share/upload 
chown -R nobody:nogroup /srv/share 
chmod 0777 /srv/share/upload 

#Cоздаём в файле /etc/exports структуру, которая позволит экспортировать ранее созданную директорию
cat << EOF > /etc/exports 
/srv/share 192.168.56.18(rw,sync,root_squash)
EOF

#Экспортируем ранее созданную директорию
exportfs -r 

#Проверяем экспортированную директорию следующей командой
exportfs -s 
 /srv/share  192.168.56.18(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

#Настраиваем клиент NFS
su -
apt install nfs-common
echo "192.168.56.17:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
systemctl daemon-reload 
systemctl restart remote-fs.target

#теперь происходит автоматическая генерация systemd units в каталоге /run/systemd/generator/, которые производят монтирование при первом обращении к каталогу /mnt/
cd /mnt; ll
mount | grep mnt
 systemd-1 on /mnt type autofs (rw,relatime,fd=71,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=15746)
192.168.56.17:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.56.17,mountvers=3,mountport=57113,mountproto=udp,local_lock=none,addr=192.168.56.17)

#Проверки стенда

root@nfsc:~# touch /mnt/upload/client_file
root@nfss:~# cd /srv/share/upload/; ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Feb  6 16:35 ./
drwxr-xr-x 3 nobody nogroup 4096 Feb  6 15:20 ../
-rw-r--r-- 1 nobody nogroup    0 Feb  6 16:35 client_file

root@nfsc:~# reboot
root@nfsc:~# cd /mnt/upload; ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Feb  6 16:35 ./
drwxr-xr-x 3 nobody nogroup 4096 Feb  6 15:20 ../
-rw-r--r-- 1 nobody nogroup    0 Feb  6 16:35 client_file

root@nfss:~# reboot
root@nfss:~# cd /srv/share/upload/; ll
total 8
drwxrwxrwx 2 nobody nogroup 4096 Feb  6 16:35 ./
drwxr-xr-x 3 nobody nogroup 4096 Feb  6 15:20 ../
-rw-r--r-- 1 nobody nogroup    0 Feb  6 16:35 client_file
root@nfss:~# exportfs -s
/srv/share  192.168.56.18(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
root@nfss:~# showmount -a 192.168.56.17
All mount points on 192.168.56.17:
192.168.56.18:/srv/share

root@nfsc:~# reboot
root@nfsc:~# ls -la /mnt/upload
total 8
drwxrwxrwx 2 nobody nogroup 4096 Feb  6 16:35 ./
drwxr-xr-x 3 nobody nogroup 4096 Feb  6 15:20 ../
-rw-r--r-- 1 nobody nogroup    0 Feb  6 16:35 client_file
root@nfsc:~# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=54,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=4030)
192.168.56.17:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.56.17,mountvers=3,mountport=37525,mountproto=udp,local_lock=none,addr=192.168.56.17)
root@nfsc:~# showmount -a 192.168.56.17
All mount points on 192.168.56.17:
192.168.56.18:/srv/share
root@nfsc:~# touch /mnt/upload/final_check
root@nfsc:~# ls -la /mnt/upload
total 8
drwxrwxrwx 2 nobody nogroup 4096 Feb  6 17:03 .
drwxr-xr-x 3 nobody nogroup 4096 Feb  6 15:20 ..
-rw-r--r-- 1 nobody nogroup    0 Feb  6 16:35 client_file
-rw-r--r-- 1 nobody nogroup    0 Feb  6 17:03 final_check
