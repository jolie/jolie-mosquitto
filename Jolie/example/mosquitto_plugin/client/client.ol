include "console.iol"
include "time.iol"
include "CalculatorInterface.iol"

outputPort Calculator {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: CalculatorInterface
}

embedded {
    Jolie: "mosquittoPlugin.ol" in Calculator
}

init {
  registerForInput@Console()()
}

main {

  sleep@Time(2000)()
  print@Console("insert first operand: ")();
  in( x ); request.x = double( x );
  print@Console("insert second operand: ")();
  in( y ); request.y = double( y );
  print@Console("insert operation [sum|mul|div|sub]: ")();
  in( operation );
  if ( operation == "sum" ) {
    sum@Calculator( request )( response )
  } else if ( operation == "sub" ) {
    sub@Calculator( request )( response )
  } else if ( operation == "div" ) {
    div@Calculator( request )( response )
  } else if ( operation == "mul" ) {
    mul@Calculator( request )( response )
  }
  ;
  println@Console( response )()
}
