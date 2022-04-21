library barcode_bill_scanner;

import 'package:barcode_bill_scanner/util/bill_util.class.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_barcode_kit/google_barcode_kit.dart';

import 'widgets/bill_scan_camera.widget.dart';

/// Widget used to read and convert a barcode.
///
/// It shows a friendly interface guiding the user to scan the barcode using the phone's camera.
/// Este widget serve como tela para exibição da câmera que faz a leitura do código de barras.
///
/// Example:
///
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///    return Stack(
///      alignment: Alignment.center,
///      children: [
///        BarcodeBillScanner(
///          onCancelLabel: "You can set a message to cancel an action",
///          onSuccess: (String value) async {
///            setState(() => barcode = value);
///          },
///          onCancel: () {
///            setState(() => barcode = null);
///          },
///        ),
///        if (barcode != null)
///          Text(
///            barcode!,
///            textAlign: TextAlign.center,
///            style: const TextStyle(
///              fontSize: 20.0,
///              color: Colors.amber,
///            ),
///          ),
///      ],
///    );
///  }
/// ```
class BarcodeBillScanner extends StatefulWidget {
  const BarcodeBillScanner({
    Key? key,
    this.infoText = "Scan the barcode using your camera.",
    required this.onSuccess,
    this.onAction,
    this.onError,
    this.onActionLabel = "Type barcode",
    this.color = Colors.cyan,
    this.textColor = const Color(0xff696876),
    this.convertToFebraban = true,
    this.backdropColor = const Color(0x99000000),
  }) : super(key: key);

  /// Text shown on top of the screen.
  final String infoText;

  /// Method called after the barcode is successfuly read and converted.
  final Future<dynamic> Function(String value) onSuccess;

  /// Method called by the action button.
  final Function()? onAction;

  /// Label for the action button.
  final String onActionLabel;

  /// Method called on error while reading the barcode.
  final Function()? onError;

  /// Main color.
  final Color color;

  /// Text color. Must have enough contrast with [color].
  final Color textColor;

  /// If `true` converts the barcode to FEBRABAN format (47/48 characters long).
  final bool convertToFebraban;

  /// Backdrop color used as a frame for reading the barcode.
  final Color backdropColor;

  @override
  _BarcodeMLKitState createState() => _BarcodeMLKitState();
}

class _BarcodeMLKitState extends State<BarcodeBillScanner> {
  BarcodeScanner barcodeScanner = GoogleMlKit.vision.barcodeScanner([
    BarcodeFormat.itf,
    BarcodeFormat.codabar,
  ]);
  bool isBusy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BillScanCameraWidget(
        onImage: (inputImage) {
          _processImage(inputImage);
        },
      ),
    );
  }

  /// Processes the [inputImage] to extract and format the barcode's numbers.
  Future<void> _processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final barcodes = await barcodeScanner.processImage(inputImage);

    if (barcodes.isNotEmpty) {
      try {
        Barcode? validBarcode = barcodes.firstWhere(
          (barcode) {
            return barcode.value.displayValue?.length == 44;
          },
        );
        if (validBarcode == null) return;
        String code = widget.convertToFebraban
            ? BillUtil.getFormattedbarcode(validBarcode.value.displayValue!)
            : validBarcode.value.displayValue!;

        widget.onSuccess(code).whenComplete(() => isBusy = false);
      } catch (e) {
        if (widget.onError != null) widget.onError!();
      }
    }

    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
