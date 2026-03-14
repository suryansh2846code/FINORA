import 'dart:math';

class CalculateWeight {
  // Coefficients for W = a * L^b
  // Length in cm, Weight in grams
  static const Map<String, Map<String, double>> _speciesCoefficients = {
    'gilt-head bream': {'a': 0.012, 'b': 3.02},
    'red sea bream': {'a': 0.016, 'b': 3.00},
    'striped red mullet': {'a': 0.008, 'b': 3.20},
    'black sea sprat': {'a': 0.006, 'b': 3.00},
    'house mackerel': {'a': 0.007, 'b': 3.00},
    'red mullet': {'a': 0.009, 'b': 3.10},
    'sea bass': {'a': 0.010, 'b': 3.00},
    'shrimp': {'a': 0.001, 'b': 3.00},
    'trout': {'a': 0.011, 'b': 3.02},
    'default': {'a': 0.011, 'b': 3.00},
  };

  double call({required double lengthCm, String? species}) {
    final coefficients = _speciesCoefficients[species?.toLowerCase()] ??
        _speciesCoefficients['default']!;

    final a = coefficients['a']!;
    final b = coefficients['b']!;

    // W = a * L^b
    return a * pow(lengthCm, b);
  }
}
