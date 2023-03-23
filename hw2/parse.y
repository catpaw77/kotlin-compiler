%{
#define Trace(t)        printf(t)
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "symboltable.cpp"
extern "C" {
	void yyerror(const char*);
}
int yylex();
void yyerror(const char*msg)
{
	fprintf(stderr, "%s\n", msg);
	exit(-1);
}
symboltablelist table;
vector<argument>curArg;
vector<int>curPara;
%}
%union {
	int ival;
	float fval;
	bool bval;
	char* sval;
	int type; //1 int 2 string 3 bool 4 float
}

/* tokens */
%token BOOL BREAK CHAR CASE CLASS CONTINUE DECLARE DO ELSE EXIT FOR FUN IF LOOP PRINT PRINTLN RETURN VAL VAR WHILE TRUE FALSE READ IN FLOAT STRING INT
%token ARROW
%left '|'
%left '&'
%left '!'
%left BO //< <= == => > !=
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

/* data type */
%token <ival> INT_CONST
%token <fval> FLOAT_CONST
%token <sval> STR_CONST
%token <sval> ID
%token <bval> BOOL_CONST

/* Nonterminals */
//%type <type> type constant
%type <type> type expression boolean_expr constant constant_expr//statement判斷是否為return

%%
//至少一個class
program:classes
	;
classes:class
	|	class classes
	;
class:CLASS ID '{' {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.create($2,"class",0);
		} declarations '}' {table.pop();}
	|	CLASS ID '{' '}' {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.create($2,"class",0);
			table.pop();
		}
	;
declarations:declaration
	|	declaration declarations
	;
declaration:val
	|	var
	|	fun
	;
//const
val:	VAL ID '=' constant_expr {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.insert($2,"val",$4);
		}
	|	VAL ID ':' type '=' constant_expr {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.insert($2,"val",$4);
		}
	;

/* declare variable */
var:	VAR ID {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.insert($2,"var",1);
			table.notInit();
		}
	|	VAR ID ':' type {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.insert($2,"var",$4);
			table.notInit();
		}
	| 	VAR ID '=' constant_expr {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.insert($2,"var",$4);
		}
	|	VAR ID ':' type '=' constant_expr {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			if($4!=$6){
				yyerror("incompatible type");
			}
			table.insert($2,"var",$4);
		}
	|	array
    ;
//array
array: VAR ID ':' type '[' INT_CONST ']' {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.insert($2,"var",$4);
			table.addArr();
		}
	;
fun: FUN ID '(' fun_argus ')' ':' type {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.create($2,"fun",$7);
			table.addArgu(curArg);
			curArg.clear();
		} block {table.pop();}
	|FUN ID '(' ')' ':' type {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.create($2,"fun",$6);
		} block {table.pop();}
	|FUN ID '(' fun_argus')' {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.create($2,"fun",0);
			table.addArgu(curArg);
			curArg.clear();
		} block {table.pop();}
	|FUN ID '(' ')' {
			if(table.lookup($2)){
				yyerror("Identifier has declared");
			}
			table.create($2,"fun",0);
		} block {table.pop();}
	;
fun_argus:fun_argu
	|	fun_argu ',' fun_argus
	;
fun_argu: ID ':' type {curArg.push_back(argument($1, $3));}
	;
block: '{' block_statements '}'
	| '{' '}'
	;
block_statements: block_statement
	|	block_statement block_statements
	;
block_statement: val
	|	var
	|	statement
	;
statement: ID '=' expression {
			if(!table.lookup($1)){
				yyerror("Identifier was not declared");
			}
			if($3!=1){//not integer
				yyerror("incompatible type");
			}
			if(table.isArr($1)){
			yyerror("cannot be array");
			}
			if(table.isConst($1)){
				yyerror("constant cannot be reassigned");
			}
			table.init($1);//assign
		}//const不行
	|	ID '[' expression ']' '=' expression {
			if(!table.lookup($1)){
			yyerror("Identifier was not declared");
			}
			if(!table.isArr($1)){
			yyerror("not array");
			}
			if($3!=1){
				yyerror("not integer expression");
			}
		}
	|	PRINT '(' expression ')'
	|	PRINT expression
	|	PRINTLN '(' expression ')'
	|	PRINTLN expression
	|	READ ID
	|	RETURN
	|	RETURN expression
	|	condition
	|	loop
	|	procedure
	;
expression:constant_expr
	|	boolean_expr
	;

constant_expr: constant_expr '+' constant_expr {if($1!=$3){yyerror("incompatible type");}}
	|	constant_expr '-' constant_expr {if($1!=$3){yyerror("incompatible type");}}
	|	constant_expr '*' constant_expr {if($1!=$3){yyerror("incompatible type");}}
	|	constant_expr '/' constant_expr {if($1!=$3){yyerror("incompatible type");}}
	|	'-' constant_expr %prec UMINUS {$$=$2;}
	|	constant
	|	ID '(' comma_separated_expressions')' {
			if(table.isFun($1)){
				$$=table.isFun($1); //returntype
			}
			else{
				yyerror("Not function");
			}
			if(!table.paraCheck($1, curPara)){
				curPara.clear();
				yyerror("Parameter error");
			}

		}//function invocation 檢查該id有沒有return 型態
	|	ID '('')'{
			if(table.isFun($1)){
				$$=table.isFun($1); //returntype
			}
			else{
				yyerror("Not function");
			}
		}
	|	ID '[' constant_expr ']' {
			if($3!=1){
				yyerror("not integer expression");
			}
			if(table.lookup($1)){
				$$=table.lookup($1);
			}
			else{
				yyerror("Identifier was not declared");
			}
			if(!table.isArr($1)){
				yyerror("not array");
			}
		}//型態 integer expression
	|	ID {
			if(table.lookup($1)){
				$$=table.lookup($1);
			}
			else{
				yyerror("Identifier was not declared");
			}
			if(!table.isInit($1)){
				yyerror("uninitialized variable");
			}
			if(table.isArr($1)){
				yyerror("cannot be array");
			}
		} //型態
	;
comma_separated_expressions:expression {curPara.push_back($1);}
	|	expression ',' comma_separated_expressions
	;

// literal constants, variable names, function invocations, and array reference of the form
//4種type 1=int 2=string 3=bool 4=float
type: INT {$$=1;}
	|	STRING {$$=2;}
	|	BOOL {$$=3;}
	|	FLOAT {$$=4;}
	;
constant:INT_CONST {$$=1;}
	|	STR_CONST {$$=2;}
	|	FLOAT_CONST {$$=4;}
	|	TRUE {$$=3;}
	|	FALSE {$$=3;}
	;
condition: IF '(' boolean_expr ')' block_or_simple
	|	IF '(' boolean_expr ')' block_or_simple ELSE block_or_simple
	;
block_or_simple: statement
	|	block
	;
loop: WHILE '(' boolean_expr ')' block
	|	FOR '(' ID {
		if(!table.lookup($3)){
			yyerror("Identifier was not declared");}
	} IN  INT_CONST '.' '.' INT_CONST ')' block
	;
procedure: ID '(' comma_separated_expressions ')' {
		if(table.isFun($1)){
			yyerror("Not procedure");
		}
		if(!table.paraCheck($1, curPara)){
			curPara.clear();
			yyerror("Parameter error");
		}
	}//Procedure invocation 檢查該id有沒有return
	|	ID '(' ')' {
		if(table.isFun($1)){
			yyerror("Not procedure");
		}
	}
	;
boolean_expr: '!' boolean_expr {$$=3;}
	|	boolean_expr '|' boolean_expr {$$=3;}
	|	boolean_expr '&' boolean_expr {$$=3;}
	|	constant_expr BO constant_expr {if($1!=$3){yyerror("incompatible type");$$=3;}}
	;
%%
int main()
{
 	yyparse();
 	return 0;
}