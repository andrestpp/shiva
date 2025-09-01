type instance_state = Pending | Running | Stopped | Stopping | Terminated
type instance = { id : string; public_ip : string; state : instance_state }

type security_group_permission = {
  from_port : int;
  to_port : int;
  cidr : string;
  protocol : string;
  description : string option;
}

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

let add_security_group_ingress sg_id protocol port cidr description =
  let cmd =
    Printf.sprintf
      "aws ec2 authorize-security-group-ingress --group-id \"%s\" --ip-permissions IpProtocol=%s,FromPort=%d,ToPort=%d,IpRanges=\"[{CidrIp=%s,Description=%s}]\""
      sg_id protocol port port cidr description
  in
  Exec.run_and_capture cmd

let rm_security_group_ingress sg_id protocol port cidr =
  let cmd =
    Printf.sprintf
      "aws ec2 revoke-security-group-ingress --group-id %s --protocol %s \
       --port %d --cidr %s"
      sg_id protocol port cidr
  in
  Exec.run_and_capture cmd

let parse_ip_range json =
  let open Yojson.Basic.Util in
  let cidr = json |> member "CidrIp" |> to_string in
  let description = json |> member "Description" |> to_string_option in
  (cidr, description)

let parse_permission json =
  let open Yojson.Basic.Util in
  let from_port = json |> member "FromPort" |> to_int in
  let to_port = json |> member "ToPort" |> to_int in
  let protocol = json |> member "IpProtocol" |> to_string in
  let ip_ranges =
    json |> member "IpRanges" |> to_list |> List.map parse_ip_range
  in
  ip_ranges
  |> List.map (fun (cidr, description) ->
         { from_port; to_port; cidr; protocol; description })

let parse_security_group_permissions ip_permissions_str =
  let json = Yojson.Basic.from_string ip_permissions_str in
  json |> Yojson.Basic.Util.to_list |> List.map parse_permission |> List.flatten

let describe_security_group (sg_id : string) : security_group_permission list =
  let cmd =
    "aws ec2 describe-security-groups --group-ids " ^ sg_id
    ^ " | jq -r '.SecurityGroups[0].IpPermissions'"
  in
  Exec.run_and_capture cmd |> parse_security_group_permissions
