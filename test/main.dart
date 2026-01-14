// expect_lint: explicit_imports
import 'dart:math';

import 'dart:math' as math;
import 'dart:math' show Random;

// expect_lint: explicit_imports
import 'dart:collection' hide HashMap;

void main() {
  print(math.Random().nextInt(10));
  print(Random().nextInt(10));
  print(Queue());
}
