markdown
# Spring PetClinic: WSL Control → Ubuntu VM (Ansible + Docker) — End-to-End Log

This README captures exactly what we did — playbooks, commands, **real outputs**, errors, and fixes — from installing **Nginx via Ansible** on the VM to **running the app in Docker**.

---

## Environment

- **Control node:** WSL (Ubuntu) as root
- **Managed node (VM):** Ubuntu 24.04 on VMware — `192.168.139.128`
- **Ansible inventory:** `hosts.ini`
- **Repo on control:** `/spring-petclinic` (contains `Dockerfile` + `target/*.jar`)

---

## Inventory

`hosts.ini`
```ini
[all]
192.168.139.128 ansible_user=mazen ansible_ssh_private_key_file=~/.ssh/id_rsa
````

> We use key auth for SSH. For sudo, we pass `--ask-become-pass` when needed.

---

## 1) Install & start Nginx on VM (Ansible Playbook)

`install_nginx.yml`

```yaml
---
- name: Install and start Nginx on Ubuntu VM
  hosts: all
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Enable and start Nginx
      service:
        name: nginx
        state: started
        enabled: yes
```

### First attempt (without sudo password) — **error**

```bash
ansible-playbook -i /etc/ansible/hosts.ini install_nginx.yml
```

**Output**

```
PLAY [Install and start Nginx on Ubuntu VM] ******************************************************************

TASK [Gathering Facts] ***************************************************************************************
fatal: [192.168.139.128]: FAILED! => {"msg": "Missing sudo password"}

PLAY RECAP ***************************************************************************************************
192.168.139.128            : ok=0    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```


### Retry with correct sudo password — **success**

```bash
ansible-playbook -i /etc/ansible/hosts.ini install_nginx.yml --ask-become-pass
```

**Result:** Nginx installed & running (success recap not captured).

---

## 2) Check Docker on VM (already installed)

`docker_check.yml`

```yaml
---
- name: Ensure Docker is installed and running
  hosts: all
  become: yes
  tasks:
    - name: Ensure Docker service is running
      service:
        name: docker
        state: started
        enabled: yes
```

Run:

```bash
ansible-playbook -i /etc/ansible/hosts.ini docker_check.yml
```

**Output**

```
PLAY [Ensure Docker is installed and running] ****************************************************************

TASK [Gathering Facts] ***************************************************************************************
[WARNING]: Platform linux on host 192.168.139.128 is using the discovered Python interpreter at
/usr/bin/python3.12, but future installation of another Python interpreter could change the meaning of that
path. See https://docs.ansible.com/ansible-core/2.17/reference_appendices/interpreter_discovery.html for more
information.
ok: [192.168.139.128]

TASK [Ensure Docker service is running] **********************************************************************
ok: [192.168.139.128]

PLAY RECAP ***************************************************************************************************
192.168.139.128            : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

---

## 3) Copy Spring PetClinic repo from WSL → VM (Ansible)

`copy_spring.yml`

```yaml
---
- name: Copy Spring Repo to Remote
  hosts: all
  become: yes
  tasks:
    - name: Copy Spring PetClinic repository
      ansible.builtin.copy:
        src: "/spring-petclinic/"
        dest: "/home/mazen/spring-petclinic/"
        owner: mazen
        group: mazen
        mode: '0755'
```

Run:

```bash
ansible-playbook -i hosts.ini copy_spring.yml
```

**Output**

```
PLAY [Deploy Spring App with Docker] *************************************************************************************************

TASK [Gathering Facts] ***************************************************************************************************************
[WARNING]: Platform linux on host 192.168.139.128 is using the discovered Python interpreter at /usr/bin/python3.12, but future
installation of another Python interpreter could change the meaning of that path. See https://docs.ansible.com/ansible-
core/2.17/reference_appendices/interpreter_discovery.html for more information.
ok: [192.168.139.128]

TASK [Copy repo to remote] ***********************************************************************************************************
ok: [192.168.139.128]
```

> We **attempted** to build the image via Ansible earlier and hit a module error:

```
TASK [Build Docker image] ************************************************************************************************************
fatal: [192.168.139.128]: FAILED! => {"changed": false, "msg": "state is present but all of the following are missing: source"}

PLAY RECAP ***************************************************************************************************************************
192.168.139.128            : ok=2    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

**Decision:** Build & run the container **manually on the VM** instead.

---

## 4) (WSL) Verify JAR exists (for Dockerfile COPY)

```bash
ls target/*.jar
```

**Output**

```
target/spring-petclinic-3.5.0-SNAPSHOT.jar
```

---

## 5) Dockerfile used by the repo (as-is)

`spring-petclinic/Dockerfile`

```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 6) On the VM: Build & Run the container (manual)

SSH into VM and go to repo:

```bash
ssh mazen@192.168.139.128
cd /home/mazen/spring-petclinic
```




### Build — success

```bash
sudo docker build -t spring-petclinic .
```

### Run the container

```bash
sudo docker run -d -p 8088:8080 --name spring-app spring-petclinic
docker ps
```

**Expected**

```
CONTAINER ID   IMAGE              ...   PORTS                    NAMES
<id>           spring-petclinic         0.0.0.0:8088->8080/tcp   spring-app
```

### Access the app

```
http://192.168.139.128:8088/
```

---

