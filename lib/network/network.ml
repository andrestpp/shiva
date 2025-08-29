let my_ip () = "myip.sh" |> Exec.run_and_capture

let update_shh_host ssh_cfg new_ip =
  let _ =
    Printf.sprintf "sshhosts.sh %s %s" ssh_cfg new_ip |> Exec.run_and_capture
  in
  ()
