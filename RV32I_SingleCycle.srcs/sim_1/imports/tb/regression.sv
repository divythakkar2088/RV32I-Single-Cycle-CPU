`ifndef REGRESSION_SV
`define REGRESSION_SV

// Runs the existing generator/driver/monitor/scoreboard architecture across
// NUM_SEEDS seeds plus one directed baseline, without changing any of those
// classes' responsibilities. A fresh environment is built per seed for a
// clean reset; the coverage_collector is reused so coverage accumulates.

// Regression is basically the manager that runs the whole verification multiple times with different random seeds
class regression_manager;
    // ---- single configuration point ----
    int NUM_SEEDS         = 10;
    int NUM_RANDOM_INSTRS = 30;   // random instructions generated per seed
    int BASE_SEED         = 100;  // seeds used: BASE_SEED .. BASE_SEED+NUM_SEEDS-1

    virtual cpu_if       vif;
    virtual cpu_probe_if pif;

    coverage_collector cov;

    int total_checked  = 0;
    int total_errors   = 0;
    int seeds_run       = 0;
    int seeds_failed     = 0;
    
// the constructor receives the interfaces and creates the coverage collector.
    function new(virtual cpu_if vif, virtual cpu_probe_if pif);
        this.vif = vif;
        this.pif = pif;
        cov = new();
    endfunction

    task automatic run();
        // directed smoke test, kept separate from the random totals below
        environment baseline;
        $display("\n======== DIRECTED REGRESSION (baseline) ========");
        baseline = new(vif, pif, cov);
        baseline.run_directed();
        $display("Baseline result: checked=%0d errors=%0d",
                  baseline.sb.num_checked, baseline.sb.num_errors);

        // nothing here calls $fatal/$stop on a check/assertion failure, so
        // one bad seed never aborts the rest of the regression
        $display("\n======== MULTI-SEED RANDOM REGRESSION (%0d seeds) ========", NUM_SEEDS);
        for (int i = 0; i < NUM_SEEDS; i++) begin
            int seed = BASE_SEED + i;
            environment env;
            bit seed_ok;

            $display("\n---- SEED %0d/%0d (value=%0d, %0d random instructions) ----",
                       i + 1, NUM_SEEDS, seed, NUM_RANDOM_INSTRS);

            process::self().srandom(seed);

            env = new(vif, pif, cov);
            env.gen.num_random_instrs = NUM_RANDOM_INSTRS;
            env.run_random();

            total_checked += env.sb.num_checked;
            total_errors  += env.sb.num_errors;
            seeds_run++;

            seed_ok = (env.sb.num_errors == 0);
            if (!seed_ok) seeds_failed++;

            $display("---- SEED %0d result: %s (checked=%0d errors=%0d) ----",
                       seed, seed_ok ? "PASS" : "FAIL",
                       env.sb.num_checked, env.sb.num_errors);
        end
    endtask

    function void report();
        int unsigned assert_fails;
        assert_fails = top_tb.dut.assertions_inst.fail_count;

        $display("\n================================================");
        $display("Regression Summary");
        $display("================================================");
        $display("Seeds Executed        : %0d", seeds_run);
        $display("Seeds Failed          : %0d", seeds_failed);
        $display("Random Instructions   : %0d", NUM_RANDOM_INSTRS * seeds_run);
        $display("Total Checks          : %0d", total_checked);
        $display("Passed Checks         : %0d", total_checked - total_errors);
        $display("Failed Checks         : %0d", total_errors);
        $display("Assertion Failures    : %0d", assert_fails);
        $display("Functional Coverage   : %0.1f%%", cov.overall_coverage());
        $display("================================================");

        cov.report();
    endfunction
endclass

`endif
