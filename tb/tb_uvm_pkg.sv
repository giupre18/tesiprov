package tb_uvm_pkg;

timeunit      1ns;                                   // declaring the timescale in ns
timeprecision 1ns;//100ps;  //1ps normal
import uvm_pkg::*;
typedef int unsigned arr_t[38]; //32 registri + pc (ultimo elemento) + mtvec + mstatus + mcause + mepc + mip
//import "DPI-C" function void my_dpi_function (int data);
import "DPI-C" function void read_log_file();
//import "DPI-C" function void my_second_dpi_function (int data);
//import "DPI-C" function void send_return();
//import "DPI-C" function void send_exit();
//import "DPI-C" function void spawn_spike();
//import "DPI-C" function void remove_pipe();
import "DPI-C" function void return_registers(int num_inst, inout arr_t registers, inout int harc_ID, inout int instr_addr, output string instr_name, output string op1, output string op2, output string op3);
//import "DPI-C" function void write_command(string command);
//import "DPI-C" function int get_ack();
//import "DPI-C" function void lw_value(int valore);
import "DPI-C" function void spawn_and_run_spike_new(input string program_name, int num);
import "DPI-C" function void read_spike_log(input string filename);
//import "DPI-C" function void spawn_mem (input string program_name, int num_inst, int harc_id, int mem_addr);

parameter KLESS_NOME = "helloworld";
parameter int     NUM_INSTRUCTIONS = 10000;//10; //100 //1000// //10000 //helloworld inizia ad avere problemi a 240 (startup normale) o 300 (startup marcello)
`define Nome_file "my_log_file.txt"
//`define Nome_programma "random_test.elf"
  	//string Nome_programma = $sformatf("%s%s", KLESS_NOME, ".elf");
	//string Nome_programma = {$} (Nome_programma, ".elf");
	//string Nome_programma = {KLESS_NOME, ".elf"}; //usa questo
	string Nome_programma= "helloworld.elf";//"helloworld.elf";//"random_test.elf";

//ITEM CLASS
//Classe oggetto (anche chiamata package) che contiene le informazioni scambiate: pc e RF 
class my_item extends uvm_sequence_item;

	`uvm_object_utils(my_item)    // typical uvm macro
   int my_hartid;
   reg [31:0] my_pc_0;
   reg [31:0][31:0] my_reg_file_0 ; //la seconda dimensione dipende da RF_SIZE
	reg [31:0] my_mtvec;
	reg [31:0] my_mstatus;
	reg [31:0] my_mcause;
	reg [31:0] my_mepc;
	reg [31:0] my_mip;
	reg [31:0] my_mem_addr;
	reg [31:0] my_mem_wdata;
	reg [31:0] my_mem_rdata;
	bit we;
	int ins_addr;
   string ins_name;
   string op1;
   string op2;
   string op3;

   function new(string name="my_item"); // typical class constructor
		super.new(name);
	endfunction: new  
endclass : my_item

//SEQUENCER CLASS      //Non utilizzata
//Classe sequencer
class my_sequencer extends uvm_sequencer #(my_item);

	`uvm_component_utils(my_sequencer)
   virtual tb_sv2uvm_if my_tb_sv2uvm_if; //non gli servirebbe in realtà, ma la metto per poter usare una sequenza con il watchdog
	
	function new(string name="my_sequencer",uvm_component parent=null); 
   	super.new(name, parent);
   	$display("Creato sequencer");
   endfunction: new
   
   virtual function void build_phase (uvm_phase phase);
	super.build_phase (phase);
   endfunction
   
   task pre_body ();
   endtask: pre_body
   
   task print();
  	 $display("Print del sequencer");
   endtask: print
   
   virtual task run_phase (uvm_phase phase);
   	phase.raise_objection(this);
		super.run_phase(phase);	
		phase.drop_objection(this);
   endtask
endclass : my_sequencer

//SEQUENCE CLASS      //Non utilizzata
//Classe sequenza primaria, volendo si possono definire delle classi-sequenza derivate
class my_sequence extends uvm_sequence #(my_item);

   `uvm_object_utils(my_sequence)
   `uvm_declare_p_sequencer(my_sequencer)
   //my_item data_obj;
   //int unsigned n_times=17;
   
	function new(string name = "my_sequence");
   	super.new(name);
   endfunction

   task pre_body();
	//roba
   endtask: pre_body
  
   task body();
		$display("Corpo sequenza");
		/*
		repeat (n_times) begin
			my_item data_obj;
			data_obj = my_item::type_id::create("data_obj");
			start_item(data_obj);
			assert (data_obj.randomize());
			finish_item(data_obj);
			//wait_for_grant();
		end
	*/
	$display("Fine sequenza");
   endtask: body
  
   task post_body();
   endtask: post_body
endclass : my_sequence

//REPEAT SEQUENCE CLASS    //Non utilizzata   
//Classe sequenza madre, serve a ripetere le sequenze, volendo si possono definire delle classi-sequenza derivate
class my_rep_sequence extends uvm_sequence #(my_item);

   `uvm_object_utils(my_rep_sequence)
 	`uvm_declare_p_sequencer(my_sequencer)
   
	function new(string name = "my_rep_sequence");
   	super.new(name);
   endfunction : new

   task pre_body();
   endtask: pre_body
  
   task automatic my_watchdog();
   endtask: my_watchdog

   virtual task body();
		begin
			//$display("CORPO SEQUENZA MADRE:");
			my_sequence sequenzaA= my_sequence::type_id::create("sequenzaA");
			my_sequence sequenzaB= my_sequence::type_id::create("sequenzaB");
			uvm_status_container status_container;
			$display("Corpo sequenza madre, lancia figlia A:");
			sequenzaA.start(p_sequencer);
			//$display("Corpo sequenza madre, lancia figlia B:");
			//sequenzaB.start(p_sequencer);
			$display("Fine sequenza madre");
		end 
	endtask: body
  
   task post_body();
   endtask: post_body
endclass : my_rep_sequence

//MONITOR CLASS
//Classe monitor
class my_monitor extends uvm_monitor; 

	`uvm_component_utils(my_monitor)
	virtual tb_sv2uvm_if my_tb_sv2uvm_if;
	uvm_analysis_port #(my_item) my_port;
	my_item data_to_send;

	function new(string name="my_monitor", uvm_component parent= null); 
		super.new(name, parent);
		$display("Creato monitor");
	endfunction: new

	virtual function void build_phase (uvm_phase phase);
		super.build_phase (phase);
		my_port =new ("my_port", this);
	endfunction

	task print();
  		int elemento;
		$display("Print del monitor");
		$display("mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
		$display("Harc_ID: %0d at %0t ps", my_tb_sv2uvm_if.harc_ID, $time);
		$display("Pc_0: %x ", my_tb_sv2uvm_if.pc_0);
   	$display("Pc_1: %x ", my_tb_sv2uvm_if.pc_1);
   	$display("Pc_2: %x ", my_tb_sv2uvm_if.pc_2);
   	$display("mtvec: %x ", my_tb_sv2uvm_if.mtvec);
   	$display("mstatus: %x ", my_tb_sv2uvm_if.mstatus);
   	$display("mcause: %x ", my_tb_sv2uvm_if.mcause);
   	$display("mepc: %x ", my_tb_sv2uvm_if.mepc);
   	$display("mip: %x ", my_tb_sv2uvm_if.mip);
   	$display("addr: %x ", my_tb_sv2uvm_if.addr);
   	$display("wdata: %x ", my_tb_sv2uvm_if.wdata);
   	$display(".............................................",);
   	for (int i=31; i>=0; i--) begin
   		$display("RF %0d: %x ",i, my_tb_sv2uvm_if.reg_file_0[i]);
   	end
		$display("mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm");
	endtask: print

	task check_pc(); //Utilizzata per stampare il pc_IE di Klessydra corrente
		$display("Pc_IE: %x at %0t ps", my_tb_sv2uvm_if.pc_0, $time); //Ho tolto l'Harc perchè tanto ne uso solo uno
	endtask:check_pc

	task save_status(); //Salva lo stato di Klessydra 
		data_to_send= my_item::new();
		data_to_send.my_hartid=my_tb_sv2uvm_if.harc_ID;
		data_to_send.my_pc_0=my_tb_sv2uvm_if.pc_0;
		data_to_send.my_mtvec=my_tb_sv2uvm_if.mtvec;
		data_to_send.my_mstatus=my_tb_sv2uvm_if.mstatus;
		data_to_send.my_mcause=my_tb_sv2uvm_if.mcause;
		data_to_send.my_mepc=my_tb_sv2uvm_if.mepc;
		data_to_send.my_mip=my_tb_sv2uvm_if.mip;
		data_to_send.ins_addr=my_tb_sv2uvm_if.ins_addr;
		data_to_send.ins_name=my_tb_sv2uvm_if.ins_name;
		data_to_send.op1=my_tb_sv2uvm_if.op1;
		data_to_send.op2=my_tb_sv2uvm_if.op2;
		data_to_send.op3=my_tb_sv2uvm_if.op3;
		data_to_send.my_mem_addr=my_tb_sv2uvm_if.addr;
		data_to_send.my_mem_rdata=my_tb_sv2uvm_if.rdata;
		data_to_send.my_mem_wdata=my_tb_sv2uvm_if.wdata;
		data_to_send.we=my_tb_sv2uvm_if.we;
		for (int i=31; i>=0; i--) begin
   		data_to_send.my_reg_file_0[i]= my_tb_sv2uvm_if.reg_file_0[i];
   	end
	endtask : save_status

	task send_to_scoreboard();
		my_port.write(data_to_send);
	endtask:send_to_scoreboard

	virtual task run_phase (uvm_phase phase);
		phase.raise_objection(this);
		super.run_phase(phase);	
		phase.drop_objection(this);
  	endtask
endclass : my_monitor

//DRIVER CLASS       //Non utilizzata
//Classe driver
class my_driver extends uvm_driver #(my_item); 

	`uvm_component_utils(my_driver)
   virtual tb_sv2uvm_if my_tb_sv2uvm_if;

   function new(string name="my_driver", uvm_component parent= null); 
		super.new(name, parent);
      $display("Creato driver");
   endfunction: new
   
   virtual function void build_phase (uvm_phase phase);
		super.build_phase (phase);
   endfunction: build_phase
 
	virtual task run_phase (uvm_phase phase);
   	my_item data_obj;
    	phase.raise_objection(this);
		super.run_phase(phase);
		//$display("run phase del driver");
		forever begin
			seq_item_port.try_next_item(data_obj);
			if (data_obj==null) begin
				break;
			end
			drive_item(data_obj);
			seq_item_port.item_done();	
		end
		phase.drop_objection(this);
	endtask

   virtual task drive_item (my_item data_obj);	
		$display("Invio dati ricevuti dal sequencer: 0x%h", data_obj);
   endtask: drive_item
   
   task print ();
		$display("Print del driver");
   endtask: print
endclass : my_driver

//AGENT CLASS      
//Classe Agente
class my_agent extends uvm_agent; 

   `uvm_component_utils(my_agent)
   virtual tb_sv2uvm_if my_tb_sv2uvm_if_agent;
	my_monitor monitor1;
   //my_driver driver1;
   my_sequencer sequencer1;
   
   function new(string name="my_agent", uvm_component parent=null); 
      super.new(name,parent);
      $display("Creato agente");
   endfunction: new

   virtual function void build_phase (uvm_phase phase);
		super.build_phase (phase);
  		monitor1=my_monitor::type_id::create("monitor1", this); 
   	monitor1.my_tb_sv2uvm_if=my_tb_sv2uvm_if_agent;
   	//driver1=my_driver::type_id::create("driver1", this);
   	//driver1.my_tb_sv2uvm_if=my_tb_sv2uvm_if_agent;
   	sequencer1=my_sequencer::type_id::create("sequencer1", this);
   endfunction

   virtual task run_phase (uvm_phase phase);
  		phase.raise_objection(this);
		super.run_phase(phase);	
		//$display("run phase dell'agente");
   	phase.drop_objection(this);
   endtask  
endclass : my_agent

//SCOREBOARD CLASS
class my_scoreboard extends uvm_scoreboard;

	`uvm_component_utils(my_scoreboard)
	uvm_analysis_imp #(my_item, my_scoreboard) ap_imp;
   my_item captured_trans_k;

   function new (string name ="my_scoreboard", uvm_component parent);
		super.new(name, parent);
		$display("Creata scoreboard");
		captured_trans_k= my_item::new();
   endfunction: new
	
	function void build_phase (uvm_phase phase);
   	phase.raise_objection(this);  
		super.build_phase (phase);
		ap_imp = new ("ap_imp", this); //ap= analysis port
		phase.drop_objection(this);  
   endfunction: build_phase
	
	virtual function void write (my_item data);
	   captured_trans_k=data;
   endfunction: write

	virtual function void show_from_monitor(my_item captured_trans);
	   $display("=================%0t=====================", $time);
	   $display("Scoreboard: Harc ID - %d ", captured_trans.my_hartid);
	   $display("Scoreboard: PC - %0x ", captured_trans.my_pc_0);
	   for (int i=0; i<32; i++) begin
   		$display("Scoreboard: RF %0d: %x ",i, captured_trans.my_reg_file_0[i]);
   	end
   	$display("Scoreboard: MTVEC - %0x ", captured_trans.my_mtvec);
   	$display("Scoreboard: MSTATUS - %0x ", captured_trans.my_mstatus);
   	$display("Scoreboard: MCAUSE - %0x ", captured_trans.my_mcause);
   	$display("Scoreboard: MEPC - %0x ", captured_trans.my_mepc);
   	$display("Scoreboard: MIP - %0x ", captured_trans.my_mip);
   	$display("=============================================="); //8= //Mostro l'item di Klessydra
   endfunction: show_from_monitor

   virtual function void show(my_item data);
	   $display("=================%0t=====================", $time);
	   $display("HARC_ID: %d ", data.my_hartid);
	   $display("     PC: %0x (%0x) %s \t%s, %s, %s", data.my_pc_0, data.ins_addr, data.ins_name, data.op1, data.op2, data.op3);

	   for (int i=0; i<32; i++) begin
   		$display("RF %0d: %x ",i, data.my_reg_file_0[i]);
   	end
   	$display("..............................................");
   	$display("MTVEC: %0x ", data.my_mtvec);
	   $display("MSTATUS: %0x ", data.my_mstatus);
	   $display("MCAUSE: %0x ", data.my_mcause);
	   $display("MEPC: %0x ", data.my_mepc);
	   $display("MIP: %0x ", data.my_mip);
   	$display("=============================================="); //8= //Mostro un item (sarà quello di Spike)
   endfunction: show

  function void connect_phase(uvm_phase phase); 
  		super.connect_phase (phase); 
  endfunction: connect_phase
	
	virtual function int check_spike (my_item data_from_spike, my_item data_from_kless); //Faccio il confronto fra Spike e Klessydra
	   bit check_bit =0;
	   //$display("Scoreboard: confronto con spike a %0t ps ",$time);
	   if(data_from_kless.my_pc_0===data_from_spike.my_pc_0) begin
	   end
	   else begin 
	    	check_bit=1;
	   end
	   if(data_from_kless.my_hartid==data_from_spike.my_hartid) begin
	   end
	   else begin 
	    	check_bit=1;
	   end
	   if(data_from_kless.my_mtvec===data_from_spike.my_mtvec) begin
	   end
	   else begin 
	    	check_bit=1;
	   end
	   if(data_from_kless.my_mcause===data_from_spike.my_mcause) begin
	   end
	   else begin 
	    	check_bit=1;
	   end
	   if(data_from_kless.my_mstatus===data_from_spike.my_mstatus) begin
	   end
	   else begin 
	    	//check_bit=1; ////RANDOM_TEST
	   end
	   if(data_from_kless.my_mepc===data_from_spike.my_mepc) begin
	   end
	   else begin 
	    	check_bit=1;
	   end
	   if(data_from_kless.my_mip===data_from_spike.my_mip) begin
	   end
	   else begin 
	    //Lo tolgo solo per il momento, sembra che klessydra ce lo abbia fisso a zero
	    //	check_bit=1;
	   end
	   
	   for (int i=31; i>=0; i--) begin
	  		if(data_from_kless.my_reg_file_0[i]===data_from_spike.my_reg_file_0[i]) begin
	   	end
	   	else begin
	   		if (data_from_kless.my_reg_file_0[i]===32'hxxxxxxxx && data_from_spike.my_reg_file_0[i]===32'h00000000) begin
	   		end
	   		else begin
	   			check_bit=1;
	   		end
	  		end
	   end
	   if(check_bit===1) begin
	   	show_difference(data_from_spike, data_from_kless);
	   	return(1);
	   end
	   else begin
	   	$display("Confronto passato! Pc: %08x, %s %s %s %s", data_from_spike.my_pc_0, data_from_spike.ins_name, data_from_spike.op1, data_from_spike.op2, data_from_spike.op3);
	   	return(0);
	   end
	endfunction: check_spike

   function void show_difference(my_item data, my_item datab);
   	$display("==============================================");
   	$display("Warning! Differenze trovate:");
	   $display("=================%0t=====================", $time);
	   $display("Istruzione di indirizzo 0x%08x: %s %s %s %s", data.ins_addr, data.ins_name, data.op1, data.op2, data.op3);
	   if (data.my_pc_0 !== datab.my_pc_0) begin
	   	$display("!\tPC:     %08x(Spike) vs %08x (Klessydra)", data.my_pc_0, datab.my_pc_0);	
	   end
	   else begin
	   	$display("PC (uguale): %08x", data.my_pc_0);
	   end
		//$display("PC:     %0x       (Spike) vs %0x (Klessydra)", data.my_pc_0, captured_trans_k.my_pc_0);	
	   for (int i=0; i<32; i++) begin
	   	//&& (data.my_reg_file_0[i]!==32'h00000000 && captured_trans_k.my_reg_file_0[i]!==32'hxxxxxxxx )
	  		if(data.my_reg_file_0[i]!== datab.my_reg_file_0[i])begin
	  		$display("!\tRF %0d: %x (Spike) vs %x (Klessydra)",i, data.my_reg_file_0[i], datab.my_reg_file_0[i]);	
	  		end
	  		else begin
	  		$display("RF %0d: %x (Spike) vs %x (Klessydra)",i, data.my_reg_file_0[i], datab.my_reg_file_0[i]);	
	  		end
	  		
   	end
   	$display("..............................................");
   	if (data.my_hartid !== datab.my_hartid) begin
	   	$display("!\tHARC_ID: %0d(Spike) vs %0d (Klessydra)", data.my_hartid, datab.my_hartid);	
	   end
	   else begin
	   	$display("HARC_ID: %0d(Spike) vs %0d (Klessydra)", data.my_hartid, datab.my_hartid);
	   end
	   if (data.my_mtvec !== datab.my_mtvec) begin
	   	$display("!\tMTVEC:  %08x(Spike) vs %08x (Klessydra)", data.my_mtvec, datab.my_mtvec);	
	   end
	   else begin
	   	$display("MTVEC:  %08x(Spike) vs %08x (Klessydra)", data.my_mtvec, datab.my_mtvec);
	   end
	   if (data.my_mstatus !== datab.my_mstatus) begin
	   	$display("!\tMSTATUS:%08x(Spike) vs %08x (Klessydra)", data.my_mstatus, datab.my_mstatus);	
	   end
	   else begin
	   	$display("MSTATUS:%08x(Spike) vs %08x (Klessydra)", data.my_mstatus, datab.my_mstatus);
	   end
	   if (data.my_mcause !== datab.my_mcause) begin
	   	$display("!\tMCAUSE: %08x(Spike) vs %08x (Klessydra)", data.my_mcause, datab.my_mcause);	
	   end
	   else begin
	   	$display("MCAUSE: %08x(Spike) vs %08x (Klessydra)", data.my_mcause, datab.my_mcause);
	   end
	   if (data.my_mepc !== datab.my_mepc) begin
	   	$display("!\tMEPC:   %08x(Spike) vs %08x (Klessydra)", data.my_mepc, datab.my_mepc);	
	   end
	   else begin
	   	$display("MEPC:   %08x(Spike) vs %08x (Klessydra)", data.my_mepc, datab.my_mepc);	
	   end
	   if (data.my_mip !== datab.my_mip) begin
	   	$display("!\tMIP:    %08x(Spike) vs %08x (Klessydra)", data.my_mip, datab.my_mip);	
	   end
	   else begin
	   	$display("MIP:    %08x(Spike) vs %08x (Klessydra)", data.my_mip, datab.my_mip);
	   end
   	$display("=============================================="); // //Stampo le differenze fra Spike e Klessydra
   endfunction : show_difference

   virtual task run_phase (uvm_phase phase);
   endtask: run_phase

   function int check_mem(input reg[31:0] s_addr, input reg[31:0] s_content, input reg[31:0] k_addr, input reg[31:0] k_data, input bit we);
   	 if (!we) begin
      	$display("Write Back non abilitato!");
      	return 1;
      end
      else begin
      	if (s_addr===k_addr && s_content===k_data) begin
      		$display("Confronto memoria passato!");
      		return 0;
      	end
      	else begin
      		$display("Accesso in memoria differente! \nIndirizzo: %08x (Spike) vs %08x (Klessydra) \nDati: %08x (Spike) vs %08x (Klessydra)",s_addr, k_addr, s_content, k_data);
      		return 1;
      	end
      end
   endfunction : check_mem
   
   virtual function void check_phase (uvm_phase phase);
   endfunction: check_phase
endclass : my_scoreboard

//SPIKE CLASS
//Classe wrapper che contiene spike
class my_spike extends uvm_monitor;

   `uvm_component_utils(my_spike)  
	//uvm_analysis_port #(my_item) my_spike_port;
  	my_item data_to_send;

	function new(string name="my_spike", uvm_component parent= null); // typical class constructor
		super.new(name, parent);
		$display("Creato wrapper spike");
	endfunction: new  

	virtual function void build_phase (uvm_phase phase);
		super.build_phase (phase);
		//my_spike_port =new ("my_spike_port", this);
	endfunction: build_phase


	function void read_output_spike();
		read_spike_log(`Nome_file);
	endfunction: read_output_spike 

	task spawn_ISS();
    spawn_and_run_spike_new(Nome_programma, NUM_INSTRUCTIONS);
	endtask: spawn_ISS

	function string remove_char(string str, string char_to_remove); // Function to remove a character from a string
   	string result_str;
   	for (int i = 0; i < str.len(); i++) begin
        if (str.substr(i, i) != char_to_remove) begin
            result_str = {result_str, str.substr(i, i)};
        end
   	end
   	return result_str;
	endfunction: remove_char
 /*
   function reg [31:0] convert_to_packed(int unsigned unpacked[0:31]);
   	reg [31:0] temp_packed;
   	for (int i = 0; i < 32; i++) begin
      	temp_packed[i] = unpacked[i];
      end
    	return temp_packed;
   endfunction: convert_to_packed
 */
 	function int convert_reg_name_to_number(string reg_name); // Function to convert register name to its corresponding number
   	int reg_num;
   	/*
   	static int reg_map[string] = {
      	"zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4, "t0": 5, "t1": 6, "t2": 7,
     		 "s0": 8, "s1": 9, "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15,
    	 	"a6": 16, "a7": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
      	"s8": 24, "s9": 25, "s10": 26, "s11": 27, "t3": 28, "t4": 29, "t5": 30, "t6": 31
  		  };
  		*/
  		if (string_contains(reg_name, "zero")) begin
  			reg_num=0; 	
  		end
  		else if (string_contains(reg_name, "ra")) begin
  		 	reg_num=1;
  		end
  		else if (string_contains(reg_name, "sp")) begin
  		 	reg_num=2;
  		end
  		else if (string_contains(reg_name, "gp")) begin
  		 	reg_num=3;
  		end
  		else if (string_contains(reg_name, "tp")) begin
  		 	reg_num=4;
  		end
  		else if (string_contains(reg_name, "t0")) begin
  		 	reg_num=5;
  		end
  		else if (string_contains(reg_name, "t1")) begin
  		 	reg_num=6;
  		end
  		else if (string_contains(reg_name, "t2")) begin
  		 	reg_num=7;
  		end
  		else if (string_contains(reg_name, "s0")) begin
  		 	reg_num=8;
  		end
  		else if (string_contains(reg_name, "s1")) begin
  		 	reg_num=9;
  		end
  		else if (string_contains(reg_name, "a0")) begin
  		 	reg_num=10;
  		end
  		else if (string_contains(reg_name, "a1")) begin
  		 	reg_num=11;
  		end
  		else if (string_contains(reg_name, "a2")) begin
  		 	reg_num=12;
  		end
  		else if (string_contains(reg_name, "a3")) begin
  		 	reg_num=13;
  		end
  		else if (string_contains(reg_name, "a4")) begin
  		 	reg_num=14;
  		end
  		else if (string_contains(reg_name, "a5")) begin
  		 	reg_num=15;
  		end
  		else if (string_contains(reg_name, "a6")) begin
  		 	reg_num=16;
  		end
  		else if (string_contains(reg_name, "a7")) begin
  		 	reg_num=17;
  		end
  		else if (string_contains(reg_name, "s2")) begin
  		 	reg_num=18;
  		end
  		else if (string_contains(reg_name, "s3")) begin
  		 	reg_num=19;
  		end
  		else if (string_contains(reg_name, "s4")) begin
  		 	reg_num=20;
  		end
  		else if (string_contains(reg_name, "s5")) begin
  		 	reg_num=21;
  		end
  		else if (string_contains(reg_name, "s6")) begin
  		 	reg_num=22;
  		end
  		else if (string_contains(reg_name, "s7")) begin
  		 	reg_num=23;
  		end
  		else if (string_contains(reg_name, "s8")) begin
  		 	reg_num=24;
  		end
  		else if (string_contains(reg_name, "s9")) begin
  		 	reg_num=25;
  		end
  		else if (string_contains(reg_name, "s10")) begin
  		 	reg_num=26;
  		end
  		else if (string_contains(reg_name, "s11")) begin
  		 	reg_num=27;
  		end
  		else if (string_contains(reg_name, "t3")) begin
  		 	reg_num=28;
  		end
  		else if (string_contains(reg_name, "t4")) begin
  		 	reg_num=29;
  		end
  		else if (string_contains(reg_name, "t5")) begin
  		 	reg_num=30;
  		end
  		else if (string_contains(reg_name, "t6")) begin
  		 	reg_num=31;
  		end
  		else begin
  			$display("Registro non valido!");
  		 	return -1;
  		end
   	
   	//if (!reg_map.exists(reg_name)) begin
    	//  return -1; // Return -1 for invalid register names
   	// end
 		//reg_num = reg_map[reg_name];
   	return reg_num;
  	endfunction: convert_reg_name_to_number

	function my_item read_item(int num_inst); 
		arr_t my_rf;
		int harc_ID;
		int instr_addr;
		string instr_name=new[20];
		string op1=new[10];
		string op2=new[10];
		string op3=new[10];
		data_to_send= my_item::new(); 
		//data_to_send.my_pc_0= 32'bx; //registro tutto nullo
		return_registers(num_inst, my_rf, harc_ID, instr_addr, instr_name, op1, op2, op3); //num_inst è il numero dell'istruzione da leggere (prima, seconda, terza...)
		data_to_send.my_hartid=harc_ID;
		data_to_send.ins_name=instr_name;
		data_to_send.ins_addr=instr_addr;
		data_to_send.op1=op1;
		data_to_send.op2=op2;
		data_to_send.op3=op3;
		for (int i=0; i<=31; i++) begin
   		data_to_send.my_reg_file_0[i]= my_rf[i];
   	end
   	data_to_send.my_pc_0= my_rf[32]; //il program counter è l'ultimo elemento dell'array
   	data_to_send.my_mtvec= my_rf[33];
   	data_to_send.my_mstatus= my_rf[34];
   	data_to_send.my_mcause= my_rf[35];
   	data_to_send.my_mepc= my_rf[36];
   	data_to_send.my_mip= my_rf[37];
   	return data_to_send;//LEGGO IL LOGFILE IN C
	endfunction: read_item

	function bit string_contains(string str, string substr);
    int str_len = str.len();
    int substr_len = substr.len();
    int i, j;

    for (i = 0; i <= str_len - substr_len; i++) begin
        for (j = 0; j < substr_len; j++) begin
            if (str.getc(i + j) != substr.getc(j)) begin
                break;
            end
        end
        if (j == substr_len) return 1; // Substring found
    end
    return 0; // Substring not found
	endfunction: string_contains

	function my_item get_item(int block_num); //LEGGO IL LOGFILE DA UVM
   	my_item item = new();
   	int file;
   	string line;
   	int block_count = 0;
   	int reg_index;
   	reg [31:0] reg_value;
   	//reg [31:0] temp_value; // Temporary variable for converted values

   	file = $fopen(`Nome_file, "r");
   	if (file == 0) begin
        $display("Failed to open the file");
        return null;
    	end

    	while (!$feof(file)) begin
      	void'($fgets(line, file));
        		if (string_contains(line,"core") && !string_contains(line, "core   0: >>>>")) begin // Detect the start of a new block
            	block_count++;
        		end

        		if (block_count == block_num) begin
            	if (string_contains(line, "core")&& !string_contains(line, "core   0: >>>>")) begin
               	 void'($sscanf(line, "core %d: 0x%x (%x) %19s %9s %9s ", item.my_hartid, item.my_pc_0, item.ins_addr, item.ins_name, item.op1, item.op2, item.op3));
            	end 
            	else if (string_contains(line, "X[")) begin
               	 void'($sscanf(line, "X[%x] = 0x%x", reg_index, reg_value));
                	item.my_reg_file_0[reg_index] = reg_value;
            	end 
            	else if (string_contains(line, "mtvec:")) begin
               	 void'($sscanf(line, "mtvec: 0x%x", item.my_mtvec));
               end
            	else if (string_contains(line, "mstatush:")) begin
               	 void'($sscanf(line, "mstatush: 0x%x", item.my_mstatus));
            	end
            	else if (string_contains(line, "mcause:")) begin
               	 void'($sscanf(line, "mcause: 0x%x", item.my_mcause));
            	end
            	else if (string_contains(line, "mepc:")) begin
               	 void'($sscanf(line, "mepc: 0x%x", item.my_mepc));
            	end
            	else if (string_contains(line, "mip:")) begin
               	 void'($sscanf(line, "mip: 0x%x", item.my_mip));
            	end
        		end
        		if (block_count > block_num) begin
            	break;
        		end
      	//end
    	end
    	$fclose(file);
    	return item;
	endfunction : get_item

 	function int calculate_address(my_item data, string addr_str);
   	int base_num = 0;
   	string reg_name;
   	int reg_num;
   	int address;
   	if (string_contains(addr_str,"(")) begin // Check if there's a number before the parenthesis
      	void'($sscanf(addr_str, "%d(%s)", base_num, reg_name));
   	end
   	else begin
      	reg_name = addr_str;
   	end
   	reg_name = remove_char(reg_name, ")"); // Removing ')' from the register name if present
   	$display("Used register %s", reg_name);
    	reg_num = convert_reg_name_to_number(reg_name);     // Convert register name to number
		if (reg_num == -1) begin
     		`uvm_error("MY_ENV", $sformatf("Invalid register name: %s", reg_name))
      	return -1;
    	end
   	address = base_num + data.my_reg_file_0[reg_num]; // Calculate the address
   	$display("address: %x, base num: %0d, content of register: %x",address, base_num, data.my_reg_file_0[reg_num]);
    	return address;
  endfunction: calculate_address

	function string int_to_hex_string(int value);
   	 return $sformatf("%0h", value);
	endfunction

	function void get_mem_content(int num, int address); //Leggo il log della memoria //DEPRECATED
   	int file;
   	int index=0;
   	string line;
   	bit found=0;
   	string addr= int_to_hex_string(address);
   	string addr_found;
   	$display("Address used to get mem_content: %s",addr);
   	file = $fopen("my_file_sw.txt", "r"); 
   	if (file == 0) begin
        $display("Failed to open the mem file");
    	end
    	while (!$feof(file)) begin
      	void'($fgets(line, file));
      	if (string_contains(line, "SW_addr=")) begin
      		index=index+1;
      	end
      	if (index==num) begin
      		if (string_contains(line,"content")) begin
        			//$display("Found: %s", line.substr(line.itoa(line.index(search_str) + search_str.len()), line.len()-1));
        			$display("Found: %s", line);
       			found=1;
       			break;
       		end
       	end
        	
      end  	
      if (!found) begin
      	$display("Address '%08x' not found in the file.", address);
   	end
    	$fclose(file);
	endfunction : get_mem_content

	function void get_sw_content(int num, output reg[31:0] s_addr, output reg[31:0] s_data);
		int file;
   	int index=0;
   	string line;
   	bit success;
   	integer r;
    	reg[31:0] addr;
    	reg[31:0] content;

   	file = $fopen("my_file_sw.txt", "r"); 
   	if (file == 0) begin
        $display("Failed to open the mem file");
    	end
    	while (!$feof(file)) begin
      	void'($fgets(line, file));
      	if (string_contains(line, "SW_addr=")) begin
      		index=index+1;
      	end
      	if (index==num) begin
       		if (string_contains(line, "SW_addr=")) begin
       			r = $sscanf(line, "SW_addr=%x\n", addr);
       		end
       		else if (string_contains(line, "content")) begin
       			r = $sscanf(line, "content: %x",content);
      	 	end
      	 	else begin
      	 		$display("Formato righe file di memoria errato!",);
    	     end     		
       	end
       	else if (index>num) begin
       		break;
       	end
      end  	
      s_addr=addr; //assegno alle variabili di uscita
      s_data=content; 
     // $display("Indirizzo: %08x, Contenuto: %08x", addr, content);
    	$fclose(file);
	endfunction : get_sw_content
endclass : my_spike

//TEST CLASS       
// La classe Test è la classe che instanzia componenti ed oggetti nella build phase, e lancia sequenze nella run phase
class my_uvm_test extends uvm_test;

   `uvm_component_utils(my_uvm_test)            // typical uvm macro
   virtual tb_sv2uvm_if m_tb_sv2uvm_if;              // define the data member m_tb_sv2uvm_if
   my_agent agent1;
   my_scoreboard scoreboard1;
   my_spike spike1;
   reg [31:0] pc_prev;
   reg [31:0] pc_start;
   reg [31:0] pc_spike_saved;
   reg [31:0] pc_kless_saved;
   reg [31:0] spike_sw_addr;
   reg [31:0] spike_sw_data; 
   //my_rep_sequence sequence1;
	//my_sequence sequence1;
	my_item spike_data;
	my_item spike_data_prev;
	my_item kless_data;
	my_item kless_data_prev;
	my_item data_to_match_k;
	my_item data_to_match_s;
	my_item data_to_match;
	

	int current_inst=1;
	int start_inst_num=1; //Inizio del programma utente nell'elenco delle istruzioni nel log_file di Spike
	int check_state=0;
	int total_differences=0; //Volte in cui gli stati di Klessydra e Spike differivano
	int total_check_passed=0; //Volte in cui gli stati di Klessydra e Spike erano uguali
	int attempts_to_start=0; //tentativi di trovare il programma utente di Klessydra
	int prova=0;
	int go_on=0;  //varrà 1 se si può procedere con il test
	int repetita=0; //aumenterà ogni volta che verrà incontrata una istruzione con pc lungo
	int started=0; //varrà 1 se avrò iniziato i confronti
	int skip=0; //varrà 1 se il confronto con l'istruzione passa già all primo ciclo del pc
	int num_mem=0;
	int sync_lost=0; //quante volte ho perso il sincronismo
	int mem_diff=0; //differenze a livello di memoria


   function new(string name, uvm_component parent);  // typical class constructor
      super.new(name, parent);
      $display("Creato test");
   endfunction: new

   virtual function void build_phase(uvm_phase phase); 
   	phase.raise_objection(this);    
   	super.build_phase(phase);
		// recall the handle of the interface from the database using get
		if (!uvm_config_db#(virtual tb_sv2uvm_if)::get(this, "*my_uvm_test","tb_sv2uvm_if_vi",m_tb_sv2uvm_if)) begin         
        	`uvm_fatal("NULL_POINTER", "Cannot find tb_sv2uvm_if_vi in config db")                  
		end
		agent1=my_agent::type_id::create("agent1", this);
		agent1.my_tb_sv2uvm_if_agent=m_tb_sv2uvm_if;
		scoreboard1=my_scoreboard::type_id::create("scoreboard1", this);
		spike1=my_spike::type_id::create("spike1", this);
		//sequence1=my_sequence::type_id::create("sequence1", this);
		spike_data= my_item::new();
		spike_data_prev= my_item::new();
		kless_data= my_item::new();
		kless_data_prev= my_item::new();
		data_to_match_k=my_item::new();
		data_to_match_s=my_item::new();
		kless_data_prev.my_pc_0=32'h00000000; //Inizializzo il pc di Klessydra 
		spike_data_prev.my_pc_0=32'h00000001; //Inizializzo il pc di Spike
		$display("PARAMETRO: %s, nome programma: %s",KLESS_NOME, Nome_programma);
		phase.drop_objection(this);
   endfunction : build_phase

   virtual function void connect_phase(uvm_phase phase);
		phase.raise_objection(this);  
   	super.connect_phase (phase);
		//agent1.driver1.seq_item_port.connect(agent1.sequencer1.seq_item_export);
		agent1.monitor1.my_port.connect(scoreboard1.ap_imp);
		//spike1.my_spike_port.connect(scoreboard1.spike_ap_imp);
		phase.drop_objection(this);
   endfunction : connect_phase

   function bit string_contains(string str, string substr);
    int str_len = str.len();
    int substr_len = substr.len();
    int i, j;

    for (i = 0; i <= str_len - substr_len; i++) begin
        for (j = 0; j < substr_len; j++) begin
            if (str.getc(i + j) != substr.getc(j)) begin
                break;
            end
        end
        if (j == substr_len) return 1; // Substring found
    end
    return 0; // Substring not found
	endfunction: string_contains

     
	function my_item match_pc(reg [31:0] pc_prev, my_item data_now);
		data_to_match= my_item::new();
		data_to_match.my_hartid=data_now.my_hartid;
		data_to_match.ins_name=data_now.ins_name;
		data_to_match.ins_addr=data_now.ins_addr;
		data_to_match.op1=data_now.op1;
		data_to_match.op2=data_now.op2;
		data_to_match.op3=data_now.op3;
		for (int i=0; i<=31; i++) begin
   		data_to_match.my_reg_file_0[i]= data_now.my_reg_file_0[i];
   	end
   	data_to_match.my_pc_0= pc_prev; //il program counter è quello precedente
   	data_to_match.my_mtvec= data_now.my_mtvec;
   	data_to_match.my_mstatus= data_now.my_mstatus;
   	data_to_match.my_mcause= data_now.my_mcause;
   	data_to_match.my_mepc= data_now.my_mepc;
   	data_to_match.my_mip= data_now.my_mip;
   	data_to_match.my_mem_addr= data_now.my_mem_addr;
   	data_to_match.my_mem_wdata= data_now.my_mem_wdata;
   	data_to_match.my_mem_rdata= data_now.my_mem_rdata;
   	data_to_match.we= data_now.we;
		return data_to_match;
	endfunction: match_pc

	function void mem_ins();
		if (string_contains(data_to_match_s.ins_name,"sw") && skip==0) begin
			num_mem=num_mem+1;
			spike1.get_sw_content(num_mem, spike_sw_addr, spike_sw_data);
			mem_diff=mem_diff +scoreboard1.check_mem(spike_sw_addr, spike_sw_data, kless_data_prev.my_mem_addr, kless_data_prev.my_mem_wdata, kless_data_prev.we);
		end
	endfunction: mem_ins

   virtual function void show_both(my_item data_k, my_item data_s);
		$display("I dati di Klessydra sono:");
		scoreboard1.show(data_k);
		$display("I dati da Spike sono:");
		scoreboard1.show(data_s);
	endfunction : show_both

   virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		$display("Fase di RUN");
		spike1.spawn_ISS();
		m_tb_sv2uvm_if.sv_execution_repeat = 1'b0;

		fork 
			begin
				wait(m_tb_sv2uvm_if.is_sv_execution_completed === 1'b1); 
					$display("Esecuzione programma terminata");
					$display("Sono arrivato alla istruzione %0d su %0d",current_inst, NUM_INSTRUCTIONS);
			end
			begin
				forever begin
					@(posedge m_tb_sv2uvm_if.clock); //Aspetto il fronte di salita del clock
					if (started==1) begin
						//$display("Partial check passed=%0d, partial differences: %0d, repetita: %0d",total_check_passed, total_differences, repetita);
						//$display("Control: current_inst-start_inst=check_passed+differences  %0d=%0d",current_inst-start_inst_num, total_check_passed+total_differences);
						//$display("ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",);
						$display("____________________________________________________________________________________________",);
						//$display("c\tc\tc\tc\tc\tc\tc");
					end

					if (current_inst>NUM_INSTRUCTIONS) begin //Ho terminato le istruzioni da eseguire?
						$display("Ho terminato le %0d istruzioni di Spike!", NUM_INSTRUCTIONS);
						$display("Ho confrontato %0d istruzioni con Klessydra", NUM_INSTRUCTIONS-(start_inst_num-1)); //-1 è perchè current inst parte da 1
						break;
					end

					
					spike_data=spike1.get_item(current_inst); //Leggo una prima volta spike con UVM
					//spike_data=spike1.read_item(current_inst); //Leggo una prima volta spike in C
					data_to_match_s=match_pc(spike_data.my_pc_0, spike_data);//Creo l'item di Spike che confronterò: pc precedente di spike ma rf attuale
																																							//potrebbe servire l'rf precedente

					while ( data_to_match_s.my_pc_0 <= 32'h80000000) begin  //Cerco l'inizio del programma utente
						current_inst=current_inst+1; 
						spike_data_prev=spike_data;
						//spike_data=spike1.read_item(current_inst); //in c
						spike_data=spike1.get_item(current_inst);  //in UVM
						data_to_match_s=match_pc(spike_data.my_pc_0, spike_data); //ri-creo l'item di Spike che confronterò
						$display("current_inst: %0d current spike_pc: %0x",start_inst_num, data_to_match_s.my_pc_0);
						start_inst_num=current_inst;
						if (start_inst_num>=NUM_INSTRUCTIONS) begin
							$display("Unable to find the start of user program!");	
							break;
						end 
					end
					//Cerco l'inizio del programma utente di Klessydra
					agent1.monitor1.save_status(); //Leggo lo status di Klessydra
					kless_data=agent1.monitor1.data_to_send; //e lo salvo in una variabile
				
					data_to_match_k=match_pc(kless_data_prev.my_pc_0, kless_data);	//Creo l'item di Klessydra: pc precedente ma rf attuale
					//$display("DEBUG: kless_pc: %0x,kless_pc_prev:%0x, spike_pc: %0x, spike_pc_prev: %0x, data_to_match_s pc: %0x, data_to_match_k pc: %0x ",kless_data.my_pc_0, kless_data_prev.my_pc_0, spike_data.my_pc_0,spike_data_prev.my_pc_0, data_to_match_s.my_pc_0, data_to_match_k.my_pc_0); 
					//Aspetto di iniziare: il pc klessydra e il pc Spike devono partire uguali
					if(go_on==0 && data_to_match_k.my_pc_0 !== data_to_match_s.my_pc_0) begin //Aspetto che Klessydra arrivi al pc di Spike iniziale
						if (attempts_to_start>2000) begin
							$display("Klessydra non matcha il pc di Spike! Klessydra pc= %0x, Spike pc= %0x, attempts_to_start= %0d",data_to_match_k.my_pc_0,data_to_match_s.my_pc_0, attempts_to_start);	
						end
						attempts_to_start=attempts_to_start+1;
						if (attempts_to_start>3000) begin
							$display("Unable to continue! Spike pc: %0x, Klessydra pc: %0x",data_to_match_s.my_pc_0, data_to_match_k.my_pc_0);
							break;
						end
					end
					//Ho iniziato! 
					else begin
						if (attempts_to_start>0) begin //la prima volta stampo che ho machato il pc di klessydra e di Spike
							$display("Fine ricerca match: Spike pc= %0x, Klessydra pc= %0x current inst: %0d, attempts_to_start= %0d",data_to_match_s.my_pc_0, data_to_match_k.my_pc_0, current_inst, attempts_to_start);
							started=1;
							pc_start=data_to_match_s.my_pc_0;
							attempts_to_start=0;
						end
						//ISTRUZIONI RIPETUTE: il prossimo pc sarà uguale!
						if (started>0 && kless_data_prev.my_pc_0===kless_data.my_pc_0) begin 
							go_on=1;
							$display("Istruzione lunga! current_inst=%0d pc=%08x",current_inst, data_to_match_k.my_pc_0);
							//$display("DEBUG: kless_pc: %0x,kless_pc_prev:%0x, spike_pc: %0x, spike_pc_prev: %0x, data_to_match_s pc: %0x, data_to_match_k pc: %0x ",kless_data.my_pc_0, kless_data_prev.my_pc_0, spike_data.my_pc_0,spike_data_prev.my_pc_0, data_to_match_s.my_pc_0, data_to_match_k.my_pc_0);
							if (skip==0) begin //Devo fare il confronto? skip=1 vorrebbe dire "skippa"
								repetita=repetita+1;//aggiorno il numero di istruzioni ripetute confrontate
								check_state=0; //Ci sarà una differenza?
								check_state=scoreboard1.check_spike(data_to_match_s, data_to_match_k);
								if(check_state==0) begin //Uguali!
									mem_ins(); //se è una istruzione di memoria faccio il check
									total_check_passed=total_check_passed+1;
									current_inst=current_inst+1;//vado avanti con il log di spike se il confronto con l'istruzione ripetuta passa
									
									skip=1; //Skippo il confronto al prossimo ciclo di clock
								end
								else begin //C'è una differenza!
									mem_ins(); //se è una istruzione di memoria faccio il check
									total_differences=total_differences+check_state;	
									current_inst=current_inst+1;
									if (total_differences>0 && data_to_match_k.my_pc_0 !== data_to_match_s.my_pc_0) begin //se ci sono troppe differenze mi fermo a ricercare il match
										$display("Sincronismo perso!");
										sync_lost=sync_lost+1;
										current_inst=current_inst-1;
										total_differences=total_differences-1;
										go_on=0;
										skip=0; //non skippare il prossimo confronto! Potresti trovare il match che ora non c'è!
										//Non vado avanti però con Spike, perchè l'attuale istruzione non ha ancora trovato match. Al secondo ciclo potrebbe arrivare il match
									end
								end	
							end
							spike_data_prev=spike_data; //Salvo lo status attuale di spike 	
						end
						//ISTRUZIONI NON RIPETUTE
						else if (started>0 && kless_data_prev.my_pc_0!==kless_data.my_pc_0 && skip==0) begin
							go_on=1; //Procedo con i confronti
							$display("current_inst=%0d",current_inst);
							//$display("DEBUG: kless_pc: %0x,kless_pc_prev:%0x, spike_pc: %0x, spike_pc_prev: %0x, data_to_match_s pc: %0x, data_to_match_k pc: %0x ",kless_data.my_pc_0, kless_data_prev.my_pc_0, spike_data.my_pc_0,spike_data_prev.my_pc_0, data_to_match_s.my_pc_0, data_to_match_k.my_pc_0);
							//show_both(data_to_match_k, data_to_match_s);
							if (skip==0) begin
								check_state=0; //Ci sarà una differenza?
								check_state=scoreboard1.check_spike(data_to_match_s, data_to_match_k);
								if(check_state==0) begin
									mem_ins(); //se è una istruzione di memoria faccio il check
									total_check_passed=total_check_passed+1;		
									//$display("DEBUG: kless_pc: %0x,kless_pc_prev:%0x, spike_pc: %0x, spike_pc_prev: %0x, data_to_match_s pc: %0x, data_to_match_k pc: %0x ",kless_data.my_pc_0, kless_data_prev.my_pc_0, spike_data.my_pc_0,spike_data_prev.my_pc_0, data_to_match_s.my_pc_0, data_to_match_s.my_pc_0);
								end
								else begin
									mem_ins(); //se è una istruzione di memoria faccio il check
									total_differences=total_differences+check_state;
									//$display("DEBUG: kless_pc: %0x,kless_pc_prev:%0x, spike_pc: %0x, spike_pc_prev: %0x, data_to_match_s pc: %0x, data_to_match_k pc: %0x ",kless_data.my_pc_0, kless_data_prev.my_pc_0, spike_data.my_pc_0,spike_data_prev.my_pc_0, data_to_match_s.my_pc_0, data_to_match_s.my_pc_0);
									if (total_differences>0 && data_to_match_k.my_pc_0 !== data_to_match_s.my_pc_0) begin //se ci sono troppe differenze mi fermo a ricercare il match
										$display("Sincronismo perso!");
										sync_lost=sync_lost+1;
										current_inst=current_inst-1;
										total_differences=total_differences-1;
										go_on=0;
									end
								end
							end
							if (skip==0) begin
								spike_data_prev=spike_data; //Salvo lo status attuale di spike per andare avanti
								current_inst=current_inst+1;
							end	
							skip=0;
						end
						else begin
							$display("Caso skippato! current_inst=%0d",current_inst); //il caso skippato è relativo a istruzioni più lunghe di un ciclo, quindi la current instr è ancora quella precedente
							skip=0;
						end
					end
					kless_data_prev=kless_data; //Salvo lo status attuale di klessydra 
				end
			end
		join_any
		//$display("Ho finito di confrontare %0d istruzioni", NUM_INSTRUCTIONS-(start_inst_num-2)); //-1 è perchè current inst parte da 1
		$display("Trovate %0d differenze",total_differences-attempts_to_start); //non conto i confronti iniziali
		$display("Accessi in memoria: %0d - Differenze memoria: %0d",num_mem, mem_diff);
		$display("Check passati: %0d",total_check_passed);
		$display("Sincronismo perso %0d volte",sync_lost);
	//	$display("Istruzioni ripetute: %0d",repetita);
   	phase.drop_objection(this);
   endtask : run_phase  
endclass : my_uvm_test

endpackage

