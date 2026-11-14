import 'package:flutter/services.dart';

class PriceInputFormatter extends TextInputFormatter {
  const PriceInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final output = StringBuffer();
    var decimalPointAdded = false;
    var cursorOffset = 0;
    final selectionOffset = newValue.selection.extentOffset;

    for (var index = 0; index < newValue.text.length; index++) {
      var character = newValue.text[index];
      if (character == ',') {
        character = '.';
      }

      final codeUnit = character.codeUnitAt(0);
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isDecimalPoint = character == '.' && !decimalPointAdded;
      if (isDigit || isDecimalPoint) {
        output.write(character);
        if (isDecimalPoint) {
          decimalPointAdded = true;
        }
        if (index < selectionOffset) {
          cursorOffset++;
        }
      }
    }

    final text = output.toString();
    if (text == newValue.text) {
      return newValue;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }
}
