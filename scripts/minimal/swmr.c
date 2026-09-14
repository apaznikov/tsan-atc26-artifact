// SWMR: a global written only before threads exist and read afterwards; SWMR removes the reads' instrumentation.
#include <pthread.h>
#include <stdio.h>
static int config[64];
void *worker(void *a) { long s = 0; for (int i = 0; i < 64; i++) s += config[i]; return (void *)s; }
int main(void) {
  for (int i = 0; i < 64; i++) config[i] = i;        // the only writes, before any thread
  pthread_t t[4]; long total = 0;
  for (int i = 0; i < 4; i++) pthread_create(&t[i], 0, worker, 0);
  for (int i = 0; i < 4; i++) { void *r; pthread_join(t[i], &r); total += (long)r; }
  printf("%ld\n", total); return 0;
}
