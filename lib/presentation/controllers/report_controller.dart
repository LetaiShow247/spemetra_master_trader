import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../controllers/trading_controller.dart';
import '../controllers/settings_controller.dart';

// Web-only: triggers browser download without dart:html import error on mobile
import 'report_controller_web.dart'
    if (dart.library.io) 'report_controller_stub.dart'
    as web_saver;

class ReportController extends GetxController {
  final isGenerating = false.obs;
  final lastSavedPath = ''.obs;

  Future<void> downloadPDFReport() async {
    isGenerating.value = true;
    try {
      final bytes = await _buildPdf();
      await _savePdf(bytes);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate report: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isGenerating.value = false;
    }
  }

  // ─── Build PDF bytes ───────────────────────────────────────────────────────
  Future<Uint8List> _buildPdf() async {
    final trading = Get.find<TradingController>();
    final settings = Get.find<SettingsController>();
    final stats = trading.sessionStats;
    final trades = trading.tradeHistory;
    final account = settings.accountInfo;
    final fmt = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('dd MMM yyyy HH:mm');
    // final fileDateFmt = DateFormat('yyyyMMdd_HHmm');

    final openingBal = trading.openingBalance.value;
    final closingBal = settings.currentBalance;
    final netChange = closingBal - openingBal;

    final pdf = pw.Document(
      title: 'Spemetra Master Trader- Session Report',
      author: 'Spemetra Tools v1.0.0',
    );

    // ── Color palette ────────────────────────────────────────────────────────
    const headerBg = PdfColor.fromInt(0xFF0D1F35);
    const accentBlue = PdfColor.fromInt(0xFF00E5FF);
    const green = PdfColor.fromInt(0xFF00E676);
    const red = PdfColor.fromInt(0xFFFF3B5C);
    const warning = PdfColor.fromInt(0xFFFFB800);
    const lightGrey = PdfColor.fromInt(0xFFF5F7FA);
    const midGrey = PdfColor.fromInt(0xFFE0E6ED);
    const darkText = PdfColor.fromInt(0xFF1A2B3C);
    const mutedText = PdfColor.fromInt(0xFF6B8499);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        header: (ctx) => _pageHeader(
          account?.loginId ?? 'N/A',
          dateFmt.format(DateTime.now()),
          headerBg,
          accentBlue,
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Spemetra Master Trader v1.0 — Confidential',
              style: pw.TextStyle(fontSize: 8, color: mutedText),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: mutedText),
            ),
          ],
        ),
        build: (ctx) => [
          pw.SizedBox(height: 8),

          // ── Summary title ────────────────────────────────────────────────
          _sectionTitle('SESSION SUMMARY', accentBlue),
          pw.SizedBox(height: 8),

          // ── Balance row ──────────────────────────────────────────────────
          pw.Row(
            children: [
              pw.Expanded(
                child: _balanceCard(
                  'Opening Balance',
                  '\$${fmt.format(openingBal)}',
                  accentBlue,
                  lightGrey,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _balanceCard(
                  'Closing Balance',
                  '\$${fmt.format(closingBal)}',
                  accentBlue,
                  lightGrey,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _balanceCard(
                  'Net Change',
                  '${netChange >= 0 ? '+' : ''}\$${fmt.format(netChange)}',
                  netChange >= 0 ? green : red,
                  netChange >= 0
                      ? const PdfColor.fromInt(0xFFE8FFF3)
                      : const PdfColor.fromInt(0xFFFFECEF),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Stats summary table ──────────────────────────────────────────
          pw.Table(
            border: pw.TableBorder.all(color: midGrey, width: 0.5),
            children: [
              _tableHeaderRow(['Field', 'Value'], headerBg, accentBlue),
              _tableRow(
                'Session Started',
                dateFmt.format(stats.sessionStart),
                lightGrey,
                darkText,
              ),
              _tableRow(
                'Total Trades',
                '${stats.totalTrades}',
                PdfColors.white,
                darkText,
              ),
              _tableRow('Wins', '${stats.wins}', lightGrey, green),
              _tableRow('Losses', '${stats.losses}', PdfColors.white, red),
              _tableRow(
                'Win Rate',
                '${stats.winRate.toStringAsFixed(1)}%',
                lightGrey,
                stats.winRate >= 55 ? green : warning,
              ),
              _tableRow(
                'Total P&L',
                '${stats.totalPnL >= 0 ? '+' : ''}\$${fmt.format(stats.totalPnL)}',
                PdfColors.white,
                stats.totalPnL >= 0 ? green : red,
              ),
              _tableRow(
                'Highest Win',
                '\$${fmt.format(stats.highestWin)}',
                lightGrey,
                green,
              ),
              _tableRow(
                'Biggest Loss',
                '\$${fmt.format(stats.biggestLoss)}',
                PdfColors.white,
                red,
              ),
              _tableRow(
                'Daily Target',
                '\$${fmt.format(settings.dailyTarget.value)}',
                lightGrey,
                darkText,
              ),
              _tableRow(
                'Stop Loss',
                '\$${fmt.format(settings.stopLoss.value)}',
                PdfColors.white,
                red,
              ),
              _tableRow(
                'Stake Per Trade',
                '\$${fmt.format(settings.stakeAmount.value)}',
                lightGrey,
                darkText,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Trade history ────────────────────────────────────────────────
          if (trades.isNotEmpty) ...[
            _sectionTitle(
              'TRADE HISTORY (Last ${trades.length} trades)',
              accentBlue,
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: midGrey, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.3),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.0),
                5: const pw.FlexColumnWidth(1.3),
              },
              children: [
                _tableHeaderRow(
                  ['Time', 'Contract', 'Stake', 'P&L', 'Result', 'AI Conf'],
                  headerBg,
                  accentBlue,
                ),
                ...trades.map((t) {
                  final rowBg = trades.indexOf(t) % 2 == 0
                      ? lightGrey
                      : PdfColors.white;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _cell(dateFmt.format(t.timestamp), darkText),
                      _cell(t.contractType, darkText),
                      _cell('\$${fmt.format(t.stake)}', darkText),
                      _cell(
                        '${t.profitLoss >= 0 ? '+' : ''}\$${fmt.format(t.profitLoss)}',
                        t.isWin ? green : red,
                        bold: true,
                      ),
                      _cell(
                        t.isWin ? 'WIN' : 'LOSS',
                        t.isWin ? green : red,
                        bold: true,
                      ),
                      _cell(
                        '${(t.aiConfidence * 100).toStringAsFixed(0)}%',
                        mutedText,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ] else ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Center(
                child: pw.Text(
                  'No trades recorded in this session.',
                  style: pw.TextStyle(color: mutedText, fontSize: 11),
                ),
              ),
            ),
          ],

          pw.SizedBox(height: 20),
          pw.Divider(color: midGrey),
          pw.SizedBox(height: 6),
          pw.Text(
            'Report generated: ${dateFmt.format(DateTime.now())}  |  '
            'Account: ${account?.loginId ?? 'N/A'}  |  '
            'Currency: ${account?.currency ?? 'USD'}',
            style: pw.TextStyle(fontSize: 8, color: mutedText),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Save PDF to device ────────────────────────────────────────────────────
  Future<void> _savePdf(Uint8List bytes) async {
    final dateFmt = DateFormat('yyyyMMdd_HHmm');
    final fileName =
        'Spemetra_Master_Trader_Report_${dateFmt.format(DateTime.now())}.pdf';

    if (kIsWeb) {
      // Web: trigger browser download
      web_saver.saveFileWeb(bytes, fileName);
      Get.snackbar(
        'Downloaded',
        '$fileName saved to Downloads.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Mobile & Desktop: save to documents/downloads directory
    Directory? dir;
    try {
      if (Platform.isAndroid) {
        // Prefer Downloads folder on Android
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        // Windows / macOS / Linux — use Downloads
        final home =
            Platform.environment['USERPROFILE'] ??
            Platform.environment['HOME'] ??
            '';
        dir = Directory('$home/Downloads');
        if (!await dir.exists()) {
          dir = await getApplicationDocumentsDirectory();
        }
      }
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }

    final path = '${dir!.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes);
    lastSavedPath.value = path;

    Get.snackbar(
      '✅ PDF Saved',
      path,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  // ─── PDF Widget Helpers ────────────────────────────────────────────────────
  pw.Widget _pageHeader(
    String accountId,
    String generated,
    PdfColor bg,
    PdfColor accent,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Spemetra MasterTrader Bot',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
              pw.Text(
                'Session Trading Report',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Account: $accountId',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
              ),
              pw.Text(
                'Generated: $generated',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title, PdfColor accent) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 16,
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF1A2B3C),
          ),
        ),
      ],
    );
  }

  pw.Widget _balanceCard(
    String label,
    String value,
    PdfColor valueColor,
    PdfColor bg,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border(
          bottom: pw.BorderSide(),
          right: pw.BorderSide(),
          left: pw.BorderSide(),
          top: pw.BorderSide(),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: const PdfColor.fromInt(0xFF6B8499),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _tableHeaderRow(
    List<String> headers,
    PdfColor bg,
    PdfColor textColor,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: headers
          .map(
            (h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.TableRow _tableRow(
    String label,
    String value,
    PdfColor bg,
    PdfColor valueColor,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: const PdfColor.fromInt(0xFF1A2B3C),
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _cell(String text, PdfColor color, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

// Helper extension for pw.Expanded equivalent
extension ExpandedHelper on pw.Widget {
  pw.Expanded get expanded => pw.Expanded(child: this);
}
