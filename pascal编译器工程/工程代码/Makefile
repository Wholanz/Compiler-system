FLEX=flex
FLEXFLAGS=
BISONFLAGS=-d
BISON=bison
COMPILER_DIST=pascal
CC=gcc
CFLAGS=-g -Wall
LDFLAGS=-g -Wall

CFLAGS=-g
LDFLAGS=-g


CVS=cvs

COMPILER_HEADER=macro.h \
				symtab.h \
				x86.h 

COMPILER_SOURCE= macro.h \
				main.c \
				symtab.c \
				symtab.h \
				x86.c \
				x86.h \
				yyout.c \
				lex.yy.c \
				memory.c

COMPILER_OBJS=lex.yy.o \
			  main.o \
			  symtab.o \
			  yyout.o \
			  memory.o \
			  x86.o  

COMPILER_AUTOFILES=y.tab.c \
				   lex.yy.c \
				   yyout.c \
				   yyout.h

.SUFFIXES:.c

all: $(COMPILER_DIST)

%.o:%.c $(COMPILER_HEADER)
	$(CC) $(CFLAGS) -c $<

lex.yy.c:spl.l yyout.c
	$(FLEX) $(FLEXFLAGS) spl.l

yyout.c:spl.y
	$(BISON) $(BISONFLAGS) -o yyout.c $<

$(COMPILER_DIST):$(COMPILER_OBJS) $(COMPILER_HEADER)
	gcc -o $(COMPILER_DIST) $(LDFLAGS) $(COMPILER_OBJS)

clean:
	rm -f *.o
	rm -f $(COMPILER_DIST)
	rm -f $(COMPILER_AUTOFILES)

