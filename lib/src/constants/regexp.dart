class RegexpRules {
  static final onlyNumbers = RegExp(r'^\d+');
  static final onlyNumersDecimal = RegExp(r'^\d*\.?\d*');
  static final onlyLetters = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]');
  static final allValidCharacters = RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9,.!?¿¡ ]');
}
