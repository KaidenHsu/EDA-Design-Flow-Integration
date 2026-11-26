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

# Open the copied 60% floorplan and connect the logical supply nets.
step OPEN_DESIGN {
    open_lib fir3.dlib
    open_block fir3_reference.design
}

step CONNECT_PG {connect_pg_net -automatic}

# Build the standard-cell rails for the rails-only comparison.
step DEFINE_RAILS {
    create_pg_std_cell_conn_pattern rail_pattern -layers {METAL1}
    set_pg_strategy rail_strategy -core -pattern {{name: rail_pattern} {nets: {VDD VSS}}}
}

step GENERATE_RAILS {compile_pg -strategies rail_strategy}

# Check the physical supply network before saving the checkpoint.
step PG_DRC {check_pg_drc}
step PG_CONNECTIVITY {check_pg_connectivity}
step SAVE_CHECKPOINT {save_block; save_lib; write_def pg_rails.def}
puts "W12_RAILS_COMPLETED"
exit
