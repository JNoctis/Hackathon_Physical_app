import 'package:flutter/material.dart';


// 頁面二：跑步頁 Run
class RunPage extends StatelessWidget {
  const RunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('這裡是跑步頁面\n(未來可整合 GPS, 距離顯示等)', textAlign: TextAlign.center),
    );
  }
}