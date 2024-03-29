# autocollaborator
Automatically helps build a collaborator server.  **You will require a legal copy of burp suite pro in order to run this script.
It is not provided in this script, it is purely for easy configuration of a burp collaborator server.** This setup runs on non-standard ports and is ideally for a dedicated collaborator server (ie only collaborator will be running on it, some minor config changes may cause other things to break).  

# Requirements
A VPS, a domain with access to add NS and A records to and a working copy of the Burpsuite_pro.jar, the community version will not work and is not provided. 

# Setup Instructions
1. Git clone this repo.
2. Place your copy of burpsuite_pro.jar file in the repo file. 
3. Prepare for domain name txt input (have the window open on your domain manager at least)
4. Run sudo sh setup.sh
5. Follow prompts and enter information when requested. (inc LetsEncrypt/certbot txt challenge!)
5. Setup DNS and A record to point to your VPS server. 
6. Run $~ autocollaborator in your terminal.
7. Test using burpsuite pro that your collaborator server is working. (see here: https://portswigger.net/burp/documentation/collaborator/deploying#testing-the-installation)

# Info
### SSL Setup (Let's Encrypt) 
Automatically sets up SSL certs by installing and configuring your certs! 

### Auto Config file
The script will create the right config file to use!

### Safe Start and Shutdown
Ensure that ports are open and closed to avoid any binding errors.  Allowing for a quicker restart without rebooting the server or running fuser -k.


# Things to Note

You may still need to edit the config file depending on your environment. This was tested using a vultr VPS (ubuntu 19.4 x64) with no problems.  


# Possible Future work

### Add port choice
Allow you to choose the ports on setup.

### Config error checker
Something to help debug little errors preventing your collaborator server from starting or running correctly. 

### Auto change config file
The ability to change options and settings in the config file without the use of nano or other editors.  Basically straight from the command line eg: autocollaborator --set-ip 123.456.789.101 --set-dns-port 53. 

### Option to run collaborator as a service in the background
^^^ You get the gist. 

