import 'package:gallery/api/user.dart';
import 'package:intl/intl.dart';

class Photo {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int width;
  final int height;
  final String color;
  final String description;
  final String altDescription;
  final Urls urls;
  final User user;

  const Photo(this.id, this.createdAt, this.updatedAt, this.width, this.height,
      this.color, this.description, this.altDescription, this.urls, this.user);

  static fromJson(json) => Photo(
        json['id'],
        DateTime.parse(json['created_at']),
        DateTime.parse(json['updated_at']),
        json['width'],
        json['height'],
        json['color'],
        json['description'],
        json['alt_description'],
        Urls.fromJson(json['urls']),
        User.fromJson(json['user']),
      );
}

class Urls {
  final String raw;
  final String full;
  final String regular;
  final String small;
  final String thumb;

  const Urls(this.raw, this.full, this.regular, this.small, this.thumb);

  static fromJson(json) => Urls(
        json['raw'],
        json['full'],
        json['regular'],
        json['small'],
        json['thumb'],
      );
}
