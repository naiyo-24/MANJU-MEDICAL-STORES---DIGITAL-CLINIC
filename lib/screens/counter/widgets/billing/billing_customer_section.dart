import 'package:flutter/material.dart';
import '../../../../services/doctor_service.dart';
import '../../../../notifiers/billing_notifier.dart';

class BillingCustomerSection extends StatefulWidget {
  final BillingState billingState;
  final BillingNotifier notifier;
  final Widget customerSearchField;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController customerLocationController;
  final TextEditingController newDoctorController;
  final List<Doctor> doctorsList;
  final Function(Doctor?)? onDoctorChanged;
  final VoidCallback onSaveCustomerToDb;

  const BillingCustomerSection({
    super.key,
    required this.billingState,
    required this.notifier,
    required this.customerSearchField,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.customerLocationController,
    required this.newDoctorController,
    required this.doctorsList,
    required this.onSaveCustomerToDb,
    this.onDoctorChanged,
  });

  @override
  State<BillingCustomerSection> createState() => _BillingCustomerSectionState();
}

class _BillingCustomerSectionState extends State<BillingCustomerSection> {
  bool _isExpanded = true;

Widget _buildCompactField(
  BuildContext context,
  String label,
  TextEditingController controller, {
  bool isNumber = false,
  String? hint,
  Function(String)? onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 32,
        child: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return       // Customer Details
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(8),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.person,
                        color: Color(0xFF166534),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Customer Details (Optional)',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF166534),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  widget.customerSearchField,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactField(
                          context,
                          'Name',
                          widget.customerNameController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactField(
                          context,
                          'Phone',
                          widget.customerPhoneController,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildCompactField(
                    context,
                    'Location / Address',
                    widget.customerLocationController,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor Name',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: widget.billingState.selectedDoctorId,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 14,
                            ),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                if (newValue == 'walk-in') {
                                  widget.notifier.updateDoctor(
                                    'walk-in',
                                    'Walk-in',
                                  );
                                } else if (newValue == 'new') {
                                  widget.notifier.updateDoctor(
                                    'new',
                                    'New Doctor',
                                  );
                                } else {
                                  final doc = widget.doctorsList.firstWhere(
                                    (d) => d.id == newValue,
                                  );
                                  widget.notifier.updateDoctor(newValue, doc.name);
                                }
                              }
                            },
                            items: [
                              const DropdownMenuItem(
                                value: 'walk-in',
                                child: Text('Walk-in'),
                              ),
                              ...widget.doctorsList.map(
                                (doc) => DropdownMenuItem(
                                  value: doc.id,
                                  child: Text(doc.name),
                                ),
                              ),
                              const DropdownMenuItem(
                                value: 'new',
                                child: Text('+ Add New Doctor'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.billingState.selectedDoctorId == 'new') ...[
                        const SizedBox(height: 4),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: TextField(
                            controller: widget.newDoctorController,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter doctor name',
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: widget.onSaveCustomerToDb,
                      icon: const Icon(
                        Icons.person_add,
                        size: 14,
                        color: Color(0xFF22C55E),
                      ),
                      label: const Text(
                        'Save to DB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        backgroundColor: const Color(0xFFDCFCE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}
