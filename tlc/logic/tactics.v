(* TLC in Coq
 *
 * Module: tlc.logic.tactics
 * Purpose: Contains tactics related to the logic implementation.
 *)

Require Import mathcomp.ssreflect.seq.
Require Import mathcomp.ssreflect.ssreflect.
Require Import tlc.logic.context.
Require Import tlc.logic.derives.
Require Import tlc.logic.sequent.
Require Import tlc.logic.temporal.
Require Import tlc.semantics.all_semantics.
Require Import tlc.syntax.all_syntax.
Require Import tlc.utility.result.

(* The head premise and its reduction are congruent *)
Lemma DReduceP C Delta Gamma H H' A :
  [[A H]] = Success H' ->
  Context Delta (H' :: Gamma) ||- C, A <->
  Context Delta (H :: Gamma) ||- C, A.
Proof.
  by move=> E; split=> P;
    (eapply DSCut; first by apply DReduceCong; exact: E);
    dsplitp; dswap; dclear; (* Extract iff *)
    dsplitp; [dswap |]; dclear; (* Extract branch *)
    (difp; first by []);
    dswap; dclear.
Qed.

(* The conclusion and its reduction are congruent *)
Lemma DReduceC C Z A A' :
  [[A A]] = Success A' ->
  Z ||- C, A' <-> Z ||- C, A.
Proof.
  by case: Z => Delta Gamma E; split=> P;
    (eapply DSCut; first by apply: DReduceCong; exact: E);
    dsplitp; dswap; dclear; (* Extract iff *)
    dsplitp; [| dswap]; dclear; (* Extract branch *)
    difp.
Qed.

(* Reduction *)
Ltac dsimplp :=
  rewrite -DReduceP; last by []; dclean.
Ltac dsimpl :=
  rewrite -DReduceC; last by []; dclean.

(* Perform case analysis on an argument term a that appears in a match *)
Ltac dcase a_ :=
  (* Unfold common forms of match syntaxes *)
  rewrite /TIf /TLet /TAbstraction /TMatchWith;
  match goal with
  | |- context[ {-t TMatch ?cs_ ' a_ -} ] =>
    eapply DSCut;
      [by apply DCaseAnalysis with (a := a_) (cs := cs_); first by [] |
      simpl]
  end.

(* Simplify a restricted assertion *)
Ltac dsimplrestrictp :=
  rewrite /restrict_assertion /=; dclean;
  repeat (dtl124; dtsubstposp);
  repeat (dtl125; dtsubstposp).
