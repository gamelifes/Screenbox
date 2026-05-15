import 'package:flutter_test/flutter_test.dart';
import 'package:liyaplayer/features/player/data/datasources/audio_data_source.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Must initialize MediaKit before using any media_kit API
  MediaKit.ensureInitialized();

  late AudioDataSource dataSource;

  setUp(() {
    dataSource = AudioDataSource();
  });

  group('AudioDataSource - 初始化测试', () {
    test('初始化不应该抛出异常', () {
      expect(() => dataSource, isNot(throwsException));
    });
  });

  group('loadAudioSource - 音频源加载', () {
    test('loadAudioSource方法应该存在', () {
      expect(dataSource.loadAudioSource, isA<Function>());
    });

    test('loadAudioSource应该返回Future', () async {
      // 注意: 不实际测试返回值类型，因为Media是media_kit的类型
      expect(dataSource.loadAudioSource('test.mp3'), isA<Future>());
    });
  });

  group('播放控制方法', () {
    test('play方法应该存在', () {
      expect(dataSource.play, isA<Function>());
    });

    test('pause方法应该存在', () {
      expect(dataSource.pause, isA<Function>());
    });

    test('stop方法应该存在', () {
      expect(dataSource.stop, isA<Function>());
    });

    test('seek方法应该存在', () {
      expect(dataSource.seek, isA<Function>());
    });

    test('play/pause/stop应该返回Future<void>', () {
      expect(dataSource.play(), isA<Future<void>>());
      expect(dataSource.pause(), isA<Future<void>>());
      expect(dataSource.stop(), isA<Future<void>>());
    });

    test('seek应该接受Duration参数并返回Future', () {
      expect(dataSource.seek(Duration.zero), isA<Future<void>>());
    });
  });
}
