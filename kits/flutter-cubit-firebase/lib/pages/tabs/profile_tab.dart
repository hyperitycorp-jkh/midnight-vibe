import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../cubits/app_user_cubit.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 헤더
            _buildProfileHeader(context),
            const SizedBox(height: 20),
            
            // 메뉴 리스트
            _buildMenuList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return BlocBuilder<AppUserCubit, AppUserState>(
      builder: (context, state) {
        if (state.status != AppUserStatus.loaded || state.user == null) {
          return const SizedBox.shrink();
        }

        final user = state.user!;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.displayName?.substring(0, 1).toUpperCase() ?? 
                  user.email.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 이름
              Text(
                user.displayName ?? '이름 없음',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              
              // 이메일
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: '프로필 편집',
            onTap: () {
              // 프로필 편집 페이지로 이동
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            onTap: () {
              // 알림 설정 페이지로 이동
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.security_outlined,
            title: '보안 설정',
            onTap: () {
              // 보안 설정 페이지로 이동
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: '도움말',
            onTap: () {
              //도움말 페이지로 이동
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: '앱 정보',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '보일러플레이트 앱',
                applicationVersion: '1.0.0',
                children: const [
                  Text('Flutter 보일러플레이트 앱입니다.'),
                ],
              );
            },
          ),
          const Divider(height: 32),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: '로그아웃',
            textColor: Colors.red,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}