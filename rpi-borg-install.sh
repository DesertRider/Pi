# --- Personnalisation de l'installation par défaut
echo >> ~/.bashrc <<END
alias dir='ls -lah'
alias ..='cd ..'
END

sudo sed -i '/\\e\[5~/s/^# //g' /etc/inputrc
sudo sed -i '/\\e\[6~/s/^# //g' /etc/inputrc
bind -f /etc/inputrc

# Outils de base...
sudo apt-get update
sudo apt-get install -y vim tree

# Encryption du mot de passe utilisé pour le WIFI (si désiré)
# remplacer ssid et password par les vrais valeurs
wpa_passphrase ssid password | grep -v "#" | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf

# --- Setup de la clé ssh
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# --- Ajout des clés publiques permises
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqz35tveThInSFi4ptaMkVKoxHrsxhUDb9xC6epDuu/3s2hvFPyuw8QOGq06tP5WmHeXgLgatzdHX5LrJ4zb425ExRlGOV85BP5tpgi1d+7bJgD94og4Fq475RjpPc5T5OKC+jYhDf/JMvID+PpDWRpPkaKUYdvmwacH95j7i1XuldUu5nKatIK3b14eWyPhmVdtAmw2C+gncTNSdZG5WM5mMfOEmbDMYcduGlUlKOB5IXp9D+E1Mg8J4gWUA6UEpqoSBjJMvSH5Vu3FlcAy0A2f0a9ckrlNsQ6EtW+8FOEFwamEoiLR8QHbV0Djya7WP7DDww4z2HjLc6mg3MTkxL serge@iMac-de-Serge.local' >> ~/.ssh/authorized_keys

# Installation de remote.it
sudo apt-get install -y remoteit

# Installation de Borg
sudo apt install -y borgbackup

# Installation de usbmount pour monter la clé USB sans que ce ne soit dans fstab
# (on ne sera pas bloqué si la clé n'est pas montée)
sudo apt install -y usbmount

# ---
