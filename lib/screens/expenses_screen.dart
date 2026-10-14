import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/farm_expense.dart';
import '../services/expense_database_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const Color green = Color(0xFF176B45);
  static const Color background = Color(0xFFF5F8F4);

  final _service = ExpenseDatabaseService.instance;
  final _searchController = TextEditingController();

  List<FarmExpense> _expenses = [];
  String _category = 'All';
  String _search = '';
  bool _loading = true;

  final List<String> _categories = [
    'Seeds',
    'Fertilizer',
    'Pesticides',
    'Labour',
    'Equipment',
    'Transport',
    'Water',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    try {
      final result = await _service.getExpenses();

      if (!mounted) return;

      setState(() {
        _expenses = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load expenses: $e')),
      );
    }
  }

  List<FarmExpense> get _filteredExpenses {
    return _expenses.where((expense) {
      final matchesCategory =
          _category == 'All' || expense.category == _category;

      final query = _search.toLowerCase();
      final matchesSearch =
          expense.title.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
  }

  double get _total =>
      _expenses.fold(0.0, (sum, item) => sum + item.amount);

  double get _thisMonthTotal {
    final now = DateTime.now();

    return _expenses
        .where((item) =>
            item.expenseDate.year == now.year &&
            item.expenseDate.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};

    for (final expense in _expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  Map<String, double> get _monthlyTotals {
    final now = DateTime.now();
    final result = <String, double>{};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(month);
      result[key] = 0;
    }

    for (final expense in _expenses) {
      final key = DateFormat('yyyy-MM').format(expense.expenseDate);
      if (result.containsKey(key)) {
        result[key] = result[key]! + expense.amount;
      }
    }

    return result;
  }

  String _money(double value) =>
      NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      ).format(value);

  Future<void> _showExpenseForm({FarmExpense? expense}) async {
    final formKey = GlobalKey<FormState>();
    final titleController =
        TextEditingController(text: expense?.title ?? '');
    final amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toString(),
    );
    final notesController =
        TextEditingController(text: expense?.notes ?? '');

    String category = expense?.category ?? 'Seeds';
    String paymentMethod = expense?.paymentMethod ?? 'Cash';
    DateTime selectedDate = expense?.expenseDate ?? DateTime.now();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: background,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense == null ? 'Add Expense' : 'Edit Expense',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Expense title',
                          prefixIcon: Icon(Icons.receipt_long),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter an expense title'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            value?.trim() ?? '',
                          );
                          if (amount == null || amount <= 0) {
                            return 'Enter an amount greater than zero';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: paymentMethod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Payment method',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Other']
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(
                              () => paymentMethod = value,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            padding: const EdgeInsets.all(15),
                          ),
                          icon: const Icon(Icons.save),
                          label: Text(
                            expense == null
                                ? 'Save Expense'
                                : 'Update Expense',
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final now = DateTime.now();
                            final item = FarmExpense(
                              id: expense?.id,
                              farmId: expense?.farmId,
                              cropId: expense?.cropId,
                              title: titleController.text.trim(),
                              category: category,
                              amount: double.parse(
                                amountController.text.trim(),
                              ),
                              expenseDate: selectedDate,
                              paymentMethod: paymentMethod,
                              notes: notesController.text.trim(),
                              createdAt: expense?.createdAt ?? now,
                            );

                            try {
                              if (expense == null) {
                                await _service.addExpense(item);
                              } else {
                                await _service.updateExpense(item);
                              }

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext, true);
                              }
                            } catch (e) {
                              if (sheetContext.mounted) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text('Save failed: $e'),
                                  ),
                                );
                              }
                            }
                          },
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
    amountController.dispose();
    notesController.dispose();

    if (saved == true) {
      await _loadExpenses();
    }
  }

  Future<void> _deleteExpense(FarmExpense expense) async {
    if (expense.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Delete "${expense.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteExpense(expense.id!);
      await _loadExpenses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;
    final categoryTotals = _categoryTotals;
    final monthlyTotals = _monthlyTotals;
    final maxMonthly = monthlyTotals.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Expense Tracking',
          style: TextStyle(
            color: Color(0xFF104B32),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: background,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh, color: green),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseForm(),
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          'Total Expenses',
                          _money(_total),
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          'This Month',
                          _money(_thisMonthTotal),
                          Icons.calendar_month,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Monthly Spending'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      children: monthlyTotals.entries.map((entry) {
                        final value = entry.value;
                        final fraction = maxMonthly == 0
                            ? 0.0
                            : (value / maxMonthly).clamp(0.0, 1.0);
                        final month = DateFormat('MMM').format(
                          DateTime.parse('${entry.key}-01'),
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 42,
                                child: Text(
                                  month,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 12,
                                    backgroundColor:
                                        const Color(0xFFE4ECE5),
                                    color: green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  _money(value),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Category Breakdown'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: categoryTotals.isEmpty
                        ? const Text('No expense data available yet.')
                        : Column(
                            children: categoryTotals.entries.map((entry) {
                              final fraction =
                                  _total == 0 ? 0.0 : entry.value / _total;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(entry.key)),
                                        Text(
                                          _money(entry.value),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: fraction.clamp(0.0, 1.0),
                                        minHeight: 7,
                                        backgroundColor:
                                            const Color(0xFFE4ECE5),
                                        color: green,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('All Expenses'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: ['All', ..._categories].map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(item),
                            selected: _category == item,
                            selectedColor: const Color(0xFFD8EBDD),
                            onSelected: (_) {
                              setState(() => _category = item);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: _cardDecoration(),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 44,
                            color: green,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No expenses found',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text('Add an expense to start tracking spending.'),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((expense) {
                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                            color: Color(0xFFE4ECE5),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE4F2E7),
                            child: Icon(
                              _categoryIcon(expense.category),
                              color: green,
                            ),
                          ),
                          title: Text(
                            expense.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '${expense.category} • '
                              '${DateFormat('dd MMM yyyy').format(expense.expenseDate)}\n'
                              '${expense.paymentMethod}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showExpenseForm(expense: expense);
                              } else if (value == 'delete') {
                                _deleteExpense(expense);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                          titleAlignment: ListTileTitleAlignment.center,
                          dense: false,
                          visualDensity: VisualDensity.comfortable,
                          subtitleTextStyle: const TextStyle(
                            color: Colors.black54,
                            height: 1.6,
                          ),
                          // Amount is shown as a separate trailing detail
                          // through the title section below.
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF104B32),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4ECE5)),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Seeds':
        return Icons.grass;
      case 'Fertilizer':
        return Icons.eco;
      case 'Pesticides':
        return Icons.sanitizer_outlined;
      case 'Labour':
        return Icons.people_outline;
      case 'Equipment':
        return Icons.agriculture;
      case 'Transport':
        return Icons.local_shipping_outlined;
      case 'Water':
        return Icons.water_drop_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
