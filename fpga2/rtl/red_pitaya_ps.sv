////////////////////////////////////////////////////////////////////////////////
// @brief Red Pitaya Processing System (PS) wrapper. Including simple AXI slave.
// @Author Matej Oblak
// (c) Red Pitaya  http://www.redpitaya.com
////////////////////////////////////////////////////////////////////////////////

/**
 * GENERAL DESCRIPTION:
 *
 * Wrapper of block design.  
 *
 *                   /-------\
 *   PS CLK -------> |       | <---------------------> SPI master & slave
 *   PS RST -------> |  PS   |
 *                   |       | ------------+---------> FCLK & reset 
 *                   |       |             |
 *   PS DDR <------> |  ARM  |   AXI   /-------\
 *   PS MIO <------> |       | <-----> |  AXI  | <---> system bus
 *                   \-------/         | SLAVE |
 *                                     \-------/
 *
 * Module wrappes PS module (BD design from Vivado or EDK from PlanAhead).
 * There is also included simple AXI slave which serves as master for custom
 * system bus. With this simpler bus it is more easy for newbies to develop 
 * their own module communication with ARM.
 */

module red_pitaya_ps (
  // PS peripherals
  inout  logic [ 54-1:0] FIXED_IO_mio       ,
  inout  logic           FIXED_IO_ps_clk    ,
  inout  logic           FIXED_IO_ps_porb   ,
  inout  logic           FIXED_IO_ps_srstb  ,
  inout  logic           FIXED_IO_ddr_vrn   ,
  inout  logic           FIXED_IO_ddr_vrp   ,
  // DDR
  inout  logic [ 15-1:0] DDR_addr           ,
  inout  logic [  3-1:0] DDR_ba             ,
  inout  logic           DDR_cas_n          ,
  inout  logic           DDR_ck_n           ,
  inout  logic           DDR_ck_p           ,
  inout  logic           DDR_cke            ,
  inout  logic           DDR_cs_n           ,
  inout  logic [  4-1:0] DDR_dm             ,
  inout  logic [ 32-1:0] DDR_dq             ,
  inout  logic [  4-1:0] DDR_dqs_n          ,
  inout  logic [  4-1:0] DDR_dqs_p          ,
  inout  logic           DDR_odt            ,
  inout  logic           DDR_ras_n          ,
  inout  logic           DDR_reset_n        ,
  inout  logic           DDR_we_n           ,
  // system signals
  output logic [  4-1:0] fclk_clk_o         ,
  output logic [  4-1:0] fclk_rstn_o        ,
  // XADC
  input  logic  [ 5-1:0] vinp_i             ,  // voltages p
  input  logic  [ 5-1:0] vinn_i             ,  // voltages n
  // interrupts
  input  logic  [13-1:0] irq,
  // system read/write channel
  sys_bus_if.m           bus,
  // stream input
  str_bus_if.d           sti [4-1:0],
  str_bus_if.s           sto [4-1:0]
);

////////////////////////////////////////////////////////////////////////////////
// AXI SLAVE
////////////////////////////////////////////////////////////////////////////////

logic [4-1:0] fclk_clk ;
logic [4-1:0] fclk_rstn;

axi4_if #(.DW (32), .AW (32), .IW (12), .LW (4)) axi_gp (.ACLK (bus.clk), .ARESETn (bus.rstn));

axi4_slave #(
  .DW (32),
  .AW (32),
  .IW (12)
) axi_slave_gp0 (
  // AXI bus
  .axi       (axi_gp),
  // system read/write channel
  .bus       (bus)
);

////////////////////////////////////////////////////////////////////////////////
// PS STUB
////////////////////////////////////////////////////////////////////////////////

assign fclk_rstn_o = fclk_rstn;

BUFG fclk_buf [4-1:0] (.O(fclk_clk_o), .I(fclk_clk));

system_wrapper system_i (
  // MIO
  .FIXED_IO_mio      (FIXED_IO_mio     ),
  .FIXED_IO_ps_clk   (FIXED_IO_ps_clk  ),
  .FIXED_IO_ps_porb  (FIXED_IO_ps_porb ),
  .FIXED_IO_ps_srstb (FIXED_IO_ps_srstb),
  .FIXED_IO_ddr_vrn  (FIXED_IO_ddr_vrn ),
  .FIXED_IO_ddr_vrp  (FIXED_IO_ddr_vrp ),
  // DDR
  .DDR_addr          (DDR_addr         ),
  .DDR_ba            (DDR_ba           ),
  .DDR_cas_n         (DDR_cas_n        ),
  .DDR_ck_n          (DDR_ck_n         ),
  .DDR_ck_p          (DDR_ck_p         ),
  .DDR_cke           (DDR_cke          ),
  .DDR_cs_n          (DDR_cs_n         ),
  .DDR_dm            (DDR_dm           ),
  .DDR_dq            (DDR_dq           ),
  .DDR_dqs_n         (DDR_dqs_n        ),
  .DDR_dqs_p         (DDR_dqs_p        ),
  .DDR_odt           (DDR_odt          ),
  .DDR_ras_n         (DDR_ras_n        ),
  .DDR_reset_n       (DDR_reset_n      ),
  .DDR_we_n          (DDR_we_n         ),
  // FCLKs
  .FCLK_CLK0         (fclk_clk[0]      ),
  .FCLK_CLK1         (fclk_clk[1]      ),
  .FCLK_CLK2         (fclk_clk[2]      ),
  .FCLK_CLK3         (fclk_clk[3]      ),
  .FCLK_RESET0_N     (fclk_rstn[0]     ),
  .FCLK_RESET1_N     (fclk_rstn[1]     ),
  .FCLK_RESET2_N     (fclk_rstn[2]     ),
  .FCLK_RESET3_N     (fclk_rstn[3]     ),
  // XADC
  .Vaux0_v_n (vinn_i[1]),  .Vaux0_v_p (vinp_i[1]),
  .Vaux1_v_n (vinn_i[2]),  .Vaux1_v_p (vinp_i[2]),
  .Vaux8_v_n (vinn_i[0]),  .Vaux8_v_p (vinp_i[0]),
  .Vaux9_v_n (vinn_i[3]),  .Vaux9_v_p (vinp_i[3]),
  .Vp_Vn_v_n (vinn_i[4]),  .Vp_Vn_v_p (vinp_i[4]),
  // GP0
  .M_AXI_GP0_ACLK    (axi_gp.ACLK   ),
//  .M_AXI_GP0_ARESETn (axi_gp.ARESETn),
  .M_AXI_GP0_arvalid (axi_gp.ARVALID),
  .M_AXI_GP0_awvalid (axi_gp.AWVALID),
  .M_AXI_GP0_bready  (axi_gp.BREADY ),
  .M_AXI_GP0_rready  (axi_gp.RREADY ),
  .M_AXI_GP0_wlast   (axi_gp.WLAST  ),
  .M_AXI_GP0_wvalid  (axi_gp.WVALID ),
  .M_AXI_GP0_arid    (axi_gp.ARID   ),
  .M_AXI_GP0_awid    (axi_gp.AWID   ),
  .M_AXI_GP0_wid     (axi_gp.WID    ),
  .M_AXI_GP0_arburst (axi_gp.ARBURST),
  .M_AXI_GP0_arlock  (axi_gp.ARLOCK ),
  .M_AXI_GP0_arsize  (axi_gp.ARSIZE ),
  .M_AXI_GP0_awburst (axi_gp.AWBURST),
  .M_AXI_GP0_awlock  (axi_gp.AWLOCK ),
  .M_AXI_GP0_awsize  (axi_gp.AWSIZE ),
  .M_AXI_GP0_arprot  (axi_gp.ARPROT ),
  .M_AXI_GP0_awprot  (axi_gp.AWPROT ),
  .M_AXI_GP0_araddr  (axi_gp.ARADDR ),
  .M_AXI_GP0_awaddr  (axi_gp.AWADDR ),
  .M_AXI_GP0_wdata   (axi_gp.WDATA  ),
  .M_AXI_GP0_arcache (axi_gp.ARCACHE),
  .M_AXI_GP0_arlen   (axi_gp.ARLEN  ),
  .M_AXI_GP0_arqos   (axi_gp.ARQOS  ),
  .M_AXI_GP0_awcache (axi_gp.AWCACHE),
  .M_AXI_GP0_awlen   (axi_gp.AWLEN  ),
  .M_AXI_GP0_awqos   (axi_gp.AWQOS  ),
  .M_AXI_GP0_wstrb   (axi_gp.WSTRB  ),
  .M_AXI_GP0_arready (axi_gp.ARREADY),
  .M_AXI_GP0_awready (axi_gp.AWREADY),
  .M_AXI_GP0_bvalid  (axi_gp.BVALID ),
  .M_AXI_GP0_rlast   (axi_gp.RLAST  ),
  .M_AXI_GP0_rvalid  (axi_gp.RVALID ),
  .M_AXI_GP0_wready  (axi_gp.WREADY ),
  .M_AXI_GP0_bid     (axi_gp.BID    ),
  .M_AXI_GP0_rid     (axi_gp.RID    ),
  .M_AXI_GP0_bresp   (axi_gp.BRESP  ),
  .M_AXI_GP0_rresp   (axi_gp.RRESP  ),
  .M_AXI_GP0_rdata   (axi_gp.RDATA  ),
  // AXI-4 streaming interfaces RX
  .S_AXI_STR_RX3_aclk    (sai[3].ACLK   ),  .S_AXI_STR_RX2_aclk    (sai[2].ACLK   ),  .S_AXI_STR_RX1_aclk    (sai[1].ACLK   ),  .S_AXI_STR_RX0_aclk    (sai[0].ACLK   ),
  .S_AXI_STR_RX3_arstn   (sai[3].ARESETn),  .S_AXI_STR_RX2_arstn   (sai[2].ARESETn),  .S_AXI_STR_RX1_arstn   (sai[1].ARESETn),  .S_AXI_STR_RX0_arstn   (sai[0].ARESETn),
  .S_AXI_STR_RX3_tdata   (sai[3].TDATA  ),  .S_AXI_STR_RX2_tdata   (sai[2].TDATA  ),  .S_AXI_STR_RX1_tdata   (sai[1].TDATA  ),  .S_AXI_STR_RX0_tdata   (sai[0].TDATA  ),
  .S_AXI_STR_RX3_tkeep   (sai[3].TKEEP  ),  .S_AXI_STR_RX2_tkeep   (sai[2].TKEEP  ),  .S_AXI_STR_RX1_tkeep   (sai[1].TKEEP  ),  .S_AXI_STR_RX0_tkeep   (sai[0].TKEEP  ),
  .S_AXI_STR_RX3_tlast   (sai[3].TLAST  ),  .S_AXI_STR_RX2_tlast   (sai[2].TLAST  ),  .S_AXI_STR_RX1_tlast   (sai[1].TLAST  ),  .S_AXI_STR_RX0_tlast   (sai[0].TLAST  ),
  .S_AXI_STR_RX3_tready  (sai[3].TREADY ),  .S_AXI_STR_RX2_tready  (sai[2].TREADY ),  .S_AXI_STR_RX1_tready  (sai[1].TREADY ),  .S_AXI_STR_RX0_tready  (sai[0].TREADY ),
  .S_AXI_STR_RX3_tvalid  (sai[3].TVALID ),  .S_AXI_STR_RX2_tvalid  (sai[2].TVALID ),  .S_AXI_STR_RX1_tvalid  (sai[1].TVALID ),  .S_AXI_STR_RX0_tvalid  (sai[0].TVALID ),
  // AXI-4 streaming interfaces TX
  .M_AXI_STR_TX3_aclk    (sao[3].ACLK   ),  .M_AXI_STR_TX2_aclk    (sao[2].ACLK   ),  .M_AXI_STR_TX1_aclk    (sao[1].ACLK   ),  .M_AXI_STR_TX0_aclk    (sao[0].ACLK   ),
  .M_AXI_STR_TX3_arstn   (sao[3].ARESETn),  .M_AXI_STR_TX2_arstn   (sao[2].ARESETn),  .M_AXI_STR_TX1_arstn   (sao[1].ARESETn),  .M_AXI_STR_TX0_arstn   (sao[0].ARESETn),
  .M_AXI_STR_TX3_tdata   (sao[3].TDATA  ),  .M_AXI_STR_TX2_tdata   (sao[2].TDATA  ),  .M_AXI_STR_TX1_tdata   (sao[1].TDATA  ),  .M_AXI_STR_TX0_tdata   (sao[0].TDATA  ),
  .M_AXI_STR_TX3_tkeep   (sao[3].TKEEP  ),  .M_AXI_STR_TX2_tkeep   (sao[2].TKEEP  ),  .M_AXI_STR_TX1_tkeep   (sao[1].TKEEP  ),  .M_AXI_STR_TX0_tkeep   (sao[0].TKEEP  ),
  .M_AXI_STR_TX3_tlast   (sao[3].TLAST  ),  .M_AXI_STR_TX2_tlast   (sao[2].TLAST  ),  .M_AXI_STR_TX1_tlast   (sao[1].TLAST  ),  .M_AXI_STR_TX0_tlast   (sao[0].TLAST  ),
  .M_AXI_STR_TX3_tready  (sao[3].TREADY ),  .M_AXI_STR_TX2_tready  (sao[2].TREADY ),  .M_AXI_STR_TX1_tready  (sao[1].TREADY ),  .M_AXI_STR_TX0_tready  (sao[0].TREADY ),
  .M_AXI_STR_TX3_tvalid  (sao[3].TVALID ),  .M_AXI_STR_TX2_tvalid  (sao[2].TVALID ),  .M_AXI_STR_TX1_tvalid  (sao[1].TVALID ),  .M_AXI_STR_TX0_tvalid  (sao[0].TVALID ),
  // IRQ
  // TODO: actual interrupts should be connnected
  .IRQ_GPIO (1'b0),
  .IRQ_LG   (1'b0),
  .IRQ_LA   (1'b0),
  .IRQ_GEN0 (1'b0),
  .IRQ_GEN1 (1'b0),
  .IRQ_SCP0 (1'b0),
  .IRQ_SCP1 (1'b0)
);

localparam int unsigned DN=2;

axi4_stream_if #(.DN (DN), .DAT_T (logic [8-1:0])) sai [4-1:0] (.ACLK (sti[0].clk), .ARESETn (sti[0].rstn));
axi4_stream_if #(.DN (DN), .DAT_T (logic [8-1:0])) sao [4-1:0] (.ACLK (sto[0].clk), .ARESETn (sto[0].rstn));

generate
for (genvar i=0; i<4; i++) begin: for_str

  // RX
//  for (genvar b=0; b<DN; b==b+DN) begin: for_byte_i
//  assign sai[i].TKEEP[DN*b+:DN] = {DN{sti[i].kep}};
//  end: for_byte_i
  assign sai[i].TKEEP           =    sti[i].kep;
  assign sai[i].TDATA           =    sti[i].dat;
  assign sai[i].TLAST           =    sti[i].lst;
  assign sai[i].TVALID          =    sti[i].vld;
  assign sti[i].rdy             =    sai[i].TREADY;

  // TX
//  for (genvar b=0; b<DN; b=b+DN) begin: for_byte_o
//  assign sto[i].kep           =   &sao[i].TKEEP[DN*b+:DN];
//  end: for_byte_o
  assign sto[i].kep           =   &sao[i].TKEEP ;
  assign sto[i].dat           =    sao[i].TDATA ;
  assign sto[i].lst           =    sao[i].TLAST ;
  assign sto[i].vld           =    sao[i].TVALID;
  assign sao[i].TREADY        =    sto[i].rdy;   

end: for_str
endgenerate

// since the PS GP0 port is AXI3 and the local bus is AXI4
assign axi_gp.AWREGION = '0;
assign axi_gp.ARREGION = '0;

endmodule
