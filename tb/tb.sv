// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "config.sv"
`include "tb_jtag_pkg.sv"


// include the uvm test class 
`include "uvm_macros.svh"
`include "tb_uvm_pkg.sv"        
  
`define REF_CLK_PERIOD   (2*15.25us)  // 32.786 kHz --> FLL reset value --> 50 MHz
`define CLK_PERIOD       10.00ns      // 100 MHz   

// write if you want to compare the memory or get an error when you have exceptions 
`define   MEMORY_COMPARE      

// write the memory size and location and the exception signl location
parameter int     MEM_SIZE         =     66846720;//16384;//   8192;     //  66846720;//                             //memory size for UVM FI tests
`define   MEMORY_PATH             tb.top_i.core_region_i.mem_gen.data_mem.sp_ram_i.mem;        //memory path for UVM FI tests
`define   EXCEPTION_SIGNAL_PATH        tb.top_i.core_region_i.CORE.RISCV_CORE.set_except_condition; //exception signal path for UVM FI tests, tutti i thread

`define   HARC_IF_PATH        tb.top_i.core_region_i.CORE.RISCV_CORE.harc_IF; //HARC signal path for UVM FI tests, thread 0
`define   HARC_ID_PATH        tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.Prg_Ctr.harc_ID; //HARC signal path for UVM FI tests, thread 0
`define   HARC_EXEC_PATH      tb.top_i.core_region_i.CORE.RISCV_CORE.harc_EXEC; //HARC signal path for UVM FI tests, thread 0
`define   HARC_WB_PATH        tb.top_i.core_region_i.CORE.RISCV_CORE.Pipe.RF.harc_WB //HARC signal path for UVM FI tests, thread 0
//SEGNALI PC DEI VARI HARC
`define   PC_PATH_0             tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.Prg_Ctr.pc[0] //PC signal path for UVM FI tests, thread 0
//`define   PC_PATH_1             tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.Prg_Ctr.pc[1] //PC signal path for UVM FI tests, thread 1
//`define   PC_PATH_2             tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.Prg_Ctr.pc[2] //PC signal path for UVM FI tests, thread 2
`define   PC_PATH_IE            tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.Pipe.pc_IE
`define   PC_PATH_WB            tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.Pipe.pc_WB
`define   REG_FILE_PATH         tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.Pipe.regfile[0]
`define   MTVEC_PATH            tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.CSR.MTVEC[0];
`define   MSTATUS_PATH          tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.CSR.MSTATUS[0];
`define   MCAUSE_PATH           tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.CSR.MCAUSE[0];
`define   MEPC_PATH             tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.CSR.MEPC[0];
`define   MIP_PATH              tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.CSR.MIP[0];
//SEGNALE DI CLOCK
`define   CLOCK_PATH            tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.clk_i;
//-------------------------------------------------------------------------------------------
//Segnali di memoria
`define   DATA_ADDR_PATH         tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.data_addr_o;
`define   DATA_WDATA_PATH        tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.data_wdata_o;
`define   DATA_RDATA_PATH        tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.data_rdata_i;
`define   DATA_WE_PATH           tb.top_i.core_region_i.CORE.RISCV_CORE.MORPH_inst.data_we_o;
//-------------------------------------------------------------------------------------------

`define EXIT_SUCCESS  0
`define EXIT_FAIL     1
`define EXIT_ERROR   -1


//---------------------------------------------------------------------------------------------------------------------------------------
/* si dichiara una interface che agisce da ponte fra il tb sv e quello uvm
 the signal is asserted when the execution of main sv tb is completed */

interface tb_sv2uvm_if(input clk );  //MODIFICO LA SENSITIVITY LIST IN MODO DA SVEGLIARE L'INTERFACCIA OGNI VOLTA CHE CAMBIA IL PC?             

   logic [3:0][7:0] mem_if [MEM_SIZE];
   bit set_except_condition_if;
   int harc_IF, harc_ID, harc_EXEC, harc_WB;
   logic is_sv_execution_completed = 1'b0; 
   logic sv_execution_repeat = 1'b1; 
   logic sv_execution_abort = 1'b0; 
   logic fault = 1'b0;
   logic my_control_bit = 1'b0;
   int results;
   reg [31:0] pc_0 ; //creare segnali simili per gli altri harc: dovranno essere assegnati più avanti
   reg [31:0] pc_1 ;
   reg [31:0] pc_2 ;
   reg [31:0][31:0] reg_file_0 ; //la seconda dimensione dipende da RF_SIZE
   reg [31:0] mtvec ;
   reg [31:0] mstatus ;
   reg [31:0] mcause ;
   reg [31:0] mepc ;
   reg [31:0] mip ;
   reg [31:0] addr;
   reg [31:0] wdata;
   reg [31:0] rdata;
   bit we;
   int ins_addr;
   string ins_name;
   string op1;
   string op2;
   string op3;
   logic clock;
   
             
  clocking cb @(posedge clk or negedge clk);  		// declaring a clocking block in order to synch all signals within the interface,
						// for a better    compatibility among interf and DUT
      input is_sv_execution_completed;
      input sv_execution_repeat;
      input sv_execution_abort;
      input fault;
      input my_control_bit;
      input pc_0;
      input pc_1; 
      input pc_2;
      input reg_file_0;
      input mtvec;
      input mstatus;
      input mcause;
      input mepc;
      input mip;
      input addr;
      input wdata;
      input rdata;
      input we;
      output results;
   endclocking
   //MODPORT: probabilmente non mi serviranno
   modport drv(clocking cb);                            // declaring a synch modport signal
   modport mnt( input fault, input is_sv_execution_completed, input sv_execution_repeat, input my_control_bit, input sv_execution_abort, output results,input pc_0,input harc_ID);
   modport acc( input mem_if, input set_except_condition_if );
   modport dynamic_tmr( input harc_IF, input harc_ID, input harc_EXEC, input harc_WB, output pc_0);
endinterface

//---------------------------------------------------------------------------------------------------------------------------------------

module tb;                                              // top module of UVM tb
  timeunit      1ns;                                    // timescal of pulpino tb - time ns
  timeprecision 1ps;
  genvar i;
  //---------------------------------------------------------------------------------------------------------------------------------------
  import uvm_pkg::*;              // import the uvm package
  import tb_uvm_pkg::*;           // import the new package defined in the separate file
  //---------------------------------------------------------------------------------------------------------------------------------------
        
  // +MEMLOAD= valid values are "SPI", "STANDALONE" "PRELOAD", "" (no load of L2)
  parameter  SPI            = "QUAD";    // valid values are "SINGLE", "QUAD"
  parameter  BAUDRATE       = 781250;    // 1562500
  parameter  CLK_USE_FLL    = 0;  // 0 or 1
  parameter  TEST           = ""; //valid values are "" (NONE), "DEBUG"
  parameter  USE_ZERO_RISCY = 0;
  parameter  USE_KLESSYDRA_T0_2TH = 0;
  parameter  USE_KLESSYDRA_T0_3TH = 0;
  parameter  USE_KLESSYDRA_T1_3TH = 0;
  parameter  USE_KLESSYDRA_M   = 0;
  parameter  USE_KLESSYDRA_S1     = 0;
  parameter  USE_KLESSYDRA_OOO    = 0;
  parameter  USE_KLESSYDRA_dfT1_M  = 0;
  parameter  USE_KLESSYDRA_fT1_3TH = 0;
  parameter  USE_KLESSYDRA_F0_3TH = 0;
  parameter  RISCY_RV32F    = 0;
  parameter  ZERO_RV32M     = 1;
  parameter  ZERO_RV32E     = 0;


  int           exit_status = `EXIT_ERROR; // modelsim exit code, will be overwritten when successful



  string        memload;
  logic         s_clk   = 1'b0;
  logic         s_rst_n = 1'b0;

  logic         fetch_enable = 1'b0;

  logic [1:0]   padmode_spi_master;
  logic         spi_sck   = 1'b0;
  logic         spi_csn   = 1'b1;
  logic [1:0]   spi_mode;
  logic         spi_sdo0;
  logic         spi_sdo1;
  logic         spi_sdo2;
  logic         spi_sdo3;
  logic         spi_sdi0;
  logic         spi_sdi1;
  logic         spi_sdi2;
  logic         spi_sdi3;

  logic         uart_tx;
  logic         uart_rx;
  logic         s_uart_dtr;
  logic         s_uart_rts;

  logic         scl_pad_i;
  logic         scl_pad_o;
  logic         scl_padoen_o;

  logic         sda_pad_i;
  logic         sda_pad_o;
  logic         sda_padoen_o;

  tri1          scl_io;
  tri1          sda_io;

  logic [31:0]  gpio_in = '0;
  logic [31:0]  gpio_dir;
  logic [31:0]  gpio_out;

  logic [31:0]  recv_data;
//INTERFACCIA
  //---------------------------------------------------------------------------------------------------------------------------------------
  /* instantiate the interface that is used a mean of communication between sv and UVM tbs, set as global - giving as input the s_clk from tb module */

  tb_sv2uvm_if tb_sv2uvm_if(s_clk);  

  `ifdef DYNAMIC_TMR
  assign tb_sv2uvm_if.dynamic_tmr.harc_IF = `HARC_IF_PATH;  
  assign tb_sv2uvm_if.dynamic_tmr.harc_ID = `HARC_ID_PATH;  
  assign tb_sv2uvm_if.dynamic_tmr.harc_EXEC = `HARC_EXEC_PATH;
  assign tb_sv2uvm_if.dynamic_tmr.harc_WB = `HARC_WB_PATH; 
  assign tb_sv2uvm_if.dynamic_tmr.pc = `PC_PATH_0;  
  `endif
  `ifdef MEMORY_COMPARE
  assign tb_sv2uvm_if.mem_if = `MEMORY_PATH;
  `endif
  `ifdef EXCEPTIONS_COMPARE
  assign tb_sv2uvm_if.set_except_condition_if = `EXCEPTION_SIGNAL_PATH;
  `endif

  //SEGNALI PC DEI VARI HARC
  assign tb_sv2uvm_if.pc_0[31:0] = `PC_PATH_IE; //0 //WB
  //assign tb_sv2uvm_if.pc_1[31:0] = `PC_PATH_1;
  //assign tb_sv2uvm_if.pc_2[31:0] = `PC_PATH_2;   
  assign tb_sv2uvm_if.harc_ID = `HARC_ID_PATH; 
  assign tb_sv2uvm_if.mtvec[31:0] = `MTVEC_PATH;
  assign tb_sv2uvm_if.mstatus[31:0] = `MSTATUS_PATH;
  assign tb_sv2uvm_if.mcause[31:0] = `MCAUSE_PATH;
  assign tb_sv2uvm_if.mepc[31:0] = `MEPC_PATH;
  assign tb_sv2uvm_if.mip[31:0] = `MIP_PATH;
  assign tb_sv2uvm_if.clock = `CLOCK_PATH;
  

  for (i=0; i<32; i++) begin
   assign tb_sv2uvm_if.reg_file_0[i][31:0] = `REG_FILE_PATH[i];
  end
  assign tb_sv2uvm_if.addr = `DATA_ADDR_PATH;
  assign tb_sv2uvm_if.rdata = `DATA_RDATA_PATH;
  assign tb_sv2uvm_if.wdata = `DATA_WDATA_PATH;
  assign tb_sv2uvm_if.we = `DATA_WE_PATH;
  
//TB GENERAL
  //---------------------------------------------------------------------------------------------------------------------------------------

  jtag_i jtag_if();

  adv_dbg_if_t adv_dbg_if = new(jtag_if);

  // use 8N1
  uart_bus
  #(
    .BAUD_RATE(BAUDRATE),
    .PARITY_EN(0)
  )
  uart
  (
    .rx         ( uart_rx ),
    .tx         ( uart_tx ),
    .rx_en      ( 1'b1    )
  );

  spi_slave
  spi_master();


  i2c_buf i2c_buf_i
  (
    .scl_io       ( scl_io       ),
    .sda_io       ( sda_io       ),
    .scl_pad_i    ( scl_pad_i    ),
    .scl_pad_o    ( scl_pad_o    ),
    .scl_padoen_o ( scl_padoen_o ),
    .sda_pad_i    ( sda_pad_i    ),
    .sda_pad_o    ( sda_pad_o    ),
    .sda_padoen_o ( sda_padoen_o )
  );

  i2c_eeprom_model
  #(
    .ADDRESS ( 7'b1010_000 )
  )
  i2c_eeprom_model_i
  (
    .scl_io ( scl_io  ),
    .sda_io ( sda_io  ),
    .rst_ni ( s_rst_n )
  );

  pulpino_top
  #(
    .USE_ZERO_RISCY          ( USE_ZERO_RISCY ),
    .USE_KLESSYDRA_T0_2TH    ( USE_KLESSYDRA_T0_2TH ),
    .USE_KLESSYDRA_T0_3TH    ( USE_KLESSYDRA_T0_3TH ),
    .USE_KLESSYDRA_T1_3TH    ( USE_KLESSYDRA_T1_3TH ),
    .USE_KLESSYDRA_F0_3TH    ( USE_KLESSYDRA_F0_3TH ),
    .RISCY_RV32F             ( RISCY_RV32F    ),
    .ZERO_RV32M              ( ZERO_RV32M     ),
    .ZERO_RV32E              ( ZERO_RV32E     )
   )
  top_i
  (
    .clk               ( s_clk        ),
    .rst_n             ( s_rst_n      ),

    .clk_sel_i         ( 1'b0         ),
    .testmode_i        ( 1'b0         ),
    .fetch_enable_i    ( fetch_enable ),

    .spi_clk_i         ( spi_sck      ),
    .spi_cs_i          ( spi_csn      ),
    .spi_mode_o        ( spi_mode     ),
    .spi_sdo0_o        ( spi_sdi0     ),
    .spi_sdo1_o        ( spi_sdi1     ),
    .spi_sdo2_o        ( spi_sdi2     ),
    .spi_sdo3_o        ( spi_sdi3     ),
    .spi_sdi0_i        ( spi_sdo0     ),
    .spi_sdi1_i        ( spi_sdo1     ),
    .spi_sdi2_i        ( spi_sdo2     ),
    .spi_sdi3_i        ( spi_sdo3     ),

    .spi_master_clk_o  ( spi_master.clk     ),
    .spi_master_csn0_o ( spi_master.csn     ),
    .spi_master_csn1_o (                    ),
    .spi_master_csn2_o (                    ),
    .spi_master_csn3_o (                    ),
    .spi_master_mode_o ( spi_master.padmode ),
    .spi_master_sdo0_o ( spi_master.sdo[0]  ),
    .spi_master_sdo1_o ( spi_master.sdo[1]  ),
    .spi_master_sdo2_o ( spi_master.sdo[2]  ),
    .spi_master_sdo3_o ( spi_master.sdo[3]  ),
    .spi_master_sdi0_i ( spi_master.sdi[0]  ),
    .spi_master_sdi1_i ( spi_master.sdi[1]  ),
    .spi_master_sdi2_i ( spi_master.sdi[2]  ),
    .spi_master_sdi3_i ( spi_master.sdi[3]  ),

    .scl_pad_i         ( scl_pad_i    ),
    .scl_pad_o         ( scl_pad_o    ),
    .scl_padoen_o      ( scl_padoen_o ),
    .sda_pad_i         ( sda_pad_i    ),
    .sda_pad_o         ( sda_pad_o    ),
    .sda_padoen_o      ( sda_padoen_o ),


    .uart_tx           ( uart_rx      ),
    .uart_rx           ( uart_tx      ),
    .uart_rts          ( s_uart_rts   ),
    .uart_dtr          ( s_uart_dtr   ),
    .uart_cts          ( 1'b0         ),
    .uart_dsr          ( 1'b0         ),

    .gpio_in           ( gpio_in      ),
    .gpio_out          ( gpio_out     ),
    .gpio_dir          ( gpio_dir     ),
    .gpio_padcfg       (              ),

    .tck_i             ( jtag_if.tck     ),
    .trstn_i           ( jtag_if.trstn   ),
    .tms_i             ( jtag_if.tms     ),
    .tdi_i             ( jtag_if.tdi     ),
    .tdo_o             ( jtag_if.tdo     )
  );

  generate
    if (CLK_USE_FLL) begin
      initial
      begin
        #(`REF_CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`REF_CLK_PERIOD/2) ~s_clk;
      end
    end else begin
      initial
      begin
        #(`CLK_PERIOD/2);
        s_clk = 1'b1;
        forever s_clk = #(`CLK_PERIOD/2) ~s_clk;
      end
    end
  endgenerate

  logic use_qspi;
        
  //-----------------------------------------------------------------------------------------------------------------------------------//
//TB UVM
   /* Inizio del tb uvm, bisognal salvare la virtual interface nel database utilizzando il comando set all'indirizzo *my_uvm_test con  	il nome tb_sv2uvm_if_vi, 
   dopodichè facciamo partire il test */

  initial 
     begin
                 
        uvm_config_db#(virtual tb_sv2uvm_if)::set(
                                                  uvm_root::get(), 
                                                  "*my_uvm_test",
                                                  "tb_sv2uvm_if_vi",
                                                  tb_sv2uvm_if
                                                  );  
        run_test("my_uvm_test");
  end
   

  /* Inizio del tb di controllo che si attiva quando il watchdog segnala una anomalia, ed è necessario abortire la simulazione corrente */
  initial
  begin
    do begin : control_loop        
      wait(tb_sv2uvm_if.sv_execution_abort === 1'b1);
      $display("HO FINITOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO",);
      tb_sv2uvm_if.sv_execution_abort = 1'b0;
  //      $fflush();

      disable pulpino_loop;          

      s_rst_n      = 1'b0;
      fetch_enable = 1'b0;

      #500ns;

      s_rst_n = 1'b1;
  
      $display("Test FAILED");
      $display("Release control to UVM  %0d", 1);
      $display("SV TB completed.");


  //      disable pulpino_loop;          
  //      #500ns;

      /* Salva il risultato della simulazione sul FF results, collegato ad UVM tramite interface*/
      tb_sv2uvm_if.results = 1;
      #10ns  

      tb_sv2uvm_if.is_sv_execution_completed=1'b1; // setto a 1 il segnale di comunicazione per indicare la fine del tb sv pulpino
      $display("WE");

    end
    while(1);
  end

  //-----------------------------------------------------------------------------------------------------------------------------------//
//TB PULPINO

  initial                       // pulpino tb initial      
  begin
    do begin : pulpino_loop        
    int i;
    //-----------------------------------------------------------------------------------------------------------------------------------//

    wait(tb_sv2uvm_if.sv_execution_repeat === 1'b0);
    #10
    tb_sv2uvm_if.is_sv_execution_completed=1'b0; // setto a 0 il segnale di comunicazione per indicare l inizio del tb sv pulpinos
    $display("STA COMINCIANDO TB_PULPINO");    
    //-----------------------------------------------------------------------------------------------------------------------------------//

    if(!$value$plusargs("MEMLOAD=%s", memload))
      memload = "PRELOAD";

    $display("Using MEMLOAD method: %s", memload);

    $display("Using %s core", USE_ZERO_RISCY ? "zero-riscy" : "ri5cy");

    use_qspi = SPI == "QUAD" ? 1'b1 : 1'b0;

    s_rst_n      = 1'b0;
    fetch_enable = 1'b0;

    #500ns;

    s_rst_n = 1'b1;

    #500ns;

    if (use_qspi)
      spi_enable_qpi();
    //////////////////////////////////////////////////////////////////////////////////////////////////

    if (memload != "STANDALONE")
    begin
      /* Configure JTAG and set boot address */
      adv_dbg_if.jtag_reset();
      adv_dbg_if.jtag_softreset();
      adv_dbg_if.init();
      adv_dbg_if.axi4_write32(32'h9A10_7008, 1, 32'h0000_0000);
    end

    if (memload == "PRELOAD")
    begin
      // preload memories
      mem_preload();
    end
    else if (memload == "SPI")
    begin
      spi_load(use_qspi);
      spi_check(use_qspi);
    end

    #200ns;
    fetch_enable = 1'b1;

    if(TEST == "DEBUG") begin
      debug_tests();
      $display("ENTRA NELLA PARTE SBAGLIATA");
    end else if (TEST == "DEBUG_IRQ") begin
      debug_irq_tests();
    end else if (TEST == "MEM_DPI") begin
      mem_dpi(4567);
      $display("ENTRA QUA");
    end else if (TEST == "ARDUINO_UART") begin
      if (~gpio_out[0])
        wait(gpio_out[0]);
      uart.send_char(8'h65);
    end else if (TEST == "ARDUINO_GPIO") begin
      // Here  test for GPIO Starts
      if (~gpio_out[0])
        wait(gpio_out[0]);

      gpio_in[4]=1'b1;

      if (~gpio_out[1])
        wait(gpio_out[1]);
      if (~gpio_out[2])
        wait(gpio_out[2]);
      if (~gpio_out[3])
        wait(gpio_out[3]);

      gpio_in[7]=1'b1;

    end else if (TEST == "ARDUINO_SHIFT") begin

      if (~gpio_out[0])
        wait(gpio_out[0]);
      //start TEST

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b1;
      if (gpio_out[4])
        wait(~gpio_out[4]);

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b1;
      if (gpio_out[4])
        wait(~gpio_out[4]);

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b0;
      if (gpio_out[4])
        wait(~gpio_out[4]);

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b0;
      if (gpio_out[4])
        wait(~gpio_out[4]);

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b1;
      if (gpio_out[4])
        wait(~gpio_out[4]);

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b0;
      if (gpio_out[4])
        wait(~gpio_out[4]);

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b0;
      if (gpio_out[4])
        wait(~gpio_out[4]);

      if (~gpio_out[4])
        wait(gpio_out[4]);
      gpio_in[3]=1'b1;
      if (gpio_out[4])
        wait(~gpio_out[4]);

    end else if (TEST == "ARDUINO_PULSEIN") begin
      if (~gpio_out[0])
        wait(gpio_out[0]);
      #50us;
      gpio_in[4]=1'b1;
      #500us;
      gpio_in[4]=1'b0;
      #1ms;
      gpio_in[4]=1'b1;
      #500us;
      gpio_in[4]=1'b0;
    end else if (TEST == "ARDUINO_INT") begin
      if (~gpio_out[0])
        wait(gpio_out[0]);
      #50us;
      gpio_in[1]=1'b1;
      #20us;
      gpio_in[1]=1'b0;
      #20us;
      gpio_in[1]=1'b1;
      #20us;
      gpio_in[2]=1'b1;
      #20us;
    end else if (TEST == "ARDUINO_SPI") begin
      for(i = 0; i < 2; i++) begin
        spi_master.wait_csn(1'b0);
        spi_master.send(0, {>>{8'h38}});
      end
    end



    // end of computation
    if (~gpio_out[8])
      wait(gpio_out[8]);

  
    spi_check_return_codes(exit_status);
  

  //  $fflush();

  //        #50000ns;
    #100ns
   // $stop();
//RELEASE CONTROL TO UVM      
  //-----------------------------------------------------------------------------------------------------------------------------------//
    $display("Release control to UVM  %0d", exit_status );

    /* Salva il risultato della simulazione sul FF results, collegato ad UVM tramite interface*/
    tb_sv2uvm_if.results = exit_status;

    /* quello che sto facendo e' sincronizzare le fasi uvm a quelle del tb sv di pulpino per evitare 
    che la simulazione termini alla fine del tb uvm, per fare questo utilizzo il segnale 
    is_sv_execution_completed per indicare l inizio e la fine del tb sv pulpino */

    tb_sv2uvm_if.is_sv_execution_completed=1'b1; // setto a 1 il segnale di comunicazione per indicare la fine del tb sv pulpino
  //-----------------------------------------------------------------------------------------------------------------------------------//

    $display("SV TB completed.");
    
  #10ns;
  end
  while(1);

  end

  // TODO: this is a hack, do it properly!
  `include "tb_spi_pkg.sv"
  `include "tb_mem_pkg.sv"
  `include "spi_debug_test.svh"
  `include "mem_dpi.svh"
  
endmodule
