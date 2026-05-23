import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../../core/widgets/custom_error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/helpers.dart';
import '../providers/cars_provider.dart';
import '../../domain/car_entity.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final authState = ref.watch(authNotifierProvider);
    final carsAsync = ref.watch(carsListProvider);
    final selectedCategory = ref.watch(carsSelectedCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(carsListProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Premium Forest Green Hero Background & Floating Search Card
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          Text(
                            'Abaarso',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              letterSpacing: 0.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.profile),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.accent, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.white24,
                                backgroundImage: authState.user?.profileImageUrl != null
                                    ? NetworkImage(Helpers.getCacheBustedUrl(authState.user!.profileImageUrl!, authState.user!.updatedAt))
                                    : null,
                                child: authState.user?.profileImageUrl == null
                                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        'Find Your Perfect Drive',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Premium vehicles for every journey. Reliable, comfortable, and ready when you are.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Floating Search Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                ref.read(carsSearchQueryProvider.notifier).state = '';
                                context.go(AppRoutes.search);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Where to?',
                                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                ref.read(carsSearchQueryProvider.notifier).state = '';
                                context.go(AppRoutes.search);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 18),
                                        const SizedBox(width: 12),
                                        Text(
                                          'mm/dd/yyyy',
                                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  context.go(AppRoutes.search);
                                },
                                child: const Text(
                                  'Search',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Horizontal Category Filter Chips (Active chip in sandy yellow)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ChoiceChip(
                          showCheckmark: false,
                          avatar: Icon(
                            Icons.directions_car_filled_rounded,
                            size: 14,
                            color: selectedCategory == null ? AppColors.secondary : Colors.grey.shade700,
                          ),
                          label: const Text('All Cars'),
                          selected: selectedCategory == null,
                          onSelected: (val) {
                            ref.read(carsSelectedCategoryProvider.notifier).state = null;
                          },
                        ),
                        const SizedBox(width: 8),
                        ...CarCategory.values.map((cat) {
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              showCheckmark: false,
                              avatar: Icon(
                                cat == CarCategory.suv
                                    ? Icons.airport_shuttle_rounded
                                    : cat == CarCategory.pickup
                                        ? Icons.local_shipping_rounded
                                        : cat == CarCategory.luxury
                                            ? Icons.workspace_premium_rounded
                                            : Icons.directions_car_filled_rounded,
                                size: 14,
                                color: isSelected ? AppColors.secondary : Colors.grey.shade700,
                              ),
                              label: Text(cat.name == 'sedan'
                                  ? 'Sedans'
                                  : cat.name == 'suv'
                                      ? 'SUVs'
                                      : cat.name.toUpperCase()),
                              selected: isSelected,
                              onSelected: (val) {
                                ref.read(carsSelectedCategoryProvider.notifier).state = val ? cat : null;
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Featured Experience Section (Range Rover Velar Mockup Card)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Experience',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      carsAsync.when(
                        data: (cars) {
                          // Find an SUV or use first car in database for functional redirection
                          final String functionalCarId = cars.isNotEmpty ? cars.first.carId : '';
                          return GestureDetector(
                            onTap: () {
                              if (functionalCarId.isNotEmpty) {
                                context.push(AppRoutes.getCarDetailRoute(functionalCarId));
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image Stack
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=80',
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      // Top Rated badge
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                              )
                                            ]
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.circle, color: Color(0xFF8B7500), size: 8),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Top Rated',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Detail Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Range Rover Velar',
                                                    style: theme.textTheme.titleLarge?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Luxury SUV',
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '4.9',
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '\$140',
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    color: const Color(0xFF8B7500),
                                                    fontSize: 22,
                                                  ),
                                                ),
                                                Text(
                                                  '/ day',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Spec chips
                                        Row(
                                          children: [
                                            _specIcon(Icons.people_alt_rounded, '5'),
                                            const SizedBox(width: 16),
                                            _specIcon(Icons.settings_rounded, 'Auto'),
                                            const SizedBox(width: 16),
                                            _specIcon(Icons.work_rounded, '3'),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Full width book now button (dark yellow/brown)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF8B7500),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              elevation: 0,
                                            ),
                                            onPressed: () {
                                              if (functionalCarId.isNotEmpty) {
                                                context.push(AppRoutes.getCarDetailRoute(functionalCarId));
                                              }
                                            },
                                            child: const Text(
                                              'Book Now',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        error: (e, st) => const SizedBox(),
                        loading: () => const ShimmerCard(width: double.infinity, height: 350),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Available Near You Horizontal row
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Near You',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(AppRoutes.search);
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              carsAsync.when(
                data: (cars) {
                  final filtered = selectedCategory == null
                      ? cars
                      : cars.where((c) => c.category == selectedCategory).toList();

                  if (filtered.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No vehicles available in this category.'),
                        ),
                      ),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 290,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final car = filtered[index];
                          // Calculate a mock distance based on location name
                          final double mockDistance = (index + 1) * 1.2;

                          return GestureDetector(
                            onTap: () {
                              context.push(AppRoutes.getCarDetailRoute(car.carId));
                            },
                            child: Container(
                              width: 240,
                              margin: const EdgeInsets.only(right: 16, bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Image stack
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: CachedNetworkImage(
                                          imageUrl: car.images.isNotEmpty ? car.images.first : 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=400',
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const ShimmerCard(width: 240, height: 140),
                                          errorWidget: (context, url, err) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image)),
                                        ),
                                      ),
                                      // Verified Check badge
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, color: AppColors.secondary, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Detail Content
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${car.brand} ${car.model}',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, color: Colors.grey, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${mockDistance.toStringAsFixed(1)} miles away',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.airline_seat_recline_extra_rounded, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.settings_rounded, size: 14, color: Colors.grey),
                                              ],
                                            ),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  '\$${car.pricePerDay.toInt()}',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  ' / day',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                error: (e, st) => SliverToBoxAdapter(
                  child: CustomErrorWidget(errorMessage: e.toString(), onRetry: () => ref.invalidate(carsListProvider)),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
