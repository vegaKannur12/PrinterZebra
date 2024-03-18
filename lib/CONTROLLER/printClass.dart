import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_simple_bluetooth_printer/flutter_simple_bluetooth_printer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplefluttre/COMPONENTS/custom_snackbar.dart';
import 'package:simplefluttre/COMPONENTS/external_dir.dart';
import 'package:simplefluttre/LOCALDB/localDb.dart';
import 'package:simplefluttre/COMPONENTS/network_connectivity.dart';
import 'package:http/http.dart' as http;
import 'package:simplefluttre/SCREENS/authentication/login.dart';
import 'dart:convert';

import 'package:simplefluttre/SCREENS/mainHome.dart';
import 'package:simplefluttre/model/registration_model.dart';
import 'package:sql_conn/sql_conn.dart';

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
  bool isLoginLoading = false;
  String label_name = "";
  var devices = <BluetoothDevice>[];
  StreamSubscription<BTConnectState>? _subscriptionBtStatus;
  BTConnectState currentStatus = BTConnectState.disconnect;
  String comname = "CFC KANNUR";
  BluetoothDevice? selectedPrinter;
  String profile_string = '';
  bool downloaded=false;
  String seldeviceName="";
  //variables for reg & login
  String? fp;
  String? cid;
  ExternalDir externalDir = ExternalDir();
  String? sof;
  bool isLoading = false;
  String? appType;
  String? cname;
  List<CD> cD = [];

  Future<RegistrationData?> postRegistration(
      String companyCode,
      String? fingerprints,
      String phoneno,
      String deviceinfo,
      BuildContext context) async {
    NetConnection.networkConnection(context).then((value) async {
      // ignore: avoid_print
      print("Text fp...$fingerprints---$companyCode---$phoneno---$deviceinfo");
      // ignore: prefer_is_empty
      if (companyCode.length >= 0) {
        appType = companyCode.substring(10, 12);
      }
      if (value == true) {
        try {
          Uri url =
              Uri.parse("https://trafiqerp.in/order/fj/get_registration.php");
          Map body = {
            'company_code': companyCode,
            'fcode': fingerprints,
            'deviceinfo': deviceinfo,
            'phoneno': phoneno
          };
          // ignore: avoid_print
          print("register body----$body");
          isLoading = true;
          notifyListeners();
          http.Response response = await http.post(
            url,
            body: body,
          );
          // print("body $body");
          var map = jsonDecode(response.body);
          // ignore: avoid_print
          print("regsiter map----$map");
          RegistrationData regModel = RegistrationData.fromJson(map);

          sof = regModel.sof;
          fp = regModel.fp;
          String? msg = regModel.msg;

          if (sof == "1") {
            if (appType == 'ST') {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              /////////////// insert into local db /////////////////////
              String? fp1 = regModel.fp;

              // ignore: avoid_print
              print("fingerprint......$fp1");
              prefs.setString("fp", fp!);
              if (map["os"] == null || map["os"].isEmpty) {
                isLoading = false;
                notifyListeners();
                CustomSnackbar snackbar = CustomSnackbar();
                snackbar.showSnackbar(context, "Series is Missing", "");
              } else {
                cid = regModel.cid;
                prefs.setString("cid", cid!);

                cname = regModel.c_d![0].cnme;

                prefs.setString("cname", cname!);
                prefs.setString("os", regModel.os!);

                // ignore: avoid_print
                print("cid----cname-----$cid---$cname");
                notifyListeners();

                await externalDir.fileWrite(fp1!);

                // ignore: duplicate_ignore
                for (var item in regModel.c_d!) {
                  // ignore: avoid_print
                  print("ciddddddddd......$item");
                  cD.add(item);
                }
                // verifyRegistration(context, "");

                isLoading = false;
                notifyListeners();

                // await JeminiBorma.instance.deleteFromTableCommonQuery("companyRegistrationTable", "");                // ignore: use_build_context_synchronously
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            } else {
              isLoading = false;
              notifyListeners();
              CustomSnackbar snackbar = CustomSnackbar();
              // ignore: use_build_context_synchronously
              snackbar.showSnackbar(context, "Invalid Apk Key", "");
            }
          }
          /////////////////////////////////////////////////////
          if (sof == "0") {
            isLoading = false;
            notifyListeners();
            CustomSnackbar snackbar = CustomSnackbar();
            // ignore: use_build_context_synchronously
            snackbar.showSnackbar(context, msg.toString(), "");
          }

          notifyListeners();
        } catch (e) {
          // ignore: avoid_print
          print(e);
          return null;
        }
      }
    });
    return null;
  }

  getLogin(String userName, String password, BuildContext context) async {
    try {
      isLoginLoading = true;
      notifyListeners();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (userName.toLowerCase() != "vega" ||
          password.toLowerCase() != "vega") {
        CustomSnackbar snackbar = CustomSnackbar();
        // ignore: use_build_context_synchronously
        snackbar.showSnackbar(context, "Incorrect Username or Password", "");
        isLoginLoading = false;
        notifyListeners();
      } else {
        prefs.setString("st_uname", userName);
        prefs.setString("st_pwd", password);
        // ignore: use_build_context_synchronously
        // initDb(context, "from login");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainHome()),
        );
      }
      isLoginLoading = false;
      notifyListeners();
    } catch (e) {
      // ignore: avoid_print
      print(e);
      return null;
    }
  }

  ///////////////////////////////////////////////////////////////////////////
  getCidCname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cid = prefs.getString("cid")!;
    cname = prefs.getString("cname")!;
    print("cid = $cid,cname--$cname");
  }

  getprintProfile(BuildContext context, String pr_id, int ind) async {
  
    NetConnection.networkConnection(context).then((value) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        cid = prefs.getString("cid")!;
      if (value == true) {
        dynamic_code = "";
        notifyListeners();
        try {
          downloaded=false;
          isprofileLoading = true;
          notifyListeners();
          Uri url =
              Uri.parse("https://trafiqerp.in/order/fj/print_profile.php");
          Map body = {
            'print_id': pr_id,
            'type': "0",
            'company_id':cid,
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
            return;
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
            downloaded=true;
            isprofileLoading = false;

            notifyListeners();
            
          }

          //     notifyListeners();
          //   }
          //  isprofileLoading=false;
          //  notifyListeners();
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
    seldeviceName=selectedPrinter!.name.toString();
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

  void printLabel(
      BuildContext context, String barcode, String qty, String sman) async {
    // List<Map> tableDatalist=[];
    // tableDatalist = await BarcodeDB.instance.allDetails();
    await getCidCname();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String pro = prefs.getString("prof_string")!.toUpperCase();

    print("profil-------------->$pro");
    String bcode = pro
        .replaceAll("<COMPANY>".toUpperCase(), cname.toString())
        .replaceAll("<Code>".toUpperCase(), barcode)
        .replaceAll("<Qty>".toUpperCase(), qty)
        .replaceAll("<SM>".toUpperCase(), sman);
    print("cfc---------------$bcode");
    if (selectedPrinter == null) {
      CustomSnackbar snackbar = CustomSnackbar();
      snackbar.showSnackbar(context, "Connect Printer", "");
      return;
    }

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
      await connectDevice();
      print(e);
    }
  }
}
