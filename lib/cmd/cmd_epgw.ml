type command = Connect_db | Disconnect_db

let anon_fun _x = ()

let aws_instance_id = "i-04ef001f17f71ceec"

let parse_cmd = function
  | "connect_db" -> Connect_db
  | "disconnect_db" -> Disconnect_db
  | cmd -> failwith ("invalid command: " ^ cmd)

let get_command cmd_str = cmd_str |> String.lowercase_ascii |> parse_cmd

let connect_db () =
  let instance = Aws.start_instance aws_instance_id in
  let () = Network.update_shh_host "ec2-rds" instance.public_ip in
  let _my_ip = Network.my_ip () in
  print_endline "revo_rds.sh epgw"
  (* TODO: change groups permissions to add my_ip *)

let disconnect_db () =
  let _ = Aws.stop_instance aws_instance_id in
  print_endline "done"

let exec_cmd = function
  | Connect_db ->
      let speclist = [] in
      Arg.parse speclist anon_fun Help.usage_msg;
      connect_db ()
  | Disconnect_db ->
      let speclist = [] in
      Arg.parse speclist anon_fun Help.usage_msg;
      disconnect_db ()
