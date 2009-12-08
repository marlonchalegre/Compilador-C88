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

#define MAX_SIMB 200

typedef enum
{
    tipoIdIndef,

    tipoConInt,
    tipoConStr,

    tipoIdInt,
    tipoIdStr,

} tipoDado;

/* tabela de simbolos */
typedef struct tabelaSimb
{
      tipoDado tipoD;
      int idx;              /* ts[idx] ou tf[idx]*/
      int uso;              //verdadeiro se ja usou
      int load;             //verdadeiro se ja carregou na tabela de simbolos de execucao
      char *idNome;         //nome da variavel ou funcao em Portugol
      int ival;             //valor da constante inteira
      char *sval;           //valor da constante texto
      char *tval;           //valor para geracao de codigo 
      char *mval;	    //valor da posicao temporaria de memoria usada em expressoes logicas
} tabelaSimb;

tabelaSimb tabSimb[MAX_SIMB];
tabelaSimb *achaId(char *nome);
tabelaSimb *achaInt(int iv);
tabelaSimb *achaStr(char *sv);
void iniciarTabelaSimb();

void yyerror(char *s);
extern int lineno;
