import "package:flutter/material.dart";
import "package:get/get.dart";

class ActionParam {
  ActionParam(this.type)
      : argController = TextEditingController(),
        keyController = TextEditingController(),
        valueController = TextEditingController();
  final String type; // "arg" or "kwarg"
  final TextEditingController argController;
  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    argController.dispose();
    keyController.dispose();
    valueController.dispose();
  }
}

class ActionParamsController extends GetxController {
  final RxList<ActionParam> params = <ActionParam>[].obs;

  @override
  void onClose() {
    for (final param in params) {
      param.dispose();
    }
    super.onClose();
  }

  void addParam(String type) {
    params.add(ActionParam(type));
  }

  void removeParam(int index) {
    params[index].dispose();
    params.removeAt(index);
  }

  List<String> getArgs() {
    return params.where((param) => param.type == "arg").map((param) => param.argController.text).toList();
  }

  Map<String, String> getKwArgs() {
    return {
      for (final param in params.where((param) => param.type == "kwarg"))
        param.keyController.text: param.valueController.text,
    };
  }
}
