import 'package:uuid/uuid.dart';

enum CriteriaType { benefit, cost }

class Criteria {
  final String id;
  final String name;
  final double weight;
  final CriteriaType type;
  String weightFormat;

  Criteria({
    String? id,
    required this.name,
    required this.weight,
    required this.type,
    required this.weightFormat,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'weight': weight,
        'type': type.toString().split('.').last,
        'weightFormat': weightFormat,
      };

  factory Criteria.fromJson(Map<String, dynamic> json) => Criteria(
        id: json['id'],
        name: json['name'],
        weight: json['weight'],
        type: json['type'] == 'benefit' ? CriteriaType.benefit : CriteriaType.cost,
        weightFormat: json['weightFormat'],
      );
}