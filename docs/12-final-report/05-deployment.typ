  = Развёртывание и эксплуатация

  == Контейнеризация (Docker)

  Для упаковки серверного приложения msocial используется подход многоэтапной сборки (multi-stage build) @docker-docs, что позволяет изолировать процесс компиляции от среды выполнения и минимизировать конечный размер Docker-образа (примерно до 135 МБ), повышая тем самым безопасность эксплуатации.

  *Листинг 5.1 — Файл конфигурации Dockerfile*
  ```dockerfile
  # Этап 1: Сборка приложения
  FROM gradle:8.5-jdk21-alpine AS builder
  WORKDIR /build
  COPY --chown=gradle:gradle . .
  RUN ./gradlew bootJar --no-daemon

  # Этап 2: Среда выполнения
  FROM eclipse-temurin:21-jre-alpine
  WORKDIR /app
  RUN addgroup -S spring && adduser -S spring -G spring
  USER spring:spring
  COPY --from=builder /build/build/libs/*.jar app.jar
  EXPOSE 8080
  ENTRYPOINT ["java", "-jar", "app.jar"]
  ```

  == Локальный запуск (Docker Compose)

  Для развертывания бэкенд-системы msocial совместно с базой данных PostgreSQL в среде локальной разработки подготовлен файл конфигурации `docker-compose.yml`.

  *Листинг 5.2 — Файл конфигурации docker-compose.yml*
  ```yaml
  version: '3.8'

  services:
    db:
      image: postgres:15-alpine
      container_name: msocial_db
      environment:
        POSTGRES_DB: msocial
        POSTGRES_USER: msocial_user
        POSTGRES_PASSWORD: msocial_password
      ports:
        - "5432:5432"
      volumes:
        - pgdata:/var/lib/postgresql/data
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U msocial_user -d msocial"]
        interval: 10s
        timeout: 5s
        retries: 5

    backend:
      image: glitchcat/msocial:local
      container_name: msocial_backend
      ports:
        - "8080:8080"
      environment:
        - SPRING_PROFILES_ACTIVE=dev
        - SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/msocial
        - SPRING_DATASOURCE_USERNAME=msocial_user
        - SPRING_DATASOURCE_PASSWORD=msocial_password
        - APP_JWT_SECRET=super_secret_key_which_must_be_long_enough_256_bits
        - AUTH_DEV_SKIP_VERIFY=true
      depends_on:
        db:
          condition: service_healthy

  volumes:
    pgdata:
  ```

  == Оркестрация (Kubernetes)

  В промышленной среде (production) развертывание осуществляется в кластер Kubernetes @kubernetes-docs. Для автоматизации развертывания и пакетирования сервисов в кластере применяются Helm-чарты @helm-docs. Ниже приведен пример манифеста деплоймента с лимитами ресурсов и проверками работоспособности (probes).

  *Листинг 5.3 — Манифест Kubernetes Deployment*
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: msocial-backend
    namespace: msocial
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: msocial-backend
    template:
      metadata:
        labels:
          app: msocial-backend
      spec:
        containers:
        - name: msocial
          image: glitchcat/msocial:v1.0.0
          ports:
          - containerPort: 8080
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 10
  ```

  == Инструкция по установке и запуску

  Для ручной сборки и запуска приложения в режиме разработки необходимо выполнить следующие команды:
  ```bash
  # 1. Клонирование репозитория вместе со всеми зависимыми субмодулями
  git clone --recurse-submodules https://github.com/lghdnov/CourseProject-2026.git
  cd CourseProject-2026

  # 2. Сборка исполняемого jar-архива
  cd msocial
  ./gradlew bootJar

  # 3. Запуск контейнеров через Docker Compose
  docker compose up -d
  ```

  == Инструкция по настройке параметров

  Настройка системы msocial осуществляется через переменные окружения, переопределяющие параметры в файле `application.yml`:
  - `SPRING_DATASOURCE_URL` — строка подключения к СУБД (например, `jdbc:postgresql://localhost:5432/msocial`).
  - `APP_JWT_SECRET` — криптографический секретный ключ для генерации JWT токенов (не менее 256 бит).
  - `APP_JWT_ACCESS_EXPIRATION` — время жизни access-токена в миллисекундах (по умолчанию 900 000 мс — 15 минут).
  - `APP_MATRIX_HOMESERVER` — URL домашнего сервера Matrix для верификации OpenID токенов.
  - `AUTH_DEV_SKIP_VERIFY` — флаг отключения верификации OIDC для локальной отладки (принимает значения `true` или `false`).

  == Требования к окружению

  Минимальные системные требования для развертывания и стабильного функционирования программного обеспечения представлены в таблице ниже.

  #figure(
    table(
      columns: 2,
      align: (left, left),
      stroke: 0.5pt,
      inset: 5pt,
      table.header([*Компонент окружения*], [*Минимальные системные требования*]),
      [Java Runtime (JRE)], [Версия 21 и выше],
      [Gradle (сборщик)], [Версия 8.5 и выше],
      [СУБД PostgreSQL], [Версия 15 и выше],
      [Docker Engine / Compose], [Версия 24.0 / 2.20 и выше],
      [Среда Kubernetes], [Версия 1.25 и выше],
      [Выделенная память (RAM)], [Не менее 1 ГБ для бэкенда],
      [Свободный диск (ROM)], [Не менее 10 ГБ для хранения медиа и БД],
    ),
    caption: [Требования к окружению эксплуатации],
  )


