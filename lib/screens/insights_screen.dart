import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/crop_model.dart';
import '../models/farm_model.dart';
import '../services/activity_database_service.dart';
import '../services/crop_database_service.dart';
import '../services/expense_database_service.dart';
import '../services/farm_database_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  static const Color green = Color(0xFF176B45);
  static const Color background = Color(0xFFF5F8F4);

  bool _loading = true;
  String? _error;

  List<CropModel> _crops = [];
  List<FarmModel> _farms = [];

  double _totalArea = 0;
  double _totalExpenses = 0;
  double _activityExpenses = 0;
  int _activityCount = 0;

  Map<String, double> _monthlyExpenses = {};
  Map<String, double> _categoryExpenses = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        CropDatabaseService.instance.getCrops(),
        FarmDatabaseService.instance.getFarms(),
        FarmDatabaseService.instance.getTotalArea(),
        ExpenseDatabaseService.instance.getTotalExpenses(),
        ExpenseDatabaseService.instance.getMonthlyExpenses(months: 6),
        ExpenseDatabaseService.instance.getCategoryBreakdown(),
        ActivityDatabaseService.instance.getTotalExpense(),
        ActivityDatabaseService.instance.getActivityCount(),
      ]);

      if (!mounted) return;

      setState(() {
        _crops = results[0] as List<CropModel>;
        _farms = results[1] as List<FarmModel>;
        _totalArea = (results[2] as num).toDouble();
        _totalExpenses = (results[3] as num).toDouble();
        _monthlyExpenses = Map<String, double>.from(results[4] as Map);
        _categoryExpenses = Map<String, double>.from(results[5] as Map);
        _activityExpenses = (results[6] as num).toDouble();
        _activityCount = results[7] as int;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load analytics. Please try again.';
      });

      debugPrint('FarmPulse insights error: $e');
    }
  }

  int _countStatus(String status) => _crops
      .where((crop) => crop.status.toLowerCase() == status.toLowerCase())
      .length;

  int _countStage(String stage) => _crops
      .where((crop) => crop.growthStage.toLowerCase() == stage.toLowerCase())
      .length;

  List<MapEntry<String, double>> get _sortedCategories {
    final entries = _categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<DateTime> get _lastSixMonths {
    final now = DateTime.now();
    return List.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index, 1),
    );
  }

  double _monthlyAmount(DateTime month) {
    final key = DateFormat('yyyy-MM').format(month);
    return _monthlyExpenses[key] ?? 0;
  }

  double get _highestMonthlyExpense {
    final values = _lastSixMonths.map(_monthlyAmount);
    return values.fold<double>(0, (max, value) => value > max ? value : max);
  }

  @override
  Widget build(BuildContext context) {
    final growing = _countStatus('Growing');
    final harvested = _countStatus('Harvested');
    final planned = _countStatus('Planned');
    final failed = _countStatus('Failed');

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Farm Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: background,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh analytics',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : _error != null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: green,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _heroCard(),
                  const SizedBox(height: 20),
                  _sectionTitle('Farm performance'),
                  const SizedBox(height: 12),
                  _performanceGrid(),
                  const SizedBox(height: 24),
                  _sectionTitle('Monthly expenses'),
                  const SizedBox(height: 12),
                  _panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense records',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _money(_totalExpenses),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Highest month: ${_money(_highestMonthlyExpense)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(height: 220, child: _monthlyChart()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Expense categories'),
                  const SizedBox(height: 12),
                  _panel(child: _categoryChart()),
                  const SizedBox(height: 24),
                  _sectionTitle('Crop status'),
                  const SizedBox(height: 12),
                  _panel(
                    child: _crops.isEmpty
                        ? const _EmptyChart(
                            message: 'Add crops to see status analytics.',
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: 190,
                                child: PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 42,
                                    sectionsSpace: 3,
                                    sections: [
                                      _section(growing, green),
                                      _section(harvested, Colors.blue),
                                      _section(planned, Colors.orange),
                                      _section(failed, Colors.red),
                                      _section(
                                        _otherStatusCount(
                                          growing,
                                          harvested,
                                          planned,
                                          failed,
                                        ),
                                        Colors.grey,
                                      ),
                                    ].where((s) => s.value > 0).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 14,
                                runSpacing: 10,
                                children: [
                                  _legend('Growing', green, growing),
                                  _legend('Harvested', Colors.blue, harvested),
                                  _legend('Planned', Colors.orange, planned),
                                  _legend('Failed', Colors.red, failed),
                                  _legend(
                                    'Other',
                                    Colors.grey,
                                    _otherStatusCount(
                                      growing,
                                      harvested,
                                      planned,
                                      failed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Growth stages'),
                  const SizedBox(height: 12),
                  _panel(
                    child: _crops.isEmpty
                        ? const _EmptyChart(
                            message: 'Growth-stage data will appear here.',
                          )
                        : SizedBox(height: 230, child: _growthChart()),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Activity insights'),
                  const SizedBox(height: 12),
                  _panel(
                    child: Column(
                      children: [
                        _detailRow(
                          Icons.task_alt,
                          'Recorded activities',
                          '$_activityCount',
                          green,
                        ),
                        const Divider(height: 24),
                        _detailRow(
                          Icons.payments_outlined,
                          'Activity expenses',
                          _money(_activityExpenses),
                          Colors.orange.shade800,
                        ),
                        const Divider(height: 24),
                        _detailRow(
                          Icons.agriculture_outlined,
                          'Average crops per farm',
                          _farms.isEmpty
                              ? '—'
                              : (_crops.length / _farms.length).toStringAsFixed(
                                  1,
                                ),
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Crop summary'),
                  const SizedBox(height: 12),
                  _panel(
                    child: Column(
                      children: [
                        _detailRow(
                          Icons.trending_up,
                          'Currently growing',
                          '$growing crops',
                          green,
                        ),
                        const Divider(height: 22),
                        _detailRow(
                          Icons.agriculture,
                          'Harvested',
                          '$harvested crops',
                          Colors.blue,
                        ),
                        const Divider(height: 22),
                        _detailRow(
                          Icons.event,
                          'Planned',
                          '$planned crops',
                          Colors.orange,
                        ),
                        const Divider(height: 22),
                        _detailRow(
                          Icons.warning_amber_rounded,
                          'Failed',
                          '$failed crops',
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  int _otherStatusCount(int growing, int harvested, int planned, int failed) {
    return (_crops.length - growing - harvested - planned - failed).clamp(
      0,
      _crops.length,
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF104B32), Color(0xFF2D9862)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 30),
          const SizedBox(height: 12),
          const Text(
            'Your farming overview',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          const Text(
            'Grow smarter with data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              _headerStat('Farms', '${_farms.length}'),
              _headerStat('Crops', '${_crops.length}'),
              _headerStat('Land area', _totalArea.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceGrid() {
    final items = [
      _MetricData('Total farms', '${_farms.length}', Icons.agriculture, green),
      _MetricData('Total crops', '${_crops.length}', Icons.grass, Colors.teal),
      _MetricData(
        'Land area',
        _totalArea.toStringAsFixed(1),
        Icons.landscape,
        Colors.brown,
      ),
      _MetricData(
        'Activities',
        '$_activityCount',
        Icons.checklist,
        Colors.blue,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE5EDE5)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _monthlyChart() {
    final months = _lastSixMonths;
    final highest = _highestMonthlyExpense;
    final maxY = highest <= 0 ? 100.0 : highest * 1.25;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = months[group.x];
              return BarTooltipItem(
                '${DateFormat('MMM yyyy').format(month)}\n${_money(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  _compactMoney(value),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= months.length) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('MMM').format(months[index]),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(months.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _monthlyAmount(months[index]),
                color: green,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _categoryChart() {
    final categories = _sortedCategories;

    if (categories.isEmpty || categories.every((entry) => entry.value <= 0)) {
      return const _EmptyChart(
        message: 'Add expenses to see category breakdown.',
      );
    }

    final colors = [
      green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.brown,
      Colors.indigo,
    ];

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 38,
              sectionsSpace: 3,
              sections: [
                for (var i = 0; i < categories.length; i++)
                  if (categories[i].value > 0)
                    PieChartSectionData(
                      value: categories[i].value,
                      color: colors[i % colors.length],
                      radius: 45,
                      title: '',
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < categories.length; i++)
          if (categories[i].value > 0) ...[
            _categoryRow(
              categories[i].key,
              categories[i].value,
              colors[i % colors.length],
            ),
            if (i != categories.length - 1) const SizedBox(height: 13),
          ],
      ],
    );
  }

  Widget _categoryRow(String name, double amount, Color color) {
    final total = _categoryExpenses.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final percentage = total <= 0 ? 0.0 : amount / total;

    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE9EFE9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _money(amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _growthChart() {
    const stages = [
      'Seedling',
      'Vegetative',
      'Flowering',
      'Fruiting',
      'Maturing',
      'Harvested',
    ];

    const labels = ['Seed', 'Veg', 'Flower', 'Fruit', 'Mature', 'Harvest'];

    final maxCount = stages
        .map(_countStage)
        .fold<int>(0, (max, count) => count > max ? count : max);

    final maxY = (maxCount + 1).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    labels[index],
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(stages.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _countStage(stages[index]).toDouble(),
                color: green,
                width: 19,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 54, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(backgroundColor: green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE5)),
      ),
      child: child,
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ($count)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _detailRow(IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  PieChartSectionData _section(int count, Color color) {
    return PieChartSectionData(
      value: count.toDouble(),
      color: color,
      radius: 48,
      title: count == 0 ? '' : '$count',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _money(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(value);
  }

  String _compactMoney(double value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₹${value.toStringAsFixed(0)}';
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.bar_chart, size: 45, color: Colors.black26),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
