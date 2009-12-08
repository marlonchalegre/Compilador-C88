#include <stdlib.h>
#include <stdio.h>
#include "stack.h"

/*int main(void) {
    Stack *a = init_stack();// = (Stack *) malloc(sizeof(Stack));
    printf("a\n");
    printf("value: %d\n", pop(a));
    push(a, 2);
    printf("b\n");
    printf("value: %d\n", pop(a));
    printf("c\n");
    //a->pt = -1;
    //a->stack[++a->pt] = 33;
    //a->pt = 1;
    //init_stack(a);
    //printf("2\n");
    //push(a, 1);
    //if (is_empty(a))
       // printf("pt: %d\n", );
    //printf("3\n");
    //printf("stack %d\n", pop(a));
    return 0;
}*/

Stack *init_stack() {
    Stack *s = (Stack *) malloc(sizeof(Stack));
    s->pt = -1;
    return s;
}

void push(Stack *s, void *value) {
    if (!is_stack_full(s))
        s->stack[++s->pt] = value;
    else
        printf("Error: stack full.\n");
}

void *pop(Stack *s) {
    if (!is_stack_empty(s))
        return s->stack[s->pt--];
    else {
        printf("Error: stack empty.\n");
        return (void *)-1;
    }
}

int is_stack_empty(Stack *s) {
    return s->pt == -1;
}

int is_stack_full(Stack *s) {
    return s->pt == STACK_MAX;
}
