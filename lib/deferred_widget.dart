// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';

typedef LibraryLoader = Future<void> Function();
typedef DeferredWidgetBuilder = Widget Function();

/// Wraps the child inside a deferred module loader.
///
/// The child is created and a single instance of the Widget is maintained in
/// state as long as closure to create widget stays the same.
///
class DeferredWidget extends StatefulWidget {
  DeferredWidget(this.libraryLoader, this.createWidget, {Key key, Widget placeholder})
      : this.placeholder = placeholder ?? Container(),
        super(key: key);

  final LibraryLoader libraryLoader;
  final DeferredWidgetBuilder createWidget;
  final Widget placeholder;
  static final Map<LibraryLoader, Future<void>> _moduleLoaders = {};
  static final Set<LibraryLoader> _loadedModules = {};

  static Future<void> preload(LibraryLoader loader) {
    if (!_moduleLoaders.containsKey(loader)) {
      _moduleLoaders[loader] = loader().then((dynamic _) {
        _loadedModules.add(loader);
      });
    }
    return _moduleLoaders[loader];
  }

  @override
  _DeferredWidgetState createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  _DeferredWidgetState();
  Widget _loadedChild;
  DeferredWidgetBuilder _loadedCreator;

  @override
  void initState() {
    /// If module was already loaded immediately create widget instead of
    /// waiting for future or zone turn.
    if (DeferredWidget._loadedModules.contains(widget.libraryLoader)) {
      _onLibraryLoaded();
    } else {
      DeferredWidget.preload(widget.libraryLoader)
          .then((dynamic _) => _onLibraryLoaded());
    }
    super.initState();
  }

  void _onLibraryLoaded() {
    setState(() {
      _loadedCreator = widget.createWidget;
      _loadedChild = _loadedCreator();
    });
  }

  @override
  Widget build(BuildContext context) {
    /// If closure to create widget changed, create new instance, otherwise
    /// treat as const Widget.
    if (_loadedCreator != widget.createWidget && _loadedCreator != null) {
      _loadedCreator = widget.createWidget;
      _loadedChild = _loadedCreator();
    }
    return _loadedChild ?? widget.placeholder;
  }
}

/// Widget that displays a progress indicator and a text description explaining
/// that the widget is a deferred component and loading.
class DeferredLoadingPlaceholder extends StatelessWidget {
  DeferredLoadingStatus({String name = 'This widget'}) : this.name = name;

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Column(
          children: <Widget>[
            Text('${name} is installing.', style: Theme.of(context).textTheme.headline4),
            Container(height: 10),
            Text('${name} is a deferred component which are downloaded and installed at runtime.', style: Theme.of(context).textTheme.body2),
            Container(height: 20),
            Center(child: CircularProgressIndicator()),
          ],
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          border: Border.all(
            width: 20.0,
            color: Colors.grey[700],
          ),
          borderRadius: BorderRadius.all(Radius.circular(10))
        ),
        width: 250.0,
      )
    );
  }
}
