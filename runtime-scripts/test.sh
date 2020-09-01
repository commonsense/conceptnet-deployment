#!/bin/bash -e
source /home/conceptnet/env/bin/activate
cd /home/conceptnet/conceptnet5
pip3 install pytest PyLD
pytest
