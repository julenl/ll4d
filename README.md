# ll4d
LXD LAMP For Development.
A simple script that automatically sets up a LAMP development environment under LXD in Ubuntu.

This script is quite simple, and does not really have much to explain.
It sets up a LXC/LXD container environment, created a LAMP server on a new instance and 
creates a symbolic link from the apache root directory in the container to wherever you want.
This allows you to confortably work on the code from your desktop with your graphic editors 
and visualize the result on real time on the server.

There are only two ways to run the script:
- Without arguments: builds the test environment
- As "ll4d.sh --clean": which deletes the container and the sylink

Everything is default, but you can edit the following variables:
- 'CONTAINER_NAME': name of the container to be created
- 'LAMP_DIR': address to the link that will point to the apache root folder
- 'MYSQL_PASSWORD': the password for the user 'root' in apache
