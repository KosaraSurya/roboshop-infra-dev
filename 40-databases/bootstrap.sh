#!/bin/bash

dnf install ansible -y
ansible-pull -U https://github.com/KosaraSurya/ansible-roles-roboshop-tf.git -e component=$1 -e env=$2 main.yaml
# component given because in ansible we written same playbbok for all in run time we are passing args as component