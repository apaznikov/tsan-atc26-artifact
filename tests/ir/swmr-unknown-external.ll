; SWMR inherits the single-threaded verdict for the writes it discounts. A
; write after a call into code this module cannot see may run while a thread
; that call started exists, so the global is not read-only; a global written
; only before the call still is.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-swmr -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@loc = internal global i32 0, align 4
@loc2 = internal global i32 0, align 4
declare void @start_worker()
declare i32 @pthread_create(ptr, ptr, ptr, ptr)

define internal ptr @reader(ptr %a) sanitize_thread {
; CHECK-LABEL: @reader
; CHECK:       call void @__tsan_read4(ptr @loc)
; CHECK-NOT:   call void @__tsan_read4(ptr @loc2)
; CHECK:       ret ptr null
  %l = load i32, ptr @loc, align 4
  %l2 = load i32, ptr @loc2, align 4
  ret ptr null
}

define i32 @main() sanitize_thread {
  store i32 1, ptr @loc, align 4
  store i32 1, ptr @loc2, align 4
  call void @start_worker()
  store i32 2, ptr @loc, align 4
  %t = alloca i64, align 8
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @reader, ptr null)
  ret i32 0
}
