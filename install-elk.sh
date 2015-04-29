#!/bin/bash
echo -e "Mise a jour du systeme..."
apt-get -y upgrade
echo -e "Installation de Open-JDK7\n"
apt-get -y install openjdk-7-jre
echo -e "Installation de Elasticsearch\n"
echo -e "Création du source list pour Elasticsearch\n"
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
echo 'deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main' | tee /etc/apt/sources.list.d/elasticsearch.list
apt-get update
apt-get -y install elasticsearch=1.4.4
echo -e "Configuration de Elasticsearch\n"
echo "network.host: localhost" >> /etc/elasticsearch/elasticsearch.yml
echo -e "Demarrage du serveur et ajout du service au demarrage\n"
service elasticsearch restart
update-rc.d elasticsearch defaults 95 10
echo -e "Elasticsearch pret\n"
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
echo -e "Installation du serveur web Nginx\n"
apt-get -y install nginx apache2-utils
echo -e "Creation d'un mot de passe pour l'administrateur kibanaadmin\n"
htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
echo -e "Configuration du serveur Nginx\n"
echo -e "server {
    listen 80;

    server_name elk-preprod.stickyadstv.com;

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
			}" > /etc/nginx/sites-available/default
service nginx restart
echo -e "Nginx pret\n"
echo -e "Installation de Logstash\n"
echo 'deb http://packages.elasticsearch.org/logstash/1.5/debian stable main' | tee /etc/apt/sources.list.d/logstash.list
apt-get update
apt-get -y install logstash
echo -e "Configuration de Logstash\n"
echo -e "#!/bin/sh
# Init script for logstash
# Maintained by Elasticsearch
# Generated by pleaserun.
# Implemented based on LSB Core 3.1:
#   * Sections: 20.2, 20.3
#
### BEGIN INIT INFO
# Provides:          logstash
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: 
# Description:        Starts Logstash as a daemon.
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin
export PATH

if [ `id -u` -ne 0 ]; then
   echo "You need root privileges to run this script"
   exit 1
fi

name=logstash
pidfile="/var/run/$name.pid"

LS_USER=logstash
LS_GROUP=logstash
LS_HOME=/var/lib/logstash
LS_HEAP_SIZE="500m"
LS_JAVA_OPTS="-Djava.io.tmpdir=${LS_HOME}"
LS_LOG_DIR=/var/log/logstash
LS_LOG_FILE="${LS_LOG_DIR}/$name.log"
LS_CONF_DIR=/etc/logstash/conf.d
LS_OPEN_FILES=16384
LS_NICE=19
LS_OPTS=""

[ -r /etc/default/$name ] && . /etc/default/$name
[ -r /etc/sysconfig/$name ] && . /etc/sysconfig/$name

program=/opt/logstash/bin/logstash
args="agent -f ${LS_CONF_DIR} -l ${LS_LOG_FILE} ${LS_OPTS}"

start() {


  JAVA_OPTS=${LS_JAVA_OPTS}
  HOME=${LS_HOME}
  export PATH HOME JAVA_OPTS LS_HEAP_SIZE LS_JAVA_OPTS LS_USE_GC_LOGGING

  # set ulimit as (root, presumably) first, before we drop privileges
  ulimit -n ${LS_OPEN_FILES}

  # Run the program!
  nice -n ${LS_NICE} chroot --userspec $LS_USER:$LS_GROUP / sh -c "
    cd $LS_HOME
    ulimit -n ${LS_OPEN_FILES}
    exec \"$program\" $args
  " > "${LS_LOG_DIR}/$name.stdout" 2> "${LS_LOG_DIR}/$name.err" &

  # Generate the pidfile from here. If we instead made the forked process
  # generate it there will be a race condition between the pidfile writing
  # and a process possibly asking for status.
  echo $! > $pidfile

  echo "$name started."
  return 0
}

stop() {
  # Try a few times to kill TERM the program
  if status ; then
    pid=`cat "$pidfile"`
    echo "Killing $name (pid $pid) with SIGTERM"
    kill -TERM $pid
    # Wait for it to exit.
    for i in 1 2 3 4 5 ; do
      echo "Waiting $name (pid $pid) to die..."
      status || break
      sleep 1
    done
    if status ; then
      echo "$name stop failed; still running."
    else
      echo "$name stopped."
    fi
  fi
}

status() {
  if [ -f "$pidfile" ] ; then
    pid=`cat "$pidfile"`
    if kill -0 $pid > /dev/null 2> /dev/null ; then
      # process by this pid is running.
      # It may not be our pid, but that's what you get with just pidfiles.
      # TODO(sissel): Check if this process seems to be the same as the one we
      # expect. It'd be nice to use flock here, but flock uses fork, not exec,
      # so it makes it quite awkward to use in this case.
      return 0
    else
      return 2 # program is dead but pid file exists
    fi
  else
    return 3 # program is not running
  fi
}

force_stop() {
  if status ; then
    stop
    status && kill -KILL `cat "$pidfile"`
  fi
}


case "$1" in
  start)
    status
    code=$?
    if [ $code -eq 0 ]; then
      echo "$name is already running"
    else
      start
      code=$?
    fi
    exit $code
    ;;
  stop) stop ;;
  force-stop) force_stop ;;
  status) 
    status
    code=$?
    if [ $code -eq 0 ] ; then
      echo "$name is running"
    else
      echo "$name is not running"
    fi
    exit $code
    ;;
  restart) 
    
    force_stop && start 
    ;;
  *)
    echo "Usage: $SCRIPTNAME {start|stop|force-stop|status|restart}" >&2
    exit 3
  ;;
esac

exit $?
" > /etc/init.d/logstash
service logstash restart
echo -e "Logstash pret\n"
echo -e "Pile ELK prete !!\n"
