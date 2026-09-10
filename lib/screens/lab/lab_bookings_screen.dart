import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';
import 'widgets/new_booking_modal.dart';

class LabBookingsScreen extends StatefulWidget {
  const LabBookingsScreen({super.key});

  @override
  State<LabBookingsScreen> createState() => _LabBookingsScreenState();
}

class _LabBookingsScreenState extends State<LabBookingsScreen> {
  List<LabBooking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final bookings = await LabDataService.getBookings();
    bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate)); // Newest first
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  void _showNewBookingModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: NewBookingModal(
          onBookingCreated: _loadData,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Sample Collected':
        return Colors.blue;
      case 'Processing':
        return Colors.purple;
      case 'Ready':
        return Colors.green;
      case 'Delivered':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Lab Bookings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Manage patient tests and package bookings', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients, bookings...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showNewBookingModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
                  : _bookings.isEmpty
                      ? const Center(child: Text('No bookings found', style: TextStyle(color: Color(0xFF64748B))))
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                              ),
                              child: Row(
                                children: const [
                                  Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                  Expanded(flex: 3, child: Text('PATIENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                  Expanded(flex: 3, child: Text('TESTS / PACKAGES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                  Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                  Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                                  SizedBox(width: 40),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _bookings.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                itemBuilder: (context, index) {
                                  final booking = _bookings[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            DateFormat('dd MMM yyyy\nhh:mm a').format(booking.bookingDate),
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(booking.patientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                              Text('${booking.patientAge} yrs • ${booking.patientGender}\n${booking.patientPhone}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '${booking.testIds.length} Tests\n${booking.packageIds.length} Packages',
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '₹${booking.totalAmount.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(booking.status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _getStatusColor(booking.status).withOpacity(0.5)),
                                            ),
                                            child: Text(
                                              booking.status,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor(booking.status)),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: PopupMenuButton(
                                            icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                                            onSelected: (value) {
                                              if (value == 'delete') {
                                                LabDataService.deleteBooking(booking.id);
                                                _loadData();
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(value: 'edit', child: Text('Edit Booking')),
                                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
