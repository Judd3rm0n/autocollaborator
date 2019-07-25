#!/bin/sh

#Burp Collaborator auto installer.  You will need root and a legal copy of burp suite pro -not included-.

#Check if root
if [ $(id -u) != "0" ]
then
echo "Error - Please run: sudo sh auto-collaborator.sh"
exit 1
fi

# Ask questions
echo "Please enter the server IP address - " && read ipaddressv
echo "Please enter the server domain name, including any subdomain you are using. - " && read domainv


# Look for burp pro file
echo "Looking for burp jar"
sleep 1
if [ -e burpsuite_pro.jar ]
then
	echo "Burp suite pro Jar Found"
	Setupf=1
else
	echo "Burp suite pro Jar NOT FOUND! You will need a legal copy of Burp Suite Pro -not included- \n Cannot continue"
	exit
fi

## Make directory for collaborator
printf "\n Creating collaborator directory....." && sleep 1
mkdir -p /usr/local/collaborator
mkdir -p /usr/local/collaborator/certs
printf "\n \n Checking...... "
# IF file
if [ -d "/usr/local/collaborator" ]
then
	echo "/usr/local/collaborator found...................."
else
	echo "Error - directory could not be made. Exiting."
	exit
fi
if [ -d "/usr/local/collaborator/certs" ]
then
	echo "/usr/local/collaborator/certs found...................."
else
	echo "Error - directory certs could not be made. Exiting."
	exit
fi

# run update if needed
upd(){
if [ "$upr" -ge "1" ]
			then 
				apt-get update
			fi
			upr=$((upr-50))
			}


# Certbot install and ssl
upr="0"
certin(){
echo "Checking if certbot install is required"
sleep 1
if  [ ! -f /usr/local/collaborator/certbot-auto   ]
then
upd
echo "Installing certbot"
cd /usr/local/collaborator/
wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
echo "Starting certbot....... \n"
else
echo "Certbot found! \n Skipping certbot install.."
fi
echo "Installing certs.............................."
sleep 2
./certbot-auto certonly -d $domainv -d *.$domainv  --server https://acme-v02.api.letsencrypt.org/directory --manual --agree-tos --register-unsafely-without-email --manual-public-ip-logging-ok --preferred-challenges dns-01
letspath="/etc/letsencrypt/live/$domainv"
echo "Installing Certs..... " && sleep 1
cp $letspath/* usr/local/collaborator/certs

}

# Ask if SSL is needed 
aut(){
read -r -p "${1:-Do you need a SSL cert? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
			echo "ok"
			echo "Running Certbot."
			certin
            ;;
        *)
            false
			echo "Skipping...."
			sleep 1
			echo "You will need to place your SSL files in the /usr/local/collaborator/certs folder and update the config file."
            ;;
    esac
}
aut && sleep 2
#Check if Java and iptables are around
echo "Checking for required packages.  If not install them" && sleep 3


# Install for iptables
ipt(){
read -r -p "${1:-Do you wish to install iptables? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
			echo "Ok, installing..."
			upr=$((upr+1))
			upd
			sudo apt-get install iptables-persistent
            ;;
        *)
            false
			echo "Sorry this script won't work without iptables, exiting..."
			exit
            ;;
    esac
}

## Install for JRE
jrei(){
read -r -p "${1:-Do you wish to install default-jre? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
			echo "Ok, installing..."
			upr=$((upr+1))
			upd
			apt-get install default-jre
            ;;
        *)
            false
			echo "Sorry this script won't work without default-jre, exiting..."
			exit
            ;;
    esac
}
## Final check

pak(){
if ! [ -x "$(command -v java)" ]
then
echo "Default JRE not installed"
jrei
else
echo "JRE Found"
fi
if ! [ -x "$(command -v iptables)" ]
then
echo "iptables not installed"
ipt
else
echo "iptables Found"
fi
}
pak

#write config file and create iptables
configw(){
echo "Creating config file please wait......" && sleep 5
cat <<EOF >/usr/local/collaborator/collaborator.config
{ 

  "serverdomain" : "$domainv", 

  "workerThreads" : 10, 

  "eventCapture": { 

    "localAddress" : ["$ipaddressv", "127.0.0.1"], 

    "publicAddress" : "$ipaddressv", 

    "http": { 

      "ports" : 3380 

    }, 

    "https": { 

      "ports" : 33443 

    }, 

    "smtp": { 

      "ports" : [3325, 33587] 

    }, 

    "smtps": { 

      "ports" : 33465 

    }, 

    "ssl": { 

      "certs/certificateFiles" : [ 

        "certs/certificate.crt", 

        "certs/ca_bundle.crt", 

        "certs/private.key" ] 

    } 

  }, 

  "polling" : { 

    "localAddress" : "127.0.0.1", 

    "publicAddress" : "$ipaddressv", 

    "http": { 

      "port" : 39090 

    }, 

    "https": { 

      "port" : 39443 

    }, 

    "ssl": { 

      "hostname" : "$domainv" 

    } 

  }, 

  "metrics": { 

    "path" : "jnaicmez8", 

    "addressWhitelist" : ["$ipaddressv/24"] 

  }, 

  "dns": { 

    "interfaces" : [{ 

      "name": "ns1.$domainv", 

      "localAddress" : "$ipaddressv", 

      "publicAddress" : "$ipaddressv" 

    }, { 

      "name" : "ns2.$domainv", 

      "localAddress" : "$ipaddressv", 

      "publicAddress" : "$ipaddressv" 

    }], 

    "ports" : 3353 

  }, 

  "logLevel" : "INFO" 

}
EOF

echo "Setting up iptables..... " && sleep 2

iptables -t nat -A PREROUTING -i ens3 -p udp --dport 53 -j REDIRECT --to-port 3353
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 9090 -j REDIRECT --to-port 39090
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 25 -j REDIRECT --to-port 3325
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 80 -j REDIRECT --to-port 3380
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 587 -j REDIRECT --to-port 33587
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 465 -j REDIRECT --to-port 33465
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 9443 -j REDIRECT --to-port 39443
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 443 -j REDIRECT --to-port 33443
iptables-save

echo "complete....." && sleep 1
}



## Copy files to collaborator
echo "\n Copying files"

cp burpsuite_pro.jar /usr/local/collaborator

# Service Method

sm(){

sudo adduser --shell /bin/nologin --no-create-home --system collaborator
sudo chown collaborator /usr/local/collaborator
configw
echo "Setting up service... "
cat <<EOF >/etc/systemd/system/collaborator.service
[Unit]
Description=Burp Collaborator Server Daemon
After=network.target

[Service]
Type=simple
User=collaborator
UMask=007
ExecStart=/usr/bin/java -Xms10m -Xmx200m -XX:GCTimeRatio=19 -jar /usr/local/collaborator/burpsuite_pro.jar --collaborator-server --collaborator-config=/usr/local/collaborator/collaborator.config
Restart=on-failure

# Configures the time to wait before service is stopped forcefully.
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOF

echo "Complete......" && sleep 3
echo "Enabling as a service"
systemctl enable collaborator
echo "\n Process complete..... \n To start burp collaborator server use: systemctl start collaborator"


}

# Standard Method
mm(){

configw
echo "Complete..... " && sleep 3
echo "Manual setup completed.... \n"
echo "To start burp run ./usr/local/collaborator/burpsuite_pro.jar --collaborator-server --collaborator-config=/usr/local/collaborator/collaborator.config"

}

#Service user?

serviceRequest(){
read -r -p "${1:-Do you want to create burp collaborator as a service? - This will create a burp service and user [y/N]} " service
    case "$service" in
        [yY][eE][sS]|[yY]) 
            true
			echo "Creating as service...."
			sm
            ;;
        *)
            false
			echo "Creating as manual launch...."
			mm
            ;;
    esac
}
serviceRequest

