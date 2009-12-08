variavel [a-zA-Z]([a-zA-Z0-9]|_)*
int [0-9]

%{
     /*
        C88 versao 1 - lex
        Autores: Elton Oliveira, Marlon Chalegre
                 Rodrigo Castro, Romulo Jales
        Emails: {elton.oliver, marlonchalegre
                 rodrigomsc, romulojales}@gmail.com
    */
 
    #include "Tabela.h"
    #include "y.tab.h"
    #include <stdlib.h>
    #include <string.h>

    void yyerror(char *);
    extern char msg[80];

    void trim(char s[]) {
        int size = strlen(s);
        int i;
        for (i = 0; s[i] != '\0' && s[i] != ' ' && s[i] != '\t'; i++);
        if (i < size)
            s[i] = '\0';
    }
%}
%%

((\/\/[^\n]*\n)|\n) { yylineno++; } 

"begin"    { return INICIO; }
"end"       { return FIM; }
"int"       { return INT; }
"string"     { return TEXTO; }
"then"     { return THEN; }
"else"     { return ELSE; }
"and"         { return AND; }
"or"        { return OR; }
"not"       { return NOT; }
"abort"    { return ABORTE; }
;           { return *yytext;}


{variavel} { 
                yylval.tb = achaId(yytext);
                return ATOMO;
           }

{int}+     {                    
                int val = atoi(yytext);
                yylval.tb = achaInt(val);
                return ATOMO;
           } 

{variavel}[ \t]*\(  {
                        char *val = strdup(yytext); 
                        val[yyleng-1] = '\0';
                        trim(val); /* Elimina espacos e tabulacoes extras */
                        yyless(yyleng-1);
                        if (!strcmp(val, "or")) {
                            return OR;
                        }
                        else if (!strcmp(val, "and")) {
                            return AND;
                        }
                        else if (!strcmp(val, "not")) {
                            return NOT;
                        }
                        else if (!strcmp(val, "while")) {
                            return ENQUANTO;
                        }
                        else if (!strcmp(val, "if")) {
                            return IF;
                        }
			else if (!strcmp(val, "print")) {
			    return IMPRIMA;
			}
			else if (!strcmp(val, "read")) {
			    return LEIA;
			}
                    }

\"[^"\n]*["\n] {
                    char *val = strdup(yytext+1);
                    if (val[yyleng-2] != '"')
                        yyerror("String terminada incorretamente.");
                    else
                        val[yyleng-2] = '\0';
                    yylval.tb = achaStr(val);
                    return ATOMO;
               }

"<="        {return MENORIGUAL;}
">="        {return MAIORIGUAL;}
"=="        {return IGUAL;}
"!="        {return DIFERENTE;}

[-+><()=/*,&%] { return *yytext; }

[ \t\r]*    {;/*Ignora espaço em branco */}

                
.           {
                sprintf(msg, "Caracter Desconhecido: '%s' (%d)", yytext, yytext[0]);
                yyerror(msg);
            }

%%

int yywrap(void) {
    return 1;
}
