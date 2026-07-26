import 'package:flutter/material.dart';

/// Font family constants
class AppFonts {
  static const String plusJakartaSans = 'PlusJakartaSans';
  static const String notoNastaliqUrdu = 'NotoNastaliqUrdu';
}

/// Build a TextStyle with the correct font family based on language.
/// Uses PlusJakartaSans for English UI, NotoNastaliqUrdu for Urdu text
/// to match the web app's index.css .font-urdu class.
TextStyle appTextStyle({
  required BuildContext context,
  required TextStyle base,
  bool forceUrdu = false,
}) {
  final isUrdu = forceUrdu ||
      Localizations.localeOf(context).languageCode == 'ur';
  return base.copyWith(
    fontFamily:
        isUrdu ? AppFonts.notoNastaliqUrdu : AppFonts.plusJakartaSans,
    height: isUrdu ? 2.2 : null, // Web app uses line-height: 2.2 for Urdu
  );
}

/// A [Text] widget that automatically uses the correct font for Urdu.
class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool isUrdu;

  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isUrdu = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUrduLocale =
        isUrdu || Localizations.localeOf(context).languageCode == 'ur';
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontFamily: isUrduLocale
          ? AppFonts.notoNastaliqUrdu
          : AppFonts.plusJakartaSans,
      height: isUrduLocale ? 2.2 : null,
    );

    return Text(
      data,
      style: effectiveStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
