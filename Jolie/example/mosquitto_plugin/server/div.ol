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

inputPort Op {
  Location:"local"
  Interfaces: OperationInterface
}

main {
  run( request )( response ) {
    if ( request.y == 0.0 )
      throw ( DivisionByZero )
    response = request.x / request.y
  }
}
