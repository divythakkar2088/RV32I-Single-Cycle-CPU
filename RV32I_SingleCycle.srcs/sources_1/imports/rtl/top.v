module top(clk, rst);
    input clk, rst;

    wire [31:0] pc_in, pc_out, pc_plus4;
    wire [31:0] instr;
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] immExt;
    wire [31:0] ALU_result;
    wire [31:0] memdata_out;
    wire [31:0] aluin2;
    wire [31:0] branch_target;
    wire [31:0] write_data;

    wire branch, memRead, memtoReg, memWrite, ALUsrc, regWrite;
    wire [1:0] ALUop;
    wire zero, PCSrc;
    wire [3:0] ALU_control_signal;

    // Program Counter
    program_counter PC(clk, rst, pc_in, pc_out);

    // PC + 4
    pcAdd4 PCAdd4(pc_out, pc_plus4);

    // Instruction Memory (COMBINATIONAL)
    instr_mem IM(pc_out, instr);

    // Register File
    reg_file RF(
        .clk(clk),
        .rst(rst),
        .rs1(instr[19:15]),
        .rs2(instr[24:20]),
        .rd(instr[11:7]),
        .regwrite(regWrite),
        .write_data(write_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Immediate Generator
    immGen IG(instr[6:0], instr, immExt);

    // Main Control Unit
    control_unit CU(
        instr[6:0],
        branch,
        memRead,
        memtoReg,
        ALUop,
        memWrite,
        ALUsrc,
        regWrite
    );

    // ALU Control
    ALU_control ALUCtrl(
        ALUop,
        instr[14:12],
        instr[30],
        instr[5],
        ALU_control_signal
    );

    // ALU input mux
    mux_2to1 alu_mux(rs2_data, immExt, ALUsrc, aluin2);

    // ALU
    ALU_unit ALU(rs1_data, aluin2, ALU_control_signal, ALU_result, zero);

    // Branch target = PC + imm
    addr branch_addr(pc_out, immExt, branch_target);

    // Branch decision
    and_gate branch_and(zero, branch, PCSrc);

    // PC select
    mux_2to1 pc_mux(pc_plus4, branch_target, PCSrc, pc_in);

    // Data Memory
    data_memory DM(
        clk,
        rst,
        memRead,
        memWrite,
        ALU_result,
        rs2_data,
        memdata_out
    );

    // Writeback mux
    mux_2to1 result_mux(ALU_result, memdata_out, memtoReg, write_data);

endmodule
