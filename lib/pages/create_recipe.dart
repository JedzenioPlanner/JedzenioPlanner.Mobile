/* Page for entering queries to search for recipes.
 */
import 'package:flutter/material.dart';

import 'package:jedzenioplanner/api/server.dart';
import 'package:jedzenioplanner/api/auth0.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateRecipePage extends StatefulWidget {
  @override
  _CreateRecipePageState createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  bool isBusy = false;
  bool isLoggedIn = false;
  String errorMessage;

  Future<void> checkLogin() async {
    setState(() {
      isBusy = true;
    });
    isLoggedIn = await AuthApi.isLoggedIn();
    setState(() {
      isBusy = false;
    });
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> loginAction() async {
    setState(() {
      isBusy = true;
      errorMessage = '';
    });

    try {
      final AuthorizationTokenResponse result =
          await AuthApi.appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AuthApi.AUTH0_CLIENT_ID,
          AuthApi.AUTH0_REDIRECT_URI,
          issuer: 'https://${AuthApi.AUTH0_DOMAIN}',
          scopes: ['openid', 'profile', 'offline_access', 'read:resource', 'read:connections'],
          // promptValues: ['login']
        ),
      );

      await AuthApi.secureStorage.write(key: 'id_token', value: result.idToken);
      await AuthApi.secureStorage
          .write(key: 'refresh_token', value: result.refreshToken);
      await AuthApi.secureStorage
          .write(key: 'access_token', value: result.accessToken);
      await AuthApi.secureStorage.write(
          key: 'token_exp_date',
          value: result.accessTokenExpirationDateTime.microsecondsSinceEpoch
              .toString());

      setState(() {
        isBusy = false;
        isLoggedIn = true;
      });
    } catch (e, s) {
      print('login error: $e - stack: $s');

      setState(() {
        isBusy = false;
        isLoggedIn = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dodaj swój własny przepis"),
      ),
      body: Center(
        child: isBusy
            ? CircularProgressIndicator()
            : isLoggedIn
                ? CreateRecipe()
                : Login(loginAction, errorMessage),
      ),
    );
  }
}

class Login extends StatelessWidget {
  final loginAction;
  final String loginError;

  const Login(this.loginAction, this.loginError);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("Musisz być zalogowany aby korzystać z tej funkcji."),
        SizedBox(height: 15),
        RaisedButton(
          onPressed: () {
            loginAction();
          },
          child: Text('Zaloguj się'),
        ),
        Text(loginError ?? ''),
      ],
    );
  }
}

class CreateRecipe extends StatefulWidget {
  @override
  _CreateRecipeState createState() => _CreateRecipeState();
}

class _CreateRecipeState extends State<CreateRecipe> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  bool isBusy = false;
  bool isLoggedIn = true;

  String name = "";
  String description = "";
  String pictureUrl = "";
  String picturePath = "";
  int calories = 100;
  List<String> ingredients = [];
  List<String> steps = [];
  String mealType = "Wybierz posiłek";

  bool pictureFailed = false; // whether pictured failed to upload or not
  bool serverFailed = false;
  bool success = false;

  Future getImage() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        picturePath = pickedFile.path;
      } else {
        picturePath = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            cacheExtent: double.infinity,
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  // title
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Nazwa",
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value.isEmpty) return "Wprowadź nazwę przepisu";
                      return null;
                    },
                    onSaved: (value) {
                      name = value;
                    },
                  ),
                  // image
                  Row(
                    children: [
                      FlatButton(
                        onPressed: getImage,
                        child: Text("Wybierz obrazek"),
                      ),
                      Flexible(
                          child: TextFormField(
                        key: Key(picturePath),
                        initialValue: (picturePath == ""
                            ? "Nie wybrano obrazka"
                            : "Wybrano obrazek"),
                        readOnly: true,
                        validator: (value) {
                          if (picturePath.isEmpty) return "Wybierz obrazek";
                          if (pictureFailed) return "Nie udało się przesłać obrazka";
                          return null;
                        },
                      )),
                    ],
                  ),
                  (picturePath == ""
                      ? Container()
                      : Image.file(File(picturePath))),
                  // mealType
                  DropdownButtonFormField(
                    value: '',
                    items: {
                      'Wybierz rodzaj posiłku': '',
                      'Śniadanie': 'breakfast',
                      'Obiad': 'lunch',
                      'Kolacja': 'dinner',
                      'Przekąska': 'snack',
                    }
                        .map<DropdownMenuItem<String>, String>((key, val) {
                          return MapEntry(
                              DropdownMenuItem<String>(
                                value: val,
                                child: Text(key),
                              ),
                              null);
                        })
                        .keys
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        mealType = value;
                      });
                    },
                    validator: (value) {
                      if (value == '') return "Wybierz rodzaj posiłku";
                      return null;
                    },
                    onSaved: (value) {
                      mealType = value;
                    },
                  ),
                  // description
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Opis",
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value.isEmpty)
                        return "Podaj krótki opis swojego przepisu";
                      return null;
                    },
                    onSaved: (value) {
                      description = value;
                    },
                  ),
                  // calories
                  SizedBox(height: 15),
                  Text("Kalorie: $calories kcal"),
                  Slider(
                    value: calories.toDouble(),
                    min: 100,
                    max: 20700,
                    divisions: ((1000 - 100) / 50).round(),
                    label: "$calories kcal",
                    onChanged: (value) {
                      setState(() {
                        calories = value.round();
                      });
                    },
                  ),
                  TextFormField(
                    initialValue: "Składniki",
                    readOnly: true,
                    validator: (value) {
                      if (ingredients.length == 0)
                        return "Podaj przynajmniej jeden składnik";
                      return null;
                    },
                  ),
                ]),
              ),
              // ingredients
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == ingredients.length) {
                      // add next item button
                      return ListTile(
                        title: FlatButton(
                          onPressed: () {
                            setState(() {
                              _formKey.currentState.save();
                              ingredients.add("");
                            });
                          },
                          child: Icon(Icons.add),
                        ),
                      );
                    }
                    // normal tile
                    return ListTile(
                      title: TextFormField(
                        key: Key(ingredients.length.toString()),
                        decoration: InputDecoration(
                          labelText: "Składnik ${index + 1}",
                        ),
                        initialValue: ingredients[index],
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value.isEmpty) return "Podaj składnik";
                          return null;
                        },
                        onSaved: (value) {
                          ingredients[index] = value;
                        },
                      ),
                      trailing: FlatButton(
                        onPressed: () {
                          setState(() {
                            _formKey.currentState.save();
                            ingredients.removeAt(index);
                          });
                        },
                        child: Icon(Icons.remove),
                      ),
                    );
                  },
                  childCount: ingredients.length + 1,
                ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                TextFormField(
                  initialValue: "Kroki",
                  readOnly: true,
                  validator: (value) {
                    if (steps.length == 0) return "Podaj przynajmniej jeden krok";
                    return null;
                  },
                ),
              ])),
              // steps
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == steps.length) {
                      // add next item button
                      return ListTile(
                        title: FlatButton(
                          onPressed: () {
                            setState(() {
                              _formKey.currentState.save();
                              steps.add("");
                            });
                          },
                          child: Icon(Icons.add),
                        ),
                      );
                    }
                    // normal tile
                    return ListTile(
                      title: TextFormField(
                        key: Key(steps.length.toString()),
                        decoration: InputDecoration(
                          labelText: "Krok ${index + 1}",
                        ),
                        initialValue: steps[index],
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value.isEmpty) return "Podaj krok";
                          return null;
                        },
                        onSaved: (value) {
                          steps[index] = value;
                        },
                      ),
                      trailing: FlatButton(
                        onPressed: () {
                          setState(() {
                            _formKey.currentState.save();
                            steps.removeAt(index);
                          });
                        },
                        child: Icon(Icons.remove),
                      ),
                    );
                  },
                  childCount: steps.length + 1,
                ),
              ),
              SliverList(
                  delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // submit button
                    (isLoggedIn
                        ? (!serverFailed
                            ? (!success ? Container() : Text(
                                "Sukces!",
                                style: TextStyle(color: Colors.green),
                              ))
                            : Text(
                                "Coś poszło nie tak X(",
                                style: TextStyle(color: Colors.red),
                              ))
                        : Text(
                            "Nie jesteś zalogowany",
                            style: TextStyle(color: Colors.red),
                          )),
                    (isBusy
                        ? Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator())
                        : FlatButton(
                            onPressed: () async {
                              pictureFailed = false;
                              serverFailed = false;
                              success = false;
                              if (!_formKey.currentState.validate()) return;
                              // post recipe and update results on screen
                              setState(() {
                                isBusy = true;
                              });

                              isLoggedIn =
                                  await AuthApi.updateAccessTokenSilently();
                              if (!isLoggedIn) {
                                setState(() {
                                  isBusy = false;
                                });
                                return;
                              }

                              pictureUrl =
                                  await ServerApi.postImage(picturePath);
                              //pictureUrl = "https://thegreenloot.com/wp-content/uploads/2018/09/vegan-meal-prep-recipes-81.jpg";
                              if (pictureUrl == null) {
                                setState(() {
                                  pictureFailed = true;
                                  serverFailed = true;
                                  isBusy = false;
                                  _formKey.currentState.validate();
                                });
                                return;
                              }

                              _formKey.currentState.save();
                              serverFailed = !await ServerApi.postRecipe(
                                name: name,
                                description: description,
                                pictureUrl: pictureUrl,
                                calories: calories,
                                ingredients: ingredients,
                                steps: steps,
                                mealTypes: [mealType],
                              );

                              success = !serverFailed;

                              setState(() {
                                isBusy = false;
                              });
                            },
                            child: Text("Prześlij"))),
                  ],
                ),
              ])),
            ],
          ),
        ),
      ),
    );
  }
}
