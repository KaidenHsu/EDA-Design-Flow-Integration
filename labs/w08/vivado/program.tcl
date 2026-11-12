# ======================================================================================
#                  1. Initialize and set up VIO and ILA
# ======================================================================================

# Week 8 physical hardware action: use only at the powered, connected PYNQ-Z2.
set root [file normalize [file join [file dirname [info script]] ..]]
set bit [file join $root artifacts fir3_pynqz2.bit]
set ltx [file join $root artifacts fir3_pynqz2.ltx]
foreach f [list $bit $ltx] {
    if {![file isfile $f] || [file size $f] <= 0} {error "Missing Week 8 handoff file: $f"}
}

open_hw_manager
connect_hw_server
open_hw_target
set devices [get_hw_devices xc7z020*]
if {[llength $devices] != 1} {error "Expected exactly one XC7Z020 hardware target, found [llength $devices]. Check PYNQ-Z2 USB-JTAG."}
set dev [lindex $devices 0]
current_hw_device $dev
refresh_hw_device $dev

set_property PROGRAM.FILE $bit $dev
set_property PROBES.FILE $ltx $dev
program_hw_devices $dev
refresh_hw_device $dev

if {[lsearch -exact [list_property $dev] IS_PROGRAMMED] >= 0} {
    if {![get_property IS_PROGRAMMED $dev]} {error "Hardware Manager device not programmed; check target and clock."}
    puts {[RESULT] HARDWARE_MANAGER_REPORTS_PROGRAMMED}
} else {
    puts {[INFO] Hardware Manager programming command returned; visually verify DONE/Programmed in GUI.}
}
puts {[IMPORTANT] Record the actual programmed-status screenshot and VIO/ILA capture; this script does NOT claim a hardware FIR regression PASS.}

set vio [lindex [get_hw_vios] 0]
set ila [lindex [get_hw_ilas] 0]
if {$vio eq "" || $ila eq ""} {error "Expected VIO and ILA debug cores were not found"}

puts [get_hw_probes -of_objects $vio]
puts [get_hw_probes -of_objects $ila]

# ======================================================================================
#                  2. Apply Reset and Input Stimulus
# ======================================================================================

set_property OUTPUT_VALUE 0 [get_hw_probes rst_n]
set_property OUTPUT_VALUE 0 [get_hw_probes sample_req]
set_property OUTPUT_VALUE_RADIX HEX [get_hw_probes x_in]
set_property OUTPUT_VALUE 05 [get_hw_probes x_in]
commit_hw_vio $vio

set_property OUTPUT_VALUE 1 [get_hw_probes rst_n]
commit_hw_vio $vio

# ======================================================================================
#                  3. Configure and Run the ILA Capture
# ======================================================================================

reset_hw_ila $ila
set_property CONTROL.DATA_DEPTH 1024 $ila
set_property CONTROL.TRIGGER_POSITION 32 $ila
set_property CONTROL.TRIGGER_CONDITION AND $ila
set_property TRIGGER_COMPARE_VALUE eq1'b1 [get_hw_probes valid_out_1]
run_hw_ila $ila

set_property OUTPUT_VALUE 1 [get_hw_probes sample_req]
commit_hw_vio $vio

# ======================================================================================
#                  4. Retrieve, Export, and Read Captured ILA Data
# ======================================================================================

wait_on_hw_ila -timeout 0.2 $ila
set capture [upload_hw_ila_data $ila]
set evidence [file join $root evidence]
file mkdir $evidence

write_hw_ila_data -force [file join $evidence ila_capture_plus5.ila] $capture
write_hw_ila_data -csv_file -force [file join $evidence ila_capture_plus5.csv] $capture
write_hw_ila_data -vcd_file -force [file join $evidence ila_capture_plus5.vcd] $capture

refresh_hw_vio $vio
puts "FIR y_out=[get_property INPUT_VALUE [get_hw_probes y_out]]"
