# Run from the repository root:
# vivado -mode batch -source scripts/create_project.tcl
set project_root [file normalize [file join [file dirname [info script]] ..]]
set project_file [file join $project_root fpga_stopwatch.xpr]
if {[file exists $project_file]} {
    error "Project already exists: $project_file"
}
create_project fpga_stopwatch $project_root -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]
close_project
puts "PASS: created fpga_stopwatch.xpr"
