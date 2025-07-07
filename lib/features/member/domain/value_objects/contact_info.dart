import 'package:app/core/exceptions/domain_exception.dart';

class ContactInfo {
  final String email;
  final String phone;

  const ContactInfo({required this.email, required this.phone});

  factory ContactInfo.create({required String email, required String phone}) {
    _validateEmail(email);
    _validatePhone(phone);

    return ContactInfo(email: email.toLowerCase().trim(), phone: phone.trim());
  }

  ContactInfo update({String? email, String? phone}) {
    final newEmail = email ?? this.email;
    final newPhone = phone ?? this.phone;

    return ContactInfo.create(email: newEmail, phone: newPhone);
  }

  static void _validateEmail(String email) {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      throw DomainException('Email cannot be empty');
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmedEmail)) {
      throw DomainException('Invalid email format');
    }
  }

  static void _validatePhone(String phone) {
    final trimmedPhone = phone.trim();

    if (trimmedPhone.isEmpty) {
      throw DomainException('Phone number cannot be empty');
    }

    final phoneRegex = RegExp(r'^(\+\d{1,3})?[0-9]{9,15}$');
    final cleanPhone = trimmedPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      throw DomainException('Invalid phone number format');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfo && other.email == email && other.phone == phone;
  }

  @override
  int get hashCode => Object.hash(email, phone);

  @override
  String toString() => 'ContactInfo(email: $email, phone: $phone)';
}
