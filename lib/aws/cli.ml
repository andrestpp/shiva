type instance_state = Pending | Running | Stopped | Stopping | Terminated
type instance = { id : string; public_ip : string; state : instance_state }

type instance_change_state = {
  id : string;
  current_state : instance_state;
  previous_state : instance_state;
}

let parse_state = function
  | 0 -> Pending
  | 16 -> Running
  | 64 -> Stopping
  | 80 -> Stopped
  | 48 -> Terminated
  | _ -> failwith "invalid state"

let parse_change_state_instance state_str =
  let json = Yojson.Basic.from_string state_str in
  let open Yojson.Basic.Util in
  let id = json |> member "InstanceId" |> to_string in
  let current_state =
    json |> member "CurrentState" |> member "Code" |> to_int |> parse_state
  in
  let previous_state =
    json |> member "PreviousState" |> member "Code" |> to_int |> parse_state
  in
  { id; current_state; previous_state }

let parse_instance instance_str =
  let json = Yojson.Basic.from_string instance_str in
  let open Yojson.Basic.Util in
  let id = json |> member "InstanceId" |> to_string in
  let public_ip =
    json |> member "PublicIpAddress" |> to_string_option |> function
    | Some ip -> ip
    | None -> ""
  in
  let state =
    json |> member "State" |> member "Code" |> to_int |> parse_state
  in
  { id; public_ip; state }

let describe_instance instance_ids =
  let cmd =
    "aws ec2 describe-instances --instance-ids " ^ instance_ids
    ^ " | jq -r '.Reservations[0].Instances[0]'"
  in
  Exec.run_and_capture cmd |> parse_instance

let start_instance instance_id =
  let cmd =
    "aws ec2 start-instances --instance-ids " ^ instance_id
    ^ " | jq -r '.StartingInstances[0]'"
  in
  Exec.run_and_capture cmd |> parse_change_state_instance

let stop_instance instance_id =
  let cmd =
    "aws ec2 stop-instances --instance-ids " ^ instance_id
    ^ " | jq -r '.StoppingInstances[0]'"
  in
  Exec.run_and_capture cmd |> parse_change_state_instance
