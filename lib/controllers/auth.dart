import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String? _token;
  String? _userId;
  DateTime? _expiryDate;

  Timer? _authTimer;

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  Future<bool> tryAutoLogin() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey('userInfo')) {
      return false;
    }
    Map<String, dynamic> userInfo =
        jsonDecode(_prefs.getString('userInfo')!) as Map<String, dynamic>;

    final DateTime expiryDate = DateTime.parse(userInfo['expiryDate']);
    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = userInfo['token'];
    _userId = userInfo['userId'];
    _expiryDate = expiryDate;

    notifyListeners();
    autoLogout();

    return true;
  }

  Future<void> _authenticate(
      String email, String password, String method) async {
    String url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$method?key=AIzaSyAT2ABNRydBc9-yveTtn33B6g9Fue0H0WI';

    try {
      http.Response response = await http.post(Uri.parse(url),
          body: jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true
          }));

      final responseData = jsonDecode(response.body);
      if (responseData['error'] != null) {
        throw responseData['error']['message'];
      }

      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now()
          .add(Duration(seconds: int.parse(responseData['expiresIn'])));

      autoLogout();
      notifyListeners();

      SharedPreferences _prefs = await SharedPreferences.getInstance();

      String userInfo = jsonEncode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate!.toIso8601String()
      });

      _prefs.setString('userInfo', userInfo);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    await _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    await _authenticate(email, password, 'signInWithPassword');
  }

  void logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }

    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.remove('userInfo');

    notifyListeners();
  }

  void autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final int _timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: _timeToExpiry), logout);
  }
}
