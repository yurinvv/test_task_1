//
// ind = mod(f1 * i + f2 * i^2, K)

module interleaver #(
	parameter DATA_WIDTH = 32,
	parameter ALU_OPP_WIDTH = 2
)(
	input aclk,
	input aresetn,
		
	input [DATA_WIDTH - 1 : 0]   s_axis_f1_tdata,
	//input                         s_axis_f1_tvalid,
	//output                        s_axis_f1_tready,	
	
	input [DATA_WIDTH - 1 : 0]   s_axis_f2_tdata,
	//input                         s_axis_f2_tvalid,
	//output                        s_axis_f2_tready,	
	
	input [DATA_WIDTH - 1 : 0]   s_axis_k_tdata,
	input                         s_axis_k_tvalid,
	output reg                    s_axis_k_tready,	
	
	input                           m_axis_ind_tready, 
	output reg                      m_axis_ind_tvalid,
	output reg [DATA_WIDTH - 1 : 0] m_axis_ind_tdata,
	output reg                      m_axis_ind_tuser,   // Start of vector 
	output reg                      m_axis_ind_tlast,    // End of vector
	
	
	//////////////////////////////
	/* ALU */
	output reg [ALU_OPP_WIDTH - 1 : 0] o_alu_opp,
	output reg[DATA_WIDTH*2 - 1 : 0]    m_axis_a_tdata,
	output reg                         m_axis_a_tvalid,
	input                              m_axis_a_tready,
	
	output reg [DATA_WIDTH*2 - 1 : 0]   m_axis_b_tdata,
	//output                         m_axis_b_tvalid,
	//input                          m_axis_b_tready,
	
	input [DATA_WIDTH*2 - 1 : 0]   s_axis_result_tdata,
	input                         s_axis_result_tvalid
	//output reg                    s_axis_result_tready,	
);
	
	// ALU oppcodes
	localparam  SUM = 0,
				MULT = 1,
				DIV = 2;
	
	localparam STATE_WIDTH = 4;
	
	// FSM state transitions
	localparam IDLE      = 0,
			   F1_MULT   = 1,
			   I_POW2    = 2,
			   F2_MULT   = 3,
			   SUMM      = 4,
			   DIVIDE    = 5,
			   SEND      = 6;

	//
	reg [STATE_WIDTH - 1 : 0] state, next;	
	reg [DATA_WIDTH - 1 : 0] f1, f2, k;
	integer i;
	
	reg [DATA_WIDTH*2 - 1 : 0] f1_mult_result;
	
	/////////////////////////////////
	/* State machine */
	
	// FSM state
	always@(posedge aclk)
		if (!aresetn) state <= IDLE;
		else state <= next;
		
	// FSM transition logic
	always@(*)
		begin
		next = state;
		case(state)
		IDLE:
			if (s_axis_k_tvalid)
				next = F1_MULT;
		F1_MULT: // 1
			if (m_axis_a_tready)
				next = I_POW2;
		I_POW2: // 2
			if (s_axis_result_tvalid)
				next = F2_MULT;
		F2_MULT: // 3
			if (s_axis_result_tvalid)
				next = SUMM;
		SUMM: // 4
			if (s_axis_result_tvalid)
				next = DIVIDE;
		DIVIDE: // 5
			if (s_axis_result_tvalid)
				next = SEND;
		SEND:  // 8
			if (m_axis_ind_tready & m_axis_ind_tvalid) begin
				if (i < k - 1)
					next = F1_MULT;
				else
					next = IDLE;
			end
		default: next = IDLE;	    
		endcase
		end
		
	//////////////////////////////////
	// Receiving of input constatnts.
	// 
	// IDLE state
	//
	// S_AXI_F1, S_AXI_F2 and S_AXI_K implementations
	
	always@(posedge aclk)
		if (!aresetn) begin
			f1 <= 64'd0;
			f2 <= 64'd0;
			k  <= 64'd0;
			s_axis_k_tready <= 0;
		end else
			case(state)
			IDLE:
				if (s_axis_k_tvalid) begin
					f1 <= s_axis_f1_tdata;
					f2 <= s_axis_f2_tdata;
					k  <= s_axis_k_tdata;
					s_axis_k_tready <= 0;
				end else 
					s_axis_k_tready <= 1;
			endcase
	
	//////////////////////////////////
	// Interaction with ALU
	//	
	// States: F1_MULT, I_POW2, F2_MULT, SUMM, DIVIDE
	
	// Send to ALU
		
	always@(posedge aclk)
		if (!aresetn) begin
			o_alu_opp       <= 64'd0;
		    m_axis_a_tvalid <= 0;
			m_axis_a_tdata  <= 64'd0;
			m_axis_b_tdata  <= 64'd0;
		end else
			case (state)
			F1_MULT: // 1 // ... f1 * i ... 
				begin
				o_alu_opp <= MULT;
				m_axis_a_tvalid <= 1;
				m_axis_a_tdata  <= {32'd0, f1};
				m_axis_b_tdata  <= {32'd0, i};
				end
			I_POW2: // 2 // ... i^2 ...
				if (s_axis_result_tvalid) begin
					o_alu_opp <= MULT;
					m_axis_a_tvalid <= 1;
					m_axis_a_tdata  <= {32'd0, i};
					m_axis_b_tdata  <= {32'd0, i};
				end else
					m_axis_a_tvalid <= 0;
			F2_MULT: // 3 // ... f2 * i^2 ...
				if (s_axis_result_tvalid) begin
					o_alu_opp <= MULT;
					m_axis_a_tvalid <= 1;
					m_axis_a_tdata  <= {32'd0, f2};
					m_axis_b_tdata  <= s_axis_result_tdata;
				end else if (m_axis_a_tready)
					m_axis_a_tvalid <= 0;

			SUMM: // 4 // f1 * i + f2 * i^2
				if (s_axis_result_tvalid) begin
					o_alu_opp <= SUMM;
					m_axis_a_tvalid <= 1;
					m_axis_a_tdata  <= f1_mult_result;
					m_axis_b_tdata  <= s_axis_result_tdata;
				end else if (m_axis_a_tready)
					m_axis_a_tvalid <= 0;
			DIVIDE: // 5 // mod(f1 * i + f2 * i^2, K)
				if (s_axis_result_tvalid) begin
					o_alu_opp <= DIV;
					m_axis_a_tvalid <= 1;
					m_axis_a_tdata  <= s_axis_result_tdata;
					m_axis_b_tdata  <= {32'd0, k};
				end else if (m_axis_a_tready)
					m_axis_a_tvalid <= 0;
			default:
				m_axis_a_tvalid <= 0;
			endcase

	// Save intermediate result
	always@(posedge aclk)
		if (!aresetn) begin
		    f1_mult_result <= 64'd0;
		end else
			case (state)
			I_POW2:
				// Get result from previous step: F1_MULT
				if (s_axis_result_tvalid)
					f1_mult_result <= s_axis_result_tdata;
				else
					f1_mult_result <= f1_mult_result;
			endcase			
					
	//////////////////////////////////
	// Send result
	//	
	// Send state
	
	always@(posedge aclk)
		if (!aresetn) begin
			m_axis_ind_tvalid <= 0;
		    m_axis_ind_tdata  <= 32'd0;
		    m_axis_ind_tuser  <= 0;
		    m_axis_ind_tlast  <= 0;
		end else
			case(state)
			SEND:
				if (!m_axis_ind_tvalid) begin
					m_axis_ind_tvalid <= s_axis_result_tvalid;
					m_axis_ind_tdata <= s_axis_result_tvalid ? s_axis_result_tdata : m_axis_ind_tdata;
					m_axis_ind_tuser <= i == 0 ? s_axis_result_tvalid : 0;
					m_axis_ind_tlast <= i == k - 1 ? s_axis_result_tvalid : 0;
				end else begin
					m_axis_ind_tvalid <= !m_axis_ind_tready;
					m_axis_ind_tuser <= i == 0 ? !m_axis_ind_tready : 0;
					m_axis_ind_tlast <= i == k - 1 ? !m_axis_ind_tready : 0;
				end
				
			default:
				begin
				m_axis_ind_tvalid <= 0;
				m_axis_ind_tuser  <= 0;
				m_axis_ind_tlast  <= 0;
				end
			endcase
	
	
	/////////////////////////////////
	// i counter
	always@(posedge aclk)
		if (!aresetn) 
			i <= 0;
		else
			case(state)
			IDLE: 
				i <= 0;
			SEND:
				if (m_axis_ind_tready & m_axis_ind_tvalid)
					i <= i + 1;
			endcase
	
	
endmodule