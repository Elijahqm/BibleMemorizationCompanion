import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves the private directory where installed packages live.
///
/// Injectable so tests can point at a temp directory instead of going through
/// the `path_provider` platform channel.
typedef DirectoryProvider = Future<Directory> Function();

Future<Directory> defaultAppDirectory() => getApplicationSupportDirectory();
