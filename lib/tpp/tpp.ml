let heroku_tpp_app = "tp-testing"

let new_connection () =
  let conninfo = Heroku.db_url heroku_tpp_app in
  let conn =
    try new Postgresql.connection ~conninfo ()
    with Postgresql.Error e ->
      Printf.eprintf "Error conectando a PostgreSQL: %s\n%!"
        (Postgresql.string_of_error e);
      exit 1
  in
  conn

let get_booking = Store.get_booking
