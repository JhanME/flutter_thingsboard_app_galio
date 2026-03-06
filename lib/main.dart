import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:thingsboard_app/app_bloc_observer.dart';
import 'package:thingsboard_app/constants/app_constants.dart';
import 'package:thingsboard_app/constants/enviroment_variables.dart';
import 'package:thingsboard_app/core/select_region/model/region.dart';
import 'package:thingsboard_app/firebase_options.dart';
import 'package:thingsboard_app/locator.dart';
import 'package:thingsboard_app/thingsboard_app.dart';
import 'package:thingsboard_app/utils/services/firebase/i_firebase_service.dart';
import 'package:thingsboard_app/utils/services/local_database/i_local_database_service.dart';
import 'package:universal_platform/universal_platform.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (ThingsboardAppConstants.thingsBoardApiEndpoint.isEmpty) {
    FlutterNativeSplash.remove();
    runApp(const _MissingConfigApp());
    return;
  }
  await Hive.initFlutter();
         SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  Hive.registerAdapter(RegionAdapter());
  await setUpRootDependencies();
  if (UniversalPlatform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(
      kDebugMode || EnvironmentVariables.verbose,
    );
  }

  try {
    getIt<IFirebaseService>().initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    log('main::FirebaseService.initializeApp() exception $e', error: e);
  }

  try {
    final uri = await AppLinks().getInitialLink();
    if (uri != null) {
      await getIt<ILocalDatabaseService>().setInitialAppLink(uri.toString());
    }
  } catch (e) {
    log('main::getInitialUri() exception $e', error: e);
  }

  if (kDebugMode || EnvironmentVariables.verbose) {
    Bloc.observer = AppBlocObserver(getIt());
  }
  FlutterNativeSplash.remove();
  runApp(const ProviderScope(child: ThingsboardApp()));
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF343A40),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Color(0xFF28A745)),
                SizedBox(height: 24),
                Text(
                  'Configuración no encontrada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Ejecuta la app con un archivo de configuración:\n\n'
                  'flutter run --dart-define-from-file=config/dev.json\n\n'
                  'Copia config/config.example.json como punto de partida.',
                  style: TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
