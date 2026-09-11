import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/crm_models.dart';
import '../../providers/crm_provider.dart';

class CrmPrescriptionsScreen extends ConsumerStatefulWidget {
  const CrmPrescriptionsScreen({super.key});

  @override
  ConsumerState<CrmPrescriptionsScreen> createState() => _CrmPrescriptionsScreenState();
}

class _CrmPrescriptionsScreenState extends ConsumerState<CrmPrescriptionsScreen> {
  String _activeTab = 'Prescription';
  final List<String> _diagnoses = ['Viral Fever', 'Acute Pharyngitis'];
  
  final List<CrmMedicine> _medicines = [
    CrmMedicine(name: 'Paracetamol 650 mg', dose: '1 Tab', frequency: 'TDS', duration: '5 Days', instruction: 'After food'),
    CrmMedicine(name: 'Azithromycin 500 mg', dose: '1 Tab', frequency: 'OD', duration: '3 Days', instruction: 'After food'),
    CrmMedicine(name: 'Cetirizine 10 mg', dose: '1 Tab', frequency: 'HS', duration: '5 Days', instruction: 'At night'),
    CrmMedicine(name: 'Domperidone 10 mg', dose: '1 Tab', frequency: 'TDS', duration: '3 Days', instruction: 'Before food'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildLeftPane()),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: _buildRightPane()),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Rx', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Prescription Generation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  const Text('Create and manage digital prescriptions for your patients', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
              const SizedBox(width: 32),
              const Text('Home  >  Prescription  >  ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              const Text('New Prescription', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B5CF6),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Draft'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B5CF6),
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Generate & Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLeftPane() {
    final selectedPatient = ref.watch(crmProvider).selectedPatient;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: selectedPatient != null ? _buildPrescriptionForm(selectedPatient) : _buildPatientSelection(),
    );
  }

  Widget _buildPatientSelection() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search, size: 64, color: Color(0xFF8B5CF6)),
          const SizedBox(height: 24),
          const Text('Find Patient', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          const SizedBox(height: 8),
          const Text('Search for an existing patient to generate prescription.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 32),
          Container(
            height: 56,
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name, Phone, or UHID...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/crm/patients');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Search'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              context.go('/crm/patients');
            },
            icon: const Icon(Icons.person_add, size: 20),
            label: const Text('Generate Prescription for New Patient'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFFE9D5FF), width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionForm(CrmPatient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Patient Profile Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: ClipOval(child: Image.network(patient.avatarUrl ?? 'https://randomuser.me/api/portraits/men/32.jpg', width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, color: Color(0xFF94A3B8)))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(patient.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Active', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('UHID: ${patient.id}    |    ${patient.age} Y / ${patient.gender}    |    ${patient.phone}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconTextRow(Icons.location_on_outlined, '123, Main Road, Kolkata - 700016'),
                    const SizedBox(height: 4),
                    _buildIconTextRow(Icons.email_outlined, 'patient@gmail.com'),
                    const SizedBox(height: 4),
                    _buildIconTextRow(Icons.warning_amber_rounded, 'No known allergies', iconColor: const Color(0xFF8B5CF6)),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconTextRow(Icons.calendar_today_outlined, 'Last Visit\n${patient.lastVisit}', isDouble: true),
                    const SizedBox(height: 8),
                    _buildIconTextRow(Icons.calendar_month_outlined, 'Next Follow Up\n14 Sep 2026', isDouble: true),
                  ],
                ),
              ],
            ),
          ),
          
          // Tabs
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                _buildTab('Prescription'),
                _buildTab('Clinical Notes'),
                _buildTab('Lab Tests'),
                _buildTab('Follow Up'),
                _buildTab('Patient History'),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chief Complaint', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Fever, headache and body pain since 2 days.', style: TextStyle(color: Color(0xFF1E293B), fontSize: 14)),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Diagnosis / Impression', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._diagnoses.map((d) => _buildDiagnosisChip(d)),
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE9D5FF))),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.add, size: 16, color: Color(0xFF8B5CF6)),
                                        SizedBox(width: 4),
                                        Text('Add Diagnosis', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ICD Code (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                              child: const TextField(
                                decoration: InputDecoration(hintText: 'Search ICD code...', prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Medicines', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16)),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Medicine'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Medicines Table
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(8)), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                          child: Row(
                            children: const [
                              SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13))),
                              Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13))),
                              Expanded(flex: 1, child: Text('Dose', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13))),
                              Expanded(flex: 1, child: Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13))),
                              Expanded(flex: 1, child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13))),
                              Expanded(flex: 2, child: Text('Instruction', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13))),
                              SizedBox(width: 80, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 13), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        ..._medicines.asMap().entries.map((entry) {
                          final i = entry.key;
                          final med = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == _medicines.length - 1 ? Colors.transparent : const Color(0xFFE2E8F0)))),
                            child: Row(
                              children: [
                                SizedBox(width: 32, child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
                                Expanded(flex: 3, child: Text(med.name, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                Expanded(flex: 1, child: Text(med.dose, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                Expanded(flex: 1, child: Text(med.frequency, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                Expanded(flex: 1, child: Text(med.duration, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                Expanded(flex: 2, child: Text(med.instruction, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13))),
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.edit_outlined, size: 16, color: Color(0xFF3B82F6)),
                                      SizedBox(width: 16),
                                      Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Additional Advice', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Container(
                              height: 60,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Take adequate fluids and rest. If symptoms persist, consult again.', style: TextStyle(color: Color(0xFF1E293B), fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Next Follow Up', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month, color: Color(0xFF8B5CF6), size: 18),
                                      SizedBox(width: 8),
                                      Text('14 Sep 2026', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Checkboxes
                  Row(
                    children: [
                      _buildCheckbox('Print Prescription', true),
                      const SizedBox(width: 24),
                      _buildCheckbox('Send to Patient (SMS/WhatsApp)', true),
                      const SizedBox(width: 24),
                      _buildCheckbox('Save as Template', false),
                      const SizedBox(width: 24),
                      _buildCheckbox('Add Lab Test', false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildRightPane() {
    return Column(
      children: [
        // Preview Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Prescription Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.fullscreen, size: 16),
                  label: const Text('Full Screen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // A4 Paper Area
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF8FAFC)),
                            child: const Center(
                              child: Text('Manju', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Manju Medical Stores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                              Text('& Digital Clinic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                              SizedBox(height: 4),
                              Text('Your Health • Our Priority', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMiniIconText(Icons.location_on, '123, Main Road\nKolkata - 700016'),
                          const SizedBox(height: 4),
                          _buildMiniIconText(Icons.phone, '+91 9830011223'),
                          const SizedBox(height: 4),
                          _buildMiniIconText(Icons.email, 'manjuclinic@gmail.com'),
                          const SizedBox(height: 4),
                          _buildMiniIconText(Icons.language, 'www.manjumedical.in'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  
                  // Patient Details Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildPreviewDetailRow('Patient Name', ': Rahul Das'),
                            _buildPreviewDetailRow('UHID', ': PT000123'),
                            _buildPreviewDetailRow('Age / Gender', ': 32 Y / Male'),
                            _buildPreviewDetailRow('Phone', ': 9830011223'),
                            _buildPreviewDetailRow('Address', ': 123, Main Road, Kolkata - 700016'),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 80, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildPreviewDetailRow('Date', ': 09 Sep 2026'),
                            _buildPreviewDetailRow('Consultation ID', ': CONS000456'),
                            _buildPreviewDetailRow('Doctor', ': Dr. Sen'),
                            _buildPreviewDetailRow('Specialization', ': General Physician'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 24),
                  
                  // Rx Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Rx', style: TextStyle(fontSize: 48, fontFamily: 'serif', color: Color(0xFF1E293B))),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Diagnosis : Viral Fever, Acute Pharyngitis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Medicine Table
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                          child: Row(
                            children: const [
                              SizedBox(width: 20, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Expanded(flex: 1, child: Text('Dose', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Expanded(flex: 1, child: Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Expanded(flex: 1, child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                              Expanded(flex: 2, child: Text('Instruction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            ],
                          ),
                        ),
                        ..._medicines.asMap().entries.map((entry) {
                          final i = entry.key;
                          final med = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i == _medicines.length - 1 ? Colors.transparent : const Color(0xFFE2E8F0)))),
                            child: Row(
                              children: [
                                SizedBox(width: 20, child: Text('${i + 1}', style: const TextStyle(fontSize: 11))),
                                Expanded(flex: 3, child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                                Expanded(flex: 1, child: Text(med.dose, style: const TextStyle(fontSize: 11))),
                                Expanded(flex: 1, child: Text(med.frequency, style: const TextStyle(fontSize: 11))),
                                Expanded(flex: 1, child: Text(med.duration, style: const TextStyle(fontSize: 11))),
                                Expanded(flex: 2, child: Text(med.instruction, style: const TextStyle(fontSize: 11))),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Additional Advice
                  const Text('Additional Advice :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text('Take adequate fluids and rest. If symptoms persist, consult again.', style: TextStyle(fontSize: 12, height: 1.5)),
                  const SizedBox(height: 24),
                  
                  // Follow Up
                  Row(
                    children: const [
                      Text('Next Follow Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(width: 16),
                      Text(': 14 Sep 2026', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 64),
                  
                  // Footer Signatures
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              color: const Color(0xFFF1F5F9),
                            ),
                            child: const Center(child: Icon(Icons.qr_code_2, size: 48)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Scan for Appointments', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('& Reports', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              SizedBox(height: 4),
                              Text('www.manjumedical.in', style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6))),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Signature', style: TextStyle(fontFamily: 'cursive', fontSize: 24, color: Color(0xFF475569))),
                          Container(width: 120, height: 1, color: Colors.black),
                          const SizedBox(height: 4),
                          const Text('Dr. Sen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const Text('MBBS, MD', style: TextStyle(fontSize: 10)),
                          const Text('Reg. No. 123456', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Center(child: Text('Care Today   Healthier Tomorrow', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Color(0xFF16A34A)))),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom Toolbar
        Container(
          margin: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildToolbarBtn(Icons.chevron_left),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('1 / 1')),
                  _buildToolbarBtn(Icons.chevron_right),
                ],
              ),
              Row(
                children: [
                  _buildToolbarBtn(Icons.remove),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('100%')),
                  _buildToolbarBtn(Icons.add),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildIconTextRow(IconData icon, String text, {Color iconColor = const Color(0xFF94A3B8), bool isDouble = false}) {
    return Row(
      crossAxisAlignment: isDouble ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: const Color(0xFF64748B), fontSize: 12, height: isDouble ? 1.5 : 1.0)),
      ],
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _activeTab == title;
    return InkWell(
      onTap: () => setState(() => _activeTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool isChecked) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFF8B5CF6) : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isChecked ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1)),
          ),
          child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13)),
      ],
    );
  }

  Widget _buildMiniIconText(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 10, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildPreviewDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }

  Widget _buildToolbarBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Icon(icon, size: 18, color: const Color(0xFF64748B))),
    );
  }
}
