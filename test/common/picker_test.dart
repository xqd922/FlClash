import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_clash/common/picker.dart';
import 'package:test/test.dart';

/// file_picker 12 稳定版的 [PlatformFile] 是抽象基类且无公开测试实现,
/// 这里用本地文件实现一个最小替身。
base class _IoPlatformFile extends PlatformFile {
  final File file;

  _IoPlatformFile(this.file);

  @override
  String get name => file.uri.pathSegments.last;

  @override
  Uri get uri => file.uri;

  @override
  XFile get xFile => XFile(file.path);

  @override
  Future<int> length() => file.length();

  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() => file.openRead().cast<Uint8List>();
}

void main() {
  group('PlatformFileExt.readBytes', () {
    test('loads bytes from the picked file path', () async {
      final directory = await Directory.systemTemp.createTemp(
        'fl_clash_picker_test_',
      );
      addTearDown(() => directory.delete(recursive: true));

      final file = File('${directory.path}/profile.yaml');
      await file.writeAsString('mixed-port: 7890');

      final platformFile = _IoPlatformFile(file);

      final bytes = await platformFile.readBytes();

      expect(String.fromCharCodes(bytes), 'mixed-port: 7890');
    });
  });
}
