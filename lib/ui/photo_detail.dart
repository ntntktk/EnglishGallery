import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:gallery/api/photo.dart';
import 'package:gallery/util/color_utils.dart';

class PhotoDetailPage extends StatelessWidget {
  final Photo photo;

  const PhotoDetailPage({Key key, this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: CustomScrollView(
          primary: true,
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.width / photo.width * photo.height,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: ColorUtils.colorFromHexString(photo.color),
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: photo.urls.regular,
                    fadeInDuration: Duration(milliseconds: 225),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SliverSafeArea(
              top: false,
              sliver: SliverList(
                delegate: SliverChildListDelegate(_createListContent(context)),
              ),
            ),
          ],
        ),
      );

  List<Widget> _createListContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profileImage = photo.user.profileImage;
    final description = photo.description ?? "Photo by ${photo.user.name}";

    final List<Widget> contents = [];
    contents.add(Container(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Text(
        description,
        style: textTheme.title.copyWith(letterSpacing: 1.2, height: 1.2),
      ),
    ));
    contents.add(Container(height: 8.0));
    if (photo.user.profileImage != null) {
      contents.add(ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(profileImage.medium),
          radius: 20.0,
        ),
        title: Text(photo.user.name),
      ));
    } else {
      contents.add(ListTile(
        leading: Icon(Icons.person, color: Colors.black54),
        title: Text(photo.user.name),
      ));
    }
    if (photo.user.bio != null) {
      contents.add(Padding(
        padding: EdgeInsets.only(left: 72.0, right: 16.0),
        child: Text(photo.user.bio, style: textTheme.body1.copyWith(color: Colors.black54)),
      ));
    }
    contents.add(Container(height: 16.0));
    contents.add(Divider(height: 0.0, indent: 72.0));
    contents.add(Container(height: 8.0));
    contents.add(ListTile(
      leading: Icon(Icons.photo_size_select_large, color: Colors.black54),
      title: Text("${photo.width}px x ${photo.height}px"),
    ));
    contents.add(ListTile(
      leading: Icon(Icons.access_time, color: Colors.black54),
      title: Text(DateFormat('yyyy/MM/dd HH:mm').format(photo.createdAt.toLocal())),
    ));
    contents.add(Container(height: 8.0));
    return contents;
  }
}
