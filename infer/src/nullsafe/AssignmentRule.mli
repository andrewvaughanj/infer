(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)
open! IStd

(** Assignment rule should be checked when a value is assigned to a location. Assignment can be
    explicit (lhs = rhs) or implicit (e.g. returning from a function). This rule checks if null can
    be passed to a place that does not expect null. *)

type violation [@@deriving compare]

val check : lhs:Nullability.t -> rhs:Nullability.t -> (unit, violation) result
(** If `null` can leak from a "less strict" type to "more strict" type, this is an Assignment Rule
    violation. *)

(** Violation that needs to be reported to the user. *)
module ReportableViolation : sig
  type t

  type assignment_type =
    | PassingParamToFunction of function_info
    | AssigningToField of Fieldname.t
    | ReturningFromFunction of Procname.t
  [@@deriving compare]

  and function_info =
    { param_signature: AnnotatedSignature.param_signature
    ; model_source: AnnotatedSignature.model_source option
    ; actual_param_expression: string
    ; param_position: int
    ; function_procname: Procname.t }

  val get_severity : t -> Exceptions.severity
  (** Severity of the violation to be reported *)

  val get_description :
       assignment_location:Location.t
    -> assignment_type
    -> rhs_origin:TypeOrigin.t
    -> t
    -> string * IssueType.t * Location.t
  (** Given context around violation, return error message together with the info where to put this
      message *)
end

val to_reportable_violation : NullsafeMode.t -> violation -> ReportableViolation.t option
(** Depending on the mode, violation might or might not be important enough to be reported to the
    user. If it should NOT be reported for that mode, this function will return None. *)
