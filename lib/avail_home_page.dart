import 'dart:ffi';
import 'dart:isolate';

import 'package:avail_light_app/confidence_response_struct.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

typedef RunNode = bool Function();
typedef RunNodeFFI = Bool Function();

typedef GetBlock = int Function();
typedef GetBlockFFI = Uint32 Function();

typedef GetConfidence = double Function(int);
typedef GetConfidenceFFI = Double Function(Uint32);

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
  late DynamicLibrary lightClientLib;
  int _finalizedBlock = 0;
  int _unfinalizedBlock = 0;
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
    lightClientLib = DynamicLibrary.open("libavail_light_2.so");
    DynamicLibrary.open("libc++_shared.so");
    super.initState();
  }

  void _startLightClient() async {
    final directory = await getApplicationDocumentsDirectory();
    debugPrint(directory.path);
    if (isolateActive) {
      return;
    }

    Future isolateRun = Isolate.run(() async {
      final lightClientLib = DynamicLibrary.open("libavail_light_2.so");
      DynamicLibrary.open("libc++_shared.so");
      RunNode function = lightClientLib
          .lookup<NativeFunction<RunNodeFFI>>("start_light_node")
          .asFunction();
      function();
    }, debugName: "light_node");
    setState(() {
      isolateActive = true;
    });
    isolateRun.whenComplete(() => setState(() {
          isolateActive = false;
        }));
  }

  int _latestBlock() {
    GetBlock function = lightClientLib
        .lookup<NativeFunction<GetBlockFFI>>("c_latest_unfinalized_block")
        .asFunction();
    return function();
  }

  int _latestFinalizedBlock() {
    GetBlock function = lightClientLib
        .lookup<NativeFunction<GetBlockFFI>>("c_latest_block")
        .asFunction();
    return function();
  }

  double _confidence(int block) {
    GetConfidence function = lightClientLib
        .lookup<NativeFunction<GetConfidenceFFI>>("c_confidence")
        .asFunction();
    return function(block);
  }

  _getData() {
    final finalizedBlock = _latestFinalizedBlock();
    final unfinalizedBlock = _latestBlock();
    final confidence = _confidence(finalizedBlock);
    setState(() {
      _finalizedBlock = finalizedBlock;
      _unfinalizedBlock = unfinalizedBlock;
      _blockConfidence = confidence;
    });
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
                        width: 200,
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                  Text("Finalized Block Confidence", style: smallTextStyle),
                  Text("$_blockConfidence",
                      style: largeTextStyle.copyWith(fontSize: 40)),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .inversePrimary
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black12,
                  ),
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
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 120,
                          width: 1,
                          color: Colors.black87,
                        ),
                      ),
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Icon(
                              Icons.timer_rounded,
                              size: 30,
                            ),
                          ),
                          Text(
                            "Latest Block",
                            style: smallRowTextStyle,
                          ),
                          Text(
                            "$_unfinalizedBlock",
                            style: largeRowTextStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30),
                child: Center(
                  child: ElevatedButton(
                    onPressed: _getData,
                    child: Text(
                      "Refresh Data",
                      style: smallRowTextStyle.copyWith(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
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
