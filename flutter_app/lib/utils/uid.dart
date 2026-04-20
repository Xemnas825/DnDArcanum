import 'dart:math';

final _rng = Random();

String uid([int len = 8]) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(len, (_) => chars[_rng.nextInt(chars.length)]).join();
}

