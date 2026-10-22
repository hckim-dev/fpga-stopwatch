# Run from the repository root:
# vivado -mode batch -source scripts/verify_project.tcl
set project_root [file normalize [file join [file dirname [info script]] ..]]
source $project_root/scripts/register_sources.tcl
close_project
open_project [file join $project_root fpga_stopwatch.xpr]
set rtl_count [llength [get_files -of_objects [get_filesets sources_1] -filter {FILE_TYPE == Verilog}]]
if {$rtl_count != 12} {error "Expected 12 RTL files, got $rtl_count"}
if {[llength [get_files -quiet */fnd_idle_animation.v]] != 1} {error "Animation module is not registered"}
file mkdir $project_root/verification
report_compile_order -used_in synthesis -file $project_root/verification/compile_order.rpt
foreach test_top {tb_display_and_boundaries tb_fnd_idle_animation tb_stopwatch_counter tb_top_minsec_stopwatch} {
    set_property top $test_top [get_filesets sim_1]
    update_compile_order -fileset sim_1
    launch_simulation -simset sim_1 -mode behavioral
    close_sim
    set sim_log $project_root/fpga_stopwatch.sim/sim_1/behav/xsim/simulate.log
    set fd [open $sim_log r]
    set sim_text [read $fd]
    close $fd
    if {![string match {*PASS:*} $sim_text] || [regexp {Fatal:|FATAL|FAIL} $sim_text]} {
        error "Test failed: $test_top (inspect $sim_log)"
    }
    file copy -force $sim_log $project_root/verification/${test_top}.log
}
set_property top tb_top_minsec_stopwatch [get_filesets sim_1]
update_compile_order -fileset sim_1
reset_run synth_1
reset_run impl_1
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
report_cdc -file $project_root/verification/cdc.rpt
report_methodology -file $project_root/verification/methodology.rpt
if {[llength [get_cells -quiet -hierarchical -filter {IS_BLACKBOX == 1}]] != 0} {
    error "Unresolved black box remains"
}
close_project
puts "PASS: project registration, simulations, synthesis, implementation and bitstream"
