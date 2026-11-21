import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef PillImageKey = ({String patientId, String medicationId});

abstract class ImageStorageGateway {
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = false,
  });

  Future<bool> objectExists({required String bucket, required String path});

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  });
}

abstract class DeletableImageStorageGateway implements ImageStorageGateway {
  Future<void> deleteObject({required String bucket, required String path});
}

class SupabaseImageStorageGateway implements DeletableImageStorageGateway {
  SupabaseImageStorageGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> uploadBinary({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
    bool upsert = false,
  }) async {
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: upsert),
        );
  }

  @override
  Future<bool> objectExists({
    required String bucket,
    required String path,
  }) async {
    final lastSlash = path.lastIndexOf('/');
    final folder = lastSlash < 0 ? '' : path.substring(0, lastSlash);
    final fileName = lastSlash < 0 ? path : path.substring(lastSlash + 1);
    final files = await _client.storage
        .from(bucket)
        .list(
          path: folder,
          searchOptions: SearchOptions(limit: 1, search: fileName),
        );
    return files.any((file) => file.name == fileName);
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresInSeconds,
  }) {
    return _client.storage.from(bucket).createSignedUrl(path, expiresInSeconds);
  }

  @override
  Future<void> deleteObject({
    required String bucket,
    required String path,
  }) async {
    await _client.storage.from(bucket).remove([path]);
  }
}

class SupabaseImageRepository {
  SupabaseImageRepository({
    required ImageStorageGateway gateway,
    String Function()? idGenerator,
  }) : _gateway = gateway,
       _idGenerator = idGenerator ?? _randomId;

  static const prescriptionsBucket = 'prescriptions';
  static const pillImagesBucket = 'pill-images';
  static const int signedUrlLifetimeSeconds = 60 * 60;
  static const int maxImageBytes = 10 * 1024 * 1024;

  final ImageStorageGateway _gateway;
  final String Function() _idGenerator;

  Future<String> uploadPrescriptionImage({
    required String patientId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final patientFolder = _validatePathSegment(patientId, 'patientId');
    _validateImageBytes(bytes);
    final path = '$patientFolder/${_idGenerator()}';
    await _gateway.uploadBinary(
      bucket: prescriptionsBucket,
      path: path,
      bytes: bytes,
      contentType: _contentType(fileName, mimeType),
    );
    return path;
  }

  Future<String> uploadPillImage({
    required String patientId,
    required String medicationId,
    required XFile file,
  }) async {
    final patientFolder = _validatePathSegment(patientId, 'patientId');
    final medicationFolder = _validatePathSegment(medicationId, 'medicationId');
    final bytes = await file.readAsBytes();
    _validateImageBytes(bytes);
    final path = '$patientFolder/$medicationFolder/image';
    await _gateway.uploadBinary(
      bucket: pillImagesBucket,
      path: path,
      bytes: bytes,
      contentType: _contentType(file.name, file.mimeType),
      upsert: true,
    );
    return path;
  }

  Future<String?> getPillImageSignedUrl({
    required String patientId,
    required String medicationId,
  }) async {
    final patientFolder = _validatePathSegment(patientId, 'patientId');
    final medicationFolder = _validatePathSegment(medicationId, 'medicationId');
    final path = '$patientFolder/$medicationFolder/image';
    if (!await _gateway.objectExists(bucket: pillImagesBucket, path: path)) {
      return null;
    }
    return await _gateway.createSignedUrl(
      bucket: pillImagesBucket,
      path: path,
      expiresInSeconds: signedUrlLifetimeSeconds,
    );
  }

  Future<void> deletePillImage({
    required String patientId,
    required String medicationId,
  }) async {
    final patientFolder = _validatePathSegment(patientId, 'patientId');
    final medicationFolder = _validatePathSegment(medicationId, 'medicationId');
    final path = '$patientFolder/$medicationFolder/image';
    final gateway = _gateway;
    if (gateway is DeletableImageStorageGateway) {
      await gateway.deleteObject(bucket: pillImagesBucket, path: path);
    } else {
      throw UnsupportedError('Image gateway does not support object deletion.');
    }
  }

  static void _validateImageBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes.length, 'bytes', 'Image cannot be empty.');
    }
    if (bytes.length > maxImageBytes) {
      throw ArgumentError.value(
        bytes.length,
        'bytes',
        'Image exceeds maximum allowed size of $maxImageBytes bytes.',
      );
    }
  }

  static String _validatePathSegment(String value, String field) {
    if (value.isEmpty ||
        value.trim() != value ||
        value.contains('/') ||
        value.contains(r'\') ||
        value == '.' ||
        value == '..') {
      throw ArgumentError.value(value, field, 'Must be one path segment.');
    }
    return value;
  }

  static String _contentType(String fileName, String? mimeType) {
    final mime = mimeType?.split(';').first.trim().toLowerCase();
    if (mime != null && mime.startsWith('image/')) return mime;

    final name = fileName.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.bmp')) return 'image/bmp';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  static String _randomId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

abstract class MediaImagePicker {
  Future<XFile?> pickImage(ImageSource source);
}

class DeviceMediaImagePicker implements MediaImagePicker {
  DeviceMediaImagePicker({
    ImagePicker? picker,
    this.maxWidth = 1600,
    this.maxHeight = 1600,
    this.imageQuality = 85,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final double maxWidth;
  final double maxHeight;
  final int imageQuality;

  @override
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
}

final mediaImagePickerProvider = Provider<MediaImagePicker>(
  (ref) => DeviceMediaImagePicker(),
);

final supabaseImageRepositoryProvider = Provider<SupabaseImageRepository>(
  (ref) => SupabaseImageRepository(
    gateway: SupabaseImageStorageGateway(ref.watch(supabaseClientProvider)),
  ),
);

// flutter_riverpod does not export the concrete future-family provider type.
// ignore: specify_nonobvious_property_types
final pillImageSignedUrlProvider = FutureProvider.autoDispose
    .family<String?, PillImageKey>((ref, key) {
      return ref
          .watch(supabaseImageRepositoryProvider)
          .getPillImageSignedUrl(
            patientId: key.patientId,
            medicationId: key.medicationId,
          );
    });
