import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:inventory_app_firebase/controllers/auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  AuthScreenState createState() => AuthScreenState();
}

enum AuthMode {
  login,
  signUp,
}

class AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? email;
  String? password;

  AuthMode _authMode = AuthMode.login;

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Timer? _timer;

  void _authenticate() async {
    try {
      if (_authMode == AuthMode.login) {
        setState(() {
          _isLoading = true;
        });
        await context.read<Auth>().login(email!, password!);
      } else {
        setState(() {
          _isLoading = true;
        });
        await context.read<Auth>().signUp(email!, password!);
        if (context.mounted) {
          await context.read<Auth>().sendEmailVerification();
        }
        _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          if (context.read<Auth>().isVerified == true) {
            timer.cancel();
          }
          await context.read<Auth>().getUserData();
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      String errorMessage = 'Failed';
      if (error.toString() == 'EMAIL_EXISTS') {
        errorMessage = 'The email address is already in use by another account.';
      } else if (error.toString() == 'EMAIL_NOT_FOUND') {
        errorMessage = 'The email address does not exists.';
      } else if (error.toString() == 'OPERATION_NOT_ALLOWED') {
        errorMessage = 'Password sign-in is disabled for this project.';
      } else if (error.toString() == 'TOO_MANY_ATTEMPTS_TRY_LATER') {
        errorMessage =
            'We have blocked all requests from this device due to unusual activity. Try again later.';
      } else if (error.toString() == 'EMAIL_NOT_FOUND') {
        errorMessage =
            'There is no user record corresponding to this identifier. The user may have been deleted.';
      } else if (error.toString() == 'INVALID_PASSWORD') {
        errorMessage = 'The password is invalid or the user does not have a password.';
      } else if (error.toString() == 'USER_DISABLED') {
        errorMessage = 'The user account has been disabled by an administrator.';
      }
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('An error occurred!'),
            content: Text(errorMessage),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xffd4bff9),
              Color(0xff6750a4),
              Color(0xff625b71),
            ],
          ),
        ),
        child: Center(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(_authMode == AuthMode.login ? 'Login' : 'Sign Up'),
                    TextFormField(
                      decoration: const InputDecoration(label: Text('email')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        } else if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        setState(() {
                          email = newValue;
                        });
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(label: Text('password')),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        } else if (value.length < 6) {
                          return 'Please enter a password more than 6 characters';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        setState(() {
                          password = newValue;
                        });
                      },
                    ),
                    if (_authMode == AuthMode.signUp)
                      TextFormField(
                        decoration: const InputDecoration(label: Text('confirm password')),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords not match';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          setState(() {
                            password = newValue;
                          });
                        },
                      ),
                    ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            _authenticate();
                          }
                        },
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(_authMode == AuthMode.login ? 'Login' : 'Sign Up')),
                    if (!_isLoading)
                      TextButton(
                          onPressed: () {
                            setState(() {
                              _authMode == AuthMode.login
                                  ? _authMode = AuthMode.signUp
                                  : _authMode = AuthMode.login;
                            });
                          },
                          child: const Text(
                            'Change',
                            style: TextStyle(color: Colors.black),
                          )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
