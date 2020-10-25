/* Show all recipes (paginated).
 */
import 'package:flutter/material.dart';

import 'package:jedzenioplanner/api/server.dart';
import 'package:jedzenioplanner/widgets/recipe_grid.dart';

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int page = -1;
  bool isLoading = false;

  List<dynamic> recipes = [];

  @override
  void initState() {
    super.initState();
    isLoading = true;
    _loadData();
  }

  Future _loadData() async {
    page++;
    print("load page $page");
    // update data and loading status
    recipes.addAll(await ServerApi.listAll(page));
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Odkrywaj"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!isLoading &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                  _loadData();
                  // start loading data
                  setState(() {
                    isLoading = true;
                  });
                }
              },
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1 / 1.5,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 5.0,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  return RecipeGrid(recipe: recipes[index], id: index);
                },
              ),
            ),
          ),
          Container(
            height: isLoading ? 50.0 : 0,
            color: Colors.transparent,
            child: Center(
              child: new CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
