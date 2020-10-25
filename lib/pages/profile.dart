/* Show some user data (TBD)
 */
import 'package:flutter/material.dart';

import 'package:jedzenioplanner/api/auth0.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isBusy = false;
  bool isLoggedIn = false;
  String errorMessage;
  String name;
  String picture;

  Future<void> checkLogin() async {
    setState(() {
      isBusy = true;
    });
    isLoggedIn = await AuthApi.updateAccessTokenSilently();
    if(isLoggedIn){
      // load user data
      name = AuthApi.parseIdToken(await AuthApi.idToken)['name'];
      var data = await AuthApi.getUserDetails(await AuthApi.accessToken);
      if(data == null){
        setState(() {
          isLoggedIn = false;
          isBusy = false;
        });
        return;
      }
      picture = data['picture'];
    }
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

      final idToken = AuthApi.parseIdToken(result.idToken);
      final profile = await AuthApi.getUserDetails(result.accessToken);

      await AuthApi.secureStorage
          .write(key: 'id_token', value: result.idToken); 
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
        name = idToken['name'];
        picture = profile['picture'];
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

  void logoutAction() async {
    await AuthApi.logout();
    setState(() {
      isLoggedIn = false;
      isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Twój Profil"),
      ),
      body: Center(
        child: isBusy
            ? CircularProgressIndicator()
            : isLoggedIn
                ? Profile(logoutAction, name, picture)
                : Login(loginAction, errorMessage),
      ),
    );
  }
}

class Profile extends StatelessWidget {
  final logoutAction;
  final String name;
  final String picture;

  Profile(this.logoutAction, this.name, this.picture);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 4.0),
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.fill,
              image: NetworkImage(picture ?? ''),
            ),
          ),
        ),
        SizedBox(height: 24.0),
        Text('Imię: $name'),
        SizedBox(height: 48.0),
        RaisedButton(
          onPressed: () {
            logoutAction();
          },
          child: Text('Wyloguj się'),
        ),
      ],
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
        Text("Nie jesteś zalogowany."),
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
