import 'package:riverpod/riverpod.dart';
import 'package:socialdownloader/data/download_repository.dart';

final downloadProvider = Provider((ref) => DownloadRepository());
