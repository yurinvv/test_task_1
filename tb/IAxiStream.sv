`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Yurin VV
// Create Date: 07.2022
// Module Name: IAxiStream
// Project Name: Some DAC
// Tool Versions: Vivado 2018.2
// Description: AXI-Stream interface
//////////////////////////////////////////////////////////////////////////////////
interface IAxiStream #(	
	parameter DATA_SIZE = 32,
	parameter ID_SIZE = 4
	)(
	input logic aclk
	//input logic areset_n
	);
	
	//--------------------------------
	logic                      tvalid;
	logic                      tready;
	logic                      tlast;
	logic[DATA_SIZE - 1 : 0]   tdata;
	logic[ID_SIZE - 1 : 0]     tid;
	logic[DATA_SIZE/8 - 1 : 0] tkeep;
	logic[DATA_SIZE/8 - 1 : 0] tstrb;
	
	//--------------------------------
	modport Master(
		output tvalid,
		input  tready,
		output tlast,
		output tdata,
		output tid,
		output tkeep,
		output tstrb
	);
	
	modport Slave(
		input  tvalid,
		output tready,
		input  tlast,
		input  tdata,
		input  tid,
		input  tkeep,
		input  tstrb
	);

	task init();
		{tvalid, tready, tlast, tdata, tid} = '0;
	endtask

	task m_init();
		{tvalid, tlast, tdata, tid} = '0;
	endtask

	task sendSingleData(input[DATA_SIZE - 1 : 0] data);
		@(posedge aclk);
		#1;
		tvalid <= 1;
		tdata <= data;
		tlast <= 1;
		wait(tready);
		@(posedge aclk);
		#1;
		tvalid <= 0;
		//tdata <= 0;
		tlast <= 0;
	endtask
	
	// Assertion

endinterface // IAxiStream