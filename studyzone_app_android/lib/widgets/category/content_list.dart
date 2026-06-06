import 'package:flutter/material.dart';
import '../../models/content_model.dart';
import '../home/material_card.dart';

/// Shows a category's materials as a flat list in the order the backend returns
/// them (oldest → newest). No automatic type grouping — content appears as-is,
/// each item a tappable card.
class ContentList extends StatelessWidget {
  final List<ContentModel> contents;
  final void Function(ContentModel) onOpen;

  const ContentList({
    super.key,
    required this.contents,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: contents
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MaterialCard(content: c, onTap: () => onOpen(c)),
            ),
          )
          .toList(),
    );
  }
}
