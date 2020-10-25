/* Page for entering queries to generate menu.
 */
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:jedzenioplanner/api/server.dart';
import 'package:jedzenioplanner/widgets/recipe_grid.dart';

class GeneratePage extends StatefulWidget {
  @override
  _GeneratePageState createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  int calories = 400;
  int meals = 2;
  List<dynamic> _cache = [];
  Future results;

  bool badRequest = false;

  Future<List<dynamic>> _getResults() async {
    badRequest = false;
    var res = await ServerApi.generateMenu(calories, meals);
    if(res == -1){
      badRequest = true;
      return null;
    }
    _cache = res;
    results = _cachedResults();
    return _cache;
  }

  Future<List<dynamic>> _cachedResults() async {
    return _cache;
  }

  @override
  void initState() {
    super.initState();
    results = _cachedResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Zaplanuj Menu"),
      ),
      body: Center(
          child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Column(
              children: [
                Text("Kaloryczność: $calories kcal"),
                Slider(
                  value: calories.toDouble(),
                  min: 100,
                  max: 20700,
                  divisions: ((1000-100)/50).round(),
                  label: "$calories kcal",
                  onChanged: (value) {
                    setState(() {
                      calories = value.round();
                    });
                  },
                ),
                Text("Ilość posiłków: $meals"),
                Slider(
                  value: meals.toDouble(),
                  min: 2,
                  max: 9,
                  divisions: (9-2),
                  label: meals.toString(),
                  onChanged: (value) {
                    setState(() {
                      meals = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FlatButton(
                        onPressed: () {
                          // update results on screen
                          setState(() {
                            results = _getResults();
                          });
                        },
                        child: Text("Zaplanuj")),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
              child: FutureBuilder(
                  future: results,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done)
                      // loading screen
                      return Center(
                        child: SpinKitCubeGrid(
                          color: Colors.blue,
                          size: 50.0,
                        ),
                      );

                    if(badRequest)
                      return Center(child: Text("Nie można wygenerować menu dla podanych parametrów :("));

                    if(snapshot.hasError)
                      // error screen
                      return Center(child: Text("Coś poszło nie tak X("));

                    // search results
                    List<dynamic> results = snapshot.data;
                    return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1 / 1.5,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 5.0,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          return RecipeGrid(recipe: results[i]['recipe'], id: i);
                        });
                  })),
        ],
      )),
    );
  }
}
