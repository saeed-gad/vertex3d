/// تفقيط المبلغ بالعربية (جنيه/قرش أو دولار/سنت).
const _ones = [
  '', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية',
  'تسعة', 'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر',
  'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر'
];
const _tens = [
  '', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون',
  'تسعون'
];
const _hund = [
  '', 'مائة', 'مئتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة',
  'سبعمائة', 'ثمانمائة', 'تسعمائة'
];

String _below1000(int n) {
  final parts = <String>[];
  final h = n ~/ 100, r = n % 100;
  if (h > 0) parts.add(_hund[h]);
  if (r > 0) {
    if (r < 20) {
      parts.add(_ones[r]);
    } else {
      final u = r % 10, t = r ~/ 10;
      parts.add(u > 0 ? '${_ones[u]} و${_tens[t]}' : _tens[t]);
    }
  }
  return parts.join(' و');
}

/// [one, two, few(3-10), many(11-99), other(100+)]
String _scale(int n, List<String> f) {
  if (n == 1) return f[0];
  if (n == 2) return f[1];
  final r = n % 100;
  if (r >= 3 && r <= 10) return '${_below1000(n)} ${f[2]}';
  if (n < 100 && r >= 11) return '${_below1000(n)} ${f[3]}';
  return '${_below1000(n)} ${f[4]}';
}

String _intWords(int n) {
  if (n == 0) return 'صفر';
  final groups = <String>[];
  final b = n ~/ 1000000000, m = (n ~/ 1000000) % 1000, k = (n ~/ 1000) % 1000, u = n % 1000;
  if (b > 0) groups.add(_scale(b, ['مليار', 'ملياران', 'مليارات', 'مليارا', 'مليار']));
  if (m > 0) groups.add(_scale(m, ['مليون', 'مليونان', 'ملايين', 'مليوناً', 'مليون']));
  if (k > 0) groups.add(_scale(k, ['ألف', 'ألفان', 'آلاف', 'ألفاً', 'ألف']));
  if (u > 0) groups.add(_below1000(u));
  return groups.join(' و');
}

String _unit(int n, List<String> f) {
  // f = [مفرد, مثنى, جمع(3-10), تمييز(11+)]
  if (n == 1) return '${f[0]} واحد';
  if (n == 2) return f[1];
  final r = n % 100;
  if (n >= 3 && n <= 10) return '${_intWords(n)} ${f[2]}';
  if (r >= 3 && r <= 10) return '${_intWords(n)} ${f[2]}';
  return '${_intWords(n)} ${f[3]}';
}

String amountInWordsAr(double amount, String currency) {
  final cents = (amount * 100).round();
  final major = cents ~/ 100, minor = cents % 100;
  final isUsd = currency == 'USD';
  final mj = isUsd
      ? ['دولار', 'دولاران', 'دولارات', 'دولاراً']
      : ['جنيه', 'جنيهان', 'جنيهات', 'جنيهاً'];
  final mn = isUsd
      ? ['سنت', 'سنتان', 'سنتات', 'سنتاً']
      : ['قرش', 'قرشان', 'قروش', 'قرشاً'];
  final parts = <String>[];
  if (major > 0 || minor == 0) {
    parts.add(major == 0 ? 'صفر ${mj[3]}' : _unit(major, mj));
  }
  if (minor > 0) parts.add(_unit(minor, mn));
  return parts.join(' و');
}
