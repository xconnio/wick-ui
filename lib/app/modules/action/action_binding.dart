import "package:get/get.dart";
import "package:wick_ui/app/modules/action/action_controller.dart";
import "package:wick_ui/app/modules/action/action_params_controller.dart";

class ActionBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put<ActionController>(
        ActionController(),
        tag: "action_0",
        permanent: true,
      )
      ..put<ActionParamsController>(
        ActionParamsController(),
        tag: "params_0",
        permanent: true,
      );
  }
}
