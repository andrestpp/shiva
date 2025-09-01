let state_to_string = function
  | Cli.Pending -> "pending"
  | Cli.Running -> "running"
  | Cli.Stopped -> "stopped"
  | Cli.Stopping -> "stopping"
  | Cli.Terminated -> "terminated"

let rec wait_for instance_id expected_state =
  let instance = Cli.describe_instance instance_id in
  match (instance.state, expected_state) with
  | Cli.Pending, Cli.Running ->
      print_endline "waiting for instance to start";
      let () = Unix.sleep 2 in
      wait_for instance_id expected_state
  | Cli.Stopping, Cli.Stopped ->
      print_endline "waiting for instance to stop";
      let () = Unix.sleep 2 in
      wait_for instance_id expected_state
  | Cli.Running, Cli.Running -> instance
  | Cli.Stopped, Cli.Stopped -> instance
  | _, _ -> instance

let start_instance instance_id =
  let instance = Cli.describe_instance instance_id in
  match instance.state with
  | Pending -> wait_for instance_id Cli.Running
  | Running -> instance
  | Stopping -> (
      let instance = wait_for instance_id Cli.Stopped in
      let res = Cli.start_instance instance_id in
      match res.current_state with
      | Cli.Pending -> wait_for instance_id Cli.Running
      | Cli.Running -> instance
      | _ -> failwith "invalid state")
  | Terminated -> failwith "instance is terminated"
  | Stopped -> (
      let res = Cli.start_instance instance_id in
      match res.current_state with
      | Cli.Pending -> wait_for instance_id Cli.Running
      | Cli.Running -> instance
      | _ -> failwith "invalid state")

let stop_instance instance_id =
  let instance = Cli.describe_instance instance_id in
  match instance.state with
  | Pending -> (
      let instance = wait_for instance_id Cli.Running in
      let res = Cli.stop_instance instance_id in
      match res.current_state with
      | Cli.Stopping -> wait_for instance_id Cli.Stopped
      | Cli.Stopped -> instance
      | _ -> failwith "invalid state")
  | Running -> (
      let res = Cli.stop_instance instance_id in
      match res.current_state with
      | Cli.Stopping -> wait_for instance_id Cli.Stopped
      | Cli.Stopped -> instance
      | _ -> failwith "invalid state")
  | Stopping -> wait_for instance_id Cli.Stopped
  | Terminated -> failwith "instance is terminated"
  | Stopped -> instance

(* Remove security group ingress that matches the description. *)
let rm_security_group_ingress sg_id description =
  let permissions = Cli.describe_security_group sg_id in
  List.iter
    (fun (permission: Cli.security_group_permission) ->
      match permission.description with
      | Some description' when description = description' ->
          let _ =
            Cli.rm_security_group_ingress sg_id permission.protocol
              permission.from_port permission.cidr
          in
          ()
      | _ -> ())
    permissions

(* TODO: validate all type parameters *)
let add_security_group_ingress = Cli.add_security_group_ingress
