%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "y.tab.h"
#define MAX_LINE_LENG 256
#define TABLE_SIZE 1000
#define LIST strcat(buf,yytext)
// #define token(t) {LIST; printf("<%s>\n",#t);}
// #define tokenINTEGER(t,i) {LIST; printf("<%s:%d>\n",t,i);}
// #define tokenSTRING(t,s) {LIST; printf("<%s:%s>\n",t,s);}
#define token(t) {LIST; }
#define tokenINTEGER(t,i) {LIST;}
#define tokenSTRING(t,s) {LIST;}
int linenum = 1;
char buf[MAX_LINE_LENG];
%}
COMMENT "/*"*(.*\n?)*"*/"|"//".*
WHITESPACE [ |\t]+
DIGIT [0-9]
LETTER [a-zA-Z]
ID {LETTER}({DIGIT}|{LETTER})*
INT_CONST {DIGIT}+
STR_CONST \"([^\"\n]|\"\")*\"
FLOAT_CONST {DIGIT}+\.{DIGIT}+

%%

","		{ token(','); return(','); }
":"		{ token(':'); return(':'); }
"."		{ token('.'); return('.'); }
";"		{ token(';'); return(';'); }
"->"	        { token('->'); return(ARROW); }
"("		{ token('('); return('('); }
")"		{ token(')'); return(')'); }
"["		{ token('['); return('['); }
"]"		{ token(']'); return(']'); }
"{"		{ token('{'); return('{'); }
"}"		{ token('}'); return('}'); }
"+"		{ token('+'); return('+'); }
"-"		{ token('-'); return('-'); }
"*"		{ token('*'); return('*'); }
"/"		{ token('/'); return('/'); }
"%"		{ token('%'); return('%'); }
"<"		{ token('<'); return BO; }
"<="	        { token("<="); return BO; }
">="	        { token(">="); return BO; }
">"	        { token('>'); return BO ; }
"=="	        { token("=="); return BO; }
"!="	        { token("!="); return BO; }
"&"	        { token('&'); return('&'); }
"|"	        { token('|'); return('|'); }
"!"	        { token('!'); return('!'); }
"="	        { token('='); return('='); }

"bool" {token(BOOL); return BOOL;}
"break" {token(BREAK); return BREAK;}
"char" {token(CHAR); return CHAR;}
"case" {token(CASE); return CASE;}
"class" {token(CLASS); return CLASS;}
"continue" {token(CONTINUE); return CONTINUE;}
"declare" {token(declare); return DECLARE; }
"do" {token(DO); return DO;}
"else" {token(ELSE); return ELSE;}
"exit" {token(EXIT); return EXIT;}
"float" {token(FLOAT); return FLOAT;}
"for" {token(FOR); return FOR;}
"fun" {token(FUN); return FUN;}
"if" {token(IF); return IF;}
"int" {token(INT); return INT;}
"loop" {token(LOOP); return LOOP;}
"print" {token(PRINT); return PRINT;}
"println" {token(PRINTLN); return PRINTLN;}
"return" {token(RETURN); return RETURN;}
"string" {token(STRING); return STRING;}
"val" {token(val); return VAL;}
"var" {token(VAR); return VAR;}
"while" {token(WHILE); return WHILE;}
"read" {token(READ); return READ;}
"in" {token(IN); return IN;}
"false" {
	token(FALSE);
	yylval.bval = false;
	return FALSE;
}

"true" {
	token(TRUE);
	yylval.bval = true;
	return TRUE;
}

{INT_CONST} {
	tokenINTEGER("integer",atoi(yytext));
        yylval.ival=atoi(yytext);
        return INT_CONST;
}
{FLOAT_CONST} {
        tokenSTRING("float",yytext);
        yylval.fval=atof(yytext);
        return FLOAT_CONST;

}
{ID} {
	tokenSTRING("id",yytext);
        yylval.sval=strdup(yytext);
        return ID;
}
{COMMENT} {

         int i=0,bufinedx=0;
         while(yytext[i]!='\0'){
         buf[bufinedx++]=yytext[i++];
         if(yytext[i-1]=='\n'){
                 buf[bufinedx]='\0';
                 printf("%d: %s",linenum,buf);
                 bufinedx=0;
                 buf[0]='\0';
                 linenum++;
         }
 }
 buf[bufinedx]='\0';
}
{STR_CONST} {
        tokenSTRING("string",yytext);
        yylval.sval=strdup(yytext);
        return STR_CONST;
}
\r?\n {
        LIST;
        printf("%d: %s", linenum, buf);
        linenum++;
        buf[0] = '\0';
}
{WHITESPACE} {
        LIST;
}
. {
        LIST;
        printf("bad character:'%s'\n",yytext);

}
%%