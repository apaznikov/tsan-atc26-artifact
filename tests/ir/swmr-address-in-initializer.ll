; A global whose address sits in another global's initializer is published
; before main runs: any thread may load that pointer and write through it,
; and no instruction in this module names the global at that write. The
; access walk saw only instruction users (and the constant expressions and
; aliases over them), so such a global counted as read-only and main's read
; of it after the thread started was elided while the thread wrote it
; through the published pointer (shape 20). Three ways the address gets into
; an initializer: directly (@g), inside a constant aggregate through a
; constant getelementptr (@agg), and through llvm.used (@u). @loc is the
; control: never address-taken, written only before the thread exists,
; read-only, elided.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-swmr -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@g = internal global i32 0, align 4
@slot = global ptr @g, align 8
@agg = internal global [2 x i32] zeroinitializer, align 4
@table = global { i32, ptr } { i32 0, ptr getelementptr ([2 x i32], ptr @agg, i64 0, i64 1) }, align 8
@u = internal global i32 0, align 4
@llvm.used = appending global [1 x ptr] [ptr @u], section "llvm.metadata"
@loc = internal global i32 0, align 4
declare i32 @pthread_create(ptr, ptr, ptr, ptr)

define internal ptr @writer(ptr %a) sanitize_thread {
  %p = load ptr, ptr @slot, align 8
  store i32 1, ptr %p, align 4
  %q = load ptr, ptr getelementptr ({ i32, ptr }, ptr @table, i64 0, i32 1), align 8
  store i32 1, ptr %q, align 4
  ret ptr null
}

define i32 @main() sanitize_thread {
; CHECK-LABEL: @main
; CHECK:       {{call|invoke}} i32 @pthread_create
; CHECK:       call void @__tsan_read4(ptr @g)
; CHECK:       call void @__tsan_read4(ptr getelementptr {{.*}}@agg
; CHECK:       call void @__tsan_read4(ptr @u)
; CHECK-NOT:   call void @__tsan_read4(ptr @loc)
; CHECK:       ret i32
  %t = alloca i64, align 8
  store i32 1, ptr @g, align 4
  store i32 1, ptr @u, align 4
  store i32 1, ptr @loc, align 4
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @writer, ptr null)
  %v = load i32, ptr @g, align 4
  %w = load i32, ptr getelementptr ([2 x i32], ptr @agg, i64 0, i64 1), align 4
  %x = load i32, ptr @u, align 4
  %l = load i32, ptr @loc, align 4
  %s1 = add i32 %v, %w
  %s2 = add i32 %s1, %x
  %s3 = add i32 %s2, %l
  ret i32 %s3
}
