// EA: a heap object whose address never escapes the thread that allocated it cannot be shared, so
// its accesses cannot race; EA removes their instrumentation. The object is filled and summed here
// while another thread exists, so nothing but the escape analysis can prove the accesses safe.
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
void *worker(void *a) { return a; }
long fill_and_sum(int n) {
  long *buf = malloc(n * sizeof(long));            // address never stored anywhere reachable by another thread
  for (int i = 0; i < n; i++) buf[i] = i;
  long s = 0; for (int i = 0; i < n; i++) s += buf[i];
  free(buf); return s;
}
int main(void) {
  pthread_t t; pthread_create(&t, 0, worker, 0);
  long s = fill_and_sum(1000);
  pthread_join(t, 0); printf("%ld\n", s); return 0;
}
