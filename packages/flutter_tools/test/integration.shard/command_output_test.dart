// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/features.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  testWithoutContext('All development tools and deprecated commands are hidden and help text is not verbose', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '-h',
      '-v',
    ]);

    // Development tools.
    expect(result.stdout, isNot(contains('ide-config')));
    expect(result.stdout, isNot(contains('update-packages')));
    expect(result.stdout, isNot(contains('inject-plugins')));

    // Deprecated.
    expect(result.stdout, isNot(contains('make-host-app-editable')));

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  testWithoutContext('flutter doctor is not verbose', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'doctor',
      '-v',
    ]);

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  testWithoutContext('flutter doctor -vv super verbose', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'doctor',
      '-vv',
    ]);

    // Check for message only printed in verbose mode.
    expect(result.stdout, contains('Running shutdown hooks'));
  });

  testWithoutContext('flutter config contains all features', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'config',
    ]);

    // contains all of the experiments in features.dart
    expect(result.stdout.split('\n'), containsAll(<Matcher>[
      for (final Feature feature in allFeatures)
        contains(feature.configSetting),
    ]));
  });

  testWithoutContext('flutter run --machine uses AppRunLogger', () async {
    final Directory directory = createResolvedTempDirectorySync('flutter_run_test.')
      .createTempSync('_flutter_run_test.')
      ..createSync(recursive: true);

    try {
      directory
        .childFile('pubspec.yaml')
        .writeAsStringSync('name: foo');
      directory
        .childFile('.packages')
        .writeAsStringSync('\n');
      directory
        .childDirectory('lib')
        .childFile('main.dart')
        .createSync(recursive: true);
      final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'run',
        '--show-test-device', // ensure command can fail to run and hit injection of correct logger.
        '--machine',
        '-v',
        '--no-resident',
      ], workingDirectory: directory.path);
      expect(result.stderr, isNot(contains('Oops; flutter has exited unexpectedly:')));
    } finally {
      tryToDelete(directory);
    }
  });

  testWithoutContext('flutter attach --machine uses AppRunLogger', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'attach',
      '--machine',
      '-v',
    ]);

    expect(result.stderr, contains('Target file')); // Target file not found, but different paths on Windows and Linux/macOS.
  });

  testWithoutContext('flutter build aot is deprecated', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      '-h',
      '-v',
    ]);

    // Deprecated.
    expect(result.stdout, isNot(contains('aot')));

    // Only printed by verbose tool.
    expect(result.stdout, isNot(contains('exiting with code 0')));
  });

  testWithoutContext('flutter --version --machine outputs JSON with flutterRoot', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '--version',
      '--machine',
    ]);

    final Map<String, Object> versionInfo = json.decode(result.stdout
      .toString()
      .replaceAll('Building flutter tool...', '')
      .replaceAll('Waiting for another flutter command to release the startup lock...', '')
      .trim()) as Map<String, Object>;

    expect(versionInfo, containsPair('flutterRoot', isNotNull));
  });

  testWithoutContext('A tool exit is thrown for an invalid debug-uri in flutter attach', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final String helloWorld = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      '--show-test-device',
      'attach',
      '-d',
      'flutter-tester',
      '--debug-uri=http://127.0.0.1:3333*/',
    ], workingDirectory: helloWorld);

    expect(result.exitCode, 1);
    expect(result.stderr, contains('Invalid `--debug-uri`: http://127.0.0.1:3333*/'));
  });

  testWithoutContext('will load bootstrap script before starting', () async {
    final String flutterBin =
        fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    final File bootstrap = fileSystem.file(fileSystem.path.join(
        getFlutterRoot(),
        'bin',
        'internal',
        platform.isWindows ? 'bootstrap.bat' : 'bootstrap.sh'));

    try {
      bootstrap.writeAsStringSync('echo TESTING 1 2 3');

      final ProcessResult result = await processManager.run(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
      ]);

      expect(result.stdout, contains('TESTING 1 2 3'));
    } finally {
      bootstrap.deleteSync();
    }
  });
}
