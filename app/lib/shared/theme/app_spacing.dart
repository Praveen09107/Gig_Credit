import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(xs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(sm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(md);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(lg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(xl);

  static const SizedBox spaceXs = SizedBox(height: xs, width: xs);
  static const SizedBox spaceSm = SizedBox(height: sm, width: sm);
  static const SizedBox spaceMd = SizedBox(height: md, width: md);
  static const SizedBox spaceLg = SizedBox(height: lg, width: lg);
  static const SizedBox spaceXl = SizedBox(height: xl, width: xl);
}
