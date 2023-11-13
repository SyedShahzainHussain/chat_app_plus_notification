import 'dart:io';
import 'dart:typed_data';

import 'package:chat_app/utils/utils.dart';
import 'package:chat_app/viewmodel/uthenticate_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  String email = "";
  String username = "";
  String password = "";
  File? image;
  bool isLogin = false;
  void save() async {
    final validate = _form.currentState!.validate();
    if (!validate) {
      return;
    }
    FocusScope.of(context).unfocus();
    _form.currentState!.save();
    
    if (isLogin) {
      context.read<AuthenticatedViewModel>().logIn(email, password, context);
    } else {
      if (image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pick An Image")));
      return;
    }
      context
          .read<AuthenticatedViewModel>()
          .signUp(email, password, username, image!, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    if(!isLogin)  CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        backgroundImage:
                            image == null ? null : FileImage(image!),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                     if(!isLogin) ElevatedButton.icon(
                          label: const Text("Pick Image"),
                          onPressed: () async {
                            image = await Utils.pickImage();
                            setState(() {});
                          },
                          icon: const Icon(Icons.camera_alt)),
                      TextFormField(
                          key: const ValueKey("email"),
                          onSaved: (newValue) {
                            email = newValue!;
                          },
                          validator: (value) {
                            if (value!.isEmpty || !value.contains("@")) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email Address",
                          )),
                      if (!isLogin)
                        TextFormField(
                            key: const ValueKey("username"),
                            onSaved: (newValue) {
                              username = newValue!;
                            },
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please enter a username";
                              }
                              return null;
                            },
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: "User Name",
                            )),
                      TextFormField(
                          key: const ValueKey("passwords"),
                          obscureText: true,
                          onSaved: (newValue) {
                            password = newValue!;
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter a password";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: "Password ",
                          )),
                      const SizedBox(
                        height: 12,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          save();
                        },
                        child: context.watch<AuthenticatedViewModel>().isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.deepPurpleAccent,
                              )
                            : isLogin
                                ? const Text("Log In")
                                : const Text("Sign Up"),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                isLogin = !isLogin;
                              });
                            },
                            child: Text(
                              isLogin ? " Sign Up" : " Log In",
                              style: const TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
