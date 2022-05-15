import 'dart:io';
import 'dart:typed_data';

import 'package:assets_picker_ot/src/grid_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:photo_manager/photo_manager.dart';

class PickerPage extends StatefulWidget {
  const PickerPage({
    Key? key,
    this.overMaxSelected,
    this.maxSelected = 1,
  }) : super(key: key);

  /// 一些错误的提示回调
  final OverMaxSelected? overMaxSelected;

  /// 最大的可选择数量
  final int maxSelected;

  @override
  PickerPageState createState() => PickerPageState();
}

class PickerPageState extends State<PickerPage> {
  final List<AssetPathEntity> _paths = [];

  // 当前页面显示的资源图片
  final List<AssetEntity> _entities = [];
  AssetPathEntity? _currentPath;

  // 已选择的资源
  final List<AssetEntity> _selected = [];

  // 是否正在切换路径
  bool _isSwitchingPath = false;

  final _pageMaxNum = 80;

  final ScrollController _scrollController = ScrollController();

  /// 权限获取
  Future<bool> _permissionCheck() async {
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();
    if (_ps.isAuth) {
      // Granted.
      debugPrint("权限已成功获取");
      return true;
    } else {
      // Limited(iOS) or Rejected, use `==` for more precise judgements.
      // You can call `PhotoManager.openSetting()` to open settings for further steps.
      debugPrint("权限拒绝 退出当前页面");
      // if(widget.showTip != null){
      //   widget.showTip!(null, "您拒绝了相册权限，请前往");
      // }
      Navigator.of(context).pop();
      PhotoManager.openSetting();
      return false;
    }
  }

  /// 获取目录
  Future<void> _getPath() async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    _paths.clear();
    _paths.addAll(paths);
    if (_paths.isNotEmpty) {
      _tapPathList(_paths.first);
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

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await _permissionCheck()) {
        await _getPath();
      }
    });

    // 滑动监听
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _queryAssetsList(_entities.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          elevation:
              _isSwitchingPath ? 0 : Theme.of(context).appBarTheme.elevation,
          title: _currentPath == null
              ? const Text('获取中')
              : GestureDetector(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_currentPath?.name ?? ''),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _isSwitchingPath = !_isSwitchingPath;
                    });
                  },
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () async {
                final fileList = <File>[];
                for (var it in _selected) {
                  final f = await it.loadFile();
                  if (f != null) {
                    fileList.add(f);
                  }
                }
                Navigator.pop(context, fileList);
              },
            )
          ],
        ),
        body: Stack(
          children: [
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
            opacity: _isSwitchingPath ? .75 : 0,
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
              color: Theme.of(context).colorScheme.brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.primary,
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height / 2,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 6),
                    ..._paths.map((it) {
                      return _buildPathEntityWidget(it);
                    }).toList(),
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
                    '${pathEntity.name} (${pathEntity.assetCount})',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.brightness ==
                              Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onPrimary,
                      fontSize: 18,
                    ),
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
                    color: Theme.of(context).colorScheme.brightness ==
                            Brightness.dark
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onPrimary,
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
      itemCount: _entities.length,
      itemBuilder: (BuildContext context, int index) {
        final entity = _entities[index];
        return GestureDetector(
          child: ImageItemWidget(
            entity,
            showNum: _selected.indexOf(entity) + 1,
          ),
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
}

// 超过最大的可选择数量
typedef OverMaxSelected = Function(BuildContext context);
