# --- Personnalisation de l'installation par défaut
echo >> ~/.bashrc <<END
alias dir='ls -lah'
alias ..='cd ..'
END

sudo sed -i '/\\e\[5~/s/^# //g' /etc/inputrc
sudo sed -i '/\\e\[6~/s/^# //g' /etc/inputrc
bind -f /etc/inputrc

sudo apt-get install -y vim bc tree

# Encryption du mot de passe utilisé pour le WIFI (si désiré)
# remplacer ssid et password par les vrais valeurs
wpa_passphrase ssid password | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf

# --- Setup de la clé ssh
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# --- Ajout des clés publiques permises
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqz35tveThInSFi4ptaMkVKoxHrsxhUDb9xC6epDuu/3s2hvFPyuw8QOGq06tP5WmHeXgLgatzdHX5LrJ4zb425ExRlGOV85BP5tpgi1d+7bJgD94og4Fq475RjpPc5T5OKC+jYhDf/JMvID+PpDWRpPkaKUYdvmwacH95j7i1XuldUu5nKatIK3b14eWyPhmVdtAmw2C+gncTNSdZG5WM5mMfOEmbDMYcduGlUlKOB5IXp9D+E1Mg8J4gWUA6UEpqoSBjJMvSH5Vu3FlcAy0A2f0a9ckrlNsQ6EtW+8FOEFwamEoiLR8QHbV0Djya7WP7DDww4z2HjLc6mg3MTkxL serge@iMac-de-Serge.local' >> ~/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz3ZQTNTh8tEu5l8PFI68ZUw1g/ew5lVaEGVKF8i1vaWvBKDNUxcnWFNGWFSs2vy2uHGUiNvA46GCDt/BgKp7qT4GmZ1RCy3TGYEGDE/soC6m7D7UUEVEKBoQTR0b9sD0aYCmPbHfRo0tiTx0AnE47aBcatFiQ0AvdcnlOFv3fnsPpiSpU4YHLNSzZu3DnauB6X44woj9qMKqxttc7XwhOUPKvDv0nbHutheaSfE/v6sPonsCrxjiOFdmq83tCub+kirT5hMo+6m3SAGppM+i0JX4QcJ5aWW2uFbauAc84Mh04xS5Gms2GByB9X6xEarM0Jw0j1ZOdIrtby00ILneb pi@bidule3' >>~/.ssh/authorized_keys

# --- Restrictions d'accès SSH (si ouvert sur Internet)

# useradd user ...
mkdir -p /home/user/.ssh
cd /home/user/.ssh
sudo cp /home/pi/.ssh/* .
sudo chown user:user *
echo "pi ALL=(ALL) NOPASSWD: ALL" | sudo cat - > /etc/sudoers.d/010_user-nopassword


# sudo vim /etc/ssh/sshd_config
PasswordAuthentication no
# ajouter AllowUsers user
sudo systemctl restart sshd

# --- Installation de Webmin
cd
sudo apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
wget http://prdownloads.sourceforge.net/webadmin/webmin_1.930_all.deb
sudo dpkg --install webmin_1.930_all.deb
echo "bind=127.0.0.1" | sudo tee -a /etc/webmin/miniserv.conf
# Webmin est maintenant accessible sur le port 10000

# --- Installation de RPi-Monitor
sudo apt-get install dirmngr
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2C0D3C0F
sudo wget http://goo.gl/vewCLL -O /etc/apt/sources.list.d/rpimonitor.list

sudo apt-get update
sudo apt-get install -y rpimonitor
sudo sed -i 's/#daemon.addr=0.0.0.0/daemon.addr=127.0.0.1/g' /etc/rpimonitor/daemon.conf

sudo /etc/init.d/rpimonitor update
sudo /etc/init.d/rpimonitor install_auto_package_status_update 

# Configurer au besoin les fichiers dans /etc/rpimonitor/...
# RPi-Monitor est maintenant accessible sur le port 8888

# --- Installation de xfs pour clé USB
sudo apt-get install -y xfsprogs

# --- Encryption de la clé USB
sudo apt-get install -y cryptsetup
sudo modprobe dm-crypt sha256 aes
# Notez bien la passphrase dans la prochaine étape!
sudo cryptsetup --verify-passphrase luksFormat /dev/sda1 -c aes -s 256 -h sha256
sudo cryptsetup luksOpen /dev/sda1 securebackup
sudo mkfs -t ext4 -m 1 /dev/mapper/securebackup

sudo mkdir /media/secure
sudo mount /dev/mapper/securebackup /media/secure/
sudo chown pi:pi /media/secure/

# Notre clé pour monter la partition automatiquement
cd /home/pi
dd if=/dev/urandom of=Cruzer1-keyfile bs=1024 count=4
chmod 400 Cruzer1-keyfile
sudo cryptsetup luksAddKey /dev/sda1 /home/pi/Cruzer1-keyfile


echo "securebackup   /dev/sda1   /home/pi/Cruzer1-keyfile   luks" | sudo tee -a /etc/crypttab 
# ou mieux, trouvez le uuid de la partition par la commande
lsblk -o +uuid,name
# et ajustez la ligne suivante:
echo "securebackup   /dev/disk/by-uuid/ee38c998-5e40-4cfd-bdc4-11e1ae954902   /home/pi/Cruzer1-keyfile   luks" | sudo tee -a /etc/crypttab 

echo "/dev/mapper/securebackup   /media/secure   ext4   defaults,rw   0  0" | sudo tee -a /etc/fstab

cd /home/pi
dd if=/dev/urandom of=Cruzer1-keyfile bs=1024 count=4
chmod 400 Cruzer1-keyfile
sudo cryptsetup luksAddKey /dev/sda1 /home/pi/Cruzer1-keyfile

# --- Dynamic DNS setup avec noip
# Ref.: https://my.noip.com/#!/dynamic-dns/duc
cd /home/pi
mkdir noip
cd noip/
wget https://www.noip.com/client/linux/noip-duc-linux.tar.gz
tar xvzf noip-duc-linux.tar.gz
cd noip-2.1.9-1/
sudo make
sudo make install
# Si problème avec la création du fichier de config:
/usr/local/bin/noip2 -C -c /tmp/no-ip2.conf
sudo mv /tmp/no-ip2.conf /usr/local/etc/

# Installer le service noip2.service
cd
cat > noip2.service <<END
[Unit]
Description=No-ip.com dynamic IP address updater
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target
Alias=noip.service

[Service]
# Start main service
ExecStart=/usr/local/bin/noip2
Restart=always
Type=forking
END

sudo mv noip2.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable noip2
sudo systemctl start noip2
systemctl status noip2

# --- Serveur de courrier
sudo apt-get install -y ssmtp
sudo apt-get install -y mailutils
# fonctionne pas, bloqué même si configuré dans gmail

# --- Installation de raspiBackup pour backup de la carte SD
# répertoire qu'on va utiliser
mkdir /media/secure/backup-sd
# configurer raspiBackup pour utiliser ce répertoire...
curl -sSLO https://www.linux-tips-and-tricks.de/raspiBackupInstallUI.sh && sudo bash ./raspiBackupInstallUI.sh

# ---
