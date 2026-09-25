import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/customer_service.dart';
import '../services/billing_service.dart';

class CustomerNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetchCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  Future<List<Map<String, dynamic>>> _fetchCustomers() async {
    final realCustomers = await CustomerService.getCustomers();

    List<dynamic> historyList = [];
    try {
      final response = await BillingService.getPosHistory();
      historyList = response['history'] as List? ?? [];
    } catch (e) {
      // Ignore if billing service fails
    }

    final List<Map<String, dynamic>> mappedRealCustomers = realCustomers
        .map<Map<String, dynamic>>((c) {
          final names = c.name.split(' ');
          final initials = names.length > 1
              ? '${names[0][0]}${names[1][0]}'.toUpperCase()
              : c.name.isNotEmpty
              ? c.name[0].toUpperCase()
              : 'C';

          final custHistory = historyList.where((h) {
            if (c.phone.isNotEmpty && h['customer_phone'] == c.phone) {
              return true;
            }
            if (c.name.isNotEmpty && h['customer_name'] == c.name) return true;
            return false;
          }).toList();

          double totalPurchases = 0.0;
          DateTime? lastPurchaseDate;

          for (var h in custHistory) {
            totalPurchases += (h['amount'] as num?)?.toDouble() ?? 0.0;
            String dateStr = h['date'].toString();
            if (!dateStr.endsWith('Z')) dateStr += 'Z';
            final dt = DateTime.tryParse(dateStr)?.toLocal();
            if (dt != null) {
              if (lastPurchaseDate == null || dt.isAfter(lastPurchaseDate)) {
                lastPurchaseDate = dt;
              }
            }
          }

          return {
            'full_id': c.id,
            'id': c.id.substring(c.id.length > 8 ? c.id.length - 8 : 0),
            'name': c.name,
            'initials': initials,
            'phone': c.phone,
            'email': c.email.isNotEmpty ? c.email : 'N/A',
            'city': c.location.isNotEmpty ? c.location : 'Local',
            'totalPurchases': totalPurchases,
            'bills': custHistory.length,
            'lastPurchase': lastPurchaseDate != null
                ? DateFormat('dd MMM yyyy').format(lastPurchaseDate)
                : 'N/A',
            'status': c.isActive ? 'Active' : 'Inactive',
            'memberSince': c.createdAt != null
                ? DateFormat('MMM yyyy').format(DateTime.parse(c.createdAt!))
                : 'Unknown',
            'history': custHistory,
          };
        })
        .toList();

    return mappedRealCustomers;
  }
}
