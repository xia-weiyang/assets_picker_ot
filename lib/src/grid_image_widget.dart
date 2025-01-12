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
                size: 30,
                Icons.videocam,
                color: Color(0xDD444444),
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
                  color: Theme.of(context).colorScheme.primary.withAlpha(220),
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

final _cacheMap = <String, Uint8List>{};

void addCacheMap(String key, Uint8List data) {
  if (_cacheMap.length > 2000) {
    _cacheMap.remove(_cacheMap.keys.first);
  }
  _cacheMap[key] = data;
}

class _ImageItemDataState extends State<ImageItemDataWidget> {
  String? _path;
  Uint8List? thumbData;

  /// 获取缩略图
  _getThumbFromAssetEntity(
    AssetEntity asset,
    int size,
  ) async {
    _path = await _getPath(asset);
    if (_path == null) {
      debugPrint("error: path is null");
      return;
    }
    var uint8list = _cacheMap[_path];
    if (uint8list == null) {
      uint8list = await asset.thumbnailDataWithSize(ThumbnailSize(size, size));
      addCacheMap(_path!, uint8list!);
    }

    setState(() {
      thumbData = uint8list;
    });
  }

  Future<String?> _getPath(AssetEntity asset) async {
    return (await asset.loadFile())?.path;
  }

  @override
  void initState() {
    super.initState();
    _getThumbFromAssetEntity(widget.asset, widget.size);
  }

  @override
  void didUpdateWidget(covariant ImageItemDataWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _getThumbFromAssetEntity(widget.asset, widget.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (thumbData == null) return const SizedBox();
    final tag = Random().nextInt(1 << 30).toString();
    PreviewData preview;
    if (widget.asset.type == AssetType.video) {
      preview = PreviewData(
        heroTag: tag,
        type: Type.video,
        video: VideoData(
          coverData: thumbData!,
          url: _path,
        ),
      );
    } else {
      preview = PreviewData(
        heroTag: tag,
        type: Type.image,
        image: ImageData(
          thumbnailData: thumbData!,
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
