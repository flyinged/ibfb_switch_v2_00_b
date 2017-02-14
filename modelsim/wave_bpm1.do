onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {PLAYER RAM INIT} /user_logic_sim_tb/ram_init_a
add wave -noupdate -expand -group {PLAYER RAM INIT} /user_logic_sim_tb/ram_init_d
add wave -noupdate -expand -group {PLAYER RAM INIT} /user_logic_sim_tb/ram_init_data
add wave -noupdate -expand -group {PLAYER RAM INIT} /user_logic_sim_tb/ram_init_done
add wave -noupdate -expand -group {PLAYER RAM INIT} /user_logic_sim_tb/ram_init_id
add wave -noupdate -expand -group {PLAYER RAM INIT} /user_logic_sim_tb/ram_init_w
add wave -noupdate /user_logic_sim_tb/pl_busy
add wave -noupdate /user_logic_sim_tb/pl_start
add wave -noupdate -expand -group {PLAYER OUT} /user_logic_sim_tb/pkt_tx_sop
add wave -noupdate -expand -group {PLAYER OUT} /user_logic_sim_tb/pkt_tx_busy
add wave -noupdate -expand -group {PLAYER OUT} /user_logic_sim_tb/player_ovalid
add wave -noupdate -expand -group {PLAYER OUT} /user_logic_sim_tb/player_odata
add wave -noupdate -expand -group {PACKET TX} /user_logic_sim_tb/txf_charisk
add wave -noupdate -expand -group {PACKET TX} /user_logic_sim_tb/txf_data
add wave -noupdate -expand -group {PACKET TX} /user_logic_sim_tb/txf_full
add wave -noupdate -expand -group {PACKET TX} -color magenta /user_logic_sim_tb/txf_write
add wave -noupdate -expand -group {PACKET RX} -color magenta /user_logic_sim_tb/qsfp_rxf_next(0)
add wave -noupdate -expand -group {PACKET RX} /user_logic_sim_tb/qsfp_rxf_empty(0)
add wave -noupdate -expand -group {PACKET RX} /user_logic_sim_tb/qsfp_rxf_charisk(0)
add wave -noupdate -expand -group {PACKET RX} /user_logic_sim_tb/qsfp_rxf_data(0)
add wave -noupdate -expand -group FILT02 -color cyan /user_logic_sim_tb/SWITCH_UUT/filt02_resetting
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_bpm_id
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_o_charisk
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_o_data
add wave -noupdate -expand -group FILT02 -color magenta /user_logic_sim_tb/SWITCH_UUT/filt02_o_next
add wave -noupdate -expand -group FILT02 -color magenta /user_logic_sim_tb/SWITCH_UUT/filt02_o_valid
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_reg_c
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_rst
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_rst_c
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_trig
add wave -noupdate -expand -group FILT02 /user_logic_sim_tb/SWITCH_UUT/filt02_trig_c
add wave -noupdate -expand -group FILT02 -color gold /user_logic_sim_tb/SWITCH_UUT/filt02_valid
add wave -noupdate -expand -group FILT02 -color gold /user_logic_sim_tb/SWITCH_UUT/filt02_discard
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_err_rst
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_i_charisk
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_i_data
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_i_next
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_i_valid
add wave -noupdate -expand -group ROUTER -color magenta /user_logic_sim_tb/SWITCH_UUT/router_i_next(2)
add wave -noupdate -expand -group ROUTER -color magenta /user_logic_sim_tb/SWITCH_UUT/router_i_valid(2)
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_i_charisk(2)
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_i_data(2)
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_o_err
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_o_next
add wave -noupdate -expand -group ROUTER -color magenta -subitemconfig {/user_logic_sim_tb/SWITCH_UUT/router_o_valid(0) {-color magenta} /user_logic_sim_tb/SWITCH_UUT/router_o_valid(1) {-color magenta}} /user_logic_sim_tb/SWITCH_UUT/router_o_valid
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_o_charisk(0)
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_o_data(0)
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_o_charisk
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_o_data
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_rst
add wave -noupdate -expand -group ROUTER /user_logic_sim_tb/SWITCH_UUT/router_rst_c
add wave -noupdate /user_logic_sim_tb/SWITCH_UUT/dbg_fifo_full
add wave -noupdate /user_logic_sim_tb/SWITCH_UUT/dbg_fifo_write
add wave -noupdate -expand -group DBG_FIFO_READ /user_logic_sim_tb/dbg_fifo_charisk
add wave -noupdate -expand -group DBG_FIFO_READ /user_logic_sim_tb/dbg_fifo_data
add wave -noupdate -expand -group DBG_FIFO_READ /user_logic_sim_tb/dbg_fifo_empty
add wave -noupdate -expand -group DBG_FIFO_READ /user_logic_sim_tb/dbg_fifo_read
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {38219482 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 399
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
WaveRestoreZoom {44128426 ps} {44633004 ps}
