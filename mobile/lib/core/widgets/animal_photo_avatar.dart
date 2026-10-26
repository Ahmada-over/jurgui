import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/colors.dart';

class AnimalPhotoResult {
  final String? dataUrl;
  final bool removed;

  const AnimalPhotoResult({this.dataUrl, this.removed = false});
}

Future<AnimalPhotoResult?> showAnimalPhotoPickerSheet(
  BuildContext context, {
  bool hasCurrentPhoto = false,
}) async {
  final picker = ImagePicker();

  return showModalBottomSheet<AnimalPhotoResult>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Photo de l\'ovin',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'Prendre une photo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Utiliser l\'appareil photo du téléphone'),
              onTap: () async {
                final xfile = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 600,
                  maxHeight: 600,
                  imageQuality: 75,
                );
                if (xfile == null) return;
                final bytes = await xfile.readAsBytes();
                final b64 = base64Encode(bytes);
                if (ctx.mounted) {
                  Navigator.pop(
                    ctx,
                    AnimalPhotoResult(dataUrl: 'data:image/jpeg;base64,$b64'),
                  );
                }
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.image,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'Choisir depuis la galerie',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Sélectionner une photo existante'),
              onTap: () async {
                final xfile = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 600,
                  maxHeight: 600,
                  imageQuality: 75,
                );
                if (xfile == null) return;
                final bytes = await xfile.readAsBytes();
                final b64 = base64Encode(bytes);
                if (ctx.mounted) {
                  Navigator.pop(
                    ctx,
                    AnimalPhotoResult(dataUrl: 'data:image/jpeg;base64,$b64'),
                  );
                }
              },
            ),
            if (hasCurrentPhoto) ...[
              const SizedBox(height: 4),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Supprimer la photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
                onTap: () => Navigator.pop(
                  ctx,
                  const AnimalPhotoResult(removed: true),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class AnimalPhotoImage extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final Widget fallback;

  const AnimalPhotoImage({
    super.key,
    required this.photoUrl,
    required this.size,
    required this.fallback,
  });

  Uint8List? _tryDecodeDataUrl(String url) {
    try {
      final commaIdx = url.indexOf(',');
      if (commaIdx != -1) {
        return base64Decode(url.substring(commaIdx + 1));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return fallback;
    }

    if (url.startsWith('data:image')) {
      final bytes = _tryDecodeDataUrl(url);
      if (bytes != null) {
        return ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      }
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
