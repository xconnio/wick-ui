import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/action/action_params_controller.dart";
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
  static const double _padding = 24;

  TabController? _controller;
  final TabStateController _tabStateController = Get.put(TabStateController(), permanent: true);
  final TextEditingController _nameController = TextEditingController();

  int? _editingTabKey;
  int _lastTabCount = 0;

  @override
  void initState() {
    super.initState();

    if (_tabStateController.tabKeys.isEmpty) {
      _tabStateController.addTab();
    }

    _lastTabCount = _tabStateController.tabKeys.length;
    _initTabController(initialIndex: _tabStateController.selectedIndex.value);

    ever(_tabStateController.tabKeys, (_) {
      if (_lastTabCount != _tabStateController.tabKeys.length) {
        final clampedIndex = _tabStateController.selectedIndex.value.clamp(0, _tabStateController.tabKeys.length - 1);
        _initTabController(initialIndex: clampedIndex);
        _lastTabCount = _tabStateController.tabKeys.length;
      }
      setState(() {});
    });

    ever(_tabStateController.selectedIndex, (int idx) {
      final controller = _controller;
      if (controller != null && controller.index != idx && idx >= 0 && idx < controller.length) {
        controller.animateTo(idx);
      }
    });
  }

  void _initTabController({required int initialIndex}) {
    _controller?.dispose();
    _controller = TabController(
      vsync: this,
      length: _tabStateController.tabKeys.length,
      initialIndex: initialIndex.clamp(0, (_tabStateController.tabKeys.length - 1).clamp(0, 1 << 31)),
    )..addListener(() {
        final idx = _controller!.index;
        if (_tabStateController.selectedIndex.value != idx) {
          _tabStateController.selectedIndex(idx);
        }

        final currentKey = _tabStateController.tabKeys[idx];
        final actionTag = "action_$currentKey";
        if (Get.isRegistered<ActionController>(tag: actionTag)) {
          Get.find<ActionController>(tag: actionTag).refresh();
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
    if (Get.isRegistered<ActionController>(tag: actionTag)) {
      await Get.delete<ActionController>(tag: actionTag, force: true);
    }

    final paramsTag = "params_$key";
    if (Get.isRegistered<ActionParamsController>(tag: paramsTag)) {
      await Get.delete<ActionParamsController>(tag: paramsTag, force: true);
    }

    _tabStateController.removeTab(key);
  }

  Tab _buildTab(int key) {
    final bool showClose = _tabStateController.tabKeys.length > 1;
    final tabName = _tabStateController.getDisplayName(key);
    final isEditing = _editingTabKey == key;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing)
            SizedBox(
              width: 120,
              child: FocusScope(
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  onSubmitted: (value) {
                    _tabStateController.setCustomName(key, value);
                    setState(() => _editingTabKey = null);
                  },
                  onEditingComplete: () {
                    _tabStateController.setCustomName(key, _nameController.text);
                    setState(() => _editingTabKey = null);
                  },
                ),
              ),
            )
          else
            GestureDetector(
              onDoubleTap: () => _startEditing(key),
              child: Text(
                tabName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          if (showClose) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _removeTab(key),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addTabButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: IconButton(
        icon: const Icon(Icons.add, size: 20, color: Colors.white),
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
                const Text("No tabs available!", style: TextStyle(color: Colors.white)),
                _addTabButton(),
              ],
            ),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _controller,
                      isScrollable: true,
                      indicatorColor: Colors.blueAccent,
                      tabs: _tabStateController.tabKeys.map(_buildTab).toList(),
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
