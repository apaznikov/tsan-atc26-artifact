; A library call that returns a pointer into its argument -- strchr, strcpy,
; memchr, fgets, realloc (TargetLibraryInfo::returnsPointerIntoArg) -- hands
; the caller's object back under another name. The escape analysis treated
; that result as an object of its own (an "escaped call" register), so
; storing it to a global published nothing about the buffer, and the
; buffer's accesses were elided while a thread wrote it through the
; published pointer (shape 21). Now the object walk continues from the
; argument, and the later-escape walk follows the result's uses. Controls:
; a result that is only compared publishes nothing (@strchr_result_private),
; a local stored through a result that points into a global still escapes
; (@store_through_result_into_global), a realloc of a private block is
; still private (@realloc_result_private), and realloc(NULL, n) -- an
; allocation, no argument object to stand for -- stays an object of its own
; and, published, is instrumented (@realloc_null_published).

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@g = global ptr null, align 8
@gbuf = global [8 x i8] zeroinitializer, align 1
@str = private constant [2 x i8] c"a\00", align 1
declare ptr @strchr(ptr, i32)
declare ptr @strcpy(ptr, ptr)
declare ptr @memchr(ptr, i32, i64)
declare ptr @fgets(ptr, i32, ptr)
declare ptr @realloc(ptr, i64)
declare noalias ptr @malloc(i64)
declare void @use(i1)

; The result of strchr is a pointer into %b; storing it publishes %b, so the
; write after the publication is instrumented.
define void @strchr_result_published() sanitize_thread {
; CHECK-LABEL: @strchr_result_published
; CHECK:       store ptr %r{{[0-9]*}}, ptr @g
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
  %b = alloca [8 x i8], align 1
  store i8 0, ptr %b, align 1
  %r = call ptr @strchr(ptr %b, i32 0)
  store ptr %r, ptr @g, align 8
  store i8 1, ptr %b, align 1
  ret void
}

; The publication comes after the access: a later escape through the
; result, so the access before it is kept as well (the thread's write is
; not ordered after it).
define void @strchr_result_published_later() sanitize_thread {
; CHECK-LABEL: @strchr_result_published_later
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
; CHECK:       store ptr %r{{[0-9]*}}, ptr @g
  %b = alloca [8 x i8], align 1
  %r = call ptr @strchr(ptr %b, i32 0)
  store i8 1, ptr %b, align 1
  store ptr %r, ptr @g, align 8
  ret void
}

; strcpy returns its destination.
define void @strcpy_result_published() sanitize_thread {
; CHECK-LABEL: @strcpy_result_published
; CHECK:       store ptr %r{{[0-9]*}}, ptr @g
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
  %b = alloca [8 x i8], align 1
  %r = call ptr @strcpy(ptr %b, ptr @str)
  store ptr %r, ptr @g, align 8
  store i8 1, ptr %b, align 1
  ret void
}

; A pointer derived from the result still points into the buffer.
define void @memchr_result_offset_published() sanitize_thread {
; CHECK-LABEL: @memchr_result_offset_published
; CHECK:       store ptr %r1{{[0-9]*}}, ptr @g
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
  %b = alloca [8 x i8], align 1
  store i8 0, ptr %b, align 1
  %r = call ptr @memchr(ptr %b, i32 0, i64 8)
  %r1 = getelementptr i8, ptr %r, i64 1
  store ptr %r1, ptr @g, align 8
  store i8 1, ptr %b, align 1
  ret void
}

; fgets returns the caller's line buffer.
define void @fgets_result_published(ptr %stream) sanitize_thread {
; CHECK-LABEL: @fgets_result_published
; CHECK:       store ptr %r{{[0-9]*}}, ptr @g
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
  %b = alloca [8 x i8], align 1
  %r = call ptr @fgets(ptr %b, i32 8, ptr %stream)
  store ptr %r, ptr @g, align 8
  store i8 1, ptr %b, align 1
  ret void
}

; Control: a result that is only compared does not publish the buffer.
define void @strchr_result_private() sanitize_thread {
; CHECK-LABEL: @strchr_result_private
; CHECK-NOT:   call void @__tsan_write1(ptr %b)
; CHECK:       ret void
  %b = alloca [8 x i8], align 1
  store i8 0, ptr %b, align 1
  %r = call ptr @strchr(ptr %b, i32 0)
  %c = icmp eq ptr %r, null
  call void @use(i1 %c)
  store i8 1, ptr %b, align 1
  ret void
}

; Control: the result points into a global; a local stored through it is
; published, so the local's write is instrumented.
define void @store_through_result_into_global() sanitize_thread {
; CHECK-LABEL: @store_through_result_into_global
; CHECK:       call void @__tsan_write4(ptr %x)
; CHECK-NEXT:  store i32 1, ptr %x
  %x = alloca i32, align 4
  %r = call ptr @strchr(ptr @gbuf, i32 0)
  store ptr %x, ptr %r, align 8
  store i32 1, ptr %x, align 4
  ret void
}

; Control: realloc of a private block stands for the same private object;
; a write through the result is not instrumented.
define void @realloc_result_private() sanitize_thread {
; CHECK-LABEL: @realloc_result_private
; CHECK-NOT:   call void @__tsan_write1(
; CHECK:       ret void
  %p = call ptr @malloc(i64 8)
  %q = call ptr @realloc(ptr %p, i64 16)
  store i8 1, ptr %q, align 1
  ret void
}

; realloc's result published: the block is shared, a later write through
; the result is instrumented.
define void @realloc_result_published() sanitize_thread {
; CHECK-LABEL: @realloc_result_published
; CHECK:       store ptr %q{{[0-9]*}}, ptr @g
; CHECK:       call void @__tsan_write1(ptr %q{{[0-9]*}})
; CHECK-NEXT:  store i8 1, ptr %q{{[0-9]*}}
  %p = call ptr @malloc(i64 8)
  %q = call ptr @realloc(ptr %p, i64 16)
  store ptr %q, ptr @g, align 8
  store i8 1, ptr %q, align 1
  ret void
}

; realloc(NULL, n) allocates; there is no argument object for the result to
; stand for. Published, the block is shared and the write is instrumented.
define void @realloc_null_published() sanitize_thread {
; CHECK-LABEL: @realloc_null_published
; CHECK:       store ptr %q{{[0-9]*}}, ptr @g
; CHECK:       call void @__tsan_write1(ptr %q{{[0-9]*}})
; CHECK-NEXT:  store i8 1, ptr %q{{[0-9]*}}
  %q = call ptr @realloc(ptr null, i64 16)
  store ptr %q, ptr @g, align 8
  store i8 1, ptr %q, align 1
  ret void
}
