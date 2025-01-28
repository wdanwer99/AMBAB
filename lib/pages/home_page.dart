import 'package:agriplant/pages/admin_page.dart';
import 'package:agriplant/pages/cart_page.dart';
import 'package:agriplant/pages/explore_page.dart';
import 'package:agriplant/pages/profile_page.dart';
import 'package:agriplant/pages/services_page.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pages = [
    const ExplorePage(),
    const ServicesPage(),
    const CartPage(),
    const ProfilePage()
  ];
  int currentPageIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const Drawer(),
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton.filledTonal(
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            icon: const Icon(Icons.menu),
          ),
          title: Image.asset(
            'assets/logo.png',
            height: 100,
          ),
          actions: [
            // Padding(
            //   padding: const EdgeInsets.only(right: 8.0),
            //   child: IconButton.filledTonal(
            //     onPressed: () {},
            //     icon: badges.Badge(
            //       badgeContent: const Text(
            //         '4',
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontSize: 12,
            //         ),
            //       ),
            //       position: badges.BadgePosition.topEnd(top: -15, end: -12),
            //       badgeStyle: const badges.BadgeStyle(
            //         badgeColor: Colors.green,
            //       ),
            //       child: const Icon(IconlyBroken.notification),
            //     ),
            //   ),
            // ),
          ],
        ),
        body: pages[currentPageIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentPageIndex,
          onTap: (index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(IconlyLight.home),
              label: "Home",
              activeIcon: Icon(IconlyBold.home),
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyLight.call),
              label: "Services",
              activeIcon: Icon(IconlyBold.call),
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyLight.buy),
              label: "Cart",
              activeIcon: Icon(IconlyBold.buy),
            ),
            BottomNavigationBarItem(
              icon: Icon(IconlyLight.profile),
              label: "Profile",
              activeIcon: Icon(IconlyBold.profile),
            ),
          ],
        ),
      ),
    );
  }
}
