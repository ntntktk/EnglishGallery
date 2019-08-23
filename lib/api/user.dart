class User {
  final String id;
  final String username;
  final String name;
  final String bio;
  final Links links; 
  final ProfileImage profileImage;

  const User(this.id, this.username, this.name, this.bio, this.links, this.profileImage);

  static fromJson(json) => User(
        json['id'],
        json['username'],
        json['name'],
        json['bio'],
        Links.fromJson(json['links']),
        ProfileImage.fromJson(json['profile_image']),
      );
}

class ProfileImage {
  final String small;
  final String medium;
  final String large;

  const ProfileImage(this.small, this.medium, this.large);

  static fromJson(json) => ProfileImage(
        json['small'],
        json['medium'],
        json['large'],
      );
}

class Links {
  final String html;

  const Links(this.html);

  static fromJson(json) => Links(
        json['html'],
      );
}

