import 'dart:io';
import 'dart:typed_data';

import 'package:assets_picker_ot/src/grid_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:photo_manager/photo_manager.dart';

class PickerPage extends StatefulWidget {
  const PickerPage({
    super.key,
    this.overMaxSelected,
    this.maxSelected = 1,
    this.showCamera = false,
    this.cameraWidget,
    this.onTapCamera,
    this.controller,
    this.appBarBackgroundColor,
    this.appBarElevation,
    this.appBarLeading,
    this.appBarDone,
    this.iconColor,
    this.titleTextStyle,
    this.isSelectedVideo = false,
  });

  /// 一些错误的提示回调
  final OverMaxSelected? overMaxSelected;

  /// 最大的可选择数量
  final int maxSelected;

  final bool showCamera;
  final Widget? cameraWidget;
  final OnTapCamera? onTapCamera;

  final PickController? controller;

  final Color? appBarBackgroundColor;
  final double? appBarElevation;
  final Widget? appBarLeading;
  final Widget? appBarDone;
  final Color? iconColor;
  final TextStyle? titleTextStyle;

  // 是否支持选择视频
  final bool isSelectedVideo;

  @override
  PickerPageState createState() => PickerPageState();
}

class PickerPageState extends State<PickerPage> {
  final List<AssetPathEntity> _paths = [];
  final assertCount = <String, int>{};

  // 当前页面显示的资源图片
  final List<AssetEntity> _entities = [];
  AssetPathEntity? _currentPath;

  // 已选择的资源
  final List<AssetEntity> _selected = [];
  File? cameraFile;

  // 是否正在切换路径
  bool _isSwitchingPath = false;

  // 是否暂无数据
  bool _isNoData = false;

  final _pageMaxNum = 80;

  final ScrollController _scrollController = ScrollController();

  /// 获取目录
  Future<void> _getPath() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: widget.isSelectedVideo ? RequestType.common : RequestType.image,
    );
    debugPrint('_getPath $paths');
    _paths.clear();
    assertCount.clear();
    for (var pathEntity in paths) {
      assertCount[pathEntity.id] = await pathEntity.assetCountAsync;
    }
    _paths.addAll(paths);
    if (_paths.isNotEmpty) {
      _tapPathList(_paths.first);
    } else {
      setState(() {
        _isNoData = true;
      });
    }
  }

  /// 通过资源ID 获取缩略图
  Future<Uint8List?> _getFirstThumbFromPathEntity(
    AssetPathEntity pathEntity,
  ) async {
    final AssetEntity asset = (await pathEntity.getAssetListRange(
      start: 0,
      end: 1,
    ))
        .elementAt(0);
    final Uint8List? assetData =
        await asset.thumbnailDataWithSize(const ThumbnailSize(100, 100));
    return assetData;
  }

  /// 点击了路径列表
  /// 然后通过[pathEntity]找到当前的图库列表
  void _tapPathList(AssetPathEntity pathEntity) {
    setState(() {
      _isNoData = false;
      _isSwitchingPath = false;
      _currentPath = pathEntity;
    });

    _queryAssetsList(0);
  }

  /// 查询资源列表
  /// [start] 开始位置
  Future<void> _queryAssetsList(int start) async {
    if (_currentPath == null) return;
    final List<AssetEntity> entities = await _currentPath!
        .getAssetListRange(start: start, end: _pageMaxNum + start);
    setState(() {
      if (start == 0) _entities.clear();
      _entities.addAll(entities);
    });
  }

  Future<void> done() async {
    if (!mounted) return;
    final fileList = <SelectedFile>[];
    for (var it in _selected) {
      final f = await it.loadFile();
      if (f != null) {
        fileList.add(SelectedFile(
          file: f,
          type: it.type == AssetType.video ? FileType.video : FileType.image,
        ));
      }
    }
    if (cameraFile != null) {
      fileList.add(SelectedFile(file: cameraFile!, type: FileType.image));
    }
    if (!mounted) return;
    Navigator.pop(context, fileList);
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      await _getPath();
    });

    // 滑动监听
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _queryAssetsList(_entities.length);
      }
    });

    widget.controller?.done = done;
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          leading: widget.appBarLeading,
          backgroundColor: widget.appBarBackgroundColor ??
              Theme.of(context).colorScheme.primary,
          elevation: _isSwitchingPath
              ? 0
              : widget.appBarElevation ??
                  Theme.of(context).appBarTheme.elevation,
          title: _currentPath == null
              ? const SizedBox()
              : GestureDetector(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Text(
                        _currentPath?.name ?? '',
                        style: widget.titleTextStyle,
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: widget.titleTextStyle?.color,
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _isSwitchingPath = !_isSwitchingPath;
                    });
                  },
                ),
          actions: [
            if (_currentPath != null)
              LayoutBuilder(builder: (context, constraint) {
                return SizedBox(
                  width: constraint.maxHeight,
                  height: constraint.maxHeight,
                  child: widget.appBarDone ??
                      IconButton(
                        icon: Icon(
                          Icons.done,
                          color: widget.iconColor,
                        ),
                        onPressed: done,
                      ),
                );
              }),
          ],
        ),
        body: Stack(
          children: [
            if (_currentPath == null)
              _isNoData ? _buildNoDataTip() : _buildLoading(),
            Positioned.fill(
              child: _buildGlideWidget(),
            ),
            _buildPathEntityListBackdrop(),
            _buildPathEntityListWidget(),
          ],
        ),
      ),
    );
  }

  /// 选择路径后的遮罩层
  Widget _buildPathEntityListBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isSwitchingPath,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isSwitchingPath = false;
            });
          },
          child: AnimatedOpacity(
            duration: kThemeAnimationDuration,
            opacity: _isSwitchingPath ? .55 : 0,
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      ),
    );
  }

  /// 选择路径后的弹出窗
  Widget _buildPathEntityListWidget() {
    return Positioned.fill(
      top: 0,
      bottom: null,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(4),
        ),
        child: AnimatedAlign(
          alignment: Alignment.bottomCenter,
          duration: kThemeAnimationDuration,
          curve: Curves.easeInOut,
          heightFactor: _isSwitchingPath ? 1 : 0,
          child: AnimatedOpacity(
            duration: kThemeAnimationDuration,
            curve: Curves.easeInOut,
            opacity: _isSwitchingPath ? 1 : 0,
            child: Container(
              color: widget.appBarBackgroundColor ??
                  Theme.of(context).colorScheme.primary,
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height / 2,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 6),
                    ..._paths.map((it) {
                      return _buildPathEntityWidget(it);
                    }),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 路径选择的list列表元素
  Widget _buildPathEntityWidget(AssetPathEntity pathEntity) {
    const imageSize = 60.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _tapPathList(pathEntity);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: FutureBuilder(
                    future: _getFirstThumbFromPathEntity(pathEntity),
                    builder: (BuildContext context,
                        AsyncSnapshot<Uint8List?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                          );
                        }
                      }
                      return const SizedBox(
                        width: imageSize,
                        height: imageSize,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pathEntity.name} (${assertCount[pathEntity.id]})',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: (widget.titleTextStyle ??
                            TextStyle(
                              color: Theme.of(context).colorScheme.brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onPrimary,
                            ))
                        .copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _currentPath == pathEntity
                ? Icon(
                    Icons.done,
                    size: 24,
                    color: widget.iconColor,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  /// 资源网格列表
  Widget _buildGlideWidget() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      itemCount: _entities.length + (widget.showCamera ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (widget.showCamera) {
          if (index == 0) {
            return GestureDetector(
              onTap: () async {
                if (_selected.length >= widget.maxSelected) {
                  if (widget.overMaxSelected != null) {
                    widget.overMaxSelected!(context);
                    return;
                  }
                }
                if (widget.onTapCamera != null) {
                  cameraFile = await widget.onTapCamera!();
                  if (cameraFile != null) {
                    await done();
                  }
                }
              },
              child: widget.cameraWidget ??
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 50,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
            );
          }
          index--;
        }
        final entity = _entities[index];
        return ImageItemWidget(
          entity,
          showNum: _selected.indexOf(entity) + 1,
          onTap: () {
            final contains = _selected.contains(entity);
            setState(() {
              if (contains) {
                _selected.remove(entity);
              } else {
                if (_selected.length >= widget.maxSelected) {
                  if (widget.overMaxSelected != null) {
                    widget.overMaxSelected!(context);
                    return;
                  }
                }
                _selected.add(entity);
              }
            });
          },
        );
      },
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        //单个子Widget的水平最大宽度
        maxCrossAxisExtent: MediaQuery.of(context).size.width / 4,
        //水平单个子Widget之间间距
        mainAxisSpacing: 2,
        //垂直单个子Widget之间间距
        crossAxisSpacing: 2,
      ),
    );
  }

  /// 加载中
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildNoDataTip() {
    return const Center(
      child: Text(
        '暂无数据',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

class PickController {
  VoidCallback? done;

  void dispose() {
    done = null;
  }
}

// 超过最大的可选择数量
typedef OverMaxSelected = Function(BuildContext context);

typedef OnTapCamera = Future<File?> Function();

// 选择的文件
class SelectedFile {
  const SelectedFile({required this.file, required this.type});

  final File file;
  final FileType type;
}

// 选择的文件类型
enum FileType { image, video }
