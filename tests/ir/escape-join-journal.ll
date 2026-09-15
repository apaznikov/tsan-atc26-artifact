; A loop around a 200-way switch whose join block has that many
; predecessors, all evaluated on one shared base: the shape of a generated
; parser, on which the escape analysis stores every block's out-state as a
; base shared by pointer plus the journal of the block's own transfer, and
; joins by merging each distinct base once and replaying the journals.
; -tsan-ea-verify-journal recomputes every block evaluation the old way (every
; predecessor's materialised state merged in turn, the transfer on a copy) and
; aborts if the shared-base join, the journal replayed on the base, the
; return-escape bit or the change verdict differ. The shapes that make the
; join more than a union of journals are all here:
;   - every case escapes a local of its own, so the first round's 200
;     journals are distinct and non-empty and the second round's are empty
;     (the join reads the switch block's out-state once, by pointer);
;   - case 1 escapes a field of %t and of %v, the latch then escapes %t as a
;     whole and both arms of the diamond %v: a journal that erases a base
;     entry, on a state with one successor, and an erasure every predecessor
;     of a join agrees on;
;   - cases 3 and 4 store %u into %slot (points-to pairs in journals) and
;     case 5 publishes %slot;
;   - the chain after the loop repeats the two erasure shapes on %w and %x
;     where no later round can bring the field entries back, so the final
;     states show them: 'after' holds %w as a whole and not its field, e3
;     holds %x as a whole and not its field.
; The printed states are pinned; they are the same as before the
; representation changed. %l is handed to a thread only after the loop, so
; its writes in the loop stay uninstrumented and the one after the thread
; creation does not.

; RUN: opt < %s -passes='print<escape-analysis-global>' -tsan-ea-verify-journal -disable-output 2>&1 | FileCheck %s
; RUN: opt < %s -passes='print<escape-analysis>' -tsan-ea-verify-journal -disable-output 2>&1 | FileCheck %s
; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -tsan-ea-verify-journal -tsan-ea-verify-skips -S | FileCheck %s --check-prefix=TSAN

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

%struct.S = type { i32, i32, i32 }

@gp = global ptr null, align 8
@out = global i32 0, align 4
declare void @take(ptr)
declare i32 @pthread_create(ptr, ptr, ptr, ptr)

define internal ptr @worker(ptr %a) sanitize_thread {
  store i32 -2, ptr %a, align 4
  ret ptr null
}

; CHECK-LABEL: Escaping objects for BB join:
; CHECK-DAG:     %s = alloca %struct.S, align 4{{$}}
; CHECK-DAG:     %u = alloca %struct.S, align 4 | Path: 1
; CHECK-DAG:     %slot = alloca ptr, align 8
; CHECK-DAG:     %c6 = alloca i32, align 4
; CHECK-DAG:     %c199 = alloca i32, align 4
; CHECK-LABEL: Escaping objects for BB done:
; CHECK-DAG:     %w = alloca %struct.S, align 4 | Path: 1
; CHECK-DAG:     %x = alloca %struct.S, align 4 | Path: 1
; CHECK-LABEL: Escaping objects for BB after:
; CHECK:         %w = alloca %struct.S, align 4{{$}}
; CHECK-NOT:     %w = alloca %struct.S, align 4 | Path
; CHECK-LABEL: Escaping objects for BB e3:
; CHECK:         %x = alloca %struct.S, align 4{{$}}
; CHECK-NOT:     %x = alloca %struct.S, align 4 | Path

; TSAN-LABEL: @parser
; TSAN-NOT:     call void @__tsan_write4(ptr %l)
; TSAN:         {{call|invoke}} i32 @pthread_create
; TSAN:         call void @__tsan_write4(ptr %l)
; TSAN:         ret void
define void @parser(i32 %n) sanitize_thread {
entry:
  %l = alloca i32, align 4
  %th = alloca i64, align 8
  %s = alloca %struct.S, align 4
  %t = alloca %struct.S, align 4
  %u = alloca %struct.S, align 4
  %v = alloca %struct.S, align 4
  %w = alloca %struct.S, align 4
  %x = alloca %struct.S, align 4
  %slot = alloca ptr, align 8
  %c6 = alloca i32, align 4
  %c7 = alloca i32, align 4
  %c8 = alloca i32, align 4
  %c9 = alloca i32, align 4
  %c10 = alloca i32, align 4
  %c11 = alloca i32, align 4
  %c12 = alloca i32, align 4
  %c13 = alloca i32, align 4
  %c14 = alloca i32, align 4
  %c15 = alloca i32, align 4
  %c16 = alloca i32, align 4
  %c17 = alloca i32, align 4
  %c18 = alloca i32, align 4
  %c19 = alloca i32, align 4
  %c20 = alloca i32, align 4
  %c21 = alloca i32, align 4
  %c22 = alloca i32, align 4
  %c23 = alloca i32, align 4
  %c24 = alloca i32, align 4
  %c25 = alloca i32, align 4
  %c26 = alloca i32, align 4
  %c27 = alloca i32, align 4
  %c28 = alloca i32, align 4
  %c29 = alloca i32, align 4
  %c30 = alloca i32, align 4
  %c31 = alloca i32, align 4
  %c32 = alloca i32, align 4
  %c33 = alloca i32, align 4
  %c34 = alloca i32, align 4
  %c35 = alloca i32, align 4
  %c36 = alloca i32, align 4
  %c37 = alloca i32, align 4
  %c38 = alloca i32, align 4
  %c39 = alloca i32, align 4
  %c40 = alloca i32, align 4
  %c41 = alloca i32, align 4
  %c42 = alloca i32, align 4
  %c43 = alloca i32, align 4
  %c44 = alloca i32, align 4
  %c45 = alloca i32, align 4
  %c46 = alloca i32, align 4
  %c47 = alloca i32, align 4
  %c48 = alloca i32, align 4
  %c49 = alloca i32, align 4
  %c50 = alloca i32, align 4
  %c51 = alloca i32, align 4
  %c52 = alloca i32, align 4
  %c53 = alloca i32, align 4
  %c54 = alloca i32, align 4
  %c55 = alloca i32, align 4
  %c56 = alloca i32, align 4
  %c57 = alloca i32, align 4
  %c58 = alloca i32, align 4
  %c59 = alloca i32, align 4
  %c60 = alloca i32, align 4
  %c61 = alloca i32, align 4
  %c62 = alloca i32, align 4
  %c63 = alloca i32, align 4
  %c64 = alloca i32, align 4
  %c65 = alloca i32, align 4
  %c66 = alloca i32, align 4
  %c67 = alloca i32, align 4
  %c68 = alloca i32, align 4
  %c69 = alloca i32, align 4
  %c70 = alloca i32, align 4
  %c71 = alloca i32, align 4
  %c72 = alloca i32, align 4
  %c73 = alloca i32, align 4
  %c74 = alloca i32, align 4
  %c75 = alloca i32, align 4
  %c76 = alloca i32, align 4
  %c77 = alloca i32, align 4
  %c78 = alloca i32, align 4
  %c79 = alloca i32, align 4
  %c80 = alloca i32, align 4
  %c81 = alloca i32, align 4
  %c82 = alloca i32, align 4
  %c83 = alloca i32, align 4
  %c84 = alloca i32, align 4
  %c85 = alloca i32, align 4
  %c86 = alloca i32, align 4
  %c87 = alloca i32, align 4
  %c88 = alloca i32, align 4
  %c89 = alloca i32, align 4
  %c90 = alloca i32, align 4
  %c91 = alloca i32, align 4
  %c92 = alloca i32, align 4
  %c93 = alloca i32, align 4
  %c94 = alloca i32, align 4
  %c95 = alloca i32, align 4
  %c96 = alloca i32, align 4
  %c97 = alloca i32, align 4
  %c98 = alloca i32, align 4
  %c99 = alloca i32, align 4
  %c100 = alloca i32, align 4
  %c101 = alloca i32, align 4
  %c102 = alloca i32, align 4
  %c103 = alloca i32, align 4
  %c104 = alloca i32, align 4
  %c105 = alloca i32, align 4
  %c106 = alloca i32, align 4
  %c107 = alloca i32, align 4
  %c108 = alloca i32, align 4
  %c109 = alloca i32, align 4
  %c110 = alloca i32, align 4
  %c111 = alloca i32, align 4
  %c112 = alloca i32, align 4
  %c113 = alloca i32, align 4
  %c114 = alloca i32, align 4
  %c115 = alloca i32, align 4
  %c116 = alloca i32, align 4
  %c117 = alloca i32, align 4
  %c118 = alloca i32, align 4
  %c119 = alloca i32, align 4
  %c120 = alloca i32, align 4
  %c121 = alloca i32, align 4
  %c122 = alloca i32, align 4
  %c123 = alloca i32, align 4
  %c124 = alloca i32, align 4
  %c125 = alloca i32, align 4
  %c126 = alloca i32, align 4
  %c127 = alloca i32, align 4
  %c128 = alloca i32, align 4
  %c129 = alloca i32, align 4
  %c130 = alloca i32, align 4
  %c131 = alloca i32, align 4
  %c132 = alloca i32, align 4
  %c133 = alloca i32, align 4
  %c134 = alloca i32, align 4
  %c135 = alloca i32, align 4
  %c136 = alloca i32, align 4
  %c137 = alloca i32, align 4
  %c138 = alloca i32, align 4
  %c139 = alloca i32, align 4
  %c140 = alloca i32, align 4
  %c141 = alloca i32, align 4
  %c142 = alloca i32, align 4
  %c143 = alloca i32, align 4
  %c144 = alloca i32, align 4
  %c145 = alloca i32, align 4
  %c146 = alloca i32, align 4
  %c147 = alloca i32, align 4
  %c148 = alloca i32, align 4
  %c149 = alloca i32, align 4
  %c150 = alloca i32, align 4
  %c151 = alloca i32, align 4
  %c152 = alloca i32, align 4
  %c153 = alloca i32, align 4
  %c154 = alloca i32, align 4
  %c155 = alloca i32, align 4
  %c156 = alloca i32, align 4
  %c157 = alloca i32, align 4
  %c158 = alloca i32, align 4
  %c159 = alloca i32, align 4
  %c160 = alloca i32, align 4
  %c161 = alloca i32, align 4
  %c162 = alloca i32, align 4
  %c163 = alloca i32, align 4
  %c164 = alloca i32, align 4
  %c165 = alloca i32, align 4
  %c166 = alloca i32, align 4
  %c167 = alloca i32, align 4
  %c168 = alloca i32, align 4
  %c169 = alloca i32, align 4
  %c170 = alloca i32, align 4
  %c171 = alloca i32, align 4
  %c172 = alloca i32, align 4
  %c173 = alloca i32, align 4
  %c174 = alloca i32, align 4
  %c175 = alloca i32, align 4
  %c176 = alloca i32, align 4
  %c177 = alloca i32, align 4
  %c178 = alloca i32, align 4
  %c179 = alloca i32, align 4
  %c180 = alloca i32, align 4
  %c181 = alloca i32, align 4
  %c182 = alloca i32, align 4
  %c183 = alloca i32, align 4
  %c184 = alloca i32, align 4
  %c185 = alloca i32, align 4
  %c186 = alloca i32, align 4
  %c187 = alloca i32, align 4
  %c188 = alloca i32, align 4
  %c189 = alloca i32, align 4
  %c190 = alloca i32, align 4
  %c191 = alloca i32, align 4
  %c192 = alloca i32, align 4
  %c193 = alloca i32, align 4
  %c194 = alloca i32, align 4
  %c195 = alloca i32, align 4
  %c196 = alloca i32, align 4
  %c197 = alloca i32, align 4
  %c198 = alloca i32, align 4
  %c199 = alloca i32, align 4
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %d3 ]
  %cont = icmp slt i32 %i, %n
  br i1 %cont, label %dispatch, label %done
dispatch:
  switch i32 %i, label %join [
    i32 0, label %case0
    i32 1, label %case1
    i32 2, label %case2
    i32 3, label %case3
    i32 4, label %case4
    i32 5, label %case5
    i32 6, label %case6
    i32 7, label %case7
    i32 8, label %case8
    i32 9, label %case9
    i32 10, label %case10
    i32 11, label %case11
    i32 12, label %case12
    i32 13, label %case13
    i32 14, label %case14
    i32 15, label %case15
    i32 16, label %case16
    i32 17, label %case17
    i32 18, label %case18
    i32 19, label %case19
    i32 20, label %case20
    i32 21, label %case21
    i32 22, label %case22
    i32 23, label %case23
    i32 24, label %case24
    i32 25, label %case25
    i32 26, label %case26
    i32 27, label %case27
    i32 28, label %case28
    i32 29, label %case29
    i32 30, label %case30
    i32 31, label %case31
    i32 32, label %case32
    i32 33, label %case33
    i32 34, label %case34
    i32 35, label %case35
    i32 36, label %case36
    i32 37, label %case37
    i32 38, label %case38
    i32 39, label %case39
    i32 40, label %case40
    i32 41, label %case41
    i32 42, label %case42
    i32 43, label %case43
    i32 44, label %case44
    i32 45, label %case45
    i32 46, label %case46
    i32 47, label %case47
    i32 48, label %case48
    i32 49, label %case49
    i32 50, label %case50
    i32 51, label %case51
    i32 52, label %case52
    i32 53, label %case53
    i32 54, label %case54
    i32 55, label %case55
    i32 56, label %case56
    i32 57, label %case57
    i32 58, label %case58
    i32 59, label %case59
    i32 60, label %case60
    i32 61, label %case61
    i32 62, label %case62
    i32 63, label %case63
    i32 64, label %case64
    i32 65, label %case65
    i32 66, label %case66
    i32 67, label %case67
    i32 68, label %case68
    i32 69, label %case69
    i32 70, label %case70
    i32 71, label %case71
    i32 72, label %case72
    i32 73, label %case73
    i32 74, label %case74
    i32 75, label %case75
    i32 76, label %case76
    i32 77, label %case77
    i32 78, label %case78
    i32 79, label %case79
    i32 80, label %case80
    i32 81, label %case81
    i32 82, label %case82
    i32 83, label %case83
    i32 84, label %case84
    i32 85, label %case85
    i32 86, label %case86
    i32 87, label %case87
    i32 88, label %case88
    i32 89, label %case89
    i32 90, label %case90
    i32 91, label %case91
    i32 92, label %case92
    i32 93, label %case93
    i32 94, label %case94
    i32 95, label %case95
    i32 96, label %case96
    i32 97, label %case97
    i32 98, label %case98
    i32 99, label %case99
    i32 100, label %case100
    i32 101, label %case101
    i32 102, label %case102
    i32 103, label %case103
    i32 104, label %case104
    i32 105, label %case105
    i32 106, label %case106
    i32 107, label %case107
    i32 108, label %case108
    i32 109, label %case109
    i32 110, label %case110
    i32 111, label %case111
    i32 112, label %case112
    i32 113, label %case113
    i32 114, label %case114
    i32 115, label %case115
    i32 116, label %case116
    i32 117, label %case117
    i32 118, label %case118
    i32 119, label %case119
    i32 120, label %case120
    i32 121, label %case121
    i32 122, label %case122
    i32 123, label %case123
    i32 124, label %case124
    i32 125, label %case125
    i32 126, label %case126
    i32 127, label %case127
    i32 128, label %case128
    i32 129, label %case129
    i32 130, label %case130
    i32 131, label %case131
    i32 132, label %case132
    i32 133, label %case133
    i32 134, label %case134
    i32 135, label %case135
    i32 136, label %case136
    i32 137, label %case137
    i32 138, label %case138
    i32 139, label %case139
    i32 140, label %case140
    i32 141, label %case141
    i32 142, label %case142
    i32 143, label %case143
    i32 144, label %case144
    i32 145, label %case145
    i32 146, label %case146
    i32 147, label %case147
    i32 148, label %case148
    i32 149, label %case149
    i32 150, label %case150
    i32 151, label %case151
    i32 152, label %case152
    i32 153, label %case153
    i32 154, label %case154
    i32 155, label %case155
    i32 156, label %case156
    i32 157, label %case157
    i32 158, label %case158
    i32 159, label %case159
    i32 160, label %case160
    i32 161, label %case161
    i32 162, label %case162
    i32 163, label %case163
    i32 164, label %case164
    i32 165, label %case165
    i32 166, label %case166
    i32 167, label %case167
    i32 168, label %case168
    i32 169, label %case169
    i32 170, label %case170
    i32 171, label %case171
    i32 172, label %case172
    i32 173, label %case173
    i32 174, label %case174
    i32 175, label %case175
    i32 176, label %case176
    i32 177, label %case177
    i32 178, label %case178
    i32 179, label %case179
    i32 180, label %case180
    i32 181, label %case181
    i32 182, label %case182
    i32 183, label %case183
    i32 184, label %case184
    i32 185, label %case185
    i32 186, label %case186
    i32 187, label %case187
    i32 188, label %case188
    i32 189, label %case189
    i32 190, label %case190
    i32 191, label %case191
    i32 192, label %case192
    i32 193, label %case193
    i32 194, label %case194
    i32 195, label %case195
    i32 196, label %case196
    i32 197, label %case197
    i32 198, label %case198
    i32 199, label %case199
  ]
case0:
  call void @take(ptr %s)
  br label %join
case1:
  %t1 = getelementptr inbounds %struct.S, ptr %t, i32 0, i32 1
  store ptr %t1, ptr @gp, align 8
  %v1 = getelementptr inbounds %struct.S, ptr %v, i32 0, i32 1
  store ptr %v1, ptr @gp, align 8
  br label %join
case2:
  %u1 = getelementptr inbounds %struct.S, ptr %u, i32 0, i32 1
  store ptr %u1, ptr @gp, align 8
  br label %join
case3:
  store ptr %u, ptr %slot, align 8
  br label %join
case4:
  store ptr %u, ptr %slot, align 8
  store i32 4, ptr %l, align 4
  br label %join
case5:
  store ptr %slot, ptr @gp, align 8
  br label %join
case6:
  store ptr %c6, ptr @gp, align 8
  store i32 6, ptr %l, align 4
  br label %join
case7:
  store ptr %c7, ptr @gp, align 8
  store i32 7, ptr %l, align 4
  br label %join
case8:
  store ptr %c8, ptr @gp, align 8
  store i32 8, ptr %l, align 4
  br label %join
case9:
  store ptr %c9, ptr @gp, align 8
  store i32 9, ptr %l, align 4
  br label %join
case10:
  store ptr %c10, ptr @gp, align 8
  store i32 10, ptr %l, align 4
  br label %join
case11:
  store ptr %c11, ptr @gp, align 8
  store i32 11, ptr %l, align 4
  br label %join
case12:
  store ptr %c12, ptr @gp, align 8
  store i32 12, ptr %l, align 4
  br label %join
case13:
  store ptr %c13, ptr @gp, align 8
  store i32 13, ptr %l, align 4
  br label %join
case14:
  store ptr %c14, ptr @gp, align 8
  store i32 14, ptr %l, align 4
  br label %join
case15:
  store ptr %c15, ptr @gp, align 8
  store i32 15, ptr %l, align 4
  br label %join
case16:
  store ptr %c16, ptr @gp, align 8
  store i32 16, ptr %l, align 4
  br label %join
case17:
  store ptr %c17, ptr @gp, align 8
  store i32 17, ptr %l, align 4
  br label %join
case18:
  store ptr %c18, ptr @gp, align 8
  store i32 18, ptr %l, align 4
  br label %join
case19:
  store ptr %c19, ptr @gp, align 8
  store i32 19, ptr %l, align 4
  br label %join
case20:
  store ptr %c20, ptr @gp, align 8
  store i32 20, ptr %l, align 4
  br label %join
case21:
  store ptr %c21, ptr @gp, align 8
  store i32 21, ptr %l, align 4
  br label %join
case22:
  store ptr %c22, ptr @gp, align 8
  store i32 22, ptr %l, align 4
  br label %join
case23:
  store ptr %c23, ptr @gp, align 8
  store i32 23, ptr %l, align 4
  br label %join
case24:
  store ptr %c24, ptr @gp, align 8
  store i32 24, ptr %l, align 4
  br label %join
case25:
  store ptr %c25, ptr @gp, align 8
  store i32 25, ptr %l, align 4
  br label %join
case26:
  store ptr %c26, ptr @gp, align 8
  store i32 26, ptr %l, align 4
  br label %join
case27:
  store ptr %c27, ptr @gp, align 8
  store i32 27, ptr %l, align 4
  br label %join
case28:
  store ptr %c28, ptr @gp, align 8
  store i32 28, ptr %l, align 4
  br label %join
case29:
  store ptr %c29, ptr @gp, align 8
  store i32 29, ptr %l, align 4
  br label %join
case30:
  store ptr %c30, ptr @gp, align 8
  store i32 30, ptr %l, align 4
  br label %join
case31:
  store ptr %c31, ptr @gp, align 8
  store i32 31, ptr %l, align 4
  br label %join
case32:
  store ptr %c32, ptr @gp, align 8
  store i32 32, ptr %l, align 4
  br label %join
case33:
  store ptr %c33, ptr @gp, align 8
  store i32 33, ptr %l, align 4
  br label %join
case34:
  store ptr %c34, ptr @gp, align 8
  store i32 34, ptr %l, align 4
  br label %join
case35:
  store ptr %c35, ptr @gp, align 8
  store i32 35, ptr %l, align 4
  br label %join
case36:
  store ptr %c36, ptr @gp, align 8
  store i32 36, ptr %l, align 4
  br label %join
case37:
  store ptr %c37, ptr @gp, align 8
  store i32 37, ptr %l, align 4
  br label %join
case38:
  store ptr %c38, ptr @gp, align 8
  store i32 38, ptr %l, align 4
  br label %join
case39:
  store ptr %c39, ptr @gp, align 8
  store i32 39, ptr %l, align 4
  br label %join
case40:
  store ptr %c40, ptr @gp, align 8
  store i32 40, ptr %l, align 4
  br label %join
case41:
  store ptr %c41, ptr @gp, align 8
  store i32 41, ptr %l, align 4
  br label %join
case42:
  store ptr %c42, ptr @gp, align 8
  store i32 42, ptr %l, align 4
  br label %join
case43:
  store ptr %c43, ptr @gp, align 8
  store i32 43, ptr %l, align 4
  br label %join
case44:
  store ptr %c44, ptr @gp, align 8
  store i32 44, ptr %l, align 4
  br label %join
case45:
  store ptr %c45, ptr @gp, align 8
  store i32 45, ptr %l, align 4
  br label %join
case46:
  store ptr %c46, ptr @gp, align 8
  store i32 46, ptr %l, align 4
  br label %join
case47:
  store ptr %c47, ptr @gp, align 8
  store i32 47, ptr %l, align 4
  br label %join
case48:
  store ptr %c48, ptr @gp, align 8
  store i32 48, ptr %l, align 4
  br label %join
case49:
  store ptr %c49, ptr @gp, align 8
  store i32 49, ptr %l, align 4
  br label %join
case50:
  store ptr %c50, ptr @gp, align 8
  store i32 50, ptr %l, align 4
  br label %join
case51:
  store ptr %c51, ptr @gp, align 8
  store i32 51, ptr %l, align 4
  br label %join
case52:
  store ptr %c52, ptr @gp, align 8
  store i32 52, ptr %l, align 4
  br label %join
case53:
  store ptr %c53, ptr @gp, align 8
  store i32 53, ptr %l, align 4
  br label %join
case54:
  store ptr %c54, ptr @gp, align 8
  store i32 54, ptr %l, align 4
  br label %join
case55:
  store ptr %c55, ptr @gp, align 8
  store i32 55, ptr %l, align 4
  br label %join
case56:
  store ptr %c56, ptr @gp, align 8
  store i32 56, ptr %l, align 4
  br label %join
case57:
  store ptr %c57, ptr @gp, align 8
  store i32 57, ptr %l, align 4
  br label %join
case58:
  store ptr %c58, ptr @gp, align 8
  store i32 58, ptr %l, align 4
  br label %join
case59:
  store ptr %c59, ptr @gp, align 8
  store i32 59, ptr %l, align 4
  br label %join
case60:
  store ptr %c60, ptr @gp, align 8
  store i32 60, ptr %l, align 4
  br label %join
case61:
  store ptr %c61, ptr @gp, align 8
  store i32 61, ptr %l, align 4
  br label %join
case62:
  store ptr %c62, ptr @gp, align 8
  store i32 62, ptr %l, align 4
  br label %join
case63:
  store ptr %c63, ptr @gp, align 8
  store i32 63, ptr %l, align 4
  br label %join
case64:
  store ptr %c64, ptr @gp, align 8
  store i32 64, ptr %l, align 4
  br label %join
case65:
  store ptr %c65, ptr @gp, align 8
  store i32 65, ptr %l, align 4
  br label %join
case66:
  store ptr %c66, ptr @gp, align 8
  store i32 66, ptr %l, align 4
  br label %join
case67:
  store ptr %c67, ptr @gp, align 8
  store i32 67, ptr %l, align 4
  br label %join
case68:
  store ptr %c68, ptr @gp, align 8
  store i32 68, ptr %l, align 4
  br label %join
case69:
  store ptr %c69, ptr @gp, align 8
  store i32 69, ptr %l, align 4
  br label %join
case70:
  store ptr %c70, ptr @gp, align 8
  store i32 70, ptr %l, align 4
  br label %join
case71:
  store ptr %c71, ptr @gp, align 8
  store i32 71, ptr %l, align 4
  br label %join
case72:
  store ptr %c72, ptr @gp, align 8
  store i32 72, ptr %l, align 4
  br label %join
case73:
  store ptr %c73, ptr @gp, align 8
  store i32 73, ptr %l, align 4
  br label %join
case74:
  store ptr %c74, ptr @gp, align 8
  store i32 74, ptr %l, align 4
  br label %join
case75:
  store ptr %c75, ptr @gp, align 8
  store i32 75, ptr %l, align 4
  br label %join
case76:
  store ptr %c76, ptr @gp, align 8
  store i32 76, ptr %l, align 4
  br label %join
case77:
  store ptr %c77, ptr @gp, align 8
  store i32 77, ptr %l, align 4
  br label %join
case78:
  store ptr %c78, ptr @gp, align 8
  store i32 78, ptr %l, align 4
  br label %join
case79:
  store ptr %c79, ptr @gp, align 8
  store i32 79, ptr %l, align 4
  br label %join
case80:
  store ptr %c80, ptr @gp, align 8
  store i32 80, ptr %l, align 4
  br label %join
case81:
  store ptr %c81, ptr @gp, align 8
  store i32 81, ptr %l, align 4
  br label %join
case82:
  store ptr %c82, ptr @gp, align 8
  store i32 82, ptr %l, align 4
  br label %join
case83:
  store ptr %c83, ptr @gp, align 8
  store i32 83, ptr %l, align 4
  br label %join
case84:
  store ptr %c84, ptr @gp, align 8
  store i32 84, ptr %l, align 4
  br label %join
case85:
  store ptr %c85, ptr @gp, align 8
  store i32 85, ptr %l, align 4
  br label %join
case86:
  store ptr %c86, ptr @gp, align 8
  store i32 86, ptr %l, align 4
  br label %join
case87:
  store ptr %c87, ptr @gp, align 8
  store i32 87, ptr %l, align 4
  br label %join
case88:
  store ptr %c88, ptr @gp, align 8
  store i32 88, ptr %l, align 4
  br label %join
case89:
  store ptr %c89, ptr @gp, align 8
  store i32 89, ptr %l, align 4
  br label %join
case90:
  store ptr %c90, ptr @gp, align 8
  store i32 90, ptr %l, align 4
  br label %join
case91:
  store ptr %c91, ptr @gp, align 8
  store i32 91, ptr %l, align 4
  br label %join
case92:
  store ptr %c92, ptr @gp, align 8
  store i32 92, ptr %l, align 4
  br label %join
case93:
  store ptr %c93, ptr @gp, align 8
  store i32 93, ptr %l, align 4
  br label %join
case94:
  store ptr %c94, ptr @gp, align 8
  store i32 94, ptr %l, align 4
  br label %join
case95:
  store ptr %c95, ptr @gp, align 8
  store i32 95, ptr %l, align 4
  br label %join
case96:
  store ptr %c96, ptr @gp, align 8
  store i32 96, ptr %l, align 4
  br label %join
case97:
  store ptr %c97, ptr @gp, align 8
  store i32 97, ptr %l, align 4
  br label %join
case98:
  store ptr %c98, ptr @gp, align 8
  store i32 98, ptr %l, align 4
  br label %join
case99:
  store ptr %c99, ptr @gp, align 8
  store i32 99, ptr %l, align 4
  br label %join
case100:
  store ptr %c100, ptr @gp, align 8
  store i32 100, ptr %l, align 4
  br label %join
case101:
  store ptr %c101, ptr @gp, align 8
  store i32 101, ptr %l, align 4
  br label %join
case102:
  store ptr %c102, ptr @gp, align 8
  store i32 102, ptr %l, align 4
  br label %join
case103:
  store ptr %c103, ptr @gp, align 8
  store i32 103, ptr %l, align 4
  br label %join
case104:
  store ptr %c104, ptr @gp, align 8
  store i32 104, ptr %l, align 4
  br label %join
case105:
  store ptr %c105, ptr @gp, align 8
  store i32 105, ptr %l, align 4
  br label %join
case106:
  store ptr %c106, ptr @gp, align 8
  store i32 106, ptr %l, align 4
  br label %join
case107:
  store ptr %c107, ptr @gp, align 8
  store i32 107, ptr %l, align 4
  br label %join
case108:
  store ptr %c108, ptr @gp, align 8
  store i32 108, ptr %l, align 4
  br label %join
case109:
  store ptr %c109, ptr @gp, align 8
  store i32 109, ptr %l, align 4
  br label %join
case110:
  store ptr %c110, ptr @gp, align 8
  store i32 110, ptr %l, align 4
  br label %join
case111:
  store ptr %c111, ptr @gp, align 8
  store i32 111, ptr %l, align 4
  br label %join
case112:
  store ptr %c112, ptr @gp, align 8
  store i32 112, ptr %l, align 4
  br label %join
case113:
  store ptr %c113, ptr @gp, align 8
  store i32 113, ptr %l, align 4
  br label %join
case114:
  store ptr %c114, ptr @gp, align 8
  store i32 114, ptr %l, align 4
  br label %join
case115:
  store ptr %c115, ptr @gp, align 8
  store i32 115, ptr %l, align 4
  br label %join
case116:
  store ptr %c116, ptr @gp, align 8
  store i32 116, ptr %l, align 4
  br label %join
case117:
  store ptr %c117, ptr @gp, align 8
  store i32 117, ptr %l, align 4
  br label %join
case118:
  store ptr %c118, ptr @gp, align 8
  store i32 118, ptr %l, align 4
  br label %join
case119:
  store ptr %c119, ptr @gp, align 8
  store i32 119, ptr %l, align 4
  br label %join
case120:
  store ptr %c120, ptr @gp, align 8
  store i32 120, ptr %l, align 4
  br label %join
case121:
  store ptr %c121, ptr @gp, align 8
  store i32 121, ptr %l, align 4
  br label %join
case122:
  store ptr %c122, ptr @gp, align 8
  store i32 122, ptr %l, align 4
  br label %join
case123:
  store ptr %c123, ptr @gp, align 8
  store i32 123, ptr %l, align 4
  br label %join
case124:
  store ptr %c124, ptr @gp, align 8
  store i32 124, ptr %l, align 4
  br label %join
case125:
  store ptr %c125, ptr @gp, align 8
  store i32 125, ptr %l, align 4
  br label %join
case126:
  store ptr %c126, ptr @gp, align 8
  store i32 126, ptr %l, align 4
  br label %join
case127:
  store ptr %c127, ptr @gp, align 8
  store i32 127, ptr %l, align 4
  br label %join
case128:
  store ptr %c128, ptr @gp, align 8
  store i32 128, ptr %l, align 4
  br label %join
case129:
  store ptr %c129, ptr @gp, align 8
  store i32 129, ptr %l, align 4
  br label %join
case130:
  store ptr %c130, ptr @gp, align 8
  store i32 130, ptr %l, align 4
  br label %join
case131:
  store ptr %c131, ptr @gp, align 8
  store i32 131, ptr %l, align 4
  br label %join
case132:
  store ptr %c132, ptr @gp, align 8
  store i32 132, ptr %l, align 4
  br label %join
case133:
  store ptr %c133, ptr @gp, align 8
  store i32 133, ptr %l, align 4
  br label %join
case134:
  store ptr %c134, ptr @gp, align 8
  store i32 134, ptr %l, align 4
  br label %join
case135:
  store ptr %c135, ptr @gp, align 8
  store i32 135, ptr %l, align 4
  br label %join
case136:
  store ptr %c136, ptr @gp, align 8
  store i32 136, ptr %l, align 4
  br label %join
case137:
  store ptr %c137, ptr @gp, align 8
  store i32 137, ptr %l, align 4
  br label %join
case138:
  store ptr %c138, ptr @gp, align 8
  store i32 138, ptr %l, align 4
  br label %join
case139:
  store ptr %c139, ptr @gp, align 8
  store i32 139, ptr %l, align 4
  br label %join
case140:
  store ptr %c140, ptr @gp, align 8
  store i32 140, ptr %l, align 4
  br label %join
case141:
  store ptr %c141, ptr @gp, align 8
  store i32 141, ptr %l, align 4
  br label %join
case142:
  store ptr %c142, ptr @gp, align 8
  store i32 142, ptr %l, align 4
  br label %join
case143:
  store ptr %c143, ptr @gp, align 8
  store i32 143, ptr %l, align 4
  br label %join
case144:
  store ptr %c144, ptr @gp, align 8
  store i32 144, ptr %l, align 4
  br label %join
case145:
  store ptr %c145, ptr @gp, align 8
  store i32 145, ptr %l, align 4
  br label %join
case146:
  store ptr %c146, ptr @gp, align 8
  store i32 146, ptr %l, align 4
  br label %join
case147:
  store ptr %c147, ptr @gp, align 8
  store i32 147, ptr %l, align 4
  br label %join
case148:
  store ptr %c148, ptr @gp, align 8
  store i32 148, ptr %l, align 4
  br label %join
case149:
  store ptr %c149, ptr @gp, align 8
  store i32 149, ptr %l, align 4
  br label %join
case150:
  store ptr %c150, ptr @gp, align 8
  store i32 150, ptr %l, align 4
  br label %join
case151:
  store ptr %c151, ptr @gp, align 8
  store i32 151, ptr %l, align 4
  br label %join
case152:
  store ptr %c152, ptr @gp, align 8
  store i32 152, ptr %l, align 4
  br label %join
case153:
  store ptr %c153, ptr @gp, align 8
  store i32 153, ptr %l, align 4
  br label %join
case154:
  store ptr %c154, ptr @gp, align 8
  store i32 154, ptr %l, align 4
  br label %join
case155:
  store ptr %c155, ptr @gp, align 8
  store i32 155, ptr %l, align 4
  br label %join
case156:
  store ptr %c156, ptr @gp, align 8
  store i32 156, ptr %l, align 4
  br label %join
case157:
  store ptr %c157, ptr @gp, align 8
  store i32 157, ptr %l, align 4
  br label %join
case158:
  store ptr %c158, ptr @gp, align 8
  store i32 158, ptr %l, align 4
  br label %join
case159:
  store ptr %c159, ptr @gp, align 8
  store i32 159, ptr %l, align 4
  br label %join
case160:
  store ptr %c160, ptr @gp, align 8
  store i32 160, ptr %l, align 4
  br label %join
case161:
  store ptr %c161, ptr @gp, align 8
  store i32 161, ptr %l, align 4
  br label %join
case162:
  store ptr %c162, ptr @gp, align 8
  store i32 162, ptr %l, align 4
  br label %join
case163:
  store ptr %c163, ptr @gp, align 8
  store i32 163, ptr %l, align 4
  br label %join
case164:
  store ptr %c164, ptr @gp, align 8
  store i32 164, ptr %l, align 4
  br label %join
case165:
  store ptr %c165, ptr @gp, align 8
  store i32 165, ptr %l, align 4
  br label %join
case166:
  store ptr %c166, ptr @gp, align 8
  store i32 166, ptr %l, align 4
  br label %join
case167:
  store ptr %c167, ptr @gp, align 8
  store i32 167, ptr %l, align 4
  br label %join
case168:
  store ptr %c168, ptr @gp, align 8
  store i32 168, ptr %l, align 4
  br label %join
case169:
  store ptr %c169, ptr @gp, align 8
  store i32 169, ptr %l, align 4
  br label %join
case170:
  store ptr %c170, ptr @gp, align 8
  store i32 170, ptr %l, align 4
  br label %join
case171:
  store ptr %c171, ptr @gp, align 8
  store i32 171, ptr %l, align 4
  br label %join
case172:
  store ptr %c172, ptr @gp, align 8
  store i32 172, ptr %l, align 4
  br label %join
case173:
  store ptr %c173, ptr @gp, align 8
  store i32 173, ptr %l, align 4
  br label %join
case174:
  store ptr %c174, ptr @gp, align 8
  store i32 174, ptr %l, align 4
  br label %join
case175:
  store ptr %c175, ptr @gp, align 8
  store i32 175, ptr %l, align 4
  br label %join
case176:
  store ptr %c176, ptr @gp, align 8
  store i32 176, ptr %l, align 4
  br label %join
case177:
  store ptr %c177, ptr @gp, align 8
  store i32 177, ptr %l, align 4
  br label %join
case178:
  store ptr %c178, ptr @gp, align 8
  store i32 178, ptr %l, align 4
  br label %join
case179:
  store ptr %c179, ptr @gp, align 8
  store i32 179, ptr %l, align 4
  br label %join
case180:
  store ptr %c180, ptr @gp, align 8
  store i32 180, ptr %l, align 4
  br label %join
case181:
  store ptr %c181, ptr @gp, align 8
  store i32 181, ptr %l, align 4
  br label %join
case182:
  store ptr %c182, ptr @gp, align 8
  store i32 182, ptr %l, align 4
  br label %join
case183:
  store ptr %c183, ptr @gp, align 8
  store i32 183, ptr %l, align 4
  br label %join
case184:
  store ptr %c184, ptr @gp, align 8
  store i32 184, ptr %l, align 4
  br label %join
case185:
  store ptr %c185, ptr @gp, align 8
  store i32 185, ptr %l, align 4
  br label %join
case186:
  store ptr %c186, ptr @gp, align 8
  store i32 186, ptr %l, align 4
  br label %join
case187:
  store ptr %c187, ptr @gp, align 8
  store i32 187, ptr %l, align 4
  br label %join
case188:
  store ptr %c188, ptr @gp, align 8
  store i32 188, ptr %l, align 4
  br label %join
case189:
  store ptr %c189, ptr @gp, align 8
  store i32 189, ptr %l, align 4
  br label %join
case190:
  store ptr %c190, ptr @gp, align 8
  store i32 190, ptr %l, align 4
  br label %join
case191:
  store ptr %c191, ptr @gp, align 8
  store i32 191, ptr %l, align 4
  br label %join
case192:
  store ptr %c192, ptr @gp, align 8
  store i32 192, ptr %l, align 4
  br label %join
case193:
  store ptr %c193, ptr @gp, align 8
  store i32 193, ptr %l, align 4
  br label %join
case194:
  store ptr %c194, ptr @gp, align 8
  store i32 194, ptr %l, align 4
  br label %join
case195:
  store ptr %c195, ptr @gp, align 8
  store i32 195, ptr %l, align 4
  br label %join
case196:
  store ptr %c196, ptr @gp, align 8
  store i32 196, ptr %l, align 4
  br label %join
case197:
  store ptr %c197, ptr @gp, align 8
  store i32 197, ptr %l, align 4
  br label %join
case198:
  store ptr %c198, ptr @gp, align 8
  store i32 198, ptr %l, align 4
  br label %join
case199:
  store ptr %c199, ptr @gp, align 8
  store i32 199, ptr %l, align 4
  br label %join
join:
  store i32 0, ptr %l, align 4
  br label %latch
latch:
  call void @take(ptr %t)
  %odd = and i32 %i, 1
  %p = icmp eq i32 %odd, 0
  br i1 %p, label %d1, label %d2
d1:
  call void @take(ptr %v)
  br label %d3
d2:
  call void @take(ptr %v)
  br label %d3
d3:
  %next = add i32 %i, 1
  br label %loop
done:
  %w1 = getelementptr inbounds %struct.S, ptr %w, i32 0, i32 1
  store ptr %w1, ptr @gp, align 8
  %x1 = getelementptr inbounds %struct.S, ptr %x, i32 0, i32 1
  store ptr %x1, ptr @gp, align 8
  br label %after
after:
  call void @take(ptr %w)
  %q = icmp sgt i32 %n, 3
  br i1 %q, label %e1, label %e2
e1:
  call void @take(ptr %x)
  br label %e3
e2:
  call void @take(ptr %x)
  br label %e3
e3:
  %c = call i32 @pthread_create(ptr %th, ptr null, ptr @worker, ptr %l)
  store i32 -1, ptr %l, align 4
  ret void
}
