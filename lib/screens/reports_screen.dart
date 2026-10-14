import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  static const Color _green = Color(0xFF176B45);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ReportService.instance.getReportData();
      if (!mounted) return;

      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf({required bool share}) async {
    final data = _data;
    if (data == null) return;

    setState(() => _exporting = true);

    try {
      final bytes = await ReportService.instance.generatePdf(data);

      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'farmpulse_report.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'FarmPulse Report',
        );
      }
    } catch (e) {
      _showMessage('PDF export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyCsv() async {
    final data = _data;
    if (data == null) return;

    try {
      final csv = ReportService.instance.generateCsv(data);
      await Clipboard.setData(ClipboardData(text: csv));
      _showMessage('CSV report copied. Paste it into Excel or a text file.');
    } catch (e) {
      _showMessage('CSV export failed: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _money(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F4),
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: _loading ? null : _loadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildReport(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Could not load the report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadReport,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport() {
    final data = _data!;
    final farms = data['farms'] as List;
    final crops = data['crops'] as List;
    final categories = data['categoryBreakdown'] as Map<String, double>;
    final monthly = data['monthlyExpenses'] as Map<String, double>;

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF176B45), Color(0xFF104B32)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  'FarmPulse Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Generated ${(data['generatedAt'] as DateTime).toLocal().toString().split('.').first}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                _summaryRow('Total expenses', _money(data['totalExpenses'])),
                _summaryRow('Total land', '${data['totalArea']}'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _statCard('Total Farms', '${farms.length}', Icons.agriculture),
              _statCard('Total Crops', '${crops.length}', Icons.grass),
              _statCard(
                'Total Expenses',
                _money(data['totalExpenses']),
                Icons.account_balance_wallet_outlined,
              ),
              _statCard(
                'Expense Categories',
                '${categories.length}',
                Icons.pie_chart_outline,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle('Expenses by Category'),
          if (categories.isEmpty)
            _emptyCard('No expenses recorded yet.')
          else
            ...categories.entries.map(
              (entry) => _breakdownTile(
                entry.key,
                _money(entry.value),
                Icons.receipt_long_outlined,
              ),
            ),
          const SizedBox(height: 20),
          _sectionTitle('Monthly Expenses'),
          if (monthly.isEmpty)
            _emptyCard('Monthly expense data will appear here.')
          else
            ...monthly.entries.map(
              (entry) => _breakdownTile(
                entry.key,
                _money(entry.value),
                Icons.calendar_month_outlined,
              ),
            ),
          const SizedBox(height: 24),
          _sectionTitle('Export Your Report'),
          const Text(
            'Create a PDF report or copy CSV data for use in Excel.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _exporting ? null : () => _exportPdf(share: false),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Print / Save PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _exporting ? null : () => _exportPdf(share: true),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _copyCsv,
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Copy CSV for Excel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          if (_exporting) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1EAE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _green, size: 25),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: _green,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _breakdownTile(String title, String amount, IconData icon) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE7F2E9),
          child: Icon(icon, color: _green),
        ),
        title: Text(title),
        trailing: Text(
          amount,
          style: const TextStyle(
            color: _green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}
