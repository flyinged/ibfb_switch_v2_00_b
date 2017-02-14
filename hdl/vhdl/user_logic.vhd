------------------------------------------------------------------------------
--                       Paul Scherrer Institute (PSI)
------------------------------------------------------------------------------
-- Unit    : user_logic.vhd
-- Author  : Alessandro Malatesta, Section Diagnostic
-- Version : $Revision: 1.5 $
------------------------------------------------------------------------------
-- Copyright© PSI, Section Diagnostic
------------------------------------------------------------------------------
-- Comment : IBFB Packet Switch
--           1.03: new router
--           1.06: X/Y datapaths split (dual out filters, two routers)
--           1.07: added ping function
--           1.08: added QDR interface
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all; --or reduce
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library ibfb_common_v1_00_b;
use ibfb_common_v1_00_b.virtex5_gtx_package.all;
use ibfb_common_v1_00_b.ibfb_comm_package.all;
use ibfb_common_v1_00_b.pkg_ibfb_timing.all;

entity user_logic is
generic (
    --Packet protocol 
    K_SOP            : std_logic_vector(7 downto 0) := X"FB"; 
    K_EOP            : std_logic_vector(7 downto 0) := X"FD";
    --Transceivers
    C_GTX_REFCLK_SEL    : std_logic_vector(7 downto 0); --BPM23, BPM01, P0, SFP02, SFP13
    --
    C_SFP13_REFCLK_FREQ : integer := 125; --MHz
    C_SFP02_REFCLK_FREQ : integer := 125; --MHz
    C_P0_REFCLK_FREQ    : integer := 125; --MHz
    C_BPM_REFCLK_FREQ   : integer := 125; --MHz
    --
    C_SFP13_BAUD_RATE   : integer := 3125000; --Kbps
    C_SFP02_BAUD_RATE   : integer := 3125000; --Kbps
    C_P0_BAUD_RATE      : integer := 3125000; --Kbps
    C_BPM_BAUD_RATE     : integer := 3125000; --Kbps
    --PLB 
    C_SLV_AWIDTH        : integer := 32; --added
    C_NUM_MEM           : integer := 1;  --added
    C_SLV_DWIDTH        : integer := 32;
    C_NUM_REG           : integer := 4
);
port (
    user_clk                    : in    std_logic;
    ------------------------------------------------------------------------
    -- CHIPSCOPE
    ------------------------------------------------------------------------
    O_CSP_CLK                     : out std_logic;
    O_CSP_DATA                    : out std_logic_vector(255 downto 0); 
    ------------------------------------------------------------------------
    -- GTX INTERFACE
    ------------------------------------------------------------------------
    I_GTX_REFCLK1_IN              : in  std_logic;
    I_GTX_REFCLK2_IN              : in  std_logic;
    O_GTX_REFCLK_OUT              : out std_logic;
    I_GTX_RX_N                    : in  std_logic_vector(2*5-1 downto 0);
    I_GTX_RX_P                    : in  std_logic_vector(2*5-1 downto 0);
    O_GTX_TX_N                    : out std_logic_vector(2*5-1 downto 0);
    O_GTX_TX_P                    : out std_logic_vector(2*5-1 downto 0);
    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_ext_clk                     : in  std_logic; 
    i_trigger                     : in  std_logic;
    o_led_pulse                   : out std_logic;
    o_cpu_int                     : out std_logic;
    o_ctrl_sys_int                : out std_logic;
    ------------------------------------------------------------------------
    --QDR2 Interface
    ------------------------------------------------------------------------
    o_qdr2_usr_clk                : out std_logic;
    o_qdr2_usr_clk_rdy            : out std_logic;
    --port0
    o_qdr2_usr_trg0               : out std_logic;
    o_qdr2_usr_we0                : out std_logic;
    o_qdr2_usr_data00             : out std_logic_vector(35 downto 0);
    o_qdr2_usr_data01             : out std_logic_vector(35 downto 0);
    o_qdr2_usr_data02             : out std_logic_vector(35 downto 0);
    o_qdr2_usr_data03             : out std_logic_vector(35 downto 0);
    --port1
    o_qdr2_usr_trg1               : out std_logic;
    o_qdr2_usr_we1                : out std_logic;
    o_qdr2_usr_data10             : out std_logic_vector(35 downto 0);
    o_qdr2_usr_data11             : out std_logic_vector(35 downto 0);
    o_qdr2_usr_data12             : out std_logic_vector(35 downto 0);
    o_qdr2_usr_data13             : out std_logic_vector(35 downto 0);
    ------------------------------------------------------------------------
    -- Bus ports
    ------------------------------------------------------------------------
    Bus2IP_Clk                    : in  std_logic;
    Bus2IP_Reset                  : in  std_logic;
    Bus2IP_Addr                   : in  std_logic_vector(0 to C_SLV_AWIDTH-1);
    Bus2IP_CS                     : in  std_logic_vector(0 to C_NUM_MEM-1);
    Bus2IP_RNW                    : in  std_logic;
    Bus2IP_Data                   : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                     : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                   : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                   : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_Burst                  : in  std_logic;
    Bus2IP_BurstLength            : in  std_logic_vector(0 to 8);
    Bus2IP_RdReq                  : in  std_logic;
    Bus2IP_WrReq                  : in  std_logic;
    IP2Bus_AddrAck                : out std_logic;
    IP2Bus_Data                   : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                  : out std_logic;
    IP2Bus_WrAck                  : out std_logic;
    IP2Bus_Error                  : out std_logic
);
end entity user_logic;

------------------------------------------------------------------------------
-- Architecture
------------------------------------------------------------------------------
architecture behavioral of user_logic is
    
  --components
  component FIFO36
  generic(
      DATA_WIDTH                  : integer := 4;
      ALMOST_FULL_OFFSET          : bit_vector := X"0080";
      ALMOST_EMPTY_OFFSET         : bit_vector := X"0080";
      DO_REG                      : integer := 1;
      EN_SYN                      : boolean := FALSE;
      FIRST_WORD_FALL_THROUGH     : boolean := FALSE
  );
  port(
      RST                         : in   std_ulogic;
  
      WRCLK                       : in    std_ulogic;
      FULL                        : out   std_ulogic;
      ALMOSTFULL                  : out   std_ulogic;
      WREN                        : in    std_ulogic;
      WRCOUNT                     : out   std_logic_vector(12 downto  0);
      WRERR                       : out   std_ulogic;
      DIP                         : in    std_logic_vector( 3 downto  0);
      DI                          : in    std_logic_vector(31 downto  0);
  
      RDCLK                       : in    std_ulogic;
      EMPTY                       : out   std_ulogic;
      ALMOSTEMPTY                 : out   std_ulogic;
      RDEN                        : in    std_ulogic;
      RDCOUNT                     : out   std_logic_vector(12 downto  0);
      RDERR                       : out   std_ulogic;
      DOP                         : out   std_logic_vector( 3 downto  0);
      DO                          : out   std_logic_vector(31 downto  0)
  );
  end component;

  --0x9: working but with critical timing (PING, QDR LOGGING)
  --0xA: new architecture to relax timing
  constant FW_VERSION : std_logic_vector(31 downto 0) := X"0000000B";

  ---------------------------------------------------------------------------
  -- Bus protocol signals
  ---------------------------------------------------------------------------
  -- Types ------------------------------------------------------------------
  type     slv_reg_type is array (0 to C_NUM_REG-1) of std_logic_vector(C_SLV_DWIDTH - 1 downto 0);
  -- Constants --------------------------------------------------------------
  constant LOW_REG                : std_logic_vector( 0 to C_NUM_REG - 1) := (others => '0');
  constant K_BAD : std_logic_vector(7 downto 0) := X"5C";
  -- Signals ----------------------------------------------------------------
  signal   slv_reg_rd      : slv_reg_type;
  signal   slv_reg_wr      : slv_reg_type;
  signal   slv_reg_rd_ack  : std_logic := '0';
  signal   slv_reg_wr_ack  : std_logic := '0';
  signal   slv_ip2bus_data : std_logic_vector( 0 to C_SLV_DWIDTH-1);
  -- Memory access               
  signal   mem_address            : std_logic_vector(31 downto  0) := (others => '0');
  signal   mem_rd_addr_ack        : std_logic := '0';
  signal   mem_rd_req             : std_logic_vector( 4 downto  0) := (others => '0');
  signal   mem_rd_ack             : std_logic := '0';
  signal   mem_rd_data            : std_logic_vector(31 downto  0) := (others => '0');
  signal   mem_wr_ack             : std_logic := '0';
  signal   mem_wr_data            : std_logic_vector(31 downto  0) := (others => '0');

  signal core_clk : std_logic;
  signal timer : unsigned(31 downto 0);

  --Per-GTX-Tile signals
  signal qsfp13_mgt_o : mgt_out_type;
  signal qsfp02_mgt_o : mgt_out_type;
  signal p0_mgt_o     : mgt_out_type;
  signal bpm01_mgt_o  : mgt_out_type;
  signal bpm23_mgt_o  : mgt_out_type;
  signal qsfp_fifo_rst_c : std_logic_vector(0 to 3);
  signal bpm_fifo_rst_c  : std_logic_vector(0 to 3);
  signal p0_fifo_rst_c   : std_logic_vector(0 to 1);

  --RX channels
  signal qsfp_rx_sync    : std_logic_vector(0 to 3);
  signal p0_rx_sync     : std_logic_vector(0 to 1);
  signal bpm_rx_sync     : std_logic_vector(0 to 3);

  --Per-GTX-channel signals
  signal qsfp_loopback    : array3(0 to 3);
  signal qsfp_fifo_rst    : std_logic_vector(0 to 3);
  signal bpm_loopback    : array3(0 to 3);
  signal bpm_fifo_rst    : std_logic_vector(0 to 3);
  signal p0_loopback    : array3(0 to 1);
  signal p0_fifo_rst    : std_logic_vector(0 to 1);
  --RX channels
  signal qsfp_rxf_vld     : std_logic_vector(0 to 3);
  signal qsfp_rxf_next    : std_logic_vector(0 to 3);
  signal qsfp_rxf_empty   : std_logic_vector(0 to 3);
  signal qsfp_rxf_charisk : array4(0 to 3);
  signal qsfp_rxf_data    : array32(0 to 3);
  --
  signal bpm_rxf_vld     : std_logic_vector(0 to 3);
  signal bpm_rxf_next    : std_logic_vector(0 to 3);
  signal bpm_rxf_empty   : std_logic_vector(0 to 3);
  signal bpm_rxf_charisk : array4(0 to 3);
  signal bpm_rxf_data    : array32(0 to 3);
  --TX channels
  signal qsfp_txf_vld     : std_logic_vector(0 to 3);
  signal qsfp_txf_full    : std_logic_vector(0 to 3);
  signal qsfp_txf_write   : std_logic_vector(0 to 3);
  signal qsfp_txf_charisk : array4(0 to 3);
  signal qsfp_txf_data    : array32(0 to 3);

  signal p0_txf_vld     : std_logic_vector(0 to 1);
  signal p0_txf_full    : std_logic_vector(0 to 1);
  signal p0_txf_write   : std_logic_vector(0 to 1);
  signal p0_txf_charisk : array4(0 to 1);
  signal p0_txf_data    : array32(0 to 1);
  --
  signal bpm_txf_vld     : std_logic_vector(0 to 3);
  signal bpm_txf_full    : std_logic_vector(0 to 3);
  signal bpm_txf_write   : std_logic_vector(0 to 3);
  signal bpm_txf_charisk : array4(0 to 3);
  signal bpm_txf_data    : array32(0 to 3);

  --FILTERS
  signal filt13_bpm_id    : bpm_id_t; --allowed BPM ids 
  signal filt13_rst       : std_logic;
  signal filt13_trig      : std_logic;
  signal filt13_resetting : std_logic;
  signal filt13_valid     : std_logic;
  --ML84 26.8.16, dual output
  signal filt13_discard_x : std_logic;
  signal filt13_discard_y : std_logic;
  signal filt13_o_next_x    : std_logic;
  signal filt13_o_valid_x   : std_logic;
  signal filt13_o_charisk_x : std_logic_vector(3 downto 0);
  signal filt13_o_data_x    : std_logic_vector(31 downto 0);
  signal filt13_o_next_y    : std_logic;
  signal filt13_o_valid_y   : std_logic;
  signal filt13_o_charisk_y : std_logic_vector(3 downto 0);
  signal filt13_o_data_y    : std_logic_vector(31 downto 0);
  signal filt13_bkt_min   : std_logic_vector(15 downto 0);
  signal filt13_bkt_max   : std_logic_vector(15 downto 0);
  signal filt13_ram_rdata : std_logic_vector(2**BPM_BITS-1 downto 0);

  signal filt02_bpm_id    : bpm_id_t; --allowed BPM ids 
  signal filt02_rst       : std_logic;
  signal filt02_trig      : std_logic;
  signal filt02_resetting : std_logic;
  signal filt02_valid     : std_logic;
  signal filt02_discard_x : std_logic;
  signal filt02_discard_y : std_logic;
  signal filt02_o_next_x    : std_logic;
  signal filt02_o_valid_x   : std_logic;
  signal filt02_o_charisk_x : std_logic_vector(3 downto 0);
  signal filt02_o_data_x    : std_logic_vector(31 downto 0);
  signal filt02_o_next_y    : std_logic;
  signal filt02_o_valid_y   : std_logic;
  signal filt02_o_charisk_y : std_logic_vector(3 downto 0);
  signal filt02_o_data_y    : std_logic_vector(31 downto 0);
  signal filt02_bkt_min   : std_logic_vector(15 downto 0);
  signal filt02_bkt_max   : std_logic_vector(15 downto 0);
  signal filt02_ram_rdata : std_logic_vector(2**BPM_BITS-1 downto 0);

  signal ping_en : std_logic_vector(0 to 3);
  signal ping_rx : std_logic_vector(0 to 3);
  signal ping_lat : array32(0 to 3);

  --PACKET ROUTER
  signal router_rst       : std_logic;
  signal router_err_rst   : std_logic;
  --v2.00: changed number on router's inputs from 5 to 3
  --ML84 26.8.16, dual router
  signal xrouter_i_next    : std_logic_vector(0 to 2);
  signal xrouter_i_valid   : std_logic_vector(0 to 2);
  signal xrouter_i_charisk : array4(0 to 2);
  signal xrouter_i_data    : array32(0 to 2);
  signal yrouter_i_next    : std_logic_vector(0 to 2);
  signal yrouter_i_valid   : std_logic_vector(0 to 2);
  signal yrouter_i_charisk : array4(0 to 2);
  signal yrouter_i_data    : array32(0 to 2);
  --v2.00: changed number on router's outputs from 2 to 3
  signal xrouter_o_enable  : std_logic_vector(0 to 1); --added v2.00
  signal xrouter_o_next    : std_logic_vector(0 to 1);
  signal xrouter_o_valid   : std_logic_vector(0 to 1);
  signal xrouter_o_err     : std_logic_vector(0 to 1);
  signal xrouter_o_charisk : array4(0 to 1);
  signal xrouter_o_data    : array32(0 to 1);
  signal yrouter_o_enable  : std_logic_vector(0 to 1); --added v2.00
  signal yrouter_o_next    : std_logic_vector(0 to 1);
  signal yrouter_o_valid   : std_logic_vector(0 to 1);
  signal yrouter_o_err     : std_logic_vector(0 to 1);
  signal yrouter_o_charisk : array4(0 to 1);
  signal yrouter_o_data    : array32(0 to 1);
  --v2.01: routing table as parameter
  signal xrouter_table, yrouter_table : array32(0 to 2);
  signal xrouter_f02_to_back,  xrouter_f02_to_side  : std_logic;
  signal xrouter_f13_to_back,  xrouter_f13_to_side  : std_logic;
  signal xrouter_side_to_back, xrouter_side_to_side : std_logic;
  signal yrouter_f02_to_back,  yrouter_f02_to_side  : std_logic;
  signal yrouter_f13_to_back,  yrouter_f13_to_side  : std_logic;
  signal yrouter_side_to_back, yrouter_side_to_side : std_logic;

  signal filt13_rst_c, filt13_reg_c : std_logic;
  signal filt02_rst_c, filt02_reg_c : std_logic;
  signal filt13_trig_c : std_logic;
  signal filt02_trig_c : std_logic;
  signal router_rst_c : std_logic;

  --LOS counters
  type   uarray16 is array(natural range <>) of unsigned(15 downto 0);
  signal los_cnt : uarray16(9 downto 0);
  signal los, los_r, los_cnt_rst : std_logic_vector(9 downto 0);

  --DEBUG FIFO
  signal dbg_fifo_en, dbg_fifo_rst, dbg_fifo_rst_c : std_logic;
  signal dbg_fifo_full, dbg_fifo_write, dbg_fifo_empty, dbg_fifo_read, dbg_fifo_read_re : std_logic;
  signal dbg_fifo_charisk : std_logic_vector(3 downto 0);
  signal dbg_fifo_data    : std_logic_vector(31 downto 0);
  signal pkt_rx_bad_data, pkt_rx_eop, pkt_rx_crc_good : std_logic;

  -- KW84, 08.08.2016, filter statistics  
  signal r_filter02_statistics   : ibfb_comm_filter_statistics;
  signal r_filter13_statistics   : ibfb_comm_filter_statistics;
  
  --CRC error counter
  signal crc_err_cnt : std_logic_vector(31 downto 0) := (others => '0');
  signal crcerr_cnt_rst : std_logic := '0';


  --TIMING COMPONENT (ML84 20.6.16)
  --type t_cpu_timing_rd is record
  --  ext_trg_missing : std_logic;
  --  read_ready      : std_logic;
  --end record t_cpu_timing_rd;
  signal r_timing_param_rd : t_cpu_timing_rd;

  --type t_cpu_timing_wr is record
  --  global_trg_ena : std_logic;
  --  trg_mode       : std_logic;
  --  trg_source     : std_logic_vector(2 downto 0);
  --  b_delay        : std_logic_vector(27 downto  0);    
  --  b_number       : std_logic_vector(15 downto  0);    
  --  b_space        : std_logic_vector(15 downto  0);    
  --  trg_rate       : std_logic_vector( 2 downto  0);    -- 0x2C -- unsigned char
  --  trg_once       : std_logic;                         -- 0x00 -- unsigned int
  --  end record t_cpu_timing_wr;
  signal r_timing_param_wr : t_cpu_timing_wr;

  --type t_timing is record
  --  sl_global_pulse_trg           : std_logic;
  --  sl_global_bunch_trg           : std_logic;
  --  sl_global_pulse               : std_logic;
  --end record t_timing;
  signal r_ibfb_timing              : t_timing; 
  signal r_ibfb_timing_lclk         : t_timing; 

  --type t_qdr2_single_out is record
  --      qdr2_trg    : std_logic;
  --      qdr2_we     : std_logic;
  --      qdr2_data0  : std_logic_vector(35 downto 0);
  --      qdr2_data1  : std_logic_vector(35 downto 0);
  --      qdr2_data2  : std_logic_vector(35 downto 0);
  --      qdr2_data3  : std_logic_vector(35 downto 0);
  --end record t_qdr2_single_out;
  signal filt13_qdr2_out, filt02_qdr2_out : t_qdr2_single_out;

  -- interrupts
  signal sl_cpu_int               : std_logic;
  signal sl_ctrl_sys_int0         : std_logic;

  signal Bus2IP_Reset_r : std_logic;
  
  signal filt02_csp_clk : std_logic;
  signal filt02_csp_data : std_logic_vector(127 downto 0);
  signal filt13_csp_data : std_logic_vector(127 downto 0);

  for all: ibfb_packet_router use entity ibfb_common_v1_00_b.ibfb_packet_router(pkt_buf); 

  --DEBUG
  constant CSP_SET : natural := 3;
  signal xrouter_o_cnt, yrouter_o_cnt : unsigned(7 downto 0);

begin

--core_clk <= user_clk;
core_clk <= i_ext_clk;

TIMER_P : process(Bus2IP_Clk)
begin
    if rising_edge(Bus2IP_Clk) then
        Bus2IP_Reset_r <= Bus2IP_Reset;
        if (Bus2IP_Reset_r = '1') then
            timer <= (others => '0');
        else
            timer <= timer+1;
        end if;
    end if;
end process;

---------------------------------------------------------------------------
-- Status
---------------------------------------------------------------------------
IP2Bus_AddrAck <= slv_reg_rd_ack or mem_rd_addr_ack or
                  slv_reg_wr_ack or mem_wr_ack;
IP2Bus_RdAck   <= slv_reg_rd_ack or mem_rd_ack;
IP2Bus_WrAck   <= slv_reg_wr_ack or mem_wr_ack;
IP2Bus_Error <= '0';

---------------------------------------------------------------------------
-- IP to Bus data
---------------------------------------------------------------------------
IP2Bus_Data    <= slv_ip2bus_data when (slv_reg_rd_ack = '1') else
                  mem_rd_data     when (mem_rd_ack     = '1') else
                  (others => '0');

---------------------------------------------------------------------------
-- Register Read
---------------------------------------------------------------------------
slv_reg_rd_proc: process(Bus2IP_RdCE, slv_reg_rd) is
begin
   slv_ip2bus_data             <= (others => '0');
   for register_index in 0 to C_NUM_REG - 1 loop
     if (Bus2IP_RdCE(register_index) = '1') then
       slv_ip2bus_data       <= slv_reg_rd(register_index);
     end if;
   end loop;
end process slv_reg_rd_proc;

slv_reg_rd_ack                 <= '1' when (Bus2IP_RdCE /= LOW_REG) else '0';

---------------------------------------------------------------------------
-- Register Write
---------------------------------------------------------------------------
slv_reg_wr_proc: process(Bus2IP_Clk) is
begin
    if rising_edge(Bus2IP_Clk) then
        slv_reg_wr_gen: for register_index in 0 to C_NUM_REG - 1 loop
        if Bus2IP_Reset_r = '1' then
            slv_reg_wr(register_index) <= (others => '0');
        else
            if (Bus2IP_WrCE(register_index) = '1') then
                --for byte_index in 0 to (C_SLV_DWIDTH / 8) - 1 loop
                    if (Bus2IP_BE(0) = '1') then
                        slv_reg_wr(register_index)(31 downto 24) <= Bus2IP_Data( 0 to  7);
                    end if;
                    if (Bus2IP_BE(1) = '1') then
                        slv_reg_wr(register_index)(23 downto 16) <= Bus2IP_Data( 8 to 15);
                    end if;
                    if (Bus2IP_BE(2) = '1') then
                        slv_reg_wr(register_index)(15 downto  8) <= Bus2IP_Data(16 to 23);
                    end if;
                    if (Bus2IP_BE(3) = '1') then
                        slv_reg_wr(register_index)( 7 downto  0) <= Bus2IP_Data(24 to 31);
                    end if;
                --end loop;             
            end if;
        end if;
        end loop;
    end if;
end process slv_reg_wr_proc;

slv_reg_wr_ack                 <= '1' when (Bus2IP_WrCE /= LOW_REG) else '0';

---------------------------------------------------------------------------
-- Memory Read
---------------------------------------------------------------------------
mem_rd_req_proc: process(Bus2IP_Clk) is
begin
    if rising_edge(Bus2IP_Clk) then
        if (Bus2IP_Reset_r = '1') then
            mem_rd_req <= (others => '0');
        else
            if or_reduce(Bus2IP_CS) = '1' then
                mem_rd_req <= mem_rd_req(3 downto 0) & Bus2IP_RdReq;
            else
                mem_rd_req <= (others => '0');
            end if;
        end if;
    end if;
end process mem_rd_req_proc;

mem_rd_addr_ack <= '1' when ( (or_reduce(Bus2IP_CS) = '1') and (Bus2IP_RdReq = '1') ) else '0';
mem_rd_ack      <= '1' when (mem_rd_req( 4) = '1') else '0';

---------------------------------------------------------------------------
-- Memory write
---------------------------------------------------------------------------
mem_wr_ack      <= '1' when (  (or_reduce(Bus2IP_CS) = '1') and (Bus2IP_WrReq = '1') ) else '0';

---------------------------------------------------------------------------
-- Memory Interface
---------------------------------------------------------------------------
mem_address                    <= Bus2IP_Addr;
mem_rd_data                    <= (others => '0'); --X"000000" & filt13_ram_rdata & filt02_ram_rdata;
--mem_wr_data                    <= Bus2IP_Data(0 to 31);

--NAMING convention for QSFP (ignoring QSFP schematic naming)
--Connectors named left to right q0,q1,q2,q3 
--TILE0, GTX0 => q3
--TILE0, GTX1 => q1
--TILE1, GTX0 => q2
--TILE1, GTX1 => q0
--
--TILE0 = QSFP13
--TILE1 = QSFP02

---------------------------------------------------------------------------
-- CHIPSCOPE connections
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--csp_set0.cpj
--monitor Filter02 output data
---------------------------------------------------------------------------
CSP0_GEN : if CSP_SET = 0 generate

O_CSP_CLK   <= filt02_csp_clk; --Bus2IP_Clk;

O_CSP_REG_P : process(core_clk) 
begin
    if rising_edge(filt02_csp_clk) then
        O_CSP_DATA( 95 downto   0) <= filt02_csp_data(95 downto  0);
        O_CSP_DATA(127 downto  96) <= filt02_o_data_x;
        O_CSP_DATA(159 downto 128) <= filt02_o_data_y;
        O_CSP_DATA(163 downto 160) <= filt02_o_charisk_x;
        O_CSP_DATA(           164) <= filt02_o_valid_x;  
        O_CSP_DATA(           165) <= filt02_o_valid_y;  
        O_CSP_DATA(           166) <= filt02_o_next_x;  
        O_CSP_DATA(           167) <= filt02_o_next_y;  
    end if;
end process;
end generate; --CSP0_GEN

---------------------------------------------------------------------------
--csp_set1.cpj
--monitor Xrouter's data throughput
---------------------------------------------------------------------------
CSP1_GEN : if CSP_SET = 1 generate

O_CSP_CLK   <= core_clk; --Bus2IP_Clk;

O_CSP_REG_P : process(core_clk) 
begin
    if rising_edge(core_clk) then
        if r_ibfb_timing_lclk.sl_global_pulse_trg = '1' then
            xrouter_o_cnt <= (others => '0');
        elsif xrouter_o_valid(0) = '1' then
            xrouter_o_cnt <= xrouter_o_cnt+1;
        end if;

        O_CSP_DATA( 31 downto   0) <= xrouter_o_data(0);
        O_CSP_DATA( 35 downto  32) <= xrouter_o_charisk(0);
        O_CSP_DATA(            36) <= xrouter_o_valid(0);
        O_CSP_DATA(            37) <= xrouter_o_next(0);
        O_CSP_DATA(            38) <= xrouter_o_err(0);
        O_CSP_DATA(            39) <= r_ibfb_timing_lclk.sl_global_pulse_trg;
        O_CSP_DATA( 47 downto  40) <= std_logic_vector(xrouter_o_cnt);
        O_CSP_DATA(            48) <= xrouter_i_valid(0);
        O_CSP_DATA(            49) <= xrouter_i_valid(1);
        O_CSP_DATA(            50) <= xrouter_i_valid(2);
    end if;
end process;
end generate; --CSP1_GEN

---------------------------------------------------------------------------
--csp_set2.cpj
--monitor data going throug cross-FPGA links and routing tables
---------------------------------------------------------------------------
CSP2_GEN : if CSP_SET = 2 generate

O_CSP_CLK   <= core_clk; --Bus2IP_Clk;

O_CSP_REG_P : process(core_clk) 
begin
    if rising_edge(core_clk) then
        O_CSP_DATA( 31 downto   0) <= bpm_rxf_data(0);
        O_CSP_DATA( 63 downto  32) <= bpm_rxf_data(1);
        O_CSP_DATA( 95 downto  64) <= bpm_txf_data(0);
        O_CSP_DATA(127 downto  96) <= bpm_txf_data(1);
        O_CSP_DATA(131 downto 128) <= bpm_rxf_charisk(0);
        O_CSP_DATA(135 downto 132) <= bpm_rxf_charisk(1);
        O_CSP_DATA(139 downto 136) <= bpm_txf_charisk(0);
        O_CSP_DATA(143 downto 140) <= bpm_txf_charisk(1);
        O_CSP_DATA(           144) <= not bpm_rxf_empty(0);
        O_CSP_DATA(           145) <= not bpm_rxf_empty(1);
        O_CSP_DATA(           146) <= bpm_txf_write(0);
        O_CSP_DATA(           147) <= bpm_txf_write(1);
        O_CSP_DATA(           148) <= bpm_rxf_next(0);
        O_CSP_DATA(           149) <= bpm_rxf_next(1);
        O_CSP_DATA(           150) <= filt02_csp_data(15);
        O_CSP_DATA(           151) <= filt13_csp_data(15);
        O_CSP_DATA(           152) <= xrouter_table(0)(0);
        O_CSP_DATA(           153) <= xrouter_table(0)(1);
        O_CSP_DATA(           154) <= xrouter_table(1)(0);
        O_CSP_DATA(           155) <= xrouter_table(1)(1);
        O_CSP_DATA(           156) <= xrouter_table(2)(0);
        O_CSP_DATA(           157) <= xrouter_table(2)(1);
        O_CSP_DATA(           158) <= yrouter_table(0)(0);
        O_CSP_DATA(           159) <= yrouter_table(0)(1);
        O_CSP_DATA(           160) <= yrouter_table(1)(0);
        O_CSP_DATA(           161) <= yrouter_table(1)(1);
        O_CSP_DATA(           162) <= yrouter_table(2)(0);
        O_CSP_DATA(           163) <= yrouter_table(2)(1);
        O_CSP_DATA(           164) <= xrouter_i_valid(0);
        O_CSP_DATA(           165) <= xrouter_i_valid(1);
        O_CSP_DATA(           166) <= xrouter_i_valid(2);
        O_CSP_DATA(           167) <= yrouter_i_valid(0);
        O_CSP_DATA(           168) <= yrouter_i_valid(1);
        O_CSP_DATA(           169) <= yrouter_i_valid(2);
    end if;
end process;
end generate; --CSP2_GEN

---------------------------------------------------------------------------
--csp_set3.cpj
--monitor data received from QSFP
---------------------------------------------------------------------------
CSP3_GEN : if CSP_SET = 3 generate

O_CSP_CLK   <= core_clk; --Bus2IP_Clk;

O_CSP_REG_P : process(core_clk) 
begin
    if rising_edge(core_clk) then
        O_CSP_DATA( 95 downto   0) <= filt02_csp_data(95 downto  0);
    end if;
end process;
end generate; --CSP3_GEN

---------------------------------------------------------------------------
-- PLB connections
---------------------------------------------------------------------------

-- COMMANDS ---------------------------------------------------------------
--0x00 RESET  filt02_rst, filt13_rst, p0(2), bpm(4), qsfp(4)
--0x04 LOOPBACK QSFP
--0x08 LOOPBACK BPM
--0x0C LOOPBACK P0
--
REGBANK_WR_P : process(core_clk)
begin
    if rising_edge(core_clk) then
		qsfp_fifo_rst_c   <= slv_reg_wr(0)(03 downto 00); 
		p0_fifo_rst_c     <= slv_reg_wr(0)(05 downto 04); 
		bpm_fifo_rst_c    <= slv_reg_wr(0)(09 downto 06); 
		filt13_rst_c      <= slv_reg_wr(0)(10);
		filt02_rst_c      <= slv_reg_wr(0)(11);
		router_rst_c      <= slv_reg_wr(0)(12);
		router_err_rst    <= slv_reg_wr(0)(13);
		--                <= slv_reg_wr(0)(15 downto 14);
		filt13_trig_c     <= slv_reg_wr(0)(16);
		filt02_trig_c     <= slv_reg_wr(0)(17);
		--dbg_fifo_en       <= slv_reg_wr(0)(18);
		--dbg_fifo_rst_c    <= slv_reg_wr(0)(19);
		los_cnt_rst       <= slv_reg_wr(0)(29 downto 20);
		crcerr_cnt_rst    <= slv_reg_wr(0)(31);
		
		--
		qsfp_loopback(0)  <= slv_reg_wr(1)(02 downto 00); 
		qsfp_loopback(1)  <= slv_reg_wr(1)(06 downto 04); 
		qsfp_loopback(2)  <= slv_reg_wr(1)(10 downto 08); 
		qsfp_loopback(3)  <= slv_reg_wr(1)(14 downto 12); 
		--
		bpm_loopback(0)   <= slv_reg_wr(1)(18 downto 16); 
		bpm_loopback(1)   <= slv_reg_wr(1)(22 downto 20); 
		bpm_loopback(2)   <= slv_reg_wr(1)(26 downto 24); 
		bpm_loopback(3)   <= slv_reg_wr(1)(30 downto 28); 
		--
		p0_loopback(0)    <= slv_reg_wr(2)(02 downto 00); 
		p0_loopback(1)    <= slv_reg_wr(2)(06 downto 04); 

        yrouter_side_to_side <= slv_reg_wr(2)(08);
        yrouter_side_to_back <= slv_reg_wr(2)(09);
        yrouter_f13_to_side  <= slv_reg_wr(2)(10);
        yrouter_f13_to_back  <= slv_reg_wr(2)(11);
        yrouter_f02_to_side  <= slv_reg_wr(2)(12);
        yrouter_f02_to_back  <= slv_reg_wr(2)(13);

        xrouter_side_to_side <= slv_reg_wr(2)(16);
        xrouter_side_to_back <= slv_reg_wr(2)(17);
        xrouter_f13_to_side  <= slv_reg_wr(2)(18);
        xrouter_f13_to_back  <= slv_reg_wr(2)(19);
        xrouter_f02_to_side  <= slv_reg_wr(2)(20);
        xrouter_f02_to_back  <= slv_reg_wr(2)(21);

		--xrouter_o_enable   <= slv_reg_wr(2)(31 downto 30);
		--yrouter_o_enable   <= slv_reg_wr(2)(29 downto 28);

        filt13_bpm_id(0)  <= slv_reg_wr(7)( 7 downto  0); --X
        filt13_bpm_id(1)  <= slv_reg_wr(7)(15 downto  8); --X
        filt13_bpm_id(2)  <= slv_reg_wr(7)(23 downto 16); --Y
        filt13_bpm_id(3)  <= slv_reg_wr(7)(31 downto 24); --Y
        filt02_bpm_id(0)  <= slv_reg_wr(8)( 7 downto  0); --X
        filt02_bpm_id(1)  <= slv_reg_wr(8)(15 downto  8); --X
        filt02_bpm_id(2)  <= slv_reg_wr(8)(23 downto 16); --Y
        filt02_bpm_id(3)  <= slv_reg_wr(8)(31 downto 24); --Y

		--TIMING COMPONENT (ML84 20.6.16)
		r_timing_param_wr.global_trg_ena <= slv_reg_wr(15)( 0); --21
		r_timing_param_wr.trg_mode       <= slv_reg_wr(15)( 8); --21
		r_timing_param_wr.trg_source     <= slv_reg_wr(15)(18 downto 16); --21
		r_timing_param_wr.b_delay        <= slv_reg_wr(16)(27 downto  0); --22
		r_timing_param_wr.b_number       <= slv_reg_wr(17)(15 downto  0); --23
		r_timing_param_wr.b_space        <= slv_reg_wr(17)(31 downto 16); --23
		r_timing_param_wr.trg_rate       <= slv_reg_wr(18)( 2 downto  0); --24
		r_timing_param_wr.trg_once       <= Bus2IP_WrCE(19); --25

        --BUCKET RANGE CONTROL (ML84 23.8.16)
        filt02_bkt_min                   <= slv_reg_wr(28)(31 downto 16);
        filt02_bkt_max                   <= slv_reg_wr(28)(15 downto 00);
        filt13_bkt_min                   <= slv_reg_wr(29)(31 downto 16);
        filt13_bkt_max                   <= slv_reg_wr(29)(15 downto 00);

        ping_en(0) <= slv_reg_wr(32)(24);
        ping_en(1) <= slv_reg_wr(32)(16);
        ping_en(2) <= slv_reg_wr(32)(08);
        ping_en(3) <= slv_reg_wr(32)(00);

    end if;
end process;

-- STATUS -----------------------------------------------------------------
REGBANK_RD_P : process(Bus2IP_Clk)
begin
    if rising_edge(Bus2IP_Clk) then
		slv_reg_rd( 0)               <= slv_reg_wr(0);
		slv_reg_rd( 1)               <= slv_reg_wr(1);
		slv_reg_rd( 2)               <= slv_reg_wr(2);
		--
		slv_reg_rd( 3)( 0)           <= qsfp13_mgt_o.ctrl.PLLLKDET;
		slv_reg_rd( 3)( 1)           <= qsfp13_mgt_o.ctrl.RESETDONE0;
		slv_reg_rd( 3)( 2)           <= qsfp13_mgt_o.ctrl.RESETDONE1;
		slv_reg_rd( 3)( 3)           <= '0';
		slv_reg_rd( 3)( 5 downto  4) <= qsfp13_mgt_o.rx(0).RXLOSSOFSYNC;
		slv_reg_rd( 3)( 7 downto  6) <= qsfp13_mgt_o.rx(1).RXLOSSOFSYNC;
		--
		slv_reg_rd( 3)( 8)           <= qsfp02_mgt_o.ctrl.PLLLKDET;
		slv_reg_rd( 3)( 9)           <= qsfp02_mgt_o.ctrl.RESETDONE0;
		slv_reg_rd( 3)(10)           <= qsfp02_mgt_o.ctrl.RESETDONE1;
		slv_reg_rd( 3)(11)           <= '0';
		slv_reg_rd( 3)(13 downto 12) <= qsfp02_mgt_o.rx(0).RXLOSSOFSYNC;
		slv_reg_rd( 3)(15 downto 14) <= qsfp02_mgt_o.rx(1).RXLOSSOFSYNC;
		--
		slv_reg_rd( 3)(16)           <= bpm01_mgt_o.ctrl.PLLLKDET;
		slv_reg_rd( 3)(17)           <= bpm01_mgt_o.ctrl.RESETDONE0;
		slv_reg_rd( 3)(18)           <= bpm01_mgt_o.ctrl.RESETDONE1;
		slv_reg_rd( 3)(19)           <= '0';
		slv_reg_rd( 3)(21 downto 20) <= bpm01_mgt_o.rx(0).RXLOSSOFSYNC;
		slv_reg_rd( 3)(23 downto 22) <= bpm01_mgt_o.rx(1).RXLOSSOFSYNC;
		--
		slv_reg_rd( 3)(24)           <= bpm23_mgt_o.ctrl.PLLLKDET;
		slv_reg_rd( 3)(25)           <= bpm23_mgt_o.ctrl.RESETDONE0;
		slv_reg_rd( 3)(26)           <= bpm23_mgt_o.ctrl.RESETDONE1;
		slv_reg_rd( 3)(27)           <= '0';
		slv_reg_rd( 3)(29 downto 28) <= bpm23_mgt_o.rx(0).RXLOSSOFSYNC;
		slv_reg_rd( 3)(31 downto 30) <= bpm23_mgt_o.rx(1).RXLOSSOFSYNC;
		--
		slv_reg_rd( 4)( 0)           <= p0_mgt_o.ctrl.PLLLKDET;
		slv_reg_rd( 4)( 1)           <= p0_mgt_o.ctrl.RESETDONE0;
		slv_reg_rd( 4)( 2)           <= p0_mgt_o.ctrl.RESETDONE1;
		slv_reg_rd( 4)( 3)           <= '0';
		slv_reg_rd( 4)( 5 downto  4) <= p0_mgt_o.rx(0).RXLOSSOFSYNC;
		slv_reg_rd( 4)( 7 downto  6) <= p0_mgt_o.rx(1).RXLOSSOFSYNC;
		--
		slv_reg_rd( 4)(11 downto 10) <= xrouter_o_err;
		slv_reg_rd( 4)(09 downto 08) <= yrouter_o_err;
		slv_reg_rd( 4)(31 downto 16) <= K_SOP & K_EOP;
		--
		slv_reg_rd( 5)(17 downto 8)  <= bpm_rx_sync & p0_rx_sync & qsfp_rx_sync;
        --slv_reg_rd( 6)               <= USED FOR INTERRUPT                      

        --
		slv_reg_rd( 7)               <= slv_reg_wr(7);
		slv_reg_rd( 8)               <= slv_reg_wr(8);
		slv_reg_rd( 9)               <= std_logic_vector(los_cnt(1)) & std_logic_vector(los_cnt(0));
		slv_reg_rd(10)               <= std_logic_vector(los_cnt(3)) & std_logic_vector(los_cnt(2));
		slv_reg_rd(11)               <= std_logic_vector(los_cnt(5)) & std_logic_vector(los_cnt(4));
		slv_reg_rd(12)               <= std_logic_vector(los_cnt(7)) & std_logic_vector(los_cnt(6));
		slv_reg_rd(13)               <= std_logic_vector(los_cnt(9)) & std_logic_vector(los_cnt(8));
        --TIMER
		slv_reg_rd(14)               <= std_logic_vector(timer);
		
		--TIMING COMPONENT (ML84 20.6.16)
		slv_reg_rd(15)               <= slv_reg_wr(15); --timing
		slv_reg_rd(16)               <= slv_reg_wr(16); --timing
		slv_reg_rd(17)               <= slv_reg_wr(17); --timing
		slv_reg_rd(18)               <= slv_reg_wr(18); --timing
		slv_reg_rd(19)               <= slv_reg_wr(19); --timing
		--
		slv_reg_rd(20)( 0)           <= r_timing_param_rd.ext_trg_missing; --26
		slv_reg_rd(20)( 8)           <= r_timing_param_rd.read_ready; --26
		-- KW84, 08.08.2016, filter statistics
		slv_reg_rd(21)(31 downto 16) <= r_filter02_statistics.packets_chan0_in ;
		slv_reg_rd(21)(15 downto  0) <= r_filter02_statistics.packets_chan1_in ;
		slv_reg_rd(22)(31 downto 16) <= r_filter13_statistics.packets_chan0_in ;
		slv_reg_rd(22)(15 downto  0) <= r_filter13_statistics.packets_chan1_in ;
        --
		slv_reg_rd(23)(31 downto 16) <= r_filter02_statistics.packets_discarded_x; 
		slv_reg_rd(23)(15 downto  0) <= r_filter02_statistics.packets_discarded_y; 
		slv_reg_rd(24)(31 downto 16) <= r_filter13_statistics.packets_discarded_x; 
		slv_reg_rd(24)(15 downto  0) <= r_filter13_statistics.packets_discarded_y; 
        --
		slv_reg_rd(25)(31 downto 24) <= r_filter02_statistics.wrong_bpm_id_x   ; 
		slv_reg_rd(25)(23 downto 16) <= r_filter02_statistics.wrong_bpm_id_y   ; 
		slv_reg_rd(25)(15 downto 08) <= r_filter13_statistics.wrong_bpm_id_x   ; 
		slv_reg_rd(25)(07 downto 00) <= r_filter13_statistics.wrong_bpm_id_y   ; 
        --
		slv_reg_rd(26)(31 downto 16) <= r_filter02_statistics.packets_passed_x ; 
		slv_reg_rd(26)(15 downto  0) <= r_filter02_statistics.packets_passed_y ; 
		slv_reg_rd(27)(31 downto 16) <= r_filter13_statistics.packets_passed_x ; 
		slv_reg_rd(27)(15 downto  0) <= r_filter13_statistics.packets_passed_y ; 
		--
		slv_reg_rd(28)               <= slv_reg_wr(28); --bucket range control
		slv_reg_rd(29)               <= slv_reg_wr(29); --bucket range control
        --
        slv_reg_rd(31)               <= FW_VERSION; --firmware version

		slv_reg_rd(32)               <= slv_reg_wr(32); --ping enable         
        slv_reg_rd(33)(24)           <= ping_rx(0);
        slv_reg_rd(33)(16)           <= ping_rx(1);
        slv_reg_rd(33)(08)           <= ping_rx(2);
        slv_reg_rd(33)(00)           <= ping_rx(3);
        slv_reg_rd(34)               <= ping_lat(0);
        slv_reg_rd(35)               <= ping_lat(1);
        slv_reg_rd(36)               <= ping_lat(2);
        slv_reg_rd(37)               <= ping_lat(3);
    end if;
end process;

  ---------------------------------------------------------------------------
  -- Interrupt generation and acknowledge  
  ---------------------------------------------------------------------------
  prc_interrupt : process ( Bus2IP_Clk )
    variable vslv_rdy : std_logic_vector(1  downto 0)  := (others => '0');
  begin
    if rising_edge(Bus2IP_Clk) then
      -- falling edge of the global pulse
      if vslv_rdy = "10" then
        sl_cpu_int      <= '1';
      else
        sl_cpu_int      <= '0';      
      end if;
      -- set by PPC when post-processing is finished
      if Bus2IP_WrCE( 6) = '1' then
        sl_ctrl_sys_int0 <= '1';
      end if;
      -- reset interrupt when acknowledge comes from the control system or the next pulse trigger comes
      if (Bus2IP_RdCE(6) = '1') or (vslv_rdy = "01") then
        sl_ctrl_sys_int0 <= '0';
      end if;
      vslv_rdy          := vslv_rdy(0) & r_ibfb_timing.sl_global_pulse;
    end if;
  end process ;
  
  slv_reg_rd(6)( 0) <= sl_ctrl_sys_int0;
   
  o_cpu_int         <= sl_cpu_int;
  o_ctrl_sys_int    <= sl_ctrl_sys_int0;
  
---------------------------------------------------------------------------
-- Loss of sync counters
---------------------------------------------------------------------------

--ML84 21.6.16 (added timing component)
ibfb_timing_inst : ibfb_timing
port map (
    i_dac_clk     => i_ext_clk,
    -- Sampling interface
    i_cpu_clk     => core_clk,
    i_cpu_fsm_wr  => r_timing_param_wr,
    o_cpu_fsm_rd  => r_timing_param_rd,
    -- BPM interface
    i_ext_trg     => i_trigger,
    o_ibfb_timing => r_ibfb_timing,
    o_led_pulse   => o_led_pulse,
    -- debug
    o_csp_clk     => open, --o_csp_clk         
    o_csp_data    => open  --o_csp_data
);

--Loss-of-sync detection (rising edge)
LOS_RE_P : process(Bus2IP_Clk)
begin
    if rising_edge(Bus2IP_Clk) then
        --first registration of LOS signals
        los(0) <= qsfp02_mgt_o.rx(1).RXLOSSOFSYNC(1); --qsfp0
        los(1) <= qsfp13_mgt_o.rx(1).RXLOSSOFSYNC(1); --qsfp1
        los(2) <= qsfp02_mgt_o.rx(0).RXLOSSOFSYNC(1); --qsfp2
        los(3) <= qsfp13_mgt_o.rx(0).RXLOSSOFSYNC(1); --qsfp3
        los(4) <= p0_mgt_o.rx(0).RXLOSSOFSYNC(1);
        los(5) <= p0_mgt_o.rx(1).RXLOSSOFSYNC(1);
        los(6) <= bpm01_mgt_o.rx(0).RXLOSSOFSYNC(1);
        los(7) <= bpm01_mgt_o.rx(1).RXLOSSOFSYNC(1);
        los(8) <= bpm23_mgt_o.rx(0).RXLOSSOFSYNC(1);
        los(9) <= bpm23_mgt_o.rx(1).RXLOSSOFSYNC(1);
        --second registration (needed for edge detection)
        los_r <= los;
    end if;
end process;

--Increment counters on rising edge of LOSSOFSYNC(1)
LOS_CNT_GEN : for i in 0 to 9 generate
    LOS_CNT_P : process(Bus2IP_Clk)
    begin
        if rising_edge(Bus2IP_Clk) then
            if Bus2IP_Reset_r = '1' or los_cnt_rst(i) = '1' then
                los_cnt(i) <= (others => '0');
            else
                -- KW84, 05.08.2016
                --if los(i) = '1' and los_r(i) = '0' and los_cnt(i)(los_cnt(i)'left) = '0' then
                if los(i) = '1' and los_r(i) = '0' then
                    los_cnt(i) <= los_cnt(i)+1;
                end if;
            end if;
        end if;
    end process;
end generate;

---------------------------------------------------------------------------
-- GTX components
---------------------------------------------------------------------------
qsfp_fifo_rst(0) <= Bus2IP_Reset_r or qsfp_fifo_rst_c(0);
qsfp_fifo_rst(1) <= Bus2IP_Reset_r or qsfp_fifo_rst_c(1);
qsfp_fifo_rst(2) <= Bus2IP_Reset_r or qsfp_fifo_rst_c(2);
qsfp_fifo_rst(3) <= Bus2IP_Reset_r or qsfp_fifo_rst_c(3);
  p0_fifo_rst(0) <= Bus2IP_Reset_r or   p0_fifo_rst_c(0);
  p0_fifo_rst(1) <= Bus2IP_Reset_r or   p0_fifo_rst_c(1);
 bpm_fifo_rst(0) <= Bus2IP_Reset_r or  bpm_fifo_rst_c(0);
 bpm_fifo_rst(1) <= Bus2IP_Reset_r or  bpm_fifo_rst_c(1);
 bpm_fifo_rst(2) <= Bus2IP_Reset_r or  bpm_fifo_rst_c(2);
 bpm_fifo_rst(3) <= Bus2IP_Reset_r or  bpm_fifo_rst_c(3);

QSFP13_TILE : gtx_tile
generic map(
    --mgt
    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(0),
    G_GTX_TILE_REFCLK_FREQ => C_SFP13_REFCLK_FREQ,
    G_GTX_BAUD_RATE        => C_SFP13_BAUD_RATE
)
port map(
    ------------------------------------------------------------------------
    -- GTX INTERFACE
    ------------------------------------------------------------------------
    I_GTX_REFCLK1_IN            => I_GTX_REFCLK1_IN,
    I_GTX_REFCLK2_IN            => I_GTX_REFCLK2_IN,
    I_GTX_RX_N                  => I_GTX_RX_N(1 downto 0),
    I_GTX_RX_P                  => I_GTX_RX_P(1 downto 0),
    O_GTX_TX_N                  => O_GTX_TX_N(1 downto 0),
    O_GTX_TX_P                  => O_GTX_TX_P(1 downto 0),
    ------------------------------------------------------------------------
    -- GTX SETTINGS & STATUS
    ------------------------------------------------------------------------
    i_loopback0      => qsfp_loopback(3),
    i_loopback1      => qsfp_loopback(1),
    o_mgt            => qsfp13_mgt_o,
    ------------------------------------------------------------------------
    -- FIFO interface
    ------------------------------------------------------------------------
    i_clk => core_clk, --Bus2IP_Clk,
    --Channel 3
    i_fifo_reset0     => qsfp_fifo_rst(3), 
    --TX
    o_tx_vld0         => qsfp_txf_vld(3), --debug
    o_txfifo_full0    => qsfp_txf_full(3),
    i_txfifo_write0   => qsfp_txf_write(3),
    i_txfifo_charisk0 => qsfp_txf_charisk(3),
    i_txfifo_data0    => qsfp_txf_data(3),
    --RX
    o_rx_sync_done0   => qsfp_rx_sync(3),
    o_rx_vld0         => qsfp_rxf_vld(3), --debug
    i_rxfifo_next0    => qsfp_rxf_next(3),
    o_rxfifo_empty0   => qsfp_rxf_empty(3),
    o_rxfifo_charisk0 => qsfp_rxf_charisk(3),
    o_rxfifo_data0    => qsfp_rxf_data(3),
    --Channel 1
    i_fifo_reset1     => qsfp_fifo_rst(1),
    --TX
    o_tx_vld1         => qsfp_txf_vld(1), --debug
    o_txfifo_full1    => qsfp_txf_full(1),
    i_txfifo_write1   => qsfp_txf_write(1),
    i_txfifo_charisk1 => qsfp_txf_charisk(1),
    i_txfifo_data1    => qsfp_txf_data(1),
    --RX
    o_rx_sync_done1   => qsfp_rx_sync(1),
    o_rx_vld1         => qsfp_rxf_vld(1), --debug
    i_rxfifo_next1    => qsfp_rxf_next(1),
    o_rxfifo_empty1   => qsfp_rxf_empty(1),
    o_rxfifo_charisk1 => qsfp_rxf_charisk(1),
    o_rxfifo_data1    => qsfp_rxf_data(1) 
);


QSFP02_TILE : gtx_tile
generic map(
    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(1),
    G_GTX_TILE_REFCLK_FREQ => C_SFP02_REFCLK_FREQ,
    G_GTX_BAUD_RATE        => C_SFP02_BAUD_RATE
)
port map(
    ------------------------------------------------------------------------
    -- GTX INTERFACE
    ------------------------------------------------------------------------
    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
    O_GTX_REFCLK_OUT => open,
    I_GTX_RX_N       => I_GTX_RX_N(3 downto 2),
    I_GTX_RX_P       => I_GTX_RX_P(3 downto 2),
    O_GTX_TX_N       => O_GTX_TX_N(3 downto 2),
    O_GTX_TX_P       => O_GTX_TX_P(3 downto 2),
    ------------------------------------------------------------------------
    -- GTX SETTINGS & STATUS
    ------------------------------------------------------------------------
    i_loopback0 => qsfp_loopback(2),
    i_loopback1 => qsfp_loopback(0),
    o_mgt       => qsfp02_mgt_o,
    ------------------------------------------------------------------------
    -- FIFO interface
    ------------------------------------------------------------------------
    i_clk             => core_clk, --Bus2IP_Clk,
    --Channel 2
    i_fifo_reset0     => qsfp_fifo_rst(2),
    --TX
    o_tx_vld0         => qsfp_txf_vld(2),
    o_txfifo_full0    => qsfp_txf_full(2),
    i_txfifo_write0   => qsfp_txf_write(2),
    i_txfifo_charisk0 => qsfp_txf_charisk(2),
    i_txfifo_data0    => qsfp_txf_data(2),
    --RX
    o_rx_sync_done0   => qsfp_rx_sync(2),
    o_rx_vld0         => qsfp_rxf_vld(2), --debug
    i_rxfifo_next0    => qsfp_rxf_next(2),
    o_rxfifo_empty0   => qsfp_rxf_empty(2),
    o_rxfifo_charisk0 => qsfp_rxf_charisk(2),
    o_rxfifo_data0    => qsfp_rxf_data(2),
    --Channel 0
    i_fifo_reset1     => qsfp_fifo_rst(0),
    --TX
    o_tx_vld1         => qsfp_txf_vld(0),
    o_txfifo_full1    => qsfp_txf_full(0),
    i_txfifo_write1   => qsfp_txf_write(0),
    i_txfifo_charisk1 => qsfp_txf_charisk(0),
    i_txfifo_data1    => qsfp_txf_data(0),
    --RX
    o_rx_sync_done1   => qsfp_rx_sync(0),
    o_rx_vld1         => qsfp_rxf_vld(0), --debug
    i_rxfifo_next1    => qsfp_rxf_next(0),
    o_rxfifo_empty1   => qsfp_rxf_empty(0),
    o_rxfifo_charisk1 => qsfp_rxf_charisk(0),
    o_rxfifo_data1    => qsfp_rxf_data(0)
);

P0_TILE : gtx_tile
generic map(
    --mgt
    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(2),
    G_GTX_TILE_REFCLK_FREQ => C_P0_REFCLK_FREQ,
    G_GTX_BAUD_RATE        => C_P0_BAUD_RATE
)
port map(
    --MGT
    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
    I_GTX_RX_N       => I_GTX_RX_N(5 downto 4),
    I_GTX_RX_P       => I_GTX_RX_P(5 downto 4),
    O_GTX_TX_N       => O_GTX_TX_N(5 downto 4),
    O_GTX_TX_P       => O_GTX_TX_P(5 downto 4),
    --
    i_loopback0      => p0_loopback(0),
    i_loopback1      => p0_loopback(1),
    o_mgt            => p0_mgt_o,
    ------------------------------------------------------------------------
    -- FIFO interface
    ------------------------------------------------------------------------
    i_clk             => core_clk, --Bus2IP_Clk,
    --Channel 0
    i_fifo_reset0     => p0_fifo_rst(0),
    --TX
    o_tx_vld0         => p0_txf_vld(0), --debug
    o_txfifo_full0    => p0_txf_full(0),
    i_txfifo_write0   => p0_txf_write(0),
    i_txfifo_charisk0 => p0_txf_charisk(0),
    i_txfifo_data0    => p0_txf_data(0),
    --RX
    o_rx_sync_done0   => p0_rx_sync(0),
    o_rx_vld0         => open,
    i_rxfifo_next0    => '0',
    o_rxfifo_empty0   => open,
    o_rxfifo_charisk0 => open,
    o_rxfifo_data0    => open,
    --Channel 1
    i_fifo_reset1     => p0_fifo_rst(1),
    --TX
    o_tx_vld1         => p0_txf_vld(1), --debug
    o_txfifo_full1    => p0_txf_full(1),
    i_txfifo_write1   => p0_txf_write(1),
    i_txfifo_charisk1 => p0_txf_charisk(1),
    i_txfifo_data1    => p0_txf_data(1),
    --RX
    o_rx_sync_done1   => p0_rx_sync(1),
    o_rx_vld1         => open,
    i_rxfifo_next1    => '0',
    o_rxfifo_empty1   => open,
    o_rxfifo_charisk1 => open,
    o_rxfifo_data1    => open
);

BPM01_TILE : gtx_tile
generic map(
    --mgt
    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(3),
    G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
    G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
)
port map(
    --MGT
    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
    I_GTX_RX_N       => I_GTX_RX_N(7 downto 6),
    I_GTX_RX_P       => I_GTX_RX_P(7 downto 6),
    O_GTX_TX_N       => O_GTX_TX_N(7 downto 6),
    O_GTX_TX_P       => O_GTX_TX_P(7 downto 6),
    --
    i_loopback0      => bpm_loopback(0),
    i_loopback1      => bpm_loopback(1),
    o_mgt            => bpm01_mgt_o,
    ------------------------------------------------------------------------
    -- FIFO interface
    ------------------------------------------------------------------------
    i_clk             => core_clk, --Bus2IP_Clk,
    --Channel 0
    i_fifo_reset0     => bpm_fifo_rst(0),
    --TX
    o_tx_vld0         => bpm_txf_vld(0), --debug
    o_txfifo_full0    => bpm_txf_full(0),
    i_txfifo_write0   => bpm_txf_write(0),
    i_txfifo_charisk0 => bpm_txf_charisk(0),
    i_txfifo_data0    => bpm_txf_data(0),
    --RX
    o_rx_sync_done0   => bpm_rx_sync(0),
    o_rx_vld0         => bpm_rxf_vld(0), --debug
    i_rxfifo_next0    => bpm_rxf_next(0),
    o_rxfifo_empty0   => bpm_rxf_empty(0),
    o_rxfifo_charisk0 => bpm_rxf_charisk(0),
    o_rxfifo_data0    => bpm_rxf_data(0),
    --Channel 1
    i_fifo_reset1     => bpm_fifo_rst(1),
    --TX
    o_tx_vld1         => bpm_txf_vld(1), --debug
    o_txfifo_full1    => bpm_txf_full(1),
    i_txfifo_write1   => bpm_txf_write(1),
    i_txfifo_charisk1 => bpm_txf_charisk(1),
    i_txfifo_data1    => bpm_txf_data(1),
    --RX
    o_rx_sync_done1   => bpm_rx_sync(1),
    o_rx_vld1         => bpm_rxf_vld(1), --debug
    i_rxfifo_next1    => bpm_rxf_next(1),
    o_rxfifo_empty1   => bpm_rxf_empty(1),
    o_rxfifo_charisk1 => bpm_rxf_charisk(1),
    o_rxfifo_data1    => bpm_rxf_data(1) 
);

BPM23_TILE : gtx_tile
generic map(
    --mgt
    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(4),
    G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
    G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
)
port map(
    --MGT
    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
    I_GTX_RX_N       => I_GTX_RX_N(9 downto 8),
    I_GTX_RX_P       => I_GTX_RX_P(9 downto 8),
    O_GTX_TX_N       => O_GTX_TX_N(9 downto 8),
    O_GTX_TX_P       => O_GTX_TX_P(9 downto 8),
    --
    i_loopback0      => bpm_loopback(0),
    i_loopback1      => bpm_loopback(1),
    o_mgt            => bpm23_mgt_o,
    ------------------------------------------------------------------------
    -- FIFO interface
    ------------------------------------------------------------------------
    i_clk             => core_clk, --Bus2IP_Clk,
    --Channel 0
    i_fifo_reset0     => bpm_fifo_rst(2),
    --TX
    o_tx_vld0         => bpm_txf_vld(2), --debug
    o_txfifo_full0    => bpm_txf_full(2),
    i_txfifo_write0   => bpm_txf_write(2),
    i_txfifo_charisk0 => bpm_txf_charisk(2),
    i_txfifo_data0    => bpm_txf_data(2),
    --RX
    o_rx_sync_done0   => bpm_rx_sync(2),
    o_rx_vld0         => bpm_rxf_vld(2), --debug
    i_rxfifo_next0    => bpm_rxf_next(2),
    o_rxfifo_empty0   => bpm_rxf_empty(2),
    o_rxfifo_charisk0 => bpm_rxf_charisk(2),
    o_rxfifo_data0    => bpm_rxf_data(2),
    --Channel 1
    i_fifo_reset1     => bpm_fifo_rst(3),
    --TX
    o_tx_vld1         => bpm_txf_vld(3), --debug
    o_txfifo_full1    => bpm_txf_full(3),
    i_txfifo_write1   => bpm_txf_write(3),
    i_txfifo_charisk1 => bpm_txf_charisk(3),
    i_txfifo_data1    => bpm_txf_data(3),
    --RX
    o_rx_sync_done1   => bpm_rx_sync(3),
    o_rx_vld1         => bpm_rxf_vld(3), --debug
    i_rxfifo_next1    => bpm_rxf_next(3),
    o_rxfifo_empty1   => bpm_rxf_empty(3),
    o_rxfifo_charisk1 => bpm_rxf_charisk(3),
    o_rxfifo_data1    => bpm_rxf_data(3) 
);

---------------------------------------------------------------------------
-- PACKET rx filters
---------------------------------------------------------------------------
filt13_rst <= Bus2IP_Reset_r or filt13_rst_c;
filt02_rst <= Bus2IP_Reset_r or filt02_rst_c;

-- KW84, 05.08.2014
-- Timing signals come from different clock domain and must not be used
-- directly in another clock domain. The triger pulses have to be formed again
  ins_timing_clock_domain_cross: timing_clock_domain_cross
  port map (
    -- adc clk domain
    i_clk_in           => i_ext_clk, 
    i_timing_in        => r_ibfb_timing, 
    -- usr clk domain   
    i_clk_out          => Bus2IP_Clk, 
    o_timing_out       => r_ibfb_timing_lclk
  );

filt13_trig <= r_ibfb_timing_lclk.sl_global_pulse_trg or filt13_trig_c;
filt02_trig <= r_ibfb_timing_lclk.sl_global_pulse_trg or filt02_trig_c;

--v2.00: filter always connected
--If SFP13_FILT_EN = '1', then channels 1 and 3 are connected to a packet filter
--FILT13_GEN : if SFP13_FILT_EN = '1' generate

    QSFP13_FILTER_I : ibfb_packet_filter
    generic map(
        --protocol
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        K_BAD => K_BAD 
    )
    port map(
        --debug
        o_flag_ram_wen   => open,
        o_flag_ram_waddr => open,
        o_flag_ram_wdata => open,
        o_csp_data       => filt13_csp_data,
        o_csp_clk        => open ,
        --setup
        i_bpm_id         => filt13_bpm_id,
        i_bkt_min        => filt13_bkt_min,
        i_bkt_max        => filt13_bkt_max,
        --v2.1: PING feature
        i_ping_enable0   => ping_en(1),
        i_ping_enable1   => ping_en(3),
        o_ping_rx0       => ping_rx(1),
        o_ping_rx1       => ping_rx(3),
        o_ping_latency0  => ping_lat(1),
        o_ping_latency1  => ping_lat(3),
        --
        i_ram_clk        => Bus2IP_Clk,
        i_ram_raddr      => mem_address(11+2 downto 2),
        o_ram_rdata      => filt13_ram_rdata,
        --
        i_clk            => core_clk, --Bus2IP_Clk,
        i_rst            => filt13_rst,
        i_trig           => filt13_trig,
        o_resetting      => filt13_resetting,
        o_pkt_valid      => filt13_valid,
        --ML84 26.8.16
        --o_pkt_discard    => filt13_discard,
        o_pkt_discard_x  => filt13_discard_y,
        o_pkt_discard_y  => filt13_discard_x,
        --Input channel 0 (RXFIFO 0)
        o_rxfifo_next0    => qsfp_rxf_next(1),
        i_rxfifo_empty0   => qsfp_rxf_empty(1),
        i_rxfifo_charisk0 => qsfp_rxf_charisk(1),
        i_rxfifo_data0    => qsfp_rxf_data(1),
        --Input channel 1 (RXFIFO 1)
        o_rxfifo_next1    => qsfp_rxf_next(3),
        i_rxfifo_empty1   => qsfp_rxf_empty(3),
        i_rxfifo_charisk1 => qsfp_rxf_charisk(3),
        i_rxfifo_data1    => qsfp_rxf_data(3),
        --v2.1: PING feature
        --Output SFP channel 0 (TXFIFO 0) PING TRANSMISSION
        i_txfifo_full0    => qsfp_txf_full(1),
        o_txfifo_write0   => qsfp_txf_write(1),
        o_txfifo_charisk0 => qsfp_txf_charisk(1),
        o_txfifo_data0    => qsfp_txf_data(1),
        --Output SFP channel 1 (TXFIFO 1) PING TRANSMISSION
        i_txfifo_full1    => qsfp_txf_full(3),
        o_txfifo_write1   => qsfp_txf_write(3),
        o_txfifo_charisk1 => qsfp_txf_charisk(3),
        o_txfifo_data1    => qsfp_txf_data(3),
        --Output channel
        --ML84 26.8.16, dual output
        i_output_next_x    => filt13_o_next_x,
        o_output_valid_x   => filt13_o_valid_x,
        o_output_charisk_x => filt13_o_charisk_x,
        o_output_data_x    => filt13_o_data_x,
        i_output_next_y    => filt13_o_next_y,
        o_output_valid_y   => filt13_o_valid_y,
        o_output_charisk_y => filt13_o_charisk_y,
        o_output_data_y    => filt13_o_data_y,
        --QDR2 interface
        o_qdr2_out         => filt13_qdr2_out,
        -- KW84, 08.08.2016, statistics
        o_statistics      => r_filter13_statistics
    );

    

    QSFP02_FILTER_I : ibfb_packet_filter
    generic map(
        --protocol
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        K_BAD => K_BAD 
    )
    port map(
        --debug
        o_flag_ram_wen   => open,
        o_flag_ram_waddr => open,
        o_flag_ram_wdata => open,
        o_csp_data       => filt02_csp_data,
        o_csp_clk        => filt02_csp_clk ,
        --setup
        i_bpm_id         => filt02_bpm_id,
        i_bkt_min        => filt02_bkt_min,
        i_bkt_max        => filt02_bkt_max,
        --v2.1: PING feature
        i_ping_enable0   => ping_en(0),
        i_ping_enable1   => ping_en(2),
        o_ping_rx0       => ping_rx(0),
        o_ping_rx1       => ping_rx(2),
        o_ping_latency0  => ping_lat(0),
        o_ping_latency1  => ping_lat(2),
        --
        i_ram_clk        => Bus2IP_Clk,
        i_ram_raddr      => mem_address(11+2 downto 2),
        o_ram_rdata      => filt02_ram_rdata,
        --
        i_clk            => core_clk, --Bus2IP_Clk,
        i_rst            => filt02_rst,
        i_trig           => filt02_trig,
        o_resetting      => filt02_resetting,
        o_pkt_valid      => filt02_valid,
        --o_pkt_discard    => filt02_discard,
        o_pkt_discard_x  => filt02_discard_x,
        o_pkt_discard_y  => filt02_discard_y,
        --Input channel 0 (RXFIFO 0)
        o_rxfifo_next0    => qsfp_rxf_next(0),
        i_rxfifo_empty0   => qsfp_rxf_empty(0),
        i_rxfifo_charisk0 => qsfp_rxf_charisk(0),
        i_rxfifo_data0    => qsfp_rxf_data(0),
        --Input channel 1 (RXFIFO 1)
        o_rxfifo_next1    => qsfp_rxf_next(2),
        i_rxfifo_empty1   => qsfp_rxf_empty(2),
        i_rxfifo_charisk1 => qsfp_rxf_charisk(2),
        i_rxfifo_data1    => qsfp_rxf_data(2),
        --v2.1: PING feature
        --Output SFP channel 0 (TXFIFO 0) PING TRANSMISSION
        i_txfifo_full0    => qsfp_txf_full(0),
        o_txfifo_write0   => qsfp_txf_write(0),
        o_txfifo_charisk0 => qsfp_txf_charisk(0),
        o_txfifo_data0    => qsfp_txf_data(0),
        --Output SFP channel 1 (TXFIFO 1) PING TRANSMISSION
        i_txfifo_full1    => qsfp_txf_full(2),
        o_txfifo_write1   => qsfp_txf_write(2),
        o_txfifo_charisk1 => qsfp_txf_charisk(2),
        o_txfifo_data1    => qsfp_txf_data(2),
        --Output channel
        i_output_next_x    => filt02_o_next_x,
        o_output_valid_x   => filt02_o_valid_x,
        o_output_charisk_x => filt02_o_charisk_x,
        o_output_data_x    => filt02_o_data_x,
        i_output_next_y    => filt02_o_next_y,
        o_output_valid_y   => filt02_o_valid_y,
        o_output_charisk_y => filt02_o_charisk_y,
        o_output_data_y    => filt02_o_data_y,
        --QDR2 interface
        o_qdr2_out         => filt02_qdr2_out,
        -- KW84, 08.08.2016, statistics
        o_statistics      => r_filter02_statistics
    );
    
--QRD2 output interface
o_qdr2_usr_clk     <= core_clk;
o_qdr2_usr_clk_rdy <= filt02_rst nor filt13_rst;
o_qdr2_usr_trg0    <= filt02_qdr2_out.qdr2_trg;
o_qdr2_usr_we0     <= filt02_qdr2_out.qdr2_we; 
o_qdr2_usr_data00  <= filt02_qdr2_out.qdr2_data0;
o_qdr2_usr_data01  <= filt02_qdr2_out.qdr2_data1;
o_qdr2_usr_data02  <= filt02_qdr2_out.qdr2_data2;
o_qdr2_usr_data03  <= filt02_qdr2_out.qdr2_data3;
o_qdr2_usr_trg1    <= filt13_qdr2_out.qdr2_trg;
o_qdr2_usr_we1     <= filt13_qdr2_out.qdr2_we; 
o_qdr2_usr_data10  <= filt13_qdr2_out.qdr2_data0;
o_qdr2_usr_data11  <= filt13_qdr2_out.qdr2_data1;
o_qdr2_usr_data12  <= filt13_qdr2_out.qdr2_data2;
o_qdr2_usr_data13  <= filt13_qdr2_out.qdr2_data3;

---------------------------------------------------------------------------
-- PACKET ROUTER
---------------------------------------------------------------------------

    --ML84 26.8.16, two routers

    --Connect filter02 X-output to X-router input 0 
    filt02_o_next_x      <= xrouter_i_next(0);
    xrouter_i_valid(0)   <= filt02_o_valid_x;
    xrouter_i_charisk(0) <= filt02_o_charisk_x;
    xrouter_i_data(0)    <= filt02_o_data_x;
    --Connect filter02 Y-output to Y-router input 0
    filt02_o_next_y      <= yrouter_i_next(0);
    yrouter_i_valid(0)   <= filt02_o_valid_y;
    yrouter_i_charisk(0) <= filt02_o_charisk_y;
    yrouter_i_data(0)    <= filt02_o_data_y;

    --Connect filter13 X-output to X-router input 1 
    filt13_o_next_x      <= xrouter_i_next(1);
    xrouter_i_valid(1)   <= filt13_o_valid_x;
    xrouter_i_charisk(1) <= filt13_o_charisk_x;
    xrouter_i_data(1)    <= filt13_o_data_x;
    --Connect filter13 Y-output to Y-router input 1
    filt13_o_next_y      <= yrouter_i_next(1);
    yrouter_i_valid(1)   <= filt13_o_valid_y;
    yrouter_i_charisk(1) <= filt13_o_charisk_y;
    yrouter_i_data(1)    <= filt13_o_data_y;

    --XRouter's input 2 connected to BPM0 RX
    bpm_rxf_next(0)      <= xrouter_i_next(2);
    xrouter_i_valid(2)   <= not bpm_rxf_empty(0);
    xrouter_i_charisk(2) <= bpm_rxf_charisk(0);
    xrouter_i_data(2)    <= bpm_rxf_data(0);
    --YRouter's input 2 connected to BPM1 RX
    bpm_rxf_next(1)      <= yrouter_i_next(2);
    yrouter_i_valid(2)   <= not bpm_rxf_empty(1);
    yrouter_i_charisk(2) <= bpm_rxf_charisk(1);
    yrouter_i_data(2)    <= bpm_rxf_data(1);

router_rst <= Bus2IP_Reset_r or router_rst_c; --same for both routers

--changed in v2.00
--Two routers (X+Y). 
--Each 3 inputs (filter02, filter13, side BPM FPGA) and 2 outputs (backplane, side BPM FPGA)
--Routing table can be set in real time.
--Outputs can be enabled via SW.

xrouter_table(0)(0) <= xrouter_f02_to_back;
xrouter_table(0)(1) <= xrouter_f02_to_side;
xrouter_table(1)(0) <= xrouter_f13_to_back;
xrouter_table(1)(1) <= xrouter_f13_to_side;
xrouter_table(2)(0) <= xrouter_side_to_back;
xrouter_table(2)(1) <= xrouter_side_to_side;

PACKET_ROUTER_X : ibfb_packet_router
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP,
    N_INPUT_PORTS  => 3, --was 5 (changed in v2.00)
    N_OUTPUT_PORTS => 2
)
port map(
    i_clk     => core_clk,
    i_rst     => router_rst,
    i_err_rst => router_err_rst,
    i_out_en  => "11",
    i_routing_table => xrouter_table,
    --input (FIFO, FWFT)
    o_next    => xrouter_i_next,
    i_valid   => xrouter_i_valid,
    i_charisk => xrouter_i_charisk,
    i_data    => xrouter_i_data,
    --output (STREAMING. i_next is used only to detect errors, but does not control data flow)
    i_next    => xrouter_o_next,
    o_valid   => xrouter_o_valid,
    o_err     => xrouter_o_err,
    o_charisk => xrouter_o_charisk,
    o_data    => xrouter_o_data
);

yrouter_table(0)(0) <= yrouter_f02_to_back;
yrouter_table(0)(1) <= yrouter_f02_to_side;
yrouter_table(1)(0) <= yrouter_f13_to_back;
yrouter_table(1)(1) <= yrouter_f13_to_side;
yrouter_table(2)(0) <= yrouter_side_to_back;
yrouter_table(2)(1) <= yrouter_side_to_side;

PACKET_ROUTER_Y : ibfb_packet_router
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP,
    N_INPUT_PORTS  => 3, --was 5 (changed in v2.00)
    N_OUTPUT_PORTS => 2
)
port map(
    i_clk     => core_clk,
    i_rst     => router_rst,
    i_err_rst => router_err_rst,
    i_out_en  => "11",
    i_routing_table => yrouter_table,
    --input (FIFO, FWFT)
    o_next    => yrouter_i_next,
    i_valid   => yrouter_i_valid,
    i_charisk => yrouter_i_charisk,
    i_data    => yrouter_i_data,
    --output (STREAMING. i_next is used only to detect errors, but does not control data flow)
    i_next    => yrouter_o_next,
    o_valid   => yrouter_o_valid,
    o_err     => yrouter_o_err,
    o_charisk => yrouter_o_charisk,
    o_data    => yrouter_o_data
);


    --Router's outputs connected to P0 (2channels)
    --router_o_next(0)  <= not p0_txf_full(0);
    --p0_txf_write(0)   <= router_o_valid(0);
    --p0_txf_charisk(0) <= router_o_charisk(0);
    --p0_txf_data(0)    <= router_o_data(0);
    --router_o_next(1)  <= not p0_txf_full(1);
    --p0_txf_write(1)   <= router_o_valid(1);
    --p0_txf_charisk(1) <= router_o_charisk(1);
    --p0_txf_data(1)    <= router_o_data(1);
    --Xrouter's output 2 to BPM0 TX (added in v2.00)
    --router_o_next(2)   <= not bpm_txf_full(0);
    --bpm_txf_write(0)   <= router_o_valid(2);
    --bpm_txf_charisk(0) <= router_o_charisk(2);
    --bpm_txf_data(0)    <= router_o_data(2);

    --ML84 26.8.16, dual router
    --XRouter's output0 connected to P0.0
    xrouter_o_next(0)  <= not p0_txf_full(0);
    p0_txf_write(0)   <= xrouter_o_valid(0);
    p0_txf_charisk(0) <= xrouter_o_charisk(0);
    p0_txf_data(0)    <= xrouter_o_data(0);
    --YRouter's output0 connected to P0.1
    yrouter_o_next(0)  <= not p0_txf_full(1);
    p0_txf_write(1)   <= yrouter_o_valid(0);
    p0_txf_charisk(1) <= yrouter_o_charisk(0);
    p0_txf_data(1)    <= yrouter_o_data(0);

    --Xrouter's output 1 to BPM0 TX
    xrouter_o_next(1)  <= not bpm_txf_full(0);
    bpm_txf_write(0)   <= xrouter_o_valid(1);
    bpm_txf_charisk(0) <= xrouter_o_charisk(1);
    bpm_txf_data(0)    <= xrouter_o_data(1);
    --Yrouter's output 1 to BPM1 TX
    yrouter_o_next(1)  <= not bpm_txf_full(1);
    bpm_txf_write(1)   <= yrouter_o_valid(1);
    bpm_txf_charisk(1) <= yrouter_o_charisk(1);
    bpm_txf_data(1)    <= yrouter_o_data(1);

--BP channels 2,3 not used
bpm_rxf_next(2 to 3)  <= "11";
bpm_txf_write(2 to 3) <= "00";

end architecture behavioral;

------------------------------------------------------------------------------
-- End of file
------------------------------------------------------------------------------
