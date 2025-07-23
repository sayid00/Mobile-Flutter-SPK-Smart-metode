import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/data_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/criteria_screen.dart';
import 'screens/alternatives_screen.dart';
import 'screens/values_screen.dart';
import 'screens/analysis_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // Hilangkan tulisan DEBUG
        title: 'SPK SMART',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            primary: const Color(0xFF2196F3),
            secondary: const Color(0xFF64B5F6),
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          textTheme: GoogleFonts.poppinsTextTheme(),
          cardTheme: const CardThemeData(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
          ),
        ),

        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/criteria': (context) => const HomeScreen(initialIndex: 0),
          '/alternatives': (context) => const HomeScreen(initialIndex: 1),
          '/values': (context) => const HomeScreen(initialIndex: 2),
          '/analysis': (context) => const HomeScreen(initialIndex: 3),
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<String> _titles = [
    'Kriteria',
    'Alternatif',
    'Nilai',
    'Analisis',
  ];

  final List<Widget> _screens = [
    const CriteriaScreen(),
    const AlternativesScreen(),
    const ValuesScreen(),
    const AnalysisScreen(),
  ];

  bool _canNavigateFromCriteria(BuildContext context) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    if (provider.criteria.isEmpty) return true;

    final totalWeight = provider.criteria.fold<double>(
      0.0,
      (sum, c) =>
          sum +
          (provider.weightFormat == 'percent' ? c.weight : c.weight / 100),
    );
    final expectedTotal = provider.weightFormat == 'percent' ? 100.0 : 1.0;

    if ((totalWeight - expectedTotal).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total bobot harus $expectedTotal${provider.weightFormat == 'percent' ? '%' : ''}!',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return false;
    }
    return true;
  }

  void _onNavTap(int index) {
    final provider = Provider.of<DataProvider>(context, listen: false);

    // Validasi kriteria
    if (_selectedIndex == 0 &&
        index != 0 &&
        !_canNavigateFromCriteria(context)) {
      return;
    }

    // Validasi nilai
    if (index == 2) {
      if (provider.criteria.length < 2 || provider.alternatives.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Minimal 2 kriteria dan 2 alternatif untuk mengisi nilai!',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
        return;
      }
    }
    // Validasi analisis
    else if (index == 3) {
      if (provider.criteria.isEmpty ||
          provider.alternatives.isEmpty ||
          !provider.isValuesSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data belum lengkap, tidak dapat melakukan analisis!',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _titles[_selectedIndex],
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedIndex == 3
              ? _screens[_selectedIndex]
              : Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    _screens[_selectedIndex],
                  ],
                ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Kriteria',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Alternatif',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Nilai',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analisis',
            ),
          ],
        ),
      ),
    );
  }
}
