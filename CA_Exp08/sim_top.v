`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:01:35 01/10/2021
// Design Name:   top
// Module Name:   D:/AAuniversityTasks/CSComputerArch/TRUECourse/chap8Exp/work/sim_top.v
// Project Name:  exp9
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module sim_top;

	// Inputs
	reg clk;
	reg rst;

	// Outputs
	wire [7:0] clk_count;
	wire [7:0] inst_count;
	wire [7:0] hit_count;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clk(clk), 
		.rst(rst), 
		.clk_count(clk_count), 
		.inst_count(inst_count), 
		.hit_count(hit_count)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#95 rst = 0;
        
		// Add stimulus here
		

	end
	
	initial forever #10 clk = ~clk;
      
endmodule

