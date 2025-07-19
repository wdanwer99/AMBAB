import 'package:agriplant/pages/admin_page.dart';
import 'package:agriplant/pages/cart_page.dart';
import 'package:agriplant/pages/explore_page.dart';
import 'package:agriplant/pages/profile_page.dart';
import 'package:agriplant/pages/services_page.dart';
import 'package:agriplant/pages/orders_page.dart'; // Added import for OrdersPage
import 'package:agriplant/pages/about_us_page.dart'; // Added import for AboutUsPage
import 'package:agriplant/services/supabase_service.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  final int initialTab;
  const HomePage({super.key, this.initialTab = 0});

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
  late int currentPageIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    print('HomePage: Building home page');
    final user = SupabaseService.getCurrentUser();
    print('HomePage: Current user - ${user?.id}');
    final loc = AppLocalizations.of(context)!;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: _buildCustomDrawer(context),
        ),
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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(IconlyLight.home),
              label: loc.home,
              activeIcon: const Icon(IconlyBold.home),
            ),
            BottomNavigationBarItem(
              icon: const Icon(IconlyLight.call),
              label: loc.services,
              activeIcon: const Icon(IconlyBold.call),
            ),
            BottomNavigationBarItem(
              icon: const Icon(IconlyLight.buy),
              label: loc.cart,
              activeIcon: const Icon(IconlyBold.buy),
            ),
            BottomNavigationBarItem(
              icon: const Icon(IconlyLight.profile),
              label: loc.profile,
              activeIcon: const Icon(IconlyBold.profile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDrawer(BuildContext context) {
    final user = SupabaseService.getCurrentUser();
    String userName = 'User';
    String userEmail = '';
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(loc.home),
            onTap: () {
              setState(() { currentPageIndex = 0; });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.miscellaneous_services),
            title: Text(loc.services),
            onTap: () {
              setState(() { currentPageIndex = 1; });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: Text(loc.cart),
            onTap: () {
              setState(() { currentPageIndex = 2; });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(loc.profile),
            onTap: () {
              setState(() { currentPageIndex = 3; });
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(loc.myOrders),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: Text(loc.savedProducts),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(loc.aboutUs),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutUsPage()));
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.language),
                const SizedBox(width: 8),
                Text(loc.language),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => showLanguagePicker(context),
                  icon: const Icon(Icons.arrow_drop_down),
                  label: Text(loc.language),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(loc.logout),
            onTap: () async {
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  void showLanguagePicker(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc.selectLanguage),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(loc.english),
                  onTap: () {
                    final appState = LocaleApp.of(context);
                    if (appState != null) {
                      appState.setLocale(const Locale('en'));
                    }
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(loc.arabic),
                  onTap: () {
                    final appState = LocaleApp.of(context);
                    if (appState != null) {
                      appState.setLocale(const Locale('ar'));
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
