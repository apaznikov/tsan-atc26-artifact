// The thread that races with main is started by a call into another
// translation unit. The single-threaded-context analysis cannot see into
// start_worker, so it must take the call for a possible thread creation and
// keep instrumenting main's store after it. Before this, a bodiless callee
// was never a creator: main's store was classified single-threaded, left
// uninstrumented, and this race went unreported.

// RUN: %clang_tsan_stock -O1 -c -DTU2 %s -o %t.tu2.o
// RUN: %clang_tsan -O1 %s %t.tu2.o -o %t -mllvm -tsan-use-single-threaded && %deflake %run %t 2>&1 | FileCheck %s
// RUN: %clang_tsan_stock -O1 %s %t.tu2.o -o %t.stock && %deflake %run %t.stock 2>&1 | FileCheck %s

#ifdef TU2
#include <pthread.h>
void start_worker(pthread_t *t, void *(*fn)(void *)) {
  pthread_create(t, NULL, fn, NULL);
}
#else
#include "test.h"

int Global;

void *Thread(void *x) {
  barrier_wait(&barrier);
  Global = 1;
  return NULL;
}

void start_worker(pthread_t *t, void *(*fn)(void *));

int main() {
  barrier_init(&barrier, 2);
  pthread_t t;
  start_worker(&t, Thread);
  Global = 2;
  barrier_wait(&barrier);
  pthread_join(t, NULL);
  return Global == 42;
}
#endif

// CHECK: WARNING: ThreadSanitizer: data race
// CHECK: #0 main
