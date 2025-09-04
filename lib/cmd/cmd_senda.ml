type command = Send_transfer | Send_transfast_email | Order_status

(* let anon_fun x = raise (Arg.Bad ("Bad argument : " ^ x)) *)
let anon_fun _x = ()

let parse_cmd = function
  | "send_transfer" -> Send_transfer
  | "send_transfast_email" -> Send_transfast_email
  | "order_status" -> Order_status
  | cmd -> failwith ("invalid command: " ^ cmd)

let get_command cmd_str = cmd_str |> String.lowercase_ascii |> parse_cmd

let cli_send_transfer order_id =
  Printf.sprintf
    "./cli queue -t moneyTransfer.sendTransfer -d '{\"orderId\":%d}'" order_id

let send_transfer order_code _verbose =
  (* select id from bookings where "bankOrderCode"='TXF8D4zXlJ3Mw0'; *)
  (* select id from "BankDepositOrders" where "orderReference"='25540'; *)
  (* ./cli queue -t moneyTransfer.sendTransfer -d '{"orderId":4691}' *)
  print_endline ("send_transfer " ^ order_code);
  let mt_conn = Money_transfer.new_connection () in
  let senda_conn = Senda.new_connection () in
  let finally () =
    senda_conn#finish;
    mt_conn#finish
  in
  try
    let senda_order = Senda.get_order senda_conn order_code in
    let mt_order = Money_transfer.get_order mt_conn senda_order.id in
    print_endline (cli_send_transfer mt_order.id);
    finally ()
  with
  | Postgresql.Error e ->
      Printf.eprintf "Error de PostgreSQL: %s\n%!"
        (Postgresql.string_of_error e);
      finally ();
      exit 3
  | exn ->
      finally ();
      raise exn

let cli_send_transfast_email (mt_order : Money_transfer__Store.order)
    (mt_sender_doc : Money_transfer__Store.sender_document) =
  Printf.sprintf
    "./cli queue -t transfast.documents -d '{\"documents\": [{\"senderId\": \
     %d, \"type\": 31, \"subtype\": \"pdf\", \"url\": \"%s\"}], \"reference\": \
     %d}'"
    mt_order.sender_id mt_sender_doc.url mt_order.id

let send_transfast_email order_code _verbose =
  (* select id from bookings where "bankOrderCode"='TXF8D4zXlJ3Mw0'; *)
  (* select id from "BankDepositOrders" where "orderReference"='25540'; *)
  (* select "senderId" from "BankDepositOrders" where id=4691; *)
  (* select url from "SenderDocuments" where "senderId"=1041 and subtype='pdf'; *)
  (* cli queue -t transfast.documents -d '{"documents": [{"senderId": 1041, "type": 31, "subtype": "pdf", "url": "Natural/4de5659c-671d-448c-9369-69a11293ad1c/Prueba de vida/pdf/pdf_1755792594031.pdf"}], "reference": 4691}' *)
  print_endline ("send_transfast_email " ^ order_code);
  let mt_conn = Money_transfer.new_connection () in
  let senda_conn = Senda.new_connection () in
  let finally () =
    senda_conn#finish;
    mt_conn#finish
  in
  try
    let senda_order = Senda.get_order senda_conn order_code in
    let mt_order = Money_transfer.get_order mt_conn senda_order.id in
    let mt_sender_doc =
      Money_transfer.get_sender_document mt_conn mt_order.sender_id
    in
    print_endline (cli_send_transfast_email mt_order mt_sender_doc);
    finally ()
  with
  | Postgresql.Error e ->
      Printf.eprintf "Error de PostgreSQL: %s\n%!"
        (Postgresql.string_of_error e);
      finally ();
      exit 3
  | exn ->
      finally ();
      raise exn

let format_order_status (mt_order : Money_transfer__Store.order) =
  Printf.sprintf "Order: id=%d, order_reference=%d" mt_order.id
    mt_order.order_reference

let get_order_status order_code _verbose =
  let mt_conn = Money_transfer.new_connection () in
  let senda_conn = Senda.new_connection () in
  let finally () =
    senda_conn#finish;
    mt_conn#finish
  in
  try
    let senda_order = Senda.get_order senda_conn order_code in
    let mt_order = Money_transfer.get_order mt_conn senda_order.id in
    print_endline (format_order_status mt_order);
    finally ()
  with
  | Postgresql.Error e ->
      Printf.eprintf "Error de PostgreSQL: %s\n%!"
        (Postgresql.string_of_error e);
      finally ();
      exit 3
  | exn ->
      finally ();
      raise exn

let exec_cmd = function
  | Send_transfer ->
      let verbose = ref false in
      let order_code = ref "" in
      let speclist =
        [
          ("--verbose", Arg.Set verbose, "Output debug information");
          ("--order_code", Arg.Set_string order_code, "Order code");
        ]
      in
      Arg.parse speclist anon_fun Help.usage_msg;
      if !order_code = "" then failwith "order_code is required";
      send_transfer !order_code !verbose
  | Send_transfast_email ->
      let verbose = ref false in
      let order_code = ref "" in
      let speclist =
        [
          ("--verbose", Arg.Set verbose, "Output debug information");
          ("--order_code", Arg.Set_string order_code, "Order code");
        ]
      in
      Arg.parse speclist anon_fun Help.usage_msg;
      if !order_code = "" then failwith "order_code is required";
      send_transfast_email !order_code !verbose
  | Order_status ->
      let verbose = ref false in
      let order_code = ref "" in
      let speclist =
        [
          ("--verbose", Arg.Set verbose, "Output debug information");
          ("--order_code", Arg.Set_string order_code, "Order code");
        ]
      in
      Arg.parse speclist anon_fun Help.usage_msg;
      if !order_code = "" then failwith "order_code is required";
      get_order_status !order_code !verbose
