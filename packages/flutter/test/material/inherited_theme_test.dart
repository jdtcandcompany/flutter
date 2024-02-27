// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Theme.wrap()', (WidgetTester tester) async {
    const Color primaryColor = Color(0xFF00FF00);
    final Key primaryContainerKey = UniqueKey();

    // Effectively the same as a StatelessWidget subclass.
    final Widget primaryBox = Builder(
      builder: (BuildContext context) {
        return Container(
          key: primaryContainerKey,
          color: Theme.of(context).primaryColor,
        );
      },
    );

    BuildContext navigatorContext;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: Builder( // Introduce a context so the app's Theme is visible.
            builder: (BuildContext context) {
              navigatorContext = context;
              return Theme(
                data: Theme.of(context).copyWith(primaryColor: primaryColor),
                child: Builder( // Introduce a context so the shadow Theme is visible to captureAll().
                  builder: (BuildContext context) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ElevatedButton(
                            child: const Text('push unwrapped'),
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  // The primaryBox will see the default Theme when built.
                                  builder: (BuildContext _) => primaryBox,
                                ),
                              );
                            },
                          ),
                          ElevatedButton(
                            child: const Text('push wrapped'),
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  // Capture the shadow Theme.
                                  builder: (BuildContext _) => InheritedTheme.captureAll(context, primaryBox),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    }

    Color containerColor() {
      return tester.widget<Container>(find.byKey(primaryContainerKey)).color;
    }

    await tester.pumpWidget(buildFrame());

    // Show the route which contains primaryBox which was wrapped with
    // InheritedTheme.captureAll().
    await tester.tap(find.text('push wrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(containerColor(), primaryColor);

    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route animation

    // Show the route which contains primaryBox
    await tester.tap(find.text('push unwrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(containerColor(), isNot(primaryColor));
  });

  testWidgets('PopupMenuTheme.wrap()', (WidgetTester tester) async {
    const double menuFontSize = 24;
    const Color menuTextColor = Color(0xFF0000FF);
    bool captureInheritedThemes = true;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: PopupMenuTheme(
            data: const PopupMenuThemeData(
              // The menu route's elevation, shape, and color are defined by the
              // current context, so they're not affected by ThemeData.captureAll().
              textStyle: TextStyle(fontSize: menuFontSize, color: menuTextColor),
            ),
            child: Center(
              child: PopupMenuButton<int>(
                // The appearance of the menu items' text is defined by the
                // PopupMenuTheme defined above. Popup menus use
                // InheritedTheme.captureAll() by default.
                captureInheritedThemes: captureInheritedThemes,
                child: const Text('show popupmenu'),
                onSelected: (int result) { },
                itemBuilder: (BuildContext context) {
                  return const <PopupMenuEntry<int>>[
                    PopupMenuItem<int>(value: 1, child: Text('One')),
                    PopupMenuItem<int>(value: 2, child: Text('Two')),
                  ];
                },
              ),
            ),
          ),
        ),
      );
    }

    TextStyle itemTextStyle(String text) {
      return tester.widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      ).text.style;
    }

    await tester.pumpWidget(buildFrame());

    await tester.tap(find.text('show popupmenu'));
    await tester.pumpAndSettle(); // menu route animation
    expect(itemTextStyle('One').fontSize, menuFontSize);
    expect(itemTextStyle('One').color, menuTextColor);
    expect(itemTextStyle('Two').fontSize, menuFontSize);
    expect(itemTextStyle('Two').color, menuTextColor);

    // Dismiss the menu
    await tester.tap(find.text('One'));
    await tester.pumpAndSettle(); // menu route animation

    // Defeat the default support for capturing the PopupMenuTheme.
    captureInheritedThemes = false;
    await tester.pumpWidget(buildFrame());

    await tester.tap(find.text('show popupmenu'));
    await tester.pumpAndSettle(); // menu route animation
    expect(itemTextStyle('One').fontSize, isNot(menuFontSize));
    expect(itemTextStyle('One').color,  isNot(menuTextColor));
    expect(itemTextStyle('Two').fontSize, isNot(menuFontSize));
    expect(itemTextStyle('Two').color,  isNot(menuTextColor));
  });

  testWidgets('BannerTheme.wrap()', (WidgetTester tester) async {
    const Color bannerBackgroundColor = Color(0xFF0000FF);
    const double bannerFontSize = 48;
    const Color bannerTextColor = Color(0xFF00FF00);

    final Widget banner = MaterialBanner(
      content: const Text('hello'),
      actions: <Widget>[
        TextButton(
          child: const Text('action'),
          onPressed: () { },
        ),
      ],
    );

    BuildContext navigatorContext;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: MaterialBannerTheme(
            data: const MaterialBannerThemeData(
              backgroundColor: bannerBackgroundColor,
              contentTextStyle: TextStyle(fontSize: bannerFontSize, color: bannerTextColor),
            ),
            child: Builder( // Introduce a context so the shadow BannerTheme is visible to captureAll().
              builder: (BuildContext context) {
                navigatorContext = context;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('push unwrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // The Banner will see the default BannerTheme when built.
                              builder: (BuildContext _) => banner,
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        child: const Text('push wrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // Capture the shadow BannerTheme.
                              builder: (BuildContext _) => InheritedTheme.captureAll(context, banner),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    Color bannerColor() {
      return tester.widget<Container>(
        find.descendant(of: find.byType(MaterialBanner), matching: find.byType(Container)).first,
      ).color;
    }

    TextStyle getTextStyle(String text) {
      return tester.widget<RichText>(
        find.descendant(
          of: find.text(text),
          matching: find.byType(RichText),
        ),
      ).text.style;
    }

    await tester.pumpWidget(buildFrame());

    // Show the route which contains the banner.
    await tester.tap(find.text('push wrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(bannerColor(), bannerBackgroundColor);
    expect(getTextStyle('hello').fontSize, bannerFontSize);
    expect(getTextStyle('hello').color, bannerTextColor);

    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route animation

    await tester.tap(find.text('push unwrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(bannerColor(), isNot(bannerBackgroundColor));
    expect(getTextStyle('hello').fontSize, isNot(bannerFontSize));
    expect(getTextStyle('hello').color, isNot(bannerTextColor));
  });

  testWidgets('DividerTheme.wrap()', (WidgetTester tester) async {
    const Color dividerColor = Color(0xFF0000FF);
    const double dividerSpace = 13;
    const double dividerThickness = 7;
    const Widget divider = Center(child: Divider());

    BuildContext navigatorContext;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: DividerTheme(
            data: const DividerThemeData(
              color: dividerColor,
              space: dividerSpace,
              thickness: dividerThickness,
            ),
            child: Builder( // Introduce a context so the shadow DividerTheme is visible to captureAll().
              builder: (BuildContext context) {
                navigatorContext = context;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('push unwrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // The Banner will see the default BannerTheme when built.
                              builder: (BuildContext _) => divider,
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        child: const Text('push wrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // Capture the shadow BannerTheme.
                              builder: (BuildContext _) => InheritedTheme.captureAll(context, divider),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    BorderSide dividerBorder() {
      final BoxDecoration decoration = tester.widget<Container>(
        find.descendant(of: find.byType(Divider), matching: find.byType(Container)).first,
      ).decoration as BoxDecoration;
      return decoration.border.bottom;
    }

    await tester.pumpWidget(buildFrame());

    // Show a route which contains a divider.
    await tester.tap(find.text('push wrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(tester.getSize(find.byType(Divider)).height, dividerSpace);
    expect(dividerBorder().color, dividerColor);
    expect(dividerBorder().width, dividerThickness);

    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route animation

    await tester.tap(find.text('push unwrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(tester.getSize(find.byType(Divider)).height, isNot(dividerSpace));
    expect(dividerBorder().color, isNot(dividerColor));
    expect(dividerBorder().width, isNot(dividerThickness));
  });

  testWidgets('ListTileTheme.wrap()', (WidgetTester tester) async {
    const Color tileSelectedColor = Color(0xFF00FF00);
    const Color tileIconColor = Color(0xFF0000FF);
    const Color tileTextColor = Color(0xFFFF0000);

    final Key selectedIconKey = UniqueKey();
    final Key unselectedIconKey = UniqueKey();

    final Widget listTiles = Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.computer, key: selectedIconKey),
              title: const Text('selected'),
              enabled: true,
              selected: true,
            ),
            ListTile(
              leading: Icon(Icons.add, key: unselectedIconKey),
              title: const Text('unselected'),
              enabled: true,
              selected: false,
            ),
          ],
        ),
      ),
    );

    BuildContext navigatorContext;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: ListTileTheme(
            selectedColor: tileSelectedColor,
            textColor: tileTextColor,
            iconColor: tileIconColor,
            child: Builder( // Introduce a context so the shadow ListTileTheme is visible to captureAll().
              builder: (BuildContext context) {
                navigatorContext = context;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('push unwrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // The Banner will see the default BannerTheme when built.
                              builder: (BuildContext _) => listTiles,
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        child: const Text('push wrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // Capture the shadow BannerTheme.
                              builder: (BuildContext _) => InheritedTheme.captureAll(context, listTiles),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    TextStyle getTextStyle(String text) {
      return tester.widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      ).text.style;
    }

    TextStyle getIconStyle(Key key) {
      return tester.widget<RichText>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(RichText),
        ),
      ).text.style;
    }

    await tester.pumpWidget(buildFrame());

    // Show a route which contains listTiles.
    await tester.tap(find.text('push wrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(getTextStyle('unselected').color, tileTextColor);
    expect(getTextStyle('selected').color, tileSelectedColor);
    expect(getIconStyle(selectedIconKey).color, tileSelectedColor);
    expect(getIconStyle(unselectedIconKey).color, tileIconColor);

    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route animation

    await tester.tap(find.text('push unwrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(getTextStyle('unselected').color, isNot(tileTextColor));
    expect(getTextStyle('selected').color, isNot(tileSelectedColor));
    expect(getIconStyle(selectedIconKey).color, isNot(tileSelectedColor));
    expect(getIconStyle(unselectedIconKey).color, isNot(tileIconColor));
  });

  testWidgets('SliderTheme.wrap()', (WidgetTester tester) async {
    const Color activeTrackColor = Color(0xFF00FF00);
    const Color inactiveTrackColor = Color(0xFF0000FF);
    const Color thumbColor = Color(0xFFFF0000);

    final Widget slider = Scaffold(
      body: Center(
        child: Slider(
          value: 0.5,
          onChanged: (double value) { },
        ),
      ),
    );

    BuildContext navigatorContext;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: activeTrackColor,
              inactiveTrackColor: inactiveTrackColor,
              thumbColor: thumbColor,
            ),
            child: Builder( // Introduce a context so the shadow SliderTheme is visible to captureAll().
              builder: (BuildContext context) {
                navigatorContext = context;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('push unwrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // The slider will see the default SliderTheme when built.
                              builder: (BuildContext _) => slider,
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        child: const Text('push wrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // Capture the shadow SliderTheme.
                              builder: (BuildContext _) => InheritedTheme.captureAll(context, slider),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());

    // Show a route which contains listTiles.
    await tester.tap(find.text('push wrapped'));
    await tester.pumpAndSettle(); // route animation
    RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));
    expect(sliderBox, paints..rrect(color: activeTrackColor)..rrect(color: inactiveTrackColor));
    expect(sliderBox, paints..circle(color: thumbColor));

    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route animation

    await tester.tap(find.text('push unwrapped'));
    await tester.pumpAndSettle(); // route animation
    sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));
    expect(sliderBox, isNot(paints..rrect(color: activeTrackColor)..rrect(color: inactiveTrackColor)));
    expect(sliderBox, isNot(paints..circle(color: thumbColor)));
  });

  testWidgets('ToggleButtonsTheme.wrap()', (WidgetTester tester) async {
    const Color buttonColor = Color(0xFF00FF00);
    const Color selectedButtonColor = Color(0xFFFF0000);

    final Widget toggleButtons = Scaffold(
      body: Center(
        child: ToggleButtons(
          children: const <Widget>[
            Text('selected'),
            Text('unselected'),
          ],
          isSelected: const <bool>[true, false],
          onPressed: (int index) { },
        ),
      ),
    );

    BuildContext navigatorContext;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: ToggleButtonsTheme(
            data: const ToggleButtonsThemeData(
              color: buttonColor,
              selectedColor: selectedButtonColor,
            ),
            child: Builder( // Introduce a context so the shadow ToggleButtonsTheme is visible to captureAll().
              builder: (BuildContext context) {
                navigatorContext = context;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('push unwrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // The slider will see the default ToggleButtonsTheme when built.
                              builder: (BuildContext _) => toggleButtons,
                            ),
                          );
                        },
                      ),
                      ElevatedButton(
                        child: const Text('push wrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // Capture the shadow toggleButtons.
                              builder: (BuildContext _) => InheritedTheme.captureAll(context, toggleButtons),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    Color getTextColor(String text) {
      return tester.widget<RichText>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      ).text.style.color;
    }

    await tester.pumpWidget(buildFrame());

    // Show a route which contains toggleButtons.
    await tester.tap(find.text('push wrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(getTextColor('selected'), selectedButtonColor);
    expect(getTextColor('unselected'), buttonColor);

    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route animation

    await tester.tap(find.text('push unwrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(getTextColor('selected'), isNot(selectedButtonColor));
    expect(getTextColor('unselected'), isNot(buttonColor));

  });

  testWidgets('ButtonTheme.wrap()', (WidgetTester tester) async {
    const Color buttonColor = Color(0xFF00FF00);
    const Color disabledButtonColor = Color(0xFFFF0000);

    final Widget buttons = Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const RaisedButton(child: Text('disabled'), onPressed: null),
            RaisedButton(child: const Text('enabled'), onPressed: () { }),
          ],
        ),
      ),
    );

    BuildContext navigatorContext;

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: ButtonTheme.fromButtonThemeData(
            data: const ButtonThemeData(
              buttonColor: buttonColor,
              disabledColor: disabledButtonColor,
            ),
            child: Builder( // Introduce a context so the shadow ButtonTheme is visible to captureAll().
              builder: (BuildContext context) {
                navigatorContext = context;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      RaisedButton(
                        child: const Text('push unwrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // The slider will see the default ButtonTheme when built.
                              builder: (BuildContext _) => buttons,
                            ),
                          );
                        },
                      ),
                      RaisedButton(
                        child: const Text('push wrapped'),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              // Capture the shadow toggleButtons.
                              builder: (BuildContext _) => InheritedTheme.captureAll(context, buttons),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    Color getButtonColor(String text) {
      return tester.widget<Material>(
        find.descendant(
          of: find.widgetWithText(RawMaterialButton, text),
          matching: find.byType(Material),
        ),
      ).color;
    }

    await tester.pumpWidget(buildFrame());

    // Show a route which contains toggleButtons.
    await tester.tap(find.text('push wrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(getButtonColor('disabled'), disabledButtonColor);
    expect(getButtonColor('enabled'), buttonColor);

    Navigator.of(navigatorContext).pop();
    await tester.pumpAndSettle(); // route animation

    await tester.tap(find.text('push unwrapped'));
    await tester.pumpAndSettle(); // route animation
    expect(getButtonColor('disabled'), isNot(disabledButtonColor));
    expect(getButtonColor('enabled'), isNot(buttonColor));

  });

}
