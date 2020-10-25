/* Page visible when opened any recipe,
 * it contains all data about recipe
 */
import 'package:flutter/material.dart';

import 'package:jedzenioplanner/widgets/circular_clipper.dart';

import 'package:jedzenioplanner/api/translator.dart';
import 'package:jedzenioplanner/api/database.dart';

class RecipePage extends StatefulWidget {
  final dynamic recipe;
  final String heroTag;

  RecipePage({@required this.recipe, this.heroTag = ""});

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  dynamic recipe;
  String heroTag;
  bool isFav = false;

  Future<void> checkFav() async {
    isFav = await DbApi.isFavourite(recipe['id']);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    recipe = widget.recipe;
    heroTag = widget.heroTag;
    checkFav();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
              Stack(
                children: <Widget>[
                  Container(
                    transform: Matrix4.translationValues(0.0, -50.0, 0.0),
                    child: Hero(
                      tag: (heroTag.isEmpty ? recipe['pictureUrl'] : heroTag),
                      child: ClipShadowPath(
                        clipper: CircularClipper(),
                        shadow: Shadow(blurRadius: 20.0),
                        child: Image(
                          height: 400.0,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          image: NetworkImage(recipe['pictureUrl']),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        padding: EdgeInsets.only(left: 30.0),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back),
                        iconSize: 30.0,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  Positioned.fill(
                    bottom: 10.0,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: RawMaterialButton(
                        padding: EdgeInsets.all(10.0),
                        elevation: 12.0,
                        onPressed: () {},
                        shape: CircleBorder(),
                        fillColor: Colors.grey[800],
                        child: Icon(
                          Icons.takeout_dining,
                          size: 60.0,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0.0,
                    right: 25.0,
                    child: IconButton(
                      onPressed: () async {
                        // remove/add to favourites
                        if(isFav){
                          await DbApi.removeFavourite(recipe['id']);
                        }else{
                          await DbApi.addFavourite(recipe['id']);
                        }

                        setState(() {
                          isFav = !isFav;
                        });
                      },
                      icon: (isFav ? Icon(Icons.star) : Icon(Icons.star_border)),
                      iconSize: 40.0,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 40.0, right: 40.0, top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      recipe['name'],
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      recipe['mealTypes']
                          .map((val) => Translator.mealType(val))
                          .join(" • "),
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16.0,
                      ),
                    ),
                    SizedBox(height: 15.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Text(
                              'Kalorie',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              recipe['calories'].toString(),
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12.0),
                    Container(
                      child: SingleChildScrollView(
                        child: Text(
                          recipe['description'],
                          style: TextStyle(
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.0),
                    Container(
                      child: SingleChildScrollView(
                        child: Text(
                          "Składniki: " + recipe['ingredients'].join(", "),
                          style: TextStyle(
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] +
            recipe['steps']
                .asMap()
                .entries
                .map<Widget>((entry) => ListTile(
                      title: Text(entry.value),
                    ))
                .toList(),
      ),
    );
  }
}
