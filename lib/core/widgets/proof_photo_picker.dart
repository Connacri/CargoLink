import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../screens/shipper/live_selfie_screen.dart';
import '../theme/app_theme.dart';

enum _ProofSource { gallery, camera }

/// Opens a bottom sheet to choose between the selfie camera or the gallery,
/// then lets the user frame/crop the photo before returning the final file.
///
/// Returns null if the user cancels.
Future<File?> pickProofPhoto(BuildContext context, {String title = 'Photo de preuve'}) async {
  final source = await showModalBottomSheet<_ProofSource>(
    context: context,
    backgroundColor: AppTheme.backgroundColor,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTheme.spaceMd),
          Text(title, style: AppTheme.h2),
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Vous pourrez cadrer la photo avant l\'envoi.',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          ListTile(
            leading:
                const Icon(Icons.photo_camera_rounded, color: AppTheme.accentColor),
            title: const Text('Appareil photo'),
            subtitle:
                const Text('Prendre une photo maintenant', style: AppTheme.caption),
            onTap: () => Navigator.of(sheetContext).pop(_ProofSource.camera),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            child: Divider(color: AppTheme.dividerColor),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppTheme.accentColor),
            title: const Text('Galerie'),
            subtitle: const Text('Choisir une image existante', style: AppTheme.caption),
            onTap: () => Navigator.of(sheetContext).pop(_ProofSource.gallery),
          ),
          const SizedBox(height: AppTheme.spaceSm),
        ],
      ),
    ),
  );

  if (source == null) return null;
  if (!context.mounted) return null;

  File? picked;
  switch (source) {
    case _ProofSource.gallery:
      final xfile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (xfile == null) return null;
      picked = File(xfile.path);
    case _ProofSource.camera:
      final path = await LiveSelfieScreen.capture(context);
      if (path == null) return null;
      picked = File(path);
  }

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 92,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Cadrer la photo',
        toolbarColor: AppTheme.primaryColor,
        toolbarWidgetColor: Colors.white,
        lockAspectRatio: false,
        showCropGrid: true,
      ),
      IOSUiSettings(
        title: 'Cadrer la photo',
        aspectRatioLockEnabled: false,
      ),
    ],
  );
  if (cropped == null) return null;
  return File(cropped.path);
}
