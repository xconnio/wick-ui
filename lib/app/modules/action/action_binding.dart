import "package:flutter/material.dart";
import "package:get/get.dart";

import "package:wick_ui/app/modules/action/action_controller.dart";

class ActionBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put<ActionController>(ActionController(), tag: "action_0")
      ..put<ScrollController>(ScrollController(), tag: "logs_0");
  }
}
