import 'package:uuid/uuid.dart';

class Alternative {
  final String id;
  final String name;

  Alternative({
    String? id,
    required this.name,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory Alternative.fromJson(Map<String, dynamic> json) => Alternative(
        id: json['id'],
        name: json['name'],
      );
}