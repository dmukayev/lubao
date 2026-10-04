/// Буквы любого алфавита (\p{L}), пробел, дефис, апостроф, точка; 2-80
/// символов; без цифр. Зеркало серверного валидатора —
/// backend/src/common/validators/person-name.validator.ts — держать
/// идентичным.
final personNameRegex = RegExp(r"^[\p{L}\s\-'.]{2,80}$", unicode: true);

bool isValidPersonName(String value) => personNameRegex.hasMatch(value.trim());
