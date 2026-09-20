import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'package:firebase_utils/firebase_utils.dart';
import 'package:firebase_utils/pages/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 앱 페이지들
import 'pages/main_tab_page.dart';
import 'pages/simple_sign_up_page.dart';
import 'widgets/custom_splash_widget.dart';

// 설정
import 'configs/app_config.dart';

// Repository
import 'repositories/user_repository.dart';

// Cubits
import 'cubits/app_user_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // AppConfig 초기화
  await AppConfig().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Repository 인스턴스 생성
    final userRepository = UserRepository();

    return MultiRepositoryProvider(
      providers: [
        // 앱의 UserRepository 제공
        RepositoryProvider<UserRepository>(create: (context) => userRepository),
        // firebase_utils가 필요로 하는 Repository들 제공
        ...FirebaseUtils.repositoryProviders(userRepository: userRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // FirebaseUtils에서 제공하는 기본 Cubit들
          ...FirebaseUtils.blocProviders(),
          // 앱 전용 User Cubit
          BlocProvider<AppUserCubit>(create: (context) => AppUserCubit(authUserCubit: context.read<AuthUserCubit>())),
        ],
        child: MaterialApp(
          title: AppConfig().appName,
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
          home: AuthGate(
            mainTabPageBuilder: () => const MainTabPage(),
            signUpPageBuilder: () => SimpleSignUpPage(firebaseUser: FirebaseAuth.instance.currentUser!),
            loginTitle: AppConfig().appName,
            loginSubtitle: "보일러플레이트 앱에 오신 것을 환영합니다",
            splashWidgetBuilder: () => const CustomSplashWidget(),
            authServiceType: AppConfig().authServiceType,
          ),
        ),
      ),
    );
  }
}
