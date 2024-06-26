library flutterslidetoact;

import 'package:flutter/material.dart';

/// Slider call to action component
class SlideAction extends StatefulWidget {
  /// The size of the sliding icon
  final double sliderButtonIconSize;

  /// Tha padding of the sliding icon
  final double sliderButtonIconPadding;

  /// The offset on the y axis of the slider icon
  final double sliderButtonYOffset;

  // Wether the user can interact with the slider
  final bool enabled;

  /// The child that is rendered instead of the default Text widget
  final Widget? child;

  /// The height of the component
  final double height;

  /// The color of the text.
  /// If not set, this attribute defaults to primaryIconTheme.
  final Color? textColor;

  /// The color of the inner circular button and the tick icon.
  /// If not set, this attribute defaults to primaryIconTheme.
  final Color? innerColor;

  /// The color of the external area and of the arrow icon.
  /// If not set, this attribute defaults to the secondary color of your theme's colorScheme.
  final Color? outerColor;

  /// The text showed in the default Text widget
  final String? text;

  /// Text style which is applied on the Text widget.
  ///
  /// By default, the text is colored using [textColor].
  final TextStyle? textStyle;

  /// The borderRadius of the sliding icon and of the background
  final double borderRadius;

  /// Callback called on submit
  /// If this is null the component will not animate to complete
  final VoidCallback onSubmit;

  /// Elevation of the component
  final double elevation;

  /// The widget to render instead of the default icon
  final Widget? sliderButtonIcon;

  /// The widget to render instead of the default submitted icon
  final Widget? submittedIcon;

  /// The duration of the animations
  final Duration animationDuration;

  /// the alignment of the widget once it's submitted
  final Alignment alignment;

  /// The point where the onSubmit callback should be executed
  final double trigger;

  /// Tha padding of the container
  final double containerPadding;

  /// Create a new instance of the widget
  const SlideAction({
    super.key,
    this.sliderButtonIconSize = 24,
    this.sliderButtonIconPadding = 16,
    this.sliderButtonYOffset = 0,
    this.enabled = true,
    this.height = 70,
    this.textColor,
    this.innerColor,
    this.outerColor,
    this.borderRadius = 52,
    this.elevation = 6,
    this.animationDuration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
    this.submittedIcon,
    required this.onSubmit,
    this.child,
    this.text,
    this.containerPadding = 8.0,
    this.textStyle,
    this.sliderButtonIcon,
    this.trigger = 0.8,
  }) : assert(0.1 <= trigger && trigger <= 1.0,
            'The value of `trigger` should be between 0.1 and 1.0');
  @override
  SlideActionState createState() => SlideActionState();
}

/// Use a GlobalKey to access the state. This is the only way to call [SlideActionState.reset]
class SlideActionState extends State<SlideAction>
    with TickerProviderStateMixin {
  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _sliderKey = GlobalKey();
  double _dx = 0;
  double _maxDx = 0;
  double get _progress => _dx == 0 ? 0 : _dx / _maxDx;
  double _endDx = 0;
  double? _containerWidth;
  bool submitted = false;
  late AnimationController _cancelAnimationController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: Container(
        key: _containerKey,
        height: widget.height,
        width: _containerWidth,
        constraints: _containerWidth != null
            ? null
            : BoxConstraints.expand(height: widget.height),
        child: Material(
          elevation: widget.elevation,
          color: widget.outerColor ?? Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: submitted
              ? Center(
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: <Widget>[
                      widget.submittedIcon ??
                          Icon(
                            Icons.done,
                            color: widget.innerColor ??
                                Theme.of(context).primaryIconTheme.color,
                          ),
                      Positioned.fill(
                        right: 0,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            color: widget.outerColor ??
                                Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Opacity(
                      opacity: 1 - 1 * _progress,
                      child: widget.child ??
                          Text(
                            widget.text ?? 'Slide to act',
                            textAlign: TextAlign.center,
                            style: widget.textStyle ??
                                TextStyle(
                                  color: widget.textColor ??
                                      Theme.of(context).primaryIconTheme.color,
                                  fontSize: 24,
                                ),
                          ),
                    ),
                    Positioned(
                      left: widget.sliderButtonYOffset,
                      child: Container(
                        key: _sliderKey,
                        child: GestureDetector(
                          onHorizontalDragUpdate:
                              widget.enabled ? onHorizontalDragUpdate : null,
                          onHorizontalDragEnd: (details) async {
                            _endDx = _dx;
                            if (_progress <= widget.trigger) {
                              _cancelAnimation();
                            } else {
                              widget.onSubmit();
                              await reset();
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.containerPadding,
                            ),
                            child: Material(
                              borderRadius:
                                  BorderRadius.circular(widget.borderRadius),
                              color: widget.innerColor ??
                                  Theme.of(context).primaryIconTheme.color,
                              child: Container(
                                width: _containerWidth != null
                                    ? 68 + (_progress * (_containerWidth! - 68))
                                    : 68,
                                padding: EdgeInsets.all(
                                    widget.sliderButtonIconPadding),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: widget.sliderButtonIcon ??
                                      Icon(
                                        Icons.arrow_forward,
                                        size: widget.sliderButtonIconSize,
                                        color: widget.outerColor ??
                                            Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dx = (_dx + details.delta.dx).clamp(0.0, _maxDx);
    });
  }

  /// Call this method to revert the animations
  Future reset() async {
    submitted = false;

    await _cancelAnimation();
  }

  Future _cancelAnimation() async {
    _cancelAnimationController.reset();
    final animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cancelAnimationController,
      curve: Curves.fastOutSlowIn,
    ));

    animation.addListener(() {
      if (mounted) {
        setState(() {
          _dx = (_endDx - (_endDx * animation.value));
        });
      }
    });
    _cancelAnimationController.forward();
  }

  @override
  void initState() {
    super.initState();

    _cancelAnimationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox containerBox =
          _containerKey.currentContext!.findRenderObject() as RenderBox;
      _containerWidth = containerBox.size.width;

      final RenderBox sliderBox =
          _sliderKey.currentContext!.findRenderObject() as RenderBox;
      final sliderWidth = sliderBox.size.width;

      _maxDx = _containerWidth! -
          (sliderWidth / 2) -
          33 -
          widget.sliderButtonYOffset;
    });
  }

  @override
  void dispose() {
    _cancelAnimationController.dispose();
    super.dispose();
  }
}
