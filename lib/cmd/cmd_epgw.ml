type command = Connect_db

let anon_fun _x = ()

let parse_cmd = function
  | "connect_db" -> Connect_db
  | cmd -> failwith ("invalid command: " ^ cmd)

let get_command cmd_str = cmd_str |> String.lowercase_ascii |> parse_cmd

let connect_db () =
  let instance = Aws.start_instance "i-04ef001f17f71ceec" in
  print_endline (instance.public_ip)
  (* TODO: change hosts value *)

let exec_cmd = function
  | Connect_db ->
      let speclist = [] in
      Arg.parse speclist anon_fun Help.usage_msg;
      connect_db ()
