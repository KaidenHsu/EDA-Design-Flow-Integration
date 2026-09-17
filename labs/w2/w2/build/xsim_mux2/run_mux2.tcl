if {[catch {log_wave -recursive *} msg]} { puts "WARN: log_wave failed: $msg" }
if {[catch {open_vcd ../../waves/mux2.vcd} msg]} {
    puts "WARN: open_vcd failed: $msg"
} else {
    catch {log_vcd /}
}
run all
catch {close_vcd}
quit
