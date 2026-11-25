import 'package:intl/intl.dart' as intl;

class Lang {
  static String code = 'ar';
  static bool get isAr => code == 'ar';
}

const Map<String, List<String>> _s = {
  // key: [ar, en]
  'appName': ['إنفويسر', 'Invoicer'],
  'tagline': ['إدارة فواتيرك بكل سهولة في مصر', 'Manage your invoices with ease'],
  'loginGoogle': ['تسجيل الدخول بـ Google', 'Sign in with Google'],
  'orEmail': ['أو بريدك الإلكتروني', 'or with email'],
  'email': ['البريد الإلكتروني', 'Email'],
  'password': ['كلمة المرور', 'Password'],
  'forgot': ['نسيت كلمة المرور؟', 'Forgot password?'],
  'login': ['تسجيل الدخول', 'Sign in'],
  'noAccount': ['ليس لديك حساب؟', "Don't have an account?"],
  'createAccount': ['إنشاء حساب جديد', 'Create account'],
  'haveAccount': ['لديك حساب؟', 'Already have an account?'],
  'resetSent': ['تم إرسال رابط إعادة التعيين لبريدك', 'Reset link sent to your email'],
  'enterEmail': ['اكتب بريدك الإلكتروني أولاً', 'Enter your email first'],
  'welcome': ['أهلاً بك في نظام الفواتير', 'Welcome to Invoicer'],
  'setupSub': ['خطوة واحدة وتكون جاهزاً لإصدار أول فاتورة لعملائك.',
    'One step and you are ready to issue your first invoice.'],
  'logo': ['شعار الشركة (اللوجو)', 'Company logo'],
  'tapLogo': ['اضغط لرفع صورة', 'Tap to upload'],
  'companyName': ['اسم الشركة', 'Company name'],
  'phone': ['رقم الهاتف', 'Phone'],
  'address': ['العنوان', 'Address'],
  'taxNumber': ['الرقم الضريبي', 'Tax number'],
  'commercialReg': ['رقم السجل التجاري', 'Commercial register'],
  'optional': ['اختياري', 'Optional'],
  'currency': ['العملة', 'Currency'],
  'saveContinue': ['حفظ ومتابعة', 'Save & continue'],
  'editLater': ['يمكنك تعديل هذه البيانات في أي وقت من الإعدادات.',
    'You can edit this later in Settings.'],
  'required': ['مطلوب', 'Required'],
  'home': ['الرئيسية', 'Home'],
  'invoices': ['الفواتير', 'Invoices'],
  'clients': ['العملاء', 'Clients'],
  'settings': ['الإعدادات', 'Settings'],
  'hello': ['مرحباً بك،', 'Welcome,'],
  'synced': ['مزامنة الآن', 'Synced'],
  'notSynced': ['جارٍ المزامنة...', 'Syncing...'],
  'quickReport': ['تقرير سريع', 'Quick report'],
  'collectedPct': ['تم تحصيل %s%% من إجمالي الفواتير', '%s%% of total invoices collected'],
  'totalInvoices': ['إجمالي الفواتير', 'Total invoices'],
  'paid': ['المدفوعة', 'Paid'],
  'pending': ['المعلقة', 'Pending'],
  'overdue': ['المتأخرة', 'Overdue'],
  'draft': ['مسودة', 'Draft'],
  'all': ['الكل', 'All'],
  'recent': ['أحدث الفواتير', 'Recent invoices'],
  'viewAll': ['عرض الكل', 'View all'],
  'newInvoice': ['فاتورة جديدة', 'New invoice'],
  'editInvoice': ['تعديل الفاتورة', 'Edit invoice'],
  'noInvoices': ['لا توجد فواتير بعد', 'No invoices yet'],
  'searchInvoices': ['ابحث برقم الفاتورة أو اسم العميل...', 'Search invoice number or client...'],
  'dueDate': ['تاريخ الاستحقاق', 'Due date'],
  'invoiceDate': ['تاريخ الفاتورة', 'Invoice date'],
  'autoNumber': ['رقم الفاتورة التلقائي', 'Invoice number'],
  'client': ['العميل', 'Client'],
  'chooseClient': ['اختر العميل...', 'Choose client...'],
  'addClient': ['إضافة عميل', 'Add client'],
  'addNewClient': ['إضافة عميل جديد', 'Add new client'],
  'items': ['بنود الفاتورة', 'Items'],
  'addItem': ['إضافة صنف', 'Add item'],
  'description': ['الوصف', 'Description'],
  'qty': ['الكمية', 'Qty'],
  'price': ['السعر', 'Price'],
  'total': ['الإجمالي', 'Total'],
  'subtotal': ['المجموع الفرعي', 'Subtotal'],
  'discount': ['الخصم', 'Discount'],
  'tax': ['ضريبة القيمة المضافة', 'VAT'],
  'taxRate': ['نسبة الضريبة %', 'Tax rate %'],
  'grandTotal': ['المجموع الكلي', 'Grand total'],
  'notes': ['ملاحظات وشروط الدفع', 'Notes & payment terms'],
  'saveDraft': ['حفظ مسودة', 'Save draft'],
  'issue': ['إصدار الفاتورة', 'Issue invoice'],
  'save': ['حفظ', 'Save'],
  'pickClient': ['اختر عميلاً أولاً', 'Please choose a client'],
  'addAnItem': ['أضف بنداً واحداً على الأقل', 'Add at least one item'],
  'invoiceDetails': ['تفاصيل الفاتورة', 'Invoice details'],
  'billTo': ['موجّه إلى', 'Bill to'],
  'issueDate': ['تاريخ الإصدار', 'Issue date'],
  'statement': ['البيان / الوصف', 'Description'],
  'sendWhatsapp': ['إرسال عبر واتساب', 'Send via WhatsApp'],
  'sharePdf': ['مشاركة كـ PDF', 'Share as PDF'],
  'print': ['طباعة', 'Print'],
  'markPaid': ['تحديد كمدفوعة', 'Mark as paid'],
  'edit': ['تعديل', 'Edit'],
  'delete': ['حذف', 'Delete'],
  'view': ['عرض', 'View'],
  'confirmDelete': ['متأكد من الحذف؟ مش هتقدر ترجّعه.', 'Delete? This cannot be undone.'],
  'cancel': ['إلغاء', 'Cancel'],
  'invoice': ['فاتورة', 'Invoice'],
  'taxInvoice': ['فاتورة', 'INVOICE'],
  'preparingPdf': ['جارٍ تجهيز الفاتورة...', 'Preparing invoice...'],
  'pdfError': ['تعذّر إنشاء ملف PDF', 'Could not create the PDF'],
  'invoiceFrom': ['فاتورة رقم', 'Invoice'],
  'overdueBy': ['متأخرة عن الاستحقاق بـ %s يوم', 'Overdue by %s days'],
  'dueOn': ['الاستحقاق: %s', 'Due: %s'],
  'manageClients': ['إدارة العملاء', 'Manage clients'],
  'searchClients': ['ابحث بالاسم أو الهاتف...', 'Search by name or phone...'],
  'totalDue': ['إجمالي المستحقات على العملاء', 'Total owed by clients'],
  'clientsCount': ['%s عميل', '%s clients'],
  'invoicesCount': ['%s فواتير', '%s invoices'],
  'owed': ['مستحق', 'Owed'],
  'settled': ['مسدد بالكامل', 'Settled'],
  'clientName': ['اسم العميل', 'Client name'],
  'countryCode': ['كود الدولة', 'Code'],
  'clientDetails': ['بيانات العميل', 'Client'],
  'editClient': ['تعديل العميل', 'Edit client'],
  'noClients': ['لا يوجد عملاء بعد', 'No clients yet'],
  'cloudSync': ['حالة المزامنة السحابية', 'Cloud sync'],
  'syncedSub': ['كل بياناتك محفوظة ومتاحة على أي هاتف', 'All data is saved and available on any phone'],
  'syncingSub': ['فيه تغييرات بتتزامن لما النت يرجع', 'Changes will sync when online'],
  'companyData': ['بيانات الشركة والشعار', 'Company & logo'],
  'changeLogo': ['تغيير الشعار', 'Change logo'],
  'defaults': ['إعدادات الفواتير الافتراضية', 'Invoice defaults'],
  'prefix': ['بادئة رقم الفاتورة', 'Invoice prefix'],
  'defaultTax': ['نسبة ضريبة القيمة المضافة', 'Default VAT rate'],
  'defaultNotes': ['ملاحظات افتراضية', 'Default notes'],
  'appearance': ['التطبيق والمظهر', 'App & appearance'],
  'language': ['لغة التطبيق', 'Language'],
  'darkMode': ['الوضع الليلي', 'Dark mode'],
  'signOut': ['تسجيل الخروج', 'Sign out'],
  'saved': ['تم الحفظ', 'Saved'],
  'egp': ['جنيه مصري (EGP)', 'Egyptian pound (EGP)'],
  'usd': ['دولار (USD)', 'US dollar (USD)'],
  'thanks': ['شكراً لتعاملكم معنا.', 'Thank you for your business.'],
  'whatsappMsg': ['فاتورة رقم %s من %s\nالإجمالي: %s', 'Invoice %s from %s\nTotal: %s'],
  'discountPct': ['خصم %', 'Disc. %'],
  'taxes': ['الضرائب', 'Taxes'],
  'amount': ['المبلغ', 'Amount'],
  'unitPrice': ['سعر الوحدة', 'Unit price'],
  'invoiceTitle': ['الفاتورة', 'Invoice'],
  'customerInvoiceDate': ['تاريخ فاتورة العميل', 'Invoice date'],
  'dueDateLbl': ['تاريخ الاستحقاق', 'Due date'],
  'untaxed': ['المبلغ دون الضريبة', 'Untaxed amount'],
  'vatAt': ['قيمة مضافة %s%% في %s', 'VAT %s%% on %s'],
  'totalLbl': ['الإجمالي', 'Total'],
  'paidOn': ['تم الدفع في %s', 'Paid on %s'],
  'amountDue': ['المبلغ المستحق', 'Amount due'],
  'paymentRef': ['التواصل بشأن الدفع', 'Payment communication'],
  'amountInWords': ['إجمالي المبلغ بالكلمات:', 'Total amount in words:'],
  'page': ['الصفحة', 'Page'],
  'country': ['الدولة', 'Country'],
  'paidAmount': ['المبلغ المدفوع', 'Amount paid'],
  'amountDueShort': ['المتبقي', 'Remaining'],
  'nextNumber': ['رقم الفاتورة القادمة', 'Next invoice number'],
  'prefixHint': ['مثال: INV/2026/', 'e.g. INV/2026/'],
  'updates': ['التحديثات', 'Updates'],
  'checkUpdate': ['التحقق من وجود تحديث', 'Check for updates'],
  'checking': ['جارٍ التحقق...', 'Checking...'],
  'upToDate': ['أنت على آخر إصدار ✅', 'You have the latest version ✅'],
  'updateAvailable': ['يتوفر إصدار جديد (رقم %s)', 'New version available (build %s)'],
  'updateNow': ['تحديث الآن', 'Update now'],
  'later': ['لاحقاً', 'Later'],
  'currentVersion': ['الإصدار الحالي: %s', 'Current version: %s'],
  'updateFailed': ['تعذّر التحقق من التحديث', 'Could not check for updates'],
  'updateHint': ['هيتفتح رابط التحميل، نزّل الملف وثبّته فوق النسخة الحالية (بياناتك هتفضل زي ما هي).',
    'The download link will open. Install the file over the current app; your data is kept.'],
  'error': ['حصل خطأ، حاول تاني', 'Something went wrong'],
  'weakPassword': ['كلمة المرور ضعيفة (6 حروف على الأقل)', 'Password too weak (min 6 chars)'],
  'badCreds': ['البريد أو كلمة المرور غير صحيحة', 'Wrong email or password'],
  'emailUsed': ['البريد مستخدم بالفعل', 'Email already in use'],
  'badEmail': ['البريد الإلكتروني غير صالح', 'Invalid email'],
};

String tr(String key, [List<Object> args = const []]) {
  final v = _s[key];
  var out = v == null ? key : v[Lang.isAr ? 0 : 1];
  for (final a in args) {
    out = out.replaceFirst('%s', '$a');
  }
  return out.replaceAll('%%', '%');
}

String fmtNum(double v) {
  final f = intl.NumberFormat('#,##0.##', 'en');
  return f.format(v);
}

String currencySymbol(String code) {
  if (code == 'USD') return r'$';
  return Lang.isAr ? 'ج.م' : 'EGP';
}

String money(double v, String currency) =>
    '${fmtNum(v)} ${currencySymbol(currency)}';

String fmtDate(DateTime d) =>
    intl.DateFormat('d MMM yyyy', Lang.code).format(d);

String fmt2(double v) => intl.NumberFormat('#,##0.00', 'en').format(v);

/// مبلغ بتنسيق الفاتورة المطبوعة: LE 12,700.00
String pdfMoney(double v, String currency) =>
    '${currency == 'USD' ? r'$' : 'LE'} ${fmt2(v)}';
