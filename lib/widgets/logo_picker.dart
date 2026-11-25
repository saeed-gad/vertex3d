import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import 'common.dart';

/// يختار صورة من المعرض ويصغّرها ويرجّعها base64 (تتخزن مع بيانات الشركة).
Future<String?> pickLogoBase64() async {
  final x = await ImagePicker().pickImage(
      source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 85);
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  return base64Encode(bytes);
}

class LogoPickerTile extends StatelessWidget {
  final String logoBase64;
  final ValueChanged<String> onChanged;
  final double size;
  const LogoPickerTile(
      {super.key,
      required this.logoBase64,
      required this.onChanged,
      this.size = 96});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(size / 4),
      onTap: () async {
        final b = await pickLogoBase64();
        if (b != null) onChanged(b);
      },
      child: Stack(alignment: Alignment.bottomRight, children: [
        CompanyLogo(Company(logoBase64: logoBase64), size: size),
        CircleAvatar(
          radius: 15,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.camera_alt,
              size: 16, color: Theme.of(context).colorScheme.onPrimary),
        ),
      ]),
    );
  }
}
