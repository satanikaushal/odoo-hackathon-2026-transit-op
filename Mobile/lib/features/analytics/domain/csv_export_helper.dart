import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models/report_type.dart';

enum CsvExportOutcome {
  saved,
  cancelled,
  failed,
}

abstract final class CsvExportHelper {
  static Future<CsvExportOutcome> exportReportCsv({
    required ReportType report,
    required String csv,
    Rect? sharePositionOrigin,
  }) async {
    final fileName = '${report.exportSlug}.csv';
    final bytes = utf8.encode(csv);

    if (_isMobile) {
      return _shareCsv(
        fileName: fileName,
        csv: csv,
        subject: '${report.label} report',
        sharePositionOrigin: sharePositionOrigin,
      );
    }

    return _saveCsv(
      report: report,
      fileName: fileName,
      bytes: bytes,
      csv: csv,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static bool get _isMobile {
    if (kIsWeb) {
      return false;
    }

    return Platform.isIOS || Platform.isAndroid;
  }

  static Future<CsvExportOutcome> _saveCsv({
    required ReportType report,
    required String fileName,
    required List<int> bytes,
    required String csv,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save ${report.label}',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(bytes),
      );

      if (savedPath != null && savedPath.isNotEmpty) {
        return CsvExportOutcome.saved;
      }
    } catch (error, stackTrace) {
      debugPrint('CSV saveFile failed: $error\n$stackTrace');
    }

    return _shareCsv(
      fileName: fileName,
      csv: csv,
      subject: '${report.label} report',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static Future<CsvExportOutcome> _shareCsv({
    required String fileName,
    required String csv,
    required String subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv, flush: true);

      final origin = sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 1, 1);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'text/csv',
              name: fileName,
            ),
          ],
          subject: subject,
          sharePositionOrigin: origin,
        ),
      );

      return switch (result.status) {
        ShareResultStatus.success => CsvExportOutcome.saved,
        ShareResultStatus.dismissed => CsvExportOutcome.cancelled,
        ShareResultStatus.unavailable => CsvExportOutcome.failed,
      };
    } catch (error, stackTrace) {
      debugPrint('CSV share failed: $error\n$stackTrace');
      return CsvExportOutcome.failed;
    }
  }
}
