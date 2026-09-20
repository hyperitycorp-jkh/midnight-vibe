#!/bin/bash

# Flutter Boilerplate 앱 생성 스크립트

echo "🚀 Flutter Boilerplate 앱 생성기"
echo "================================"

# 앱 이름 입력
read -p "앱 이름을 입력하세요 (예: my_awesome_app): " APP_NAME
read -p "앱 표시 이름을 입력하세요 (예: My Awesome App): " APP_DISPLAY_NAME
read -p "조직 이름을 입력하세요 (예: com.mycompany): " ORG_NAME

# 템플릿 선택
echo ""
echo "템플릿을 선택하세요:"
echo "1) 기본 (Basic) - AuthGate, User 관리"
echo "2) 고급 (Advanced) - 기본 + 추가 기능들"
echo "3) 최소 (Minimal) - 최소 기능만"
read -p "선택 (1-3): " TEMPLATE_CHOICE

case $TEMPLATE_CHOICE in
  1) TEMPLATE="boilerplate";;
  2) TEMPLATE="boilerplate_advanced";;
  3) TEMPLATE="boilerplate_minimal";;
  *) TEMPLATE="boilerplate";;
esac

# 앱 생성
echo ""
echo "📁 앱을 생성하는 중..."

# Flutter 프로젝트 생성
flutter create --org $ORG_NAME $APP_NAME
cd $APP_NAME

# 템플릿 복사
cp -r ../templates/$TEMPLATE/* .

# pubspec.yaml 수정
sed -i '' "s/name: boilerplate/name: $APP_NAME/g" pubspec.yaml
sed -i '' "s/Boilerplate App/$APP_DISPLAY_NAME/g" pubspec.yaml

# AppConfig 수정
sed -i '' "s/'app_name': 'Boilerplate App'/'app_name': '$APP_DISPLAY_NAME'/g" lib/configs/app_config.dart

# 패키지 경로 수정 (상대 경로로)
sed -i '' "s|path: ../../packages/|path: ../packages/|g" pubspec.yaml

echo ""
echo "✅ 앱 생성 완료!"
echo ""
echo "다음 단계:"
echo "1. cd $APP_NAME"
echo "2. flutterfire configure --project=your-firebase-project"
echo "3. flutter pub get"
echo "4. flutter run"
echo ""
echo "Happy coding! 🎉"