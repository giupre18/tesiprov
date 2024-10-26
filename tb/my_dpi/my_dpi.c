#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <svdpi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "dpiheader.h"
#define MAX_LINE_LENGTH 256
#define MAX_STRING_LENGTH 20
//puntatore a file?
typedef struct {
    int core_id;
    int hart_id;
    unsigned int x_registers[32];
    unsigned int mtvec;
    unsigned int mstatush;
    unsigned int mcause;
    unsigned int mepc;
    unsigned int mip;
    unsigned int ins_addr;
    char ins_name [20];
    char op1 [10];
    char op2 [10];
    char op3 [20];
} CpuState;

typedef struct {
    char name[5];
    unsigned int value;
} Register;

void read_spike_log(const char *filename) {
  char line[MAX_LINE_LENGTH];
  char cestino [10];
  unsigned int pc;
  unsigned int temp=0;
  unsigned int indice=0;
  int print_ok=0;
  CpuState state;
  FILE *file = fopen(filename, "r");
  if (file == NULL) {
        perror("Errore nell'apertura del file");
        exit(EXIT_FAILURE);
  }
  // Leggi e salva i valori dei registri
  while (fgets(line, sizeof(line), file) != NULL) 
  {
    if (strstr(line, "core ") != NULL) {
      int read_items = sscanf(line, "core %x: 0x%x (%x) %19s %9s %9s %19s", &state.hart_id, &state.core_id, &state.ins_addr, state.ins_name, state.op1, state.op2, state.op3);
      if (read_items < 4) {
        printf("Errore nel leggere istruzione e operandi!\n");
      }
    }
    else if (strstr(line, "X[") != NULL) { 
      int result = sscanf(line, " X[%x] = 0x%x", &indice, &temp);
      state.x_registers[indice]=temp;
      if (result == 2 && indice >= 0 && indice < 32) {
        // Assegnazione corretta, indice e valore sono stati letti
      } 
      else {
        printf("Errore nell'assegnazione!\n");
      }
    }
    else if (strstr(line, "mtvec: 0x") != NULL){
      sscanf(line, "mtvec: 0x%x",&state.mtvec);}
    else if (strstr(line, "mstatush: 0x") != NULL){
      sscanf(line, "mstatush: 0x%x",&state.mstatush);}
    else if (strstr(line, "mcause: 0x") != NULL){
      sscanf(line, "mcause: 0x%x",&state.mcause);}
    else if (strstr(line, "mepc: 0x") != NULL){
      sscanf(line, "mepc: 0x%x",&state.mepc);}
    else if (strstr(line, "mip: 0x") != NULL){
      sscanf(line, "mip: 0x%x",&state.mip);    
      print_ok=1;
      indice=0;
    }
    memset(line,0,strlen(line));
    // Stampa i valori dei registri
    if (print_ok==1){
        printf("hart: %x\n", state.hart_id);
        printf("pc: 0x%x (%x)\n", state.core_id, state.ins_addr);
        printf("%s %s %s %s\n", state.ins_name, state.op1, state.op2, state.op3 );
        for (int i = 0; i < 32; i++) {
            printf("x[%x]: 0x%x\n",i, state.x_registers[i]);
        }
        printf("mtvec: 0x%x\n", state.mtvec);
        printf("mstatush: 0x%x\n", state.mstatush);
        printf("mcause: 0x%x\n", state.mcause);
        printf("mepc: 0x%x\n", state.mepc);
        printf("mip: 0x%x\n", state.mip);
        printf("--------------------------\n");
        print_ok=0;
    }
  }
  fclose(file);
}

void my_dpi_function(int data)
{printf("Sto utilizzando le DPI!! Numero di test: %d \n", data);}

// Funzione per leggere il file e salvare i valori dei registri
void readAndSaveRegisters(const char *filename) {
  char line[MAX_LINE_LENGTH];
  char cestino [10];
  unsigned int pc;
  Register registers[32]; // Array per i registri
  FILE *file = fopen(filename, "r");
  if (file == NULL) {
        perror("Errore nell'apertura del file");
        exit(EXIT_FAILURE);
  }
  // Leggi e salva i valori dei registri
  while (fgets(line, sizeof(line), file) != NULL) {
    if (strstr(line, "core   0: 0x") != NULL) {
      sscanf(line, "%*[^x]x%x", &pc);
    }
    else if (strstr(line, "zero: 0x") != NULL) { 
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[0].value,cestino, &registers[1].value,cestino, &registers[2].value,cestino, &registers[3].value);}
    else if (strstr(line, "tp: 0x") != NULL){
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[4].value, cestino, &registers[5].value, cestino, &registers[6].value, cestino, &registers[7].value);}
    else if (strstr(line, "s0: 0x") != NULL){
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[8].value, cestino, &registers[9].value, cestino, &registers[10].value, cestino, &registers[11].value);}
    else if (strstr(line, "a2: 0x") != NULL){
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[12].value, cestino, &registers[13].value, cestino, &registers[14].value, cestino, &registers[15].value);}
    else if (strstr(line, "a6: 0x") != NULL){
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[16].value, cestino, &registers[17].value, cestino, &registers[18].value, cestino, &registers[19].value);}
    else if (strstr(line, "s4: 0x") != NULL){
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[20].value, cestino, &registers[21].value, cestino, &registers[22].value, cestino, &registers[23].value);}
    else if (strstr(line, "s8: 0x") != NULL){
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[24].value, cestino, &registers[25].value, cestino, &registers[26].value, cestino, &registers[27].value);}
    else if (strstr(line, "t3: 0x") != NULL){
      sscanf(line, "%s 0x%x %s 0x%x %s 0x%x %s 0x%x\n",cestino, &registers[28].value, cestino, &registers[29].value, cestino, &registers[30].value, cestino, &registers[31].value);}
    memset(line,0,strlen(line));
    }
    // Chiudi il file
  fclose(file);
  strcpy(registers[0].name,"zero");
  strcpy(registers[1].name,"ra");
  strcpy(registers[2].name,"sp");
  strcpy(registers[3].name,"gp");
  strcpy(registers[4].name,"tp");
  strcpy(registers[5].name,"t0");
  strcpy(registers[6].name,"t1");
  strcpy(registers[7].name,"t2");
  strcpy(registers[8].name,"s0");
  strcpy(registers[9].name,"s1");
  strcpy(registers[10].name,"a0");
  strcpy(registers[11].name,"a1");
  strcpy(registers[12].name,"a2");
  strcpy(registers[13].name,"a3");
  strcpy(registers[14].name,"a4");
  strcpy(registers[15].name,"a5");
  strcpy(registers[16].name,"a6");
  strcpy(registers[17].name,"a7");
  strcpy(registers[18].name,"s2");
  strcpy(registers[19].name,"s3");
  strcpy(registers[20].name,"s4");
  strcpy(registers[21].name,"s5");
  strcpy(registers[22].name,"s6");
  strcpy(registers[23].name,"s7");
  strcpy(registers[24].name,"s8");
  strcpy(registers[25].name,"s9");
  strcpy(registers[26].name,"s10");
  strcpy(registers[27].name,"s11");
  strcpy(registers[28].name,"t3");
  strcpy(registers[29].name,"t4");
  strcpy(registers[30].name,"t5");
  strcpy(registers[31].name,"t6");
  // Stampa i valori dei registri
  printf("pc: 0x%x\n", pc);
  for (int i = 0; i < 32; i=i+4) {
    printf("\t %s: 0x%08x\t", registers[i].name, registers[i].value);
    printf("\t %s: 0x%08x\t", registers[i+1].name, registers[i+1].value);
    printf("\t %s: 0x%08x\t", registers[i+2].name, registers[i+2].value);
    printf("\t %s: 0x%08x\n", registers[i+3].name, registers[i+3].value);
  }
}
//Funzione in realtà inutile
void read_log_file() {
    const char *filename = "my_log_file.txt"; // Sostituisci con il tuo nome di file
    readAndSaveRegisters(filename);
}

void my_second_dpi_function(int data){
  sleep (3);
  read_log_file();
}

void spawn_and_run_spike_new(const char *elf_file_name, int num){ //num è il numero di istruzioni da eseguire
  char command[256];
  snprintf(command, sizeof(command), "rm my_log_file.txt; rm my_file_sw.txt; touch my_log_file.txt; touch my_file_sw.txt; ./spike_new.exp %s %d > output_script.txt", elf_file_name, num);
  //NB: >output_script.txt serve sennò modelsim stampa tutto
  int ret= system(command);
  if (ret != 0) {
    printf("Errore nell'esecuzione del comando\n");
  }
}


void return_registers( int num_inst, unsigned int* registers, int* harc_id, int* instr_addr, const char** instr_name, const char** op1, const char** op2, const char** op3){
  char line[MAX_LINE_LENGTH];
  char cestino [10];
  int indice=0;
  unsigned int pc;
  unsigned int temp;
  int blocco_corrente = 0;
  char temp_instr_name[MAX_STRING_LENGTH];
  char temp_op1[MAX_STRING_LENGTH];
  char temp_op2[MAX_STRING_LENGTH];
  char temp_op3[MAX_STRING_LENGTH];
  FILE *file = fopen("my_log_file.txt", "r");
  if (file == NULL) {
    perror("Errore nell'apertura del file");
    exit(EXIT_FAILURE);
  }

  while (fgets(line, sizeof(line), file) != NULL) {
    if (strstr(line, "core ") != NULL && strstr(line, "core   0: >>>>") == NULL) {
      blocco_corrente++;
      int read_items = sscanf(line, "core %x: 0x%x (%x) %19s %9s %9s %[^\n]", harc_id, &registers[32], instr_addr, temp_instr_name, temp_op1, temp_op2, temp_op3);
      if (read_items < 4) {
        printf("Errore nel leggere istruzione e operandi!\n");
      }  
      else {
        int len = strlen(temp_op3);
        if (len > 0 && (temp_op3[len - 1] == '\n' || temp_op3[len - 1] == '\r')) {
           temp_op3[len - 1] = '\0';  // Rimuovi il newline
        }
        /*
        *instr_name=&temp_instr_name; ///Problemi :(
        *op1=&temp_op1;
        *op2=&temp_op2;
        *op3=&temp_op3;
        */
        
        *instr_name = strdup(temp_instr_name); //DEVO DEALLOCARE!
        *op1 = strdup(temp_op1); //&temp_op1[0] //strcpy
        *op2 = strdup(temp_op2);
        *op3 = strdup(temp_op3);
        
        //strcpy(instr_name,temp_instr_name);
        //strcpy(op1,temp_op1);
        //strcpy(op2,temp_op2);
        //strcpy(op3,temp_op3);
        
        memset(temp_instr_name, 0, sizeof(temp_instr_name));///
        memset(temp_op1, 0, sizeof(temp_op1));
        memset(temp_op2, 0, sizeof(temp_op2));
        memset(temp_op3, 0, sizeof(temp_op3));
      }
    }
    else if (strstr(line, "X[") != NULL) { 
      int result = sscanf(line, " X[%x] = 0x%x", &indice, &temp);
      registers[indice]=temp;
    }
    else if (strstr(line, "mtvec: 0x") != NULL){
      sscanf(line, "mtvec: 0x%x",&registers[33]);}
    else if (strstr(line, "mstatush: 0x") != NULL){
      sscanf(line, "mstatush: 0x%x",&registers[34]);}
    else if (strstr(line, "mcause: 0x") != NULL){
      sscanf(line, "mcause: 0x%x",&registers[35]);}
    else if (strstr(line, "mepc: 0x") != NULL){
      sscanf(line, "mepc: 0x%x",&registers[36]);}
    else if (strstr(line, "mip: 0x") != NULL){
      sscanf(line, "mip: 0x%x",&registers[37]);    
      indice=0;
      if(blocco_corrente == num_inst){break;}
    }
    memset(line,0,strlen(line));
  }
  //Libero la memoria alla fine
  /*
  if (*instr_name != NULL) {
    free(*instr_name);
  }
  if (*op1 != NULL) {
    free(*op1);
  }
  if (*op2 != NULL) {
    free(*op2);
  }
  if (*op3 != NULL) 
    free(*op3);
  }
  */
  // Chiudi il file
  fclose(file);
}


void spawn_mem (const char *elf_file_name, int num_inst, int harc_id, int mem_addr){
  char command[256];
  snprintf(command, sizeof(command), "rm my_log_file_mem.txt; touch my_log_file_mem.txt; ./spike_new_mem.exp %s %d %d %08x> output_script_mem.txt", elf_file_name, num_inst, harc_id, mem_addr);
  //NB: >output_script_mem.txt serve sennò modelsim stampa tutto
  int ret= system(command);
  if (ret != 0) {
    printf("Errore nell'esecuzione del comando di memoria\n");
  }
}