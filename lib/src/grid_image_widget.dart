import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageItemWidget extends StatefulWidget {
  const ImageItemWidget(
    this.asset, {
    super.key,
    this.showNum = 0,
  });

  final AssetEntity asset;
  final int showNum;

  @override
  ImageItemState createState() => ImageItemState();
}

class ImageItemState extends State<ImageItemWidget> {
  Uint8List? _data;

  /// 获取缩略图
  Future<Uint8List?> _getThumbFromAssetEntity(
    AssetEntity asset,
    int size,
  ) async {
    return await asset.thumbnailDataWithSize(ThumbnailSize(size, size));
  }

  @override
  Widget build(BuildContext context) {
    int size = MediaQuery.of(context).size.width ~/ 4;
    return Stack(children: [
      SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: _data != null
            ? Image.memory(
                _data!,
                fit: BoxFit.cover,
              )
            : FutureBuilder(
                future: _getThumbFromAssetEntity(
                    widget.asset, (size * 1.5).toInt()),
                builder:
                    (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      _data = snapshot.data;
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                  }
                  return const SizedBox();
                },
              ),
      ),
      if (widget.asset.type == AssetType.video)
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              size: 26,
              Icons.videocam,
              color: Color(0x99666666),
            ),
          ),
        ),
      widget.showNum <= 0
          ? Container()
          : Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).colorScheme.primary.withAlpha(180),
                  ),
                  child: Center(
                    child: Text(
                      widget.showNum.toString(),
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    ]);
  }
}
