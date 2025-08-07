# depi-tasks
Project

This project demonstrates a basic Docker setup using Ubuntu and two shell scripts: `hello.sh` and `script.sh`.

---

## 📁 Project Structure

```
.
├── Dockerfile
├── hello.sh
├── script.sh
└── README.md
```

---

## 🐳 Dockerfile

```Dockerfile
FROM ubuntu

ARG USER_NAME=mazen
ENV APP_ENV=production

WORKDIR /app

ADD hello.sh .
COPY script.sh .

RUN chmod +x hello.sh script.sh

CMD ["./hello.sh"]
ENTRYPOINT ["./script.sh"]
```

---

## 📜 Script Files

### `hello.sh`
```bash
#!/bin/bash
echo "Hello from hello.sh 🎉"
```

### `script.sh`
```bash
#!/bin/bash
echo "Running script.sh 🛠️"
exec "$@"
```

---

## 🛠️ Build Image

```bash
docker build . -t py-script
```

### ✅ Sample Output

```
[+] Building 0.1s (1/1) FINISHED
 => [internal] load build definition from Dockerfile
 => [2/5] WORKDIR /app
 => [3/5] ADD hello.sh .
 => [4/5] COPY script.sh .
 => [5/5] RUN chmod +x hello.sh script.sh
 => exporting to image
 => naming to py-script
```

---

## 🚀 Run Container

```bash
docker run -it py-script
```

### ✅ Output

```
Running script.sh 🛠️
Hello from hello.sh 🎉
```

---


# 🐳 Spring PetClinic with Docker

## ⚙️ Step 1: Package the app

```bash
./mvnw package

# 🧱 Docker Builds

# 📦 Version 1: Basic Dockerfile – petclinic-app
# Dockerfile
FROM openjdk:17-jdk-slim
COPY target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]

# Build
docker build -t petclinic-app .

# Run
docker run -p 8080:8080 petclinic-app

# 📦 Version 2: With layers – petclinic-app2
# Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
RUN apt-get update && apt-get install -y curl && apt-get clean
ENTRYPOINT ["java", "-jar", "app.jar"]

# Build
docker build -t petclinic-app2 .

# Run
docker run -p 8080:8080 petclinic-app2

# 📦 Version 3: Separated RUN – petclinic-app3
# Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean
ENTRYPOINT ["java", "-jar", "app.jar"]

# Build
docker build -t petclinic-app3 .

# Run
docker run -p 8080:8080 petclinic-app3

# 📦 Version 4: With .dockerignore – petclinic-app3ignore
# Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean
ENTRYPOINT ["java", "-jar", "app.jar"]

# .dockerignore
# -------------------
# .git
# **
# !target/
# !target/*.jar
# *.log
# *.iml
# .idea
# Dockerfile
# README.md
# -------------------

# Build
docker build -t petclinic-app3ignore .

# Run
docker run -p 8080:8080 petclinic-app3ignore

# 📊 Docker Image Size Comparison
# docker images
# REPOSITORY               TAG       IMAGE ID       CREATED          SIZE
# petclinic-app3           latest    782a66b861f6   13 minutes ago   498MB
# petclinic-app3ignore     latest    782a66b861f6   13 minutes ago   498MB
# petclinic-app2           latest    029a57f23047   16 minutes ago   498MB
# petclinic-app            latest    c0255514ad23   46 hours ago     475MB
# py-script                latest    84c33ac2cc2c   34 minutes ago   78.1MB
```

