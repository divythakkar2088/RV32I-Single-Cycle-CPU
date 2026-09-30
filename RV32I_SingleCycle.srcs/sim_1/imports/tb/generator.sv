`ifndef GENERATOR_SV
`define GENERATOR_SV

// Builds the program the driver loads into the DUT. gen_directed() replays
// the original tb_top.v regression; gen_random() makes n constrained-random
// straight-line instructions (no branches, so PC tracking stays simple).
class generator;
    mailbox #(instr_transaction) gen2drv;
    int num_random_instrs = 30;

    function new(mailbox #(instr_transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task automatic gen_directed();
        instr_transaction t;
        t = mk(ADDI, 1, 0, 0, 10);        gen2drv.put(t);
        t = mk(ADDI, 2, 0, 0, 20);        gen2drv.put(t);
        t = mk(ADD,  3, 1, 2, 0);         gen2drv.put(t);
        t = mk(SW,   0, 0, 3, 0);         gen2drv.put(t);
        t = mk(LW,   4, 0, 0, 0);         gen2drv.put(t);
        t = mk(BEQ,  0, 3, 4, 8);         gen2drv.put(t);
        t = mk(ADDI, 5, 0, 0, 1);         gen2drv.put(t);  // skipped by the branch
        t = mk(ADDI, 5, 0, 0, 99);        gen2drv.put(t);
        t = mk(ADDI, 6, 0, 0, -1);        gen2drv.put(t);
        t = mk(SUB,  7, 1, 2, 0);         gen2drv.put(t);
        t = mk(AND_OP, 8, 1, 2, 0);       gen2drv.put(t);
        t = mk(OR_OP,  9, 1, 2, 0);       gen2drv.put(t);
        t = mk(ADDI, 10, 0, 0, 5);        gen2drv.put(t);
        t = mk(BEQ,  0, 1, 10, 8);        gen2drv.put(t);  // not taken
        t = mk(ADDI, 11, 0, 0, 111);      gen2drv.put(t);
        t = mk(ADDI, 12, 0, 0, 222);      gen2drv.put(t);
    endtask

    task automatic gen_random();
        instr_transaction t;
        repeat (num_random_instrs) begin
            t = new();
            if (!t.randomize() with {
                    kind inside {ADDI, ADD, SUB, AND_OP, OR_OP, LW, SW};
                })
                $fatal(1, "generator: randomize() failed");
            gen2drv.put(t);
        end
    endtask

    local function instr_transaction mk(instr_kind_e k, int rd, int rs1, int rs2, int imm);
        instr_transaction t = new();
        t.kind = k; t.rd = rd; t.rs1 = rs1; t.rs2 = rs2;
        t.imm_i = imm; t.imm_b = imm;
        return t;
    endfunction
endclass

`endif
