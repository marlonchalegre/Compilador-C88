#define STACK_MAX 50

typedef struct {
    void *stack[STACK_MAX];
    int pt;
} Stack;

Stack *init_stack();
void *pop(Stack *s);
void push(Stack *s, void *value);
int is_stack_empty(Stack *s);
int is_stack_full(Stack *s);
