open Lwt.Infix

type t =
  switch:Lwt_switch.t ->
  log:Log_data.t ->
  spec:Obuilder.Spec.stage ->
  src_dir:string -> (string, [ `Cancelled | `Msg of string ]) result Lwt.t

module Sandbox = Obuilder.Runc_sandbox

let ( / ) = Filename.concat

let log_to log_data tag msg =
  match tag with
  | `Heading -> Log_data.info log_data "%s" msg
  | `Note -> Log_data.info log_data "%s" msg
  | `Output -> Log_data.write log_data msg

let create spec =
  Obuilder.Store_spec.to_store spec >|= fun (Store ((module Store), store)) ->
  let sandbox = Sandbox.create ~runc_state_dir:(Store.state_dir store / "runc") in
  let module Builder = Obuilder.Builder(Store)(Sandbox) in
  let builder = Builder.v ~store ~sandbox in
  fun ~switch ~log ~spec ~src_dir ->
    let log = log_to log in
    let context = Obuilder.Context.v ~switch ~log ~src_dir () in
    Builder.build builder context spec

let build t = t