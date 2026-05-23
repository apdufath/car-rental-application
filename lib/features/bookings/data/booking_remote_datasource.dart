import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/booking_entity.dart';
import '../domain/review_entity.dart';
import '../../cars/domain/car_entity.dart';

abstract class BookingRemoteDataSource {
  Future<List<BookingEntity>> getAllBookings();
  Future<List<BookingEntity>> getBookingsByUser(String userId);
  Future<List<BookingEntity>> getBookingsByCar(String carId);
  Future<BookingEntity?> getBookingById(String bookingId);
  Future<void> createBooking(BookingEntity booking);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  Future<void> updatePaymentStatus(String bookingId, PaymentStatus paymentStatus, String? reference);
  Future<void> addReview(ReviewEntity review);
  Future<List<ReviewEntity>> getReviewsForCar(String carId);
}

class FirestoreBookingRemoteDataSource implements BookingRemoteDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<BookingEntity>> getAllBookings() async {
    final snapshot = await _db.collection('bookings').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => BookingEntity.fromMap(doc.data())).toList();
  }

  @override
  Future<List<BookingEntity>> getBookingsByUser(String userId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => BookingEntity.fromMap(doc.data())).toList();
  }

  @override
  Future<List<BookingEntity>> getBookingsByCar(String carId) async {
    final snapshot = await _db.collection('bookings').where('carId', isEqualTo: carId).get();
    return snapshot.docs.map((doc) => BookingEntity.fromMap(doc.data())).toList();
  }

  @override
  Future<BookingEntity?> getBookingById(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BookingEntity.fromMap(doc.data()!);
  }

  @override
  Future<void> createBooking(BookingEntity booking) async {
    // Write booking details
    await _db.collection('bookings').doc(booking.bookingId).set(booking.toMap());
    
    // Also, if payment is paid immediately, update availability if active
    try {
      if (booking.status == BookingStatus.active) {
        await _db.collection('cars').doc(booking.carId).update({'isAvailable': false});
      }
    } catch (e) {
      // Log warning but do not abort booking creation
      print('Warning: Failed to update car availability during booking creation: $e');
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _db.collection('bookings').doc(bookingId).update({'status': status.name});
    
    // Manage car availability based on booking status
    try {
      final doc = await _db.collection('bookings').doc(bookingId).get();
      if (doc.exists && doc.data() != null) {
        final booking = BookingEntity.fromMap(doc.data()!);
        if (status == BookingStatus.active) {
          await _db.collection('cars').doc(booking.carId).update({'isAvailable': false});
        } else if (status == BookingStatus.completed || status == BookingStatus.cancelled) {
          await _db.collection('cars').doc(booking.carId).update({'isAvailable': true});
        }
      }
    } catch (e) {
      // Log warning but do not abort booking status update
      print('Warning: Failed to update car availability during status update: $e');
    }
  }

  @override
  Future<void> updatePaymentStatus(String bookingId, PaymentStatus paymentStatus, String? reference) async {
    await _db.collection('bookings').doc(bookingId).update({
      'paymentStatus': paymentStatus.name,
      if (reference != null) 'paymentReference': reference,
      if (paymentStatus == PaymentStatus.paid) 'status': BookingStatus.approved.name,
    });
  }

  @override
  Future<void> addReview(ReviewEntity review) async {
    await _db.collection('reviews').doc(review.reviewId).set(review.toMap());
    
    // Recalculate car average rating
    final carRef = _db.collection('cars').doc(review.carId);
    final reviewsSnapshot = await _db.collection('reviews').where('carId', isEqualTo: review.carId).get();
    
    if (reviewsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }
      final avg = totalRating / reviewsSnapshot.docs.length;
      await carRef.update({
        'averageRating': avg,
        'totalReviews': reviewsSnapshot.docs.length,
      });
    }
  }

  @override
  Future<List<ReviewEntity>> getReviewsForCar(String carId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('carId', isEqualTo: carId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => ReviewEntity.fromMap(doc.data())).toList();
  }
}

class SimulatedBookingRemoteDataSource implements BookingRemoteDataSource {
  static final Map<String, BookingEntity> _simulatedBookings = {};
  static final Map<String, List<ReviewEntity>> _simulatedReviews = {};

  SimulatedBookingRemoteDataSource() {
    if (_simulatedBookings.isEmpty) {
      final now = DateTime.now();
      
      // Preseed some mock bookings
      final list = [
        BookingEntity(
          bookingId: 'book_1',
          userId: 'user123', // Admin user / Default simulator user
          carId: 'car_vitz_2',
          carBrandModel: 'Toyota Vitz',
          carPlateNumber: 'SL 1234 HR',
          carImageUrl: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=600&q=80',
          userName: 'Mohamed Ali',
          userPhone: '+252634455667',
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.subtract(const Duration(days: 2)),
          totalDays: 3,
          totalPrice: 54.0,
          status: BookingStatus.completed,
          paymentMethod: PaymentMethod.zaad,
          paymentStatus: PaymentStatus.paid,
          paymentReference: 'ZAAD-872361-TXT',
          notes: 'Kireysi kooban oo magaalada dhexdeeda ah.',
          pickupLocation: 'Jigjiga Yar, Hargeisa',
          pickupCoords: const LocationPoint(9.5750, 44.0680),
          dropoffLocation: 'Jigjiga Yar, Hargeisa',
          dropoffCoords: const LocationPoint(9.5750, 44.0680),
          createdAt: now.subtract(const Duration(days: 6)),
        ),
        BookingEntity(
          bookingId: 'book_2',
          userId: 'customer_sim', // Simulated customer
          carId: 'car_v8_1',
          carBrandModel: 'Toyota Land Cruiser V8',
          carPlateNumber: 'SL 5234 HR',
          carImageUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=600&q=80',
          userName: 'Faduma Omar',
          userPhone: '+252634998877',
          startDate: now.add(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 4)),
          totalDays: 3,
          totalPrice: 270.0,
          status: BookingStatus.approved,
          paymentMethod: PaymentMethod.evc,
          paymentStatus: PaymentStatus.paid,
          paymentReference: 'EVC-991823-REF',
          notes: 'Macaamiil muhiim ah oo u baahan gaariga in la keeno hudheelka.',
          pickupLocation: "Sha'ab, Hargeisa",
          pickupCoords: const LocationPoint(9.5624, 44.0770),
          dropoffLocation: "Sha'ab, Hargeisa",
          dropoffCoords: const LocationPoint(9.5624, 44.0770),
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        BookingEntity(
          bookingId: 'book_3',
          userId: 'user123', // Admin user / Default simulator user
          carId: 'car_lx570_4',
          carBrandModel: 'Lexus LX570 VIP',
          carPlateNumber: 'SL 9999 HR',
          carImageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=600&q=80',
          userName: 'Mohamed Ali',
          userPhone: '+252634455667',
          startDate: now.add(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 10)),
          totalDays: 3,
          totalPrice: 450.0,
          status: BookingStatus.pending,
          paymentMethod: PaymentMethod.zaad,
          paymentStatus: PaymentStatus.pending,
          notes: 'Munaasabad aroos ah.',
          pickupLocation: "Sha'ab, Hargeisa",
          pickupCoords: const LocationPoint(9.5600, 44.0820),
          dropoffLocation: "Sha'ab, Hargeisa",
          dropoffCoords: const LocationPoint(9.5600, 44.0820),
          createdAt: now.subtract(const Duration(hours: 4)),
        ),
      ];

      for (var b in list) {
        _simulatedBookings[b.bookingId] = b;
      }
    }

    if (_simulatedReviews.isEmpty) {
      _simulatedReviews['car_v8_1'] = [
        ReviewEntity(
          reviewId: 'rev_1',
          userId: 'usr_abc',
          userName: 'Abdirahman Yusuf',
          userProfileUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
          carId: 'car_v8_1',
          bookingId: 'book_sim_1',
          rating: 5.0,
          comment: 'Gaariga aad buu u fiicnaa, awoodiisuna waa boqolkiiba boqol. Aad baan ugu qancay.',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
        ReviewEntity(
          reviewId: 'rev_2',
          userId: 'usr_xyz',
          userName: 'Amira Ahmed',
          userProfileUrl: null,
          carId: 'car_v8_1',
          bookingId: 'book_sim_2',
          rating: 4.8,
          comment: 'Adeeg aad u wanaagsan iyo gaari nadiif ah. Mahadsantihiin.',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ];
      
      _simulatedReviews['car_vitz_2'] = [
        ReviewEntity(
          reviewId: 'rev_3',
          userId: 'user123',
          userName: 'Mohamed Ali',
          userProfileUrl: null,
          carId: 'car_vitz_2',
          bookingId: 'book_1',
          rating: 4.5,
          comment: 'Gaarigu wuxuu ahaa mid aad u dhaqaale badan. Wax cillad ah ma lahayn.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        )
      ];
    }
  }

  @override
  Future<List<BookingEntity>> getAllBookings() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _simulatedBookings.values.toList();
  }

  @override
  Future<List<BookingEntity>> getBookingsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _simulatedBookings.values.where((b) => b.userId == userId).toList();
  }

  @override
  Future<List<BookingEntity>> getBookingsByCar(String carId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _simulatedBookings.values.where((b) => b.carId == carId).toList();
  }

  @override
  Future<BookingEntity?> getBookingById(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _simulatedBookings[bookingId];
  }

  @override
  Future<void> createBooking(BookingEntity booking) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _simulatedBookings[booking.bookingId] = booking;
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final booking = _simulatedBookings[bookingId];
    if (booking != null) {
      _simulatedBookings[bookingId] = booking.copyWith(status: status);
    }
  }

  @override
  Future<void> updatePaymentStatus(String bookingId, PaymentStatus paymentStatus, String? reference) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final booking = _simulatedBookings[bookingId];
    if (booking != null) {
      _simulatedBookings[bookingId] = booking.copyWith(
        paymentStatus: paymentStatus,
        paymentReference: reference,
        status: paymentStatus == PaymentStatus.paid ? BookingStatus.approved : booking.status,
      );
    }
  }

  @override
  Future<void> addReview(ReviewEntity review) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final reviews = _simulatedReviews[review.carId] ?? [];
    reviews.insert(0, review);
    _simulatedReviews[review.carId] = reviews;
  }

  @override
  Future<List<ReviewEntity>> getReviewsForCar(String carId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _simulatedReviews[carId] ?? [];
  }
}
