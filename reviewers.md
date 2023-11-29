# Information needed for reviewers

# Importing the .ova
When you import the .ova files in virtualbox, make sure to select the option to import ALL the network interfaces (not selected by default).

# sysadmin
On the user-gui machine, there is a user called sysadmin.
The local password is: `tulip-evident-theft`
This user can ssh into the firewall/router, the ca-server, the backup-server and the mysql-server.
To ssh use the following commands (from the sysadmin user):
```
ssh firewall
ssh webserver
ssh ca-server
ssh backup-server
ssh mysql-server
```
The password to decrypt the ssh key for sysadmin is `flail-dandelion-concierge`.

Sysadmin password on the machines (with sudo rights):
- firewall: `FQTE:-4R)+KJ5&#MxzN~k@`
- ca-server: `FQTE:-4R)+KJ5&#MxzN~k@`
- mysql-server: `dv8RCJruycKGyN`
- backup-server: `RbNoH9BGxO1FcyTXc1`
- webserver: `FUwzhJEGWHOVUm8f`

# employee
On the user-gui machine, log into the vagrant user with password `vagrant`.
To connect to the web interface, open Firefox and go to https://1.2.3.4 . There, you can enter the credentials which are displayed in the assignment pdf. Afterwards you can do certificate authentication by installing the pkcs12 and logging in from the login page and selecting the certificate authentication option.

The rest of the interface is self-explanatory.

# ca-admin
On the user-gui machine, log into the vagrant user with password `vagrant`.
To connect to the web interface, open Firefox and go to https://1.2.3.4 . When Firefox asks for a certificate, make sure to select the certificate for the ca-admin. 

The certificate for the ca-admin is at /home/vagrant/Documents/ca-admin.p12
The password to import the certificate is `Er+vcqM9Q&;=.f4*:2eY8G`.