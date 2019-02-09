Require Import mathcomp.ssreflect.seq.
Require Import mathcomp.ssreflect.ssreflect.
Require Import tlc.semantics.environment.
Require Import tlc.semantics.predicate.
Require Import tlc.syntax.all_syntax.
Require Import tlc.utility.partial_map.
Require Import tlc.utility.set.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(* Substitutes free variables in assertion A with terms from environment E *)
Reserved Notation "A [A/ E ]" (at level 1, left associativity).
Fixpoint substitute_assertion (E : environment) A :=
  match A with
  | APredicate p => APredicate p[p/E]
  | ANot A => ANot A[A/E]
  | AOr Al Ar => AOr Al[A/E] Ar[A/E]
  | AForAll v A => A[A/E{-v}]
  | AUntil' Al Ar => AUntil' Al[A/E] Ar[A/E]
  | ASince' Al Ar => ASince' Al[A/E] Ar[A/E]
  | ASelf A => ASelf A[A/E]
  end
where "A [A/ E ]" := (substitute_assertion E A).

(* Computes the set of free variables in an assertion *)
Fixpoint assertion_free A :=
  match A with
  | APredicate p => predicate_free p
  | ANot A => assertion_free A
  | AOr Al Ar => assertion_free Al \union assertion_free Ar
  | AForAll v A => rem v (assertion_free A)
  | AUntil' Al Ar => assertion_free Al \union assertion_free Ar
  | ASince' Al Ar => assertion_free Al \union assertion_free Ar
  | ASelf A => assertion_free A
  end.