#ifndef _MACRO_H
#define _MACRO_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//ȫ�ֱ���
typedef int		boolean;
extern	FILE 	*asmfp;
extern	FILE	*tmpfp;
extern  FILE 	*errfp;

extern int line_pos;
extern int line_no;
char line_buf[20480];
extern int error_times;
//ȫ�ֺ궨�壬������������
#define MAX_SYS_FUNCTION	(24)
#define MAX_TERM  64
#define KEYWORD		-1
#define STACK_SEG_SIZE		(2048)
#define TABLE_LEN			(128)
#define LABEL_LEN			(32)
#define LAST_ENTRY			(65536 * 1024)
#define NAME_LEN			(32)
#define SIZE_CHAR			(1)
#define SIZE_INTEGER		(4)
#define SIZE_REAL			(4)
#define SIZE_BOOLEAN		SIZE_INTEGER
#define SIZE_POINTER		(4)
#define S_STACK				SIZE_INTEGER
#define DEF_UNKNOWN			(0)
#define DEF_CONST			(1)
#define DEF_VAR				(2)
#define DEF_TYPE			(3)
#define DEF_FIELD			(4)
#define DEF_VALPARA			(5)
#define DEF_VARPARA			(6)
#define DEF_PROC			(7)
#define DEF_FUNCT			(8)
#define DEF_PROG			(9)
#define DEF_TEMPVAR			(10)
#define DEF_ELEMENT			(11)
#define DEF_LABEL			(12)
#define false 				0
#define true 				1
#define new_index(m)		++m##_index
#define size(x)				SIZE_##x
//���Ա��ϵͳ����
typedef struct
{
    char name[NAME_LEN];
    int key;
    int attr;
    int ret_type;
    int arg_type;
}
KEYENTRY;
//��������
enum {
    TYPE_UNKNOWN = 0,
    TYPE_INTEGER = 1,
    TYPE_CHAR = 2,
    TYPE_REAL = 3,
    TYPE_BOOLEAN = 4,
    TYPE_ARRAY = 5,
    TYPE_ENUM = 6,
    TYPE_SUBRANGE = 7,
    TYPE_RECORD = 8,
    TYPE_VOID = 9,
    TYPE_STRING = 10,
    TYPE_POINTER = 11,
    TYPE_DOUBLE = 12,
    TYPE_FUNCTION = 13,
    TYPE_LONG = 14,
    TYPE_CONST = 15
};
//�����﷨����
void yyerror(const char *info);
void parse_error(const char *info, char *name);
//�����ڴ�����ڻ���
#include "symtab.h"
int get_keytable_size();
void *allocate(unsigned long n);
void deallocate();

#endif