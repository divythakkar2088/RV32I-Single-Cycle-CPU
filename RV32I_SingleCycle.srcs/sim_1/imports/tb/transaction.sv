`ifndef TRANSACTION_SV
`define TRANSACTION_SV

// Only the instructions control_unit.v / ALU_control.v actually support.
typedef enum {ADDI, ADD, SUB, AND_OP, OR_OP, LW, SW, BEQ} instr_kind_e;

// Inverse of encode() below -- decodes a raw instruction word back to a kind.
function automatic instr_kind_e decode_instr_kind(bit [31:0] w);
    bit [6:0] opcode = w[6:0];
    bit [2:0] funct3 = w[14:12];
    bit       funct7 = w[30];
    case (opcode)
        7'b0010011: decode_instr_kind = ADDI;
        7'b0000011: decode_instr_kind = LW;
        7'b0100011: decode_instr_kind = SW;
        7'b1100011: decode_instr_kind = BEQ;
        7'b0110011: begin
            case (funct3)
                3'b111:  decode_instr_kind = AND_OP;
                3'b110:  decode_instr_kind = OR_OP;
                default: decode_instr_kind = funct7 ? SUB : ADD;
            endcase
        end
        default: decode_instr_kind = ADDI; // unreachable for a valid program
    endcase
endfunction


// STIMULUS: one randomizable RV32I instruction. The generator builds a
// program (queue of these); the driver encodes each one into the ROM.
class instr_transaction;
    rand instr_kind_e     kind;
    rand bit [4:0]        rd;
    rand bit [4:0]        rs1;
    rand bit [4:0]        rs2;
    rand bit signed [11:0] imm_i;   // I-/S-type immediate
    rand bit signed [12:0] imm_b;   // branch immediate (bit0 always 0)

    bit [31:0] word;  // filled in by encode()

    constraint c_regs {
        rd  inside {[1:31]};   // Destination cannot be x0
        rs1 inside {[0:31]};
        rs2 inside {[0:31]};
    }

    // keep loads/stores in-bounds for the 64-entry data_memory array
    constraint c_mem {
        (kind inside {LW, SW}) -> rs1 == 0;
        (kind inside {LW, SW}) -> imm_i inside {[0:252]};
        (kind inside {LW, SW}) -> (imm_i % 4 == 0);
    }

    constraint c_alu_imm {
        (kind == ADDI) -> imm_i inside {[-2048:2047]};
    }

// Transaction fields to 32-bit RISC-V instruction
    function bit [31:0] encode();
        unique case (kind)
            ADDI:   word = {imm_i,               rs1, 3'b000, rd,          7'b0010011};
            ADD:    word = {7'b0000000, rs2,     rs1, 3'b000, rd,          7'b0110011};
            SUB:    word = {7'b0100000, rs2,     rs1, 3'b000, rd,          7'b0110011};
            AND_OP: word = {7'b0000000, rs2,     rs1, 3'b111, rd,          7'b0110011};
            OR_OP:  word = {7'b0000000, rs2,     rs1, 3'b110, rd,          7'b0110011};
            LW:     word = {imm_i,               rs1, 3'b010, rd,          7'b0000011};
            SW:     word = {imm_i[11:5], rs2,    rs1, 3'b010, imm_i[4:0],  7'b0100011};
            BEQ:    word = {imm_b[12], imm_b[10:5], rs2, rs1, 3'b000,
                             imm_b[4:1], imm_b[11],                        7'b1100011};
        endcase
        return word;
    endfunction

    function void display(string tag = "");
        $display("[TXN%s] kind=%-6s rd=x%0d rs1=x%0d rs2=x%0d imm_i=%0d word=%08h",
                  tag, kind.name(), rd, rs1, rs2, imm_i, word);
    endfunction
endclass


// OBSERVED: one cycle's worth of DUT internal state, sampled by the
// monitor. The scoreboard re-derives the expected values from these fields.
class mon_transaction;
    bit [31:0] pc_out;
    bit [31:0] instr;
    bit [31:0] rs1_data, rs2_data;
    bit [31:0] immExt;
    bit [31:0] ALU_result;
    bit [31:0] memdata_out;
    bit [31:0] write_data;
    bit [31:0] branch_target;
    bit        branch, memRead, memtoReg, memWrite, ALUsrc, regWrite, zero, PCSrc;
    bit [1:0]  ALUop;
    bit [3:0]  ALU_control_signal;

    function void display();
        $display("[MON] PC=%0d instr=%08h regWrite=%0b rd=%0d write_data=%0d memWrite=%0b",
                  pc_out, instr, regWrite, instr[11:7], write_data, memWrite);
    endfunction
endclass

`endif
