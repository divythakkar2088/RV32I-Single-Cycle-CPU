`ifndef MONITOR_SV
`define MONITOR_SV

// Passive observer. Samples cpu_probe_if every cycle (once reset is
// deasserted) and forwards each sample to the scoreboard and the coverage
// collector.
class monitor;
    virtual cpu_probe_if pif;
    mailbox #(mon_transaction) mon2sb;
    mailbox #(mon_transaction) mon2cov;
    bit enabled;

    function new(virtual cpu_probe_if pif,
                  mailbox #(mon_transaction) mon2sb,
                  mailbox #(mon_transaction) mon2cov);
        this.pif = pif;
        this.mon2sb = mon2sb;
        this.mon2cov = mon2cov;
        this.enabled = 0;
    endfunction

    task automatic run();
        mon_transaction m;
        forever begin
            @(posedge pif.clk);
            if (enabled && !pif.rst) begin
                m = new();
                m.pc_out             = pif.pc_out;
                m.instr              = pif.instr;
                m.rs1_data           = pif.rs1_data;
                m.rs2_data           = pif.rs2_data;
                m.immExt             = pif.immExt;
                m.ALU_result         = pif.ALU_result;
                m.memdata_out        = pif.memdata_out;
                m.write_data         = pif.write_data;
                m.branch_target      = pif.branch_target;
                m.branch             = pif.branch;
                m.memRead            = pif.memRead;
                m.memtoReg           = pif.memtoReg;
                m.memWrite           = pif.memWrite;
                m.ALUsrc             = pif.ALUsrc;
                m.regWrite           = pif.regWrite;
                m.zero               = pif.zero;
                m.PCSrc              = pif.PCSrc;
                m.ALUop              = pif.ALUop;
                m.ALU_control_signal = pif.ALU_control_signal;
                mon2sb.put(m);
                mon2cov.put(m);
            end
        end
    endtask
endclass

`endif
