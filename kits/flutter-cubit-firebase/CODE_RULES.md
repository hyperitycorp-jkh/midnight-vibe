# 코드 규칙

## 1. Repository 패턴
- **하나의 Repository는 하나의 컬렉션에만 대응**
- **오직 CRUD만 담당** (Create, Read, Update, Delete)
- 여러 컬렉션 조합, 상태 변경 등 비즈니스 로직은 절대 포함하지 않음

## 2. Model 사용
- Repository 함수의 파라미터와 반환값은 **반드시 Model 객체로 통일**
- 각 Model은 다음을 구현:
  - `fromJson()`
  - `toJson()`
  - `copyWith()`
  - `Equatable` 상속

## 3. Enum 사용
- 하드코딩된 문자열 대신 **enum 사용**
- 상태 필드 등은 enum으로 정의
- 일관된 값 관리와 오류 방지

## 4. Cubit/State 패턴
- State는 `Equatable` 상속
- 상태는 Enum으로 관리
- 모든 비즈니스 로직은 Cubit에서 처리

## 5. 콜백함수 사용 최대한 금지

## 6. 코드 재사용
- 재활용 가능한 수준의 공통함수 추출
- 활용도가 높은 경우 위젯으로 분리

## 7. 프로젝트 구조
```
lib/
├── models/          # 전체 데이터 모델
├── repositories/    # Firestore CRUD 전담 (비즈니스 로직 금지)
├── services/        # 외부 API 통합 (Firebase Auth, Gemini, Storage 등)
├── cubits/          # 모든 비즈니스 로직과 상태 관리
├── pages/           # UI 페이지
├── widgets/         # 재사용 가능한 위젯
└── config/            # 앱 전체 설정, 상수, 유틸리티
```

## 8. 코딩 스타일
- 작은 유틸리티 함수는 **private 메서드로 분리**
- 로깅은 `Log.d()` / `Log.e()` 사용
- **try-catch로 세분화된 에러 처리**
- 불필요한 주석 최소화
- **Cubit 패턴으로 상태 관리**
- **워닝(Warning)이 발생하는 코드는 사용 금지** - 워닝 해결 후 커밋

## 9. 신규 Flutter 문법
- `withOpacity()` 대신 **`withAlpha()` 사용**
- nullable 타입은 `!` 대신 **null 체크 후 사용**

## 10. 데이터베이스
- **집계쿼리를 쓸 수 있으면 적극 활용**

## 11. 디자인
- **플랫 디자인 선호**

## 12. 아키텍처 원칙
- **Repository**: 순수하게 데이터 액세스만 담당 (Firestore CRUD)
- **Service**: 외부 API 통합 (상태 관리 없음, 단순 호출)
- **Cubit**: 모든 비즈니스 로직 처리 (Repository + Service 조합)
- **UI**: 화면 렌더링에만 집중
- 함수 반환값이 Map인 경우 **클래스로 생성**

## 13. Service와 Repository 구분

### Repository
- Firestore 컬렉션과 1:1 대응
- CRUD만 담당

### Service
- 외부 API 통합 (Gemini, Firebase Auth, Storage 등)

### 예시
```dart
// Repository 예시
class UserRepository {
  // users 컬렉션 CRUD만 담당
  Future<User> createUser(User user) async { ... }
  Future<User?> getUser(String userId) async { ... }
  Future<void> updateUser(User user) async { ... }
  Future<void> deleteUser(String userId) async { ... }
}

// Service 예시
class FirebaseAuthService {
  // Firebase Auth API 호출만 담당
  Future<UserCredential> signInWithEmail(String email, String password) async { ... }
  Future<void> signOut() async { ... }
}

// Cubit 예시
class AuthCubit extends Cubit<AuthState> {
  // Repository와 Service를 조합하여 비즈니스 로직 처리
  final UserRepository _userRepository;
  final FirebaseAuthService _authService;
  
  Future<void> signIn(String email, String password) async {
    // 1. Auth Service로 로그인
    // 2. Repository에서 사용자 정보 조회
    // 3. 상태 업데이트
  }
}
```