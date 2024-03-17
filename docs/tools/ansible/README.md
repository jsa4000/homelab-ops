# Ansible

Ansible is a popular open-source automation tool that can help you automate your IT infrastructure. Is is an **agentless** automation that automates deployment, configuration management (maintain infrastructure consistency) and orchestration (execution of multiple applications in order). Ansible gains it's popularity due to it's simplicity for being agentless, efficient, requires no additional software installed on target machine, use the simple YAML and complete with reporting

A common best practice is using **ephemeral**, **idempotent** and **immutable** infrastructure as possible, this means prevent infrastructure configuration drifts (**idempotent** ) and use of resources wherein containerized components are replaced rather than changed (**immutable**).

Take following consideration using **Change Management** tools:

* Do not update or make change to the OS since it will drift from the original state (**idempotent**). If so use Ansible, do not make any change manually.
* Use **immutable** images, so every time an update is needed because maintenance reasons: vulnerabilities, fixes, etc.. the server must be replaced entirely by the new version of the image.

## Installation

Since it is **agentless** it does not require to install anything in the servers. The only requirements are:

* Python3 installed on remote machines
* Added SSH public keys

For the server side, in order to install using MacOs the simpler way is by using homebrew.

```bash
# Install Ansible using brew
brew install ansible

# Check the installation
ansible --version
```

## Structure

### Config

This config file is used for ansible to simpligy the execution of playbooks using default inventory, roles folder, etc..

`ansible.cfg`

```ini
[defaults]
nocows = True
roles_path = ./roles
inventory  = ./inventory.yaml

remote_tmp = $HOME/.ansible/tmp
local_tmp  = $HOME/.ansible/tmp
pipelining = True
become = True
host_key_checking = False
deprecation_warnings = False
callback_whitelist = profile_tasks

```

### Inventory

You can define the inventory using `ini` or `yaml` files in Ansible.
In this file you must define the servers that Ansible are going to manage organized into groups.
Also you can specify variables to be used later on during the tasks execution.

`inventory.yaml`

```yaml
---
k3s_cluster:
  children:
    server:
      hosts:
        sbc-server-1:
    agent:
      hosts:
        sbc-server-2:
        sbc-server-3:
  # This section is the same as using `group_vars/k3s_cluster/vars.yaml` file
  vars:
    custom_command: lsblk

```

```bash
# Check all servers in the inventory ('-i' flag is not necessary because it will use the default in ansible.cfg)
ansible all -m ping
ansible all -m ping -i inventory.yaml

# Check the k3s_cluster group and children
ansible k3s_cluster -m ping

# Check the server group
ansible server -m ping

# Check the agent group
ansible agent -m ping

# List all hosts
ansible k3s_cluster --list-hosts
```

### Tasks

Standalone tasks are stored in `tasks` folder, however it is not a good practice.

Create a file `./tasks/test.yaml`

```bash
---
- name: Get CPU Info
  register: cpuinfo
  command: "cat /proc/cpuinfo"

- name: Execute the uname command
  register: unameout
  command: "uname -a"

- name: Execute custom command
  register: commandout
  command: "{{ custom_command }}"

- debug:
    var: unameout.stdout_lines, cpuinfo.stdout_lines, commandout.stdout_lines
```

Create a playbook file `./playbook/test.yaml`

```yaml
---

- name: Return Server Info
  hosts: all
  gather_facts: true
  become: true # Ansible sudo
  tasks:
    import_tasks: tasks/test.yaml

```

### Playbooks

Ansible Playbooks offer a **repeatable**, **reusable**, **simple configuration management** and **multi-machine deployment system**, one that is well suited to deploying complex applications. If you need to execute a task with Ansible more than once, write a playbook and put it under source control. Then you can use the playbook to push out new configuration or confirm the configuration of remote systems. The playbooks in the ansible-examples repository illustrate many useful techniques. You may want to look at these in another tab as you read the documentation.

Playbooks can:

* Declare configurations
* orchestrate steps of any manual ordered process, on multiple sets of machines, in a defined order
* launch tasks synchronously or asynchronously

Playbooks are stored in the `playbook` folder, so create a file `./playbook/test.yaml`

```yaml
---

- name: Return Server Info
  hosts: all
  gather_facts: true
  become: true # Ansible sudo
  tasks:
    - name: Get CPU Info
      register: cpuinfo
      command: "cat /proc/cpuinfo"
    - name: Execute the UNAME command
      register: unameout
      command: "uname -a"
    - debug:
        var: unameout.stdout_lines, cpuinfo.stdout_lines

```

In order to run playbooks use following commands.

```bash
# Running playbooks
ansible-playbook playbook/test.yaml
ansible-playbook playbook/test.yaml -i inventory.yaml

# Ansible's check mode allows you to execute a playbook without applying any alterations to your systems. You can use check mode to test playbooks before implementing them in a production environment.
ansible-playbook --check playbook/test.yaml
```

### Roles

Playbooks are stored in the `roles` folder. Within this folder, a new folder is created for each role.

Create a task file at `roles/info/tasks/main.yaml`

```yaml
---
- name: Get CPU Info
  register: cpuinfo
  command: "cat /proc/cpuinfo"

- name: Execute the uname command
  register: unameout
  command: "uname -a"

- name: Execute custom command
  register: commandout
  command: "{{ custom_command }}"

- debug:
    var: unameout.stdout_lines, cpuinfo.stdout_lines, commandout.stdout_lines

```

Create a playbook file `./playbook/test.yaml` that uses that role.

```yaml
---

- name: Cluster Info
  hosts: k3s_cluster
  gather_facts: true
  become: true
  roles:
    - role: info


```
