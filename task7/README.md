

---

# Monitoring Spring Petclinic with Prometheus & Grafana (Docker Compose)

## 1) Project Structure

```
spring-petclinic/
├─ Dockerfile
├─ pom.xml
├─ docker-compose.yml
├─ docker-compose-dev.yml
├─ docker-compose-prod.yml
├─ prometheus/
│  └─ prometheus.yml
├─ grafana/
│  └─ provisioning/
│     └─ datasources/
│        └─ datasources.yaml
└─ src/
   └─ main/
      └─ resources/
         └─ application.properties
```

**Explanation :**
This structure keeps runtime tooling (Prometheus/Grafana) side-by-side with your app. Grafana provisioning and Prometheus config live in their own folders so Compose can mount them into containers in a clean way.

---

## 2) `docker-compose.yml` (Final after fixes)

```yaml
services:
  webapp:
    image: spring_petclinic:v2
    container_name: pet_web
    ports:
      - "8083:8080"  
    depends_on:
      - prometheus
      - grafana
    networks:
      - net1

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
    networks:
      - net1

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro
    networks:
      - net1

networks:
  net1:
```

**Explanation **

* `webapp` exposes **8080** inside the container and maps it to **8083** on your machine.
* Prometheus and Grafana mount their configs from the repo.
* All services share the same Docker network so they can reach each other by **service/container name** (e.g., `prometheus:9090`, `pet_web:8080`).

---

## 3) `docker-compose-dev.yml` (Development overrides)

```yaml
services:
  webapp:
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://dev:3306/devDB
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: 1234
      SPRING_PROFILES_ACTIVE: mysql
    depends_on:
      - devdb
    networks:
      - net1

  devdb:
    image: mysql:8.0
    container_name: dev
    environment:
      MYSQL_DATABASE: devDB
      MYSQL_ROOT_PASSWORD: 1234
    expose:
      - "3306"
    volumes:
      - mysql_vol:/var/lib/mysql
    networks:
      - net1

volumes:
  mysql_vol:

networks:
  net1:
```

**Explanation (EN):**
This file injects **MySQL** for local dev and points Spring to it via environment variables. You combine it with the base file when running dev.

---

## 4) `docker-compose-prod.yml` (Production-like overrides)

```yaml
services:
  webapp:
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://prod:5432/prodDB
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: 1234
      SPRING_PROFILES_ACTIVE: postgres
    depends_on:
      - prodb
    networks:
      - net1

  prodb:
    image: postgres:15
    container_name: prod
    environment:
      POSTGRES_DB: prodDB
      POSTGRES_PASSWORD: 1234
    expose:
      - "5432"
    volumes:
      - postgres_vol:/var/lib/postgresql/data
    networks:
      - net1

volumes:
  postgres_vol:

networks:
  net1:
```

**Explanation (EN):**
This file swaps the DB to **PostgreSQL** for a production-like environment. Note the corrected env var `POSTGRES_DB` (not `POSTGRS_DB`).

---

## 5) Prometheus & Grafana Configs

### 5.1 `prometheus/prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'spring-app'
    metrics_path: '/actuator/prometheus'
    scrape_interval: 3s
    static_configs:
      - targets: ['pet_web:8080']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']
```

**Explanation (EN):**
Prometheus scrapes your Spring Boot app every **3s** from the internal container address `pet_web:8080/actuator/prometheus` and also scrapes its own metrics.

---

### 5.2 `grafana/provisioning/datasources/datasources.yaml`

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
```

**Explanation (EN):**
Grafana auto-loads this data source on startup, pointing it to the Prometheus container by service name (`prometheus:9090`), so you don’t have to add it manually.

---

## 6) The two app files we modified

### 6.1 `pom.xml` (original content + added Micrometer Prometheus dependency)

> **Only addition** is the `micrometer-registry-prometheus` dependency inside `<dependencies>` (right after actuator). Everything else is unchanged from your original.

```xml

  <dependencies>
    <!-- Spring and Spring Boot dependencies -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>

    <!-- ADDED for Prometheus metrics export -->
    <dependency>
      <groupId>io.micrometer</groupId>
      <artifactId>micrometer-registry-prometheus</artifactId>
    </dependency>


```

**Explanation (EN):**
Micrometer’s Prometheus registry enables the `/actuator/prometheus` endpoint to actually emit numeric time series Prometheus can scrape.

---

### 6.2 `src/main/resources/application.properties` (original + two lines added)

> **Only additions** are the two lines under the Actuator section.

```
# Actuator
management.endpoints.web.exposure.include=*
management.endpoint.prometheus.enabled=true
management.metrics.export.prometheus.enabled=true

```

**Explanation (EN):**

* `management.endpoints.web.exposure.include=*` exposes actuator endpoints over HTTP.
* `management.endpoint.prometheus.enabled=true` & `management.metrics.export.prometheus.enabled=true` ensure Prometheus metrics are available at `/actuator/prometheus`.

---

## 7) Build Commands (App & Image)

```bash
# From project root:
./mvnw clean package -DskipTests
# (Optional sanity run outside Docker)
java -jar target/*.jar
```

**Explanation (EN):**
Builds the Spring Boot jar with the new dependency. Running it locally lets you confirm `/actuator/prometheus` shows metrics text.

```bash
# Build Docker image for the app
docker build -t spring_petclinic:v2 .
```

**Explanation (EN):**
Creates the container image that `docker-compose.yml` will use.

---

## 8) Run Commands (Dev/Prod, Prometheus, Grafana)

### 8.1 Development stack (with MySQL)

```bash
docker-compose -f docker-compose.yml -f docker-compose-dev.yml up -d
```

**Explanation (EN):**
Brings up app + Prometheus + Grafana + MySQL using both the base and dev override files.

### 8.2 Production-like stack (with PostgreSQL)

```bash
docker-compose -f docker-compose.yml -f docker-compose-prod.yml up -d
```

**Explanation (EN):**
Brings up app + Prometheus + Grafana + PostgreSQL using the prod overrides.

### 8.3 Stop everything

```bash
docker-compose down
```

**Explanation (EN):**
Stops and removes all the containers started by the selected compose files.

---

## 9) Verifications & Grafana Dashboards

### 9.1 Verify endpoints

* App metrics: `http://localhost:8083/actuator/prometheus`
* Prometheus UI: `http://localhost:9090` (Targets: `http://localhost:9090/targets`)
* Grafana UI: `http://localhost:3000` (login: `admin / admin` by default)

**Explanation (EN):**
Use the URLs above to confirm each piece is healthy. In Prometheus Targets, your app should show **UP**.

### 9.2 Grafana data source

In Grafana: **Connections → Data sources → Prometheus** should already point to `http://prometheus:9090`.

**Explanation (EN):**
Grafana reads the datasource from the provisioned file; no manual step needed.

### 9.3 Import a ready-made dashboard

Grafana → **Dashboards → Import** → Enter ID 11378 → Select Prometheus datasource → **Import**.

**Explanation (EN):**
This instantly gives you nice charts (JVM memory, request rate, latency, etc.) without writing queries. You can later customize panels as needed.

---

