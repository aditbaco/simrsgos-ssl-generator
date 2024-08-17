#!/bin/sh

###################################################################
#Script Name	: SSL Generator for SIMGOS V2+
#Description	: create SSL for simgos server
#Args           : config/install
###################################################################
############## LENGKAPI DATA DIBAWAH INI ####################
PROVINSI=""
KOTA=""
KODENAMARS=""
INSTALASIRS=""
EMAIL=""

######### JANGAN MENGUBAH APAPUN DIBAWAH BARIS IN I##########
INSTALLDIR='/home/simgos'
HOSTNAME='simgos2'
MYIP=$(ip route get 1 | awk '{print $NF;exit}')
DT=$(date +"%d%m%y")
RED="31"
GREEN="32"
BOLDRED="\e[1;${RED}m"
BOLDGREEN="\e[1;${GREEN}m"
ENDCOLOR="\e[0m"
###########################################################

CENTOSVER=$(awk '{ print $3 }' /etc/redhat-release | cut -d . -f1)

if [ "$CENTOSVER" == 'release' ]; then
    CENTOSVER=$(awk '{ print $4 }' /etc/redhat-release | cut -d . -f1)
fi

if [ "$(id -u)" != 0 ]; then
  echo "$(date) : script needs to be run as root user" >&2
  if [ "$(id -Gn | grep -o wheel)" ]; then
    echo "$(date) : if using a sudo user, switch to full root first:" >&2
    echo >&2
    echo "sudo -i" >&2
  fi
  exit 1
fi

DEF=${1:-novalue}

banner() {
    if [ -f "$(which figlet)" ]; then
        figlet -ckf standard "SIMGOS V2+ SSL Install"
    else
        time yum -y -q install figlet
        banner
    fi
} 

double_check_data() {
    if [ -z "${PROVINSI}" ]; then
        echo -e "$(date) : ${BOLDRED}Data Provinsi kosong. Silakan isi dulu.${ENDCOLOR}"
        exit
    fi
    if [ -z "${KOTA}" ]; then
        echo -e "$(date) : ${BOLDRED}Data Kota kosong. Silakan isi dulu.${ENDCOLOR}"
        exit
    fi
    if [ -z "${KODENAMARS}" ]; then
        echo -e "$(date) : ${BOLDRED}Data Kode & Nama RS kosong. Silakan isi dulu.${ENDCOLOR}"
        exit
    fi
    if [ -z "${INSTALASIRS}" ]; then
        echo -e "$(date) : ${BOLDRED}Data Instalasi RS kosong. Silakan isi dulu.${ENDCOLOR}"
        exit
    fi
    if [ -z "${EMAIL}" ]; then
        echo -e "$(date) : ${BOLDRED}Data Email kosong. Silakan isi dulu.${ENDCOLOR}"
        exit
    fi
}

double_check_packages() {
    if [ ! -f /usr/bin/wget ]; then
        echo "$(date) : wget not found. installing..."
        time yum -y -q install wget
    fi
    if [ ! -f /usr/bin/openssl ]; then
        echo "$(date) : openssl not found. installing..."
        time yum -y -q install openssl
    fi
    if [[ -z "$(rpm -qa | grep mod_ssl)" ]]; then
        echo "$(date) : mod_ssl not found. installing..."
        time yum -y -q install mod_ssl
    fi
    if [ ! -f /usr/bin/nano ]; then
        echo "$(date) : nano not found. installing..."
        time yum -y -q install nano
    fi
    if [ ! -f /usr/bin/figlet ]; then
        echo "$(date) : figlet not found. installing..."
        time yum -y install figlet
    fi
} 

certconfig() {
    if [[ ! -f /usr/bin/wget || ! -f /usr/bin/openssl || -z "$(rpm -qa | grep mod_ssl)" ]]; then       
        echo "$(date) : please wait, checking required packages..."
        double_check_packages
        echo
        echo "$(date) : --------------------------------------------------------"
        echo -e "$(date) : ${BOLDGREEN}Required package has been installed. Continuing...${ENDCOLOR}"
        echo "$(date) : --------------------------------------------------------"
        echo
    fi
    cd $INSTALLDIR
    double_check_data
    if [[ ! -f "${INSTALLDIR}/certs" ]]; then
        echo "$(date) : creating required directory..."
        mkdir -p /home/simgos/certs
        cd "${INSTALLDIR}/certs"
        echo "$(date) : creating configuration file..."
            if [[ "$(/usr/bin/cat /etc/httpd/conf/httpd.conf | grep '#ServerName www.example.com:80' >/dev/null 2>&1; echo $?)" != '0' ]]; then
                echo "$(date) : using current hostname:"
                HOSTNAME=$(/usr/bin/cat /etc/httpd/conf/httpd.conf | grep "ServerName" | tail -1 | awk '{print $2}')
                echo -e "$(date) : ${BOLDGREEN}${HOSTNAME}${ENDCOLOR}"
            else
                echo "$(date) : changing default hostname to:"
                sed -i 's/#ServerName www.example.com:80/ServerName simgos2/g' /etc/httpd/conf/httpd.conf
                HOSTNAME='simgos2'
                echo -e "$(date) : ${BOLDGREEN}${HOSTNAME}${ENDCOLOR}"
            fi
cat > "/home/simgos/certs/config.cnf" <<EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
countryName = ID
stateOrProvinceName = $PROVINSI
localityName = $KOTA
0.organizationName = $KODENAMARS
organizationalUnitName = $INSTALASIRS
commonName = $HOSTNAME
emailAddress = $EMAIL

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical,CA:true

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

EOF
        echo
        echo "$(date) : --------------------------------------------------------"
        echo "$(date) : config file has been created. your SSL configuration file:"
        echo
        cat $INSTALLDIR/certs/config.cnf
        echo
        echo "$(date) : --------------------------------------------------------"
        echo -e "$(date) : ${BOLDRED}please double check the data before you install.${ENDCOLOR}"
        echo "$(date) : --------------------------------------------------------"
        echo -e "$(date) : please install SSL using: ${BOLDGREEN}bash sslcert.sh install${ENDCOLOR}"
        echo "$(date) : --------------------------------------------------------"
        echo "$(date) : Config Summary Logs: ${INSTALLDIR}/ssl_config_${DT}.log"
        echo "$(date) : --------------------------------------------------------"
        echo
    fi
}

certinstall () {
    double_check_packages
    if [ -f /usr/bin/openssl ]; then
        echo "$(date) : generating new certificate, this might take a while..."
        openssl req -new -x509 -newkey rsa:2048 -sha256 -nodes -keyout /home/simgos/certs/server.key -days 3650 -out /home/simgos/certs/server.crt -config /home/simgos/certs/config.cnf

        echo -e "$(date) : ${BOLDGREEN}setting up your new cert file & key...${ENDCOLOR}"
        sed -i "s/^SSLCertificateFile \/etc\/pki\/tls\/certs\/\(.*\).crt$/SSLCertificateFile \/home\/simgos\/certs\/server.crt/g" /etc/httpd/conf.d/ssl.conf
        sed -i "s/^SSLCertificateKeyFile \/etc\/pki\/tls\/private\/\(.*\).key$/SSLCertificateKeyFile \/home\/simgos\/certs\/server.key/g" /etc/httpd/conf.d/ssl.conf
        echo -e "$(date) : ${BOLDGREEN}success! restarting your services...${ENDCOLOR}"
        chown -R simgos:simgos /home/simgos/
        firewall-cmd --permanent --add-service=https
        echo
        echo "systemctl daemon-reload; service httpd restart; systemctl restart php-fpm; echo \"Restarting apache & php-fpm (via systemctl) [  OK  ]\"" >/usr/bin/hprestart ; chmod 700 /usr/bin/hprestart
        echo "$(date) : systemctl daemon-reload"
        systemctl daemon-reload
        echo
        echo "$(date) : firewall-cmd --reload"
        firewall-cmd --reload
        echo
        echo "$(date) : systemctl restart httpd"
        systemctl restart httpd
        sleep 5
        echo
        echo "$(date) : systemctl restart php-fpm"
        systemctl restart php-fpm
        sleep 5
        echo
        systemctl status httpd | grep 'active (running)' > /dev/null 2>&1
        if [ $? != 0 ]
            then
                echo -e "$(date) : ${BOLDRED}APACHE is NOT running. Pls restart it manually...${ENDCOLOR}"
            else
                echo -e "$(date) : ${BOLDGREEN}Successfully restarting services...${ENDCOLOR}"
                echo
                echo "$(date) : --------------------------------------------------------"
                echo "$(date) : Thankyou for using SIMGOS V2+ SSL Installer!"
                echo "$(date) : --------------------------------------------------------"
                echo "$(date) : Install Summary Logs: ${INSTALLDIR}/ssl_install_${DT}.log"
                echo "$(date) : --------------------------------------------------------"
                echo
        fi
    fi
}

info () {
    echo -e "$(date) : ${BOLDRED}Generate Self Sign Certificate for SSL SIMGOS V2+${ENDCOLOR}"
    echo -e "$(date) : ${BOLDRED}# Step 1${ENDCOLOR}"
    echo -e "$(date) : # Edit config variables"
    echo -e "$(date) : ${BOLDGREEN}open this script using nano and change field value at the top of this script${ENDCOLOR}"
    echo -e "$(date) : ${BOLDRED}# Step 2${ENDCOLOR}"
    echo -e "$(date) : # Install required packages and set config file"
    echo -e "$(date) : ${BOLDGREEN}bash sslcert.sh config${ENDCOLOR}"
    echo -e "$(date) : ${BOLDRED}# Step 3${ENDCOLOR}"
    echo -e "$(date) : # Generate certificate"
    echo -e "$(date) : ${BOLDGREEN}bash sslcert.sh install${ENDCOLOR}"
    exit 1
}

case "$1" in
    install)
        {
            banner
            certinstall
        } 2>&1 | tee "${INSTALLDIR}/ssl_install_${DT}.log"
        ;;
    config)
        {
            banner
            certconfig
        } 2>&1 | tee "${INSTALLDIR}/ssl_config_${DT}.log"
        ;;
    *)
    if [[ "$DEF" = 'novalue' ]]; then
        info
    else
        echo "$(date) : Please enter a command [config|install]."
        echo -e "$(date) : ${BOLDRED}eg: bash sslcert.sh status${ENDCOLOR}"
        exit 1
    fi
    ;;
esac
