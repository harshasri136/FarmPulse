import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/crop_model.dart';
import '../models/farm_model.dart';
import 'crop_database_service.dart';
import 'expense_database_service.dart';
import 'farm_database_service.dart';

class ReportService {
  ReportService._();

  static final ReportService instance = ReportService._();

  /// Loads all data required for the FarmPulse report.
  Future<Map<String, dynamic>> getReportData() async {
    final results = await Future.wait<dynamic>([
      FarmDatabaseService.instance.getFarms(),
      CropDatabaseService.instance.getCrops(),
      FarmDatabaseService.instance.getTotalArea(),
      ExpenseDatabaseService.instance.getTotalExpenses(),
      ExpenseDatabaseService.instance.getCategoryBreakdown(),
      ExpenseDatabaseService.instance.getMonthlyExpenses(months: 6),
    ]);

    return {
      'farms': results[0] as List<FarmModel>,
      'crops': results[1] as List<CropModel>,
      'totalArea': (results[2] as num).toDouble(),
      'totalExpenses': (results[3] as num).toDouble(),
      'categoryBreakdown': results[4] as Map<String, double>,
      'monthlyExpenses': results[5] as Map<String, double>,
      'generatedAt': DateTime.now(),
    };
  }

  /// Generates CSV text compatible with csv package 8.0.0.
  String generateCsv(Map<String, dynamic> data) {
    final farms = data['farms'] as List<FarmModel>;
    final crops = data['crops'] as List<CropModel>;
    final categories = data['categoryBreakdown'] as Map<String, double>;
    final monthly = data['monthlyExpenses'] as Map<String, double>;
    final generatedAt = data['generatedAt'] as DateTime;

    final rows = <List<dynamic>>[
      ['FARMPULSE FARM MANAGEMENT REPORT'],
      ['Generated At', generatedAt.toIso8601String()],
      [],
      ['OVERVIEW'],
      ['Total Farms', farms.length],
      ['Total Crops', crops.length],
      ['Total Land Area', data['totalArea']],
      ['Total Expenses', data['totalExpenses']],
      [],
      ['FARM DETAILS'],
      ['Farm ID', 'Farm Name', 'Location', 'Area', 'Area Unit', 'Soil Type'],
      ...farms.map(
        (farm) => [
          farm.id ?? '',
          farm.name,
          farm.location,
          farm.area,
          farm.areaUnit,
          farm.soilType,
        ],
      ),
      [],
      ['CROP DETAILS'],
      [
        'Crop ID',
        'Farm ID',
        'Crop Name',
        'Variety',
        'Planting Date',
        'Harvest Date',
        'Growth Stage',
        'Status',
      ],
      ...crops.map(
        (crop) => [
          crop.id ?? '',
          crop.farmId,
          crop.name,
          crop.variety,
          crop.plantingDate.toIso8601String().split('T').first,
          crop.harvestDate.toIso8601String().split('T').first,
          crop.growthStage,
          crop.status,
        ],
      ),
      [],
      ['EXPENSES BY CATEGORY'],
      ['Category', 'Amount'],
      ...categories.entries.map((entry) => [entry.key, entry.value]),
      [],
      ['MONTHLY EXPENSES'],
      ['Month', 'Amount'],
      ...monthly.entries.map((entry) => [entry.key, entry.value]),
    ];

    return csv.encode(rows);
  }

  /// Generates a PDF report as bytes.
  Future<Uint8List> generatePdf(Map<String, dynamic> data) async {
    final farms = data['farms'] as List<FarmModel>;
    final crops = data['crops'] as List<CropModel>;
    final categories = data['categoryBreakdown'] as Map<String, double>;
    final monthly = data['monthlyExpenses'] as Map<String, double>;
    final generatedAt = data['generatedAt'] as DateTime;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'FarmPulse',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#176B45'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Smart Farm Management Report',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated: ${generatedAt.toLocal().toString().split('.').first}',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Divider(),
          pw.Header(level: 1, text: 'Farm Overview'),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Farms', '${farms.length}'],
              ['Total Crops', '${crops.length}'],
              ['Total Land Area', '${data['totalArea']}'],
              ['Total Expenses', _money(data['totalExpenses'] as num)],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Header(level: 1, text: 'Farm Details'),
          if (farms.isEmpty)
            pw.Text('No farms have been added yet.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Farm', 'Location', 'Area', 'Soil'],
              data: farms
                  .map(
                    (farm) => [
                      farm.name,
                      farm.location,
                      '${farm.area} ${farm.areaUnit}',
                      farm.soilType,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 18),
          pw.Header(level: 1, text: 'Crop Details'),
          if (crops.isEmpty)
            pw.Text('No crops have been added yet.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Crop', 'Variety', 'Stage', 'Status'],
              data: crops
                  .map(
                    (crop) => [
                      crop.name,
                      crop.variety,
                      crop.growthStage,
                      crop.status,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 18),
          pw.Header(level: 1, text: 'Expenses by Category'),
          if (categories.isEmpty)
            pw.Text('No expenses recorded yet.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Category', 'Amount'],
              data: categories.entries
                  .map((entry) => [entry.key, _money(entry.value)])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 18),
          pw.Header(level: 1, text: 'Monthly Expenses'),
          if (monthly.isEmpty)
            pw.Text('No monthly expense data available.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Month', 'Amount'],
              data: monthly.entries
                  .map((entry) => [entry.key, _money(entry.value)])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            'Generated by FarmPulse',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _money(num amount) => 'Rs. ${amount.toStringAsFixed(2)}';
}
