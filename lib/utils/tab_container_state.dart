import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/action/action_params_controller.dart";
import "package:wick_ui/utils/constants.dart";
import "package:wick_ui/utils/tab_container_controller.dart";

class TabContainerWidget extends StatefulWidget {
  const TabContainerWidget({required this.buildScreen, super.key});
  final Widget Function(BuildContext context, int key) buildScreen;

  @override
  State<TabContainerWidget> createState() => TabContainerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<Widget Function(BuildContext, int)>.has("buildScreen", buildScreen),
    );
  }
}

class TabContainerState extends State<TabContainerWidget> with TickerProviderStateMixin {
  static const Color selectedTabColor = Colors.white;
  static const Color unselectedTabColor = Colors.white70;
  static const double _padding = horizontalPadding * 2.4;
  static const double _tabWidth = 80;
  static const double _tabHeight = kToolbarHeight;
  static const EdgeInsets _tabPadding = EdgeInsets.symmetric(vertical: 6);
  static const TextStyle _tabTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  late final TabStateController _tabStateController = Get.put(TabStateController(), permanent: true);
  late final TextEditingController _nameController = TextEditingController();
  TabController? _controller;

  int? _editingTabKey;
  int _lastTabCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeTabs();
    _setupListeners();
  }

  void _initializeTabs() {
    if (_tabStateController.tabKeys.isEmpty) {
      _tabStateController.addTab();
    }
    _lastTabCount = _tabStateController.tabKeys.length;
    _initTabController(initialIndex: _tabStateController.selectedIndex.value);
  }

  void _initTabController({required int initialIndex}) {
    _controller?.dispose();
    _controller = TabController(
      vsync: this,
      length: _tabStateController.tabKeys.length,
      initialIndex: initialIndex.clamp(0, _tabStateController.tabKeys.length - 1),
    )..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    final idx = _controller!.index;
    if (_tabStateController.selectedIndex.value != idx) {
      _tabStateController.selectedIndex(idx);
    }
    final currentKey = _tabStateController.tabKeys[idx];
    final actionTag = "action_$currentKey";
    if (Get.isRegistered<ActionController>(tag: actionTag)) {
      Get.find<ActionController>(tag: actionTag).refresh();
    }
  }

  void _setupListeners() {
    ever(_tabStateController.tabKeys, (_) {
      if (_lastTabCount != _tabStateController.tabKeys.length) {
        final clampedIndex = _tabStateController.selectedIndex.value.clamp(0, _tabStateController.tabKeys.length - 1);
        _initTabController(initialIndex: clampedIndex);
        _lastTabCount = _tabStateController.tabKeys.length;
      }
      setState(() {});
    });

    ever(_tabStateController.selectedIndex, (int idx) {
      if (_controller != null && _controller!.index != idx && idx >= 0 && idx < _controller!.length) {
        _controller!.animateTo(idx);
      }
    });
  }

  void _startEditing(int key) {
    setState(() {
      _nameController.text = _tabStateController.getDisplayName(key);
      _editingTabKey = key;
    });
  }

  Future<void> _removeTab(int key) async {
    final actionTag = "action_$key";
    final paramsTag = "params_$key";

    if (Get.isRegistered<ActionController>(tag: actionTag)) {
      await Get.delete<ActionController>(tag: actionTag, force: true);
    }
    if (Get.isRegistered<ActionParamsController>(tag: paramsTag)) {
      await Get.delete<ActionParamsController>(tag: paramsTag, force: true);
    }
    _tabStateController.removeTab(key);
  }

  Widget _buildTabContent(int key) {
    final isEditing = _editingTabKey == key;
    final isSelected = _controller?.index == _tabStateController.tabKeys.indexOf(key);
    final color = isSelected ? selectedTabColor : unselectedTabColor;

    return SizedBox(
      width: _tabWidth,
      child: Padding(
        padding: _tabPadding,
        child: isEditing
            ? TextField(
                controller: _nameController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: _tabTextStyle.copyWith(color: color),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onSubmitted: (value) {
                  _tabStateController.setCustomName(key, value);
                  setState(() => _editingTabKey = null);
                },
              )
            : Center(
                child: Text(
                  _tabStateController.getDisplayName(key),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: _tabTextStyle.copyWith(color: color),
                ),
              ),
      ),
    );
  }

  Tab _buildTab(int key) {
    final showClose = _tabStateController.tabKeys.length > 1;
    final isSelected = _controller?.index == _tabStateController.tabKeys.indexOf(key);
    final color = isSelected ? selectedTabColor : unselectedTabColor;

    return Tab(
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onDoubleTap: () => _startEditing(key),
              behavior: HitTestBehavior.opaque,
              child: _buildTabContent(key),
            ),
            if (showClose) ...[
              const SizedBox(width: 6),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _removeTab(key),
                  child: Icon(Icons.close, size: iconSize, color: color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _addTabButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: IconButton(
        icon: Icon(Icons.add, size: largeIconSize, color: whiteColor),
        onPressed: _tabStateController.addTab,
        tooltip: "Add a new tab",
      ),
    );
  }

  Widget _buildTabView(BuildContext context, int key) {
    final actionTag = "action_$key";
    final paramsTag = "params_$key";

    if (!Get.isRegistered<ActionController>(tag: actionTag)) {
      Get.put<ActionController>(
        ActionController()..tag = actionTag,
        tag: actionTag,
        permanent: true,
      );
    }

    if (!Get.isRegistered<ActionParamsController>(tag: paramsTag)) {
      Get.put<ActionParamsController>(
        ActionParamsController(),
        tag: paramsTag,
        permanent: true,
      );
    }

    return GetBuilder<ActionController>(
      tag: actionTag,
      builder: (_) => widget.buildScreen(context, key),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Obx(() {
        if (_tabStateController.tabKeys.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No tabs available!", style: TextStyle(color: whiteColor)),
                _addTabButton(),
              ],
            ),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: _tabHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        tabBarTheme: TabBarThemeData(
                          labelColor: selectedTabColor,
                          unselectedLabelColor: unselectedTabColor,
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              color: blueAccentColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _controller,
                        isScrollable: true,
                        tabs: _tabStateController.tabKeys.map(_buildTab).toList(),
                      ),
                    ),
                  ),
                  _addTabButton(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: _tabStateController.tabKeys.map((key) => _buildTabView(context, key)).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TabController?>("_controller", _controller));
  }
}
