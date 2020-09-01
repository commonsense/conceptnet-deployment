#!/bin/bash -e
sudo chown -R conceptnet:conceptnet /home/conceptnet/env
sudo chmod +x /home/conceptnet/env/bin/activate
source /home/conceptnet/env/bin/activate
cd /home/conceptnet/conceptnet5
sudo --preserve-env=PATH -H -u conceptnet ./build.sh webdata
