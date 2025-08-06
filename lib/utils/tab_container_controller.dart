import "package:get/get.dart";

class TabStateController extends GetxController {
  final RxList<int> tabKeys = <int>[].obs;
  final RxInt tabCounter = 1.obs;
  final RxInt selectedIndex = 0.obs;
  final RxMap<int, String> customNames = <int, String>{}.obs;
  final RxMap<int, String> clientNames = <int, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (tabKeys.isEmpty) {
      addTab();
    }
  }

  void addTab() {
    final key = tabCounter.value;
    tabKeys.add(key);
    tabCounter.value++;
    selectedIndex.value = tabKeys.length - 1;
  }

  void removeTab(int key) {
    if (tabKeys.length > 1) {
      final index = tabKeys.indexOf(key);
      tabKeys.remove(key);
      customNames.remove(key);
      clientNames.remove(key);

      if (selectedIndex.value >= tabKeys.length) {
        selectedIndex.value = tabKeys.length - 1;
      } else if (selectedIndex.value >= index) {
        selectedIndex.value--;
      }
    }
  }

  void updateClientName(int key, String name) {
    if (!customNames.containsKey(key)) {
      clientNames[key] = _getUniqueClientName(name, key);
    }
  }

  String _getUniqueClientName(String baseName, int currentKey) {
    final count = clientNames.values.where((n) => n.startsWith(baseName)).length;
    return count > 0 ? "$baseName (${count + 1})" : baseName;
  }

  String getDisplayName(int key) {
    return customNames[key] ?? clientNames[key] ?? "Tab ${tabKeys.indexOf(key) + 1}";
  }

  void setCustomName(int key, String name) {
    if (name.trim().isNotEmpty) {
      customNames[key] = name.trim();
    } else {
      customNames.remove(key);
    }
  }
}
