type order = { id : int }

let get_order_query order_reference =
  Printf.sprintf
    "SELECT id FROM \"BankDepositOrders\" WHERE \"orderReference\"='%d'"
    order_reference

let get_order (conn : Postgresql.connection) (order_ref: int) =
  let select_res = conn#exec (get_order_query order_ref) in
  let rows = select_res#ntuples in
  if rows = 0 then failwith "no order found"
  else if rows > 1 then failwith "more than one order found"
  else
    let id_str = select_res#getvalue 0 0 in
    { id = int_of_string id_str }
