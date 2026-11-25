import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n.dart';
import '../models.dart';
import '../widgets/common.dart';

class PdfService {
  static pw.Font? _regular, _bold;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/pdf_regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/pdf_bold.ttf'));
  }

  /// يبني ملف PDF للفاتورة (بالعربي أو الإنجليزي حسب لغة التطبيق).
  static Future<Uint8List> build(Invoice inv, Company co) async {
    await _loadFonts();
    final rtl = Lang.isAr;
    final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final start = rtl ? pw.TextAlign.right : pw.TextAlign.left;
    final end = rtl ? pw.TextAlign.left : pw.TextAlign.right;
    final crossStart =
        rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final crossEnd =
        rtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end;

    const navy = PdfColor.fromInt(0xFF00236F);
    const grey = PdfColor.fromInt(0xFF666B78);
    const light = PdfColor.fromInt(0xFFF1F3F8);
    final cur = co.currency;

    pw.Widget t(String s,
            {double size = 10,
            bool bold = false,
            PdfColor? color,
            pw.TextAlign? align}) =>
        pw.Text(s,
            textDirection: dir,
            textAlign: align ?? start,
            style: pw.TextStyle(
                fontSize: size,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color));

    // الصفحة LTR دايماً، والعربي بنقلب ترتيب العناصر يدوياً (أضمن من الاعتماد على اتجاه الصفحة).
    pw.Widget row(List<pw.Widget> kids) => pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: rtl ? kids.reversed.toList() : kids);

    final logo = co.logoBytes;
    final statusKey = {
      DisplayStatus.paid: 'paid',
      DisplayStatus.pending: 'pending',
      DisplayStatus.overdue: 'overdue',
      DisplayStatus.draft: 'draft',
    }[inv.display]!;

    final doc = pw.Document(title: inv.number, author: co.name);

    pw.Widget cell(String s, int flex,
            {bool head = false, pw.TextAlign? align}) =>
        pw.Expanded(
          flex: flex,
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: t(s,
                size: head ? 9.5 : 10,
                bold: head,
                color: head ? PdfColors.white : null,
                align: align),
          ),
        );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
        ),
        build: (ctx) => [
          // ---- رأس الفاتورة
          row([
            if (logo != null) ...[
              pw.Container(
                width: 64,
                height: 64,
                child: pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 12),
            ],
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: crossStart, children: [
                t(co.name, size: 18, bold: true, color: navy),
                if (co.address.isNotEmpty) t(co.address, color: grey),
                if (co.phone.isNotEmpty) t(co.phone, color: grey),
                if (co.email.isNotEmpty) t(co.email, color: grey),
                if (co.taxNumber.isNotEmpty)
                  t('${tr('taxNumber')}: ${co.taxNumber}', color: grey),
              ]),
            ),
            pw.Column(crossAxisAlignment: crossEnd, children: [
              t(tr('taxInvoice'), size: 22, bold: true, color: navy, align: end),
              pw.SizedBox(height: 4),
              t(inv.number, size: 12, bold: true, align: end),
              pw.SizedBox(height: 2),
              t(tr(statusKey), color: grey, align: end),
            ]),
          ]),
          pw.SizedBox(height: 16),
          pw.Divider(color: navy, thickness: 1.5),
          pw.SizedBox(height: 10),

          // ---- العميل والتواريخ
          row([
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                    color: light, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(crossAxisAlignment: crossStart, children: [
                  t(tr('billTo'), color: grey, size: 9),
                  pw.SizedBox(height: 3),
                  t(inv.clientName, bold: true, size: 12),
                  if (inv.clientAddress.isNotEmpty) t(inv.clientAddress),
                  if (inv.clientPhone.isNotEmpty) t(inv.clientPhone),
                ]),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                    color: light, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(crossAxisAlignment: crossStart, children: [
                  t(tr('issueDate'), color: grey, size: 9),
                  t(fmtDate(inv.date), bold: true),
                  pw.SizedBox(height: 6),
                  t(tr('dueDate'), color: grey, size: 9),
                  t(fmtDate(inv.dueDate), bold: true),
                ]),
              ),
            ),
          ]),
          pw.SizedBox(height: 16),

          // ---- جدول البنود
          pw.Container(
            color: navy,
            child: row([
              cell(tr('statement'), 5, head: true),
              cell(tr('qty'), 1, head: true, align: pw.TextAlign.center),
              cell(tr('price'), 2, head: true, align: end),
              cell(tr('total'), 2, head: true, align: end),
            ]),
          ),
          ...inv.items.map((i) => pw.Container(
                decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey300))),
                child: row([
                  cell(i.description, 5),
                  cell(fmtNum(i.qty), 1, align: pw.TextAlign.center),
                  cell(fmtNum(i.price), 2, align: end),
                  cell(fmtNum(i.total), 2, align: end),
                ]),
              )),
          pw.SizedBox(height: 14),

          // ---- الإجماليات
          pw.Align(
            alignment:
                rtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 230,
              child: pw.Column(children: [
                _totalRow(t, row, tr('subtotal'), money(inv.subtotal, cur), end),
                if (inv.discount > 0)
                  _totalRow(
                      t, row, tr('discount'), '- ${money(inv.discount, cur)}', end),
                _totalRow(
                    t,
                    row,
                    '${tr('tax')} (${fmtNum(inv.taxRate)}%)',
                    money(inv.tax, cur),
                    end),
                pw.Divider(color: navy),
                _totalRow(t, row, tr('grandTotal'), money(inv.total, cur), end,
                    big: true),
              ]),
            ),
          ),

          // ---- الملاحظات
          if (inv.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF4E8),
                  borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(crossAxisAlignment: crossStart, children: [
                t(tr('notes'), bold: true),
                pw.SizedBox(height: 3),
                t(inv.notes),
              ]),
            ),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _totalRow(
      pw.Widget Function(String,
              {double size, bool bold, PdfColor? color, pw.TextAlign? align})
          t,
      pw.Widget Function(List<pw.Widget>) row,
      String label,
      String value,
      pw.TextAlign end,
      {bool big = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: row([
        pw.Expanded(child: t(label, size: big ? 12 : 10, bold: big)),
        t(value, size: big ? 13 : 10, bold: big, align: end),
      ]),
    );
  }

  // ------------------------------------------------------------ إجراءات

  static Future<File> _toFile(Invoice inv, Company co) async {
    final bytes = await build(inv, co);
    final dir = await getTemporaryDirectory();
    final safe = inv.number.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    final f = File('${dir.path}/$safe.pdf');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  /// يولّد الـ PDF ويفتح قائمة المشاركة. لو [whatsapp] فالرسالة المصاحبة
  /// بتكون جاهزة وتختار واتساب من القائمة (واتساب بيطلب اختيار الجهة بإيدك).
  static Future<void> share(BuildContext context, Invoice inv, Company co) async {
    toast(context, tr('preparingPdf'));
    try {
      final f = await _toFile(inv, co);
      final text = tr('whatsappMsg',
          [inv.number, co.name, money(inv.total, co.currency)]);
      await Share.shareXFiles(
        [XFile(f.path, mimeType: 'application/pdf')],
        subject: inv.number,
        text: text,
      );
    } catch (e) {
      if (context.mounted) toast(context, '${tr('pdfError')}\n$e');
    }
  }

  static Future<void> printInvoice(
      BuildContext context, Invoice inv, Company co) async {
    try {
      await Printing.layoutPdf(
          name: inv.number, onLayout: (_) => build(inv, co));
    } catch (e) {
      if (context.mounted) toast(context, '${tr('pdfError')}\n$e');
    }
  }
}
