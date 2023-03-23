%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#define MAX_LINE_LENG 256
#define TABLE_SIZE 1000
#define LIST strcat(buf,yytext)
#define token(t) {LIST; printf("<%s>\n",t);}
#define token(t) {LIST; printf("<%s>\n",t);}
#define tokenINTEGER(t,i) {LIST; printf("<%s:%d>\n",t,i);}
#define tokenSTRING(t,s) {LIST; printf("<%s:%s>\n",t,s);}
int linenum = 1;
char buf[MAX_LINE_LENG];
char delimiter[4];
typedef struct {
    char* id;
} data;
int element=0;
data* symboltable[TABLE_SIZE];
int key(char* id) {
    int size = strlen(id);
    int value = 0;
    for (int i = 0; i < size; i++) {
        value += id[i];
    }
    value %= TABLE_SIZE;
    return value;
}
void create() {

    for (int i = 0; i < TABLE_SIZE; i++) {
        symboltable[i] = NULL;
    }
}
bool lookup(char* id) {
    int index = key(id);
    for (int i = 0; i < TABLE_SIZE; i++) {
        int iter=(index + i) % TABLE_SIZE;
        if (symboltable[iter]!=NULL&&!strcmp(id,symboltable[iter]->id)) {
            return true;
        }
    }
    return false;
}
void dump() {
    for (int i = 0; i < TABLE_SIZE; i++) {
        if (symboltable[i] != NULL) {
            printf("%s\n",symboltable[i]->id);
        }
    }
}

bool insert(char* id) {
    int index = key(id);
     if(lookup(id)){
         return true;}
    for (int i = 0; i < TABLE_SIZE; i++) {
        int iter=(index + i) % TABLE_SIZE;
        if (symboltable[iter] == NULL) {
            data* newdata=(data*)malloc(sizeof(data));
            char *s=(char*)malloc(sizeof(char));
            strcpy(s,id);
            newdata->id = s;
            symboltable[(index + i) % TABLE_SIZE] = newdata;
            return true;
        }
    }
    return false;
}

%}
COMMENT "/*"*(.*\n?)*"*/"|"//".*
WHITESPACE [ |\t]+
DIGIT [0-9]
LETTER [a-zA-Z]
ID {LETTER}({DIGIT}|{LETTER})*
INTEGER {DIGIT}+
STRING      \"([^\"\n]|\"\")*\"
DELIMITER ,|:|;|->|\[|\]|\(|\)|\{|\}|\+|-|\*|\/|%|<|<=|>=|>|==|!=|&|!|=|\+=|-=|\*=|\/=
KEY bool|break|char|case|class|continue|declare|do|else|exit|float|for|fun|if|int|loop|print|println|return|string|val|var|while|true|false
%%
{KEY} {

        char keyword[10];
        for(int i=0; i < sizeof(yytext); i++)
        keyword[i] = toupper(yytext[i]);
        keyword[sizeof(yytext)]='\0';
        token(keyword);
}
{INTEGER} {
	tokenINTEGER("INTEGER",atoi(yytext));
}
{ID} {
	tokenSTRING("id",yytext);

        insert(yytext);
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
{DELIMITER} {
        delimiter[0]='\'';
        delimiter[1]=yytext[0];
        delimiter[2]='\'';
        delimiter[3]='\0';
        token(delimiter);
}

{STRING} {
        tokenSTRING("STRING",yytext);

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
int main(){
        create();
        yylex();
        printf("Symbol Table:\n");
        dump();
}
