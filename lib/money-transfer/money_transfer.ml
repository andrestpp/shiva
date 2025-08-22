let heroku_money_transfer_app = "svc-remittance-mtransfer-prod"

let new_connection () =
  let conninfo = Heroku.db_url heroku_money_transfer_app in
  let conn =
    try new Postgresql.connection ~conninfo ()
    with Postgresql.Error e ->
      Printf.eprintf "Error conectando a PostgreSQL: %s\n%!"
        (Postgresql.string_of_error e);
      exit 1
  in
  conn

let get_order = Store.get_order
