
            open_project {d:\Material\CSDP\CNN_FPGA\CNN_FPGA.xpr}
            update_compile_order -fileset sources_1
            set_property target_simulator ModelSim [current_project]
            set_property compxlib.modelsim_compiled_library_dir  D:/modeltech64_2019.2/Vivado_lib [current_project]
            
 set_property top lenet_TB [get_filesets sim_1 ] 
 launch_simulation -install_path D:/modeltech64_2019.2/win64