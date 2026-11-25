import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

double toD(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

/// يحوّل الأرقام العربية و"," إلى رقم عادي.
double parseNum(String s) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var t = s.trim().replaceAll('٫', '.').replaceAll(',', '.');
  for (var i = 0; i < 10; i++) {
    t = t.replaceAll(ar[i], '$i');
  }
  return double.tryParse(t) ?? 0;
}

class Company {
  final String name, phone, email, address, taxNumber, commercialReg, country;
  final String currency; // EGP | USD
  final String logoBase64;
  final String prefix;
  final double taxRate;
  final String defaultNotes;
  final String lang; // ar | en
  final bool dark;
  final int nextNumber;

  Company({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.taxNumber = '',
    this.commercialReg = '',
    this.country = 'مصر',
    this.currency = 'EGP',
    this.logoBase64 = '',
    this.prefix = 'INV/',
    this.taxRate = 14,
    this.defaultNotes = '',
    this.lang = 'ar',
    this.dark = false,
    this.nextNumber = 1,
  });

  Uint8List? _bytes;
  Uint8List? get logoBytes {
    if (logoBase64.isEmpty) return null;
    try {
      return _bytes ??= base64Decode(logoBase64);
    } catch (_) {
      return null;
    }
  }

  factory Company.fromMap(Map<String, dynamic> m) => Company(
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        email: m['email'] ?? '',
        address: m['address'] ?? '',
        taxNumber: m['taxNumber'] ?? '',
        commercialReg: m['commercialReg'] ?? '',
        country: m['country'] ?? 'مصر',
        currency: m['currency'] ?? 'EGP',
        logoBase64: m['logoBase64'] ?? '',
        prefix: m['prefix'] ?? 'INV/',
        taxRate: m['taxRate'] == null ? 14 : toD(m['taxRate']),
        defaultNotes: m['defaultNotes'] ?? '',
        lang: m['lang'] ?? 'ar',
        dark: m['dark'] ?? false,
        nextNumber: (m['nextNumber'] ?? 1) as int,
      );

  /// بدون nextNumber عشان التعديل ما يرجّع العداد.
  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'taxNumber': taxNumber,
        'commercialReg': commercialReg,
        'country': country,
        'currency': currency,
        'logoBase64': logoBase64,
        'prefix': prefix,
        'taxRate': taxRate,
        'defaultNotes': defaultNotes,
        'lang': lang,
        'dark': dark,
      };

  Company copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? taxNumber,
    String? commercialReg,
    String? country,
    String? currency,
    String? logoBase64,
    String? prefix,
    double? taxRate,
    String? defaultNotes,
    String? lang,
    bool? dark,
  }) =>
      Company(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        taxNumber: taxNumber ?? this.taxNumber,
        commercialReg: commercialReg ?? this.commercialReg,
        country: country ?? this.country,
        currency: currency ?? this.currency,
        logoBase64: logoBase64 ?? this.logoBase64,
        prefix: prefix ?? this.prefix,
        taxRate: taxRate ?? this.taxRate,
        defaultNotes: defaultNotes ?? this.defaultNotes,
        lang: lang ?? this.lang,
        dark: dark ?? this.dark,
        nextNumber: nextNumber,
      );

  String get nextInvoiceNumber =>
      '$prefix${nextNumber.toString().padLeft(5, '0')}';
}

class Client {
  final String id;
  final String name, countryCode, phone, email, address;

  Client({
    this.id = '',
    this.name = '',
    this.countryCode = '+20',
    this.phone = '',
    this.email = '',
    this.address = '',
  });

  /// الرقم الكامل بصيغة دولية بدون + (يصلح لواتساب)
  String get fullPhone {
    var p = phone.replaceAll(RegExp(r'[^0-9]'), '');
    p = p.replaceFirst(RegExp(r'^0+'), '');
    final c = countryCode.replaceAll(RegExp(r'[^0-9]'), '');
    return p.isEmpty ? '' : '$c$p';
  }

  String get displayPhone => phone.isEmpty ? '' : '$countryCode $phone';

  factory Client.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Client(
      id: d.id,
      name: m['name'] ?? '',
      countryCode: m['countryCode'] ?? '+20',
      phone: m['phone'] ?? '',
      email: m['email'] ?? '',
      address: m['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'countryCode': countryCode,
        'phone': phone,
        'email': email,
        'address': address,
      };
}

class InvoiceItem {
  final String description;
  final double qty, price, discountPct;
  InvoiceItem(this.description, this.qty, this.price, [this.discountPct = 0]);
  double get gross => qty * price;
  double get total => gross * (1 - discountPct / 100);

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
      m['description'] ?? '', toD(m['qty']), toD(m['price']), toD(m['discountPct']));
  Map<String, dynamic> toMap() => {
        'description': description,
        'qty': qty,
        'price': price,
        'discountPct': discountPct
      };
}

enum DisplayStatus { draft, pending, paid, overdue }

class Invoice {
  final String id, number;
  final String clientId, clientName, clientPhone, clientAddress;
  final DateTime date, dueDate;
  final List<InvoiceItem> items;
  final double discount, taxRate;
  final String notes;
  final String status; // draft | pending | paid
  final double paidAmount;
  final DateTime? paidDate;
  final DateTime createdAt;

  Invoice({
    this.id = '',
    required this.number,
    required this.clientId,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    required this.date,
    required this.dueDate,
    required this.items,
    this.discount = 0,
    this.taxRate = 0,
    this.notes = '',
    this.status = 'draft',
    this.paidAmount = 0,
    this.paidDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get taxable => (subtotal - discount).clamp(0, double.infinity);
  double get tax => taxable * taxRate / 100;
  double get total => taxable + tax;

  /// المدفوع الفعلي (الفاتورة المحددة "مدفوعة" تُعتبر مسددة بالكامل)
  double get paidEff => status == 'paid' ? total : paidAmount.clamp(0, total).toDouble();
  double get due => status == 'draft' ? total : (total - paidEff).clamp(0, double.infinity).toDouble();

  DisplayStatus get display {
    if (status == 'draft') return DisplayStatus.draft;
    if (status == 'paid' || (total > 0 && paidAmount >= total)) {
      return DisplayStatus.paid;
    }
    final today = DateTime.now();
    final d0 = DateTime(today.year, today.month, today.day);
    return dueDate.isBefore(d0) ? DisplayStatus.overdue : DisplayStatus.pending;
  }

  factory Invoice.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    DateTime dt(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();
    return Invoice(
      id: d.id,
      number: m['number'] ?? '',
      clientId: m['clientId'] ?? '',
      clientName: m['clientName'] ?? '',
      clientPhone: m['clientPhone'] ?? '',
      clientAddress: m['clientAddress'] ?? '',
      date: dt(m['date']),
      dueDate: dt(m['dueDate']),
      items: ((m['items'] ?? []) as List)
          .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      discount: toD(m['discount']),
      taxRate: toD(m['taxRate']),
      notes: m['notes'] ?? '',
      status: m['status'] ?? 'draft',
      paidAmount: toD(m['paidAmount']),
      paidDate: m['paidDate'] is Timestamp ? (m['paidDate'] as Timestamp).toDate() : null,
      createdAt: dt(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'number': number,
        'clientId': clientId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientAddress': clientAddress,
        'date': Timestamp.fromDate(date),
        'dueDate': Timestamp.fromDate(dueDate),
        'items': items.map((e) => e.toMap()).toList(),
        'discount': discount,
        'taxRate': taxRate,
        'notes': notes,
        'status': status,
        'paidAmount': paidAmount,
        'paidDate': paidDate == null ? null : Timestamp.fromDate(paidDate!),
        'total': total,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Invoice copyWith({String? status}) => Invoice(
        id: id,
        number: number,
        clientId: clientId,
        clientName: clientName,
        clientPhone: clientPhone,
        clientAddress: clientAddress,
        date: date,
        dueDate: dueDate,
        items: items,
        discount: discount,
        taxRate: taxRate,
        notes: notes,
        status: status ?? this.status,
        paidAmount: paidAmount,
        paidDate: paidDate,
        createdAt: createdAt,
      );
}
