import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extracted candidate fields from OCR text to assist the user without guessing.
class OcrCandidateFields {
  final String? productName;
  final String? brand;
  final DateTime? purchaseDate;
  final int? warrantyDurationMonths;

  const OcrCandidateFields({
    this.productName,
    this.brand,
    this.purchaseDate,
    this.warrantyDurationMonths,
  });

  bool get hasAnyField =>
      (productName != null && productName!.isNotEmpty) ||
      (brand != null && brand!.isNotEmpty) ||
      purchaseDate != null ||
      warrantyDurationMonths != null;
}

/// Result returned from processing an image with OCR.
class OcrResult {
  final String rawText;
  final OcrCandidateFields candidateFields;

  const OcrResult({
    required this.rawText,
    this.candidateFields = const OcrCandidateFields(),
  });

  bool get isEmpty => rawText.trim().isEmpty;
}

/// Dedicated On-Device OCR Service using Google ML Kit Text Recognition.
class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer _getRecognizer() {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Closes the native text recognition resources.
  Future<void> dispose() async {
    if (_textRecognizer != null) {
      await _textRecognizer!.close();
      _textRecognizer = null;
    }
  }

  /// Processes a local image file path and returns extracted text and candidate fields.
  Future<OcrResult> processImageFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const OcrException('The selected image file does not exist.');
    }

    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizer = _getRecognizer();
      final RecognizedText recognizedText = await recognizer.processImage(inputImage);

      final rawText = recognizedText.text.trim();
      if (rawText.isEmpty) {
        return const OcrResult(
          rawText: '',
          candidateFields: OcrCandidateFields(),
        );
      }

      final fields = extractCandidateFields(rawText);
      return OcrResult(
        rawText: rawText,
        candidateFields: fields,
      );
    } on OcrException {
      rethrow;
    } catch (e) {
      throw OcrException('Failed to process image: ${e.toString()}');
    }
  }

  /// Pure helper to extract candidate product fields from OCR raw text.
  static OcrCandidateFields extractCandidateFields(String text) {
    if (text.trim().isEmpty) {
      return const OcrCandidateFields();
    }

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? productName;
    String? brand;
    DateTime? purchaseDate;
    int? warrantyDurationMonths;

    // 1. Check for labeled fields first (e.g. "Product: ...", "Brand: ...")
    for (final line in lines) {
      final lower = line.toLowerCase();

      // Labeled product name
      if (productName == null) {
        final productMatch = RegExp(r'^(?:product|item|model)(?:\s+name)?\s*[:=-]\s*(.+)$', caseSensitive: false).firstMatch(line);
        if (productMatch != null) {
          final val = productMatch.group(1)?.trim();
          if (val != null && val.isNotEmpty && val.length > 2) {
            productName = val;
          }
        }
      }

      // Labeled brand
      if (brand == null) {
        final brandMatch = RegExp(r'^(?:brand|make|manufacturer)\s*[:=-]\s*(.+)$', caseSensitive: false).firstMatch(line);
        if (brandMatch != null) {
          final val = brandMatch.group(1)?.trim();
          if (val != null && val.isNotEmpty) {
            brand = val;
          }
        }
      }

      // Labeled or pattern purchase date
      if (purchaseDate == null) {
        if (lower.contains('date') || lower.contains('purchas') || lower.contains('invoice') || lower.contains('bill')) {
          purchaseDate = _parseDateFromLine(line);
        }
      }

      // Labeled warranty duration
      if (warrantyDurationMonths == null) {
        if (lower.contains('warranty') || lower.contains('guarantee') || lower.contains('period')) {
          warrantyDurationMonths = _parseDurationFromLine(line);
        }
      }
    }

    // 2. Fallback regex search for purchase date if not found in labeled lines
    purchaseDate ??= _parseDateFromText(text);

    // 3. Fallback regex search for warranty duration if not found in labeled lines
    warrantyDurationMonths ??= _parseDurationFromText(text);

    return OcrCandidateFields(
      productName: productName,
      brand: brand,
      purchaseDate: purchaseDate,
      warrantyDurationMonths: warrantyDurationMonths,
    );
  }

  static DateTime? _parseDateFromLine(String line) {
    return _parseDateFromText(line);
  }

  static DateTime? _parseDateFromText(String text) {
    // Matches YYYY-MM-DD or YYYY/MM/DD
    final isoMatch = RegExp(r'\b(20[1-3][0-9])[-/.](0[1-9]|1[0-2])[-/.](0[1-9]|[12][0-9]|3[01])\b').firstMatch(text);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1)!);
      final m = int.tryParse(isoMatch.group(2)!);
      final d = int.tryParse(isoMatch.group(3)!);
      if (y != null && m != null && d != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }

    // Matches DD/MM/YYYY or DD-MM-YYYY
    final dmyMatch = RegExp(r'\b(0?[1-9]|[12][0-9]|3[01])[-/.](0?[1-9]|1[0-2])[-/.](20[1-3][0-9])\b').firstMatch(text);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!);
      final m = int.tryParse(dmyMatch.group(2)!);
      final y = int.tryParse(dmyMatch.group(3)!);
      if (y != null && m != null && d != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {}
      }
    }

    return null;
  }

  static int? _parseDurationFromLine(String line) {
    return _parseDurationFromText(line);
  }

  static int? _parseDurationFromText(String text) {
    // Look for e.g. "2 years", "1 year", "3 yr", "5 yrs"
    final yearMatch = RegExp(r'\b(\d+)\s*(?:year|yr)s?\b', caseSensitive: false).firstMatch(text);
    if (yearMatch != null) {
      final yrs = int.tryParse(yearMatch.group(1)!);
      if (yrs != null && yrs > 0 && yrs <= 10) {
        return yrs * 12;
      }
    }

    // Look for e.g. "24 months", "6 months", "12 mo", "36 mos"
    final monthMatch = RegExp(r'\b(\d+)\s*(?:month|mo)s?\b', caseSensitive: false).firstMatch(text);
    if (monthMatch != null) {
      final mos = int.tryParse(monthMatch.group(1)!);
      if (mos != null && mos > 0 && mos <= 120) {
        return mos;
      }
    }

    return null;
  }

  /// Converts exceptions to clear, user-friendly messages.
  static String getReadableErrorMessage(dynamic error) {
    if (error is OcrException) {
      return error.message;
    }
    final msg = error.toString();
    if (msg.contains('not exist')) {
      return 'Selected document image file could not be found.';
    }
    if (msg.contains('permission')) {
      return 'Permission denied to access the document image.';
    }
    return 'Unable to read this document. Please try a clearer image.';
  }
}

/// Custom exception for OCR operations.
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);

  @override
  String toString() => message;
}
