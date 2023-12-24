import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Color.fromRGBO(3, 3, 3, 1.0),
      statusBarBrightness: Brightness.light));
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  runApp(MaterialApp(
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Connectivity _connectivity = Connectivity();

  bool isLoading = true;
  bool hideui = true;

  @override
  void initState() {
    super.initState();
    final FirebaseAnalytics analytics = FirebaseAnalytics.instance;



    _connectivity.onConnectivityChanged.listen((event) {
      if (event == ConnectivityResult.none) {
        setState(() {
          hideui = true;
        });
      } else {
        setState(() {
          hideui = false;
        });
      }
    });
  }

  int selectedIndex = 0;
  final List<String> webviewList = [
    "http://www.vierlingsbeek-bergen.nl/",
    "https://tegoed.vierlingsbeek-bergen.nl/account/login",
    "https://tegoed.vierlingsbeek-bergen.nl/opwaarderen?action=deposit",
    "http://www.vierlingsbeek-bergen.nl/tarieven-abbonementen"
  ];
  late WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    int x = 0;
    String url = "https://www.ilovevierlingsbeekgroeningen.nl";
    String email = 'subject';
    String Whatsapp = 'whatsapp';
    String Linkedin = 'linkedin';
    String Phonenumber = '614443390';
    String pubble = "pubble";
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            unselectedItemColor: Colors.black,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.rightToBracket),
                label: "Inloggen",
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.arrowUp),
                label: "Opwaarderen",
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.list),
                label: "Dienstregeling",
              ),
            ],
            currentIndex: selectedIndex,
            selectedItemColor: Color(0xff15a2a2),
            onTap: (i) {
              webViewController.loadUrl(webviewList[i]);
              setState(() => selectedIndex = i);
            },
          ),
          body: Stack(children: <Widget>[
            SafeArea(
              child: hideui
                  ? Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/disconnect.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : WillPopScope(
                onWillPop: () async {
                  if (await webViewController.canGoBack()) {
                    webViewController.goBack();
                    return false;
                  } else {
                    return true;
                  }
                },
                child: WebView(
                  initialUrl: webviewList[selectedIndex],
                  onWebViewCreated: (c) {
                    webViewController = c;
                  },
                  javascriptMode: JavascriptMode.unrestricted,
                  onPageFinished: (finish) {
                    setState(() {
                      isLoading = false;
                    });
                  },
                  navigationDelegate: (NavigationRequest request) async {

                    if (request.url.contains(email) ||
                        request.url.contains("mailto")) {
                      String emailurl = request.url;
                      _launchURL(emailurl);
                      return NavigationDecision.prevent;
                    }
                    if (request.url.contains(Whatsapp)) {
                      String shareUrlwrong = request.url;
                      String shareUrl = shareUrlwrong.substring(31);
                      Share.share(
                          "Ik heb een heel leuk bericht gelezen op $shareUrl");
                      return NavigationDecision.prevent;
                    }
                    if (request.url.contains(Linkedin)) {
                      FirebaseAnalytics.instance
                          .logEvent(name: "linkedin");
                      String Linkedinurl = request.url;
                      _launchURL(Linkedinurl);
                      return NavigationDecision.prevent;
                    }
                    if (request.url.contains(Phonenumber)) {
                      String Phonenumberurl = request.url;
                      _launchURL(Phonenumberurl);
                      return NavigationDecision.prevent;
                    }
                    if (!request.url.contains("vierlingsbeek")) {
                      String otherurl = request.url;
                      _launchURL(otherurl);
                      return NavigationDecision.prevent;
                    }
                    return NavigationDecision.navigate;
                  },
                ),
              ),
            ),
            isLoading ? Center( child: CircularProgressIndicator(),)
                : Stack(),
          ]),
        ));
  }

  _launchURL(String url) async {
    String realurl = url;
    launch(realurl);
  }
}