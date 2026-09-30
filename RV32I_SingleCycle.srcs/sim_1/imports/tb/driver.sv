`ifndef DRIVER_SV
`define DRIVER_SV

// This DUT has no instruction/data bus, so the only way to load a program
// is a backdoor poke of instr_mem's ROM array via an absolute hierarchical
// path -- the same trick tb_top.v already used to read final state.
class driver;
    virtual cpu_if vif;
    mailbox #(instr_transaction) gen2drv;
    mailbox #(instr_transaction) drv2sb;
    int num_instrs_loaded = 0;

    function new(virtual cpu_if vif,
                  mailbox #(instr_transaction) gen2drv,
                  mailbox #(instr_transaction) drv2sb);
        this.vif     = vif;
        this.gen2drv = gen2drv;
        this.drv2sb  = drv2sb;
    endfunction

    task automatic load_and_run();
        instr_transaction t;
        int idx;

        vif.rst = 1;
        idx = 0;

        // load the whole program before the first posedge, so the CPU never
        // fetches a stale/uninitialized word
        while (gen2drv.try_get(t)) begin
            top_tb.dut.IM.memory[idx] = t.encode();
            drv2sb.put(t);
            idx++;
        end
        num_instrs_loaded = idx;
        $display("[DRV] Loaded %0d instructions into instr_mem ROM", num_instrs_loaded);

        repeat (2) @(posedge vif.clk);
        vif.rst = 0;
        $display("[DRV] Reset released @ %0t", $time);

        // one posedge commits one instruction on this single-cycle CPU
        repeat (num_instrs_loaded) @(posedge vif.clk);

        #1; // let the last cycle's non-blocking writes settle
    endtask
endclass

`endif
