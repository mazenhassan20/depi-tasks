# 🐳 Spring PetClinic with Docker
## ⚙️ Step 1: Create Networks & Volumes
```bash
docker network create net1
docker network create net2

docker volume create vol
docker volume create vol2
```
## 🗄 Step 2: Run Shared MySQL for App1 & App2
```bash
docker run -d --name db-shared --network net1 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=pet1 \
  -v vol:/var/lib/mysql \
  mysql:8
```
## ⏳ Step 3: Create Second Database (pet2)
```bash
docker exec -it db-shared mysql -uroot -proot -e "CREATE DATABASE pet2;"
```
## 🚀 Step 4: Run App1 (Connect to pet1)
```bash
docker run -d --name app1 --network net1 \
  -p 8081:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://db-shared:3306/pet1 \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=root \
  petclinic-app
```
## 🚀 Step 5: Run App2 (Connect to pet2)
```bash
docker run -d --name app2 --network net1 \
  -p 8082:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://db-shared:3306/pet2 \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=root \
  petclinic-app2
```
## 🗄 Step 6: Run MySQL for App3 (Separate Network)
```bash
docker run -d --name db3 --network net2 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=pet3 \
  -v vol2:/var/lib/mysql \
  mysql:8
```
## 🚀 Step 7: Run App3 (Connect to db3)
```bash
docker run -d --name app3 --network net2 \
  -p 8083:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://db3:3306/pet3 \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=root \
  petclinic-app3
```
## 🔗 Step 8: Connect App3 to net1 to Access db-shared
```bash
docker network connect net1 app3
```
## 🔄 Step 9: Change App3 to Use pet2 in db-shared
```bash
docker rm -f app3
docker run -d --name app3 --network net1 \
  -p 8083:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://db-shared:3306/pet2 \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=root \
  petclinic-app3
```
## 📊 Verify Running Containers
```bash
docker ps
```
```
CONTAINER ID   IMAGE            COMMAND                  CREATED          STATUS          PORTS                                         NAMES
8355f1871d70   petclinic-app3   "java -jar app.jar"      22 minutes ago   Up 22 minutes   0.0.0.0:8083->8080/tcp, [::]:8083->8080/tcp   app3
d8b16e82a0a2   mysql:8          "docker-entrypoint.s…"   51 minutes ago   Up 51 minutes   3306/tcp, 33060/tcp                           db3
c1863aca3d06   petclinic-app2   "java -jar app.jar"      52 minutes ago   Up 52 minutes   0.0.0.0:8082->8080/tcp, [::]:8082->8080/tcp   app2
317bed5da58e   petclinic-app    "java -jar app.jar"      52 minutes ago   Up 52 minutes   0.0.0.0:8081->8080/tcp, [::]:8081->8080/tcp   app1
5a2d5bad2203   mysql:8          "docker-entrypoint.s…"   54 minutes ago   Up 54 minutes   3306/tcp, 33060/tcp                           db-shared
```
