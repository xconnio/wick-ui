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

  @override
  void initState() {
    super.initState();
    if (_tabStateController.tabKeys.isEmpty) {
      _tabStateController.addTab();
    }
  }

  void _initializeController(int selectedIndex) {
    _controller?.dispose();
    _controller = TabController(
      vsync: this,
      length: _tabStateController.tabKeys.length,
      initialIndex: selectedIndex.clamp(0, _tabStateController.tabKeys.length - 1),
    )..addListener(() {
        _tabStateController.selectedIndex(_controller!.index);
        final currentKey = _tabStateController.tabKeys[_controller!.index];
        final actionTag = "action_$currentKey";
        if (Get.isRegistered<ActionController>(tag: actionTag)) {
          Get.find<ActionController>(tag: actionTag).refresh();
        }
      });
  }

  void _startEditing(int key) {
    setState(() {
      _nameController.text = _tabStateController.getDisplayName(key);
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

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onDoubleTap: () => _startEditing(key),
            child: Text(
              tabName,
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
      final controller = Get.put<ActionController>(
        ActionController(),
        tag: actionTag,
        permanent: true,
      );
      controller.tag = actionTag;
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
      builder: (controller) => widget.buildScreen(context, key),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Obx(() {
        _initializeController(_tabStateController.selectedIndex.value);

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
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TabController?>("_controller", _controller));
  }
}
