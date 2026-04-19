import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isOfflineProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  final connectivity = Connectivity();

  Future<void> emitCurrent() async {
    final result = await connectivity.checkConnectivity();
    controller.add(result.contains(ConnectivityResult.none));
  }

  emitCurrent();

  final sub = connectivity.onConnectivityChanged.listen((result) {
    controller.add(result.contains(ConnectivityResult.none));
  });

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
});

