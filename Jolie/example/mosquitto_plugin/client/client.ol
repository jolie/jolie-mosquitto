/*
   Copyright 2020 Riccardo Iattoni <riccardo.iattoni92@gmail.com>

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

include "../server/CalculatorInterface.iol"

include "console.iol"
include "time.iol"

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
    scope ( div ) {
      install ( DivisionByZero => response = "NaN" )
      div@Calculator( request )( response )
    }
  } else if ( operation == "mul" ) {
    mul@Calculator( request )( response )
  }
  ;
  println@Console( response )()
}
