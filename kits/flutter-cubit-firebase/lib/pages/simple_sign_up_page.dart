import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:common_utils/logger/logger.dart';
import '../repositories/user_repository.dart';
import '../models/user.dart';

class SimpleSignUpPage extends StatefulWidget {
  final firebase_auth.User firebaseUser;

  const SimpleSignUpPage({
    super.key,
    required this.firebaseUser,
  });

  @override
  State<SimpleSignUpPage> createState() => _SimpleSignUpPageState();
}

class _SimpleSignUpPageState extends State<SimpleSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _completeSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 새 사용자 생성
      final user = User(
        uid: widget.firebaseUser.uid,
        email: widget.firebaseUser.email ?? '',
        displayName: _displayNameController.text.trim(),
        phoneNumber: widget.firebaseUser.phoneNumber,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Repository를 통해 사용자 저장
      final userRepository = context.read<UserRepository>();
      await userRepository.createUser(user);

      // AuthUserCubit이 자동으로 업데이트됩니다 (Firebase Auth 상태 변경 감지)

      Log.d('SimpleSignUpPage: 회원가입 완료 - ${user.uid}');
    } catch (e) {
      Log.e('SimpleSignUpPage: 회원가입 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  '환영합니다!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '프로필을 설정해주세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // 이메일 표시 (수정 불가)
                TextFormField(
                  initialValue: widget.firebaseUser.email ?? '이메일 없음',
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 전화번호 표시 (있는 경우)
                if (widget.firebaseUser.phoneNumber != null) ...[
                  TextFormField(
                    initialValue: widget.firebaseUser.phoneNumber,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // 이름 입력
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    hintText: '표시될 이름을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    if (value.trim().length < 2) {
                      return '이름은 2자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                // 가입 완료 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeSignUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '가입 완료',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}