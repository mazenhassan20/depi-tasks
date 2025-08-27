# Ansible Setup on WSL (Ubuntu) as Control Node and VMware Ubuntu as Managed Node

This guide documents **all the steps**, **commands executed**, **actual outputs**, **errors encountered**, and their **solutions** in a professional, reproducible format.

---

## **Environment**

* **Control Node:** WSL (Ubuntu)
* **Managed Node:** VMware Ubuntu 24.04 (IP: `192.168.139.128`)

---

## **Steps and Outputs**

### 1. **SSH Key Generation**

```bash
ssh-keygen
```

**Output:**

```
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
```

*(Pressed Enter to accept default)*

### 2. **Attempt SSH Connection**

```bash
ssh mazen@192.168.139.128
```

**Error:**

```
ssh: connect to host 192.168.139.128 port 22: Connection refused
```

**Solution:** Enable SSH on the VMware Ubuntu machine:

```bash
sudo apt update && sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

### 3. **Successful SSH Connection**

```bash
ssh mazen@192.168.139.128
```

**Output:**

```

<img width="906" height="481" alt="Screenshot 2025-08-27 033051" src="https://github.com/user-attachments/assets/2aea05d5-ce2f-46a4-b0ea-817d74e37d52" />

```

---

### 4. **Install Ansible on WSL**

```bash
sudo apt install python3-pip -y
pip install ansible
```

**Output:**

```
WARNING: Running pip as the 'root' user can result in broken permissions...
Successfully installed ansible-10.7.0 ansible-core-2.17.13 resolvelib-1.0.1
```

**Verification:**

```bash
pip3 show ansible
```

Output:

```
Name: ansible
Version: 10.7.0
Location: /usr/local/lib/python3.10/dist-packages
```

---

### 5. **Problem: Ansible Command Not Found**

```bash
ansible --version
```

**Error:**

```
bash: /usr/bin/ansible: No such file or directory
```

**Cause:** Ansible installed via pip is not in PATH.

**Solution:**

```bash
export PATH=$PATH:/usr/local/bin
```

*(Add this line to `~/.bashrc` for persistence.)*

---

### 6. **Test Ansible Ping**

Create inventory file:

```bash
sudo nano /etc/ansible/hosts.ini
```

Add:

```
[all]
192.168.139.128 ansible_user=mazen ansible_ssh_private_key_file=/root/.ssh/id_rsa
```

Run test:

```bash
ansible all -i /etc/ansible/hosts.ini -m ping
```

**Output:**

```
192.168.139.128 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

---

## **Final Notes**

* Always ensure `openssh-server` is running on the managed node.
* Use SSH key authentication for smooth automation.
* Add Ansible bin path to system PATH when installed via pip.

✅ **Ansible is now ready for automation tasks.**
