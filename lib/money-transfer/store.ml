type order = { id : int; sender_id : int }

let get_order_query order_reference =
  Printf.sprintf
    "SELECT id,\"senderId\" FROM \"BankDepositOrders\" WHERE \
     \"orderReference\"='%d'"
    order_reference

let get_order (conn : Postgresql.connection) (order_ref : int) =
  let select_res = order_ref |> get_order_query |> conn#exec in
  let rows = select_res#ntuples in
  if rows = 0 then failwith "no order found"
  else if rows > 1 then failwith "more than one order found"
  else
    let id = select_res#getvalue 0 0 |> int_of_string in
    let sender_id = select_res#getvalue 0 1 |> int_of_string in
    { id; sender_id }

let get_sender_document_query sender_id =
  Printf.sprintf
    "SELECT url FROM \"SenderDocuments\" WHERE \"senderId\"=%d and \
     subtype='pdf'"
    sender_id

type sender_document = { url : string }

let get_sender_document (conn : Postgresql.connection) (sender_id : int) =
  let select_res = sender_id |> get_sender_document_query |> conn#exec in
  let rows = select_res#ntuples in
  if rows = 0 then failwith "no sender document found"
  else if rows > 1 then failwith "more than one sender document found"
  else
    let url = select_res#getvalue 0 0 in
    { url }
