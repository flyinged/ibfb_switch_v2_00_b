#***--------------------------------***------------------------------------***
#
#			     PLATGEN_SYSLEVEL_UPDATE_PROC
#
#***--------------------------------***------------------------------------***

##
## Generate TimeSpec constraining SPLB MBusy output path to 50% of PLB clock period,
##   if Xbar:SPLB clock ratio > 1:1
##

proc generate_corelevel_ucf {mhsinst} {
    # Create pcore UCF file
    set  filePath [xget_ncf_dir $mhsinst]
    file mkdir    $filePath
    set    instname   [xget_hw_parameter_value $mhsinst "INSTANCE"]
    set    name_lower [string   tolower   $instname]
    set    fileName   $name_lower
    append fileName   "_wrapper.ucf"
    append filePath   $fileName
    set    outputFile [open $filePath "w"]

    puts $outputFile "############################################"
    puts $outputFile "#Created by generate_corelevel_ucf procedure"
    puts $outputFile "############################################"
    
     #RXRECCLK CONSTRAINTS
    #First define all nets
    #QSFP13
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP13_TILE/mgt_out_rx<0>_RXRECCLK\" TNM_NET = Q13_RXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP13_TILE/mgt_out_rx<1>_RXRECCLK\" TNM_NET = Q13_RXCLK1;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP13_TILE/mgt_out_tx<0>_TXOUTCLK\" TNM_NET = Q13_TXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP13_TILE/mgt_out_tx<1>_TXOUTCLK\" TNM_NET = Q13_TXCLK1;"
    #QSFP02
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP02_TILE/mgt_out_rx<0>_RXRECCLK\" TNM_NET = Q02_RXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP02_TILE/mgt_out_rx<1>_RXRECCLK\" TNM_NET = Q02_RXCLK1;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP02_TILE/mgt_out_tx<0>_TXOUTCLK\" TNM_NET = Q02_TXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/QSFP02_TILE/mgt_out_tx<1>_TXOUTCLK\" TNM_NET = Q02_TXCLK1;"
    #BPM01
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM01_TILE/mgt_out_rx<0>_RXRECCLK\"  TNM_NET = B01_RXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM01_TILE/mgt_out_rx<1>_RXRECCLK\"  TNM_NET = B01_RXCLK1;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM01_TILE/mgt_out_tx<0>_TXOUTCLK\"  TNM_NET = B01_TXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM01_TILE/mgt_out_tx<1>_TXOUTCLK\"  TNM_NET = B01_TXCLK1;"
    #BPM23
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM23_TILE/mgt_out_rx<0>_RXRECCLK\"  TNM_NET = B23_RXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM23_TILE/mgt_out_rx<1>_RXRECCLK\"  TNM_NET = B23_RXCLK1;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM23_TILE/mgt_out_tx<0>_TXOUTCLK\"  TNM_NET = B23_TXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/BPM23_TILE/mgt_out_tx<1>_TXOUTCLK\"  TNM_NET = B23_TXCLK1;"
    #P0
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/P0_TILE/mgt_out_rx<0>_RXRECCLK\"     TNM_NET = P0_RXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/P0_TILE/mgt_out_rx<1>_RXRECCLK\"     TNM_NET = P0_RXCLK1;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/P0_TILE/mgt_out_tx<0>_TXOUTCLK\"     TNM_NET = P0_TXCLK0;"
    puts $outputFile "  NET \"${instname}/USER_LOGIC_I/P0_TILE/mgt_out_tx<1>_TXOUTCLK\"     TNM_NET = P0_TXCLK1;"

    #Then define timing constraints
    #QSFP13
    puts $outputFile "  TIMESPEC TS_Q13_RXCLK0 = PERIOD \"Q13_RXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_Q13_RXCLK1 = PERIOD \"Q13_RXCLK1\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_Q13_TXCLK0 = PERIOD \"Q13_TXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_Q13_TXCLK1 = PERIOD \"Q13_TXCLK1\" 6.4 ns HIGH 50%;"
    #QSFP02
    puts $outputFile "  TIMESPEC TS_Q02_RXCLK0 = PERIOD \"Q02_RXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_Q02_RXCLK1 = PERIOD \"Q02_RXCLK1\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_Q02_TXCLK0 = PERIOD \"Q02_TXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_Q02_TXCLK1 = PERIOD \"Q02_TXCLK1\" 6.4 ns HIGH 50%;"
    #BPM01
    puts $outputFile "  TIMESPEC TS_B01_RXCLK0 = PERIOD \"B01_RXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_B01_RXCLK1 = PERIOD \"B01_RXCLK1\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_B01_TXCLK0 = PERIOD \"B01_TXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_B01_TXCLK1 = PERIOD \"B01_TXCLK1\" 6.4 ns HIGH 50%;"
    #BPM23
    puts $outputFile "  TIMESPEC TS_B23_RXCLK0 = PERIOD \"B23_RXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_B23_RXCLK1 = PERIOD \"B23_RXCLK1\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_B23_TXCLK0 = PERIOD \"B23_TXCLK0\" 6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_B23_TXCLK1 = PERIOD \"B23_TXCLK1\" 6.4 ns HIGH 50%;"
    #P0
    puts $outputFile "  TIMESPEC TS_P0_RXCLK0  = PERIOD \"P0_RXCLK0\"  6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_P0_RXCLK1  = PERIOD \"P0_RXCLK1\"  6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_P0_TXCLK0  = PERIOD \"P0_TXCLK0\"  6.4 ns HIGH 50%;"
    puts $outputFile "  TIMESPEC TS_P0_TXCLK1  = PERIOD \"P0_TXCLK1\"  6.4 ns HIGH 50%;"


#NET "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<0>_RXRECCLK" TNM_NET = psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<0>_RXRECCLK
#NET "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<0>_RXRECCLK" TNM_NET = psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<0>_RXRECCLK;
#TIMESPEC TS_psi_plbovergtx_inst_psi_plbovergtx_inst_mgt_out_rx_0__RXRECCLK = PERIOD "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<0>_RXRECCLK" 4 ns HIGH 50%;
#TIMESPEC TS_psi_plbovergtx_inst_psi_plbovergtx_inst_mgt_out_rx_0__RXRECCLK = PERIOD "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<0>_RXRECCLK" 4 ns HIGH 50%;
#NET "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<1>_RXRECCLK" TNM_NET = psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<1>_RXRECCLK;
#TIMESPEC TS_psi_plbovergtx_inst_psi_plbovergtx_inst_mgt_out_rx_1__RXRECCLK = PERIOD "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_rx<1>_RXRECCLK" 4 ns HIGH 50%;
#NET "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<0>_TXOUTCLK1" TNM_NET = psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<0>_TXOUTCLK1;
#NET "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<0>_TXOUTCLK1" TNM_NET = psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<0>_TXOUTCLK1;
#TIMESPEC TS_psi_plbovergtx_inst_psi_plbovergtx_inst_mgt_out_tx_0__TXOUTCLK1 = PERIOD "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<0>_TXOUTCLK1" 4 ns HIGH 50%;
#TIMESPEC TS_psi_plbovergtx_inst_psi_plbovergtx_inst_mgt_out_tx_0__TXOUTCLK1 = PERIOD "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<0>_TXOUTCLK1" 4 ns HIGH 50%;
#NET "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<1>_TXOUTCLK1" TNM_NET = psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<1>_TXOUTCLK1;
#TIMESPEC TS_psi_plbovergtx_inst_psi_plbovergtx_inst_mgt_out_tx_1__TXOUTCLK1 = PERIOD "psi_plbovergtx_inst/psi_plbovergtx_inst/mgt_out_tx<1>_TXOUTCLK1" 4 ns HIGH 50%;

    
    
#    set enable_tspecs [xget_hw_parameter_value $mhsinst "C_GENERATE_PLB_TIMESPECS"]
#    set xbar_clk_handle [xget_hw_port_handle $mhsinst "CPMINTERCONNECTCLK"]
#    set xbar_clk_freq [xget_hw_subproperty_value $xbar_clk_handle "CLK_FREQ_HZ"]
#
#    foreach i {0 1} {
#      set connector [xget_hw_busif_value     $mhsinst "SPLB${i}"]
#      if {[llength $connector] != 0} {  ## SPLBi is connected
#        ## Define TimeGroup for this SPLB busif
#        puts $outputFile "INST \"${instname}/*PPCS${i}PLBMBUSY_reg*\" TNM = \"${instname}_PPCS${i}PLBMBUSY\";"
#      }
#    }
#    foreach i {0 1} {
#      set connector [xget_hw_busif_value     $mhsinst "SPLB${i}"]
#      if {[llength $connector] != 0} {  ## SPLBi is connected
#        set splb_clk_handle [xget_hw_port_handle $mhsinst "CPMPPCS${i}PLBCLK"]
#        set splb_clk_freq [xget_hw_subproperty_value $splb_clk_handle "CLK_FREQ_HZ"]
#        if { [llength ${splb_clk_freq}] == 0 || [llength ${xbar_clk_freq}] == 0 } {
#          puts "\nWARNING: Frequencies could not be determined for the Interconnect clock (CPMINTERCONNECTCLK) and/or the PLB bus connected to SPLB0 or SPLB1."
#          puts "Therefore, TimeSpecs are not being generated for the pipeline flops on the PPCS*PLBMBUSY outputs."
#          puts "If any master connected to SPLB0/1 relies on the MBusy signal, it is important to ensure that the PPCS*PLBMBUSY outputs of the PPC440 block arrive at their fabric pipeline registers within half of the PLB clock period."
#          puts "This could be achieved by constraining the PPCS*PLBMBUSY_reg* D-input paths, as follows:"
#          puts "  TIMESPEC \"TS_${instname}_PPCS0PLBMBUSY\" = FROM CPUS TO \"${instname}_PPCS0PLBMBUSY\" 5000 ps"
#          puts "The value of this TimeSpec should be half of the SPLB clock period."
#          puts "The TimeGroups \"${instname}_PPCS0PLBMBUSY\" and \"${instname}_PPCS1PLBMBUSY\" have been generated automatically (if connected)."
#          puts "For automatic TimeSpec generation, please specify all Interconnect and SPLB clock frequencies in your design.\n"
#          close $outputFile
#          return
#        }
#        if { $splb_clk_freq < $xbar_clk_freq - 1 } {
#          set splb_clk_half_period_ps [expr 500000000000 / $splb_clk_freq]
#          if { $enable_tspecs > 0 } {
#            ## Constrain MBusy flop to 50% SPLB clk period
#            puts $outputFile "TIMESPEC \"TS_${instname}_PPCS${i}PLBMBUSY\" = FROM CPUS TO \
#              \"${instname}_PPCS${i}PLBMBUSY\" ${splb_clk_half_period_ps} ps;"
#            ## Note: If the SPLB:XBAR clock ratio is 1:1, generate no TimeSpec; pipeline flop will then
#            ##   remain constrained to the original SPLB period.
#          } else {
#            puts "\nWARNING: Generation of PLB-related TimeSpecs has been disabled for PowerPC ${instname}." 
#            puts "The PLB bus connected to SPLB${i} is clocked at a lower frequency than the Interconnect clock (CPMINTERCONNECTCLK)."
#            puts "Therefore, if any master connected to SPLB${i} relies on the MBusy signal, it would be important to ensure that the PPCS${i}PLBMBUSY output of the PPC440 block arrives at its fabric pipeline register within half of the PLB clock period. "
#            puts "This could be achieved by constraining the PPCS${i}PLBMBUSY_reg* D-input paths, as follows:"
#            puts "  TIMESPEC \"TS_${instname}_PPCS${i}PLBMBUSY\" = FROM CPUS TO \"${instname}_PPCS${i}PLBMBUSY\" ${splb_clk_half_period_ps} ps;"
#            puts "The value of this TimeSpec should be half of the SPLB${i} clock period. "
#            puts "The TimeGroup \"${instname}_PPCS${i}PLBMBUSY\" has been generated automatically.\n"
#          }
#        }
#      }
#    }
    close $outputFile
}
