import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/app_user_cubit.dart';
import '../../configs/app_config.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            _buildHeader(context),
            const SizedBox(height: 30),
            
            // 사용자 정보 카드
            _buildUserInfoCard(context),
            const SizedBox(height: 20),
            
            // 빠른 액션들
            _buildQuickActions(context),
            const SizedBox(height: 20),
            
            // 최근 활동
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AppUserCubit, AppUserState>(
      builder: (context, state) {
        final userName = state.user?.displayName ?? '사용자';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요,',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '$userName님! 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return BlocBuilder<AppUserCubit, AppUserState>(
      builder: (context, state) {
        if (state.status != AppUserStatus.loaded || state.user == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final user = state.user!;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 정보',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildInfoRow('이메일', user.email),
                if (user.displayName != null)
                  _buildInfoRow('이름', user.displayName!),
                if (user.phoneNumber != null)
                  _buildInfoRow('전화번호', user.phoneNumber!),
                _buildInfoRow('가입일', _formatDate(user.createdAt)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 액션',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              context,
              icon: Icons.person_outline,
              label: '프로필',
              onTap: () {
                //  프로필 페이지로 이동
              },
            ),
            _buildActionButton(
              context,
              icon: Icons.settings_outlined,
              label: '설정',
              onTap: () {
                // 설정 페이지로 이동
              },
            ),
            _buildActionButton(
              context,
              icon: Icons.help_outline,
              label: '도움말',
              onTap: () {
                // 도움말 페이지로 이동
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 활동',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('활동 내역이 없습니다'),
            subtitle: Text(
              '${AppConfig().appName}을 사용해보세요!',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}