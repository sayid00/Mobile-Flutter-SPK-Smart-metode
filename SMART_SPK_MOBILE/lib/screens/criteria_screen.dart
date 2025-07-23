import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/criteria.dart';
import '../providers/data_provider.dart';

class CriteriaScreen extends StatefulWidget {
  const CriteriaScreen({super.key});

  @override
  CriteriaScreenState createState() => CriteriaScreenState();
}

class CriteriaScreenState extends State<CriteriaScreen> {
  String _weightFormat = 'percent';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DataProvider>(context, listen: false);
    _weightFormat = provider.weightFormat;
  }

  double _calculateTotalWeight(List<Criteria> criteria, String weightFormat) {
    return criteria.fold(
        0.0,
        (sum, c) =>
            sum + (weightFormat == 'percent' ? c.weight : c.weight / 100));
  }

  String _formatTotalWeight(double totalWeight, String weightFormat) {
    if (weightFormat == 'percent') {
      return '${totalWeight.toStringAsFixed(0)}%';
    }
    return totalWeight
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  void _showAddEditDialog(BuildContext context,
      {Criteria? criterion, int? index}) {
    final nameController = TextEditingController(text: criterion?.name ?? '');
    final weightController = TextEditingController(
      text: criterion != null
          ? (_weightFormat == 'percent'
              ? criterion.weight.toStringAsFixed(3).replaceAll('.', ',')
              : (criterion.weight / 100)
                  .toStringAsFixed(3)
                  .replaceAll('.', ','))
          : '',
    );
    CriteriaType type = criterion?.type ?? CriteriaType.benefit;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            criterion == null ? 'Tambah Kriteria' : 'Edit Kriteria',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kriteria',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Masukkan nama kriteria' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText:
                        'Bobot (${_weightFormat == 'percent' ? '%' : 'Desimal'})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                    hintText: _weightFormat == 'percent'
                        ? 'Contoh: 25'
                        : 'Contoh: 0,484',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    _CommaDecimalFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan bobot';
                    }
                    final normalizedValue = value.replaceAll(',', '.');
                    final parsed = double.tryParse(normalizedValue);
                    if (parsed == null || parsed <= 0) {
                      return 'Masukkan bobot valid (contoh: ${_weightFormat == 'percent' ? '25' : '0,484'})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CriteriaType>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: 'Jenis',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: CriteriaType.benefit, child: Text('Benefit')),
                    DropdownMenuItem(
                        value: CriteriaType.cost, child: Text('Cost')),
                  ],
                  onChanged: (value) {
                    type = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty ||
                    weightController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Isi semua field dengan valid!',
                          style: GoogleFonts.poppins()),
                    ),
                  );
                  return;
                }
                final normalizedWeight =
                    weightController.text.replaceAll(',', '.');
                final weight = double.tryParse(normalizedWeight);
                if (weight == null || weight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Bobot harus valid (contoh: ${_weightFormat == 'percent' ? '25' : '0,484'})!',
                          style: GoogleFonts.poppins()),
                    ),
                  );
                  return;
                }

                final provider =
                    Provider.of<DataProvider>(context, listen: false);
                // Normalisasi bobot ke format persen untuk penyimpanan
                final adjustedWeight =
                    _weightFormat == 'percent' ? weight : weight * 100;

                final newCriterion = Criteria(
                  name: nameController.text,
                  weight: adjustedWeight,
                  type: type,
                  weightFormat: _weightFormat,
                );

                if (criterion == null) {
                  provider.addCriterion(newCriterion);
                } else {
                  provider.updateCriterion(index!, newCriterion);
                }
                Navigator.pop(ctx);
              },
              child: Text('Simpan', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final provider = Provider.of<DataProvider>(context, listen: false);
        if (provider.criteria.isNotEmpty) {
          final totalWeight =
              _calculateTotalWeight(provider.criteria, _weightFormat);
          final expectedTotal = _weightFormat == 'percent' ? 100.0 : 1.0;
          if ((totalWeight - expectedTotal).abs() > 0.01) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Total bobot harus $expectedTotal${_weightFormat == 'percent' ? '%' : ''}!',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
            return false; 
          }
        }
        return true; 
      },
      child: Consumer<DataProvider>(
        builder: (context, provider, _) {
          final totalWeight =
              _calculateTotalWeight(provider.criteria, _weightFormat);
          final expectedTotal = _weightFormat == 'percent' ? 100.0 : 1.0;
          final isTotalWeightValid = provider.criteria.isEmpty ||
              (totalWeight - expectedTotal).abs() <= 0.01;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _weightFormat,
                  decoration: InputDecoration(
                    labelText: 'Format Bobot',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Persen')),
                    DropdownMenuItem(value: 'decimal', child: Text('Desimal')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _weightFormat = value!;
                      provider.setWeightFormat(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: provider.criteria.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 50), 
                            Text(
                              'Belum ada kriteria.',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: provider.criteria.length,
                          itemBuilder: (context, index) {
                            final criterion = provider.criteria[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: ListTile(
                                title: Text(
                                  criterion.name,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'Bobot: ${(_weightFormat == 'percent' ? criterion.weight : criterion.weight / 100).toStringAsFixed(3).replaceAll('.', ',')} '
                                  '(${_weightFormat == 'percent' ? '%' : 'Desimal'}, '
                                  '${criterion.type == CriteriaType.benefit ? 'Benefit' : 'Cost'})',
                                  style: GoogleFonts.poppins(),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                      onPressed: () => _showAddEditDialog(
                                        context,
                                        criterion: criterion,
                                        index: index,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text('Hapus Kriteria',
                                                style: GoogleFonts.poppins()),
                                            content: Text(
                                              'Hapus kriteria "${criterion.name}"?',
                                              style: GoogleFonts.poppins(),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: Text('Batal',
                                                    style:
                                                        GoogleFonts.poppins()),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  provider
                                                      .deleteCriterion(index);
                                                  Navigator.pop(ctx);
                                                },
                                                child: Text('Hapus',
                                                    style:
                                                        GoogleFonts.poppins()),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Text(
                  'Total Bobot: ${_formatTotalWeight(totalWeight, _weightFormat)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isTotalWeightValid
                        ? Theme.of(context).colorScheme.primary
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showAddEditDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          Text('Tambah Kriteria', style: GoogleFonts.poppins()),
                    ),
                    ElevatedButton(
                      onPressed: provider.criteria.isEmpty
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Reset Kriteria',
                                      style: GoogleFonts.poppins()),
                                  content: Text(
                                    'Apakah Anda yakin ingin mereset semua kriteria?',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('Batal',
                                          style: GoogleFonts.poppins()),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        provider.resetCriteria();
                                        Navigator.pop(ctx);
                                      },
                                      child: Text('Reset',
                                          style: GoogleFonts.poppins()),
                                    ),
                                  ],
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      child: Text('Reset', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommaDecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll('.', ',');

    int commaCount = newText.split(',').length - 1;
    if (commaCount > 1) {
      return oldValue;
    }

    if (!RegExp(r'^[0-9]*(,[0-9]*)?$').hasMatch(newText)) {
      return oldValue;
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
