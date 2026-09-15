; A callee that stores its pointer argument through another argument
; publishes the caller's object into the caller's memory: `*out = p`. The
; bottom-up summary recorded p as escaping only by the seed reason every
; pointer argument carries (PTR_ARG_ALIASING), the reason callers mask out
; as "just an argument", so the caller saw both arguments as non-escaping,
; never learned that its slot held the local, published the slot's content
; to a global, started a thread that writes through it, and elided its own
; later store to the local: a lost race. Stored through external memory now
; carries a bit that survives the mask. @reads_only is the control: a callee
; that only reads through its arguments and stores something else through
; the slot leaves the local unpublished, and its store is still elided; so is
; a callee that stores the pointer only into its own local slot.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -S | FileCheck %s
; RUN: opt < %s -passes='print<escape-analysis-global>' -disable-output 2>&1 | FileCheck %s --check-prefix=PRINT

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@sink = global ptr null, align 8
@other = global i32 0, align 4
declare i32 @pthread_create(ptr, ptr, ptr, ptr)

define internal void @publish_via_out(ptr %p, ptr %out) noinline {
  store ptr %p, ptr %out, align 8
  ret void
}

define internal void @reads_only(ptr %p, ptr %out) noinline {
  %v = load i32, ptr %p, align 4
  store i32 %v, ptr @other, align 4
  store ptr @other, ptr %out, align 8
  ret void
}

define internal void @keeps_locally(ptr %p) noinline {
  %mine = alloca ptr, align 8
  store ptr %p, ptr %mine, align 8
  ret void
}

define internal ptr @worker(ptr %a) sanitize_thread {
  %v = load ptr, ptr @sink, align 8
  store i32 9, ptr %v, align 4
  ret ptr null
}

; CHECK-LABEL: @caller
; CHECK:       call void @__tsan_write4(ptr %local)
; CHECK:       ret i32 0
; PRINT-LABEL: function 'caller'
; PRINT:       %local = alloca i32
define i32 @caller() sanitize_thread {
  %local = alloca i32, align 4
  %slot = alloca ptr, align 8
  %t = alloca i64, align 8
  call void @publish_via_out(ptr %local, ptr %slot)
  %p = load ptr, ptr %slot, align 8
  store ptr %p, ptr @sink, align 8
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  store i32 1, ptr %local, align 4
  ret i32 0
}

; CHECK-LABEL: @control_reads_only
; CHECK-NOT:   call void @__tsan_write4(ptr %local)
; CHECK:       ret i32 0
define i32 @control_reads_only() sanitize_thread {
  %local = alloca i32, align 4
  %slot = alloca ptr, align 8
  %t = alloca i64, align 8
  store i32 0, ptr %local, align 4
  call void @reads_only(ptr %local, ptr %slot)
  %p = load ptr, ptr %slot, align 8
  store ptr %p, ptr @sink, align 8
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  store i32 1, ptr %local, align 4
  ret i32 0
}

; CHECK-LABEL: @control_local_slot
; CHECK-NOT:   call void @__tsan_write4(ptr %local)
; CHECK:       ret i32 0
define i32 @control_local_slot() sanitize_thread {
  %local = alloca i32, align 4
  %t = alloca i64, align 8
  call void @keeps_locally(ptr %local)
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr null)
  store i32 1, ptr %local, align 4
  ret i32 0
}
