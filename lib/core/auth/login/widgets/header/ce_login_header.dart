import 'package:flutter/material.dart';
import 'package:thingsboard_app/constants/assets_path.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        ThingsboardImage.thingsboardBigLogo,
        height: 140,
        fit: BoxFit.contain,
      ),
    );
  }
}
