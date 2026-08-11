#!/bin/bash

terraform init

terraform apply -auto-approve

kubectl cluster-info

kubectl get nodes

## make it executable first by the below command

chmod +x create.sh

# then run the script

./create.sh