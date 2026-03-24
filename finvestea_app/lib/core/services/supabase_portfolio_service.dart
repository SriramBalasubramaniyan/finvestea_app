// supabase_portfolio_service.dart
//
// Upload pipeline:
//   uploadFile()       — Supabase Storage bucket "portfolios"
//   insertToDatabase() — Supabase table "portfolios"
//   uploadPortfolio()  — convenience wrapper that calls both in order
//   triggerAiAnalysis()— stub for AI backend
//
// Every error is logged with its FULL detail (message, code, status, stack)
// and re-thrown as a PortfolioUploadException whose .message is the REAL
// error text — no generic replacements.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePortfolioService {
  SupabasePortfolioService._();
  static final SupabasePortfolioService instance =
      SupabasePortfolioService._();

  final SupabaseClient _client = Supabase.instance.client;

  static const _bucket = 'portfolios';
  static const _table  = 'portfolios';

  // ─────────────────────────────────────────────────────────────────────────
  // 1. uploadFile
  // ─────────────────────────────────────────────────────────────────────────

  /// Uploads [bytes] to Supabase Storage using uploadBinary().
  ///
  /// Returns the public URL on success.
  /// Throws [PortfolioUploadException] with the REAL error message on failure.
  Future<String> uploadFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uid  = _currentUid();
    final path = _buildStoragePath(fileName);

    debugPrint('════ [uploadFile] ════════════════════════');
    debugPrint('[uploadFile] bucket   : $_bucket');
    debugPrint('[uploadFile] path     : $path');
    debugPrint('[uploadFile] bytes    : ${bytes.length}');
    debugPrint('[uploadFile] mimeType : $mimeType');
    debugPrint('[uploadFile] uid      : $uid');

    try {
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );
      debugPrint('[uploadFile] ✅ uploadBinary() succeeded');
    } on StorageException catch (e, stack) {
      debugPrint('[uploadFile] ❌ StorageException');
      debugPrint('[uploadFile]   message    : ${e.message}');
      debugPrint('[uploadFile]   statusCode : ${e.statusCode}');
      debugPrint('[uploadFile]   stack      :\n$stack');
      // Preserve the real message — never replace with a generic string
      throw PortfolioUploadException(
        '[Upload error] ${e.message} (HTTP ${e.statusCode})',
      );
    } catch (e, stack) {
      debugPrint('[uploadFile] ❌ Unexpected error');
      debugPrint('[uploadFile]   error : $e');
      debugPrint('[uploadFile]   stack :\n$stack');
      throw PortfolioUploadException('[Upload error] $e');
    }

    final url = _client.storage.from(_bucket).getPublicUrl(path);
    debugPrint('[uploadFile] 🔗 public URL: $url');
    return url;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. insertToDatabase
  // ─────────────────────────────────────────────────────────────────────────

  /// Inserts a row into the `portfolios` table.
  ///
  /// Returns the inserted record map on success.
  /// Throws [PortfolioUploadException] with the REAL error message on failure.
  Future<Map<String, dynamic>> insertToDatabase({
    required String fileName,
    required String fileUrl,
  }) async {
    final uid = _currentUid();

    debugPrint('════ [insertToDatabase] ══════════════════');
    debugPrint('[insertToDatabase] table     : $_table');
    debugPrint('[insertToDatabase] user_id   : $uid');
    debugPrint('[insertToDatabase] file_name : $fileName');
    debugPrint('[insertToDatabase] file_url  : $fileUrl');

    try {
      final response = await _client.from(_table).insert({
        'user_id'  : uid,
        'file_name': fileName,
        'file_url' : fileUrl,
        // created_at is handled by Supabase default (now())
      }).select().single();

      debugPrint('[insertToDatabase] ✅ insert succeeded');
      debugPrint('[insertToDatabase] response : $response');
      return response;
    } on PostgrestException catch (e, stack) {
      // Log ALL fields — RLS violations show in `code`, not always `message`
      debugPrint('[insertToDatabase] ❌ PostgrestException');
      debugPrint('[insertToDatabase]   message : ${e.message}');
      debugPrint('[insertToDatabase]   code    : ${e.code}');
      debugPrint('[insertToDatabase]   details : ${e.details}');
      debugPrint('[insertToDatabase]   hint    : ${e.hint}');
      debugPrint('[insertToDatabase]   stack   :\n$stack');

      final detail = [
        if (e.message.isNotEmpty) e.message,
        if (e.code != null && e.code!.isNotEmpty) 'code: ${e.code}',
        if (e.hint  != null && e.hint!.isNotEmpty) 'hint: ${e.hint}',
      ].join(' · ');

      throw PortfolioUploadException('[DB error] $detail');
    } catch (e, stack) {
      debugPrint('[insertToDatabase] ❌ Unexpected error');
      debugPrint('[insertToDatabase]   error : $e');
      debugPrint('[insertToDatabase]   stack :\n$stack');
      throw PortfolioUploadException('[DB error] $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. uploadPortfolio  — full pipeline
  // ─────────────────────────────────────────────────────────────────────────

  /// Runs uploadFile → insertToDatabase in sequence.
  /// Each step is awaited before the next begins.
  /// Throws [PortfolioUploadException] if either step fails.
  Future<UploadResult> uploadPortfolio({
    required String fileName,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final mimeType = _mimeType(fileExtension);

    debugPrint('════ [uploadPortfolio] ═══════════════════');
    debugPrint('[uploadPortfolio] fileName      : $fileName');
    debugPrint('[uploadPortfolio] fileExtension : $fileExtension');
    debugPrint('[uploadPortfolio] mimeType      : $mimeType');

    // ── Step 1: upload bytes to storage ──────────────────────────────────
    debugPrint('[uploadPortfolio] Step 1 → uploadFile()');
    final fileUrl = await uploadFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
    // uploadFile() either returns a URL or throws — never continues silently

    // ── Step 2: insert DB record ─────────────────────────────────────────
    debugPrint('[uploadPortfolio] Step 2 → insertToDatabase()');
    final record = await insertToDatabase(
      fileName: fileName,
      fileUrl: fileUrl,
    );
    // insertToDatabase() either returns a row or throws

    final id = record['id'] as String? ?? '';
    debugPrint('[uploadPortfolio] ✅ pipeline complete — id: $id');

    return UploadResult(id: id, fileUrl: fileUrl, fileName: fileName);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. triggerAiAnalysis  — stub
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> triggerAiAnalysis(String fileUrl) async {
    debugPrint('[triggerAiAnalysis] stub called — fileUrl: $fileUrl');
    await Future.delayed(const Duration(seconds: 2));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _currentUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw PortfolioUploadException(
        '[Auth error] No authenticated user. Please log in and try again.',
      );
    }
    return uid;
  }

  /// Replaces spaces → underscores, strips chars outside [a-zA-Z0-9_.-].
  static String _sanitizeFileName(String name) =>
      name.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w.\-]'), '');

  /// user_uploads/{timestamp}_{sanitizedName}
  /// Example: user_uploads/1712345678901_portfolio.csv
  static String _buildStoragePath(String originalName) {
    final ts        = DateTime.now().millisecondsSinceEpoch;
    final sanitized = _sanitizeFileName(originalName);
    return 'user_uploads/${ts}_$sanitized';
  }

  static String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'csv'  : return 'text/csv';
      case 'xlsx' : return 'application/vnd.openxmlformats-officedocument'
                            '.spreadsheetml.sheet';
      case 'xls'  : return 'application/vnd.ms-excel';
      default     : return 'application/octet-stream';
    }
  }
}

// ── Result model ──────────────────────────────────────────────────────────────

class UploadResult {
  final String id;
  final String fileUrl;
  final String fileName;
  const UploadResult({
    required this.id,
    required this.fileUrl,
    required this.fileName,
  });
}

// ── Exception ─────────────────────────────────────────────────────────────────

/// Thrown by SupabasePortfolioService when any step fails.
/// [message] always contains the REAL error — never a generic replacement.
class PortfolioUploadException implements Exception {
  final String message;
  const PortfolioUploadException(this.message);

  @override
  String toString() => message;
}
