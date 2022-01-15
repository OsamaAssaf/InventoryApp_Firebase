import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:inventoryapp_firebase/modules/item.dart';
import 'package:http/http.dart' as http;

class Database with ChangeNotifier {
  String? _token;
  String? _userId;

  getAuthData(String? tok, String? id) {
    _token = tok;
    _userId = id;
    notifyListeners();
  }

  List<Item> itemList = [];

  Future<void> addItem(Item item) async {
    String url =
        'https://inventory-app-d018c-default-rtdb.firebaseio.com/users/$_userId.json';

    try {
      await http.post(Uri.parse(url),
          body: jsonEncode({
            'name': item.name,
            'description': item.description,
            'category': item.category,
            'quantity': item.quantity,
            'price': item.price,
            'imageUrl': item.imageUrl,
          }));
    } catch (e) {
      rethrow;
    }

    itemList.add(item);
    notifyListeners();
  }

  Future<void> updateData(Item item) async {
    String url =
        'https://inventory-app-d018c-default-rtdb.firebaseio.com/users/$_userId/${item.id}.json';

    try {
      await http.patch(Uri.parse(url),
          body: jsonEncode({
            'name': item.name,
            'description': item.description,
            'category': item.category,
            'quantity': item.quantity,
            'price': item.price,
            'imageUrl': item.imageUrl,
          }));
    } catch (e) {
      rethrow;
    }

    int itemIndex = itemList.indexWhere((element) => element.id == item.id);
    itemList[itemIndex] = item;
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    String url =
        'https://inventory-app-d018c-default-rtdb.firebaseio.com/users/$_userId/$id.json';

    try {
      await http.delete(Uri.parse(url));
    } catch (e) {
      rethrow;
    }

    int itemIndex = itemList.indexWhere((element) => element.id == id);
    itemList.removeAt(itemIndex);
    notifyListeners();
  }

  Future<void> deleteAllItem() async {
    String url =
        'https://inventory-app-d018c-default-rtdb.firebaseio.com/users/$_userId.json';
    try {
      await http.delete(Uri.parse(url));
    } catch (e) {
      rethrow;
    }
    clearItemList();
  }

  Future<void> getItems([String? category]) async {
    String url =
        'https://inventory-app-d018c-default-rtdb.firebaseio.com/users/$_userId.json?auth=$_token';
    try {
      http.Response response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);
      if (data == null) {
        notifyListeners();
        return;
      }
      List<Item> tempList = [];
      data.forEach((itemId, itemData) {
        tempList.add(Item(
          id: itemId,
          name: itemData['name'],
          description: itemData['description'],
          category: itemData['category'],
          quantity: itemData['quantity'],
          price: itemData['price'],
          imageUrl: itemData['imageUrl'],
        ));
      });

      if (category != null) {
        itemList =
            tempList.where((element) => element.category == category).toList();
      } else {
        itemList = tempList;
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void clearItemList() {
    itemList.clear();
    notifyListeners();
  }
}
