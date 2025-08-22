type command = Send_transfer | Send_transfast_email

(* let anon_fun x = raise (Arg.Bad ("Bad argument : " ^ x)) *)
let anon_fun _x = ()

let parse_cmd = function
  | "send_transfer" -> Send_transfer
  | "send_transfast_email" -> Send_transfast_email
  | cmd -> failwith ("invalid command: " ^ cmd)

let get_command cmd_str = cmd_str |> String.lowercase_ascii |> parse_cmd

let cli_send_transfer order_id =
  Printf.sprintf
    "./cli queue -t moneyTransfer.sendTransfer -d '{\"orderId\":%d}" order_id

let send_transfer order_code _verbose =
  (* select id from bookings where "bankOrderCode"='TXF8D4zXlJ3Mw0'; *)
  (* select id from "BankDepositOrders" where "orderReference"='25540'; *)
  (* ./cli queue -t moneyTransfer.sendTransfer -d '{"orderId":4691}' *)
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

let send_transfast_email order_code _verbose =
  (* select id from bookings where "bankOrderCode"='TXF8D4zXlJ3Mw0'; *)
  (* select id from "BankDepositOrders" where "orderReference"='25540'; *)
  (* select "senderId" from "BankDepositOrders" where id=4691; *)
  (* select url from "SenderDocuments" where "senderId"=1041 and subtype='pdf'; *)
  (* cli queue -t transfast.documents -d '{"documents": [{"senderId": 1041, "type": 31, "subtype": "pdf", "url": "Natural/4de5659c-671d-448c-9369-69a11293ad1c/Prueba de vida/pdf/pdf_1755792594031.pdf"}], "reference": 4691}' *)
  print_endline ("send_transfast_email" ^ order_code)

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
