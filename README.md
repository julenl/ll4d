# ll4d
LXD LAMP For Development.
A simple script that automatically sets up a LAMP development environment under LXD in Ubuntu.

This script is quite simple, and does not really have much to explain.
It sets up a LXC/LXD container environment, created a LAMP server on a new instance and 
creates a symbolic link from the apache root directory in the container to wherever you want.
This allows you to confortably work on the code from your desktop with your graphic editors 
and visualize the result on real time on the server.
