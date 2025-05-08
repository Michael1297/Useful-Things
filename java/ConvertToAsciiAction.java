import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ConvertToAsciiAction {

    private static final Pattern UNICODE_ESCAPE_PATTERN = Pattern.compile("\\\\u([0-9a-fA-F]{4})");

    private static String native2ascii(String text){
        return native2ascii(text, false);
    }

    private static String native2ascii(String text, boolean ignoreLatinCharacters) {
        if (text == null || text.isEmpty()) {
            return text; // Если строка пустая или null, возвращаем как есть
        }

        StringBuilder unicodeText = new StringBuilder();
        for (char character  : text.toCharArray()) {
            if((int) character > Byte.MAX_VALUE || ignoreLatinCharacters){
                unicodeText.append(String.format("\\u%04x", (int) character));
            } else {
                unicodeText.append(character);
            }

        }
        return unicodeText.toString();
    }

    public static String ascii2native(String text) {
        if (text == null || text.isEmpty()) {
            return text; // Если строка пустая или null, возвращаем как есть
        }

        Matcher matcher = UNICODE_ESCAPE_PATTERN.matcher(text);
        StringBuilder sb = new StringBuilder();
        while (matcher.find()) {
            int codePoint = Integer.parseInt(matcher.group(1), 16); // Преобразуем hex-код в десятичное число
            matcher.appendReplacement(sb, Character.toString((char) codePoint));
        }
        matcher.appendTail(sb);

        return new String(sb.toString().getBytes(StandardCharsets.UTF_8), StandardCharsets.UTF_8); // Декодируем строку в UTF-8
    }

    public static void main(String[] args) throws UnsupportedEncodingException {

        System.out.println(native2ascii("123 test тест", false));
        System.out.println(ascii2native("123 test \\u0442\\u0435\\u0441\\u0442"));
    }
}
