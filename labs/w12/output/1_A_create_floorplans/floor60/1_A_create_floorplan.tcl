# Log each operation and stop if an ICC2 or Library Manager command fails.
proc step {name command} {
    puts "W12_BEGIN $name"
    if {[catch {uplevel #0 $command} result]} {
        puts "W12_FAIL $name: $result"
        exit 1
    }
    puts "W12_RESULT $name: $result"
    puts "W12_END $name"
}

# Create the design library, then import and link the mapped FIR netlist.
step CREATE_LIBRARY {create_lib -technology $::env(W12_TECH) -ref_libs [list $::env(W12_NDM)] fir3.dlib}
step IMPORT_NETLIST {read_verilog -top fir3_reference $::env(W12_NETLIST)}
step LINK_DESIGN {link_block}
step CHECK_REFERENCES {
    set unresolved [sizeof_collection [get_cells -hierarchical -filter {is_unbound == true}]]
    puts "W12_UNRESOLVED_CELLS=$unresolved"
    set count [sizeof_collection [get_cells -hierarchical]]
    puts "W12_CELL_COUNT=$count"
    if {$unresolved != 0 || $count == 0} {error "Unresolved or empty design"}
}
step REFERENCE_REPORT {report_ref_libs}

# Build the core using the utilization target supplied by the runner.
step FLOORPLAN {initialize_floorplan -core_utilization $::env(W12_UTIL) -shape R -side_ratio {1 1} -core_offset {5}}
step FLOORPLAN_REPORT {report_design -floorplan}
step UTILIZATION_REPORT {report_utilization}

# Save the native checkpoint and export its floorplan DEF.
step SAVE_CHECKPOINT {save_block; save_lib}
step EXPORT_DEF {write_def floorplan.def}
puts "W12_IMPORT_FLOORPLAN_COMPLETED"
exit
