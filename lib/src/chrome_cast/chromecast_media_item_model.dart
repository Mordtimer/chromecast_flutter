class ChromecastMediaItemModel {
  final String url;
  final String title;
  final String subtitle;
  final String image;

  ChromecastMediaItemModel({
    required this.url,
    required this.title,
    required this.subtitle,
    required this.image,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'title': title,
        'subtitle': subtitle,
        'image': image,
      };
}
