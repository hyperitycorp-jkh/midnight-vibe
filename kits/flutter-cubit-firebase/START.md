# 이 킷으로 시작하기

```bash
cp -R kits/flutter-cubit-firebase <새-앱-이름>
cd <새-앱-이름>
flutterfire configure          # lib/firebase_options.dart 를 새로 만든다 (.template 는 참고용)
flutter pub get
```

`CODE_RULES.md` 가 이 킷의 규칙이다. 같은 내용이 `conventions/flutter-cubit-firebase.md` 에도 있어
인터뷰가 그것부터 읽고 **이미 정해진 것은 다시 묻지 않는다**.

구조: `lib/{models,repositories,cubits,pages,widgets,configs}`.
repository 는 컬렉션 하나의 CRUD 만, 비즈니스 로직은 전부 cubit.
