import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class ValuesScreen extends StatelessWidget {
  const ValuesScreen({super.key});

  void _showValueInputDialog(BuildContext context, int alternativeIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ValueInputDialog(alternativeIndex: alternativeIndex);
      },
    );
  }

  bool _areValuesSet(DataProvider provider, int altIndex) {
    if (provider.values.isEmpty || altIndex >= provider.values.length) {
      return false;
    }
    return !provider.values[altIndex].values.any((value) => value < 0);
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Reset',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah kamu yakin ingin mereset semua nilai?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).resetValues();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Semua nilai berhasil direset.',
                      style: GoogleFonts.poppins()),
                ),
              );
            },
            child: Text('Reset', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final criteria = provider.criteria;
    final alternatives = provider.alternatives;

    if (criteria.length < 2 || alternatives.length < 2) {
      return Center(
        child: Text(
          'Minimal 2 kriteria dan 2 alternatif untuk mengisi nilai!',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: alternatives.length,
        itemBuilder: (context, index) {
          final alternative = alternatives[index];
          final bool isSet = _areValuesSet(provider, index);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(alternative.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: Text(
                isSet ? 'Nilai sudah diisi' : 'Ketuk untuk mengisi nilai',
                style: GoogleFonts.poppins(
                    color: isSet ? Colors.green : Colors.grey),
              ),
              trailing: Icon(
                isSet ? Icons.check_circle : Icons.edit_note,
                color: isSet ? Colors.green : Colors.grey,
              ),
              onTap: () => _showValueInputDialog(context, index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reset',
        backgroundColor: Colors.red,
        onPressed: () => _confirmReset(context),
        icon: const Icon(Icons.refresh),
        label: Text('Reset Nilai', style: GoogleFonts.poppins()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ValueInputDialog extends StatefulWidget {
  final int alternativeIndex;

  const ValueInputDialog({super.key, required this.alternativeIndex});

  @override
  ValueInputDialogState createState() => ValueInputDialogState();
}

class ValueInputDialogState extends State<ValueInputDialog> {
  late final List<TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DataProvider>(context, listen: false);
    final values = provider.values[widget.alternativeIndex].values;

    _controllers = List.generate(
      provider.criteria.length,
      (index) {
        final value = values[index];
        return TextEditingController(
            text: value >= 0 ? value.toStringAsFixed(0) : '');
      },
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveValues() {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<DataProvider>(context, listen: false);

      for (int i = 0; i < _controllers.length; i++) {
        final value = double.parse(_controllers[i].text);
        provider.updateValue(widget.alternativeIndex, i, value);
      }

      provider.saveValues();

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final criteria = provider.criteria;
    final alternativeName = provider.alternatives[widget.alternativeIndex].name;

    return AlertDialog(
      title: Text('Nilai untuk "$alternativeName"',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: ListBody(
            children: List.generate(criteria.length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _controllers[index],
                  decoration: InputDecoration(
                    labelText: criteria[index].name,
                    hintText: 'Masukkan nilai',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wajib diisi';
                    }
                    final doubleValue = double.tryParse(value);
                    if (doubleValue == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
              );
            }),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Batal', style: GoogleFonts.poppins()),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Simpan', style: GoogleFonts.poppins()),
          onPressed: _saveValues,
        ),
      ],
    );
  }
}
