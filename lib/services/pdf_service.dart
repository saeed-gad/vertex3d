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
import 'number_words.dart';

class PdfService {
  static pw.Font? _regular, _bold;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/pdf_regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/pdf_bold.ttf'));
  }

  static const _purple = PdfColor.fromInt(0xFF5C4370);
  static const _ink = PdfColor.fromInt(0xFF1E1E28);
  static const _muted = PdfColor.fromInt(0xFF6B6F7B);
  static const _line = PdfColor.fromInt(0xFF3A3A48);
  static const _shade = PdfColor.fromInt(0xFFF1F2F6);
  static const _decor = PdfColor.fromInt(0xFFD8D3DE);

  /// الخطوط الزخرفية أعلى اليمين وأسفل الصفحة (زي القالب القديم).
  static void _paintDecor(PdfGraphics c, PdfPoint s) {
    final w = s.x, h = s.y;
    c
      ..setStrokeColor(_decor)
      ..setLineWidth(0.5);
    for (var i = 0; i < 14; i++) {
      final sx = w * 0.38 + i * w * 0.022;
      c
        ..moveTo(sx, h)
        ..curveTo(sx + w * 0.02, h - h * 0.05, w * 0.80 + i * w * 0.01,
            h - h * 0.06 - i * h * 0.004, w, h - h * 0.10 - i * h * 0.011)
        ..strokePath();
    }
    for (var i = 0; i < 12; i++) {
      final y = h * 0.075 - i * h * 0.0055;
      c
        ..moveTo(0, y)
        ..curveTo(w * 0.3, y + h * 0.03, w * 0.65, y - h * 0.025, w, y + h * 0.02)
        ..strokePath();
    }
  }

  /// يبني ملف PDF بنفس تصميم الفاتورة القديمة.
  static Future<Uint8List> build(Invoice inv, Company co) async {
    await _loadFonts();
    final rtl = Lang.isAr;
    final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final start = rtl ? pw.TextAlign.right : pw.TextAlign.left; // بداية السطر
    final endA = rtl ? pw.TextAlign.left : pw.TextAlign.right; // نهاية السطر
    final cross = rtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    String m(double v) => pdfMoney(v, co.currency);

    List<T> vis<T>(List<T> l) => rtl ? l.reversed.toList() : l;

    pw.Widget t(String s,
            {double size = 10,
            bool bold = false,
            PdfColor color = _ink,
            pw.TextAlign? align}) =>
        pw.Text(s,
            textDirection: dir,
            textAlign: align ?? start,
            style: pw.TextStyle(
                fontSize: size,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color));

    pw.Widget cellBox(pw.Widget child, {PdfColor? bg}) => pw.Container(
        color: bg,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: child);

    pw.Widget numCell(String s, {bool bold = false, PdfColor color = _ink, PdfColor? bg}) =>
        cellBox(
            pw.Text(s,
                textDirection: pw.TextDirection.ltr,
                textAlign: pw.TextAlign.left,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: color)),
            bg: bg);

    final logo = co.logoBytes;
    final title = '${tr('invoiceTitle')} ${inv.number}';

    // ---------------- جدول البنود
    // الترتيب المنطقي (LTR): وصف | كمية | سعر | خصم | ضرائب | مبلغ
    final colFlex = [5.0, 1.3, 2.0, 1.4, 1.4, 2.6];
    final visFlex = vis(colFlex);
    final widths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < visFlex.length; i++) i: pw.FlexColumnWidth(visFlex[i])
    };
    final taxCell = inv.taxRate > 0 ? '${fmtNum(inv.taxRate)}%' : '';

    pw.TableRow headerRow() => pw.TableRow(
          repeat: true,
          children: vis<pw.Widget>([
            cellBox(t(tr('description'))),
            cellBox(t(tr('qty'))),
            cellBox(t(tr('unitPrice'))),
            cellBox(t(tr('discountPct'))),
            cellBox(t(tr('taxes'))),
            cellBox(t(tr('amount')), bg: _shade),
          ]),
        );

    pw.TableRow itemRow(InvoiceItem i) => pw.TableRow(
          children: vis<pw.Widget>([
            cellBox(t(i.description)),
            numCell(fmt2(i.qty)),
            numCell(fmt2(i.price)),
            numCell(fmt2(i.discountPct)),
            numCell(taxCell),
            numCell(m(i.total), bg: _shade),
          ]),
        );

    final itemsTable = pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: widths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      children: [headerRow(), ...inv.items.map(itemRow)],
    );

    // ---------------- مربع الإجماليات
    pw.TableRow totalRow(String label, String value,
            {bool bold = false, bool shade = false, PdfColor vColor = _ink}) =>
        pw.TableRow(
          decoration: shade ? const pw.BoxDecoration(color: _shade) : null,
          children: vis<pw.Widget>([
            cellBox(t(label, bold: bold)),
            cellBox(t(value, bold: bold, color: vColor, align: endA)),
          ]),
        );

    final totalsRows = <pw.TableRow>[
      if (inv.discount > 0) totalRow(tr('discount'), '- ${m(inv.discount)}'),
      totalRow(tr('untaxed'), m(inv.taxable)),
      totalRow(tr('vatAt', [fmtNum(inv.taxRate), m(inv.taxable)]), m(inv.tax),
          shade: true),
      totalRow(tr('totalLbl'), m(inv.total),
          bold: true, vColor: _purple),
      if (inv.paidEff > 0)
        totalRow(tr('paidOn', [fmtDate(inv.paidDate ?? inv.date)]),
            m(inv.paidEff)),
      totalRow(tr('amountDue'), m(inv.due), bold: true),
    ];

    final totalsBox = pw.SizedBox(
      width: 280,
      child: pw.Table(
        border: pw.TableBorder.all(color: _line, width: 0.6),
        columnWidths: {
          for (var i = 0; i < 2; i++) i: const pw.FlexColumnWidth(1)
        },
        children: totalsRows,
      ),
    );

    // الترتيب المنطقي LTR: [مرجع الدفع (يتمدد) | الإجماليات] -> العربي بينعكس
    final summaryRow = pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: vis<pw.Widget>([
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(top: 14, left: 8, right: 8),
            child: pw.Column(crossAxisAlignment: cross, children: [
              t('${tr('paymentRef')}: ${inv.number}', bold: true),
            ]),
          ),
        ),
        totalsBox,
      ]),
    );

    // ---------------- تاريخين
    pw.Widget dateBox(String label, DateTime d) => pw.SizedBox(
          width: 185,
          child: pw.Column(crossAxisAlignment: cross, children: [
            t(label, bold: true),
            pw.SizedBox(height: 3),
            t(intlDate(d)),
          ]),
        );
    final datesRow = pw.Row(
      mainAxisAlignment:
          rtl ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
      children: vis<pw.Widget>([
        dateBox(tr('customerInvoiceDate'), inv.date),
        pw.SizedBox(width: 10),
        dateBox(tr('dueDateLbl'), inv.dueDate),
      ]),
    );

    final doc = pw.Document(title: inv.number, author: co.name);
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 40),
          textDirection: pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.CustomPaint(
              size: PdfPoint(PdfPageFormat.a4.width, PdfPageFormat.a4.height),
              painter: _paintDecor,
            ),
          ),
        ),
        footer: (ctx) => pw.Align(
          alignment: rtl ? pw.Alignment.centerLeft : pw.Alignment.centerRight,
          child: t('${tr('page')} ${ctx.pageNumber} / ${ctx.pagesCount}',
              size: 9, color: _muted),
        ),
        build: (ctx) => [
          // رأس: اللوجو يسار والدولة يمين
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              logo != null
                  ? pw.Container(
                      width: 150,
                      height: 46,
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Image(pw.MemoryImage(logo),
                          fit: pw.BoxFit.contain,
                          alignment: pw.Alignment.centerLeft),
                    )
                  : pw.Text(co.name,
                      textDirection: dir,
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: _purple)),
              if (co.country.isNotEmpty) t(co.country, color: _ink),
            ],
          ),
          pw.SizedBox(height: 62),
          pw.Center(child: t(title, size: 22, color: _purple, align: pw.TextAlign.center)),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment:
                rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: pw.Column(crossAxisAlignment: cross, children: [
              t(inv.clientName, size: 11, bold: true),
              if (inv.clientAddress.isNotEmpty)
                t(inv.clientAddress, size: 9, color: _muted),
              if (inv.clientPhone.isNotEmpty)
                pw.Text(inv.clientPhone,
                    textDirection: pw.TextDirection.ltr,
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
            ]),
          ),
          pw.SizedBox(height: 16),
          datesRow,
          pw.SizedBox(height: 14),
          itemsTable,
          summaryRow,
          if (rtl) ...[
            pw.SizedBox(height: 16),
            t(tr('amountInWords'), size: 11),
            pw.SizedBox(height: 2),
            t(amountInWordsAr(inv.total, co.currency), size: 9, color: _muted),
          ],
          if (inv.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            t(tr('notes'), bold: true, size: 10),
            pw.SizedBox(height: 2),
            t(inv.notes, size: 9, color: _muted),
          ],
        ],
      ),
    );
    return doc.save();
  }

  static String intlDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ------------------------------------------------------------ إجراءات

  static Future<File> _toFile(Invoice inv, Company co) async {
    final bytes = await build(inv, co);
    final dir = await getTemporaryDirectory();
    final safe = inv.number.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    final f = File('${dir.path}/$safe.pdf');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  /// يولّد الـ PDF ويفتح قائمة المشاركة (اختار واتساب من القائمة).
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
