all:parser
parser:lex.o yacc.o
	g++ y.tab.c lex.yy.c -ll -ly -o parser
lex.o:lex.l yacc.o
	flex lex.l
	g++ -c lex.yy.c
yacc.o:parse.y symboltable.cpp
	bison -y -d parse.y
	g++ -c y.tab.c
clean:
	rm -f *.o
