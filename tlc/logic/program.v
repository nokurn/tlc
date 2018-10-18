From mathcomp.ssreflect
Require Import ssreflect seq fintype.
From tlc.utility
Require Import seq.
From tlc.comp
Require Import component.
From tlc.assert
Require Import all_assert.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(* Basic rules of the program logic *)
Section basic.

  Reserved Notation "|- p"
    (at level 80, no associativity).

  Import TLC.

  Inductive program {C : component} : @prop C -> Prop :=

  | PNode : |-
    (henceforth: Atom (mem <- Fn <- Nodes))

  | PIR (e : @term C IREvent) : |-
    (event: [], Request, EventIR <- e =>>
    (Fs' <- Fn, Fors, Fois) = request <- Fn <- (Fs <- Fn) <- e)

  | PII (i : 'I_(size (@IIEvents C))) (e : @term C (ith i)) : |-
    let: ie := @Const C Nat i in
    let: ei := ini i <- e in
    (event: [ie], Indication, EventII <- ei =>>
    (Fs' <- Fn, Fors, Fois) = indication <- Fn <- (Fs <- Fn) <- ei)

  | PPe : |-
    (event: [], Periodic, per =>>
    (Fs' <- Fn, Fors, Fois) = periodic <- Fn <- (Fs <- Fn))

  | POR (n : @term C Node)
  (i : 'I_(size (@OREvents C))) (e : @term C (ith i)) : |-
    let: ie := @Const C Nat i in
    let: ei := ini i <- e in
    (on: n, (Atom (mem <- ei <- Fors) /\ self) =>>
    eventually^: on: n, event: [ie], Request, EventOR <- ei)

  | POI (n : @term C Node) (e : @term C OIEvent) : |-
    (on: n, (Atom (mem <- e <- Fois) /\ self) =>>
    eventually^: on: n, event: [], Indication, EventOI <- e)

  | POR' (n : @term C Node)
  (i : 'I_(size (@OREvents C))) (e : @term C (ith i)) : |-
    let: ie := @Const C Nat i in
    let: ei := ini i <- e in
    (on: n, event: [ie], Request, EventOR <- ei =>>
    once^: on: n, (Atom (mem <- ei <- Fors) /\ self))

  | POI' (n : @term C Node) (e : @term C OIEvent) : |-
    (on: n, event: [], Indication, EventOI <- e =>>
    once^: on: n, (Atom (mem <- e <- Fois) /\ self))

  | PInit (n : @term C Node) : |-
    (self: (Fs <- n = init <- n))

  | PPostPre (n : @term C Node) (s : @term C State) : |-
    (self: (Atom (mem <- n <- Nodes) ->
      (Fs' <- n = s <=> next: (Fs <- n = s))))

  | PSeq (n : @term C Node) : |-
    (~(Fn = n) =>> (Fs' <- n = Fs <- n))

  | PASelf : |-
    (self: henceforth: self)

  (* TODO: PSInv *)

  | PCSet (n : @term C Node) : |-
    ((Atom (correct <- n)) <-> (Atom (mem <- n <- Correct)))

  | PAPer (n : @term C Node) : |-
    ((Atom (mem <- n <- Correct)) ->
    henceforth: eventually: on: n, event: [], Periodic, per)

  | PFLoss
  (ir : 'I_(size (@OREvents C))) (ii : 'I_(size (@IIEvents C)))
  (Hr : ith ir = FLRequest) (Hi : ith ii = FLIndication)
  (n n' : @term C Node) (m : @term C Message) : |-
    let: ier := @Const C Nat ir in
    let: iei := @Const C Nat ii in
    ((Atom (correct <- n')) ->
    henceforth: eventually: on: n, event: [ier], Request,
      (EventOR <- (ini ir <- (ith_FLRequest Hr (Send_fl <- n' <- m)))) ->
    henceforth: eventually: on: n', event: [iei], Indication,
      (EventII <- (ini ii <- (ith_FLIndication Hi (Deliver_fl <- n' <- m)))))

  | PFDup
  (ir : 'I_(size (@OREvents C))) (ii : 'I_(size (@IIEvents C)))
  (Hr : ith ir = FLRequest) (Hi : ith ii = FLIndication)
  (n n' : @term C Node) (m : @term C Message) : |-
    let: ier := @Const C Nat ir in
    let: iei := @Const C Nat ii in
    (henceforth: eventually: on: n', event: [iei], Indication,
      (EventII <- (ini ii <- (ith_FLIndication Hi (Deliver_fl <- n' <- m)))) ->
    henceforth: eventually: on: n, event: [ier], Request,
      (EventOR <- (ini ir <- (ith_FLRequest Hr (Send_fl <- n' <- m)))))

  | PNForge
  (ir : 'I_(size (@OREvents C))) (ii : 'I_(size (@IIEvents C)))
  (Hr : ith ir = FLRequest) (Hi : ith ii = FLIndication)
  (n n' : @term C Node) (m : @term C Message) : |-
    let: ier := @Const C Nat ir in
    let: iei := @Const C Nat ii in
    ((on: n', event: [iei], Indication,
      (EventII <- (ini ii <-
        (ith_FLIndication Hi (Deliver_fl <- n' <- m))))) =>>
    once: on: n, event: [ier], Request,
      (EventOR <- (ini ir <- (ith_FLRequest Hr (Send_fl <- n' <- m)))))

  | PUniOR (n : @term C Node)
  (i : 'I_(size OREvents)) (e : @term C (ith i)) : |-
    let: ie := @Const C Nat i in
    let: ei := ini i <- e in
    (((occ <- ei <- Fors) <= (@Const _ Nat 1) /\
      alwaysbeen^: (Fn = n /\ self -> ~(Atom (mem <- ei <- Fors))) /\
      henceforth^: (Fn = n /\ self -> ~(Atom (mem <- ei <- Fors)))) =>>
    (on: n, event: [], Indication, EventOR <- ei) =>>
    ((alwaysbeen^: ~(on: n, event: [ie], Request, EventOR <- ei)) /\
      (henceforth^: ~(on: n, event: [ie], Request, EventOR <- ei))))

  | PUniOI (n : @term C Node) (e : @term C OIEvent) : |-
    (((occ <- e <- Fois) <= (@Const _ Nat 1) /\
      alwaysbeen^: (Fn = n /\ self -> ~(Atom (mem <- e <- Fois))) /\
      henceforth^: (Fn = n /\ self -> ~(Atom (mem <- e <- Fois)))) =>>
    (on: n, event: [], Indication, EventOI <- e) =>>
    ((alwaysbeen^: ~(on: n, event: [], Indication, EventOI <- e)) /\
      (henceforth^: ~(on: n, event: [], Indication, EventOI <- e))))

  where "|- p" := (program p).

End basic.

Notation "|-p C , p" := (@program C p)
  (at level 80, no associativity).
