  = Проектная часть

== Модель требований к ПО

=== Use Case диаграмма

Диаграмма вариантов использования определяет три актора и десять прецедентов:

- *Акторы:* Пользователь, Администратор группы, Система.
- *Прецеденты:* управление профилем, управление публикациями, комментирование, управление персональной информацией, история аватаров, управление группами, назначение алиасов, изменение имени участника, тег сообщества, список сообществ.

#figure(image("images/01-requirements/usecase.png", width: 90%), caption: [Диаграмма Use Case]) <usecase>

=== Спецификация прецедентов

Ключевые прецеденты детализированы в соответствии с шаблоном RUP:

*UC3: Управление публикациями*
- Предусловия: пользователь авторизован, имеет права на публикацию, контент в пределах лимитов.
- Постусловия: публикация создана, отображается в ленте, уведомления отправлены подписчикам.
- Основной поток: создание → валидация → сохранение → отображение.
- Исключения: ошибка загрузки медиа, нарушение правил контента, превышение дневного лимита.

*UC4: Управление персональной информацией*
- Предусловия: пользователь авторизован, профиль доступен для редактирования.
- Постусловия: данные сохранены, профиль обновлён для всех пользователей.
- Основной поток: открытие формы → загрузка текущих значений → редактирование → валидация → сохранение.
- Исключения: ошибка валидации (некорректный формат), ошибка сервера, доступ запрещён.

=== Глоссарий терминов
Ключевые термины определены на основе спецификации Matrix @matrix-spec и методологии DDD @evans2004domain.

#figure(
  table(
    columns: 2,
    align: (left, left),
    stroke: 0.5pt,
    inset: 5pt,
    table.header([*Термин*], [*Определение*]),
    [Matrix ID], [Уникальный идентификатор пользователя в федеративной сети Matrix (например, \@user:example.org).],
    [OpenID Token], [Токен аутентификации, выдаваемый Matrix-сервером для верификации личности пользователя.],
    [Alias], [Отображаемое имя или роль пользователя в контексте конкретной группы.],
    [Community Tag], [Постфикс, автоматически добавляемый к имени пользователя при публикации от имени сообщества.],
    [Soft Delete], [Маркировка записи как удалённой без физического удаления из базы данных.],
    [JWT], [JSON Web Token — токен доступа, содержащий claims пользователя и сессии.],
    [PCMEF], [Presentation-Control-Mediator-Entity-Foundation — паттерн многослойной архитектуры.],
  ),
  caption: [Глоссарий терминов предметной области],
)

== Модель предметной области

=== Domain Model (диаграмма классов)

Domain Model построена с использованием многоуровневой архитектуры, характерной для enterprise-приложений на платформе Spring. Модель включает шесть слоёв:

1. Controller Layer — обработка HTTP запросов, валидация, маппинг DTO.
2. Service Layer — бизнес-логика, транзакции, оркестрация репозиториев.
3. Repository Layer — доступ к данным, CRUD операции.
4. Entity Layer — модели данных, маппинг на таблицы БД.
5. DTO Layer — передача данных между слоями.
6. Exception Layer — обработка ошибок и HTTP статусов.

Ключевые сущности: `User`, `PersonalInfo`, `Avatar`, `Post`, `Comment`, `GroupChat`, `GroupMember`, `Community`.

#figure(image("images/01-requirements/domain_model.png", width: 90%), caption: [Domain Model — модель предметной области]) <domain-model>

=== Описание сущностей и атрибутов

#figure(
  table(
    columns: 4,
    align: (left, left, left, left),
    stroke: 0.5pt,
    inset: 4pt,
    table.header([*Слой*], [*Компоненты*], [*Ответственность*], [*Аннотации Spring*]),
    [Controller], [`UserController`, `PostController`, `AdminController`, `CommunityController`], [Обработка HTTP запросов, валидация, маппинг DTO], [`@RestController`, `@RequestMapping`, `@GetMapping`, `@PostMapping`],
    [Service], [`UserService`, `PostService`, `CommentService`, `GroupService`, `CommunityService`], [Бизнес-логика, транзакции, оркестрация], [`@Service`, `@Transactional`],
    [Repository], [`UserRepository`, `PostRepository`, `AvatarRepository`, `GroupMemberRepository`, `CommunityRepository`], [Доступ к данным, CRUD], [`@Repository`, `extends JpaRepository`],
    [Entity], [`User`, `PersonalInfo`, `Avatar`, `Post`, `Comment`, `GroupChat`, `GroupMember`, `Community`], [Модель данных, ORM-маппинг], [`@Entity`, `@Table`, `@Id`, `@ManyToOne`, `@OneToOne`],
    [DTO], [`UserDTO`, `PostDTO`, `PersonalInfoDTO`, `AvatarDTO`, `GroupMemberDTO`], [Передача данных, скрытие внутренней структуры], [Plain Java Classes],
    [Exception], [`ValidationException`, `NotFoundException`, `AccessDeniedException`], [Обработка ошибок, HTTP статусы], [`@ResponseStatus`, `@ControllerAdvice`],
  ),
  caption: [Описание слоёв и компонентов Domain Model],
)

=== Бизнес-правила

#figure(
  table(
    columns: 3,
    align: (left, left, left),
    stroke: 0.5pt,
    inset: 5pt,
    table.header([*Правило*], [*Описание*], [*Последствия нарушения*]),
    [BR-001], [Один пользователь = один активный аватар], [Конфликт отображения профиля],
    [BR-002], [Алиас может назначить только администратор группы], [Нарушение прав доступа],
    [BR-003], [Личная группа может быть только одна на пользователя], [Конфликт приватного пространства],
    [BR-004], [Тег сообщества отображается только для активных участников], [Некорректная информация о членстве],
    [BR-005], [Изменение имени в группе не влияет на глобальное имя], [Путаница в идентификации пользователя],
  ),
  caption: [Бизнес-правила и ограничения предметной области],
)

== Архитектурное проектирование
=== Выбор архитектурного стиля
Архитектурный паттерн PCMEF выбран по следующим причинам @fowler2002patterns:

1. *Чёткое разделение ответственности* — пять строго определённых слоёв исключают дублирование функциональности.
2. *Однонаправленная направленность зависимостей* — каждый слой зависит только от нижележащего, что гарантирует отсутствие циклических связей.
3. *Совместимость с Spring-экосистемой* — слои PCMEF естественным образом отображаются на стандартные аннотации Spring.
4. *Возможность адаптации* — PCMEF допускает модификацию под конкретную предметную область без потери основных принципов.
5. *Проверенная практика* — паттерн широко применяется в enterprise-приложениях.

=== Диаграмма пакетов (PCMEF)

Система организована по бизнес-фичам (feature-first), внутри каждой из которых присутствуют собственные PCMEF-слои:

```
com.app.backendapi
├── feature/
│   ├── user/        (dto, controller, service, entity, repository)
│   ├── post/        (аналогично)
│   ├── comment/     (аналогично)
│   ├── group/       (аналогично)
│   └── community/   (аналогично)
├── common/
│   ├── exceptions/  (BaseException, ValidationException, NotFoundException)
│   ├── security/    (AuthFilter, JwtProvider, SecurityConfig)
│   ├── config/      (WebMvcConfig, SwaggerConfig, DBConfig)
│   └── utils/       (DateUtil, StringUtils, ValidatorUtil)
```

#figure(image("images/02-architecture/PCMEF_backend_layer.png", width: 90%), caption: [Диаграмма пакетов PCMEF backend-слоя]) <pcmef-packages>

=== Описание слоёв и их ответственности

#figure(
  table(
    columns: 3,
    align: (left, left, left),
    stroke: 0.5pt,
    inset: 5pt,
    table.header([*Слой PCMEF*], [*Компоненты проекта*], [*Назначение*]),
    [Presentation], [`UserDTO`, `PostDTO`, `CommentDTO`, `PostCreateRequest`, `PostUpdateRequest`, `CommentRequest`], [Форматы данных API, маппинг запросов/ответов],
    [Control], [`UserController`, `PostController`, `PostCommentController`, `GroupController`, `AdminGroupController`, `CommunityController`], [Обработка HTTP-запросов, валидация, маршрутизация],
    [Mediator], [`UserService`, `PostService`, `CommentService`, `GroupService`, `CommunityService`, `AvatarService`, `MediaProcessor`, `TagGenerator`, `ProfileValidator`, `ContentValidator`], [Бизнес-логика, транзакции, оркестрация],
    [Entity], [`User`, `Post`, `Comment`, `GroupChat`, `GroupMember`, `Community`, `PersonalInfo`, `Avatar`, `MediaType`], [Модели предметной области, ORM-маппинг],
    [Foundation], [`UserRepository`, `PostRepository`, `PostMediaRepository`, `CommentRepository`, `GroupChatRepository`, `GroupMemberRepository`, `CommunityRepository`, `AvatarRepository`, `PersonalInfoRepository`], [Доступ к данным, CRUD-операции],
  ),
  caption: [Распределение компонентов по слоям PCMEF],
)

#figure(image("images/02-architecture/infra.png", width: 90%), caption: [Диаграмма инфраструктуры и развёртывания]) <infra>

=== Архитектурные решения (ADR)

*ADR-001: Выбор архитектурного паттерна PCMEF*
- Контекст: необходимо обеспечить чёткое разделение ответственности и масштабируемость.
- Решение: использовать PCMEF с адаптацией под feature-first.
- Последствия: упрощение навигации по коду, независимое тестирование фич, возможность выделения микросервисов.

*ADR-002: Выбор базы данных и ORM*
- Контекст: требуется надёжное хранение реляционных данных с поддержкой транзакций.
- Решение: PostgreSQL + Spring Data JPA @postgresql-docs.
- Последствия: стандартизация доступа к данным, миграции через Flyway.

*ADR-003: Стратегия аутентификации*
- Контекст: интеграция с существующей Matrix-инфраструктурой.
- Решение: Matrix OpenID Federation + внутренние JWT (access/refresh).
- Последствия: единый вход для Matrix-пользователей, stateless API, ротация токенов.

#figure(image("images/02-architecture/interfaces.png", width: 90%), caption: [Диаграмма интерфейсов (Ports \& Adapters)]) <interfaces>

== Проектирование базы данных

=== ER-диаграмма

Логическая модель данных включает восемь сущностей:

- `users` — центральная сущность, 1:1 с `personal_infos`, 1:N с `avatars`, `posts`, `comments`, `personal_groups`.
- `personal_infos` — личная информация пользователя (дата рождения, адрес, статус, любимый трек).
- `avatars` — история загрузок аватаров с флагом `is_current`.
- `communities` — сообщества с уникальным тегом.
- `group_members` — ассоциативная сущность M:N между `communities` и `users`, содержит алиас и переопределение имени.
- `posts` — публикации с типом медиа и ссылкой на контент.
- `comments` — комментарии к постам, древовидная структура через `parent_id`.
- `personal_groups` — личные группы пользователей.

=== Физическая модель данных

Нормализация выполнена до третьей нормальной формы (3НФ):

- 1НФ: все атрибуты атомарны, типы приведены к SQL-типам.
- 2НФ: все сущности имеют суррогатный ключ `id`, частичные зависимости отсутствуют.
- 3НФ: добавлены UNIQUE ограничения для гарантии 1:1 связи (`personal_infos.user_id`), частичный индекс для активного аватара, уникальный композитный ключ (`group_members.group_id`, `group_members.user_id`).

=== DDL-скрипты

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE
);

CREATE TABLE personal_infos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE,
    birthday DATE,
    address VARCHAR(255),
    favorite_track_url VARCHAR(512),
    status VARCHAR(255),
    CONSTRAINT fk_personal_info_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE avatars (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    image_url VARCHAR(512) NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_avatar_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX idx_current_avatar ON avatars(user_id) WHERE is_current = TRUE;

CREATE TABLE communities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    tag VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE group_members (
    id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    alias VARCHAR(100),
    display_name_override VARCHAR(100),
    CONSTRAINT fk_member_group FOREIGN KEY (group_id)
        REFERENCES communities(id) ON DELETE CASCADE,
    CONSTRAINT fk_member_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_group_member UNIQUE(group_id, user_id)
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL,
    content TEXT,
    media_type VARCHAR(20) CHECK (media_type IN ('text', 'image', 'video', 'audio', 'link')),
    media_url VARCHAR(512),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_post_author FOREIGN KEY (author_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_comment_post FOREIGN KEY (post_id)
        REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_author FOREIGN KEY (author_id)
        REFERENCES users(id) ON DELETE CASCADE
);
```

== Детальное проектирование

=== Диаграммы последовательности

Для детального проектирования выбраны три ключевых сценария:

1. *UC4: Управление персональной информацией* — редактирование профиля с валидацией и частичным обновлением.
2. *UC3: Создание публикации* — создание поста с валидацией контента и сохранением в БД.
3. *UC3-2a: Загрузка и валидация медиафайлов* — циклическая обработка файлов с ветвлением по результатам валидации.

Взаимодействие объектов следует направлению PCMEF: Presentation → Controller → Mediator → Foundation → Entity.

#figure(image("images/04-detailed-design/uc4.png", width: 90%), caption: [Диаграмма последовательности UC4: основной поток сохранения профиля]) <uc4>

#figure(image("images/04-detailed-design/uc4_alt.png", width: 90%), caption: [Диаграмма последовательности UC4: альтернативные потоки]) <uc4-alt>

#figure(image("images/04-detailed-design/uc3-1.png", width: 90%), caption: [Диаграмма последовательности UC3-1: создание публикации]) <uc3-1>

#figure(image("images/04-detailed-design/uc3-2a.png", width: 90%), caption: [Диаграмма последовательности UC3-2a: обработка медиафайлов]) <uc3-2a>

#figure(image("images/04-detailed-design/uc3-2b.png", width: 90%), caption: [Диаграмма последовательности UC3-2b: проверка лимитов]) <uc3-2b>

=== Диаграммы классов проектирования

Уточнённая диаграмма классов разделена на доменные модули (feature-first):

- `feature::user` — порты `UserQueryPort`, `UserCommandPort`, `AvatarStoragePort`; сервисы `UserService`, `AvatarService`; валидатор `ProfileValidator`.
- `feature::auth` — порты `AuthCommandPort`, `TokenValidationPort`, `OidcVerificationPort`, `TokenGenerationPort`, `SessionManagementPort`; адаптер `MatrixFederationAdapter`.
- `feature::post` — порты `PostQueryPort`, `PostCommandPort`, `MediaProcessorPort`; валидатор `ContentValidator`.
- `feature::comment` — порты `CommentQueryPort`, `CommentCommandPort`, `PostContextPort`; валидатор `CommentValidator`.

#figure(image("images/04-detailed-design/feature_user.png", width: 90%), caption: [Диаграмма классов: управление пользователями]) <feature-user>

#figure(image("images/04-detailed-design/feature_auth.png", width: 90%), caption: [Диаграмма классов: аутентификация]) <feature-auth>

#figure(image("images/04-detailed-design/feature_post.png", width: 90%), caption: [Диаграмма классов: публикации]) <feature-post>

#figure(image("images/04-detailed-design/feature_comment.png", width: 90%), caption: [Диаграмма классов: комментарии]) <feature-comment>

=== Применение паттернов GoF
*Builder* — конструирование DTO и запросов с множеством опциональных полей через Lombok `@Builder`, реализующее паттерн GoF @gamma1995design.
*Decorator* — кеширование, rate-limiting и метрики для портов через декорирование интерфейсов (`CachedUserQueryPort`).

*Chain of Responsibility* — валидация комментариев и постов через цепочку обработчиков (`LengthValidator` → `SpamValidator` → `ToxicityValidator`).

*Adapter* — интеграция внешних систем (Matrix Federation, S3) через адаптеры (`MatrixFederationAdapter`, `MediaStorageAdapter`).

*Builder* — конструирование DTO и запросов с множеством опциональных полей через Lombok `@Builder`.

