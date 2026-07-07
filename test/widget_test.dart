import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fingerprint/game/world/maze/fingerprint_generator.dart';

void main() {
  group('FingerprintGenerator Tests', () {
    test('Logical maze has correct dimensions', () {
      final generator = FingerprintGenerator(cols: 10, rows: 10, type: FingerprintType.whorl);
      expect(generator.grid.length, 10);
      expect(generator.grid[0].length, 10);
    });

    test('Logical maze cell has visited all paths', () {
      final generator = FingerprintGenerator(cols: 5, rows: 5, type: FingerprintType.arch);
      for (final col in generator.grid) {
        for (final cell in col) {
          expect(cell.visited, isTrue, reason: 'Every cell in a completed maze must be visited');
        }
      }
    });

    test('Warped positions are computed successfully', () {
      final generator = FingerprintGenerator(cols: 8, rows: 8, type: FingerprintType.loop);
      final size = const Size(800, 600);
      
      final posCenter = generator.getWarpedPosition(4, 4, size);
      expect(posCenter, isNotNull);
    });
  });
}
