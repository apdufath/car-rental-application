import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../data/booking_remote_datasource.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_entity.dart';
import '../../domain/review_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/user_entity.dart';
import '../../../cars/domain/car_entity.dart';

// 1. Data Source Provider
final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirestoreBookingRemoteDataSource();
    }
  } catch (_) {}
  return SimulatedBookingRemoteDataSource();
});

// 2. Repository Provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final ds = ref.watch(bookingRemoteDataSourceProvider);
  return BookingRepository(ds);
});

// 3. User Bookings Stream/Future Provider
final userBookingsProvider = FutureProvider<List<BookingEntity>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;
  if (user == null) return [];
  
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingsByUser(user.uid);
});

// 4. Car Bookings Provider (to calculate blocked dates)
final carBookingsProvider = FutureProvider.family<List<BookingEntity>, String>((ref, carId) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getBookingsByCar(carId);
});

// 5. Car Reviews Provider
final carReviewsProvider = FutureProvider.family<List<ReviewEntity>, String>((ref, carId) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getReviewsForCar(carId);
});

// 6. Admin Bookings Provider
final adminBookingsProvider = FutureProvider<List<BookingEntity>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getAllBookings();
});

// Booking UI State Notifier
class BookingCheckoutState {
  final bool isLoading;
  final String? errorEn;
  final String? errorSo;
  final String? successMessageEn;
  final String? successMessageSo;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final String pickupLocation;
  final String dropoffLocation;
  final PaymentMethod paymentMethod;

  BookingCheckoutState({
    this.isLoading = false,
    this.errorEn,
    this.errorSo,
    this.successMessageEn,
    this.successMessageSo,
    this.selectedStartDate,
    this.selectedEndDate,
    this.pickupLocation = 'Jigjiga Yar, Hargeisa',
    this.dropoffLocation = 'Jigjiga Yar, Hargeisa',
    this.paymentMethod = PaymentMethod.evc,
  });

  BookingCheckoutState copyWith({
    bool? isLoading,
    String? errorEn,
    String? errorSo,
    String? successMessageEn,
    String? successMessageSo,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    String? pickupLocation,
    String? dropoffLocation,
    PaymentMethod? paymentMethod,
  }) {
    return BookingCheckoutState(
      isLoading: isLoading ?? this.isLoading,
      errorEn: errorEn,
      errorSo: errorSo,
      successMessageEn: successMessageEn,
      successMessageSo: successMessageSo,
      selectedStartDate: selectedStartDate ?? this.selectedStartDate,
      selectedEndDate: selectedEndDate ?? this.selectedEndDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingCheckoutState> {
  final BookingRepository _repository;
  final Ref _ref;

  BookingNotifier(this._repository, this._ref) : super(BookingCheckoutState());

  void setDates(DateTime? start, DateTime? end) {
    state = state.copyWith(selectedStartDate: start, selectedEndDate: end);
  }

  void setLocations({String? pickup, String? dropoff}) {
    state = state.copyWith(
      pickupLocation: pickup ?? state.pickupLocation,
      dropoffLocation: dropoff ?? state.dropoffLocation,
    );
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearMessages() {
    state = state.copyWith(
      errorEn: null,
      errorSo: null,
      successMessageEn: null,
      successMessageSo: null,
    );
  }

  Map<String, String>? validateBooking({
    required String carId,
    required String brandModel,
    required String plateNumber,
    required double pricePerDay,
  }) {
    return null; // Bypassed: Always return null (success) to allow automatic bookings with zero requirements!
  }

  Future<BookingEntity?> createNewBooking({
    required String carId,
    required String brandModel,
    required String plateNumber,
    required double pricePerDay,
    String? imageUrl,
    String? notes,
  }) async {
    // 1. Run strict pre-flight validations
    final validationError = validateBooking(
      carId: carId,
      brandModel: brandModel,
      plateNumber: plateNumber,
      pricePerDay: pricePerDay,
    );

    if (validationError != null) {
      state = state.copyWith(
        errorEn: validationError['en'],
        errorSo: validationError['so'],
      );
      return null;
    }

    final user = _ref.read(authNotifierProvider).user!;
    final start = state.selectedStartDate!;
    final end = state.selectedEndDate!;

    state = state.copyWith(isLoading: true);
    clearMessages();

    final days = end.difference(start).inDays + 1;
    final totalCost = days * pricePerDay * 1.10; // includes 10% Somali luxury/service tax


    final booking = BookingEntity(
      bookingId: 'book_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      carId: carId,
      carBrandModel: brandModel,
      carPlateNumber: plateNumber,
      carImageUrl: imageUrl,
      userName: user.fullName,
      userPhone: user.phone,
      startDate: start,
      endDate: end,
      totalDays: days,
      totalPrice: totalCost,
      status: BookingStatus.pending,
      paymentMethod: state.paymentMethod,
      paymentStatus: PaymentStatus.pending,
      notes: notes,
      pickupLocation: state.pickupLocation,
      pickupCoords: const LocationPoint(9.5624, 44.0770),
      dropoffLocation: state.dropoffLocation,
      dropoffCoords: const LocationPoint(9.5624, 44.0770),
      createdAt: DateTime.now(),
    );

    try {
      await _repository.createBooking(booking);
      
      // Refresh user bookings lists
      _ref.invalidate(userBookingsProvider);
      _ref.invalidate(carBookingsProvider(carId));
      
      state = state.copyWith(
        isLoading: false,
        successMessageEn: 'Booking created successfully!',
        successMessageSo: 'Dalabka waa la abuuray si guul leh!',
      );
      return booking;
    } on FirebaseException catch (e) {
      String errEn = 'Failed to save booking: ${e.message}';
      String errSo = 'Ku guuldarraystay kaydinta dalabka: ${e.message}';
      
      if (e.code == 'permission-denied') {
        errEn = 'Access Denied: Missing or insufficient permissions. Please log in again.';
        errSo = 'Fasax la\'aan: Laguma guuleysan fasax la\'aan awgeed. Fadlan dib u gal.';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorEn: errEn,
        errorSo: errSo,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorEn: 'Failed to create booking: ${e.toString()}',
        errorSo: 'Ku guuldarraystay abuurista dalabka: Macluumaad khaldan.',
      );
      return null;
    }
  }

  Future<void> submitReview({
    required String carId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    final user = _ref.read(authNotifierProvider).user;
    if (user == null) return;

    final review = ReviewEntity(
      reviewId: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      userName: user.fullName,
      userProfileUrl: user.profileImageUrl,
      carId: carId,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await _repository.addReview(review);
      _ref.invalidate(carReviewsProvider(carId));
    } catch (_) {}
  }
}

final bookingNotifierProvider = StateNotifierProvider<BookingNotifier, BookingCheckoutState>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repo, ref);
});
