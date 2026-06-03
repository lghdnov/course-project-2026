# Тестирование

## 1. Модульное тестирование

### 1.1. Тесты Entity

Тест бизнес-метода `Session.isActive()`:

```java
import lghdnov.msocial.feature.auth.entity.Session;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import static org.assertj.core.api.Assertions.assertThat;

class SessionEntityTest {

    @Test
    void isActive_shouldReturnTrue_whenNotRevokedAndNotExpired() {
        Session session = Session.builder()
            .userId(1L)
            .refreshToken("token")
            .createdAt(Instant.now())
            .refreshTokenExpiresAt(Instant.now().plusSeconds(3600))
            .build();

        assertThat(session.isActive()).isTrue();
    }

    @Test
    void isActive_shouldReturnFalse_whenRevoked() {
        Session session = Session.builder()
            .userId(1L)
            .refreshToken("token")
            .createdAt(Instant.now())
            .refreshTokenExpiresAt(Instant.now().plusSeconds(3600))
            .revokedAt(Instant.now())
            .build();

        assertThat(session.isActive()).isFalse();
    }

    @Test
    void isActive_shouldReturnFalse_whenExpired() {
        Session session = Session.builder()
            .userId(1L)
            .refreshToken("token")
            .createdAt(Instant.now().minusSeconds(7200))
            .refreshTokenExpiresAt(Instant.now().minusSeconds(3600))
            .build();

        assertThat(session.isActive()).isFalse();
    }
}
```

---

### 1.2. Тесты сервисов (Mockito)

#### AuthServiceTest

```java
package lghdnov.msocial.feature.auth.service;

import lghdnov.msocial.common.exceptions.*;
import lghdnov.msocial.feature.auth.api.*;
import lghdnov.msocial.feature.auth.entity.*;
import lghdnov.msocial.feature.auth.presentation.*;
import lghdnov.msocial.feature.user.api.UserProvisioningPort;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.Optional;
import java.util.Set;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private OidcVerificationPort oidcVerificationPort;
    @Mock private UserProvisioningPort userProvisioningPort;
    @Mock private TokenGenerationPort tokenGenerationPort;
    @Mock private SessionManagementPort sessionManagementPort;

    @InjectMocks
    private AuthService authService;

    @Test
    void login_shouldReturnTokens_whenValidOpenIdToken() {
        String openidToken = "valid_token";
        String matrixSub = "@user:example.org";
        Long userId = 1L;
        String accessToken = "access_jwt";
        String refreshToken = "refresh_xyz";

        when(oidcVerificationPort.verifyOpenIdToken(openidToken))
            .thenReturn(new MatrixUserInfo(matrixSub));
        when(userProvisioningPort.findByIdOrCreate(matrixSub)).thenReturn(userId);
        when(userProvisioningPort.isAccountActive(userId)).thenReturn(true);

        Session session = Session.builder().id(10L).userId(userId).build();
        when(sessionManagementPort.createSession(userId)).thenReturn(session);
        when(tokenGenerationPort.generateRefreshToken(10L)).thenReturn(refreshToken);
        when(tokenGenerationPort.generateAccessToken(eq(userId), any(JwtClaims.class)))
            .thenReturn(accessToken);
        when(tokenGenerationPort.getAccessTokenExpirationSeconds()).thenReturn(900L);

        AuthResponse response = authService.login(
            new LoginRequest(openidToken, null));

        assertThat(response.accessToken()).isEqualTo(accessToken);
        assertThat(response.refreshToken()).isEqualTo(refreshToken);
        assertThat(response.expiresIn()).isEqualTo(900L);
        verify(sessionManagementPort).updateRefreshToken(10L, refreshToken);
    }

    @Test
    void login_shouldThrow_whenOpenIdTokenIsBlank() {
        assertThatThrownBy(() -> authService.login(new LoginRequest(" ", null)))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("OpenID токен обязателен");
    }

    @Test
    void refresh_shouldReturnNewTokens_whenValidRefreshToken() {
        String oldRefresh = "old_refresh";
        String newAccess = "new_access";
        String newRefresh = "new_refresh";
        Long userId = 1L;

        Session oldSession = Session.builder().id(10L).userId(userId).build();
        when(sessionManagementPort.findActiveSession(oldRefresh))
            .thenReturn(Optional.of(oldSession));

        Session newSession = Session.builder().id(11L).userId(userId).build();
        when(sessionManagementPort.createSession(userId)).thenReturn(newSession);
        when(tokenGenerationPort.generateRefreshToken(11L)).thenReturn(newRefresh);
        when(tokenGenerationPort.generateAccessToken(eq(userId), any(JwtClaims.class)))
            .thenReturn(newAccess);
        when(tokenGenerationPort.getAccessTokenExpirationSeconds()).thenReturn(900L);

        AuthResponse response = authService.refresh(
            new RefreshRequest(oldRefresh));

        assertThat(response.accessToken()).isEqualTo(newAccess);
        assertThat(response.refreshToken()).isEqualTo(newRefresh);
        verify(sessionManagementPort).revokeSession(10L);
        verify(sessionManagementPort).updateRefreshToken(11L, newRefresh);
    }

    @Test
    void logout_shouldRevokeSession_whenValidRefreshToken() {
        String refreshToken = "valid_refresh";
        Session session = Session.builder().id(10L).userId(1L).build();
        when(sessionManagementPort.findActiveSession(refreshToken))
            .thenReturn(Optional.of(session));

        authService.logout(refreshToken);

        verify(sessionManagementPort).revokeSession(10L);
    }
}
```

Mockito изолирует `AuthService` от реальных зависимостей (Matrix Federation, БД, JWT-криптографии). Тесты проверяют:

- Успешный сценарий `login` с полной оркестрацией
- Валидацию пустого токена
- Ротацию refresh-токена с отзывом старой сессии
- Выход из системы

---

#### TokenServiceTest

```java
package lghdnov.msocial.feature.auth.service;

import io.jsonwebtoken.Claims;
import lghdnov.msocial.common.exceptions.ValidationException;
import lghdnov.msocial.feature.auth.entity.JwtClaims;
import lghdnov.msocial.feature.auth.infrastructure.JwtProvider;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.Set;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TokenServiceTest {

    @Mock private JwtProvider jwtProvider;
    @InjectMocks private TokenService tokenService;

    @Test
    void validateToken_shouldReturnTrue_whenTokenValid() {
        when(jwtProvider.verifySignature("valid")).thenReturn(mock(Claims.class));
        assertThat(tokenService.validateToken("valid")).isTrue();
    }

    @Test
    void validateToken_shouldReturnFalse_whenTokenInvalid() {
        when(jwtProvider.verifySignature("invalid")).thenReturn(null);
        assertThat(tokenService.validateToken("invalid")).isFalse();
    }

    @Test
    void extractClaims_shouldReturnClaims_whenTokenValid() {
        Claims claims = mock(Claims.class);
        when(claims.getSubject()).thenReturn("1");
        when(claims.get("sessionId", Long.class)).thenReturn(10L);
        when(claims.get("roles", Set.class)).thenReturn(Set.of("ROLE_USER"));
        when(jwtProvider.verifySignature("valid")).thenReturn(claims);

        JwtClaims result = tokenService.extractClaims("valid");

        assertThat(result.sub()).isEqualTo("1");
        assertThat(result.sessionId()).isEqualTo(10L);
        assertThat(result.roles()).containsExactly("ROLE_USER");
    }

    @Test
    void extractClaims_shouldThrow_whenTokenInvalid() {
        when(jwtProvider.verifySignature("invalid")).thenReturn(null);
        assertThatThrownBy(() -> tokenService.extractClaims("invalid"))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("Токен повреждён или истёк");
    }
}
```

`JwtProvider` заменяется моком, что позволяет тестировать `TokenService` без реальной криптографии и конфигурации секретных ключей.

---

## 2. Интеграционное тестирование (TestContainers)

```java
package lghdnov.msocial.feature.auth.service;

import lghdnov.msocial.TestcontainersConfiguration;
import lghdnov.msocial.feature.auth.api.AuthCommandPort;
import lghdnov.msocial.feature.auth.presentation.*;
import lghdnov.msocial.feature.user.api.UserProvisioningPort;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.TestPropertySource;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Import(TestcontainersConfiguration.class)
@TestPropertySource(properties = "auth.dev.skip-verify=true")
class AuthServiceIntegrationTest {

    @Autowired
    private AuthCommandPort authCommandPort;

    @Autowired
    private UserProvisioningPort userProvisioningPort;

    @Test
    void login_shouldWork_withDevSkipVerify() {
        LoginRequest request = new LoginRequest("any_token", "@devuser:example.org");

        AuthResponse response = authCommandPort.login(request);

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank();

        Long userId = userProvisioningPort.findByIdOrCreate("@devuser:example.org");
        assertThat(userProvisioningPort.isAccountActive(userId)).isTrue();
    }
}
```

Интеграционный тест поднимает полный контекст Spring Boot с реальной базой данных PostgreSQL в Docker-контейнере (TestContainers). Верификация OIDC отключена (`auth.dev.skip-verify=true`), что позволяет протестировать цепочку «Controller → Service → Repository → БД» без зависимости от внешнего Matrix-сервера.

---

## 3. Покрытие тестами

| Модуль | Тип тестов | Покрытие |
|--------|-----------|----------|
| feature::auth | Unit (Mockito) | Entity, Service |
| feature::auth | Integration (TestContainers) | Полный контекст Spring Boot + БД |
