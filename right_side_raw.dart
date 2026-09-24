Widget rightSide = Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Current Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                InkWell(
                                  onTap: _clearCart,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                      const SizedBox(width: 4),
                                      const Text('Clear All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bill Table
                          _buildConditionalExpanded(
                            hasEnoughHeight,
                            LayoutBuilder(builder: (context, tableConstraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 500,
                                    maxWidth: tableConstraints.maxWidth > 500 ? tableConstraints.maxWidth : 500,
                                  ),
                                  child: Column(
                                    children: [
                                      // Bill Table Header
                                      Container(
                                        color: const Color(0xFFF8FAFC),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: const Row(
                                          children: [
                                            SizedBox(width: 20, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                            Expanded(flex: 3, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                            Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                            Expanded(flex: 2, child: Text('Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                            Expanded(flex: 2, child: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                            SizedBox(width: 45, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 10))),
                                          ],
                                        ),
                                      ),

                                      // Bill Table Body
                                      Expanded(
                                        child: _currentBill.isEmpty
                                            ? const Center(child: Text('Cart is empty', style: TextStyle(color: Color(0xFF94A3B8))))
                                            : ListView.separated(
                                          itemCount: _currentBill.length,
                                          separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                          itemBuilder: (context, index) {
                                            final item = _currentBill[index];
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 20, child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 11)),
                                                        Text(item['brand'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            InkWell(
                                                              onTap: () => _decreaseQty(index),
                                                              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Icon(Icons.remove, size: 14)),
                                                            ),
                                                            Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                            InkWell(
                                                              onTap: () => _increaseQty(index),
                                                              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: Icon(Icons.add, size: 14)),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(flex: 2, child: Text(item['price'].toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11))),
                                                  Expanded(flex: 2, child: Text(item['total'].toStringAsFixed(2), style: const TextStyle(color: Color(0xFF1E293B), fontSize: 11))),
                                                  SizedBox(
                                                    width: 45,
                                                    child: InkWell(
                                                      onTap: () => _removeItem(index),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                                                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 14),
                                                      ),
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
                              );
                            }),
                          ),

                          // Customer Details
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: const BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.person, color: Color(0xFF166534), size: 16),
                                          SizedBox(width: 8),
                                          Text('Customer Details (Optional)', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                      const Icon(Icons.keyboard_arrow_up, color: Color(0xFF166534), size: 16),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      _buildCustomerSearchField(),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(child: _buildCompactField('Name', _customerNameController)),
                                          const SizedBox(width: 8),
                                          Expanded(child: _buildCompactField('Phone', _customerPhoneController, isNumber: true)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCompactField('Location / Address', _customerLocationController),
                                      const SizedBox(height: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Doctor Name', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Container(
                                                  height: 32,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<String>(
                                                      value: _selectedDoctorId,
                                                      isExpanded: true,
                                                      icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
                                                      onChanged: (String? newValue) {
                                                        if (newValue != null) {
                                                          setState(() {
                                                            _selectedDoctorId = newValue;
                                                            if (newValue == 'walk-in') {
                                                              _selectedDoctorName = 'Walk-in';
                                                            } else if (newValue == 'new') {
                                                              _selectedDoctorName = 'New Doctor';
                                                            } else {
                                                              final doc = _doctorsList.firstWhere((d) => d.id == newValue);
                                                              _selectedDoctorName = doc.name;
                                                            }
                                                          });
                                                        }
                                                      },
                                                      items: [
                                                        const DropdownMenuItem(value: 'walk-in', child: Text('Walk-in')),
                                                        ..._doctorsList.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.name))),
                                                        const DropdownMenuItem(value: 'new', child: Text('+ Add New Doctor')),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                if (_selectedDoctorId == 'new') ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    height: 32,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                                                    child: TextField(
                                                      controller: _newDoctorController,
                                                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E293B)),
                                                      decoration: const InputDecoration(
                                                        hintText: 'Enter doctor name',
                                                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                                        border: InputBorder.none,
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                                          onPressed: _saveCustomerToDb,
                                          icon: const Icon(Icons.person_add, size: 14, color: Color(0xFF22C55E)),
                                          label: const Text('Save to DB', style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                                            minimumSize: Size.zero,
                                            backgroundColor: const Color(0xFFDCFCE7),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bill Summary
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Items', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Text('$_totalItems', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                    Text('₹ ${_subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const SizedBox(width: 80, child: Text('Discount', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                    Container(
                                      width: 80,
                                      height: 32,
                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                                      child: TextField(
                                        controller: _discountController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: '0.00'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => setState(() => _isDiscountPercentage = true),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: _isDiscountPercentage ? const Color(0xFF22C55E) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                                              child: Text('%', style: TextStyle(color: _isDiscountPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => setState(() => _isDiscountPercentage = false),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: !_isDiscountPercentage ? const Color(0xFF22C55E) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                                              child: Text('₹', style: TextStyle(color: !_isDiscountPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text('- ₹ ${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const SizedBox(width: 80, child: Text('Tax (GST)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                                    Container(
                                      width: 80,
                                      height: 32,
                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(6)),
                                      child: TextField(
                                        controller: _gstController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: '0.00'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 32,
                                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => setState(() => _isGstPercentage = true),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: _isGstPercentage ? const Color(0xFF22C55E) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                                              child: Text('%', style: TextStyle(color: _isGstPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => setState(() => _isGstPercentage = false),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: !_isGstPercentage ? const Color(0xFF22C55E) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                                              child: Text('₹', style: TextStyle(color: !_isGstPercentage ? Colors.white : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text('₹ ${_gstAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Grand Total', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('₹ ${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900, fontSize: 16)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text('Payment:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: ['CASH', 'UPI', 'CARD'].map((method) {
                                            bool isSelected = _paymentMethod == method;
                                            return Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _paymentMethod = method;
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    method,
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text('Format:', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: ['A4', 'A5', 'Thermal'].map((format) {
                                            bool isSelected = _selectedFormat == format;
                                            return Expanded(
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedFormat = format;
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(8),
                                                    boxShadow: isSelected ? [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.05),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ] : null,
                                                  ),
                                                  child: Text(
                                                    format,
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _showDraftsDialog,
                                        icon: const Icon(Icons.folder_open, color: Color(0xFF1E293B), size: 16),
                                        label: const Text('Drafts', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE2E8F0)), padding: const EdgeInsets.symmetric(vertical: 16)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _saveDraft,
                                        icon: const Icon(Icons.save, color: Color(0xFF1E293B), size: 16),
                                        label: const Text('Save Draft', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE2E8F0)), padding: const EdgeInsets.symmetric(vertical: 16)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _showBillPreview,
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: _isGeneratingBill ? null : _generateAndSaveBill,
                                        icon: _isGeneratingBill 
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Icon(Icons.print, size: 16),
                                        label: Text(_isGeneratingBill ? 'Generating...' : 'Generate Bill', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
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