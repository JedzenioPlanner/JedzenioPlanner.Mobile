/* Grid visible when searching recipes
 */
import 'package:flutter/material.dart';

import 'package:jedzenioplanner/pages/recipe.dart';
import 'package:jedzenioplanner/api/translator.dart';

class RecipeGrid extends StatelessWidget {
  final dynamic recipe;
  final int id;
  RecipeGrid({@required this.recipe, this.id = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RecipePage(
                        recipe: recipe,
                        heroTag: recipe['pictureUrl'] + id.toString(),
                      )));
        },
        child: Container(
          //width: 100,
          color: Colors.grey[600],
          child: Column(
            children: [
              Expanded(
                  flex: 6,
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      child: Hero(
                          tag: recipe['pictureUrl'] + id.toString(),
                          child: Image.network(
                            recipe['pictureUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image),
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes
                                      : null,
                                ),
                              );
                            },
                            //width: 90,
                            //height: 140,
                          )))),
              Expanded(
                flex: 1,
                child: Text(recipe['name']),
              ),
              Expanded(
                flex: 1,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(recipe['mealTypes']
                          .map((val) => Translator.mealType(val))
                          .join(" • ")),
                      Text("${recipe['calories']} kcal"),
                    ]),
              ),
            ],
          ),
        ));
  }
}
