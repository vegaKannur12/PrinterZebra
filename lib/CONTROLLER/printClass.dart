import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_simple_bluetooth_printer/flutter_simple_bluetooth_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplefluttre/LOCALDB/localDb.dart';
import 'package:simplefluttre/COMPONENTS/network_connectivity.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PrintController extends ChangeNotifier {
  List label_list = [];
  List config_data = [];
  List detail_data = [];
  String dynamic_code = "";
  bool isprofileLoading = false;
  var bluetoothManager = FlutterSimpleBluetoothPrinter.instance;
  var isScanning = false;
  var isBle = true;
  var isConnected = false;
  bool connectLoading = false;
  String label_name = "";
  var devices = <BluetoothDevice>[];
  StreamSubscription<BTConnectState>? _subscriptionBtStatus;
  BTConnectState currentStatus = BTConnectState.disconnect;
  String comname = "CFC KANNUR";
  BluetoothDevice? selectedPrinter;
  String profile_string = '';

  getprintProfile(BuildContext context, String pr_id, int ind) async {
    NetConnection.networkConnection(context).then((value) async {
      if (value == true) {
        dynamic_code = "";
        notifyListeners();
        try {
          isprofileLoading = true;
          notifyListeners();
          Uri url =
              Uri.parse("https://trafiqerp.in/order/fj/print_profile.php");
          Map body = {
            'print_id': pr_id,
            'type': "0",
          };
          print("body----$body");

          http.Response response = await http.post(
            url,
            body: body,
          );
          // print("respones --- ${response.body}");

          var map = jsonDecode(response.body);
          // print("map printr ${map}");
          if (pr_id == "0") {
            label_list.clear();
            for (var item in map["printer_list"]) {
              label_list.add(item);
            }
            print("heloooooooooooooo prid 0$pr_id");
            print("label list-------------#####---$label_list");

            isprofileLoading = false;
            notifyListeners();
          } else {
            config_data.clear();
            for (var item in map["config_data"]) {
              config_data.add(item);
            }
            // print("config------------>$config_data");
            dynamic_code = config_data[0]['code'];

            print("Dymanic_CODE_----$dynamic_code");
            await BarcodeDB.instance.deleteAllDetails();
            await BarcodeDB.instance
                .insertDetails(int.parse(pr_id), dynamic_code.toString());
            print("inserted to local DDDDDDDDDDDDDBBBBBBB----");
            getLabelProfile();
            setLabelName(label_list[ind]['name'].toString());

            isprofileLoading = false;

            notifyListeners();
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Alert'),
                  content: Text('Config downloaded'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        // Close the AlertDialog
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/bluetoothhome');
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        } catch (e) {
          print(e);
          return null;
        }
      }
    });
  }

  setLabelName(String lName) async {
    label_name = lName;
    notifyListeners();
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString("label_name", label_name);
    notifyListeners();
  }

  connectDevice() async {
    isConnected = false;
    notifyListeners();
    if (selectedPrinter == null) return;
    try {
      connectLoading = true;
      notifyListeners();
      isConnected = await bluetoothManager.connect(
          address: selectedPrinter!.address, isBLE: selectedPrinter!.isLE);
      connectLoading = false;
      notifyListeners();
    } on BTException catch (e) {
      print(e);
    }
  }

  void discovery() {
    devices.clear();
    try {
      bluetoothManager.discovery().listen((device) {
        devices.add(device);
        // setState(() {});
      });
    } on BTException catch (e) {
      print(e);
    }
  }

  void scan() async {
    devices.clear();
    try {
      isScanning = true;
      notifyListeners();

      // if (_isBle) {
      //   final results = await bluetoothManager.scan(timeout: const Duration(seconds: 10));
      //   devices.addAll(results);
      //   setState(() {});
      // }
      // else {
      final bondedDevices = await bluetoothManager.getAndroidPairedDevices();
      devices.addAll(bondedDevices);
      notifyListeners();
      // }
    } on BTException catch (e) {
      print(e);
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  void selectDevice(BluetoothDevice device) async {
    if (selectedPrinter != null) {
      if (device.address != selectedPrinter!.address) {
        await bluetoothManager.disconnect();
      }
    }

    selectedPrinter = device;
    notifyListeners();
  }

  void dispose() {
    _subscriptionBtStatus?.cancel();
    super.dispose();
  }

  subStatus() {
    _subscriptionBtStatus = bluetoothManager.connectState.listen((status) {
      print(' ----------------- status bt $status ------------------ ');
      currentStatus = status;
      if (status == BTConnectState.connected) {
        isConnected = true;

        notifyListeners();
      }
      if (status == BTConnectState.disconnect ||
          status == BTConnectState.fail) {
        isConnected = false;
        notifyListeners();
      }
    });
  }

  setProfileONEDit(String edited) async {
    profile_string = edited;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("prof_string", profile_string);
    notifyListeners();
  }

  getLabelProfile() async {
    profile_string = "";
    notifyListeners();
    List<Map> tableDatalist = [];
    tableDatalist = await BarcodeDB.instance.allDetails();
    print("labelString-------------->${tableDatalist[0]['dynamicCode']}");
    profile_string = tableDatalist[0]['dynamicCode'].toString();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("prof_string", profile_string);
    notifyListeners();
  }

  void printLabel(String barcode, String qty, String sman) async {
    // List<Map> tableDatalist=[];
    // tableDatalist = await BarcodeDB.instance.allDetails();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String pro = prefs.getString("prof_string")!.toUpperCase();
    print("profil-------------->$pro");
    String bcode = pro
        .replaceAll("<COMPANY>".toUpperCase(), comname.toString())
        .replaceAll("<Code>".toUpperCase(), barcode)
        .replaceAll("<Qty>".toUpperCase(), qty)
        .replaceAll("<SM>".toUpperCase(), sman);
    print("cfc---------------$bcode");
    if (selectedPrinter == null) return;
    // final codes =
    //     "^XA\r\n^MMT\r\n^PW384\r\n^LL0253\r\n^LS0\r\n^BY2,2,50^FT40,104^BCN,,N,N,,A\r\n^FDABC123456#5.25^FS\r\n^FT375,191^A0I,45,45^FH\\^FDABC123456#5.25^FS\r\n^FT374,27^A0I,23,24^FH\\^FDHello^FS\r\n^FT372,59^A0I,23,24^FH\\^FDSreya^FS\r\n^PQ1,0,1,Y^PQ1^XZ\r\n";

    final codes = bcode;
    // String.fromCharCode(16) +
    //     "CT~~CD,~CC^~CT~\r\n"
    //         "^XA\r\n"
    //         "~TA000\r\n"
    //         "~JSN\r\n"
    //         "^LT0\r\n"
    //         "^MNW\r\n"
    //         "^MTT\r\n"
    //         "^PON\r\n"
    //         "^PMN\r\n"
    //         "^LH0,0\r\n"
    //         "^JMA\r\n"
    //         "^PR4,4\r\n"
    //         "~SD15\r\n"
    //         "^JUS\r\n"
    //         "^LRN\r\n"
    //         "^CI27\r\n"
    //         "^PA0,1,1,0\r\n"
    //         "^XZ\r\n"
    //         "^XA\r\n"
    //         "^MMT\r\n"
    //         "^PW320\r\n"
    //         "^LL280\r\n"
    //         "^LS0\r\n"
    //         "^BY1,3,92^FT300,100^BCI,,N,N\r\n"
    //         "^FD$barcode^FS\r\n"
    //         "^FT300,25^A0I,31,30^FH\^CI28^FDSREYA^FS^CI27\r\n"
    //         "^FT300,200^A0I,31,30^FH\^CI28^FDVEGA SOFTWARE^FS^CI27\r\n"
    //         "^FT300,70^A0I,31,30^FH\^CI28^FD$barcode^FS^CI27\r\n"
    //         "^PQ1,,,Y\r\n"
    //         "^XZ";
    print("code=====$codes");
//  final codes ="SIZE 57.5 mm, 37.5 mm"
//     "DIRECTION 1,0"
//     "GAP 0,0\n"
//     "REFERENCE 0,0"
//     "OFFSET 0mm"
//     "SET PEEL OFF"
//     "SET CUTTER OFF"
//     "SET PARTIAL_CUTTER OFF"
//     "SET TEAR ON"
//     "CLS"
//     "TEXT 10,100, \"ROMAN.TTF\",0,1,1,\"        MALINCINSI      \""
//     "TEXT 10,120, \"ROMAN.TTF\",0,1,1,\"        MALINCINSI      \""
//     "TEXT 10,150, \"ROMAN.TTF\",0,1,1,\"     KDV: %18    \""
//     "TEXT 10,200, \"ROMAN.TTF\",0,3,2,\"     12.79    \""
//     "BARCODE 328,386,\"128M\",102,0,180,3,6,\"!10512345678\""
//     "TEXT 328, 250, \"ROMAN.TTF\",0,1,1,\"12345678\""
//     "PRINT 1,1";
    try {
      await connectDevice();
      if (!isConnected) return;
      final isSuccess = await bluetoothManager.writeText(codes);
      if (isSuccess) {
        await bluetoothManager.disconnect();
      }
    } on BTException catch (e) {
      print(e);
    }
  }
}
