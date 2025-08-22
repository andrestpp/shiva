let read_all_in ic =
  let buf = Buffer.create 4096 in
  (try
     while true do
       Buffer.add_channel buf ic 4096
     done
   with End_of_file -> ());
  Buffer.contents buf

let run_and_capture cmd =
  let ic = Unix.open_process_in cmd in
  let out = read_all_in ic in
  match Unix.close_process_in ic with
  | Unix.WEXITED 0 -> out |> String.trim
  | Unix.WEXITED code ->
      failwith (Printf.sprintf "command exited %d: %s" code out)
  | Unix.WSIGNALED s -> failwith (Printf.sprintf "command signaled %d" s)
  | Unix.WSTOPPED s -> failwith (Printf.sprintf "command stopped %d" s)

let db_url app =
  let app_flag = "--app " ^ Filename.quote app in
  let cmd =
    "heroku pg:credentials:url DATABASE " ^ app_flag
    ^ " | grep \"postgres://\" | awk '{print $1}'"
  in
  run_and_capture cmd
