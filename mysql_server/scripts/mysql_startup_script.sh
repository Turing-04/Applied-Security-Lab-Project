#!/bin/bash

export SYNCED_FOLDER="/vagrant"
export VAGRANT_HOME="/home/vagrant"

echo "Startup script started"

# mysql server setup
echo "Starting mysql setup"
bash "$SYNCED_FOLDER/scripts/setup_mysql.sh"
echo "DONE: mysql setup"

echo "Starting install of necessary software"
# allows to get newer packages than the box creation (e.g. python3.11-venv)
sudo apt update



# echo "Copy src to $VAGRANT_HOME"
# cp -r "$SYNCED_FOLDER/src/" "$VAGRANT_HOME/"
# rm -r "$VAGRANT_HOME/src/__pycache__" "$VAGRANT_HOME/src/.venv"

# # TODO !!! grant only execute to apache user
# chmod +x "$VAGRANT_HOME/src/ca_sign_csr.sh"

# cd "$VAGRANT_HOME/src"
# python -m venv .venv
# source .venv/bin/activate
# python -m pip install -r requirements.txt

# TODO set static ip to new network interface
# 10.0.0.5
# TODO disable internet access once setup done
# TODO delete synced folder once setup is done
# TODO remove vagrant user after setup