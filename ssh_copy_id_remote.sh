#!/bin/bash
echo "#################################"
echo "Author Nikos Nikoloutsopoulos"
echo "#################################"
# Exit on error
# set -e

sshpass -V &> /dev/null
if [ $? -ne 0 ]
then
   echo "sshpass is not installed. Installing sshpass..."
    apt --help # &> /dev/null
    if [ $? -eq 0 ]
    then
      echo "#################################"
      echo "Installing sshpass on Ubuntu"
      echo "#################################"
      echo "password" | sudo -S apt update -y #&> /dev/null
      echo "password" | sudo -S apt install sshpass #&> /dev/null
    else
      echo "#################################"
      echo "Installing sshpass on CentOS"
      echo "#################################"
      echo "password" | sudo -S yum update -y &> /dev/null
      echo "password" | sudo -S yum install -y sshpass &> /dev/null
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

cat remotehosts.txt | while IFS=":" read -r host USER
do
      # ping -c 1 $host &> /dev/null
      # echo "Ping executed on $host"
      # sleep 2
      # if [ $? -eq 0 ]
     sleep 1
# 1. Connectivity Check
      if ping -c 1 $host &> /dev/null
      then
        echo "#################################"
        echo "Copy public on the remote server $host"
        echo "#################################"
# 2. Key Transfer        
        if sshpass -e ssh-copy-id -i $KEY_PATH.pub -o StrictHostKeyChecking=no $USER@$host
        then
          echo "#################################"
          echo "Key file  transfered in the $host server"
          echo "#################################"
        
        else
          echo "key fie transfer failed"
        fi	    
        echo "#################################"
        echo "The user $USER is connected on the remote server $host"
# 3. Remote Execution
        echo "#################################"
        ssh -i $KEY_PATH $USER@$host <<'EOF'
          REMOTE_SERVER_NAME=\${hostname}
          echo "I am running on \$REMOTE_SERVER_NAME"
          ls -la .ssh/
          cat /etc/os-release
          sleep 1
          exit
EOF
      else
        echo "#################################"
        echo "Host $host is unreachable."
        echo "#################################"
      fi

done  


