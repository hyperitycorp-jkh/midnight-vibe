# Flutter Boilerplate with AuthGate

Flutter 보일러플레이트 앱 - AuthGate 아키텍처를 활용한 빠른 앱 개발을 위한 템플릿

## 특징

- 🔐 **AuthGate 기반 인증 시스템** - Firebase Auth 자동 상태 관리
- 📁 **깔끔한 아키텍처** - Repository 패턴과 Cubit 상태 관리
- 🎨 **커스터마이징 가능한 UI** - 스플래시, 로그인, 회원가입 페이지
- ⚙️ **AppConfig** - 실시간 원격 설정 지원
- 📝 **코드 규칙** - 일관된 코딩 스타일 가이드

## 시작하기

### 1. Firebase 프로젝트 설정

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 연결
flutterfire configure
```

### 2. 패키지 설치

```bash
flutter pub get
```

### 3. 앱 실행

```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── configs/         # 앱 설정 (AppConfig)
├── models/          # 데이터 모델
├── repositories/    # Firestore CRUD 전담
├── services/        # 외부 API 통합
├── cubits/          # 비즈니스 로직과 상태 관리
├── pages/           # UI 페이지
├── widgets/         # 재사용 가능한 위젯
└── main.dart        # 앱 진입점
```

## 주요 구성 요소

### AuthGate
앱의 인증 상태를 자동으로 관리하며, 로그인/회원가입/메인 페이지로 자동 라우팅

```dart
AuthGate(
  mainTabPageBuilder: () => const PreMainPage(),
  signUpPageBuilder: () => SimpleSignUpPage(
    firebaseUser: FirebaseAuth.instance.currentUser!,
  ),
  loginTitle: AppConfig().appName,
  loginSubtitle: "보일러플레이트 앱에 오신 것을 환영합니다",
  splashWidgetBuilder: () => const CustomSplashWidget(),
  authServiceType: AppConfig().authServiceType,
)
```

### Repository 패턴
하나의 Repository는 하나의 Firestore 컬렉션에 대응하며, CRUD만 담당

```dart
class UserRepository extends BaseRepository<User> {
  // Create
  Future<User> createUser(User user) async { ... }
  
  // Read
  Future<User?> getUser(String uid) async { ... }
  
  // Update
  Future<void> updateUser(User user) async { ... }
  
  // Delete
  Future<void> deleteUser(String uid) async { ... }
}
```

### Model 클래스
모든 Model은 Equatable을 상속하고 다음 메서드들을 구현

```dart
class User extends Equatable {
  // fromJson 생성자
  factory User.fromJson(Map<String, dynamic> json) { ... }
  
  // toJson 메서드
  Map<String, dynamic> toJson() { ... }
  
  // copyWith 메서드
  User copyWith({...}) { ... }
  
  @override
  List<Object?> get props => [...];
}
```

## 커스터마이징

### 1. 새로운 Model 추가
`lib/models/` 폴더에 새 Model 클래스 생성

### 2. 새로운 Repository 추가
`lib/repositories/` 폴더에 BaseRepository를 상속받는 Repository 생성

### 3. 새로운 Cubit 추가
`lib/cubits/` 폴더에 비즈니스 로직을 담당할 Cubit 생성

### 4. AppConfig 설정
Firebase Firestore의 `config/app_settings` 문서를 통해 원격 설정 관리

## 코드 규칙

자세한 코드 규칙은 [CODE_RULES.md](CODE_RULES.md) 파일 참조

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.