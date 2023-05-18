#!/bin/bash

ansible-pull -i localhost, -U https://github.com/raghudevopsb71/roboshop-ansible roboshop.yml -e role_name=${component} -e env=${env} >/opt/ansible.log
# in the above command we are running ansible playbook
# and we are diverting the output to a log file " /opt/ansible.log "
# so that we can read the output from the file " /opt/ansible.log "