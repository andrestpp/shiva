let usage_msg = "Usage: shiva app command [options]

Apps:
  senda         Senda

Commands:
  send_transfast_email [options]  Send user kyc documents to transfast
  send_transfer [options]         Send a transfer email

Examples:

shiva senda send_transfast_email --order_code TXF8D4zXlJ3Mw0
shiva senda send_transfer --order_code TXF8D4zXlJ3Mw0
"

let help () = print_endline usage_msg

let usage (error_msg) =
  print_endline error_msg;
  print_endline usage_msg
