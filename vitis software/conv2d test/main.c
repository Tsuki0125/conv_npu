#include <stdio.h>
#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"
#include "feature_in.h"
#include "weights.h"
#include "feature_out.h"

int* CSR_BASE = (int*)0x40000000;
int* FRAM0_BASE = (int*)0x42000000;
int* FRAM1_BASE = (int*)0x42008000;
int* FRAM2_BASE = (int*)0x42010000;
int* FRAM3_BASE = (int*)0x42018000;
int* KRAM_SLOT0_BASE = (int*)0x44000000;
int* KRAM_SLOT1_BASE = (int*)0x44020000;


// 等待device完成计算暂时使用轮询模式，后面完善之后改为中断；
int main()
{
    print("CONV2d TEST BEGIN.\n");
    // WRITE INPUT FEATURE DATA
    int* p = FRAM0_BASE;
    for(int i = 0; i<9600; i++) {
    	*p = feature_in[i];
    	p++;
    }
    // WRITE INPUT kernel weights
	p = KRAM_SLOT0_BASE;
	for(int i = 0; i<27; i++) {
		*p = weights[i];
		p++;
	}
    // WRITE CSR to start compute
    Xil_Out32(0x40000004, 0x44000000);
    Xil_Out32(0x40000008, 0x42000000);
    Xil_Out32(0x4000000c, 0x00000064);
    Xil_Out32(0x40000010, 0x00000020);
    Xil_Out32(0x40000014, 0x00000003);
    Xil_Out32(0x40000018, 0x00000001);
    Xil_Out32(0x4000001c, 0x42010000);
    Xil_Out32(0x40000020, 49);
    Xil_Out32(0x40000024, 15);
    Xil_Out32(0x40000000, 0x0302FF21);

    // wait compute result
    int compute_done = 0;
    int i;
    for(i = 0; i<10000; i++){
    	sleep(1);
		compute_done = (Xil_In32(0x40000000) & 0x00000004);
		printf("csr[ctrl] = 0x%lx \n", Xil_In32(0x40000000));
		if(compute_done){
			break;
		}
        }
    // compute time out:
    if(i == 10000){
    	print("compute TIME OUT!\n");
    	return 1;
    }
    // validate compute result
    int test_pass = 1;
    p = (int*)0x42010000;
    for(i = 0; i<735; i++){
    	printf("output data[%x] = %d \n", (int)p, *p );
		if(*p != feature_out[i]){
			printf("compute result[%x] error! \n", (int)p);
			test_pass = 0;
			break;
		}
		p++;
    }

    if(test_pass){
    	print("\nCONV2D TEST PASSED!\n");
    }
    else {
    	print("\nCONV2D TEST FAILED!\n");
    }
    return 0;
}
