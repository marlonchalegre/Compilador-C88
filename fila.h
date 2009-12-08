typedef struct queue_elmt {

    char* value;
    struct queue_elmt *next;

} Queue_elmt;

typedef struct queue {
    Queue_elmt *first;
    Queue_elmt *last;
} Queue;

Queue* init_queue(void);
Queue* newQueue(void);
void enqueue(Queue *q, char* value);
char* dequeue(Queue *q);
int is_empty(Queue *q);
