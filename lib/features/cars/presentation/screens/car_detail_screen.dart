import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/user_entity.dart';
import '../../../../core/widgets/custom_error_widget.dart';
import '../providers/cars_provider.dart';

class CarDetailScreen extends ConsumerStatefulWidget {
  final String carId;

  const CarDetailScreen({
    super.key,
    required this.carId,
  });

  @override
  ConsumerState<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends ConsumerState<CarDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImagePage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final carsAsync = ref.watch(carsListProvider);
    final favorites = ref.watch(favoriteCarsProvider);
    final isFavorite = favorites.contains(widget.carId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: carsAsync.when(
        data: (cars) {
          final carList = cars.where((c) => c.carId == widget.carId).toList();
          if (carList.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Car Details')),
              body: const Center(child: Text('Car not found')),
            );
          }
          final car = carList.first;

          return Stack(
            children: [
              // Scrollable Details Body
              CustomScrollView(
                slivers: [
                  // 1. Premium Image Slider Header with Back and Favorite overlays
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? Colors.red.shade600 : AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            Helpers.triggerHapticLight();
                            ref.read(favoriteCarsProvider.notifier).toggleFavorite(car.carId);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        color: const Color(0xFFEAEFEF), // Light-grey green-tinted background
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: (idx) {
                                setState(() {
                                  _currentImagePage = idx;
                                });
                              },
                              itemCount: car.images.isNotEmpty ? car.images.length : 1,
                              itemBuilder: (context, index) {
                                final imgUrl = car.images.isNotEmpty ? car.images[index] : '';
                                return Hero(
                                  tag: 'car_img_${car.carId}',
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
                                    child: imgUrl.startsWith('data:')
                                        ? Image.network(
                                            imgUrl,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                          )
                                        : CachedNetworkImage(
                                            imageUrl: imgUrl.isNotEmpty ? imgUrl : 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=600',
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            placeholder: (context, url) => const ShimmerCard(width: double.infinity, height: 280),
                                            errorWidget: (context, url, err) => const Icon(Icons.broken_image, size: 48, color: AppColors.primary),
                                          ),
                                  ),
                                );
                              },
                            ),
                            // Dot indicator overlay
                            if (car.images.length > 1)
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    car.images.length,
                                    (idx) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: _currentImagePage == idx ? 20 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentImagePage == idx ? AppColors.primary : AppColors.primary.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Info Details
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Primary Details Row: Brand + Model, Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    car.brand.toUpperCase(),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${car.model} (${car.year})',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.secondary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: car.isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: car.isAvailable ? AppColors.active : AppColors.cancelled,
                                    size: 8,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    car.isAvailable ? 'AVAILABLE' : 'BOOKED',
                                    style: TextStyle(
                                      color: car.isAvailable ? AppColors.active : AppColors.cancelled,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Stars Rating Row
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              car.averageRating.toString(),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${car.totalReviews} Reviews)',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                            ),
                            const Spacer(),
                            const Icon(Icons.tag_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              car.plateNumber,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Floating Sandy-Yellow Dual Currency Pricing Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFCEEB5), AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'US DOLLARS (USD)',
                                    style: TextStyle(
                                      color: Color(0xFF4A3E1B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatUSD(car.pricePerDay),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF261F09),
                                      fontSize: 24,
                                    ),
                                  ),
                                  const Text(
                                    'per day rate',
                                    style: TextStyle(
                                      color: Color(0xFF7A6A3F),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1.5,
                                height: 50,
                                color: const Color(0xFFD6BA5F),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'SOMALI SHILLINGS (SOS)',
                                    style: TextStyle(
                                      color: Color(0xFF4A3E1B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Formatters.formatSOS(car.pricePerDay * 600),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const Text(
                                    'approximate standard',
                                    style: TextStyle(
                                      color: Color(0xFF7A6A3F),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Soft Light Green Spec Chips
                        Text(
                          'Specifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _specChip(Icons.settings_rounded, 'Automatic'),
                            _specChip(Icons.airline_seat_recline_normal_rounded, '7 Seats'),
                            _specChip(Icons.ac_unit_rounded, 'AC Active'),
                            _specChip(Icons.local_gas_station_rounded, 'Petrol'),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Features wrap
                        Text(
                          'Key Features',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: car.features.map((feat) {
                            return Chip(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade200),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              label: Text(
                                feat,
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              avatar: Icon(
                                feat.toLowerCase() == 'ac'
                                    ? Icons.ac_unit_rounded
                                    : feat.toLowerCase() == '4wd'
                                        ? Icons.grid_goldenratio_rounded
                                        : feat.toLowerCase() == 'gps'
                                            ? Icons.gps_fixed_rounded
                                            : Icons.check_circle_outline_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),

                        // Restructured Owner Card
                        Text(
                          'Owner / Lessor',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150'),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Ahmed Ali',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xFFD6BA5F),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Verified Lessor • 98% rating',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Helpers.triggerHapticLight();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Starting chat with Ahmed Ali...'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2EBE7),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Mockup Map Placeholder Container
                        Text(
                          'Location',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              children: [
                                // Mock Map Grid graphic
                                Container(
                                  color: const Color(0xFFE8F0EC),
                                  child: GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 8,
                                    ),
                                    itemBuilder: (context, index) => Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.8),
                                      ),
                                    ),
                                  ),
                                ),
                                // Glowing Location ring and marker
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.location_on_rounded,
                                            color: AppColors.primary,
                                            size: 32,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 8,
                                            )
                                          ],
                                        ),
                                        child: Text(
                                          car.locationName.isNotEmpty ? car.locationName : 'Downtown Hargeisa',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Map tag
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.directions_car, color: AppColors.primary, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Downtown Hargeisa',
                                          style: TextStyle(
                                            color: AppColors.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Latest Customer Reviews list
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Latest Reviews',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _ReviewTile(
                          name: 'Mohamed Ibrahim',
                          comment: 'Excellent condition vehicle. V8 cruiser was perfectly clean and performed marvelously on my trip around Hargeisa suburbs.',
                          rating: 5,
                        ),
                        const SizedBox(height: 12),
                        _ReviewTile(
                          name: 'Khadra Duale',
                          comment: 'Great customer support and seamless payment setup. Recommending this platform for anybody visiting Somaliland.',
                          rating: 4.8,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),

              // 3. Sticky Bottom Reservation Action Bar (Forest Green Full-Width Button)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Check user KYC status first
                        final user = ref.read(authNotifierProvider).user;
                        if (user != null && !user.isVerified && user.role == UserRole.customer) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your KYC profile verification is pending. Admin will approve shortly.'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                        context.push(AppRoutes.getBookingRoute(car.carId));
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Book Now  •  ${Formatters.formatUSD(car.pricePerDay)}/day',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        error: (e, st) => CustomErrorWidget(errorMessage: e.toString(), onRetry: () => ref.invalidate(carsListProvider)),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _specChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F0), // Soft light green
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name;
  final String comment;
  final double rating;

  const _ReviewTile({
    required this.name,
    required this.comment,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
