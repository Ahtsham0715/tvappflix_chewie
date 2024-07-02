import 'package:flutter/material.dart';
import 'package:flutter_app_tv/ui/auth/auth.dart';
import 'package:flutter_app_tv/ui/auth/profile.dart';
import 'package:flutter_app_tv/ui/channel/channels.dart';
import 'package:flutter_app_tv/ui/home/home.dart';
import 'package:flutter_app_tv/ui/home/mylist.dart';
import 'package:flutter_app_tv/ui/movie/movies.dart';
import 'package:flutter_app_tv/ui/search/search.dart';
import 'package:flutter_app_tv/ui/serie/series.dart';
import 'package:flutter_app_tv/ui/setting/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class HomeMobile extends StatefulWidget {
  const HomeMobile({super.key});

  @override
  State<HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends State<HomeMobile> {
  int _selectedIndex = 0;
  bool logged = false;

  @override
  void initState() {
    getLogged();
    super.initState();
  }

  getLogged() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    logged = await prefs.getBool("LOGGED_USER") ?? false;

    setState(() {});
  }

  static List<Widget> _widgetOptions = <Widget>[
    Home(),
    Movies(),
    Series(),
    Channels(),
    MyList(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        elevation: 0,
        centerTitle: true,
        title: Container(
          width: 100,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Image.asset("assets/images/logo.png"),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                // widget.postx = 0;
                // widget.posty = -2;
                Future.delayed(Duration(milliseconds: 200), () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          Search(),
                      transitionDuration: Duration(seconds: 0),
                    ),
                  );
                });
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // color: (widget.selectedItem == 0)
                //     ? (widget.posty == -2 && widget.postx == 0)
                //         ? Colors.white
                //         : Colors.white70
                //     : (widget.posty == -2 && widget.postx == 0)
                //         ? Colors.white24
                //         : Colors.transparent,
                color: Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 20,
                    // color: (widget.selectedItem == 0)
                    //     ? Colors.black
                    //     : (widget.posty == -2 &&
                    //             widget.postx == 0)
                    //         ? Colors.white
                    //         : Colors.white60,
                    color: Colors.white,
                  ),
                  SizedBox(width: 5),
                  Text(
                    "Search",
                    style: TextStyle(
                        // color: (widget.selectedItem == 0)
                        //     ? Colors.black
                        //     : (widget.posty == -2 && widget.postx == 0)
                        //         ? Colors.white
                        //         : Colors.white60,
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: AssetImage("assets/images/background.jpeg"),
                fit: BoxFit.cover),
            CustomDrawerTile(
                title: 'Profile',
                onTap: () {
                  if (logged) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) =>
                            Profile(),
                        transitionDuration: Duration(seconds: 0),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) =>
                            Auth(),
                        transitionDuration: Duration(seconds: 0),
                      ),
                    );
                  }
                },
                icon: Icons.person),
            CustomDrawerTile(
                title: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) =>
                          Settings(),
                      transitionDuration: Duration(seconds: 0),
                    ),
                  );
                },
                icon: Icons.settings),
          ],
        ),
      ),
      body: _selectedIndex == 4
          ? logged
              ? MyList()
              : Auth()
          : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Movies',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_creation_sharp),
            label: 'Shows',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: 'Live TV',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My List',
            backgroundColor: Colors.black,
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.shifting,
        selectedItemColor: Colors.amber[800],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        unselectedLabelStyle: TextStyle(color: Colors.white),
        // useLegacyColorScheme: false,
        onTap: _onItemTapped,
      ),
    );
  }
}

class CustomDrawerTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData icon;
  const CustomDrawerTile(
      {super.key,
      required this.title,
      required this.onTap,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}
