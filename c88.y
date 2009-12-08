%{
    /*
        C88 versao 1 - yacc 
        Autores: Elton Oliveira, Marlon Chalegre
                 Rodrigo Castro, Romulo Jales
        Emails: {elton.oliver, marlonchalegre
                 rodrigomsc, romulojales}@gmail.com
    */

    #include <stdio.h>
    #include <math.h>
    #include <string.h>
    #include <stdlib.h>
    #include "tabela.h"
    #include "fila.h"
    #include "stack.h"

    FILE *file;
    void yyerror(char *);
    int yylex(void);
    int *copy_int(int *value);
    void desempilhar(Queue* queue);
    void validaTipoAtribuicao(tabelaSimb *s1, tabelaSimb *s2);
    tipoDado defineTipo(tabelaSimb *s1, tabelaSimb *s2);
    tabelaSimb *alloc_tabelaSimb();
    tabelaSimb *mnemonico(tabelaSimb *s1, tabelaSimb *s2, char buffer[]);
    void gera_procedimento_read();
    void geraSaidaTemplate(FILE *file);
    void load(tabelaSimb *s);
    void verificaUso(tabelaSimb *s);
    int yylineno;
    int cond_count = 1;
    int cond_mem = 500;
    int *l;
    int count_if_else = 0;
    int chamou_leia = 0;
    char msg[80];
    Stack *stack_if;
    Stack *stack_enquanto;
    Queue *queue_geral;
    Queue *queue_data;
    Queue *queue_bss;
    char command[10000];
%}

%union {
    tabelaSimb *tb;
}

%token INICIO FIM
%token <tb> ATOMO
%token <tipo> TIPO
%token INT TEXTO 
%token IF
%token ENQUANTO
%token IMPRIMA ABORTE LEIA 
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
        bloco_instrucao imprime_data_bss
        ;

declaracao:
        INT ATOMO {
                                verificaUso($2); 
                                $2->tipoD = tipoIdInt; 
                                $2->load = 1;
                                sprintf(command, "\tMOV (%d), 0\n", $2->idx);
                                enqueue(queue_geral, strdup(command));
                          }
        | TEXTO ATOMO {
                                verificaUso($2); 
                                $2->tipoD = tipoIdStr; 
				sprintf(command,
					"strd%d: .SPACE 80\n",
					$2->idx);
                            	enqueue(queue_bss, strdup(command));
                                $2->load = 1;
				
                            }

        ;

atribuicao:
        ATOMO '=' expressao {
                                validaTipoAtribuicao($1, $3);
				if ($1->tipoD == tipoIdStr) {
				    sprintf(command, "(%d)", $1->idx);
			    	    $1->tval = strdup(command);
				}
                                sprintf(command,"\tMOV %s, %s\n", $1->tval, $3->tval);
                                enqueue(queue_geral, strdup(command) );
                                $$ = $3;
			    }
        ;

expressao_relacional:
        expressao '>' expressao {
                                        sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tCMP AX, CX\n"
						"\tJLE cond%d\n"
						"\tMOV (%d), 1\n"
						"\tJMP cond%d\n"
						"cond%d:\n"
						"\tMOV (%d), 0\n"
						"cond%d:\n",
						$1->tval, $3->tval, cond_count, cond_mem,
						cond_count + 1, cond_count, cond_mem, cond_count + 1);
					cond_count += 2;
					cond_mem += 2;
                                        $$ = mnemonico($1, $3, strdup(command));
                                }

	| expressao '<' expressao {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tCMP AX, CX\n"
						"\tJGE cond%d\n"
						"\tMOV (%d), 1\n"
						"\tJMP cond%d\n"
						"cond%d:\n"
						"\tMOV (%d), 0\n"
						"cond%d:\n",
						$1->tval, $3->tval, cond_count, cond_mem,
						cond_count + 1, cond_count, cond_mem, cond_count + 1);
					cond_count += 2;
					cond_mem += 2;

                                        $$ = mnemonico($1, $3, strdup(command));
                                  }

	| expressao MENORIGUAL expressao {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tCMP AX, CX\n"
						"\tJG cond%d\n"
						"\tMOV (%d), 1\n"
						"\tJMP cond%d\n"
						"cond%d:\n"
						"\tMOV (%d), 0\n"
						"cond%d:\n",
						$1->tval, $3->tval, cond_count, cond_mem,
						cond_count + 1, cond_count, cond_mem, cond_count + 1);
					cond_count += 2;
					cond_mem += 2;
                                            $$ = mnemonico($1, $3, strdup(command));
                                         }

	| expressao MAIORIGUAL expressao {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tCMP AX, CX\n"
						"\tJL cond%d\n"
						"\tMOV (%d), 1\n"
						"\tJMP cond%d\n"
						"cond%d:\n"
						"\tMOV (%d), 0\n"
						"cond%d:\n",
						$1->tval, $3->tval, cond_count, cond_mem,
						cond_count + 1, cond_count, cond_mem, cond_count + 1);
					cond_count += 2;
					cond_mem += 2;
                                            $$ = mnemonico($1, $3, strdup(command));
                                         }

	| expressao IGUAL expressao {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tCMP AX, CX\n"
						"\tJNE cond%d\n"
						"\tMOV (%d), 1\n"
						"\tJMP cond%d\n"
						"cond%d:\n"
						"\tMOV (%d), 0\n"
						"cond%d:\n",
						$1->tval, $3->tval, cond_count, cond_mem,
						cond_count + 1, cond_count, cond_mem, cond_count + 1);
					cond_count += 2;
					cond_mem += 2;
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao DIFERENTE expressao {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tCMP AX, CX\n"
						"\tJE cond%d\n"
						"\tMOV (%d), 1\n"
						"\tJMP cond%d\n"
						"cond%d:\n"
						"\tMOV (%d), 0\n"
						"cond%d:\n",
						$1->tval, $3->tval, cond_count, cond_mem,
						cond_count + 1, cond_count, cond_mem, cond_count + 1);
					cond_count += 2;
					cond_mem += 2;
                                            $$ = mnemonico($1, $3, strdup(command));
                                        }
        ;

expressao:
        ATOMO                       { 
					
                                        tabelaSimb *s = alloc_tabelaSimb();
                                        s->tval = strdup($1->tval);
                                        s->mval = strdup($1->mval);
                                        s->tipoD = $1->tipoD;
                                        if (!$1->load) {
                                            load($1);
                                        }

                                        $$ = s; 
                                    }

        | expressao '+' expressao   {
                                        sprintf(command,
						"\tMOV AX, %s\n"
						"\tADD AX, %s\n"
						"\tMOV DX, AX\n",
						$1->tval, $3->tval);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao '-' expressao   {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tSUB AX, %s\n"
						"\tMOV DX, AX\n",
						$1->tval, $3->tval);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao '*' expressao   {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tIMUL CX\n"
						"\tMOV DX, AX\n",
						$1->tval, $3->tval);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

        | expressao '/' expressao   {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, %s\n"
						"\tIDIV CX\n"
						"\tMOV DX, AX\n",
						$1->tval, $3->tval);
                                        $$ = mnemonico($1, $3, strdup(command));
                                    }

	| '+''+'expressao	    {
					if ($3->tipoD != tipoIdInt) {
					    yyerror("Atribuicao invalida.");
					}
					sprintf(command,
						"\tINC %s\n"
						"\tMOV DX, %s\n",
						$3->tval, $3->tval);
                                        $$ = mnemonico($3, NULL, strdup(command));
				    }

	| expressao'+''+'	    {
					if ($1->tipoD != tipoIdInt) {
					    yyerror("Atribuicao invalida.");
					}

					sprintf(command,
						"\tMOV DX, %s\n"
						"\tINC %s\n",
						$1->tval, $1->tval);
                                        $$ = mnemonico($1, NULL, strdup(command));

				    }

        | '-' expressao %prec UMINUS {
					sprintf(command,
						"\tMOV AX, %s\n"
						"\tMOV CX, -1\n"
						"\tIMUL CX\n"
						"\tMOV DX, AX\n",
						$2->tval);
                                        $$ = mnemonico($2, NULL, strdup(command));
                                     }

        | '(' expressao ')'         { $$ = $2; }
        ;

sentenca:
        IMPRIMA '(' ATOMO ')' ';' {
			    if ($3->tipoD != tipoConStr && $3->tipoD != tipoIdStr) {
			        yyerror("O comando imprima aceita apenas constantes e variaveis de texto.");
			    }
			    if (!$3->load) {
				load($3);
			    }
                            sprintf(command,
				"\tPUSH %s\n"
				"\tPUSH _PRINTF\n"
				"\tSYS\n",
				$3->tval); 
                            enqueue(queue_geral,strdup(command));
                          }

	| LEIA '(' ATOMO ')' ';' {
			    if ($3->tipoD != tipoIdStr) {
			        yyerror("O comando imprima aceita apenas variaveis de texto.");
			    }
			    sprintf(command, "strd%d", $3->idx);
			    $3->tval = strdup(command);
			    chamou_leia = 1;
			    sprintf(command,
			   	"\tPUSH %s\n"
				"\tCALL readstring\n",
				$3->tval);
                            enqueue(queue_geral,strdup(command));
                          }
        ;

label_enquanto_inicio: {
                            sprintf(command, "l%d:\n", (*l)++);
                            enqueue(queue_geral,strdup(command));
                       }
                       ;
label_enquanto_fim: {
                        int *label = (int *) pop(stack_enquanto);
                        sprintf(command, "\tJMP l%d\n", *label-1);
                        enqueue(queue_geral,strdup(command));
                        sprintf(command, "l%d:\n", *label); 
                        enqueue(queue_geral,strdup(command));
                        free(label);
                    }
                    ;
inicio_enquanto: {
                    push(stack_enquanto,(void *) copy_int(l));
		    sprintf(command,
			"\tCMP (%d), 1\n"
			"\tJNE l%d\n",
			cond_mem - 2, *l);
		    (*l)++;
                    enqueue(queue_geral,strdup(command));
                 }
                 ;
enquanto:
        ENQUANTO '(' label_enquanto_inicio expressao_logica ')' inicio_enquanto instrucao label_enquanto_fim
        ;

inicio_selecao: {
                push(stack_if, (void *) copy_int(l));
                sprintf(command,
			"\tCMP (%d), 1\n"
			"\tJNE l%d\n",
			cond_mem - 2, *l);
		(*l)++;
                enqueue(queue_geral,strdup(command));
                count_if_else++;
           }
           ;

label_selecao: {
                    int *label = (int *) pop(stack_if);
                    sprintf(command, "l%d:\n", *label);
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
                                        $$ = $1; 
                                     }

                | expressao_relacional AND expressao_logica {
                                                                sprintf(command,
									"\tMOV AX, %s\n"
									"\tAND AX, %s\n"
									"\tJE cond%d\n"
									"\tMOV (%d), 1\n"
									"\tJMP cond%d\n"
									"cond%d:\n"
									"\tMOV (%d), 0\n"
									"cond%d:\n",
									$1->mval, $3->mval, cond_count, cond_mem,
									cond_count + 1, cond_count, cond_mem, cond_count + 1);
								cond_count += 2;
								cond_mem += 2;
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                            }

                | expressao_logica AND expressao_relacional { 
								sprintf(command,
									"\tMOV AX, %s\n"
									"\tAND AX, %s\n"
									"\tJE cond%d\n"
									"\tMOV (%d), 1\n"
									"\tJMP cond%d\n"
									"cond%d:\n"
									"\tMOV (%d), 0\n"
									"cond%d:\n",
									$1->mval, $3->mval, cond_count, cond_mem,
									cond_count + 1, cond_count, cond_mem, cond_count + 1);
								cond_count += 2;
								cond_mem += 2;
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                            }

                | expressao_logica OR expressao_relacional {
								sprintf(command,
									"\tMOV AX, %s\n"
									"\tOR AX, %s\n"
									"\tJE cond%d\n"
									"\tMOV (%d), 1\n"
									"\tJMP cond%d\n"
									"cond%d:\n"
									"\tMOV (%d), 0\n"
									"cond%d:\n",
									$1->mval, $3->mval, cond_count, cond_mem,
									cond_count + 1, cond_count, cond_mem, cond_count + 1);
								cond_count += 2;
								cond_mem += 2;
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                           }

                | expressao_relacional OR expressao_logica {
								sprintf(command,
									"\tMOV AX, %s\n"
									"\tOR AX, %s\n"
									"\tJE cond%d\n"
									"\tMOV (%d), 1\n"
									"\tJMP cond%d\n"
									"cond%d:\n"
									"\tMOV (%d), 0\n"
									"cond%d:\n",
									$1->mval, $3->mval, cond_count, cond_mem,
									cond_count + 1, cond_count, cond_mem, cond_count + 1);
								cond_count += 2;
								cond_mem += 2;
                                                                $$ = mnemonico($1, $3, strdup(command));
                                                           }

                | NOT expressao_logica {
								sprintf(command,
									"\tMOV AX, %s\n"
									"\tCMP AX, 1\n"
									"\tJE cond%d\n"
									"\tMOV (%d), 1\n"
									"\tJMP cond%d\n"
									"cond%d:\n"
									"\tMOV (%d), 0\n"
									"cond%d:\n",
									$2->mval, cond_count, cond_mem,
									cond_count + 1, cond_count, cond_mem, cond_count + 1);
								cond_count += 2;
								cond_mem += 2;
                                            $$ = mnemonico($2, NULL, strdup(command));
                                       }

                | '(' expressao_logica ')' { $$ = $2; }
                ;

aborte:
     ABORTE ';' {
                    sprintf(command, "\tHLT\n");
                    enqueue(queue_geral, strdup(command));
                 }
      ;

instrucao:
	selecao { 
                    desempilhar(queue_geral);
                    count_if_else--;
                    if (!count_if_else) { // label de jump incondicional
                        fprintf(file, "l%d:\n", (*l)++);
                        fflush(file);
                    }
                }
        | enquanto { desempilhar(queue_geral); }
        | aborte { if (count_if_else == 0) desempilhar(queue_geral); }
        | expressao_logica
        | sentenca { if (count_if_else == 0) desempilhar(queue_geral); }
        | declaracao ';' { if (count_if_else == 0) desempilhar(queue_geral); }
	| atribuicao ';' { if (count_if_else == 0) desempilhar(queue_geral); } 
        | expressao ';' { if (count_if_else == 0) desempilhar(queue_geral); } 
	| bloco_instrucao
        | ';' { if (count_if_else == 0) {
                    fprintf(file, "\tNOP\n");
                    fflush(file);
                } else {
                    enqueue(queue_geral,"\tNOP\n");
                }
        }
	;

conjunto_instrucao:
	instrucao
	| conjunto_instrucao instrucao
	;

imprime_data_bss:
{
    fprintf(file,
        "\tPUSH 0\n"
	"\tPUSH _EXIT\n"
	"\tSYS\n\n");
    if (chamou_leia) {
	gera_procedimento_read();
    }

    fprintf(file, ".SECT .DATA\n");
    desempilhar(queue_data);

    fprintf(file,
	"\n.SECT .BSS\n"
	"EOF = '\\n'\n");
    desempilhar(queue_bss);
}
	;

bloco_instrucao:
	INICIO ';' imprimir_label FIM ';' {
                           }
	| INICIO ';' imprimir_label conjunto_instrucao FIM ';'  {
                                                }
	;
imprimir_label: {
                    if (count_if_else == 0 && *l > 1) // Soh imprime se nao estiver em um if
                        fprintf(file, " l%d:\n", (*l)++);
                }
%%

void load(tabelaSimb *s) {
    if (s->tipoD == tipoConStr) {
        sprintf(command,
            "%s: .ASCIZ \"%s\\n\"\n",
	    s->tval, s->sval);
        enqueue(queue_data, strdup(command));
    }
    s->load = 1;
}

tabelaSimb *mnemonico(tabelaSimb *s1, tabelaSimb *s2, char cmd[10000]) {
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

    sprintf(command, "DX");
    s->tval = strdup(command);
    sprintf(command, "(%d)", cond_mem - 2);
    s->mval = strdup(command);
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
            if (s2->tipoD != tipoIdInt && s2->tipoD != tipoConInt) {
                yyerror("Atribuicao invalida.");
            }
            break;
        case tipoIdStr:
            if (s2->tipoD != tipoIdStr && s2->tipoD != tipoConStr) {
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
        case tipoConInt:
        case tipoIdInt:
            if (s2->tipoD == tipoConStr || s2->tipoD == tipoIdStr) {
                yyerror("Tipos incompativeis");
            }
            else
                tipo = tipoConInt;
            break;
        case tipoConStr:
        case tipoIdStr:
            if (s2->tipoD == tipoIdStr || s2->tipoD == tipoConStr) {
                tipo = tipoConStr;
            }
            else
                yyerror("Tipos incompativeis");
            break; 
        default:
            yyerror("Tipo nao reconhecido");

    }

    return tipo;
}

int *copy_int(int *value) {
    int *copy = (int *) malloc(sizeof(int));
    *copy = *value;
    return copy;
}

void desempilhar(Queue *queue) {
    char *value; 
    while (!is_queue_empty(queue)) {
        value = dequeue(queue);
        if (!strcmp(value, "jump_incondicional")) {
            fprintf(file, "\tJMP l%d\n", *l);
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

void gera_procedimento_read() {
	fprintf(file,
		"readstring:\n"
		"\tPOP AX\n"
		"\tPOP DI\n"
		"\tPUSH AX\n"
		"\tPUSH _GETCHAR\n"
		"1:\n"
		"\tSYS\n"
		"\tCMP AX,EOF\n"
		"\tJE 9f\n"
		"\tSTOSB\n"
		"\tJMP 1b\n"
		"9:\n"
		"\tMOVB (DI),0\n"
		"\tADD SP, 2\n"
		"\tRET\n\n"
		);
}

void geraSaidaTemplate(FILE *file) {
    fprintf(file,
                "!\tGerado pelo compilador C88 versao 0.1\n"
                "!\tAutores: Elton Oliveira, Marlon Chalegre\n"
                "!\t\t Rodrigo Castro, Romulo Jales\n"
                "!\tEmail: {elton.oliver, marlonchalegre,\n"
                "!\t\trodrigomsc, romulojales}@gmail.com\n"
                "!\tData: 09/12/2009\n\n"
		"_EXIT = 1\n"
		"_PRINTF = 127\n"
		"_GETCHAR = 117\n\n"
		".SECT .TEXT\n"
		"main:\n"
                );
}

int main(int argc, char **argv) {
    file = fopen("out.asm","w");
    iniciarTabelaSimb();
    
    l = malloc(sizeof(int));
    *l = 1;

    stack_if = init_stack();
    stack_enquanto = init_stack();
    queue_geral = init_queue();
    queue_data = init_queue();
    queue_bss = init_queue();

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

    fclose(file);
}
