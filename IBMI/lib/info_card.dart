// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class InfoCard extends StatelessWidget {
//   final Widget child;
//   final double width, height;
//
//   const InfoCard({
//     required this.height,
//     required this.width,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: width,
//       height: height,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const[BoxShadow(
//           color: Colors.black26,
//           blurRadius: 5,
//         )],
//       ),
//       child: child,
//     );
//   }
// }

import 'package:flutter/cupertino.dart';

class InfoCard extends StatelessWidget {
  final Widget child;
  final double width, height;

  const InfoCard({
    required this.height,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6, // iOS-style card color
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
