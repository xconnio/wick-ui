import "package:get/get.dart";

class KwargsController extends GetxController {
  RxList<MapEntry<String, String>> tableData = <MapEntry<String, String>>[].obs;

  @override
  void onInit() {
    tableData.add(const MapEntry("", ""));
    super.onInit();
  }

  void addRow(MapEntry<String, String> mapEntry) {
    tableData.add(const MapEntry("", ""));
  }

  void updateRow(int index, MapEntry<String, String> newRowData) {
    if (index >= 0 && index < tableData.length) {
      tableData[index] = newRowData;
    }
  }

  void removeRow(int index) {
    if (tableData.length > 1 && index >= 0 && index < tableData.length) {
      tableData.removeAt(index);
    }
  }

  @override
  void onClose() {
    tableData.clear();
    super.onClose();
  }
}
