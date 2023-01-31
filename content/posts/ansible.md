---
title: Ansible增加用户和免密码登录
date : 2022-10-20
draft: false
---

## Ansible增加用户和免密码登录

### Playbook文件

```yaml
- hosts: all
  remote_user: ubuntu
  ## 是否通过sudo 执行,如果sudo 需要密码，可以通过在命令行加 -K 来输入
  become: yes 
#  vars_files: 
#    - vault-foo.yml
  tasks:
  - name: Add User curve
    ansible.builtin.user:
      name: curve
      comment: curve user
      #group: admin
  - name: Set authorized key token from file
    authorized_key:
      user: curve
      state: present
      key: "{{ lookup('file','~/.ssh/id_rsa.pub') }}"
  - name: Add user curve to sudo
    lineinfile:
      path: /etc/sudoers.d/curve
      line: 'curve ALL=(ALL) NOPASSWD: ALL'
      state: present
      mode: 0400
      create: yes
      validate: 'visudo -cf %s'
```

### Host文件

```text
192.168.2.168
```

### 执行操作

参数说明：-k 表示在命令行中读取密码，也可以通过密码文件的方式。

- 从命令行中读取密码：
```shell
$ ansible-playbook -i hosts playbook.yml -k
```

- 从Vault文件中读取密码
```shell
$ ansible-playbook -i hosts playbook.yml --ask-vault-pass
```
密码文件可以通过以下命令创建:
```yaml
ansible-vault create foo.yml
```

- 执行特定Task
```shell
ansible-playbook -i hosts.all reboot-playbook.yaml -k --tags "reboot"
```

