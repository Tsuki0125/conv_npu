/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"


int main()
{
    init_platform();
    int bram_test_result = 1;
    print("#################################################\n");
    print("\t BRAM WR-LOOP TEST\n");
    print("#################################################\n");
    ////////////////////////////////
    int* p = (int*)0x42000000;
    for(int i = 0; i<32768; i++) {
    	*p = i;
    	p++;
    }
    // read after write loop to validate
    p = (int*)0x42000000;
	for(int i = 0; i<32768; i++) {
		printf("feature BRAM[%x] = %d \n", (int)p, *p );
		if(*p != i){
			printf("feature BRAM[%x] error!", (int)p);
			bram_test_result = 0;
			break;
		}
		p++;
	}
	//////////////////////////////
    p = (int*)0x44000000;
    for(int i = 0; i<65536; i++) {
    	*p = i;
    	p++;
    }
    // read after write loop to validate
    p = (int*)0x44000000;
	for(int i = 0; i<65536; i++) {
		printf("kernel-weights BRAM[%x] = %d \n", (int)p, *p );
		if(*p != i){
			printf("kernel-weights BRAM[%x] error!", (int)p);
			bram_test_result = 0;
			break;
		}
		p++;
	}
	print("######################################################\n");
	if(bram_test_result == 1){
		print("\t BRAM TEST PASSED! \n");
	}
	else {
		print("\t BRAM TEST FAILED! \n");
	}
    print("######################################################\n");
    cleanup_platform();
    return 0;
}
