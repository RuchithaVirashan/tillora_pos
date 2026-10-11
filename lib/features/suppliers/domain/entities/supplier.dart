import 'package:equatable/equatable.dart';

class SupplierAddress extends Equatable {
  const SupplierAddress({this.number = '', this.street = '', this.district = '', this.country = ''});

  final String number;
  final String street;
  final String district;
  final String country;

  bool get isEmpty => number.isEmpty && street.isEmpty && district.isEmpty && country.isEmpty;

  /// "No., Street" on one line, as shown in the details panel.
  String get line => [number, street].where((s) => s.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [number, street, district, country];
}

class Supplier extends Equatable {
  const Supplier({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
  });

  /// Null until saved.
  final int? id;
  final String name;
  final SupplierAddress address;
  final String phone;
  final String email;

  /// Up to two initials for the avatar.
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return (words.length == 1 ? words.first.substring(0, words.first.length.clamp(0, 2)) : '${words[0][0]}${words[1][0]}').toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, address, phone, email];
}

/// Sri Lanka's districts, for the address picker.
const sriLankaDistricts = [
  'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 'Gampaha', 'Hambantota', 'Jaffna',
  'Kalutara', 'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
  'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya',
];
