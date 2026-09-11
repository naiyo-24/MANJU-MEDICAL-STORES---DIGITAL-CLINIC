import 'package:flutter/material.dart';
import '../../models/crm_models.dart';
import '../../services/crm_data_service.dart';

class CrmOrdersScreen extends StatefulWidget {
  const CrmOrdersScreen({super.key});

  @override
  State<CrmOrdersScreen> createState() => _CrmOrdersScreenState();
}

class _CrmOrdersScreenState extends State<CrmOrdersScreen> {
  List<CrmOrder> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orders = await CrmDataService.getOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: _buildDataGrid()),
                              const SizedBox(width: 24),
                              Expanded(flex: 3, child: _buildRightPane()),
                            ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Order Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text('Manage medicine orders from store, website or patient app', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Care Today', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  Row(
                    children: const [
                      Text('Healthier Tomorrow ', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                      Icon(Icons.eco, size: 16, color: Color(0xFF22C55E)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Orders', '128', Icons.shopping_bag, const Color(0xFF8B5CF6), null)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Delivered', '102', Icons.check_circle, const Color(0xFF22C55E), '80%')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('In Transit', '16', Icons.local_shipping, const Color(0xFF3B82F6), '12%')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Pending', '7', Icons.access_time_filled, const Color(0xFFF59E0B), '5%')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Cancelled', '3', Icons.cancel, const Color(0xFFEF4444), '3%')),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String? subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: const TextField(decoration: InputDecoration(hintText: 'Search orders...', prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 18, color: Color(0xFF8B5CF6)),
                            SizedBox(width: 8),
                            Text('01 Sep 2026 - 09 Sep 2026', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1E3A8A)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildDropdown('All Status')),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildDropdown('All Source')),
                const SizedBox(width: 16),
                Container(
                  height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                  child: TextButton(onPressed: () {}, child: const Text('Reset', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600))),
                ),
              ],
            ),
          ),
          
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Color(0xFFCBD5E1), size: 18)),
                const SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                const Expanded(flex: 2, child: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                const Expanded(flex: 2, child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                const Expanded(flex: 2, child: Text('Patient Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                const Expanded(flex: 1, child: Text('Items', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                const Expanded(flex: 1, child: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12), textAlign: TextAlign.right)),
                const Expanded(flex: 2, child: Align(alignment: Alignment.center, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12)))),
                const Expanded(flex: 1, child: Text('Source', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12))),
                const SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12), textAlign: TextAlign.center)),
              ],
            ),
          ),
          
          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: _orders.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 32, child: Icon(Icons.check_box_outline_blank, color: Color(0xFFCBD5E1), size: 18)),
                      SizedBox(width: 32, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 2, child: Text(order.id, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.date, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12)),
                            Text(order.time, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(order.patientName, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
                      Expanded(flex: 1, child: Text(order.itemsCount, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
                      Expanded(flex: 1, child: Text(order.total.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Align(alignment: Alignment.center, child: _buildStatusPill(order.status))),
                      Expanded(flex: 1, child: Text(order.source, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13))),
                      SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionIcon(Icons.visibility, const Color(0xFF1E3A8A), isSolid: true),
                            const SizedBox(width: 8),
                            _buildActionIcon(Icons.more_vert, const Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Pagination
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Showing 1 to 10 of 128 orders', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                Row(
                  children: [
                    _buildPageBtn(Icons.chevron_left, false),
                    _buildPageBtn('1', true),
                    _buildPageBtn('2', false),
                    _buildPageBtn('3', false),
                    _buildPageBtn('4', false),
                    _buildPageBtn('5', false),
                    _buildPageBtn('...', false),
                    _buildPageBtn('13', false),
                    _buildPageBtn(Icons.chevron_right, false),
                  ],
                ),
                Row(
                  children: [
                    const Text('Rows per page:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: const [
                          Text('10', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1E3A8A)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane() {
    if (_orders.isEmpty) return const SizedBox();
    final currentOrder = _orders.first;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      _buildStatusPill(currentOrder.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Metadata Grid
                  _buildDetailRow('Order ID', ': ${currentOrder.id}'),
                  _buildDetailRow('Date & Time', ': ${currentOrder.date}, ${currentOrder.time}'),
                  _buildDetailRow('Patient Name', ': ${currentOrder.patientName}'),
                  _buildDetailRow('Phone', ': 9830011223'),
                  _buildDetailRow('Delivery Address', ': 123, Main Road\n  Kolkata - 700016', isMultiLine: true),
                  _buildDetailRow('Source', ': Patient App'),
                  _buildDetailRow('Payment Mode', ': Online (UPI)'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 120, child: Text('Payment Status', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                        Expanded(
                          child: Row(
                            children: [
                              const Text(': ', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                                    SizedBox(width: 4),
                                    Text('Paid', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDetailRow('Delivery Type', ': Home Delivery'),
                  _buildDetailRow('Delivered On', ': 09 Sep 2026, 06:30 PM'),
                  _buildDetailRow('Notes', ': Thank you for choosing\n  Manju Medical Stores.', isMultiLine: true),
                  const SizedBox(height: 32),
                  
                  // Items Table
                  const Text('Items Ordered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(8)), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                          child: Row(
                            children: const [
                              SizedBox(width: 24, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 12))),
                              Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 12))),
                              Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 12), textAlign: TextAlign.center)),
                              Expanded(flex: 2, child: Text('Unit Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 12), textAlign: TextAlign.right)),
                              Expanded(flex: 2, child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 12), textAlign: TextAlign.right)),
                            ],
                          ),
                        ),
                        ...currentOrder.items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == currentOrder.items.length - 1 ? Colors.transparent : const Color(0xFFE2E8F0)))),
                            child: Row(
                              children: [
                                SizedBox(width: 24, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12))),
                                Expanded(flex: 3, child: Text(item.name, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12))),
                                Expanded(flex: 1, child: Text(item.qty.toString(), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12), textAlign: TextAlign.center)),
                                Expanded(flex: 2, child: Text(item.unitPrice.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 12), textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: Text(item.amount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 12), textAlign: TextAlign.right)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Summary Block
                  Row(
                    children: [
                      Expanded(flex: 3, child: const SizedBox()),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', '₹ 490.00'),
                            const SizedBox(height: 12),
                            _buildSummaryRow('Delivery Charge', '₹ 40.00'),
                            const SizedBox(height: 12),
                            _buildSummaryRow('Discount', '₹ 0.00'),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 14)),
                                  Text('₹ 530.00', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 18)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print Invoice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFFE9D5FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Reorder'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDropdown(String label) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 13, fontWeight: FontWeight.w500)),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1E3A8A)),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Delivered':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        break;
      case 'In Transit':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        break;
      case 'Pending':
        bgColor = const Color(0xFFFFEDD5);
        textColor = const Color(0xFFEA580C);
        break;
      case 'Cancelled':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: textColor),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, {bool isSolid = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isSolid ? const Color(0xFFF3E8FF) : Colors.white,
        border: Border.all(color: isSolid ? const Color(0xFFE9D5FF) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: Icon(icon, size: 14, color: color)),
    );
  }

  Widget _buildPageBtn(dynamic content, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
        border: Border.all(color: isActive ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: content is IconData
            ? Icon(content, size: 16, color: const Color(0xFF1E3A8A))
            : Text(content.toString(), style: TextStyle(color: isActive ? Colors.white : const Color(0xFF1E3A8A), fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
      ],
    );
  }
}
