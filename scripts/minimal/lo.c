// LO: a global accessed only while holding one mutex is consistently protected; LO removes its instrumentation.
#include <pthread.h>
#include <stdio.h>
static pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
static long counter;
void *worker(void *a) { for (int i = 0; i < 1000; i++) { pthread_mutex_lock(&m); counter++; pthread_mutex_unlock(&m); } return 0; }
int main(void) {
  pthread_t t[4]; for (int i = 0; i < 4; i++) pthread_create(&t[i], 0, worker, 0);
  for (int i = 0; i < 4; i++) pthread_join(t[i], 0);
  pthread_mutex_lock(&m); printf("%ld\n", counter); pthread_mutex_unlock(&m); return 0;
}
