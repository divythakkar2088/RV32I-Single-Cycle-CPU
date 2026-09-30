`ifndef COVERAGE_SV
`define COVERAGE_SV

typedef enum {ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_UNKNOWN} alu_op_e;
typedef enum {MEM_NONE, MEM_LOAD, MEM_STORE}                  mem_op_e;
typedef enum {BR_NA, BR_TAKEN, BR_NOT_TAKEN}                  branch_outcome_e;

// Passive functional coverage. Never touches the DUT -- it only receives
// mon_transaction samples from the environment, plus a notification on
// each reset. One instance is shared across a whole regression so coverage
// accumulates across seeds instead of resetting.
class coverage_collector;
    instr_kind_e     cur_kind;
    alu_op_e         cur_alu_op;
    bit [4:0]        cur_rd, cur_rs1, cur_rs2;
    mem_op_e         cur_mem_op;
    branch_outcome_e cur_branch_outcome;

    bit reset_hit;
    int reset_count = 0;

    covergroup cg_instr;
        option.per_instance = 1;
        option.name = "cg_instr";

        cp_kind: coverpoint cur_kind;

        // explicit bins, not enum auto-bins + ignore_bins -- more portable
        cp_alu: coverpoint cur_alu_op {
            bins add_op = {ALU_ADD};
            bins sub_op = {ALU_SUB};
            bins and_op = {ALU_AND};
            bins or_op  = {ALU_OR};
        }

        cp_rd: coverpoint cur_rd {
            bins zero = {0};
            bins low  = {[1:15]};
            bins high = {[16:31]};
        }

        cp_rs1: coverpoint cur_rs1 {
            bins zero = {0};
            bins low  = {[1:15]};
            bins high = {[16:31]};
        }

        cp_rs2: coverpoint cur_rs2 {
            bins zero = {0};
            bins low  = {[1:15]};
            bins high = {[16:31]};
        }

        cp_mem_op: coverpoint cur_mem_op;
        cp_branch_outcome: coverpoint cur_branch_outcome;

        // which instruction types write to which part of the register file
        cross_kind_rd: cross cp_kind, cp_rd;

        // do loads/stores span the full destination-register range
        cross_memop_rd: cross cp_mem_op, cp_rd {
            ignore_bins ig_none = binsof(cp_mem_op) intersect {MEM_NONE};
        }
    endgroup

    covergroup cg_reset;
        option.per_instance = 1;
        option.name = "cg_reset";
        cp_reset: coverpoint reset_hit {
            bins seen = {1};
        }
    endgroup

    function new();
        cg_instr = new();
        cg_reset = new();
    endfunction

    function void sample_instruction(mon_transaction m);
        bit [6:0] opcode = m.instr[6:0];

        cur_kind = decode_instr_kind(m.instr);

        case (m.ALU_control_signal)
            4'b0010: cur_alu_op = ALU_ADD;
            4'b0110: cur_alu_op = ALU_SUB;
            4'b0000: cur_alu_op = ALU_AND;
            4'b0001: cur_alu_op = ALU_OR;
            default: begin
                cur_alu_op = ALU_UNKNOWN;
                $display("[COV] WARNING: unrecognized ALU_control_signal=%b @ %0t",
                          m.ALU_control_signal, $time);
            end
        endcase

        cur_rd  = m.instr[11:7];
        cur_rs1 = m.instr[19:15];
        cur_rs2 = m.instr[24:20];

        if (opcode == 7'b0000011)      cur_mem_op = MEM_LOAD;
        else if (opcode == 7'b0100011) cur_mem_op = MEM_STORE;
        else                           cur_mem_op = MEM_NONE;

        if (opcode == 7'b1100011) cur_branch_outcome = m.PCSrc ? BR_TAKEN : BR_NOT_TAKEN;
        else                      cur_branch_outcome = BR_NA;

        cg_instr.sample();
    endfunction

    function void sample_reset();
        reset_hit = 1;
        reset_count++;
        cg_reset.sample();
    endfunction

    function real overall_coverage();
        return (cg_instr.get_coverage() + cg_reset.get_coverage()) / 2.0;
    endfunction

    function void report();
        $display("\n---- FUNCTIONAL COVERAGE REPORT ----");
        $display("cp_kind              : %0.2f%%", cg_instr.cp_kind.get_coverage());
        $display("cp_alu               : %0.2f%%", cg_instr.cp_alu.get_coverage());
        $display("cp_rd                : %0.2f%%", cg_instr.cp_rd.get_coverage());
        $display("cp_rs1               : %0.2f%%", cg_instr.cp_rs1.get_coverage());
        $display("cp_rs2               : %0.2f%%", cg_instr.cp_rs2.get_coverage());
        $display("cp_mem_op            : %0.2f%%", cg_instr.cp_mem_op.get_coverage());
        $display("cp_branch_outcome    : %0.2f%%", cg_instr.cp_branch_outcome.get_coverage());
        $display("cross_kind_rd        : %0.2f%%", cg_instr.cross_kind_rd.get_coverage());
        $display("cross_memop_rd       : %0.2f%%", cg_instr.cross_memop_rd.get_coverage());
        $display("cg_instr (group)     : %0.2f%%", cg_instr.get_coverage());
        $display("cp_reset             : %0.2f%% (reset pulses observed: %0d)",
                  cg_reset.get_coverage(), reset_count);
        $display("OVERALL COVERAGE     : %0.2f%%", overall_coverage());
    endfunction
endclass

`endif
