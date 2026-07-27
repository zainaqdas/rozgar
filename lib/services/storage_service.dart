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

  Future<String> uploadAvatar(String userId, Uint8List bytes, String ext) async {
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
    final path = '$conversationId/$senderId/$filename';
    await SupabaseConfig.client.storage
        .from(portfoliosBucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: false));
    return SupabaseConfig.client.storage.from(portfoliosBucket).getPublicUrl(path);
  }

  String getPublicUrl(String bucket, String path) {
    return SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
  }
}
