import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/alternative.dart';
import '../providers/data_provider.dart';

class AlternativesScreen extends StatefulWidget {
  const AlternativesScreen({super.key});

  @override
  AlternativesScreenState createState() => AlternativesScreenState();
}

class AlternativesScreenState extends State<AlternativesScreen> {
  void _showAddEditDialog(BuildContext context,
      {Alternative? alternative, int? index}) {
    final nameController = TextEditingController(text: alternative?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            alternative == null ? 'Tambah Alternatif' : 'Edit Alternatif',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nama Alternatif',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: GoogleFonts.poppins(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Masukkan nama alternatif' : null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Masukkan nama alternatif!',
                          style: GoogleFonts.poppins()),
                    ),
                  );
                  return;
                }

                final newAlternative = Alternative(name: nameController.text);
                final provider =
                    Provider.of<DataProvider>(context, listen: false);
                if (alternative == null) {
                  provider.addAlternative(newAlternative);
                } else {
                  provider.updateAlternative(index!, newAlternative);
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
    return Consumer<DataProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: provider.alternatives.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50), 
                          Text(
                            'Belum ada alternatif.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: provider.alternatives.length,
                        itemBuilder: (context, index) {
                          final alternative = provider.alternatives[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(
                                alternative.name,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
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
                                      alternative: alternative,
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
                                          title: Text('Hapus Alternatif',
                                              style: GoogleFonts.poppins()),
                                          content: Text(
                                            'Hapus alternatif "${alternative.name}"?',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: Text('Batal',
                                                  style: GoogleFonts.poppins()),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                provider
                                                    .deleteAlternative(index);
                                                Navigator.pop(ctx);
                                              },
                                              child: Text('Hapus',
                                                  style: GoogleFonts.poppins()),
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
                        Text('Tambah Alternatif', style: GoogleFonts.poppins()),
                  ),
                  ElevatedButton(
                    onPressed: provider.alternatives.isEmpty
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Reset Alternatif',
                                    style: GoogleFonts.poppins()),
                                content: Text(
                                  'Apakah Anda yakin ingin mereset semua alternatif?',
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
                                      provider.resetAlternatives();
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
    );
  }
}
