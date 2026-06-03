# Интерфейсы между слоями

## Control → Mediator (IService)

### UserService

```java
public interface UserService {
    User getUserById(Long id);
    User updateProfile(Long id, ProfileUpdateRequest dto);
    Avatar updateAvatar(Long id, MultipartFile file);
    List<Avatar> getAvatarHistory(Long id);
}
```

### PostService

```java
public interface PostService {
    Post createPost(CreatePostRequest req);
    Post updatePost(Long id, UpdatePostRequest req);
    Post getPost(Long id);
    void deletePost(Long id);
    List<Post> getUserPosts(Long userId);
}
```

### CommentService

```java
public interface CommentService {
    Comment addComment(Long postId, CreateCommentRequest req);
    Comment updateComment(Long id, UpdateCommentRequest req);
    void deleteComment(Long id);
    List<Comment> getPostComments(Long postId);
}
```

### GroupService

```java
public interface GroupService {
    GroupChat createGroup(CreateGroupRequest req);
    GroupChat getGroup(Long id);
    void addMember(Long groupId, Long userId);
    void removeMember(Long groupId, Long userId);
}
```

---

## Mediator → Foundation (IRepository)

### UserRepository

```java
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    boolean existsByUsername(String username);
}
```

### PostRepository

```java
public interface PostRepository extends JpaRepository<Post, Long> {
    List<Post> findByAuthorId(Long authorId);
    List<Post> findAllByOrderByCreatedAtDesc();
}
```

### CommentRepository

```java
public interface CommentRepository extends JpaRepository<Comment, Long> {
    List<Comment> findByPostId(Long postId);
    List<Comment> findByAuthorId(Long authorId);
}
```

### SessionRepository

```java
public interface SessionRepository extends JpaRepository<Session, Long> {
    Optional<Session> findByRefreshToken(String refreshToken);
    void deleteByRefreshToken(String refreshToken);
}
```

---

## Гексагональные порты

### AuthCommandPort

```java
public interface AuthCommandPort {
    AuthResponse login(LoginRequest request);
    AuthResponse refresh(RefreshRequest request);
    void logout(String refreshToken);
}
```

### TokenGenerationPort

```java
public interface TokenGenerationPort {
    String generateAccessToken(Long userId, JwtClaims claims);
    String generateRefreshToken(Long sessionId);
    long getAccessTokenExpirationSeconds();
}
```

### TokenValidationPort

```java
public interface TokenValidationPort {
    boolean validateToken(String token);
    JwtClaims extractClaims(String token);
}
```

### SessionManagementPort

```java
public interface SessionManagementPort {
    Session createSession(Long userId);
    void revokeSession(Long sessionId);
    Optional<Session> findActiveSession(String refreshToken);
    void updateRefreshToken(Long sessionId, String refreshToken);
}
```

### OidcVerificationPort

```java
public interface OidcVerificationPort {
    MatrixUserInfo verifyOpenIdToken(String openidToken);
}
```

### AvatarStoragePort

```java
public interface AvatarStoragePort {
    String store(MultipartFile file);
    byte[] load(Long id);
    void delete(Long id);
}
```
