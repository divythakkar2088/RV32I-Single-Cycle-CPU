`timescale 1ns/1ps

// `include instead of relying on compile order, so this is the only file
// you need to add as a simulation source besides rtl/*.v
`include "transaction.sv"
`include "interface.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "coverage.sv"
`include "environment.sv"
`include "regression.sv"
`include "assertions.sv"

module top_tb;

    logic clk = 0;
    always #5 clk = ~clk;

    cpu_if u_cpu_if (.clk(clk));

    // DUT -- rtl/top.v, completely unmodified
    top dut (
        .clk(clk),
        .rst(u_cpu_if.rst)
    );

    regression_manager regr;

    initial begin
        regr = new(u_cpu_if, dut.probe_if_inst);
        regr.run();
        regr.report();
        $display("\nSimulation finished @ %0t", $time);
        $finish;
    end

endmodule
