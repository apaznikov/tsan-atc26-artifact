; The library table answers "sync-free" only for functions it names: pure
; computation, memory and string operations on the caller's buffers,
; conversions, formatting into buffers, byte order. A redundant store across
; one of those is elided. Everything else -- a file, directory or time system
; call, a stream operation without the lock, strtok with its static state,
; qsort with its callback into the program -- is treated as possibly
; synchronising and both stores stay. Before this the table's default was
; "sync-free", so the second store was elided across every function it did
; not name: across qsort, whose comparator may release a lock another thread
; then acquires before writing @x, the race on the second store was lost.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-dominance-analysis -S | FileCheck %s
; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-dominance-analysis-postdom -S | FileCheck %s --check-prefix=POSTDOM

; (Calls to functions that may unwind become invokes, so the call lines
; match either form.)

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@x = global i32 0, align 4
@buf = global [64 x i8] zeroinitializer, align 16
@fmt = private constant [3 x i8] c"%d\00"
@arr = global [4 x i32] zeroinitializer, align 4
@st = global [144 x i8] zeroinitializer, align 8
@tv = global [16 x i8] zeroinitializer, align 8
@save = global ptr null, align 8

declare ptr @memcpy(ptr, ptr, i64)
declare double @sqrt(double)
declare i32 @abs(i32)
declare i32 @snprintf(ptr, i64, ptr, ...)
declare i32 @htonl(i32)
declare i32 @atoi(ptr)
declare i32 @isdigit(i32)
declare ptr @strtok_r(ptr, ptr, ptr)
declare void @qsort(ptr, i64, i64, ptr)
declare i32 @stat(ptr, ptr)
declare i32 @gettimeofday(ptr, ptr)
declare i64 @fread_unlocked(ptr, i64, i64, ptr)
declare ptr @strtok(ptr, ptr)
declare i32 @access(ptr, i32)
declare i32 @unlink(ptr)
declare i32 @pthread_mutex_unlock(ptr)

define internal i32 @cmp(ptr %a, ptr %b) {
  ret i32 0
}

; --- sync-free: the dominated store is elided ---

; CHECK-LABEL: @across_memcpy
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} ptr @memcpy
; CHECK: ret void
define void @across_memcpy(ptr %src) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call ptr @memcpy(ptr @buf, ptr %src, i64 8)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_sqrt
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} double @sqrt
; CHECK: ret void
define void @across_sqrt(double %d) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call double @sqrt(double %d)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_abs
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @abs
; CHECK: ret void
define void @across_abs(i32 %i) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @abs(i32 %i)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_snprintf
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 (ptr, i64, ptr, ...) @snprintf
; CHECK: ret void
define void @across_snprintf(i32 %i) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 (ptr, i64, ptr, ...) @snprintf(ptr @buf, i64 64, ptr @fmt, i32 %i)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_htonl
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @htonl
; CHECK: ret void
define void @across_htonl(i32 %i) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @htonl(i32 %i)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_atoi
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @atoi
; CHECK: ret void
define void @across_atoi(ptr %s) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @atoi(ptr %s)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_isdigit
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @isdigit
; CHECK: ret void
define void @across_isdigit(i32 %c) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @isdigit(i32 %c)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_strtok_r
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK-NOT: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} ptr @strtok_r
; CHECK: ret void
define void @across_strtok_r(ptr %s, ptr %d) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call ptr @strtok_r(ptr %s, ptr %d, ptr @save)
  store i32 2, ptr @x, align 4
  ret void
}

; --- not sync-free: both stores stay ---

; CHECK-LABEL: @across_qsort
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} void @qsort
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: ret void
define void @across_qsort() sanitize_thread {
  store i32 1, ptr @x, align 4
  call void @qsort(ptr @arr, i64 4, i64 4, ptr @cmp)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_stat
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @stat
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: ret void
define void @across_stat(ptr %p) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @stat(ptr %p, ptr @st)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_gettimeofday
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @gettimeofday
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: ret void
define void @across_gettimeofday() sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @gettimeofday(ptr @tv, ptr null)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_fread_unlocked
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i64 @fread_unlocked
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: ret void
define void @across_fread_unlocked(ptr %f) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i64 @fread_unlocked(ptr @buf, i64 1, i64 8, ptr %f)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_strtok
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} ptr @strtok
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: ret void
define void @across_strtok(ptr %s, ptr %d) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call ptr @strtok(ptr %s, ptr %d)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_access
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @access
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: ret void
define void @across_access(ptr %p) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @access(ptr %p, i32 0)
  store i32 2, ptr @x, align 4
  ret void
}

; CHECK-LABEL: @across_unlink
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: {{call|invoke}} i32 @unlink
; CHECK: call void @__tsan_write4(ptr @x)
; CHECK: ret void
define void @across_unlink(ptr %p) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @unlink(ptr %p)
  store i32 2, ptr @x, align 4
  ret void
}

; --- post-dominance: the same table, the same two verdicts ---

; POSTDOM-LABEL: @postdom_strlen_free
; POSTDOM: call void @__tsan_write4(ptr @x)
; POSTDOM-NOT: call void @__tsan_write4(ptr @x)
; POSTDOM: ret void
define void @postdom_strlen_free(i32 %i) sanitize_thread {
  store i32 1, ptr @x, align 4
  %r = call i32 @abs(i32 %i) willreturn
  store i32 2, ptr @x, align 4
  ret void
}

; POSTDOM-LABEL: @postdom_qsort
; POSTDOM: call void @__tsan_write4(ptr @x)
; POSTDOM: {{call|invoke}} void @qsort
; POSTDOM: call void @__tsan_write4(ptr @x)
; POSTDOM: ret void
define void @postdom_qsort() sanitize_thread {
  store i32 1, ptr @x, align 4
  call void @qsort(ptr @arr, i64 4, i64 4, ptr @cmp) willreturn
  store i32 2, ptr @x, align 4
  ret void
}
