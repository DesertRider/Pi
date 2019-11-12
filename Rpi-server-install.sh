sudo apt-get update -y
sudo apt-get upgrade -y

# --- Personnalisation de l'installation par défaut
cat >> ~/.bash_aliases <<END
alias dir='ls -lah'
alias ..='cd ..'
END

source ~/.bashrc

sudo sed -i '/\\e\[5~/s/^# //g' /etc/inputrc
sudo sed -i '/\\e\[6~/s/^# //g' /etc/inputrc
bind -f /etc/inputrc

sudo apt-get install -y vim bc tree

# --- Setup de la clé ssh
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# --- Ajout des clés publiques permises
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqz35tveThInSFi4ptaMkVKoxHrsxhUDb9xC6epDuu/3s2hvFPyuw8QOGq06tP5WmHeXgLgatzdHX5LrJ4zb425ExRlGOV85BP5tpgi1d+7bJgD94og4Fq475RjpPc5T5OKC+jYhDf/JMvID+PpDWRpPkaKUYdvmwacH95j7i1XuldUu5nKatIK3b14eWyPhmVdtAmw2C+gncTNSdZG5WM5mMfOEmbDMYcduGlUlKOB5IXp9D+E1Mg8J4gWUA6UEpqoSBjJMvSH5Vu3FlcAy0A2f0a9ckrlNsQ6EtW+8FOEFwamEoiLR8QHbV0Djya7WP7DDww4z2HjLc6mg3MTkxL serge@iMac-de-Serge.local' >> ~/.ssh/authorized_keys

# --- Restrictions d'accès SSH (si ouvert sur Internet)
# useradd pi-admin ...

# sudo vim /etc/ssh/sshd_config
# PasswordAuthentication no
# KbdInteractive no
# ajouter AllowUsers user1 user2
# sudo systemctl restart sshd

# --- Installation de Webmin
cd
sudo apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
wget http://prdownloads.sourceforge.net/webadmin/webmin_1.930_all.deb
sudo dpkg --install webmin_1.930_all.deb

# --- Installation NFS Server
sudo apt-get install nfs-kernel-server -y

# --- Installation de xfs pour clé USB
sudo apt-get install -y xfsprogs

# --- Partionnage et formattage du disque SSD
# fdisk créer partition 1 = 16gb, partition 2 = reste
sudo mkfs -t ext4  -L rootfs /dev/sda1
sudo mkfs -t btrfs -L data   /dev/sda2

PARTUUID1=$(lsblk -o PARTUUID /dev/sda1 | tail -n1 | awk '{print $1}')
PARTUUID2=$(lsblk -o PARTUUID /dev/sda2 | tail -n1 | awk '{print $1}')

# --- Identification de la partition boot sur SSD
# --- Ajuster /boot/cmdline.txt (quirks)
sudo cp /boot/cmdline.txt /boot/cmdline.txt.bkp
echo "usb-storage.quirks=152d:0578:u console=serial0,115200 console=tty1 root=PARTUUID=6a0660a9-4e90-814d-8a78-977afc39391e rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait program_usb_timeout=1" | sudo tee -a /boot/cmdline.txt

# --- copier / sur 1ere partition disque ssd
sudo mount /dev/sda1 /mnt
sudo rsync -ax / /mnt
sudo mkdir -p /mnt/data

# retirer ligne de mount de / avec SED
sudo sed -i -e "/ \/ /d" -e "/\/data/d" /mnt/etc/fstab
echo "PARTUUID=$PARTUUID1  /        ext4    defaults,noatime  0 1" | sudo tee -a /mnt/etc/fstab
echo "PARTUUID=$PARTUUID2  /data    xfs     rw,relatime,attr2,inode64,noquota 0 0" | sudo tee -a /mnt/etc/fstab
# on attends le prochain redémarrage pour monter /data

# --- Préparation du disque /data et shares NFS
sudo mkdir -p /data/backups/bidule1 /data/partages/bidule1 /data/backups/bidule3 /data/backups/ncp /data/nextcloud
echo "/data/backups/bidule1   192.168.0.253(no_root_squash,insecure,rw)" | sudo tee -a /etc/exports
echo "/data/partages/bidule1  192.168.0.253(no_root_squash,insecure,rw)" | sudo tee -a /etc/exports
# sudo exportfs -a

# --- Installation de raspi-backup
# ref: https://bit.ly/2PNUgem
curl -sSLO https://www.linux-tips-and-tricks.de/raspiBackupInstallUI.sh && sudo bash ./raspiBackupInstallUI.sh
# configurer pour utiliser /data/backups comme path de destinations (il créera le sous-répertoire bidule3)

# --- Installation de NextCloudPi
cd
curl -sSL https://raw.githubusercontent.com/nextcloud/nextcloudpi/master/install.sh > nextcloudpi-install.sh
sudo bash ./nextcloudpi-install.sh

# --- Dynamic DNS setup avec noip
cd /home/pi
mkdir noip
cd noip/
wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
tar xvzf noip-duc-linux.tar.gz
cd noip-2.1.9-1/
sudo make
sudo make install

# --- rootCA et certificat pour bidule3
# voir https://stackoverflow.com/questions/991758/how-to-get-pem-file-from-key-and-crt-files 
# ensuite:
#First: Visit https://192.168.0.254/  https://nextcloudpi.local/ (also https://nextcloudpi.lan/ or https://nextcloudpi/ on windows and mac)
#to activate your instance of NC, and save the auto generated passwords. You may review or reset them
#anytime by using nc-admin and nc-passwd.
#Second: Type 'sudo ncp-config' to further configure NCP, or access ncp-web on https://192.168.0.254:4443/
#Note: You will have to add an exception, to bypass your browser warning when you
#first load the activation and :4443 pages. You can run letsencrypt to get rid of
#the warning if you have a (sub)domain available.

# --- shell script to automatically issue & renew the free certificates from Let's Encrypt
# ref: https://bit.ly/2Nm85Pq et https://bit.ly/2CiLXPF
curl https://get.acme.sh | sh

# ---
