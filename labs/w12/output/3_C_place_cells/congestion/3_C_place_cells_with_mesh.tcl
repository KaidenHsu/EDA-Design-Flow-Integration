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

# Open a copy of the 50% floorplan and apply the Week 11 timing constraints.
step OPEN_DESIGN {
    open_lib fir3.dlib
    open_block fir3_reference.design
}

step READ_CONSTRAINTS {read_sdc $::env(W12_SDC); report_clocks}

# Connect the supply nets and build the mesh and standard-cell rails.
step CONNECT_PG {connect_pg_net -automatic}
step DEFINE_MESH {
    create_pg_mesh_pattern mesh_pattern -layers {
        {{vertical_layer: METAL2} {width: 0.84} {spacing: interleaving} {pitch: 20} {offset: 3} {trim: false}}
        {{horizontal_layer: METAL3} {width: 0.84} {spacing: interleaving} {pitch: 20} {offset: 3} {trim: false}}
    }
    set_pg_strategy mesh_strategy -core -pattern {{name: mesh_pattern} {nets: {VDD VSS}}} -extension {{stop: design_boundary_and_generate_pin}}
}

step DEFINE_RAILS {
    create_pg_std_cell_conn_pattern rail_pattern -layers {METAL1}
    set_pg_strategy rail_strategy -core -pattern {{name: rail_pattern} {nets: {VDD VSS}}}
}

step GENERATE_PDN {compile_pg -strategies {mesh_strategy rail_strategy}}

# Record supply checks before placing the cells.
step INITIAL_PG_DRC {check_pg_drc}
step INITIAL_PG_CONNECTIVITY {check_pg_connectivity}
step SAVE_POWERPLAN {save_block; save_lib; write_def powerplan.def}

# Place signal pins and run the placement strategy selected by the runner.
step PIN_CONSTRAINTS {set_block_pin_constraints -self -allowed_layers {METAL2 METAL3}}
step PLACE_SIGNAL_PINS {place_pins -self}
step GLOBAL_PLACEMENT {
    if {$::env(W12_VARIANT) eq "congestion"} {create_placement -congestion} else {create_placement}
}
step SAVE_GLOBAL_PLACEMENT {write_def global_placement.def}

# Move cells to legal sites and reconnect their supply pins.
step LEGALIZATION {legalize_placement}
step FINAL_PG_CONNECTIONS {connect_pg_net -automatic}

# Check the legalized design before saving the placed checkpoint.
step LEGALITY {check_legality}
step PG_DRC {check_pg_drc}
step PG_CONNECTIVITY {check_pg_connectivity}
step AREA {report_utilization}
step PLACEMENT {report_placement}

step SAVE_PLACED_DESIGN {save_block; save_lib; write_def placed.def}


puts "W12_PG_PLACE_COMPLETED"
exit
