// a + b
// a * b
// a % b

module alu_controller #(
	parameter DATA_WIDTH = 64,
	parameter ALU_OPP_WIDTH = 2
)(
	input aclk,
	input aresetn,
	
	input [ALU_OPP_WIDTH - 1 : 0] i_alu_opp,
	input [DATA_WIDTH - 1 : 0]   s_axis_a_tdata,
	input                         s_axis_a_tvalid,
	output logic                  s_axis_a_tready,
	
	input [DATA_WIDTH - 1 : 0]   s_axis_b_tdata,
	//input                       m_axis_b_tvalid,
	//output                      m_axis_b_tready,
	
	output logic [DATA_WIDTH - 1 : 0]   m_axis_result_tdata,
	output logic                         m_axis_result_tvalid,
	//input reg                    m_axis_result_tready,	
	
	//////////////////////////////////////////////////
	// Operators
	
	output logic [DATA_WIDTH - 1 : 0] add_a,
	output logic [DATA_WIDTH - 1 : 0] add_b,
	input        [DATA_WIDTH - 1 : 0] add_sum,
	
	output logic [DATA_WIDTH - 1 : 0] mult_a,
	output logic [DATA_WIDTH - 1 : 0] mult_b,
	input        [DATA_WIDTH - 1 : 0] mult_result,

	output logic                        divisor_tvalid,
	output logic [DATA_WIDTH/2 - 1 : 0] divisor_tdata,
	
	output logic                        dividend_tvalid,
	output logic [DATA_WIDTH - 1 : 0]   dividend_tdata,
	
	input div_result_tvalid,
	input zero_error,
	input [95 : 0] div_result_data
);
/////////////////////////////////////////////////////////////////////////
// Body

	
	localparam TIMER_MAX = 2;
	
	logic [$clog2(TIMER_MAX) - 1 : 0] timer;
	
	// ALU oppcodes
	localparam  SUM = 0,
				MULT = 1,
				DIV = 2;
	
	
	logic [ALU_OPP_WIDTH - 1 : 0] alu_opp_mem;
	
	// FSM state transitions
	typedef enum {
		GET_TASK,
		RETURN_RES
	} State_e;
	
	State_e state, next;
	
	/////////////////////////////////
	/* State machine */
	
	// FSM state
	always_ff@(posedge aclk)
		if (!aresetn) state <= GET_TASK;
		else state <= next;
		
	// FSM transition logic
	always_comb begin
		next = state;
		case (state)
		GET_TASK:
		
			if (s_axis_a_tvalid)
				next = RETURN_RES;
				
		RETURN_RES:
		
			if (alu_opp_mem == DIV) begin
				if (div_result_tvalid)
					next = GET_TASK;
			end else if (timer == TIMER_MAX - 1)
				next = GET_TASK;
				
		endcase
	end
	
	
	///////////////////////////////
	// Selection of operators
		
	always_ff@(posedge aclk)
		if (!aresetn) begin
			add_a           <= '0;
			add_b           <= '0;
			mult_a          <= '0;
			mult_b          <= '0;
			dividend_tdata  <= '0; // a
			divisor_tdata   <= '0; // b
			divisor_tvalid  <= '0;
			dividend_tvalid <= '0;
			alu_opp_mem     <= '0;
		end else if (s_axis_a_tvalid) begin
			case (i_alu_opp)
			SUM:
				begin
				add_a <= s_axis_a_tdata;
				add_b <= s_axis_b_tdata;
				end
			MULT:
				begin
				mult_a <= s_axis_a_tdata;
				mult_b <= s_axis_b_tdata;
				end
			DIV:
				begin
				dividend_tdata <= s_axis_a_tdata;
				divisor_tdata <= s_axis_b_tdata[DATA_WIDTH/2 - 1 : 0];
				divisor_tvalid <= 1;
				dividend_tvalid <= 1;
				end
			endcase
			
			alu_opp_mem <= s_axis_a_tready ? i_alu_opp : alu_opp_mem;
			
		end else begin
			divisor_tvalid <= 0;
			dividend_tvalid <= 0;
		end
	
	// Slave AXIS Tready
	always_ff@(posedge aclk)
		if (!aresetn)
			s_axis_a_tready <= 0;
		else
			case(state)
				GET_TASK:
					if (s_axis_a_tvalid & s_axis_a_tready)
						s_axis_a_tready <= 0;
					else
						s_axis_a_tready <= 1;
				default:
					s_axis_a_tready <= 0;
			endcase
		
	/////////////////////////////////
	// Wait for result
	
	always_ff@(posedge aclk)
		if (!aresetn) begin
			timer <= '0;
		end else
			case(state)
			RETURN_RES:
				timer <= timer + 1;
			default:
				timer <= '0;
			endcase
	
	////////////////////////////////
	// Reception of result
	
	logic [DATA_WIDTH - 1 : 0] out_tdata;
	logic                      out_tvalid;	
	
	// AXIS preparation
	always_comb begin
		case(alu_opp_mem)
		SUM:  
			begin
			out_tdata = add_sum; 
			out_tvalid = timer == TIMER_MAX - 1;
			end
		MULT:
			begin
			out_tdata = mult_result; 
			out_tvalid = timer == TIMER_MAX - 1;
			end
		DIV:
			begin
			out_tdata = zero_error ? 0 : {32'd0, div_result_data[31 : 0]}; //Remainder 
			out_tvalid = div_result_tvalid; 
			end
		endcase
	end
	
	// Axis
	always_ff@(posedge aclk)
		if (!aresetn) begin
			m_axis_result_tdata <= '0;
			m_axis_result_tvalid <= '0;
		end else
			case(state)
			RETURN_RES: 
				begin
				m_axis_result_tdata <= out_tdata;
				m_axis_result_tvalid <= out_tvalid;
				end
			default:
				m_axis_result_tvalid <= '0;
			endcase
endmodule