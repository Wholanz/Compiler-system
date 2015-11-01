#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "macro.h"

extern FILE *yyin;
FILE *asmfp, *tmpfp, *errfp;

int line_no = 1;
int line_pos = 0;
int error_times = 0;

char progname[15];
char asmname[15];
char tmpname[15];
char errname[15];

static char buffer[128];
int main(int argc, char **argv)
{
	char *p;

	get_keytable_size();

	for (p = argv[1]; *p; p++)
		*p = tolower(*p);

	if (strstr(argv[1], ".pas"))
	{
		for (; p > argv[1]; p--)
		{
			if (*p == '.')
				break;

		}
		*p = '\0';
	}

	snprintf(progname, sizeof(progname), "%s.pas", argv[1]);
	snprintf(asmname, sizeof(asmname), "%s.asm", argv[1]);
	snprintf(tmpname, sizeof(tmpname), "%s.cod", argv[1]);
	snprintf(errname, sizeof(errname), "%s.err", argv[1]);

	yyin = fopen(progname, "rt");
	asmfp = fopen(tmpname, "wt");
	tmpfp = fopen(asmname, "wt");
	errfp = fopen(errname, "wt");

    yyparse();
    
    if (!error_times)
    {
		fclose(asmfp);
		asmfp = fopen(tmpname, "rt");
		fgets(buffer, sizeof(buffer), asmfp);
		while (!feof(asmfp))
		{
			fputs(buffer, tmpfp);
			fgets(buffer, sizeof(buffer), asmfp);
		}
		printf("compile success!");
	}
	else
		unlink(asmname);
	fclose(yyin);
	fclose(asmfp);
	fclose(tmpfp);
	fclose(errfp);
	unlink(tmpname);
	unlink(errname);

    return 0;
}