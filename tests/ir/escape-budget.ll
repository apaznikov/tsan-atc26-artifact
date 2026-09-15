; The escape analysis gives up on a function that exceeds a budget
; (-tsan-ea-max-blocks here; -tsan-ea-max-evals-per-block and
; -tsan-ea-max-state-entries are the other two) and treats every object in it
; as escaped, so its accesses stay instrumented: reach is lost, no race is.
; @big has three blocks and its local is passed to strlen, so stock's
; capture rule keeps the access and only the escape analysis could elide it;
; with the budget at two blocks it is abandoned and the store stays. @small
; is the sibling within the budget: its store is elided. @caller hands a
; local to the abandoned @big before storing to it: the argument is reported
; escaped to callers, so the store stays too, and giving up on one function
; cannot loosen another. The report line names the function and the reason.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -tsan-ea-max-blocks=2 -tsan-ea-report-abandoned -S 2>&1 | FileCheck %s
; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -S | FileCheck %s --check-prefix=FULL
; RUN: opt < %s -passes='print<escape-analysis-global>' -disable-output -tsan-ea-max-blocks=2 2>&1 | FileCheck %s --check-prefix=PRINT

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

declare i64 @strlen(ptr)

; CHECK: warning: escape analysis gave up on big (too many blocks; 3 blocks, 0 evaluations)
; PRINT: (escape analysis abandoned: too many blocks; every object treated as escaped)

; CHECK-LABEL: @big
; CHECK:       call void @__tsan_write4(ptr %l)
; CHECK:       ret void
; FULL-LABEL: @big
; FULL-NOT:   call void @__tsan_write4
; FULL:       ret void
define internal void @big(ptr %p) sanitize_thread {
entry:
  %l = alloca i32, align 4
  store i32 1, ptr %l, align 4
  %n = call i64 @strlen(ptr %l)
  %m = call i64 @strlen(ptr %p)
  %c = icmp eq i64 %n, %m
  br i1 %c, label %a, label %b
a:
  ret void
b:
  ret void
}

; CHECK-LABEL: @small
; CHECK-NOT:   call void @__tsan_write4
; CHECK:       ret void
define internal void @small() sanitize_thread {
entry:
  %l = alloca i32, align 4
  store i32 2, ptr %l, align 4
  %n = call i64 @strlen(ptr %l)
  br label %exit
exit:
  ret void
}

; CHECK-LABEL: @caller
; CHECK:       call void @__tsan_write4(ptr %arg)
; CHECK:       ret void
; FULL-LABEL: @caller
; FULL-NOT:   call void @__tsan_write4(ptr %arg)
; FULL:       ret void
define void @caller() sanitize_thread {
entry:
  %arg = alloca i32, align 4
  store i32 3, ptr %arg, align 4
  call void @big(ptr %arg)
  call void @small()
  ret void
}
