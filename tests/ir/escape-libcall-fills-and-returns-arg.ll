; realpath and ctermid fill a caller-supplied buffer and return a pointer into
; it. They are deliberately absent from TargetLibraryInfo::returnsPointerIntoArg,
; because the result need not come from that buffer at all: realpath(p, NULL)
; allocates, ctermid(NULL) answers from a static buffer. So the result cannot be
; said to alias the argument, and nothing on the aliasing side pays for them.
;
; Nothing on the escape side paid either. Both sat in doesArgEscape's "known not
; to escape" list, so
;
;   char b[PATH_MAX]; g = realpath(p, b); b[0] = 'x';
;
; left b local, elided the store, and lost the race against a thread writing
; through g -- shape 21's shape, for these two names, in the shipped default.
; doesArgEscape now answers true for realpath's second argument and ctermid's
; only one. That is the conservative side of the trade: the buffer escapes at
; the call whether or not the result is ever published, which is why
; @realpath_result_unpublished is instrumented below and is not a control for
; elision. The precise alternative -- admitting both to returnsPointerIntoArg
; under a non-null check on the buffer operand -- would keep that case local,
; and is not taken here because neither name occurs in the corpus, so the
; conservative form costs nothing measurable and asserts less.
;
; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@g = global ptr null, align 8

declare ptr @realpath(ptr noundef, ptr noundef)
declare ptr @ctermid(ptr noundef)
declare ptr @strchr(ptr noundef, i32 noundef)
declare void @sink(ptr noundef)

define void @realpath_published(ptr %path) nounwind uwtable sanitize_thread {
; CHECK-LABEL: @realpath_published
; CHECK: call void @__tsan_write1
entry:
  %buf = alloca [64 x i8], align 16
  %p = call ptr @realpath(ptr %path, ptr %buf)
  store ptr %p, ptr @g, align 8
  store i8 120, ptr %buf, align 16
  ret void
}

define void @ctermid_published() nounwind uwtable sanitize_thread {
; CHECK-LABEL: @ctermid_published
; CHECK: call void @__tsan_write1
entry:
  %buf = alloca [64 x i8], align 16
  %p = call ptr @ctermid(ptr %buf)
  store ptr %p, ptr @g, align 8
  store i8 121, ptr %buf, align 16
  ret void
}

; The conservative consequence, pinned rather than hidden: the buffer escapes at
; the call even though the result never leaves the function.
define void @realpath_result_unpublished(ptr %path) nounwind uwtable sanitize_thread {
; CHECK-LABEL: @realpath_result_unpublished
; CHECK: call void @__tsan_write1
entry:
  %buf = alloca [64 x i8], align 16
  %p = call ptr @realpath(ptr %path, ptr %buf)
  store i8 124, ptr %buf, align 16
  ret void
}

; Positive control one: a name already covered by returnsPointerIntoArg behaves
; the same way, so the two mechanisms agree on the published case.
define void @strchr_published() nounwind uwtable sanitize_thread {
; CHECK-LABEL: @strchr_published
; CHECK: call void @__tsan_write1
entry:
  %buf = alloca [64 x i8], align 16
  %p = call ptr @strchr(ptr %buf, i32 47)
  store ptr %p, ptr @g, align 8
  store i8 123, ptr %buf, align 16
  ret void
}

; Positive control two: the analysis can still elide here. Without this a fix
; that simply escaped every alloca would pass every check above.
define void @never_passed_anywhere() nounwind uwtable sanitize_thread {
; CHECK-LABEL: @never_passed_anywhere
; CHECK-NOT: call void @__tsan_write1
entry:
  %buf = alloca [64 x i8], align 16
  store i8 122, ptr %buf, align 16
  ret void
}

; Positive control three: realpath's *first* argument is still read-only, so a
; local passed there and not published stays local.
define void @realpath_first_arg_local() nounwind uwtable sanitize_thread {
; CHECK-LABEL: @realpath_first_arg_local
; CHECK-NOT: call void @__tsan_write1
entry:
  %path = alloca [64 x i8], align 16
  %out = alloca [64 x i8], align 16
  %p = call ptr @realpath(ptr %path, ptr %out)
  store i8 125, ptr %path, align 16
  ret void
}
