// DE: the second store to `shared` is dominated by the first, and the only thing between them is a
// call to a function in this file that performs no synchronization; so any race with the second
// store is also a race with the first, and DE removes the second store's instrumentation. The race
// is still reported, on the first store. (The call is what keeps both stores alive at -O2: without
// it the compiler itself would delete the first one before any analysis runs.)
#include <pthread.h>
#include <stdio.h>
long shared, other;
static __attribute__((noinline)) long peek(void) { return shared; }
void *worker(void *a) { return (void *)shared; }
__attribute__((noinline)) void update(long a) { shared = a; other += peek(); shared = a + 1; }
int main(void) {
  pthread_t t; pthread_create(&t, 0, worker, 0);
  update(1);
  void *r; pthread_join(t, &r); printf("%ld %ld %ld\n", shared, other, (long)r); return 0;
}
