module top_module (
	input x3,
	input x2,
	input x1,
	output f
);
	// This truth table has four minterms:
	// assign f = ( ~x3 & x2 & ~x1 ) |
	// 			( ~x3 & x2 & x1 ) |
	// 			( x3 & ~x2 & x1 ) |
	// 			( x3 & x2 & x1 ) ;
	//
	// Simplified by boolean algebra / Karnaugh map:
	// assign f = (~x3 & x2) | (x3 & x1);
	//
	// Which is really just a 2-to-1 mux, selected by x3:
	assign f = x3 ? x1 : x2;
	
endmodule