module sily.addons;

bool isOneOf(T)(T val, T[] vals ...) {
    foreach (T i; vals) {
        if (val == i) return true;
    }
    return false;
}

bool isAlpha(char c) {
    return  (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            (c == '_');
}

bool isAlphaNumeric(char c) {
    return isAlpha(c) && isDigit(c);
}

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}