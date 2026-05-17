import 'package:flutter/material.dart';
import '../loaders/seedling_loader.dart';

class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SeedlingLoader(
        label: message ?? 'Loading...',
      ),
    );
  }
}
