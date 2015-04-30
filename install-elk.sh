#!/bin/bash

  echo -e "Voulez-vous installer la pile ELK? (o/n) "
  read on
  case $on in
    o* | O*)    echo -e "Mise a jour du systeme..."
		apt-get -y upgrade
		echo -e "Installation de Open-JDK7\n"
		apt-get -y install openjdk-7-jre
		;;
    [nN]*  )  echo "Sortie" ; exit ;;
    q*     )  exit  ;;
    * )      exit;;  
  esac

echo -e "Quelle partie de la pile ELK voulez-vous installer ? 
1. Elasticsearch.
2. Logstash.
3. Kibana + Nginx.
4. Toute la pile."
read choix
case $choix in
	1) echo -e "Installation de Elasticsearch\n"
	echo -e "Création du source list pour Elasticsearch\n"
	wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
	echo 'deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main' | tee /etc/apt/sources.list.d/elasticsearch.list
	apt-get update
	apt-get -y install elasticsearch=1.4.4
	echo -e "Configuration de Elasticsearch\n"
	sleep 1
	echo "network.host: localhost" >> /etc/elasticsearch/elasticsearch.yml
	echo -e "Demarrage du serveur et ajout du service au demarrage\n"
	sleep 1
	service elasticsearch restart
	update-rc.d elasticsearch defaults 95 10
	echo -e "Elasticsearch pret\n"
	sleep 1
	exit
	;;
###############################################################
	2) echo -e "Installation de Logstash\n"
	echo 'deb http://packages.elasticsearch.org/logstash/1.5/debian stable main' | tee /etc/apt/sources.list.d/logstash.list
	apt-get update
	apt-get -y install logstash
	echo -e "Configuration de Logstash\n"
	cp ./logstash /etc/init.d/logstash
	service logstash restart
	echo -e "Logstash pret\n"
	sleep 1 
	exit
	;;
#####################################################################
	3)echo -e "Installation du serveur web Nginx\n"
	apt-get -y install nginx apache2-utils
	echo -e "Creation du compte administrateur pour Kibana ...\n"
	echo -e "Entrez votre login ( sans majuscules, ni espaces, ni caracteres speciaux ) :"
	read login
	echo -e "Creation d'un mot de passe pour l'administrateur $login\n"
	htpasswd -c /etc/nginx/htpasswd.users $login
	echo -e "Configuration du serveur Nginx\n"
	echo -e "Creation des elements necessaires pour une connexion HTTPS ( .key, .crt)\n"
	sleep 1
	echo -e "Installation de openssl\n"
	apt-get -y install openssl
	echo -e "Choisissez l'emplacement du dossier contenant les certificats ( ex : /etc/nginx/certmonsite) :"
	read location
	mkdir $location
	cd $location
	echo -e "Creation des certificats ...\n"
	openssl genrsa -out server.key 1024
	openssl req -new -key server.key -out server.csr
	openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
	echo -e "Entrez le nom de domaine de votre serveur web ( ex : mon.siteweb.com) :"
	read FQDN
	echo -e "server {
        listen 80;

        server_name $FQDN;
        return 301 https://\$host\$request_uri;

	}
	
	server {
	        listen 443 ;
	
	        server_name $FQDN;
	
	        auth_basic \"Restricted Access\";
	        auth_basic_user_file /etc/nginx/htpasswd.users;
	
	        location / {
	                proxy_pass http://localhost:5601;
	                proxy_http_version 1.1;
	                proxy_set_header Upgrade \$http_upgrade;
	                proxy_set_header Connection 'upgrade';
	                proxy_set_header Host \$host;
	                proxy_cache_bypass \$http_upgrade;
	        }
	
	
	        ssl_certificate $location/server.crt;
	        ssl_certificate_key $location/server.key;
	
	        ssl on;
	
	
	}
" > /etc/nginx/sites-available/default
	service nginx restart
	echo -e "Nginx pret\n"
	sleep 1
	echo -e "Installation de Kibana\n"
	cd 
	echo -e "Recupérationdes fichiers d'installation\n"
	wget https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz
	echo -e "Decompression\n"
	tar xvf kibana-*.tar.gz
	echo -e "Configuration\n"
	sed -i -e "s/\"0\.0\.0\.0\"/\"localhost\"/g" ~/kibana-4*/config/kibana.yml
	mkdir -p /opt/kibana
	cp -R ~/kibana-4*/* /opt/kibana/
	echo -e "Ajout de Kibana en tant que service\n"
	cd /etc/init.d && wget https://gist.githubusercontent.com/thisismitch/8b15ac909aed214ad04a/raw/bce61d85643c2dcdfbc2728c55a41dab444dca20/kibana4
	chmod +x /etc/init.d/kibana4
	update-rc.d kibana4 defaults 96 9
	service kibana4 start
	echo -e "Kibana pret\n"
	sleep 1
	exit
	;;
	4) echo -e "Installation de la pile complete Elasticsearch Logstash Kibana\n"
	sleep 1
	echo -e "Installation de Elasticsearch\n"
	echo -e "Création du source list pour Elasticsearch\n"
	wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
	echo 'deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main' | tee /etc/apt/sources.list.d/elasticsearch.list
	apt-get update
	apt-get -y install elasticsearch=1.4.4
	echo -e "Configuration de Elasticsearch\n"
	sleep 1
	echo "network.host: localhost" >> /etc/elasticsearch/elasticsearch.yml
	echo -e "Demarrage du serveur et ajout du service au demarrage\n"
	sleep 1
	service elasticsearch restart
	update-rc.d elasticsearch defaults 95 10
	echo -e "Elasticsearch pret\n"
	sleep 1
	echo -e "Installation de Logstash\n"
	echo 'deb http://packages.elasticsearch.org/logstash/1.5/debian stable main' | tee /etc/apt/sources.list.d/logstash.list
	apt-get update
	apt-get -y install logstash
	echo -e "Configuration de Logstash\n"
	cp ./logstash /etc/init.d/logstash
	service logstash restart
	echo -e "Logstash pret\n"
	sleep 1 
	echo -e "Installation du serveur web Nginx\n"
	apt-get -y install nginx apache2-utils
	echo -e "Creation du compte administrateur pour Kibana ...\n"
	echo -e "Entrez votre login ( sans majuscules, ni espaces, ni caracteres speciaux ) :"
	read login
	echo -e "Creation d'un mot de passe pour l'administrateur $login\n"
	htpasswd -c /etc/nginx/htpasswd.users $login
	echo -e "Configuration du serveur Nginx\n"
	echo -e "Creation des elements necessaires pour une connexion HTTPS ( .key, .crt)\n"
	sleep 1
	echo -e "Installation de openssl\n"
	apt-get -y install openssl
	echo -e "Choisissez l'emplacement du dossier contenant les certificats ( ex : /etc/nginx/certmonsite) :"
	read location
	mkdir $location
	cd $location
	echo -e "Creation des certificats ...\n"
	openssl genrsa -out server.key 1024
	openssl req -new -key server.key -out server.csr
	openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
	echo -e "Entrez le nom de domaine de votre serveur web ( ex : mon.siteweb.com) :"
	read FQDN
	echo -e "server {
        listen 80;

        server_name $FQDN;
        return 301 https://\$host\$request_uri;

	}
	
	server {
	        listen 443 ;
	
	        server_name $FQDN;
	
	        auth_basic \"Restricted Access\";
	        auth_basic_user_file /etc/nginx/htpasswd.users;
	
	        location / {
	                proxy_pass http://localhost:5601;
	                proxy_http_version 1.1;
	                proxy_set_header Upgrade \$http_upgrade;
	                proxy_set_header Connection 'upgrade';
	                proxy_set_header Host \$host;
	                proxy_cache_bypass \$http_upgrade;
	        }
	
	
	        ssl_certificate $location/server.crt;
	        ssl_certificate_key $location/server.key;
	
	        ssl on;
	
	
	}
" > /etc/nginx/sites-available/default
	service nginx restart
	echo -e "Nginx pret\n"
	sleep 1
	echo -e "Installation de Kibana\n"
	cd 
	echo -e "Recupérationdes fichiers d'installation\n"
	wget https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz
	echo -e "Decompression\n"
	tar xvf kibana-*.tar.gz
	echo -e "Configuration\n"
	sed -i -e "s/\"0\.0\.0\.0\"/\"localhost\"/g" ~/kibana-4*/config/kibana.yml
	mkdir -p /opt/kibana
	cp -R ~/kibana-4*/* /opt/kibana/
	echo -e "Ajout de Kibana en tant que service\n"
	cd /etc/init.d && wget https://gist.githubusercontent.com/thisismitch/8b15ac909aed214ad04a/raw/bce61d85643c2dcdfbc2728c55a41dab444dca20/kibana4
	chmod +x /etc/init.d/kibana4
	update-rc.d kibana4 defaults 96 9
	service kibana4 start
	echo -e "Kibana pret\n"
	sleep 1
	echo -e "Pile ELK prete !!\n"
	sleep 1 
	exit
	;;
	esac
	
	exit
	
