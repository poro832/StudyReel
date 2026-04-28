import 'package:flutter/material.dart';

class CardDetailScreen extends StatelessWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('카드 상세: $cardId (Task 7에서 구현)')),
    );
  }
}
