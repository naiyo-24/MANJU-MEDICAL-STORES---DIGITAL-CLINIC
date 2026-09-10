import 'package:flutter/material.dart';
import '../../models/lab_models.dart';
import '../../services/lab_data_service.dart';
import 'package:uuid/uuid.dart';

class LabTemplatesScreen extends StatefulWidget {
  const LabTemplatesScreen({super.key});

  @override
  State<LabTemplatesScreen> createState() => _LabTemplatesScreenState();
}

class _LabTemplatesScreenState extends State<LabTemplatesScreen> {
  List<LabTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final templates = await LabDataService.getTemplates();
    setState(() {
      _templates = templates;
      _isLoading = false;
    });
  }

  void _showAddTemplateDialog({LabTemplate? existingTemplate}) {
    final nameCtrl = TextEditingController(text: existingTemplate?.name);
    List<TemplateField> fields = existingTemplate?.fields.toList() ?? [TemplateField(name: '', unit: '', normalRange: '')];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingTemplate == null ? 'Create Template' : 'Edit Template'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Template Name')),
                  const SizedBox(height: 24),
                  const Text('Template Fields / Parameters', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...fields.asMap().entries.map((entry) {
                    final index = entry.key;
                    final field = entry.value;
                    final nameC = TextEditingController(text: field.name);
                    final unitC = TextEditingController(text: field.unit);
                    final rangeC = TextEditingController(text: field.normalRange);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Parameter Name (e.g. Hemoglobin)'), onChanged: (v) => fields[index] = TemplateField(name: v, unit: fields[index].unit, normalRange: fields[index].normalRange))),
                          const SizedBox(width: 8),
                          Expanded(flex: 1, child: TextField(controller: unitC, decoration: const InputDecoration(labelText: 'Unit (e.g. g/dL)'), onChanged: (v) => fields[index] = TemplateField(name: fields[index].name, unit: v, normalRange: fields[index].normalRange))),
                          const SizedBox(width: 8),
                          Expanded(flex: 1, child: TextField(controller: rangeC, decoration: const InputDecoration(labelText: 'Normal Range'), onChanged: (v) => fields[index] = TemplateField(name: fields[index].name, unit: fields[index].unit, normalRange: v))),
                          IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setDialogState(() => fields.removeAt(index))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => setDialogState(() => fields.add(TemplateField(name: '', unit: '', normalRange: ''))),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Parameter'),
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
              onPressed: () async {
                final template = LabTemplate(
                  id: existingTemplate?.id ?? const Uuid().v4(),
                  name: nameCtrl.text,
                  fields: fields.where((f) => f.name.isNotEmpty).toList(),
                );
                await LabDataService.saveTemplate(template);
                if (mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Report Templates', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ElevatedButton.icon(
                onPressed: () => _showAddTemplateDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(template.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showAddTemplateDialog(existingTemplate: template), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                    const SizedBox(width: 8),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () async {
                                      await LabDataService.deleteTemplate(template.id);
                                      _loadData();
                                    }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Parameters', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: template.fields.length,
                                itemBuilder: (context, fIndex) {
                                  final field = template.fields[fIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('${field.name} (${field.unit})', style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                                      ],
                                    ),
                                  );
                                },
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
    );
  }
}
