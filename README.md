# autocollaborator
Automatically helps build a collaborator server.  **You will require a legal copy of burp suite pro in order to run this script.
It is not provided in this script, it is purly for easy configuration of a burp collaborator server.** 

# Requirements
A VPS a domain with access to add NS record and a working copy of the Burpsuite_pro.jar, the community version will not work and is not provided. 

# Setup Instructions
1. Git clone this repo.
2. Run sudo sh setup.sh
3. Follow prompts and enter information when requested. 
4. Setup DNS and A record to point to your VPS server. 
5. Run $~ autocollaborator in your terminal.
6. Test using burpsuite pro that your collaborator server is working. 

# Info
### SSL Setup (Let's Encrypt) 
Automatically sets up SSL certs by installing and configuring your certs! 

### Auto Config file
The script will create the right config file to use!

### Safe Start and Shutdown
Ensure that ports are open and closed to avoid any binding errors.  Allowing for a quicker restart without rebooting the server or running fuser -k.

# Future work

### Add port choice
We will add the choice to add ports so you can select what goes where. 

### Auto change config file
The ability to change options and settings in the config file without the use of nano or other editors.  Basically straight from the command line eg: autocollaborator --set-ip 123.456.789.101 --set-dns-port 53. 

### Option to run collaborator as a service in the background
^^^ You get the gist. 

