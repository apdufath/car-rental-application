import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_error_widget.dart';
import '../../../../core/services/payment_service.dart';
import '../../../cars/presentation/providers/cars_provider.dart';
import '../../../cars/domain/car_entity.dart';
import '../../domain/booking_entity.dart';
import '../providers/bookings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String carId;

  const BookingScreen({
    super.key,
    required this.carId,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _pickupLocation = "Jigjiga Yar, Hargeisa";
  String _dropoffLocation = "Jigjiga Yar, Hargeisa";

  final List<String> _hargeisaLocations = [
    "Jigjiga Yar, Hargeisa",
    "Sha'ab, Hargeisa",
    "26 June, Hargeisa",
    "Xeedho, Hargeisa",
    "Egal Intl Airport (EIG)",
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final carsAsync = ref.watch(carsListProvider);
    final bookingsAsync = ref.watch(carBookingsProvider(widget.carId));
    final checkoutState = ref.watch(bookingNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        top: false,
        child: carsAsync.when(
          data: (cars) {
            final carList = cars.where((c) => c.carId == widget.carId).toList();
            if (carList.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Complete Booking')),
                body: const Center(child: Text('Car not found / Gaariga lama helin.')),
              );
            }
            final car = carList.first;

            // Pre-fill phone if empty
            if (_phoneController.text.isEmpty) {
              final user = ref.read(authNotifierProvider).user;
              if (user != null) {
                _phoneController.text = user.phone;
              }
            }

            return bookingsAsync.when(
              data: (bookings) {
                // Calculate blocked dates
                final Set<DateTime> blockedDates = {};
                for (var booking in bookings) {
                  if (booking.status != BookingStatus.cancelled) {
                    var current = DateTime(booking.startDate.year, booking.startDate.month, booking.startDate.day);
                    final end = DateTime(booking.endDate.year, booking.endDate.month, booking.endDate.day);
                    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
                      blockedDates.add(current);
                      current = current.add(const Duration(days: 1));
                    }
                  }
                }

                // TableCalendar checks if day is blocked
                bool isDayBlocked(DateTime day) {
                  final normalized = DateTime(day.year, day.month, day.day);
                  return blockedDates.contains(normalized);
                }

                final daysCount = (_rangeStart != null && _rangeEnd != null)
                    ? _rangeEnd!.difference(_rangeStart!).inDays + 1
                    : 0;

                final basePrice = daysCount * car.pricePerDay;
                final tax = basePrice * 0.10; // 10% Somali luxury/service tax
                final totalCost = basePrice + tax;

                return Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                    // 1. Curved Forest Green Context Header & Back navigation
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
                        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Complete Booking',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Secure your luxury rental in just a few quick steps.',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Overlapping Car Summary Card
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Transform.translate(
                          offset: const Offset(0, -32),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: car.images.isNotEmpty
                                      ? Image.network(
                                          car.images.first,
                                          width: 100,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(color: Colors.grey, width: 100, height: 70),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${car.brand} ${car.model}',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.secondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF9E7),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.verified_user_rounded, color: AppColors.secondary, size: 10),
                                                SizedBox(width: 4),
                                                Text(
                                                  'VERIFIED',
                                                  style: TextStyle(
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${Formatters.formatUSD(car.pricePerDay)} / day rate',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Trip Details & Calendar
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Date picker Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Trip Dates',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                              if (daysCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF4F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$daysCount Days Selected',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // TableCalendar styled
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: TableCalendar(
                              firstDay: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                              lastDay: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).add(const Duration(days: 180)),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                              rangeStartDay: _rangeStart,
                              rangeEndDay: _rangeEnd,
                              rangeSelectionMode: _rangeSelectionMode,
                              enabledDayPredicate: (day) => !isDayBlocked(day),
                              onRangeSelected: (start, end, focused) {
                                setState(() {
                                  _rangeStart = start;
                                  _rangeEnd = end;
                                  _focusedDay = focused;
                                });
                                ref.read(bookingNotifierProvider.notifier).setDates(start, end);
                              },
                              onFormatChanged: (format) {
                                setState(() {
                                  _calendarFormat = format;
                                });
                              },
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              calendarStyle: CalendarStyle(
                                rangeStartDecoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                rangeEndDecoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                rangeHighlightColor: AppColors.primary.withOpacity(0.1),
                                todayDecoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                disabledTextStyle: const TextStyle(color: Colors.grey),
                              ),
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, day, focusedDay) {
                                  if (isDayBlocked(day)) {
                                    return Container(
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.cancelled.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${day.day}',
                                        style: const TextStyle(color: AppColors.cancelled, decoration: TextDecoration.lineThrough),
                                      ),
                                    );
                                  }
                                  return Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Location Picker Inputs
                          Text(
                            'Trip Details / Location',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pick-up Point', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _pickupLocation,
                                          isExpanded: true,
                                          icon: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                                          items: _hargeisaLocations.map((loc) {
                                            return DropdownMenuItem<String>(value: loc, child: Text(loc, style: const TextStyle(fontSize: 13)));
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _pickupLocation = val);
                                              ref.read(bookingNotifierProvider.notifier).setLocations(pickup: val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Drop-off Point', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _dropoffLocation,
                                          isExpanded: true,
                                          icon: const Icon(Icons.drive_file_move_rounded, color: AppColors.primary, size: 18),
                                          items: _hargeisaLocations.map((loc) {
                                            return DropdownMenuItem<String>(value: loc, child: Text(loc, style: const TextStyle(fontSize: 13)));
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => _dropoffLocation = val);
                                              ref.read(bookingNotifierProvider.notifier).setLocations(dropoff: val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Three-way Payment Option Layout (EVC, Zaad, Cash)
                          Text(
                            'Payment Method',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _paymentCard(
                                method: PaymentMethod.evc,
                                label: 'EVC Plus',
                                brand: 'Hormuud',
                                activeColor: const Color(0xFF2D6A4F),
                                isSelected: checkoutState.paymentMethod == PaymentMethod.evc,
                              ),
                              const SizedBox(width: 12),
                              _paymentCard(
                                method: PaymentMethod.zaad,
                                label: 'Zaad Pay',
                                brand: 'Telesom',
                                activeColor: const Color(0xFFE8C96A),
                                isSelected: checkoutState.paymentMethod == PaymentMethod.zaad,
                              ),
                              const SizedBox(width: 12),
                              _paymentCard(
                                method: PaymentMethod.cash,
                                label: 'Cash Pay',
                                brand: 'Offline',
                                activeColor: AppColors.secondary,
                                isSelected: checkoutState.paymentMethod == PaymentMethod.cash,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Mobile Push payment input
                          if (checkoutState.paymentMethod != PaymentMethod.cash) ...[
                            const Text(
                              'Mobile Number for Push Payment',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: checkoutState.paymentMethod == PaymentMethod.zaad ? '+252 63XXXXXXX' : '+252 61XXXXXXX',
                                prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Notes/Optional Instructions
                          const Text(
                            'Special Instructions (Optional)',
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g., Please meet at airport arrival gate...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Price summary breakdown
                          if (daysCount > 0) ...[
                            Text(
                              'Price Summary',
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
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Base Rental ($daysCount Days)', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                      Text(Formatters.formatUSD(basePrice), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Somaliland Luxury Tax (10%)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                                      Text('Included', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Rate (USD)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                      Text(
                                        Formatters.formatUSD(totalCost),
                                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.secondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Rate (SOS approx)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      Text(
                                        Formatters.formatSOS(totalCost * 600),
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 120), // Spacing for sticky bottom button
                        ]),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: checkoutState.isLoading
                      ? Container(
                          height: 80,
                          color: Colors.white,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: AppColors.primary),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            border: Border(top: BorderSide(color: Colors.grey.shade100)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
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
                                backgroundColor: AppColors.accent,
                                foregroundColor: const Color(0xFF261F09),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: (_rangeStart == null || _rangeEnd == null)
                                  ? null
                                  : () {
                                      _handlePaymentAndBooking(context, totalCost, car);
                                    },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Confirm & Pay Booking',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
          error: (e, st) => CustomErrorWidget(errorMessage: e.toString(), onRetry: () => ref.invalidate(carBookingsProvider(widget.carId))),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
      },
      error: (e, st) => CustomErrorWidget(errorMessage: e.toString(), onRetry: () => ref.invalidate(carsListProvider)),
      loading: () => const Center(child: CircularProgressIndicator()),
    ),
  ),
);
  }

  Widget _paymentCard({
    required PaymentMethod method,
    required String label,
    required String brand,
    required Color activeColor,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Helpers.triggerHapticLight();
          ref.read(bookingNotifierProvider.notifier).setPaymentMethod(method);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEAF4F0) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    brand,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppColors.secondary : Colors.grey.shade800,
                    ),
                  ),
                  const Text(
                    'Direct push',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePaymentAndBooking(BuildContext context, double totalCost, CarEntity car) async {
    final bookingNotifier = ref.read(bookingNotifierProvider.notifier);

    // 1. Pre-flight validation checks before initiating payment to prevent charging for invalid requests
    final validationError = bookingNotifier.validateBooking(
      carId: widget.carId,
      brandModel: '${car.brand} ${car.model}',
      plateNumber: car.plateNumber,
      pricePerDay: car.pricePerDay,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError['en']!),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (ref.read(bookingNotifierProvider).paymentMethod != PaymentMethod.cash && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter phone number for payment.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    // Show elegant full screen payment status modal dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _PaymentModal(
        method: ref.read(bookingNotifierProvider).paymentMethod,
        phone: phone.isNotEmpty ? phone : 'Cash Payment',
        amount: totalCost,
      ),
    );

    // Call payment service
    final paymentRes = await PaymentService.instance.initiateMobilePayment(
      method: ref.read(bookingNotifierProvider).paymentMethod,
      phone: phone.isNotEmpty ? phone : 'Cash',
      usdAmount: totalCost,
    );

    // Dismiss dialog
    if (context.mounted) Navigator.pop(context);

    if (paymentRes.isSuccess) {
      // 1. Trigger haptic success
      Helpers.triggerHapticSuccess();

      // 2. Submit booking to backend
      final booking = await bookingNotifier.createNewBooking(
        carId: widget.carId,
        brandModel: '${car.brand} ${car.model}',
        plateNumber: car.plateNumber,
        pricePerDay: car.pricePerDay,
        imageUrl: car.images.isNotEmpty ? car.images.first : null,
        notes: _notesController.text,
      );

      if (booking != null) {
        // Complete payment registration
        await ref.read(bookingRepositoryProvider).updatePaymentStatus(booking.bookingId, PaymentStatus.paid, paymentRes.reference);
        ref.invalidate(userBookingsProvider);

        if (context.mounted) {
          // Success SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking confirmed! Ref: ${paymentRes.reference}'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to booking details
          context.pushReplacement(AppRoutes.getBookingDetailRoute(booking.bookingId));
        }
      } else {
        if (context.mounted) {
          final checkoutState = ref.read(bookingNotifierProvider);
          final errorMsg = checkoutState.errorEn ?? 'Payment succeeded but booking registration failed. Contact Admin.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.cancelled,
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentRes.errorMessageEn ?? 'Payment failed.'),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    }
  }
}

class _PaymentModal extends StatelessWidget {
  final PaymentMethod method;
  final String phone;
  final double amount;

  const _PaymentModal({
    required this.method,
    required this.phone,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZaad = method == PaymentMethod.zaad;
    final isCash = method == PaymentMethod.cash;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored logo dot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isCash ? AppColors.secondary : (isZaad ? Colors.green : Colors.orange),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                method.name.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            // Custom Spinner
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(isCash ? AppColors.secondary : (isZaad ? Colors.green : Colors.orange)),
            ),
            const SizedBox(height: 24),
            Text(
              isCash ? 'Registering Cash Order...' : 'USSD Push Sent',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isCash
                  ? 'Confirming booking. Please settle cash payment with Lessor upon vehicle pickup.'
                  : 'Please check your mobile screen and enter your PIN code to authorize \$${amount.toStringAsFixed(2)}.',
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (!isCash) ...[
              const SizedBox(height: 20),
              Text(
                'Sending to: $phone',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
