#!/bin/bash

NAME='test'

#création du conteneur
lxc init ubuntu:22.04 $NAME
sleep 2

#attachement du conteneur à la carte réseau
lxc network attach lxdbr0 $NAME
sleep 2

#demarrage du container
lxc start $NAME
sleep 2
#configuration du réseau
lxc exec $NAME -- sed -i 's|#DNS=|DNS=1.1.1.1|g' /etc/systemd/resolved.conf
lxc exec $NAME -- systemctl restart systemd-resolved
lxc exec $NAME -- bash -c 'echo -e "[Match]\nName=*\n\n[Network]\nDHCP=ipv4" > /etc/systemd/network/10-all.network'
lxc exec $NAME -- systemctl restart systemd-networkd
sleep 2

#installation des packages
lxc exec $NAME apt update
lxc exec $NAME -- apt install apache2 -y
lxc exec $NAME -- apt install php -y
lxc exec $NAME -- apt install git -y

#suppresion de index.html
lxc exec $NAME rm /var/www/html/index.html

#récupération du répertoire git
lxc exec $NAME -- git clone 'https://github.com/Steven-176/JenkinsP.git' /var/www/html/
sleep 2

#récupération de l'adresse ip du conteneur test
CT_IP=$(lxc ls test -f csv -c 4 | cut -d ' ' -f 1)
tab=()
allValid=true

for A in {1..4} 
do
  #récupation du résultat de la page
  RESULT=$(curl $CT_IP/test/test$A.php)
  sleep 2
  
  echo "$RESULT"

#vérification si le contenu de la page renvoie "oui"
if [ "$RESULT" == "oui" ]
then
	echo "true"
    tab+=("yes")
else
	echo "false"
    tab+=("no")
fi
done


for i in "${tab[@]}"
do
    if [ "$i" -eq "no" ]
    then
        allValid=false
        break
    fi
done

if $allValid
then
	### Si les tests sont tous a true ###
    #récupération du conteneur de prod
        lxc list -f csv -c n | grep -x prod
        
        #vérificattion si un conteneur prod existe 
        if [ $? -eq 0 ]
        then
        
            #arrêt du conteneur de prod
            lxc stop prod
            sleep 2
        
            #renommage du contenur de prod en conteneur de rollback
            lxc rename prod rollback
            sleep 2
        fi
        #arrêt du conteneur de test
        lxc stop $NAME
        sleep 2
        
        #renommage du contenur de test en conteneur de prod
        lxc rename $NAME prod
        sleep 2
        
        #démarrage du nouveau conteneur de prod
        lxc start prod
        sleep 2
else
	### Si au moins un des tests est a false ###
        #arrêt du conteneur test
    lxc stop test
    sleep 2

    #suppression du conteneur de test
    lxc rm test
    
    exit 1
fi