/* Main "page" file, here add new pages to be visible in main navigation menu.
 * It's recommended to include this in main.dart file.
 */
import 'package:flutter/material.dart';

import 'package:jedzenioplanner/pages/generate.dart';
import 'package:jedzenioplanner/pages/explore.dart';
import 'package:jedzenioplanner/pages/favourites.dart';
import 'package:jedzenioplanner/pages/create_recipe.dart';
import 'package:jedzenioplanner/pages/profile.dart';

class RootPage extends StatefulWidget {
  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedPageIndex = 0;

  PageController controller = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          // here add new page objects
          GeneratePage(),
          ExplorePage(),
          FavouritesPage(),
          CreateRecipePage(),
          ProfilePage(),
        ],
        controller: controller,
        onPageChanged: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
      ),
      bottomNavigationBar: NavigationBar(
        index: _selectedPageIndex,
        controller: controller,
      ),
    );
  }
}

class NavigationBar extends StatelessWidget {
  final int index;
  final PageController controller;

  NavigationBar({@required this.index, @required this.controller});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // here add navigation buttons
          BottomNavigationBarItem(
            icon: Icon(Icons.all_inbox),
            label: 'Zaplanuj Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Odkrywaj',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Zapisane przepisy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Dodaj przepis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Twój Profil',
          ),
        ],
        currentIndex: index,
        selectedItemColor: Colors.grey[300],
        unselectedItemColor: Colors.grey[500],
        onTap: (toIndex) {
          if(index == toIndex)
            return; // ignore going to the same page
          controller.animateToPage(toIndex, duration: Duration(milliseconds: 500), curve: Curves.ease);
        },
      );
  }
}