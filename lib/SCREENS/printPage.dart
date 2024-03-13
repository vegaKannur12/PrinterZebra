import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:simplefluttre/COMPONENTS/textfldCommon.dart';
import 'package:simplefluttre/CONTROLLER/printClass.dart';

class PrintPage extends StatefulWidget {
  const PrintPage({
    super.key,
  });

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController barcode_ctrl = TextEditingController();
  TextEditingController qty_ctrl = TextEditingController();
  TextEditingController sale_ctrl = TextEditingController();
  String _scanBarcode = 'Unknown';
  @override
  void initState() {
    super.initState();
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } 
    on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
      barcode_ctrl.text = _scanBarcode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.red[50],
      appBar: AppBar(backgroundColor: Colors.red[50],
          // actions: [
          //   IconButton(onPressed: () {}, icon: Icon(Icons.document_scanner_sharp))
          // ],
          ),
      body: Consumer<PrintController>(
        builder: (BuildContext context, PrintController value, Widget? child) {
          return Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  Card(elevation: 3,
                    child: Container(
                      padding: EdgeInsets.only(right: 5, left: 5),
                      width: 320,
                      height: 280,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                height: 50,
                                width: 255,
                                child: Widget_TextField(
                                  isSuffix: true,
                                  controller: barcode_ctrl,
                                  obscureNotifier: ValueNotifier<bool>(
                                      false), // For non-password field, you can set any initial value
                                  hintText: 'Barcode',
                                  prefixIcon: Icons.barcode_reader,
                                  typeoffld: TextInputType.text,
                                  validator: (text) {
                                    if (text == null || text.isEmpty) {
                                      return 'Please Enter barcode';
                                    }
                                    return null;
                                  },
                                ),
                              ),SizedBox(width: 5,),
                              IconButton(
                                icon: Image.asset(
                                  "assets/barscan.png",
                                  height: 40,
                                  width: 30,
                                ),
                                onPressed: () {
                                  scanBarcodeNormal();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                height: 50,
                                width: 255,
                                child: Widget_TextField(
                                  isSuffix: true,
                                  controller: qty_ctrl,
                                  obscureNotifier: ValueNotifier<bool>(
                                      false), // For non-password field, you can set any initial value
                                  hintText: 'Quantity',
                                  prefixIcon: Icons.numbers,
                                  typeoffld: TextInputType.number,
                                  validator: (text) {
                                    if (text == null || text.isEmpty) {
                                      return 'Please Enter quantity';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                height: 50,
                                width: 255,
                                child: Widget_TextField(
                                  isSuffix: true,
                                  controller: sale_ctrl,
                                  obscureNotifier: ValueNotifier<bool>(
                                      false), // For non-password field, you can set any initial value
                                  hintText: 'SalesMan',
                                  prefixIcon: Icons.person,
                                  
                                  typeoffld: TextInputType.number,
                                  
                                  validator: (text) {
                                    if (text == null || text.isEmpty) {
                                      return 'Please Enter SalesMan';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // TextButton(
                  //     onPressed: () {
                  //       print(
                  //           "yyyyyyyyyyyyyyyyyyyyyyyyyy${barcode_ctrl.text}\u0023${qty_ctrl.text}");
                  //     },
                  //     child: Text("viewdata")),
                  const SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                    height: 50,
                    width: 150,
                    child: ElevatedButton(
                      child: Text(
                        "PRINT",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: ()  {
                        if (_formKey.currentState!.validate()) {
                          value.printLabel(
                              barcode_ctrl.text.toString(),
                              qty_ctrl.text.toString(),
                              sale_ctrl.text.toString());

                              barcode_ctrl.clear();
                              qty_ctrl.clear();
                              sale_ctrl.clear();
                          // "${barcode_ctrl.text}\u0023${qty_ctrl.text}");
                        }
                      },
                    ),
                  ),

                  // TextButton(
                  //     onPressed: () {
                  //       Provider.of<Controller>(context, listen: false)
                  //           .getprintProfile(context);
                  //     },
                  //     child: Text("Dataaaa"))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
