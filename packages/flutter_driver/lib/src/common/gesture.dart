// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'find.dart';
import 'message.dart';

/// A Flutter Driver command that taps on a target widget located by [finder].
class Tap extends CommandWithTarget {
  /// Creates a tap command to tap on a widget located by [finder].
  Tap(SerializableFinder finder, { Duration timeout }) : super(finder, timeout: timeout);

  /// Deserializes this command from the value generated by [serialize].
  Tap.deserialize(Map<String, String> json) : super.deserialize(json);

  @override
  String get kind => 'tap';
}

/// The result of a [Tap] command.
class TapResult extends Result {
  /// Creates a [TapResult].
  const TapResult();

  /// Deserializes this result from JSON.
  static TapResult fromJson(Map<String, dynamic> json) {
    return const TapResult();
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}


/// A Flutter Driver command that commands the driver to perform a scrolling action.
class Scroll extends CommandWithTarget {
  /// Creates a scroll command that will attempt to scroll a scrollable view by
  /// dragging a widget located by the given [finder].
  Scroll(
    SerializableFinder finder,
    this.dx,
    this.dy,
    this.duration,
    this.frequency, {
    Duration timeout,
  }) : super(finder, timeout: timeout);

  /// Deserializes this command from the value generated by [serialize].
  Scroll.deserialize(Map<String, String> json)
    : dx = double.parse(json['dx']),
      dy = double.parse(json['dy']),
      duration = Duration(microseconds: int.parse(json['duration'])),
      frequency = int.parse(json['frequency']),
      super.deserialize(json);

  /// Delta X offset per move event.
  final double dx;

  /// Delta Y offset per move event.
  final double dy;

  /// The duration of the scrolling action
  final Duration duration;

  /// The frequency in Hz of the generated move events.
  final int frequency;

  @override
  String get kind => 'scroll';

  @override
  Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
    'dx': '$dx',
    'dy': '$dy',
    'duration': '${duration.inMicroseconds}',
    'frequency': '$frequency',
  });
}

/// The result of a [Scroll] command.
class ScrollResult extends Result {
  /// Creates a [ScrollResult].
  const ScrollResult();

  /// Deserializes this result from JSON.
  static ScrollResult fromJson(Map<String, dynamic> json) {
    return const ScrollResult();
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

/// A Flutter Driver command that commands the driver to ensure that the element
/// represented by [finder] has been scrolled completely into view.
class ScrollIntoView extends CommandWithTarget {
  /// Creates this command given a [finder] used to locate the widget to be
  /// scrolled into view.
  ScrollIntoView(SerializableFinder finder, { this.alignment = 0.0, Duration timeout }) : super(finder, timeout: timeout);

  /// Deserializes this command from the value generated by [serialize].
  ScrollIntoView.deserialize(Map<String, String> json)
    : alignment = double.parse(json['alignment']),
      super.deserialize(json);

  /// How the widget should be aligned.
  ///
  /// This value is passed to [Scrollable.ensureVisible] as the value of its
  /// argument of the same name.
  ///
  /// Defaults to 0.0.
  final double alignment;

  @override
  String get kind => 'scrollIntoView';

  @override
  Map<String, String> serialize() => super.serialize()..addAll(<String, String>{
    'alignment': '$alignment',
  });
}
