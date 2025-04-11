import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class TabContainerWidget extends StatefulWidget {
  const TabContainerWidget({required this.buildScreen, super.key});

  final Widget Function(BuildContext, int) buildScreen;

  @override
  TabContainerState createState() => TabContainerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<Widget Function(BuildContext p1, int p2)>.has("buildScreen", buildScreen))
      ..add(ObjectFlagProperty<Widget Function(BuildContext p1, int p2)>.has("buildScreen", buildScreen));
  }
}

class TabContainerState extends State<TabContainerWidget> with TickerProviderStateMixin {
  static const double _padding = 24;

  TabController? _controller;
  final Map<int, Widget> _tabs = {};
  final List<int> _tabKeys = [];
  int _tabCounter = 0;

  @override
  void initState() {
    super.initState();
    _addTab();
    _initializeController(0);
  }

  void _initializeController(int selectedIndex) {
    if (_tabKeys.isNotEmpty) {
      _controller = TabController(
        vsync: this,
        length: _tabKeys.length,
        initialIndex: selectedIndex.clamp(0, _tabKeys.length - 1),
      );
    } else {
      _controller = null;
    }
  }

  void _addTab() {
    setState(() {
      int newKey = _tabCounter++;
      String title = "Tab ${newKey + 1}";

      _tabs[newKey] = _buildTab(title, newKey);
      _tabKeys.add(newKey);

      _initializeController(_tabKeys.length - 1);
    });
  }

  void _removeTab(int key) {
    if (_tabKeys.length > 1) {
      final int currentIndex = _controller?.index ?? 0;

      setState(() {
        _tabs.remove(key);
        _tabKeys.remove(key);

        final int newIndex = (currentIndex >= _tabKeys.length) ? _tabKeys.length - 1 : currentIndex;

        _initializeController(newIndex);
      });
    }
  }

  Widget _buildTab(String title, int key) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          if (_tabKeys.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => _removeTab(key),
            ),
        ],
      ),
    );
  }

  Widget _addTabButton() {
    return Tooltip(
      message: "Add a new tab",
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
        onPressed: _addTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: SizedBox.expand(
        child: Column(
          children: [
            if (_tabKeys.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No tabs available!", style: TextStyle(color: Colors.white)),
                    _addTabButton(),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TabBar(
                            controller: _controller,
                            isScrollable: true,
                            tabs: _tabKeys.map((key) => _tabs[key]!).toList(),
                          ),
                        ),
                        _addTabButton(),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _controller,
                        children: _tabKeys.map((key) {
                          return Builder(
                            builder: (BuildContext context) {
                              return widget.buildScreen(context, key);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
    properties
      ..add(DiagnosticsProperty<TabController?>("_controller", _controller))
      ..add(DiagnosticsProperty<TabController?>("_controller", _controller));
  }
}
