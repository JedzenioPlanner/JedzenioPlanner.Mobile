/* Get and send data to server
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import 'package:jedzenioplanner/api/auth0.dart';

class AppException implements Exception {
  final _message;
  final _prefix;

  AppException([this._message, this._prefix]);

  String toString() {
    return "$_prefix$_message";
  }
}

class ServerException extends AppException {
  ServerException([String message]) : super(message, "Server error: ");
}

class ServerApi {
  static String serverEndpoint =
      "https://jedzenioplanner.bazik.xyz/api";

  static int paginationCount = 12; // how many recipes per page in listing

  static Future<List<dynamic>> search(int cal) async {
    // request recipes on server based on calories and preferences
    if (cal < 0) return [];

    var request = "$serverEndpoint/single?calories=$cal";
    var r = await http.get(request);
    if (r.statusCode != 200) {
      throw ServerException("${r.statusCode}");
    }

    return jsonDecode(r.body);
    //return List.generate(cal, (index) => json.decode(sampleRequest));
  }

  static Future<dynamic> getRecipe(String id) async {
    // return data about single recipe by id
    var request = "$serverEndpoint/recipes/$id";
    var r = await http.get(request);
    if(r.statusCode == 400){
      return -1;
    }
    if (r.statusCode != 200) {
      throw ServerException("${r.statusCode}");
    }

    return jsonDecode(r.body);
  }

  static Future<List<dynamic>> listAll(int page) async {
    // return list of all recipes from database
    var request = "$serverEndpoint/recipes?page=$page&amount=$paginationCount";
    var r = await http.get(request);
    if (r.statusCode != 200) {
      throw ServerException("${r.statusCode}");
    }

    return jsonDecode(r.body);
  }

  static Future<dynamic> generateMenu(int cal, int mealCount) async {
    var request =
        "$serverEndpoint/menu?caloriesTarget=$cal&mealsAmount=$mealCount";
    var r = await http.get(request);
    if(r.statusCode == 400){
      return -1;
    }
    if (r.statusCode != 200) {
      throw ServerException("${r.statusCode}");
    }

    //print(jsonDecode(r.body)['mealPlanRows'][0]);

    return jsonDecode(r.body)['mealPlanRows'];
  }

  static Future<String> postImage(String path) async {
    // get access token
    if (!await AuthApi.isLoggedIn()) return null;
    String token = await AuthApi.idToken;
    token = AuthApi.prepareJWT(token);
    Dio dio = new Dio();
    dio.options.headers["Authorization"] = "Bearer $token";

    var request = "$serverEndpoint/recipes/pictures";

    String fileName = path.split('/').last;
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(path, filename: fileName),
    });

    var response;
    try {
      response = await dio.post(
        request,
        data: formData,
        onReceiveProgress: (count, total) => print("${count / total}%"),
      );
    } catch (e) {
      print("Error image: $e");
      return null;
    }

    if (response.statusCode != 200) {
      print("Response error: ${response.body}");
      return null;
    }

    print("$serverEndpoint/recipes/pictures/${response.data}");

    return "$serverEndpoint/recipes/pictures/${response.data}";
  }

  static Future<bool> postRecipe({
    String name,
    String description,
    String pictureUrl,
    int calories,
    List<String> ingredients,
    List<String> steps,
    List<String> mealTypes,
  }) async {
    print("Sending recipe");
    // get access token
    if (!await AuthApi.isLoggedIn()) return false;
    String token = await AuthApi.idToken;
    token = AuthApi.prepareJWT(token);

    // create request
    var request = "$serverEndpoint/recipes";
    var recipe = {
      "name": name,
      "description": description,
      "pictureUrl": pictureUrl,
      "calories": calories,
      "ingredients": ingredients,
      "steps": steps,
      "mealTypes": mealTypes,
    };

    print("Made $token");

    try {
      var r = await http.post(
        request,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(recipe),
      );
      print("Sent: ${r.statusCode} : ${r.body}");

      return r.statusCode == 200;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
}
