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

# Load the T18 technology, logical timing library, and physical cell views.
step WORKSPACE {create_workspace -flow normal -technology $::env(W12_TECH) t18_typical}
step LOGICAL_LIBRARY {read_db $::env(W12_DB)}
step PHYSICAL_LIBRARY {read_lef $::env(W12_LEF)}

# Validate the workspace before committing the reference library.
step VALIDATE_WORKSPACE {check_workspace}
step COMMIT_NDM {commit_workspace -output t18_typical.ndm}

# Confirm the NDM was written before reporting success to the runner.
if {![file isdirectory t18_typical.ndm]} {error "NDM not created"}
puts "W12_NDM_CREATED"
exit
