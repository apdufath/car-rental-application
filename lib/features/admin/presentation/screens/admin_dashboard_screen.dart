import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/utils/helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cars/presentation/providers/cars_provider.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/booking_entity.dart';
import '../../../../core/services/firestore_seeder_service.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(appSettingsProvider);

    final carsAsync = ref.watch(carsListProvider);
    final bookingsAsync = ref.watch(adminBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard / Maamulka'),
        centerTitle: true,
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final cars = carsAsync.value ?? [];

          // 1. Calculations
          final totalFleet = cars.length;
          final pendingBookings = bookings.where((b) => b.status == BookingStatus.pending).length;
          final activeRentals = bookings.where((b) => b.status == BookingStatus.active).length;
          
          double totalRevenue = 0;
          for (var b in bookings) {
            if (b.paymentStatus == PaymentStatus.paid) {
              totalRevenue += b.totalPrice;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Database seeding banner
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF1E3C72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.storage_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Firestore Setup',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Create and seed all 5 collections in live Firestore.',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          );
                          try {
                            await FirestoreSeederService.instance.seedAllCollections();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All collections seeded successfully in Firestore!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to seed: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Seed / Abuur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ),

                // KPI Metrics Grids
                Text(
                  'BUSINESS METRICS',
                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      title: 'Total Revenue',
                      value: Formatters.formatUSD(totalRevenue),
                      subValue: Formatters.formatSOS(totalRevenue * 600),
                      icon: Icons.monetization_on_rounded,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      title: 'Active Rentals',
                      value: activeRentals.toString(),
                      subValue: 'On Hargeisa Roads',
                      icon: Icons.directions_car_rounded,
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      title: 'Pending Requests',
                      value: pendingBookings.toString(),
                      subValue: 'Requires Approval',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Total Fleet Size',
                      value: totalFleet.toString(),
                      subValue: 'Vehicles Registered',
                      icon: Icons.fact_check_rounded,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Premium Revenue curve chart using fl_chart
                Text(
                  'WEEKLY REVENUE TRENDS (USD)',
                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (val.toInt() >= 0 && val.toInt() < days.length) {
                                return Text(days[val.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 450),
                            const FlSpot(1, 600),
                            const FlSpot(2, 350),
                            const FlSpot(3, 900),
                            const FlSpot(4, 750),
                            const FlSpot(5, 1200),
                            const FlSpot(6, 1400),
                          ],
                          isCurved: true,
                          barWidth: 3.5,
                          color: AppColors.primary,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Administrative Operations Grid
                Text(
                  'ADMIN OPERATIONS / MAAMULKA',
                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                _AdminShortcutCard(
                  icon: Icons.airport_shuttle_rounded,
                  title: 'Fleet & Fleet CRUD Management',
                  subtitle: 'Add, update or delete registered vehicles',
                  route: AppRoutes.adminCars,
                ),
                const SizedBox(height: 12),
                _AdminShortcutCard(
                  icon: Icons.assignment_rounded,
                  title: 'Rental Requests & Approvals',
                  subtitle: 'Approve, decline, or complete bookings',
                  route: AppRoutes.adminBookings,
                ),
                const SizedBox(height: 12),
                _AdminShortcutCard(
                  icon: Icons.people_alt_rounded,
                  title: 'User Management & KYC Verifications',
                  subtitle: 'Approve client licenses and ID uploads',
                  route: AppRoutes.adminUsers,
                ),
                const SizedBox(height: 12),
                _AdminShortcutCard(
                  icon: Icons.notifications_active_rounded,
                  title: 'FCM Push Broadcast Centre',
                  subtitle: 'Send localized push notifications to users',
                  route: AppRoutes.adminNotifications,
                ),
                const SizedBox(height: 32),

                // Settings & Preferences Section
                Text(
                  'SETTINGS & PREFERENCES',
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
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _profileTile(
                        icon: Icons.dark_mode_outlined,
                        iconBg: const Color(0xFFFBF4DB), // Light yellow
                        iconColor: const Color(0xFF8B7500),
                        title: 'Dark Mode / Habka Madow',
                        subtitle: 'Toggle app colors / Beddel midabada',
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
                const SizedBox(height: 32),

                // Account Management Section
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
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
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
                      _divider(isDark),
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
              ],
            ),
          );
        },
        error: (e, st) => Center(child: Text('Error: ${e.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                subValue,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _AdminShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: () {
          context.push(route);
        },
      ),
    );
  }
}
