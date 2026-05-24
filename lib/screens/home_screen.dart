import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'customer_home.dart';
import 'worker_home.dart';
import 'language_selection.dart';
import 'system_support_screen.dart';
import '../app_theme.dart';
import '../widgets/custom_drawer/drawer_user_controller.dart';
import '../widgets/custom_drawer/home_drawer.dart';

class HomeScreen extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  HomeScreen({required this.onLocaleChanged});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget? screenView;
  DrawerIndex? drawerIndex;

  @override
  void initState() {
    drawerIndex = DrawerIndex.HOME;
    screenView = DashboardScreen(onLocaleChanged: widget.onLocaleChanged);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Scaffold(
          backgroundColor: AppTheme.nearlyWhite,
          body: DrawerUserController(
            screenIndex: drawerIndex,
            drawerWidth: MediaQuery.of(context).size.width * 0.75,
            onDrawerCall: (DrawerIndex drawerIndexdata) {
              changeIndex(drawerIndexdata);
            },
            screenView: screenView,
          ),
        ),
      ),
    );
  }

  void changeIndex(DrawerIndex drawerIndexdata) {
    if (drawerIndex != drawerIndexdata) {
      drawerIndex = drawerIndexdata;
      switch (drawerIndex) {
        case DrawerIndex.HOME:
          setState(() {
            screenView = DashboardScreen(onLocaleChanged: widget.onLocaleChanged);
          });
          break;
        case DrawerIndex.Help:
          setState(() {
            screenView = SystemSupportScreen();
          });
          break;
        default:
          setState(() {
            screenView = SystemSupportScreen();
          });
          break;
      }
    }
  }
}

class DashboardScreen extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  DashboardScreen({required this.onLocaleChanged});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _index = 0;
  late PageController _pageController;

  final _pages = <Widget>[CustomerHome(), WorkerHome()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _changePage(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('service_platform')),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            tooltip: 'Language',
            onPressed: () async {
              final locale = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LanguageSelection()),
              );
              if (locale != null) widget.onLocaleChanged(locale);
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _index = index),
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: AppTheme.deactivatedText,
          enableFeedback: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.home, size: 20),
              ),
              label: AppLocalizations.of(context).t('customer'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              activeIcon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, size: 20),
              ),
              label: AppLocalizations.of(context).t('worker'),
            ),
          ],
          onTap: _changePage,
        ),
      ),
    );
  }
}
