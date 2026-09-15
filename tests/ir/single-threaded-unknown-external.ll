; The thread that races with an access is usually started inside a call the
; module cannot see into: a helper in another translation unit, a library's
; initialisation. Such a call ends the single-threaded prefix. Before this,
; a bodiless callee was never a possible thread creator, so the store after
; @start_worker in main -- and in any helper making the same call -- was
; classified single-threaded and left uninstrumented. A recognised library
; function, or a callback carrier handed a harmless callback, keeps the
; prefix going; an indirect call or a carrier handed a creating callback
; ends it.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-single-threaded -S | FileCheck %s
; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -S | FileCheck %s --check-prefix=NOSTC

; (Calls to functions that may unwind become invokes, so the call lines
; match either form.)

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@g = global i32 0, align 4
@h = global i32 0, align 4
@slot = global ptr null, align 8
@buf = global [4 x i32] zeroinitializer, align 4
@fmt = private constant [3 x i8] c"x\0A\00"

declare i32 @pthread_create(ptr, ptr, ptr, ptr)
declare void @start_worker()
declare i32 @printf(ptr, ...)
declare void @qsort(ptr, i64, i64, ptr)

define internal ptr @worker(ptr %arg) sanitize_thread {
  store i32 1, ptr @g, align 4
  ret ptr null
}

; Called from main before the unknown call: single-threaded, elided.
define internal void @before_unknown() sanitize_thread {
; CHECK-LABEL: @before_unknown
; CHECK-NOT:   call void @__tsan_write4
; CHECK:       ret void
; NOSTC-LABEL: @before_unknown
; NOSTC:       call void @__tsan_write4(ptr @h)
  store i32 1, ptr @h, align 4
  ret void
}

; Called from main after it: multi-threaded, instrumented.
define internal void @after_unknown() sanitize_thread {
; CHECK-LABEL: @after_unknown
; CHECK:       call void @__tsan_write4(ptr @g)
; CHECK:       ret void
  store i32 2, ptr @g, align 4
  ret void
}

; Makes the unknown call itself: a creator, every access instrumented.
define internal void @calls_unknown() sanitize_thread {
; CHECK-LABEL: @calls_unknown
; CHECK:       {{call|invoke}} void @start_worker()
; CHECK:       call void @__tsan_write4(ptr @g)
; CHECK:       ret void
  call void @start_worker()
  store i32 3, ptr @g, align 4
  ret void
}

; A library function TargetLibraryInfo recognises starts no thread.
define internal void @calls_printf() sanitize_thread {
; CHECK-LABEL: @calls_printf
; CHECK:       {{call|invoke}} i32 (ptr, ...) @printf
; CHECK-NOT:   call void @__tsan_write4
; CHECK:       ret void
; NOSTC-LABEL: @calls_printf
; NOSTC:       call void @__tsan_write4(ptr @h)
  %r = call i32 (ptr, ...) @printf(ptr @fmt)
  store i32 4, ptr @h, align 4
  ret void
}

; An indirect call could reach a creator.
define internal void @indirect() sanitize_thread {
; CHECK-LABEL: @indirect
; CHECK:       {{call|invoke}} void %fp()
; CHECK:       call void @__tsan_write4(ptr @g)
; CHECK:       ret void
  %fp = load ptr, ptr @slot, align 8
  call void %fp()
  store i32 5, ptr @g, align 4
  ret void
}

define internal i32 @cmp(ptr %a, ptr %b) sanitize_thread {
  ret i32 0
}
define internal i32 @cmp_spawn(ptr %a, ptr %b) sanitize_thread {
  %t = alloca i64, align 8
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  ret i32 0
}

; qsort starts no thread; its comparator might.
define internal void @via_qsort_ok() sanitize_thread {
; CHECK-LABEL: @via_qsort_ok
; CHECK:       {{call|invoke}} void @qsort
; CHECK-NOT:   call void @__tsan_write4
; CHECK:       ret void
; NOSTC-LABEL: @via_qsort_ok
; NOSTC:       call void @__tsan_write4(ptr @h)
  call void @qsort(ptr @buf, i64 4, i64 4, ptr @cmp)
  store i32 6, ptr @h, align 4
  ret void
}
define internal void @via_qsort_spawn() sanitize_thread {
; CHECK-LABEL: @via_qsort_spawn
; CHECK:       {{call|invoke}} void @qsort
; CHECK:       call void @__tsan_write4(ptr @g)
; CHECK:       ret void
  call void @qsort(ptr @buf, i64 4, i64 4, ptr @cmp_spawn)
  store i32 7, ptr @g, align 4
  ret void
}

; The lost race: main's store after @start_worker.
define i32 @main() sanitize_thread {
; CHECK-LABEL: @main
; CHECK-NOT:   call void @__tsan_write4(ptr @h)
; CHECK:       {{call|invoke}} void @start_worker()
; CHECK:       call void @__tsan_write4(ptr @g)
; CHECK:       ret i32 0
; NOSTC-LABEL: @main
; NOSTC:       call void @__tsan_write4(ptr @h)
; NOSTC:       {{call|invoke}} void @start_worker()
; NOSTC:       call void @__tsan_write4(ptr @g)
entry:
  store i32 7, ptr @h, align 4
  call void @before_unknown()
  call void @calls_printf()
  call void @via_qsort_ok()
  call void @start_worker()
  store i32 2, ptr @g, align 4
  call void @after_unknown()
  call void @calls_unknown()
  call void @indirect()
  call void @via_qsort_spawn()
  %t = alloca i64, align 8
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  ret i32 0
}
