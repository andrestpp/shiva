type app = Senda

let parse_app = function
  | "senda" -> Senda
  | app -> failwith ("invalid app: " ^ app)

let get_app app_str = app_str |> String.lowercase_ascii |> parse_app

let run () =
  if Array.length Sys.argv < 3 then Help.usage "invalid arguments"
  else
    try
      let app = get_app Sys.argv.(1) in
      match app with
      | Senda -> Sys.argv.(2) |> Cmd_senda.get_command |> Cmd_senda.exec_cmd
    with Failure msg -> Help.usage msg
