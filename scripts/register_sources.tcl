# Run from the Vivado Tcl Console to repair source registration.
set project_root [file normalize [file join [file dirname [info script]] ..]]
set project_file [file join $project_root fpga_stopwatch.xpr]
if {[current_project -quiet] eq ""} {
    open_project $project_file
} elseif {[file normalize [get_property DIRECTORY [current_project]]] ne $project_root} {
    error "A different project is open. Open $project_file first."
}
foreach source_file [lsort [glob $project_root/fpga_stopwatch.srcs/sources_1/new/*.v]] {
    if {[llength [get_files -quiet $source_file]] == 0} {
        add_files -fileset sources_1 -norecurse $source_file
    }
    set_property file_type Verilog [get_files $source_file]
    set_property used_in_synthesis true [get_files $source_file]
    set_property used_in_implementation true [get_files $source_file]
    set_property used_in_simulation true [get_files $source_file]
    set_property is_enabled true [get_files $source_file]
}
foreach source_file [lsort [glob $project_root/fpga_stopwatch.srcs/sim_1/new/*.v]] {
    if {[llength [get_files -quiet $source_file]] == 0} {
        add_files -fileset sim_1 -norecurse $source_file
    }
    set_property file_type Verilog [get_files $source_file]
    set_property used_in_synthesis false [get_files $source_file]
    set_property used_in_implementation false [get_files $source_file]
    set_property used_in_simulation true [get_files $source_file]
    set_property is_enabled true [get_files $source_file]
}
set constraint_file [file join $project_root fpga_stopwatch.srcs constrs_1 new basys3.xdc]
if {[llength [get_files -quiet $constraint_file]] == 0} {
    add_files -fileset constrs_1 -norecurse $constraint_file
}
set_property file_type XDC [get_files $constraint_file]
set_property used_in_synthesis true [get_files $constraint_file]
set_property used_in_implementation true [get_files $constraint_file]
set_property is_enabled true [get_files $constraint_file]
set_property top top_minsec_stopwatch [get_filesets sources_1]
set_property top_auto_set false [get_filesets sources_1]
set_property top tb_top_minsec_stopwatch [get_filesets sim_1]
set_property top_auto_set false [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "PASS: registered [llength [get_files -of_objects [get_filesets sources_1] -filter {FILE_TYPE == Verilog}]] RTL files"
