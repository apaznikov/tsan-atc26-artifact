// STC: accesses before the first thread is created cannot race; STC removes their instrumentation.
#include <pthread.h>
#include <stdio.h>
int table[1024];
void *worker(void *a) { long s = 0; for (int i = 0; i < 1024; i++) s += table[i]; return (void *)s; }
int main(void) {
  for (int i = 0; i < 1024; i++) table[i] = i * 3;   // single-threaded: no thread exists yet
  pthread_t t; pthread_create(&t, 0, worker, 0); void *r; pthread_join(t, &r);
  printf("%ld\n", (long)r); return 0;
}
