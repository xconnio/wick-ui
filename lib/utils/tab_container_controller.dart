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
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    if (customNames.containsKey(key)) {
      return;
    }

    if (clientNames[key] == trimmedName) {
      return;
    }

    clientNames[key] = _getUniqueClientName(trimmedName, key);
  }

  String _getUniqueClientName(String baseName, int currentKey) {
    final duplicates =
        clientNames.entries.where((e) => e.key != currentKey && e.value.split(" (").first == baseName).length;
    return duplicates > 0 ? "$baseName (${duplicates + 1})" : baseName;
  }

  String getDisplayName(int key) {
    return customNames[key] ?? clientNames[key] ?? "Tab ${tabKeys.indexOf(key) + 1}";
  }

  void setCustomName(int key, String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      customNames[key] = trimmed;
    } else {
      customNames.remove(key);
    }
  }
}
