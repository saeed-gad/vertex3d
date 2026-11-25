import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../google_config.dart';
import '../l10n.dart';
import '../models.dart';

/// حالة التطبيق: تسجيل الدخول + بيانات Firestore (متزامنة وتعمل أوفلاين).
/// مسار البيانات:  users/{uid}  (بيانات الشركة)
///                 users/{uid}/clients/{id}
///                 users/{uid}/invoices/{id}
class AppState extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool authReady = false;
  User? user;

  Company? company;
  bool companyLoaded = false;
  List<Client> clients = [];
  List<Invoice> invoices = [];
  bool synced = true;

  StreamSubscription? _authSub, _companySub, _clientsSub, _invoicesSub;

  AppState() {
    _authSub = _auth.authStateChanges().listen(_onUser);
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(user!.uid);

  void _onUser(User? u) {
    _companySub?.cancel();
    _clientsSub?.cancel();
    _invoicesSub?.cancel();
    user = u;
    authReady = true;
    company = null;
    companyLoaded = false;
    clients = [];
    invoices = [];
    notifyListeners();
    if (u == null) return;

    _companySub = _userDoc.snapshots(includeMetadataChanges: true).listen((s) {
      final data = s.data();
      company = (s.exists && data != null && data['name'] != null)
          ? Company.fromMap(data)
          : null;
      companyLoaded = true;
      synced = !s.metadata.hasPendingWrites && !s.metadata.isFromCache;
      notifyListeners();
    }, onError: (_) {
      companyLoaded = true;
      notifyListeners();
    });

    _clientsSub = _userDoc
        .collection('clients')
        .orderBy('name')
        .snapshots()
        .listen((s) {
      clients = s.docs.map(Client.fromDoc).toList();
      notifyListeners();
    });

    _invoicesSub = _userDoc
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((s) {
      invoices = s.docs.map(Invoice.fromDoc).toList();
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------- Auth

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return tr('badEmail');
      case 'weak-password':
        return tr('weakPassword');
      case 'email-already-in-use':
        return tr('emailUsed');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return tr('badCreds');
      default:
        return '${tr('error')} (${e.code})';
    }
  }

  /// يرجّع نص الخطأ أو null لو نجح.
  Future<String?> signInEmail(String email, String pass) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: pass);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<String?> register(String email, String pass) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: pass);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  Future<String?> signInGoogle() async {
    try {
      final g = await GoogleSignIn(serverClientId: kWebClientId.isEmpty ? null : kWebClientId).signIn();
      if (g == null) return ''; // المستخدم لغى
      final a = await g.authentication;
      final cred = GoogleAuthProvider.credential(
          accessToken: a.accessToken, idToken: a.idToken);
      await _auth.signInWithCredential(cred);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (e) {
      return '${tr('error')}\n$e';
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ------------------------------------------------------------- الكتابة
  // ملاحظة: مش بنعمل await على الكتابة لأن Firestore بيخلّص الـ Future
  // بعد تأكيد السيرفر، وده بيعلّق الواجهة لو النت فاصل. الكتابة بتتسجل
  // محلياً فوراً وبتترفع لوحدها لما النت يرجع.

  void saveCompany(Company c, {bool first = false}) {
    final data = c.toMap();
    if (first) data['nextNumber'] = 1;
    _userDoc.set(data, SetOptions(merge: true)).catchError((_) {});
  }

  String saveClient(Client c) {
    final col = _userDoc.collection('clients');
    final ref = c.id.isEmpty ? col.doc() : col.doc(c.id);
    ref.set(c.toMap()).catchError((_) {});
    return ref.id;
  }

  void deleteClient(String id) =>
      _userDoc.collection('clients').doc(id).delete().catchError((_) {});

  /// يحفظ الفاتورة ويرجّع الـ id. لو جديدة بيزوّد عدّاد الأرقام.
  String saveInvoice(Invoice inv, {required bool isNew}) {
    final col = _userDoc.collection('invoices');
    final ref = inv.id.isEmpty ? col.doc() : col.doc(inv.id);
    final batch = _db.batch();
    batch.set(ref, inv.toMap());
    if (isNew) {
      batch.set(_userDoc, {'nextNumber': FieldValue.increment(1)},
          SetOptions(merge: true));
    }
    batch.commit().catchError((_) {});
    return ref.id;
  }

  void setInvoiceStatus(String id, String status) => _userDoc
      .collection('invoices')
      .doc(id)
      .update({'status': status}).catchError((_) {});

  void deleteInvoice(String id) =>
      _userDoc.collection('invoices').doc(id).delete().catchError((_) {});

  // ---------------------------------------------------------- مساعدات

  Invoice? invoiceById(String id) {
    for (final i in invoices) {
      if (i.id == id) return i;
    }
    return null;
  }

  Client? clientById(String id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  double sumFor(Iterable<Invoice> list, DisplayStatus s) => list
      .where((i) => i.display == s)
      .fold(0.0, (a, i) => a + i.total);

  @override
  void dispose() {
    _authSub?.cancel();
    _companySub?.cancel();
    _clientsSub?.cancel();
    _invoicesSub?.cancel();
    super.dispose();
  }
}
