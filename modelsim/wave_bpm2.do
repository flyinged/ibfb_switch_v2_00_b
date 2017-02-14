onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand /user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id
add wave -noupdate /user_logic_sim_tb/SWITCH_UUT/filt13_bpm_id
add wave -noupdate -color {Orange Red} /user_logic_sim_tb/SWITCH_UUT/filt13_resetting
add wave -noupdate -color {Orange Red} /user_logic_sim_tb/SWITCH_UUT/filt02_resetting
add wave -noupdate /user_logic_sim_tb/rst
add wave -noupdate /user_logic_sim_tb/trig02
add wave -noupdate /user_logic_sim_tb/trig13
add wave -noupdate /user_logic_sim_tb/npackets
add wave -noupdate -color magenta -expand -subitemconfig {/user_logic_sim_tb/qsfp_pkt_start(0) {-color magenta -height 15} /user_logic_sim_tb/qsfp_pkt_start(1) {-color magenta -height 15} /user_logic_sim_tb/qsfp_pkt_start(2) {-color magenta -height 15} /user_logic_sim_tb/qsfp_pkt_start(3) {-color magenta -height 15}} /user_logic_sim_tb/qsfp_pkt_start
add wave -noupdate -group {PKT GEN} /user_logic_sim_tb/qsfp_pkt_busy
add wave -noupdate -group {PKT GEN} /user_logic_sim_tb/qsfp_pkt_valid
add wave -noupdate -group {PKT GEN} /user_logic_sim_tb/qsfp_pkt
add wave -noupdate -group {PKT TX} /user_logic_sim_tb/qsfp_txf_full
add wave -noupdate -group {PKT TX} /user_logic_sim_tb/qsfp_txf_valid
add wave -noupdate -group {PKT TX} /user_logic_sim_tb/qsfp_txf_charisk
add wave -noupdate -group {PKT TX} /user_logic_sim_tb/qsfp_txf_data
add wave -noupdate -group {PKT RX} /user_logic_sim_tb/qsfp_rxf_next
add wave -noupdate -group {PKT RX} -expand /user_logic_sim_tb/qsfp_rxf_empty
add wave -noupdate -group {PKT RX} /user_logic_sim_tb/qsfp_rxf_charisk
add wave -noupdate -group {PKT RX} /user_logic_sim_tb/qsfp_rxf_data
add wave -noupdate -group {FILT13 OUT} /user_logic_sim_tb/SWITCH_UUT/filt13_discard
add wave -noupdate -group {FILT13 OUT} /user_logic_sim_tb/SWITCH_UUT/filt13_o_charisk
add wave -noupdate -group {FILT13 OUT} /user_logic_sim_tb/SWITCH_UUT/filt13_o_data
add wave -noupdate -group {FILT13 OUT} /user_logic_sim_tb/SWITCH_UUT/filt13_o_next
add wave -noupdate -group {FILT13 OUT} /user_logic_sim_tb/SWITCH_UUT/filt13_o_valid
add wave -noupdate -group {FILT13 OUT} /user_logic_sim_tb/SWITCH_UUT/filt13_resetting
add wave -noupdate -group {FILT13 OUT} /user_logic_sim_tb/SWITCH_UUT/filt13_valid
add wave -noupdate -group {FILT02 OUT} /user_logic_sim_tb/SWITCH_UUT/filt02_resetting
add wave -noupdate -group {FILT02 OUT} /user_logic_sim_tb/SWITCH_UUT/filt02_o_charisk
add wave -noupdate -group {FILT02 OUT} /user_logic_sim_tb/SWITCH_UUT/filt02_o_data
add wave -noupdate -group {FILT02 OUT} /user_logic_sim_tb/SWITCH_UUT/filt02_o_next
add wave -noupdate -group {FILT02 OUT} /user_logic_sim_tb/SWITCH_UUT/filt02_o_valid
add wave -noupdate -group {FILT02 OUT} /user_logic_sim_tb/SWITCH_UUT/filt02_valid
add wave -noupdate -group {FILT02 OUT} /user_logic_sim_tb/SWITCH_UUT/filt02_discard
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/i_rst
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/o_next
add wave -noupdate -group ROUTER -color magenta /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/i_valid
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/i_charisk
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/i_data
add wave -noupdate -group ROUTER -color magenta /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/in_valid
add wave -noupdate -group ROUTER -color cyan /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/in_next
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/in_charisk
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/in_data
add wave -noupdate -group ROUTER -color gold /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/in_port
add wave -noupdate -group ROUTER -color blue /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/s
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/i_err_rst
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/i_next
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/nxt
add wave -noupdate -group ROUTER -color orange /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/o_err
add wave -noupdate -group ROUTER -color cyan /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/o_valid
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/o_charisk
add wave -noupdate -group ROUTER /user_logic_sim_tb/SWITCH_UUT/PACKET_ROUTER_I/o_data
add wave -noupdate -expand -group OUTPUT /user_logic_sim_tb/bpm_txf_charisk
add wave -noupdate -expand -group OUTPUT /user_logic_sim_tb/bpm_txf_data
add wave -noupdate -expand -group OUTPUT /user_logic_sim_tb/bpm_txf_full
add wave -noupdate -expand -group OUTPUT /user_logic_sim_tb/bpm_txf_next
add wave -noupdate -expand -group OUTPUT /user_logic_sim_tb/bpm_txf_write
add wave -noupdate -group {PKT OUT} /user_logic_sim_tb/bpm_rx_bad_data
add wave -noupdate -group {PKT OUT} /user_logic_sim_tb/bpm_rx_crc_good
add wave -noupdate -group {PKT OUT} /user_logic_sim_tb/bpm_rx_data
add wave -noupdate -group {PKT OUT} /user_logic_sim_tb/bpm_rx_eop
add wave -noupdate /user_logic_sim_tb/bpm_rx_data_reg
add wave -noupdate /user_logic_sim_tb/bpm_rx_eop_reg
add wave -noupdate /user_logic_sim_tb/bpm_rx_good_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {95379990 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {43986658 ps} {45053334 ps}
