6-30	: 6-30l.o 6-30y.o 
		gcc 6-30l.o 6-30y.o -o 6-30
6-30l.o	: 6-30l.c 
		gcc -ll -c 6-30l.c -o 6-30l.o 
6-30y.o	: 6-30y.c
		gcc -c 6-30y.c -o 6-30y.o
6-30l.c	: 6-30.l 6-30.h
		flex 6-30.l 
		mv lex.yy.c 6-30l.c 
6-30y.c	: 6-30.y
6-30.h	: 6-30.y
		yacc -d 6-30.y 
		mv y.tab.h 6-30.h	
		mv y.tab.c 6-30y.c

clean	:
		rm 6-30.h 6-30l.c 6-30y.c 6-30y.o 6-30l.o 6-30
