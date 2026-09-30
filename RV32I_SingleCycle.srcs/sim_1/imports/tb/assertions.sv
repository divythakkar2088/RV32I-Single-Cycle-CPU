`ifndef ASSERTIONS_SV
`define ASSERTIONS_SV

// Structural invariants, checked every cycle. Bound directly into `top`
// like cpu_probe_if, so rtl/top.v stays untouched.
module cpu_assertions (
    input logic        clk,
    input logic        rst,
    input logic [31:0] pc_out,
    input logic [31:0] instr,
    input logic         memWrite,
    input logic         memRead,
    input logic         regWrite,
    input logic         branch,
    input logic         PCSrc,
    input logic         zero
);

    // cumulative fail count, read by regression.sv via a hierarchical path
    int unsigned fail_count = 0;

    property p_pc_aligned;
        @(posedge clk) disable iff (rst) pc_out[1:0] == 2'b00;
    endproperty
    a_pc_aligned: assert property (p_pc_aligned)
        else begin fail_count++; $error("[ASSERT] PC not word-aligned: pc_out=%0d", pc_out); end

    property p_instr_known;
        @(posedge clk) disable iff (rst) !$isunknown(instr);  // instr must not contain X or Z
    endproperty
    a_instr_known: assert property (p_instr_known)
        else begin fail_count++; $error("[ASSERT] instr has X/Z bits: %h", instr); end

    property p_memwrite_is_store;
        @(posedge clk) disable iff (rst) memWrite |-> (instr[6:0] == 7'b0100011); // memWrite = 1, then the instruction must be a STORE instruction
    endproperty
    a_memwrite_is_store: assert property (p_memwrite_is_store)
        else begin fail_count++; $error("[ASSERT] memWrite asserted on non-store instr=%h", instr); end

    property p_memread_is_load;
        @(posedge clk) disable iff (rst) memRead |-> (instr[6:0] == 7'b0000011); // If memRead = 1, the instruction must be a LOAD instruction
    endproperty
    a_memread_is_load: assert property (p_memread_is_load)
        else begin fail_count++; $error("[ASSERT] memRead asserted on non-load instr=%h", instr); end

    property p_pcsrc_needs_branch_and_zero;
        @(posedge clk) disable iff (rst) PCSrc |-> (branch && zero); // If PCSrc = 1, then both branch = 1 AND zero = 1 must be true
    endproperty
    a_pcsrc_valid: assert property (p_pcsrc_needs_branch_and_zero)  
        else begin fail_count++; $error("[ASSERT] PCSrc high without branch&&zero"); end

    function void reset_fail_count();
        fail_count = 0;
    endfunction

endmodule
// Attach cpu_assertions inside top and automatically connect signals with the same names
bind top cpu_assertions assertions_inst (.*);

`endif
