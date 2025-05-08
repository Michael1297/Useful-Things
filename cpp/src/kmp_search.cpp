#include <string>
#include <vector>
#include <iostream>

/*
    Функция возвращает номер индекса найденного образа (pattern) в строке (str).
    Образ может содержать символы '?' - который заменяет любой символ
    Алгоритм Кнута-Морриса-Пратта
*/
int find_substring(const std::string& str, const std::string& pattern)
{
    std::vector<int> pf (pattern.length());

    pf[0] = 0;
    for (int k = 0, i = 1; i < pattern.length(); i++)
    {
        while ((k > 0) && (pattern[i] != pattern[k]))
            k = pf[k-1];

        if (pattern[i] == pattern[k])
            k++;
        pf[i] = k;
    }

    for (int match_len = 0, i = 0; i < str.length(); i++)
    {
        bool reset = false;

        while ((match_len > 0) && (pattern[match_len] != str[i])) {

            if(pattern[match_len] == '?') {

                if(match_len > 0 && reset) {

                    int kmp_value = find_substring(str.substr(i-match_len, i), pattern.substr(0, match_len));

                    if(kmp_value != 0)
                        match_len = 0;
                    else if(pattern[match_len - 1] == '?')
                        match_len++;
                }

                break;
            }

            match_len = pf[match_len-1];
            reset = true;
        }

        if(reset && pattern[match_len] == str[i-1]){
            match_len++;
        }

        if (pattern[match_len] == str[i] || pattern[match_len] == '?')
            match_len++;

        if (match_len == pattern.length())
            return (i - pattern.length() + 1);
    }

    return -1;
}


int main() {

    std::cout << find_substring("ddabcd", "??bf") << '\n';  // returns  -1
    std::cout << find_substring("abcd", "a?cd") << '\n';    // returns  0
    std::cout << find_substring("abcd", "abcd") << '\n';    // returns  0
    std::cout << find_substring("abcd", "ab") << '\n';      // returns  0
    std::cout << find_substring("ab", "abcd") << '\n';      // returns  -1
    std::cout << find_substring("ababc", "abc") << '\n';    // returns  2
    std::cout << find_substring("aabaabbaaabaabaabaabaabbaabb", "aabbaab") << '\n'; // returns  20
    std::cout << find_substring("aabaabbaaabaabaabaabaabbaabb", "aa?b??b") << '\n'; // returns  20

    return 0;
}
