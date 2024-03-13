import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplefluttre/LOCALDB/localDb.dart';
import 'package:simplefluttre/LOCALDB/tablelist.dart';
import 'package:simplefluttre/COMPONENTS/custom_snackbar.dart';
import 'package:simplefluttre/SCREENS/ADMIN/loginAdminDialog.dart';
import 'package:simplefluttre/SCREENS/blutoothCon.dart';
import 'package:simplefluttre/CONTROLLER/printClass.dart';
import 'package:simplefluttre/SCREENS/printPage.dart';

class MainHome extends StatefulWidget {
  const MainHome({Key? key}) : super(key: key);

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  String pro = "";
  String pro_name = "";
  // PrintController pm=PrintController();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getProfile();
    });
    super.initState();
  }

  getProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    pro = prefs.getString("prof_string")!;
    pro_name = prefs.getString("label_name")!;
    print("proofil = $pro");
    print("proofilNM = $pro_name");
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    print("width = ${size.width}");
    print("height = ${size.height}");
    return MaterialApp(
      home: Scaffold(backgroundColor: Color.fromARGB(255, 194, 235, 231),
        // appBar: AppBar(
        //   backgroundColor: Colors.green,
        //   actions: [
        //     Consumer<PrintController>(
        //         builder: (BuildContext context, PrintController value,
        //                 Widget? child) =>
        //             Row(
        //               children: [
        //                 Text(
        //                   pro_name.toString(),
        //                   style: TextStyle(fontSize: 18, color: Colors.white),
        //                 ),
        //                 IconButton(
        //                     onPressed: () {
        //                       // LoginDialog l=LoginDialog();
        //                       // l.dialogBuilder(context);
        //                       showDialog(
        //                         context: context,
        //                         builder: (BuildContext context) {
        //                           return LoginDialog();
        //                         },
        //                       );
        //                     },
        //                     icon: Icon(
        //                       Icons.edit,
        //                       color: Colors.red,
        //                     ))
        //               ],
        //             )),
        //   ],
        // ),
        body: Consumer<PrintController>(
          builder: (BuildContext context, PrintController value, Widget? child) {
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    InkWell(
                      child: Card(elevation: 4,shadowColor: Colors.black,
                        child: Container(
                          height: 100,
                          width: size.width / 1.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                        
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black87,
                                Color.fromARGB(255, 3, 141, 109),
                              ],
                              stops: [0.112, 0.789],
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      height: 35,
                                      width: 35,
                                      child: Image.asset(
                                        "assets/bluetooth.png",
                                        color: Colors.white,
                                      )),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  SizedBox(
                                    width: size.width / 1.6,
                                    child: Text(
                                      "CONNECT PRINTER",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 20),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BluetoothConnection(),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    InkWell(
                      child: Container(
                        height: 100,
                        width: size.width / 1.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.amber,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black87,
                              Color.fromARGB(255, 3, 141, 109),
                            ],
                            stops: [0.112, 0.789],
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                    height: 35,
                                    width: 35,
                                    child: Image.asset(
                                      "assets/print.png",
                                      color: Colors.white,
                                    )),
                                SizedBox(
                                  width: 15,
                                ),
                                SizedBox(
                                  width: size.width / 1.6,
                                  child: Text(
                                    "PRINT LABEL",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrintPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
