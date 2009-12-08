variavel [a-zA-Z]([a-zA-Z0-9]|_)*
int [0-9]
float ([0-9]*\.[0-9]+)([eE][-+]?[0-9]+)?

%{
     /*
        Portugol versao 3 - lex
        Autores: Ed Prado, Edinaldo Carvalho, Elton Oliveira
                 Marlon Chalegre, Rodrigo Castro
        Emails: {msgprado, truetypecode, elton.oliver,
                 marlonchalegre, rodrigomsc}@gmail.com
    */
 
    #include "quadruplas.h"
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

"inicio"    { return INICIO; }
"fim"       { return FIM; }
"int"       { return INT; }
"texto"     { return TEXTO; }
"entao"     { return THEN; }
"senao"     { return ELSE; }
"e"         { return AND; }
"ou"        { return OR; }
"nao"       { return NOT; }
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
                        if (!strcmp(val, "ou")) {
                            return OR;
                        }
                        else if (!strcmp(val, "e")) {
                            return AND;
                        }
                        else if (!strcmp(val, "nao")) {
                            return NOT;
                        }
                        else if (!strcmp(val, "para")) {
                            return PARA;
                        }
                        else if (!strcmp(val, "enquanto")) {
                            return ENQUANTO;
                        }
                        else if (!strcmp(val, "se")) {
                            return IF;
                        }
                        else if (!strcmp(val, "aborte")) {
                            return ABORTE;
                        }
			else if (!strcmp(val, "imprima")) {
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
