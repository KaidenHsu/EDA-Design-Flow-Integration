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

# Open a copy of the checkpoint for the selected placement strategy.
step OPEN_DESIGN {
    open_lib fir3.dlib
    open_block fir3_reference.design
}

# Run the congestion analysis and report the physical checks for comparison.
step CONGESTION {
    set_app_options -name route.global.timing_driven -value false
    report_congestion -rerun_global_router
}
step LEGALITY {check_legality}
step PG_DRC {check_pg_drc}
step PG_CONNECTIVITY {check_pg_connectivity}
step AREA {report_utilization}
step PLACEMENT {report_placement}

puts "W12_CONGESTION_COMPLETED"
exit
