Role Name: global_posix_capabilities_check
=========

This role is an Ansible Posix Capabilities checker.

Requirements
------------

Linux

Role Variables
--------------

N/A

Dependencies
------------

N/A

How is working:
===============
ansible-playbook checker.yml -i hosts --ask-become-pass  --tags "posix_capabilities"


NOTE:
=====
playbook exemple, when you call the role:

- name: "Ansible Posix Capabilities checker"
  hosts: servers
  port: ssh
  gather_facts: true
  tasks:
  - name: "global_posix_capabilities_check"
    # role global_posix_capabilities_check | Linux
    include_role:
      name: global_posix_capabilities_check
    tags:
      - posix_capabilities

Structure:
==========
roles/global_posix_capabilities_check
  files/posix_capabilities.sh
  tasks/main.yml
  tasks/posix_capabilities.yml

TAGS:
=====
- posix_capabilities
- global_posix_capabilities_check