import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_utils/cubit/auth_user/auth_user_cubit.dart';
import '../models/user.dart';

part 'app_user_state.dart';

/// AuthUserCubit 위에 앱 전용 User 모델을 사용하는 Cubit
class AppUserCubit extends Cubit<AppUserState> {
  final AuthUserCubit _authUserCubit;
  
  AppUserCubit({required AuthUserCubit authUserCubit}) 
    : _authUserCubit = authUserCubit,
      super(const AppUserState()) {
    // AuthUserCubit의 상태 변경 감지
    _authUserCubit.stream.listen(_onAuthUserStateChanged);
    // 초기 상태 처리
    _onAuthUserStateChanged(_authUserCubit.state);
  }

  void _onAuthUserStateChanged(AuthUserState authState) {
    if (authState.status == AuthUserStatus.authUser && authState.userJson != null) {
      try {
        // JSON을 User 모델로 변환
        final user = User.fromJson(authState.userJson!);
        emit(state.copyWith(
          status: AppUserStatus.loaded,
          user: user,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: AppUserStatus.error,
          error: e.toString(),
        ));
      }
    } else if (authState.status == AuthUserStatus.authNoUser) {
      emit(state.copyWith(status: AppUserStatus.noUser));
    } else if (authState.status == AuthUserStatus.noAuth) {
      emit(state.copyWith(status: AppUserStatus.noAuth));
    } else if (authState.status == AuthUserStatus.error) {
      emit(state.copyWith(
        status: AppUserStatus.error,
        error: authState.errorMessage,
      ));
    }
  }

  // 사용자 정보 업데이트 (예: 프로필 수정 후)
  void updateUser(User user) {
    if (state.user != null) {
      emit(state.copyWith(user: user));
    }
  }
}