import 'package:flutter/material.dart';

import '../models/crop_model.dart';
import '../models/farm_model.dart';
import '../services/crop_database_service.dart';
import '../services/farm_database_service.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({super.key});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final CropDatabaseService _cropService = CropDatabaseService.instance;
  final FarmDatabaseService _farmService = FarmDatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<CropModel> _crops = [];
  List<FarmModel> _farms = [];

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStage = 'All';

  static const Color _green = Color(0xFF176B45);
  static const Color _background = Color(0xFFF5F8F4);

  final List<String> _stages = const [
    'All',
    'Seedling',
    'Vegetative',
    'Flowering',
    'Fruiting',
    'Mature',
    'Harvested',
  ];

  final List<String> _growthStages = const [
    'Seedling',
    'Vegetative',
    'Flowering',
    'Fruiting',
    'Mature',
  ];

  final List<String> _statuses = const [
    'Growing',
    'Ready to Harvest',
    'Harvested',
    'Completed',
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
        _cropService.getCrops(),
        _farmService.getFarms(),
      ]);

      if (!mounted) return;

      setState(() {
        _crops = results[0] as List<CropModel>;
        _farms = results[1] as List<FarmModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load crops: $e')));
    }
  }

  List<CropModel> get _filteredCrops {
    final query = _searchQuery.trim().toLowerCase();

    return _crops.where((crop) {
      final matchesSearch =
          crop.name.toLowerCase().contains(query) ||
          crop.variety.toLowerCase().contains(query);

      final matchesStage =
          _selectedStage == 'All' || crop.growthStage == _selectedStage;

      return matchesSearch && matchesStage;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _farmName(int farmId) {
    for (final farm in _farms) {
      if (farm.id == farmId) return farm.name;
    }
    return 'Farm unavailable';
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'Seedling':
        return const Color(0xFF2E7D32);
      case 'Vegetative':
        return const Color(0xFF087E8B);
      case 'Flowering':
        return const Color(0xFF8E44AD);
      case 'Fruiting':
        return const Color(0xFFCC7722);
      case 'Mature':
        return const Color(0xFF176B45);
      case 'Harvested':
        return Colors.blueGrey;
      default:
        return _green;
    }
  }

  Future<void> _openCropForm({CropModel? crop}) async {
    if (_farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a farm before adding a crop.'),
        ),
      );
      return;
    }

    final result = await showDialog<CropModel>(
      context: context,
      builder: (_) => _CropFormDialog(
        farms: _farms,
        growthStages: _growthStages,
        statuses: _statuses,
        existingCrop: crop,
      ),
    );

    if (result == null) return;

    try {
      if (crop == null) {
        await _cropService.insertCrop(result);
      } else {
        await _cropService.updateCrop(result);
      }

      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            crop == null
                ? 'Crop added successfully!'
                : 'Crop updated successfully!',
          ),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save crop: $e')));
    }
  }

  Future<void> _deleteCrop(CropModel crop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete crop?'),
        content: Text('Are you sure you want to delete "${crop.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || crop.id == null) return;

    try {
      await _cropService.deleteCrop(crop.id!);
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crop deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete crop: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCrops = _filteredCrops;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Crop Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _background,
        actions: [
          IconButton(
            tooltip: 'Refresh crops',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCropForm(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Crop'),
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
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search crops or varieties...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _stages.map((stage) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(stage),
                            selected: _selectedStage == stage,
                            selectedColor: const Color(0xFFD9EDE0),
                            checkmarkColor: _green,
                            onSelected: (_) {
                              setState(() => _selectedStage = stage);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Crops',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF104B32),
                        ),
                      ),
                      Text(
                        '${visibleCrops.length} crops',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_farms.isEmpty)
                    _buildEmptyState(
                      icon: Icons.agriculture_outlined,
                      title: 'No farms available',
                      message:
                          'Add a farm first, then you can register its crops.',
                    )
                  else if (visibleCrops.isEmpty)
                    _buildEmptyState(
                      icon: Icons.grass_outlined,
                      title: _crops.isEmpty
                          ? 'No crops added yet'
                          : 'No matching crops',
                      message: _crops.isEmpty
                          ? 'Start managing your crops by adding your first crop.'
                          : 'Try another search or growth-stage filter.',
                    )
                  else
                    ...visibleCrops.map(_buildCropCard),
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    final growingCount = _crops
        .where((crop) => crop.status == 'Growing')
        .length;

    final readyCount = _crops
        .where((crop) => crop.status == 'Ready to Harvest')
        .length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total Crops',
            _crops.length.toString(),
            Icons.grass,
            const Color(0xFF176B45),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Growing',
            growingCount.toString(),
            Icons.eco,
            const Color(0xFF087E8B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            'Harvest Ready',
            readyCount.toString(),
            Icons.agriculture,
            const Color(0xFFCC7722),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(CropModel crop) {
    final stageColor = _stageColor(crop.growthStage);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F2E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.grass, color: _green, size: 27),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (crop.variety.trim().isNotEmpty)
                        Text(
                          crop.variety,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.landscape_outlined,
                            size: 14,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _farmName(crop.farmId),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openCropForm(crop: crop);
                    } else if (value == 'delete') {
                      _deleteCrop(crop);
                    }
                  },
                  itemBuilder: (_) => const [
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tag(crop.growthStage, stageColor),
                _tag(
                  crop.status,
                  crop.status == 'Ready to Harvest'
                      ? const Color(0xFFCC7722)
                      : _green,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dateInfo(
                    'Planted',
                    _formatDate(crop.plantingDate),
                    Icons.event_available_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateInfo(
                    'Expected harvest',
                    _formatDate(crop.harvestDate),
                    Icons.calendar_month_outlined,
                  ),
                ),
              ],
            ),
            if (crop.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                crop.notes,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dateInfo(String label, String date, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _green),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 54, color: const Color(0xFF8EAD97)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _CropFormDialog extends StatefulWidget {
  const _CropFormDialog({
    required this.farms,
    required this.growthStages,
    required this.statuses,
    this.existingCrop,
  });

  final List<FarmModel> farms;
  final List<String> growthStages;
  final List<String> statuses;
  final CropModel? existingCrop;

  @override
  State<_CropFormDialog> createState() => _CropFormDialogState();
}

class _CropFormDialogState extends State<_CropFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _varietyController;
  late final TextEditingController _notesController;

  late int _farmId;
  late DateTime _plantingDate;
  late DateTime _harvestDate;
  late String _growthStage;
  late String _status;

  bool _saving = false;

  bool get _isEditing => widget.existingCrop != null;

  @override
  void initState() {
    super.initState();

    final crop = widget.existingCrop;

    _nameController = TextEditingController(text: crop?.name ?? '');
    _varietyController = TextEditingController(text: crop?.variety ?? '');
    _notesController = TextEditingController(text: crop?.notes ?? '');

    final existingFarmId = crop?.farmId;
    _farmId = widget.farms.any((farm) => farm.id == existingFarmId)
        ? existingFarmId!
        : widget.farms.first.id!;

    _plantingDate = crop?.plantingDate ?? DateTime.now();
    _harvestDate =
        crop?.harvestDate ?? DateTime.now().add(const Duration(days: 90));

    _growthStage = widget.growthStages.contains(crop?.growthStage)
        ? crop!.growthStage
        : widget.growthStages.first;

    _status = widget.statuses.contains(crop?.status)
        ? crop!.status
        : widget.statuses.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _chooseDate({required bool planting}) async {
    final initialDate = planting ? _plantingDate : _harvestDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (planting) {
        _plantingDate = selected;
        if (_harvestDate.isBefore(_plantingDate)) {
          _harvestDate = _plantingDate.add(const Duration(days: 1));
        }
      } else {
        _harvestDate = selected;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_harvestDate.isBefore(_plantingDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harvest date must be on or after the planting date.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final oldCrop = widget.existingCrop;

    final crop = CropModel(
      id: oldCrop?.id,
      farmId: _farmId,
      name: _nameController.text.trim(),
      variety: _varietyController.text.trim(),
      plantingDate: _plantingDate,
      harvestDate: _harvestDate,
      growthStage: _growthStage,
      status: _status,
      notes: _notesController.text.trim(),
      createdAt: oldCrop?.createdAt ?? DateTime.now(),
    );

    Navigator.of(context).pop(crop);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Crop' : 'Add New Crop'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Crop name *',
                    hintText: 'e.g. Rice, Tomato, Maize',
                    prefixIcon: Icon(Icons.grass),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a crop name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _varietyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Variety (optional)',
                    hintText: 'e.g. Basmati',
                    prefixIcon: Icon(Icons.spa_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _farmId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Farm *',
                    prefixIcon: Icon(Icons.landscape_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.farms
                      .where((farm) => farm.id != null)
                      .map(
                        (farm) => DropdownMenuItem<int>(
                          value: farm.id!,
                          child: Text(
                            farm.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _farmId = value);
                  },
                ),
                const SizedBox(height: 14),
                _dateField(
                  label: 'Planting date',
                  date: _plantingDate,
                  onTap: () => _chooseDate(planting: true),
                ),
                const SizedBox(height: 12),
                _dateField(
                  label: 'Expected harvest date',
                  date: _harvestDate,
                  onTap: () => _chooseDate(planting: false),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _growthStage,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Growth stage',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.growthStages
                      .map(
                        (stage) =>
                            DropdownMenuItem(value: stage, child: Text(stage)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _growthStage = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Crop status',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.statuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add farming notes...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_isEditing ? 'Save Changes' : 'Add Crop'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF176B45),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(date)),
            const Icon(Icons.edit_calendar_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}
