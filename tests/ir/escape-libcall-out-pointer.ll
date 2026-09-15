; strtol(s, &end, base) stores a pointer into s through end. The library
; table said only that s is not retained, so the slot never pointed into the
; buffer: `strtol(buf, &end, 10); g = end;` left buf local and its later
; accesses were elided while a thread wrote it through g (shape 22). The call
; is now the store `*end = s` for the escape analysis and a store site for
; the later-escape rule. Controls: a null end pointer stores nothing
; (@strtol_endptr_null), an end pointer that is only compared publishes
; nothing (@strtol_endptr_private).

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@g = global ptr null, align 8
declare i64 @strtol(ptr, ptr, i32)
declare double @strtod(ptr, ptr)
declare void @use(i1)

; The slot's content is published after the conversion: the write to the
; buffer after that is instrumented.
define void @strtol_endptr_published() sanitize_thread {
; CHECK-LABEL: @strtol_endptr_published
; CHECK:       store ptr %e, ptr @g
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
  %b = alloca [8 x i8], align 1
  %endp = alloca ptr, align 8
  store i8 49, ptr %b, align 1
  %v = call i64 @strtol(ptr %b, ptr %endp, i32 10)
  %e = load ptr, ptr %endp, align 8
  store ptr %e, ptr @g, align 8
  store i8 1, ptr %b, align 1
  ret void
}

; The publication comes after the access: the conversion's store into the
; local slot is a site the later-escape rule keeps.
define void @strtol_endptr_published_later() sanitize_thread {
; CHECK-LABEL: @strtol_endptr_published_later
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
; CHECK:       store ptr %e, ptr @g
  %b = alloca [8 x i8], align 1
  %endp = alloca ptr, align 8
  %v = call i64 @strtol(ptr %b, ptr %endp, i32 10)
  store i8 1, ptr %b, align 1
  %e = load ptr, ptr %endp, align 8
  store ptr %e, ptr @g, align 8
  ret void
}

; strtod, the same shape.
define void @strtod_endptr_published() sanitize_thread {
; CHECK-LABEL: @strtod_endptr_published
; CHECK:       store ptr %e, ptr @g
; CHECK:       call void @__tsan_write1(ptr %b)
; CHECK-NEXT:  store i8 1, ptr %b
  %b = alloca [8 x i8], align 1
  %endp = alloca ptr, align 8
  %v = call double @strtod(ptr %b, ptr %endp)
  %e = load ptr, ptr %endp, align 8
  store ptr %e, ptr @g, align 8
  store i8 1, ptr %b, align 1
  ret void
}

; Control: a null end pointer stores nothing; the buffer stays local.
define void @strtol_endptr_null() sanitize_thread {
; CHECK-LABEL: @strtol_endptr_null
; CHECK-NOT:   call void @__tsan_write1(ptr %b)
; CHECK:       ret void
  %b = alloca [8 x i8], align 1
  store i8 49, ptr %b, align 1
  %v = call i64 @strtol(ptr %b, ptr null, i32 10)
  store i8 1, ptr %b, align 1
  ret void
}

; Control: the end pointer is only compared; nothing is published.
define void @strtol_endptr_private() sanitize_thread {
; CHECK-LABEL: @strtol_endptr_private
; CHECK-NOT:   call void @__tsan_write1(ptr %b)
; CHECK:       ret void
  %b = alloca [8 x i8], align 1
  %endp = alloca ptr, align 8
  store i8 49, ptr %b, align 1
  %v = call i64 @strtol(ptr %b, ptr %endp, i32 10)
  %e = load ptr, ptr %endp, align 8
  %c = icmp eq ptr %e, %b
  call void @use(i1 %c)
  store i8 1, ptr %b, align 1
  ret void
}
