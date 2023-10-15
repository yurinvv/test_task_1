module alu #(
	parameter DATA_WIDTH = 64,
	parameter ALU_OPP_WIDTH = 2
)(
	input aclk,
	input aresetn,
	
	input [ALU_OPP_WIDTH - 1 : 0] i_alu_opp,
	input [DATA_WIDTH - 1 : 0]   s_axis_a_tdata,
	input                         s_axis_a_tvalid,
	output                        s_axis_a_tready,
	
	input [DATA_WIDTH - 1 : 0]   s_axis_b_tdata,
	
	output [DATA_WIDTH - 1 : 0]   m_axis_result_tdata,
	output                         m_axis_result_tvalid
);
		
	/////////////////////////////
	/* Adder */
	wire [DATA_WIDTH - 1 : 0] add_a;
	wire [DATA_WIDTH - 1 : 0] add_b;
	wire [DATA_WIDTH - 1 : 0] add_sum;
	
	adder adder0 (
	  .A     (add_a),      // input wire [63 : 0] A
	  .B     (add_b),      // input wire [63 : 0] B
	  .CLK   (aclk),         // input wire CLK
	  .S     (add_sum)     // output wire [63 : 0] S
	);
	
	///////////////////////////
	/* Multiplier */
	wire [DATA_WIDTH - 1 : 0] mult_a;
	wire [DATA_WIDTH - 1 : 0] mult_b;
	wire [DATA_WIDTH - 1 : 0] mult_result;	
	
	multiplier multiplier0 (
	  .CLK   (aclk),  // input wire CLK
	  .A     (mult_a),    // input wire [63 : 0] A
	  .B     (mult_b),    // input wire [63 : 0] B
	  .P     (mult_result)     // output wire [63 : 0] P
	);	
	
	
	//////////////////////////
	/* Divider */
	wire divisor_tvalid;
	wire divisor_tready;
	wire [DATA_WIDTH/2 - 1 : 0] divisor_tdata;
	
	wire dividend_tvalid;
	wire dividend_tready;
	wire [DATA_WIDTH - 1 : 0] dividend_tdata;
	
	wire div_result_tvalid;
	wire zero_error;
	wire [DATA_WIDTH + DATA_WIDTH/2 - 1 : 0] div_result_data;
	
	divider divider0 (
	  .aclk                   (aclk),              // input wire aclk
	  // Divisor
	  .s_axis_divisor_tvalid  (divisor_tvalid),    // input wire s_axis_divisor_tvalid
	  .s_axis_divisor_tdata   (divisor_tdata),     // input wire [31 : 0] s_axis_divisor_tdata
	  // Dividend
	  .s_axis_dividend_tvalid (dividend_tvalid),   // input wire s_axis_dividend_tvalid
	  .s_axis_dividend_tdata  (dividend_tdata),    // input wire [63 : 0] s_axis_dividend_tdata
	  // Result
	  .m_axis_dout_tvalid     (div_result_tvalid),    // output wire m_axis_dout_tvalid
	  .m_axis_dout_tuser      (zero_error),          // output wire [0 : 0] m_axis_dout_tuser
	  .m_axis_dout_tdata      (div_result_data)     // output wire [95 : 0] m_axis_dout_tdata
	);	
	
	
	//////////////////////////////
	/* Controller */
	
	alu_controller #(
		.DATA_WIDTH   (DATA_WIDTH),
		.ALU_OPP_WIDTH (ALU_OPP_WIDTH)
	) alu_controller0 (
		.aclk    (aclk),
		.aresetn (aresetn),
	
		.i_alu_opp       (i_alu_opp),
		.s_axis_a_tdata  (s_axis_a_tdata),
		.s_axis_a_tvalid (s_axis_a_tvalid),
		.s_axis_a_tready (s_axis_a_tready),
	
		.s_axis_b_tdata  (s_axis_b_tdata),
	
		.m_axis_result_tdata  (m_axis_result_tdata),
		.m_axis_result_tvalid (m_axis_result_tvalid),
	//input reg                    m_axis_result_tready,	
	
	//////////////////////////////////////////////////
	// Operators
	
		.add_a   (add_a),
		.add_b   (add_b),
		.add_sum (add_sum),
	
		.mult_a      (mult_a),
		.mult_b      (mult_b),
		.mult_result (mult_result),

		.divisor_tvalid (divisor_tvalid),
		.divisor_tdata  (divisor_tdata),
	
		.dividend_tvalid (dividend_tvalid),
		.dividend_tdata  (dividend_tdata ),
	
		.div_result_tvalid  (div_result_tvalid),
		.zero_error         (zero_error       ),
		.div_result_data    (div_result_data  )
);
	
endmodule