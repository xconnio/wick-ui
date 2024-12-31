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
  final Map<int, Widget> _children = {};
  int _tabCounter = 0;

  @override
  void initState() {
    super.initState();
    _addTab();
    _initializeController(0);
  }

  void _initializeController(int selectedIndex) {
    if (_tabs.isNotEmpty) {
      _controller = TabController(
        vsync: this,
        length: _tabs.length,
        initialIndex: selectedIndex.clamp(0, _tabs.length - 1),
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
      _children[newKey] = widget.buildScreen(context, newKey);

      _initializeController(_tabs.length - 1);
    });
  }

  void _removeTab(int key) {
    if (_tabs.length > 1) {
      final int currentIndex = _controller?.index ?? 0;

      setState(() {
        _tabs.remove(key);
        _children.remove(key);

        final int newIndex = (currentIndex >= _tabs.length) ? _tabs.length - 1 : currentIndex;

        _initializeController(newIndex);
      });
    }
  }

  Widget _buildTab(String title, int key) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (_tabs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
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
        icon: const Icon(Icons.add),
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
            if (_tabs.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No tabs available!"),
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
                            isScrollable: true, // Makes the TabBar scrollable if necessary
                            tabs: _tabs.values.toList(),
                          ),
                        ),
                        _addTabButton(), // Add button aligned to the right
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _controller,
                        children: _children.values.toList(),
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
