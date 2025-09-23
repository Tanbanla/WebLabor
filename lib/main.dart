import 'package:flutter/material.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Get.put(AuthState());
  // Khởi tạo AuthState và load dữ liệu đã lưu
  final authState = AuthState();
  await authState.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('vi'), Locale('ja')],
      path: 'assets/translations',
      fallbackLocale: Locale('vi'),
      child: ChangeNotifierProvider(
        create: (context) => authState,
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final router = createRouter(context);
    return MaterialApp.router(
      title: 'Labor Contract Evaluation System',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
      builder: (context, child) {
        final authState = Provider.of<AuthState>(context, listen: true);
        if (authState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

//
class LanguageNotifier {
  static final ValueNotifier<Locale> _notifier = ValueNotifier<Locale>(
    Locale('vi'),
  );

  static ValueNotifier<Locale> get notifier => _notifier;

  static void changeLanguage(Locale locale) {
    _notifier.value = locale;
  }
}
