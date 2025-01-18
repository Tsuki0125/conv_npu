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
#include "xil_io.h"


int main()
{
    init_platform();

    print("AXI-LITE SLAVE REG TEST\n");
    for(int i = 0; i<10; i++){
            	printf("aci-csr[%x] = 0x%lx \n", (0x40000000 + 0x4 * i), Xil_In32(0x40000000 + 0x4 * i));
            }

    for(int i = 1; i<10; i++){ //0X4000_0000 is the ctrl register, just ignore it
    	Xil_Out32(0x40000000 + 0x4 * i, 0xFFFFFFFF);
    }

    for(int i = 0; i<10; i++){
        	printf("aci-csr[%x] = 0x%lx \n", (0x40000000 + 0x4 * i), Xil_In32(0x40000000 + 0x4 * i));
        }
    print("Successfully ran AXI-LITE SLAVE REG TEST application\n");
    cleanup_platform();
    return 0;
}
