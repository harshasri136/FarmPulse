import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_activity.dart';
import '../models/farm_model.dart';
import '../models/crop_model.dart';
import '../services/activity_database_service.dart';
import '../services/farm_database_service.dart';
import '../services/crop_database_service.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  static const Color _green = Color(0xFF176B45);
  static const Color _darkGreen = Color(0xFF104B32);
  static const Color _background = Color(0xFFF5F8F4);

  final _searchController = TextEditingController();

  List<FarmActivity> _activities = [];
  List<FarmModel> _farms = [];
  List<CropModel> _crops = [];

  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _activityTypes = [
    'Planting',
    'Watering',
    'Fertilizing',
    'Spraying',
    'Pruning',
    'Harvesting',
    'Weeding',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        ActivityDatabaseService.instance.getActivities(),
        FarmDatabaseService.instance.getFarms(),
        CropDatabaseService.instance.getCrops(),
      ]);

      if (!mounted) return;

      setState(() {
        _activities = results[0] as List<FarmActivity>;
        _farms = results[1] as List<FarmModel>;
        _crops = results[2] as List<CropModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Unable to load activity logs: $e');
    }
  }

  List<FarmActivity> get _filteredActivities {
    return _activities.where((activity) {
      final matchesType =
          _selectedFilter == 'All' || activity.type == _selectedFilter;

      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          activity.title.toLowerCase().contains(query) ||
          activity.type.toLowerCase().contains(query) ||
          activity.description.toLowerCase().contains(query) ||
          activity.notes.toLowerCase().contains(query) ||
          _farmName(activity.farmId).toLowerCase().contains(query) ||
          _cropName(activity.cropId).toLowerCase().contains(query);

      return matchesType && matchesSearch;
    }).toList();
  }

  double get _totalExpense =>
      _activities.fold(0, (sum, activity) => sum + activity.expense);

  String _farmName(int? id) {
    if (id == null) return 'General activity';

    for (final farm in _farms) {
      if (farm.id == id) return farm.name;
    }

    return 'Farm #$id';
  }

  String _cropName(int? id) {
    if (id == null) return 'No crop selected';

    for (final crop in _crops) {
      if (crop.id == id) return crop.name;
    }

    return 'Crop #$id';
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Planting':
        return Icons.grass;
      case 'Watering':
        return Icons.water_drop;
      case 'Fertilizing':
        return Icons.eco;
      case 'Spraying':
        return Icons.sanitizer_outlined;
      case 'Pruning':
        return Icons.content_cut;
      case 'Harvesting':
        return Icons.agriculture;
      case 'Weeding':
        return Icons.yard;
      default:
        return Icons.event_note;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'Watering':
        return Colors.blue;
      case 'Fertilizing':
        return Colors.orange;
      case 'Spraying':
        return Colors.purple;
      case 'Harvesting':
        return _green;
      case 'Planting':
        return Colors.teal;
      default:
        return _darkGreen;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showActivityForm({FarmActivity? existing}) async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final quantityController = TextEditingController(
      text: existing == null || existing.quantity == 0
          ? ''
          : existing.quantity.toString(),
    );
    final unitController = TextEditingController(
      text: existing?.quantityUnit ?? '',
    );
    final expenseController = TextEditingController(
      text: existing == null || existing.expense == 0
          ? ''
          : existing.expense.toString(),
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');

    String selectedType = existing?.type ?? 'Watering';
    DateTime selectedDate = existing?.activityDate ?? DateTime.now();
    int? selectedFarmId = existing?.farmId;
    int? selectedCropId = existing?.cropId;
    bool isSaving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _background,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final availableCrops = selectedFarmId == null
                ? _crops
                : _crops
                      .where((crop) => crop.farmId == selectedFarmId)
                      .toList();

            if (selectedCropId != null &&
                !availableCrops.any((crop) => crop.id == selectedCropId)) {
              selectedCropId = null;
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existing == null
                            ? 'Add Farm Activity'
                            : 'Edit Farm Activity',
                        style: const TextStyle(
                          color: _darkGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Record your daily farm work and expenses.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 22),

                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Activity Type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: _activityTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Activity Title *',
                          hintText: 'e.g. Morning irrigation',
                          prefixIcon: Icon(Icons.edit_note),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter an activity title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<int?>(
                        initialValue: selectedFarmId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Farm (optional)',
                          prefixIcon: Icon(Icons.landscape_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('General activity'),
                          ),
                          ..._farms.map(
                            (farm) => DropdownMenuItem<int?>(
                              value: farm.id,
                              child: Text(farm.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() {
                            selectedFarmId = value;
                            selectedCropId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<int?>(
                        initialValue: selectedCropId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Crop (optional)',
                          prefixIcon: Icon(Icons.grass),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('No crop selected'),
                          ),
                          ...availableCrops.map(
                            (crop) => DropdownMenuItem<int?>(
                              value: crop.id,
                              child: Text(crop.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setSheetState(() => selectedCropId = value);
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'What work was performed?',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (date != null) {
                            setSheetState(() => selectedDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Activity Date',
                            prefixIcon: Icon(Icons.calendar_month),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                hintText: '0',
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isNotEmpty &&
                                    (double.tryParse(text) == null ||
                                        double.parse(text) < 0)) {
                                  return 'Enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: unitController,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                hintText: 'e.g. Litres',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: expenseController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Expense (₹)',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isNotEmpty &&
                              (double.tryParse(text) == null ||
                                  double.parse(text) < 0)) {
                            return 'Enter a valid expense';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Additional details',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setSheetState(() => isSaving = true);

                                  try {
                                    final now = DateTime.now();

                                    final activity = FarmActivity(
                                      id: existing?.id,
                                      farmId: selectedFarmId,
                                      cropId: selectedCropId,
                                      title: titleController.text.trim(),
                                      type: selectedType,
                                      description: descriptionController.text
                                          .trim(),
                                      activityDate: selectedDate,
                                      quantity:
                                          double.tryParse(
                                            quantityController.text.trim(),
                                          ) ??
                                          0,
                                      quantityUnit: unitController.text.trim(),
                                      expense:
                                          double.tryParse(
                                            expenseController.text.trim(),
                                          ) ??
                                          0,
                                      notes: notesController.text.trim(),
                                      createdAt: existing?.createdAt ?? now,
                                    );

                                    if (existing == null) {
                                      await ActivityDatabaseService.instance
                                          .addActivity(activity);
                                    } else {
                                      await ActivityDatabaseService.instance
                                          .updateActivity(activity);
                                    }

                                    if (sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop(true);
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);

                                    if (sheetContext.mounted) {
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Unable to save activity: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(isSaving ? 'Saving...' : 'Save Activity'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    unitController.dispose();
    expenseController.dispose();
    notesController.dispose();

    if (saved == true) {
      await _loadData();
      _showMessage(
        existing == null
            ? 'Activity added successfully'
            : 'Activity updated successfully',
      );
    }
  }

  Future<void> _deleteActivity(FarmActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: Text('Delete "${activity.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ActivityDatabaseService.instance.deleteActivity(activity.id!);
      await _loadData();
      _showMessage('Activity deleted');
    } catch (e) {
      _showMessage('Unable to delete activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activities = _filteredActivities;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Activity Logs',
          style: TextStyle(color: _darkGreen, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _background,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, color: _darkGreen),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActivityForm(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search activities, farms or crops...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', ..._activityTypes].map((filter) {
                        final selected = _selectedFilter == filter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            selectedColor: _green,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : _darkGreen,
                              fontWeight: FontWeight.w500,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recorded Activities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                        ),
                      ),
                      Text(
                        '${activities.length} records',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (activities.isEmpty)
                    _buildEmptyState()
                  else
                    ...activities.map(_buildActivityCard),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.event_note,
            label: 'Activities',
            value: '${_activities.length}',
            color: _green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.currency_rupee,
            label: 'Total Expense',
            value: '₹${_totalExpense.toStringAsFixed(0)}',
            color: Colors.orange.shade800,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(FarmActivity activity) {
    final color = _activityColor(activity.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5ECE5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _activityIcon(activity.type),
                    color: color,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${activity.type} • '
                        '${DateFormat('dd MMM yyyy').format(activity.activityDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _farmName(activity.farmId),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (activity.cropId != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          _cropName(activity.cropId),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showActivityForm(existing: activity);
                    } else if (value == 'delete') {
                      _deleteActivity(activity);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(activity.description),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.scale_outlined,
                  size: 17,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.quantity > 0
                        ? '${activity.quantity} ${activity.quantityUnit}'
                        : 'Quantity not specified',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const Icon(Icons.currency_rupee, size: 17, color: _green),
                Text(
                  activity.expense.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _darkGreen,
                  ),
                ),
              ],
            ),
            if (activity.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Note: ${activity.notes}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.agriculture_outlined, size: 54, color: _green),
          const SizedBox(height: 14),
          const Text(
            'No activities found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'Try changing your search or filter.'
                : 'Record watering, planting, harvesting and other farm work.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _showActivityForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Activity'),
          ),
        ],
      ),
    );
  }
}
