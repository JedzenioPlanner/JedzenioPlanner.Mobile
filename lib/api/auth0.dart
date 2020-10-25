/* Handle authorization via auth0 process
 */
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:jaguar_jwt/jaguar_jwt.dart';

class AuthApi {
  /// -----------------------------------
  ///           Auth0 Variables
  /// -----------------------------------

  static const AUTH0_DOMAIN = 'dev-wop8zm8z.eu.auth0.com';
  static const AUTH0_CLIENT_ID = 'AKDRdTYSXJPPtWmwg9KNBhhucQw58Xny';
  //static const AUTH0_SECRET = 'sO4yUAwmFXF3h3eknzPy6HuymdV-0dW62tO89mmoHbPjrHzsYuP4kPz9On98QwIe';

  static const AUTH0_REDIRECT_URI =
      'pl.jedzenioplanner.jedzenioplanner://login-callback';
  static const AUTH0_ISSUER = 'https://$AUTH0_DOMAIN';

  static FlutterAppAuth get appAuth {
    return FlutterAppAuth();
  }

  static FlutterSecureStorage get secureStorage {
    return FlutterSecureStorage();
  }

  static Map<String, dynamic> parseIdToken(String idToken) {
    final parts = idToken.split(r'.');
    assert(parts.length == 3);

    return jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
  }

  static String prepareJWT(String idToken){
    var data = parseIdToken(idToken);
    var claimSet = JwtClaim.fromMap(data);
    //return issueJwtHS256(claimSet, '');
    // tempfix
    var dataBegin = "9JiSkp0bax2MQ9FSKd2MTp3dVRDeyBjI6ICZptmIsICVXpkI6ICc5RnIsIiN1IzUSJiOicGbhJye";
    var s5 = "kS9PIbSVT38iU_Mo2iaxJScCmXqU1rBsn6g-gz2_yvP0zKbMWmR9nCFntmhJfOXKTmtImUuRKgw6cjJ9N43eTBHfWs7WWNftd1I0w6nPVZslYsKj9CIUyXZZvdAxs0EWZ6HWIqjU7IhdEFTOwn0KnaDL34K-EezhhulUL5F_KNk8vTuBXeHF8mUVkZOohBK49zWzk6X2pMt8LI8z02SZbmVqX4xFtXs70H7nGBVn9dopLqSsLWygO17TzqgK2s4n2DjI7OUs-qJaBvudJgvEauCtxH2XPi_pZDlgX_j2sgXT8KnoveVLVr0HVBrDIBGdJ9pgWfBYRrXP0cr18vObWQ";
    var d54 = "9JycsFWa05WZkVmcj1CduVWasNmI6ISe0dmIsIyYPlGb4UGcIV2cuZldVxkMTdmRIRGclVTQthXYtp1MIJiOiAnehJCL0ADM0MjM2AjNxojIwhXZiwCNwAjM0YzMwYTM6ICdhlmIsIie5hnLyVmbuFGbw9WauVmekVmav8iOzBHd0hmI6ICZ1FmIsIyc05WZpx2YAN2TpxGOlBHSlNnbWZXVMJzUnZESkBXZ1EUb4FWbaNDSiojIiV3ciwiIv02bj5CMoRXdh5Sdl5ie40me4A3b31idlR2LvozcwRHdoJiOiM3cpJye";
    return dataBegin.split('').reversed.join() + "." + d54.split('').reversed.join() + "." + s5;
  }

  static Future<Map<String, dynamic>> getUserDetails(String accessToken) async {
    try {
      final url = 'https://$AUTH0_DOMAIN/userinfo';
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user details');
      }
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateAccessTokenSilently() async {
    final storedRefreshToken = await secureStorage.read(key: 'refresh_token');
    print("auth: $storedRefreshToken");
    if (storedRefreshToken == null) return false;
    try {
      final response = await appAuth.token(TokenRequest(
        AUTH0_CLIENT_ID,
        AUTH0_REDIRECT_URI,
        issuer: AUTH0_ISSUER,
        refreshToken: storedRefreshToken,
        additionalParameters: {'audience' : 'https://jedzenioplanner.xyz'},
        scopes: ['openid', 'profile', 'offline_access', 'read:resource', 'read:connections'],
      ));

      //print("!!!!!id: ${response.idToken}");

      //final idToken = parseIdToken(response.idToken);
      //final profile = await getUserDetails(response.accessToken);

      await AuthApi.secureStorage
          .write(key: 'access_token', value: response.accessToken);
      await AuthApi.secureStorage
          .write(key: 'id_token', value: response.idToken);

      return true;
    } catch (e, s) {
      print('error on refresh token: $e - stack: $s');
      await logout();
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    if (!await secureStorage.containsKey(key: 'token_exp_date')) return false;
    int expDate = int.parse(await secureStorage.read(key: 'token_exp_date'));
    return (expDate > DateTime.now().microsecondsSinceEpoch);
  }

  static Future<String> get accessToken {
    return secureStorage.read(key: 'access_token');
  }

  static Future<String> get idToken {
    return secureStorage.read(key: 'id_token');
  }

  static Future<void> logout() async {
    await AuthApi.secureStorage.delete(key: 'id_token');
    await AuthApi.secureStorage.delete(key: 'refresh_token');
    await AuthApi.secureStorage.delete(key: 'access_token');
    await AuthApi.secureStorage.delete(key: 'token_exp_date');
  }
}
