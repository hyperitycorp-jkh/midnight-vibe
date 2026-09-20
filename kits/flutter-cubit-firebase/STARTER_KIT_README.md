# Flutter Starter Kit 🚀

프로덕션 준비가 완료된 Flutter 보일러플레이트 및 재사용 가능한 패키지 모음

## 특징 ✨

- 🔐 **Firebase 인증** - 이메일/전화번호 로그인
- 📱 **반응형 UI** - 모바일/태블릿/웹 지원
- 🎨 **테마 시스템** - 다크모드 지원
- 🌐 **다국어 지원** - easy_localization
- 📦 **상태 관리** - Bloc/Cubit 패턴
- 🔥 **Firebase 통합** - Firestore, Storage, Analytics
- 🧩 **재사용 가능한 위젯** - 공통 컴포넌트
- 📏 **코드 규칙** - 일관된 코딩 스타일

## 시작하기 🏁

### 필요 조건

- Flutter 3.7.0 이상
- Dart 3.0.0 이상
- Firebase 프로젝트

### 빠른 시작

```bash
# 저장소 클론
git clone https://github.com/yourusername/flutter-starter-kit.git
cd flutter-starter-kit

# 새 앱 생성
./scripts/create_app.sh

# 또는 수동으로
cp -r templates/boilerplate my_app
cd my_app
flutter pub get
```

## 패키지 구조 📦

### common_utils
- 다이얼로그, 스낵바
- 이미지 처리
- 권한 관리
- 로거
- Excel 내보내기

### firebase_utils
- AuthGate - 인증 플로우 자동 관리
- BaseRepository - Firestore CRUD
- Auth/User Cubits

### app_core (신규)
- 앱 설정 관리
- 테마 시스템
- 라우팅

## 템플릿 종류 🎯

### 1. Basic (기본)
- Firebase 인증
- 사용자 관리
- 탭 네비게이션
- 프로필 관리

### 2. Advanced (고급)
- Basic 기능 +
- 게시판 기능
- 채팅
- 알림
- 결제

### 3. Minimal (최소)
- Firebase 인증만
- 단일 페이지
- 최소 의존성

## 사용 예시 💡

### AuthGate 사용
```dart
AuthGate(
  mainTabPageBuilder: () => const MainTabPage(),
  signUpPageBuilder: () => SignUpPage(
    firebaseUser: FirebaseAuth.instance.currentUser!,
  ),
  loginTitle: '앱 이름',
  splashWidgetBuilder: () => const SplashWidget(),
)
```

### Repository 패턴
```dart
class UserRepository extends BaseRepository<User> {
  UserRepository() : super(
    collectionName: 'users',
    fromJson: (json) => User.fromJson(json),
  );
}
```

## 기여하기 🤝

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 라이선스 📄

MIT License - 자유롭게 사용하세요!

## 문의 📧

- 이메일: your.email@example.com
- 이슈: https://github.com/yourusername/flutter-starter-kit/issues