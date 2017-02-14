
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ibfb_comm_package.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity user_logic_sim_tb is
end entity user_logic_sim_tb;


--FIRST TEST (SWITCH IN BPM1 configuration: receive data from QSFP, FILTER, FORWARD TO P0
architecture test_bpm1 of user_logic_sim_tb is

component user_logic is
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
    qsfp_rxf_next    : out std_logic_vector(0 to 3);
    qsfp_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    qsfp_rxf_charisk : in array4(0 to 3);
    qsfp_rxf_data    : in array32(0 to 3);
  --
    bpm_rxf_next    : out std_logic_vector(0 to 3);
    bpm_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
    bpm_rxf_charisk : in  array4(0 to 3);
    bpm_rxf_data    : in  array32(0 to 3);
  --TX channels
    p0_txf_full    : in  std_logic_vector(0 to 1) := "00";
    p0_txf_write   : out std_logic_vector(0 to 1);
    p0_txf_charisk : out array4(0 to 1);
    p0_txf_data    : out array32(0 to 1);
  --
    bpm_txf_full    : in  std_logic_vector(0 to 3) := X"0";
    bpm_txf_write   : out std_logic_vector(0 to 3);
    bpm_txf_charisk : out array4(0 to 3);
    bpm_txf_data    : out array32(0 to 3); 
    --
    dbg_fifo_empty   : out std_logic;
    dbg_fifo_charisk : out std_logic_vector(3 downto 0);
    dbg_fifo_data    : out std_logic_vector(31 downto 0);
    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_filt13_trig : in std_logic; --filter connected to channels 1 and 3
    i_filt02_trig : in std_logic; --filter connected to channels 0 and 2
    user_clk                    : in    std_logic;
    Bus2IP_Clk                  : in    std_logic;
    Bus2IP_Reset                : in    std_logic;
    Bus2IP_RdCE                 : in    std_logic
);
end component user_logic;

--Playback packets from RAM
--Packets are stored in 32bit RAM as follows:
--    CTRL(8) & BPM(8) & BUCKET(16)
--    X_POSITION(32)
--    Y_POSITION(32)
component ibfb_packet_player is
generic(
    CTRL_EOS   : std_logic_vector(7 downto 0) := X"FF"; --when this CTRL value is encountered, playback is stopped
    RAM_ADDR_W : natural := 13 --0x1FFF 32-bit words => 0x1FFF/3 = 2730 packets 
);
port(
    i_clk       : in  std_logic;
    i_rst       : in  std_logic;
    --debug signals
    o_dbg_ram_raddr : out std_logic_vector(RAM_ADDR_W-1 downto 0);
    o_dbg_ram_rdata : out std_logic_vector(31 downto 0);
    --CTRL interface
    i_start     : in  std_logic;
    o_busy      : out std_logic;
    o_pkt_num   : out std_logic_vector(RAM_ADDR_W-1 downto 0);
    --RAM interface
    i_ram_clk : in  std_logic;
    i_ram_w   : in  std_logic;
    i_ram_a   : in  std_logic_vector(RAM_ADDR_W-1 downto 0);
    i_ram_d   : in  std_logic_vector(31 downto 0);
    o_ram_d   : out std_logic_vector(31 downto 0);
    --TX Interface
    i_sop       : in  std_logic;
    i_eop       : in  std_logic;
    i_busy      : in  std_logic;
    o_tx_valid  : out std_logic;
    o_tx_data   : out ibfb_comm_packet  --tx data (packet fields)
);
end component ibfb_packet_player;

component ram_infer_dual is
generic(
    ADDR_W : natural := 12;
    DATA_W : natural := 36 
);
port(
    --port A (read/write)
    clka  : in  std_logic;
    ena   : in  std_logic;
    wea   : in  std_logic;
    addra : in  std_logic_vector(ADDR_W-1 downto 0);
    dia   : in  std_logic_vector(DATA_W-1 downto 0);
    doa   : out std_logic_vector(DATA_W-1 downto 0);
    --port B
    clkb  : in  std_logic;
    enb   : in  std_logic;
    addrb : in  std_logic_vector(ADDR_W-1 downto 0);
    dob   : out std_logic_vector(DATA_W-1 downto 0)
);
end component ram_infer_dual;

component FIFO36
   generic
   (
      DATA_WIDTH                  : integer := 4;
      ALMOST_FULL_OFFSET          : bit_vector := X"0080";
      ALMOST_EMPTY_OFFSET         : bit_vector := X"0080";
      DO_REG                      : integer := 1;
      EN_SYN                      : boolean := FALSE;
      FIRST_WORD_FALL_THROUGH     : boolean := FALSE
   );
   port
   (
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

constant RAM_ADDR_W    : natural := 14;
constant RAM_INIT_SIZE : natural := 44;
constant K_SOP : std_logic_vector(7 downto 0) := X"FB";
constant K_EOP : std_logic_vector(7 downto 0) := X"FD";

signal clk, rst : std_logic;
signal ram_init_w : std_logic;
signal ram_init_a : std_logic_vector(RAM_ADDR_W-1 downto 0);
signal ram_read_a : std_logic_vector(RAM_ADDR_W-1 downto 0);
signal ram_init_d, ram_read_d : std_logic_vector(31 downto 0);
signal ram_init_id : natural;
signal ram_init_done : std_logic;

signal pl_start, player_ovalid, pl_busy : std_logic;
signal player_odata : ibfb_comm_packet;

signal pkt_tx_busy, pkt_tx_sop : std_logic;

signal trig02, trig13   : std_logic := '0';

signal txf_full, txf_write : std_logic;
signal txf_charisk : std_logic_vector(3 downto 0);
signal txf_data    : std_logic_vector(31 downto 0);

signal qsfp_rxf_next    : std_logic_vector(0 to 3) := X"0";
signal qsfp_rxf_empty   : std_logic_vector(0 to 3) := X"F";
signal qsfp_rxf_charisk : array4(0 to 3)           := (others => (others => '0'));
signal qsfp_rxf_data    : array32(0 to 3)          := (others => (others => '0'));
  --
signal bpm_rxf_next    : std_logic_vector(0 to 3) := X"0";
signal bpm_rxf_empty   : std_logic_vector(0 to 3) := X"F";
signal bpm_rxf_charisk : array4(0 to 3)           := (others => (others => '0'));
signal bpm_rxf_data    : array32(0 to 3)          := (others => (others => '0'));
  --
signal p0_txf_full    : std_logic_vector(0 to 1) := "00";
signal p0_txf_write   : std_logic_vector(0 to 1) := "00";
signal p0_txf_charisk : array4(0 to 1)           := (others => (others => '0'));
signal p0_txf_data    : array32(0 to 1)          := (others => (others => '0'));
  --
signal bpm_txf_full    : std_logic_vector(0 to 3) := X"0";
signal bpm_txf_write   : std_logic_vector(0 to 3) := X"0";
signal bpm_txf_charisk : array4(0 to 3)           := (others => (others => '0'));
signal bpm_txf_data    : array32(0 to 3)          := (others => (others => '0')); 
    --
signal dbg_fifo_empty   : std_logic;
signal dbg_fifo_read    : std_logic;
signal dbg_fifo_charisk : std_logic_vector(3 downto 0);
signal dbg_fifo_data    : std_logic_vector(31 downto 0);

signal dbg_ram_raddr : std_logic_vector(RAM_ADDR_W-1 downto 0);
signal dbg_ram_rdata : std_logic_vector(31 downto 0);

type ram_t is array (0 to RAM_INIT_SIZE-1) of std_logic_vector(31 downto 0);
constant ram_init_data : ram_t := ( 
    X"00000010",X"1A"&X"01"&X"0010", X"11110001", X"22220001", --PACKET 0 (00:03)
    X"00000020",X"1B"&X"01"&X"0011", X"11110002", X"22220002", --PACKET 1 (04:07)
    X"00000030",X"1C"&X"01"&X"0012", X"11110003", X"22220003", --PACKET 2 (08:11)
    X"00000040",X"1D"&X"01"&X"0013", X"11110004", X"22220004", --PACKET 3 (12:15)
    X"00000000",X"FF"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 4 (16:19)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 5 (20:23)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 6 (24:27)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 7 (28:31)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 8 (32:35)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000", --PACKET 9 (36:39)
    X"00000000",X"00"&X"00"&X"0000", X"00000000", X"00000000"  --END OF SEQUENCE (40:43)
);

begin

rst <= '1', '0' after 500 ns;
clk <= '1' after 5 ns when clk = '0' else
       '0' after 5 ns;
pl_start <= '0';

--initialize ram content
RAM_INIT_P : process(clk)
begin
    if rising_edge(clk) then
        if rst = '1' then
            ram_init_id <= 0;
            ram_init_w  <= '0';
            ram_init_done <= '0';
        else
            if ram_init_id < RAM_INIT_SIZE then
                ram_init_d <= ram_init_data(ram_init_id);
                ram_init_a <= std_logic_vector(to_unsigned(ram_init_id,RAM_ADDR_W));
                ram_init_w <= '1';
                ram_init_id <= ram_init_id+1;
            else
                ram_init_done <= '1';
                ram_init_w <= '0';
            end if;
        end if;
    end if;
end process;

PLAYER_I : ibfb_packet_player
generic map(
    CTRL_EOS   => X"FF",
    RAM_ADDR_W => RAM_ADDR_W
)
port map(
    i_clk      => clk,
    i_rst      => rst,
    o_dbg_ram_raddr => dbg_ram_raddr,
    o_dbg_ram_rdata => dbg_ram_rdata,
    --CTRL interface
    i_start    => pl_start,
    o_busy     => pl_busy,
    o_pkt_num  => open,
    --RAM interface
    i_ram_clk  => clk,
    i_ram_w    => ram_init_w,
    i_ram_a    => ram_init_a,
    i_ram_d    => ram_init_d,
    o_ram_d    => open,
    --TX Interface
    i_sop      => pkt_tx_sop,
    i_eop      => '0', --internally not connected
    i_busy     => pkt_tx_busy,
    o_tx_valid => player_ovalid,
    o_tx_data  => player_odata
);


PKT_TX_I : ibfb_packet_tx
generic map(
    K_SOP => K_SOP,
    K_EOP => K_EOP,
    EXTERNAL_CRC => '0'
)
port map(
    i_rst       => rst,
    i_clk       => clk,
    --user interface
    o_sample    => pkt_tx_sop,
    o_busy      => pkt_tx_busy,
    i_tx_valid  => player_ovalid,
    i_tx_data   => player_odata,
    --MGT FIFO interface
    i_fifo_full => txf_full,
    o_valid     => txf_write,
    o_charisk   => txf_charisk,
    o_data      => txf_data
);

--emulate MGT TX/RX fifo
MGT_FIFO_i : FIFO36
    generic map(
        DATA_WIDTH              => 36, --36 bit width
        ALMOST_FULL_OFFSET      => X"080", --almost full when FIFO contains more than 128 (1/8)
        ALMOST_EMPTY_OFFSET     => X"080", --almost empty when FIFO contains less than 128 (1/8)
        DO_REG                  => 1, --enable data pipeline register
        EN_SYN                  => FALSE, --no multirate
        FIRST_WORD_FALL_THROUGH => TRUE 
    )
    port map(
        RST         => rst,

        WRCLK       => clk,
        FULL        => txf_full,
        ALMOSTFULL  => open,
        WREN        => txf_write,
        WRCOUNT     => open,
        WRERR       => open,
        DIP         => txf_charisk,
        DI          => txf_data,

        RDCLK       => clk,
        EMPTY       => qsfp_rxf_empty(0),
        ALMOSTEMPTY => open,
        RDEN        => qsfp_rxf_next(0),
        RDCOUNT     => open,
        RDERR       => open,
        DOP         => qsfp_rxf_charisk(0),
        DO          => qsfp_rxf_data(0)
    );

SWITCH_UUT : user_logic
generic map(
    --BPM1 FPGA 
    SFP02_FILT_EN    => '1',
    SFP13_FILT_EN    => '1',
    OUTPUT_TO_P0     => '1',
    --Packet protocol 
    K_SOP            => K_SOP,
    K_EOP            => K_EOP,
    --Transceivers
    C_GTX_REFCLK_SEL    => X"00"
)
port map(
    --RX channels
    qsfp_rxf_next    => qsfp_rxf_next,
    qsfp_rxf_empty   => qsfp_rxf_empty,
    qsfp_rxf_charisk => qsfp_rxf_charisk,
    qsfp_rxf_data    => qsfp_rxf_data,
    --
    bpm_rxf_next    => bpm_rxf_next,
    bpm_rxf_empty   => bpm_rxf_empty,
    bpm_rxf_charisk => bpm_rxf_charisk,
    bpm_rxf_data    => bpm_rxf_data,
    --TX channels
    p0_txf_full    => p0_txf_full,
    p0_txf_write   => p0_txf_write,
    p0_txf_charisk => p0_txf_charisk,
    p0_txf_data    => p0_txf_data,
    --
    bpm_txf_full    => bpm_txf_full,
    bpm_txf_write   => bpm_txf_write,
    bpm_txf_charisk => bpm_txf_charisk,
    bpm_txf_data    => bpm_txf_data,
    --
    dbg_fifo_empty   => dbg_fifo_empty,
    dbg_fifo_charisk => dbg_fifo_charisk,
    dbg_fifo_data    => dbg_fifo_data,

    ------------------------------------------------------------------------
    -- Triggers (synchronized internally)
    ------------------------------------------------------------------------
    i_filt13_trig => trig13,
    i_filt02_trig => trig02,
    user_clk      => clk,
    Bus2IP_Clk    => clk,
    Bus2IP_RdCE   => dbg_fifo_read,
    Bus2IP_Reset  => rst
);

dbg_fifo_read <= '0';

end architecture test_bpm1;


----SECOND TEST (SWITCH IN BPM2 configuration: receive data from QSFP, FILTER only one couple, FORWARD TO BPM0
--architecture test_bpm2 of user_logic_sim_tb is
--
--component FIFO36
--   generic
--   (
--      DATA_WIDTH                  : integer := 4;
--      ALMOST_FULL_OFFSET          : bit_vector := X"0080";
--      ALMOST_EMPTY_OFFSET         : bit_vector := X"0080";
--      DO_REG                      : integer := 1;
--      EN_SYN                      : boolean := FALSE;
--      FIRST_WORD_FALL_THROUGH     : boolean := FALSE
--   );
--   port
--   (
--      RST                         : in   std_ulogic;
--
--      WRCLK                       : in    std_ulogic;
--      FULL                        : out   std_ulogic;
--      ALMOSTFULL                  : out   std_ulogic;
--      WREN                        : in    std_ulogic;
--      WRCOUNT                     : out   std_logic_vector(12 downto  0);
--      WRERR                       : out   std_ulogic;
--      DIP                         : in    std_logic_vector( 3 downto  0);
--      DI                          : in    std_logic_vector(31 downto  0);
--
--      RDCLK                       : in    std_ulogic;
--      EMPTY                       : out   std_ulogic;
--      ALMOSTEMPTY                 : out   std_ulogic;
--      RDEN                        : in    std_ulogic;
--      RDCOUNT                     : out   std_logic_vector(12 downto  0);
--      RDERR                       : out   std_ulogic;
--      DOP                         : out   std_logic_vector( 3 downto  0);
--      DO                          : out   std_logic_vector(31 downto  0)
--   );
--end component;
--
----Playback packets from RAM
----Packets are stored in 32bit RAM as follows:
----    CTRL(8) & BPM(8) & BUCKET(16)
----    X_POSITION(32)
----    Y_POSITION(32)
--component ibfb_packet_player is
--generic(
--    CTRL_EOS   : std_logic_vector(7 downto 0) := X"FF"; --when this CTRL value is encountered, playback is stopped
--    RAM_ADDR_W : natural := 13 --0x1FFF 32-bit words => 0x1FFF/3 = 2730 packets 
--);
--port(
--    i_clk       : in  std_logic;
--    i_rst       : in  std_logic;
--    --debug signals
--    o_dbg_ram_raddr : out std_logic_vector(RAM_ADDR_W-1 downto 0);
--    o_dbg_ram_rdata : out std_logic_vector(31 downto 0);
--    --CTRL interface
--    i_start     : in  std_logic;
--    o_busy      : out std_logic;
--    o_pkt_num   : out std_logic_vector(RAM_ADDR_W-1 downto 0);
--    --RAM interface
--    i_ram_clk : in  std_logic;
--    i_ram_w   : in  std_logic;
--    i_ram_a   : in  std_logic_vector(RAM_ADDR_W-1 downto 0);
--    i_ram_d   : in  std_logic_vector(31 downto 0);
--    o_ram_d   : out std_logic_vector(31 downto 0);
--    --TX Interface
--    i_sop       : in  std_logic;
--    i_eop       : in  std_logic;
--    i_busy      : in  std_logic;
--    o_tx_valid  : out std_logic;
--    o_tx_data   : out ibfb_comm_packet  --tx data (packet fields)
--);
--end component ibfb_packet_player;
--
--component user_logic is
--generic (
--    --Interconnection topology 
--    SFP02_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 02
--    SFP13_FILT_EN    : std_logic := '1'; --enable packet filter on channel pair 13
--    OUTPUT_TO_P0     : std_logic := '1'; --when 1, packets are output on backplane P0 connector. 
--                                         --Otherwise on BPM0 channel
--    --Packet protocol 
--    K_SOP            : std_logic_vector(7 downto 0) := X"FB"; 
--    K_EOP            : std_logic_vector(7 downto 0) := X"FD";
--    --Transceivers
--    C_GTX_REFCLK_SEL    : std_logic_vector(7 downto 0); --BPM23, BPM01, P0, SFP02, SFP13
--    --
--    C_SFP13_REFCLK_FREQ : integer := 125; --MHz
--    C_SFP02_REFCLK_FREQ : integer := 125; --MHz
--    C_P0_REFCLK_FREQ    : integer := 125; --MHz
--    C_BPM_REFCLK_FREQ   : integer := 125; --MHz
--    --
--    C_SFP13_BAUD_RATE   : integer := 3125000; --Kbps
--    C_SFP02_BAUD_RATE   : integer := 3125000; --Kbps
--    C_P0_BAUD_RATE      : integer := 3125000; --Kbps
--    C_BPM_BAUD_RATE     : integer := 3125000; --Kbps
--    --PLB 
--    C_SLV_DWIDTH     : integer := 32;
--    C_NUM_REG        : integer := 32
--);
--port (
--    --RX channels
--    qsfp_rxf_next    : out std_logic_vector(0 to 3);
--    qsfp_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
--    qsfp_rxf_charisk : in array4(0 to 3);
--    qsfp_rxf_data    : in array32(0 to 3);
--  --
--    bpm_rxf_next    : out std_logic_vector(0 to 3);
--    bpm_rxf_empty   : in  std_logic_vector(0 to 3) := X"F";
--    bpm_rxf_charisk : in  array4(0 to 3);
--    bpm_rxf_data    : in  array32(0 to 3);
--  --TX channels
--    p0_txf_full    : in  std_logic_vector(0 to 1) := "00";
--    p0_txf_write   : out std_logic_vector(0 to 1);
--    p0_txf_charisk : out array4(0 to 1);
--    p0_txf_data    : out array32(0 to 1);
--  --
--    bpm_txf_full    : in  std_logic_vector(0 to 3) := X"0";
--    bpm_txf_write   : out std_logic_vector(0 to 3);
--    bpm_txf_charisk : out array4(0 to 3);
--    bpm_txf_data    : out array32(0 to 3); 
--    --
--    dbg_fifo_empty   : out std_logic;
--    dbg_fifo_read    : in  std_logic;
--    dbg_fifo_charisk : out std_logic_vector(3 downto 0);
--    dbg_fifo_data    : out std_logic_vector(31 downto 0);
--    ------------------------------------------------------------------------
--    -- Triggers (synchronized internally)
--    ------------------------------------------------------------------------
--    i_filt13_trig : in std_logic; --filter connected to channels 1 and 3
--    i_filt02_trig : in std_logic; --filter connected to channels 0 and 2
--    user_clk                    : in    std_logic;
--    Bus2IP_Reset                : in    std_logic
--);
--end component user_logic;
--
--constant K_SOP : std_logic_vector(7 downto 0) := X"FB";
--constant K_EOP : std_logic_vector(7 downto 0) := X"FD";
--
--signal clk, rst : std_logic;
--signal ram_init_w : std_logic;
--signal ram_init_a : std_logic_vector(RAM_ADDR_W-1 downto 0);
--signal ram_read_a : std_logic_vector(RAM_ADDR_W-1 downto 0);
--signal ram_init_d, ram_read_d : std_logic_vector(31 downto 0);
--signal ram_init_id : natural;
--signal ram_init_done : std_logic;
--
--signal pl_start, player_ovalid, pl_busy : std_logic;
--signal player_odata : ibfb_comm_packet;
---------------------------------------------------------
--
--signal qsfp_rxf_next    : std_logic_vector(0 to 3);
--signal qsfp_rxf_empty   : std_logic_vector(0 to 3);
--signal qsfp_rxf_charisk : array4(0 to 3);
--signal qsfp_rxf_data    : array32(0 to 3);
----
--signal bpm_rxf_next    : std_logic_vector(0 to 3);
--signal bpm_rxf_empty   : std_logic_vector(0 to 3);
--signal bpm_rxf_charisk : array4(0 to 3);
--signal bpm_rxf_data    : array32(0 to 3);
----
--signal p0_txf_full    : std_logic_vector(0 to 1);
--signal p0_txf_write   : std_logic_vector(0 to 1);
--signal p0_txf_charisk : array4(0 to 1);
--signal p0_txf_data    : array32(0 to 1);
----
--signal bpm_txf_full    : std_logic_vector(0 to 3);
--signal bpm_txf_write   : std_logic_vector(0 to 3);
--signal bpm_txf_charisk : array4(0 to 3);
--signal bpm_txf_data    : array32(0 to 3);
--signal bpm_txf_next    : std_logic_vector(0 to 3);
--
--type array8 is array (natural range<>) of std_logic_vector(7 downto 0);
--type arrayP is array (natural range<>) of ibfb_comm_packet;
--
--constant CTRL_V      : array8(0 to 3) := (X"AA", X"BB", X"CC", X"DD");
--constant DOWNCOUNT_V : std_logic_vector(0 to 3) := "0011";
--
--signal qsfp_pkt_start : std_logic_vector(0 to 3);
--signal qsfp_pkt_busy  : std_logic_vector(0 to 3);
--signal qsfp_pkt_valid : std_logic_vector(0 to 3);
--signal qsfp_pkt       : arrayP(0 to 3);
--
--signal qsfp_txf_full    : std_logic_vector(0 to 3);
--signal qsfp_txf_valid   : std_logic_vector(0 to 3);
--signal qsfp_txf_charisk : array4(0 to 3);
--signal qsfp_txf_data    : array32(0 to 3);
--
--signal bpm_rx_bad_data : std_logic;
--signal bpm_rx_eop      : std_logic;
--signal bpm_rx_crc_good : std_logic;
--signal bpm_rx_data     : ibfb_comm_packet;
--
--signal bpm_rx_eop_reg  : std_logic;
--signal bpm_rx_good_reg : std_logic;
--signal bpm_rx_data_reg : ibfb_comm_packet;
--
--signal npackets : std_logic_vector(7 downto 0);
--
--signal trig13, trig02 : std_logic;
--
--signal dbg_fifo_empty   : std_logic;
--signal dbg_fifo_read    : std_logic;
--signal dbg_fifo_charisk : std_logic_vector(3 downto 0);
--signal dbg_fifo_data    : std_logic_vector(31 downto 0);
--
--begin
--
--rst <= '1', '0' after 500 ns;
--clk <= '1' after 5 ns when clk = '0' else 
--       '0' after 5 ns;
--
--pl_start <= '0';
----initialize ram content
--RAM_INIT_P : process(clk)
--begin
--    if rising_edge(clk) then
--        if rst = '1' then
--            ram_init_id <= 0;
--            ram_init_w  <= '0';
--            ram_init_done <= '0';
--        else
--            if ram_init_id < RAM_INIT_SIZE then
--                ram_init_d <= ram_init_data(ram_init_id);
--                ram_init_a <= std_logic_vector(to_unsigned(ram_init_id,RAM_ADDR_W));
--                ram_init_w <= '1';
--                ram_init_id <= ram_init_id+1;
--            else
--                ram_init_done <= '1';
--                ram_init_w <= '0';
--            end if;
--        end if;
--    end if;
--end process;
--
--PLAYER_I : ibfb_packet_player
--generic map(
--    CTRL_EOS   => X"FF",
--    RAM_ADDR_W => RAM_ADDR_W
--)
--port map(
--    i_clk      => clk,
--    i_rst      => rst,
--    o_dbg_ram_raddr => dbg_ram_raddr,
--    o_dbg_ram_rdata => dbg_ram_rdata,
--    --CTRL interface
--    i_start    => pl_start,
--    o_busy     => pl_busy,
--    o_pkt_num  => open,
--    --RAM interface
--    i_ram_clk  => clk,
--    i_ram_w    => ram_init_w,
--    i_ram_a    => ram_init_a,
--    i_ram_d    => ram_init_d,
--    o_ram_d    => open,
--    --TX Interface
--    i_sop      => pkt_tx_sop,
--    i_eop      => open,
--    i_busy     => pkt_tx_busy,
--    o_tx_valid => player_ovalid,
--    o_tx_data  => player_odata
--);
----EMULATE QSFP CHANNELS (leave channel 3 unconnected)
--QSFP_GEN : for i in 0 to 2 generate
--
--    PKT_GEN_i : ibfb_packet_gen
--    generic map(
--        CTRL => CTRL_V(i),
--        PKT_CNT_W => 8,
--        DOWNCOUNT => DOWNCOUNT_V(i),
--        SOP => K_SOP,
--        EOP => K_EOP
--    )
--    port map(
--        i_clk       => clk,
--        i_rst       => rst,
--        --CTRL interface
--        i_start     => qsfp_pkt_start(i),
--        i_npackets  => npackets,
--        --PKT interface
--        i_busy      => qsfp_pkt_busy(i),
--        o_tx_valid  => qsfp_pkt_valid(i),
--        o_tx_data   => qsfp_pkt(i)
--    );
--
--    PACK_TX_i : ibfb_packet_tx
--    generic map(
--        K_SOP => K_SOP,
--        K_EOP => K_EOP,
--        EXTERNAL_CRC => '0'
--    )
--    port map(
--        i_rst       => rst,
--        i_clk       => clk,
--        --user interface
--        o_busy      => qsfp_pkt_busy(i),
--        i_tx_valid  => qsfp_pkt_valid(i),
--        i_tx_data   => qsfp_pkt(i),
--        --MGT FIFO interface
--        i_fifo_full => qsfp_txf_full(i),
--        o_valid     => qsfp_txf_valid(i),
--        o_charisk   => qsfp_txf_charisk(i),
--        o_data      => qsfp_txf_data(i)
--    );
--
--    assert not(qsfp_txf_valid(i) = '1' and qsfp_txf_full(i) = '1')
--           report "QSFP_PKT_TX : CRITICAL : Writing TX FIFO while FULL"
--           severity error;
--
--    FIFO_i : FIFO36
--    generic map(
--        DATA_WIDTH              => 36, --36 bit width
--        ALMOST_FULL_OFFSET      => X"080", --almost full when FIFO contains more than 128 (1/8)
--        ALMOST_EMPTY_OFFSET     => X"080", --almost empty when FIFO contains less than 128 (1/8)
--        DO_REG                  => 1, --enable data pipeline register
--        EN_SYN                  => FALSE, --no multirate
--        FIRST_WORD_FALL_THROUGH => TRUE 
--    )
--    port map(
--        RST         => rst,
--
--        WRCLK       => clk,
--        FULL        => qsfp_txf_full(i),
--        ALMOSTFULL  => open,
--        WREN        => qsfp_txf_valid(i),
--        WRCOUNT     => open,
--        WRERR       => open,
--        DIP         => qsfp_txf_charisk(i),
--        DI          => qsfp_txf_data(i),
--
--        RDCLK       => clk,
--        EMPTY       => qsfp_rxf_empty(i),
--        ALMOSTEMPTY => open,
--        RDEN        => qsfp_rxf_next(i),
--        RDCOUNT     => open,
--        RDERR       => open,
--        DOP         => qsfp_rxf_charisk(i),
--        DO          => qsfp_rxf_data(i)
--    );
--
--end generate;
--
--qsfp_rxf_empty(3) <= '0'; --channel not used
--
--bpm_rxf_empty <= "1111";
--
--SWITCH_UUT : user_logic
--generic map(
--    --BPM1 FPGA 
--    SFP02_FILT_EN    => '1',
--    SFP13_FILT_EN    => '0',
--    OUTPUT_TO_P0     => '0',
--    --Packet protocol 
--    K_SOP            => K_SOP,
--    K_EOP            => K_EOP,
--    --Transceivers
--    C_GTX_REFCLK_SEL    => X"00"
--)
--port map(
--    --RX channels
--    qsfp_rxf_next    => qsfp_rxf_next,
--    qsfp_rxf_empty   => qsfp_rxf_empty,
--    qsfp_rxf_charisk => qsfp_rxf_charisk,
--    qsfp_rxf_data    => qsfp_rxf_data,
--  --
--    bpm_rxf_next    => bpm_rxf_next,
--    bpm_rxf_empty   => bpm_rxf_empty,
--    bpm_rxf_charisk => bpm_rxf_charisk,
--    bpm_rxf_data    => bpm_rxf_data,
--  --TX channels
--    p0_txf_full    => p0_txf_full,
--    p0_txf_write   => p0_txf_write,
--    p0_txf_charisk => p0_txf_charisk,
--    p0_txf_data    => p0_txf_data,
--  --
--    bpm_txf_full    => bpm_txf_full,
--    bpm_txf_write   => bpm_txf_write,
--    bpm_txf_charisk => bpm_txf_charisk,
--    bpm_txf_data    => bpm_txf_data,
--    --
--    dbg_fifo_empty   => dbg_fifo_empty,
--    dbg_fifo_read    => dbg_fifo_read,
--    dbg_fifo_charisk => dbg_fifo_charisk,
--    dbg_fifo_data    => dbg_fifo_data,
--    ------------------------------------------------------------------------
--    -- Triggers (synchronized internally)
--    ------------------------------------------------------------------------
--    i_filt13_trig => trig13,
--    i_filt02_trig => trig02,
--    user_clk      => clk,
--    Bus2IP_Reset  => rst
--);
--
--    bpm_txf_next(1 to 3) <= "000";
--    bpm_txf_full <= not bpm_txf_next;
--
--    PKT_RX : ibfb_packet_rx
--    generic map(
--        K_SOP => K_SOP,
--        K_EOP => K_EOP
--    )
--    port map(
--        i_rst => rst,
--        i_clk => clk,
--        --MGT FIFO interface
--        o_next     => bpm_txf_next(0),
--        i_valid    => bpm_txf_write(0),
--        i_charisk  => bpm_txf_charisk(0),
--        i_data     => bpm_txf_data(0),
--        --user interface
--        o_bad_data => bpm_rx_bad_data,
--        o_eop      => bpm_rx_eop,
--        o_crc_good => bpm_rx_crc_good,
--        o_rx_data  => bpm_rx_data
--    );
--
--    RX_PKT_REG_P : process(clk)
--    begin
--        if rising_edge(clk) then
--            bpm_rx_eop_reg  <= bpm_rx_eop;
--            bpm_rx_good_reg <= bpm_rx_crc_good;
--            if bpm_rx_eop = '1' then
--                bpm_rx_data_reg <= bpm_rx_data;
--            end if;
--        end if;
--    end process;
--
--end architecture test_bpm2;
