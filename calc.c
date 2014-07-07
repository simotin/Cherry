#include <string.h>

typedef struct {
	int age;
	char name[128];
} ST_PERSON;

// ============================================================================
// プロトタイプ宣言
// NOTICE
//   ractinではテスト対象となる関数のプロトタイプ宣言が必ず必要!
// ============================================================================

int add(int a, int b);
ST_PERSON init_person(int age, char *name);

int add(int a, int b) {
	return a+b;
}

ST_PERSON init_person(int age, char *name) {
	ST_PERSON person;
	person.age = age;
	strcpy(person.name, name);
	return person;
}
