(******************************************************************************)
(** * Lemmas about traces (finite or infinite sequences) *)
(******************************************************************************)

Require Import HahnBase HahnList HahnSets HahnOmega.
Require Import Omega IndefiniteDescription.

Set Implicit Arguments.

Lemma set_infinite_natE (s : nat -> Prop) (INF: ~ set_finite s) n :
  exists m, s m /\ length (filterP s (seq 0 m)) = n.
Proof.
  assert (IMP: forall findom, exists x, s x /\ ~ In x findom).
  { unfold set_finite in *; apply NNPP; intro X; clarify_not.
    eapply INF; eexists; ins; apply NNPP; intro Y; eauto. }
  apply functional_choice in IMP; destruct IMP as [nin IMP].
  assert (exists m, s m /\ n <= length (filterP s (seq 0 m))).
  { induction n; desf.
    1: exists (nin nil); split; [apply IMP | omega].
    exists (nin (seq 0 (S m))); split; [apply IMP|].
    rewrite seq_split0 with (a := m).
    rewrite filterP_app, length_app; ins; desf; ins; omega.
    specialize (IMP (seq 0 (S m))); desf.
    rewrite in_seq0_iff in IMP0; omega. }
  desf; rewrite Nat.le_lteq in *; desf; eauto.
  clear - H0; induction m; ins.
  replace (seq 0 0) with (@nil nat) in H0; ins; omega.
  replace (S m) with (m + 1) in H0; try omega.
  rewrite seq_add, filterP_app, length_app in H0; ins.
  replace (seq m 1) with (m :: nil) in H0; ins; desf; ins.
  1: rewrite Nat.add_1_r, Nat.lt_succ_r, Nat.le_lteq in *; desf; eauto.
  rewrite Nat.add_0_r in *; eauto.
Qed.

(** Prepend a finite list to an infinite sequence *)

Definition trace_prepend A (l : list A) (fl : nat -> A) n :=
  if Nat.ltb n (length l) then nth n l (fl 0)
  else fl (n - length l).


(******************************************************************************)
(** Lemmas about [trace_prepend] *)
(******************************************************************************)

Lemma trace_prepend_fst A (l: list A) fl n (LT : n < length l) :
  trace_prepend l fl n = nth n l (fl 0).
Proof.
  unfold trace_prepend; desf; f_equal; omega.
Qed.

Lemma trace_prepend_fst0 A (l: list A) fl x :
  trace_prepend (x :: l) fl 0 = x.
Proof.
  ins.
Qed.

Lemma trace_prepend_snd A (l: list A) fl n :
  trace_prepend l fl (length l + n) = fl n.
Proof.
  unfold trace_prepend; desf; f_equal; omega.
Qed.

Lemma trace_prepend_snd0 A (l: list A) fl :
  trace_prepend l fl (length l) = fl 0.
Proof.
  unfold trace_prepend; desf; f_equal; omega.
Qed.

Lemma trace_prepend_app A (l l' : list A) fl :
  trace_prepend (l ++ l') fl = trace_prepend l (trace_prepend l' fl).
Proof.
  unfold trace_prepend; extensionality n.
  rewrite length_app, nth_app; desf; try omega.
  all: first [apply nth_indep | f_equal]; omega.
Qed.

Hint Rewrite
     filterP_app
     length_app
     trace_prepend_fst0
     trace_prepend_snd
     trace_prepend_snd0
     trace_prepend_app : trace_prepends.

Lemma map_trace_prepend_geq A (l: list A) fl n (LT: length l <= n) :
  map (trace_prepend l fl) (seq 0 n) =
    l ++ map fl (seq 0 (n - length l)).
Proof.
  unfold trace_prepend.
  rewrite seq_split with (x := length l); ins.
  rewrite map_app.
  rewrite map_nth_seq with (d := fl 0); [|by ins; desf].
  rewrite map_seq_shift with (g := fl) (b := 0); ins.
  desf; try f_equal; omega.
Qed.

Lemma map_trace_prepend_lt A (l: list A) fl n (LT: n < length l) :
  exists l' a l'',
    l = l' ++ a :: l'' /\ length l' = n /\
    map (trace_prepend l fl) (seq 0 n) = l'.
Proof.
  unfold trace_prepend.
  destruct (Nat.le_exists_sub n (length l)) as (p & X & _);
    try omega.
      rewrite Nat.add_comm in X.
  apply length_eq_add in X; desf.
  rewrite length_app in *; destruct l''; ins; try omega.
  repeat eexists.
  eapply map_nth_seq with (d := fl 0); ins; desf; try omega.
  rewrite nth_app; desf; try omega.
Qed.


Lemma set_finite_prepend A (l : list A) (fl : nat -> A) (f : A -> Prop) :
  set_finite (set_map (trace_prepend l fl) f) <-> set_finite (set_map fl f).
Proof.
  unfold trace_prepend, set_finite, set_map.
  split; ins; desf.
  { exists (map (fun x => x - length l) findom); intro y; ins.
    rewrite in_map_iff.
    specialize (H (y + length l)); desf; eauto; try omega.
    exists (y + length l); rewrite Nat.add_sub in *; eauto. }
  { exists (seq 0 (length l) ++ map (fun x => x + length l) findom);
    intro y; ins.
    rewrite in_app_iff, in_seq0_iff, in_map_iff; desf; eauto.
    apply H in IN.
    right; eexists; split; eauto; omega.
  }
Qed.

(******************************************************************************)
(** Finite or infinite traces of [A] elements. *)
(******************************************************************************)

Inductive trace (A : Type) : Type :=
| trace_fin (l : list A)
| trace_inf (fl : nat -> A).

(** [trace_app] concatenates two traces *)

Definition trace_app A (t t' : trace A) :=
  match t, t' with
  | trace_fin l, trace_fin l' => trace_fin (l ++ l')
  | trace_fin l, trace_inf f =>
    trace_inf (trace_prepend l f)
  | trace_inf f, _ => trace_inf f
  end.

(** [trace_map f t] applies [f] to all the elements of [t] *)

Definition trace_map A B (f : A -> B) (t : trace A) : trace B :=
  match t with
  | trace_fin l => trace_fin (map f l)
  | trace_inf fl => trace_inf (fun x => f (fl x))
  end.

(** Returns the length of a trace *)

Definition trace_length A (t : trace A) : nat_omega :=
  match t with
  | trace_fin l => NOnum (length l)
  | trace_inf fl => NOinfinity
  end.

(** [trace_in a t] returns true iff [a] is an element of the trace [t] *)

Definition trace_in A (a : A) (t : trace A) :=
  match t with
  | trace_fin l => In a l
  | trace_inf fl => exists n, a = fl n
  end.

(** [trace_nth n t d] returns the [n]th element of trace [t]
   or the default element [d], if [n] exceeds the trace's length. *)

Definition trace_nth (n : nat) A (t : trace A) (d : A) : A :=
  match t with
  | trace_fin l => nth n l d
  | trace_inf fl => fl n
  end.

(** [trace_filter f t] returns the sub-trace of [t] whose elements
satisfy the predicate [f]. *)

Definition trace_filter A (f : A -> Prop) (t : trace A) : trace A :=
  match t with
  | trace_fin l => trace_fin (filterP f l)
  | trace_inf fl =>
    let s := excluded_middle_informative (set_finite (set_map fl f)) in
    match s with
    | left FIN =>
        let B := set_finite_nat_bounded FIN in
        let n := proj1_sig (constructive_indefinite_description _ B) in
        trace_fin (filterP f (map fl (seq 0 (S n))))
    | right INF =>
        trace_inf
          (fun n =>
           let H := set_infinite_natE INF n in
           let H0 := constructive_indefinite_description _ H in
           fl (proj1_sig H0))
    end
  end.

(** Is a trace a prefix of another trace? *)

Definition trace_prefix A (t t' : trace A) :=
  match t, t' with
  | trace_fin l, trace_fin l' => exists l'', l' = l ++ l''
  | trace_fin l, trace_inf f => forall i (LLEN: i < length l) d, f i = nth i l d
  | trace_inf f, trace_fin _ => False
  | trace_inf f, trace_inf f' => forall x, f x = f' x
  end.

(******************************************************************************)
(** Basic lemmas *)
(******************************************************************************)

Lemma trace_nth_indep (n : nat) A (t : trace A)
      (LT : NOmega.lt_nat_l n (trace_length t)) (d d' : A) :
  trace_nth n t d = trace_nth n t d'.
Proof.
  destruct t; ins; desf; auto using nth_indep.
Qed.

Lemma trace_length_app A (t t' : trace A) :
  trace_length (trace_app t t') =
  NOmega.add (trace_length t) (trace_length t').
Proof.
  destruct t, t'; ins; auto using length_app.
Qed.

Lemma trace_in_app A (a : A) (t t' : trace A) :
  trace_in a (trace_app t t') <->
  trace_in a t \/ trace_length t <> NOinfinity /\ trace_in a t'.
Proof.
  split; destruct t, t'; ins; unfold trace_prepend in *;
    desf; rewrite ?in_app_iff in *; desf;
    eauto using nth_In; vauto.
  all: try solve [right; split; ins; eauto].
  apply In_nth with (d := fl 0) in H; desf; exists n; desf; ins.
  exists (n + length l); desf; try f_equal; omega.
Qed.

Lemma trace_nth_app (n : nat) A (t t' : trace A) (d : A) :
  trace_nth n (trace_app t t') d =
  ifP NOmega.lt_nat_l n (trace_length t) then trace_nth n t d
  else trace_nth (NOmega.sub_nat_l n (trace_length t)) t' d.
Proof.
  destruct t, t'; ins; unfold trace_prepend in *;
    desf; try rewrite app_nth; desf;
      auto using nth_indep; omega.
Qed.

Lemma trace_in_map A (a : A) B (f : B -> A) (t : trace B) :
  trace_in a (trace_map f t) <-> exists x, trace_in x t /\ f x = a.
Proof.
  destruct t; ins; try rewrite in_map_iff; split; ins; desf; eauto.
Qed.

Lemma trace_nth_map (n : nat) A (a : A) B (f : B -> A) (t : trace B) d :
  trace_nth n (trace_map f t) (f d) = f (trace_nth n t d).
Proof.
  destruct t; ins; apply map_nth.
Qed.

Lemma trace_in_filter A (a : A) (f : A -> Prop) (t : trace A) :
  trace_in a (trace_filter f t) <-> trace_in a t /\ f a.
Proof.
  destruct t; ins; desf; ins; rewrite ?in_filterP_iff, ?in_map_iff; ins.
  all: split; ins; desf; splits; eauto.
  all: try (eexists; try split; ins).
  all: destruct (constructive_indefinite_description); ins; desf.
  { in_simp; apply l in H0; omega. }
  revert a0.
  instantiate (1 := length (filterP (fl ↓₁ f) (seq 0 n0))).
  destruct (lt_eq_lt_dec x n0) as [[LT|]|LT]; desf.
  unfold set_map.
  all: rewrite (seq_split0 LT), filterP_app, length_app;
    ins; desf; ins; omega.
Qed.


Lemma trace_filter_app A (f : A -> Prop) (t t' : trace A)
      (IMP: trace_length (trace_filter f t) <> NOinfinity ->
            trace_length t <> NOinfinity) :
  trace_filter f (trace_app t t') =
  trace_app (trace_filter f t)
            (trace_filter f t').
Proof.
  destruct t; ins; desf; ins; desf.
  all: try solve [destruct IMP; ins]; clear IMP.
  all: repeat destruct (constructive_indefinite_description); ins; desf.
  all: try solve [exfalso; rewrite set_finite_prepend in *; ins].
    by rewrite filterP_app in *.
  { unfold set_map in *.
    destruct (le_lt_dec (length l) (S x)).
    - rewrite map_trace_prepend_geq; ins.
      unfold trace_prepend in *.
      rewrite filterP_app.
      do 2 f_equal.
      eapply filterP_map_seq_eq; simpl; eauto.
      ins; forward apply (l0 (length l + i)); desf; try omega.
        by rewrite minus_plus.
      ins; eapply l1 in H; omega.
    - eapply map_trace_prepend_lt with (fl := fl) in l2; desf.
      rewrite l4, filterP_app, appA; clear l4.
      f_equal.
      symmetry; rewrite app_eq_prefix, app_eq_nil, ?filterP_eq_nil.
      remember (a :: l'') as l; clear a l'' Heql.
      split; ins.
      apply in_split in IN; desf.
        forward apply (l0 (length l' + length l2)); try omega.
        by autorewrite with trace_prepends.
      in_simp.
      forward apply (l0 (length l' + (length l + x2))); try omega.
      by autorewrite with trace_prepends.
  }
  { f_equal; extensionality y; ins.
    destruct (constructive_indefinite_description); ins; desf.
    erewrite <- length_map, <- filterP_map.
    destruct (le_lt_dec (length l) x) as [LE|LT].
    { rewrite map_trace_prepend_geq; ins.
      autorewrite with trace_prepends.
      rewrite filterP_map, length_map.
      destruct (constructive_indefinite_description); ins; desf.
      unfold set_map, trace_prepend in *; desf; try omega.
      destruct (lt_eq_lt_dec (x - length l) x0) as [[LT|]|LT]; desf;
      apply seq_split0 in LT; rewrite LT in *;
        exfalso; revert a1; rewrite ?map_app, ?filterP_app, ?length_app;
          ins; desf; ins; omega. }
    eapply map_trace_prepend_lt with (fl := fl) in LT; desf.
    rewrite filterP_app, LT1; red in a.
    autorewrite with trace_prepends in *; ins; desf.
  }
Qed.


Lemma trace_prefix_app A (t t' : trace A) :
  trace_prefix t (trace_app t t').
Proof.
  destruct t, t'; ins; unfold trace_prepend;
    desf; eauto using nth_indep; done.
Qed.

Lemma trace_prefixE A (t t' : trace A) :
  trace_prefix t t' <-> exists t'', t' = trace_app t t''.
Proof.
  split; ins; desf; eauto using trace_prefix_app.
  destruct t, t'; ins; desf; desf.
  - by eexists (trace_fin _).
  - exists (trace_inf (fun x => fl (x + length l))).
    unfold trace_prepend; f_equal; extensionality y; desf; eauto.
    f_equal; omega.
  - exists (trace_fin nil); f_equal; extensionality x; eauto.
Qed.


Lemma trace_prefix_refl A (t : trace A) :
  trace_prefix t t.
Proof.
  destruct t; ins; eauto using app_nil_end.
Qed.

Lemma trace_prefix_trans A (t t' t'' : trace A) :
  trace_prefix t t' ->
  trace_prefix t' t'' ->
  trace_prefix t t''.
Proof.
  destruct t, t', t''; ins; desf; try rewrite <- H0; eauto.
    by rewrite appA; vauto.
  forward apply H0 with (i := i) (d := d);
    rewrite ?length_app, ?nth_app;
    ins; desf; omega.
Qed.


Lemma trace_appA A (t t' t'' : trace A) :
  trace_app (trace_app t t') t'' = trace_app t (trace_app t' t'').
Proof.
  unfold trace_app; ins; desf; try by rewrite appA.
  all: f_equal; extensionality x; desf.
  by rewrite trace_prepend_app.
Qed.

Lemma trace_app_assoc A (t t' t'' : trace A) :
  trace_app t (trace_app t' t'') = trace_app (trace_app t t') t''.
Proof.
  symmetry; apply trace_appA.
Qed.


(** Labelled transition system (LTS) *)

Record LTS (State Label : Type) : Type :=
  { LTS_init : State -> Prop ;
    LTS_final : State -> Prop ;
    LTS_step : State -> Label -> State -> Prop }.

Section LTS_traces.

  Variable State : Type.
  Variable Label : Type.
  Variable lts : LTS State Label.

  (** Traces generated by a labelled transition system *)

  Definition LTS_trace (t : trace Label) :=
    match t with
    | trace_fin l =>
      exists fl', LTS_init lts (fl' 0) /\
                  forall i (LLEN : i < length l) d,
                    LTS_step lts (fl' i) (nth i l d) (fl' (S i))
    | trace_inf fl =>
      exists fl', LTS_init lts (fl' 0) /\
                  forall i, LTS_step lts (fl' i) (fl i) (fl' (S i))
    end.

  Definition LTS_complete_trace (t : trace Label) :=
    match t with
    | trace_fin l =>
      exists fl', LTS_init lts (fl' 0) /\
                  LTS_final lts (fl' 0) /\
                  forall i (LLEN : i < length l) d,
                    LTS_step lts (fl' i) (nth i l d) (fl' (S i))
    | trace_inf fl =>
      exists fl', LTS_init lts (fl' 0) /\
                  forall i, LTS_step lts (fl' i) (fl i) (fl' (S i))
    end.

  Lemma LTS_complete_trace_weaken t :
    LTS_complete_trace t -> LTS_trace t.
  Proof.
    destruct t; ins; desf; eauto.
  Qed.

  Lemma LTS_trace_prefix_closed t t' :
    LTS_trace t' -> trace_prefix t t' -> LTS_trace t.
  Proof.
    destruct t, t'; ins; desf; exists fl'; splits; ins.
    all: specialize (H1 i); rewrite ?length_app in *.
    all: specialize_full H1; try omega.
    all: try rewrite nth_app in *; desf; eauto; try omega.
    rewrite <- H0; ins.
    rewrite H0; ins.
  Qed.

End LTS_traces.
