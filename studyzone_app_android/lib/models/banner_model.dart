/// Home promotional / announcement banner.
class BannerModel {
  final int id;
  final String? title;
  final String? subtitle;
  final String imageUrl;
  final String? linkUrl;

  const BannerModel({
    required this.id,
    this.title,
    this.subtitle,
    required this.imageUrl,
    this.linkUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString(),
      subtitle: json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      linkUrl: (json['link_url']?.toString().isNotEmpty ?? false)
          ? json['link_url'].toString()
          : null,
    );
  }
}
