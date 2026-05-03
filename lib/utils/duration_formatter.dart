String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

String formatDurationFull(Duration duration) {
  if (duration == Duration.zero) return '0h 00m';
  return formatDuration(duration);
}
