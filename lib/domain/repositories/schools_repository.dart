import '../entities/booking.dart';
import '../entities/school.dart';

abstract class SchoolsRepository {
  Future<List<School>> getSchools();
  Future<School> getSchool(String id);
  Future<Booking> createBooking({
    required String userId,
    required String schoolId,
    required String vehicleCategory,
    required String scheduledDate,
    required int amount,
  });
  Future<List<Booking>> getUserBookings(String userId);
}
