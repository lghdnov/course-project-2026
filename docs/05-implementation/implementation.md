# Реализация слоёв

## 1. Реализованный модуль: feature::auth (Аутентификация)

Модуль аутентификации обеспечивает вход пользователей через Matrix OpenID, генерацию внутренних JWT (access/refresh токенов), управление сессиями и валидацию токенов.

---

### 1.1. Слой Entity

Слой Entity содержит доменные сущности с поведением.

| Класс | Назначение | Аннотации JPA |
|-------|-----------|---------------|
| `Session` | Сессия аутентификации, хранит refresh-токен и сроки действия | `@Entity`, `@Table(name = "auth_sessions")`, `@Id`, `@GeneratedValue`, `@Version` |
| `JwtClaims` | Кастомные claims внутреннего access-токена (sub, roles, sessionId) | Plain Java `record` |
| `MatrixUserInfo` | Информация о пользователе, полученная от Matrix Federation API | Plain Java `record` |

Ключевой бизнес-метод сущности `Session` — проверка активности сессии:

```java
public boolean isActive() {
    return revokedAt == null && refreshTokenExpiresAt.isAfter(Instant.now());
}
```

Сессия считается активной, если она не отозвана (`revokedAt == null`) и срок действия refresh-токена ещё не истёк.

---

### 1.2. Слой Foundation

Репозиторий `SessionRepository` на базе Spring Data JPA:

```java
@Repository
public interface SessionRepository extends JpaRepository<Session, Long> {
    Optional<Session> findByRefreshToken(String refreshToken);
    void deleteByRefreshToken(String refreshToken);
}
```

Базовый набор CRUD-операций + кастомные методы:
- `findByRefreshToken` — поиск сессии по refresh-токену (используется при logout и refresh)
- `deleteByRefreshToken` — удаление сессии по токену

Направленность зависимостей: `SessionRepository` зависит только от `Session` (Entity), что соответствует правилу PCMEF «Foundation → Entity».

---

### 1.3. Слой Mediator

Реализованы сервисы:

| Сервис | Порты | Назначение |
|--------|-------|-----------|
| `AuthService` | `AuthCommandPort`, `TokenValidationPort` | Оркестрация аутентификации |
| `TokenService` | `TokenGenerationPort`, `TokenValidationPort` | Генерация и валидация JWT |
| `SessionService` | `SessionManagementPort` | CRUD сессий, отзыв, ротация |

**AuthService.login()** — полный цикл аутентификации:

1. Валидация входных данных (пустой токен)
2. Верификация OIDC-токена (или skip в dev-режиме)
3. Провижининг пользователя (`UserProvisioningPort`)
4. Проверка активности аккаунта
5. Создание сессии
6. Генерация refresh-токена
7. Генерация access-токена (JWT)
8. Возврат `AuthResponse`

**TokenService** — криптографически стойкий refresh-токен:

```java
public String generateRefreshToken(Long sessionId) {
    byte[] bytes = new byte[REFRESH_TOKEN_BYTES]; // 64 байта
    SECURE_RANDOM.nextBytes(bytes);
    return BASE64_ENCODER.encodeToString(bytes);  // Base64 URL-safe
}
```

**SessionService** — управление сессиями с ротацией:

- `createSession(userId)` — создание сессии со сроком 30 дней
- `revokeSession(sessionId)` — мягкий отзыв (`revokedAt = now`)
- `findActiveSession(refreshToken)` — поиск только активных сессий
- `updateRefreshToken(sessionId, token)` — обновление токена

---

### 1.4. Слой Control

**DTO (Presentation)** — неизменяемые `record`-классы:

```java
public record LoginRequest(
    @NotBlank(message = "OpenID токен обязателен")
    @Schema(description = "Токен, полученный от Matrix-сервера")
    String openidToken,
    @Schema(description = "Идентификатор пользователя (dev-режим)")
    String userId
) {}

public record AuthResponse(
    @Schema(description = "JWT access-токен")
    String accessToken,
    @Schema(description = "Refresh-токен для обновления сессии")
    String refreshToken,
    @Schema(description = "Время жизни access-токена в секундах")
    long expiresIn
) {}
```

**AuthController** — REST API с OpenAPI-аннотациями:

| Метод | Эндпоинт | Описание |
|-------|----------|----------|
| POST | `/api/v1/auth/login` | Вход по Matrix OpenID токену |
| POST | `/api/v1/auth/refresh` | Обновление токенов |
| POST | `/api/v1/auth/logout` | Выход из системы |
| GET | `/api/v1/auth/validate` | Валидация access-токена |

Контроллер зависит только от портов (`AuthCommandPort`, `TokenValidationPort`), а не от конкретных сервисов.

---

## 2. Другие реализованные модули

### 2.1. feature::user (Управление пользователями)

Модуль предоставляет API для работы с профилем пользователя:

| Эндпоинт | Метод | Описание |
|----------|-------|----------|
| `/api/v1/users/profile` | GET | Получить профиль текущего пользователя |
| `/api/v1/users/profile` | PUT | Обновить профиль |

Ключевые классы:
- `UserController` — REST-контроллер
- `UserService` — бизнес-логика профиля
- `UserRepository` — доступ к данным пользователей
- `UserDTO`, `ProfileUpdateRequest` — DTO

### 2.2. feature::post (Публикации)

Модуль управляет постами пользователей:

| Эндпоинт | Метод | Описание |
|----------|-------|----------|
| `/api/v1/posts` | GET | Список постов |
| `/api/v1/posts` | POST | Создать пост |
| `/api/v1/posts/{id}` | GET | Получить пост по ID |
| `/api/v1/posts/{id}` | PUT | Обновить пост |
| `/api/v1/posts/{id}` | DELETE | Удалить пост |

Ключевые классы:
- `PostController` — REST-контроллер
- `PostService` — бизнес-логика публикаций
- `PostRepository` — доступ к данным постов
- `PostDTO`, `CreatePostRequest`, `UpdatePostRequest` — DTO
- `MediaType` — enum типов медиа (TEXT, IMAGE, VIDEO, AUDIO, LINK)

### 2.3. feature::comment (Комментарии)

Модуль управляет комментариями к постам:

| Эндпоинт | Метод | Описание |
|----------|-------|----------|
| `/api/v1/posts/{id}/comments` | GET | Список комментариев к посту |
| `/api/v1/posts/{id}/comments` | POST | Создать комментарий |
| `/api/v1/comments/{id}` | PUT | Обновить комментарий |
| `/api/v1/comments/{id}` | DELETE | Удалить комментарий |

Ключевые классы:
- `CommentController` — REST-контроллер
- `CommentService` — бизнес-логика комментариев
- `CommentRepository` — доступ к данным комментариев
- `CommentDTO`, `CreateCommentRequest`, `UpdateCommentRequest` — DTO
- `CommentStatus` — enum статусов (PUBLISHED, DELETED, HIDDEN)

### 2.4. Общие компоненты (common)

| Компонент | Назначение |
|-----------|-----------|
| `GlobalExceptionHandler` | Глобальная обработка исключений (`@ControllerAdvice`) |
| `AuthFilter` | Фильтр аутентификации по JWT |
| `SecurityConfig` | Конфигурация Spring Security |
| `OpenApiConfig` | Конфигурация OpenAPI / Scalar |
| `RestClientConfig` | Конфигурация HTTP-клиента для Matrix Federation |

---

## 3. Конфигурация приложения

### 3.1. application.yaml

```yaml
spring:
  application:
    name: msocial
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/msocial}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:postgres}
  jpa:
    hibernate:
      ddl-auto: validate
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: ${SERVER_PORT:8080}

jwt:
  secret: ${JWT_SECRET:your-secret-key-here-change-in-production}
  expiration: ${JWT_EXPIRATION:86400000}

auth:
  dev:
    skip-verify: ${DEV_AUTH_SKIP_VERIFY:true}

app:
  storage:
    type: ${STORAGE_TYPE:local}
    local:
      avatar-path: ${AVATAR_STORAGE_PATH:./uploads/avatars}
      post-media-path: ${POST_MEDIA_STORAGE_PATH:./uploads/post-media}

matrix:
  federation:
    base-url: ${MATRIX_BASE_URL:https://matrix.org}

management:
  server:
    port: 8081
  endpoints:
    web:
      exposure:
        include: health
```

### 3.2. Переменные окружения

| Переменная | Описание | Значение по умолчанию |
|-----------|----------|----------------------|
| `DB_URL` | JDBC URL PostgreSQL | `jdbc:postgresql://localhost:5432/msocial` |
| `DB_USERNAME` | Имя пользователя БД | `postgres` |
| `DB_PASSWORD` | Пароль БД | `postgres` |
| `JWT_SECRET` | Секретный ключ для подписи JWT | `your-secret-key-here-change-in-production` |
| `JWT_EXPIRATION` | Время жизни JWT в мс | `86400000` |
| `DEV_AUTH_SKIP_VERIFY` | Пропуск OIDC-верификации в dev | `true` |
| `STORAGE_TYPE` | Тип хранилища файлов | `local` |
| `MATRIX_BASE_URL` | URL Matrix-сервера | `https://matrix.org` |
| `SERVER_PORT` | Порт приложения | `8080` |
| `LOG_LEVEL` | Уровень логирования | `INFO` |

---

## 4. Соответствие архитектуре PCMEF

| Правило PCMEF | Реализация | Статус |
|--------------|-----------|--------|
| Control зависит только от Mediator (через порты) | `AuthController` использует `AuthCommandPort`, `TokenValidationPort` | ✅ Соблюдается |
| Mediator зависит от Entity и Foundation (через порты) | `AuthService` → порты; `SessionService` → `SessionRepository`; `TokenService` → `JwtProvider` | ✅ Соблюдается |
| Foundation зависит только от Entity | `SessionRepository` extends `JpaRepository<Session, Long>` | ✅ Соблюдается |
| Entity не зависит от других слоёв | `Session`, `JwtClaims`, `MatrixUserInfo` — чистые классы | ✅ Соблюдается |
| Отсутствие циклических зависимостей | Зависимости направлены строго сверху вниз | ✅ Соблюдается |
| Dependency Injection | Spring `@Autowired` / конструкторный DI | ✅ Соблюдается |
