/*
    Arquivo original escrito por:
      Autor: Ruben Carlo Benante
      Email: benante@gmail.com
      Data: 23/04/2009
      Modificado: 25/05/2009

    C88 versao 1 - tabela.h
    Autores: Elton Oliveira, Marlon Chalegre
             Rodrigo Castro, Romulo Jales
    Emails: {elton.oliver, marlonchalegre
             rodrigomsc, romulojales}@gmail.com
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "tabela.h"

char buffer[100];
int idxId = 200;
int strxId = 1;
int idxCon = 30;

void iniciarTabelaSimb() {
        tabelaSimb *sp = NULL;
	for(sp = tabSimb; sp < &tabSimb[MAX_SIMB]; sp++) { 
            sp->uso = 0;
	}
}

/* Procura na tabela de simbolos, nela iremos colocar nossas palavras reservadas e variaveis que estao sendo criadas */
/* se a palavra nao for encontrada ela e adicionada a tabela de simbolos*/
tabelaSimb* achaId(char *nome) {
        tabelaSimb *sp = NULL;

	for (sp = tabSimb; sp < &tabSimb[MAX_SIMB]; sp++) { 
		/* Existe? */
		if (sp->uso && sp->idNome && !strcmp(sp->idNome, nome))
			return sp;
                /* ta livre? */
	        if (!sp->uso) { 
                    sp->uso = 1;
                    sp->load = 0;
                    sp->tipoD = tipoIdIndef;
		    sp->idNome = strdup(nome); //coloca na tabela de simbolos
                    sp->idx = idxId;
		    idxId += 2;
                    sprintf(buffer, "(%d)", sp->idx);
                    sp->tval = strdup(buffer);
                    sprintf(buffer, "(%d)", sp->idx);
		    sp->mval = strdup(buffer);
		    return sp; 
	        }
	}
       
	//a tabela de simbolos tem uma quantidade max, cuidado para n estourar
	yyerror("Espaco insuficiente.\n");
        return sp;
}

tabelaSimb* achaInt(int valor){
        tabelaSimb *sp = NULL;

	for(sp = tabSimb; sp < &tabSimb[MAX_SIMB]; sp++) { 
		/* Existe? */
		if (sp->uso && sp->ival == valor &&
                    sp->tipoD == tipoConInt)
	            return sp;
                /* ta livre? */
	        if (!sp->uso) { 
                    sp->uso = 1;
                    sp->load = 0;
                    sp->tipoD = tipoConInt;
                    sp->ival = valor;
                    sp->idx = idxCon++;
                    sprintf(buffer, "%d", valor);
                    sp->tval = strdup(buffer); 
                    sprintf(buffer, "%d", valor);
                    sp->mval = strdup(buffer); 
		    return sp;
	        }
	}

	//a tabela de simbolos tem uma quantidade max, cuidado para n estourar
	yyerror("Espaco insuficiente.\n");
        return sp;
}

tabelaSimb* achaStr(char *valor){
        tabelaSimb *sp = NULL;

	for(sp = tabSimb; sp < &tabSimb[MAX_SIMB]; sp++) { 
		/* Existe? */
		if (sp->uso && sp->sval && !strcmp(sp->sval, valor) &&
                    sp->tipoD == tipoConStr)
	            return sp;
                /* ta livre? */
	        if (!sp->uso) {
                    sp->uso = 1;
                    sp->load = 0;
                    sp->tipoD = tipoConStr;
                    sp->sval = strdup(valor);
                    sp->idx = idxCon++;
                    sprintf(buffer, "str%d", strxId++);
                    sp->tval = strdup(buffer);
                    sprintf(buffer, "str%d", strxId-1);
                    sp->mval = strdup(buffer);
		    return sp;
	        }
	}

	//a tabela de simbolos tem uma quantidade max, cuidado para n estourar
	yyerror("Espaco insuficiente.\n");
        return sp;
}
