%{
    #include <stdio.h>
    #include <math.h>
    #include <string.h>
    #include <stdlib.h>
    #include "Tabela.h"
    #include "Fila.h"
    #include "Stack.h"

    FILE *file;
    void yyerror(char *);
    int yylex(void);
    int *copy_int(int *value);
    void desempilhar(void);
    void validaTipoAtribuicao(tabelaSimb *s1, tabelaSimb *s2);
    tipoDado defineTipo(tabelaSimb *s1, tabelaSimb *s2);
    tabelaSimb *alloc_tabelaSimb();
    tabelaSimb *mnemonico(tabelaSimb *s1, tabelaSimb *s2, char buffer[]);
    void geraSaidaTemplate(FILE *file);
    void load(tabelaSimb *s);
    void verificaUso(tabelaSimb *s);
    int yylineno;
    int tp_count = 0;
    int *l;
    int count_if_else = 0;
    int count_para = 0;
    int numParam = 0;
    char msg[80];
    Stack *stack_if;
    Stack *stack_enquanto;
    Stack *stack_para_label;
    Stack *stack_para_atribuicao;
    Queue *queue_geral;
    char command[100];
%}

%union {
    tabelaSimb *tb;
}

%token INICIO FIM
//%token <tb> IDENTIFICADOR
//%token <tb> TEXTO
%token <tb> ATOMO FUNCAO 
%token <tipo> TIPO
%token SQRT INT FLOAT TEXTO 
%token IF
%token ENQUANTO PARA
%token IMPRIMA ABORTE SAIA
%token MAIORIGUAL IGUAL MENORIGUAL DIFERENTE
%right '='
%left '<' '>' MENORIGUAL MAIORIGUAL IGUAL DIFERENTE
%left '%'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS THEN ELSE AND OR NOT
%type <tb> expressao
%type <tb> expressao_relacional
%type <tb> expressao_logica
%type <tb> atribuicao
%expect 3
%%

programa:
        bloco_instrucao
        ;

declaracao:
        INT ATOMO {
                                verificaUso($2); 
                                $2->tipoD = tipoIdInt; 
                                $2->load = 1;
                                sprintf(command, "\tMOV (%d), 0\n", $2->idx);
                                enqueue(queue_geral, strdup(command));
                          }
        /*| TEXTO ATOMO {
                                verificaUso($2); 
                                $2->tipoD = tipoIdStr; 
                                $2->load = 1;
                                sprintf(command, "\tloads(\"\", NULL, &%s);\n", $2->tval);
                                enqueue(queue_geral, strdup(command));
                            }*/

        ;

atribuicao:
        ATOMO '=' expressao {
                                        validaTipoAtribuicao($1, $3);
                                        sprintf(command,"\tMOV (%d), %s\n", $1->idx, $3->tval);
                                        enqueue(queue_geral, strdup(command) );
                                        $$ = $3;
				    }
        /*| IDENTIFICADOR '=' atribuicao {
                                            sprintf(command,"\tmov(%s, NULL, &ts[%d]);\n", $3, $1);
                                            enqueue(queue_geral, strdup(command) );
                                            $$ = $3;
                                          }*/
        ;

expressao_relacional:
        expressao '>' expressao {
                                        sprintf(command,"\tcomp_gt(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                        $$ = mnemonico($1, $3, strdup(command));
                                }

	| expressao '<' expressao {
                                        sprintf(command, "\tcomp_lt(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                        $$ = mnemonico($1, $3, strdup(command));
                                  }

	| expressao MENORIGUAL expressao {
                                            sprintf(command, "\tcomp_le(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                            $$ = mnemonico($1, $3, strdup(command));
                                         }

	| expressao MAIORIGUAL expressao {
                                            sprintf(command, "\tcomp_ge(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                            $$ = mnemonico($1, $3, strdup(command));
                                         }

	| expressao IGUAL expressao {
                                        sprintf(command, "\tcomp_eq(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao DIFERENTE expressao {
                                            sprintf(command, "\tcomp_ne(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                            $$ = mnemonico($1, $3, strdup(command));
                                        }
        ;

expressao:
        ATOMO                       { 
                                        tabelaSimb *s = alloc_tabelaSimb();
                                        s->tval = strdup($1->tval);
                                        s->tipoD = $1->tipoD;
                                        if (!$1->load) {
                                            load($1);
                                        }

                                        $$ = s; 
                                    }
        | FUNCAO '(' lista_parametros ')' {
                                        tabelaSimb *s = alloc_tabelaSimb();
                                        if ($1->tipoD == tipoIdFuncVoid) {
                                            sprintf(command, "\tcall(\"%s\", %d, NULL);\n", $1->idNome, numParam, tp_count++);
                                            enqueue(queue_geral, strdup(command));
                                            s->tval = "";
                                        }
                                        else {
                                            sprintf(command, "\tcall(\"%s\", %d, &tp[%d]);\n", $1->idNome, numParam, tp_count++);
                                            enqueue(queue_geral, strdup(command));
                                            sprintf(command, "tp[%d]", tp_count-1);
                                            s->tval = strdup(command);
                                        }
                                        $1->numParam = numParam;
                                        numParam = 0;
                                        
                                        s->tipoD = $1->tipoD;
                                        $$ = s;
                                      }

        /*| IDENTIFICADOR             { 
                                        tabelaSimb *s = alloc_tabelaSimb();
                                        s->tval = strdup($1->tval);
                                        s->tipoD = $1->tipoD;

                                        $$ = s;
                                    }*/

        | expressao '+' expressao   {
                                        sprintf(command,"\tMOV AX, %s\n\tADD AX, %s\n\tMOV CX, AX\n", $1->tval, $3->tval);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao '-' expressao   {
                                        sprintf(command,"\tsub(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao '*' expressao   { 
                                        sprintf(command,"\tmult(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao '/' expressao   {
                                        sprintf(command,"\tdivi(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao '%' expressao   {
                                        sprintf(command,"\tmod(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | '-' expressao %prec UMINUS {
                                        sprintf(command,"\tuminus(%s, NULL, &tp[%d]);\n", $2->tval, tp_count++);
                                        $$ = mnemonico($2, NULL, strdup(command));
                                     }

        | '(' expressao ')'         { $$ = $2; }
        ;

/*sentenca:
        IMPRIMA ATOMO ')' ';' {
                            sprintf(command, "\tparam(%s, NULL, NULL);\n", $2->tval); 
                            enqueue(queue_geral,strdup(command));
                            sprintf(command, "\tcall(\"imprima\", 1, NULL);\n");
                            enqueue(queue_geral,strdup(command));
                          }
        | IMPRIMA IDENTIFICADOR ';' {

                                        sprintf(command, "\tparam(%s, NULL, NULL);\n", $2->tval); 
                                        enqueue(queue_geral,strdup(command));
                                        sprintf(command, "\tcall(\"imprima\", 1, NULL);\n");
                                        enqueue(queue_geral,strdup(command));
                                    }
        ;
*/
lista_parametros:
                /* Lista vazia. Funcao sem parametros. */
                | '&'ATOMO {
                            if (!$2->load) {
                                load($2);
                            }
                            sprintf(command, "\tparam(NULL, NULL, &%s);\n", $2->tval);
                            enqueue(queue_geral, strdup(command));
                            numParam++;

                           }
                | expressao {
                            //if (!$1->load) {
                            //    load($1);
                            //}
                            sprintf(command, "\tparam(&%s, NULL, NULL);\n", $1->tval);
                            enqueue(queue_geral, strdup(command));
                            numParam++;
                        }
                | '&'ATOMO ',' lista_parametros {
                                                    if (!$2->load) {
                                                        load($2);
                                                    }
                                                    sprintf(command, "\tparam(NULL, NULL, &%s);\n", $2->tval);
                                                    enqueue(queue_geral, strdup(command));
                                                    numParam++;
                                                }
                | expressao ',' lista_parametros {
                                                //if (!$1->load) {
                                                //    load($1);
                                                //}
                                                sprintf(command, "\tparam(&%s, NULL, NULL);\n", $1->tval);
                                                enqueue(queue_geral, strdup(command));
                                                numParam++;
                                             }
                ;

/*funcao:
      FUNCAO lista_parametros ')' {
                                    sprintf(command, "\tcall(\"%s\", 1, NULL);\n", $1->idNome);
                                    enqueue(queue_geral, strdup(command));
                                    $1->numParam = numParam;
                                    numParam = 0;
                                  }
      ;
*/
label_para_inicio: {
                        sprintf(command, " l%d:\n", (*l)++);
                        enqueue(queue_geral, strdup(command));
                   }
                   ;

posicionar_segunda_atribuicao:
                    {
                        char *value;
                        Stack *stack_tmp = init_stack();
                        int *label = (int *) pop(stack_para_label);

                        value = (char *) pop(stack_para_atribuicao);
                        while (strcmp(value, "fim") && !is_stack_empty(stack_para_atribuicao)) {
                            push(stack_tmp, (void *) value);
                            value = (char *) pop(stack_para_atribuicao);
                        }

                        while (!is_stack_empty(stack_tmp)) {
                            value = (char *) pop(stack_tmp);
                            enqueue(queue_geral, value);
                        }

                        sprintf(command, "\tjump(NULL, NULL, l%d);\n", *label-1);
                        enqueue(queue_geral, strdup(command));
                        sprintf(command, " l%d:\n", *label);
                        enqueue(queue_geral, strdup(command));
                    }
                    ;

retirar_segunda_atribuicao:
                     {
                        char *value; 
                        enqueue(queue_geral, "fim_atribuicao_para");

                        while (!is_queue_empty(queue_geral)) {
                            value = dequeue(queue_geral);
                            if (!strcmp(value, "inicio_atribuicao_para"))
                                break;
                            enqueue(queue_geral, value);
                        }
                        push(stack_para_atribuicao, (void *) "fim");
                        while (!is_queue_empty(queue_geral)) {
                            value = dequeue(queue_geral);
                            if (!strcmp(value, "fim_atribuicao_para"))
                                break;
                            push(stack_para_atribuicao, (void *) value);
                        }
                     }
                     ;

marcar_inicio_atribuicao:
                        {
                            push(stack_para_label, (void *) copy_int(l));
                            sprintf(command,"\tjump_f(tp[%d], NULL, l%d);\n", tp_count-1, (*l)++);
                            enqueue(queue_geral,strdup(command));
                            enqueue(queue_geral, "inicio_atribuicao_para"); 
                        }
                        ;

para:
    PARA '(' atribuicao ';' label_para_inicio expressao_logica ';' marcar_inicio_atribuicao atribuicao retirar_segunda_atribuicao ')' instrucao posicionar_segunda_atribuicao
    ;

label_enquanto_inicio: {
                            sprintf(command, " l%d:\n", (*l)++);
                            enqueue(queue_geral,strdup(command));
                       }
                       ;
label_enquanto_fim: {
                        int *label = (int *) pop(stack_enquanto);
                        sprintf(command, "\tjump(NULL, NULL, l%d);\n", *label-1);
                        enqueue(queue_geral,strdup(command));
                        sprintf(command, "l%d:\n", *label); 
                        enqueue(queue_geral,strdup(command));
                        free(label);
                    }
                    ;
inicio_enquanto: {
                    push(stack_enquanto,(void *) copy_int(l));
                    sprintf(command,"\tjump_f(tp[%d], NULL, l%d);\n", tp_count-1, (*l)++);
                    enqueue(queue_geral,strdup(command));
                 }
                 ;
enquanto:
        ENQUANTO '(' label_enquanto_inicio expressao_logica ')' inicio_enquanto instrucao label_enquanto_fim
        ;

inicio_selecao: {
                push(stack_if, (void *) copy_int(l));
                sprintf(command,"\tjump_f(tp[%d], NULL, l%d);\n", tp_count-1, (*l)++);
                enqueue(queue_geral,strdup(command));
                count_if_else++;
           }
           ;

label_selecao: {
                    int *label = (int *) pop(stack_if);
                    sprintf(command, " l%d:\n", *label);
                    enqueue(queue_geral,strdup(command));
                    free(label);
               }
               ;
bloco_selecao: {
                    enqueue(queue_geral,"jump_incondicional");
               }
               ;
selecao: 
	IF '(' expressao_logica ')' inicio_selecao THEN instrucao label_selecao
        | IF '(' expressao_logica ')' inicio_selecao THEN instrucao ELSE bloco_selecao label_selecao instrucao
	;

expressao_logica:
                expressao_relacional {
                                        //sprintf(command, "tp[%d]", tp_count-1);
                                        $$ = $1; 
                                     }

                | expressao_relacional AND expressao_logica {
                                                                sprintf(command, "\trela_an(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                            }
                | expressao_logica AND expressao_relacional { 
                                                                sprintf(command, "\trela_an(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                            }
                | expressao_logica OR expressao_relacional {
                                                                sprintf(command, "\trela_or(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                           }
                | expressao_relacional OR expressao_logica {
                                                                sprintf(command, "\trela_or(%s, %s, &tp[%d]);\n", $1->tval, $3->tval, tp_count++);
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                           }
                | NOT expressao_logica {
                                            sprintf(command, "\trela_no(%s, NULL, &tp[%d]);\n", $2->tval, tp_count++);
                                            $$ = mnemonico($2, NULL, strdup(command));
                                       }

                | '(' expressao_logica ')' { $$ = $2; }
                ;

aborte:
     '(' ABORTE ')' ';' {
                    sprintf(command, "\thalt(NULL, NULL, NULL);\n");
                    enqueue(queue_geral, strdup(command));
                 }
      ;

saia:
    SAIA '(' ATOMO ')' ';' {
                                switch ($3->tipoD) {
                                    case tipoConInt:
                                        if (!$3->load)
                                            load($3);
                                    case tipoIdInt:
                                        sprintf(command, "\tparam(%s, NULL, NULL);\n", $3->tval);
                                        enqueue(queue_geral, strdup(command));
                                        break;
                                    default:
                                        yyerror("Parametro deve ser um inteiro.");
                                        break;
                                }
                                sprintf(command, "\tcall(\"exit\", 1, NULL);\n");
                                enqueue(queue_geral, strdup(command));
                           }
    ;

instrucao:
	selecao { 
                    desempilhar();
                    count_if_else--;
                    if (!count_if_else) { // label de jump incondicional
                        fprintf(file, " l%d:\n", (*l)++);
                        fflush(file);
                    }
                }
        | enquanto { desempilhar(); }
        | para { desempilhar(); }
        | aborte { if (count_if_else == 0) desempilhar(); }
        | saia { if (count_if_else == 0) desempilhar(); }
        | expressao_logica
        //| funcao ';' { if (count_if_else == 0) desempilhar(); }
//        | sentenca { if (count_if_else == 0) desempilhar(); }
        | declaracao ';' { if (count_if_else == 0) desempilhar(); }
	| atribuicao ';' { if (count_if_else == 0) desempilhar(); } 
        | expressao ';' { if (count_if_else == 0) desempilhar(); } 
	| bloco_instrucao
        | ';' { if (count_if_else == 0) {
                    fprintf(file, "\tnop(NULL, NULL, NULL);\n");
                    fflush(file);
                } else {
                    enqueue(queue_geral,"\tnop(NULL, NULL, NULL);\n");
                }
        }
	;
conjunto_instrucao:
	instrucao
	| conjunto_instrucao instrucao
	;
bloco_instrucao:
	INICIO ';' imprimir_label FIM ';' {
                           }
	| INICIO ';' imprimir_label conjunto_instrucao FIM ';' {
                                                }
	;
imprimir_label: {
                    if (count_if_else == 0 && *l > 1) // Soh imprime se nao estiver em um if
                        fprintf(file, " l%d:\n", (*l)++);
                }
%%

void load(tabelaSimb *s) {
    /*switch (s->tipoD) {
        case tipoConInt:
            sprintf(command, "\tloadi(%d, NULL, &%s);\n", s->ival, s->tval);
            break;
        case tipoConFloat:
            sprintf(command, "\tloadf(%.2f, NULL, &%s);\n", s->fval, s->tval);
            break;
        case tipoConStr:
            sprintf(command, "\tloads(\"%s\", NULL, &%s);\n", s->sval, s->tval);
            break;
        default:
            return;
    }*/
    s->load = 1;
    //enqueue(queue_geral, strdup(command));
}

tabelaSimb *mnemonico(tabelaSimb *s1, tabelaSimb *s2, char cmd[100]) {
    tabelaSimb *s = alloc_tabelaSimb();

    if (s2 != NULL) {
        s->tipoD = defineTipo(s1, s2);
        free(s2);
    }
    else {
        s->tipoD = s1->tipoD;
    }
    free(s1);

    enqueue(queue_geral, cmd);

    sprintf(command, "CX");
    s->tval = strdup(command);
    s->load = 1;
    return s;
}

tabelaSimb *alloc_tabelaSimb() {
    tabelaSimb *s = (tabelaSimb *) malloc(sizeof(tabelaSimb));
    return s;
}

void validaTipoAtribuicao(tabelaSimb *s1, tabelaSimb *s2) {
    switch (s1->tipoD) {
        case tipoIdInt:
            if (s2->tipoD != tipoIdInt && s2->tipoD != tipoConInt &&
                s2->tipoD != tipoIdFuncInt) {
                yyerror("Atribuicao invalida.");
            }
            break;
        case tipoIdFloat:
            if (s2->tipoD != tipoIdFloat && s2->tipoD != tipoConFloat &&
                s2->tipoD != tipoIdFuncFloat && s2->tipoD != tipoIdFuncDouble) {
                yyerror("Atribuicao invalida.");
            }
            break;
        case tipoIdStr:
            if (s2->tipoD != tipoIdStr && s2->tipoD != tipoConStr &&
                s2->tipoD != tipoIdFuncStr) {
                yyerror("Atribuicao invalida.");
            }
            break;
        case tipoIdIndef:
            sprintf(command, "Variavel %s nao declarada.", s1->idNome);
            yyerror(strdup(command));
            break;
        default:
            yyerror("Atribuicao invalida.");
            
    }
}

tipoDado defineTipo(tabelaSimb *s1, tabelaSimb *s2) {
    tipoDado tipo;

    switch (s1->tipoD) {
        case tipoConFloat:
        case tipoIdFloat:
        case tipoIdFuncFloat:
        case tipoIdFuncDouble:
            if (s2->tipoD != tipoConStr && s2->tipoD != tipoIdStr &&
                s2->tipoD != tipoIdFuncStr) {
                tipo = tipoConFloat;
            }
            break;
        case tipoConInt:
        case tipoIdInt:
        case tipoIdFuncInt:
            if (s2->tipoD == tipoConStr || s2->tipoD == tipoIdStr || 
                s2->tipoD == tipoIdFuncStr) {
                yyerror("Tipos incompativeis");
            }
            else if (s2->tipoD == tipoConFloat || s2->tipoD == tipoIdFloat ||
                     s2->tipoD == tipoIdFuncDouble || s2->tipoD == tipoIdFuncFloat) {
                tipo = tipoConFloat;
            }
            else
                tipo = tipoConInt;
            break;
        case tipoConStr:
        case tipoIdStr:
        case tipoIdFuncStr:
            if (s2->tipoD == tipoIdStr || s2->tipoD == tipoConStr ||
                s2->tipoD == tipoIdFuncStr) {
                tipo = tipoConStr;
            }
            else
                yyerror("Tipos incompativeis");
            break; 
        default:
            yyerror("Tipo nao reconhecido");

    }

/*    if ((s1->tipoD == tipoConFloat || s1->tipoD == tipoIdFloat) &&
        (s2->tipoD != tipoConStr && s2->tipoD != tipoIdStr)) {
        tipo = tipoConFloat;
    }
    else if ((s2->tipoD == tipoConFloat || s2->tipoD == tipoIdFloat) &&
        (s1->tipoD != tipoConStr && s1->tipoD != tipoIdStr)) {
        tipo = tipoConFloat;
    }
    else if ((s2->tipoD == tipoConInt || s2->tipoD == tipoIdInt) &&
        (s1->tipoD == tipoConInt || s1->tipoD == tipoIdInt)) {
        tipo = tipoConInt;
    }
    else if ((s1->tipoD == tipoIdStr || s1->tipoD == tipoConStr) && 
        (s2->tipoD == tipoIdStr || s2->tipoD == tipoConStr)) {
        tipo = tipoConStr; 
    }
    else {
        yyerror("Tipos incompativeis");
    }*/

    return tipo;
}

int *copy_int(int *value) {
    int *copy = (int *) malloc(sizeof(int));
    *copy = *value;
    return copy;
}

void desempilhar(void) {
    char *value; 
    while (!is_queue_empty(queue_geral)) {
        value = dequeue(queue_geral);
        if (!strcmp(value, "jump_incondicional")) {
            fprintf(file, "\tjump(NULL, NULL, l%d);\n", *l);
        }
        else {
            fprintf(file,"%s",value);
        }
    }
    fflush(file);
}

void yyerror(char *s) {
    fprintf(stderr, "line %d: %s\n", yylineno, s);
    exit(1);
}

void verificaUso(tabelaSimb *s) {
    char error[200];
    sprintf(error, "Erro: variavel %s ja foi declarada.", s->idNome);
    if (s->load)
        yyerror(error);
}

void geraSaidaTemplate(FILE *file) {
    fprintf(file,
                "!\tGerado pelo compilador PORTUGOL versao 0.1\n"
                "!\tAutores: Ed Prado, Edinaldo Carvalho, Elton Oliveira,\n"
                "!\t\t Marlon Chalegre, Rodrigo Castro\n"
                "!\tEmail: {msgprado, truetypecode, elton.oliver,\n"
                "!\t\tmarlonchalegre, rodrigomsc}@gmail.com\n"
                "!\tData: 26/05/2009\n"
                //";\n#include <stdlib.h>\n"
                //";#include \"quadruplas.h\"\n"
                //";#include \"saida.h\"\n\n"
                //";void filltf();\n\n"                
                //";int main(void)\n{\n"
                //";\tfilltf();\n\n"
		"_EXIT = 1\n"
		".SECT .TEXT\n"
		"main:\n"
                );
}

void criar_filltf() {
    fprintf(file, "\nvoid filltf()\n{\n");
                
    tabelaSimb *sp = NULL;

    for (sp = tabSimb; sp < &tabSimb[MAX_SIMB]; sp++) { 
        /* Existe? */
        if (sp->uso) {
            switch (sp->tipoD) {
                case tipoIdFuncInt:
                    break;
                case tipoIdFuncFloat:
                    break;
                case tipoIdFuncDouble:
                    if (!strcmp(sp->idNome, "leia")) {
                        fprintf(file, "\ttf[%d].tipoRet = tipoRetFuncDouble;\n"
                                      "\ttf[%d].vfunc = (void *) scanf;\n"
                                      "\ttf[%d].idNome = malloc(5);\n"
                                      "\tstrcpy(tf[%d].idNome, \"leia\");\n",
                                      sp->idx, sp->idx, sp->idx, sp->idx
                        );
                    }
                    else if (!strcmp(sp->idNome, "raiz")) {
                        fprintf(file, "\ttf[%d].tipoRet = tipoRetFuncDouble;\n"
                                      "\ttf[%d].dfunc = (void *) sqrt;\n"
                                      "\ttf[%d].idNome = malloc(5);\n"
                                      "\tstrcpy(tf[%d].idNome, \"raiz\");\n",
                                      sp->idx, sp->idx, sp->idx, sp->idx
                        );
                    }
                    else if (!strcmp(sp->idNome, "exp")) {
                        fprintf(file, "\ttf[%d].tipoRet = tipoRetFuncDouble;\n"
                                      "\ttf[%d].dfunc = (void *) exp;\n"
                                      "\ttf[%d].idNome = malloc(4);\n"
                                      "\tstrcpy(tf[%d].idNome, \"exp\");\n",
                                      sp->idx, sp->idx, sp->idx, sp->idx
                        );
                    }
                    else if (!strcmp(sp->idNome, "log")) {
                        fprintf(file, "\ttf[%d].tipoRet = tipoRetFuncDouble;\n"
                                      "\ttf[%d].dfunc = (void *) log;\n"
                                      "\ttf[%d].idNome = malloc(4);\n"
                                      "\tstrcpy(tf[%d].idNome, \"log\");\n",
                                      sp->idx, sp->idx, sp->idx, sp->idx
                        );
                    }
                    else if (!strcmp(sp->idNome, "pow")) {
                        fprintf(file, "\ttf[%d].tipoRet = tipoRetFuncDouble;\n"
                                      "\ttf[%d].dfunc = (void *) pow;\n"
                                      "\ttf[%d].idNome = malloc(4);\n"
                                      "\tstrcpy(tf[%d].idNome, \"pow\");\n",
                                      sp->idx, sp->idx, sp->idx, sp->idx
                        );
                    }
                    break;
                case tipoIdFuncChar:
                    break;
                case tipoIdFuncStr:
                    break;
                case tipoIdFuncVoid: 
                    if (!strcmp(sp->idNome, "imprima")) {
                        fprintf(file, "\ttf[%d].tipoRet = tipoRetFuncVoid;\n"
                                      "\ttf[%d].vfunc = (void *) printf;\n"
                                      "\ttf[%d].idNome = malloc(8);\n"
                                      "\tstrcpy(tf[%d].idNome, \"imprima\");\n",
                                      sp->idx, sp->idx, sp->idx, sp->idx
                        );
                    }
                    
                    else if (!strcmp(sp->idNome, "saia")) {
                        fprintf(file, "\ttf[%d].tipoRet = tipoRetFuncVoid;\n"
                                      "\ttf[%d].vfunc = (void *) exit;\n"
                                      "\ttf[%d].idNome = malloc(5);\n"
                                      "\tstrcpy(tf[%d].idNome, \"saia\");\n",
                                      sp->idx, sp->idx, sp->idx, sp->idx
                        );
                    }
                    break;
                default:
                    /* Nao eh uma funcao */
                    break;
            }
        }
    }

//    fprintf(file, "}\n");
}

int main(int argc, char **argv) {
    file = fopen("out.asm","w");
    iniciarTabelaSimb();
    
    l = malloc(sizeof(int));
    *l = 1;

    stack_if = init_stack();
    stack_enquanto = init_stack();
    stack_para_label = init_stack();
    stack_para_atribuicao = init_stack();
    queue_geral = init_queue();

    if(!file){
        printf("O arquivo nao pode ser aberto!\n");
        exit(1);
    }
    
    geraSaidaTemplate(file);

    FILE *yyin;
    if (argc > 1) {
        if ((yyin = fopen(argv[1], "r")) == NULL) {
            printf("erro ao ler arquivo de entrada.\n");
            exit(1);
        }
        yyrestart(yyin); 
    }
            
    yyparse();
    if (argc > 1) fclose(yyin);    

    fprintf(file,"\tPUSH _EXIT\n\tSYS\n.SECT .DATA \n\n");
    //criar_filltf();
    fclose(file);
    geraSaidaH();
}
