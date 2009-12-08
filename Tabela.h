/*
    Portugol versao 3 - Tabela.h
    Autores: Ed Prado, Edinaldo Carvalho, Elton Oliveira
             Marlon Chalegre, Rodrigo Castro
    Emails: {msgprado, truetypecode, elton.oliver,
             marlonchalegre, rodrigomsc}@gmail.com
*/

#define MAX_SIMB 200
#define STACK_SIZE 200
#define FUNC_NAME_SIZE 32
#define MAX_PARAM 4
#define MAX_SVAL 256

/* Tipos de Base */
//char *sTipoBase[4]={"tipoIndef", "tipoInt", "tipoFloat", "tipoStr"};
typedef enum
{
    tipoIndef,
    tipoInt,
    tipoFloat,
    tipoStr,
    tipoVoid
} tipoBase;

/* Tipos de Dados da Tabela de Simbolos */
//char *sTipoDado[14]={"tipoIdIndef", "tipoConInt", "tipoConFloat", "tipoConStr", "tipoIdInt", "tipoIdFloat", "tipoIdStr", "tipoIdFuncInt", "tipoIdFuncFloat", "tipoIdFuncDouble", "tipoIdFuncChar", "tipoIdFuncStr", "tipoIdFuncVoid", "tipoIdFuncPVoid"};
typedef enum
{
    tipoIdIndef,

    tipoConInt,
    tipoConFloat,
    tipoConStr,

    tipoIdInt,
    tipoIdFloat,
    tipoIdStr,

    tipoIdFuncInt,
    tipoIdFuncFloat,
    tipoIdFuncDouble,
    tipoIdFuncChar,
    tipoIdFuncStr,
    tipoIdFuncVoid,
    tipoIdFuncPVoid
} tipoDado;

/* Tipos de Nodos */
typedef enum
{
    tipoSimb,
    tipoOper
} tipoNodo;

typedef enum
{
    tipoRetFuncInt,
    tipoRetFuncFloat,
    tipoRetFuncDouble,
    tipoRetFuncChar,
    tipoRetFuncStr,
    tipoRetFuncVoid,
    tipoRetFuncPVoid
} tipoRetFunc;

/* Super Tipo */
typedef struct
{
      tipoBase tipo;
      int    ival;
      float  fval;
      char   sval[MAX_SVAL];
} superTipo;

/* Super Func */
typedef struct
{
      tipoRetFunc tipoRet;
      tipoBase tipoParam[MAX_PARAM];
      int numParam;
      char   *idNome;
      int    (*ifunc)();   //ponteiro para funcao que retorna inteiro
      float  (*ffunc)();   //ponteiro para funcao que retorna float
      double (*dfunc)();   //ponteiro para funcao que retorna double
      char   (*cfunc)();   //ponteiro para funcao que retorna char
      char   *(*sfunc)();  //ponteiro para funcao que retorna ponteiro para char
      void   (*vfunc)();   //ponteiro para a funcao que retorna void
      void   *(*pfunc)();  //ponteiro para a funcao que retorna ponteiro para void
} superFunc;

/* tabela de simbolos */
typedef struct tabelaSimb
{
      tipoDado tipoD;
      int idx;              /* ts[idx] ou tf[idx]*/
      int uso;              //verdadeiro se ja usou
      int load;             //verdadeiro se ja carregou na tabela de simbolos de execucao
      char *idNome;         //nome da variavel ou funcao em Portugol
      char *idFunc;         //nome da funcao em C
      int ival;             //valor da constante inteira
      float fval;           //valor da constante real
      char *sval;           //valor da constante texto
      char *tval;           //valor para geracao de codigo 
      char *mval;	    //valor da posicao temporaria de memoria usada em expressoes logicas
      int numParam;         //numero de parametros recebidos pela funcao
      int (*ifunc)();       //ponteiro para funcao que retorna inteiro
      float (*ffunc)();     //ponteiro para funcao que retorna double
      double (*dfunc)();    //ponteiro para funcao que retorna double
      char *(*sfunc)();     //ponteiro para funcao que retorna ponteiro para char
      void (*vfunc)();      //ponteiro para a funcao que retorna void
} tabelaSimb;

/* operadores */
typedef struct
{
    tipoBase tipoBOper;    /* apos executado, seu tipo de retorno */
    int oper;              /* o operador */
    int nops;              /* numero de operandos */
    struct uNodo *ptn[1];  /* [MAX_OPER]; os operandos (expansivel) tam = sizeof(nodo) + (nops - 1) * sizeof(nodo *); */
} nodoOper;

/* Nodo */
typedef struct uNodo
{
    int linha;              /* linha da criacao */
    tipoNodo tipoN;         /* tipo de nodo: simb ou oper */
    tabelaSimb *pSimb;      /* ponteiro para tabela de simbolos com identificadores e constantes */
    nodoOper opr;           /* operadores */
} nodo;

tabelaSimb tabSimb[MAX_SIMB];
tabelaSimb *achaId(char *nome);
tabelaSimb *achaInt(int iv);
tabelaSimb *achaFloat(float fv);
tabelaSimb *achaStr(char *sv);
tabelaSimb *achaFuncs(char *nome);
void iniciarTabelaSimb();

//extern FILE *yyin, *yyout;
//extern FILE *fhead;
char *nomeTipo(nodo *p); //retorna o nome do tipoDado ou tipoBase

void yyerror(char *s);
extern int lineno;
