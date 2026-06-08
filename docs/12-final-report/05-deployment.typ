= РАЗВЁРТЫВАНИЕ И ЭКСПЛУАТАЦИЯ

== Контейнеризация (Docker)

Бэкенд упакован в Docker-образ на базе Eclipse Temurin JRE 21 (Alpine):

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

Многослойная сборка (multi-stage) обеспечивает минимальный размер образа (~150 МБ).

== Инструкция по установке

```bash
# 1. Клонирование репозитория с субмодулями
git clone --recurse-submodules https://github.com/lghdnov/CourseProject-2026.git
cd CourseProject-2026

# 2. Сборка бэкенда
cd msocial
./gradlew bootJar

# 3. Сборка Docker-образа
docker build -t glitchcat/msocial:local .

# 4. Запуск
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host:5432/msocial \
  glitchcat/msocial:local
```

== Инструкция по настройке

Основные параметры конфигурации (через переменные окружения или `application.yml`):

- `SPRING_DATASOURCE_URL` — URL подключения к PostgreSQL.
- `SPRING_DATASOURCE_USERNAME` / `SPRING_DATASOURCE_PASSWORD` — учётные данные БД.
- `APP_JWT_SECRET` — секретный ключ для подписи JWT (минимум 256 бит).
- `APP_JWT_ACCESS_EXPIRATION` — время жизни access-токена (по умолчанию 15 минут).
- `APP_JWT_REFRESH_EXPIRATION` — время жизни refresh-токена (по умолчанию 30 дней).
- `APP_MATRIX_HOMESERVER` — базовый URL Matrix-сервера для Federation API.
- `AUTH_DEV_SKIP_VERIFY` — режим разработки (отключает проверку OIDC).

== Требования к окружению

#figure(
  table(
    columns: 2,
    align: (left, left),
    stroke: 0.5pt,
    inset: 5pt,
    table.header([*Компонент*], [*Минимальные требования*]),
    [Java JDK], [21+],
    [Gradle], [8.5+],
    [PostgreSQL], [15+],
    [Docker (опционально)], [24+],
    [Kubernetes], [1.25+],
    [Helm], [3.10+],
    [ОЗУ (runtime)], [1 GB],
    [Диск (база данных)], [10 GB],
  ),
  caption: [Требования к окружению эксплуатации],
)

