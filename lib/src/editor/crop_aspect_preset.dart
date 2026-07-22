enum CropAspectPreset {
  free(null),
  landscapeWide(16 / 9),
  landscape(3 / 2),
  square(1),
  portrait(2 / 3),
  portraitTall(9 / 16);

  final double? ratio;

  const CropAspectPreset(this.ratio);

  static CropAspectPreset fromRatio(double? ratio) {
    if (ratio == null) return free;
    return values.firstWhere(
      (preset) => preset.ratio != null && (preset.ratio! - ratio).abs() < 0.001,
      orElse: () => free,
    );
  }
}
