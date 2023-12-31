# Information needed for reviewers

# Importing the .ova
When you import the .ova files in virtualbox, make sure to select the option to import ALL the network interfaces (not selected by default).

# Launching the VMs
When launching the VMs, it's important to wait until one machine is fully booted before booting the next one.
Don't launch all the machines at once, IT WON'T WORK. (There seems to be some non-determinism on the virtualbox side with the managing of virtual network interfaces).

- First, boot the user-gui machine. Verify that you can login to the vagrant user using the password `vagrant` (difficult to login directly to sysadmin due to keyboard config). If the screen remains black very long, it's a graphical issue, try resizing the virtual screen to force refreshes.
- Then, boot the firewall machine. Try to ping 1.2.3.4. If it does not work, there was a network config issue, so reboot the firewall machine.
- Then boot the webserver machine. Try to open firefox to https://1.2.3.4 . You should see the web interface login page. If not reboot webserver.
- Then boot the mysql-server machine. Try to login on https://1.2.3.4 with user id `a3` and password `Astrid`. You should land on the home page. If not, reboot the mysql-server machine.
- Then boot the ca-server machine. Try to download the CRL from the web interface home page. This should download a file called `revoked_list.crl`. If not, reboot the ca-server machine.
- Finally, boot the backup-server machine. Try requesting a new certificate from the home page. This should download a file called `certificate.p12`. If not, reboot the backup-server machine.

# sysadmin
On the user-gui machine, there is a user called sysadmin.
The local password is: `tulip-evident-theft`

To enable ssh connection, please use the following commands (didn't manage to automate, sorry):
```
sudo ip link set eth0 down
```

This user can ssh into the firewall/router, the webserver, the ca-server, the backup-server and the mysql-server.
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
- firewall: `pyACm3GbmBV4d1UY`
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
(by default the certificate should already be imported)

# Source codes for whitebox review
- ca-server backend: on machine ca-server, in /var/www/ca-server/src
- webserver server code: on machine webserver, in /var/www/webserver/app
- backups and centralized logs are stored in /backup on the backup-server