import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

typedef RunNode = Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
);
typedef RunNodeFFI = Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
);

typedef GetBlock = Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
);
typedef GetBlockFFI = Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
);

typedef GetV2Status = Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
);
typedef GetV2StatusFfi = Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
);

typedef GetStatus = Pointer<Utf8> Function(
  int,
  ffi.Pointer<ffi.Uint8> cfg,
);
typedef GetStatusFfi = Pointer<Utf8> Function(
  Int,
  ffi.Pointer<ffi.Uint8> cfg,
);

typedef GetConfidence = Pointer<Utf8> Function(
  int,
  ffi.Pointer<ffi.Uint8> cfg,
);
typedef GetConfidenceFFI = Pointer<Utf8> Function(
  ffi.Uint32,
  ffi.Pointer<ffi.Uint8> cfg,
);
void callbackFunction(Pointer<Utf8> message) {
  debugPrint("Message: ${message.toDartString()}");
}

//callback
typedef RunNodeWithCallback = Pointer<Utf8> Function(
    ffi.Pointer<ffi.Uint8> cfg, Pointer<NativeFunction<FfiCallback>>);
typedef RunNodeWithCallbackFFI = ffi.Pointer<Utf8> Function(
    ffi.Pointer<ffi.Uint8> cfg, Pointer<NativeFunction<FfiCallback>>);
typedef FfiCallback = Void Function(Pointer<Utf8>);

class IsolateModel {
  final int callbackPointer;
  final String config;

  IsolateModel({required this.callbackPointer, required this.config});
}

// Submit transaction

typedef SubmitTransaction = ffi.Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
  int appId,
  ffi.Pointer<ffi.Uint8> data,
  ffi.Pointer<ffi.Uint8> privateKey,
);
typedef SubmitTransactionFfi = ffi.Pointer<Utf8> Function(
  ffi.Pointer<ffi.Uint8> cfg,
  ffi.Uint32 appId,
  ffi.Pointer<ffi.Uint8> data,
  ffi.Pointer<ffi.Uint8> privateKey,
);

Future<void> _startLightClientCall(IsolateModel config) async {
  ffi.Pointer<ffi.Uint8> nativeConfig =
      config.config.toNativeUtf8().cast<ffi.Uint8>();
  // final lightClientLib = ffi.DynamicLibrary.open("libavail_light_2.so");

  final lightClientLib = Platform.isAndroid
      ? DynamicLibrary.open("libavail_light_2.so")
      : DynamicLibrary.process();

  ffi.DynamicLibrary.open("libc++_shared.so");
  RunNode function = lightClientLib
      .lookup<ffi.NativeFunction<RunNodeFFI>>("startLightNode")
      .asFunction();
  var resp = function(nativeConfig);
  print("${resp.toDartString()}");
  // RunNodeWithCallback function = lightClientLib
  //     // .lookup<ffi.NativeFunction<RunNodeWithCallbackFFI>>("start_light_node")
  //     .lookup<ffi.NativeFunction<RunNodeWithCallbackFFI>>(
  //         "startLightNodeWithCallback")
  //     .asFunction();
  // var resp =
  //     function(nativeConfig, Pointer.fromAddress(config.callbackPointer));
  // print("${resp.toDartString()}");
}

class AvailHomePage extends StatefulWidget {
  const AvailHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  State<AvailHomePage> createState() => _AvailHomePageState();
}

class _AvailHomePageState extends State<AvailHomePage> {
  late ffi.DynamicLibrary lightClientLib;
  String config = '';
  int _finalizedBlock = 0;
  double _blockConfidence = 0;
  bool isolateActive = false;
  final TextStyle smallTextStyle = const TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  final TextStyle largeTextStyle = const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  final TextStyle smallRowTextStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  final TextStyle largeRowTextStyle = const TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  @override
  void initState() {
    // lightClientLib = ffi.DynamicLibrary.open("libavail_light_2.so");
    // ffi.DynamicLibrary.open("libc++_shared.so");
    lightClientLib = Platform.isAndroid
        ? DynamicLibrary.open("libavail_light_2.so")
        : DynamicLibrary.process();

    super.initState();
  }

  void _startLightClient() async {
    final directory = await getApplicationDocumentsDirectory();
    debugPrint(directory.path);
    if (isolateActive) {
      return;
    }
    await rootBundle.loadString('assets/config.toml').then((str) {
      config = str;
      final callback = NativeCallable<FfiCallback>.listener(callbackFunction);

      IsolateModel isolateConfig = IsolateModel(
          callbackPointer: callback.nativeFunction.address, config: config);

      compute(_startLightClientCall, isolateConfig).then((_) {
        setState(() {
          isolateActive = false;
        });
      });
      setState(() {
        isolateActive = true;
      });
    });
  }

  int _latestFinalizedBlock() {
    ffi.Pointer<ffi.Uint8> nativeConfig =
        config.toNativeUtf8().cast<ffi.Uint8>();

    GetBlock function = lightClientLib
        .lookup<ffi.NativeFunction<GetBlockFFI>>("latestBlock")
        .asFunction();
    Map<dynamic, dynamic> response =
        jsonDecode(function(nativeConfig).toDartString());
    debugPrint("response $response");
    return response['latest_block'];
  }

  sendTransaction() {
    ffi.Pointer<ffi.Uint8> nativeConfig =
        config.toNativeUtf8().cast<ffi.Uint8>();
    const appId = 0;
    final data = jsonEncode({"data": "VGVzdCBkYXRhYWE="});
    const privateKey =
        "pact source double stadium tourist lake skill ginger scatter age strike purpose";
    ffi.Pointer<ffi.Uint8> encodedData = data.toNativeUtf8().cast<ffi.Uint8>();
    ffi.Pointer<ffi.Uint8> encodedPrivateKey =
        privateKey.toNativeUtf8().cast<ffi.Uint8>();

    final SubmitTransaction function = lightClientLib
        .lookup<ffi.NativeFunction<SubmitTransactionFfi>>("submitTransaction")
        .asFunction();
    String response =
        function(nativeConfig, appId, encodedData, encodedPrivateKey)
            .toDartString();
    debugPrint("response $response");
  }

  double _confidence(int block) {
    ffi.Pointer<ffi.Uint8> nativeConfig =
        config.toNativeUtf8().cast<ffi.Uint8>();

    GetConfidence function = lightClientLib
        .lookup<ffi.NativeFunction<GetConfidenceFFI>>("confidence")
        .asFunction();
    Map<dynamic, dynamic> response =
        jsonDecode(function(45, nativeConfig).toDartString());
    debugPrint("response $response");
    return response['confidence'];
  }

  _statusV2() {
    ffi.Pointer<ffi.Uint8> nativeConfig =
        config.toNativeUtf8().cast<ffi.Uint8>();

    GetV2Status function = lightClientLib
        .lookup<ffi.NativeFunction<GetV2StatusFfi>>("getStatusV2")
        .asFunction();
    String response = function(nativeConfig).toDartString();
    debugPrint("response $response");
    return 0;
  }

  _status() {
    ffi.Pointer<ffi.Uint8> nativeConfig =
        config.toNativeUtf8().cast<ffi.Uint8>();

    GetStatus function = lightClientLib
        .lookup<ffi.NativeFunction<GetStatusFfi>>("status")
        .asFunction();
    String response = function(0, nativeConfig).toDartString();
    debugPrint("response $response");
    return 0;
  }

  _getData() {
    final finalizedBlock = _latestFinalizedBlock();
    final confidence = _confidence(finalizedBlock);
    setState(() {
      _finalizedBlock = finalizedBlock;
      _blockConfidence = confidence;
    });
    // _latestFinalizedBlock();
    // _confidence(101);
    // _statusV2();
    // sendTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30),
        child: ElevatedButton(
          onPressed: _getData,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.refresh),
              ),
              Text(
                "Refresh Data",
                style: smallRowTextStyle.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: _startLightClient,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: SizedBox(
                        width: 185,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isolateActive
                                  ? "Light Client Active"
                                  : "Connect to Light Client",
                              style: smallRowTextStyle.copyWith(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.stay_current_portrait_rounded,
                                size: 14.0,
                                color:
                                    isolateActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 100,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Confidence", style: smallTextStyle),
                  Text("$_blockConfidence",
                      style: largeTextStyle.copyWith(fontSize: 40)),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .inversePrimary
                      .withOpacity(0.5),
                  // borderRadius: BorderRadius.circular(20),
                  // border: Border.all(
                  //   color: Colors.black12,
                  // ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30.0,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Icon(
                              Icons.check_circle,
                              size: 30,
                            ),
                          ),
                          Text(
                            "Finalized Block",
                            style: smallRowTextStyle,
                          ),
                          Text(
                            "$_finalizedBlock",
                            style: largeRowTextStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
