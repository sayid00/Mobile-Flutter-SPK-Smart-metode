import '../models/criteria.dart';
import '../models/alternative.dart';
import '../models/value_data.dart';

// Kelas untuk menyimpan hasil perankingan
class HasilPerankingan {
  final Alternative alternatif;
  final double skor;
  HasilPerankingan({required this.alternatif, required this.skor});
}

// Kelas untuk menyimpan hasil analisis
class HasilAnalisis {
  final Map<String, Map<String, double>> matriksNormalisasi;
  final List<HasilPerankingan> ranking;

  HasilAnalisis({required this.matriksNormalisasi, required this.ranking});
}

class SmartService {
  final List<Criteria> criteria;
  final List<Alternative> alternatives;
  final List<ValueData> values;
  final String weightFormat;

  SmartService({
    required this.criteria,
    required this.alternatives,
    required this.values,
    required this.weightFormat,
  });

  HasilAnalisis calculateSMART() {
    // Inisialisasi output default jika data kosong
    if (criteria.isEmpty || alternatives.isEmpty || values.isEmpty) {
      return HasilAnalisis(
        matriksNormalisasi: {},
        ranking: [],
      );
    }

    // 1. Hitung nilai min/max untuk setiap kriteria
    final minMaxPerKriteria = <String, Map<String, double>>{};
    for (var crit in criteria) {
      minMaxPerKriteria[crit.id] = {'min': double.infinity, 'max': double.negativeInfinity};
    }

    for (var valueData in values) {
      for (int j = 0; j < criteria.length; j++) {
        final value = valueData.values[j];
        minMaxPerKriteria[criteria[j].id]!['min'] = value < minMaxPerKriteria[criteria[j].id]!['min']! ? value : minMaxPerKriteria[criteria[j].id]!['min']!;
        minMaxPerKriteria[criteria[j].id]!['max'] = value > minMaxPerKriteria[criteria[j].id]!['max']! ? value : minMaxPerKriteria[criteria[j].id]!['max']!;
      }
    }

    // 2. Normalisasi
    final Map<String, Map<String, double>> matriksNormalisasi = {};
    for (var alt in alternatives) {
      matriksNormalisasi[alt.id] = {};
      for (var crit in criteria) {
        final double val = values[alternatives.indexOf(alt)].values[criteria.indexOf(crit)];
        final minVal = minMaxPerKriteria[crit.id]!['min']!;
        final maxVal = minMaxPerKriteria[crit.id]!['max']!;
        double nilaiNormal;

        if (maxVal == minVal) {
          nilaiNormal = 1.0;
        } else {
          if (crit.type == CriteriaType.benefit) {
            nilaiNormal = (val - minVal) / (maxVal - minVal);
          } else {
            nilaiNormal = (maxVal - val) / (maxVal - minVal);
          }
        }
        matriksNormalisasi[alt.id]![crit.id] = nilaiNormal;
      }
    }

    // 3. Hitung Skor Akhir
    final List<HasilPerankingan> ranking = [];
    for (var alt in alternatives) {
      double totalScore = 0;
      for (var crit in criteria) {
        final double nilaiNormal = matriksNormalisasi[alt.id]![crit.id]!;
        // Konversi bobot ke desimal jika dalam persen
        final double bobot = weightFormat == 'percent' ? crit.weight / 100 : crit.weight;
        totalScore += nilaiNormal * bobot;
      }
      ranking.add(HasilPerankingan(alternatif: alt, skor: totalScore));
    }

    // 4. Urutkan berdasarkan skor
    ranking.sort((a, b) => b.skor.compareTo(a.skor));

    return HasilAnalisis(
      matriksNormalisasi: matriksNormalisasi,
      ranking: ranking,
    );
  }
}