  = Реализационная часть

  == Реализация бизнес-логики

  Бэкенд-система `msocial` реализована на языке Java 21 с использованием фреймворка Spring Boot 3.2 @spring-boot-docs. В соответствии с выбранной архитектурой PCMEF и принципами Clean Architecture, бизнес-логика изолирована от внешних фреймворков и библиотек.

  === Структура проекта

  Проектная структура следует шаблону *feature-first*, где код сгруппирован по функциональным модулям:

  ```
  msocial/
  ├── src/main/java/lghdnov/msocial/
  │   ├── feature/
  │   │   ├── user/         (dto, controller, service, entity, repository, port, adapter)
  │   │   ├── auth/         (аналогично)
  │   │   ├── post/         (аналогично)
  │   │   └── comment/      (аналогично)
  │   └── common/
  │       ├── exceptions/   (ValidationException, GlobalExceptionHandler)
  │       ├── security/     (AuthFilter, JwtProvider, SecurityConfig)
  │       ├── config/       (WebMvcConfig, CaffeineCacheConfig)
  │       └── utils/        (SecureTokenGenerator)
  ```

  === Классы-сущности (Entity Layer)

  Ниже представлены листинги ключевых JPA-сущностей, инкапсулирующих структуру базы данных и доменное поведение.

  *Листинг 3.1 — Класс доменной сущности User*
  ```java
  @Entity
  @Table(name = "users")
  @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
  public class User {
      @Id
      @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;

      @Column(name = "username", nullable = false, unique = true, length = 50)
      private String username;

      @Column(name = "display_name", nullable = false, length = 100)
      private String displayName;

      @Column(name = "created_at", nullable = false, updatable = false)
      private Instant createdAt;

      @Column(name = "last_active")
      private Instant lastActive;

      @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
      private PersonalInfo personalInfo;

      @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
      @OrderBy("uploadedAt DESC")
      private List<Avatar> avatars = new ArrayList<>();
  }
  ```

  *Листинг 3.2 — Сущность PersonalInfo*
  ```java
  @Entity
  @Table(name = "personal_infos")
  @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
  public class PersonalInfo {
      @Id
      @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;

      @OneToOne(fetch = FetchType.LAZY)
      @JoinColumn(name = "user_id", nullable = false)
      private User user;

      @Column(name = "birthday")
      private LocalDate birthday;

      @Column(name = "address", length = 255)
      private String address;

      @Column(name = "favorite_track_url", length = 512)
      private String favoriteTrackUrl;

      @Column(name = "status", length = 255)
      private String status;
  }
  ```

  *Листинг 3.3 — Сущность Session*
  ```java
  @Entity
  @Table(name = "auth_sessions")
  @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
  public class Session {
      @Id
      @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;

      @Column(name = "user_id", nullable = false)
      private Long userId;

      @Column(name = "refresh_token", unique = true, length = 512)
      private String refreshToken;

      @Column(name = "refresh_token_expires_at", nullable = false)
      private Instant refreshTokenExpiresAt;

      @Column(name = "created_at", nullable = false)
      private Instant createdAt;

      @Column(name = "revoked_at")
      private Instant revokedAt;

      @Version
      private Long version;

      public boolean isActive() {
          return revokedAt == null && refreshTokenExpiresAt.isAfter(Instant.now());
      }
  }
  ```

  === Слой доступа к данным (Foundation Layer)

  Доступ к данным реализован с помощью Spring Data JPA. Пример репозитория управления сессиями:

  *Листинг 3.4 — Интерфейс SessionRepository*
  ```java
  @Repository
  public interface SessionRepository extends JpaRepository<Session, Long> {
      Optional<Session> findByRefreshToken(String refreshToken);
      
      @Modifying
      @Query("UPDATE Session s SET s.revokedAt = CURRENT_TIMESTAMP WHERE s.id = :id")
      void revokeSession(@Param("id") Long id);
      
      List<Session> findAllByUserIdAndRevokedAtIsNull(Long userId);
  }
  ```

  === Слой бизнес-логики (Mediator Layer)

  Сервисы реализуют доменные порты, обеспечивая слабую связанность. Пример реализации процесса аутентификации:

  *Листинг 3.5 — Метод login в AuthService*
  ```java
  @Service
  @RequiredArgsConstructor
  public class AuthService implements AuthCommandPort {
      private final MatrixAuthPort matrixAuthPort;
      private final UserCommandPort userCommandPort;
      private final SessionManagementPort sessionManagementPort;
      private final TokenGenerationPort tokenGenerationPort;

      @Override
      @Transactional
      public AuthResponse login(LoginRequest request) {
          // 1. Верификация во внешней сети Matrix
          String matrixId = matrixAuthPort.verifyOpenIdToken(request.openidToken());
          
          // 2. Поиск или создание локального пользователя (provisioning)
          User user = userCommandPort.findByUsername(matrixId)
              .orElseGet(() -> userCommandPort.create(User.builder()
                  .username(matrixId)
                  .displayName(extractLocalName(matrixId))
                  .createdAt(Instant.now())
                  .build()));

          // 3. Создание сессии и генерация токенов
          Session session = sessionManagementPort.createSession(user.getId());
          String accessToken = tokenGenerationPort.generateAccessToken(user, session.getId());
          
          return new AuthResponse(accessToken, session.getRefreshToken(), 900L);
      }
      
      private String extractLocalName(String mxid) {
          return mxid.substring(1, mxid.indexOf(":"));
      }
  }
  ```

  == Рефакторинг и оптимизация

  === Статический анализ кода

  Для контроля качества исходного кода в Gradle-сборку внедрены плагины статического анализа SpotBugs, PMD и Checkstyle. Внедрен плагин JaCoCo для замера покрытия кода автоматизированными тестами.
  - Покрытие критических сервисных классов (сервисы модулей `auth` и `user`) составляет не менее 75%.
  - Цикломатическая сложность методов строго ограничена: максимальный индекс сложности не превышает 8, что гарантирует простоту чтения и поддержки кода.
  - Проверка зависимостей на уязвимости осуществляется плагином OWASP Dependency Check при каждой сборке CI/CD пайплайна по базе уязвимостей @owasp-top10.

  === Применение паттернов (Data Mapper, Identity Map)

  - *Data Mapper*: преобразование сущностей в DTO осуществляется с помощью MapStruct. Это изолирует доменную структуру БД от внешнего API, предотвращая утечку полей (например, `revokedAt`, `version`).
  - *Identity Map*: повторные запросы на чтение данных пользователя в рамках одного HTTP-запроса оптимизируются с помощью кэша первого уровня Hibernate. На уровне приложения реализован кэш второго уровня на базе библиотеки Caffeine с TTL 5 минут для статических данных профиля.

  === Оптимизация SQL-запросов

  Для повышения пропускной способности СУБД выполнены следующие настройки:
  - Установлен ленивый тип загрузки связей (`FetchType.LAZY`) для всех ассоциаций `@OneToMany` и `@ManyToOne` для исключения проблемы N+1.
  - Созданы составные индексы в PostgreSQL:
    ```sql
    CREATE INDEX idx_posts_author_created ON posts(author_id, created_at DESC);
    ```
    Это ускоряет выборку новостной ленты конкретного пользователя с сортировкой по дате.
  - Добавлена пагинация на уровне базы данных с использованием объектов `Pageable` и `Slice` в Spring Data, что предотвращает перегрузку ОЗУ при обработке миллионов комментариев.

  == Пользовательский интерфейс

  === Настольное (десктопное) приложение

  Настольный клиент представляет собой легковесную оболочку, созданную на базе фреймворка Tauri. Логика отрисовки интерфейса выполняется внутри WebView, а взаимодействие с операционной системой и сервером msocial осуществляется по защищенному протоколу HTTPS через REST API.

  === Веб-приложение

  Клиентская часть `likma` разработана на React 18 @react-docs, сборщике Vite и компиляторе TypeScript.
  - *CSS-in-JS*: стилизация выполнена с использованием `vanilla-extract`, что гарантирует компиляцию стилей на этапе сборки (zero-runtime CSS) и высокую скорость рендеринга.
  - *Управление состоянием*: Jotai обеспечивает реактивное атомарное состояние сессии и настроек на клиенте.
  
  Пример Jotai-атома авторизации:

  *Листинг 3.6 — Атом Jotai для сессии пользователя*
  ```typescript
  import { atom } from 'jotai';

  export interface AuthSession {
    accessToken: string;
    refreshToken: string;
    userId: string;
  }

  export const sessionAtom = atom<AuthSession | null>(null);
  export const isAuthenticatedAtom = atom((get) => get(sessionAtom) !== null);
  ```

  - *TanStack Query (React Query)*: используется для кэширования ответов сервера, автоматического обновления данных в фоне (background refetching) и оптимистичных обновлений интерфейса при лайках и комментариях.

  === Сравнение реализаций

  #figure(
    table(
      columns: 3,
      align: (left, left, left),
      stroke: 0.5pt,
      inset: 5pt,
      table.header([*Критерий*], [*Web (SPA)*], [*Desktop (Tauri)*]),
      [Доставка пользователю], [Через браузер по URL], [Локальный установочный пакет],
      [Потребление памяти], [Зависит от открытых вкладок браузера], [Минимальное (WebView от ОС, ~40 МБ)],
      [Локальные возможности], [Ограничены песочницей браузера], [Прямой доступ к ФС через Rust-биндинги],
      [Автономность (Offline)], [Service Workers, кэширование], [Локальная база данных SQLite + синхронизация],
    ),
    caption: [Сравнение реализаций web и desktop приложений],
  )

  == Безопасность и транзакции

  === Аутентификация и авторизация

  Схема безопасности базируется на Spring Security. Конфигурация включает в себя пользовательский фильтр аутентификации JWT с интеграцией через Matrix OpenID Federation @matrix-openid и генерацией внутренней JWT-пары по стандарту RFC 7519 @jwt-rfc:

  *Листинг 3.7 — Конфигурационный класс SecurityConfig*
  ```java
  @Configuration
  @EnableWebSecurity
  @RequiredArgsConstructor
  public class SecurityConfig {
      private final JwtAuthenticationFilter jwtAuthFilter;

      @Bean
      public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
          http
              .csrf(AbstractHttpConfigurer::disable)
              .cors(cors -> cors.configurationSource(corsConfigurationSource()))
              .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
              .authorizeHttpRequests(auth -> auth
                  .requestMatchers("/api/v1/auth/login", "/api/v1/auth/refresh").permitAll()
                  .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/scalar/**").permitAll()
                  .anyRequest().authenticated()
              )
              .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);
          return http.build();
      }
  }
  ```

  === Управление транзакциями

  Управление транзакциями в Spring Boot настроено декларативно с помощью аннотации `@Transactional` @spring-docs. Все методы на чтение оптимизированы с помощью `@Transactional(readOnly = true)`. Это сообщает Hibernate о возможности отключения механизма dirty checking, что существенно экономит ресурсы процессора.

  === Защита от атак и Rate Limiting

  - *CORS*: настроен жесткий фильтр источников. Разрешены запросы только от доверенного домена веб-приложения, настроен проброс заголовков `Authorization` и `Set-Cookie`.
  - *SQL-инъекции*: все репозитории используют именованные параметры и компилируемые PreparedStatement, что делает SQL-инъекции невозможными.
  - *Rate Limiting (Bucket4j)*: для защиты API от перегрузки (DoS/DDoS) и brute-force атак реализовано ограничение частоты запросов с использованием Bucket4j на основе IP-адреса и токена пользователя:

  *Листинг 3.8 — Сервис лимитирования запросов RateLimiterService*
  ```java
  @Service
  public class RateLimiterService {
      private final Map<String, Bucket> cache = new ConcurrentHashMap<>();

      public Bucket resolveBucket(String key) {
          return cache.computeIfAbsent(key, k -> Bucket.builder()
              .addLimit(Bandwidth.builder()
                  .capacity(100)
                  .refillGreedy(100, Duration.ofMinutes(1))
                  .build())
              .build());
      }
  }
  ```

  == REST API

  === Спецификация OpenAPI

  API бэкенда полностью документировано по спецификации OpenAPI 3.1 @openapi-spec. Для автоматической генерации Swagger-документации используется библиотека `springdoc-openapi-starter-webmvc-ui`. На клиенте сгенерированная JSON-схема используется для автоматического создания TypeScript SDK (`msocial-js-sdk`) с помощью утилиты `orval`.
