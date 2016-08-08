#! /bin/bash

## ll4d: LXD LAMP FOR DEVELOPMENT
## ll4d is a script for building a quick and safe LAMP development environment using LXD.
## It is built and tested on Ubuntu 15.10.
## It works as follows:
##  - If not already installed, install and configure the LXD/LXC environment
##  - Create a container and execute a short script that installs the LAMP server
##  - Make a symbolic link from the apache root directory of the LAMP server (container)
##     to the $LAMP_DIR, or directory where you want to work on your desktop
##    * It prompts for root password, to give write permissions on that root directory.
##  - Generate a web page to verify that the apache, PHP and MySQL work properly
##
## It takes no arguments, except for "ll4d.sh --clean", which cleans everything the 
## script did: delete container and symbolic link.
##
## Author: Julen Larrucea

CONTAINER_NAME="dev-lamp-server"
LAMP_DIR=~/my_lxd_lamp
MYSQL_PASSWORD="MyPassword"

echo -e "\033[0;32m ll4d: LXD LAMP FOR DEVELOPMENT  \033[0m"
echo    " The quick script to build a LAMP test environment."

if [ "$1" == "--clean" ]; then
    lxc delete $CONTAINER_NAME &> /dev/null
    rm $LAMP_DIR &> /dev/null
    echo -e "Contaner \033[0;37m$CONTAINER_NAME\033[0m and symbolic link \033[0;37m$LAMP_DIR\033[0m deleted"
    exit 0
fi 

if ! which lxd > /dev/null ; then
    echo "LXC/LXD was not found, installing..."
    sudo -n ls &>/dev/null || \
    printf '\033[0;37m>> Root password is required for installing lxd.\n\033[0m' && \
    echo "this will execute:" && echo "sudo add-apt-repository -y ppa:ubuntu-lxc/lxd-git-master" && echo "sudo apt-get -y update" && echo "sudo apt-get -y install lxd"
    sudo add-apt-repository -y ppa:ubuntu-lxc/lxd-git-master
    sudo apt-get -y update

    sudo apt-get -y install lxd 
    newgrp lxd
    lxd init
fi

if ! lxc image list |grep ubuntu-trusty > /dev/null ; then
    echo "Importing the ubuntu trusty image"
    lxd-images import ubuntu trusty amd64 --sync --alias ubuntu-trusty
fi

function create_lamp_container () {

    echo "Launching container with name $CONTAINER_NAME"
    lxc launch ubuntu-trusty $CONTAINER_NAME

    echo "Waiting until the container responds to ping."
    
    while true; do 
        IP=$(lxc list |grep $CONTAINER_NAME |awk '{print $6}')
        if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            if ping -c1 -q $IP > /dev/null ; then
               break
            fi
        fi

        sleep 1
    done

    cat > /tmp/lamp_install.sh <<EOF
#/bin/bash
sudo apt-get update
echo "mysql-server-5.5 mysql-server/root_password password $MYSQL_PASSWORD" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $MYSQL_PASSWORD" | debconf-set-selections
sudo apt-get install -q -y --force-yes lamp-server^
EOF

    lxc file push /tmp/lamp_install.sh $CONTAINER_NAME/tmp/

    lxc exec $CONTAINER_NAME chmod 777 /tmp/lamp_install.sh

    lxc exec $CONTAINER_NAME /tmp/lamp_install.sh
}

create_lamp_container


function link2html_dir {

    echo "Making a link from the apache root from the LAMP server, to the $LAMP_DIR"  
    [ -h $LAMP_DIR ] && rm $LAMP_DIR

    ln -s /var/lib/lxd/containers/$CONTAINER_NAME/rootfs/var/www/html $LAMP_DIR

    sudo -n ls &>/dev/null || \
    printf '\033[0;37m>> Root password is required for allowing write to the apache root directory.\n\033[0m' && \
    echo "We are going to run this command:" && \
    echo "sudo chmod -R 777 /var/lib/lxd/containers/$CONTAINER_NAME/rootfs/var/www/html/"

    sudo chmod -R 777 /var/lib/lxd/containers/$CONTAINER_NAME/rootfs/var/www/html/

}

link2html_dir


function test_page () {
    echo "Generating a test page."
    IP=$(lxc list |grep $CONTAINER_NAME |awk '{print $6}')
    rm $LAMP_DIR/index.html

    cat > $LAMP_DIR/index.php << EOF
<html>
 <head>
  <title>LAMP Test</title>
 </head>
 <body>
 <?php echo '<p>Hello! if you can read this, php is working :)</p>'; ?>

 <?php
\$servername = "localhost";
\$username = "root";
\$password = "$MYSQL_PASSWORD";

\$conn = new mysqli(\$servername, \$username, \$password);

if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}
echo "<p>Great! MySQL is also working :)</p>";
?>
 </br>
 This website is on the IP: $IP
 </body>
</html>
EOF
    echo "Done. You can visit your development site at:"
    echo -e "\033[0;37m  http://$IP \033[0m"
    echo "... and edit the code in $LAMP_DIR"
    echo "To edit settings and manipulate the MySQL databases, access the server by:"
    echo -e "\033[0;37m lxc exec $CONTAINER_NAME /bin/bash\033[0m"
    echo "The MySQL root password is: $MYSQL_PASSWORD"

}

test_page

