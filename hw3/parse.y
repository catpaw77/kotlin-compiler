%{
#define Trace(t)        printf(t)
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "symboltable.cpp"
extern FILE* yyin;
extern "C" {
	void yyerror(const char*);
	int yyparse(void);
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
ofstream jasm;
vector<element>globalConst;
int getValue(string id){
	for(int i=0;i<globalConst.size();i++){
		if(globalConst[i].id==id){
			return globalConst[i].value;
		}
	}
	return INT8_MIN;
}
int label_counter  = 0;
int jump_counter=0;
int curVal=0;
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
%token <sval> BO

/* Nonterminals */
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
		jasm << "class " << $2 <<endl<<"{"<<endl;

	} declarations '}' {
		table.pop();
		jasm <<"}";

	}
	|	CLASS ID '{' '}' {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.create($2,"class",0);
		table.pop();
		jasm << "class " << $2 <<endl<<"{"<<endl<<"}";

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
		if(table.back==0){
			globalConst.push_back(element($2,curVal));//要計算就完蛋
		}
	}
	|	VAL ID ':' type '=' constant_expr {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.insert($2,"val",$4);
		if(table.back==0){
			globalConst.push_back(element($2,curVal));//要計算就完蛋
		}
	}
	;

/* declare variable */
var:	VAR ID {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.insert($2,"var",1);
		table.notInit();
		if(table.back==0){
			jasm<<getTab(table.back)<<"field static int "<<$2<<endl;
		}
	}
	|	VAR ID ':' type {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.insert($2,"var",$4);
		table.notInit();
		if(table.back==0){
		jasm<<getTab(table.back)<<"field static "<<intToStr($4)<<" "<<$2<<endl;
		}
	}
	| 	VAR ID '=' constant_expr {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.insert($2,"var",$4);
		if(table.back==0){
			jasm<<getTab(table.back)<<"field static int "<<$2<< " = " <<curVal<<endl;
		}
		else{
			jasm<<getTab(table.back)<< "istore " << table.getIndex($2) <<endl;
		}
	}
	|	VAR ID ':' type '=' constant_expr {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		if($4!=$6){
			yyerror("incompatible type");
		}
		table.insert($2,"var",$4);
		if(table.back==0){
			jasm<<getTab(table.back)<<"field static int "<<$2<< " = " <<curVal<<endl;
		}
		else{
			jasm <<getTab(table.back)<< "istore " << table.getIndex($2) <<endl;
		}
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
		jasm<<getTab(table.back-1)<<"method public static "<<intToStr($7)<<" "<<$2<<"(";
		for(int i=0;i<curArg.size();i++){
			if(i!=0){
				jasm<<", ";
			}
			jasm<<intToStr(curArg[i].datatype);
		}
		jasm<<")"<<endl;
		jasm<<getTab(table.back-1)<<"max_stack 15"<<endl<<getTab(table.back-1)<<"max_locals 15"<<endl;
		curArg.clear();
		{jasm<<getTab(table.back-1)<<"{"<<endl;}

	} block {
		if(table.isFun()==0)
			jasm<<getTab(table.back)<<("return")<<endl;
		jasm<<getTab(table.back-1)<<"}"<<endl;
		table.pop();
	}
	|FUN ID '(' ')' ':' type {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.create($2,"fun",$6);
		{jasm<<getTab(table.back-1)<<"{"<<endl;}
	} block {
		if(table.isFun()==0)
			jasm<<getTab(table.back)<<("return")<<endl;
		jasm<<getTab(table.back-1)<<"}"<<endl;
		table.pop();
	}
	|FUN ID '(' fun_argus')' {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.create($2,"fun",0);
		table.addArgu(curArg);
		curArg.clear();
		{jasm<<getTab(table.back-1)<<"{"<<endl;}

	} block {
		if(table.isFun()==0)
			jasm<<getTab(table.back)<<("return")<<endl;
		jasm<<getTab(table.back-1)<<"}"<<endl;
		table.pop();
	}
	|FUN ID '(' ')' {
		if(table.lookup($2)){
			yyerror("Identifier has declared");
		}
		table.create($2,"fun",0);
		string tmp=$2;
		if(tmp=="main"){
			jasm<<getTab(table.back-1)<<"method public static void main(java.lang.String[])"<<endl<<getTab(table.back-1)<<"max_stack 15"<<endl<<getTab(table.back-1)<<"max_locals 15"<<endl;
		}
		{jasm<<getTab(table.back-1)<<"{"<<endl;}

	} block {
		if(table.isFun()==0)
			jasm<<getTab(table.back)<<("return")<<endl;
		jasm<<getTab(table.back-1)<<"}"<<endl;
		table.pop();
	}
	;
fun_argus:fun_argu
	|	fun_argu ',' fun_argus
	;
fun_argu: ID ':' type {curArg.push_back(argument($1, $3));}
	;
block: '{'  block_statements '}'
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
		if($3!=table.lookup($1)){
			yyerror("incompatible type");
		}
		if(table.isArr($1)){
		yyerror("cannot be array");
		}
		if(table.isConst($1)){
			yyerror("constant cannot be reassigned");
		}
		table.init($1);//assign
		if(table.getIndex($1)>=0)
			jasm<<getTab(table.back)<<"istore "<<table.getIndex($1)<<endl;
		else
			jasm<<getTab(table.back)<<"putstatic "<<intToStr(table.lookup($1))<<" "<<table.stb.front().id<<"."<<$1<<endl;
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
	|	PRINT '(' {	jasm<<getTab(table.back) << "getstatic java.io.PrintStream java.lang.System.out"<<endl;} expression ')' {
		if ($4 == 1){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.print(int)"<<endl;
		}
		if ($4 == 2){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.print(java.lang.String)"<<endl;
		}
		if ($4 == 3){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.print(boolean)"<<endl;
		}
	}
	|	PRINT {jasm<<getTab(table.back) << "getstatic java.io.PrintStream java.lang.System.out"<<endl;} expression {
		if ($3 == 1){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.print(int)"<<endl;
		}
		if ($3 == 2){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.print(java.lang.String)"<<endl;
		}
		if ($3 == 3){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.print(boolean)"<<endl;
		}
	}
	|	PRINTLN '(' {jasm<<getTab(table.back) << "getstatic java.io.PrintStream java.lang.System.out"<<endl;} expression ')' {
		if ($4 == 1){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.println(int)"<<endl;
		}
		if ($4 == 2){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.println(java.lang.String)"<<endl;
		}
		if ($4 == 3){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.println(boolean)"<<endl;
		}
	}
	|	PRINTLN {jasm<<getTab(table.back) << "getstatic java.io.PrintStream java.lang.System.out"<<endl;} expression {
		if ($3 == 1){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.println(int)"<<endl;
		}
		if ($3 == 2){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.println(java.lang.String)"<<endl;
		}
		if ($3 == 3){
			jasm<<getTab(table.back) << "invokevirtual void java.io.PrintStream.println(boolean)"<<endl;
		}
	}
	|	READ ID
	|	RETURN {jasm<<getTab(table.back) << "return"<<endl;}
	|	RETURN expression {jasm<<getTab(table.back) << "ireturn"<<endl;}
	|	condition
	|	loop
	|	procedure
	;
expression:constant_expr
	|	boolean_expr
	;

constant_expr: constant_expr '+' constant_expr {if($1!=$3){yyerror("incompatible type");}jasm<<getTab(table.back)<<"iadd"<<endl;}
	|	constant_expr '-' constant_expr {if($1!=$3){yyerror("incompatible type");}jasm<<getTab(table.back)<<"isub"<<endl;}
	|	constant_expr '*' constant_expr {if($1!=$3){yyerror("incompatible type");}jasm<<getTab(table.back)<<"imul"<<endl;}
	|	constant_expr '/' constant_expr {if($1!=$3){yyerror("incompatible type");}jasm<<getTab(table.back)<<"idiv"<<endl;}
	|	constant_expr '%' constant_expr {if($1!=$3){yyerror("incompatible type");}jasm<<getTab(table.back)<<"irem"<<endl;}
	|	'-' constant_expr %prec UMINUS {$$=$2;jasm<<getTab(table.back)<<"ineg"<<endl;}
	|	constant
	|	ID '(' comma_separated_expressions')' {
		if(table.isFun($1)){
			$$=table.isFun($1); //returntype
		}
		else{
			yyerror("Not function");
		}
		if(!table.paraCheck($1, curPara)){
			yyerror("Parameter error");
		}
		jasm<<getTab(table.back)<<"invokestatic "<<intToStr(table.isFun($1))<<" "<<table.stb.front().id<<"."<<$1<<"(";
		for(int i=0;i<curPara.size();i++){
			if(i!=0){
				jasm<<", ";
			}
			jasm<<intToStr(curPara[i]);
		}
		jasm<<")"<<endl;
		curPara.clear();

	}//function invocation 檢查該id有沒有return 型態
	|	ID '('')'{
		if(table.isFun($1)){
			$$=table.isFun($1); //returntype
		}
		else{
			yyerror("Not function");
		}
		jasm<<getTab(table.back)<<"invokestatic "<<intToStr(table.isFun($1))<<" "<<table.stb.front().id<<"."<<$1<<"(";
		jasm<<")"<<endl;

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
		if(table.getIndex($1)>=0)
			jasm<<getTab(table.back)<<"iload "<<table.getIndex($1)<<endl;
		else if(getValue($1)!=INT8_MIN){// global const

			jasm<<getTab(table.back)<<"sipush "<<getValue($1)<<endl;

		}
		else
			jasm<<getTab(table.back)<<"getstatic int "<<table.stb.front().id<<"."<<$1<<endl;
	} //型態
	|	'(' constant_expr ')' {$$=$2;}
	;
comma_separated_expressions:expression {curPara.push_back($1);}
	|	expression ',' comma_separated_expressions {curPara.push_back($1);}
	;

// literal constants, variable names, function invocations, and array reference of the form
//4種type 1=int 2=string 3=bool 4=float
type: INT {$$=1;}
	|	STRING {$$=2;}
	|	BOOL {$$=3;}
	|	FLOAT {$$=4;}
	;
constant:INT_CONST {
			$$=1;
			curVal=$1;
			if(table.back!=0){
				jasm<<getTab(table.back)<<"sipush "<<$1<<endl;
			}
		}
	|	STR_CONST {$$=2;jasm<<getTab(table.back) << "ldc " <<$1<<endl;}
	|	FLOAT_CONST {$$=4;}
	|	TRUE {$$=3;jasm<<getTab(table.back)<<"iconst_1"<<endl;curVal=1;}
	|	FALSE {$$=3;jasm<<getTab(table.back)<<"iconst_0"<<endl;curVal=0;}
	;
condition: IF '(' boolean_expr ')' ifact block_or_simple {jasm<< "Lfalse" << label_counter << ":"<<endl;}
	|	IF '(' boolean_expr ')' ifact block_or_simple ELSE elseact block_or_simple {jasm<< "Lexit" << label_counter+1 << ":"<<endl;label_counter+=2;}
	;
ifact:{
		jasm<<getTab(table.back) << "ifeq Lfalse" << label_counter << "\n";
	}
	;
elseact:{
		jasm<<getTab(table.back) << "goto Lexit" << label_counter+1 << "\n";
		jasm<< "Lfalse" << label_counter << ":\n";
	}
	;
block_or_simple: statement
	|	block
	;
loop: WHILE {jasm << "Lbegin" << label_counter<<":"<<endl;jump_counter=label_counter;label_counter++;} '(' boolean_expr ')' {jasm <<getTab(table.back)<<"ifeq Lexit" << label_counter<<endl;} block_or_simple {
		jasm<<getTab(table.back)<< "goto Lbegin" <<jump_counter <<endl;
		jasm << "Lexit" << label_counter++<<":"<<endl;
	}
	|	FOR '(' ID {
		table.insert($3,"var",1);
	} IN  INT_CONST {
		jasm<<getTab(table.back)<<"sipush "<<$6<<endl;
		jasm<<getTab(table.back)<<"istore "<<table.getIndex($3)<<endl;
		jasm << "Lbegin" << label_counter<<":"<<endl;
		jump_counter=label_counter;
		label_counter++;
		jasm<<getTab(table.back)<<"iload "<<table.getIndex($3)<<endl;

	} '.' '.' INT_CONST  ')' {
		jasm<<getTab(table.back)<<"sipush "<<$10<<endl;
		jasm<<getTab(table.back)<<"isub"<<endl;
		if($10>=$6)
			jasm<<getTab(table.back) << "ifle Ltrue" << label_counter  << endl;
		else
			jasm<<getTab(table.back) << "ifge Ltrue" << label_counter  << endl;
		jasm<<getTab(table.back) << "iconst_0"<<endl;
		jasm<<getTab(table.back) << "goto Lfalse" << label_counter  + 1 <<endl;
		jasm<< "Ltrue" << label_counter << ":"<<endl;
		jasm<<getTab(table.back) << "iconst_1"<<endl;
		jasm<< "Lfalse" << label_counter + 1 << ":"<<endl;
		jasm<<getTab(table.back)<<"ifeq Lexit" << label_counter + 2<<endl;
	}block_or_simple{
		jasm<<getTab(table.back)<<"iload "<<table.getIndex($3)<<endl;
		jasm<<getTab(table.back)<<"sipush 1"<<endl;
		if($10>=$6)
			jasm<<getTab(table.back)<<"iadd"<<endl;
		else
			jasm<<getTab(table.back)<<"isub"<<endl;
		jasm<<getTab(table.back)<<"istore "<<table.getIndex($3)<<endl;
		jasm<<getTab(table.back)<<"goto Lbegin"<<jump_counter<<endl;
		jasm<<"Lexit"<<label_counter + 2<<":"<<endl;
		label_counter+=3;
	}
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
boolean_expr: '!' boolean_expr {$$=3;jasm<<getTab(table.back)<<"iconst_1"<<endl<<getTab(table.back)<<"ixor"<<endl;}
	|	boolean_expr '|' boolean_expr {$$=3;jasm<<getTab(table.back)<<"ior"<<endl;}
	|	boolean_expr '&' boolean_expr {$$=3;jasm<<getTab(table.back)<<"iand"<<endl;}
	|	constant_expr BO constant_expr {
		if($1!=$3){
			yyerror("incompatible type");$$=3;
		}
		jasm<<getTab(table.back)<<"isub"<<endl;
		string tmp=$2;
		if (tmp=="<") jasm<<getTab(table.back) << "iflt Ltrue" << label_counter  << endl;
		if (tmp==">") jasm<<getTab(table.back) << "ifgt Ltrue" << label_counter  << endl;
		if (tmp=="<=") jasm<<getTab(table.back) << "ifle Ltrue" << label_counter  << endl;
		if (tmp==">=") jasm<<getTab(table.back) << "ifge Ltrue" << label_counter  << endl;
		if (tmp=="==") jasm<<getTab(table.back) << "ifeq Ltrue" << label_counter  << endl;
		if (tmp=="!=") jasm<<getTab(table.back) << "ifne Ltrue" << label_counter  << endl;
		jasm<<getTab(table.back) << "iconst_0"<<endl;
		jasm<<getTab(table.back) << "goto Lfalse" << label_counter  + 1 <<endl;//L2
		jasm<< "Ltrue" << label_counter << ":"<<endl;//L1
		jasm<<getTab(table.back) << "iconst_1"<<endl;
		jasm<< "Lfalse" << label_counter + 1 << ":"<<endl;//L2
		label_counter += 2;
	}
	|	'(' boolean_expr ')' {$$=3;}
	|	constant_expr
	;
%%
int main(int argc, char *argv[])
{
	 if (argc != 2) {
        printf ("Usage: sc filename\n");
        exit(1);
    }
	yyin = fopen(argv[1], "r");         /* open input file */
	string filename=(argv[1]);
	filename=filename.substr(0,filename.size()-3);
	jasm.open(filename+".jasm");
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error !");     /* syntax error */
	jasm.close();
 	return 0;
}