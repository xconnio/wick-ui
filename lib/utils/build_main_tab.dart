import "dart:io" show Platform;
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "package:provider/provider.dart";
import "package:wick_ui/constants.dart";
import "package:wick_ui/providers/args_provider.dart";
import "package:wick_ui/providers/event_provider.dart";
import "package:wick_ui/providers/invocation_provider.dart";
import "package:wick_ui/providers/kwargs_provider.dart";
import "package:wick_ui/providers/result_provider.dart";
import "package:wick_ui/providers/session_states_provider.dart";
import "package:wick_ui/providers/tab_provider.dart";
import "package:wick_ui/utils/args_screen.dart";
import "package:wick_ui/utils/kwargs_screen.dart";
import "package:wick_ui/wamp_util.dart";
import "package:xconn/xconn.dart";

class BuildMainTab extends StatefulWidget {
  const BuildMainTab({required this.index, required this.tabControllerProvider, this.formKey, super.key});

  final int index;
  final TabControllerProvider tabControllerProvider;
  final GlobalKey<FormState>? formKey;

  @override
  State<BuildMainTab> createState() => _BuildMainTabState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TabControllerProvider>("tabControllerProvider", tabControllerProvider))
      ..add(IntProperty("index", index))
      ..add(DiagnosticsProperty<GlobalKey<FormState>>("formKey", formKey));
  }
}

class _BuildMainTabState extends State<BuildMainTab> with TickerProviderStateMixin {
  late SessionStateProvider sessionStateProvider;
  late ScaffoldMessengerState scaffoldMessenger;
  late InvocationProvider invocationProvider;
  late EventProvider eventProvider;
  late ResultProvider resultProvider;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  double _textFieldHeight = 0;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTextFieldHeight();
    });
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _areAllTextFieldsFilled();
    });
  }

  bool _areAllTextFieldsFilled() {
    final text1 = widget.tabControllerProvider.tabData[widget.index].linkController.text;
    final text2 = widget.tabControllerProvider.tabData[widget.index].realmController.text;
    final text3 = widget.tabControllerProvider.tabData[widget.index].topicProcedureController.text;
    return text1.isNotEmpty && text2.isNotEmpty && text3.isNotEmpty;
  }

  void _updateTextFieldHeight() {
    final keyContext = formKey.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject()! as RenderBox;
      setState(() {
        _textFieldHeight = box.size.height;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    sessionStateProvider = Provider.of<SessionStateProvider>(context, listen: false);
    invocationProvider = Provider.of<InvocationProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    resultProvider = Provider.of<ResultProvider>(context, listen: false);
    scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildTabActionDropdown(widget.index, widget.tabControllerProvider, context),
          const SizedBox(height: 20),
          _buildTabSerializerDropdown(widget.index, widget.tabControllerProvider),
          const SizedBox(height: 20),
          buildTopicProcedure(
            widget.tabControllerProvider.tabData[widget.index].topicProcedureController,
            widget.tabControllerProvider.tabData[widget.index].sendButtonText,
          ),
          const SizedBox(height: 20),
          buildArgs(
            widget.tabControllerProvider.tabData[widget.index].sendButtonText,
            widget.tabControllerProvider.argsProviders[widget.index],
          ),
          const SizedBox(height: 20),
          if (widget.tabControllerProvider.tabData[widget.index].sendButtonText != "Subscribe" &&
              widget.tabControllerProvider.tabData[widget.index].sendButtonText != "UnSubscribe")
            const Divider(),
          buildKwargs(
            widget.tabControllerProvider.tabData[widget.index].sendButtonText,
            widget.tabControllerProvider.kwargsProviders[widget.index],
          ),
          if (widget.tabControllerProvider.tabData[widget.index].sendButtonText != "Subscribe" &&
              widget.tabControllerProvider.tabData[widget.index].sendButtonText != "UnSubscribe")
            const Divider(),
          Consumer3<InvocationProvider, EventProvider, ResultProvider>(
            builder: (context, invocationProvider, eventProvider, resultProvider, child) {
              final hasInvocationResults = _hasResults(widget.index, invocationProvider.invocations);
              final hasEventsResults = _hasResults(widget.index, eventProvider.events);
              final hasCallResults = _hasResults(widget.index, resultProvider.results);
              if (hasInvocationResults || hasEventsResults || hasCallResults) {
                return resultText(widget.tabControllerProvider.tabData[widget.index].sendButtonText);
              } else {
                return Container();
              }
            },
          ),
          _buildInvocationResults(widget.index),
          _buildEventResults(widget.index),
          _buildCallResults(widget.index, widget.tabControllerProvider),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool _hasResults(int index, List<String> results) {
    return results.where((result) => result.startsWith("$index:")).isNotEmpty;
  }

  Widget _buildTabActionDropdown(int index, TabControllerProvider tabControllerProvider, BuildContext context) {
    double baseWidth;
    if (kIsWeb || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      baseWidth = 50;
    } else {
      baseWidth = 100;
    }

    double pixelDensity = MediaQuery.of(context).devicePixelRatio;
    double buttonWidth = baseWidth / pixelDensity;
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return TextFormField(
                    key: formKey,
                    onChanged: (text) {
                      _updateButtonState();
                    },
                    controller: tabControllerProvider.tabData[index].linkController,
                    decoration: const InputDecoration(
                      hintText: "ws://localhost:8080/ws",
                      hintStyle: TextStyle(fontWeight: FontWeight.w200),
                      labelText: "Enter URL here",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: EdgeInsets.all(10),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "URL cannot be empty";
                      }
                      const urlPattern = r"^(ws|wss):\/\/[^\s$.?#]+(\.[^\s$.?#]+)*(:\d+)?(\/[^\s]*)?$";
                      final result = RegExp(urlPattern, caseSensitive: false).hasMatch(value);
                      if (!result) {
                        return "Enter a valid WebSocket URL";
                      }
                      return null;
                    },
                  );
                },
              ),
            ),
          ),
          sendButton(tabControllerProvider.tabData[index].sendButtonText, index, tabControllerProvider, context),
          Container(width: 1, height: _textFieldHeight, color: Colors.black),
          if (widget.tabControllerProvider.tabData[index].sendButtonText == "UnRegister" ||
              widget.tabControllerProvider.tabData[index].sendButtonText == "UnSubscribe")
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Please ${widget.tabControllerProvider.tabData[index].sendButtonText} first"),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                width: buttonWidth,
                height: _textFieldHeight,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  color: Colors.grey,
                ),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              width: buttonWidth,
              height: _textFieldHeight,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                color: Colors.blue,
              ),
              child: PopupMenuButton<String>(
                onSelected: (String newValue) {
                  setState(() {
                    widget.tabControllerProvider.tabData[index].selectedValue = newValue;
                    widget.tabControllerProvider.tabData[index].sendButtonText = newValue;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return ["Register", "Subscribe", "Call", "Publish"].map((String value) {
                    return PopupMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList();
                },
                child: PopupMenuButton<String>(
                  onSelected: (String newValue) {
                    setState(() {
                      tabControllerProvider.tabData[index].selectedValue = newValue;
                      tabControllerProvider.tabData[index].sendButtonText = newValue;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return ["Register", "Subscribe", "Call", "Publish"].map((String value) {
                      return PopupMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList();
                  },
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSerializerDropdown(int index, TabControllerProvider tabControllerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: tabControllerProvider.tabData[index].selectedSerializer.isEmpty
                  ? null
                  : tabControllerProvider.tabData[index].selectedSerializer,
              focusColor: Colors.transparent,
              hint: const Text("Serializers"),
              items: [jsonSerializer, cborSerializer, msgPackSerializer].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  tabControllerProvider.tabData[index].selectedSerializer = newValue!;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              onChanged: (text) {
                _updateButtonState();
              },
              controller: tabControllerProvider.tabData[index].realmController,
              decoration: InputDecoration(
                hintText: "Enter realm here",
                hintStyle: const TextStyle(fontWeight: FontWeight.w200),
                labelText: "Enter realm here",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(10),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Realm cannot be empty";
                }
                const regexPattern = r"^([^\s\.#]+\.)*([^\s\.#]+)$";
                if (!RegExp(regexPattern).hasMatch(value)) {
                  return "Enter a valid realm";
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvocationResults(int index) {
    return Consumer<InvocationProvider>(
      builder: (context, invocationResult, _) {
        List<String> results = invocationResult.invocations;
        List<String> invocationRslt = results.where((result) => result.startsWith("$index:")).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: invocationRslt.map(_buildResultContainer).toList(),
        );
      },
    );
  }

  Widget _buildEventResults(int index) {
    return Consumer<EventProvider>(
      builder: (context, eventResult, _) {
        List<String> results = eventResult.events;
        List<String> eventRslt = results.where((result) => result.startsWith("$index:")).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: eventRslt.map(_buildResultContainer).toList(),
        );
      },
    );
  }

  Widget _buildCallResults(int index, TabControllerProvider tabControllerProvider) {
    return Consumer<ResultProvider>(
      builder: (context, callResult, _) {
        List<String> results = callResult.results;
        tabControllerProvider.tabData[index].callRslt =
            results.where((result) => result.startsWith("$index:")).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tabControllerProvider.tabData[index].callRslt!.map(_buildResultContainer).toList(),
        );
      },
    );
  }

  Widget _buildResultContainer(String result) {
    String finalResult = result.replaceFirst(RegExp(r"^\d+: "), "");
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            finalResult,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget resultText(String buttonText) {
    String resultLabel;

    switch (buttonText) {
      case "Register":
      case "UnRegister":
        resultLabel = "Invocation";
      case "Call":
        resultLabel = "Result";
      case "Subscribe":
      case "UnSubscribe":
        resultLabel = "Event";
      default:
        return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: 30,
          width: MediaQuery.of(context).size.width,
          child: Text(
            resultLabel,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _publish(int index, TabControllerProvider tabControllerProvider) async {
    List<String> argsData =
        tabControllerProvider.argsProviders[index].controllers.map((controller) => controller.text).toList();
    Map<String, String> kWarValues = {};
    for (final mapEntry in tabControllerProvider.kwargsProviders[index].tableData) {
      kWarValues[mapEntry.key] = mapEntry.value;
    }

    try {
      var session = await connect(
        tabControllerProvider.tabData[index].linkController.text,
        tabControllerProvider.tabData[index].realmController.text,
        tabControllerProvider.tabData[index].selectedSerializer,
      );

      await session.publish(
        tabControllerProvider.tabData[index].topicProcedureController.text,
        args: argsData,
        kwargs: kWarValues,
      );
      setState(() {});
    } on Exception catch (e) {
      return Future.error(e);
    }
  }

  Widget sendButton(String sendButton, int index, TabControllerProvider tabControllerProvider, BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    double baseWidth = (kIsWeb || Platform.isLinux) ? 180 : 350;
    double pixelDensity = MediaQuery.of(context).devicePixelRatio;
    double buttonWidth = baseWidth / pixelDensity;
    Widget buildButton(String label, Future<void> Function() action) {
      return SizedBox(
        width: buttonWidth,
        height: _textFieldHeight,
        child: ElevatedButton(
          onPressed: _isButtonEnabled
              ? () async {
                  if (label == "UnRegister" ||
                      label == "UnSubscribe" ||
                      (widget.formKey?.currentState?.validate() ?? false)) {
                    try {
                      await action();
                    } on Exception catch (error) {
                      if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text("Send Button Error: $error"),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.tabControllerProvider.tabData[index].sendButtonText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    switch (sendButton) {
      case "Publish":
        return buildButton(sendButton, () async {
          try {
            await _publish(index, tabControllerProvider);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("Publish Successful"),
                duration: Duration(seconds: 2),
              ),
            );
          } on Exception catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text("Error in publishing $e"),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      case "Subscribe":
        return buildButton(sendButton, () async {
          try {
            await _subscribe(index, tabControllerProvider, context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("Subscribe Successful"),
                duration: Duration(seconds: 2),
              ),
            );
          } on Exception catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text("Error in Subscribing $e"),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      case "UnSubscribe":
        return buildButton(sendButton, () async {
          try {
            await _unSubscribe(
              index,
              sessionStateProvider.sessionUnSubscribe,
              sessionStateProvider.subscription,
              tabControllerProvider,
            );
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("UnSubscribe Successfully"),
                duration: Duration(seconds: 2),
              ),
            );
          } on Exception catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text("Error in Subscribing: $e"),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      case "Call":
        return buildButton(sendButton, () async {
          try {
            await _call(index, tabControllerProvider, context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("Call Successful"),
                duration: Duration(seconds: 2),
              ),
            );
          } on Exception catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text("Error in Calling: $e"),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      case "Register":
        return buildButton(sendButton, () async {
          try {
            await _registerAndStoreResult(index, tabControllerProvider, sessionStateProvider, context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("Registration Successful"),
                duration: Duration(seconds: 2),
              ),
            );
          } on Exception catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text("Error in Registration $e"),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      case "UnRegister":
        return buildButton(sendButton, () async {
          try {
            await _unRegister(
              index,
              sessionStateProvider.sessionUnRegister,
              sessionStateProvider.unregister,
              tabControllerProvider,
            );
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text("UnRegister Successfully"),
                duration: Duration(seconds: 2),
              ),
            );
          } on Exception catch (e) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text("Error in UnRegistering: $e"),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      default:
        return Container();
    }
  }

  Future<void> _unRegister(int index, Session? session, var reg, TabControllerProvider tabControllerProvider) async {
    await session?.unregister(reg);
    setState(() {
      widget.tabControllerProvider.tabData[index].sendButtonText = "Register";
      invocationProvider.invocations.clear();
    });
  }

  Future<void> _unSubscribe(int index, Session? session, var sub, TabControllerProvider tabControllerProvider) async {
    await session?.unsubscribe(sub);
    setState(() {
      widget.tabControllerProvider.tabData[index].sendButtonText = "Subscribe";
      eventProvider.events.clear();
    });
  }

  Future<void> _registerAndStoreResult(
    int index,
    TabControllerProvider tabControllerProvider,
    SessionStateProvider sessionStateProvider,
    BuildContext context,
  ) async {
    List<String> argsData =
        tabControllerProvider.argsProviders[index].controllers.map((controller) => controller.text).toList();
    Map<String, String> kWarValues = {};
    for (final mapEntry in tabControllerProvider.kwargsProviders[index].tableData) {
      kWarValues[mapEntry.key] = mapEntry.value;
    }

    try {
      var session = await connect(
        tabControllerProvider.tabData[index].linkController.text,
        tabControllerProvider.tabData[index].realmController.text,
        tabControllerProvider.tabData[index].selectedSerializer,
      );

      var registration = await session.register(
        tabControllerProvider.tabData[index].topicProcedureController.text,
        (invocation) {
          String invocations = "$index: args=${invocation.args}, kwargs=${invocation.kwargs}";
          invocationProvider.addInvocation(invocations);
          return Result(args: argsData, kwargs: kWarValues);
        },
      );

      sessionStateProvider
        ..setSessionUnRegister(session)
        ..setUnregister(registration);
      setState(() {
        var unregister = widget.tabControllerProvider.tabData[index].sendButtonText = "UnRegister";
        sendButton(unregister, index, tabControllerProvider, context);
      });
    } on Exception catch (error) {
      throw Exception(error);
    }
  }

  Future<void> _subscribe(int index, TabControllerProvider tabControllerProvider, BuildContext context) async {
    try {
      var session = await connect(
        tabControllerProvider.tabData[index].linkController.text,
        tabControllerProvider.tabData[index].realmController.text,
        tabControllerProvider.tabData[index].selectedSerializer,
      );
      var subscription = await session.subscribe(
        tabControllerProvider.tabData[index].topicProcedureController.text,
        (event) {
          String events = "$index: args=${event.args}, kwargs=${event.kwargs}";
          eventProvider.addEvents(events);
        },
      );
      sessionStateProvider
        ..setSessionUnSubscribe(session)
        ..setUnSubscribe(subscription);
      setState(() {
        var unsubscribe = widget.tabControllerProvider.tabData[index].sendButtonText = "UnSubscribe";
        sendButton(unsubscribe, index, tabControllerProvider, context);
      });
    } on Exception catch (error) {
      throw Exception(error);
    }
  }

  Future<void> _call(int index, TabControllerProvider tabControllerProvider, BuildContext context) async {
    try {
      List<String> argsData =
          tabControllerProvider.argsProviders[index].controllers.map((controller) => controller.text).toList();
      Map<String, String> kWarValues = {};
      for (final mapEntry in tabControllerProvider.kwargsProviders[index].tableData) {
        kWarValues[mapEntry.key] = mapEntry.value;
      }
      var session = await connect(
        tabControllerProvider.tabData[index].linkController.text,
        tabControllerProvider.tabData[index].realmController.text,
        tabControllerProvider.tabData[index].selectedSerializer,
      );

      var calls = await session.call(
        tabControllerProvider.tabData[index].topicProcedureController.text,
        args: argsData,
        kwargs: kWarValues,
      );

      resultProvider.results.clear();
      String result = "$index: args=${calls.args}, kwargs=${calls.kwargs}";
      resultProvider.addResult(result);
    } on Exception catch (error) {
      throw Exception(error);
    }
  }

  Widget buildTopicProcedure(TextEditingController controller, String sendButtonText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextFormField(
        onChanged: (text) {
          _updateButtonState();
        },
        controller: controller,
        decoration: InputDecoration(
          hintText: sendButtonText.contains("Publish") || sendButtonText.contains("Subscribe")
              ? "Enter topic here"
              : "Enter procedure here",
          hintStyle: const TextStyle(fontWeight: FontWeight.w200),
          labelText: sendButtonText.contains("Publish") || sendButtonText.contains("Subscribe")
              ? "Enter topic here"
              : "Enter procedure here",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.all(10),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return "${sendButtonText.contains("Publish") || sendButtonText.contains("Subscribe") ? "Topic" : "Procedure"} cannot be empty";
          }
          const regexPattern = r"^([^\s.#]+\.)*([^\s.#]+)$";
          if (!RegExp(regexPattern).hasMatch(value!)) {
            return sendButtonText.contains("Publish") || sendButtonText.contains("Subscribe")
                ? "Enter a valid topic"
                : "Enter a valid procedure";
          }
          return null;
        },
      ),
    );
  }

  Widget buildArgs(String argsSendButton, ArgsProvider argsProvider) {
    return argsSendButton.contains("Publish") || argsSendButton.contains("Call") || argsSendButton.contains("Register")
        ? ArgsTextFormFields(provider: argsProvider)
        : Container();
  }

  Widget buildKwargs(String kWargSendButton, KwargsProvider kwargsProvider) {
    return kWargSendButton.contains("Publish") ||
            kWargSendButton.contains("Call") ||
            kWargSendButton.contains("Register")
        ? DynamicKeyValuePairs(provider: kwargsProvider)
        : Container();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<SessionStateProvider>("sessionStateProvider", sessionStateProvider))
      ..add(DiagnosticsProperty<ScaffoldMessengerState>("scaffoldMessenger", scaffoldMessenger))
      ..add(DiagnosticsProperty<InvocationProvider>("invocationProvider", invocationProvider))
      ..add(DiagnosticsProperty<EventProvider>("eventProvider", eventProvider))
      ..add(DiagnosticsProperty<ResultProvider>("resultProvider", resultProvider))
      ..add(DiagnosticsProperty<GlobalKey<FormState>>("formKey", formKey));
  }
}
