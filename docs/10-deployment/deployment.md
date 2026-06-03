# Развёртывание

## 1. Docker

### 1.1. Dockerfile

Многоступенчатая сборка на базе Alpine JRE:

```dockerfile
FROM eclipse-temurin:25-jre-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY build/libs/*.jar app.jar

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

Особенности:
- **Alpine Linux** — минимальный размер образа
- **Непривилегированный пользователь** (`appuser`) — повышенная безопасность
- **Healthcheck** — проверка через Actuator на порту 8081
- **Порт 8080** — основной API
- **Порт 8081** — Actuator / health probes

### 1.2. Сборка Docker-образа

```bash
cd msocial
./gradlew bootJar
docker build -t glitchcat/msocial:local .
```

### 1.3. Запуск контейнера

```bash
docker run -d \
  -p 8080:8080 \
  -e DB_URL=jdbc:postgresql://host.docker.internal:5432/msocial \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=your-secret-key \
  glitchcat/msocial:local
```

---

## 2. CI/CD (GitHub Actions)

### 2.1. Workflow: docker-publish.yml

Конвейер автоматически собирает и публикует Docker-образ в Docker Hub при пуше в `main`.

Особенности:
- **Триггер:** push в ветку `main`
- **Сборка:** Gradle bootJar
- **Публикация:** Docker Hub (`glitchcat/msocial:main`)
- **Секреты:** `DOCKER_USERNAME`, `DOCKER_PASSWORD`

---

## 3. Kubernetes (Helm)

### 3.1. Требования

- Kubernetes 1.25+
- Helm 3.10+

### 3.2. Быстрый старт

```bash
helm dependency update ./msocial-helm
helm install msocial ./msocial-helm
kubectl get pods -l app.kubernetes.io/name=msocial
```

### 3.3. Параметры Helm-чарта

#### Глобальные параметры

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `replicaCount` | Количество реплик | `1` |
| `image.repository` | Docker-репозиторий | `glitchcat/msocial` |
| `image.tag` | Тег образа | `main` |
| `image.pullPolicy` | Политика загрузки | `IfNotPresent` |
| `service.type` | Тип Service | `ClusterIP` |
| `service.port` | Порт сервиса | `8080` |

#### Конфигурация приложения

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `app.serverPort` | Порт приложения | `8080` |
| `app.logLevel` | Уровень логирования | `INFO` |
| `app.jwt.secret` | JWT-секрет | `""` (автогенерация) |
| `app.jwt.expiration` | Время жизни JWT | `86400000` |
| `app.storage.type` | Тип хранилища | `local` |
| `persistence.enabled` | PVC для uploads | `false` |
| `persistence.size` | Размер PVC | `5Gi` |

#### PostgreSQL (subchart)

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `postgresql.enabled` | Встроенный PostgreSQL | `true` |
| `postgresql.auth.username` | Имя пользователя | `postgres` |
| `postgresql.auth.password` | Пароль | `""` (автогенерация) |
| `postgresql.auth.database` | Имя БД | `msocial` |

#### Масштабирование

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `autoscaling.enabled` | HPA | `false` |
| `autoscaling.minReplicas` | Мин. реплик | `1` |
| `autoscaling.maxReplicas` | Макс. реплик | `5` |
| `pdb.enabled` | PodDisruptionBudget | `false` |

### 3.4. Примеры установки

**Встроенный PostgreSQL:**

```bash
helm install msocial ./msocial-helm \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=SuperSecretPassword123 \
  --set app.jwt.secret=MyVeryStrongJWTSecretKeyForProd
```

**Внешний PostgreSQL:**

```bash
helm install msocial ./msocial-helm \
  --set postgresql.enabled=false \
  --set externalDatabase.host=postgres.example.com \
  --set externalDatabase.database=msocial \
  --set externalDatabase.username=msocial \
  --set externalDatabase.password=SecretPassword \
  --set app.jwt.secret=MyVeryStrongJWTSecretKeyForProd
```

### 3.5. Обновление и удаление

```bash
helm upgrade msocial ./msocial-helm --set image.tag=new-version
helm uninstall msocial
```

---

## 4. Локальная разработка

### 4.1. Требования

- Java 21+
- Gradle 8.5+
- PostgreSQL 15+ (или Docker)

### 4.2. Запуск PostgreSQL в Docker

```bash
docker run -d --name msocial-postgres \
  -e POSTGRES_DB=msocial -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 postgres:15-alpine
```

### 4.3. Запуск приложения

```bash
cd msocial
./gradlew bootRun
```

Приложение: http://localhost:8080  
Scalar UI: http://localhost:8080/scalar

### 4.4. Запуск тестов

```bash
./gradlew test
```

---

## 5. Мониторинг

### 5.1. Actuator Endpoints

| Эндпоинт | Описание |
|----------|----------|
| `GET :8081/actuator/health` | Состояние здоровья |
| `GET :8081/actuator/health/liveness` | Liveness probe |
| `GET :8081/actuator/health/readiness` | Readiness probe |

### 5.2. Логирование

Настройка через переменную окружения `LOG_LEVEL`.
