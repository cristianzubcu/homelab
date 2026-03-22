#!/bin/bash
cd "$(dirname "$0")"
ansible-playbook -i ansible/inventory.yml ansible/playbooks/setup.yml