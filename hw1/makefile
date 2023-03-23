lex: lex.yy.o
	gcc lex.yy.o -ll
lex.yy.o: lex.l
	lex lex.l
	gcc -c -g lex.yy.c
clean:
	rm -f *.o lex.yy.c