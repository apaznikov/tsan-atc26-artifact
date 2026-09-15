; The arguments of a call whose returned pointer escapes must be analysed
; like any other call's. The classifier answered "the result escapes" for
; every pointer operand of such a call, so the arguments were never looked
; at: @leak_and_return stores its argument to a global and returns a global
; pointer, the caller starts a thread that writes through the global, and
; the caller's later store to the local was elided -- a lost race. The same
; callee returning void (@leak) was handled, which is the first control; a
; callee that returns an escaped pointer but retains nothing (@harmless)
; leaves the local unpublished, and its store is still elided.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@sink = global ptr null, align 8
@box = global i32 0, align 4
declare i32 @pthread_create(ptr, ptr, ptr, ptr)

define internal ptr @leak_and_return(ptr %p) noinline {
  store ptr %p, ptr @sink, align 8
  ret ptr @box
}
define internal void @leak(ptr %p) noinline {
  store ptr %p, ptr @sink, align 8
  ret void
}
define internal ptr @harmless(ptr %p) noinline {
  %v = load i32, ptr %p, align 4
  store i32 %v, ptr @box, align 4
  ret ptr @box
}
define internal ptr @worker(ptr %a) sanitize_thread {
  %v = load ptr, ptr @sink, align 8
  store i32 9, ptr %v, align 4
  ret ptr null
}

; CHECK-LABEL: @caller
; CHECK:       call void @__tsan_write4(ptr %local)
; CHECK:       ret i32 0
define i32 @caller() sanitize_thread {
  %local = alloca i32, align 4
  %t = alloca i64, align 8
  %r = call ptr @leak_and_return(ptr %local)
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  store i32 1, ptr %local, align 4
  ret i32 0
}

; CHECK-LABEL: @control_void
; CHECK:       call void @__tsan_write4(ptr %local)
; CHECK:       ret i32 0
define i32 @control_void() sanitize_thread {
  %local = alloca i32, align 4
  %t = alloca i64, align 8
  call void @leak(ptr %local)
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  store i32 1, ptr %local, align 4
  ret i32 0
}

; CHECK-LABEL: @control_harmless
; CHECK-NOT:   call void @__tsan_write4(ptr %local)
; CHECK:       ret i32 0
define i32 @control_harmless() sanitize_thread {
  %local = alloca i32, align 4
  %t = alloca i64, align 8
  store i32 0, ptr %local, align 4
  %r = call ptr @harmless(ptr %local)
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  store i32 1, ptr %local, align 4
  ret i32 0
}
