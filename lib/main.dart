import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/photos_screen.dart';
import 'screens/videos_screen.dart';
import 'screens/folders_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/metadata_screen.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FLAVOR環境変数を取得（デフォルトはdev）
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  // 環境変数ファイルを読み込み（ファイルが存在しない場合はスキップ）
  try {
    await dotenv.load(fileName: "assets/.env.$flavor");
  } catch (e) {
    print('Warning: Could not load .env.$flavor file: $e');
    // デフォルト値を設定
    dotenv.env['ADMOB_APP_ID'] = 'ca-app-pub-6529629959594411~8991187983';
    dotenv.env['DEBUG_MODE'] = 'true';
  }

  // Firebase初期化
  await Firebase.initializeApp();

  // AdMob初期化
  await MobileAds.instance.initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          brightness: Brightness.light,
        ),
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          toolbarTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: const IconThemeData(
            color: Colors.white,
            size: 24,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.surfaceColor,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PhotosScreen(),
    const VideosScreen(),
    const FoldersScreen(),
    const FavoritesScreen(),
    const MetadataScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    if (!state.isAuth) {
      // 権限が拒否された場合の処理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('写真へのアクセス権限が必要です'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'フォト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'ムービー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'フォルダ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'お気に入り',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: '詳細',
          ),
        ],
      ),
    );
  }
}
