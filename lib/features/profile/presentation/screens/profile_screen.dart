import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/storage_service.dart';
import '../../../auth/domain/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cars/presentation/providers/cars_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _updateProfilePicture(BuildContext context, WidgetRef ref, String uid) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show temporary loading indicator dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );

      final bytes = await image.readAsBytes();
      final storage = ref.read(storageServiceProvider);
      final photoUrl = await storage.uploadBytes(
        uid: uid,
        fileName: 'profile.jpg',
        bytes: bytes,
      );

      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.uploadProfilePhoto(photoUrl);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog
      Helpers.triggerHapticSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e'), backgroundColor: AppColors.cancelled),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    final settings = ref.watch(appSettingsProvider);

    final favoriteIds = ref.watch(favoriteCarsProvider);
    final carsAsync = ref.watch(carsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: user == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Profile Settings')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Please log in to view profile.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Log In',
                      onPressed: () => context.go(AppRoutes.login),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Forest Green Curved Hero Header with Sandy Yellow ring & User details
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 280,
                        decoration: const BoxDecoration(
                        color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(36),
                            bottomRight: Radius.circular(36),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 20),
                        child: Column(
                          children: [
                            // Custom top bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                                const Text(
                                  'My Profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Sandy yellow ring surrounding user avatar
                            GestureDetector(
                              onTap: () => _updateProfilePicture(context, ref, user.uid),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 46,
                                      backgroundColor: Colors.white,
                                      backgroundImage: user.profileImageUrl != null
                                          ? NetworkImage(Helpers.getCacheBustedUrl(user.profileImageUrl!, user.updatedAt))
                                          : null,
                                      child: user.profileImageUrl == null
                                          ? const Icon(Icons.person, color: AppColors.primary, size: 46)
                                          : null,
                                    ),
                                  ),
                                  // Edit pencil overlay button
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: AppColors.secondary,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // User Name
                            Text(
                              user.fullName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Role Subtitle / Verification
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.phone,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  user.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                                  size: 14,
                                  color: user.isVerified ? AppColors.accent : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.isVerified ? 'VERIFIED' : 'PENDING',
                                  style: TextStyle(
                                    color: user.isVerified ? AppColors.accent : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 2. Floating/Overlapping Stats Card
                      Positioned(
                        bottom: -40,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statCol('12', 'Trips', Icons.directions_car_rounded),
                              _verticalDivider(),
                              _statCol('4.9', 'Rating', Icons.star_rounded),
                              _verticalDivider(),
                              _statCol(favoriteIds.length.toString(), 'Saved', Icons.favorite_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  // Admin Operations Dashboard Control
                  if (user.role == UserRole.admin) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          context.push(AppRoutes.adminDashboard);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.secondary, Color(0xFF233A30)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded, color: AppColors.accent, size: 28),
                                  SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Admin Dashboard Control',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Manage fleet, users & booking requests',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white12,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 3. Settings list as a clean stack of modern individual Cards with alternating soft green & soft yellow background leading icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCOUNT PREFERENCES',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stack of clean settings tiles
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            children: [
                              _profileTile(
                                icon: Icons.person_outline_rounded,
                                iconBg: const Color(0xFFE2EBE7), // Light green
                                iconColor: AppColors.primary,
                                title: 'Personal Info',
                                subtitle: 'Manage your contact details',
                              ),
                              _divider(),
                              _profileTile(
                                icon: Icons.history_rounded,
                                iconBg: const Color(0xFFFBF4DB), // Light yellow
                                iconColor: const Color(0xFF8B7500),
                                title: 'My Bookings',
                                subtitle: 'History of car rentals',
                                onTap: () => context.go(AppRoutes.bookings),
                              ),
                              _divider(),
                              _profileTile(
                                icon: Icons.credit_card_rounded,
                                iconBg: const Color(0xFFE2EBE7), // Light green
                                iconColor: AppColors.primary,
                                title: 'Payment Settings',
                                subtitle: 'Configured push accounts',
                              ),
                              _divider(),
                              _profileTile(
                                icon: Icons.dark_mode_outlined,
                                iconBg: const Color(0xFFFBF4DB), // Light yellow
                                iconColor: const Color(0xFF8B7500),
                                title: 'Dark Mode',
                                subtitle: 'Toggle app colors',
                                trailing: Switch(
                                  value: settings.themeMode == ThemeMode.dark,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) {
                                    Helpers.triggerHapticLight();
                                    ref.read(appSettingsProvider.notifier).toggleTheme(val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 4. Favorite cars section
                        Text(
                          'MY SAVED VEHICLES',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        carsAsync.when(
                          data: (cars) {
                            final favCars = cars.where((c) => favoriteIds.contains(c.carId)).toList();
                            if (favCars.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.favorite_border_rounded, color: Colors.grey.shade300, size: 36),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No favorited cars yet.',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                children: favCars.map((car) {
                                  final isLast = favCars.indexOf(car) == favCars.length - 1;
                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: car.images.isNotEmpty
                                              ? Image.network(
                                                  car.images.first,
                                                  width: 70,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: Colors.grey.shade200,
                                                    width: 70,
                                                    height: 48,
                                                    child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(color: Colors.grey, width: 70, height: 48),
                                        ),
                                        title: Text(
                                          '${car.brand} ${car.model}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary),
                                        ),
                                        subtitle: Text(
                                          '\$${car.pricePerDay.toInt()}/day',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                                          onPressed: () {
                                            Helpers.triggerHapticLight();
                                            ref.read(favoriteCarsProvider.notifier).toggleFavorite(car.carId);
                                          },
                                        ),
                                        onTap: () {
                                          context.push(AppRoutes.getCarDetailRoute(car.carId));
                                        },
                                      ),
                                      if (!isLast) _divider(),
                                    ],
                                  );
                                }).toList(),
                              ),
                            );
                          },
                          error: (e, st) => const SizedBox(),
                          loading: () => const Center(child: CircularProgressIndicator()),
                        ),
                        const SizedBox(height: 32),

                        // 5. Account operations
                        Text(
                          'ACCOUNT MANAGEMENT',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            children: [
                              _profileTile(
                                icon: Icons.logout_rounded,
                                iconBg: const Color(0xFFFFEBEE), // Soft red
                                iconColor: AppColors.cancelled,
                                title: 'Sign Out / Log Out',
                                subtitle: 'Safely exit the app',
                                onTap: () async {
                                  Helpers.triggerHapticLight();
                                  await ref.read(authNotifierProvider.notifier).logout();
                                  if (context.mounted) {
                                    context.go(AppRoutes.login);
                                  }
                                },
                              ),
                              _divider(),
                              _profileTile(
                                icon: Icons.delete_forever_rounded,
                                iconBg: const Color(0xFFF3F3F3), // Soft grey
                                iconColor: Colors.grey.shade700,
                                title: 'Delete Account',
                                subtitle: 'Irreversibly delete account data',
                                onTap: () {
                                  _showDeleteDialog(context, ref);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCol(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1.2,
      height: 36,
      color: Colors.grey.shade200,
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade100,
      indent: 68,
    );
  }

  Widget _profileTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.secondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This operation is irreversible. All of your bookings, records, and KYC uploads will be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              Helpers.triggerHapticLight();
              await ref.read(authNotifierProvider.notifier).deleteAccount();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Yes, Delete', style: TextStyle(color: AppColors.cancelled)),
          ),
        ],
      ),
    );
  }
}
