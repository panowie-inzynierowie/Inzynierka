import 'package:flutter/material.dart';

class GradientScaffold extends StatefulWidget {
  final Widget body;
  const GradientScaffold({Key? key, required this.body}) : super(key: key);

  @override
  GradientScaffoldState createState() => GradientScaffoldState();
}

class GradientScaffoldState extends State<GradientScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(_animation.value * 2 - 1, -1.0),
                end: Alignment(-_animation.value * 2 + 1, 1.0),
                colors: const [
                  Color.fromARGB(255, 14, 105, 185),
                  Color.fromARGB(255, 203, 64, 228)
                ],
              ),
            ),
            child: widget.body,
          ),
        );
      },
    );
  }
}
