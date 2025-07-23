import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/criteria.dart';
import '../providers/data_provider.dart';
import '../services/smart_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String chartType = 'Bar Chart';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final smartService = SmartService(
      criteria: provider.criteria,
      alternatives: provider.alternatives,
      values: provider.values,
      weightFormat: provider.weightFormat,
    );
    final hasilAnalisis = smartService.calculateSMART();
    final matriksNormalisasi = hasilAnalisis.matriksNormalisasi;
    final ranking = hasilAnalisis.ranking;

    return Scaffold(
      body: provider.criteria.isEmpty ||
              provider.alternatives.isEmpty ||
              ranking.isEmpty
          ? Center(
              child: Text(
                'Harap masukkan data kriteria, alternatif, dan nilai terlebih dahulu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Analisis',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pdf = pw.Document();
                      final image = await imageFromAssetBundle(
                          'assets/images/pdf.png');  
                      pdf.addPage(
                        pw.Page(
                          pageFormat: PdfPageFormat.a4,
                          build: (context) {
                            return pw.Stack(
                              children: [
                                pw.Positioned.fill(
                                  child: pw.Image(image, fit: pw.BoxFit.cover),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(24),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'Hasil Analisis',
                                        style: pw.TextStyle(
                                            fontSize: 20,
                                            fontWeight: pw.FontWeight.bold),
                                      ),
                                      pw.SizedBox(height: 12),
                                      pw.Table.fromTextArray(
                                        border: pw.TableBorder.all(),
                                        cellAlignment: pw.Alignment.centerLeft,
                                        headerDecoration: pw.BoxDecoration(
                                            color: PdfColors.grey300),
                                        headers: [
                                          'Peringkat',
                                          'Alternatif',
                                          'Skor',
                                          ...provider.criteria
                                              .map((c) => c.name),
                                        ],
                                        data: ranking
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final rank = entry.key + 1;
                                          final result = entry.value;
                                          return [
                                            '$rank',
                                            result.alternatif.name,
                                            result.skor.toStringAsFixed(3),
                                            ...provider.criteria.map((c) {
                                              final val = matriksNormalisasi[
                                                  result.alternatif.id]![c.id]!;
                                              return val.toStringAsFixed(3);
                                            }).toList()
                                          ];
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );

                      await Printing.layoutPdf(
                        onLayout: (format) async => pdf.save(),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text('Export PDF',
                        style: GoogleFonts.poppins(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        border: TableBorder.all(color: Colors.grey[300]!),
                        columnSpacing: 16.0,
                        columns: [
                          DataColumn(
                            label: Text('Peringkat',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Alternatif',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Skor',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold)),
                          ),
                          ...provider.criteria.map(
                            (c) => DataColumn(
                              label: Text(c.name,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                        rows: ranking.asMap().entries.map((e) {
                          final rank = e.key + 1;
                          final result = e.value;
                          return DataRow(
                            cells: [
                              DataCell(
                                  Text('$rank', style: GoogleFonts.poppins())),
                              DataCell(Text(result.alternatif.name,
                                  style: GoogleFonts.poppins())),
                              DataCell(
                                Text(result.skor.toStringAsFixed(3),
                                    style: GoogleFonts.poppins()),
                              ),
                              ...provider.criteria.map((c) {
                                final utilitas = matriksNormalisasi[
                                    result.alternatif.id]![c.id]!;
                                return DataCell(
                                  Text(
                                    utilitas.toStringAsFixed(3),
                                    style: GoogleFonts.poppins(),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(height: 24, thickness: 1, color: Colors.grey),

                  // ExpansionTile: Cara Perhitungan
                  ExpansionTile(
                    backgroundColor: Colors.grey[100],
                    collapsedBackgroundColor: Colors.blue[50],
                    title: Text(
                      'Cara Perhitungan',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Metode SMART digunakan untuk menghitung skor akhir berdasarkan kriteria. Langkah-langkah:',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text('1. Normalisasi Nilai:',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '   - Benefit: (Nilai - Min) / (Max - Min)\n   - Cost: (Max - Nilai) / (Max - Min)',
                                style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            Text('2. Hitung Skor:',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                            Text('   Σ (Normalisasi × Bobot)',
                                style: GoogleFonts.poppins()),
                            const SizedBox(height: 8),
                            Text('3. Urutkan berdasarkan skor tertinggi.',
                                style: GoogleFonts.poppins()),
                          ],
                        ),
                      )
                    ],
                  ),

                  const Divider(height: 24, thickness: 1, color: Colors.grey),

                  ExpansionTile(
                    backgroundColor: Colors.grey[100],
                    collapsedBackgroundColor: Colors.blue[50],
                    title: Text(
                      'Rekap Kriteria & Alternatif',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kriteria:',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                border:
                                    TableBorder.all(color: Colors.grey[300]!),
                                columns: [
                                  DataColumn(
                                      label: Text('Nama',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Bobot',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('Jenis',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: provider.criteria.map((criterion) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(criterion.name,
                                          style: GoogleFonts.poppins())),
                                      DataCell(Text(
                                          '${criterion.weight.toStringAsFixed(2)}${provider.weightFormat == 'percent' ? '%' : ''}',
                                          style: GoogleFonts.poppins())),
                                      DataCell(Text(
                                          criterion.type == CriteriaType.benefit
                                              ? 'Benefit'
                                              : 'Cost',
                                          style: GoogleFonts.poppins())),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Alternatif:',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                border:
                                    TableBorder.all(color: Colors.grey[300]!),
                                columns: [
                                  DataColumn(
                                      label: Text('Nama',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: provider.alternatives.map((alt) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(alt.name,
                                          style: GoogleFonts.poppins())),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  const Divider(height: 24, thickness: 1, color: Colors.grey),

                  ExpansionTile(
                    backgroundColor: Colors.grey[100],
                    collapsedBackgroundColor: Colors.blue[50],
                    title: Text(
                      'Normalisasi Nilai',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(color: Colors.grey[300]!),
                            columns: [
                              DataColumn(
                                  label: Text('Alternatif',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold))),
                              ...provider.criteria.map(
                                (c) => DataColumn(
                                  label: Text(c.name,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                            rows: provider.alternatives.map((alt) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(alt.name,
                                      style: GoogleFonts.poppins())),
                                  ...provider.criteria.map((crit) {
                                    final value =
                                        matriksNormalisasi[alt.id]![crit.id]!;
                                    return DataCell(Text(
                                        value.toStringAsFixed(4),
                                        style: GoogleFonts.poppins()));
                                  }).toList(),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    ],
                  ),

                  const Divider(height: 24, thickness: 1, color: Colors.grey),

                  ExpansionTile(
                    backgroundColor: Colors.grey[100],
                    collapsedBackgroundColor: Colors.blue[50],
                    title: Text(
                      'Visualisasi Skor Akhir',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4),
                            child: DropdownButton<String>(
                              value: chartType,
                              isExpanded: true,
                              onChanged: (value) {
                                setState(() {
                                  chartType = value!;
                                });
                              },
                              items: ['Bar Chart', 'Pie Chart']
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type,
                                            style: GoogleFonts.poppins()),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (chartType == 'Bar Chart')
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: ranking.length * 100,
                                height: 300,
                                child: BarChart(
                                  BarChartData(
                                    barGroups: ranking.asMap().entries.map((e) {
                                      return BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value.skor,
                                            width: 28,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.7),
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < ranking.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Transform.rotate(
                                                  angle: -0.5,
                                                  child: Text(
                                                    ranking[index]
                                                        .alternatif
                                                        .name,
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 10),
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) =>
                                              Text(
                                            value.toStringAsFixed(1),
                                            style: GoogleFonts.poppins(
                                                fontSize: 11),
                                          ),
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: const FlGridData(show: true),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipMargin: 12,
                                        tooltipRoundedRadius: 12,
                                        tooltipPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                        getTooltipItem:
                                            (group, groupIndex, rod, _) {
                                          return BarTooltipItem(
                                            '${ranking[groupIndex].alternatif.name}\nSkor: ${rod.toY.toStringAsFixed(3)}',
                                            GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 300,
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 4,
                                  sections:
                                      ranking.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final result = entry.value;
                                    final color = Colors.primaries[
                                        idx % Colors.primaries.length];
                                    return PieChartSectionData(
                                      value: result.skor,
                                      title:
                                          '${result.alternatif.name}\n(${result.skor.toStringAsFixed(2)})',
                                      radius: 80,
                                      titleStyle: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      color: color,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
