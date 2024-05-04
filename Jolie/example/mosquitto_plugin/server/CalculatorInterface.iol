type RequestType: void {
  .x: double
  .y: double
}

interface CalculatorInterface {
  RequestResponse:
    sum( RequestType )( double ),
    mul( RequestType )( double ),
    div( RequestType )( double ) throws DivisionByZero,
    sub( RequestType )( double )
}
