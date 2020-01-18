import '../persistent-tab-view.dart';

///Navigation bar controller for `PersistentTabView`.
class PersistentTabController extends ChangeNotifier {
  PersistentTabController({int initialIndex = 0})
      : _index = initialIndex,
        assert(initialIndex != null),
        assert(initialIndex >= 0);

  bool _isDisposed = false;
  int get index => _index;
  int _index;
  set index(int value) {
    assert(value != null);
    assert(value >= 0);
    if (_index == value) {
      return;
    }
    _index = value;
    notifyListeners();
  }

  @mustCallSuper
  @override
  void dispose() {
    super.dispose();
    _isDisposed = true;
  }
}

class PersistentTabScaffold extends StatefulWidget {
  PersistentTabScaffold({
    Key key,
    @required this.tabBar,
    @required this.tabBuilder,
    this.controller,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.isIOS,
  })  : assert(tabBar != null),
        assert(tabBuilder != null),
        assert(
            controller == null || controller.index < tabBar.items.length,
            "The PersistentTabController's current index ${controller.index} is "
            'out of bounds for the tab bar with ${tabBar.items.length} tabs'),
        super(key: key);

  final PersistentBottomNavBar tabBar;

  final PersistentTabController controller;

  final IndexedWidgetBuilder tabBuilder;

  final Color backgroundColor;

  final bool resizeToAvoidBottomInset;

  final bool isIOS;

  @override
  _PersistentTabScaffoldState createState() => _PersistentTabScaffoldState();
}

class _PersistentTabScaffoldState extends State<PersistentTabScaffold> {
  PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    _updateTabController();
  }

  void _updateTabController({bool shouldDisposeOldController = false}) {
    final PersistentTabController newController = widget.controller ??
        PersistentTabController(initialIndex: widget.tabBar.selectedIndex);

    if (newController == _controller) {
      return;
    }

    if (shouldDisposeOldController) {
      _controller?.dispose();
    } else if (_controller?._isDisposed == false) {
      _controller.removeListener(_onCurrentIndexChange);
    }

    newController.addListener(_onCurrentIndexChange);
    _controller = newController;
  }

  void _onCurrentIndexChange() {
    assert(
        _controller.index >= 0 &&
            _controller.index < widget.tabBar.items.length,
        "The $runtimeType's current index ${_controller.index} is "
        'out of bounds for the tab bar with ${widget.tabBar.items.length} tabs');
    setState(() {});
  }

  @override
  void didUpdateWidget(PersistentTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateTabController(
          shouldDisposeOldController: oldWidget.controller == null);
    } else if (_controller.index >= widget.tabBar.items.length) {
      _controller.index = widget.tabBar.items.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData existingMediaQuery = MediaQuery.of(context);
    MediaQueryData newMediaQuery = MediaQuery.of(context);

    Widget content = _TabSwitchingView(
      currentTabIndex: _controller.index,
      tabCount: widget.tabBar.items.length,
      tabBuilder: widget.tabBuilder,
    );
    EdgeInsets contentPadding = EdgeInsets.zero;

    if (widget.resizeToAvoidBottomInset) {
      // Remove the view inset and add it back as a padding in the inner content.
      newMediaQuery = newMediaQuery.removeViewInsets(removeBottom: true);
      contentPadding =
          EdgeInsets.only(bottom: existingMediaQuery.viewInsets.bottom);
    }

    if (widget.tabBar.isCurved) {
      if (widget.isIOS) {
        if (widget.tabBar != null &&
            (!widget.resizeToAvoidBottomInset ||
                widget.tabBar.navBarHeight * 0.8 >
                    existingMediaQuery.viewInsets.bottom)) {
          final double bottomPadding = widget.tabBar.navBarHeight * 0.8;
          contentPadding = EdgeInsets.only(bottom: bottomPadding);
        }
      } else {
        if (widget.tabBar != null &&
            (!widget.resizeToAvoidBottomInset ||
                widget.tabBar.navBarHeight * 0.8 >
                    existingMediaQuery.viewInsets.bottom)) {
          final double bottomPadding = widget.tabBar.navBarHeight * 0.8;
          contentPadding = EdgeInsets.only(bottom: bottomPadding);
        }
      }
    } else {
      if (widget.isIOS) {
        if (widget.tabBar != null &&
            (!widget.resizeToAvoidBottomInset ||
                widget.tabBar.navBarHeight * 0.6 >
                    existingMediaQuery.viewInsets.bottom)) {
          final double bottomPadding = widget.tabBar.navBarHeight;
          contentPadding = EdgeInsets.only(bottom: bottomPadding);
        }
      } else {
        if (widget.tabBar != null &&
            (!widget.resizeToAvoidBottomInset ||
                widget.tabBar.navBarHeight >
                    existingMediaQuery.viewInsets.bottom)) {
          final double bottomPadding = widget.tabBar.navBarHeight;
          contentPadding = EdgeInsets.only(bottom: bottomPadding);
        }
      }
    }

    content = MediaQuery(
      data: newMediaQuery,
      child: Padding(
        padding: contentPadding,
        child: content,
      ),
    );

    return DecoratedBox(
      decoration: widget.tabBar.isCurved
          ? BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
            )
          : BoxDecoration(color: CupertinoColors.white),
      child: Stack(
        children: <Widget>[
          content,
          MediaQuery(
            data: existingMediaQuery.copyWith(textScaleFactor: 1),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: widget.tabBar.copyWith(
                selectedIndex: _controller.index,
                onItemSelected: (int newIndex) {
                  _controller.index = newIndex;
                  if (widget.tabBar.onItemSelected != null)
                    widget.tabBar.onItemSelected(newIndex);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller?.dispose();
    } else if (_controller?._isDisposed == false) {
      _controller.removeListener(_onCurrentIndexChange);
    }

    super.dispose();
  }
}

class _TabSwitchingView extends StatefulWidget {
  const _TabSwitchingView({
    @required this.currentTabIndex,
    @required this.tabCount,
    @required this.tabBuilder,
  })  : assert(currentTabIndex != null),
        assert(tabCount != null && tabCount > 0),
        assert(tabBuilder != null);

  final int currentTabIndex;
  final int tabCount;
  final IndexedWidgetBuilder tabBuilder;

  @override
  _TabSwitchingViewState createState() => _TabSwitchingViewState();
}

class _TabSwitchingViewState extends State<_TabSwitchingView> {
  final List<bool> shouldBuildTab = <bool>[];
  final List<FocusScopeNode> tabFocusNodes = <FocusScopeNode>[];
  final List<FocusScopeNode> discardedNodes = <FocusScopeNode>[];

  @override
  void initState() {
    super.initState();
    shouldBuildTab.addAll(List<bool>.filled(widget.tabCount, false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusActiveTab();
  }

  @override
  void didUpdateWidget(_TabSwitchingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int lengthDiff = widget.tabCount - shouldBuildTab.length;
    if (lengthDiff > 0) {
      shouldBuildTab.addAll(List<bool>.filled(lengthDiff, false));
    } else if (lengthDiff < 0) {
      shouldBuildTab.removeRange(widget.tabCount, shouldBuildTab.length);
    }
    _focusActiveTab();
  }

  void _focusActiveTab() {
    if (tabFocusNodes.length != widget.tabCount) {
      if (tabFocusNodes.length > widget.tabCount) {
        discardedNodes.addAll(tabFocusNodes.sublist(widget.tabCount));
        tabFocusNodes.removeRange(widget.tabCount, tabFocusNodes.length);
      } else {
        tabFocusNodes.addAll(
          List<FocusScopeNode>.generate(
            widget.tabCount - tabFocusNodes.length,
            (int index) => FocusScopeNode(
                debugLabel:
                    '$CupertinoTabScaffold Tab ${index + tabFocusNodes.length}'),
          ),
        );
      }
    }
    FocusScope.of(context).setFirstFocus(tabFocusNodes[widget.currentTabIndex]);
  }

  @override
  void dispose() {
    for (FocusScopeNode focusScopeNode in tabFocusNodes) {
      focusScopeNode.dispose();
    }
    for (FocusScopeNode focusScopeNode in discardedNodes) {
      focusScopeNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List<Widget>.generate(widget.tabCount, (int index) {
        final bool active = index == widget.currentTabIndex;
        shouldBuildTab[index] = active || shouldBuildTab[index];

        return Offstage(
          offstage: !active,
          child: TickerMode(
            enabled: active,
            child: FocusScope(
              node: tabFocusNodes[index],
              child: Builder(builder: (BuildContext context) {
                return shouldBuildTab[index]
                    ? widget.tabBuilder(context, index)
                    : Container();
              }),
            ),
          ),
        );
      }),
    );
  }
}
