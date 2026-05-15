import 'package:watcher/watcher.dart';

class FileWatcherService {
  final Map<String, DirectoryWatcher> _watchers = {};

  void watch(String path, void Function(String event, String path) onEvent) {
    final watcher = DirectoryWatcher(path);
    _watchers[path] = watcher;

    watcher.events.listen((event) {
      onEvent(event.type.toString(), event.path);
    });
  }

  void stopWatching(String path) {
    _watchers.remove(path);
  }

  void stopAll() {
    _watchers.clear();
  }
}
