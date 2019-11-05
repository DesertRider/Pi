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
wget http://prdownloads.sourcefsudo apt-get install nfs-kernel-server -yorge.net/webadmin/webmin_1.930_all.deb
sudo dpkg --install webmin_1.930_all.deb

# --- Installation NFS Server

sudo apt-get install nfs-kernel-server -y

# --- Installation de xfs pour clé USB
sudo apt-get install -y xfsprogs

# --- Ajuster /boot/cmdline.txt (quirks)
# ajouter
usb-storage.quirks=152d:0578:u au début de la ligne

# --- Partionnage et formattage du disque SSD
# fdisk créer partition 1 = 16gb, partition 2 = reste
sudo mkfs -t ext4 -L rootfs /dev/sda1
sudo mkfs -t xfs  -L data   /dev/sda2
sudo mkdir /data

UUID=$(lsblk -o UUID /dev/sda2 | tail -n1 | awk '{print $1}')
echo "UUID=$UUID  /data    xfs rw,relatime,attr2,inode64,noquota 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# --- Préparation du disque /data

echo "/data/backups/bidule1   192.168.0.253(no_root_squash,insecure,rw)" | sudo tee -a /etc/exports
echo "/data/partages/bidule1  192.168.0.253(no_root_squash,insecure,rw)" | sudo tee -a /etc/exports
sudo mkdir -p /data/backups/bidule1 /data/partages/bidule1
sudo exportfs -a


# ---
