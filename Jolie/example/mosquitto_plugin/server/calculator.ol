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

include "OperationInterface.iol"
include "CalculatorInterface.iol"

include "runtime.iol"

execution: concurrent

/* common interface of the embedded services */
outputPort Operation {
  Interfaces: OperationInterface
}

inputPort Calculator {
  Location: "socket://localhost:8000"
  Protocol: sodep
  Interfaces: CalculatorInterface
}

init {
  emb << {
    filepath = "mosquittoPlugin.ol",
    type = "Jolie"
  }
  loadEmbeddedService@Runtime( emb )(  )
}

/* this is the body of each service which embeds the jolie service that corresponds to the name of the operation */
define __embed_service {
    with( emb ) {
      .filepath = __op + ".ol";
      .type = "Jolie"
    };
    /* this is the Runtime service operation for dynamic embed files */
    loadEmbeddedService@Runtime( emb )( Operation.location );

    /* once embedded we call the run operation */
    run@Operation( request )( response )
}

/* note that the embedded service is running once ofr each enabled session then it expires.
Thus each call produce a new specific embedding for that call */
main {
  [ sum( request )( response ) {
      __op = "sum";
      /* here we call the define __embed_service where the variable __p is the name of the operation */
      __embed_service
  }]

  [ mul( request )( response ) {
      __op = "mul";
      __embed_service
  }]

  [ div( request )( response ) {
      __op = "div";
      __embed_service
  }]

  [ sub( request )( response ) {
    __op = "sub";
    __embed_service
  }]
}
