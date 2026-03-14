import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
// import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection_wrapper.dart';
import 'package:ar_flutter_plugin_updated/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:collection/collection.dart';
import '../../domain/usecases/calculate_weight.dart';

class ARMeasurePage extends StatefulWidget {
  final String? species;

  const ARMeasurePage({super.key, this.species});

  @override
  State<ARMeasurePage> createState() => _ARMeasurePageState();
}

class _ARMeasurePageState extends State<ARMeasurePage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  String _message = "Tap to place Start Point (Head)";
  double? _distanceCm;
  double? _weightGrams;

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measure Fish'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_distanceCm != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Length:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          '${_distanceCm!.toStringAsFixed(1)} cm',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Est. Weight:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          '${_weightGrams!.toStringAsFixed(0)} g',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetMeasurement,
                        child: const Text('Measure Again'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: false,
          handlePans: true,
          handleRotation: true,
        );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTap;
  }

  Future<void> onPlaneOrPointTap(List<ARHitTestResult> hitTestResults) async {
    print("Tap detected! Hits: ${hitTestResults.length}");
    if (nodes.length >= 2) return;

    var singleHitTestResult = hitTestResults.firstWhereOrNull(
      (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
    );

    if (singleHitTestResult != null) {
      print("Plane hit detected!");
      var newAnchor = ARPlaneAnchor(
        transformation: singleHitTestResult.worldTransform,
      );
      bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        anchors.add(newAnchor);

        // Add a sphere node at the tapped point
        var newNode = ARNode(
          type: NodeType.webGLB,
          uri:
              "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb", // Placeholder or simple shape
          scale: vector.Vector3(0.01, 0.01, 0.01),
          position: vector.Vector3(0, 0, 0),
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? didAddNode =
            await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
        if (didAddNode == true) {
          nodes.add(newNode);
        }

        setState(() {
          if (nodes.length == 1) {
            _message = "Tap to place End Point (Tail)";
          } else if (nodes.length == 2) {
            _calculateDistance();
            _message = "Measurement Complete";
          }
        });
      }
    } else {
      print("No plane hit.");
    }
  }

  void _calculateDistance() {
    if (anchors.length < 2) return;

    // Get positions from anchors
    // transformation is a 4x4 matrix, position is column 3 (x, y, z)
    final pos1 = anchors[0].transformation.getColumn(3);
    final pos2 = anchors[1].transformation.getColumn(3);

    final distanceMeters = pos1.distanceTo(pos2);
    final distanceCm = distanceMeters * 100;

    final weight = CalculateWeight()(
      lengthCm: distanceCm,
      species: widget.species,
    );

    setState(() {
      _distanceCm = distanceCm;
      _weightGrams = weight;
    });
  }

  void _resetMeasurement() {
    for (var anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors.clear();
    nodes.clear();
    setState(() {
      _distanceCm = null;
      _weightGrams = null;
      _message = "Tap to place Start Point (Head)";
    });
  }
}
