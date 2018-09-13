From mathcomp.ssreflect
Require Import ssreflect eqtype ssrbool ssrfun seq.
From tlc.assert
Require Import all_assert.

Require Import comp flc.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section slc.

  Variable node : eqType.
  Variable message : eqType.

  (* Concrete requests *)
  Inductive req_sl_ : Type :=
  | Send_sl : node -> message -> req_sl_.

  (* Equality *)
  Section req_sl__eq.

    Definition eq_req_sl_ (r r' : req_sl_) :=
      match r, r' with
      | Send_sl n m, Send_sl n' m' => (n == n') && (m == m')
      end.

    Lemma eq_req_sl_P : Equality.axiom eq_req_sl_.
    Proof.
      case=> [n m]; case=> [n' m'];
        rewrite /eq_req_sl_ /=; try by constructor.
      - (* Send_sl *)
        case Hn: (n == n');
          [move/eqP: Hn => ?; subst n' | constructor];
          last by case=> ?; subst n'; rewrite eqxx in Hn.
        case Hm: (m == m');
          [move/eqP: Hm => ?; subst m' | constructor];
          last by case=> ?; subst m'; rewrite eqxx in Hm.
        by constructor.
    Qed.

    Canonical req_sl__eqMixin :=
      Eval hnf in EqMixin eq_req_sl_P.
    Canonical req_sl__eqType :=
      Eval hnf in EqType req_sl_ req_sl__eqMixin.

    Definition req_sl := [eqType of req_sl_].

  End req_sl__eq.

  (* Assertion requests *)
  Inductive req_sl_A_ : Type :=
  | Send_sl_A : node_variable -> message_variable -> req_sl_A_.

  (* Equality *)
  Section req_sl_A__eq.

    Definition eq_req_sl_A_ (r r' : req_sl_A_) :=
      match r, r' with
      | Send_sl_A n m, Send_sl_A n' m' => (n == n') && (m == m')
      end.

    Lemma eq_req_sl_A_P : Equality.axiom eq_req_sl_A_.
    Proof.
      case=> [n m]; case=> [n' m'];
        rewrite /eq_req_sl_A_ /=; try by constructor.
      - (* Send_sl_A *)
        case Hn: (n == n');
          [move/eqP: Hn => ?; subst n' | constructor];
          last by case=> ?; subst n'; rewrite eqxx in Hn.
        case Hm: (m == m');
          [move/eqP: Hm => ?; subst m' | constructor];
          last by case=> ?; subst m'; rewrite eqxx in Hm.
        by constructor.
    Qed.

    Canonical req_sl_A__eqMixin :=
      Eval hnf in EqMixin eq_req_sl_A_P.
    Canonical req_sl_A__eqType :=
      Eval hnf in EqType req_sl_A_ req_sl_A__eqMixin.

    Definition req_sl_A := [eqType of req_sl_A_].

  End req_sl_A__eq.

  (* Concrete indications *)
  Inductive ind_sl_ : Type :=
  | Deliver_sl : node -> message -> ind_sl_.

  (* Equality *)
  Section ind_sl__eq.

    Definition eq_ind_sl_ (r r' : ind_sl_) :=
      match r, r' with
      | Deliver_sl n m, Deliver_sl n' m' => (n == n') && (m == m')
      end.

    Lemma eq_ind_sl_P : Equality.axiom eq_ind_sl_.
    Proof.
      case=> [n m]; case=> [n' m'];
        rewrite /eq_ind_sl_ /=; try by constructor.
      - (* Deliver_sl *)
        case Hn: (n == n');
          [move/eqP: Hn => ?; subst n' | constructor];
          last by case=> ?; subst n'; rewrite eqxx in Hn.
        case Hm: (m == m');
          [move/eqP: Hm => ?; subst m' | constructor];
          last by case=> ?; subst m'; rewrite eqxx in Hm.
        by constructor.
    Qed.

    Canonical ind_sl__eqMixin :=
      Eval hnf in EqMixin eq_ind_sl_P.
    Canonical ind_sl__eqType :=
      Eval hnf in EqType ind_sl_ ind_sl__eqMixin.

    Definition ind_sl := [eqType of ind_sl_].

  End ind_sl__eq.

  (* Assertion indications *)
  Inductive ind_sl_A_ : Type :=
  | Deliver_sl_A : node_variable -> message_variable -> ind_sl_A_.

  (* Equality *)
  Section ind_sl_A__eq.

    Definition eq_ind_sl_A_ (r r' : ind_sl_A_) :=
      match r, r' with
      | Deliver_sl_A n m, Deliver_sl_A n' m' => (n == n') && (m == m')
      end.

    Lemma eq_ind_sl_A_P : Equality.axiom eq_ind_sl_A_.
    Proof.
      case=> [n m]; case=> [n' m'];
        rewrite /eq_ind_sl_A_ /=; try by constructor.
      - (* Deliver_sl_A *)
        case Hn: (n == n');
          [move/eqP: Hn => ?; subst n' | constructor];
          last by case=> ?; subst n'; rewrite eqxx in Hn.
        case Hm: (m == m');
          [move/eqP: Hm => ?; subst m' | constructor];
          last by case=> ?; subst m'; rewrite eqxx in Hm.
        by constructor.
    Qed.

    Canonical ind_sl_A__eqMixin :=
      Eval hnf in EqMixin eq_ind_sl_A_P.
    Canonical ind_sl_A__eqType :=
      Eval hnf in EqType ind_sl_A_ ind_sl_A__eqMixin.

    Definition ind_sl_A := [eqType of ind_sl_A_].

  End ind_sl_A__eq.

  (* State *)
  Definition slc_state := seq (prod node message).

  (* Component *)
  Definition slc_subcomps :=
    [:: Subcomp (req_fl node message)
                (ind_fl node message)].
  Definition slc :=
    let flc := 0 in
    let slc_init n := [::] in
    let slc_request n s ir :=
      match ir with
      | Send_sl n' m =>
        ((n', m) :: s, [:: Send_fl n' m], [::])
      end in
    let slc_indication n' s ii :=
      match ii with
      | Deliver_fl n m =>
        (s, [::], [:: Deliver_sl n m])
      end in
    let slc_periodic n s :=
      let ors := [seq Send_fl p.1 p.2 | p <- s] in
      (s, ors, [::]) in
    @Comp node req_sl ind_sl slc_subcomps
      slc_state slc_init
      slc_request slc_indication slc_periodic.

  (* Specification *)
  Section spec.

    Import AssertNotations.

    Local Notation Vrn' := (first_node_var).

    (* Non-compiling
    (* SL_1: Stubborn delivery *)
    Definition SL_1 :=
      ((Pcorrect?(Vrn)) /\ (Pcorrect?(Vrn')) ->
      (on: Vrn, ev: [], Creq_ev, (Send_sl_A Vrn' Vrm) =>
       alwaysf: eventf: on: Vrn', ev: [], Cind_ev, (Deliver_sl_A Vrn Vrm)))%A.

    (* SL_2: No-forge *)
    Definition SL_2 :=
      (on: Vrn, ev: [], Cind_ev, (Deliver_sl_A Vrn' Vrm) <~
      on: Vrn', ev: [], Creq_ev, (Send_sl_A Vrn Vrm))%A.
    *)

  End spec.

End slc.
