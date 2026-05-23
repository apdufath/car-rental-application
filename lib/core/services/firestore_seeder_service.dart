import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/user_entity.dart';
import '../../features/cars/domain/car_entity.dart';
import '../../features/bookings/domain/booking_entity.dart';
import '../../features/bookings/domain/review_entity.dart';
import '../../features/profile/domain/notification_entity.dart';

class FirestoreSeederService {
  FirestoreSeederService._();

  static final FirestoreSeederService instance = FirestoreSeederService._();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Main function to seed all 5 collections with rich mock data
  Future<void> seedAllCollections() async {
    final now = DateTime.now();

    // 1. SEED USERS COLLECTION
    final List<UserEntity> users = [
      UserEntity(
        uid: 'admin123',
        fullName: 'Saeed Mohamed',
        phone: '+252634444444',
        email: 'saeed@abaarso.com',
        role: UserRole.admin,
        profileImageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        isVerified: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      UserEntity(
        uid: 'baashe123',
        fullName: 'Baashe',
        phone: '+252637777777',
        email: 'baashe@abaarso.com',
        role: UserRole.admin,
        profileImageUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        isVerified: true,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      UserEntity(
        uid: 'customer123',
        fullName: 'Khadra Ali',
        phone: '+252635555555',
        email: 'khadra@gmail.com',
        role: UserRole.customer,
        profileImageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
        isVerified: false,
        licenseImageUrl: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?auto=format&fit=crop&w=600&q=80',
        idCardImageUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      UserEntity(
        uid: 'driver123',
        fullName: 'Yusuf Ibrahim',
        phone: '+252636666666',
        email: 'yusuf@abaarso.com',
        role: UserRole.driver,
        profileImageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
        isVerified: true,
        licenseImageUrl: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?auto=format&fit=crop&w=600&q=80',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
    ];

    for (var user in users) {
      await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    }

    // 2. SEED CARS COLLECTION
    final List<CarEntity> cars = [
      CarEntity(
        carId: 'car_v8_1',
        brand: 'Toyota',
        model: 'Land Cruiser V8',
        year: 2021,
        color: 'Pearl White',
        plateNumber: 'SL 5234 HR',
        category: CarCategory.suv,
        pricePerDay: 90.0,
        currency: 'USD',
        isAvailable: true,
        features: ['AC', 'GPS', '4WD', 'Automatic', 'Leather Seats', 'Sunroof'],
        images: [
          'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=600&q=80',
        ],
        location: const LocationPoint(9.5624, 44.0770), // Sha'ab, Hargeisa
        locationName: "Sha'ab, Hargeisa",
        ownerId: 'admin123',
        averageRating: 4.9,
        totalReviews: 2,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      CarEntity(
        carId: 'car_vitz_2',
        brand: 'Toyota',
        model: 'Vitz',
        year: 2018,
        color: 'Silver Grey',
        plateNumber: 'SL 1234 HR',
        category: CarCategory.sedan,
        pricePerDay: 18.0,
        currency: 'USD',
        isAvailable: true,
        features: ['AC', 'Automatic', 'Bluetooth', 'USB Charger', 'Keyless entry'],
        images: [
          'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=600&q=80',
        ],
        location: const LocationPoint(9.5750, 44.0680), // Jigjiga Yar, Hargeisa
        locationName: "Jigjiga Yar, Hargeisa",
        ownerId: 'admin123',
        averageRating: 4.5,
        totalReviews: 1,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      CarEntity(
        carId: 'car_hilux_3',
        brand: 'Toyota',
        model: 'Hilux Revo',
        year: 2020,
        color: 'Metallic Grey',
        plateNumber: 'SL 8765 HR',
        category: CarCategory.pickup,
        pricePerDay: 55.0,
        currency: 'USD',
        isAvailable: true,
        features: ['AC', '4WD', 'Manual', 'GPS', 'Bluetooth', 'Heavy Suspension'],
        images: [
          'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=600&q=80',
        ],
        location: const LocationPoint(9.5540, 44.0720), // 26 June, Hargeisa
        locationName: "26 June, Hargeisa",
        ownerId: 'admin123',
        averageRating: 0.0,
        totalReviews: 0,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      CarEntity(
        carId: 'car_lx570_4',
        brand: 'Lexus',
        model: 'LX570 VIP',
        year: 2022,
        color: 'Black Metallic',
        plateNumber: 'SL 9999 HR',
        category: CarCategory.luxury,
        pricePerDay: 150.0,
        currency: 'USD',
        isAvailable: true,
        features: ['AC', 'GPS', '4WD', 'Automatic', 'Massage Seats', 'Bulletproof Glass', 'Premium Audio'],
        images: [
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=600&q=80',
        ],
        location: const LocationPoint(9.5600, 44.0820), // Sha'ab (Villas), Hargeisa
        locationName: "Sha'ab, Hargeisa",
        ownerId: 'admin123',
        averageRating: 0.0,
        totalReviews: 0,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      CarEntity(
        carId: 'car_noah_5',
        brand: 'Toyota',
        model: 'Noah',
        year: 2017,
        color: 'Dark Blue',
        plateNumber: 'SL 6423 HR',
        category: CarCategory.minibus,
        pricePerDay: 30.0,
        currency: 'USD',
        isAvailable: true,
        features: ['AC', 'Automatic', 'Dual Sliding Doors', '7-Seats', 'Reverse Camera'],
        images: [
          'https://images.unsplash.com/photo-1502877338535-766e1452684a?auto=format&fit=crop&w=600&q=80',
        ],
        location: const LocationPoint(9.5490, 44.0530), // Xeedho, Hargeisa
        locationName: "Xeedho, Hargeisa",
        ownerId: 'admin123',
        averageRating: 0.0,
        totalReviews: 0,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];

    for (var car in cars) {
      await _db.collection('cars').doc(car.carId).set(car.toMap(), SetOptions(merge: true));
    }

    // 3. SEED BOOKINGS COLLECTION
    final List<BookingEntity> bookings = [
      BookingEntity(
        bookingId: 'book_1',
        userId: 'customer123',
        carId: 'car_vitz_2',
        carBrandModel: 'Toyota Vitz',
        carPlateNumber: 'SL 1234 HR',
        carImageUrl: 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=600&q=80',
        userName: 'Khadra Ali',
        userPhone: '+252635555555',
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
        userId: 'customer123',
        carId: 'car_v8_1',
        carBrandModel: 'Toyota Land Cruiser V8',
        carPlateNumber: 'SL 5234 HR',
        carImageUrl: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=600&q=80',
        userName: 'Khadra Ali',
        userPhone: '+252635555555',
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 4)),
        totalDays: 3,
        totalPrice: 270.0,
        status: BookingStatus.approved, // Will be stored as 'confirmed'
        paymentMethod: PaymentMethod.evc, // Will be stored as 'evc_plus'
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
        userId: 'customer123',
        carId: 'car_lx570_4',
        carBrandModel: 'Lexus LX570 VIP',
        carPlateNumber: 'SL 9999 HR',
        carImageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=600&q=80',
        userName: 'Khadra Ali',
        userPhone: '+252635555555',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 10)),
        totalDays: 3,
        totalPrice: 450.0,
        status: BookingStatus.pending,
        paymentMethod: PaymentMethod.zaad,
        paymentStatus: PaymentStatus.pending, // Will be stored as 'unpaid'
        notes: 'Munaasabad aroos ah.',
        pickupLocation: "Sha'ab, Hargeisa",
        pickupCoords: const LocationPoint(9.5600, 44.0820),
        dropoffLocation: "Sha'ab, Hargeisa",
        dropoffCoords: const LocationPoint(9.5600, 44.0820),
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];

    for (var booking in bookings) {
      await _db.collection('bookings').doc(booking.bookingId).set(booking.toMap(), SetOptions(merge: true));
    }

    // Dynamic Seeding for Custom Cars:
    // If the database has other cars (like custom cars created by the user),
    // automatically generate active/completed bookings for them so they show up beautifully!
    try {
      final carsSnapshot = await _db.collection('cars').get();
      for (var doc in carsSnapshot.docs) {
        final carId = doc.id;
        // Check if this is a custom user-created car
        if (carId == 'car_1779451781731' || 
            (!carId.startsWith('car_v8_') && 
             !carId.startsWith('car_vitz_') && 
             !carId.startsWith('car_hilux_') && 
             !carId.startsWith('car_lx570_') && 
             !carId.startsWith('car_noah_'))) {
          
          final data = doc.data();
          final brand = data['brand'] as String? ?? 'Custom';
          final model = data['model'] as String? ?? 'Vehicle';
          final plateNumber = data['plateNumber'] as String? ?? 'SL 7777 HR';
          final price = (data['pricePerDay'] as num? ?? 45.0).toDouble();
          final imagesList = data['images'] as List?;
          final carImg = (imagesList != null && imagesList.isNotEmpty) ? imagesList.first as String : null;

          final dynamicBooking = BookingEntity(
            bookingId: 'book_custom_$carId',
            userId: 'customer123',
            carId: carId,
            carBrandModel: '$brand $model',
            carPlateNumber: plateNumber,
            carImageUrl: carImg,
            userName: 'Khadra Ali',
            userPhone: '+252635555555',
            startDate: now.subtract(const Duration(days: 1)),
            endDate: now.add(const Duration(days: 2)),
            totalDays: 3,
            totalPrice: price * 3 * 1.10, // includes 10% Somali luxury/service tax
            status: BookingStatus.active,
            paymentMethod: PaymentMethod.evc,
            paymentStatus: PaymentStatus.paid,
            paymentReference: 'EVC-883719-TX',
            notes: 'Si toos ah ayaa loogu dalbaday gaariga dhawaan la diiwaan geliyay.',
            pickupLocation: 'Jigjiga Yar, Hargeisa',
            pickupCoords: const LocationPoint(9.5750, 44.0680),
            dropoffLocation: 'Jigjiga Yar, Hargeisa',
            dropoffCoords: const LocationPoint(9.5750, 44.0680),
            createdAt: now.subtract(const Duration(days: 2)),
          );

          await _db.collection('bookings').doc(dynamicBooking.bookingId).set(dynamicBooking.toMap(), SetOptions(merge: true));
        }
      }
    } catch (_) {
      // Bypassed if offline or standard Firestore error
    }

    // 4. SEED REVIEWS COLLECTION
    final List<ReviewEntity> reviews = [
      ReviewEntity(
        reviewId: 'rev_1',
        userId: 'customer123',
        userName: 'Khadra Ali',
        userProfileUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
        carId: 'car_v8_1',
        bookingId: 'book_sim_1',
        rating: 5.0,
        comment: 'Gaariga aad buu u fiicnaa, awoodiisuna waa boqolkiiba boqol. Aad baan ugu qancay.',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      ReviewEntity(
        reviewId: 'rev_2',
        userId: 'driver123',
        userName: 'Yusuf Ibrahim',
        userProfileUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
        carId: 'car_v8_1',
        bookingId: 'book_sim_2',
        rating: 4.8,
        comment: 'Adeeg aad u wanaagsan iyo gaari nadiif ah. Mahadsantihiin.',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      ReviewEntity(
        reviewId: 'rev_3',
        userId: 'customer123',
        userName: 'Khadra Ali',
        userProfileUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
        carId: 'car_vitz_2',
        bookingId: 'book_1',
        rating: 4.5,
        comment: 'Gaarigu wuxuu ahaa mid aad u dhaqaale badan. Wax cillad ah ma lahayn.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    for (var review in reviews) {
      await _db.collection('reviews').doc(review.reviewId).set(review.toMap(), SetOptions(merge: true));
    }

    // 5. SEED NOTIFICATIONS COLLECTION
    final List<NotificationEntity> notifications = [
      NotificationEntity(
        notificationId: 'notif_1',
        userId: 'admin123',
        title: 'Codsiga Kireysiga / New Booking Request',
        body: 'Waxaad heshay codsi cusub oo Lexus LX570 VIP ah oo ka yimid Khadra Ali.',
        type: 'booking',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      NotificationEntity(
        notificationId: 'notif_2',
        userId: 'customer123',
        title: 'Hubinta KYC / Profile Verification Pending',
        body: 'Liisankaaga kaxaynta iyo kaarkaaga aqoonsiga ayaa hadda gacanta lagu hayaa.',
        type: 'system',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      NotificationEntity(
        notificationId: 'notif_3',
        userId: 'customer123',
        title: 'Dalabka La Xaqiijiyay / Booking Confirmed!',
        body: 'Kireysigaaga Toyota Land Cruiser V8 waa la xaqiijiyay. Waa ku kan koodka tixraacu: EVC-991823-REF.',
        type: 'booking',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];

    for (var notification in notifications) {
      await _db.collection('notifications').doc(notification.notificationId).set(notification.toMap(), SetOptions(merge: true));
    }
  }
}
