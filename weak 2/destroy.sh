#!/bin/bash

terraform destroy -auto-approve

echo "Cluster destroyed."

## make it executable first by the below command

chmod +x destroy.sh

## then run the script

./destroy.sh 
