`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

// Per-cycle predictor, not a stateful reference CPU. Takes the actual
// observed operands (rs1_data, rs2_data, memdata_out) and re-derives what
// immGen/control_unit/ALU_control/ALU_unit should have produced, then
// compares against what the DUT actually shows. Also checks PC sequencing.
class scoreboard;
    mailbox #(mon_transaction) mon2sb;
    mailbox #(instr_transaction) drv2sb;
    int num_checked = 0;
    int num_errors  = 0;

    bit        have_pending_pc;
    bit [31:0] predicted_next_pc;

    function new(mailbox #(mon_transaction) mon2sb, mailbox #(instr_transaction) drv2sb);
        this.mon2sb = mon2sb;
        this.drv2sb = drv2sb;
        have_pending_pc = 0;
    endfunction

    // reference models, mirroring the RTL's combinational logic
    local function bit [31:0] f_immGen(bit [6:0] opcode, bit [31:0] instr);
        case (opcode)
            7'b0000011, 7'b0010011: f_immGen = {{20{instr[31]}}, instr[31:20]};
            7'b0100011:             f_immGen = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011:             f_immGen = {{19{instr[31]}}, instr[31], instr[30:25], instr[11:8], 1'b0};
            default:                f_immGen = 32'b0;
        endcase
    endfunction

    local function void f_control(input bit [6:0] opcode,
                                   output bit branch, memRead, memtoReg, memWrite, ALUsrc, regWrite,
                                   output bit [1:0] ALUop);
        branch = 0; memRead = 0; memtoReg = 0; ALUop = 2'b00; memWrite = 0; ALUsrc = 0; regWrite = 0;
        case (opcode)
            7'b0110011: begin ALUsrc = 0; regWrite = 1; ALUop = 2'b10; end
            7'b0010011: begin ALUsrc = 1; regWrite = 1; ALUop = 2'b10; end
            7'b0000011: begin ALUsrc = 1; memtoReg = 1; regWrite = 1; memRead = 1; ALUop = 2'b00; end
            7'b0100011: begin ALUsrc = 1; memWrite = 1; ALUop = 2'b00; end
            7'b1100011: begin branch = 1; ALUop = 2'b01; end
            default: ;
        endcase
    endfunction

    local function bit [3:0] f_alu_control(bit [1:0] ALUop, bit [2:0] funct3, bit funct7, bit is_Rtype);
        case (ALUop)
            2'b00: f_alu_control = 4'b0010;
            2'b01: f_alu_control = 4'b0110;
            2'b10: begin
                case (funct3)
                    3'b000:  f_alu_control = (funct7 && is_Rtype) ? 4'b0110 : 4'b0010;
                    3'b111:  f_alu_control = 4'b0000;
                    3'b110:  f_alu_control = 4'b0001;
                    default: f_alu_control = 4'b0010;
                endcase
            end
            default: f_alu_control = 4'b0010;
        endcase
    endfunction

    local function bit [31:0] f_alu(bit [31:0] a, b, bit [3:0] ctrl);
        case (ctrl)
            4'b0000: f_alu = a & b;
            4'b0001: f_alu = a | b;
            4'b0010: f_alu = a + b;
            4'b0110: f_alu = a - b;
            default: f_alu = 32'b0;
        endcase
    endfunction

    task automatic run();
        mon_transaction m;
        forever begin
            mon2sb.get(m);
            check(m);
        end
    endtask

    local task automatic check(mon_transaction m);
        bit [6:0] opcode  = m.instr[6:0];
        bit [2:0] funct3  = m.instr[14:12];
        bit       funct7  = m.instr[30];
        bit       is_Rtyp = m.instr[5];

        bit        e_branch, e_memRead, e_memtoReg, e_memWrite, e_ALUsrc, e_regWrite;
        bit [1:0]  e_ALUop;
        bit [3:0]  e_alu_ctrl;
        bit [31:0] e_imm, e_alu_result, e_write_data, e_branch_target, aluin2;
        bit        e_zero, e_PCSrc;

        num_checked++;

        // PC predicted by the previous cycle
        if (have_pending_pc && m.pc_out !== predicted_next_pc) begin
            $display("[SB] FAIL @%0t: pc_out=%0d, expected %0d (branch/PC+4 mismatch)",
                      $time, m.pc_out, predicted_next_pc);
            num_errors++;
        end

        e_imm = f_immGen(opcode, m.instr);
        f_control(opcode, e_branch, e_memRead, e_memtoReg, e_memWrite, e_ALUsrc, e_regWrite, e_ALUop);
        e_alu_ctrl = f_alu_control(e_ALUop, funct3, funct7, is_Rtyp);
        aluin2 = e_ALUsrc ? e_imm : m.rs2_data;
        e_alu_result = f_alu(m.rs1_data, aluin2, e_alu_ctrl);
        e_zero = (e_alu_result == 32'b0);
        e_PCSrc = e_branch & e_zero;
        e_write_data = e_memtoReg ? m.memdata_out : e_alu_result;
        e_branch_target = m.pc_out + e_imm;

        check_field("immExt",     m.immExt,             e_imm);
        check_field("branch",     m.branch,             e_branch);
        check_field("memRead",    m.memRead,            e_memRead);
        check_field("memtoReg",   m.memtoReg,            e_memtoReg);
        check_field("memWrite",   m.memWrite,            e_memWrite);
        check_field("ALUsrc",     m.ALUsrc,              e_ALUsrc);
        check_field("regWrite",   m.regWrite,            e_regWrite);
        check_field("ALUop",      m.ALUop,               e_ALUop);
        check_field("ALUctrl",    m.ALU_control_signal, e_alu_ctrl);
        check_field("ALU_result", m.ALU_result,          e_alu_result);
        check_field("zero",       m.zero,                e_zero);
        check_field("PCSrc",      m.PCSrc,               e_PCSrc);
        check_field("write_data", m.write_data,          e_write_data);
        if (e_branch)
            check_field("branch_target", m.branch_target, e_branch_target);

        predicted_next_pc = e_PCSrc ? e_branch_target : (m.pc_out + 4);
        have_pending_pc = 1;
    endtask

    local function void check_field(string name, logic [31:0] actual, logic [31:0] expected);
        if (actual !== expected) begin
            $display("[SB] FAIL @%0t: %s = %0h, expected %0h", $time, name, actual, expected);
            num_errors++;
        end
    endfunction

    // call between back-to-back runs so a reset pulse doesn't cause a false
    // PC mismatch against the previous run's last instruction
    function void reset_pc_tracking();
        have_pending_pc = 0;
    endfunction

    function void report();
        $display("\n---- SCOREBOARD REPORT ----");
        $display("checked=%0d  errors=%0d", num_checked, num_errors);
        if (num_errors == 0) $display("RESULT: ALL CHECKS PASSED");
        else                 $display("RESULT: %0d CHECK(S) FAILED", num_errors);
    endfunction
endclass

`endif
