------------------------------------------------------------------------------
--                       Paul Scherrer Institute (PSI)
------------------------------------------------------------------------------
-- Unit    : user_logic.vhd
-- Author  : Alessandro Malatesta, Section Diagnostic
-- Version : $Revision: 1.1 $
------------------------------------------------------------------------------
-- Copyright© PSI, Section Diagnostic
------------------------------------------------------------------------------
-- Comment : IBFB Packet Switch
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library ibfb_common_v1_00_a;
--use ibfb_switch_v1_00_a.virtex5_gtx_package.all;
--use ibfb_switch_v1_00_a.ibfb_comm_package.all;
use ibfb_common_v1_00_a.ibfb_comm_package.all;

entity user_logic is
generic (
    --Interconnection topology 
    SFP02_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 02
    SFP13_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 13
    OUTPUT_TO_P0     : std_logic := '1'; --when 1, packets are output on backplane P0 connector. 
                                         --Otherwise on BPM0 channel
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
    C_SLV_DWIDTH     : integer := 32;
    C_NUM_REG        : integer := 32
);
port (
    --RX channels
    qsfp_rxf_next    : out std_logic_vector(0 to 3) := X"0";
    qsfp_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    qsfp_rxf_charisk : in array4(0 to 3);
    qsfp_rxf_data    : in array32(0 to 3);
  --
    bpm_rxf_next    : out std_logic_vector(0 to 3) := X"0";
    bpm_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    bpm_rxf_charisk : in  array4(0 to 3);
    bpm_rxf_data    : in  array32(0 to 3);
  --TX channels
    p0_txf_full    : in  std_logic_vector(0 to 1) := "00";
    p0_txf_write   : out std_logic_vector(0 to 1) := "00";
    p0_txf_charisk : out array4(0 to 1) := (others => (others => '0'));
    p0_txf_data    : out array32(0 to 1) := (others => (others => '0'));
  --
    bpm_txf_full    : in  std_logic_vector(0 to 3) := X"0";
    bpm_txf_write   : out std_logic_vector(0 to 3) := X"0";
    bpm_txf_charisk : out array4(0 to 3) := (others => (others => '0'));
    bpm_txf_data    : out array32(0 to 3) := (others => (others => '0'));
    --
    dbg_fifo_empty   : out std_logic;
    dbg_fifo_charisk : out std_logic_vector(3 downto 0);
    dbg_fifo_data    : out std_logic_vector(31 downto 0);
    ------------------------------------------------------------------------
    -- GTX INTERFACE
    ------------------------------------------------------------------------
--    I_GTX_REFCLK1_IN            : in  std_logic;
--    I_GTX_REFCLK2_IN            : in  std_logic;
--    O_GTX_REFCLK_OUT            : out std_logic;
--    I_GTX_RX_N                  : in  std_logic_vector(2*5-1 downto 0);
--    I_GTX_RX_P                  : in  std_logic_vector(2*5-1 downto 0);
--    O_GTX_TX_N                  : out std_logic_vector(2*5-1 downto 0);
--    O_GTX_TX_P                  : out std_logic_vector(2*5-1 downto 0);
--    O_CSP_CLK                   : out std_logic;
--    O_CSP_DATA                  : out std_logic_vector(63 downto 0); 
    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_filt13_trig : in std_logic; --filter connected to channels 1 and 3
    i_filt02_trig : in std_logic; --filter connected to channels 0 and 2
    ------------------------------------------------------------------------
    -- Bus ports
    ------------------------------------------------------------------------
    user_clk                    : in    std_logic;
    Bus2IP_Clk                  : in    std_logic;
    Bus2IP_Reset                : in    std_logic;
    Bus2IP_RdCE                 : in    std_logic
--    Bus2IP_Data                 : in    std_logic_vector(0 to C_SLV_DWIDTH - 1);
--    Bus2IP_BE                   : in    std_logic_vector(0 to C_SLV_DWIDTH / 8 - 1);
--    Bus2IP_RdCE                 : in    std_logic_vector(0 to C_NUM_REG - 1);
--    Bus2IP_WrCE                 : in    std_logic_vector(0 to C_NUM_REG - 1);
--    IP2Bus_Data                 : out   std_logic_vector(0 to C_SLV_DWIDTH - 1);
--    IP2Bus_RdAck                : out   std_logic;
--    IP2Bus_WrAck                : out   std_logic;
--    IP2Bus_Error                : out   std_logic
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

  -- Types ------------------------------------------------------------------
--  type     slv_reg_type is array (0 to C_NUM_REG-1) of std_logic_vector(C_SLV_DWIDTH - 1 downto 0);

  -- Constants --------------------------------------------------------------
--  constant LOW_REG : std_logic_vector(C_SLV_DWIDTH - 1 downto  0) := (others => '0');
  constant K_BAD   : std_logic_vector(7 downto 0)                 := X"5C";

  -- Signals ----------------------------------------------------------------
--  signal   slv_reg_rd            : slv_reg_type;
--  signal   slv_reg_wr            : slv_reg_type;
 
  --Per-GTX-Tile signals
--  signal qsfp13_mgt_o : mgt_out_type;
--  signal qsfp02_mgt_o : mgt_out_type;
--  signal p0_mgt_o     : mgt_out_type;
--  signal bpm01_mgt_o  : mgt_out_type;
--  signal bpm23_mgt_o  : mgt_out_type;
  signal qsfp_fifo_rst_c : std_logic_vector(0 to 3);
  signal bpm_fifo_rst_c  : std_logic_vector(0 to 3);
  signal p0_fifo_rst_c   : std_logic_vector(0 to 1);

  --Per-GTX-channel signals
--  signal qsfp_loopback    : array3(0 to 3);
--  signal qsfp_fifo_rst    : std_logic_vector(0 to 3);
--  signal bpm_loopback    : array3(0 to 3);
--  signal bpm_fifo_rst    : std_logic_vector(0 to 3);
--  signal p0_loopback    : array3(0 to 1);
--  signal p0_fifo_rst    : std_logic_vector(0 to 1);
  --RX channels
--  signal qsfp_rxf_vld     : std_logic_vector(0 to 3);
--  signal qsfp_rxf_next    : std_logic_vector(0 to 3);
--  signal qsfp_rxf_empty   : std_logic_vector(0 to 3);
--  signal qsfp_rxf_charisk : array4(0 to 3);
--  signal qsfp_rxf_data    : array32(0 to 3);
  --
--  signal bpm_rxf_vld     : std_logic_vector(0 to 3);
--  signal bpm_rxf_next    : std_logic_vector(0 to 3);
--  signal bpm_rxf_empty   : std_logic_vector(0 to 3);
--  signal bpm_rxf_charisk : array4(0 to 3);
--  signal bpm_rxf_data    : array32(0 to 3);
  --TX channels
--  signal p0_txf_vld     : std_logic_vector(0 to 1);
--  signal p0_txf_full    : std_logic_vector(0 to 1);
--  signal p0_txf_write   : std_logic_vector(0 to 1);
--  signal p0_txf_charisk : array4(0 to 1);
--  signal p0_txf_data    : array32(0 to 1);
  --
--  signal bpm_txf_vld     : std_logic_vector(0 to 3);
--  signal bpm_txf_full    : std_logic_vector(0 to 3);
--  signal bpm_txf_write   : std_logic_vector(0 to 3);
--  signal bpm_txf_charisk : array4(0 to 3);
--  signal bpm_txf_data    : array32(0 to 3);

  --FILTERS
  signal filt13_bpm_id    : bpm_id_t; --allowed BPM ids 
  signal filt13_rst       : std_logic;
  signal filt13_trig      : std_logic;
  signal filt13_resetting : std_logic;
  signal filt13_valid     : std_logic;
  signal filt13_discard   : std_logic;
  signal filt13_o_next    : std_logic;
  signal filt13_o_valid   : std_logic;
  signal filt13_o_charisk : std_logic_vector(3 downto 0);
  signal filt13_o_data    : std_logic_vector(31 downto 0);

  signal filt02_bpm_id    : bpm_id_t; --allowed BPM ids 
  signal filt02_rst       : std_logic;
  signal filt02_trig      : std_logic;
  signal filt02_resetting : std_logic;
  signal filt02_valid     : std_logic;
  signal filt02_discard   : std_logic;
  signal filt02_o_next    : std_logic;
  signal filt02_o_valid   : std_logic;
  signal filt02_o_charisk : std_logic_vector(3 downto 0);
  signal filt02_o_data    : std_logic_vector(31 downto 0);

  --PACKET ROUTER
  signal router_rst       : std_logic;
  signal router_err_rst   : std_logic;
  signal router_i_next    : std_logic_vector(0 to 4);
  signal router_i_valid   : std_logic_vector(0 to 4);
  signal router_i_charisk : array4(0 to 4);
  signal router_i_data    : array32(0 to 4);
  signal router_o_next    : std_logic_vector(0 to 1);
  signal router_o_valid   : std_logic_vector(0 to 1);
  signal router_o_err     : std_logic_vector(0 to 1);
  signal router_o_charisk : array4(0 to 1);
  signal router_o_data    : array32(0 to 1);

  signal filt13_rst_c, filt13_reg_c : std_logic;
  signal filt02_rst_c, filt02_reg_c : std_logic;
  signal filt13_trig_c : std_logic;
  signal filt02_trig_c : std_logic;
  signal router_rst_c : std_logic;

  --DEBUG FIFO
  signal dbg_fifo_en, dbg_fifo_rst, dbg_fifo_rst_c : std_logic;
  signal dbg_fifo_full, dbg_fifo_write, dbg_fifo_read, dbg_fifo_read_re : std_logic;
  --signal dbg_fifo_empty, dbg_fifo_read : std_logic;
  --signal dbg_fifo_charisk : std_logic_vector(3 downto 0);
  --signal dbg_fifo_data    : std_logic_vector(31 downto 0);

begin
---------------------------------------------------------------------------
-- Status
---------------------------------------------------------------------------
--IP2Bus_WrAck <= '1' when (Bus2IP_WrCE /= LOW_REG) else '0';
--IP2Bus_RdAck <= '1' when (Bus2IP_RdCE /= LOW_REG) else '0';
--IP2Bus_Error <= '0';

---------------------------------------------------------------------------
-- Read register
---------------------------------------------------------------------------
--slv_reg_rd_proc: process(Bus2IP_RdCE, slv_reg_rd) is
--begin
--    IP2Bus_Data                 <= (others => '0');
--    for register_index in 0 to C_NUM_REG - 1 loop
--        if (Bus2IP_RdCE(register_index) = '1') then
--            --IP2Bus_Data           <= slv_reg_rd(register_index);
--            IP2Bus_Data( 0 to  7)           <= slv_reg_rd(register_index)(31 downto 24);
--            IP2Bus_Data( 8 to 15)           <= slv_reg_rd(register_index)(23 downto 16);
--            IP2Bus_Data(16 to 23)           <= slv_reg_rd(register_index)(15 downto  8);
--            IP2Bus_Data(24 to 31)           <= slv_reg_rd(register_index)( 7 downto  0);
--        end if;
--    end loop;
--end process slv_reg_rd_proc;

---------------------------------------------------------------------------
-- Write register
---------------------------------------------------------------------------
--slv_reg_wr_proc: process(Bus2IP_Clk) is
--begin
--    if rising_edge(Bus2IP_Clk) then
--        slv_reg_wr_gen: for register_index in 0 to C_NUM_REG - 1 loop
--        if (Bus2IP_WrCE(register_index) = '1') then
--            for byte_index in 0 to (C_SLV_DWIDTH / 8) - 1 loop
--                if (Bus2IP_BE(0) = '1') then
--                    slv_reg_wr(register_index)(31 downto 24) <= Bus2IP_Data( 0 to  7);
--                end if;
--                if (Bus2IP_BE(1) = '1') then
--                    slv_reg_wr(register_index)(23 downto 16) <= Bus2IP_Data( 8 to 15);
--                end if;
--                if (Bus2IP_BE(2) = '1') then
--                    slv_reg_wr(register_index)(15 downto  8) <= Bus2IP_Data(16 to 23);
--                end if;
--                if (Bus2IP_BE(3) = '1') then
--                    slv_reg_wr(register_index)( 7 downto  0) <= Bus2IP_Data(24 to 31);
--                end if;
--            end loop;             
--        end if;
--        end loop;
--    end if;
--end process slv_reg_wr_proc;

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
--O_CSP_CLK   <= user_clk; --Bus2IP_Clk;

--O_CSP_DATA <= X"0000000000000000"; 
--qsfp_rxf_vld(0 to 3)
-- bpm_rxf_vld(0 to 3)
-- bpm_txf_vld(0 to 3)
--  p0_txf_vld(0 to 1)
--filt13_resetting
--filt13_valid
--filt13_discard
--filt02_resetting
--filt02_valid
--filt02_discard

---------------------------------------------------------------------------
-- PLB connections
---------------------------------------------------------------------------

-- COMMANDS ---------------------------------------------------------------
--0x00 RESET  filt02_rst, filt13_rst, p0(2), bpm(4), qsfp(4)
--0x04 LOOPBACK QSFP
--0x08 LOOPBACK BPM
--0x0C LOOPBACK P0
--
qsfp_fifo_rst_c   <= (others => '0');
bpm_fifo_rst_c    <= (others => '0');
p0_fifo_rst_c     <= (others => '0');
filt13_rst_c      <= '0';
filt02_rst_c      <= '0';
router_rst_c      <= '0';
router_err_rst    <= '0';
--                <= slv_reg_wr(0)(15 downto 14);
filt13_trig_c     <= '0';
filt02_trig_c     <= '0';
dbg_fifo_en       <= '1';
dbg_fifo_rst_c    <= '0';
--
--qsfp_loopback(0)  <= slv_reg_wr(1)(02 downto 00); 
--qsfp_loopback(1)  <= slv_reg_wr(1)(06 downto 04); 
--qsfp_loopback(2)  <= slv_reg_wr(1)(10 downto 08); 
--qsfp_loopback(3)  <= slv_reg_wr(1)(14 downto 12); 
--
--bpm_loopback(0)   <= slv_reg_wr(1)(18 downto 16); 
--bpm_loopback(1)   <= slv_reg_wr(1)(22 downto 20); 
--bpm_loopback(2)   <= slv_reg_wr(1)(26 downto 24); 
--bpm_loopback(3)   <= slv_reg_wr(1)(30 downto 28); 
--
--p0_loopback(0)    <= slv_reg_wr(2)(02 downto 00); 
--p0_loopback(1)    <= slv_reg_wr(2)(06 downto 04); 

filt13_bpm_id(0)  <= X"01";
filt13_bpm_id(1)  <= X"02";
filt13_bpm_id(2)  <= X"03";
filt13_bpm_id(3)  <= X"04";
filt02_bpm_id(0)  <= X"01";
filt02_bpm_id(1)  <= X"02";
filt02_bpm_id(2)  <= X"03";
filt02_bpm_id(3)  <= X"04";
-- STATUS -----------------------------------------------------------------
--slv_reg_rd( 0)               <= slv_reg_wr(0);
--slv_reg_rd( 1)               <= slv_reg_wr(1);
--slv_reg_rd( 2)               <= slv_reg_wr(2);
--
--slv_reg_rd( 3)( 0)           <= qsfp13_mgt_o.ctrl.PLLLKDET;
--slv_reg_rd( 3)( 1)           <= qsfp13_mgt_o.ctrl.RESETDONE0;
--slv_reg_rd( 3)( 2)           <= qsfp13_mgt_o.ctrl.RESETDONE1;
--slv_reg_rd( 3)( 3)           <= '0';
--slv_reg_rd( 3)( 5 downto  4) <= qsfp13_mgt_o.rx(0).RXLOSSOFSYNC;
--slv_reg_rd( 3)( 7 downto  6) <= qsfp13_mgt_o.rx(1).RXLOSSOFSYNC;
--
--slv_reg_rd( 3)( 8)           <= qsfp02_mgt_o.ctrl.PLLLKDET;
--slv_reg_rd( 3)( 9)           <= qsfp02_mgt_o.ctrl.RESETDONE0;
--slv_reg_rd( 3)(10)           <= qsfp02_mgt_o.ctrl.RESETDONE1;
--slv_reg_rd( 3)(11)           <= '0';
--slv_reg_rd( 3)(13 downto 12) <= qsfp02_mgt_o.rx(0).RXLOSSOFSYNC;
--slv_reg_rd( 3)(15 downto 14) <= qsfp02_mgt_o.rx(1).RXLOSSOFSYNC;
--
--slv_reg_rd( 3)(16)           <= bpm01_mgt_o.ctrl.PLLLKDET;
--slv_reg_rd( 3)(17)           <= bpm01_mgt_o.ctrl.RESETDONE0;
--slv_reg_rd( 3)(18)           <= bpm01_mgt_o.ctrl.RESETDONE1;
--slv_reg_rd( 3)(19)           <= '0';
--slv_reg_rd( 3)(21 downto 20) <= bpm01_mgt_o.rx(0).RXLOSSOFSYNC;
--slv_reg_rd( 3)(23 downto 22) <= bpm01_mgt_o.rx(1).RXLOSSOFSYNC;
--
--slv_reg_rd( 3)(24)           <= bpm23_mgt_o.ctrl.PLLLKDET;
--slv_reg_rd( 3)(25)           <= bpm23_mgt_o.ctrl.RESETDONE0;
--slv_reg_rd( 3)(26)           <= bpm23_mgt_o.ctrl.RESETDONE1;
--slv_reg_rd( 3)(27)           <= '0';
--slv_reg_rd( 3)(29 downto 28) <= bpm23_mgt_o.rx(0).RXLOSSOFSYNC;
--slv_reg_rd( 3)(31 downto 30) <= bpm23_mgt_o.rx(1).RXLOSSOFSYNC;
--
--slv_reg_rd( 4)( 0)           <= p0_mgt_o.ctrl.PLLLKDET;
--slv_reg_rd( 4)( 1)           <= p0_mgt_o.ctrl.RESETDONE0;
--slv_reg_rd( 4)( 2)           <= p0_mgt_o.ctrl.RESETDONE1;
--slv_reg_rd( 4)( 3)           <= '0';
--slv_reg_rd( 4)( 5 downto  4) <= p0_mgt_o.rx(0).RXLOSSOFSYNC;
--slv_reg_rd( 4)( 7 downto  6) <= p0_mgt_o.rx(1).RXLOSSOFSYNC;
--
--slv_reg_rd( 4)( 9 downto  8) <= router_o_err;
--slv_reg_rd( 4)(31 downto 10) <= X"00000"&"00";
--
--slv_reg_rd( 5)( 0)           <= dbg_fifo_empty;
--slv_reg_rd( 5)( 1)           <= dbg_fifo_full;
--slv_reg_rd( 5)( 3 downto 2)   <= "00";
--slv_reg_rd( 5)( 7 downto 4)  <= dbg_fifo_charisk;
--slv_reg_rd( 5)(31 downto 8)   <= X"000000";
--slv_reg_rd( 6)               <= dbg_fifo_data;
--
--slv_reg_rd( 7)               <= slv_reg_wr(7);
--slv_reg_rd( 8)               <= slv_reg_wr(8);
---------------------------------------------------------------------------
-- GTX components
---------------------------------------------------------------------------
--qsfp_fifo_rst(0) <= Bus2IP_Reset or qsfp_fifo_rst_c(0);
--qsfp_fifo_rst(1) <= Bus2IP_Reset or qsfp_fifo_rst_c(1);
--qsfp_fifo_rst(2) <= Bus2IP_Reset or qsfp_fifo_rst_c(2);
--qsfp_fifo_rst(3) <= Bus2IP_Reset or qsfp_fifo_rst_c(3);
-- bpm_fifo_rst(0) <= Bus2IP_Reset or  bpm_fifo_rst_c(0);
-- bpm_fifo_rst(1) <= Bus2IP_Reset or  bpm_fifo_rst_c(1);
-- bpm_fifo_rst(2) <= Bus2IP_Reset or  bpm_fifo_rst_c(2);
-- bpm_fifo_rst(3) <= Bus2IP_Reset or  bpm_fifo_rst_c(3);
--  p0_fifo_rst(0) <= Bus2IP_Reset or   p0_fifo_rst_c(0);
--  p0_fifo_rst(1) <= Bus2IP_Reset or   p0_fifo_rst_c(1);

--QSFP13_TILE : gtx_tile
--generic map(
--    --mgt
--    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(0),
--    G_GTX_TILE_REFCLK_FREQ => C_SFP13_REFCLK_FREQ,
--    G_GTX_BAUD_RATE        => C_SFP13_BAUD_RATE
--)
--port map(
--    --DEBUG
--    o_DBG_x0 => open,
--    o_DBG_v0 => open,
--    o_DBG_k0 => open,
--    o_DBG_d0 => open,
--    o_DBG_x1 => open,
--    o_DBG_v1 => open,
--    o_DBG_k1 => open,
--    o_DBG_d1 => open,
--    ------------------------------------------------------------------------
--    -- GTX INTERFACE
--    ------------------------------------------------------------------------
--    I_GTX_REFCLK1_IN            => I_GTX_REFCLK1_IN,
--    I_GTX_REFCLK2_IN            => I_GTX_REFCLK2_IN,
--    I_GTX_RX_N                  => I_GTX_RX_N(1 downto 0),
--    I_GTX_RX_P                  => I_GTX_RX_P(1 downto 0),
--    O_GTX_TX_N                  => O_GTX_TX_N(1 downto 0),
--    O_GTX_TX_P                  => O_GTX_TX_P(1 downto 0),
--    ------------------------------------------------------------------------
--    -- GTX SETTINGS & STATUS
--    ------------------------------------------------------------------------
--    i_loopback0      => qsfp_loopback(3),
--    i_loopback1      => qsfp_loopback(1),
--    o_mgt            => qsfp13_mgt_o,
--    ------------------------------------------------------------------------
--    -- FIFO interface
--    ------------------------------------------------------------------------
--    i_clk => user_clk, --Bus2IP_Clk,
--    --Channel 3
--    i_fifo_reset0 => qsfp_fifo_rst(3), 
--    --TX
--    o_tx_vld0         => open,
--    o_txfifo_full0    => open,
--    i_txfifo_write0   => '0',
--    i_txfifo_charisk0 => X"0",
--    i_txfifo_data0    => X"00000000",
--    --RX
--    o_rx_vld0         => qsfp_rxf_vld(3), --debug
--    i_rxfifo_next0    => qsfp_rxf_next(3),
--    o_rxfifo_empty0   => qsfp_rxf_empty(3),
--    o_rxfifo_charisk0 => qsfp_rxf_charisk(3),
--    o_rxfifo_data0    => qsfp_rxf_data(3),
--    --Channel 1
--    i_fifo_reset1     => qsfp_fifo_rst(1),
--    --TX
--    o_tx_vld1         => open,
--    o_txfifo_full1    => open,
--    i_txfifo_write1   => '0',
--    i_txfifo_charisk1 => X"0",
--    i_txfifo_data1    => X"00000000",
--    --RX
--    o_rx_vld1         => qsfp_rxf_vld(1), --debug
--    i_rxfifo_next1    => qsfp_rxf_next(1),
--    o_rxfifo_empty1   => qsfp_rxf_empty(1),
--    o_rxfifo_charisk1 => qsfp_rxf_charisk(1),
--    o_rxfifo_data1    => qsfp_rxf_data(1) 
--);
--
--
--QSFP02_TILE : gtx_tile
--generic map(
--    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(1),
--    G_GTX_TILE_REFCLK_FREQ => C_SFP02_REFCLK_FREQ,
--    G_GTX_BAUD_RATE        => C_SFP02_BAUD_RATE
--)
--port map(
--    --DEBUG
--    o_DBG_x0 => open,
--    o_DBG_v0 => open,
--    o_DBG_k0 => open,
--    o_DBG_d0 => open,
--    o_DBG_x1 => open,
--    o_DBG_v1 => open,
--    o_DBG_k1 => open,
--    o_DBG_d1 => open,
--    ------------------------------------------------------------------------
--    -- GTX INTERFACE
--    ------------------------------------------------------------------------
--    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
--    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
--    O_GTX_REFCLK_OUT => open,
--    I_GTX_RX_N       => I_GTX_RX_N(3 downto 2),
--    I_GTX_RX_P       => I_GTX_RX_P(3 downto 2),
--    O_GTX_TX_N       => O_GTX_TX_N(3 downto 2),
--    O_GTX_TX_P       => O_GTX_TX_P(3 downto 2),
--    ------------------------------------------------------------------------
--    -- GTX SETTINGS & STATUS
--    ------------------------------------------------------------------------
--    i_loopback0 => qsfp_loopback(2),
--    i_loopback1 => qsfp_loopback(0),
--    o_mgt       => qsfp02_mgt_o,
--    ------------------------------------------------------------------------
--    -- FIFO interface
--    ------------------------------------------------------------------------
--    i_clk             => user_clk, --Bus2IP_Clk,
--    --Channel 2
--    i_fifo_reset0     => qsfp_fifo_rst(2),
--    --TX
--    o_tx_vld0         => open,
--    o_txfifo_full0    => open,
--    i_txfifo_write0   => '0',
--    i_txfifo_charisk0 => X"0",
--    i_txfifo_data0    => X"00000000",
--    --RX
--    o_rx_vld0         => qsfp_rxf_vld(2), --debug
--    i_rxfifo_next0    => qsfp_rxf_next(2),
--    o_rxfifo_empty0   => qsfp_rxf_empty(2),
--    o_rxfifo_charisk0 => qsfp_rxf_charisk(2),
--    o_rxfifo_data0    => qsfp_rxf_data(2),
--    --Channel 0
--    i_fifo_reset1     => qsfp_fifo_rst(0),
--    --TX
--    o_tx_vld1         => open,
--    o_txfifo_full1    => open,
--    i_txfifo_write1   => '0',
--    i_txfifo_charisk1 => X"0",
--    i_txfifo_data1    => X"00000000",
--    --RX
--    o_rx_vld1         => qsfp_rxf_vld(0), --debug
--    i_rxfifo_next1    => qsfp_rxf_next(0),
--    o_rxfifo_empty1   => qsfp_rxf_empty(0),
--    o_rxfifo_charisk1 => qsfp_rxf_charisk(0),
--    o_rxfifo_data1    => qsfp_rxf_data(0)
--);
--
--P0_TILE : gtx_tile
--generic map(
--    --mgt
--    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(2),
--    G_GTX_TILE_REFCLK_FREQ => C_P0_REFCLK_FREQ,
--    G_GTX_BAUD_RATE        => C_P0_BAUD_RATE
--)
--port map(
--    --DEBUG
--    o_DBG_x0 => open,
--    o_DBG_v0 => open,
--    o_DBG_k0 => open,
--    o_DBG_d0 => open,
--    o_DBG_x1 => open,
--    o_DBG_v1 => open,
--    o_DBG_k1 => open,
--    o_DBG_d1 => open,
--    --MGT
--    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
--    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
--    I_GTX_RX_N       => I_GTX_RX_N(5 downto 4),
--    I_GTX_RX_P       => I_GTX_RX_P(5 downto 4),
--    O_GTX_TX_N       => O_GTX_TX_N(5 downto 4),
--    O_GTX_TX_P       => O_GTX_TX_P(5 downto 4),
--    --
--    i_loopback0      => p0_loopback(0),
--    i_loopback1      => p0_loopback(1),
--    o_mgt            => p0_mgt_o,
--    ------------------------------------------------------------------------
--    -- FIFO interface
--    ------------------------------------------------------------------------
--    i_clk             => user_clk, --Bus2IP_Clk,
--    --Channel 0
--    i_fifo_reset0     => p0_fifo_rst(2),
--    --TX
--    o_tx_vld0         => p0_txf_vld(0), --debug
--    o_txfifo_full0    => p0_txf_full(0),
--    i_txfifo_write0   => p0_txf_write(0),
--    i_txfifo_charisk0 => p0_txf_charisk(0),
--    i_txfifo_data0    => p0_txf_data(0),
--    --RX
--    o_rx_vld0         => open,
--    i_rxfifo_next0    => '0',
--    o_rxfifo_empty0   => open,
--    o_rxfifo_charisk0 => open,
--    o_rxfifo_data0    => open,
--    --Channel 1
--    i_fifo_reset1     => p0_fifo_rst(0),
--    --TX
--    o_tx_vld1         => p0_txf_vld(1), --debug
--    o_txfifo_full1    => p0_txf_full(1),
--    i_txfifo_write1   => p0_txf_write(1),
--    i_txfifo_charisk1 => p0_txf_charisk(1),
--    i_txfifo_data1    => p0_txf_data(1),
--    --RX
--    o_rx_vld1         => open,
--    i_rxfifo_next1    => '0',
--    o_rxfifo_empty1   => open,
--    o_rxfifo_charisk1 => open,
--    o_rxfifo_data1    => open,
--);
--
--BPM01_TILE : gtx_tile
--generic map(
--    --mgt
--    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(3),
--    G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
--    G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
--)
--port map(
--    --DEBUG
--    o_DBG_x0 => open,
--    o_DBG_v0 => open,
--    o_DBG_k0 => open,
--    o_DBG_d0 => open,
--    o_DBG_x1 => open,
--    o_DBG_v1 => open,
--    o_DBG_k1 => open,
--    o_DBG_d1 => open,
--    --MGT
--    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
--    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
--    I_GTX_RX_N       => I_GTX_RX_N(7 downto 6),
--    I_GTX_RX_P       => I_GTX_RX_P(7 downto 6),
--    O_GTX_TX_N       => O_GTX_TX_N(7 downto 6),
--    O_GTX_TX_P       => O_GTX_TX_P(7 downto 6),
--    --
--    i_loopback0      => bpm_loopback(0),
--    i_loopback1      => bpm_loopback(1),
--    o_mgt            => bpm01_mgt_o,
--    ------------------------------------------------------------------------
--    -- FIFO interface
--    ------------------------------------------------------------------------
--    i_clk             => user_clk, --Bus2IP_Clk,
--    --Channel 0
--    i_fifo_reset0     => bpm_fifo_rst(0),
--    --TX
--    o_tx_vld0         => bpm_txf_vld(0), --debug
--    o_txfifo_full0    => bpm_txf_full(0),
--    i_txfifo_write0   => bpm_txf_write(0),
--    i_txfifo_charisk0 => bpm_txf_charisk(0),
--    i_txfifo_data0    => bpm_txf_data(0),
--    --RX
--    o_rx_vld0         => bpm_rxf_vld(0), --debug
--    i_rxfifo_next0    => bpm_rxf_next(0),
--    o_rxfifo_empty0   => bpm_rxf_empty(0),
--    o_rxfifo_charisk0 => bpm_rxf_charisk(0),
--    o_rxfifo_data0    => bpm_rxf_data(0),
--    --Channel 1
--    i_fifo_reset1     => bpm_fifo_rst(1),
--    --TX
--    o_tx_vld1         => bpm_txf_vld(1), --debug
--    o_txfifo_full1    => bpm_txf_full(1),
--    i_txfifo_write1   => bpm_txf_write(1),
--    i_txfifo_charisk1 => bpm_txf_charisk(1),
--    i_txfifo_data1    => bpm_txf_data(1),
--    --RX
--    o_rx_vld1         => bpm_rxf_vld(1), --debug
--    i_rxfifo_next1    => bpm_rxf_next(1),
--    o_rxfifo_empty1   => bpm_rxf_empty(1),
--    o_rxfifo_charisk1 => bpm_rxf_charisk(1),
--    o_rxfifo_data1    => bpm_rxf_data(1) 
--);
--
--BPM23_TILE : gtx_tile
--generic map(
--    --mgt
--    G_GTX_REFCLK_SEL       => C_GTX_REFCLK_SEL(4),
--    G_GTX_TILE_REFCLK_FREQ => C_BPM_REFCLK_FREQ,
--    G_GTX_BAUD_RATE        => C_BPM_BAUD_RATE
--)
--port map(
--    --DEBUG
--    o_DBG_x0 => open,
--    o_DBG_v0 => open,
--    o_DBG_k0 => open,
--    o_DBG_d0 => open,
--    o_DBG_x1 => open,
--    o_DBG_v1 => open,
--    o_DBG_k1 => open,
--    o_DBG_d1 => open,
--    --MGT
--    I_GTX_REFCLK1_IN => I_GTX_REFCLK1_IN,
--    I_GTX_REFCLK2_IN => I_GTX_REFCLK2_IN,
--    I_GTX_RX_N       => I_GTX_RX_N(9 downto 8),
--    I_GTX_RX_P       => I_GTX_RX_P(9 downto 8),
--    O_GTX_TX_N       => O_GTX_TX_N(9 downto 8),
--    O_GTX_TX_P       => O_GTX_TX_P(9 downto 8),
--    --
--    i_loopback0      => bpm_loopback(0),
--    i_loopback1      => bpm_loopback(1),
--    o_mgt            => bpm01_mgt_o,
--    ------------------------------------------------------------------------
--    -- FIFO interface
--    ------------------------------------------------------------------------
--    i_clk             => user_clk, --Bus2IP_Clk,
--    --Channel 0
--    i_fifo_reset0     => bpm_fifo_rst(2),
--    --TX
--    o_tx_vld0         => bpm_txf_vld(2), --debug
--    o_txfifo_full0    => bpm_txf_full(2),
--    i_txfifo_write0   => bpm_txf_write(2),
--    i_txfifo_charisk0 => bpm_txf_charisk(2),
--    i_txfifo_data0    => bpm_txf_data(2),
--    --RX
--    o_rx_vld0         => bpm_rxf_vld(2), --debug
--    i_rxfifo_next0    => bpm_rxf_next(2),
--    o_rxfifo_empty0   => bpm_rxf_empty(2),
--    o_rxfifo_charisk0 => bpm_rxf_charisk(2),
--    o_rxfifo_data0    => bpm_rxf_data(2),
--    --Channel 1
--    i_fifo_reset1     => bpm_fifo_rst(3),
--    --TX
--    o_tx_vld1         => bpm_txf_vld(3), --debug
--    o_txfifo_full1    => bpm_txf_full(3),
--    i_txfifo_write1   => bpm_txf_write(3),
--    i_txfifo_charisk1 => bpm_txf_charisk(3),
--    i_txfifo_data1    => bpm_txf_data(3),
--    --RX
--    o_rx_vld1         => bpm_rxf_vld(3), --debug
--    i_rxfifo_next1    => bpm_rxf_next(3),
--    o_rxfifo_empty1   => bpm_rxf_empty(3),
--    o_rxfifo_charisk1 => bpm_rxf_charisk(3),
--    o_rxfifo_data1    => bpm_rxf_data(3) 
--);

---------------------------------------------------------------------------
-- PACKET rx filters
---------------------------------------------------------------------------
filt13_rst <= Bus2IP_Reset or filt13_rst_c;
filt02_rst <= Bus2IP_Reset or filt02_rst_c;

--triggers are resynchronized internally
filt13_trig <= i_filt13_trig or filt13_trig_c;
filt02_trig <= i_filt02_trig or filt02_trig_c;

--If SFP13_FILT_EN = '1', then channels 0 and 2 are connected to a packet filter
FILT13_GEN : if SFP13_FILT_EN = '1' generate

    QSFP13_FILTER_I : ibfb_packet_filter
    generic map(
        --protocol
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        K_BAD => K_BAD 
    )
    port map(
        i_bpm_id         => filt13_bpm_id,
        --
        i_clk            => user_clk, --Bus2IP_Clk,
        i_rst            => filt13_rst,
        i_trig           => filt13_trig,
        --
        o_resetting      => filt13_resetting,
        o_pkt_valid      => filt13_valid,
        o_pkt_discard    => filt13_discard,
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
        --Output channel
        i_output_next     => filt13_o_next,
        o_output_valid    => filt13_o_valid,
        o_output_charisk  => filt13_o_charisk,
        o_output_data     => filt13_o_data
    );

    --connect filter output to router's input port 0
    filt13_o_next       <= router_i_next(0);
    router_i_valid(0)   <= filt13_o_valid;
    router_i_charisk(0) <= filt13_o_charisk;
    router_i_data(0)    <= filt13_o_data;
    --set router's port 1 as unused
    router_i_valid(1)   <= '0';

end generate; --FILT13_GEN
FILT13_GEN_N : if SFP13_FILT_EN = '0' generate

    --connect rx channel 1 directly to packet router's input 0 
    qsfp_rxf_next(1)    <= router_i_next(0);
    router_i_valid(0)   <= not qsfp_rxf_empty(1);
    router_i_charisk(0) <= qsfp_rxf_charisk(1);
    router_i_data(0)    <= qsfp_rxf_data(1);
    --connect rx channel 3 directly to packet router's input 1 
    qsfp_rxf_next(3)    <= router_i_next(1);
    router_i_valid(1)   <= not qsfp_rxf_empty(3);
    router_i_charisk(1) <= qsfp_rxf_charisk(3);
    router_i_data(1)    <= qsfp_rxf_data(3);

end generate; --FILT13_GEN_N

--If SFP02_FILT_EN = '1', then channels 0 and 2 are connected to a packet filter
FILT02_GEN : if SFP02_FILT_EN = '1' generate

    QSFP02_FILTER_I : ibfb_packet_filter
    generic map(
        --protocol
        K_SOP => K_SOP,
        K_EOP => K_EOP,
        K_BAD => K_BAD 
    )
    port map(
        i_bpm_id         => filt02_bpm_id,
        --
        i_clk            => user_clk, --Bus2IP_Clk,
        i_rst            => filt02_rst,
        i_trig           => filt02_trig,
        --
        o_resetting      => filt02_resetting,
        o_pkt_valid      => filt02_valid,
        o_pkt_discard    => filt02_discard,
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
        --Output channel
        i_output_next     => filt02_o_next,
        o_output_valid    => filt02_o_valid,
        o_output_charisk  => filt02_o_charisk,
        o_output_data     => filt02_o_data
    );
    
    --connect filter output to router's input port 2
    filt02_o_next       <= router_i_next(2);
    router_i_valid(2)   <= filt02_o_valid;
    router_i_charisk(2) <= filt02_o_charisk;
    router_i_data(2)    <= filt02_o_data;
    --set router's port 3 as unused
    router_i_valid(3)   <= '0';

end generate; --FILT02_GEN
FILT02_GEN_N : if SFP02_FILT_EN = '0' generate

    --connect rx channel 0 directly to packet router's input 2 
    qsfp_rxf_next(0)    <= router_i_next(2);
    router_i_valid(2)   <= not qsfp_rxf_empty(0);
    router_i_charisk(2) <= qsfp_rxf_charisk(0);
    router_i_data(2)    <= qsfp_rxf_data(0);
    --connect rx channel 2 directly to packet router's input 3 
    qsfp_rxf_next(2)    <= router_i_next(3);
    router_i_valid(3)   <= not qsfp_rxf_empty(2);
    router_i_charisk(3) <= qsfp_rxf_charisk(2);
    router_i_data(3)    <= qsfp_rxf_data(2);

end generate; --FILT02_GEN_N

---------------------------------------------------------------------------
-- PACKET ROUTER
---------------------------------------------------------------------------

router_rst <= Bus2IP_Reset or router_rst_c;

--Has always 5 input ports and 2 output ports.
--Ports 0,1 and 2,3 are used as pairs.
--When a filter is present, it is connected to port 0 or 2, leaving the other port in the pair open.
--When no filter is used, both channels in trhe pair are connected directly to the input FIFOs.
--Output are both connected if output is sent to backplane.
--If output is connected to BPM GTX, then only output 0 is used.
PACKET_ROUTER_I : ibfb_packet_router
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP,
    N_INPUT_PORTS  => 5,
    N_OUTPUT_PORTS => 2
)
port map(
    i_clk     => user_clk,
    i_rst     => router_rst,
    i_err_rst => router_err_rst,
    --input (FIFO, FWFT)
    o_next    => router_i_next,
    i_valid   => router_i_valid,
    i_charisk => router_i_charisk,
    i_data    => router_i_data,
    --output (STREAMING. i_next is used only to detect errors, but does not control data flow)
    i_next    => router_o_next,
    o_valid   => router_o_valid,
    o_err     => router_o_err,
    o_charisk => router_o_charisk,
    o_data    => router_o_data
);

--CONNECT ROUTER OUTPUTS and BPM GTX input
OUT2P0_GEN : if OUTPUT_TO_P0 = '1' generate

    --Router's input 4 connected to BPM0 RX
    bpm_rxf_next(0)     <= router_i_next(4);
    router_i_valid(4)   <= not bpm_rxf_empty(0);
    router_i_charisk(4) <= bpm_rxf_charisk(0);
    router_i_data(4)    <= bpm_rxf_data(0);

    --BPM0 TX not used
    bpm_txf_write(0)    <= '0';

    --Router's outputs connected to P0 (2channels)
    router_o_next(0)  <= not p0_txf_full(0);
    p0_txf_write(0)   <= router_o_valid(0);
    p0_txf_charisk(0) <= router_o_charisk(0);
    p0_txf_data(0)    <= router_o_data(0);

    router_o_next(1)  <= not p0_txf_full(1);
    p0_txf_write(1)   <= router_o_valid(1);
    p0_txf_charisk(1) <= router_o_charisk(1);
    p0_txf_data(1)    <= router_o_data(1);
    
end generate; --OUT_TO_P0_GEN
OUT2P0_GEN_N : if OUTPUT_TO_P0 = '0' generate
    --Router's input 4 not used
    router_i_valid(4)   <= '0';

    --BPM0 RX not used
    bpm_rxf_next(0)     <= '1';

    --Router's output 0 connected to BPM0 TX
    --Router's output 1 left open
    router_o_next(0)   <= not bpm_txf_full(0);
    bpm_txf_write(0)   <= router_o_valid(0);
    bpm_txf_charisk(0) <= router_o_charisk(0);
    bpm_txf_data(0)    <= router_o_data(0);

    router_o_next(1)   <= '1'; --output channel not used

    --P0 channels not used
    p0_txf_write(0) <= '0';
    p0_txf_write(1) <= '0';

end generate; --OUT2P0_GEN_N

--BP channels 1,2,3 not used
bpm_rxf_next(1 to 3)  <= "111";
bpm_txf_write(1 to 3) <= "000";

------------------------------------------------------------------------------
-- DEBUG FIFO
------------------------------------------------------------------------------
dbg_fifo_rst   <= Bus2IP_Reset or dbg_fifo_rst_c;
dbg_fifo_write <= dbg_fifo_en and router_o_valid(0) and (not dbg_fifo_full);

--Read from data register advances RX FIFO
SLV_FIFO_RD_P : process ( Bus2IP_Clk )
begin
    if rising_edge( Bus2IP_Clk ) then
        dbg_fifo_read    <= Bus2IP_RdCE;
        dbg_fifo_read_re <= Bus2IP_RdCE and not dbg_fifo_read;
    end if;
end process;

DBG_FIFO : FIFO36
generic map(
    DATA_WIDTH              => 36,
    --ALMOST_FULL_OFFSET      : bit_vector := X"0080";
    --ALMOST_EMPTY_OFFSET     : bit_vector := X"0080";
    DO_REG                  => 1,
    EN_SYN                  => FALSE,
    FIRST_WORD_FALL_THROUGH => TRUE
)
port map(
    RST         => dbg_fifo_rst,
    --
    WRCLK       => user_clk, --Bus2IP_Clk,
    FULL        => dbg_fifo_full,
    ALMOSTFULL  => open,
    WREN        => dbg_fifo_write,
    WRCOUNT     => open,
    WRERR       => open,
    DIP         => router_o_charisk(0),
    DI          => router_o_data(0),
    --
    RDCLK       => Bus2IP_Clk,
    EMPTY       => dbg_fifo_empty,
    ALMOSTEMPTY => open,
    RDEN        => dbg_fifo_read_re,
    RDCOUNT     => open,
    RDERR       => open,
    DOP         => dbg_fifo_charisk,
    DO          => dbg_fifo_data
);

end architecture behavioral;

------------------------------------------------------------------------------
-- End of file
------------------------------------------------------------------------------
