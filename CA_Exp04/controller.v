`include "define.vh"


/**
 * Controller for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module controller (/*AUTOARG*/
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	`endif
	// instruction decode
	input wire [31:0] inst,  // instruction
	//!! input wire is_branch_exe,  // whether instruction in EXE stage is jump/branch instruction
	input wire [4:0] regw_addr_exe,  // register write address from EXE stage
	input wire wb_wen_exe,  // register write enable signal feedback from EXE stage
	//!! input wire is_branch_mem,  // whether instruction in MEM stage is jump/branch instruction
	input wire [4:0] regw_addr_mem,  // register write address from MEM stage
	input wire wb_wen_mem, 	// register write enable signal feedback from MEM stage
	input wire is_load_exe,
	output reg is_load,
	output reg [2:0] pc_src,  // how would PC change to next
	output reg imm_ext,  // whether using sign extended to immediate data
	output reg [1:0] exe_a_src,  // data source of operand A for ALU
	output reg [1:0] exe_b_src,  // data source of operand B for ALU
	output reg [3:0] exe_alu_oper,  // ALU operation type
	output reg mem_ren,  // memory read enable signal
	output reg mem_wen,  // memory write enable signal
	output reg [1:0] wb_addr_src,  // address source to write data back to registers
	output reg wb_data_src,  // data source of data being written back to registers
	output reg wb_wen,  // register write enable signal
	output reg unrecognized,  // whether current instruction can not be recognized
	// pipeline control
	output reg if_rst,  // stage reset signal
	output reg if_en,  // stage enable signal
	input wire if_valid,  // stage valid flag
	output reg id_rst,
	output reg id_en,
	input wire id_valid,
	output reg exe_rst,
	output reg exe_en,
	input wire exe_valid,
	output reg mem_rst,
	output reg mem_en,
	input wire mem_valid,
	output reg wb_rst,
	output reg wb_en,
	input wire wb_valid,
	input wire [4:0] regw_addr_wb,
	input wire mem_ren_mem,
	input wire wb_wen_wb,
	
	output reg [1:0] exe_fwd_a_ctrl,
	output reg [1:0] exe_fwd_b_ctrl,

	//!! added signla;
	input wire rs_rt_equal,
	output reg fwd_m
	);
	
	`include "mips_define.vh"
	
	// instruction decode
	reg rs_used, rt_used;//used means read the value of the register(rs/rt)
	//!! instruction decode append
	reg is_store;
	//reg is_load_exe;
	reg load_stall;

	
	always @(*) begin
	is_store=0;
	is_load=0;
		pc_src = PC_NEXT;
		imm_ext = 0;
		exe_a_src = EXE_A_RS;
		exe_b_src = EXE_B_RT;
		exe_alu_oper = EXE_ALU_ADD;
		mem_ren = 0;
		mem_wen = 0;
		wb_addr_src = WB_ADDR_RD;
		wb_data_src = WB_DATA_ALU;
		wb_wen = 0;
		rs_used = 0;
		rt_used = 0;
		unrecognized = 0;
		case (inst[31:26])
			INST_R: begin
				case (inst[5:0])
					R_FUNC_JR: begin
						pc_src = PC_JR;
						rs_used = 1;
					end
					R_FUNC_ADD: begin
						exe_alu_oper = EXE_ALU_ADD;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SUB: begin
						exe_alu_oper = EXE_ALU_SUB;//
						wb_addr_src = WB_ADDR_RD;//
						wb_data_src = WB_DATA_ALU;//
						wb_wen = 1;////
						rs_used = 1;////
						rt_used = 1;////
					end
					R_FUNC_AND: begin
						exe_alu_oper = EXE_ALU_AND;//
						wb_addr_src = WB_ADDR_RD;//
						wb_data_src = WB_DATA_ALU;//
						wb_wen = 1;////
						rs_used = 1;////
						rt_used = 1;////
					end
					R_FUNC_OR: begin
						exe_alu_oper = EXE_ALU_OR;//
						wb_addr_src = WB_ADDR_RD;//
						wb_data_src = WB_DATA_ALU;//
						wb_wen = 1;////
						rs_used = 1;////
						rt_used = 1;////
					end
					R_FUNC_SLT: begin
						exe_alu_oper = EXE_ALU_SLT;//
						wb_addr_src = WB_ADDR_RD;//
						wb_data_src = WB_DATA_ALU;//
						wb_wen = 1;//
						rs_used = 1;//
						rt_used = 1;//
					end
					default: begin
						unrecognized = 1;
					end
				endcase
			end
			INST_J: begin
				pc_src = PC_JUMP;
			end
			INST_JAL: begin
				pc_src = PC_JUMP;//
				exe_a_src = EXE_A_NEXT;//
				exe_b_src = EXE_B_FOUR;//
				exe_alu_oper = EXE_ALU_ADD;//
				wb_addr_src = WB_ADDR_LINK;//
				wb_data_src = WB_DATA_ALU;//
				wb_wen = 1;
			end
			INST_BEQ: begin
				pc_src = rs_rt_equal ? PC_BRANCH:PC_NEXT;//
				imm_ext = 1;//
				rs_used = 1;////
				rt_used = 1;////
			end
			INST_BNE: begin
				pc_src = rs_rt_equal ? PC_NEXT:PC_BRANCH;//
				imm_ext = 1;//
				rs_used = 1;//
				rt_used = 1;//
			end
			INST_ADDI: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_ANDI: begin
				imm_ext = 0;//n<0 not considered
				exe_b_src = EXE_B_IMM;//
				exe_alu_oper =EXE_ALU_AND;//
				wb_addr_src = WB_ADDR_RT;//
				wb_data_src = WB_DATA_ALU;//
				wb_wen = 1;//
				rs_used = 1;////
			end
			INST_ORI: begin
				imm_ext = 0;//n<0 not considered
				exe_b_src = EXE_B_IMM;//
				exe_alu_oper = EXE_ALU_OR;//
				wb_addr_src = WB_ADDR_RT;//
				wb_data_src = WB_DATA_ALU;//
				wb_wen = 1;///
				rs_used = 1;////
			end
			INST_LW: begin
				imm_ext = 1;//
				exe_b_src = EXE_B_IMM;//
				exe_alu_oper = EXE_ALU_ADD;//
				mem_ren = 1;//
				wb_addr_src = WB_ADDR_RT;//
				wb_data_src = WB_DATA_MEM;//
				wb_wen = 1;//
				rs_used = 1;////
				is_load = 1; //!!
			end
			INST_SW: begin
				imm_ext = 1;//
				exe_b_src = EXE_B_IMM;//
				exe_alu_oper = EXE_ALU_ADD;//
				mem_wen = 1;//
				rs_used = 1;//
				rt_used = 1;//
				is_store = 1;//!!
			end
			default: begin
				unrecognized = 1;
			end
		endcase
	end
	
	// pipeline control
	//! reg reg_stall;
	reg branch_stall;
	wire [4:0] addr_rs, addr_rt;///
	
	assign
		addr_rs = inst[25:21],
		addr_rt = inst[20:16];
	
	always @(*) begin////PPT27ҳ
		exe_fwd_a_ctrl = ID_A_FWD_RS;
		exe_fwd_b_ctrl = ID_B_FWD_RT;
		//exe_fwd_a_ctrl is parallel to fwd_a_ctrl
		//so is exe_fwd_b_ctrl is parrel to fwd_b_ctrl
		fwd_m = 1'b0;
		load_stall = 1'b0;
		if (wb_wen_mem && regw_addr_mem != 0) begin////
			if (regw_addr_mem == addr_rs)
				exe_fwd_a_ctrl = ID_A_FWD_MEMIN;
			if(regw_addr_mem == addr_rt)
				exe_fwd_b_ctrl = ID_B_FWD_MEMIN;
			if(regw_addr_mem == addr_rs && mem_ren_mem)
				exe_fwd_a_ctrl = ID_A_FWD_MEMOUT;
			if(regw_addr_mem == addr_rt && mem_ren_mem)
				exe_fwd_b_ctrl = ID_B_FWD_MEMOUT;
		end
		if(wb_wen_exe && regw_addr_exe != 0) begin////
			if(regw_addr_exe == addr_rs)////
				exe_fwd_a_ctrl = ID_A_FWD_ALUOUT;////
			if(regw_addr_exe == addr_rt)////
				exe_fwd_b_ctrl = ID_B_FWD_ALUOUT;////
		end	////

		if (rt_used && regw_addr_exe == addr_rt && wb_wen_exe && is_load_exe && is_store) begin
			fwd_m = 1;
		end	

		if((rs_used && regw_addr_exe == addr_rs && wb_wen_exe && is_load_exe)
			|| (rt_used && regw_addr_exe == addr_rt && wb_wen_exe && is_load_exe && ~is_store)) begin
				load_stall = 1;
			end
	end

	always @(*) begin////PPT28
	/*!!	branch_stall = 0;
		if (pc_src != PC_NEXT || is_branch_mem || is_branch_exe)////
			branch_stall = 1;
	*/
	end
	
	`ifdef DEBUG
	reg debug_step_prev;
	
	always @(posedge clk) begin
		debug_step_prev <= debug_step;
	end
	`endif
	
	always @(*) begin
		if_rst = 0;
		if_en = 1;
		id_rst = 0;
		id_en = 1;
		exe_rst = 0;
		exe_en = 1;
		mem_rst = 0;
		mem_en = 1;
		wb_rst = 0;
		wb_en = 1;
		if (rst) begin
			if_rst = 1;
			id_rst = 1;
			exe_rst = 1;
			mem_rst = 1;
			wb_rst = 1;
		end
		`ifdef DEBUG
		// suspend and step execution
		else if ((debug_en) && ~(~debug_step_prev && debug_step)) begin
			if_en = 0;
			id_en = 0;
			exe_en = 0;
			mem_en = 0;
			wb_en = 0;
		end
		`endif

		else if (load_stall) begin
			if_en = 0;
			id_en = 0;
			exe_rst = 1;
		end		
	end
	
endmodule
