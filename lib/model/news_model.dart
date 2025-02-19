class NewsModel {
  final String title;
  final String desc;
  final String image;
  final String content;
  final String source;
  final DateTime publishedAt;
  NewsModel(
      {this.title = '',
      this.content = '',
      this.desc = '',
      this.image = '',
      this.source = '',
      DateTime? publishedAt})
      : this.publishedAt = publishedAt ?? DateTime.now();

  factory NewsModel.fromJson(json) {
    return NewsModel(
      title: json['title'],
      desc: json['description'],
      image: json['image'],
      content: json['content'],
      source: json['source']['name'],
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }
}
