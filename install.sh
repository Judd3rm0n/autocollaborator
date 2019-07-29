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
mkdir -p /usr/local/collaborator/keys
printf "\n \n Checking...... "
# IF file
if [ -d "/usr/local/collaborator" ]
then
	echo "/usr/local/collaborator found...................."
else
	echo "Error - directory could not be made. Exiting."
	exit
fi
if [ -d "/usr/local/collaborator/keys" ]
then
	echo "/usr/local/collaborator/keys found...................."
else
	echo "Error - directory keys could not be made. Exiting."
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
wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
echo "Starting certbot....... \n"
else
echo "Certbot found! \n Skipping certbot install.."
fi
echo "Installing certs.............................."
sleep 2
./certbot-auto certonly -d $domainv -d *.$domainv  --server https://acme-v02.api.letsencrypt.org/directory --manual --agree-tos --register-unsafely-without-email --manual-public-ip-logging-ok --preferred-challenges dns-01
echo "Installing Certs..... " && sleep 1
cp /etc/letsencrypt/live/$domainv/privkey.pem /usr/local/collaborator/keys/
cp /etc/letsencrypt/live/$domainv/fullchain.pem /usr/local/collaborator/keys/
cp /etc/letsencrypt/live/$domainv/cert.pem /usr/local/collaborator/keys/
}

# Ask if SSL is needed 
aut(){
read -r -p "${1:-Do you need a SSL cert? [y/N]} " response
    case "$response" in
        [yY]*) 
            true
			echo "ok"
			echo "Running Certbot."
			certin
            ;;
        [nN]*)
            false
			echo "Skipping...."
			sleep 1
			echo "You will need to place your SSL files in the /usr/local/collaborator/keys/ folder and update the config file."
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
			echo "Sorry I can't install without iptables-persistent, exiting..."
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
  "serverDomain" : "$domainv",
  "workerThreads" : 10,
  "eventCapture": {
      "localAddress" : [ "$ipaddressv" ],
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
          "certificateFiles" : [
              "/usr/local/collaborator/keys/privkey.pem",
              "/usr/local/collaborator/keys/cert.pem",
              "/usr/local/collaborator/keys/fullchain.pem" ]
      }
  },
  "polling" : {
      "localAddress" :  "$ipaddressv",
      "publicAddress" :  "$ipaddressv",
      "http": {
          "port" : 39090
      },
      "https": {
          "port" : 39443
      },
      "ssl": {
          "certificateFiles" : [
              "/usr/local/collaborator/keys/privkey.pem",
              "/usr/local/collaborator/keys/cert.pem",
              "/usr/local/collaborator/keys/fullchain.pem" ]

      }
  },
  "metrics": {
      "path" : "jnaicmez8",
      "addressWhitelist" : ["0.0.0.0/1"]
  },
  "dns": {
      "interfaces" : [{
          "name":"ns1.$domainv", 
          "localAddress":"$ipaddressv",
          "publicAddress":"$ipaddressv",
      }],
      "ports" : 3353
   },
   "logLevel" : "INFO"
}
EOF
echo "Creating terminal files........... " && sleep 2
cat <<EOF >/usr/local/bin/autocollaborator

#!/bin/bash
valid=0
if [[ $@ = "--flush-config" || $@ = "-fc" ]]
then
valid=1
# Ask questions
echo "Changing Config................. " && sleep 2
echo "Please enter the server IP address - " && read ipaddressv
echo "Please enter the server domain name, including any subdomain you are using. - " && read domainv
echo "Recreating Config File......" && sleep 5
cat <<EOF >/usr/local/collaborator/collaborator.config 

  {
  "serverDomain" : "$domainv",
  "workerThreads" : 10,
  "eventCapture": {
      "localAddress" : [ "$ipaddressv" ],
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
          "certificateFiles" : [
              "/usr/local/collaborator/keys/privkey.pem",
              "/usr/local/collaborator/keys/cert.pem",
              "/usr/local/collaborator/keys/fullchain.pem" ]
      }
  },
  "polling" : {
      "localAddress" :  "$ipaddressv",
      "publicAddress" :  "$ipaddressv",
      "http": {
          "port" : 39090
      },
      "https": {
          "port" : 39443
      },
      "ssl": {
          "certificateFiles" : [
              "/usr/local/collaborator/keys/privkey.pem",
              "/usr/local/collaborator/keys/cert.pem",
              "/usr/local/collaborator/keys/fullchain.pem" ]

      }
  },
  "metrics": {
      "path" : "jnaicmez8",
      "addressWhitelist" : ["0.0.0.0/1"]
  },
  "dns": {
      "interfaces" : [{
          "name":"ns1.$domainv", 
          "localAddress":"$ipaddressv",
          "publicAddress":"$ipaddressv",
      }],
      "ports" : 3353
   },
   "logLevel" : "INFO"
}
\EOF
fi



if [[ $@ = "--force-start" || $@ = "-fs" ]]
then
valid=1
echo "Forcing start with no health checks........."
sleep 1
cd /usr/local/collaborator
sudo java -jar burpsuite_pro.jar --collaborator-server --collaborator-config=collaborator.config
fi

#Reset IP tables if needed
ipt(){
echo "Confirming iptables................"
iptables -t nat -A PREROUTING -i ens3 -p udp --dport 53 -j REDIRECT --to-port 3353
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 9090 -j REDIRECT --to-port 39090
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 25 -j REDIRECT --to-port 3325
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 80 -j REDIRECT --to-port 3380
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 587 -j REDIRECT --to-port 33587
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 465 -j REDIRECT --to-port 33465
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 9443 -j REDIRECT --to-port 39443
iptables -t nat -A PREROUTING -i ens3 -p tcp --dport 443 -j REDIRECT --to-port 33443
iptables-save >/dev/null
echo "Done................ " && sleep 3
}
if [[ $1 == "" ]]
then
valid="1"
end(){
echo "Safely shutting down collaborator server......."
sleep 2
	echo "Closing Port 3325"
	fuser -k 3325/tcp
	echo "Closing Port 3380"
	fuser -k 3380/tcp
	echo "Closing Port 39090"
	fuser -k 39090/tcp
	echo "Closing Port 33587"
	fuser -k 33587/tcp
	echo "Closing Port 3353"
	fuser -k 3353/tcp
	echo "Closing Port 33465"
	fuser -k 33465/tcp
	echo "Closing Port 39443"
	fuser -k 39443/tcp
	echo "Closing Port 33443"
	fuser -k 33443/tcp
}
trap end EXIT
# Check ports and files and reset iptables if needed
echo "Running pre-flight checks.... "
pc(){
if lsof -Pi :3325 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 3325 is in LISTEN...."
	echo "Killing 3325"
	fuser -k 3325/tcp
else
    echo "Port 3325 Ready........."
fi

if lsof -Pi :3380 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 3380 is in LISTEN...."
	echo "Killing 3380"
	fuser -k 3380/udp
else
    echo "Port 3380 Ready........."
fi

if lsof -Pi :39090 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 39090 is in LISTEN...."
	echo "Killing 39090"
	fuser -k 39090/tcp
else
    echo "Port 39090 Ready........."
fi

if lsof -Pi :33587 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 33587 is in LISTEN...."
	echo "Killing 33587"
	fuser -k 33587/tcp
else
    echo "Port 33587 Ready........."
fi

if lsof -Pi :3353 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 3353 is in LISTEN...."
	echo "Killing 3353"
	fuser -k 3353/tcp
else
    echo "Port 3353 Ready........."
fi

if lsof -Pi :33465 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 33465 is in LISTEN...."
	echo "Killing 33465"
	fuser -k 33465/tcp
else
    echo "Port 33465 Ready........."
fi

if lsof -Pi :39443 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 39443 is in LISTEN...."
	echo "Killing 39443"
	fuser -k 39443/tcp
else
    echo "Port 39443 Ready........."
fi

if lsof -Pi :33443 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 33443 is in LISTEN...."
	echo "Killing 33443"
	fuser -k 33443/tcp
else
    echo "Port 33443 Ready........."
fi

# 2nd wave
if lsof -Pi :25 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 3325 is in LISTEN...."
	echo "Killing 3325"
	fuser -k 25/tcp
else
    echo "Port 3325 Ready........."
fi

if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 3380 is in LISTEN...."
	echo "Killing 3380"
	fuser -k 80/udp
else
    echo "Port 80 Ready........."
fi

if lsof -Pi :9090 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 39090 is in LISTEN...."
	echo "Killing 39090"
	fuser -k 9090/tcp
else
    echo "Port 9090 Ready........."
fi

if lsof -Pi :587 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 33587 is in LISTEN...."
	echo "Killing 33587"
	fuser -k 587/tcp
else
    echo "Port 587 Ready........."
fi

if lsof -Pi :53 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 3353 is in LISTEN...."
	echo "Killing 3353"
	fuser -k 53/tcp
else
    echo "Port 53 Ready........."
fi

if lsof -Pi :465 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 33465 is in LISTEN...."
	echo "Killing 33465"
	fuser -k 465/tcp
else
    echo "Port 465 Ready........."
fi


if lsof -Pi :443 -sTCP:LISTEN -t >/dev/null ; then
    echo "Port 33443 is in LISTEN...."
	echo "Killing 33443"
	fuser -k 443/tcp
else
    echo "Port 443 Ready........."
fi
sleep 2
}
#check for files
fb(){
echo "Checking files.........." && sleep 2
echo "Checking for burpsuite_pro.jar........"
cd /usr/local/collaborator
if [ -e burpsuite_pro.jar ]
then
	echo "Complete............."
else
	echo "ERROR!...................... Could not find burpsuite_pro.jar exiting!"
	exit
fi
echo "Checking for config file.............."
cd /usr/local/collaborator
if [ -e collaborator.config ]
then
	echo "Complete............."
else
	echo "ERROR!...................... Could not find config file exiting!"
	exit
fi
}
fb
pc
ipt
cd /usr/local/collaborator

echo "Using screen to start burp collaborator server- on shut down/ctrl-c this script will close ports safely" & sleep 3
me="$(whoami)"
screen sudo -H -u $me bash -c "java -jar burpsuite_pro.jar --collaborator-server --collaborator-config=collaborator.config">/dev/null
fi

#help
if [[ $@ = "--help" || $@ = "-h" ]]
then
valid=1
echo "Welcome to autocollaborator 

Usage:
	
	autocollaborator --help [-h]
	
Simple start: 
	
	autocollaborator
	
Change config:
	
	autocollaborator --flush-config [-fc]

Forced start:

	autocollaborator --force-start [-fs]



To safe shutdown during use simply use ctrl c" 
fi


if [[ $valid = "0" ]] 
then
echo "Argument not valid, try autocollaborator -h or --help"
fi



EOF
chmod /usr/bin/autocollaborator

echo "Removing any prerouting on target ports........" && sleep 2
iptables -t nat -D PREROUTING -i ens3 -p udp --dport 53 -j REDIRECT --to-port 3353
iptables -t nat -D PREROUTING -i ens3 -p tcp --dport 9090 -j REDIRECT --to-port 39090
iptables -t nat -D PREROUTING -i ens3 -p tcp --dport 25 -j REDIRECT --to-port 3325
iptables -t nat -D PREROUTING -i ens3 -p tcp --dport 80 -j REDIRECT --to-port 3380
iptables -t nat -D PREROUTING -i ens3 -p tcp --dport 587 -j REDIRECT --to-port 33587
iptables -t nat -D PREROUTING -i ens3 -p tcp --dport 465 -j REDIRECT --to-port 33465
iptables -t nat -D PREROUTING -i ens3 -p tcp --dport 9443 -j REDIRECT --to-port 39443
iptables -t nat -D PREROUTING -i ens3 -p tcp --dport 443 -j REDIRECT --to-port 33443
iptables-save

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

echo "Complete....." && sleep 1
}



## Copy files to collaborator
echo "\n Copying files"

cp burpsuite_pro.jar /usr/local/collaborator



# Standard Method
mm(){

configw
echo "Complete..... " && sleep 3
echo "To start the collaborator server - use: autocollaborator"

}

#Begin

mm

