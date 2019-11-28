(******************************************************************************)
(** * Lemmas about lists and permutations *)
(******************************************************************************)

Require Import HahnBase HahnSets.
Require Import Omega Setoid Morphisms Sorted.
Require Export List Permutation.

Set Implicit Arguments.

(** This file contains a number of basic definitions and lemmas about lists
    that are missing from the standard library, and a few properties of
    classical logic. *)

(** Very basic lemmas *)
(******************************************************************************)

Definition appA := app_ass.
Definition length_nil A : length (@nil A) = 0 := eq_refl. 
Definition length_cons A (a: A) l : length (a :: l) = S (length l) := eq_refl. 
Definition length_app := app_length.
Definition length_rev := rev_length.
Definition length_map := map_length.
Definition length_combine := combine_length.
Definition length_prod := prod_length.
Definition length_firstn := firstn_length.
Definition length_seq := seq_length.
Definition length_repeat := repeat_length.

Hint Rewrite length_nil length_cons length_app length_rev length_map : calc_length.
Hint Rewrite length_combine length_prod length_firstn length_seq  : calc_length.
Hint Rewrite length_repeat : calc_length.

Lemma in_cons_iff A (a b : A) l : In b (a :: l) <-> a = b \/ In b l.
Proof. done. Qed.

Lemma in_app_l A (a : A) l l' : In a l -> In a (l ++ l').
Proof. eauto using in_or_app. Qed.

Lemma in_app_r A (a : A) l l' : In a l' -> In a (l ++ l').
Proof. eauto using in_or_app. Qed.

Hint Resolve in_app_l in_app_r in_cons in_eq : hahn.

Lemma In_split2 :
  forall A (x: A) l (IN: In x l),
  exists l1 l2, l = l1 ++ x :: l2 /\ ~ In x l1.
Proof.
  induction l; ins; desf; [by eexists nil; ins; eauto|].
  destruct (classic (a = x)); desf; [by eexists nil; ins; eauto|].
  apply IHl in IN; desf; eexists (_ :: _); repeat eexists; ins; intro; desf.
Qed.

Lemma map_eq_app_inv A B (f : A -> B) l l1 l2 :
  map f l = l1 ++ l2 ->
  exists l1' l2', l = l1' ++ l2' /\ map f l1' = l1 /\ map f l2' = l2.
Proof.
  revert l1; induction l; ins.
    by destruct l1, l2; ins; eexists nil, nil.
  destruct l1; ins; desf.
    by eexists nil,_; ins.
  eapply IHl in H; desf; eexists (_ :: _), _; split; ins.
Qed.

Lemma app_nth A n l l' (d : A) :
  nth n (l ++ l') d =
  if le_lt_dec (length l) n then nth (n - length l) l' d else nth n l d.
Proof.
  desf; eauto using app_nth1, app_nth2.
Qed.

Definition nth_app := app_nth. 

(** List filtering *)
(******************************************************************************)

Lemma in_filter_iff A l f (x : A) : In x (filter f l) <-> In x l /\ f x.
Proof.
  induction l; ins; try tauto.
  des_if; ins; rewrite IHl; split; ins; desf; eauto.
Qed.

Lemma filter_app A f (l l' : list A) :
  filter f (l ++ l') = filter f l ++ filter f l'.
Proof.
  induction l; ins; desf; ins; congruence.
Qed.

Lemma Permutation_filter A (l l' : list A) (P: Permutation l l') f :
  Permutation (filter f l) (filter f l').
Proof.
  induction P; ins; desf; vauto.
Qed.

Add Parametric Morphism A : (@filter A) with
  signature eq ==> (@Permutation A) ==> (@Permutation A)
      as filter_mor.
Proof.
  by ins; apply Permutation_filter.
Qed.

(** List filtering with a [Prop]-predicate *)
(******************************************************************************)

Fixpoint filterP A (f: A -> Prop) l :=
  match l with
    | nil => nil
    | x :: l => if excluded_middle_informative (f x) then 
                  x :: filterP f l 
                else filterP f l
  end.

Lemma in_filterP_iff A (x : A) f l :
  In x (filterP f l) <-> In x l /\ f x.
Proof.
  induction l; ins; desf; ins; try (rewrite IHn; clear IHn);
  intuition; desf; eauto.
Qed.

Lemma filterP_app A f (l l' : list A) :
  filterP f (l ++ l') = filterP f l ++ filterP f l'.
Proof.
  induction l; ins; desf; ins; congruence.
Qed.

Lemma filterP_set_equiv A (f f' : A -> Prop) (EQ: f ≡₁ f') (l : list A) :
  filterP f l = filterP f' l.
Proof.
  induction l; ins; desf; f_equal; firstorder. 
Qed.

Lemma Permutation_filterP A (l l' : list A) (P: Permutation l l') f :
  Permutation (filterP f l) (filterP f l').
Proof.
  induction P; ins; desf; vauto.
Qed.

Lemma Permutation_filterP2 A f f' (EQ: f ≡₁ f') l l' (P: Permutation (A:=A) l l') :
  Permutation (filterP f l) (filterP f' l').
Proof.
  replace (filterP f' l') with (filterP f l'); 
    auto using Permutation_filterP, filterP_set_equiv. 
Qed.

Instance filterP_Proper A : Proper (_ ==> _ ==> _) _ := Permutation_filterP2 (A:=A).


Lemma filterP_eq_nil A f (l: list A): 
  filterP f l = nil <-> forall x (IN: In x l) (COND: f x), False.
Proof.
  split; ins.
  * enough (In x nil) by done.
    rewrite <- H; apply in_filterP_iff; eauto.
  * induction l; ins; desf; eauto; exfalso; eauto.
Qed.
    
Lemma filterP_eq_cons A f (l l': list A) x: 
  filterP f l = x :: l' -> 
  f x /\ 
  exists p p', 
    l = p ++ x :: p' /\ 
    (forall x (IN: In x p) (COND: f x), False) /\
    l' = filterP f p'.
Proof.
  induction l; ins; desf. 
    by splits; ins; eexists nil; eexists; splits; ins; desf; eauto.
  eapply IHl in H; desc; splits; ins; desf. 
  eexists (_ :: _); eexists; splits; ins; desf; eauto.
Qed.


(** List flattening *)
(******************************************************************************)

Fixpoint flatten A (l: list (list A)) :=
  match l with
    | nil => nil
    | x :: l' => x ++ flatten l'
  end.

Lemma in_flatten_iff A (x: A) ll :
  In x (flatten ll) <-> exists l, In l ll /\ In x l.
Proof.
  induction ll; ins.
    by split; ins; desf.
  rewrite in_app_iff, IHll; clear; split; ins; desf; eauto.
Qed.

Lemma flatten_app A (l l' : list (list A)) :
  flatten (l ++ l') = flatten l ++ flatten l'.
Proof.
  by induction l; ins; desf; ins; rewrite appA, IHl.
Qed.


(** List disjointness *)
(******************************************************************************)

Definition disjoint A (l1 l2 : list A) :=
  forall a (IN1: In a l1) (IN2: In a l2), False.


(** Remove duplicate list elements (classical) *)
(******************************************************************************)

Fixpoint undup A (l: list A) :=
  match l with nil => nil
    | x :: l =>
      if excluded_middle_informative (In x l) then undup l else x :: undup l
  end.

(** Lemmas about [NoDup] and [undup] *)
(******************************************************************************)

Lemma nodup_one A (x: A) : NoDup (x :: nil).
Proof. vauto. Qed.

Hint Resolve NoDup_nil nodup_one : core hahn.

Lemma nodup_map:
  forall (A B: Type) (f: A -> B) (l: list A),
  NoDup l ->
  (forall x y, In x l -> In y l -> x <> y -> f x <> f y) ->
  NoDup (map f l).
Proof.
  induction 1; ins; vauto.
  constructor; eauto.
  intro; rewrite in_map_iff in *; desf.
  edestruct H1; try eapply H2; eauto.
  intro; desf.
Qed.

Lemma nodup_append_commut:
  forall (A: Type) (a b: list A),
  NoDup (a ++ b) -> NoDup (b ++ a).
Proof.
  intro A.
  assert (forall (x: A) (b: list A) (a: list A),
           NoDup (a ++ b) -> ~(In x a) -> ~(In x b) ->
           NoDup (a ++ x :: b)).
    induction a; simpl; intros.
    constructor; auto.
    inversion H. constructor. red; intro.
    elim (in_app_or _ _ _ H6); intro.
    elim H4. apply in_or_app. tauto.
    elim H7; intro. subst a. elim H0. left. auto.
    elim H4. apply in_or_app. tauto.
    auto.
  induction a; simpl; intros.
  rewrite <- app_nil_end. auto.
  inversion H0. apply H. auto.
  red; intro; elim H3. apply in_or_app. tauto.
  red; intro; elim H3. apply in_or_app. tauto.
Qed.

Lemma nodup_cons A (x: A) l:
  NoDup (x :: l) <-> ~ In x l /\ NoDup l.
Proof. split; inversion 1; vauto. Qed.

Lemma nodup_app:
  forall (A: Type) (l1 l2: list A),
  NoDup (l1 ++ l2) <->
  NoDup l1 /\ NoDup l2 /\ disjoint l1 l2.
Proof.
  induction l1; ins.
    by split; ins; desf; vauto.
  rewrite !nodup_cons, IHl1, in_app_iff; unfold disjoint.
  ins; intuition (subst; eauto).
Qed.

Lemma nodup_append:
  forall (A: Type) (l1 l2: list A),
  NoDup l1 -> NoDup l2 -> disjoint l1 l2 ->
  NoDup (l1 ++ l2).
Proof.
  generalize nodup_app; firstorder.
Qed.

Lemma nodup_append_right:
  forall (A: Type) (l1 l2: list A),
  NoDup (l1 ++ l2) -> NoDup l2.
Proof.
  generalize nodup_app; firstorder.
Qed.

Lemma nodup_append_left:
  forall (A: Type) (l1 l2: list A),
  NoDup (l1 ++ l2) -> NoDup l1.
Proof.
  generalize nodup_app; firstorder.
Qed.

Lemma nodup_filter A (l: list A) (ND: NoDup l) f : NoDup (filter f l).
Proof.
  induction l; ins; inv ND; desf; eauto using NoDup.
  econstructor; eauto; rewrite in_filter_iff; tauto.
Qed.

Lemma nodup_filterP A (l: list A) (ND: NoDup l) f : NoDup (filterP f l).
Proof.
  induction l; ins; inv ND; desf; eauto using NoDup.
  econstructor; eauto; rewrite in_filterP_iff; tauto.
Qed.

Hint Resolve nodup_filter nodup_filterP : core hahn.

Lemma Permutation_nodup A ( l l' : list A) :
  Permutation l l' -> NoDup l -> NoDup l'.
Proof.
  induction 1; eauto; rewrite !nodup_cons in *; ins; desf; intuition.
  eby symmetry in H; eapply H0; eapply Permutation_in.
Qed.

Lemma nodup_eq_one A (x : A) l :
   NoDup l -> In x l -> (forall y (IN: In y l), y = x) -> l = x :: nil.
Proof.
  destruct l; ins; f_equal; eauto.
  inv H; desf; clear H H5; induction l; ins; desf; case H4; eauto using eq_sym.
  rewrite IHl in H0; ins; desf; eauto.
Qed.

Lemma nodup_consD A (x : A) l : NoDup (x :: l) -> NoDup l.
Proof. inversion 1; desf. Qed.

Lemma nodup_mapD A B (f : A-> B) l : NoDup (map f l) -> NoDup l.
Proof.
  induction l; ins; rewrite !nodup_cons, in_map_iff in *; desf; eauto 8.
Qed.

Lemma In_NoDup_Permutation A (a : A) l (IN: In a l) (ND : NoDup l) :
  exists l', Permutation l (a :: l') /\ ~ In a l'.
Proof.
  induction l; ins; desf; inv ND; eauto.
  destruct IHl as (l' & ? & ?); eauto.
  destruct (classic (a0 = a)); desf.
  eexists (a0 :: l'); split; try red; ins; desf.
  eapply Permutation_trans, perm_swap; eauto.
Qed.

Lemma in_undup_iff A (x : A) (l : list A) : In x (undup l) <-> In x l.
Proof. induction l; split; ins; desf; ins; desf; eauto. Qed.

Lemma nodup_undup A (l : list A) : NoDup (undup l).
Proof. induction l; ins; desf; constructor; rewrite ?in_undup_iff in *; eauto. Qed.

Hint Resolve nodup_undup : core hahn.

Lemma undup_nodup A (l : list A) : NoDup l -> undup l = l.
Proof. induction 1; ins; desf; congruence. Qed.

Lemma undup_nonnil A (l : list A) : l <> nil -> undup l <> nil.
Proof.
  induction l; ins; desf.
  by eapply in_undup_iff in i; intro X; rewrite X in *.
Qed.

Lemma Permutation_undup A (l l' : list A) :
  Permutation l l' -> Permutation (undup l) (undup l').
Proof.
  ins; eapply NoDup_Permutation; ins; rewrite !in_undup_iff.
  split; eauto using Permutation_in, Permutation_sym.
Qed.

Lemma in_split_perm A (x : A) l (IN: In x l) :
  exists l', Permutation l (x :: l').
Proof.
  induction l; ins; intuition; desf; eauto.
  exists (a :: l'); rewrite H0; vauto.
Qed.

Lemma NoDup_eq_simpl A l1 (a : A) l1' l2 l2'
      (ND : NoDup (l1 ++ a :: l1'))
      (L : l1 ++ a :: l1' = l2 ++ a :: l2') :
      l1 = l2 /\ l1' = l2'.
Proof.
  revert l2 L; induction l1; ins; destruct l2; ins; desf.
    by exfalso; inv ND; eauto using in_or_app, in_eq, in_cons.
    by exfalso; inv ND; eauto using in_or_app, in_eq, in_cons.
  inv ND; eapply IHl1 in H0; desf.
Qed.


(** Lemmas about list concatenation *)
(******************************************************************************)

Lemma in_concat_iff A (a: A) ll :
  In a (concat ll) <-> exists l, In a l /\ In l ll.
Proof.
  induction ll; ins; [by split; ins; desf|].
  rewrite in_app_iff, IHll; split; ins; desf; eauto.
Qed.

Lemma in_concat A (a: A) l ll :
  In a l ->
  In l ll ->
  In a (concat ll).
Proof.
  rewrite in_concat_iff; eauto.
Qed.

Add Parametric Morphism X : (@concat X) with
  signature (@Permutation (list X)) ==> (@Permutation X)
      as concat_more.
Proof.
  induction 1; rewrite ?concat_cons,  ?app_assoc;
  eauto using Permutation, Permutation_app, Permutation_app_comm.
Qed.

Lemma NoDup_concat_simpl A (a : A) l1 l2 ll
      (ND: NoDup (concat ll))
      (K: In l1 ll) (K' : In a l1)
      (L: In l2 ll) (L' : In a l2) :
      l1 = l2.
Proof.
  apply in_split_perm in K; desc; rewrite K, concat_cons, nodup_app in *; ins; desf.
  edestruct ND1; eauto using in_concat.
Qed.

Lemma NoDup_concatD A (l: list A) ll :
  NoDup (concat ll) -> In l ll -> NoDup l.
Proof.
  ins; apply in_split_perm in H0; desf.
  rewrite H0, concat_cons, nodup_app in H; desf.
Qed.


(** [map_filter] *)
(******************************************************************************)

Section map_filter.

  Variables A B : Type.
  Variable f : A -> option B.

  Fixpoint map_filter l :=
    match l with
      | nil => nil
      | x :: l => match f x with
                    | None => map_filter l
                    | Some b => b :: map_filter l
                  end
    end.

  Lemma in_map_filter x l :
    In x (map_filter l) <-> exists a, f a = Some x /\ In a l.
  Proof.
    induction l; ins; desf; ins; try (rewrite IHn; clear IHn);
    intuition; desf; eauto.
  Qed.

  Lemma map_filter_app (l l' : list A) :
    map_filter (l ++ l') = map_filter l ++ map_filter l'.
  Proof.
    induction l; ins; desf; ins; congruence.
  Qed.

  Lemma nodup_map_filter l :
    NoDup l ->
    (forall x y z, In x l -> In y l -> f x = Some z -> f y = Some z -> x = y) ->
    NoDup (map_filter l).
  Proof.
    induction l; ins; desf; rewrite ?nodup_cons, ?in_map_filter in *;
      desf; splits; eauto.
    by intro; desf; eauto; rewrite (H0 a a0 b) in H; eauto.
  Qed.

End map_filter.


(** Lemmas about Forall *)
(******************************************************************************)

Lemma Forall_cons A (P : A -> Prop) a l :
  Forall P (a :: l) <-> P a /\ Forall P l.
Proof.
  split; intro H; desf; vauto; inversion H; desf. 
Qed. 

Lemma Forall_app A (P : A -> Prop) l1 l2 :
  Forall P (l1 ++ l2) <-> Forall P l1 /\ Forall P l2.
Proof.
  induction l1; ins; [by intuition; vauto|].
  by rewrite !Forall_cons, IHl1, and_assoc.
Qed.

Lemma Forall_filter A (P: A -> Prop) f l : 
  Forall P l -> Forall P (filter f l).
Proof.
  rewrite !Forall_forall; ins.
  rewrite in_filter_iff in H0; desf; eauto.
Qed.

Lemma Forall_filterP A (P: A -> Prop) f l : 
  Forall P l -> Forall P (filterP f l).
Proof.
  rewrite !Forall_forall; ins.
  rewrite in_filterP_iff in H0; desf; eauto.
Qed.

Definition ForallE := Forall_forall.

(** [dprod] *)
(******************************************************************************)

Fixpoint dprod A B al (f : A -> list B) :=
  match al with
    | nil => nil
    | a :: al => map (fun b => (a, b)) (f a) ++ dprod al f
  end.

Lemma in_dprod_iff A B x al (f : A -> list B) :
  In x (dprod al f) <-> In (fst x) al /\ In (snd x) (f (fst x)).
Proof.
  induction al; ins; rewrite ?in_app_iff, ?in_map_iff, ?IHal; try clear IHal;
  split; ins; desf; ins; eauto; destruct x; ins; eauto.
Qed.


(** [seq] *)
(******************************************************************************)

Lemma in_seq_iff a n l : In a (seq n l) <-> n <= a < n + l.
Proof.
  revert n; induction l; ins; rewrite ?IHl; omega.
Qed.

Lemma in_seq0_iff x a : In x (seq 0 a) <-> x < a.
Proof.
  rewrite in_seq_iff; omega.
Qed.

Lemma nodup_seq n l : NoDup (seq n l).
Proof.
  revert n; induction l; ins; constructor; ins; eauto.
  rewrite in_seq_iff; omega.
Qed.

(*
Lemma seq_split :
  forall l a,
  a < l ->
  exists l', Permutation (seq 0 l) (a :: l') /\ ~ In a l'.
Proof.
  ins; eapply In_NoDup_Permutation; eauto using nodup_seq; apply in_seq_iff; omega.
Qed.
*)

Lemma seq_split :
  forall x a y,
    x <= y ->
    seq a y = seq a x ++ seq (x + a) (y - x).
Proof.
  induction x; ins; rewrite ?Nat.sub_0_r; ins.
  destruct y; ins; try omega.
  f_equal; rewrite IHx; repeat (f_equal; try omega).
Qed.

Lemma seq_split_gen :
  forall l n a,
  n <= a < n + l ->
  seq n l = seq n (a - n) ++ a :: seq (S a) (l + n - a - 1).
Proof.
  induction l; ins; desf; ins; try omega.
    repeat f_equal; omega.
  destruct (eqP n (S n0)); subst.
    replace (n0 - n0) with 0 by omega; ins; repeat f_equal; omega.
  rewrite IHl with (a := S n0); try omega.
  desf; ins; try replace (n0 - n2) with (S (n0 - S n2)) by omega;
  ins; repeat (f_equal; try omega).
Qed.

Lemma seq_split0 :
  forall l a,
  a < l ->
  seq 0 l = seq 0 a ++ a :: seq (S a) (l - a - 1).
Proof.
  ins; rewrite seq_split_gen with (a := a); repeat f_equal; omega.
Qed.

Global Opaque seq.

(** [mk_list] *)
(******************************************************************************)

Fixpoint mk_list n A (f: nat -> A) :=
  match n with
      0 => nil
    | S n => mk_list n f ++ f n :: nil
  end.

Lemma mk_listE n A (f: nat -> A) :
  mk_list n f = map f (seq 0 n).
Proof.
  induction n; ins; rewrite IHn.
  rewrite seq_split with (x:=n) (y:=S n); try omega.
  by rewrite map_app, plus_0_r, <- minus_Sn_m, minus_diag.
Qed.

Lemma in_mk_list_iff A (x: A) n f :
  In x (mk_list n f) <-> exists m, m < n /\ x = f m.
Proof.
  induction n; ins; try (rewrite in_app_iff, IHn; clear IHn); desc;
    split; ins; desf; try omega; try (by repeat eexists; omega).
  destruct (eqP m n); desf; eauto.
  left; repeat eexists; ins; omega.
Qed.

Lemma mk_list_length A n (f : nat -> A) :
  length (mk_list n f) = n.
Proof.
  induction n; ins; rewrite app_length; ins; omega.
Qed.

Lemma mk_list_nth A i n f (d : A) :
  nth i (mk_list n f) d = if le_lt_dec n i then d else f i.
Proof.
  induction n; ins; desf; rewrite app_nth; desf;
  rewrite mk_list_length in *; desf; try omega.
    apply nth_overflow; ins; omega.
  by assert (i = n) by omega; desf; rewrite minus_diag.
Qed.

Definition length_mk_list := mk_list_length.
Definition nth_mk_list := mk_list_nth. 

Hint Rewrite length_mk_list : calc_length.


(** [max_of_list] *)
(******************************************************************************)

Fixpoint max_of_list l :=
  match l with
      nil => 0
    | n :: l => max n (max_of_list l)
  end.

Lemma max_of_list_app l l' :
  max_of_list (l ++ l') = max (max_of_list l) (max_of_list l').
Proof.
  by induction l; ins; rewrite IHl, Max.max_assoc.
Qed.

(** Miscellaneous *)
(******************************************************************************)

Lemma perm_from_subset :
  forall A (l : list A) l',
    NoDup l' ->
    (forall x, In x l' -> In x l) ->
    exists l'', Permutation l (l' ++ l'').
Proof.
  induction l; ins; vauto.
    by destruct l'; ins; vauto; exfalso; eauto.
  destruct (classic (In a l')).

    eapply In_split in H1; desf; rewrite ?nodup_app, ?nodup_cons in *; desf.
    destruct (IHl (l1 ++ l2)); ins.
      by rewrite ?nodup_app, ?nodup_cons in *; desf; repeat split; ins; red;
         eauto using in_cons.
      by specialize (H0 x); rewrite in_app_iff in *; ins; desf;
         destruct (classic (a = x)); subst; try tauto; exfalso; eauto using in_eq.
    eexists; rewrite app_ass in *; ins.
    by eapply Permutation_trans, Permutation_middle; eauto.

  destruct (IHl l'); eauto; ins.
    by destruct (H0 x); auto; ins; subst.
  by eexists (a :: _); eapply Permutation_trans, Permutation_middle; eauto.
Qed.


Lemma list_prod_app A (l l' : list A) B (m : list B) :
  list_prod (l ++ l') m = list_prod l m ++ list_prod l' m.
Proof.
  by induction l; ins; rewrite IHl, app_assoc.
Qed.

Lemma list_prod_nil_r A (l : list A) B :
  list_prod l (@nil B) = nil.
Proof.
  induction l; ins.
Qed.

Lemma list_prod_cons_r A (l : list A) B a (m : list B) :
  Permutation (list_prod l (a :: m)) (map (fun x => (x,a)) l ++ list_prod l m).
Proof.
  induction l; ins.
  eapply Permutation_cons; ins.
  eapply Permutation_trans; [by apply Permutation_app; eauto|].
  rewrite !app_assoc; eauto using Permutation_app, Permutation_app_comm.
Qed.

Lemma list_prod_app_r A (l : list A) B (m m' : list B) :
  Permutation (list_prod l (m ++ m')) (list_prod l m ++ list_prod l m').
Proof.
  induction m; ins; ins.
    by rewrite list_prod_nil_r.
  rewrite list_prod_cons_r.
  eapply Permutation_trans; [by eapply Permutation_app, IHm|].
  rewrite app_assoc; apply Permutation_app; ins.
  symmetry; apply list_prod_cons_r.
Qed.


Lemma Permutation_listprod_r A (l : list A) B (m m' : list B) :
  Permutation m m' ->
  Permutation (list_prod l m) (list_prod l m').
Proof.
  ins; revert l; induction H; ins; eauto using Permutation.
    by rewrite ?list_prod_cons_r; eauto using Permutation_app.
  rewrite list_prod_cons_r.
  eapply Permutation_trans; [by apply Permutation_app, list_prod_cons_r|].
  symmetry.
  rewrite list_prod_cons_r.
  eapply Permutation_trans; [by apply Permutation_app, list_prod_cons_r|].
  rewrite !app_assoc; eauto using Permutation_app, Permutation_app_comm.
Qed.


Ltac in_simp :=
  try match goal with |- ~ _ => intro end;
  repeat first [
    rewrite in_flatten_iff in *; desc; clarify |
    rewrite in_map_iff in *; desc; clarify |
    rewrite in_seq0_iff in *; desc; clarify |
    rewrite in_mk_list_iff in *; desc; clarify |
    rewrite in_filter_iff in *; desc; clarify |
    rewrite in_filterP_iff in *; desc; clarify ].



