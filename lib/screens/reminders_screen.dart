import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_reminder.dart';
import '../services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const Color _green = Color(0xFF176B45);
  static const Color _background = Color(0xFFF5F8F4);

  List<FarmReminder> _reminders = [];
  bool _loading = true;
  String _filter = 'All';

  final List<String> _types = const [
    'General',
    'Planting',
    'Watering',
    'Fertilizer',
    'Pest Control',
    'Harvest',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await ReminderService.instance.getReminders();

      if (!mounted) return;
      setState(() {
        _reminders = reminders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Could not load reminders: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<FarmReminder> get _filteredReminders {
    final now = DateTime.now();

    switch (_filter) {
      case 'Pending':
        return _reminders.where((r) => !r.isCompleted).toList();
      case 'Completed':
        return _reminders.where((r) => r.isCompleted).toList();
      case 'Overdue':
        return _reminders
            .where((r) =>
                !r.isCompleted && r.dueDate.isBefore(now) &&
                !_isSameDay(r.dueDate, now))
            .toList();
      default:
        return _reminders;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _openReminderForm({FarmReminder? reminder}) async {
    final formKey = GlobalKey<FormState>();
    final titleController =
        TextEditingController(text: reminder?.title ?? '');
    final descriptionController =
        TextEditingController(text: reminder?.description ?? '');

    String selectedType = _types.contains(reminder?.type)
        ? reminder!.type
        : 'General';
    DateTime selectedDate = reminder?.dueDate ?? DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                reminder == null ? 'Add Reminder' : 'Edit Reminder',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Reminder title *',
                          hintText: 'e.g. Water tomato plants',
                          prefixIcon: Icon(Icons.edit_calendar_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a reminder title'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _types
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Add notes (optional)',
                          prefixIcon: Icon(Icons.notes_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due date',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: _green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd MMM yyyy')
                                        .format(selectedDate),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: dialogContext,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        selectedDate = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                          selectedDate.hour,
                                          selectedDate.minute,
                                        );
                                      });
                                    }
                                  },
                                  child: const Text('Change'),
                                ),
                              ],
                            ),
                          ],
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
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final now = DateTime.now();
                    final item = FarmReminder(
                      id: reminder?.id,
                      farmId: reminder?.farmId,
                      cropId: reminder?.cropId,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      type: selectedType,
                      dueDate: selectedDate,
                      isCompleted: reminder?.isCompleted ?? false,
                      createdAt: reminder?.createdAt ?? now,
                    );

                    try {
                      if (reminder == null) {
                        await ReminderService.instance.addReminder(item);
                      } else {
                        await ReminderService.instance.updateReminder(item);
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Could not save reminder: $e')),
                        );
                      }
                    }
                  },
                  child: Text(reminder == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

    if (result == true) {
      await _loadReminders();
      _showMessage(reminder == null
          ? 'Reminder added successfully'
          : 'Reminder updated successfully');
    }
  }

  Future<void> _toggleComplete(FarmReminder reminder) async {
    try {
      await ReminderService.instance.updateReminder(
        reminder.copyWith(isCompleted: !reminder.isCompleted),
      );
      await _loadReminders();
    } catch (e) {
      _showMessage('Could not update reminder: $e');
    }
  }

  Future<void> _deleteReminder(FarmReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('Delete "${reminder.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || reminder.id == null) return;

    try {
      await ReminderService.instance.deleteReminder(reminder.id!);
      await _loadReminders();
      _showMessage('Reminder deleted');
    } catch (e) {
      _showMessage('Could not delete reminder: $e');
    }
  }

  Color _statusColor(FarmReminder reminder) {
    if (reminder.isCompleted) return Colors.green;
    final now = DateTime.now();
    if (reminder.dueDate.isBefore(now) &&
        !_isSameDay(reminder.dueDate, now)) {
      return Colors.red;
    }
    if (_isSameDay(reminder.dueDate, now)) return Colors.orange;
    return _green;
  }

  String _statusText(FarmReminder reminder) {
    if (reminder.isCompleted) return 'Completed';
    final now = DateTime.now();
    if (reminder.dueDate.isBefore(now) &&
        !_isSameDay(reminder.dueDate, now)) {
      return 'Overdue';
    }
    if (_isSameDay(reminder.dueDate, now)) return 'Due today';
    return 'Upcoming';
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Planting':
        return Icons.grass;
      case 'Watering':
        return Icons.water_drop_outlined;
      case 'Fertilizer':
        return Icons.compost_outlined;
      case 'Pest Control':
        return Icons.pest_control_outlined;
      case 'Harvest':
        return Icons.agriculture_outlined;
      case 'Maintenance':
        return Icons.handyman_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _reminders.where((r) => !r.isCompleted).length;
    final completed = _reminders.where((r) => r.isCompleted).length;
    final overdue = _reminders.where((r) {
      final now = DateTime.now();
      return !r.isCompleted &&
          r.dueDate.isBefore(now) &&
          !_isSameDay(r.dueDate, now);
    }).length;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Farm Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _background,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadReminders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openReminderForm(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _green),
            )
          : RefreshIndicator(
              onRefresh: _loadReminders,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_green, Color(0xFF104B32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stay on top of farm tasks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Plan your work. Grow with confidence.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _summaryItem('Pending', pending),
                            _summaryItem('Overdue', overdue),
                            _summaryItem('Completed', completed),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Pending', 'Overdue', 'Completed']
                          .map((filter) {
                        final selected = _filter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            selectedColor: _green.withValues(alpha: 0.15),
                            onSelected: (_) =>
                                setState(() => _filter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredReminders.isEmpty)
                    _emptyState()
                  else
                    ..._filteredReminders.map(_reminderCard),
                ],
              ),
            ),
    );
  }

  Widget _summaryItem(String label, int value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(FarmReminder reminder) {
    final color = _statusColor(reminder);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: reminder.isCompleted,
              activeColor: _green,
              onChanged: (_) => _toggleComplete(reminder),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(reminder.type), color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration: reminder.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (reminder.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _tag(reminder.type, _green),
                      _tag(_statusText(reminder), color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        DateFormat('dd MMM yyyy').format(reminder.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
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
                  _openReminderForm(reminder: reminder);
                } else if (value == 'delete') {
                  _deleteReminder(reminder);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No reminders found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _filter == 'All'
                ? 'Add your first farm reminder to get started.'
                : 'Try another filter or add a new reminder.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
