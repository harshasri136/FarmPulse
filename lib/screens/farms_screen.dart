import 'package:flutter/material.dart';

import '../models/farm_model.dart';
import '../services/farm_database_service.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  final FarmDatabaseService _service = FarmDatabaseService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<FarmModel> _farms = [];
  bool _loading = true;
  String _search = '';

  static const Color green = Color(0xFF176B45);
  static const Color background = Color(0xFFF5F8F4);

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await _service.getFarms();
      if (!mounted) return;

      setState(() {
        _farms = farms;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Unable to load farms: $e');
    }
  }

  List<FarmModel> get _filteredFarms {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _farms;

    return _farms.where((farm) {
      return farm.name.toLowerCase().contains(query) ||
          farm.location.toLowerCase().contains(query) ||
          farm.soilType.toLowerCase().contains(query);
    }).toList();
  }

  double get _totalArea => _farms.fold(0.0, (total, farm) => total + farm.area);

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showFarmForm({FarmModel? farm}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: farm?.name ?? '');
    final locationController = TextEditingController(
      text: farm?.location ?? '',
    );
    final areaController = TextEditingController(
      text: farm == null ? '' : farm.area.toString(),
    );
    final descriptionController = TextEditingController(
      text: farm?.description ?? '',
    );

    String areaUnit = farm?.areaUnit ?? 'Acres';
    String soilType = farm?.soilType ?? 'Loamy';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(farm == null ? 'Add Farm' : 'Edit Farm'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Farm name *',
                          prefixIcon: Icon(Icons.agriculture),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter farm name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location *',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter location'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: areaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Farm area *',
                          prefixIcon: Icon(Icons.square_foot),
                        ),
                        validator: (value) {
                          final area = double.tryParse(value ?? '');
                          if (area == null || area <= 0) {
                            return 'Enter a valid area';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: areaUnit,
                        decoration: const InputDecoration(
                          labelText: 'Area unit',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Acres',
                            child: Text('Acres'),
                          ),
                          DropdownMenuItem(
                            value: 'Hectares',
                            child: Text('Hectares'),
                          ),
                          DropdownMenuItem(
                            value: 'Cents',
                            child: Text('Cents'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => areaUnit = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: soilType,
                        decoration: const InputDecoration(
                          labelText: 'Soil type',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Loamy',
                            child: Text('Loamy'),
                          ),
                          DropdownMenuItem(value: 'Clay', child: Text('Clay')),
                          DropdownMenuItem(
                            value: 'Sandy',
                            child: Text('Sandy'),
                          ),
                          DropdownMenuItem(
                            value: 'Silty',
                            child: Text('Silty'),
                          ),
                          DropdownMenuItem(
                            value: 'Black',
                            child: Text('Black soil'),
                          ),
                          DropdownMenuItem(
                            value: 'Red',
                            child: Text('Red soil'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => soilType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: Text(farm == null ? 'Save Farm' : 'Update Farm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final newFarm = FarmModel(
        id: farm?.id,
        name: nameController.text.trim(),
        location: locationController.text.trim(),
        area: double.parse(areaController.text.trim()),
        areaUnit: areaUnit,
        soilType: soilType,
        description: descriptionController.text.trim(),
        createdAt: farm?.createdAt ?? DateTime.now(),
      );

      try {
        if (farm == null) {
          await _service.insertFarm(newFarm);
          _message('Farm added successfully');
        } else {
          await _service.updateFarm(newFarm);
          _message('Farm updated successfully');
        }

        await _loadFarms();
      } catch (e) {
        _message('Unable to save farm: $e');
      }
    }

    nameController.dispose();
    locationController.dispose();
    areaController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteFarm(FarmModel farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete farm?'),
        content: Text('Delete "${farm.name}" and its associated crops?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || farm.id == null) return;

    try {
      await _service.deleteFarm(farm.id!);
      await _loadFarms();
      _message('Farm deleted');
    } catch (e) {
      _message('Unable to delete farm: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final farms = _filteredFarms;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Farms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: background,
        foregroundColor: const Color(0xFF183A29),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadFarms,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFarmForm(),
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Farm'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFarms,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF176B45), Color(0xFF2D9862)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your farmland',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Manage every field',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.agriculture, size: 48, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Total Farms',
                          '${_farms.length}',
                          Icons.landscape,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Total Area',
                          _totalArea.toStringAsFixed(1),
                          Icons.square_foot,
                          subtitle: _farms.isEmpty
                              ? 'No farms'
                              : _farms.map((f) => f.areaUnit).toSet().length ==
                                    1
                              ? _farms.first.areaUnit
                              : 'Mixed units',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: 'Search farms or locations...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your farms',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${farms.length} farms'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (farms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 35),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.agriculture_outlined,
                            size: 65,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty
                                ? 'No farms added yet'
                                : 'No farms match your search',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add a farm to start managing your fields.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...farms.map(
                      (farm) => Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE5EDE5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F3E7),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.agriculture,
                                      color: green,
                                      size: 29,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          farm.name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          farm.location,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showFarmForm(farm: farm);
                                      } else if (value == 'delete') {
                                        _deleteFarm(farm);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit farm'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete farm'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: _detail(
                                      Icons.square_foot,
                                      '${farm.area} ${farm.areaUnit}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _detail(Icons.grass, farm.soilType),
                                  ),
                                ],
                              ),
                              if (farm.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    farm.description,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green, size: 25),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          Text(title, style: const TextStyle(color: Colors.black54)),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: green),
        const SizedBox(width: 7),
        Flexible(child: Text(text)),
      ],
    );
  }
}
