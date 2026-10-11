import 'package:equatable/equatable.dart';

class PaymentType extends Equatable {
  const PaymentType({required this.id, required this.name, required this.imagePath});

  final int id;
  final String name;
  final String imagePath;

  @override
  List<Object?> get props => [id, name];
}
