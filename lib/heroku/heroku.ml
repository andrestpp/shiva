let db_url app =
  let app_flag = "--app " ^ Filename.quote app in
  let cmd =
    "heroku pg:credentials:url DATABASE " ^ app_flag
    ^ " | grep \"postgres://\" | awk '{print $1}'"
  in
  Exec.run_and_capture cmd
