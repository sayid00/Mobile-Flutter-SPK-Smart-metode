import 'package:flutter/foundation.dart';
import '../models/criteria.dart';
import '../models/alternative.dart';
import '../models/value_data.dart';

class DataProvider with ChangeNotifier {
  List<Criteria> _criteria = [];
  List<Alternative> _alternatives = [];
  List<ValueData> _values = [];
  String _weightFormat = 'percent';
  bool _isValuesSaved = false;

  List<Criteria> get criteria => _criteria;
  List<Alternative> get alternatives => _alternatives;
  List<ValueData> get values => _values;
  String get weightFormat => _weightFormat;
  bool get isValuesSaved => _isValuesSaved;

  void setWeightFormat(String format) {
    _weightFormat = format;
    for (var criterion in _criteria) {
      criterion.weightFormat = format;
    }
    notifyListeners();
  }

  void saveValues() {
    _isValuesSaved = true;
    notifyListeners();
  }

  void addCriterion(Criteria criterion) {
    _criteria.add(criterion);
    _values = _values.map((v) {
      final newValues = List<double>.from(v.values)..add(-1.0); 
      return ValueData(name: v.name, values: newValues);
    }).toList();
    _isValuesSaved = false;
    notifyListeners();
  }

  void updateCriterion(int index, Criteria criterion) {
    if (index >= 0 && index < _criteria.length) {
      _criteria[index] = criterion;
      _isValuesSaved = false;
      notifyListeners();
    }
  }

  void deleteCriterion(int index) {
    if (index >= 0 && index < _criteria.length) {
      _criteria.removeAt(index);
      _values = _values.map((v) {
        final newValues = List<double>.from(v.values);
        newValues.removeAt(index);
        return ValueData(name: v.name, values: newValues);
      }).toList();
      _isValuesSaved = false;
      notifyListeners();
    }
  }

  void addAlternative(Alternative alternative) {
    _alternatives.add(alternative);
    _values.add(ValueData(
      name: alternative.name,
      values: List.filled(_criteria.length, -1.0), 
    ));
    _isValuesSaved = false;
    notifyListeners();
  }

  void updateAlternative(int index, Alternative alternative) {
    if (index >= 0 && index < _alternatives.length) {
      _alternatives[index] = alternative;
      _values[index] = ValueData(
        name: alternative.name,
        values: _values[index].values,
      );
      _isValuesSaved = false;
      notifyListeners();
    }
  }

  void deleteAlternative(int index) {
    if (index >= 0 && index < _alternatives.length) {
      _alternatives.removeAt(index);
      _values.removeAt(index);
      _isValuesSaved = false;
      notifyListeners();
    }
  }

  void updateValue(int altIndex, int critIndex, double value) {
    if (altIndex >= 0 &&
        altIndex < _values.length &&
        critIndex >= 0 &&
        critIndex < _values[altIndex].values.length) {
      _values[altIndex] = ValueData(
        name: _values[altIndex].name,
        values: List<double>.from(_values[altIndex].values)..[critIndex] = value,
      );
      _isValuesSaved = false;
      notifyListeners();
    }
  }

  void resetCriteria() {
    _criteria = [];
    _values = _alternatives
        .map((alt) => ValueData(
              name: alt.name,
              values: List.filled(0, -1.0), 
            ))
        .toList();
    _isValuesSaved = false;
    notifyListeners();
  }

  void resetAlternatives() {
    _alternatives = [];
    _values = [];
    _isValuesSaved = false;
    notifyListeners();
  }

  void resetValues() {
    _values = _alternatives
        .map((alt) => ValueData(
              name: alt.name,
              values: List.filled(_criteria.length, -1.0),
            ))
        .toList();
    _isValuesSaved = false;
    notifyListeners();
  }

  void resetAll() {
    _criteria = [];
    _alternatives = [];
    _values = [];
    _weightFormat = 'percent';
    _isValuesSaved = false;
    notifyListeners();
  }
}