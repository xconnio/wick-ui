import "package:get/get.dart";
import "package:wick_ui/app/data/models/action_param_model.dart";

class ActionParamsController extends GetxController {
  final RxList<ParamModel> params = <ParamModel>[].obs;

  void addParam(String type) {
    params.add(ParamModel(type: type));
  }

  void removeParam(int index) {
    params[index].dispose();
    params.removeAt(index);
  }

  List<String> getArgs() {
    return params
        .where((p) => p.type == "arg")
        .map((p) => p.argController.text)
        .where((text) => text.isNotEmpty)
        .toList();
  }

  Map<String, String> getKwArgs() {
    return {
      for (final param in params.where((p) => p.type == "kwarg"))
        if (param.keyController.text.isNotEmpty && param.valueController.text.isNotEmpty)
          param.keyController.text: param.valueController.text,
    };
  }

  @override
  void onClose() {
    for (final param in params) {
      param.dispose();
    }
    params.clear();
    super.onClose();
  }
}
