Require Import Coq.Lists.List.
Require Import TLC.Component.
Require Import TLC.Event.
Require Import TLC.FairLossLink.
Require Import TLC.Flexible.
Require Import TLC.Orientation.
Require Import TLC.StaticTerm.
Require Import TLC.Term.
Require Import TLC.Variant.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Lemma request_fl_or_events {C} i
  (H : Vector.nth (or_events C) i = request_fl (node C) (message C))
  (e : term C (request_fl (node C) (message C))) :
  term C (Vector.nth (or_events C) i).
Proof.
  rewrite <- H in e; exact e.
Qed.

Lemma indication_fl_ii_events {C} i
  (H : Vector.nth (ii_events C) i = indication_fl (node C) (message C))
  (e : term C (indication_fl (node C) (message C))) :
  term C (Vector.nth (ii_events C) i).
Proof.
  rewrite <- H in e; exact e.
Qed.

(* Basic axioms of the program logic *)
Section program_basic.

  Reserved Notation "|- A"
    (at level 0, A at level 200, no associativity).

  Inductive program_logic {C} : list (term C Prop) -> term C Prop -> Prop :=

  | ProgramNode : |- forall: n,
    ^(@List.In _) <- ^n <- NodeSet

  | ProgramIR : |- forall: e,
    when[]->: ^e =>>
    (Fs' <- Fn, Fors, Fois) = ^(@request C) <- Fn <- (Fs <- Fn) <- ^e

  | ProgramII : |- forall: i, forall: e : Vector.nth (ii_events C) i,
    let ii := in_variant e in
    when<-: ^e /\
    ((Fs' <- Fn, Fors, Fois) = ^(indication C) <- Fn <- (Fs <- Fn) <- ^ii)

  | ProgramPe : |-
    when[]~> =>>
      (Fs' <- Fn, Fors, Fois) = ^(@periodic C) <- Fn <- (Fs <- Fn)

  | ProgramOR : |- forall: n,
    forall: i, forall: e : Vector.nth (or_events C) i,
    let or := in_variant e in
    on: ^n, ^(@List.In _) <- ^or <- Fors /\ self =>>
      eventually^: on: ^n, when->: ^e

  | ProgramOI : |- forall: n, forall: e,
    on: ^n, ^(@List.In _) <- ^e <- Fois /\ self =>>
      eventually^: on: ^n, when[]<-: ^e

  | ProgramOR' : |- forall: n,
    forall: i, forall: e : Vector.nth (or_events C) i,
    let or := in_variant e in
    on: ^n, when->: ^e =>>
      eventuallyp^: on: ^n, ^(@List.In _) <- ^or <- Fors /\ self

  | ProgramOI' : |- forall: n, forall: e,
    on: ^n, when[]<-: ^e =>>
      eventuallyp^: on: ^n, ^(@List.In _) <- ^e <- Fois /\ self

  | ProgramInitialize : |- forall: n,
    self: Fs <- ^n = ^(initialize C) <- ^n

  | ProgramPostPre : |- forall: s,
    self: (Fs' = ^s <=> next: Fs = ^s)

  | ProgramSEq : |- forall: n,
    Fn <> ^n =>> (Fs' <- ^n = Fs <- ^n)

  | ProgramASelf : |-
    self: always: self

  (* TODO: SInv *)

  | ProgramCSet : |- forall: n,
    Correct <- ^n <-> ^(@List.In _) <- ^n <- CorrectSet

  | ProgramAPer : |- forall: n,
    Correct <- ^n -> always: eventually: on: ^n,
      when[]~>

  | ProgramFLoss i
    (Hor : Vector.nth (or_events C) i = request_fl (node C) (message C))
    (Hii : Vector.nth (ii_events C) i = indication_fl (node C) (message C)) :
    |- forall: n, forall: n', forall: m,
    let or := (^(@Send_fl (node C) (message C)) <- ^n' <- ^m)%tlc in
    let ii := (^(@Deliver_fl (node C) (message C)) <- ^n <- ^m)%tlc in
    Correct <- ^n' ->
      always: eventually: on: ^n, when->: request_fl_or_events Hor or ->
      always: eventually: on: ^n', when<-: indication_fl_ii_events Hii ii

  | ProgramFDup i
    (Hor : Vector.nth (or_events C) i = request_fl (node C) (message C))
    (Hii : Vector.nth (ii_events C) i = indication_fl (node C) (message C)) :
    |- forall: n, forall: n', forall: m,
    let or := (^(@Send_fl (node C) (message C)) <- ^n' <- ^m)%tlc in
    let ii := (^(@Deliver_fl (node C) (message C)) <- ^n <- ^m)%tlc in
    always: eventually: on: ^n', when<-: indication_fl_ii_events Hii ii ->
    always: eventually: on: ^n, when->: request_fl_or_events Hor or

  | ProgramNForge i
    (Hor : Vector.nth (or_events C) i = request_fl (node C) (message C))
    (Hii : Vector.nth (ii_events C) i = indication_fl (node C) (message C)) :
    |- forall: n, forall: n', forall: m,
    let or := (^(@Send_fl (node C) (message C)) <- ^n' <- ^m)%tlc in
    let ii := (^(@Deliver_fl (node C) (message C)) <- ^n <- ^m)%tlc in
    (on: ^n', when<-: indication_fl_ii_events Hii ii) =>>
    eventuallyp: on: ^n, when->: request_fl_or_events Hor or

  where "|- A" := (forall X, program_logic X A).

End program_basic.

Arguments program_logic : clear implicits.

Notation "X |-p C , A" := (program_logic C X A)
  (at level 80, no associativity).

(* Derived rules of the program logic *)
Section program_derived.

  Lemma ProgramInvL'R {C} (A : term C Prop) (SA : static_term A) :
    static_term ((forall: e,
      when[]->: ^e /\
      (^(request C) <- Fn <- (Fs <- Fn) <- ^e = (Fs' <- Fn, Fors, Fois))) -> A).
  Proof. repeat econstructor. assumption. Qed.

  Lemma ProgramInvL'I {C} (A : term C Prop) (SA : static_term A) :
    static_term ((forall: i, forall: e : Vector.nth (ii_events C) i,
      let ii := in_variant e in
      when<-: ^e /\
      (^(indication C) <- Fn <- (Fs <- Fn) <- ^ii = (Fs' <- Fn, Fors, Fois))) ->
      A).
  Proof. repeat constructor. assumption. Qed.

  Lemma ProgramInvL'P {C} (A : term C Prop) (SA : static_term A) :
    static_term ((when[]~> /\
      (^(periodic C) <- Fn <- (Fs <- Fn) = (Fs' <- Fn, Fors, Fois))) ->
      A).
  Proof. repeat constructor. assumption. Qed.

  Lemma ProgramInvL {C} X (fd : flexible_denotation C) A (SA : static_term A) :
    denote_static_term fd (ProgramInvL'R SA) ->
    denote_static_term fd (ProgramInvL'I SA) ->
    denote_static_term fd (ProgramInvL'P SA) ->
    X |-p C, (self =>> A).
  Proof.
  Admitted. (* TODO *)

End program_derived.
