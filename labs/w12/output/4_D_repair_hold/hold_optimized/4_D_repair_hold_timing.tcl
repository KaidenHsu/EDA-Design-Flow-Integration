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

# Open the ordinary placement and record its timing configuration.
step OPEN_DESIGN {
    open_lib fir3.dlib
    open_block fir3_reference.design
}

step INPUT_AUDIT {report_clocks; report_corners; report_scenarios; report_parasitic_parameters}

# Insert the hold buffer only in the optimized copy.
# add_buffer is an ICC2 command that inserts a buffer between the driver pin and its load.
if {$::env(W12_VARIANT) eq "optimized"} {
    step BUFFER_DISCOVERY {
        set buf [get_lib_cells */BUFX1]
        set driver [get_pins valid_out_reg/Q]
        if {[sizeof_collection $buf] != 1 || [sizeof_collection $driver] != 1} {error "Expected reference buffer and driver not found"}
        puts "W12_BUFFER=[get_object_name $buf]"
    }
    step INSERT_HOLD_BUFFER {
        add_buffer $driver -lib_cell [get_object_name $buf] -new_cell_names W12_HOLD_BUF -new_net_names W12_HOLD_NET
        if {[sizeof_collection [get_cells W12_HOLD_BUF]] != 1} {error "Buffer insertion not confirmed"}
    }
    step LEGALIZE {connect_pg_net -automatic; legalize_placement}
}

# Measure setup and hold slack on the target path and across the design.
step UPDATE_TIMING {update_timing}
step TARGET_HOLD {report_timing -to [get_ports valid_out] -delay_type min -max_paths 3}
step TARGET_SETUP {report_timing -to [get_ports valid_out] -delay_type max -max_paths 3}
step GLOBAL_SETUP {report_timing -delay_type max -max_paths 5}
step GLOBAL_HOLD {report_timing -delay_type min -max_paths 5}
step QOR {report_qor}
step COVERAGE {check_timing}

# Recheck placement and power-grid integrity after the timing comparison.
step LEGALITY {check_legality}
step PG_DRC {check_pg_drc}
step PG_CONNECTIVITY {check_pg_connectivity}
step AREA {report_utilization}
step PLACEMENT {report_placement}

# Save the native checkpoint and export DEF and Verilog for comparison.
step SAVE_CHECKPOINT {save_block; save_lib; write_def final.def; write_verilog final.v}

step CONGESTION {
    set_app_options -name route.global.timing_driven -value false
    report_congestion -rerun_global_router
}

puts "W12_HOLD_EXPERIMENT_COMPLETED"
exit
