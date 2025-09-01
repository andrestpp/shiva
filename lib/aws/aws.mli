val start_instance : string -> Cli.instance
val stop_instance : string -> Cli.instance
val state_to_string : Cli.instance_state -> string
val add_security_group_ingress : string -> string -> int -> string -> string -> string
val rm_security_group_ingress : string -> string -> unit
