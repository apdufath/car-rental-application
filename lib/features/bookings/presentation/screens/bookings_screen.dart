import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../domain/booking_entity.dart';
import '../providers/bookings_provider.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings / Dalabyadayda'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Active / Socda'),
            Tab(text: 'Upcoming / Soo Socda'),
            Tab(text: 'Past / Hore'),
            Tab(text: 'Cancelled / La Joojiyay'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          final now = DateTime.now();

          // Categorize bookings
          final active = bookings.where((b) {
            final isOngoing = (b.startDate.isBefore(now) || isSameDay(b.startDate, now)) &&
                              (b.endDate.isAfter(now) || isSameDay(b.endDate, now));
            return isOngoing && (b.status == BookingStatus.approved || b.status == BookingStatus.active);
          }).toList();

          final upcoming = bookings.where((b) {
            return b.startDate.isAfter(now) &&
                (b.status == BookingStatus.pending || b.status == BookingStatus.approved);
          }).toList();

          final past = bookings.where((b) {
            return b.status == BookingStatus.completed ||
                (b.endDate.isBefore(now) && b.status != BookingStatus.cancelled);
          }).toList();

          final cancelled = bookings.where((b) => b.status == BookingStatus.cancelled).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingsList(bookings: active, emptyMessageEn: 'No active rentals.', emptyMessageSo: 'Ma jiraan kireysi firfircoon.'),
              _BookingsList(bookings: upcoming, emptyMessageEn: 'No upcoming reservations.', emptyMessageSo: 'Ma jiraan dalabyo soo socda.'),
              _BookingsList(bookings: past, emptyMessageEn: 'No past rentals recorded.', emptyMessageSo: 'Ma jiraan kireysi hore.'),
              _BookingsList(bookings: cancelled, emptyMessageEn: 'No cancelled bookings.', emptyMessageSo: 'Ma jiraan dalabyo la joojiyay.'),
            ],
          );
        },
        error: (e, st) => Center(child: Text('Error loading bookings: ${e.toString()}')),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 3,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ShimmerCard(width: double.infinity, height: 140),
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _BookingsList extends StatelessWidget {
  final List<BookingEntity> bookings;
  final String emptyMessageEn;
  final String emptyMessageSo;

  const _BookingsList({
    required this.bookings,
    required this.emptyMessageEn,
    required this.emptyMessageSo,
  });

  @override
  Widget build(BuildContext context) {

    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(emptyMessageEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(emptyMessageSo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];

        // Format dates e.g. "May 21, 2026"
        String formatDate(DateTime date) {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${months[date.month - 1]} ${date.day}, ${date.year}';
        }

        // Get status color
        Color getStatusColor(BookingStatus status) {
          switch (status) {
            case BookingStatus.pending:
              return Colors.orange;
            case BookingStatus.approved:
              return Colors.blue;
            case BookingStatus.active:
              return AppColors.success;
            case BookingStatus.completed:
              return Colors.grey;
            case BookingStatus.cancelled:
              return AppColors.cancelled;
          }
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              context.push(AppRoutes.getBookingDetailRoute(booking.bookingId));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: booking.carImageUrl != null
                            ? Image.network(
                                booking.carImageUrl!,
                                width: 70,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade200,
                                  width: 70,
                                  height: 50,
                                  child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                                ),
                              )
                            : Container(color: Colors.grey.shade200, width: 70, height: 50, child: const Icon(Icons.car_rental)),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.carBrandModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(booking.carPlateNumber, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: getStatusColor(booking.status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booking.status.name.toUpperCase(),
                          style: TextStyle(
                            color: getStatusColor(booking.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  // Dates & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RENTAL PERIOD', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${formatDate(booking.startDate)} - ${formatDate(booking.endDate)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('TOTAL PRICE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(Formatters.formatUSD(booking.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(Formatters.formatSOS(booking.totalPrice * 600), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
