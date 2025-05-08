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
}
