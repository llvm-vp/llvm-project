; REQUIRES: asserts

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -use-vp-intrinsics=forced-no-evl \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=WITHOUT-AVL %s

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -use-vp-intrinsics=forced \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=FORCE-AVL %s

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -use-vp-intrinsics=off \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=NO-VP %s

; RUN: opt -loop-vectorize -debug-only=loop-vectorize -force-vector-width=4 \
; RUN: -prefer-predicate-over-epilogue=predicate-dont-vectorize \
; RUN: -mattr=+avx512f -disable-output  %s 2>&1 | FileCheck --check-prefix=DEFAULT %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Function Attrs: nofree norecurse nounwind uwtable
define dso_local void @foo(i32* noalias nocapture %a, i32* noalias nocapture readonly %b, i32* noalias nocapture readonly %c, i64 %N) local_unnamed_addr {
; WITHOUT-AVL: Plan 'Initial VPlan for VF={4},UF>=1' {
; WITHOUT-AVL: Live-in vp<%1> = vector-trip-count
; WITHOUT-AVL: Live-in vp<%2> = backedge-taken count
; WITHOUT-AVL: <x1> vector loop: {
; WITHOUT-AVL-NEXT:   vector.body:
; WITHOUT-AVL-NEXT:     EMIT vp<%4> = CANONICAL-INDUCTION
; WITHOUT-AVL-NEXT:     vp<%5>    = SCALAR-STEPS vp<%4>, ir<0>, ir<1>
; WITHOUT-AVL-NEXT:     EMIT vp<%6> = WIDEN-CANONICAL-INDUCTION vp<%4>
; WITHOUT-AVL-NEXT:     EMIT vp<%7> = icmp ule vp<%6> vp<%2>
; WITHOUT-AVL-NEXT:     CLONE ir<%arrayidx> = getelementptr ir<%b>, vp<%5>
; WITHOUT-AVL-NEXT:     PREDICATED-WIDEN ir<%0> = load ir<%arrayidx>, vp<%7>, vp<%3>
; WITHOUT-AVL-NEXT:     CLONE ir<%arrayidx2> = getelementptr ir<%c>, vp<%5>
; WITHOUT-AVL-NEXT:     PREDICATED-WIDEN ir<%1> = load ir<%arrayidx2>, vp<%7>, vp<%3>
; WITHOUT-AVL-NEXT:     PREDICATED-WIDEN ir<%add> = add ir<%1>, ir<%0>, vp<%7>, vp<%3>
; WITHOUT-AVL-NEXT:     CLONE ir<%arrayidx4> = getelementptr ir<%a>, vp<%5>
; WITHOUT-AVL-NEXT:     PREDICATED-WIDEN store ir<%arrayidx4>, ir<%add>, vp<%7>, vp<%3>
; WITHOUT-AVL-NEXT:     EMIT vp<%14> = VF * UF +  vp<%4>
; WITHOUT-AVL-NEXT:     EMIT branch-on-count  vp<%14> vp<%1>
; WITHOUT-AVL-NEXT:   No successors
; WITHOUT-AVL-NEXT: }


; FORCE-AVL: VPlan 'Initial VPlan for VF={4},UF>=1' {
; FORCE-AVL: Live-in vp<%1> = vector-trip-count
; FORCE-AVL: <x1> vector loop: {
; FORCE-AVL-NEXT:   vector.body:
; FORCE-AVL-NEXT:     EMIT vp<%3> = CANONICAL-INDUCTION
; FORCE-AVL-NEXT:     vp<%4>    = SCALAR-STEPS vp<%3>, ir<0>, ir<1>
; FORCE-AVL-NEXT:     EMIT vp<%5> = WIDEN-CANONICAL-INDUCTION vp<%3>
; FORCE-AVL-NEXT:     EMIT vp<%6> = GENERATE-EXPLICIT-VECTOR-LENGTH
; FORCE-AVL-NEXT:     CLONE ir<%arrayidx> = getelementptr ir<%b>, vp<%4>
; FORCE-AVL-NEXT:     EMIT vp<%8> = all true mask
; FORCE-AVL-NEXT:     PREDICATED-WIDEN ir<%0> = load ir<%arrayidx>, vp<%8>, vp<%6>
; FORCE-AVL-NEXT:     CLONE ir<%arrayidx2> = getelementptr ir<%c>, vp<%4>
; FORCE-AVL-NEXT:     PREDICATED-WIDEN ir<%1> = load ir<%arrayidx2>, vp<%8>, vp<%6>
; FORCE-AVL-NEXT:     PREDICATED-WIDEN ir<%add> = add ir<%1>, ir<%0>, vp<%8>, vp<%6>
; FORCE-AVL-NEXT:     CLONE ir<%arrayidx4> = getelementptr ir<%a>, vp<%4>
; FORCE-AVL-NEXT:     PREDICATED-WIDEN store ir<%arrayidx4>, ir<%add>, vp<%8>, vp<%6>
; FORCE-AVL-NEXT:     EMIT vp<%14> = VF * UF +  vp<%3>
; FORCE-AVL-NEXT:     EMIT branch-on-count  vp<%14> vp<%1>
; FORCE-AVL-NEXT:   No successors
; FORCE-AVL-NEXT: }


; NO-VP: VPlan 'Initial VPlan for VF={4},UF>=1' {
; NO-VP: Live-in vp<%1> = vector-trip-count
; NO-VP: Live-in vp<%2> = backedge-taken count
; NO-VP: <x1> vector loop: {
; NO-VP-NEXT:   vector.body:
; NO-VP-NEXT:     EMIT vp<%3> = CANONICAL-INDUCTION
; NO-VP-NEXT:     vp<%4>    = SCALAR-STEPS vp<%3>, ir<0>, ir<1>
; NO-VP-NEXT:     EMIT vp<%5> = WIDEN-CANONICAL-INDUCTION vp<%3>
; NO-VP-NEXT:     EMIT vp<%6> = icmp ule vp<%5> vp<%2>
; NO-VP-NEXT:     CLONE ir<%arrayidx> = getelementptr ir<%b>, vp<%4>
; NO-VP-NEXT:     WIDEN ir<%0> = load ir<%arrayidx>, vp<%6>
; NO-VP-NEXT:     CLONE ir<%arrayidx2> = getelementptr ir<%c>, vp<%4>
; NO-VP-NEXT:     WIDEN ir<%1> = load ir<%arrayidx2>, vp<%6>
; NO-VP-NEXT:     WIDEN ir<%add> = add ir<%1>, ir<%0>
; NO-VP-NEXT:     CLONE ir<%arrayidx4> = getelementptr ir<%a>, vp<%4>
; NO-VP-NEXT:     WIDEN store ir<%arrayidx4>, ir<%add>, vp<%6>
; NO-VP-NEXT:     EMIT vp<%13> = VF * UF +  vp<%3>
; NO-VP-NEXT:     EMIT branch-on-count  vp<%13> vp<%1>
; NO-VP-NEXT:   No successors
; NO-VP-NEXT: }


; DEFAULT: VPlan 'Initial VPlan for VF={4},UF>=1' {
; DEFAULT: Live-in vp<%1> = vector-trip-count
; DEFAULT: Live-in vp<%2> = backedge-taken count
; DEFAULT: <x1> vector loop: {
; DEFAULT-NEXT:   vector.body:
; DEFAULT-NEXT:     EMIT vp<%3> = CANONICAL-INDUCTION
; DEFAULT-NEXT:     vp<%4>    = SCALAR-STEPS vp<%3>, ir<0>, ir<1>
; DEFAULT-NEXT:     EMIT vp<%5> = WIDEN-CANONICAL-INDUCTION vp<%3>
; DEFAULT-NEXT:     EMIT vp<%6> = icmp ule vp<%5> vp<%2>
; DEFAULT-NEXT:     CLONE ir<%arrayidx> = getelementptr ir<%b>, vp<%4>
; DEFAULT-NEXT:     WIDEN ir<%0> = load ir<%arrayidx>, vp<%6>
; DEFAULT-NEXT:     CLONE ir<%arrayidx2> = getelementptr ir<%c>, vp<%4>
; DEFAULT-NEXT:     WIDEN ir<%1> = load ir<%arrayidx2>, vp<%6>
; DEFAULT-NEXT:     WIDEN ir<%add> = add ir<%1>, ir<%0>
; DEFAULT-NEXT:     CLONE ir<%arrayidx4> = getelementptr ir<%a>, vp<%4>
; DEFAULT-NEXT:     WIDEN store ir<%arrayidx4>, ir<%add>, vp<%6>
; DEFAULT-NEXT:     EMIT vp<%13> = VF * UF +  vp<%3>
; DEFAULT-NEXT:     EMIT branch-on-count  vp<%13> vp<%1>
; DEFAULT-NEXT:   No successors
; DEFAULT-NEXT: }

entry:
  %cmp10 = icmp sgt i64 %N, 0
  br i1 %cmp10, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  br label %for.body

for.cond.cleanup.loopexit:                        ; preds = %for.body
  br label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond.cleanup.loopexit, %entry
  ret void

for.body:                                         ; preds = %for.body.preheader, %for.body
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds i32, i32* %b, i64 %indvars.iv
  %0 = load i32, i32* %arrayidx, align 4
  %arrayidx2 = getelementptr inbounds i32, i32* %c, i64 %indvars.iv
  %1 = load i32, i32* %arrayidx2, align 4
  %add = add nsw i32 %1, %0
  %arrayidx4 = getelementptr inbounds i32, i32* %a, i64 %indvars.iv
  store i32 %add, i32* %arrayidx4, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %N
  br i1 %exitcond.not, label %for.cond.cleanup.loopexit, label %for.body
}
