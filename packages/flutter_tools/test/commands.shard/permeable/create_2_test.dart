// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  Directory tempDir;
  Directory projectDir;

  setUpAll(() async {
    Cache.disableLocking();

    // GitHub actions do not have access to the full Flutter checkout with the
    // cache folder, so we don't use `flutter_tools.snapshot`.
  });

  setUp(() {
    tempDir = globals.fs.systemTempDirectory
        .createTempSync('flutter_tools_create_test.');
    projectDir = tempDir.childDirectory('flutter_project');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testUsingContext('create an FFI plugin, then run ffigen', () async {
    Cache.flutterRoot = '../..';

    // Find the Flutter and Dart executable from the GitHub action.
    final String dart = io.Platform.resolvedExecutable;
    printOnFailure('dart: $dart');

    final CreateCommand command = CreateCommand();
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>[
      'create',
      '--no-pub',
      '--template=plugin_ffi',
      projectDir.path,
    ]);

    expect(projectDir.childFile('ffigen.yaml'), exists);
    final File generatedBindings = projectDir
        .childDirectory('lib')
        .childFile('${projectDir.basename}_bindings_generated.dart');
    expect(generatedBindings, exists);

    printOnFailure('projectDir.path: ${projectDir.path}');
    printOnFailure('pubspec.yaml contents:');
    printOnFailure(await projectDir.childFile('pubspec.yaml').readAsString());

    final io.File template =
        io.File('templates/plugin_shared/pubspec.yaml.tmpl');
    printOnFailure('templates/plugin_shared/pubspec.yaml.tmpl contents:');
    printOnFailure(await template.readAsString());

    final String generatedBindingsFromTemplate =
        (await generatedBindings.readAsString()).replaceAll('\r', '');

    await generatedBindings.delete();

    final ProcessResult pubGetResult = await Process.run(
      dart,
      <String>[
        'pub',
        'get',
      ],
      workingDirectory: projectDir.path,
    );
    printOnFailure('Results of running pub get:');
    printOnFailure(pubGetResult.stdout.toString());
    printOnFailure(pubGetResult.stderr.toString());
    expect(pubGetResult.exitCode, 0);

    final ProcessResult ffigenResult = await Process.run(
      dart,
      <String>[
        'pub',
        'run',
        'ffigen',
        '--config',
        'ffigen.yaml',
      ],
      workingDirectory: projectDir.path,
    );
    printOnFailure('Results of running ffigen:');
    printOnFailure(ffigenResult.stdout.toString());
    printOnFailure(ffigenResult.stderr.toString());
    expect(ffigenResult.exitCode, 0);

    final String generatedBindingsFromFfigen =
        (await generatedBindings.readAsString()).replaceAll('\r', '');

    expect(generatedBindingsFromFfigen, generatedBindingsFromTemplate);
  });
}
