#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "res.h"
int save_cnt=1;//判断ID变量保存在save中还是save1中
int isTypeDefineID=1;//判断是否需要记录type define中的ID
int isVarDefineID=1;//判断是否需要记录var difine中的ID
int isFuncDefineID=0;
int isProcDefineID=0;
int isForID=0;
int isNameList=0;//判断是否在namelist块

int procedure_cnt=0;//记录词法分析进行到的步骤，对应res.h中的enum program_flow；
int name_list_cnt=0;//记录name_list的记录表记录了多少个name
int etable_cnt=0;
int const_cnt=0;
int define_cnt=1;
int cp_index=0;

int CalculateHashNumber(char* varname){
	int j, hash=0;
	for(j=0; j<strlen(varname); j++){
		hash+=varname[j];
	}
	return (hash % MAX_HASHTABLE_SIZE);
}

void addDefineRelation(char* proce_name){
	//将定义关系存放在DefineRelation的结构中
	//struct DefineRelation* new_define=(struct DefineRelation*)malloc(sizeof(struct DefineRelation));
	strcpy(define_table[define_cnt].name, proce_name);
	define_table[define_cnt].curhashtable=cur_procedure_vt;
	define_table[define_cnt].parent_index=cp_index;

	printf("                                       $$$proce_name=%s parent=%d\n", proce_name, cp_index);
	cp_index=define_cnt;
	define_cnt++;
}

void completeDefineRelation(struct TreeNode* tree_pt){
	//将定义好的函数tree指针保存下来
	define_table[cp_index].node_pt=tree_pt;
	cp_index=define_table[cp_index].parent_index;
}

void DefineRelationTraversal(){
	int i;
	printf("\n\n\ndefine_cnt=%d\n", define_cnt);
	for(i=0;i<define_cnt;i++){
		printf("%d:%s cp=%d  ", i, define_table[i].name, define_table[i].parent_index);
		if(define_table[i].node_pt==NULL) printf("NULL  ");
	}
	printf("\n\n\n");
}

struct TreeNode* FindFuncProcTree(char *funct_proce_name){
	DefineRelationTraversal();
	//printf("funct_proce_name=%s\n", funct_proce_name);
	int i;
	for(i=0;i<define_cnt;i++){
		if(!strcmp(define_table[i].name, funct_proce_name)){
			return define_table[i].node_pt;
		}
	}
	return NULL;
}

void CopyAddHashTable(char *callerID){
	struct HashTables* cur=cur_procedure_vt;
	struct HashTables* new=(struct HashTables*)malloc(sizeof(struct HashTables));
	strcpy(new->proce_name, callerID);
	int i;
	for(i=0;i<MAX_HASHTABLE_SIZE;i++){
		struct VariableTable* var=cur->proce_table[i].next;//
		while(var!=NULL){
			struct VariableTable* tobeadded=(struct VariableTable*)malloc(sizeof(struct VariableTable));
			strcpy(tobeadded->name, var->name);
			tobeadded->value=(struct Node* )malloc(sizeof(struct Node));
			tobeadded->value->type=var->value->type;
			tobeadded->value->intValue=var->value->intValue;
			tobeadded->value->realValue=var->value->realValue;
			tobeadded->value->boolValue=var->value->boolValue;
			tobeadded->value->charValue=var->value->charValue;
			if(var->value->strValue!=NULL){
				tobeadded->value->strValue=(char *)malloc(sizeof(char)*strlen(var->value->strValue));
				strcpy(tobeadded->value->strValue,var->value->strValue);
			}
			tobeadded->copy_to_caller=var->copy_to_caller;
			
			tobeadded->next=var;
			cur->proce_table[i].next=tobeadded;

			var=var->next;
		}
	}
	new->caller_pointer=cur_procedure_vt;
	cur_procedure_vt=new;
}

void initHashTables(){
	struct HashTables* new_procedure=(struct HashTables*)malloc(sizeof(struct HashTables));
	strcpy(new_procedure->proce_name,"main");
	int i;
	for(i=0;i<=MAX_HASHTABLE_SIZE;i++){
		new_procedure->proce_table[i].next=NULL;
	}
	new_procedure->caller_pointer=NULL;
	root_vt=new_procedure;
	cur_procedure_vt=new_procedure;
	tree_root=NULL;

	//DefineRelation:
	/*define_main=(struct DefineRelation*)malloc(sizeof(struct DefineRelation));
	define_main->sub_define_cnt=0;
	define_main->curhashtable=new_procedure;
	define_main->parentprocedure=NULL;
	//define_main->nextprocedure=NULL;
	cur_define=define_main;//当前正在定义的是main结构
	*/
}

void addHashTable(char* proce_name){//called before params are added to current hashtable:not used now
	struct HashTables* new_procedure=(struct HashTables*)malloc(sizeof(struct HashTables));
	strcpy(new_procedure->proce_name, proce_name);
	int i;
	for(i=0;i<=MAX_HASHTABLE_SIZE;i++){
		new_procedure->proce_table[i].next=NULL;
	}

	new_procedure->caller_pointer=cur_procedure_vt;
	cur_procedure_vt=new_procedure;
}

void addReturnValue(char* return_name, idType return_type){//put function name as a variable into the current hashtable
	printf("return_name=%s\n", return_name);
	int hash=CalculateHashNumber(return_name);

	struct VariableTable* toBeAdded=(struct VariableTable*)malloc(sizeof(struct VariableTable));
	strcpy(toBeAdded->name, return_name);
	toBeAdded->value=(struct Node*)malloc(sizeof(struct Node*));
	toBeAdded->value->type=return_type;
	toBeAdded->next=cur_procedure_vt->proce_table[hash].next;
	cur_procedure_vt->proce_table[hash].next=toBeAdded;
}

void replaceInCaller(struct HashTables* caller, char* name, int hash, struct Node* src){
	struct VariableTable* tmp=caller->proce_table[hash].next;
	while(tmp!=NULL){
		if(tmp->value->type!=src->type) printf("Error: type of '%s' dismatched while returning\n", name);
		switch(tmp->value->type){
			case integer: tmp->value->intValue=src->intValue; 
						  tmp->value->boolValue=(tmp->value->intValue==0)?0:1; 
						  tmp->value->realValue=(float)tmp->value->intValue;
						  break;
			case real:	  tmp->value->realValue=src->realValue;  
						  tmp->value->intValue=(int)tmp->value->realValue; 
						  break;
			case boolean: tmp->value->boolValue=tmp->value->intValue=src->boolValue; break;
			case character: tmp->value->intValue=src->intValue; break;
			case string: strcpy(tmp->value->strValue, src->strValue); break;
		}
		tmp=tmp->next;
	}
}

void deleteHashTable(){
	int i;
	struct HashTables* caller = cur_procedure_vt->caller_pointer;
	struct VariableTable* tmp;
	struct VariableTable* tmpnext;

	for(i=0;i<MAX_HASHTABLE_SIZE;i++){
		tmp=cur_procedure_vt->proce_table[i].next;
		while(tmp!=NULL){
			tmpnext=tmp->next;
			if(tmp->copy_to_caller==1){/*find this ID in caller table, and update its value*/
				replaceInCaller(caller, tmp->name, i, tmp->value);
			}
			free(tmp);
			tmp=tmpnext;
		}
	}
	struct HashTables* toBeFreed = cur_procedure_vt;//will be freed
	cur_procedure_vt=caller;
	free(toBeFreed);
}

void addToNameList(char *s){
	strcpy(nlist[name_list_cnt].name, s);
	//printf("added to name_list: %s\n", s);
	name_list_cnt++;
}

void getId(char *s)//保存变量名
{
	if(save_cnt==1) save_cnt=0;
	else save_cnt++;
	switch(save_cnt){
		case 0: strcpy(save,s);break;
		case 1: strcpy(save1,s);break;
	}
	//printf("procedure_cnt=%d\n", procedure_cnt);
	switch(procedure_cnt){
		case program_head:	break;
		case type_define:	if(isTypeDefineID) strcpy(type_define_save,s); 
							if(isNameList) { addToNameList(s); }
							break;
		case var_define:	if(isVarDefineID) strcpy(var_define_save,s);
							if(isNameList){ addToNameList(s); }
							break;
		case function_define:	if(isFuncDefineID){strcpy(fvalue,s);addHashTable(fvalue);isFuncDefineID=0;}
								if(isNameList){ addToNameList(s); }
								break;
		case procedure_define:	if(isProcDefineID){strcpy(pvalue,s);addHashTable(pvalue);isProcDefineID=0;}
								if(isNameList){ addToNameList(s); }
								break;
		case procedure_body:		
		case function_body:	
		case mainprogram:	if(isForID){ printf("forID: %s\n", s);getForID(s); isForID=0;} break;
	}
}
void getAssignID(char *s){
	strcpy(assignID,s);
}
void getForID(char *s){
	strcpy(forID, s);
}
void getConst(char *s)//
{
	strcpy(cvalue,s);
}
void getType(char *s)//
{
	strcpy(sys_type,s);
}
void getCallerID(char *s){
	strcpy(callerID, s);
}

char res[20];
char* getIdType(int i){
	switch(i){
		case 0: strcpy(res, "boolean"); break;
		case 1: strcpy(res, "integer"); break;
		case 2: strcpy(res, "real"); break;
		case 3: strcpy(res, "character"); break;
		case 4: strcpy(res, "string"); break;
		case 5: strcpy(res, "record"); break;
		case 6: strcpy(res, "array"); break;
		case 7: strcpy(res, "subrange"); break;
		case 8: strcpy(res, "enumeration"); break;
	}
	return res;
}

char* getStatementType(int i){
	switch(i){
		case 0: strcpy(res, "assign"); break;
		case 1: strcpy(res, "proc"); break;
		case 2: strcpy(res, "compound"); break;
		case 3: strcpy(res, "iff"); break;
		case 4: strcpy(res, "repeat"); break;
		case 5: strcpy(res, "whilee"); break;
		case 6: strcpy(res, "forr"); break;
		case 7: strcpy(res, "casee"); break;
		case 8: strcpy(res, "gotoo"); break;
		case 9: strcpy(res, "write"); break;
		case 10: strcpy(res, "caseexp"); break;
	}
	return res;
}

char* getOperation(int i){
	switch(i){
		case 0: strcpy(res, "add"); break;
		case 1: strcpy(res, "sub"); break;
		case 2: strcpy(res, "mul"); break;
		case 3: strcpy(res, "div"); break;
		case 4: strcpy(res, "mod"); break;
		case 5: strcpy(res, "or"); break;
		case 6: strcpy(res, "and"); break;
		case 7: strcpy(res, "not"); break;
		case 8: strcpy(res, "ge"); break;
		case 9: strcpy(res, "gt"); break;
		case 10: strcpy(res, "le"); break;
		case 11: strcpy(res, "lt"); break;
		case 12: strcpy(res, "eq"); break;
		case 13: strcpy(res, "ue"); break;
		case 14: strcpy(res, "none"); break;
	}
	return res;
}

char* getNodeType(int i){
	switch(i){
		case 0: strcpy(res, "anoperator"); break;
		case 1: strcpy(res, "anid"); break;
		case 2: strcpy(res, "value"); break;
		case 3: strcpy(res, "namelist"); break;
		case 4: strcpy(res, "comparation"); break;
		case 5: strcpy(res, "logic"); break;
		case 6: strcpy(res, "stmt"); break;
		case 7: strcpy(res, "expr"); break;
		case 8: strcpy(res, "root"); break;
		case 9: strcpy(res, "valpara"); break;
		case 10: strcpy(res, "varpara"); break;
		case 11: strcpy(res, "parameter"); break;
		case 12: strcpy(res, "function"); break;
		case 13: strcpy(res, "functhead"); break;
		case 14: strcpy(res, "procedure"); break;
		case 15: strcpy(res, "procehead"); break;
		case 16: strcpy(res, "sysfunc"); break;
		case 17: strcpy(res, "read"); break;
		case 18: strcpy(res, "idontknow"); break;
	}
	return res;
}

void getNode(struct TreeNode* node, FILE* file_pt){
	fprintf(file_pt, "node_type: %s\n", getNodeType(node->node_type));
	//printf("node_type: %s\n", getNodeType(node->node_type));
	switch(node->node_type){
		case anoperator: fprintf(file_pt, "operation: %s\n", getOperation(node->operation)); 
						//printf("operation: %s\n", getOperation(node->operation)); 
						break;
		case anid: break;
		case value: fprintf(file_pt, "node_value: type=%s intValue=%d realValue=%f charValue=%c boolValue=%d strValue=%s\n", 
							getIdType(node->node_value->type), node->node_value->intValue, node->node_value->realValue, 
							node->node_value->charValue, node->node_value->boolValue, node->node_value->strValue); 
					//printf("node_value: type=%s intValue=%d realValue=%f charValue=%c boolValue=%d strValue=%s\n", 
					//		getIdType(node->node_value->type), node->node_value->intValue, node->node_value->realValue, 
					//		node->node_value->charValue, node->node_value->boolValue, node->node_value->strValue); 
					break;
		case namelist: break;
		case comparation: break;
		case logic: break;
		case stmt:	//printf("statement: %s\n", getStatementType(node->statement)); 
					fprintf(file_pt, "statement: %s\n", getStatementType(node->statement)); 
					if(node->statement==forr)  //printf("direction: %d\n", node->direction);   
						fprintf(file_pt, "direction: %d\n", node->direction);   
					break;
		case expr: break;
		case root: break;
		case valpara: break;
		case varpara: break;
		case parameter: break;
		case function:	//printf("funct_proce_name: %s  ", node->funct_proce_name);
						//printf("funct_proce_return: type=%s\n", getIdType(node->funct_proce_return->type));
						fprintf(file_pt, "funct_proce_name: %s  ", node->funct_proce_name);
						fprintf(file_pt, "funct_proce_return: type=%s\n", getIdType(node->funct_proce_return->type));
						break;
		case functhead: break;
		case procedure: //printf("funct_proce_name: %s\n", node->funct_proce_name); 
						fprintf(file_pt, "funct_proce_name: %s\n", node->funct_proce_name);
						break;
		case procehead: break;
		case idontknow: break;
	}

}

void treeTraversal(struct TreeNode* root, FILE* fp_tree){
	struct TreeNode* cur=root;
	getNode(cur, fp_tree);

	fprintf(fp_tree, "==============================================\n");
	if(cur->left_child==NULL&&cur->right_child==NULL&&cur->next_sibling==NULL){
		//printf(">Return to parent\n");
		fprintf(fp_tree, ">Return to parent\n");
		return ;
	}
	if(cur->left_child!=NULL){
		//printf(">To left child\n");
		fprintf(fp_tree, ">To left child\n");
		treeTraversal(cur->left_child, fp_tree);
	}
	if(cur->right_child!=NULL){
		//printf(">To right child\n");
		fprintf(fp_tree, ">To right child\n");
		treeTraversal(cur->right_child, fp_tree);
	}
	if(cur->next_sibling!=NULL){
		//printf(">To next sibling\n");
		fprintf(fp_tree, ">To next sibling\n");
		treeTraversal(cur->next_sibling, fp_tree);
	}
	fprintf(fp_tree, ">Return to parent\n");
	//printf(">Return to parent\n");
}

void writeTree(struct TreeNode* root){
	FILE *fp_tree = fopen("d:\\tree_out.txt","w");
	//printf("Content in sytax tree\n");
	//printf("==============================================\n");
	fputs("Content in sytax tree\n",fp_tree);
	fputs("==============================================\n",fp_tree);
	treeTraversal(root, fp_tree);

	fclose(fp_tree);
}

void enumTableTraversal(){
	int i, j;

	printf("Content in enumeration table\n");
	for(i=0;i<etable_cnt;i++){
		printf("==============================================\n");
		printf("etable[%d]: %s\n", i, etable[i].name);
		for(j=0;j<etable[i].cnt;j++){
			printf("%s  ", etable[i].content[j]);
		}
		printf("\n");
	}
}

void hashTableTraversal(){
	FILE *fp_hash = fopen("d:\\hash_out.txt","w");

	fprintf(fp_hash, "Content in current hash table\n");
	struct HashTables* outtmp=cur_procedure_vt;
	while(outtmp!=NULL){
		fprintf(fp_hash, "==============================================\n");
		int i;
		for(i=0;i<MAX_HASHTABLE_SIZE;i++){
			fprintf(fp_hash, "hash=%d: ", i);
			struct VariableTable* tmp=outtmp->proce_table[i].next;
			while(tmp!=NULL){//traverse the list of hash number=i
				fprintf(fp_hash, "%s  ", tmp->name);
				tmp=tmp->next;
			}
			fprintf(fp_hash, "\n");
		}
		
		outtmp=outtmp->caller_pointer;
	}
	fclose(fp_hash);
}

void constTableTraversal(){
	int i, j;
	printf("Content in current const table\n");
	printf("==============================================\n");
	for(i=0;i<const_cnt;i++){
		printf("ctable[%d]    %s: ", i, ctable[i].name);
		struct Node* tmp=ctable[i].value;
		switch(tmp->type){
			case integer:	printf("integer(%d)  ",tmp->intValue);  break;
			case character:	printf("character(%c)  ",tmp->charValue); break;
			case real:		printf("real(%f)  ",tmp->realValue); break;
			case string:	printf("string(%s)  ",tmp->strValue); break;
			case boolean:	printf("boolean(%d)  ",tmp->boolValue); break;
		}
		printf("\n");
	}

}
