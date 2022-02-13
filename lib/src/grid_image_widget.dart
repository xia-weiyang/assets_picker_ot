import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageItemWidget extends StatefulWidget {
  const ImageItemWidget(
    this.asset, {
    this.showNum = 0,
    Key? key,
  }) : super(key: key);

  final AssetEntity asset;

  /// 序号显示
  final int showNum;

  @override
  ImageItemState createState() => ImageItemState();
}

class ImageItemState extends State<ImageItemWidget> {

  /// 获取缩略图
  Future<Uint8List?> _getThumbFromAssetEntity(
    AssetEntity asset,
    int size,
  ) async {
    return await asset.thumbDataWithSize(size, size);
  }

  @override
  Widget build(BuildContext context) {
    int size = MediaQuery.of(context).size.width ~/ 4;
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: FutureBuilder(
        future: _getThumbFromAssetEntity(widget.asset, size),
        builder: (BuildContext context,
        AsyncSnapshot<Uint8List?> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            }
          }
          return const SizedBox(
          );
        },
      ),
    );
  }
}
