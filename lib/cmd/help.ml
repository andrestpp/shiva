let usage_msg = "Usage: shiva app command [options]

Apps:
  senda         Senda
  epgw          Payment entity gateway

Commands:
  send_transfast_email [options]  Send user kyc documents to transfast
  send_transfer [options]         Send a transfer email
  connect_db                      Connect to the database

Examples:

shiva senda send_transfast_email --order_code TXF8D4zXlJ3Mw0
shiva senda send_transfer --order_code TXF8D4zXlJ3Mw0
shiva senda order_status --order_code TXF8D4zXlJ3Mw0
shiva epgw connect_db
shiva epgw disconnect_db
"

let help () = print_endline usage_msg

let usage (error_msg) =
  print_endline error_msg;
  print_endline usage_msg
