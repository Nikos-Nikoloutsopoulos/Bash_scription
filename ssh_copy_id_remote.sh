#!/bin/bash
# This script reads hosts and users from a file with name remotehosts.txt
# Afterwords generate key pairs localy
# Copies the bublic key into remote servers
# Connected on the remote servers and execute commads there

# Exit on error
set -e

sshpass -V &> /dev/null
if [ $? -ne 0 ]
then
   echo "sshpass is not installed. Installing sshpass..."
    apt --help &> /dev/null
    if [ $? -eq 0 ]
    then
      echo "#################################"
      echo "Installing sshpass on Ubuntu"
      echo "#################################"
      apt update -y &> /dev/null
      apt install -y sshpass &> /dev/null
    else
      echo "#################################"
      echo "Installing sshpass on CentOS"
      echo "#################################"
      yum update -y &> /dev/null
      yum install -y sshpass &> /dev/null
    fi  
else
    echo "sshpass is already installed."
fi

export SSHPASS='password'

# Config
KEY_NAME="key_name"
KEY_DIR="$HOME/.ssh"
KEY_PATH="$KEY_DIR/$KEY_NAME"


# Create .ssh directory if it doesn't exist
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

# Check if key already exists
if [ ! -f "$KEY_PATH" ]
then
  echo "#################################"
  echo "Key does not exist: $KEY_PATH"
  echo "#################################"
  # Generate key pair
  ssh-keygen \
    -f "$KEY_PATH" \
    -N ""

  Set correct permissions
  chmod 600 "$KEY_PATH"
  chmod 644 "$KEY_PATH.pub"


  echo "Private key: $KEY_PATH"
  echo "Public key:  $KEY_PATH.pub"
else
  echo "#################################"
  echo "Key already exist"	
  echo "#################################"
fi

cat remotehosts.txt | while IFS=":" read -r host USER; 
do
      echo "#################################"
      echo "Copy public on the remote server $host"
      echo "#################################"
      sshpass -e ssh-copy-id -i $KEY_PATH.pub -o StrictHostKeyChecking=no $USER@$host
      if [ $? -eq 0 ]
      then
        echo "#################################"
        echo "Key file  transfered in the $host server"
        echo "#################################"
      
      else
        echo "key fie transfer failed"
      fi	    
      echo "#################################"
      echo "Connect on the remote server $host"
      echo "#################################"
      ssh -i $KEY_PATH $USER@$host <<EOF
        REMOTE_SERVER_NAME=\$(hostname)
        echo "I am running on \$REMOTE_SERVER_NAME"
        ls -la .ssh/
        cat /etc/os-release
        sleep 1
        exit
EOF
  
done      


