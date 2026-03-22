class Mountain {
  final List<double> heightMap;

  const Mountain({required this.heightMap});

  Map<String, dynamic> toJson() => {
        'heightMap': heightMap,
      };

  factory Mountain.fromJson(Map<String, dynamic> json) {
    return Mountain(
      heightMap: (json['heightMap'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  double heightAt(double x) {
    if (heightMap.isEmpty) return 0.0;
    if (x <= 0) return heightMap.first;
    if (x >= heightMap.length - 1) return heightMap.last;

    final ix = x.floor();
    final frac = x - ix;
    final h0 = heightMap[ix];
    final h1 = ix + 1 < heightMap.length ? heightMap[ix + 1] : h0;
    return h0 + (h1 - h0) * frac;
  }
}
