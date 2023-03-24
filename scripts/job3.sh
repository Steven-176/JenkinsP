NAME='pre-prod'

### Crée un conteneur pre-prod ###
lxc init ubuntu:22.04 $NAME

# Attachement du conteneur à la carte réseau
lxc network attach lxdbr0 $NAME
sleep 2

# Démarre le conteneur
lxc start $NAME
sleep 2

# Configuration du réseau
lxc exec $NAME -- sed -i 's|#DNS=|DNS=1.1.1.1|g' /etc/systemd/resolved.conf
lxc exec $NAME -- systemctl restart systemd-resolved
lxc exec $NAME -- bash -c 'echo -e "[Match]\nName=*\n\n[Network]\nDHCP=ipv4" > /etc/systemd/network/10-all.network'
lxc exec $NAME -- systemctl restart systemd-networkd
sleep 2

# Installation des packages
lxc exec $NAME apt update
lxc exec $NAME -- apt install apache2 -y
lxc exec $NAME -- apt install php -y

# Récupération du répertoire git
lxc exec $NAME -- git clone 'https://github.com/Steven-176/JenkinsP.git' /var/www/html/
sleep 2

# Supprime dossier test du conteneur pre-prod
lxc exec $NAME /bin/bash/ rm /var/www/html/test/

# Eteins le conteneur prod
lxc stop prod

# Supprime conteneur prod
lxc delete prod

# Renomme conteneur pre-prod en prod 
lxc rename $NAME prod