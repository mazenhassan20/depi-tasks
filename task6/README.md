# 📝 Create docker-compose file

```bash
nano docker-compose.yml
```

# 📄 Docker Compose Content

```bash
services:
  mysql:
    image: mysql:9.2
    container_name: petclinic-mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: petclinic
      MYSQL_USER: petclinic
      MYSQL_PASSWORD: petclinic
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - petnet

  petclinic:
    image: petclinic-app
    container_name: petclinic-app
    environment:
      - SPRING_PROFILES_ACTIVE=mysql
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/petclinic
      - SPRING_DATASOURCE_USERNAME=petclinic
      - SPRING_DATASOURCE_PASSWORD=petclinic
    ports:
      - "8089:8080"
    depends_on:
      - mysql
    networks:
      - petnet

networks:
  petnet:

volumes:
  mysql_data:
```

# 🔄 عمل Replica بتعديل الملف

```bash
cat << 'EOL' > docker-compose.yml
services:
  mysql:
    image: mysql:8
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: petclinic
      MYSQL_USER: petclinic
      MYSQL_PASSWORD: petclinic
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - petnet

  petclinic:
    image: petclinic-app
    environment:
      - SPRING_PROFILES_ACTIVE=mysql
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/petclinic
      - SPRING_DATASOURCE_USERNAME=petclinic
      - SPRING_DATASOURCE_PASSWORD=petclinic
    ports:
      - "0:8080"
    depends_on:
      - mysql
    networks:
      - petnet
    deploy:
      replicas: 3

networks:
  petnet:

volumes:
  mysql_data:
EOL
```

# ⚡️ عمل Replica من غير تعديل الملف

```bash
docker-compose up -d --scale petclinic=3
```
