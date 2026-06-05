import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Reusable circular user avatar. Shows, in priority order:
///   1. [localFile] (a freshly picked image being previewed),
///   2. the network [imageUrl] (the saved avatar),
///   3. the first letter of [name] on a coloured circle.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? localFile;
  final String name;
  final double size;
  final double fontSize;
  final Color? background;
  final Color? foreground;
  final BoxBorder? border;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.localFile,
    this.size = 44,
    this.fontSize = 18,
    this.background,
    this.foreground,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bg = background ?? colors.primary;
    final fg = foreground ?? Colors.white;

    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';

    Widget child;
    if (localFile != null) {
      child = Image.file(localFile!, width: size, height: size, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _initialCircle(initial, bg, fg),
        errorWidget: (_, _, _) => _initialCircle(initial, bg, fg),
      );
    } else {
      child = _initialCircle(initial, bg, fg);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: border),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _initialCircle(String initial, Color bg, Color fg) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
