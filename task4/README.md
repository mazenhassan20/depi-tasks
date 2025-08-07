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
