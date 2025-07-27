import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/shared/presentation/routes/app_routes.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/widgets/loading_indicator.dart';
import 'package:app/features/shared/presentation/widgets/svg/slogen.dart';

/// Member profile screen for authenticated users
class MemberProfileScreen extends HookConsumerWidget {
  static const Key logoutButtonKey = Key('logout_button');
  static const Key memberInfoKey = Key('member_info');
  static const Key contactInfoKey = Key('contact_info');
  static const Key tierBadgeKey = Key('tier_badge');

  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(memberAuthNotifierProvider);
    final authNotifier = ref.read(memberAuthNotifierProvider.notifier);

    // Handle unauthenticated state
    if (!authState.isAuthenticated) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(message: '正在載入會員資訊...')),
      );
    }

    final member = authState.member!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '會員中心',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            key: logoutButtonKey,
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, authNotifier),
            tooltip: '登出',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger member data refresh if needed
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header
                _buildProfileHeader(context, member),

                const Gap(24),

                // Member information card
                _buildMemberInfoCard(context, member),

                const Gap(16),

                // Contact information card
                _buildContactInfoCard(context, member),

                const Gap(16),

                // Account management card
                _buildAccountManagementCard(context, authNotifier),

                const Gap(24),

                // App info
                _buildAppInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build profile header with member tier and basic info
  Widget _buildProfileHeader(BuildContext context, MemberDTO member) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _getTierGradientColors(member.tier),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                _getTierIcon(member.tier),
                size: 40,
                color: Colors.white,
              ),
            ),

            const Gap(16),

            // Member name
            Text(
              member.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const Gap(8),

            // Member tier badge
            Container(
              key: tierBadgeKey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(127)),
              ),
              child: Text(
                _getTierDisplayName(member.tier),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build member information card
  Widget _buildMemberInfoCard(BuildContext context, MemberDTO member) {
    return Card(
      key: memberInfoKey,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: AppColors.primary, size: 24),
                const Gap(8),
                Text(
                  '會員資訊',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Gap(20),

            _buildInfoRow(
              context,
              '會員號碼',
              member.memberNumber,
              Icons.badge_outlined,
            ),

            const Gap(16),

            _buildInfoRow(
              context,
              '會員等級',
              _getTierDisplayName(member.tier),
              Icons.star_outline,
            ),

            if (member.createdAt != null) ...[
              const Gap(16),
              _buildInfoRow(
                context,
                '加入日期',
                member.formatCreatedAt,
                Icons.calendar_today_outlined,
              ),
            ],

            if (member.lastLoginAt != null) ...[
              const Gap(16),
              _buildInfoRow(
                context,
                '最後登入',
                member.formatLastLoginAt,
                Icons.access_time_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build contact information card
  Widget _buildContactInfoCard(BuildContext context, MemberDTO member) {
    return Card(
      key: contactInfoKey,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_mail_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const Gap(8),
                Text(
                  '聯絡資訊',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showEditContactDialog(context, member),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('編輯'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),

            const Gap(20),

            _buildInfoRow(context, '電子郵件', member.email, Icons.email_outlined),

            const Gap(16),

            _buildInfoRow(context, '聯絡電話', member.phone, Icons.phone_outlined),
          ],
        ),
      ),
    );
  }

  /// Build account management card
  Widget _buildAccountManagementCard(
    BuildContext context,
    MemberAuthNotifier authNotifier,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const Gap(8),
                Text(
                  '帳號管理',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Gap(20),

            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('安全設定'),
              subtitle: const Text('修改密碼、安全驗證'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showComingSoonDialog(context, '安全設定'),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('通知設定'),
              subtitle: const Text('管理推送通知偏好'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showComingSoonDialog(context, '通知設定'),
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('登出', style: TextStyle(color: AppColors.error)),
              subtitle: const Text('登出目前帳號'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLogoutDialog(context, authNotifier),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  /// Build app information section
  Widget _buildAppInfo() {
    return Card(
      elevation: 1,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SlogenWidget(height: 24),
            const Gap(8),
            Text(
              '航空登機證管理系統',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const Gap(8),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Build information row widget
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const Gap(4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(
    BuildContext context,
    MemberAuthNotifier authNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認登出'),
        content: const Text('您確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authNotifier.logout();
              context.go(AppRoutes.memberAuth);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('登出'),
          ),
        ],
      ),
    );
  }

  /// Show edit contact information dialog
  void _showEditContactDialog(BuildContext context, MemberDTO member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯聯絡資訊'),
        content: const Text('聯絡資訊編輯功能即將推出'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  /// Show coming soon dialog for unimplemented features
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('此功能即將推出，敬請期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  /// Get tier gradient colors
  List<Color> _getTierGradientColors(MemberTier tier) {
    switch (tier) {
      case MemberTier.bronze:
        return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
      case MemberTier.silver:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case MemberTier.gold:
        return [const Color(0xFFFFD700), const Color(0xFFB8860B)];
      case MemberTier.suspended:
        return [AppColors.error, const Color(0xFFC62828)];
    }
  }

  /// Get tier icon
  IconData _getTierIcon(MemberTier tier) {
    switch (tier) {
      case MemberTier.bronze:
        return Icons.workspace_premium;
      case MemberTier.silver:
        return Icons.military_tech;
      case MemberTier.gold:
        return Icons.diamond;
      case MemberTier.suspended:
        return Icons.block;
    }
  }

  /// Get tier display name in Chinese
  String _getTierDisplayName(MemberTier tier) {
    switch (tier) {
      case MemberTier.bronze:
        return '銅級會員';
      case MemberTier.silver:
        return '銀級會員';
      case MemberTier.gold:
        return '金級會員';
      case MemberTier.suspended:
        return '暫停會員';
    }
  }
}
