import SovereignApollo.State

inductive CommsState where
  | Acquire | Lock | Data | Drop
  deriving DecidableEq, Repr

def commsTransition : CommsState → CommsState → Prop
  | .Acquire, .Lock => True
  | .Lock, .Data => True
  | .Data, .Drop => True
  | .Drop, .Acquire => True
  | s, t => s = t  -- stutter allowed

theorem comms_no_skip_acquire_to_data : ¬ commsTransition .Acquire .Data := by
  simp [commsTransition]

theorem comms_reflexive (s : CommsState) : commsTransition s s := by
  cases s <;> simp [commsTransition]
