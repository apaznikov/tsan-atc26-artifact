; A loop around a 300-way switch: the shape of a generated parser, whose join
; block has as many predecessors as the switch has cases. The escape
; analysis's worklist must evaluate that join block once per round, not once
; per changed predecessor; before this it did the latter, re-merging every
; predecessor's state each time, and a 2 000-case parser took three hours.
; The budget -tsan-ea-max-evals-per-block=6 makes a regression visible without
; a wall-clock test: a quadratic worklist exceeds six evaluations per block,
; the analysis gives up, and the local that is handed to a thread only after
; the loop would stay instrumented everywhere instead of being elided in
; every case before that release-like publication (a plain store of the
; pointer to a global would not do: the sound flow-sensitive rule keeps
; accesses before a publication that is not release-like; and no other call
; may take the local, since reachability from a case to it is answered
; conservatively past 32 blocks). The thread creation is also what makes
; stock's capture rule keep the accesses, so the verdict is the analysis's.

; RUN: opt < %s -passes='module(tsan-module),function(tsan)' -tsan-use-escape-analysis-global -tsan-ea-max-evals-per-block=6 -tsan-ea-report-abandoned -S 2>&1 | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@out = global i32 0, align 4
declare i32 @pthread_create(ptr, ptr, ptr, ptr)

define internal ptr @worker(ptr %a) sanitize_thread {
  store i32 -2, ptr %a, align 4
  ret ptr null
}

; CHECK-NOT: escape analysis gave up
; CHECK-LABEL: @parser
; CHECK-NOT:   call void @__tsan_write4(ptr %l)
; CHECK:       {{call|invoke}} i32 @pthread_create
; CHECK:       call void @__tsan_write4(ptr %l)
; CHECK:       ret void
define void @parser(i32 %n) sanitize_thread {
entry:
  %l = alloca i32, align 4
  %t = alloca i64, align 8
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %join ]
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
    i32 200, label %case200
    i32 201, label %case201
    i32 202, label %case202
    i32 203, label %case203
    i32 204, label %case204
    i32 205, label %case205
    i32 206, label %case206
    i32 207, label %case207
    i32 208, label %case208
    i32 209, label %case209
    i32 210, label %case210
    i32 211, label %case211
    i32 212, label %case212
    i32 213, label %case213
    i32 214, label %case214
    i32 215, label %case215
    i32 216, label %case216
    i32 217, label %case217
    i32 218, label %case218
    i32 219, label %case219
    i32 220, label %case220
    i32 221, label %case221
    i32 222, label %case222
    i32 223, label %case223
    i32 224, label %case224
    i32 225, label %case225
    i32 226, label %case226
    i32 227, label %case227
    i32 228, label %case228
    i32 229, label %case229
    i32 230, label %case230
    i32 231, label %case231
    i32 232, label %case232
    i32 233, label %case233
    i32 234, label %case234
    i32 235, label %case235
    i32 236, label %case236
    i32 237, label %case237
    i32 238, label %case238
    i32 239, label %case239
    i32 240, label %case240
    i32 241, label %case241
    i32 242, label %case242
    i32 243, label %case243
    i32 244, label %case244
    i32 245, label %case245
    i32 246, label %case246
    i32 247, label %case247
    i32 248, label %case248
    i32 249, label %case249
    i32 250, label %case250
    i32 251, label %case251
    i32 252, label %case252
    i32 253, label %case253
    i32 254, label %case254
    i32 255, label %case255
    i32 256, label %case256
    i32 257, label %case257
    i32 258, label %case258
    i32 259, label %case259
    i32 260, label %case260
    i32 261, label %case261
    i32 262, label %case262
    i32 263, label %case263
    i32 264, label %case264
    i32 265, label %case265
    i32 266, label %case266
    i32 267, label %case267
    i32 268, label %case268
    i32 269, label %case269
    i32 270, label %case270
    i32 271, label %case271
    i32 272, label %case272
    i32 273, label %case273
    i32 274, label %case274
    i32 275, label %case275
    i32 276, label %case276
    i32 277, label %case277
    i32 278, label %case278
    i32 279, label %case279
    i32 280, label %case280
    i32 281, label %case281
    i32 282, label %case282
    i32 283, label %case283
    i32 284, label %case284
    i32 285, label %case285
    i32 286, label %case286
    i32 287, label %case287
    i32 288, label %case288
    i32 289, label %case289
    i32 290, label %case290
    i32 291, label %case291
    i32 292, label %case292
    i32 293, label %case293
    i32 294, label %case294
    i32 295, label %case295
    i32 296, label %case296
    i32 297, label %case297
    i32 298, label %case298
    i32 299, label %case299
  ]
case0:
  store i32 0, ptr %l, align 4
  store i32 0, ptr @out, align 4
  br label %join
case1:
  store i32 1, ptr %l, align 4
  store i32 1, ptr @out, align 4
  br label %join
case2:
  store i32 2, ptr %l, align 4
  store i32 2, ptr @out, align 4
  br label %join
case3:
  store i32 3, ptr %l, align 4
  store i32 3, ptr @out, align 4
  br label %join
case4:
  store i32 4, ptr %l, align 4
  store i32 4, ptr @out, align 4
  br label %join
case5:
  store i32 5, ptr %l, align 4
  store i32 5, ptr @out, align 4
  br label %join
case6:
  store i32 6, ptr %l, align 4
  store i32 6, ptr @out, align 4
  br label %join
case7:
  store i32 7, ptr %l, align 4
  store i32 7, ptr @out, align 4
  br label %join
case8:
  store i32 8, ptr %l, align 4
  store i32 8, ptr @out, align 4
  br label %join
case9:
  store i32 9, ptr %l, align 4
  store i32 9, ptr @out, align 4
  br label %join
case10:
  store i32 10, ptr %l, align 4
  store i32 10, ptr @out, align 4
  br label %join
case11:
  store i32 11, ptr %l, align 4
  store i32 11, ptr @out, align 4
  br label %join
case12:
  store i32 12, ptr %l, align 4
  store i32 12, ptr @out, align 4
  br label %join
case13:
  store i32 13, ptr %l, align 4
  store i32 13, ptr @out, align 4
  br label %join
case14:
  store i32 14, ptr %l, align 4
  store i32 14, ptr @out, align 4
  br label %join
case15:
  store i32 15, ptr %l, align 4
  store i32 15, ptr @out, align 4
  br label %join
case16:
  store i32 16, ptr %l, align 4
  store i32 16, ptr @out, align 4
  br label %join
case17:
  store i32 17, ptr %l, align 4
  store i32 17, ptr @out, align 4
  br label %join
case18:
  store i32 18, ptr %l, align 4
  store i32 18, ptr @out, align 4
  br label %join
case19:
  store i32 19, ptr %l, align 4
  store i32 19, ptr @out, align 4
  br label %join
case20:
  store i32 20, ptr %l, align 4
  store i32 20, ptr @out, align 4
  br label %join
case21:
  store i32 21, ptr %l, align 4
  store i32 21, ptr @out, align 4
  br label %join
case22:
  store i32 22, ptr %l, align 4
  store i32 22, ptr @out, align 4
  br label %join
case23:
  store i32 23, ptr %l, align 4
  store i32 23, ptr @out, align 4
  br label %join
case24:
  store i32 24, ptr %l, align 4
  store i32 24, ptr @out, align 4
  br label %join
case25:
  store i32 25, ptr %l, align 4
  store i32 25, ptr @out, align 4
  br label %join
case26:
  store i32 26, ptr %l, align 4
  store i32 26, ptr @out, align 4
  br label %join
case27:
  store i32 27, ptr %l, align 4
  store i32 27, ptr @out, align 4
  br label %join
case28:
  store i32 28, ptr %l, align 4
  store i32 28, ptr @out, align 4
  br label %join
case29:
  store i32 29, ptr %l, align 4
  store i32 29, ptr @out, align 4
  br label %join
case30:
  store i32 30, ptr %l, align 4
  store i32 30, ptr @out, align 4
  br label %join
case31:
  store i32 31, ptr %l, align 4
  store i32 31, ptr @out, align 4
  br label %join
case32:
  store i32 32, ptr %l, align 4
  store i32 32, ptr @out, align 4
  br label %join
case33:
  store i32 33, ptr %l, align 4
  store i32 33, ptr @out, align 4
  br label %join
case34:
  store i32 34, ptr %l, align 4
  store i32 34, ptr @out, align 4
  br label %join
case35:
  store i32 35, ptr %l, align 4
  store i32 35, ptr @out, align 4
  br label %join
case36:
  store i32 36, ptr %l, align 4
  store i32 36, ptr @out, align 4
  br label %join
case37:
  store i32 37, ptr %l, align 4
  store i32 37, ptr @out, align 4
  br label %join
case38:
  store i32 38, ptr %l, align 4
  store i32 38, ptr @out, align 4
  br label %join
case39:
  store i32 39, ptr %l, align 4
  store i32 39, ptr @out, align 4
  br label %join
case40:
  store i32 40, ptr %l, align 4
  store i32 40, ptr @out, align 4
  br label %join
case41:
  store i32 41, ptr %l, align 4
  store i32 41, ptr @out, align 4
  br label %join
case42:
  store i32 42, ptr %l, align 4
  store i32 42, ptr @out, align 4
  br label %join
case43:
  store i32 43, ptr %l, align 4
  store i32 43, ptr @out, align 4
  br label %join
case44:
  store i32 44, ptr %l, align 4
  store i32 44, ptr @out, align 4
  br label %join
case45:
  store i32 45, ptr %l, align 4
  store i32 45, ptr @out, align 4
  br label %join
case46:
  store i32 46, ptr %l, align 4
  store i32 46, ptr @out, align 4
  br label %join
case47:
  store i32 47, ptr %l, align 4
  store i32 47, ptr @out, align 4
  br label %join
case48:
  store i32 48, ptr %l, align 4
  store i32 48, ptr @out, align 4
  br label %join
case49:
  store i32 49, ptr %l, align 4
  store i32 49, ptr @out, align 4
  br label %join
case50:
  store i32 50, ptr %l, align 4
  store i32 50, ptr @out, align 4
  br label %join
case51:
  store i32 51, ptr %l, align 4
  store i32 51, ptr @out, align 4
  br label %join
case52:
  store i32 52, ptr %l, align 4
  store i32 52, ptr @out, align 4
  br label %join
case53:
  store i32 53, ptr %l, align 4
  store i32 53, ptr @out, align 4
  br label %join
case54:
  store i32 54, ptr %l, align 4
  store i32 54, ptr @out, align 4
  br label %join
case55:
  store i32 55, ptr %l, align 4
  store i32 55, ptr @out, align 4
  br label %join
case56:
  store i32 56, ptr %l, align 4
  store i32 56, ptr @out, align 4
  br label %join
case57:
  store i32 57, ptr %l, align 4
  store i32 57, ptr @out, align 4
  br label %join
case58:
  store i32 58, ptr %l, align 4
  store i32 58, ptr @out, align 4
  br label %join
case59:
  store i32 59, ptr %l, align 4
  store i32 59, ptr @out, align 4
  br label %join
case60:
  store i32 60, ptr %l, align 4
  store i32 60, ptr @out, align 4
  br label %join
case61:
  store i32 61, ptr %l, align 4
  store i32 61, ptr @out, align 4
  br label %join
case62:
  store i32 62, ptr %l, align 4
  store i32 62, ptr @out, align 4
  br label %join
case63:
  store i32 63, ptr %l, align 4
  store i32 63, ptr @out, align 4
  br label %join
case64:
  store i32 64, ptr %l, align 4
  store i32 64, ptr @out, align 4
  br label %join
case65:
  store i32 65, ptr %l, align 4
  store i32 65, ptr @out, align 4
  br label %join
case66:
  store i32 66, ptr %l, align 4
  store i32 66, ptr @out, align 4
  br label %join
case67:
  store i32 67, ptr %l, align 4
  store i32 67, ptr @out, align 4
  br label %join
case68:
  store i32 68, ptr %l, align 4
  store i32 68, ptr @out, align 4
  br label %join
case69:
  store i32 69, ptr %l, align 4
  store i32 69, ptr @out, align 4
  br label %join
case70:
  store i32 70, ptr %l, align 4
  store i32 70, ptr @out, align 4
  br label %join
case71:
  store i32 71, ptr %l, align 4
  store i32 71, ptr @out, align 4
  br label %join
case72:
  store i32 72, ptr %l, align 4
  store i32 72, ptr @out, align 4
  br label %join
case73:
  store i32 73, ptr %l, align 4
  store i32 73, ptr @out, align 4
  br label %join
case74:
  store i32 74, ptr %l, align 4
  store i32 74, ptr @out, align 4
  br label %join
case75:
  store i32 75, ptr %l, align 4
  store i32 75, ptr @out, align 4
  br label %join
case76:
  store i32 76, ptr %l, align 4
  store i32 76, ptr @out, align 4
  br label %join
case77:
  store i32 77, ptr %l, align 4
  store i32 77, ptr @out, align 4
  br label %join
case78:
  store i32 78, ptr %l, align 4
  store i32 78, ptr @out, align 4
  br label %join
case79:
  store i32 79, ptr %l, align 4
  store i32 79, ptr @out, align 4
  br label %join
case80:
  store i32 80, ptr %l, align 4
  store i32 80, ptr @out, align 4
  br label %join
case81:
  store i32 81, ptr %l, align 4
  store i32 81, ptr @out, align 4
  br label %join
case82:
  store i32 82, ptr %l, align 4
  store i32 82, ptr @out, align 4
  br label %join
case83:
  store i32 83, ptr %l, align 4
  store i32 83, ptr @out, align 4
  br label %join
case84:
  store i32 84, ptr %l, align 4
  store i32 84, ptr @out, align 4
  br label %join
case85:
  store i32 85, ptr %l, align 4
  store i32 85, ptr @out, align 4
  br label %join
case86:
  store i32 86, ptr %l, align 4
  store i32 86, ptr @out, align 4
  br label %join
case87:
  store i32 87, ptr %l, align 4
  store i32 87, ptr @out, align 4
  br label %join
case88:
  store i32 88, ptr %l, align 4
  store i32 88, ptr @out, align 4
  br label %join
case89:
  store i32 89, ptr %l, align 4
  store i32 89, ptr @out, align 4
  br label %join
case90:
  store i32 90, ptr %l, align 4
  store i32 90, ptr @out, align 4
  br label %join
case91:
  store i32 91, ptr %l, align 4
  store i32 91, ptr @out, align 4
  br label %join
case92:
  store i32 92, ptr %l, align 4
  store i32 92, ptr @out, align 4
  br label %join
case93:
  store i32 93, ptr %l, align 4
  store i32 93, ptr @out, align 4
  br label %join
case94:
  store i32 94, ptr %l, align 4
  store i32 94, ptr @out, align 4
  br label %join
case95:
  store i32 95, ptr %l, align 4
  store i32 95, ptr @out, align 4
  br label %join
case96:
  store i32 96, ptr %l, align 4
  store i32 96, ptr @out, align 4
  br label %join
case97:
  store i32 97, ptr %l, align 4
  store i32 97, ptr @out, align 4
  br label %join
case98:
  store i32 98, ptr %l, align 4
  store i32 98, ptr @out, align 4
  br label %join
case99:
  store i32 99, ptr %l, align 4
  store i32 99, ptr @out, align 4
  br label %join
case100:
  store i32 100, ptr %l, align 4
  store i32 100, ptr @out, align 4
  br label %join
case101:
  store i32 101, ptr %l, align 4
  store i32 101, ptr @out, align 4
  br label %join
case102:
  store i32 102, ptr %l, align 4
  store i32 102, ptr @out, align 4
  br label %join
case103:
  store i32 103, ptr %l, align 4
  store i32 103, ptr @out, align 4
  br label %join
case104:
  store i32 104, ptr %l, align 4
  store i32 104, ptr @out, align 4
  br label %join
case105:
  store i32 105, ptr %l, align 4
  store i32 105, ptr @out, align 4
  br label %join
case106:
  store i32 106, ptr %l, align 4
  store i32 106, ptr @out, align 4
  br label %join
case107:
  store i32 107, ptr %l, align 4
  store i32 107, ptr @out, align 4
  br label %join
case108:
  store i32 108, ptr %l, align 4
  store i32 108, ptr @out, align 4
  br label %join
case109:
  store i32 109, ptr %l, align 4
  store i32 109, ptr @out, align 4
  br label %join
case110:
  store i32 110, ptr %l, align 4
  store i32 110, ptr @out, align 4
  br label %join
case111:
  store i32 111, ptr %l, align 4
  store i32 111, ptr @out, align 4
  br label %join
case112:
  store i32 112, ptr %l, align 4
  store i32 112, ptr @out, align 4
  br label %join
case113:
  store i32 113, ptr %l, align 4
  store i32 113, ptr @out, align 4
  br label %join
case114:
  store i32 114, ptr %l, align 4
  store i32 114, ptr @out, align 4
  br label %join
case115:
  store i32 115, ptr %l, align 4
  store i32 115, ptr @out, align 4
  br label %join
case116:
  store i32 116, ptr %l, align 4
  store i32 116, ptr @out, align 4
  br label %join
case117:
  store i32 117, ptr %l, align 4
  store i32 117, ptr @out, align 4
  br label %join
case118:
  store i32 118, ptr %l, align 4
  store i32 118, ptr @out, align 4
  br label %join
case119:
  store i32 119, ptr %l, align 4
  store i32 119, ptr @out, align 4
  br label %join
case120:
  store i32 120, ptr %l, align 4
  store i32 120, ptr @out, align 4
  br label %join
case121:
  store i32 121, ptr %l, align 4
  store i32 121, ptr @out, align 4
  br label %join
case122:
  store i32 122, ptr %l, align 4
  store i32 122, ptr @out, align 4
  br label %join
case123:
  store i32 123, ptr %l, align 4
  store i32 123, ptr @out, align 4
  br label %join
case124:
  store i32 124, ptr %l, align 4
  store i32 124, ptr @out, align 4
  br label %join
case125:
  store i32 125, ptr %l, align 4
  store i32 125, ptr @out, align 4
  br label %join
case126:
  store i32 126, ptr %l, align 4
  store i32 126, ptr @out, align 4
  br label %join
case127:
  store i32 127, ptr %l, align 4
  store i32 127, ptr @out, align 4
  br label %join
case128:
  store i32 128, ptr %l, align 4
  store i32 128, ptr @out, align 4
  br label %join
case129:
  store i32 129, ptr %l, align 4
  store i32 129, ptr @out, align 4
  br label %join
case130:
  store i32 130, ptr %l, align 4
  store i32 130, ptr @out, align 4
  br label %join
case131:
  store i32 131, ptr %l, align 4
  store i32 131, ptr @out, align 4
  br label %join
case132:
  store i32 132, ptr %l, align 4
  store i32 132, ptr @out, align 4
  br label %join
case133:
  store i32 133, ptr %l, align 4
  store i32 133, ptr @out, align 4
  br label %join
case134:
  store i32 134, ptr %l, align 4
  store i32 134, ptr @out, align 4
  br label %join
case135:
  store i32 135, ptr %l, align 4
  store i32 135, ptr @out, align 4
  br label %join
case136:
  store i32 136, ptr %l, align 4
  store i32 136, ptr @out, align 4
  br label %join
case137:
  store i32 137, ptr %l, align 4
  store i32 137, ptr @out, align 4
  br label %join
case138:
  store i32 138, ptr %l, align 4
  store i32 138, ptr @out, align 4
  br label %join
case139:
  store i32 139, ptr %l, align 4
  store i32 139, ptr @out, align 4
  br label %join
case140:
  store i32 140, ptr %l, align 4
  store i32 140, ptr @out, align 4
  br label %join
case141:
  store i32 141, ptr %l, align 4
  store i32 141, ptr @out, align 4
  br label %join
case142:
  store i32 142, ptr %l, align 4
  store i32 142, ptr @out, align 4
  br label %join
case143:
  store i32 143, ptr %l, align 4
  store i32 143, ptr @out, align 4
  br label %join
case144:
  store i32 144, ptr %l, align 4
  store i32 144, ptr @out, align 4
  br label %join
case145:
  store i32 145, ptr %l, align 4
  store i32 145, ptr @out, align 4
  br label %join
case146:
  store i32 146, ptr %l, align 4
  store i32 146, ptr @out, align 4
  br label %join
case147:
  store i32 147, ptr %l, align 4
  store i32 147, ptr @out, align 4
  br label %join
case148:
  store i32 148, ptr %l, align 4
  store i32 148, ptr @out, align 4
  br label %join
case149:
  store i32 149, ptr %l, align 4
  store i32 149, ptr @out, align 4
  br label %join
case150:
  store i32 150, ptr %l, align 4
  store i32 150, ptr @out, align 4
  br label %join
case151:
  store i32 151, ptr %l, align 4
  store i32 151, ptr @out, align 4
  br label %join
case152:
  store i32 152, ptr %l, align 4
  store i32 152, ptr @out, align 4
  br label %join
case153:
  store i32 153, ptr %l, align 4
  store i32 153, ptr @out, align 4
  br label %join
case154:
  store i32 154, ptr %l, align 4
  store i32 154, ptr @out, align 4
  br label %join
case155:
  store i32 155, ptr %l, align 4
  store i32 155, ptr @out, align 4
  br label %join
case156:
  store i32 156, ptr %l, align 4
  store i32 156, ptr @out, align 4
  br label %join
case157:
  store i32 157, ptr %l, align 4
  store i32 157, ptr @out, align 4
  br label %join
case158:
  store i32 158, ptr %l, align 4
  store i32 158, ptr @out, align 4
  br label %join
case159:
  store i32 159, ptr %l, align 4
  store i32 159, ptr @out, align 4
  br label %join
case160:
  store i32 160, ptr %l, align 4
  store i32 160, ptr @out, align 4
  br label %join
case161:
  store i32 161, ptr %l, align 4
  store i32 161, ptr @out, align 4
  br label %join
case162:
  store i32 162, ptr %l, align 4
  store i32 162, ptr @out, align 4
  br label %join
case163:
  store i32 163, ptr %l, align 4
  store i32 163, ptr @out, align 4
  br label %join
case164:
  store i32 164, ptr %l, align 4
  store i32 164, ptr @out, align 4
  br label %join
case165:
  store i32 165, ptr %l, align 4
  store i32 165, ptr @out, align 4
  br label %join
case166:
  store i32 166, ptr %l, align 4
  store i32 166, ptr @out, align 4
  br label %join
case167:
  store i32 167, ptr %l, align 4
  store i32 167, ptr @out, align 4
  br label %join
case168:
  store i32 168, ptr %l, align 4
  store i32 168, ptr @out, align 4
  br label %join
case169:
  store i32 169, ptr %l, align 4
  store i32 169, ptr @out, align 4
  br label %join
case170:
  store i32 170, ptr %l, align 4
  store i32 170, ptr @out, align 4
  br label %join
case171:
  store i32 171, ptr %l, align 4
  store i32 171, ptr @out, align 4
  br label %join
case172:
  store i32 172, ptr %l, align 4
  store i32 172, ptr @out, align 4
  br label %join
case173:
  store i32 173, ptr %l, align 4
  store i32 173, ptr @out, align 4
  br label %join
case174:
  store i32 174, ptr %l, align 4
  store i32 174, ptr @out, align 4
  br label %join
case175:
  store i32 175, ptr %l, align 4
  store i32 175, ptr @out, align 4
  br label %join
case176:
  store i32 176, ptr %l, align 4
  store i32 176, ptr @out, align 4
  br label %join
case177:
  store i32 177, ptr %l, align 4
  store i32 177, ptr @out, align 4
  br label %join
case178:
  store i32 178, ptr %l, align 4
  store i32 178, ptr @out, align 4
  br label %join
case179:
  store i32 179, ptr %l, align 4
  store i32 179, ptr @out, align 4
  br label %join
case180:
  store i32 180, ptr %l, align 4
  store i32 180, ptr @out, align 4
  br label %join
case181:
  store i32 181, ptr %l, align 4
  store i32 181, ptr @out, align 4
  br label %join
case182:
  store i32 182, ptr %l, align 4
  store i32 182, ptr @out, align 4
  br label %join
case183:
  store i32 183, ptr %l, align 4
  store i32 183, ptr @out, align 4
  br label %join
case184:
  store i32 184, ptr %l, align 4
  store i32 184, ptr @out, align 4
  br label %join
case185:
  store i32 185, ptr %l, align 4
  store i32 185, ptr @out, align 4
  br label %join
case186:
  store i32 186, ptr %l, align 4
  store i32 186, ptr @out, align 4
  br label %join
case187:
  store i32 187, ptr %l, align 4
  store i32 187, ptr @out, align 4
  br label %join
case188:
  store i32 188, ptr %l, align 4
  store i32 188, ptr @out, align 4
  br label %join
case189:
  store i32 189, ptr %l, align 4
  store i32 189, ptr @out, align 4
  br label %join
case190:
  store i32 190, ptr %l, align 4
  store i32 190, ptr @out, align 4
  br label %join
case191:
  store i32 191, ptr %l, align 4
  store i32 191, ptr @out, align 4
  br label %join
case192:
  store i32 192, ptr %l, align 4
  store i32 192, ptr @out, align 4
  br label %join
case193:
  store i32 193, ptr %l, align 4
  store i32 193, ptr @out, align 4
  br label %join
case194:
  store i32 194, ptr %l, align 4
  store i32 194, ptr @out, align 4
  br label %join
case195:
  store i32 195, ptr %l, align 4
  store i32 195, ptr @out, align 4
  br label %join
case196:
  store i32 196, ptr %l, align 4
  store i32 196, ptr @out, align 4
  br label %join
case197:
  store i32 197, ptr %l, align 4
  store i32 197, ptr @out, align 4
  br label %join
case198:
  store i32 198, ptr %l, align 4
  store i32 198, ptr @out, align 4
  br label %join
case199:
  store i32 199, ptr %l, align 4
  store i32 199, ptr @out, align 4
  br label %join
case200:
  store i32 200, ptr %l, align 4
  store i32 200, ptr @out, align 4
  br label %join
case201:
  store i32 201, ptr %l, align 4
  store i32 201, ptr @out, align 4
  br label %join
case202:
  store i32 202, ptr %l, align 4
  store i32 202, ptr @out, align 4
  br label %join
case203:
  store i32 203, ptr %l, align 4
  store i32 203, ptr @out, align 4
  br label %join
case204:
  store i32 204, ptr %l, align 4
  store i32 204, ptr @out, align 4
  br label %join
case205:
  store i32 205, ptr %l, align 4
  store i32 205, ptr @out, align 4
  br label %join
case206:
  store i32 206, ptr %l, align 4
  store i32 206, ptr @out, align 4
  br label %join
case207:
  store i32 207, ptr %l, align 4
  store i32 207, ptr @out, align 4
  br label %join
case208:
  store i32 208, ptr %l, align 4
  store i32 208, ptr @out, align 4
  br label %join
case209:
  store i32 209, ptr %l, align 4
  store i32 209, ptr @out, align 4
  br label %join
case210:
  store i32 210, ptr %l, align 4
  store i32 210, ptr @out, align 4
  br label %join
case211:
  store i32 211, ptr %l, align 4
  store i32 211, ptr @out, align 4
  br label %join
case212:
  store i32 212, ptr %l, align 4
  store i32 212, ptr @out, align 4
  br label %join
case213:
  store i32 213, ptr %l, align 4
  store i32 213, ptr @out, align 4
  br label %join
case214:
  store i32 214, ptr %l, align 4
  store i32 214, ptr @out, align 4
  br label %join
case215:
  store i32 215, ptr %l, align 4
  store i32 215, ptr @out, align 4
  br label %join
case216:
  store i32 216, ptr %l, align 4
  store i32 216, ptr @out, align 4
  br label %join
case217:
  store i32 217, ptr %l, align 4
  store i32 217, ptr @out, align 4
  br label %join
case218:
  store i32 218, ptr %l, align 4
  store i32 218, ptr @out, align 4
  br label %join
case219:
  store i32 219, ptr %l, align 4
  store i32 219, ptr @out, align 4
  br label %join
case220:
  store i32 220, ptr %l, align 4
  store i32 220, ptr @out, align 4
  br label %join
case221:
  store i32 221, ptr %l, align 4
  store i32 221, ptr @out, align 4
  br label %join
case222:
  store i32 222, ptr %l, align 4
  store i32 222, ptr @out, align 4
  br label %join
case223:
  store i32 223, ptr %l, align 4
  store i32 223, ptr @out, align 4
  br label %join
case224:
  store i32 224, ptr %l, align 4
  store i32 224, ptr @out, align 4
  br label %join
case225:
  store i32 225, ptr %l, align 4
  store i32 225, ptr @out, align 4
  br label %join
case226:
  store i32 226, ptr %l, align 4
  store i32 226, ptr @out, align 4
  br label %join
case227:
  store i32 227, ptr %l, align 4
  store i32 227, ptr @out, align 4
  br label %join
case228:
  store i32 228, ptr %l, align 4
  store i32 228, ptr @out, align 4
  br label %join
case229:
  store i32 229, ptr %l, align 4
  store i32 229, ptr @out, align 4
  br label %join
case230:
  store i32 230, ptr %l, align 4
  store i32 230, ptr @out, align 4
  br label %join
case231:
  store i32 231, ptr %l, align 4
  store i32 231, ptr @out, align 4
  br label %join
case232:
  store i32 232, ptr %l, align 4
  store i32 232, ptr @out, align 4
  br label %join
case233:
  store i32 233, ptr %l, align 4
  store i32 233, ptr @out, align 4
  br label %join
case234:
  store i32 234, ptr %l, align 4
  store i32 234, ptr @out, align 4
  br label %join
case235:
  store i32 235, ptr %l, align 4
  store i32 235, ptr @out, align 4
  br label %join
case236:
  store i32 236, ptr %l, align 4
  store i32 236, ptr @out, align 4
  br label %join
case237:
  store i32 237, ptr %l, align 4
  store i32 237, ptr @out, align 4
  br label %join
case238:
  store i32 238, ptr %l, align 4
  store i32 238, ptr @out, align 4
  br label %join
case239:
  store i32 239, ptr %l, align 4
  store i32 239, ptr @out, align 4
  br label %join
case240:
  store i32 240, ptr %l, align 4
  store i32 240, ptr @out, align 4
  br label %join
case241:
  store i32 241, ptr %l, align 4
  store i32 241, ptr @out, align 4
  br label %join
case242:
  store i32 242, ptr %l, align 4
  store i32 242, ptr @out, align 4
  br label %join
case243:
  store i32 243, ptr %l, align 4
  store i32 243, ptr @out, align 4
  br label %join
case244:
  store i32 244, ptr %l, align 4
  store i32 244, ptr @out, align 4
  br label %join
case245:
  store i32 245, ptr %l, align 4
  store i32 245, ptr @out, align 4
  br label %join
case246:
  store i32 246, ptr %l, align 4
  store i32 246, ptr @out, align 4
  br label %join
case247:
  store i32 247, ptr %l, align 4
  store i32 247, ptr @out, align 4
  br label %join
case248:
  store i32 248, ptr %l, align 4
  store i32 248, ptr @out, align 4
  br label %join
case249:
  store i32 249, ptr %l, align 4
  store i32 249, ptr @out, align 4
  br label %join
case250:
  store i32 250, ptr %l, align 4
  store i32 250, ptr @out, align 4
  br label %join
case251:
  store i32 251, ptr %l, align 4
  store i32 251, ptr @out, align 4
  br label %join
case252:
  store i32 252, ptr %l, align 4
  store i32 252, ptr @out, align 4
  br label %join
case253:
  store i32 253, ptr %l, align 4
  store i32 253, ptr @out, align 4
  br label %join
case254:
  store i32 254, ptr %l, align 4
  store i32 254, ptr @out, align 4
  br label %join
case255:
  store i32 255, ptr %l, align 4
  store i32 255, ptr @out, align 4
  br label %join
case256:
  store i32 256, ptr %l, align 4
  store i32 256, ptr @out, align 4
  br label %join
case257:
  store i32 257, ptr %l, align 4
  store i32 257, ptr @out, align 4
  br label %join
case258:
  store i32 258, ptr %l, align 4
  store i32 258, ptr @out, align 4
  br label %join
case259:
  store i32 259, ptr %l, align 4
  store i32 259, ptr @out, align 4
  br label %join
case260:
  store i32 260, ptr %l, align 4
  store i32 260, ptr @out, align 4
  br label %join
case261:
  store i32 261, ptr %l, align 4
  store i32 261, ptr @out, align 4
  br label %join
case262:
  store i32 262, ptr %l, align 4
  store i32 262, ptr @out, align 4
  br label %join
case263:
  store i32 263, ptr %l, align 4
  store i32 263, ptr @out, align 4
  br label %join
case264:
  store i32 264, ptr %l, align 4
  store i32 264, ptr @out, align 4
  br label %join
case265:
  store i32 265, ptr %l, align 4
  store i32 265, ptr @out, align 4
  br label %join
case266:
  store i32 266, ptr %l, align 4
  store i32 266, ptr @out, align 4
  br label %join
case267:
  store i32 267, ptr %l, align 4
  store i32 267, ptr @out, align 4
  br label %join
case268:
  store i32 268, ptr %l, align 4
  store i32 268, ptr @out, align 4
  br label %join
case269:
  store i32 269, ptr %l, align 4
  store i32 269, ptr @out, align 4
  br label %join
case270:
  store i32 270, ptr %l, align 4
  store i32 270, ptr @out, align 4
  br label %join
case271:
  store i32 271, ptr %l, align 4
  store i32 271, ptr @out, align 4
  br label %join
case272:
  store i32 272, ptr %l, align 4
  store i32 272, ptr @out, align 4
  br label %join
case273:
  store i32 273, ptr %l, align 4
  store i32 273, ptr @out, align 4
  br label %join
case274:
  store i32 274, ptr %l, align 4
  store i32 274, ptr @out, align 4
  br label %join
case275:
  store i32 275, ptr %l, align 4
  store i32 275, ptr @out, align 4
  br label %join
case276:
  store i32 276, ptr %l, align 4
  store i32 276, ptr @out, align 4
  br label %join
case277:
  store i32 277, ptr %l, align 4
  store i32 277, ptr @out, align 4
  br label %join
case278:
  store i32 278, ptr %l, align 4
  store i32 278, ptr @out, align 4
  br label %join
case279:
  store i32 279, ptr %l, align 4
  store i32 279, ptr @out, align 4
  br label %join
case280:
  store i32 280, ptr %l, align 4
  store i32 280, ptr @out, align 4
  br label %join
case281:
  store i32 281, ptr %l, align 4
  store i32 281, ptr @out, align 4
  br label %join
case282:
  store i32 282, ptr %l, align 4
  store i32 282, ptr @out, align 4
  br label %join
case283:
  store i32 283, ptr %l, align 4
  store i32 283, ptr @out, align 4
  br label %join
case284:
  store i32 284, ptr %l, align 4
  store i32 284, ptr @out, align 4
  br label %join
case285:
  store i32 285, ptr %l, align 4
  store i32 285, ptr @out, align 4
  br label %join
case286:
  store i32 286, ptr %l, align 4
  store i32 286, ptr @out, align 4
  br label %join
case287:
  store i32 287, ptr %l, align 4
  store i32 287, ptr @out, align 4
  br label %join
case288:
  store i32 288, ptr %l, align 4
  store i32 288, ptr @out, align 4
  br label %join
case289:
  store i32 289, ptr %l, align 4
  store i32 289, ptr @out, align 4
  br label %join
case290:
  store i32 290, ptr %l, align 4
  store i32 290, ptr @out, align 4
  br label %join
case291:
  store i32 291, ptr %l, align 4
  store i32 291, ptr @out, align 4
  br label %join
case292:
  store i32 292, ptr %l, align 4
  store i32 292, ptr @out, align 4
  br label %join
case293:
  store i32 293, ptr %l, align 4
  store i32 293, ptr @out, align 4
  br label %join
case294:
  store i32 294, ptr %l, align 4
  store i32 294, ptr @out, align 4
  br label %join
case295:
  store i32 295, ptr %l, align 4
  store i32 295, ptr @out, align 4
  br label %join
case296:
  store i32 296, ptr %l, align 4
  store i32 296, ptr @out, align 4
  br label %join
case297:
  store i32 297, ptr %l, align 4
  store i32 297, ptr @out, align 4
  br label %join
case298:
  store i32 298, ptr %l, align 4
  store i32 298, ptr @out, align 4
  br label %join
case299:
  store i32 299, ptr %l, align 4
  store i32 299, ptr @out, align 4
  br label %join
join:
  %next = add i32 %i, 1
  br label %loop
done:
  %c = call i32 @pthread_create(ptr %t, ptr null, ptr @worker, ptr %l)
  store i32 -1, ptr %l, align 4
  ret void
}
