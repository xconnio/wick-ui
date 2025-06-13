import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/action/action_params_controller.dart";

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
  final List<int> _tabKeys = [];
  int _tabCounter = 0;

  @override
  void initState() {
    super.initState();
    _addTab();
  }

  void _initializeController(int selectedIndex) {
    _controller?.dispose();
    _controller = TabController(
      vsync: this,
      length: _tabKeys.length,
      initialIndex: selectedIndex.clamp(0, _tabKeys.length - 1),
    )..addListener(() {
        setState(() {});
      });

    setState(() {});
  }

  void _addTab() {
    setState(() {
      int newKey = _tabCounter++;
      _tabKeys.add(newKey);
      _initializeController(_tabKeys.length - 1);
    });
  }

  Future<void> _removeTab(int key) async {
    if (_tabKeys.length > 1) {
      final int currentIndex = _controller?.index ?? 0;

      final actionTag = "action_$key";
      if (Get.isRegistered<ActionController>(tag: actionTag)) {
        await Get.delete<ActionController>(tag: actionTag);
      }

      setState(() {
        _tabKeys.remove(key);
        final int newIndex = (currentIndex >= _tabKeys.length) ? _tabKeys.length - 1 : currentIndex;
        _initializeController(newIndex);
      });
    }
  }

  Tab _buildTab(String title, int key) {
    final bool showClose = _tabKeys.length > 1;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
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
        onPressed: _addTab,
        tooltip: "Add a new tab",
      ),
    );
  }

  Widget _buildTabView(BuildContext context, int key) {
    final actionTag = "action_$key";
    final paramsTag = "params_$key";

    if (!Get.isRegistered<ActionController>(tag: actionTag)) {
      Get.lazyPut<ActionController>(ActionController.new, tag: actionTag, fenix: true);
    }

    if (!Get.isRegistered<ActionParamsController>(tag: paramsTag)) {
      Get.lazyPut<ActionParamsController>(ActionParamsController.new, tag: paramsTag, fenix: true);
    }

    return widget.buildScreen(context, key);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: _tabKeys.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No tabs available!", style: TextStyle(color: Colors.white)),
                  _addTabButton(),
                ],
              ),
            )
          : Column(
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
                          tabs: _tabKeys.map((key) => _buildTab("Tab ${key + 1}", key)).toList(),
                        ),
                      ),
                      _addTabButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: IndexedStack(
                    index: _controller?.index ?? 0,
                    children: _tabKeys.map((key) => _buildTabView(context, key)).toList(),
                  ),
                ),
              ],
            ),
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
