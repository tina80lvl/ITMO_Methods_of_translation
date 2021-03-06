grammar Grammar;

// Directly preceds the lexer class declaration in the h file (e.g. for additional types etc.).
@parser::context {
#include <iostream>
#include <string>
#include <unordered_set>
#include <vector>
#include "Grammar.h"
#include "Unit.h"
#include "NonTerm.h"
#include "Term.h"
}

// Appears in the private part of the parser in the h file.
// The function bodies could also appear in the definitions section, but I want to maximize
// Java compatibility, so we can also create a Java parser from this grammar.
// Still, some tweaking is necessary after the Java file generation (e.g. bool -> boolean).
@parser::members {
char escape(char c) {
    switch(c) {
        case 'n':
            return '\n';
        case 't':
            return '\t';
        case 'r':
            return '\r';
        case '\\':
            return '\\';
        case 'b':
            return '\b';
        case 'a':
            return '\a';
        case 'f':
            return '\f';
        case 'v':
            return '\v';
        default:
            assert(false && "Unknown escape sequence");
    }
}

char get_char(const std::string& s) {
    if (s.length() == 1)
        return s[0];
    return escape(s[1]);
}
}

// Actual grammar starts
// Unused rule to demonstrate some of the special features.
start returns [Grammar grammar]
    :
    '✋:' NTERM ';'     { $grammar = Grammar($NTERM.text); }
    (
        non_terminal
        {
            $grammar.add_non_term($non_terminal.non_term);
        }
    )+
    (
        terminal
        {
            $grammar.add_term($terminal.term);
        }
    )+
    (
        skip_symbols
        {
            $grammar.skip_symbols = $skip_symbols.skip_chars;
        }
    )?
;

non_terminal returns [NonTerm non_term]
    : NTERM
        ( '🤓'   Attr  { $non_term.arg_list = $Attr.text.substr(1, $Attr.text.length() - 2); })?
        ( '🤯'  Attr  { $non_term.ret_type = $Attr.text.substr(1, $Attr.text.length() - 2); })?
        ':'     { $non_term.name = $NTERM.text; }
        ('🤔' production
            {
                $non_term.add_rule($production.rule, $production.code, $production.exp_list);
            }
        )+
        ';'
;

production returns [Rule rule, std::string code, std::vector<std::string> exp_list]
    : (   NTERM      {
                        $exp_list.push_back("");
                        $rule.push_back($NTERM.text);
                     }
                     (Code { $exp_list.back() = $Code.text.substr(1, $Code.text.length() - 2); } )?
        | TERM       {
                        $exp_list.push_back("");
                        $rule.push_back($TERM.text);
                     }
      )+
      (Code  {$code = $Code.text.substr(1, $Code.text.length() - 2);} )?
    | (Code  {$code = $Code.text.substr(1, $Code.text.length() - 2);} )?    { $rule.push_back("#"); }
;

terminal returns [Term term]
    : TERM ':' STRING ';'   { $term = Term($TERM.text, $STRING.text); }
;

skip_symbols returns [std::unordered_set<char> skip_chars]:
    '👉:'
     (
        SYMBOL    { $skip_chars.insert(get_char($SYMBOL.text.substr(1, $SYMBOL.text.length()-2))); }
     )+
     ';'
;

TERM   : [A-Z][a-zA-Z0-9_]*;
NTERM  : [a-z][a-zA-Z0-9_]*;
Attr: '[' .*? ']';
//ExpList: '(' .*? ')';
STRING : '"' .*? '"';
SYMBOL : '\'' ('\\')? . '\'';
Code   : '{' .*? '}';
WS     : (' ' | '\t' | '\r'| '\n') -> skip;
//CODE   : '{' (~[{}]+ CODE?)* '}';