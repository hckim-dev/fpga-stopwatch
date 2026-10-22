# Run from a Vivado-enabled terminal:
# vivado -mode batch -source scripts/verify_project.tcl
set project_root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $project_root fpga_stopwatch.xpr]

# Validate the saved project before repairing anything: a fresh checkout must work.
foreach fileset {sources_1 sim_1 constrs_1} extension {v v xdc} {
    set expected [glob $project_root/fpga_stopwatch.srcs/$fileset/new/*.$extension]
    foreach source_file $expected {
        if {[llength [get_files -quiet -of_objects [get_filesets $fileset] $source_file]] != 1} {
            error "Unregistered file: $source_file (run scripts/register_sources.tcl)"
        }
    }
    if {[llength [get_files -of_objects [get_filesets $fileset]]] != [llength $expected]} {
        error "Unexpected or stale files in $fileset"
    }
}
file mkdir $project_root/verification
report_compile_order -used_in synthesis -file $project_root/verification/compile_order.rpt

# Stop at time zero, select presentation signals, then record the actual simulation.
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
foreach test_top {tb_top_minsec_stopwatch tb_stopwatch_counter} {
    set_property top $test_top [get_filesets sim_1]
    update_compile_order -fileset sim_1
    launch_simulation -simset sim_1 -mode behavioral
    create_wave_config
    if {$test_top eq "tb_top_minsec_stopwatch"} {
        set signals {scenario reset btn btn_pulse mode clock_time stopwatch_time dot_on animation_active}
    } else {
        set signals {scenario reset enable clear display_time}
    }
    open_vcd $project_root/verification/$test_top.vcd
    foreach signal $signals {
        add_wave -radix unsigned /$test_top/$signal
        log_vcd /$test_top/$signal
    }
    file delete -force $project_root/verification/$test_top.wcfg
    save_wave_config $project_root/verification/$test_top.wcfg
    run all
    close_vcd
    close_sim
    set sim_log $project_root/fpga_stopwatch.sim/sim_1/behav/xsim/simulate.log
    set fd [open $sim_log r]
    set sim_text [read $fd]
    close $fd
    if {![string match {*PASS:*} $sim_text] || [regexp {Fatal:|FATAL|FAIL} $sim_text]} {
        error "Test failed: $test_top (inspect $sim_log)"
    }
    file copy -force $sim_log $project_root/verification/$test_top.log
}
set_property top tb_top_minsec_stopwatch [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
update_compile_order -fileset sim_1

reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
open_run impl_1
report_timing_summary -file $project_root/verification/timing_summary.rpt
report_utilization -file $project_root/verification/utilization.rpt
report_drc -file $project_root/verification/drc.rpt
report_methodology -file $project_root/verification/methodology.rpt
foreach delay_type {max min} {
    set worst_path [get_timing_paths -delay_type $delay_type -max_paths 1]
    if {[get_property SLACK $worst_path] < 0} {error "Timing violation: $delay_type"}
}
if {[llength [get_drc_violations -quiet -filter {SEVERITY == Error}]] != 0} {error "DRC error"}
if {[llength [get_cells -quiet -hierarchical -filter {IS_BLACKBOX == 1}]] != 0} {
    error "Unresolved black box"
}
if {[llength [get_cells -quiet -hierarchical -filter {REF_NAME =~ LD*}]] != 0} {
    error "Inferred latch"
}
close_project
puts "PASS: saved project, two simulations, timing, DRC and bitstream"
