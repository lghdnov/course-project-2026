# msocial — Matrix Social Network

**Автор:** Иванов Дмитрий Романович  
**Группа:** ПИЖ-б-о-23-2  
**Траектория:** Enterprise  
**Дата начала:** 11.05.2026  
**Дата сдачи:** 30.05.2026

---

## Описание проекта

**msocial** это система управления профилем пользователя и групповыми чатами для мессенджера на базе протокола Matrix. Предоставляет функционал управления профилем (аватар, персональные данные, публикации), групповыми чатами (алиасы, управление участниками) и сообществами. Архитектура реализована по принципу feature-first с адаптацией классического PCMEF под гексагональные принципы.

---

## Траектория выполнения

- [x] Enterprise

---

## Технологический стек

| Компонент       | Технология                                      |
|-----------------|-------------------------------------------------|
| Бэкенд          | Java 25, Spring Boot 3.x, Gradle                |
| База данных     | PostgreSQL, Flyway migrations                   |
| API             | REST, OpenAPI 3.1 (Swagger / Scalar UI)         |
| Безопасность    | JWT (jjwt), Matrix OpenID Federation            |
| Кэширование     | Caffeine                                        |
| Сборка          | Gradle, Docker                                  |
| Контейнеризация | Docker (multi-stage Alpine JRE)                 |
| Деплой          | Helm 3, Kubernetes 1.25+                        |
| SDK             | TypeScript / JavaScript (orval, axios)          |
| Инструменты     | Git, Postman, JaCoCo, TestContainers, WireMock  |

---

## Требования к окружению

| Требование           | Версия |
|----------------------|--------|
| Java JDK             | 21+    |
| Gradle               | 8.5+   |
| PostgreSQL           | 15+    |
| Docker (опционально) | 24+    |
| Kubernetes           | 1.25+  |
| Helm                 | 3.10+  |

---

## Установка и запуск

### 1. Клонирование репозитория

```bash
git clone --recurse-submodules https://github.com/lghdnov/CourseProject-2026.git
cd CourseProject-2026
```

### 2. Запуск бэкенда (локально)

```bash
cd msocial
./gradlew bootRun
```

Сервер запустится на <http://localhost:8080>

Scalar UI: <http://localhost:8080/scalar>

### 3. Запуск через Docker

```bash
cd msocial
docker build -t glitchcat/msocial:local .
docker run -p 8080:8080 -e SPRING_PROFILES_ACTIVE=dev glitchcat/msocial:local
```

### 4. Деплой в Kubernetes через Helm

```bash
helm dependency update ./msocial-helm
helm install msocial ./msocial-helm \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=SuperSecretPassword123 \
  --set app.jwt.secret=MyVeryStrongJWTSecretKeyForProd
```

### 5. Использование SDK

```bash
npm install msocial-js-sdk axios
```

```typescript
import { createMsocialClient } from 'msocial-js-sdk';
const client = createMsocialClient('https://api.example.com');
const { data } = await client.auth.login({ openidToken: 'matrix-token' });
client.setAuth(data);
const profile = await client.users.getProfile();
```

---

## Структура документации

Вся документация находится в папке [docs/](docs/):

| Раздел | Содержимое |
|--------|-----------|
| [00-project-charter/](docs/00-project-charter/) | Паспорт проекта, IDEF0, BUC, SWOT, ROI |
| [01-requirements/](docs/01-requirements/) | Use Case, Domain Model, бизнес-правила |
| [02-architecture/](docs/02-architecture/) | PCMEF, ADR, интерфейсы |
| [03-database/](docs/03-database/) | ER-диаграмма, DDL, ORM |
| [04-detailed-design/](docs/04-detailed-design/) | Sequence диаграммы, спецификация методов |
| [05-implementation/](docs/05-implementation/) | Реализация слоёв |
| [06-testing/](docs/06-testing/) | Тест-планы, JaCoCo, Postman |
| [07-refactoring/](docs/07-refactoring/) | «Запахи кода», Data Mapper, Identity Map |
| [08-ui/](docs/08-ui/) | Скриншоты интерфейсов |
| [09-api/](docs/09-api/) | OpenAPI, Swagger |
| [10-deployment/](docs/10-deployment/) | Docker, CI/CD, администрирование |
| [11-user-guide/](docs/11-user-guide/) | Руководство пользователя |
| [12-final-report/](docs/12-final-report/) | Пояснительная записка, презентация |

---

## Архитектура (PCMEF)

Система построена на архитектурном паттерне PCMEF (Presentation-Control-Mediator-Entity-Foundation) с адаптацией под feature-first и гексагональные принципы.

Распределение слоёв:

| Слой             | Расположение | Ответственность              |
|------------------|-------------|------------------------------|
| Presentation (P) | DTO / SDK   | Форматы данных API           |
| Control (C)      | Spring Boot | REST API, валидация DTO      |
| Mediator (M)     | Spring Boot | Бизнес-логика, транзакции    |
| Entity (E)       | Spring Boot | JPA-сущности                 |
| Foundation (F)   | Spring Boot | Репозитории, доступ к БД     |

Ключевые ADR:

- [ADR-001: Выбор архитектурного паттерна](docs/02-architecture/adr/adr-001.md)
- [ADR-002: Выбор базы данных и ORM](docs/02-architecture/adr/adr-002.md)
- [ADR-003: Стратегия аутентификации](docs/02-architecture/adr/adr-003.md)

---

## Статистика разработки

### Git метрики

| Метрика                   | Значение                |
|---------------------------|-------------------------|
| Всего коммитов            | 15                      |
| Период разработки         | 11.05.2026 – 30.05.2026 |
| Средняя частота           | ~5 коммитов/неделю      |

---

## Авторы

- Иванов Дмитрий Романович — разработчик, документация  
  Группа ПИЖ-б-о-23-2, GitHub: [lghdnov](https://github.com/lghdnov)
