`ifndef CPU_INTERFACE_SV
`define CPU_INTERFACE_SV

// The DUT's only real ports: clk and rst. Driver uses this to control reset.
interface cpu_if (input logic clk);
    logic rst;
endinterface

// Read-only spy bound directly into `top` so we can see internal signals
// without touching rtl/top.v. Port names match top.v's internal wire names
// exactly, so `.*` wires everything up automatically.
interface cpu_probe_if (
    input logic        clk,
    input logic        rst,
    input logic [31:0] pc_out,
    input logic [31:0] instr,
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,
    input logic [31:0] immExt,
    input logic [31:0] ALU_result,
    input logic [31:0] memdata_out,
    input logic [31:0] write_data,
    input logic [31:0] branch_target,
    input logic        branch,
    input logic         memRead,
    input logic         memtoReg,
    input logic         memWrite,
    input logic         ALUsrc,
    input logic         regWrite,
    input logic         zero,
    input logic         PCSrc,
    input logic [1:0]  ALUop,
    input logic [3:0]  ALU_control_signal
);
endinterface

bind top cpu_probe_if probe_if_inst (.*);

`endif
