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
