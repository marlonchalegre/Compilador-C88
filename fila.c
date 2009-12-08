#include <stdio.h>
#include <stdlib.h>
#include "fila.h"

//Queue* first;
//Queue* last;

/*int main(void) {
    printf("1\n");
    Queue *q = init_queue();
    printf("2\n");
    enqueue(q, "a");
    printf("3\n");
    printf("dequeue: %s\n", dequeue(q));
    printf("4\n");

    return 0;
}*/

Queue *init_queue(void) {
    Queue *nova = (Queue *) malloc(sizeof(Queue));
    Queue_elmt *elmt = (Queue_elmt*)malloc(sizeof(Queue_elmt));
    elmt->value = NULL;
    elmt->next = NULL;
    nova->first = nova->last = elmt;
    return nova;
}

Queue_elmt* newQueue_elmt(void) {
    Queue_elmt* elmt = (Queue_elmt*)malloc(sizeof(Queue_elmt));
    elmt->value = NULL;
    elmt->next = NULL;
    return elmt;
}

void enqueue(Queue *q, char* value){
    q->last->value = value;
    q->last->next = newQueue_elmt();
    q->last = q->last->next;
}

char *dequeue(Queue *q) {
    if (is_queue_empty(q))
	return NULL;
    char* value = q->first->value;
    Queue_elmt* next = q->first->next;
    free(q->first);
    q->first = q->first->next;
    return value;
}

int is_queue_empty(Queue *q) {
    return q->first->value == NULL;
}
