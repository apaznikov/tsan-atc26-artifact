// A real race: main and the worker write the same variable with no synchronization between them.
// Every configuration must report it. The worker sleeps before writing so that the two writes are
// far apart in time: ThreadSanitizer only reports a race when the second access finds the first
// one's record, and for two writes a few microseconds apart the outcome depends on the schedule.
// The sleep orders the writes in time without creating any happens-before edge.
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>
int racy;
void *worker(void *a) { usleep(100000); racy = 1; return 0; }
int main(void) {
  pthread_t t; pthread_create(&t, 0, worker, 0);
  racy = 2;
  pthread_join(t, 0); printf("%d\n", racy); return 0;
}
