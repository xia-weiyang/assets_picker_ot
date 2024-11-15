import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_preview/preview.dart';
import 'package:image_preview/preview_data.dart';
import 'package:photo_manager/photo_manager.dart';

class ImageItemWidget extends StatefulWidget {
  const ImageItemWidget(
    this.asset, {
    super.key,
    this.showNum = 0,
    this.onTap,
  });

  final AssetEntity asset;
  final int showNum;
  final VoidCallback? onTap;

  @override
  ImageItemState createState() => ImageItemState();
}

class ImageItemState extends State<ImageItemWidget> {
  @override
  Widget build(BuildContext context) {
    int size = MediaQuery.of(context).size.width ~/ 4;
    return Stack(children: [
      SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ImageItemDataWidget(
          asset: widget.asset,
          size: size,
          onTap: widget.onTap,
        ),
      ),
      if (widget.asset.type == AssetType.video)
        const IgnorePointer(
          ignoring: true,
          child: Align(
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
        ),
      if (widget.showNum > 0)
        IgnorePointer(
          ignoring: true,
          child: Align(
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
        ),
    ]);
  }
}

class ImageItemDataWidget extends StatefulWidget {
  final AssetEntity asset;
  final VoidCallback? onTap;
  final int size;

  const ImageItemDataWidget({
    super.key,
    required this.asset,
    this.onTap,
    this.size = 100,
  });

  @override
  State<StatefulWidget> createState() => _ImageItemDataState();
}

class _ImageItemDataState extends State<ImageItemDataWidget> {
  String? _path;
  late Future<Uint8List?> _futureData;

  /// 获取缩略图
  Future<Uint8List?> _getThumbFromAssetEntity(
    AssetEntity asset,
    int size,
  ) async {
    _path = await _getPath(asset);
    return await asset.thumbnailDataWithSize(ThumbnailSize(size, size));
  }

  Future<String?> _getPath(AssetEntity asset) async {
    return (await asset.loadFile())?.path;
  }

  @override
  void initState() {
    super.initState();
    _futureData = _getThumbFromAssetEntity(widget.asset, widget.size);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _futureData,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            final tag = Random().nextInt(1 << 30).toString();
            PreviewData preview;
            if (widget.asset.type == AssetType.video) {
              preview = PreviewData(
                heroTag: tag,
                type: Type.video,
                video: VideoData(
                  coverData: snapshot.data!,
                  url: _path,
                ),
              );
            } else {
              preview = PreviewData(
                heroTag: tag,
                type: Type.image,
                image: ImageData(
                  thumbnailData: snapshot.data!,
                  path: _path,
                ),
              );
            }
            return PreviewThumbnail(
              videoShowPlayIcon: false,
              data: preview,
              onTap: () {
                if (widget.onTap != null) {
                  widget.onTap!();
                }
              },
              onLongTap: () {
                openPreviewPage(Navigator.of(context), data: preview);
              },
            );
          }
        }
        return const SizedBox();
      },
    );
  }
}
