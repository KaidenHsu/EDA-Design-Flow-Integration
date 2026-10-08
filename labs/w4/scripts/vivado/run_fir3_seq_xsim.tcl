# Week 4 XSim batch script.
# The testbench itself creates waves/fir3_seq.vcd using $dumpfile/$dumpvars.
# Keep VCD generation in exactly one place: the testbench.
if {[catch {log_wave -recursive *} msg]} {
    puts "WARN: log_wave failed: $msg"
}
run all
quit
