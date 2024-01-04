#!/bin/bash

CA_SERVER_ROOT="/var/www/ca-server"

cd "$CA_SERVER_ROOT/src"
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt

# performing unit tests
python -m pytest