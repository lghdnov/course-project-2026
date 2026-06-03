# Документация API

## 1. Общая информация

- **Базовый URL:** `http://localhost:8080/api/v1`
- **Формат:** REST / JSON
- **Аутентификация:** Bearer-токен (JWT access-token)
- **Документация:** Scalar UI доступен по адресу `http://localhost:8080/scalar`
- **OpenAPI Spec:** `msocial-js-sdk/schema.yaml`

---

## 2. Эндпоинты по модулям

### 2.1. Auth (Аутентификация)

Базовый путь: `/api/v1/auth`

| Метод | Путь | Описание | Авторизация |
|-------|------|----------|-------------|
| POST | `/login` | Вход по Matrix OpenID токену | Публичный |
| POST | `/refresh` | Обновление пары токенов | Публичный |
| POST | `/logout` | Выход из системы | Публичный (требует refresh-токен) |
| GET | `/validate` | Валидация access-токена | Bearer |

**LoginRequest:**

```json
{
  "openidToken": "openid_token_xyz",
  "userId": "@user:example.org"
}
```

**AuthResponse:**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "refreshToken": "dB9xK2mP...",
  "expiresIn": 900
}
```

---

### 2.2. Users (Пользователи)

Базовый путь: `/api/v1/users`

| Метод | Путь | Описание | Авторизация |
|-------|------|----------|-------------|
| GET | `/profile` | Получить профиль текущего пользователя | Bearer |
| PUT | `/profile` | Обновить профиль | Bearer |

**ProfileUpdateRequest:**

```json
{
  "displayName": "Иван Иванов",
  "status": "В сети",
  "birthday": "2000-01-15",
  "address": "г. Москва",
  "favoriteTrackUrl": "https://music.example.com/track/123"
}
```

**UserDTO:**

```json
{
  "id": 1,
  "username": "ivanov",
  "displayName": "Иван Иванов",
  "createdAt": "2026-05-11T10:00:00Z",
  "lastActive": "2026-05-30T14:30:00Z"
}
```

---

### 2.3. Posts (Публикации)

Базовый путь: `/api/v1/posts`

| Метод | Путь | Описание | Авторизация |
|-------|------|----------|-------------|
| GET | `/` | Список постов | Bearer |
| POST | `/` | Создать пост | Bearer |
| GET | `/{id}` | Получить пост по ID | Bearer |
| PUT | `/{id}` | Обновить пост | Bearer (автор) |
| DELETE | `/{id}` | Удалить пост | Bearer (автор) |

**CreatePostRequest:**

```json
{
  "content": "Привет, мир!",
  "mediaType": "TEXT",
  "mediaUrls": []
}
```

**PostDTO:**

```json
{
  "id": 1,
  "authorId": 1,
  "content": "Привет, мир!",
  "mediaType": "TEXT",
  "mediaUrl": null,
  "createdAt": "2026-05-30T10:00:00Z"
}
```

---

### 2.4. Comments (Комментарии)

Базовый путь: `/api/v1/posts/{postId}/comments`

| Метод | Путь | Описание | Авторизация |
|-------|------|----------|-------------|
| GET | `/posts/{postId}/comments` | Список комментариев | Bearer |
| POST | `/posts/{postId}/comments` | Создать комментарий | Bearer |
| PUT | `/comments/{id}` | Обновить комментарий | Bearer (автор) |
| DELETE | `/comments/{id}` | Удалить комментарий | Bearer (автор) |

**CreateCommentRequest:**

```json
{
  "content": "Отличный пост!"
}
```

**CommentDTO:**

```json
{
  "id": 1,
  "postId": 1,
  "authorId": 2,
  "content": "Отличный пост!",
  "createdAt": "2026-05-30T11:00:00Z"
}
```

---

### 2.5. Echo (Тестовые запросы)

Базовый путь: `/api/v1/echo`

| Метод | Путь | Описание | Авторизация |
|-------|------|----------|-------------|
| GET | `/` | Эхо-запрос для проверки работоспособности | Публичный |

---

## 3. Использование SDK

### 3.1. Установка

```bash
npm install msocial-js-sdk axios
```

### 3.2. Быстрый старт

```typescript
import { createMsocialClient } from 'msocial-js-sdk';

const client = createMsocialClient('https://api.example.com');

// 1. Авторизация
const { data } = await client.auth.login({ openidToken: 'matrix-token' });

// 2. Сохраняем сессию
client.setAuth(data);

// 3. Запросы с автоматической авторизацией
const profile = await client.users.getProfile();
const posts = await client.posts.getPosts();

// 4. При 401 клиент автоматически обновит access-токен через refresh
//    и повторит запрос. Параллельные запросы встают в очередь.

// 5. Выход
await client.auth.logout();
client.clearAuth();
```

### 3.3. Модули SDK

| Модуль | Методы SDK | Описание |
|--------|-----------|----------|
| `auth` | `client.auth.login()`, `client.auth.refresh()`, `client.auth.logout()` | Аутентификация |
| `users` | `client.users.getProfile()`, `client.users.updateProfile()` | Профиль пользователя |
| `posts` | `client.posts.getPosts()`, `client.posts.createPost()`, `client.posts.getPost(id)` | Публикации |
| `comments` | `client.comments.getComments(postId)`, `client.comments.createComment(...)` | Комментарии |
| `echo` | `client.echo.getEcho()` | Тестовые запросы |

### 3.4. CommonJS

```javascript
const { createMsocialClient } = require('msocial-js-sdk');
const client = createMsocialClient('https://api.example.com');
client.posts.getPost(1).then(({ data }) => {
  console.log(data);
});
```

---

## 4. Модели данных (DTO)

### 4.1. Auth

```typescript
interface LoginRequest {
  openidToken: string;
  userId?: string;
}

interface RefreshRequest {
  refreshToken: string;
}

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}
```

### 4.2. Users

```typescript
interface UserDTO {
  id: number;
  username: string;
  displayName: string;
  createdAt: string;
  lastActive?: string;
}

interface ProfileUpdateRequest {
  displayName?: string;
  status?: string;
  birthday?: string;
  address?: string;
  favoriteTrackUrl?: string;
}
```

### 4.3. Posts

```typescript
interface PostDTO {
  id: number;
  authorId: number;
  content: string;
  mediaType: 'TEXT' | 'IMAGE' | 'VIDEO' | 'AUDIO' | 'LINK';
  mediaUrl?: string;
  createdAt: string;
}

interface CreatePostRequest {
  content: string;
  mediaType?: string;
  mediaUrls?: string[];
}
```

### 4.4. Comments

```typescript
interface CommentDTO {
  id: number;
  postId: number;
  authorId: number;
  content: string;
  createdAt: string;
}

interface CreateCommentRequest {
  content: string;
}
```

---

## 5. Обработка ошибок

Все ошибки возвращаются в едином формате:

```json
{
  "code": "VALIDATION_ERROR",
  "message": "OpenID токен обязателен",
  "timestamp": "2026-05-30T12:00:00Z"
}
```

| HTTP код | Код ошибки | Описание |
|----------|-----------|----------|
| 400 | `VALIDATION_ERROR` | Ошибка валидации входных данных |
| 401 | `UNAUTHORIZED` | Пользователь не аутентифицирован |
| 403 | `ACCESS_DENIED` | Доступ запрещён |
| 404 | `NOT_FOUND` | Ресурс не найден |
| 429 | `RATE_LIMITED` | Превышен лимит запросов |
| 500 | `INTERNAL_ERROR` | Внутренняя ошибка сервера |
