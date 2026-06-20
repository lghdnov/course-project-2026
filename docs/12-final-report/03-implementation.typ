  = Реализационная часть

  == Реализация бизнес-логики

Бэкенд системы реализован на фреймворке Spring Boot @spring-boot-docs с использованием многослойной архитектуры и модульной организации по бизнес-функциям (feature-first).

=== Структура проекта

```
msocial/
├── src/main/java/lghdnov/msocial/
│   ├── feature/
│   │   ├── user/         (api, controller, presentation, service, entity, repository, infrastructure)
│   │   ├── auth/         (аналогично)
│   │   ├── post/         (аналогично)
│   │   ├── comment/      (аналогично)
│   │   ├── group/        (аналогично)
│   │   └── community/    (аналогично)
│   └── common/
│       ├── exceptions/   (ValidationException, NotFoundException, AccessDeniedException)
│       ├── security/     (AuthFilter, JwtProvider, SecurityConfig)
│       ├── config/       (WebMvcConfig, SwaggerConfig, DBConfig)
│       └── utils/        (DateUtil, StringUtils)
├── src/main/resources/
│   ├── application.yml
│   └── db/migration/     (Flyway миграции)
└── src/test/
    ├── java/             (Unit и интеграционные тесты)
    └── resources/
```

=== Классы-сущности

Сущность `Session` инкапсулирует бизнес-правило активности сессии:

```java
@Entity
@Table(name = "auth_sessions")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Session {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name = "user_id", nullable = false) private Long userId;
    @Column(name = "refresh_token", unique = true, length = 512) private String refreshToken;
    @Column(name = "refresh_token_expires_at", nullable = false) private Instant refreshTokenExpiresAt;
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @Column(name = "revoked_at") private Instant revokedAt;
    @Version private Long version;

    public boolean isActive() {
        return revokedAt == null && refreshTokenExpiresAt.isAfter(Instant.now());
    }
}
```

=== Слой доступа к данным

Репозитории реализованы на Spring Data JPA с пользовательскими методами:

```java
@Repository
public interface SessionRepository extends JpaRepository<Session, Long> {
    Optional<Session> findByRefreshToken(String refreshToken);
    void deleteByRefreshToken(String refreshToken);
}
```

=== Слой управления

Контроллеры используют порты (интерфейсы) вместо конкретных сервисов, обеспечивая инверсию зависимостей:

```java
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final AuthCommandPort authCommandPort;
    private final TokenValidationPort tokenValidationPort;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authCommandPort.login(request));
    }
    // ...
}
```

== Рефакторинг и оптимизация

=== Статический анализ кода

Проект настроен для выполнения статического анализа через Gradle плагины (SpotBugs, PMD). Основные метрики:

- Покрытие кода тестами (JaCoCo): более 60 % для критичных модулей.

- Максимальная цикломатическая сложность методов: не более 10.

- Отсутствие критических уязвимостей зависимостей (OWASP Dependency Check).


=== Применение паттернов (Data Mapper, Identity Map)

*Маппер данных (Data Mapper)* — маппинг между Entity и DTO выполняется через MapStruct, что изолирует доменную модель от представления.

*Карта идентичности (Identity Map)* — кэширование пользовательских сессий и профилей через локальный кэш Caffeine со временем жизни (TTL) 5 минут, предотвращающее лишние запросы к БД при частом доступе к одним и тем же данным.

=== Оптимизация запросов

- Использование `FetchType.LAZY` для всех ассоциаций `@OneToMany` и `@ManyToOne`.

- Создание индексов на часто используемых столбцах (`posts.author_id`, `comments.post_id`, `avatars.user_id`).

- Частичный индекс для активных аватаров (`WHERE is_current = TRUE`).

- Пагинация для лент публикаций и комментариев (`Pageable` в Spring Data).


== Пользовательский интерфейс

=== Настольное (десктопное) приложение

Desktop-версия реализована как обёртка над веб-приложением в изолированном WebView (Tauri / Electron-подход). Бизнес-логика отсутствует на клиенте; взаимодействие осуществляется через REST API и WebSockets.

=== Веб-приложение

Клиентское приложение `likma` построено на React 18 + Vite + TypeScript @react-docs:

- Дизайн-система: `folds` + `vanilla-extract` (zero-runtime CSS-in-JS).

- Управление состоянием: Jotai (атомарное глобальное состояние приложения) + TanStack Query (состояние сервера).

- Маршрутизация: `react-router-dom` v6 с поддержкой Browser и Hash Router.

- Интеграция с Matrix: `matrix-js-sdk` для чатов, `msocial-js-sdk` для социальных функций.



Основные экраны (список чатов, комната, лента публикаций, редактор постов, комментарии, профиль пользователя, настройки) представлены в Приложении В.

=== Сравнение реализаций

#figure(
  table(
    columns: 3,
    align: (left, left, left),
    stroke: 0.5pt,
    inset: 5pt,
    table.header([*Критерий*], [*Web*], [*Desktop*]),
    [Развёртывание], [Браузер, обновление без установки], [Установщик, автообновление],
    [Производительность], [Зависит от браузера], [Нативный WebView, меньше overhead],
    [Доступ к системе], [Ограничен песочницей браузера], [Возможен доступ к файловой системе],
    [Offline-режим], [Service Workers], [Локальное хранилище + синхронизация],
    [Разработка], [Один код для всех платформ], [Один код + нативная оболочка],
  ),
  caption: [Сравнение реализаций web и desktop приложений],
)

== Безопасность и транзакции

=== Аутентификация и авторизация

Аутентификация выполняется через Matrix OpenID Federation @matrix-openid:

+ Клиент получает `openid_token` от Matrix-сервера.

+ Бэкенд верифицирует токен через Federation API (`/_matrix/federation/v1/openid/userinfo`).

+ При успешной верификации выполняется провижининг пользователя (`findByIdOrCreate`).

+ Генерируется внутренняя JWT-пара (access + refresh) на основе стандарта RFC 7519 @jwt-rfc.

+ Access-токен передаётся в заголовке `Authorization: Bearer`, refresh — в теле запроса или HttpOnly cookie.


Авторизация на основе ролей: `@PreAuthorize("hasRole('ADMIN')")` для административных конечных точек доступа.

=== Управление транзакциями

Все операции, изменяющие состояние (создание, обновление, удаление), аннотированы `@Transactional` @spring-docs. Чтение оптимизировано через `@Transactional(readOnly = true)`.

Стратегия изоляции по умолчанию: `READ_COMMITTED`. Критичные операции (обновление баланса, ротация токенов) используют оптимистичные блокировки (`@Version`).

=== Защита от атак

- *SQL-инъекции* — предотвращаются Spring Data JPA (параметризованные запросы).

- *XSS* — предотвращается экранированием выходных данных на frontend и валидацией входных данных.

- *CORS* — настроен строгий CORS-фильтр с явным перечислением разрешённых адресов источников (origins) в промышленной среде (production).

- *Rate Limiting* — ограничение частоты запросов через Bucket4j (100 запросов/мин для аутентифицированных, 20 для анонимных).


== REST API

=== Спецификация OpenAPI

API документировано с использованием SpringDoc OpenAPI 3.1 @openapi-spec. Спецификация доступна по адресам:

- Swagger UI: `/swagger-ui.html`

- Scalar UI: `/scalar`

- JSON спецификация: `/v3/api-docs`


На основе спецификации генерируется TypeScript SDK (`msocial-js-sdk`) через инструмент `orval`.

=== Реализация контроллеров

Все контроллеры следуют единому соглашению:

- Базовый путь: `/api/v1/{resource}`

- HTTP методы: GET (чтение), POST (создание), PUT/PATCH (обновление), DELETE (удаление)

- Статусы: 200 OK, 201 Created, 204 No Content, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 429 Too Many Requests


=== Тестирование API

API тестируется на трёх уровнях:

+ *Модульные (unit) тесты контроллеров* — через `@WebMvcTest` с заменой сервисов имитационными объектами (mock-объектами).

+ *Интеграционные тесты* — через `TestRestTemplate` с поднятием полного контекста Spring.

+ *Контрактные тесты* — проверка соответствия реализации сгенерированному SDK.



