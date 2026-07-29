import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const String avatarsBucket = 'avatars';
  static const String portfoliosBucket = 'portfolios';
  static const String cnicBucket = 'cnic-docs';
  static const String chatMediaBucket = 'chat-media';

  // Size limits in bytes
  static const int maxAvatarBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxCnicBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxChatMediaBytes = 10 * 1024 * 1024; // 10 MB

  static const _avatarExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const _cnicExtensions = {'jpg', 'jpeg', 'png', 'pdf'};

  Future<String> uploadAvatar(String userId, Uint8List bytes, String ext) async {
    _validateUpload(bytes, ext, maxAvatarBytes, _avatarExtensions, 'Avatar');
    final path = '$userId/avatar.$ext';
    await SupabaseConfig.client.storage
        .from(avatarsBucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return SupabaseConfig.client.storage.from(avatarsBucket).getPublicUrl(path);
  }

  Future<String> uploadPortfolioItem(String userId, Uint8List bytes, String filename) async {
    final path = '$userId/$filename';
    await SupabaseConfig.client.storage
        .from(portfoliosBucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false));
    return SupabaseConfig.client.storage.from(portfoliosBucket).getPublicUrl(path);
  }

  Future<void> deletePortfolioItem(String userId, String filename) async {
    final path = '$userId/$filename';
    await SupabaseConfig.client.storage.from(portfoliosBucket).remove([path]);
  }

  Future<String> uploadCnic(String userId, Uint8List bytes, String ext) async {
    _validateUpload(bytes, ext, maxCnicBytes, _cnicExtensions, 'CNIC');
    final path = '$userId/cnic.$ext';
    await SupabaseConfig.client.storage
        .from(cnicBucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  Future<Uint8List> downloadCnic(String userId, String ext) async {
    final path = '$userId/cnic.$ext';
    return SupabaseConfig.client.storage.from(cnicBucket).download(path);
  }

  Future<String> uploadChatMedia(String conversationId, String senderId, Uint8List bytes, String filename) async {
    if (bytes.length > maxChatMediaBytes) {
      throw ArgumentError('Chat media exceeds ${maxChatMediaBytes ~/ (1024 * 1024)}MB limit.');
    }
    final path = '$conversationId/$senderId/$filename';
    await SupabaseConfig.client.storage
        .from(chatMediaBucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false));
    return SupabaseConfig.client.storage.from(chatMediaBucket).getPublicUrl(path);
  }

  String getPublicUrl(String bucket, String path) {
    return SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
  }

  void _validateUpload(
    Uint8List bytes,
    String ext,
    int maxBytes,
    Set<String> allowedExtensions,
    String label,
  ) {
    if (bytes.isEmpty) {
      throw ArgumentError('$label file is empty.');
    }
    if (bytes.length > maxBytes) {
      throw ArgumentError('$label exceeds ${maxBytes ~/ (1024 * 1024)}MB limit.');
    }
    final normalizedExt = ext.toLowerCase().replaceFirst('.', '');
    if (!allowedExtensions.contains(normalizedExt)) {
      throw ArgumentError(
        '$label format .$normalizedExt not allowed. Accepted: ${allowedExtensions.map((e) => '.$e').join(', ')}',
      );
    }
  }
}
