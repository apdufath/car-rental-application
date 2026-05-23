import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/domain/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UsersManagementScreen extends ConsumerWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User KYC Management'),
        centerTitle: true,
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users registered.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(Helpers.getCacheBustedUrl(user.profileImageUrl!, user.updatedAt))
                        : null,
                    child: user.profileImageUrl == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Role: ${user.role.name.toUpperCase()} | Phone: ${user.phone}', style: const TextStyle(fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isVerified
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          user.isVerified ? Icons.verified : Icons.hourglass_top_rounded,
                          size: 12,
                          color: user.isVerified ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.isVerified ? 'VERIFIED' : 'PENDING',
                          style: TextStyle(
                            color: user.isVerified ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    _showKycVerificationSheet(context, ref, user);
                  },
                ),
              );
            },
          );
        },
        error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _showKycVerificationSheet(BuildContext context, WidgetRef ref, UserEntity user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user.profileImageUrl != null ? NetworkImage(Helpers.getCacheBustedUrl(user.profileImageUrl!, user.updatedAt)) : null,
                  child: user.profileImageUrl == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Phone: ${user.phone} | Email: ${user.email ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),

            // KYC Documents Grid Preview
            Text('SUBMITTED DOCUMENTS', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _DocPreviewCard(
                    title: "Driver's License",
                    imgUrl: user.licenseImageUrl ?? "https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?auto=format&fit=crop&w=300",
                  ),
                  _DocPreviewCard(
                    title: "National ID Card",
                    imgUrl: user.idCardImageUrl ?? "https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?auto=format&fit=crop&w=300",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verification CTA actions
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: user.isVerified ? 'Revoke Verification' : 'Verify & Approve KYC',
                    backgroundColor: user.isVerified ? AppColors.cancelled : AppColors.success,
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      Helpers.triggerHapticLight();
                      final repo = ref.read(authRepositoryProvider);
                      await repo.verifyUserKyc(user.uid, !user.isVerified);
                      
                      // Refresh lists
                      ref.invalidate(adminUsersProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(user.isVerified ? 'Verification status revoked.' : 'User verified successfully!'),
                            backgroundColor: user.isVerified ? AppColors.cancelled : AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocPreviewCard extends StatelessWidget {
  final String title;
  final String imgUrl;

  const _DocPreviewCard({
    required this.title,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
              child: Image.network(
                imgUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  width: double.infinity,
                  child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.zoom_in_rounded, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Tap to Zoom', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
