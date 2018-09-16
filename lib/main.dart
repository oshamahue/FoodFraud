import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:food_report/constants.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';

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
  AnimatedList animatedList;
  ListModel _list;
  List<Food> foodList = List<Food>();
  SearchBar searchBar;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    // Demonstrates configuring to the database using a file
    // Demonstrates configuring the database directly
    initDatabase();

    _list = ListModel(
      listKey: _listKey,
      removedItemBuilder: _buildItem,
    );

    searchBar = new SearchBar(
        inBar: false,
        buildDefaultAppBar: buildAppBar,
        setState: setState,
        onChanged: _filterList,
        onClosed: () {
          _filterList("");
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
      appBar: searchBar.build(context),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new AnimatedList(
              key: _listKey,
              itemBuilder: _buildItem,
            ),
          ),
        ],
      ),
    );
  }

  void initDatabase() {
    final FirebaseDatabase database = new FirebaseDatabase(app: widget.app);
    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    _messagesRef = database.reference().child('foods');
    _messagesRef.once().then((DataSnapshot snapshot) {
      setState(() {});
      List<dynamic> values = snapshot.value;
      values.forEach((value) {
        try {
          var food = Food(
              value["company"].toString() ?? "",
              value["brand"].toString() ?? "",
              value["product"].toString() ?? "",
              value["fraud"].toString() ?? "",
              value["date"].toString() ?? "",
              value["address"].toString() ?? "");
          _list.add(food);
          foodList.add(food);
        } catch (e) {
          print(e);
        }
      });
    });
  }

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
        title: const Text(title),
        actions: [searchBar.getSearchAction(context)]);
  }

  void _filterList(String filter) {
    if (filter.length <= 2) {
      foodList.forEach((food) {
        if (_list.indexOf(food) < 0) {
          _list.add(food);
        }
      });
    } else {
      foodList.forEach((food) {
        if (food.address.toLowerCase().contains(filter.toLowerCase()) ||
            food.brand.toLowerCase().contains(filter.toLowerCase()) ||
            food.company.toLowerCase().contains(filter.toLowerCase()) ||
            food.fraud.toLowerCase().contains(filter.toLowerCase()) ||
            food.product.toLowerCase().contains(filter.toLowerCase())) {
          if (_list.indexOf(food) < 0) {
            _list.add(food);
          }
        } else {
          if (_list.indexOf(food) >= 0) {
            _list.removeAt(_list.indexOf(food));
          }
        }
      });
    }
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    Food food = _list[index];
    return new Container(
        decoration:
            new BoxDecoration(border: new Border.all(color: Colors.blueAccent)),
        margin: new EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        padding: EdgeInsets.all(4.0),
        child: Row(children: [
          Expanded(
              child: Column(
            children: <Widget>[
              new ListItemText("Firma: ", food.company, 2),
              new ListItemText("Marka: ", food.brand, 1),
              new ListItemText("Ürun: ", food.product, 1),
              new ListItemText("Hile: ", food.fraud, 1),
              new ListItemText("Yayınlanma Tarihi: ", food.date, 1),
              new ListItemText("Adres: ", food.address, 2),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
          ))
        ]));
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

class ListModel {
  ListModel({
    @required this.listKey,
    @required this.removedItemBuilder,
  })  : assert(listKey != null),
        _items = List<Food>();

  final GlobalKey<AnimatedListState> listKey;
  final dynamic removedItemBuilder;
  final List<Food> _items;

  AnimatedListState get _animatedList => listKey.currentState;

  void add(Food item) {
    insert(length, item);
  }

  void insert(int index, Food item) {
    _items.insert(index, item);
    _animatedList.insertItem(index);
  }

  Food removeAt(int index) {
    final Food removedItem = _items.removeAt(index);
    if (removedItem != null) {
      _animatedList.removeItem(
        index,
        (context, animation) => new Container(),
      );
    }
    return removedItem;
  }

  int get length => _items.length;

  Food operator [](int index) => _items[index];

  int indexOf(Food item) => _items.indexOf(item);
}

class Food {
  String company, brand, product, fraud, date, address;

  Food(this.company, this.brand, this.product, this.fraud, this.date,
      this.address);
}
