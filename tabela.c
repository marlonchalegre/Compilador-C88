#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "Tabela.h"

char buffer[100];
int idxId = 10;
int idxFunc = 0;
int idxCon = 0;

void geraSaidaH() {
    FILE *file;
    file = fopen("saida.h","w");
    if(!file){
        printf("O arquivo nao pode ser aberto!\n");
        exit(1);
    }   
    fprintf(file,
                "//\tGerado pelo compilador PORTUGOL versao 2q\n"
                "//\tAutores: Ed Prado, Edinaldo Carvalho, Elton Oliveira,\n"
                "//\t\t Marlon Chalegre, Rodrigo Castro\n"
                "//\tEmail: {msgprado, truetypecode, elton.oliver,\n"
                "//\t\tmarlonchalegre, rodrigomsc}@gmail.com\n"
                "//\tData: 26/05/2009\n"
                "\n\n"
                "#define MAX_TS %d /* Tabela de variaveis */\n"
                "#define MAX_TC %d /* Tabela de constantes */\n"
                "#define MAX_TP %d /* Tabela de temporarios */\n"
                "#define MAX_TF %d /* Tabela de funcoes */\n"
                "\n"
                "superTipo ts[MAX_TS];\n"
                "superTipo tc[MAX_TC];\n"
                "superTipo tp[MAX_TP];\n"
                "superFunc tf[MAX_TF];\n",
                idxId, idxCon, 100, idxFunc 
                );
    fclose(file);

}

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
                    sp->idx = idxId++;
                    sprintf(buffer, "ts[%d]", sp->idx);
                    sp->tval = strdup(buffer);
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
                    sprintf(buffer, "tc[%d]", sp->idx);
                    sp->tval = strdup(buffer); 
		    return sp;
	        }
	}

	//a tabela de simbolos tem uma quantidade max, cuidado para n estourar
	yyerror("Espaco insuficiente.\n");
        return sp;
}

tabelaSimb* achaFloat(float valor){
        tabelaSimb *sp = NULL;

	for(sp = tabSimb; sp < &tabSimb[MAX_SIMB]; sp++) { 
		/* Existe? */
		if (sp->uso && sp->fval == valor &&
                    sp->tipoD == tipoConFloat)
	            return sp;
                /* ta livre? */
	        if (!sp->uso) { 
                    sp->uso = 1;
                    sp->load = 0;
                    sp->tipoD = tipoConFloat;
                    sp->fval = valor;
                    sp->idx = idxCon++;
                    sprintf(buffer, "tc[%d]", sp->idx);
                    sp->tval = strdup(buffer);
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
                    sprintf(buffer, "tc[%d]", sp->idx);
                    sp->tval = strdup(buffer);
		    return sp;
	        }
	}

	//a tabela de simbolos tem uma quantidade max, cuidado para n estourar
	yyerror("Espaco insuficiente.\n");
        return sp;
}

tabelaSimb* achaFuncs(char *nome){
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
                    sp->idx = idxFunc++;
                    sprintf(buffer, "tf[%d]", sp->idx);
                    sp->tval = strdup(buffer);
                    /*built-in functions*/
                    if (!strcmp(sp->idNome, "imprima") ||
                        !strcmp(sp->idNome, "saia")) { 
                        sp->tipoD = tipoIdFuncVoid;
                    }
                    else if (!strcmp(sp->idNome, "raiz") ||
                             !strcmp(sp->idNome, "exp") ||
                             !strcmp(sp->idNome, "log") ||
                             !strcmp(sp->idNome, "leia") || 
                             !strcmp(sp->idNome, "pow")) {
                        sp->tipoD = tipoIdFuncDouble;
                    }
		    return sp;
	        }
	}
       
	//a tabela de simbolos tem uma quantidade max, cuidado para n estourar
	yyerror("Espaco insuficiente.\n");
        return sp;
}


