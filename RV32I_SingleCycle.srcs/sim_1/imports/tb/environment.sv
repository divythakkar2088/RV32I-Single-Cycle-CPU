`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

// One environment runs one test (a directed program or one random program).
// regression.sv builds a fresh environment per seed so scoreboard/monitor
// state can't leak between runs, while a single coverage_collector is
// passed in and shared so coverage accumulates across the regression.
class environment;
    virtual cpu_if       vif;
    virtual cpu_probe_if pif;

    mailbox #(instr_transaction) gen2drv;
    mailbox #(instr_transaction) drv2sb;
    mailbox #(mon_transaction)   mon2sb;
    mailbox #(mon_transaction)   mon2cov;

    generator          gen;
    driver             drv;
    monitor            mon;
    scoreboard         sb;
    coverage_collector cov;

    function new(virtual cpu_if vif, virtual cpu_probe_if pif, coverage_collector cov);
        this.vif = vif;
        this.pif = pif;
        this.cov = cov;

        gen2drv = new();
        drv2sb  = new();
        mon2sb  = new();
        mon2cov = new();

        gen = new(gen2drv);
        drv = new(vif, gen2drv, drv2sb);
        mon = new(pif, mon2sb, mon2cov);
        sb  = new(mon2sb, drv2sb);
    endfunction

    task automatic run_directed();
        run_common("directed_regression", 1);
    endtask

    task automatic run_random();
        run_common("constrained_random", 0);
    endtask

    local task automatic cov_loop();
        mon_transaction m;
        forever begin
            mon2cov.get(m);
            cov.sample_instruction(m);
        end
    endtask

    local task automatic run_common(string name, bit directed);
        process mon_proc, sb_proc, cov_proc;

        $display("\n==== TEST: %s ====", name);
        if (directed) gen.gen_directed();
        else          gen.gen_random();

        // fork fresh for this test only, killed at the end -- not left
        // running for the rest of the simulation
        fork
            begin mon_proc = process::self(); mon.run(); end
            begin sb_proc  = process::self(); sb.run();  end
            begin cov_proc = process::self(); cov_loop(); end
        join_none

        mon.enabled = 1;
        cov.sample_reset();      // driver asserts rst as its first action below
        drv.load_and_run();
        mon.enabled = 0;

        #1; // let the last in-flight mailbox items drain before killing the loops
        mon_proc.kill();
        sb_proc.kill();
        cov_proc.kill();

        $display("---- %s complete (%0d instructions) ----", name, drv.num_instrs_loaded);
    endtask

    function void report();
        sb.report();
    endfunction
endclass

`endif
