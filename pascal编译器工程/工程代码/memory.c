#include "macro.h"
//连接所有程序分配的空间，便于程序执行完后回收内存
struct space
{
	void *new_space;
	struct space *next;
};

struct space *all_space;

void *allocate(unsigned long n)
{
	void *new_s = malloc(n);
	struct space *new_node = (struct space*)malloc(sizeof(struct space));
	new_node->new_space = new_s;
	new_node->next = all_space;
	all_space = new_node;
	return new_node->new_space;
}
void deallocate()
{
	struct space *p,*q;
	for (p = all_space; p; p = q)
	{
		q = p->next;
		free(p->new_space);
		free(p);
	}
}
