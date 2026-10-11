/// Till alert sounds, from `assets/sounds/`.
enum AlertSound {
  notFound('noProdNew.mp3'),
  expired('expiredNew.mp3'),
  ageCheck('ageRefusalNew.mp3'),
  promotion('PromotionNew.mp3'),
  warning('warning.mp3');

  const AlertSound(this.file);
  final String file;
}

/// Implemented in `infrastructure/hardware`; screens get it from `app/di`.
abstract interface class AlertSounds {
  Future<void> play(AlertSound sound);
}
