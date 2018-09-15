import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:food_report/constants.dart';

const String title = 'Hileli ürünler';

void main() async {
  final FirebaseApp app = await FirebaseApp.configure(
    name: "food_report",
    options: Platform.isIOS
        ? const FirebaseOptions(
            googleAppID: iosGoogleAppId,
            gcmSenderID: iosGcmSenderId,
            databaseURL: firebaseDbURL,
          )
        : const FirebaseOptions(
            googleAppID: androidGoogleAppId,
            apiKey: androidGoogleApiKey,
            databaseURL: firebaseDbURL,
          ),
  );

  runApp(new MaterialApp(
    title: title,
    home: new FoodFraudListPage(app: app),
  ));
}

class FoodFraudListPage extends StatefulWidget {
  FoodFraudListPage({this.app});

  final FirebaseApp app;

  @override
  _FoodFraudState createState() => new _FoodFraudState();
}

class _FoodFraudState extends State<FoodFraudListPage> {
  DatabaseReference _messagesRef;
  StreamSubscription<Event> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    // Demonstrates configuring to the database using a file
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = new FirebaseDatabase(app: widget.app);
    _messagesRef = database.reference().child('foods');
    database.reference().child('counter').once().then((DataSnapshot snapshot) {
      print('Connected to second database and read ${snapshot.value}');
    });
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _messagesRef.limitToLast(10).onChildAdded.listen((Event event) {
      print('Child added: ${event.snapshot.value}');
    }, onError: (Object o) {
      final DatabaseError error = o;
      print('Error: ${error.code} ${error.message}');
    });
  }

  @override
  void dispose() {
    super.dispose();
    _messagesSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text(title),
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new FirebaseAnimatedList(
              key: new ValueKey<bool>(true),
              query: _messagesRef,
              reverse: false,
              sort: (DataSnapshot a, DataSnapshot b) => b.key.compareTo(a.key),
              itemBuilder: _buildItem,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, DataSnapshot snapshot,
      Animation<double> animation, int index) {
    return new SizeTransition(
        sizeFactor: animation,
        child: new Container(
            decoration: new BoxDecoration(
                border: new Border.all(color: Colors.blueAccent)),
            margin: new EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            padding: EdgeInsets.all(4.0),
            child: Row(children: [
              Expanded(
                  child: Column(
                children: <Widget>[
                  new ListItemText(
                      "Firma: ", snapshot.value["company"].toString(), 2),
                  new ListItemText(
                      "Marka: ", snapshot.value["brand"].toString(), 1),
                  new ListItemText(
                      "Ürun: ", snapshot.value["product"].toString(), 1),
                  new ListItemText(
                      "Hile: ", snapshot.value["fraud"].toString(), 1),
                  new ListItemText("Yayınlanma Tarihi: ",
                      snapshot.value["date"].toString(), 1),
                  new ListItemText(
                      "Adres: ", snapshot.value["address"].toString(), 2),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
              ))
            ])));
  }
}

class ListItemText extends RichText {
  ListItemText(String title, String description, int maxLines)
      : super(
            text: new TextSpan(
              style: new TextStyle(
                fontSize: 14.0,
                color: Colors.black,
              ),
              children: <TextSpan>[
                new TextSpan(
                    text: title,
                    style: new TextStyle(fontWeight: FontWeight.bold)),
                new TextSpan(text: description),
              ],
            ),
            maxLines: maxLines,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis);
}
