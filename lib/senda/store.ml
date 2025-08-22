type order = { id : int; bank_order_code : string }

let get_order_query order_code =
  Printf.sprintf
    "SELECT id, \"bankOrderCode\" FROM bookings WHERE \"bankOrderCode\"='%s'"
    order_code

let get_order (conn : Postgresql.connection) raw_order_code =
  let order_code = conn#escape_string raw_order_code in
  let select_res = conn#exec (get_order_query order_code) in
  let rows = select_res#ntuples in
  if rows = 0 then failwith "no order found"
  else if rows > 1 then failwith "more than one order found"
  else
    let id_str = select_res#getvalue 0 0 in
    let bank_order_code = select_res#getvalue 0 1 in
    { id = int_of_string id_str; bank_order_code }
