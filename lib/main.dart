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

    String firma = snapshot.value["company"].toString();
    String marka = snapshot.value["brand"].toString();
    String urun = snapshot.value["product"].toString();
    String madde = snapshot.value["fraud"].toString();
    String tarih = snapshot.value["date"].toString();
    String adres = snapshot.value["address"].toString();

    return new SizeTransition(
        sizeFactor: animation,
        child:
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: new Card(
            elevation: 4.0,
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                 ListTile(
                   leading: const Icon(Icons.branding_watermark),
                   title:  Text(
                       marka,
                       style: new TextStyle(fontWeight: FontWeight.bold),
                   ),
                 ),
                 ListTile(
                   leading: const Icon(Icons.remove_shopping_cart),
                   title:  Text(
                     urun,
                     style: new TextStyle(fontWeight: FontWeight.bold),
                   ),
                 ),
                 ListTile(
                   leading: const Icon(Icons.home),
                   title:  Text(firma),
                 ),
                 ListTile(
                   leading: const Icon(Icons.healing),
                   title:  Text(madde),
                 ),
                 ListTile(
                   leading: const Icon(Icons.event),
                   title:  Text(tarih),
                 ),
                 ListTile(
                   leading: const Icon(Icons.my_location),
                   title:  Text(adres),
                 ),

                new ButtonTheme.bar( // make buttons use the appropriate styles for cards
                  child: new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        child: const Text('MAP'),
                        onPressed: () { /* ... */ },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
