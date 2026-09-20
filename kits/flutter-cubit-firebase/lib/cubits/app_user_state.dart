part of 'app_user_cubit.dart';

enum AppUserStatus {
  initial,
  loaded,
  noUser,
  noAuth,
  error,
}

class AppUserState extends Equatable {
  final AppUserStatus status;
  final User? user;
  final String? error;

  const AppUserState({
    this.status = AppUserStatus.initial,
    this.user,
    this.error,
  });

  AppUserState copyWith({
    AppUserStatus? status,
    User? user,
    String? error,
  }) {
    return AppUserState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, user, error];
}