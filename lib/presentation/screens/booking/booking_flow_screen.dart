import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/school.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 1;
  String _category = 'B';
  DateTime? _date;
  bool _submitting = false;
  String? _bookingId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book lesson')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please sign in to book.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    final schoolAsync = ref.watch(schoolProvider(widget.schoolId));

    return schoolAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString()),
      ),
      data: (school) {
        final category = school.vehicleCategories.contains(_category)
            ? _category
            : (school.vehicleCategories.isNotEmpty
                ? school.vehicleCategories.first
                : _category);

        return Scaffold(
          appBar: AppBar(title: Text(school.name)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StepIndicator(current: _step),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildStepContent(school, user.id, category),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepContent(School school, String userId, String category) {
    switch (_step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 1: Confirm school', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(school.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${school.town}, ${school.county}', style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => setState(() => _step = 2), child: const Text('Continue')),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 2: Vehicle category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: school.vehicleCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text('Category $c')))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'B'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(onPressed: () => setState(() => _step = 1), child: const Text('Back')),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _step = 3),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 3: Choose date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _date == null
                    ? 'Select date'
                    : DateFormat.yMMMd().format(_date!),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(onPressed: () => setState(() => _step = 2), child: const Text('Back')),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _date == null ? null : () => setState(() => _step = 4),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 4: Confirm & pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _SummaryRow(label: 'School', value: school.name),
            _SummaryRow(label: 'Category', value: category),
            _SummaryRow(
              label: 'Date',
              value: _date == null ? '—' : DateFormat.yMMMd().format(_date!),
            ),
            _SummaryRow(label: 'Amount', value: 'KSh ${school.priceFrom}'),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(onPressed: () => setState(() => _step = 3), child: const Text('Back')),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () => _confirmBooking(school, userId, category),
                    child: Text(_submitting ? 'Booking…' : 'Confirm booking'),
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Booking confirmed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_bookingId != null) ...[
              const SizedBox(height: 8),
              Text('Reference: $_bookingId', style: const TextStyle(color: AppColors.textMuted)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/profile'),
              child: const Text('View my bookings'),
            ),
          ],
        );
    }
  }

  Future<void> _confirmBooking(
    School school,
    String userId,
    String category,
  ) async {
    setState(() => _submitting = true);
    try {
      final booking = await ref.read(schoolsRepositoryProvider).createBooking(
            userId: userId,
            schoolId: widget.schoolId,
            vehicleCategory: category,
            scheduledDate: DateFormat('yyyy-MM-dd').format(_date!),
            amount: school.priceFrom,
          );
      ref.invalidate(userBookingsProvider);
      setState(() {
        _bookingId = booking.id;
        _step = 5;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final step = i + 1;
        final active = current >= step;
        return Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: active ? AppColors.primary : Colors.grey.shade300,
              child: Text(
                '$step',
                style: TextStyle(
                  color: active ? Colors.white : Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (step < 5)
              Container(
                width: 24,
                height: 2,
                color: current > step ? AppColors.primary : Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
