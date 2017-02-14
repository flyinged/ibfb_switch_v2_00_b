#vcom -work work -2002 -explicit -novopt C:/my_hdl/myfifo.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_switch_v1_00_a/hdl/vhdl/ram_infer.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_switch_v1_00_a/hdl/vhdl/pkg_crc.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_switch_v1_00_a/hdl/vhdl/ibfb_comm_package_sim.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_switch_v1_00_a/hdl/vhdl/ibfb_packet_gen.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_switch_v1_00_a/hdl/vhdl/user_logic_sim.vhd
vcom -work work -2002 -explicit -novopt C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_switch_v1_00_a/modelsim/user_logic_sim_tb.vhd

vsim -gui -t ps -novopt work.user_logic_sim_tb

log -r *
radix hex

#force -freeze sim:/ibfb_packet_gen_tb/npackets0 10 0
#force -freeze sim:/ibfb_packet_gen_tb/tx_packet0.ctrl AA 0
#force -freeze sim:/ibfb_packet_gen_tb/tx_packet1.ctrl BB 0
force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(0) 01 0
force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(1) 02 0
force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(2) 03 0
force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id(3) 04 0

force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(0) 05 0
force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(1) 06 0
force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(2) 07 0
force -freeze sim:/user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id(3) 08 0

do wave.do

alias TRIG "force -freeze sim:/user_logic_sim_tb/trig13 1 0 -cancel {100 ns}
            force -freeze sim:/user_logic_sim_tb/trig02 1 0 -cancel {100 ns}"
alias S0 "force -freeze sim:/user_logic_sim_tb/qsfp_pkt_start(0) 1 0 -cancel {100 ns}"
alias S1 "force -freeze sim:/user_logic_sim_tb/qsfp_pkt_start(1) 1 0 -cancel {100 ns}"
alias S2 "force -freeze sim:/user_logic_sim_tb/qsfp_pkt_start(2) 1 0 -cancel {100 ns}"
alias S3 "force -freeze sim:/user_logic_sim_tb/qsfp_pkt_start(3) 1 0 -cancel {100 ns}"
alias WW "write format wave -window .main_pane.wave.interior.cs.body.pw.wf C:/temp/G/XFEL/14_Firmware/22_Library/EDKLib/hw/PSI/pcores/ibfb_switch_v1_00_a/modelsim/wave.do"