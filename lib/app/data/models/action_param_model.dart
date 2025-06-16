import "package:flutter/material.dart";

class ParamModel {
  ParamModel({required this.type})
      : argController = TextEditingController(),
        keyController = TextEditingController(),
        valueController = TextEditingController();
  final String type;
  final TextEditingController argController;
  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    argController.dispose();
    keyController.dispose();
    valueController.dispose();
  }

  String? validateArg(String? value) {
    if (value == null || value.isEmpty) {
      return "arg cannot be empty";
    }
    return null;
  }

  String? validateKey(String? value) {
    if (value == null || value.isEmpty) {
      return "key cannot be empty";
    }
    return null;
  }

  String? validateValue(String? value) {
    if (value == null || value.isEmpty) {
      return "value cannot be empty";
    }
    return null;
  }
}
