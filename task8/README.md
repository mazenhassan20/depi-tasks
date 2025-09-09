
---

````markdown
# 🐾 Spring PetClinic CI/CD with Jenkins and Docker

This repository documents the process of setting up **CI/CD for the Spring PetClinic app** using **Jenkins Pipelines** and **Docker**.  
We went through **two tasks**:  
1. Run the application using a pre-built Docker image.  
2. Build the JAR file ourselves with Maven, then package it into a Docker image and deploy.  

Along the way, we faced several errors and solved them step by step.

---

## 📌 Task 1: Run with Pre-Built Docker Image

### Jenkinsfile (first version)
```groovy
pipeline {
    agent any

    stages {
        stage('Clean Old Container') {
            steps {
                sh '''
                docker rm -f petclinic-container || true
                '''
            }
        }

        stage('Run PetClinic') {
            steps {
                sh '''
                docker run -d --name petclinic-container -p 8087:8080 petclinic-app
                '''
            }
        }
    }
}
````

### Explanation

* We used a **ready-made image**:
   petclinic-app
* Jenkins simply pulled this image and ran it in a container.
* The app was accessible at:

  ```
  http://localhost:8087
  ```

✅ This proved that Jenkins could successfully run a pipeline and deploy the PetClinic app.

---

## 📌 Task 2: Build and Package Ourselves

After running the prebuilt image, we extended the pipeline to **compile the app, build our own Docker image, and deploy it**.

### Jenkinsfile (final version)

```groovy
pipeline {
  agent any

  environment {
    IMAGE = "petclinic-app:${BUILD_NUMBER}"
    PORT  = "8087"
  }

  stages {
    stage('Build (Maven)') {
      steps {
        sh 'mvn -v'
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('Docker: build') {
      steps {
        sh "docker build -t ${IMAGE} ."
      }
    }

    stage('Deploy') {
      steps {
        sh '''
          docker rm -f petclinic-container || true
          docker run -d --name petclinic-container -p ${PORT}:8080 ${IMAGE}
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
    }
  }
}
```

### Dockerfile

```dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY target/*.jar app.jar
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Steps

1. **Build with Maven**

   * Jenkins runs:

     ```bash
     mvn clean package -DskipTests
     ```
   * This generates the JAR inside `target/`.

2. **Build Docker Image**

   * Jenkins builds a Docker image:

     ```bash
     docker build -t petclinic-app:${BUILD_NUMBER} .
     ```
   * First time was slow because the base image `openjdk:17-jdk-slim` was downloaded.

3. **Deploy**

   * Old container (if exists) is removed:

     ```bash
     docker rm -f petclinic-container || true
     ```
   * New container is started:

     ```bash
     docker run -d --name petclinic-container -p 8087:8080 petclinic-app:${BUILD_NUMBER}
     ```

4. **Post Actions**

   * The built JAR file (`target/*.jar`) is archived by Jenkins.

---

## ⚡ Issues We Faced and Fixes
### 1. Jenkins Could Not See Local Repository
At first, Jenkins failed to read the repo because it was just a **local folder** without a proper `.git` remote.  
We tried several things:
- Copying the project into Jenkins’ workspace → ❌ didn’t help.  
- Using the repo under `/home/mazen` → ❌ still not detected properly.  

✅ **Final working fix**:  
We created a **bare repository** and pointed Jenkins to it:  
```bash
cd /home/mazen
git clone --bare spring-petclinic spring-petclinic.git
Then in Jenkins, under SCM config, we used:


file:///home/mazen/spring-petclinic.git
This made Jenkins see it as a proper remote repository.

🔑 Jenkins Permission Issue

At one point, Jenkins failed to access the local repository because of file ownership and permissions.
By default, Jenkins runs under the jenkins system user, while the project files were owned by another user (mazen).

This caused errors like:

Permission denied
Could not read from remote repository


✅ Fix: Change the ownership of the project so Jenkins can access it.

sudo chown -R jenkins:jenkins /home/mazen/spring-petclinic
sudo chown -R jenkins:jenkins /home/mazen/spring-petclinic.git


After this, Jenkins was able to read the repo and run the pipeline normally.

2. Dubious Ownership Error
Error:


fatal: detected dubious ownership in repository at '/home/mazen/spring-petclinic.git'
✅ Fix:


git config --global --add safe.directory /home/mazen/spring-petclinic.git
3. Jenkins Local Checkout Blocked
By default, Jenkins doesn’t allow local SCM checkouts.
We solved this by editing Jenkins startup options.

✅ Fix:

Created an override file for the systemd service:


sudo systemctl edit jenkins
Added:


[Service]
Environment="JAVA_ARGS=-Djava.awt.headless=true -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"
Reloaded systemd and restarted Jenkins:


sudo systemctl daemon-reexec
sudo systemctl restart jenkins
Verified with:


ps -ef | grep jenkins | grep ALLOW_LOCAL_CHECKOUT


```
### 3. Maven Wrapper Missing

Error:

```
./mvnw: cannot open ./.mvn/wrapper/maven-wrapper.properties
cannot read distributionUrl property
```

Reason: the project didn’t include Maven Wrapper.
Fix: Updated **Jenkinsfile** to use system Maven:

```groovy
sh 'mvn -v'
sh 'mvn clean package -DskipTests'
```

---



---

## 🚀 Final Result

* We started with a simple pipeline running a **prebuilt image**.
* Then we created a **full pipeline**:

  * Compiling the app with Maven,
  * Building a custom Docker image,
  * Deploying it with Jenkins.

The app runs successfully at:

```
http://localhost:8087
```

---

```

---

تحبني أخلي الـ README ده **short & clean** (instructions سريعة زي أي repo) ولا تسيبه **detailed story** زي كده؟
```
