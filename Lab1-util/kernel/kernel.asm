
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	80010113          	addi	sp,sp,-2048 # 8000a800 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <junk>:
    8000001a:	a001                	j	8000001a <junk>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	0000a617          	auipc	a2,0xa
    8000004e:	fb660613          	addi	a2,a2,-74 # 8000a000 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c7478793          	addi	a5,a5,-908 # 80005cd0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd47a3>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	b9c78793          	addi	a5,a5,-1124 # 80000c42 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  timerinit();
    800000c4:	00000097          	auipc	ra,0x0
    800000c8:	f58080e7          	jalr	-168(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000cc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000d0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000d2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000d4:	30200073          	mret
}
    800000d8:	60a2                	ld	ra,8(sp)
    800000da:	6402                	ld	s0,0(sp)
    800000dc:	0141                	addi	sp,sp,16
    800000de:	8082                	ret

00000000800000e0 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    800000e0:	7119                	addi	sp,sp,-128
    800000e2:	fc86                	sd	ra,120(sp)
    800000e4:	f8a2                	sd	s0,112(sp)
    800000e6:	f4a6                	sd	s1,104(sp)
    800000e8:	f0ca                	sd	s2,96(sp)
    800000ea:	ecce                	sd	s3,88(sp)
    800000ec:	e8d2                	sd	s4,80(sp)
    800000ee:	e4d6                	sd	s5,72(sp)
    800000f0:	e0da                	sd	s6,64(sp)
    800000f2:	fc5e                	sd	s7,56(sp)
    800000f4:	f862                	sd	s8,48(sp)
    800000f6:	f466                	sd	s9,40(sp)
    800000f8:	f06a                	sd	s10,32(sp)
    800000fa:	ec6e                	sd	s11,24(sp)
    800000fc:	0100                	addi	s0,sp,128
    800000fe:	8b2a                	mv	s6,a0
    80000100:	8aae                	mv	s5,a1
    80000102:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000104:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000108:	00012517          	auipc	a0,0x12
    8000010c:	6f850513          	addi	a0,a0,1784 # 80012800 <cons>
    80000110:	00001097          	auipc	ra,0x1
    80000114:	8bc080e7          	jalr	-1860(ra) # 800009cc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000118:	00012497          	auipc	s1,0x12
    8000011c:	6e848493          	addi	s1,s1,1768 # 80012800 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000120:	89a6                	mv	s3,s1
    80000122:	00012917          	auipc	s2,0x12
    80000126:	77690913          	addi	s2,s2,1910 # 80012898 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000012a:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000012c:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    8000012e:	4da9                	li	s11,10
  while(n > 0){
    80000130:	07405863          	blez	s4,800001a0 <consoleread+0xc0>
    while(cons.r == cons.w){
    80000134:	0984a783          	lw	a5,152(s1)
    80000138:	09c4a703          	lw	a4,156(s1)
    8000013c:	02f71463          	bne	a4,a5,80000164 <consoleread+0x84>
      if(myproc()->killed){
    80000140:	00001097          	auipc	ra,0x1
    80000144:	75e080e7          	jalr	1886(ra) # 8000189e <myproc>
    80000148:	591c                	lw	a5,48(a0)
    8000014a:	e7b5                	bnez	a5,800001b6 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    8000014c:	85ce                	mv	a1,s3
    8000014e:	854a                	mv	a0,s2
    80000150:	00002097          	auipc	ra,0x2
    80000154:	f60080e7          	jalr	-160(ra) # 800020b0 <sleep>
    while(cons.r == cons.w){
    80000158:	0984a783          	lw	a5,152(s1)
    8000015c:	09c4a703          	lw	a4,156(s1)
    80000160:	fef700e3          	beq	a4,a5,80000140 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    80000164:	0017871b          	addiw	a4,a5,1
    80000168:	08e4ac23          	sw	a4,152(s1)
    8000016c:	07f7f713          	andi	a4,a5,127
    80000170:	9726                	add	a4,a4,s1
    80000172:	01874703          	lbu	a4,24(a4)
    80000176:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    8000017a:	079c0663          	beq	s8,s9,800001e6 <consoleread+0x106>
    cbuf = c;
    8000017e:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000182:	4685                	li	a3,1
    80000184:	f8f40613          	addi	a2,s0,-113
    80000188:	85d6                	mv	a1,s5
    8000018a:	855a                	mv	a0,s6
    8000018c:	00002097          	auipc	ra,0x2
    80000190:	184080e7          	jalr	388(ra) # 80002310 <either_copyout>
    80000194:	01a50663          	beq	a0,s10,800001a0 <consoleread+0xc0>
    dst++;
    80000198:	0a85                	addi	s5,s5,1
    --n;
    8000019a:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000019c:	f9bc1ae3          	bne	s8,s11,80000130 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    800001a0:	00012517          	auipc	a0,0x12
    800001a4:	66050513          	addi	a0,a0,1632 # 80012800 <cons>
    800001a8:	00001097          	auipc	ra,0x1
    800001ac:	88c080e7          	jalr	-1908(ra) # 80000a34 <release>

  return target - n;
    800001b0:	414b853b          	subw	a0,s7,s4
    800001b4:	a811                	j	800001c8 <consoleread+0xe8>
        release(&cons.lock);
    800001b6:	00012517          	auipc	a0,0x12
    800001ba:	64a50513          	addi	a0,a0,1610 # 80012800 <cons>
    800001be:	00001097          	auipc	ra,0x1
    800001c2:	876080e7          	jalr	-1930(ra) # 80000a34 <release>
        return -1;
    800001c6:	557d                	li	a0,-1
}
    800001c8:	70e6                	ld	ra,120(sp)
    800001ca:	7446                	ld	s0,112(sp)
    800001cc:	74a6                	ld	s1,104(sp)
    800001ce:	7906                	ld	s2,96(sp)
    800001d0:	69e6                	ld	s3,88(sp)
    800001d2:	6a46                	ld	s4,80(sp)
    800001d4:	6aa6                	ld	s5,72(sp)
    800001d6:	6b06                	ld	s6,64(sp)
    800001d8:	7be2                	ld	s7,56(sp)
    800001da:	7c42                	ld	s8,48(sp)
    800001dc:	7ca2                	ld	s9,40(sp)
    800001de:	7d02                	ld	s10,32(sp)
    800001e0:	6de2                	ld	s11,24(sp)
    800001e2:	6109                	addi	sp,sp,128
    800001e4:	8082                	ret
      if(n < target){
    800001e6:	000a071b          	sext.w	a4,s4
    800001ea:	fb777be3          	bgeu	a4,s7,800001a0 <consoleread+0xc0>
        cons.r--;
    800001ee:	00012717          	auipc	a4,0x12
    800001f2:	6af72523          	sw	a5,1706(a4) # 80012898 <cons+0x98>
    800001f6:	b76d                	j	800001a0 <consoleread+0xc0>

00000000800001f8 <consputc>:
  if(panicked){
    800001f8:	0002a797          	auipc	a5,0x2a
    800001fc:	e207a783          	lw	a5,-480(a5) # 8002a018 <panicked>
    80000200:	c391                	beqz	a5,80000204 <consputc+0xc>
    for(;;)
    80000202:	a001                	j	80000202 <consputc+0xa>
{
    80000204:	1141                	addi	sp,sp,-16
    80000206:	e406                	sd	ra,8(sp)
    80000208:	e022                	sd	s0,0(sp)
    8000020a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000020c:	10000793          	li	a5,256
    80000210:	00f50a63          	beq	a0,a5,80000224 <consputc+0x2c>
    uartputc(c);
    80000214:	00000097          	auipc	ra,0x0
    80000218:	5d2080e7          	jalr	1490(ra) # 800007e6 <uartputc>
}
    8000021c:	60a2                	ld	ra,8(sp)
    8000021e:	6402                	ld	s0,0(sp)
    80000220:	0141                	addi	sp,sp,16
    80000222:	8082                	ret
    uartputc('\b'); uartputc(' '); uartputc('\b');
    80000224:	4521                	li	a0,8
    80000226:	00000097          	auipc	ra,0x0
    8000022a:	5c0080e7          	jalr	1472(ra) # 800007e6 <uartputc>
    8000022e:	02000513          	li	a0,32
    80000232:	00000097          	auipc	ra,0x0
    80000236:	5b4080e7          	jalr	1460(ra) # 800007e6 <uartputc>
    8000023a:	4521                	li	a0,8
    8000023c:	00000097          	auipc	ra,0x0
    80000240:	5aa080e7          	jalr	1450(ra) # 800007e6 <uartputc>
    80000244:	bfe1                	j	8000021c <consputc+0x24>

0000000080000246 <consolewrite>:
{
    80000246:	715d                	addi	sp,sp,-80
    80000248:	e486                	sd	ra,72(sp)
    8000024a:	e0a2                	sd	s0,64(sp)
    8000024c:	fc26                	sd	s1,56(sp)
    8000024e:	f84a                	sd	s2,48(sp)
    80000250:	f44e                	sd	s3,40(sp)
    80000252:	f052                	sd	s4,32(sp)
    80000254:	ec56                	sd	s5,24(sp)
    80000256:	0880                	addi	s0,sp,80
    80000258:	89aa                	mv	s3,a0
    8000025a:	84ae                	mv	s1,a1
    8000025c:	8ab2                	mv	s5,a2
  acquire(&cons.lock);
    8000025e:	00012517          	auipc	a0,0x12
    80000262:	5a250513          	addi	a0,a0,1442 # 80012800 <cons>
    80000266:	00000097          	auipc	ra,0x0
    8000026a:	766080e7          	jalr	1894(ra) # 800009cc <acquire>
  for(i = 0; i < n; i++){
    8000026e:	03505e63          	blez	s5,800002aa <consolewrite+0x64>
    80000272:	00148913          	addi	s2,s1,1
    80000276:	fffa879b          	addiw	a5,s5,-1
    8000027a:	1782                	slli	a5,a5,0x20
    8000027c:	9381                	srli	a5,a5,0x20
    8000027e:	993e                	add	s2,s2,a5
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000280:	5a7d                	li	s4,-1
    80000282:	4685                	li	a3,1
    80000284:	8626                	mv	a2,s1
    80000286:	85ce                	mv	a1,s3
    80000288:	fbf40513          	addi	a0,s0,-65
    8000028c:	00002097          	auipc	ra,0x2
    80000290:	0da080e7          	jalr	218(ra) # 80002366 <either_copyin>
    80000294:	01450b63          	beq	a0,s4,800002aa <consolewrite+0x64>
    consputc(c);
    80000298:	fbf44503          	lbu	a0,-65(s0)
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	f5c080e7          	jalr	-164(ra) # 800001f8 <consputc>
  for(i = 0; i < n; i++){
    800002a4:	0485                	addi	s1,s1,1
    800002a6:	fd249ee3          	bne	s1,s2,80000282 <consolewrite+0x3c>
  release(&cons.lock);
    800002aa:	00012517          	auipc	a0,0x12
    800002ae:	55650513          	addi	a0,a0,1366 # 80012800 <cons>
    800002b2:	00000097          	auipc	ra,0x0
    800002b6:	782080e7          	jalr	1922(ra) # 80000a34 <release>
}
    800002ba:	8556                	mv	a0,s5
    800002bc:	60a6                	ld	ra,72(sp)
    800002be:	6406                	ld	s0,64(sp)
    800002c0:	74e2                	ld	s1,56(sp)
    800002c2:	7942                	ld	s2,48(sp)
    800002c4:	79a2                	ld	s3,40(sp)
    800002c6:	7a02                	ld	s4,32(sp)
    800002c8:	6ae2                	ld	s5,24(sp)
    800002ca:	6161                	addi	sp,sp,80
    800002cc:	8082                	ret

00000000800002ce <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ce:	1101                	addi	sp,sp,-32
    800002d0:	ec06                	sd	ra,24(sp)
    800002d2:	e822                	sd	s0,16(sp)
    800002d4:	e426                	sd	s1,8(sp)
    800002d6:	e04a                	sd	s2,0(sp)
    800002d8:	1000                	addi	s0,sp,32
    800002da:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002dc:	00012517          	auipc	a0,0x12
    800002e0:	52450513          	addi	a0,a0,1316 # 80012800 <cons>
    800002e4:	00000097          	auipc	ra,0x0
    800002e8:	6e8080e7          	jalr	1768(ra) # 800009cc <acquire>

  switch(c){
    800002ec:	47d5                	li	a5,21
    800002ee:	0af48663          	beq	s1,a5,8000039a <consoleintr+0xcc>
    800002f2:	0297ca63          	blt	a5,s1,80000326 <consoleintr+0x58>
    800002f6:	47a1                	li	a5,8
    800002f8:	0ef48763          	beq	s1,a5,800003e6 <consoleintr+0x118>
    800002fc:	47c1                	li	a5,16
    800002fe:	10f49a63          	bne	s1,a5,80000412 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000302:	00002097          	auipc	ra,0x2
    80000306:	0ba080e7          	jalr	186(ra) # 800023bc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030a:	00012517          	auipc	a0,0x12
    8000030e:	4f650513          	addi	a0,a0,1270 # 80012800 <cons>
    80000312:	00000097          	auipc	ra,0x0
    80000316:	722080e7          	jalr	1826(ra) # 80000a34 <release>
}
    8000031a:	60e2                	ld	ra,24(sp)
    8000031c:	6442                	ld	s0,16(sp)
    8000031e:	64a2                	ld	s1,8(sp)
    80000320:	6902                	ld	s2,0(sp)
    80000322:	6105                	addi	sp,sp,32
    80000324:	8082                	ret
  switch(c){
    80000326:	07f00793          	li	a5,127
    8000032a:	0af48e63          	beq	s1,a5,800003e6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000032e:	00012717          	auipc	a4,0x12
    80000332:	4d270713          	addi	a4,a4,1234 # 80012800 <cons>
    80000336:	0a072783          	lw	a5,160(a4)
    8000033a:	09872703          	lw	a4,152(a4)
    8000033e:	9f99                	subw	a5,a5,a4
    80000340:	07f00713          	li	a4,127
    80000344:	fcf763e3          	bltu	a4,a5,8000030a <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000348:	47b5                	li	a5,13
    8000034a:	0cf48763          	beq	s1,a5,80000418 <consoleintr+0x14a>
      consputc(c);
    8000034e:	8526                	mv	a0,s1
    80000350:	00000097          	auipc	ra,0x0
    80000354:	ea8080e7          	jalr	-344(ra) # 800001f8 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000358:	00012797          	auipc	a5,0x12
    8000035c:	4a878793          	addi	a5,a5,1192 # 80012800 <cons>
    80000360:	0a07a703          	lw	a4,160(a5)
    80000364:	0017069b          	addiw	a3,a4,1
    80000368:	0006861b          	sext.w	a2,a3
    8000036c:	0ad7a023          	sw	a3,160(a5)
    80000370:	07f77713          	andi	a4,a4,127
    80000374:	97ba                	add	a5,a5,a4
    80000376:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037a:	47a9                	li	a5,10
    8000037c:	0cf48563          	beq	s1,a5,80000446 <consoleintr+0x178>
    80000380:	4791                	li	a5,4
    80000382:	0cf48263          	beq	s1,a5,80000446 <consoleintr+0x178>
    80000386:	00012797          	auipc	a5,0x12
    8000038a:	5127a783          	lw	a5,1298(a5) # 80012898 <cons+0x98>
    8000038e:	0807879b          	addiw	a5,a5,128
    80000392:	f6f61ce3          	bne	a2,a5,8000030a <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000396:	863e                	mv	a2,a5
    80000398:	a07d                	j	80000446 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039a:	00012717          	auipc	a4,0x12
    8000039e:	46670713          	addi	a4,a4,1126 # 80012800 <cons>
    800003a2:	0a072783          	lw	a5,160(a4)
    800003a6:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	00012497          	auipc	s1,0x12
    800003ae:	45648493          	addi	s1,s1,1110 # 80012800 <cons>
    while(cons.e != cons.w &&
    800003b2:	4929                	li	s2,10
    800003b4:	f4f70be3          	beq	a4,a5,8000030a <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b8:	37fd                	addiw	a5,a5,-1
    800003ba:	07f7f713          	andi	a4,a5,127
    800003be:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c0:	01874703          	lbu	a4,24(a4)
    800003c4:	f52703e3          	beq	a4,s2,8000030a <consoleintr+0x3c>
      cons.e--;
    800003c8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003cc:	10000513          	li	a0,256
    800003d0:	00000097          	auipc	ra,0x0
    800003d4:	e28080e7          	jalr	-472(ra) # 800001f8 <consputc>
    while(cons.e != cons.w &&
    800003d8:	0a04a783          	lw	a5,160(s1)
    800003dc:	09c4a703          	lw	a4,156(s1)
    800003e0:	fcf71ce3          	bne	a4,a5,800003b8 <consoleintr+0xea>
    800003e4:	b71d                	j	8000030a <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e6:	00012717          	auipc	a4,0x12
    800003ea:	41a70713          	addi	a4,a4,1050 # 80012800 <cons>
    800003ee:	0a072783          	lw	a5,160(a4)
    800003f2:	09c72703          	lw	a4,156(a4)
    800003f6:	f0f70ae3          	beq	a4,a5,8000030a <consoleintr+0x3c>
      cons.e--;
    800003fa:	37fd                	addiw	a5,a5,-1
    800003fc:	00012717          	auipc	a4,0x12
    80000400:	4af72223          	sw	a5,1188(a4) # 800128a0 <cons+0xa0>
      consputc(BACKSPACE);
    80000404:	10000513          	li	a0,256
    80000408:	00000097          	auipc	ra,0x0
    8000040c:	df0080e7          	jalr	-528(ra) # 800001f8 <consputc>
    80000410:	bded                	j	8000030a <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000412:	ee048ce3          	beqz	s1,8000030a <consoleintr+0x3c>
    80000416:	bf21                	j	8000032e <consoleintr+0x60>
      consputc(c);
    80000418:	4529                	li	a0,10
    8000041a:	00000097          	auipc	ra,0x0
    8000041e:	dde080e7          	jalr	-546(ra) # 800001f8 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000422:	00012797          	auipc	a5,0x12
    80000426:	3de78793          	addi	a5,a5,990 # 80012800 <cons>
    8000042a:	0a07a703          	lw	a4,160(a5)
    8000042e:	0017069b          	addiw	a3,a4,1
    80000432:	0006861b          	sext.w	a2,a3
    80000436:	0ad7a023          	sw	a3,160(a5)
    8000043a:	07f77713          	andi	a4,a4,127
    8000043e:	97ba                	add	a5,a5,a4
    80000440:	4729                	li	a4,10
    80000442:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000446:	00012797          	auipc	a5,0x12
    8000044a:	44c7ab23          	sw	a2,1110(a5) # 8001289c <cons+0x9c>
        wakeup(&cons.r);
    8000044e:	00012517          	auipc	a0,0x12
    80000452:	44a50513          	addi	a0,a0,1098 # 80012898 <cons+0x98>
    80000456:	00002097          	auipc	ra,0x2
    8000045a:	de0080e7          	jalr	-544(ra) # 80002236 <wakeup>
    8000045e:	b575                	j	8000030a <consoleintr+0x3c>

0000000080000460 <consoleinit>:

void
consoleinit(void)
{
    80000460:	1141                	addi	sp,sp,-16
    80000462:	e406                	sd	ra,8(sp)
    80000464:	e022                	sd	s0,0(sp)
    80000466:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000468:	00008597          	auipc	a1,0x8
    8000046c:	cb058593          	addi	a1,a1,-848 # 80008118 <userret+0x88>
    80000470:	00012517          	auipc	a0,0x12
    80000474:	39050513          	addi	a0,a0,912 # 80012800 <cons>
    80000478:	00000097          	auipc	ra,0x0
    8000047c:	442080e7          	jalr	1090(ra) # 800008ba <initlock>

  uartinit();
    80000480:	00000097          	auipc	ra,0x0
    80000484:	330080e7          	jalr	816(ra) # 800007b0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000488:	00022797          	auipc	a5,0x22
    8000048c:	64078793          	addi	a5,a5,1600 # 80022ac8 <devsw>
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c5070713          	addi	a4,a4,-944 # 800000e0 <consoleread>
    80000498:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049a:	00000717          	auipc	a4,0x0
    8000049e:	dac70713          	addi	a4,a4,-596 # 80000246 <consolewrite>
    800004a2:	ef98                	sd	a4,24(a5)
}
    800004a4:	60a2                	ld	ra,8(sp)
    800004a6:	6402                	ld	s0,0(sp)
    800004a8:	0141                	addi	sp,sp,16
    800004aa:	8082                	ret

00000000800004ac <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ac:	7179                	addi	sp,sp,-48
    800004ae:	f406                	sd	ra,40(sp)
    800004b0:	f022                	sd	s0,32(sp)
    800004b2:	ec26                	sd	s1,24(sp)
    800004b4:	e84a                	sd	s2,16(sp)
    800004b6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b8:	c219                	beqz	a2,800004be <printint+0x12>
    800004ba:	08054663          	bltz	a0,80000546 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004be:	2501                	sext.w	a0,a0
    800004c0:	4881                	li	a7,0
    800004c2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c8:	2581                	sext.w	a1,a1
    800004ca:	00008617          	auipc	a2,0x8
    800004ce:	53e60613          	addi	a2,a2,1342 # 80008a08 <digits>
    800004d2:	883a                	mv	a6,a4
    800004d4:	2705                	addiw	a4,a4,1
    800004d6:	02b577bb          	remuw	a5,a0,a1
    800004da:	1782                	slli	a5,a5,0x20
    800004dc:	9381                	srli	a5,a5,0x20
    800004de:	97b2                	add	a5,a5,a2
    800004e0:	0007c783          	lbu	a5,0(a5)
    800004e4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e8:	0005079b          	sext.w	a5,a0
    800004ec:	02b5553b          	divuw	a0,a0,a1
    800004f0:	0685                	addi	a3,a3,1
    800004f2:	feb7f0e3          	bgeu	a5,a1,800004d2 <printint+0x26>

  if(sign)
    800004f6:	00088b63          	beqz	a7,8000050c <printint+0x60>
    buf[i++] = '-';
    800004fa:	fe040793          	addi	a5,s0,-32
    800004fe:	973e                	add	a4,a4,a5
    80000500:	02d00793          	li	a5,45
    80000504:	fef70823          	sb	a5,-16(a4)
    80000508:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050c:	02e05763          	blez	a4,8000053a <printint+0x8e>
    80000510:	fd040793          	addi	a5,s0,-48
    80000514:	00e784b3          	add	s1,a5,a4
    80000518:	fff78913          	addi	s2,a5,-1
    8000051c:	993a                	add	s2,s2,a4
    8000051e:	377d                	addiw	a4,a4,-1
    80000520:	1702                	slli	a4,a4,0x20
    80000522:	9301                	srli	a4,a4,0x20
    80000524:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000528:	fff4c503          	lbu	a0,-1(s1)
    8000052c:	00000097          	auipc	ra,0x0
    80000530:	ccc080e7          	jalr	-820(ra) # 800001f8 <consputc>
  while(--i >= 0)
    80000534:	14fd                	addi	s1,s1,-1
    80000536:	ff2499e3          	bne	s1,s2,80000528 <printint+0x7c>
}
    8000053a:	70a2                	ld	ra,40(sp)
    8000053c:	7402                	ld	s0,32(sp)
    8000053e:	64e2                	ld	s1,24(sp)
    80000540:	6942                	ld	s2,16(sp)
    80000542:	6145                	addi	sp,sp,48
    80000544:	8082                	ret
    x = -xx;
    80000546:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054a:	4885                	li	a7,1
    x = -xx;
    8000054c:	bf9d                	j	800004c2 <printint+0x16>

000000008000054e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000054e:	1101                	addi	sp,sp,-32
    80000550:	ec06                	sd	ra,24(sp)
    80000552:	e822                	sd	s0,16(sp)
    80000554:	e426                	sd	s1,8(sp)
    80000556:	1000                	addi	s0,sp,32
    80000558:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055a:	00012797          	auipc	a5,0x12
    8000055e:	3607a323          	sw	zero,870(a5) # 800128c0 <pr+0x18>
  printf("panic: ");
    80000562:	00008517          	auipc	a0,0x8
    80000566:	bbe50513          	addi	a0,a0,-1090 # 80008120 <userret+0x90>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
  printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
  printf("\n");
    8000057c:	00008517          	auipc	a0,0x8
    80000580:	c2450513          	addi	a0,a0,-988 # 800081a0 <userret+0x110>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
  panicked = 1; // freeze other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	0002a717          	auipc	a4,0x2a
    80000592:	a8f72523          	sw	a5,-1398(a4) # 8002a018 <panicked>
  for(;;)
    80000596:	a001                	j	80000596 <panic+0x48>

0000000080000598 <printf>:
{
    80000598:	7131                	addi	sp,sp,-192
    8000059a:	fc86                	sd	ra,120(sp)
    8000059c:	f8a2                	sd	s0,112(sp)
    8000059e:	f4a6                	sd	s1,104(sp)
    800005a0:	f0ca                	sd	s2,96(sp)
    800005a2:	ecce                	sd	s3,88(sp)
    800005a4:	e8d2                	sd	s4,80(sp)
    800005a6:	e4d6                	sd	s5,72(sp)
    800005a8:	e0da                	sd	s6,64(sp)
    800005aa:	fc5e                	sd	s7,56(sp)
    800005ac:	f862                	sd	s8,48(sp)
    800005ae:	f466                	sd	s9,40(sp)
    800005b0:	f06a                	sd	s10,32(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00012d97          	auipc	s11,0x12
    800005ce:	2f6dad83          	lw	s11,758(s11) # 800128c0 <pr+0x18>
  if(locking)
    800005d2:	020d9b63          	bnez	s11,80000608 <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0263          	beqz	s4,8000061a <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	16050263          	beqz	a0,8000074a <printf+0x1b2>
    800005ea:	4481                	li	s1,0
    if(c != '%'){
    800005ec:	02500a93          	li	s5,37
    switch(c){
    800005f0:	07000b13          	li	s6,112
  consputc('x');
    800005f4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f6:	00008b97          	auipc	s7,0x8
    800005fa:	412b8b93          	addi	s7,s7,1042 # 80008a08 <digits>
    switch(c){
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
    acquire(&pr.lock);
    80000608:	00012517          	auipc	a0,0x12
    8000060c:	2a050513          	addi	a0,a0,672 # 800128a8 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	3bc080e7          	jalr	956(ra) # 800009cc <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
    panic("null fmt");
    8000061a:	00008517          	auipc	a0,0x8
    8000061e:	b1650513          	addi	a0,a0,-1258 # 80008130 <userret+0xa0>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	f2c080e7          	jalr	-212(ra) # 8000054e <panic>
      consputc(c);
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	bce080e7          	jalr	-1074(ra) # 800001f8 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000632:	2485                	addiw	s1,s1,1
    80000634:	009a07b3          	add	a5,s4,s1
    80000638:	0007c503          	lbu	a0,0(a5)
    8000063c:	10050763          	beqz	a0,8000074a <printf+0x1b2>
    if(c != '%'){
    80000640:	ff5515e3          	bne	a0,s5,8000062a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000644:	2485                	addiw	s1,s1,1
    80000646:	009a07b3          	add	a5,s4,s1
    8000064a:	0007c783          	lbu	a5,0(a5)
    8000064e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000652:	cfe5                	beqz	a5,8000074a <printf+0x1b2>
    switch(c){
    80000654:	05678a63          	beq	a5,s6,800006a8 <printf+0x110>
    80000658:	02fb7663          	bgeu	s6,a5,80000684 <printf+0xec>
    8000065c:	09978963          	beq	a5,s9,800006ee <printf+0x156>
    80000660:	07800713          	li	a4,120
    80000664:	0ce79863          	bne	a5,a4,80000734 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	85ea                	mv	a1,s10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e32080e7          	jalr	-462(ra) # 800004ac <printint>
      break;
    80000682:	bf45                	j	80000632 <printf+0x9a>
    switch(c){
    80000684:	0b578263          	beq	a5,s5,80000728 <printf+0x190>
    80000688:	0b879663          	bne	a5,s8,80000734 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068c:	f8843783          	ld	a5,-120(s0)
    80000690:	00878713          	addi	a4,a5,8
    80000694:	f8e43423          	sd	a4,-120(s0)
    80000698:	4605                	li	a2,1
    8000069a:	45a9                	li	a1,10
    8000069c:	4388                	lw	a0,0(a5)
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	e0e080e7          	jalr	-498(ra) # 800004ac <printint>
      break;
    800006a6:	b771                	j	80000632 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a8:	f8843783          	ld	a5,-120(s0)
    800006ac:	00878713          	addi	a4,a5,8
    800006b0:	f8e43423          	sd	a4,-120(s0)
    800006b4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b8:	03000513          	li	a0,48
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	b3c080e7          	jalr	-1220(ra) # 800001f8 <consputc>
  consputc('x');
    800006c4:	07800513          	li	a0,120
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	b30080e7          	jalr	-1232(ra) # 800001f8 <consputc>
    800006d0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d2:	03c9d793          	srli	a5,s3,0x3c
    800006d6:	97de                	add	a5,a5,s7
    800006d8:	0007c503          	lbu	a0,0(a5)
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	b1c080e7          	jalr	-1252(ra) # 800001f8 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e4:	0992                	slli	s3,s3,0x4
    800006e6:	397d                	addiw	s2,s2,-1
    800006e8:	fe0915e3          	bnez	s2,800006d2 <printf+0x13a>
    800006ec:	b799                	j	80000632 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006ee:	f8843783          	ld	a5,-120(s0)
    800006f2:	00878713          	addi	a4,a5,8
    800006f6:	f8e43423          	sd	a4,-120(s0)
    800006fa:	0007b903          	ld	s2,0(a5)
    800006fe:	00090e63          	beqz	s2,8000071a <printf+0x182>
      for(; *s; s++)
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	d515                	beqz	a0,80000632 <printf+0x9a>
        consputc(*s);
    80000708:	00000097          	auipc	ra,0x0
    8000070c:	af0080e7          	jalr	-1296(ra) # 800001f8 <consputc>
      for(; *s; s++)
    80000710:	0905                	addi	s2,s2,1
    80000712:	00094503          	lbu	a0,0(s2)
    80000716:	f96d                	bnez	a0,80000708 <printf+0x170>
    80000718:	bf29                	j	80000632 <printf+0x9a>
        s = "(null)";
    8000071a:	00008917          	auipc	s2,0x8
    8000071e:	a0e90913          	addi	s2,s2,-1522 # 80008128 <userret+0x98>
      for(; *s; s++)
    80000722:	02800513          	li	a0,40
    80000726:	b7cd                	j	80000708 <printf+0x170>
      consputc('%');
    80000728:	8556                	mv	a0,s5
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	ace080e7          	jalr	-1330(ra) # 800001f8 <consputc>
      break;
    80000732:	b701                	j	80000632 <printf+0x9a>
      consputc('%');
    80000734:	8556                	mv	a0,s5
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	ac2080e7          	jalr	-1342(ra) # 800001f8 <consputc>
      consputc(c);
    8000073e:	854a                	mv	a0,s2
    80000740:	00000097          	auipc	ra,0x0
    80000744:	ab8080e7          	jalr	-1352(ra) # 800001f8 <consputc>
      break;
    80000748:	b5ed                	j	80000632 <printf+0x9a>
  if(locking)
    8000074a:	020d9163          	bnez	s11,8000076c <printf+0x1d4>
}
    8000074e:	70e6                	ld	ra,120(sp)
    80000750:	7446                	ld	s0,112(sp)
    80000752:	74a6                	ld	s1,104(sp)
    80000754:	7906                	ld	s2,96(sp)
    80000756:	69e6                	ld	s3,88(sp)
    80000758:	6a46                	ld	s4,80(sp)
    8000075a:	6aa6                	ld	s5,72(sp)
    8000075c:	6b06                	ld	s6,64(sp)
    8000075e:	7be2                	ld	s7,56(sp)
    80000760:	7c42                	ld	s8,48(sp)
    80000762:	7ca2                	ld	s9,40(sp)
    80000764:	7d02                	ld	s10,32(sp)
    80000766:	6de2                	ld	s11,24(sp)
    80000768:	6129                	addi	sp,sp,192
    8000076a:	8082                	ret
    release(&pr.lock);
    8000076c:	00012517          	auipc	a0,0x12
    80000770:	13c50513          	addi	a0,a0,316 # 800128a8 <pr>
    80000774:	00000097          	auipc	ra,0x0
    80000778:	2c0080e7          	jalr	704(ra) # 80000a34 <release>
}
    8000077c:	bfc9                	j	8000074e <printf+0x1b6>

000000008000077e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000077e:	1101                	addi	sp,sp,-32
    80000780:	ec06                	sd	ra,24(sp)
    80000782:	e822                	sd	s0,16(sp)
    80000784:	e426                	sd	s1,8(sp)
    80000786:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000788:	00012497          	auipc	s1,0x12
    8000078c:	12048493          	addi	s1,s1,288 # 800128a8 <pr>
    80000790:	00008597          	auipc	a1,0x8
    80000794:	9b058593          	addi	a1,a1,-1616 # 80008140 <userret+0xb0>
    80000798:	8526                	mv	a0,s1
    8000079a:	00000097          	auipc	ra,0x0
    8000079e:	120080e7          	jalr	288(ra) # 800008ba <initlock>
  pr.locking = 1;
    800007a2:	4785                	li	a5,1
    800007a4:	cc9c                	sw	a5,24(s1)
}
    800007a6:	60e2                	ld	ra,24(sp)
    800007a8:	6442                	ld	s0,16(sp)
    800007aa:	64a2                	ld	s1,8(sp)
    800007ac:	6105                	addi	sp,sp,32
    800007ae:	8082                	ret

00000000800007b0 <uartinit>:
#define ReadReg(reg) (*(Reg(reg)))
#define WriteReg(reg, v) (*(Reg(reg)) = (v))

void
uartinit(void)
{
    800007b0:	1141                	addi	sp,sp,-16
    800007b2:	e422                	sd	s0,8(sp)
    800007b4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b6:	100007b7          	lui	a5,0x10000
    800007ba:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, 0x80);
    800007be:	f8000713          	li	a4,-128
    800007c2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c6:	470d                	li	a4,3
    800007c8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007cc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, 0x03);
    800007d0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, 0x07);
    800007d4:	471d                	li	a4,7
    800007d6:	00e78123          	sb	a4,2(a5)

  // enable receive interrupts.
  WriteReg(IER, 0x01);
    800007da:	4705                	li	a4,1
    800007dc:	00e780a3          	sb	a4,1(a5)
}
    800007e0:	6422                	ld	s0,8(sp)
    800007e2:	0141                	addi	sp,sp,16
    800007e4:	8082                	ret

00000000800007e6 <uartputc>:

// write one output character to the UART.
void
uartputc(int c)
{
    800007e6:	1141                	addi	sp,sp,-16
    800007e8:	e422                	sd	s0,8(sp)
    800007ea:	0800                	addi	s0,sp,16
  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & (1 << 5)) == 0)
    800007ec:	10000737          	lui	a4,0x10000
    800007f0:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007f4:	0ff7f793          	andi	a5,a5,255
    800007f8:	0207f793          	andi	a5,a5,32
    800007fc:	dbf5                	beqz	a5,800007f0 <uartputc+0xa>
    ;
  WriteReg(THR, c);
    800007fe:	0ff57513          	andi	a0,a0,255
    80000802:	100007b7          	lui	a5,0x10000
    80000806:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>
}
    8000080a:	6422                	ld	s0,8(sp)
    8000080c:	0141                	addi	sp,sp,16
    8000080e:	8082                	ret

0000000080000810 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000810:	1141                	addi	sp,sp,-16
    80000812:	e422                	sd	s0,8(sp)
    80000814:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000816:	100007b7          	lui	a5,0x10000
    8000081a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000081e:	8b85                	andi	a5,a5,1
    80000820:	cb81                	beqz	a5,80000830 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000082a:	6422                	ld	s0,8(sp)
    8000082c:	0141                	addi	sp,sp,16
    8000082e:	8082                	ret
    return -1;
    80000830:	557d                	li	a0,-1
    80000832:	bfe5                	j	8000082a <uartgetc+0x1a>

0000000080000834 <uartintr>:

// trap.c calls here when the uart interrupts.
void
uartintr(void)
{
    80000834:	1101                	addi	sp,sp,-32
    80000836:	ec06                	sd	ra,24(sp)
    80000838:	e822                	sd	s0,16(sp)
    8000083a:	e426                	sd	s1,8(sp)
    8000083c:	1000                	addi	s0,sp,32
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000083e:	54fd                	li	s1,-1
    int c = uartgetc();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	fd0080e7          	jalr	-48(ra) # 80000810 <uartgetc>
    if(c == -1)
    80000848:	00950763          	beq	a0,s1,80000856 <uartintr+0x22>
      break;
    consoleintr(c);
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	a82080e7          	jalr	-1406(ra) # 800002ce <consoleintr>
  while(1){
    80000854:	b7f5                	j	80000840 <uartintr+0xc>
  }
}
    80000856:	60e2                	ld	ra,24(sp)
    80000858:	6442                	ld	s0,16(sp)
    8000085a:	64a2                	ld	s1,8(sp)
    8000085c:	6105                	addi	sp,sp,32
    8000085e:	8082                	ret

0000000080000860 <kinit>:

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.
void
kinit()
{
    80000860:	1141                	addi	sp,sp,-16
    80000862:	e406                	sd	ra,8(sp)
    80000864:	e022                	sd	s0,0(sp)
    80000866:	0800                	addi	s0,sp,16
  char *p = (char *) PGROUNDUP((uint64) end);
  bd_init(p, (void*)PHYSTOP);
    80000868:	45c5                	li	a1,17
    8000086a:	05ee                	slli	a1,a1,0x1b
    8000086c:	0002a517          	auipc	a0,0x2a
    80000870:	7ef50513          	addi	a0,a0,2031 # 8002b05b <end+0xfff>
    80000874:	77fd                	lui	a5,0xfffff
    80000876:	8d7d                	and	a0,a0,a5
    80000878:	00006097          	auipc	ra,0x6
    8000087c:	51a080e7          	jalr	1306(ra) # 80006d92 <bd_init>
}
    80000880:	60a2                	ld	ra,8(sp)
    80000882:	6402                	ld	s0,0(sp)
    80000884:	0141                	addi	sp,sp,16
    80000886:	8082                	ret

0000000080000888 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000888:	1141                	addi	sp,sp,-16
    8000088a:	e406                	sd	ra,8(sp)
    8000088c:	e022                	sd	s0,0(sp)
    8000088e:	0800                	addi	s0,sp,16
  bd_free(pa);
    80000890:	00006097          	auipc	ra,0x6
    80000894:	044080e7          	jalr	68(ra) # 800068d4 <bd_free>
}
    80000898:	60a2                	ld	ra,8(sp)
    8000089a:	6402                	ld	s0,0(sp)
    8000089c:	0141                	addi	sp,sp,16
    8000089e:	8082                	ret

00000000800008a0 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    800008a0:	1141                	addi	sp,sp,-16
    800008a2:	e406                	sd	ra,8(sp)
    800008a4:	e022                	sd	s0,0(sp)
    800008a6:	0800                	addi	s0,sp,16
  return bd_malloc(PGSIZE);
    800008a8:	6505                	lui	a0,0x1
    800008aa:	00006097          	auipc	ra,0x6
    800008ae:	e3e080e7          	jalr	-450(ra) # 800066e8 <bd_malloc>
}
    800008b2:	60a2                	ld	ra,8(sp)
    800008b4:	6402                	ld	s0,0(sp)
    800008b6:	0141                	addi	sp,sp,16
    800008b8:	8082                	ret

00000000800008ba <initlock>:

uint64 ntest_and_set;

void
initlock(struct spinlock *lk, char *name)
{
    800008ba:	1141                	addi	sp,sp,-16
    800008bc:	e422                	sd	s0,8(sp)
    800008be:	0800                	addi	s0,sp,16
  lk->name = name;
    800008c0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    800008c2:	00052023          	sw	zero,0(a0) # 1000 <_entry-0x7ffff000>
  lk->cpu = 0;
    800008c6:	00053823          	sd	zero,16(a0)
}
    800008ca:	6422                	ld	s0,8(sp)
    800008cc:	0141                	addi	sp,sp,16
    800008ce:	8082                	ret

00000000800008d0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800008d0:	1101                	addi	sp,sp,-32
    800008d2:	ec06                	sd	ra,24(sp)
    800008d4:	e822                	sd	s0,16(sp)
    800008d6:	e426                	sd	s1,8(sp)
    800008d8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800008da:	100024f3          	csrr	s1,sstatus
    800008de:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800008e2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800008e4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800008e8:	00001097          	auipc	ra,0x1
    800008ec:	f9a080e7          	jalr	-102(ra) # 80001882 <mycpu>
    800008f0:	5d3c                	lw	a5,120(a0)
    800008f2:	cf89                	beqz	a5,8000090c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800008f4:	00001097          	auipc	ra,0x1
    800008f8:	f8e080e7          	jalr	-114(ra) # 80001882 <mycpu>
    800008fc:	5d3c                	lw	a5,120(a0)
    800008fe:	2785                	addiw	a5,a5,1
    80000900:	dd3c                	sw	a5,120(a0)
}
    80000902:	60e2                	ld	ra,24(sp)
    80000904:	6442                	ld	s0,16(sp)
    80000906:	64a2                	ld	s1,8(sp)
    80000908:	6105                	addi	sp,sp,32
    8000090a:	8082                	ret
    mycpu()->intena = old;
    8000090c:	00001097          	auipc	ra,0x1
    80000910:	f76080e7          	jalr	-138(ra) # 80001882 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000914:	8085                	srli	s1,s1,0x1
    80000916:	8885                	andi	s1,s1,1
    80000918:	dd64                	sw	s1,124(a0)
    8000091a:	bfe9                	j	800008f4 <push_off+0x24>

000000008000091c <pop_off>:

void
pop_off(void)
{
    8000091c:	1141                	addi	sp,sp,-16
    8000091e:	e406                	sd	ra,8(sp)
    80000920:	e022                	sd	s0,0(sp)
    80000922:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000924:	00001097          	auipc	ra,0x1
    80000928:	f5e080e7          	jalr	-162(ra) # 80001882 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000092c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000930:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000932:	ef8d                	bnez	a5,8000096c <pop_off+0x50>
    panic("pop_off - interruptible");
  c->noff -= 1;
    80000934:	5d3c                	lw	a5,120(a0)
    80000936:	37fd                	addiw	a5,a5,-1
    80000938:	0007871b          	sext.w	a4,a5
    8000093c:	dd3c                	sw	a5,120(a0)
  if(c->noff < 0)
    8000093e:	02079693          	slli	a3,a5,0x20
    80000942:	0206cd63          	bltz	a3,8000097c <pop_off+0x60>
    panic("pop_off");
  if(c->noff == 0 && c->intena)
    80000946:	ef19                	bnez	a4,80000964 <pop_off+0x48>
    80000948:	5d7c                	lw	a5,124(a0)
    8000094a:	cf89                	beqz	a5,80000964 <pop_off+0x48>
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000094c:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80000950:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000954:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000958:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000095c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000960:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000964:	60a2                	ld	ra,8(sp)
    80000966:	6402                	ld	s0,0(sp)
    80000968:	0141                	addi	sp,sp,16
    8000096a:	8082                	ret
    panic("pop_off - interruptible");
    8000096c:	00007517          	auipc	a0,0x7
    80000970:	7dc50513          	addi	a0,a0,2012 # 80008148 <userret+0xb8>
    80000974:	00000097          	auipc	ra,0x0
    80000978:	bda080e7          	jalr	-1062(ra) # 8000054e <panic>
    panic("pop_off");
    8000097c:	00007517          	auipc	a0,0x7
    80000980:	7e450513          	addi	a0,a0,2020 # 80008160 <userret+0xd0>
    80000984:	00000097          	auipc	ra,0x0
    80000988:	bca080e7          	jalr	-1078(ra) # 8000054e <panic>

000000008000098c <holding>:
{
    8000098c:	1101                	addi	sp,sp,-32
    8000098e:	ec06                	sd	ra,24(sp)
    80000990:	e822                	sd	s0,16(sp)
    80000992:	e426                	sd	s1,8(sp)
    80000994:	1000                	addi	s0,sp,32
    80000996:	84aa                	mv	s1,a0
  push_off();
    80000998:	00000097          	auipc	ra,0x0
    8000099c:	f38080e7          	jalr	-200(ra) # 800008d0 <push_off>
  r = (lk->locked && lk->cpu == mycpu());
    800009a0:	409c                	lw	a5,0(s1)
    800009a2:	ef81                	bnez	a5,800009ba <holding+0x2e>
    800009a4:	4481                	li	s1,0
  pop_off();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	f76080e7          	jalr	-138(ra) # 8000091c <pop_off>
}
    800009ae:	8526                	mv	a0,s1
    800009b0:	60e2                	ld	ra,24(sp)
    800009b2:	6442                	ld	s0,16(sp)
    800009b4:	64a2                	ld	s1,8(sp)
    800009b6:	6105                	addi	sp,sp,32
    800009b8:	8082                	ret
  r = (lk->locked && lk->cpu == mycpu());
    800009ba:	6884                	ld	s1,16(s1)
    800009bc:	00001097          	auipc	ra,0x1
    800009c0:	ec6080e7          	jalr	-314(ra) # 80001882 <mycpu>
    800009c4:	8c89                	sub	s1,s1,a0
    800009c6:	0014b493          	seqz	s1,s1
    800009ca:	bff1                	j	800009a6 <holding+0x1a>

00000000800009cc <acquire>:
{
    800009cc:	1101                	addi	sp,sp,-32
    800009ce:	ec06                	sd	ra,24(sp)
    800009d0:	e822                	sd	s0,16(sp)
    800009d2:	e426                	sd	s1,8(sp)
    800009d4:	1000                	addi	s0,sp,32
    800009d6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	ef8080e7          	jalr	-264(ra) # 800008d0 <push_off>
  if(holding(lk))
    800009e0:	8526                	mv	a0,s1
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	faa080e7          	jalr	-86(ra) # 8000098c <holding>
    800009ea:	e901                	bnez	a0,800009fa <acquire+0x2e>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    800009ec:	4685                	li	a3,1
     __sync_fetch_and_add(&ntest_and_set, 1);
    800009ee:	00029717          	auipc	a4,0x29
    800009f2:	63270713          	addi	a4,a4,1586 # 8002a020 <ntest_and_set>
    800009f6:	4605                	li	a2,1
    800009f8:	a829                	j	80000a12 <acquire+0x46>
    panic("acquire");
    800009fa:	00007517          	auipc	a0,0x7
    800009fe:	76e50513          	addi	a0,a0,1902 # 80008168 <userret+0xd8>
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	b4c080e7          	jalr	-1204(ra) # 8000054e <panic>
     __sync_fetch_and_add(&ntest_and_set, 1);
    80000a0a:	0f50000f          	fence	iorw,ow
    80000a0e:	04c7302f          	amoadd.d.aq	zero,a2,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000a12:	87b6                	mv	a5,a3
    80000a14:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000a18:	2781                	sext.w	a5,a5
    80000a1a:	fbe5                	bnez	a5,80000a0a <acquire+0x3e>
  __sync_synchronize();
    80000a1c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000a20:	00001097          	auipc	ra,0x1
    80000a24:	e62080e7          	jalr	-414(ra) # 80001882 <mycpu>
    80000a28:	e888                	sd	a0,16(s1)
}
    80000a2a:	60e2                	ld	ra,24(sp)
    80000a2c:	6442                	ld	s0,16(sp)
    80000a2e:	64a2                	ld	s1,8(sp)
    80000a30:	6105                	addi	sp,sp,32
    80000a32:	8082                	ret

0000000080000a34 <release>:
{
    80000a34:	1101                	addi	sp,sp,-32
    80000a36:	ec06                	sd	ra,24(sp)
    80000a38:	e822                	sd	s0,16(sp)
    80000a3a:	e426                	sd	s1,8(sp)
    80000a3c:	1000                	addi	s0,sp,32
    80000a3e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000a40:	00000097          	auipc	ra,0x0
    80000a44:	f4c080e7          	jalr	-180(ra) # 8000098c <holding>
    80000a48:	c115                	beqz	a0,80000a6c <release+0x38>
  lk->cpu = 0;
    80000a4a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000a4e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000a52:	0f50000f          	fence	iorw,ow
    80000a56:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000a5a:	00000097          	auipc	ra,0x0
    80000a5e:	ec2080e7          	jalr	-318(ra) # 8000091c <pop_off>
}
    80000a62:	60e2                	ld	ra,24(sp)
    80000a64:	6442                	ld	s0,16(sp)
    80000a66:	64a2                	ld	s1,8(sp)
    80000a68:	6105                	addi	sp,sp,32
    80000a6a:	8082                	ret
    panic("release");
    80000a6c:	00007517          	auipc	a0,0x7
    80000a70:	70450513          	addi	a0,a0,1796 # 80008170 <userret+0xe0>
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	ada080e7          	jalr	-1318(ra) # 8000054e <panic>

0000000080000a7c <sys_ntas>:

uint64
sys_ntas(void)
{
    80000a7c:	1141                	addi	sp,sp,-16
    80000a7e:	e422                	sd	s0,8(sp)
    80000a80:	0800                	addi	s0,sp,16
  return ntest_and_set;
}
    80000a82:	00029517          	auipc	a0,0x29
    80000a86:	59e53503          	ld	a0,1438(a0) # 8002a020 <ntest_and_set>
    80000a8a:	6422                	ld	s0,8(sp)
    80000a8c:	0141                	addi	sp,sp,16
    80000a8e:	8082                	ret

0000000080000a90 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000a90:	1141                	addi	sp,sp,-16
    80000a92:	e422                	sd	s0,8(sp)
    80000a94:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000a96:	ce09                	beqz	a2,80000ab0 <memset+0x20>
    80000a98:	87aa                	mv	a5,a0
    80000a9a:	fff6071b          	addiw	a4,a2,-1
    80000a9e:	1702                	slli	a4,a4,0x20
    80000aa0:	9301                	srli	a4,a4,0x20
    80000aa2:	0705                	addi	a4,a4,1
    80000aa4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000aa6:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7ffd4fa4>
  for(i = 0; i < n; i++){
    80000aaa:	0785                	addi	a5,a5,1
    80000aac:	fee79de3          	bne	a5,a4,80000aa6 <memset+0x16>
  }
  return dst;
}
    80000ab0:	6422                	ld	s0,8(sp)
    80000ab2:	0141                	addi	sp,sp,16
    80000ab4:	8082                	ret

0000000080000ab6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ab6:	1141                	addi	sp,sp,-16
    80000ab8:	e422                	sd	s0,8(sp)
    80000aba:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000abc:	ca05                	beqz	a2,80000aec <memcmp+0x36>
    80000abe:	fff6069b          	addiw	a3,a2,-1
    80000ac2:	1682                	slli	a3,a3,0x20
    80000ac4:	9281                	srli	a3,a3,0x20
    80000ac6:	0685                	addi	a3,a3,1
    80000ac8:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000aca:	00054783          	lbu	a5,0(a0)
    80000ace:	0005c703          	lbu	a4,0(a1)
    80000ad2:	00e79863          	bne	a5,a4,80000ae2 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ad6:	0505                	addi	a0,a0,1
    80000ad8:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ada:	fed518e3          	bne	a0,a3,80000aca <memcmp+0x14>
  }

  return 0;
    80000ade:	4501                	li	a0,0
    80000ae0:	a019                	j	80000ae6 <memcmp+0x30>
      return *s1 - *s2;
    80000ae2:	40e7853b          	subw	a0,a5,a4
}
    80000ae6:	6422                	ld	s0,8(sp)
    80000ae8:	0141                	addi	sp,sp,16
    80000aea:	8082                	ret
  return 0;
    80000aec:	4501                	li	a0,0
    80000aee:	bfe5                	j	80000ae6 <memcmp+0x30>

0000000080000af0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000af0:	1141                	addi	sp,sp,-16
    80000af2:	e422                	sd	s0,8(sp)
    80000af4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000af6:	02a5e563          	bltu	a1,a0,80000b20 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000afa:	fff6069b          	addiw	a3,a2,-1
    80000afe:	ce11                	beqz	a2,80000b1a <memmove+0x2a>
    80000b00:	1682                	slli	a3,a3,0x20
    80000b02:	9281                	srli	a3,a3,0x20
    80000b04:	0685                	addi	a3,a3,1
    80000b06:	96ae                	add	a3,a3,a1
    80000b08:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000b0a:	0585                	addi	a1,a1,1
    80000b0c:	0785                	addi	a5,a5,1
    80000b0e:	fff5c703          	lbu	a4,-1(a1)
    80000b12:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000b16:	fed59ae3          	bne	a1,a3,80000b0a <memmove+0x1a>

  return dst;
}
    80000b1a:	6422                	ld	s0,8(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret
  if(s < d && s + n > d){
    80000b20:	02061713          	slli	a4,a2,0x20
    80000b24:	9301                	srli	a4,a4,0x20
    80000b26:	00e587b3          	add	a5,a1,a4
    80000b2a:	fcf578e3          	bgeu	a0,a5,80000afa <memmove+0xa>
    d += n;
    80000b2e:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000b30:	fff6069b          	addiw	a3,a2,-1
    80000b34:	d27d                	beqz	a2,80000b1a <memmove+0x2a>
    80000b36:	02069613          	slli	a2,a3,0x20
    80000b3a:	9201                	srli	a2,a2,0x20
    80000b3c:	fff64613          	not	a2,a2
    80000b40:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000b42:	17fd                	addi	a5,a5,-1
    80000b44:	177d                	addi	a4,a4,-1
    80000b46:	0007c683          	lbu	a3,0(a5)
    80000b4a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000b4e:	fec79ae3          	bne	a5,a2,80000b42 <memmove+0x52>
    80000b52:	b7e1                	j	80000b1a <memmove+0x2a>

0000000080000b54 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e406                	sd	ra,8(sp)
    80000b58:	e022                	sd	s0,0(sp)
    80000b5a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	f94080e7          	jalr	-108(ra) # 80000af0 <memmove>
}
    80000b64:	60a2                	ld	ra,8(sp)
    80000b66:	6402                	ld	s0,0(sp)
    80000b68:	0141                	addi	sp,sp,16
    80000b6a:	8082                	ret

0000000080000b6c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000b6c:	1141                	addi	sp,sp,-16
    80000b6e:	e422                	sd	s0,8(sp)
    80000b70:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000b72:	ce11                	beqz	a2,80000b8e <strncmp+0x22>
    80000b74:	00054783          	lbu	a5,0(a0)
    80000b78:	cf89                	beqz	a5,80000b92 <strncmp+0x26>
    80000b7a:	0005c703          	lbu	a4,0(a1)
    80000b7e:	00f71a63          	bne	a4,a5,80000b92 <strncmp+0x26>
    n--, p++, q++;
    80000b82:	367d                	addiw	a2,a2,-1
    80000b84:	0505                	addi	a0,a0,1
    80000b86:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000b88:	f675                	bnez	a2,80000b74 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000b8a:	4501                	li	a0,0
    80000b8c:	a809                	j	80000b9e <strncmp+0x32>
    80000b8e:	4501                	li	a0,0
    80000b90:	a039                	j	80000b9e <strncmp+0x32>
  if(n == 0)
    80000b92:	ca09                	beqz	a2,80000ba4 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000b94:	00054503          	lbu	a0,0(a0)
    80000b98:	0005c783          	lbu	a5,0(a1)
    80000b9c:	9d1d                	subw	a0,a0,a5
}
    80000b9e:	6422                	ld	s0,8(sp)
    80000ba0:	0141                	addi	sp,sp,16
    80000ba2:	8082                	ret
    return 0;
    80000ba4:	4501                	li	a0,0
    80000ba6:	bfe5                	j	80000b9e <strncmp+0x32>

0000000080000ba8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000ba8:	1141                	addi	sp,sp,-16
    80000baa:	e422                	sd	s0,8(sp)
    80000bac:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000bae:	872a                	mv	a4,a0
    80000bb0:	8832                	mv	a6,a2
    80000bb2:	367d                	addiw	a2,a2,-1
    80000bb4:	01005963          	blez	a6,80000bc6 <strncpy+0x1e>
    80000bb8:	0705                	addi	a4,a4,1
    80000bba:	0005c783          	lbu	a5,0(a1)
    80000bbe:	fef70fa3          	sb	a5,-1(a4)
    80000bc2:	0585                	addi	a1,a1,1
    80000bc4:	f7f5                	bnez	a5,80000bb0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000bc6:	86ba                	mv	a3,a4
    80000bc8:	00c05c63          	blez	a2,80000be0 <strncpy+0x38>
    *s++ = 0;
    80000bcc:	0685                	addi	a3,a3,1
    80000bce:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000bd2:	fff6c793          	not	a5,a3
    80000bd6:	9fb9                	addw	a5,a5,a4
    80000bd8:	010787bb          	addw	a5,a5,a6
    80000bdc:	fef048e3          	bgtz	a5,80000bcc <strncpy+0x24>
  return os;
}
    80000be0:	6422                	ld	s0,8(sp)
    80000be2:	0141                	addi	sp,sp,16
    80000be4:	8082                	ret

0000000080000be6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000be6:	1141                	addi	sp,sp,-16
    80000be8:	e422                	sd	s0,8(sp)
    80000bea:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000bec:	02c05363          	blez	a2,80000c12 <safestrcpy+0x2c>
    80000bf0:	fff6069b          	addiw	a3,a2,-1
    80000bf4:	1682                	slli	a3,a3,0x20
    80000bf6:	9281                	srli	a3,a3,0x20
    80000bf8:	96ae                	add	a3,a3,a1
    80000bfa:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000bfc:	00d58963          	beq	a1,a3,80000c0e <safestrcpy+0x28>
    80000c00:	0585                	addi	a1,a1,1
    80000c02:	0785                	addi	a5,a5,1
    80000c04:	fff5c703          	lbu	a4,-1(a1)
    80000c08:	fee78fa3          	sb	a4,-1(a5)
    80000c0c:	fb65                	bnez	a4,80000bfc <safestrcpy+0x16>
    ;
  *s = 0;
    80000c0e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000c12:	6422                	ld	s0,8(sp)
    80000c14:	0141                	addi	sp,sp,16
    80000c16:	8082                	ret

0000000080000c18 <strlen>:

int
strlen(const char *s)
{
    80000c18:	1141                	addi	sp,sp,-16
    80000c1a:	e422                	sd	s0,8(sp)
    80000c1c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000c1e:	00054783          	lbu	a5,0(a0)
    80000c22:	cf91                	beqz	a5,80000c3e <strlen+0x26>
    80000c24:	0505                	addi	a0,a0,1
    80000c26:	87aa                	mv	a5,a0
    80000c28:	4685                	li	a3,1
    80000c2a:	9e89                	subw	a3,a3,a0
    80000c2c:	00f6853b          	addw	a0,a3,a5
    80000c30:	0785                	addi	a5,a5,1
    80000c32:	fff7c703          	lbu	a4,-1(a5)
    80000c36:	fb7d                	bnez	a4,80000c2c <strlen+0x14>
    ;
  return n;
}
    80000c38:	6422                	ld	s0,8(sp)
    80000c3a:	0141                	addi	sp,sp,16
    80000c3c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000c3e:	4501                	li	a0,0
    80000c40:	bfe5                	j	80000c38 <strlen+0x20>

0000000080000c42 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000c42:	1141                	addi	sp,sp,-16
    80000c44:	e406                	sd	ra,8(sp)
    80000c46:	e022                	sd	s0,0(sp)
    80000c48:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	c28080e7          	jalr	-984(ra) # 80001872 <cpuid>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000c52:	00029717          	auipc	a4,0x29
    80000c56:	3d670713          	addi	a4,a4,982 # 8002a028 <started>
  if(cpuid() == 0){
    80000c5a:	c139                	beqz	a0,80000ca0 <main+0x5e>
    while(started == 0)
    80000c5c:	431c                	lw	a5,0(a4)
    80000c5e:	2781                	sext.w	a5,a5
    80000c60:	dff5                	beqz	a5,80000c5c <main+0x1a>
      ;
    __sync_synchronize();
    80000c62:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000c66:	00001097          	auipc	ra,0x1
    80000c6a:	c0c080e7          	jalr	-1012(ra) # 80001872 <cpuid>
    80000c6e:	85aa                	mv	a1,a0
    80000c70:	00007517          	auipc	a0,0x7
    80000c74:	52050513          	addi	a0,a0,1312 # 80008190 <userret+0x100>
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	920080e7          	jalr	-1760(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	1ea080e7          	jalr	490(ra) # 80000e6a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000c88:	00002097          	auipc	ra,0x2
    80000c8c:	874080e7          	jalr	-1932(ra) # 800024fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000c90:	00005097          	auipc	ra,0x5
    80000c94:	080080e7          	jalr	128(ra) # 80005d10 <plicinithart>
  }

  scheduler();        
    80000c98:	00001097          	auipc	ra,0x1
    80000c9c:	148080e7          	jalr	328(ra) # 80001de0 <scheduler>
    consoleinit();
    80000ca0:	fffff097          	auipc	ra,0xfffff
    80000ca4:	7c0080e7          	jalr	1984(ra) # 80000460 <consoleinit>
    printfinit();
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	ad6080e7          	jalr	-1322(ra) # 8000077e <printfinit>
    printf("\n");
    80000cb0:	00007517          	auipc	a0,0x7
    80000cb4:	4f050513          	addi	a0,a0,1264 # 800081a0 <userret+0x110>
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	8e0080e7          	jalr	-1824(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80000cc0:	00007517          	auipc	a0,0x7
    80000cc4:	4b850513          	addi	a0,a0,1208 # 80008178 <userret+0xe8>
    80000cc8:	00000097          	auipc	ra,0x0
    80000ccc:	8d0080e7          	jalr	-1840(ra) # 80000598 <printf>
    printf("\n");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	4d050513          	addi	a0,a0,1232 # 800081a0 <userret+0x110>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	8c0080e7          	jalr	-1856(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	b80080e7          	jalr	-1152(ra) # 80000860 <kinit>
    kvminit();       // create kernel page table
    80000ce8:	00000097          	auipc	ra,0x0
    80000cec:	300080e7          	jalr	768(ra) # 80000fe8 <kvminit>
    kvminithart();   // turn on paging
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	17a080e7          	jalr	378(ra) # 80000e6a <kvminithart>
    procinit();      // process table
    80000cf8:	00001097          	auipc	ra,0x1
    80000cfc:	aaa080e7          	jalr	-1366(ra) # 800017a2 <procinit>
    trapinit();      // trap vectors
    80000d00:	00001097          	auipc	ra,0x1
    80000d04:	7d4080e7          	jalr	2004(ra) # 800024d4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000d08:	00001097          	auipc	ra,0x1
    80000d0c:	7f4080e7          	jalr	2036(ra) # 800024fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000d10:	00005097          	auipc	ra,0x5
    80000d14:	fea080e7          	jalr	-22(ra) # 80005cfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000d18:	00005097          	auipc	ra,0x5
    80000d1c:	ff8080e7          	jalr	-8(ra) # 80005d10 <plicinithart>
    binit();         // buffer cache
    80000d20:	00002097          	auipc	ra,0x2
    80000d24:	f1a080e7          	jalr	-230(ra) # 80002c3a <binit>
    iinit();         // inode cache
    80000d28:	00002097          	auipc	ra,0x2
    80000d2c:	5ae080e7          	jalr	1454(ra) # 800032d6 <iinit>
    fileinit();      // file table
    80000d30:	00003097          	auipc	ra,0x3
    80000d34:	78a080e7          	jalr	1930(ra) # 800044ba <fileinit>
    virtio_disk_init(minor(ROOTDEV)); // emulated hard disk
    80000d38:	4501                	li	a0,0
    80000d3a:	00005097          	auipc	ra,0x5
    80000d3e:	10a080e7          	jalr	266(ra) # 80005e44 <virtio_disk_init>
    userinit();      // first user process
    80000d42:	00001097          	auipc	ra,0x1
    80000d46:	dd0080e7          	jalr	-560(ra) # 80001b12 <userinit>
    __sync_synchronize();
    80000d4a:	0ff0000f          	fence
    started = 1;
    80000d4e:	4785                	li	a5,1
    80000d50:	00029717          	auipc	a4,0x29
    80000d54:	2cf72c23          	sw	a5,728(a4) # 8002a028 <started>
    80000d58:	b781                	j	80000c98 <main+0x56>

0000000080000d5a <walk>:
//   21..39 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..12 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000d5a:	7139                	addi	sp,sp,-64
    80000d5c:	fc06                	sd	ra,56(sp)
    80000d5e:	f822                	sd	s0,48(sp)
    80000d60:	f426                	sd	s1,40(sp)
    80000d62:	f04a                	sd	s2,32(sp)
    80000d64:	ec4e                	sd	s3,24(sp)
    80000d66:	e852                	sd	s4,16(sp)
    80000d68:	e456                	sd	s5,8(sp)
    80000d6a:	e05a                	sd	s6,0(sp)
    80000d6c:	0080                	addi	s0,sp,64
    80000d6e:	84aa                	mv	s1,a0
    80000d70:	89ae                	mv	s3,a1
    80000d72:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000d74:	57fd                	li	a5,-1
    80000d76:	83e9                	srli	a5,a5,0x1a
    80000d78:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000d7a:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000d7c:	04b7f263          	bgeu	a5,a1,80000dc0 <walk+0x66>
    panic("walk");
    80000d80:	00007517          	auipc	a0,0x7
    80000d84:	42850513          	addi	a0,a0,1064 # 800081a8 <userret+0x118>
    80000d88:	fffff097          	auipc	ra,0xfffff
    80000d8c:	7c6080e7          	jalr	1990(ra) # 8000054e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000d90:	060a8663          	beqz	s5,80000dfc <walk+0xa2>
    80000d94:	00000097          	auipc	ra,0x0
    80000d98:	b0c080e7          	jalr	-1268(ra) # 800008a0 <kalloc>
    80000d9c:	84aa                	mv	s1,a0
    80000d9e:	c529                	beqz	a0,80000de8 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000da0:	6605                	lui	a2,0x1
    80000da2:	4581                	li	a1,0
    80000da4:	00000097          	auipc	ra,0x0
    80000da8:	cec080e7          	jalr	-788(ra) # 80000a90 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000dac:	00c4d793          	srli	a5,s1,0xc
    80000db0:	07aa                	slli	a5,a5,0xa
    80000db2:	0017e793          	ori	a5,a5,1
    80000db6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000dba:	3a5d                	addiw	s4,s4,-9
    80000dbc:	036a0063          	beq	s4,s6,80000ddc <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80000dc0:	0149d933          	srl	s2,s3,s4
    80000dc4:	1ff97913          	andi	s2,s2,511
    80000dc8:	090e                	slli	s2,s2,0x3
    80000dca:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000dcc:	00093483          	ld	s1,0(s2)
    80000dd0:	0014f793          	andi	a5,s1,1
    80000dd4:	dfd5                	beqz	a5,80000d90 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000dd6:	80a9                	srli	s1,s1,0xa
    80000dd8:	04b2                	slli	s1,s1,0xc
    80000dda:	b7c5                	j	80000dba <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80000ddc:	00c9d513          	srli	a0,s3,0xc
    80000de0:	1ff57513          	andi	a0,a0,511
    80000de4:	050e                	slli	a0,a0,0x3
    80000de6:	9526                	add	a0,a0,s1
}
    80000de8:	70e2                	ld	ra,56(sp)
    80000dea:	7442                	ld	s0,48(sp)
    80000dec:	74a2                	ld	s1,40(sp)
    80000dee:	7902                	ld	s2,32(sp)
    80000df0:	69e2                	ld	s3,24(sp)
    80000df2:	6a42                	ld	s4,16(sp)
    80000df4:	6aa2                	ld	s5,8(sp)
    80000df6:	6b02                	ld	s6,0(sp)
    80000df8:	6121                	addi	sp,sp,64
    80000dfa:	8082                	ret
        return 0;
    80000dfc:	4501                	li	a0,0
    80000dfe:	b7ed                	j	80000de8 <walk+0x8e>

0000000080000e00 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
static void
freewalk(pagetable_t pagetable)
{
    80000e00:	7179                	addi	sp,sp,-48
    80000e02:	f406                	sd	ra,40(sp)
    80000e04:	f022                	sd	s0,32(sp)
    80000e06:	ec26                	sd	s1,24(sp)
    80000e08:	e84a                	sd	s2,16(sp)
    80000e0a:	e44e                	sd	s3,8(sp)
    80000e0c:	e052                	sd	s4,0(sp)
    80000e0e:	1800                	addi	s0,sp,48
    80000e10:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000e12:	84aa                	mv	s1,a0
    80000e14:	6905                	lui	s2,0x1
    80000e16:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000e18:	4985                	li	s3,1
    80000e1a:	a821                	j	80000e32 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80000e1c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80000e1e:	0532                	slli	a0,a0,0xc
    80000e20:	00000097          	auipc	ra,0x0
    80000e24:	fe0080e7          	jalr	-32(ra) # 80000e00 <freewalk>
      pagetable[i] = 0;
    80000e28:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80000e2c:	04a1                	addi	s1,s1,8
    80000e2e:	03248163          	beq	s1,s2,80000e50 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80000e32:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000e34:	00f57793          	andi	a5,a0,15
    80000e38:	ff3782e3          	beq	a5,s3,80000e1c <freewalk+0x1c>
    } else if(pte & PTE_V){
    80000e3c:	8905                	andi	a0,a0,1
    80000e3e:	d57d                	beqz	a0,80000e2c <freewalk+0x2c>
      panic("freewalk: leaf");
    80000e40:	00007517          	auipc	a0,0x7
    80000e44:	37050513          	addi	a0,a0,880 # 800081b0 <userret+0x120>
    80000e48:	fffff097          	auipc	ra,0xfffff
    80000e4c:	706080e7          	jalr	1798(ra) # 8000054e <panic>
    }
  }
  kfree((void*)pagetable);
    80000e50:	8552                	mv	a0,s4
    80000e52:	00000097          	auipc	ra,0x0
    80000e56:	a36080e7          	jalr	-1482(ra) # 80000888 <kfree>
}
    80000e5a:	70a2                	ld	ra,40(sp)
    80000e5c:	7402                	ld	s0,32(sp)
    80000e5e:	64e2                	ld	s1,24(sp)
    80000e60:	6942                	ld	s2,16(sp)
    80000e62:	69a2                	ld	s3,8(sp)
    80000e64:	6a02                	ld	s4,0(sp)
    80000e66:	6145                	addi	sp,sp,48
    80000e68:	8082                	ret

0000000080000e6a <kvminithart>:
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000e70:	00029797          	auipc	a5,0x29
    80000e74:	1c07b783          	ld	a5,448(a5) # 8002a030 <kernel_pagetable>
    80000e78:	83b1                	srli	a5,a5,0xc
    80000e7a:	577d                	li	a4,-1
    80000e7c:	177e                	slli	a4,a4,0x3f
    80000e7e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000e80:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000e84:	12000073          	sfence.vma
}
    80000e88:	6422                	ld	s0,8(sp)
    80000e8a:	0141                	addi	sp,sp,16
    80000e8c:	8082                	ret

0000000080000e8e <walkaddr>:
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000e96:	4601                	li	a2,0
    80000e98:	00000097          	auipc	ra,0x0
    80000e9c:	ec2080e7          	jalr	-318(ra) # 80000d5a <walk>
  if(pte == 0)
    80000ea0:	c105                	beqz	a0,80000ec0 <walkaddr+0x32>
  if((*pte & PTE_V) == 0)
    80000ea2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000ea4:	0117f693          	andi	a3,a5,17
    80000ea8:	4745                	li	a4,17
    return 0;
    80000eaa:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000eac:	00e68663          	beq	a3,a4,80000eb8 <walkaddr+0x2a>
}
    80000eb0:	60a2                	ld	ra,8(sp)
    80000eb2:	6402                	ld	s0,0(sp)
    80000eb4:	0141                	addi	sp,sp,16
    80000eb6:	8082                	ret
  pa = PTE2PA(*pte);
    80000eb8:	83a9                	srli	a5,a5,0xa
    80000eba:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000ebe:	bfcd                	j	80000eb0 <walkaddr+0x22>
    return 0;
    80000ec0:	4501                	li	a0,0
    80000ec2:	b7fd                	j	80000eb0 <walkaddr+0x22>

0000000080000ec4 <kvmpa>:
{
    80000ec4:	1101                	addi	sp,sp,-32
    80000ec6:	ec06                	sd	ra,24(sp)
    80000ec8:	e822                	sd	s0,16(sp)
    80000eca:	e426                	sd	s1,8(sp)
    80000ecc:	1000                	addi	s0,sp,32
    80000ece:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80000ed0:	03451493          	slli	s1,a0,0x34
  pte = walk(kernel_pagetable, va, 0);
    80000ed4:	4601                	li	a2,0
    80000ed6:	00029517          	auipc	a0,0x29
    80000eda:	15a53503          	ld	a0,346(a0) # 8002a030 <kernel_pagetable>
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	e7c080e7          	jalr	-388(ra) # 80000d5a <walk>
  if(pte == 0)
    80000ee6:	cd11                	beqz	a0,80000f02 <kvmpa+0x3e>
    80000ee8:	90d1                	srli	s1,s1,0x34
  if((*pte & PTE_V) == 0)
    80000eea:	6108                	ld	a0,0(a0)
    80000eec:	00157793          	andi	a5,a0,1
    80000ef0:	c38d                	beqz	a5,80000f12 <kvmpa+0x4e>
  pa = PTE2PA(*pte);
    80000ef2:	8129                	srli	a0,a0,0xa
    80000ef4:	0532                	slli	a0,a0,0xc
}
    80000ef6:	9526                	add	a0,a0,s1
    80000ef8:	60e2                	ld	ra,24(sp)
    80000efa:	6442                	ld	s0,16(sp)
    80000efc:	64a2                	ld	s1,8(sp)
    80000efe:	6105                	addi	sp,sp,32
    80000f00:	8082                	ret
    panic("kvmpa");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	2be50513          	addi	a0,a0,702 # 800081c0 <userret+0x130>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	644080e7          	jalr	1604(ra) # 8000054e <panic>
    panic("kvmpa");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	2ae50513          	addi	a0,a0,686 # 800081c0 <userret+0x130>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	634080e7          	jalr	1588(ra) # 8000054e <panic>

0000000080000f22 <mappages>:
{
    80000f22:	715d                	addi	sp,sp,-80
    80000f24:	e486                	sd	ra,72(sp)
    80000f26:	e0a2                	sd	s0,64(sp)
    80000f28:	fc26                	sd	s1,56(sp)
    80000f2a:	f84a                	sd	s2,48(sp)
    80000f2c:	f44e                	sd	s3,40(sp)
    80000f2e:	f052                	sd	s4,32(sp)
    80000f30:	ec56                	sd	s5,24(sp)
    80000f32:	e85a                	sd	s6,16(sp)
    80000f34:	e45e                	sd	s7,8(sp)
    80000f36:	0880                	addi	s0,sp,80
    80000f38:	8aaa                	mv	s5,a0
    80000f3a:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    80000f3c:	777d                	lui	a4,0xfffff
    80000f3e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80000f42:	167d                	addi	a2,a2,-1
    80000f44:	00b609b3          	add	s3,a2,a1
    80000f48:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80000f4c:	893e                	mv	s2,a5
    80000f4e:	40f68a33          	sub	s4,a3,a5
    a += PGSIZE;
    80000f52:	6b85                	lui	s7,0x1
    80000f54:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80000f58:	4605                	li	a2,1
    80000f5a:	85ca                	mv	a1,s2
    80000f5c:	8556                	mv	a0,s5
    80000f5e:	00000097          	auipc	ra,0x0
    80000f62:	dfc080e7          	jalr	-516(ra) # 80000d5a <walk>
    80000f66:	c51d                	beqz	a0,80000f94 <mappages+0x72>
    if(*pte & PTE_V)
    80000f68:	611c                	ld	a5,0(a0)
    80000f6a:	8b85                	andi	a5,a5,1
    80000f6c:	ef81                	bnez	a5,80000f84 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80000f6e:	80b1                	srli	s1,s1,0xc
    80000f70:	04aa                	slli	s1,s1,0xa
    80000f72:	0164e4b3          	or	s1,s1,s6
    80000f76:	0014e493          	ori	s1,s1,1
    80000f7a:	e104                	sd	s1,0(a0)
    if(a == last)
    80000f7c:	03390863          	beq	s2,s3,80000fac <mappages+0x8a>
    a += PGSIZE;
    80000f80:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80000f82:	bfc9                	j	80000f54 <mappages+0x32>
      panic("remap");
    80000f84:	00007517          	auipc	a0,0x7
    80000f88:	24450513          	addi	a0,a0,580 # 800081c8 <userret+0x138>
    80000f8c:	fffff097          	auipc	ra,0xfffff
    80000f90:	5c2080e7          	jalr	1474(ra) # 8000054e <panic>
      return -1;
    80000f94:	557d                	li	a0,-1
}
    80000f96:	60a6                	ld	ra,72(sp)
    80000f98:	6406                	ld	s0,64(sp)
    80000f9a:	74e2                	ld	s1,56(sp)
    80000f9c:	7942                	ld	s2,48(sp)
    80000f9e:	79a2                	ld	s3,40(sp)
    80000fa0:	7a02                	ld	s4,32(sp)
    80000fa2:	6ae2                	ld	s5,24(sp)
    80000fa4:	6b42                	ld	s6,16(sp)
    80000fa6:	6ba2                	ld	s7,8(sp)
    80000fa8:	6161                	addi	sp,sp,80
    80000faa:	8082                	ret
  return 0;
    80000fac:	4501                	li	a0,0
    80000fae:	b7e5                	j	80000f96 <mappages+0x74>

0000000080000fb0 <kvmmap>:
{
    80000fb0:	1141                	addi	sp,sp,-16
    80000fb2:	e406                	sd	ra,8(sp)
    80000fb4:	e022                	sd	s0,0(sp)
    80000fb6:	0800                	addi	s0,sp,16
    80000fb8:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80000fba:	86ae                	mv	a3,a1
    80000fbc:	85aa                	mv	a1,a0
    80000fbe:	00029517          	auipc	a0,0x29
    80000fc2:	07253503          	ld	a0,114(a0) # 8002a030 <kernel_pagetable>
    80000fc6:	00000097          	auipc	ra,0x0
    80000fca:	f5c080e7          	jalr	-164(ra) # 80000f22 <mappages>
    80000fce:	e509                	bnez	a0,80000fd8 <kvmmap+0x28>
}
    80000fd0:	60a2                	ld	ra,8(sp)
    80000fd2:	6402                	ld	s0,0(sp)
    80000fd4:	0141                	addi	sp,sp,16
    80000fd6:	8082                	ret
    panic("kvmmap");
    80000fd8:	00007517          	auipc	a0,0x7
    80000fdc:	1f850513          	addi	a0,a0,504 # 800081d0 <userret+0x140>
    80000fe0:	fffff097          	auipc	ra,0xfffff
    80000fe4:	56e080e7          	jalr	1390(ra) # 8000054e <panic>

0000000080000fe8 <kvminit>:
{
    80000fe8:	1101                	addi	sp,sp,-32
    80000fea:	ec06                	sd	ra,24(sp)
    80000fec:	e822                	sd	s0,16(sp)
    80000fee:	e426                	sd	s1,8(sp)
    80000ff0:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80000ff2:	00000097          	auipc	ra,0x0
    80000ff6:	8ae080e7          	jalr	-1874(ra) # 800008a0 <kalloc>
    80000ffa:	00029797          	auipc	a5,0x29
    80000ffe:	02a7bb23          	sd	a0,54(a5) # 8002a030 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001002:	6605                	lui	a2,0x1
    80001004:	4581                	li	a1,0
    80001006:	00000097          	auipc	ra,0x0
    8000100a:	a8a080e7          	jalr	-1398(ra) # 80000a90 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000100e:	4699                	li	a3,6
    80001010:	6605                	lui	a2,0x1
    80001012:	100005b7          	lui	a1,0x10000
    80001016:	10000537          	lui	a0,0x10000
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	f96080e7          	jalr	-106(ra) # 80000fb0 <kvmmap>
  kvmmap(VIRTION(0), VIRTION(0), PGSIZE, PTE_R | PTE_W);
    80001022:	4699                	li	a3,6
    80001024:	6605                	lui	a2,0x1
    80001026:	100015b7          	lui	a1,0x10001
    8000102a:	10001537          	lui	a0,0x10001
    8000102e:	00000097          	auipc	ra,0x0
    80001032:	f82080e7          	jalr	-126(ra) # 80000fb0 <kvmmap>
  kvmmap(VIRTION(1), VIRTION(1), PGSIZE, PTE_R | PTE_W);
    80001036:	4699                	li	a3,6
    80001038:	6605                	lui	a2,0x1
    8000103a:	100025b7          	lui	a1,0x10002
    8000103e:	10002537          	lui	a0,0x10002
    80001042:	00000097          	auipc	ra,0x0
    80001046:	f6e080e7          	jalr	-146(ra) # 80000fb0 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000104a:	4699                	li	a3,6
    8000104c:	6641                	lui	a2,0x10
    8000104e:	020005b7          	lui	a1,0x2000
    80001052:	02000537          	lui	a0,0x2000
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	f5a080e7          	jalr	-166(ra) # 80000fb0 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000105e:	4699                	li	a3,6
    80001060:	00400637          	lui	a2,0x400
    80001064:	0c0005b7          	lui	a1,0xc000
    80001068:	0c000537          	lui	a0,0xc000
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	f44080e7          	jalr	-188(ra) # 80000fb0 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001074:	00008497          	auipc	s1,0x8
    80001078:	f8c48493          	addi	s1,s1,-116 # 80009000 <initcode>
    8000107c:	46a9                	li	a3,10
    8000107e:	80008617          	auipc	a2,0x80008
    80001082:	f8260613          	addi	a2,a2,-126 # 9000 <_entry-0x7fff7000>
    80001086:	4585                	li	a1,1
    80001088:	05fe                	slli	a1,a1,0x1f
    8000108a:	852e                	mv	a0,a1
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f24080e7          	jalr	-220(ra) # 80000fb0 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001094:	4699                	li	a3,6
    80001096:	4645                	li	a2,17
    80001098:	066e                	slli	a2,a2,0x1b
    8000109a:	8e05                	sub	a2,a2,s1
    8000109c:	85a6                	mv	a1,s1
    8000109e:	8526                	mv	a0,s1
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	f10080e7          	jalr	-240(ra) # 80000fb0 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800010a8:	46a9                	li	a3,10
    800010aa:	6605                	lui	a2,0x1
    800010ac:	00007597          	auipc	a1,0x7
    800010b0:	f5458593          	addi	a1,a1,-172 # 80008000 <trampoline>
    800010b4:	04000537          	lui	a0,0x4000
    800010b8:	157d                	addi	a0,a0,-1
    800010ba:	0532                	slli	a0,a0,0xc
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	ef4080e7          	jalr	-268(ra) # 80000fb0 <kvmmap>
}
    800010c4:	60e2                	ld	ra,24(sp)
    800010c6:	6442                	ld	s0,16(sp)
    800010c8:	64a2                	ld	s1,8(sp)
    800010ca:	6105                	addi	sp,sp,32
    800010cc:	8082                	ret

00000000800010ce <uvmunmap>:
{
    800010ce:	715d                	addi	sp,sp,-80
    800010d0:	e486                	sd	ra,72(sp)
    800010d2:	e0a2                	sd	s0,64(sp)
    800010d4:	fc26                	sd	s1,56(sp)
    800010d6:	f84a                	sd	s2,48(sp)
    800010d8:	f44e                	sd	s3,40(sp)
    800010da:	f052                	sd	s4,32(sp)
    800010dc:	ec56                	sd	s5,24(sp)
    800010de:	e85a                	sd	s6,16(sp)
    800010e0:	e45e                	sd	s7,8(sp)
    800010e2:	0880                	addi	s0,sp,80
    800010e4:	8a2a                	mv	s4,a0
    800010e6:	8ab6                	mv	s5,a3
  a = PGROUNDDOWN(va);
    800010e8:	77fd                	lui	a5,0xfffff
    800010ea:	00f5f933          	and	s2,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010ee:	167d                	addi	a2,a2,-1
    800010f0:	00b609b3          	add	s3,a2,a1
    800010f4:	00f9f9b3          	and	s3,s3,a5
    if(PTE_FLAGS(*pte) == PTE_V)
    800010f8:	4b05                	li	s6,1
    a += PGSIZE;
    800010fa:	6b85                	lui	s7,0x1
    800010fc:	a8b1                	j	80001158 <uvmunmap+0x8a>
      panic("uvmunmap: walk");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	0da50513          	addi	a0,a0,218 # 800081d8 <userret+0x148>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	448080e7          	jalr	1096(ra) # 8000054e <panic>
      printf("va=%p pte=%p\n", a, *pte);
    8000110e:	862a                	mv	a2,a0
    80001110:	85ca                	mv	a1,s2
    80001112:	00007517          	auipc	a0,0x7
    80001116:	0d650513          	addi	a0,a0,214 # 800081e8 <userret+0x158>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	47e080e7          	jalr	1150(ra) # 80000598 <printf>
      panic("uvmunmap: not mapped");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	0d650513          	addi	a0,a0,214 # 800081f8 <userret+0x168>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	424080e7          	jalr	1060(ra) # 8000054e <panic>
      panic("uvmunmap: not a leaf");
    80001132:	00007517          	auipc	a0,0x7
    80001136:	0de50513          	addi	a0,a0,222 # 80008210 <userret+0x180>
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	414080e7          	jalr	1044(ra) # 8000054e <panic>
      pa = PTE2PA(*pte);
    80001142:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001144:	0532                	slli	a0,a0,0xc
    80001146:	fffff097          	auipc	ra,0xfffff
    8000114a:	742080e7          	jalr	1858(ra) # 80000888 <kfree>
    *pte = 0;
    8000114e:	0004b023          	sd	zero,0(s1)
    if(a == last)
    80001152:	03390763          	beq	s2,s3,80001180 <uvmunmap+0xb2>
    a += PGSIZE;
    80001156:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 0)) == 0)
    80001158:	4601                	li	a2,0
    8000115a:	85ca                	mv	a1,s2
    8000115c:	8552                	mv	a0,s4
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	bfc080e7          	jalr	-1028(ra) # 80000d5a <walk>
    80001166:	84aa                	mv	s1,a0
    80001168:	d959                	beqz	a0,800010fe <uvmunmap+0x30>
    if((*pte & PTE_V) == 0){
    8000116a:	6108                	ld	a0,0(a0)
    8000116c:	00157793          	andi	a5,a0,1
    80001170:	dfd9                	beqz	a5,8000110e <uvmunmap+0x40>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001172:	01f57793          	andi	a5,a0,31
    80001176:	fb678ee3          	beq	a5,s6,80001132 <uvmunmap+0x64>
    if(do_free){
    8000117a:	fc0a8ae3          	beqz	s5,8000114e <uvmunmap+0x80>
    8000117e:	b7d1                	j	80001142 <uvmunmap+0x74>
}
    80001180:	60a6                	ld	ra,72(sp)
    80001182:	6406                	ld	s0,64(sp)
    80001184:	74e2                	ld	s1,56(sp)
    80001186:	7942                	ld	s2,48(sp)
    80001188:	79a2                	ld	s3,40(sp)
    8000118a:	7a02                	ld	s4,32(sp)
    8000118c:	6ae2                	ld	s5,24(sp)
    8000118e:	6b42                	ld	s6,16(sp)
    80001190:	6ba2                	ld	s7,8(sp)
    80001192:	6161                	addi	sp,sp,80
    80001194:	8082                	ret

0000000080001196 <uvmcreate>:
{
    80001196:	1101                	addi	sp,sp,-32
    80001198:	ec06                	sd	ra,24(sp)
    8000119a:	e822                	sd	s0,16(sp)
    8000119c:	e426                	sd	s1,8(sp)
    8000119e:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    800011a0:	fffff097          	auipc	ra,0xfffff
    800011a4:	700080e7          	jalr	1792(ra) # 800008a0 <kalloc>
  if(pagetable == 0)
    800011a8:	cd11                	beqz	a0,800011c4 <uvmcreate+0x2e>
    800011aa:	84aa                	mv	s1,a0
  memset(pagetable, 0, PGSIZE);
    800011ac:	6605                	lui	a2,0x1
    800011ae:	4581                	li	a1,0
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	8e0080e7          	jalr	-1824(ra) # 80000a90 <memset>
}
    800011b8:	8526                	mv	a0,s1
    800011ba:	60e2                	ld	ra,24(sp)
    800011bc:	6442                	ld	s0,16(sp)
    800011be:	64a2                	ld	s1,8(sp)
    800011c0:	6105                	addi	sp,sp,32
    800011c2:	8082                	ret
    panic("uvmcreate: out of memory");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	06450513          	addi	a0,a0,100 # 80008228 <userret+0x198>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	382080e7          	jalr	898(ra) # 8000054e <panic>

00000000800011d4 <uvminit>:
{
    800011d4:	7179                	addi	sp,sp,-48
    800011d6:	f406                	sd	ra,40(sp)
    800011d8:	f022                	sd	s0,32(sp)
    800011da:	ec26                	sd	s1,24(sp)
    800011dc:	e84a                	sd	s2,16(sp)
    800011de:	e44e                	sd	s3,8(sp)
    800011e0:	e052                	sd	s4,0(sp)
    800011e2:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    800011e4:	6785                	lui	a5,0x1
    800011e6:	04f67863          	bgeu	a2,a5,80001236 <uvminit+0x62>
    800011ea:	8a2a                	mv	s4,a0
    800011ec:	89ae                	mv	s3,a1
    800011ee:	84b2                	mv	s1,a2
  mem = kalloc();
    800011f0:	fffff097          	auipc	ra,0xfffff
    800011f4:	6b0080e7          	jalr	1712(ra) # 800008a0 <kalloc>
    800011f8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800011fa:	6605                	lui	a2,0x1
    800011fc:	4581                	li	a1,0
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	892080e7          	jalr	-1902(ra) # 80000a90 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001206:	4779                	li	a4,30
    80001208:	86ca                	mv	a3,s2
    8000120a:	6605                	lui	a2,0x1
    8000120c:	4581                	li	a1,0
    8000120e:	8552                	mv	a0,s4
    80001210:	00000097          	auipc	ra,0x0
    80001214:	d12080e7          	jalr	-750(ra) # 80000f22 <mappages>
  memmove(mem, src, sz);
    80001218:	8626                	mv	a2,s1
    8000121a:	85ce                	mv	a1,s3
    8000121c:	854a                	mv	a0,s2
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	8d2080e7          	jalr	-1838(ra) # 80000af0 <memmove>
}
    80001226:	70a2                	ld	ra,40(sp)
    80001228:	7402                	ld	s0,32(sp)
    8000122a:	64e2                	ld	s1,24(sp)
    8000122c:	6942                	ld	s2,16(sp)
    8000122e:	69a2                	ld	s3,8(sp)
    80001230:	6a02                	ld	s4,0(sp)
    80001232:	6145                	addi	sp,sp,48
    80001234:	8082                	ret
    panic("inituvm: more than a page");
    80001236:	00007517          	auipc	a0,0x7
    8000123a:	01250513          	addi	a0,a0,18 # 80008248 <userret+0x1b8>
    8000123e:	fffff097          	auipc	ra,0xfffff
    80001242:	310080e7          	jalr	784(ra) # 8000054e <panic>

0000000080001246 <uvmdealloc>:
{
    80001246:	87aa                	mv	a5,a0
    80001248:	852e                	mv	a0,a1
  if(newsz >= oldsz)
    8000124a:	00b66363          	bltu	a2,a1,80001250 <uvmdealloc+0xa>
}
    8000124e:	8082                	ret
{
    80001250:	1101                	addi	sp,sp,-32
    80001252:	ec06                	sd	ra,24(sp)
    80001254:	e822                	sd	s0,16(sp)
    80001256:	e426                	sd	s1,8(sp)
    80001258:	1000                	addi	s0,sp,32
    8000125a:	84b2                	mv	s1,a2
  uvmunmap(pagetable, newsz, oldsz - newsz, 1);
    8000125c:	4685                	li	a3,1
    8000125e:	40c58633          	sub	a2,a1,a2
    80001262:	85a6                	mv	a1,s1
    80001264:	853e                	mv	a0,a5
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	e68080e7          	jalr	-408(ra) # 800010ce <uvmunmap>
  return newsz;
    8000126e:	8526                	mv	a0,s1
}
    80001270:	60e2                	ld	ra,24(sp)
    80001272:	6442                	ld	s0,16(sp)
    80001274:	64a2                	ld	s1,8(sp)
    80001276:	6105                	addi	sp,sp,32
    80001278:	8082                	ret

000000008000127a <uvmalloc>:
  if(newsz < oldsz)
    8000127a:	0ab66163          	bltu	a2,a1,8000131c <uvmalloc+0xa2>
{
    8000127e:	7139                	addi	sp,sp,-64
    80001280:	fc06                	sd	ra,56(sp)
    80001282:	f822                	sd	s0,48(sp)
    80001284:	f426                	sd	s1,40(sp)
    80001286:	f04a                	sd	s2,32(sp)
    80001288:	ec4e                	sd	s3,24(sp)
    8000128a:	e852                	sd	s4,16(sp)
    8000128c:	e456                	sd	s5,8(sp)
    8000128e:	0080                	addi	s0,sp,64
    80001290:	8aaa                	mv	s5,a0
    80001292:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001294:	6985                	lui	s3,0x1
    80001296:	19fd                	addi	s3,s3,-1
    80001298:	95ce                	add	a1,a1,s3
    8000129a:	79fd                	lui	s3,0xfffff
    8000129c:	0135f9b3          	and	s3,a1,s3
  for(; a < newsz; a += PGSIZE){
    800012a0:	08c9f063          	bgeu	s3,a2,80001320 <uvmalloc+0xa6>
  a = oldsz;
    800012a4:	894e                	mv	s2,s3
    mem = kalloc();
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	5fa080e7          	jalr	1530(ra) # 800008a0 <kalloc>
    800012ae:	84aa                	mv	s1,a0
    if(mem == 0){
    800012b0:	c51d                	beqz	a0,800012de <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012b2:	6605                	lui	a2,0x1
    800012b4:	4581                	li	a1,0
    800012b6:	fffff097          	auipc	ra,0xfffff
    800012ba:	7da080e7          	jalr	2010(ra) # 80000a90 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800012be:	4779                	li	a4,30
    800012c0:	86a6                	mv	a3,s1
    800012c2:	6605                	lui	a2,0x1
    800012c4:	85ca                	mv	a1,s2
    800012c6:	8556                	mv	a0,s5
    800012c8:	00000097          	auipc	ra,0x0
    800012cc:	c5a080e7          	jalr	-934(ra) # 80000f22 <mappages>
    800012d0:	e905                	bnez	a0,80001300 <uvmalloc+0x86>
  for(; a < newsz; a += PGSIZE){
    800012d2:	6785                	lui	a5,0x1
    800012d4:	993e                	add	s2,s2,a5
    800012d6:	fd4968e3          	bltu	s2,s4,800012a6 <uvmalloc+0x2c>
  return newsz;
    800012da:	8552                	mv	a0,s4
    800012dc:	a809                	j	800012ee <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800012de:	864e                	mv	a2,s3
    800012e0:	85ca                	mv	a1,s2
    800012e2:	8556                	mv	a0,s5
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	f62080e7          	jalr	-158(ra) # 80001246 <uvmdealloc>
      return 0;
    800012ec:	4501                	li	a0,0
}
    800012ee:	70e2                	ld	ra,56(sp)
    800012f0:	7442                	ld	s0,48(sp)
    800012f2:	74a2                	ld	s1,40(sp)
    800012f4:	7902                	ld	s2,32(sp)
    800012f6:	69e2                	ld	s3,24(sp)
    800012f8:	6a42                	ld	s4,16(sp)
    800012fa:	6aa2                	ld	s5,8(sp)
    800012fc:	6121                	addi	sp,sp,64
    800012fe:	8082                	ret
      kfree(mem);
    80001300:	8526                	mv	a0,s1
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	586080e7          	jalr	1414(ra) # 80000888 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000130a:	864e                	mv	a2,s3
    8000130c:	85ca                	mv	a1,s2
    8000130e:	8556                	mv	a0,s5
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f36080e7          	jalr	-202(ra) # 80001246 <uvmdealloc>
      return 0;
    80001318:	4501                	li	a0,0
    8000131a:	bfd1                	j	800012ee <uvmalloc+0x74>
    return oldsz;
    8000131c:	852e                	mv	a0,a1
}
    8000131e:	8082                	ret
  return newsz;
    80001320:	8532                	mv	a0,a2
    80001322:	b7f1                	j	800012ee <uvmalloc+0x74>

0000000080001324 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001324:	1101                	addi	sp,sp,-32
    80001326:	ec06                	sd	ra,24(sp)
    80001328:	e822                	sd	s0,16(sp)
    8000132a:	e426                	sd	s1,8(sp)
    8000132c:	1000                	addi	s0,sp,32
    8000132e:	84aa                	mv	s1,a0
    80001330:	862e                	mv	a2,a1
  uvmunmap(pagetable, 0, sz, 1);
    80001332:	4685                	li	a3,1
    80001334:	4581                	li	a1,0
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	d98080e7          	jalr	-616(ra) # 800010ce <uvmunmap>
  freewalk(pagetable);
    8000133e:	8526                	mv	a0,s1
    80001340:	00000097          	auipc	ra,0x0
    80001344:	ac0080e7          	jalr	-1344(ra) # 80000e00 <freewalk>
}
    80001348:	60e2                	ld	ra,24(sp)
    8000134a:	6442                	ld	s0,16(sp)
    8000134c:	64a2                	ld	s1,8(sp)
    8000134e:	6105                	addi	sp,sp,32
    80001350:	8082                	ret

0000000080001352 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001352:	c671                	beqz	a2,8000141e <uvmcopy+0xcc>
{
    80001354:	715d                	addi	sp,sp,-80
    80001356:	e486                	sd	ra,72(sp)
    80001358:	e0a2                	sd	s0,64(sp)
    8000135a:	fc26                	sd	s1,56(sp)
    8000135c:	f84a                	sd	s2,48(sp)
    8000135e:	f44e                	sd	s3,40(sp)
    80001360:	f052                	sd	s4,32(sp)
    80001362:	ec56                	sd	s5,24(sp)
    80001364:	e85a                	sd	s6,16(sp)
    80001366:	e45e                	sd	s7,8(sp)
    80001368:	0880                	addi	s0,sp,80
    8000136a:	8b2a                	mv	s6,a0
    8000136c:	8aae                	mv	s5,a1
    8000136e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001370:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001372:	4601                	li	a2,0
    80001374:	85ce                	mv	a1,s3
    80001376:	855a                	mv	a0,s6
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	9e2080e7          	jalr	-1566(ra) # 80000d5a <walk>
    80001380:	c531                	beqz	a0,800013cc <uvmcopy+0x7a>
      panic("copyuvm: pte should exist");
    if((*pte & PTE_V) == 0)
    80001382:	6118                	ld	a4,0(a0)
    80001384:	00177793          	andi	a5,a4,1
    80001388:	cbb1                	beqz	a5,800013dc <uvmcopy+0x8a>
      panic("copyuvm: page not present");
    pa = PTE2PA(*pte);
    8000138a:	00a75593          	srli	a1,a4,0xa
    8000138e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001392:	01f77493          	andi	s1,a4,31
    if((mem = kalloc()) == 0)
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	50a080e7          	jalr	1290(ra) # 800008a0 <kalloc>
    8000139e:	892a                	mv	s2,a0
    800013a0:	c939                	beqz	a0,800013f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800013a2:	6605                	lui	a2,0x1
    800013a4:	85de                	mv	a1,s7
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	74a080e7          	jalr	1866(ra) # 80000af0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800013ae:	8726                	mv	a4,s1
    800013b0:	86ca                	mv	a3,s2
    800013b2:	6605                	lui	a2,0x1
    800013b4:	85ce                	mv	a1,s3
    800013b6:	8556                	mv	a0,s5
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	b6a080e7          	jalr	-1174(ra) # 80000f22 <mappages>
    800013c0:	e515                	bnez	a0,800013ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800013c2:	6785                	lui	a5,0x1
    800013c4:	99be                	add	s3,s3,a5
    800013c6:	fb49e6e3          	bltu	s3,s4,80001372 <uvmcopy+0x20>
    800013ca:	a83d                	j	80001408 <uvmcopy+0xb6>
      panic("copyuvm: pte should exist");
    800013cc:	00007517          	auipc	a0,0x7
    800013d0:	e9c50513          	addi	a0,a0,-356 # 80008268 <userret+0x1d8>
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	17a080e7          	jalr	378(ra) # 8000054e <panic>
      panic("copyuvm: page not present");
    800013dc:	00007517          	auipc	a0,0x7
    800013e0:	eac50513          	addi	a0,a0,-340 # 80008288 <userret+0x1f8>
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	16a080e7          	jalr	362(ra) # 8000054e <panic>
      kfree(mem);
    800013ec:	854a                	mv	a0,s2
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	49a080e7          	jalr	1178(ra) # 80000888 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i, 1);
    800013f6:	4685                	li	a3,1
    800013f8:	864e                	mv	a2,s3
    800013fa:	4581                	li	a1,0
    800013fc:	8556                	mv	a0,s5
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	cd0080e7          	jalr	-816(ra) # 800010ce <uvmunmap>
  return -1;
    80001406:	557d                	li	a0,-1
}
    80001408:	60a6                	ld	ra,72(sp)
    8000140a:	6406                	ld	s0,64(sp)
    8000140c:	74e2                	ld	s1,56(sp)
    8000140e:	7942                	ld	s2,48(sp)
    80001410:	79a2                	ld	s3,40(sp)
    80001412:	7a02                	ld	s4,32(sp)
    80001414:	6ae2                	ld	s5,24(sp)
    80001416:	6b42                	ld	s6,16(sp)
    80001418:	6ba2                	ld	s7,8(sp)
    8000141a:	6161                	addi	sp,sp,80
    8000141c:	8082                	ret
  return 0;
    8000141e:	4501                	li	a0,0
}
    80001420:	8082                	ret

0000000080001422 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001422:	1141                	addi	sp,sp,-16
    80001424:	e406                	sd	ra,8(sp)
    80001426:	e022                	sd	s0,0(sp)
    80001428:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000142a:	4601                	li	a2,0
    8000142c:	00000097          	auipc	ra,0x0
    80001430:	92e080e7          	jalr	-1746(ra) # 80000d5a <walk>
  if(pte == 0)
    80001434:	c901                	beqz	a0,80001444 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001436:	611c                	ld	a5,0(a0)
    80001438:	9bbd                	andi	a5,a5,-17
    8000143a:	e11c                	sd	a5,0(a0)
}
    8000143c:	60a2                	ld	ra,8(sp)
    8000143e:	6402                	ld	s0,0(sp)
    80001440:	0141                	addi	sp,sp,16
    80001442:	8082                	ret
    panic("uvmclear");
    80001444:	00007517          	auipc	a0,0x7
    80001448:	e6450513          	addi	a0,a0,-412 # 800082a8 <userret+0x218>
    8000144c:	fffff097          	auipc	ra,0xfffff
    80001450:	102080e7          	jalr	258(ra) # 8000054e <panic>

0000000080001454 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001454:	cab5                	beqz	a3,800014c8 <copyout+0x74>
{
    80001456:	715d                	addi	sp,sp,-80
    80001458:	e486                	sd	ra,72(sp)
    8000145a:	e0a2                	sd	s0,64(sp)
    8000145c:	fc26                	sd	s1,56(sp)
    8000145e:	f84a                	sd	s2,48(sp)
    80001460:	f44e                	sd	s3,40(sp)
    80001462:	f052                	sd	s4,32(sp)
    80001464:	ec56                	sd	s5,24(sp)
    80001466:	e85a                	sd	s6,16(sp)
    80001468:	e45e                	sd	s7,8(sp)
    8000146a:	e062                	sd	s8,0(sp)
    8000146c:	0880                	addi	s0,sp,80
    8000146e:	8baa                	mv	s7,a0
    80001470:	8c2e                	mv	s8,a1
    80001472:	8a32                	mv	s4,a2
    80001474:	89b6                	mv	s3,a3
    va0 = (uint)PGROUNDDOWN(dstva);
    80001476:	00100b37          	lui	s6,0x100
    8000147a:	1b7d                	addi	s6,s6,-1
    8000147c:	0b32                	slli	s6,s6,0xc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000147e:	6a85                	lui	s5,0x1
    80001480:	a015                	j	800014a4 <copyout+0x50>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001482:	9562                	add	a0,a0,s8
    80001484:	0004861b          	sext.w	a2,s1
    80001488:	85d2                	mv	a1,s4
    8000148a:	41250533          	sub	a0,a0,s2
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	662080e7          	jalr	1634(ra) # 80000af0 <memmove>

    len -= n;
    80001496:	409989b3          	sub	s3,s3,s1
    src += n;
    8000149a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000149c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800014a0:	02098263          	beqz	s3,800014c4 <copyout+0x70>
    va0 = (uint)PGROUNDDOWN(dstva);
    800014a4:	016c7933          	and	s2,s8,s6
    pa0 = walkaddr(pagetable, va0);
    800014a8:	85ca                	mv	a1,s2
    800014aa:	855e                	mv	a0,s7
    800014ac:	00000097          	auipc	ra,0x0
    800014b0:	9e2080e7          	jalr	-1566(ra) # 80000e8e <walkaddr>
    if(pa0 == 0)
    800014b4:	cd01                	beqz	a0,800014cc <copyout+0x78>
    n = PGSIZE - (dstva - va0);
    800014b6:	418904b3          	sub	s1,s2,s8
    800014ba:	94d6                	add	s1,s1,s5
    if(n > len)
    800014bc:	fc99f3e3          	bgeu	s3,s1,80001482 <copyout+0x2e>
    800014c0:	84ce                	mv	s1,s3
    800014c2:	b7c1                	j	80001482 <copyout+0x2e>
  }
  return 0;
    800014c4:	4501                	li	a0,0
    800014c6:	a021                	j	800014ce <copyout+0x7a>
    800014c8:	4501                	li	a0,0
}
    800014ca:	8082                	ret
      return -1;
    800014cc:	557d                	li	a0,-1
}
    800014ce:	60a6                	ld	ra,72(sp)
    800014d0:	6406                	ld	s0,64(sp)
    800014d2:	74e2                	ld	s1,56(sp)
    800014d4:	7942                	ld	s2,48(sp)
    800014d6:	79a2                	ld	s3,40(sp)
    800014d8:	7a02                	ld	s4,32(sp)
    800014da:	6ae2                	ld	s5,24(sp)
    800014dc:	6b42                	ld	s6,16(sp)
    800014de:	6ba2                	ld	s7,8(sp)
    800014e0:	6c02                	ld	s8,0(sp)
    800014e2:	6161                	addi	sp,sp,80
    800014e4:	8082                	ret

00000000800014e6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800014e6:	cab5                	beqz	a3,8000155a <copyin+0x74>
{
    800014e8:	715d                	addi	sp,sp,-80
    800014ea:	e486                	sd	ra,72(sp)
    800014ec:	e0a2                	sd	s0,64(sp)
    800014ee:	fc26                	sd	s1,56(sp)
    800014f0:	f84a                	sd	s2,48(sp)
    800014f2:	f44e                	sd	s3,40(sp)
    800014f4:	f052                	sd	s4,32(sp)
    800014f6:	ec56                	sd	s5,24(sp)
    800014f8:	e85a                	sd	s6,16(sp)
    800014fa:	e45e                	sd	s7,8(sp)
    800014fc:	e062                	sd	s8,0(sp)
    800014fe:	0880                	addi	s0,sp,80
    80001500:	8baa                	mv	s7,a0
    80001502:	8a2e                	mv	s4,a1
    80001504:	8c32                	mv	s8,a2
    80001506:	89b6                	mv	s3,a3
    va0 = (uint)PGROUNDDOWN(srcva);
    80001508:	00100b37          	lui	s6,0x100
    8000150c:	1b7d                	addi	s6,s6,-1
    8000150e:	0b32                	slli	s6,s6,0xc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001510:	6a85                	lui	s5,0x1
    80001512:	a015                	j	80001536 <copyin+0x50>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001514:	9562                	add	a0,a0,s8
    80001516:	0004861b          	sext.w	a2,s1
    8000151a:	412505b3          	sub	a1,a0,s2
    8000151e:	8552                	mv	a0,s4
    80001520:	fffff097          	auipc	ra,0xfffff
    80001524:	5d0080e7          	jalr	1488(ra) # 80000af0 <memmove>

    len -= n;
    80001528:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000152c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000152e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001532:	02098263          	beqz	s3,80001556 <copyin+0x70>
    va0 = (uint)PGROUNDDOWN(srcva);
    80001536:	016c7933          	and	s2,s8,s6
    pa0 = walkaddr(pagetable, va0);
    8000153a:	85ca                	mv	a1,s2
    8000153c:	855e                	mv	a0,s7
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	950080e7          	jalr	-1712(ra) # 80000e8e <walkaddr>
    if(pa0 == 0)
    80001546:	cd01                	beqz	a0,8000155e <copyin+0x78>
    n = PGSIZE - (srcva - va0);
    80001548:	418904b3          	sub	s1,s2,s8
    8000154c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000154e:	fc99f3e3          	bgeu	s3,s1,80001514 <copyin+0x2e>
    80001552:	84ce                	mv	s1,s3
    80001554:	b7c1                	j	80001514 <copyin+0x2e>
  }
  return 0;
    80001556:	4501                	li	a0,0
    80001558:	a021                	j	80001560 <copyin+0x7a>
    8000155a:	4501                	li	a0,0
}
    8000155c:	8082                	ret
      return -1;
    8000155e:	557d                	li	a0,-1
}
    80001560:	60a6                	ld	ra,72(sp)
    80001562:	6406                	ld	s0,64(sp)
    80001564:	74e2                	ld	s1,56(sp)
    80001566:	7942                	ld	s2,48(sp)
    80001568:	79a2                	ld	s3,40(sp)
    8000156a:	7a02                	ld	s4,32(sp)
    8000156c:	6ae2                	ld	s5,24(sp)
    8000156e:	6b42                	ld	s6,16(sp)
    80001570:	6ba2                	ld	s7,8(sp)
    80001572:	6c02                	ld	s8,0(sp)
    80001574:	6161                	addi	sp,sp,80
    80001576:	8082                	ret

0000000080001578 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001578:	c6dd                	beqz	a3,80001626 <copyinstr+0xae>
{
    8000157a:	715d                	addi	sp,sp,-80
    8000157c:	e486                	sd	ra,72(sp)
    8000157e:	e0a2                	sd	s0,64(sp)
    80001580:	fc26                	sd	s1,56(sp)
    80001582:	f84a                	sd	s2,48(sp)
    80001584:	f44e                	sd	s3,40(sp)
    80001586:	f052                	sd	s4,32(sp)
    80001588:	ec56                	sd	s5,24(sp)
    8000158a:	e85a                	sd	s6,16(sp)
    8000158c:	e45e                	sd	s7,8(sp)
    8000158e:	0880                	addi	s0,sp,80
    80001590:	8aaa                	mv	s5,a0
    80001592:	8b2e                	mv	s6,a1
    80001594:	8bb2                	mv	s7,a2
    80001596:	84b6                	mv	s1,a3
    va0 = (uint)PGROUNDDOWN(srcva);
    80001598:	00100a37          	lui	s4,0x100
    8000159c:	1a7d                	addi	s4,s4,-1
    8000159e:	0a32                	slli	s4,s4,0xc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800015a0:	6985                	lui	s3,0x1
    800015a2:	a035                	j	800015ce <copyinstr+0x56>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800015a4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800015a8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800015aa:	0017b793          	seqz	a5,a5
    800015ae:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800015b2:	60a6                	ld	ra,72(sp)
    800015b4:	6406                	ld	s0,64(sp)
    800015b6:	74e2                	ld	s1,56(sp)
    800015b8:	7942                	ld	s2,48(sp)
    800015ba:	79a2                	ld	s3,40(sp)
    800015bc:	7a02                	ld	s4,32(sp)
    800015be:	6ae2                	ld	s5,24(sp)
    800015c0:	6b42                	ld	s6,16(sp)
    800015c2:	6ba2                	ld	s7,8(sp)
    800015c4:	6161                	addi	sp,sp,80
    800015c6:	8082                	ret
    srcva = va0 + PGSIZE;
    800015c8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800015cc:	c8a9                	beqz	s1,8000161e <copyinstr+0xa6>
    va0 = (uint)PGROUNDDOWN(srcva);
    800015ce:	014bf933          	and	s2,s7,s4
    pa0 = walkaddr(pagetable, va0);
    800015d2:	85ca                	mv	a1,s2
    800015d4:	8556                	mv	a0,s5
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	8b8080e7          	jalr	-1864(ra) # 80000e8e <walkaddr>
    if(pa0 == 0)
    800015de:	c131                	beqz	a0,80001622 <copyinstr+0xaa>
    n = PGSIZE - (srcva - va0);
    800015e0:	41790833          	sub	a6,s2,s7
    800015e4:	984e                	add	a6,a6,s3
    if(n > max)
    800015e6:	0104f363          	bgeu	s1,a6,800015ec <copyinstr+0x74>
    800015ea:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800015ec:	955e                	add	a0,a0,s7
    800015ee:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800015f2:	fc080be3          	beqz	a6,800015c8 <copyinstr+0x50>
    800015f6:	985a                	add	a6,a6,s6
    800015f8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800015fa:	41650633          	sub	a2,a0,s6
    800015fe:	14fd                	addi	s1,s1,-1
    80001600:	9b26                	add	s6,s6,s1
    80001602:	00f60733          	add	a4,a2,a5
    80001606:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4fa4>
    8000160a:	df49                	beqz	a4,800015a4 <copyinstr+0x2c>
        *dst = *p;
    8000160c:	00e78023          	sb	a4,0(a5)
      --max;
    80001610:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001614:	0785                	addi	a5,a5,1
    while(n > 0){
    80001616:	ff0796e3          	bne	a5,a6,80001602 <copyinstr+0x8a>
      dst++;
    8000161a:	8b42                	mv	s6,a6
    8000161c:	b775                	j	800015c8 <copyinstr+0x50>
    8000161e:	4781                	li	a5,0
    80001620:	b769                	j	800015aa <copyinstr+0x32>
      return -1;
    80001622:	557d                	li	a0,-1
    80001624:	b779                	j	800015b2 <copyinstr+0x3a>
  int got_null = 0;
    80001626:	4781                	li	a5,0
  if(got_null){
    80001628:	0017b793          	seqz	a5,a5
    8000162c:	40f00533          	neg	a0,a5
}
    80001630:	8082                	ret

0000000080001632 <print_pte>:

void
print_pte(uint64 pte, int level, int index) {
  if((pte & PTE_V) != 0) {
    80001632:	00157793          	andi	a5,a0,1
    80001636:	c7a5                	beqz	a5,8000169e <print_pte+0x6c>
print_pte(uint64 pte, int level, int index) {
    80001638:	7139                	addi	sp,sp,-64
    8000163a:	fc06                	sd	ra,56(sp)
    8000163c:	f822                	sd	s0,48(sp)
    8000163e:	f426                	sd	s1,40(sp)
    80001640:	f04a                	sd	s2,32(sp)
    80001642:	ec4e                	sd	s3,24(sp)
    80001644:	e852                	sd	s4,16(sp)
    80001646:	e456                	sd	s5,8(sp)
    80001648:	0080                	addi	s0,sp,64
    8000164a:	89aa                	mv	s3,a0
    8000164c:	8ab2                	mv	s5,a2
      for(int i = 0; i < 3-level; i++) {
    8000164e:	490d                	li	s2,3
    80001650:	40b9093b          	subw	s2,s2,a1
    80001654:	01205f63          	blez	s2,80001672 <print_pte+0x40>
    80001658:	4481                	li	s1,0
        printf(" ..");
    8000165a:	00007a17          	auipc	s4,0x7
    8000165e:	c5ea0a13          	addi	s4,s4,-930 # 800082b8 <userret+0x228>
    80001662:	8552                	mv	a0,s4
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	f34080e7          	jalr	-204(ra) # 80000598 <printf>
      for(int i = 0; i < 3-level; i++) {
    8000166c:	2485                	addiw	s1,s1,1
    8000166e:	ff249ae3          	bne	s1,s2,80001662 <print_pte+0x30>
      }
      printf("%d: pte %p pa %p\n", index, pte, PTE2PA(pte));
    80001672:	00a9d693          	srli	a3,s3,0xa
    80001676:	06b2                	slli	a3,a3,0xc
    80001678:	864e                	mv	a2,s3
    8000167a:	85d6                	mv	a1,s5
    8000167c:	00007517          	auipc	a0,0x7
    80001680:	c4450513          	addi	a0,a0,-956 # 800082c0 <userret+0x230>
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	f14080e7          	jalr	-236(ra) # 80000598 <printf>
    }
}
    8000168c:	70e2                	ld	ra,56(sp)
    8000168e:	7442                	ld	s0,48(sp)
    80001690:	74a2                	ld	s1,40(sp)
    80001692:	7902                	ld	s2,32(sp)
    80001694:	69e2                	ld	s3,24(sp)
    80001696:	6a42                	ld	s4,16(sp)
    80001698:	6aa2                	ld	s5,8(sp)
    8000169a:	6121                	addi	sp,sp,64
    8000169c:	8082                	ret
    8000169e:	8082                	ret

00000000800016a0 <print_level>:

uint64
print_level(pagetable_t pagetable, int level)
{
    800016a0:	7159                	addi	sp,sp,-112
    800016a2:	f486                	sd	ra,104(sp)
    800016a4:	f0a2                	sd	s0,96(sp)
    800016a6:	eca6                	sd	s1,88(sp)
    800016a8:	e8ca                	sd	s2,80(sp)
    800016aa:	e4ce                	sd	s3,72(sp)
    800016ac:	e0d2                	sd	s4,64(sp)
    800016ae:	fc56                	sd	s5,56(sp)
    800016b0:	f85a                	sd	s6,48(sp)
    800016b2:	f45e                	sd	s7,40(sp)
    800016b4:	f062                	sd	s8,32(sp)
    800016b6:	ec66                	sd	s9,24(sp)
    800016b8:	e86a                	sd	s10,16(sp)
    800016ba:	e46e                	sd	s11,8(sp)
    800016bc:	1880                	addi	s0,sp,112
    800016be:	8aae                	mv	s5,a1
  uint64 lastpa = 0;
  pte_t lastpte = 0;
  int lastindex = 0;
  int printlast = 0;
  for(int i = 0; i < 512; i++) {
    800016c0:	89aa                	mv	s3,a0
    800016c2:	4481                	li	s1,0
  int printlast = 0;
    800016c4:	4b81                	li	s7,0
  int lastindex = 0;
    800016c6:	4601                	li	a2,0
  pte_t lastpte = 0;
    800016c8:	4901                	li	s2,0
  uint64 lastpa = 0;
    800016ca:	4a01                	li	s4,0

    // if(pte != 0) printf("%d: pte %x %d %d\n", i, pte, printlast);

    if(pte & PTE_V) {
      uint64 next = PTE2PA(pte);
      if((next - lastpa != 4096) || i == 0 || i == 511) {
    800016cc:	6c05                	lui	s8,0x1
    }
    
    if(pte & PTE_V){
      uint64 child = PTE2PA(pte);
      if(level > 0) {
        lastpa = print_level((pagetable_t)child, level-1);
    800016ce:	fff58c9b          	addiw	s9,a1,-1
      if((next - lastpa != 4096) || i == 0 || i == 511) {
    800016d2:	1ff00d13          	li	s10,511
  for(int i = 0; i < 512; i++) {
    800016d6:	20000b13          	li	s6,512
    800016da:	a01d                	j	80001700 <print_level+0x60>
        print_pte(pte, level, i);
    800016dc:	8626                	mv	a2,s1
    800016de:	85d6                	mv	a1,s5
    800016e0:	854a                	mv	a0,s2
    800016e2:	00000097          	auipc	ra,0x0
    800016e6:	f50080e7          	jalr	-176(ra) # 80001632 <print_pte>
    800016ea:	8ba6                	mv	s7,s1
      } else {
        lastpa = child;
    800016ec:	8a6e                	mv	s4,s11
      if(level > 0) {
    800016ee:	05504863          	bgtz	s5,8000173e <print_level+0x9e>
  for(int i = 0; i < 512; i++) {
    800016f2:	0014879b          	addiw	a5,s1,1
    800016f6:	09a1                	addi	s3,s3,8
    800016f8:	8626                	mv	a2,s1
    800016fa:	05678a63          	beq	a5,s6,8000174e <print_level+0xae>
    800016fe:	84be                	mv	s1,a5
    pte_t pte = pagetable[i];
    80001700:	854a                	mv	a0,s2
    80001702:	0009b903          	ld	s2,0(s3) # 1000 <_entry-0x7ffff000>
    if(pte & PTE_V) {
    80001706:	00197793          	andi	a5,s2,1
    8000170a:	cf81                	beqz	a5,80001722 <print_level+0x82>
      uint64 next = PTE2PA(pte);
    8000170c:	00a95d93          	srli	s11,s2,0xa
    80001710:	0db2                	slli	s11,s11,0xc
      if((next - lastpa != 4096) || i == 0 || i == 511) {
    80001712:	414d8a33          	sub	s4,s11,s4
    80001716:	fd8a13e3          	bne	s4,s8,800016dc <print_level+0x3c>
    8000171a:	d0e9                	beqz	s1,800016dc <print_level+0x3c>
    8000171c:	fda498e3          	bne	s1,s10,800016ec <print_level+0x4c>
    80001720:	bf75                	j	800016dc <print_level+0x3c>
      if((lastpte & PTE_V) && printlast != i-1) {
    80001722:	00157793          	andi	a5,a0,1
    80001726:	d7f1                	beqz	a5,800016f2 <print_level+0x52>
    80001728:	fff4879b          	addiw	a5,s1,-1
    8000172c:	fd7783e3          	beq	a5,s7,800016f2 <print_level+0x52>
        print_pte(lastpte, level, lastindex);
    80001730:	85d6                	mv	a1,s5
    80001732:	00000097          	auipc	ra,0x0
    80001736:	f00080e7          	jalr	-256(ra) # 80001632 <print_pte>
    8000173a:	8ba6                	mv	s7,s1
    8000173c:	bf5d                	j	800016f2 <print_level+0x52>
        lastpa = print_level((pagetable_t)child, level-1);
    8000173e:	85e6                	mv	a1,s9
    80001740:	856e                	mv	a0,s11
    80001742:	00000097          	auipc	ra,0x0
    80001746:	f5e080e7          	jalr	-162(ra) # 800016a0 <print_level>
    8000174a:	8a2a                	mv	s4,a0
    8000174c:	b75d                	j	800016f2 <print_level+0x52>
    lastpte = pte;
    lastindex = i;
  }
  
  return lastpa;
}
    8000174e:	8552                	mv	a0,s4
    80001750:	70a6                	ld	ra,104(sp)
    80001752:	7406                	ld	s0,96(sp)
    80001754:	64e6                	ld	s1,88(sp)
    80001756:	6946                	ld	s2,80(sp)
    80001758:	69a6                	ld	s3,72(sp)
    8000175a:	6a06                	ld	s4,64(sp)
    8000175c:	7ae2                	ld	s5,56(sp)
    8000175e:	7b42                	ld	s6,48(sp)
    80001760:	7ba2                	ld	s7,40(sp)
    80001762:	7c02                	ld	s8,32(sp)
    80001764:	6ce2                	ld	s9,24(sp)
    80001766:	6d42                	ld	s10,16(sp)
    80001768:	6da2                	ld	s11,8(sp)
    8000176a:	6165                	addi	sp,sp,112
    8000176c:	8082                	ret

000000008000176e <print>:

void
print(pagetable_t pagetable) {
    8000176e:	1101                	addi	sp,sp,-32
    80001770:	ec06                	sd	ra,24(sp)
    80001772:	e822                	sd	s0,16(sp)
    80001774:	e426                	sd	s1,8(sp)
    80001776:	1000                	addi	s0,sp,32
    80001778:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    8000177a:	85aa                	mv	a1,a0
    8000177c:	00007517          	auipc	a0,0x7
    80001780:	b5c50513          	addi	a0,a0,-1188 # 800082d8 <userret+0x248>
    80001784:	fffff097          	auipc	ra,0xfffff
    80001788:	e14080e7          	jalr	-492(ra) # 80000598 <printf>
  print_level(pagetable, 2);
    8000178c:	4589                	li	a1,2
    8000178e:	8526                	mv	a0,s1
    80001790:	00000097          	auipc	ra,0x0
    80001794:	f10080e7          	jalr	-240(ra) # 800016a0 <print_level>
}
    80001798:	60e2                	ld	ra,24(sp)
    8000179a:	6442                	ld	s0,16(sp)
    8000179c:	64a2                	ld	s1,8(sp)
    8000179e:	6105                	addi	sp,sp,32
    800017a0:	8082                	ret

00000000800017a2 <procinit>:

extern char trampoline[]; // trampoline.S

void
procinit(void)
{
    800017a2:	715d                	addi	sp,sp,-80
    800017a4:	e486                	sd	ra,72(sp)
    800017a6:	e0a2                	sd	s0,64(sp)
    800017a8:	fc26                	sd	s1,56(sp)
    800017aa:	f84a                	sd	s2,48(sp)
    800017ac:	f44e                	sd	s3,40(sp)
    800017ae:	f052                	sd	s4,32(sp)
    800017b0:	ec56                	sd	s5,24(sp)
    800017b2:	e85a                	sd	s6,16(sp)
    800017b4:	e45e                	sd	s7,8(sp)
    800017b6:	0880                	addi	s0,sp,80
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800017b8:	00007597          	auipc	a1,0x7
    800017bc:	b3058593          	addi	a1,a1,-1232 # 800082e8 <userret+0x258>
    800017c0:	00011517          	auipc	a0,0x11
    800017c4:	10850513          	addi	a0,a0,264 # 800128c8 <pid_lock>
    800017c8:	fffff097          	auipc	ra,0xfffff
    800017cc:	0f2080e7          	jalr	242(ra) # 800008ba <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017d0:	00011917          	auipc	s2,0x11
    800017d4:	51090913          	addi	s2,s2,1296 # 80012ce0 <proc>
      initlock(&p->lock, "proc");
    800017d8:	00007b97          	auipc	s7,0x7
    800017dc:	b18b8b93          	addi	s7,s7,-1256 # 800082f0 <userret+0x260>
      // Map it high in memory, followed by an invalid
      // guard page.
      char *pa = kalloc();
      if(pa == 0)
        panic("kalloc");
      uint64 va = KSTACK((int) (p - proc));
    800017e0:	8b4a                	mv	s6,s2
    800017e2:	00007a97          	auipc	s5,0x7
    800017e6:	33ea8a93          	addi	s5,s5,830 # 80008b20 <syscalls+0xc0>
    800017ea:	040009b7          	lui	s3,0x4000
    800017ee:	19fd                	addi	s3,s3,-1
    800017f0:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800017f2:	00017a17          	auipc	s4,0x17
    800017f6:	eeea0a13          	addi	s4,s4,-274 # 800186e0 <tickslock>
      initlock(&p->lock, "proc");
    800017fa:	85de                	mv	a1,s7
    800017fc:	854a                	mv	a0,s2
    800017fe:	fffff097          	auipc	ra,0xfffff
    80001802:	0bc080e7          	jalr	188(ra) # 800008ba <initlock>
      char *pa = kalloc();
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	09a080e7          	jalr	154(ra) # 800008a0 <kalloc>
    8000180e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001810:	c929                	beqz	a0,80001862 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001812:	416904b3          	sub	s1,s2,s6
    80001816:	848d                	srai	s1,s1,0x3
    80001818:	000ab783          	ld	a5,0(s5)
    8000181c:	02f484b3          	mul	s1,s1,a5
    80001820:	2485                	addiw	s1,s1,1
    80001822:	00d4949b          	slliw	s1,s1,0xd
    80001826:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000182a:	4699                	li	a3,6
    8000182c:	6605                	lui	a2,0x1
    8000182e:	8526                	mv	a0,s1
    80001830:	fffff097          	auipc	ra,0xfffff
    80001834:	780080e7          	jalr	1920(ra) # 80000fb0 <kvmmap>
      p->kstack = va;
    80001838:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000183c:	16890913          	addi	s2,s2,360
    80001840:	fb491de3          	bne	s2,s4,800017fa <procinit+0x58>
  }
  kvminithart();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	626080e7          	jalr	1574(ra) # 80000e6a <kvminithart>
}
    8000184c:	60a6                	ld	ra,72(sp)
    8000184e:	6406                	ld	s0,64(sp)
    80001850:	74e2                	ld	s1,56(sp)
    80001852:	7942                	ld	s2,48(sp)
    80001854:	79a2                	ld	s3,40(sp)
    80001856:	7a02                	ld	s4,32(sp)
    80001858:	6ae2                	ld	s5,24(sp)
    8000185a:	6b42                	ld	s6,16(sp)
    8000185c:	6ba2                	ld	s7,8(sp)
    8000185e:	6161                	addi	sp,sp,80
    80001860:	8082                	ret
        panic("kalloc");
    80001862:	00007517          	auipc	a0,0x7
    80001866:	a9650513          	addi	a0,a0,-1386 # 800082f8 <userret+0x268>
    8000186a:	fffff097          	auipc	ra,0xfffff
    8000186e:	ce4080e7          	jalr	-796(ra) # 8000054e <panic>

0000000080001872 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001872:	1141                	addi	sp,sp,-16
    80001874:	e422                	sd	s0,8(sp)
    80001876:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001878:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000187a:	2501                	sext.w	a0,a0
    8000187c:	6422                	ld	s0,8(sp)
    8000187e:	0141                	addi	sp,sp,16
    80001880:	8082                	ret

0000000080001882 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001882:	1141                	addi	sp,sp,-16
    80001884:	e422                	sd	s0,8(sp)
    80001886:	0800                	addi	s0,sp,16
    80001888:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000188a:	2781                	sext.w	a5,a5
    8000188c:	079e                	slli	a5,a5,0x7
  return c;
}
    8000188e:	00011517          	auipc	a0,0x11
    80001892:	05250513          	addi	a0,a0,82 # 800128e0 <cpus>
    80001896:	953e                	add	a0,a0,a5
    80001898:	6422                	ld	s0,8(sp)
    8000189a:	0141                	addi	sp,sp,16
    8000189c:	8082                	ret

000000008000189e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000189e:	1101                	addi	sp,sp,-32
    800018a0:	ec06                	sd	ra,24(sp)
    800018a2:	e822                	sd	s0,16(sp)
    800018a4:	e426                	sd	s1,8(sp)
    800018a6:	1000                	addi	s0,sp,32
  push_off();
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	028080e7          	jalr	40(ra) # 800008d0 <push_off>
    800018b0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800018b2:	2781                	sext.w	a5,a5
    800018b4:	079e                	slli	a5,a5,0x7
    800018b6:	00011717          	auipc	a4,0x11
    800018ba:	01270713          	addi	a4,a4,18 # 800128c8 <pid_lock>
    800018be:	97ba                	add	a5,a5,a4
    800018c0:	6f84                	ld	s1,24(a5)
  pop_off();
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	05a080e7          	jalr	90(ra) # 8000091c <pop_off>
  return p;
}
    800018ca:	8526                	mv	a0,s1
    800018cc:	60e2                	ld	ra,24(sp)
    800018ce:	6442                	ld	s0,16(sp)
    800018d0:	64a2                	ld	s1,8(sp)
    800018d2:	6105                	addi	sp,sp,32
    800018d4:	8082                	ret

00000000800018d6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800018d6:	1141                	addi	sp,sp,-16
    800018d8:	e406                	sd	ra,8(sp)
    800018da:	e022                	sd	s0,0(sp)
    800018dc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800018de:	00000097          	auipc	ra,0x0
    800018e2:	fc0080e7          	jalr	-64(ra) # 8000189e <myproc>
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	14e080e7          	jalr	334(ra) # 80000a34 <release>

  if (first) {
    800018ee:	00007797          	auipc	a5,0x7
    800018f2:	7467a783          	lw	a5,1862(a5) # 80009034 <first.1743>
    800018f6:	eb89                	bnez	a5,80001908 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(minor(ROOTDEV));
  }

  usertrapret();
    800018f8:	00001097          	auipc	ra,0x1
    800018fc:	c1c080e7          	jalr	-996(ra) # 80002514 <usertrapret>
}
    80001900:	60a2                	ld	ra,8(sp)
    80001902:	6402                	ld	s0,0(sp)
    80001904:	0141                	addi	sp,sp,16
    80001906:	8082                	ret
    first = 0;
    80001908:	00007797          	auipc	a5,0x7
    8000190c:	7207a623          	sw	zero,1836(a5) # 80009034 <first.1743>
    fsinit(minor(ROOTDEV));
    80001910:	4501                	li	a0,0
    80001912:	00002097          	auipc	ra,0x2
    80001916:	944080e7          	jalr	-1724(ra) # 80003256 <fsinit>
    8000191a:	bff9                	j	800018f8 <forkret+0x22>

000000008000191c <allocpid>:
allocpid() {
    8000191c:	1101                	addi	sp,sp,-32
    8000191e:	ec06                	sd	ra,24(sp)
    80001920:	e822                	sd	s0,16(sp)
    80001922:	e426                	sd	s1,8(sp)
    80001924:	e04a                	sd	s2,0(sp)
    80001926:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001928:	00011917          	auipc	s2,0x11
    8000192c:	fa090913          	addi	s2,s2,-96 # 800128c8 <pid_lock>
    80001930:	854a                	mv	a0,s2
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	09a080e7          	jalr	154(ra) # 800009cc <acquire>
  pid = nextpid;
    8000193a:	00007797          	auipc	a5,0x7
    8000193e:	6fe78793          	addi	a5,a5,1790 # 80009038 <nextpid>
    80001942:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001944:	0014871b          	addiw	a4,s1,1
    80001948:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    8000194a:	854a                	mv	a0,s2
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	0e8080e7          	jalr	232(ra) # 80000a34 <release>
}
    80001954:	8526                	mv	a0,s1
    80001956:	60e2                	ld	ra,24(sp)
    80001958:	6442                	ld	s0,16(sp)
    8000195a:	64a2                	ld	s1,8(sp)
    8000195c:	6902                	ld	s2,0(sp)
    8000195e:	6105                	addi	sp,sp,32
    80001960:	8082                	ret

0000000080001962 <proc_pagetable>:
{
    80001962:	1101                	addi	sp,sp,-32
    80001964:	ec06                	sd	ra,24(sp)
    80001966:	e822                	sd	s0,16(sp)
    80001968:	e426                	sd	s1,8(sp)
    8000196a:	e04a                	sd	s2,0(sp)
    8000196c:	1000                	addi	s0,sp,32
    8000196e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001970:	00000097          	auipc	ra,0x0
    80001974:	826080e7          	jalr	-2010(ra) # 80001196 <uvmcreate>
    80001978:	84aa                	mv	s1,a0
  mappages(pagetable, TRAMPOLINE, PGSIZE,
    8000197a:	4729                	li	a4,10
    8000197c:	00006697          	auipc	a3,0x6
    80001980:	68468693          	addi	a3,a3,1668 # 80008000 <trampoline>
    80001984:	6605                	lui	a2,0x1
    80001986:	040005b7          	lui	a1,0x4000
    8000198a:	15fd                	addi	a1,a1,-1
    8000198c:	05b2                	slli	a1,a1,0xc
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	594080e7          	jalr	1428(ra) # 80000f22 <mappages>
  mappages(pagetable, TRAPFRAME, PGSIZE,
    80001996:	4719                	li	a4,6
    80001998:	05893683          	ld	a3,88(s2)
    8000199c:	6605                	lui	a2,0x1
    8000199e:	020005b7          	lui	a1,0x2000
    800019a2:	15fd                	addi	a1,a1,-1
    800019a4:	05b6                	slli	a1,a1,0xd
    800019a6:	8526                	mv	a0,s1
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	57a080e7          	jalr	1402(ra) # 80000f22 <mappages>
}
    800019b0:	8526                	mv	a0,s1
    800019b2:	60e2                	ld	ra,24(sp)
    800019b4:	6442                	ld	s0,16(sp)
    800019b6:	64a2                	ld	s1,8(sp)
    800019b8:	6902                	ld	s2,0(sp)
    800019ba:	6105                	addi	sp,sp,32
    800019bc:	8082                	ret

00000000800019be <allocproc>:
{
    800019be:	1101                	addi	sp,sp,-32
    800019c0:	ec06                	sd	ra,24(sp)
    800019c2:	e822                	sd	s0,16(sp)
    800019c4:	e426                	sd	s1,8(sp)
    800019c6:	e04a                	sd	s2,0(sp)
    800019c8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ca:	00011497          	auipc	s1,0x11
    800019ce:	31648493          	addi	s1,s1,790 # 80012ce0 <proc>
    800019d2:	00017917          	auipc	s2,0x17
    800019d6:	d0e90913          	addi	s2,s2,-754 # 800186e0 <tickslock>
    acquire(&p->lock);
    800019da:	8526                	mv	a0,s1
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	ff0080e7          	jalr	-16(ra) # 800009cc <acquire>
    if(p->state == UNUSED) {
    800019e4:	4c9c                	lw	a5,24(s1)
    800019e6:	cf81                	beqz	a5,800019fe <allocproc+0x40>
      release(&p->lock);
    800019e8:	8526                	mv	a0,s1
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	04a080e7          	jalr	74(ra) # 80000a34 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f2:	16848493          	addi	s1,s1,360
    800019f6:	ff2492e3          	bne	s1,s2,800019da <allocproc+0x1c>
  return 0;
    800019fa:	4481                	li	s1,0
    800019fc:	a0a9                	j	80001a46 <allocproc+0x88>
  p->pid = allocpid();
    800019fe:	00000097          	auipc	ra,0x0
    80001a02:	f1e080e7          	jalr	-226(ra) # 8000191c <allocpid>
    80001a06:	dc88                	sw	a0,56(s1)
  if((p->tf = (struct trapframe *)kalloc()) == 0){
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	e98080e7          	jalr	-360(ra) # 800008a0 <kalloc>
    80001a10:	892a                	mv	s2,a0
    80001a12:	eca8                	sd	a0,88(s1)
    80001a14:	c121                	beqz	a0,80001a54 <allocproc+0x96>
  p->pagetable = proc_pagetable(p);
    80001a16:	8526                	mv	a0,s1
    80001a18:	00000097          	auipc	ra,0x0
    80001a1c:	f4a080e7          	jalr	-182(ra) # 80001962 <proc_pagetable>
    80001a20:	e8a8                	sd	a0,80(s1)
  memset(&p->context, 0, sizeof p->context);
    80001a22:	07000613          	li	a2,112
    80001a26:	4581                	li	a1,0
    80001a28:	06048513          	addi	a0,s1,96
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	064080e7          	jalr	100(ra) # 80000a90 <memset>
  p->context.ra = (uint64)forkret;
    80001a34:	00000797          	auipc	a5,0x0
    80001a38:	ea278793          	addi	a5,a5,-350 # 800018d6 <forkret>
    80001a3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001a3e:	60bc                	ld	a5,64(s1)
    80001a40:	6705                	lui	a4,0x1
    80001a42:	97ba                	add	a5,a5,a4
    80001a44:	f4bc                	sd	a5,104(s1)
}
    80001a46:	8526                	mv	a0,s1
    80001a48:	60e2                	ld	ra,24(sp)
    80001a4a:	6442                	ld	s0,16(sp)
    80001a4c:	64a2                	ld	s1,8(sp)
    80001a4e:	6902                	ld	s2,0(sp)
    80001a50:	6105                	addi	sp,sp,32
    80001a52:	8082                	ret
    release(&p->lock);
    80001a54:	8526                	mv	a0,s1
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	fde080e7          	jalr	-34(ra) # 80000a34 <release>
    return 0;
    80001a5e:	84ca                	mv	s1,s2
    80001a60:	b7dd                	j	80001a46 <allocproc+0x88>

0000000080001a62 <proc_freepagetable>:
{
    80001a62:	1101                	addi	sp,sp,-32
    80001a64:	ec06                	sd	ra,24(sp)
    80001a66:	e822                	sd	s0,16(sp)
    80001a68:	e426                	sd	s1,8(sp)
    80001a6a:	e04a                	sd	s2,0(sp)
    80001a6c:	1000                	addi	s0,sp,32
    80001a6e:	84aa                	mv	s1,a0
    80001a70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, PGSIZE, 0);
    80001a72:	4681                	li	a3,0
    80001a74:	6605                	lui	a2,0x1
    80001a76:	040005b7          	lui	a1,0x4000
    80001a7a:	15fd                	addi	a1,a1,-1
    80001a7c:	05b2                	slli	a1,a1,0xc
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	650080e7          	jalr	1616(ra) # 800010ce <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, PGSIZE, 0);
    80001a86:	4681                	li	a3,0
    80001a88:	6605                	lui	a2,0x1
    80001a8a:	020005b7          	lui	a1,0x2000
    80001a8e:	15fd                	addi	a1,a1,-1
    80001a90:	05b6                	slli	a1,a1,0xd
    80001a92:	8526                	mv	a0,s1
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	63a080e7          	jalr	1594(ra) # 800010ce <uvmunmap>
  if(sz > 0)
    80001a9c:	00091863          	bnez	s2,80001aac <proc_freepagetable+0x4a>
}
    80001aa0:	60e2                	ld	ra,24(sp)
    80001aa2:	6442                	ld	s0,16(sp)
    80001aa4:	64a2                	ld	s1,8(sp)
    80001aa6:	6902                	ld	s2,0(sp)
    80001aa8:	6105                	addi	sp,sp,32
    80001aaa:	8082                	ret
    uvmfree(pagetable, sz);
    80001aac:	85ca                	mv	a1,s2
    80001aae:	8526                	mv	a0,s1
    80001ab0:	00000097          	auipc	ra,0x0
    80001ab4:	874080e7          	jalr	-1932(ra) # 80001324 <uvmfree>
}
    80001ab8:	b7e5                	j	80001aa0 <proc_freepagetable+0x3e>

0000000080001aba <freeproc>:
{
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	1000                	addi	s0,sp,32
    80001ac4:	84aa                	mv	s1,a0
  if(p->tf)
    80001ac6:	6d28                	ld	a0,88(a0)
    80001ac8:	c509                	beqz	a0,80001ad2 <freeproc+0x18>
    kfree((void*)p->tf);
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	dbe080e7          	jalr	-578(ra) # 80000888 <kfree>
  p->tf = 0;
    80001ad2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ad6:	68a8                	ld	a0,80(s1)
    80001ad8:	c511                	beqz	a0,80001ae4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ada:	64ac                	ld	a1,72(s1)
    80001adc:	00000097          	auipc	ra,0x0
    80001ae0:	f86080e7          	jalr	-122(ra) # 80001a62 <proc_freepagetable>
  p->pagetable = 0;
    80001ae4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ae8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001aec:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001af0:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001af4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001af8:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001afc:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001b00:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001b04:	0004ac23          	sw	zero,24(s1)
}
    80001b08:	60e2                	ld	ra,24(sp)
    80001b0a:	6442                	ld	s0,16(sp)
    80001b0c:	64a2                	ld	s1,8(sp)
    80001b0e:	6105                	addi	sp,sp,32
    80001b10:	8082                	ret

0000000080001b12 <userinit>:
{
    80001b12:	1101                	addi	sp,sp,-32
    80001b14:	ec06                	sd	ra,24(sp)
    80001b16:	e822                	sd	s0,16(sp)
    80001b18:	e426                	sd	s1,8(sp)
    80001b1a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	ea2080e7          	jalr	-350(ra) # 800019be <allocproc>
    80001b24:	84aa                	mv	s1,a0
  initproc = p;
    80001b26:	00028797          	auipc	a5,0x28
    80001b2a:	50a7b923          	sd	a0,1298(a5) # 8002a038 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001b2e:	03300613          	li	a2,51
    80001b32:	00007597          	auipc	a1,0x7
    80001b36:	4ce58593          	addi	a1,a1,1230 # 80009000 <initcode>
    80001b3a:	6928                	ld	a0,80(a0)
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	698080e7          	jalr	1688(ra) # 800011d4 <uvminit>
  p->sz = PGSIZE;
    80001b44:	6785                	lui	a5,0x1
    80001b46:	e4bc                	sd	a5,72(s1)
  p->tf->epc = 0;      // user program counter
    80001b48:	6cb8                	ld	a4,88(s1)
    80001b4a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->tf->sp = PGSIZE;  // user stack pointer
    80001b4e:	6cb8                	ld	a4,88(s1)
    80001b50:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001b52:	4641                	li	a2,16
    80001b54:	00006597          	auipc	a1,0x6
    80001b58:	7ac58593          	addi	a1,a1,1964 # 80008300 <userret+0x270>
    80001b5c:	15848513          	addi	a0,s1,344
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	086080e7          	jalr	134(ra) # 80000be6 <safestrcpy>
  p->cwd = namei("/");
    80001b68:	00006517          	auipc	a0,0x6
    80001b6c:	7a850513          	addi	a0,a0,1960 # 80008310 <userret+0x280>
    80001b70:	00002097          	auipc	ra,0x2
    80001b74:	0ea080e7          	jalr	234(ra) # 80003c5a <namei>
    80001b78:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001b7c:	4789                	li	a5,2
    80001b7e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001b80:	8526                	mv	a0,s1
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	eb2080e7          	jalr	-334(ra) # 80000a34 <release>
}
    80001b8a:	60e2                	ld	ra,24(sp)
    80001b8c:	6442                	ld	s0,16(sp)
    80001b8e:	64a2                	ld	s1,8(sp)
    80001b90:	6105                	addi	sp,sp,32
    80001b92:	8082                	ret

0000000080001b94 <growproc>:
{
    80001b94:	1101                	addi	sp,sp,-32
    80001b96:	ec06                	sd	ra,24(sp)
    80001b98:	e822                	sd	s0,16(sp)
    80001b9a:	e426                	sd	s1,8(sp)
    80001b9c:	e04a                	sd	s2,0(sp)
    80001b9e:	1000                	addi	s0,sp,32
    80001ba0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	cfc080e7          	jalr	-772(ra) # 8000189e <myproc>
    80001baa:	892a                	mv	s2,a0
  sz = p->sz;
    80001bac:	652c                	ld	a1,72(a0)
    80001bae:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001bb2:	00904f63          	bgtz	s1,80001bd0 <growproc+0x3c>
  } else if(n < 0){
    80001bb6:	0204cc63          	bltz	s1,80001bee <growproc+0x5a>
  p->sz = sz;
    80001bba:	1602                	slli	a2,a2,0x20
    80001bbc:	9201                	srli	a2,a2,0x20
    80001bbe:	04c93423          	sd	a2,72(s2)
  return 0;
    80001bc2:	4501                	li	a0,0
}
    80001bc4:	60e2                	ld	ra,24(sp)
    80001bc6:	6442                	ld	s0,16(sp)
    80001bc8:	64a2                	ld	s1,8(sp)
    80001bca:	6902                	ld	s2,0(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001bd0:	9e25                	addw	a2,a2,s1
    80001bd2:	1602                	slli	a2,a2,0x20
    80001bd4:	9201                	srli	a2,a2,0x20
    80001bd6:	1582                	slli	a1,a1,0x20
    80001bd8:	9181                	srli	a1,a1,0x20
    80001bda:	6928                	ld	a0,80(a0)
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	69e080e7          	jalr	1694(ra) # 8000127a <uvmalloc>
    80001be4:	0005061b          	sext.w	a2,a0
    80001be8:	fa69                	bnez	a2,80001bba <growproc+0x26>
      return -1;
    80001bea:	557d                	li	a0,-1
    80001bec:	bfe1                	j	80001bc4 <growproc+0x30>
    if((sz = uvmdealloc(p->pagetable, sz, sz + n)) == 0) {
    80001bee:	9e25                	addw	a2,a2,s1
    80001bf0:	1602                	slli	a2,a2,0x20
    80001bf2:	9201                	srli	a2,a2,0x20
    80001bf4:	1582                	slli	a1,a1,0x20
    80001bf6:	9181                	srli	a1,a1,0x20
    80001bf8:	6928                	ld	a0,80(a0)
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	64c080e7          	jalr	1612(ra) # 80001246 <uvmdealloc>
    80001c02:	0005061b          	sext.w	a2,a0
    80001c06:	fa55                	bnez	a2,80001bba <growproc+0x26>
      return -1;
    80001c08:	557d                	li	a0,-1
    80001c0a:	bf6d                	j	80001bc4 <growproc+0x30>

0000000080001c0c <fork>:
{
    80001c0c:	7179                	addi	sp,sp,-48
    80001c0e:	f406                	sd	ra,40(sp)
    80001c10:	f022                	sd	s0,32(sp)
    80001c12:	ec26                	sd	s1,24(sp)
    80001c14:	e84a                	sd	s2,16(sp)
    80001c16:	e44e                	sd	s3,8(sp)
    80001c18:	e052                	sd	s4,0(sp)
    80001c1a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	c82080e7          	jalr	-894(ra) # 8000189e <myproc>
    80001c24:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	d98080e7          	jalr	-616(ra) # 800019be <allocproc>
    80001c2e:	c175                	beqz	a0,80001d12 <fork+0x106>
    80001c30:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001c32:	04893603          	ld	a2,72(s2)
    80001c36:	692c                	ld	a1,80(a0)
    80001c38:	05093503          	ld	a0,80(s2)
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	716080e7          	jalr	1814(ra) # 80001352 <uvmcopy>
    80001c44:	04054863          	bltz	a0,80001c94 <fork+0x88>
  np->sz = p->sz;
    80001c48:	04893783          	ld	a5,72(s2)
    80001c4c:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001c50:	0329b023          	sd	s2,32(s3)
  *(np->tf) = *(p->tf);
    80001c54:	05893683          	ld	a3,88(s2)
    80001c58:	87b6                	mv	a5,a3
    80001c5a:	0589b703          	ld	a4,88(s3)
    80001c5e:	12068693          	addi	a3,a3,288
    80001c62:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001c66:	6788                	ld	a0,8(a5)
    80001c68:	6b8c                	ld	a1,16(a5)
    80001c6a:	6f90                	ld	a2,24(a5)
    80001c6c:	01073023          	sd	a6,0(a4)
    80001c70:	e708                	sd	a0,8(a4)
    80001c72:	eb0c                	sd	a1,16(a4)
    80001c74:	ef10                	sd	a2,24(a4)
    80001c76:	02078793          	addi	a5,a5,32
    80001c7a:	02070713          	addi	a4,a4,32
    80001c7e:	fed792e3          	bne	a5,a3,80001c62 <fork+0x56>
  np->tf->a0 = 0;
    80001c82:	0589b783          	ld	a5,88(s3)
    80001c86:	0607b823          	sd	zero,112(a5)
    80001c8a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001c8e:	15000a13          	li	s4,336
    80001c92:	a03d                	j	80001cc0 <fork+0xb4>
    freeproc(np);
    80001c94:	854e                	mv	a0,s3
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	e24080e7          	jalr	-476(ra) # 80001aba <freeproc>
    release(&np->lock);
    80001c9e:	854e                	mv	a0,s3
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	d94080e7          	jalr	-620(ra) # 80000a34 <release>
    return -1;
    80001ca8:	54fd                	li	s1,-1
    80001caa:	a899                	j	80001d00 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001cac:	00003097          	auipc	ra,0x3
    80001cb0:	8a0080e7          	jalr	-1888(ra) # 8000454c <filedup>
    80001cb4:	009987b3          	add	a5,s3,s1
    80001cb8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001cba:	04a1                	addi	s1,s1,8
    80001cbc:	01448763          	beq	s1,s4,80001cca <fork+0xbe>
    if(p->ofile[i])
    80001cc0:	009907b3          	add	a5,s2,s1
    80001cc4:	6388                	ld	a0,0(a5)
    80001cc6:	f17d                	bnez	a0,80001cac <fork+0xa0>
    80001cc8:	bfcd                	j	80001cba <fork+0xae>
  np->cwd = idup(p->cwd);
    80001cca:	15093503          	ld	a0,336(s2)
    80001cce:	00001097          	auipc	ra,0x1
    80001cd2:	7c2080e7          	jalr	1986(ra) # 80003490 <idup>
    80001cd6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001cda:	4641                	li	a2,16
    80001cdc:	15890593          	addi	a1,s2,344
    80001ce0:	15898513          	addi	a0,s3,344
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	f02080e7          	jalr	-254(ra) # 80000be6 <safestrcpy>
  pid = np->pid;
    80001cec:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001cf0:	4789                	li	a5,2
    80001cf2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001cf6:	854e                	mv	a0,s3
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	d3c080e7          	jalr	-708(ra) # 80000a34 <release>
}
    80001d00:	8526                	mv	a0,s1
    80001d02:	70a2                	ld	ra,40(sp)
    80001d04:	7402                	ld	s0,32(sp)
    80001d06:	64e2                	ld	s1,24(sp)
    80001d08:	6942                	ld	s2,16(sp)
    80001d0a:	69a2                	ld	s3,8(sp)
    80001d0c:	6a02                	ld	s4,0(sp)
    80001d0e:	6145                	addi	sp,sp,48
    80001d10:	8082                	ret
    return -1;
    80001d12:	54fd                	li	s1,-1
    80001d14:	b7f5                	j	80001d00 <fork+0xf4>

0000000080001d16 <reparent>:
reparent(struct proc *p, struct proc *parent) {
    80001d16:	711d                	addi	sp,sp,-96
    80001d18:	ec86                	sd	ra,88(sp)
    80001d1a:	e8a2                	sd	s0,80(sp)
    80001d1c:	e4a6                	sd	s1,72(sp)
    80001d1e:	e0ca                	sd	s2,64(sp)
    80001d20:	fc4e                	sd	s3,56(sp)
    80001d22:	f852                	sd	s4,48(sp)
    80001d24:	f456                	sd	s5,40(sp)
    80001d26:	f05a                	sd	s6,32(sp)
    80001d28:	ec5e                	sd	s7,24(sp)
    80001d2a:	e862                	sd	s8,16(sp)
    80001d2c:	e466                	sd	s9,8(sp)
    80001d2e:	1080                	addi	s0,sp,96
    80001d30:	892a                	mv	s2,a0
  int child_of_init = (p->parent == initproc);
    80001d32:	02053b83          	ld	s7,32(a0)
    80001d36:	00028b17          	auipc	s6,0x28
    80001d3a:	302b3b03          	ld	s6,770(s6) # 8002a038 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001d3e:	00011497          	auipc	s1,0x11
    80001d42:	fa248493          	addi	s1,s1,-94 # 80012ce0 <proc>
      pp->parent = initproc;
    80001d46:	00028a17          	auipc	s4,0x28
    80001d4a:	2f2a0a13          	addi	s4,s4,754 # 8002a038 <initproc>
      if(pp->state == ZOMBIE) {
    80001d4e:	4a91                	li	s5,4
// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
  if(p->chan == p && p->state == SLEEPING) {
    80001d50:	4c05                	li	s8,1
    p->state = RUNNABLE;
    80001d52:	4c89                	li	s9,2
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001d54:	00017997          	auipc	s3,0x17
    80001d58:	98c98993          	addi	s3,s3,-1652 # 800186e0 <tickslock>
    80001d5c:	a805                	j	80001d8c <reparent+0x76>
  if(p->chan == p && p->state == SLEEPING) {
    80001d5e:	751c                	ld	a5,40(a0)
    80001d60:	00f51d63          	bne	a0,a5,80001d7a <reparent+0x64>
    80001d64:	4d1c                	lw	a5,24(a0)
    80001d66:	01879a63          	bne	a5,s8,80001d7a <reparent+0x64>
    p->state = RUNNABLE;
    80001d6a:	01952c23          	sw	s9,24(a0)
        if(!child_of_init)
    80001d6e:	016b8663          	beq	s7,s6,80001d7a <reparent+0x64>
          release(&initproc->lock);
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	cc2080e7          	jalr	-830(ra) # 80000a34 <release>
      release(&pp->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	cb8080e7          	jalr	-840(ra) # 80000a34 <release>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001d84:	16848493          	addi	s1,s1,360
    80001d88:	03348f63          	beq	s1,s3,80001dc6 <reparent+0xb0>
    if(pp->parent == p){
    80001d8c:	709c                	ld	a5,32(s1)
    80001d8e:	ff279be3          	bne	a5,s2,80001d84 <reparent+0x6e>
      acquire(&pp->lock);
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	c38080e7          	jalr	-968(ra) # 800009cc <acquire>
      pp->parent = initproc;
    80001d9c:	000a3503          	ld	a0,0(s4)
    80001da0:	f088                	sd	a0,32(s1)
      if(pp->state == ZOMBIE) {
    80001da2:	4c9c                	lw	a5,24(s1)
    80001da4:	fd579be3          	bne	a5,s5,80001d7a <reparent+0x64>
        if(!child_of_init)
    80001da8:	fb6b8be3          	beq	s7,s6,80001d5e <reparent+0x48>
          acquire(&initproc->lock);
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	c20080e7          	jalr	-992(ra) # 800009cc <acquire>
        wakeup1(initproc);
    80001db4:	000a3503          	ld	a0,0(s4)
  if(p->chan == p && p->state == SLEEPING) {
    80001db8:	751c                	ld	a5,40(a0)
    80001dba:	faa79ce3          	bne	a5,a0,80001d72 <reparent+0x5c>
    80001dbe:	4d1c                	lw	a5,24(a0)
    80001dc0:	fb8799e3          	bne	a5,s8,80001d72 <reparent+0x5c>
    80001dc4:	b75d                	j	80001d6a <reparent+0x54>
}
    80001dc6:	60e6                	ld	ra,88(sp)
    80001dc8:	6446                	ld	s0,80(sp)
    80001dca:	64a6                	ld	s1,72(sp)
    80001dcc:	6906                	ld	s2,64(sp)
    80001dce:	79e2                	ld	s3,56(sp)
    80001dd0:	7a42                	ld	s4,48(sp)
    80001dd2:	7aa2                	ld	s5,40(sp)
    80001dd4:	7b02                	ld	s6,32(sp)
    80001dd6:	6be2                	ld	s7,24(sp)
    80001dd8:	6c42                	ld	s8,16(sp)
    80001dda:	6ca2                	ld	s9,8(sp)
    80001ddc:	6125                	addi	sp,sp,96
    80001dde:	8082                	ret

0000000080001de0 <scheduler>:
{
    80001de0:	715d                	addi	sp,sp,-80
    80001de2:	e486                	sd	ra,72(sp)
    80001de4:	e0a2                	sd	s0,64(sp)
    80001de6:	fc26                	sd	s1,56(sp)
    80001de8:	f84a                	sd	s2,48(sp)
    80001dea:	f44e                	sd	s3,40(sp)
    80001dec:	f052                	sd	s4,32(sp)
    80001dee:	ec56                	sd	s5,24(sp)
    80001df0:	e85a                	sd	s6,16(sp)
    80001df2:	e45e                	sd	s7,8(sp)
    80001df4:	e062                	sd	s8,0(sp)
    80001df6:	0880                	addi	s0,sp,80
    80001df8:	8792                	mv	a5,tp
  int id = r_tp();
    80001dfa:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001dfc:	00779b13          	slli	s6,a5,0x7
    80001e00:	00011717          	auipc	a4,0x11
    80001e04:	ac870713          	addi	a4,a4,-1336 # 800128c8 <pid_lock>
    80001e08:	975a                	add	a4,a4,s6
    80001e0a:	00073c23          	sd	zero,24(a4)
        swtch(&c->scheduler, &p->context);
    80001e0e:	00011717          	auipc	a4,0x11
    80001e12:	ada70713          	addi	a4,a4,-1318 # 800128e8 <cpus+0x8>
    80001e16:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001e18:	4c0d                	li	s8,3
        c->proc = p;
    80001e1a:	079e                	slli	a5,a5,0x7
    80001e1c:	00011a17          	auipc	s4,0x11
    80001e20:	aaca0a13          	addi	s4,s4,-1364 # 800128c8 <pid_lock>
    80001e24:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e26:	00017997          	auipc	s3,0x17
    80001e2a:	8ba98993          	addi	s3,s3,-1862 # 800186e0 <tickslock>
        found = 1;
    80001e2e:	4b85                	li	s7,1
    80001e30:	a08d                	j	80001e92 <scheduler+0xb2>
        p->state = RUNNING;
    80001e32:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001e36:	009a3c23          	sd	s1,24(s4)
        swtch(&c->scheduler, &p->context);
    80001e3a:	06048593          	addi	a1,s1,96
    80001e3e:	855a                	mv	a0,s6
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	62a080e7          	jalr	1578(ra) # 8000246a <swtch>
        c->proc = 0;
    80001e48:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001e4c:	8ade                	mv	s5,s7
      release(&p->lock);
    80001e4e:	8526                	mv	a0,s1
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	be4080e7          	jalr	-1052(ra) # 80000a34 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e58:	16848493          	addi	s1,s1,360
    80001e5c:	01348b63          	beq	s1,s3,80001e72 <scheduler+0x92>
      acquire(&p->lock);
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	b6a080e7          	jalr	-1174(ra) # 800009cc <acquire>
      if(p->state == RUNNABLE) {
    80001e6a:	4c9c                	lw	a5,24(s1)
    80001e6c:	ff2791e3          	bne	a5,s2,80001e4e <scheduler+0x6e>
    80001e70:	b7c9                	j	80001e32 <scheduler+0x52>
    if(found == 0){
    80001e72:	020a9063          	bnez	s5,80001e92 <scheduler+0xb2>
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001e76:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001e7a:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001e7e:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e82:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e86:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e8a:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001e8e:	10500073          	wfi
  asm volatile("csrr %0, sie" : "=r" (x) );
    80001e92:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    80001e96:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80001e9a:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ea2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ea6:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001eaa:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001eac:	00011497          	auipc	s1,0x11
    80001eb0:	e3448493          	addi	s1,s1,-460 # 80012ce0 <proc>
      if(p->state == RUNNABLE) {
    80001eb4:	4909                	li	s2,2
    80001eb6:	b76d                	j	80001e60 <scheduler+0x80>

0000000080001eb8 <sched>:
{
    80001eb8:	7179                	addi	sp,sp,-48
    80001eba:	f406                	sd	ra,40(sp)
    80001ebc:	f022                	sd	s0,32(sp)
    80001ebe:	ec26                	sd	s1,24(sp)
    80001ec0:	e84a                	sd	s2,16(sp)
    80001ec2:	e44e                	sd	s3,8(sp)
    80001ec4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ec6:	00000097          	auipc	ra,0x0
    80001eca:	9d8080e7          	jalr	-1576(ra) # 8000189e <myproc>
    80001ece:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	abc080e7          	jalr	-1348(ra) # 8000098c <holding>
    80001ed8:	c93d                	beqz	a0,80001f4e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001eda:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001edc:	2781                	sext.w	a5,a5
    80001ede:	079e                	slli	a5,a5,0x7
    80001ee0:	00011717          	auipc	a4,0x11
    80001ee4:	9e870713          	addi	a4,a4,-1560 # 800128c8 <pid_lock>
    80001ee8:	97ba                	add	a5,a5,a4
    80001eea:	0907a703          	lw	a4,144(a5)
    80001eee:	4785                	li	a5,1
    80001ef0:	06f71763          	bne	a4,a5,80001f5e <sched+0xa6>
  if(p->state == RUNNING)
    80001ef4:	4c98                	lw	a4,24(s1)
    80001ef6:	478d                	li	a5,3
    80001ef8:	06f70b63          	beq	a4,a5,80001f6e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001efc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f00:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f02:	efb5                	bnez	a5,80001f7e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f04:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f06:	00011917          	auipc	s2,0x11
    80001f0a:	9c290913          	addi	s2,s2,-1598 # 800128c8 <pid_lock>
    80001f0e:	2781                	sext.w	a5,a5
    80001f10:	079e                	slli	a5,a5,0x7
    80001f12:	97ca                	add	a5,a5,s2
    80001f14:	0947a983          	lw	s3,148(a5)
    80001f18:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->scheduler);
    80001f1a:	2781                	sext.w	a5,a5
    80001f1c:	079e                	slli	a5,a5,0x7
    80001f1e:	00011597          	auipc	a1,0x11
    80001f22:	9ca58593          	addi	a1,a1,-1590 # 800128e8 <cpus+0x8>
    80001f26:	95be                	add	a1,a1,a5
    80001f28:	06048513          	addi	a0,s1,96
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	53e080e7          	jalr	1342(ra) # 8000246a <swtch>
    80001f34:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f36:	2781                	sext.w	a5,a5
    80001f38:	079e                	slli	a5,a5,0x7
    80001f3a:	97ca                	add	a5,a5,s2
    80001f3c:	0937aa23          	sw	s3,148(a5)
}
    80001f40:	70a2                	ld	ra,40(sp)
    80001f42:	7402                	ld	s0,32(sp)
    80001f44:	64e2                	ld	s1,24(sp)
    80001f46:	6942                	ld	s2,16(sp)
    80001f48:	69a2                	ld	s3,8(sp)
    80001f4a:	6145                	addi	sp,sp,48
    80001f4c:	8082                	ret
    panic("sched p->lock");
    80001f4e:	00006517          	auipc	a0,0x6
    80001f52:	3ca50513          	addi	a0,a0,970 # 80008318 <userret+0x288>
    80001f56:	ffffe097          	auipc	ra,0xffffe
    80001f5a:	5f8080e7          	jalr	1528(ra) # 8000054e <panic>
    panic("sched locks");
    80001f5e:	00006517          	auipc	a0,0x6
    80001f62:	3ca50513          	addi	a0,a0,970 # 80008328 <userret+0x298>
    80001f66:	ffffe097          	auipc	ra,0xffffe
    80001f6a:	5e8080e7          	jalr	1512(ra) # 8000054e <panic>
    panic("sched running");
    80001f6e:	00006517          	auipc	a0,0x6
    80001f72:	3ca50513          	addi	a0,a0,970 # 80008338 <userret+0x2a8>
    80001f76:	ffffe097          	auipc	ra,0xffffe
    80001f7a:	5d8080e7          	jalr	1496(ra) # 8000054e <panic>
    panic("sched interruptible");
    80001f7e:	00006517          	auipc	a0,0x6
    80001f82:	3ca50513          	addi	a0,a0,970 # 80008348 <userret+0x2b8>
    80001f86:	ffffe097          	auipc	ra,0xffffe
    80001f8a:	5c8080e7          	jalr	1480(ra) # 8000054e <panic>

0000000080001f8e <exit>:
{
    80001f8e:	7179                	addi	sp,sp,-48
    80001f90:	f406                	sd	ra,40(sp)
    80001f92:	f022                	sd	s0,32(sp)
    80001f94:	ec26                	sd	s1,24(sp)
    80001f96:	e84a                	sd	s2,16(sp)
    80001f98:	e44e                	sd	s3,8(sp)
    80001f9a:	e052                	sd	s4,0(sp)
    80001f9c:	1800                	addi	s0,sp,48
    80001f9e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	8fe080e7          	jalr	-1794(ra) # 8000189e <myproc>
    80001fa8:	89aa                	mv	s3,a0
  if(p == initproc)
    80001faa:	00028797          	auipc	a5,0x28
    80001fae:	08e7b783          	ld	a5,142(a5) # 8002a038 <initproc>
    80001fb2:	0d050493          	addi	s1,a0,208
    80001fb6:	15050913          	addi	s2,a0,336
    80001fba:	02a79363          	bne	a5,a0,80001fe0 <exit+0x52>
    panic("init exiting");
    80001fbe:	00006517          	auipc	a0,0x6
    80001fc2:	3a250513          	addi	a0,a0,930 # 80008360 <userret+0x2d0>
    80001fc6:	ffffe097          	auipc	ra,0xffffe
    80001fca:	588080e7          	jalr	1416(ra) # 8000054e <panic>
      fileclose(f);
    80001fce:	00002097          	auipc	ra,0x2
    80001fd2:	5d0080e7          	jalr	1488(ra) # 8000459e <fileclose>
      p->ofile[fd] = 0;
    80001fd6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001fda:	04a1                	addi	s1,s1,8
    80001fdc:	01248563          	beq	s1,s2,80001fe6 <exit+0x58>
    if(p->ofile[fd]){
    80001fe0:	6088                	ld	a0,0(s1)
    80001fe2:	f575                	bnez	a0,80001fce <exit+0x40>
    80001fe4:	bfdd                	j	80001fda <exit+0x4c>
  begin_op(ROOTDEV);
    80001fe6:	4501                	li	a0,0
    80001fe8:	00002097          	auipc	ra,0x2
    80001fec:	f8e080e7          	jalr	-114(ra) # 80003f76 <begin_op>
  iput(p->cwd);
    80001ff0:	1509b503          	ld	a0,336(s3)
    80001ff4:	00001097          	auipc	ra,0x1
    80001ff8:	5e8080e7          	jalr	1512(ra) # 800035dc <iput>
  end_op(ROOTDEV);
    80001ffc:	4501                	li	a0,0
    80001ffe:	00002097          	auipc	ra,0x2
    80002002:	022080e7          	jalr	34(ra) # 80004020 <end_op>
  p->cwd = 0;
    80002006:	1409b823          	sd	zero,336(s3)
  acquire(&p->parent->lock);
    8000200a:	0209b503          	ld	a0,32(s3)
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	9be080e7          	jalr	-1602(ra) # 800009cc <acquire>
  acquire(&p->lock);
    80002016:	854e                	mv	a0,s3
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	9b4080e7          	jalr	-1612(ra) # 800009cc <acquire>
  reparent(p, p->parent);
    80002020:	0209b583          	ld	a1,32(s3)
    80002024:	854e                	mv	a0,s3
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	cf0080e7          	jalr	-784(ra) # 80001d16 <reparent>
  wakeup1(p->parent);
    8000202e:	0209b783          	ld	a5,32(s3)
  if(p->chan == p && p->state == SLEEPING) {
    80002032:	7798                	ld	a4,40(a5)
    80002034:	02e78963          	beq	a5,a4,80002066 <exit+0xd8>
  p->xstate = status;
    80002038:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000203c:	4791                	li	a5,4
    8000203e:	00f9ac23          	sw	a5,24(s3)
  release(&p->parent->lock);
    80002042:	0209b503          	ld	a0,32(s3)
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	9ee080e7          	jalr	-1554(ra) # 80000a34 <release>
  sched();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	e6a080e7          	jalr	-406(ra) # 80001eb8 <sched>
  panic("zombie exit");
    80002056:	00006517          	auipc	a0,0x6
    8000205a:	31a50513          	addi	a0,a0,794 # 80008370 <userret+0x2e0>
    8000205e:	ffffe097          	auipc	ra,0xffffe
    80002062:	4f0080e7          	jalr	1264(ra) # 8000054e <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80002066:	4f94                	lw	a3,24(a5)
    80002068:	4705                	li	a4,1
    8000206a:	fce697e3          	bne	a3,a4,80002038 <exit+0xaa>
    p->state = RUNNABLE;
    8000206e:	4709                	li	a4,2
    80002070:	cf98                	sw	a4,24(a5)
    80002072:	b7d9                	j	80002038 <exit+0xaa>

0000000080002074 <yield>:
{
    80002074:	1101                	addi	sp,sp,-32
    80002076:	ec06                	sd	ra,24(sp)
    80002078:	e822                	sd	s0,16(sp)
    8000207a:	e426                	sd	s1,8(sp)
    8000207c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000207e:	00000097          	auipc	ra,0x0
    80002082:	820080e7          	jalr	-2016(ra) # 8000189e <myproc>
    80002086:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	944080e7          	jalr	-1724(ra) # 800009cc <acquire>
  p->state = RUNNABLE;
    80002090:	4789                	li	a5,2
    80002092:	cc9c                	sw	a5,24(s1)
  sched();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	e24080e7          	jalr	-476(ra) # 80001eb8 <sched>
  release(&p->lock);
    8000209c:	8526                	mv	a0,s1
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	996080e7          	jalr	-1642(ra) # 80000a34 <release>
}
    800020a6:	60e2                	ld	ra,24(sp)
    800020a8:	6442                	ld	s0,16(sp)
    800020aa:	64a2                	ld	s1,8(sp)
    800020ac:	6105                	addi	sp,sp,32
    800020ae:	8082                	ret

00000000800020b0 <sleep>:
{
    800020b0:	7179                	addi	sp,sp,-48
    800020b2:	f406                	sd	ra,40(sp)
    800020b4:	f022                	sd	s0,32(sp)
    800020b6:	ec26                	sd	s1,24(sp)
    800020b8:	e84a                	sd	s2,16(sp)
    800020ba:	e44e                	sd	s3,8(sp)
    800020bc:	1800                	addi	s0,sp,48
    800020be:	89aa                	mv	s3,a0
    800020c0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	7dc080e7          	jalr	2012(ra) # 8000189e <myproc>
    800020ca:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800020cc:	05250663          	beq	a0,s2,80002118 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	8fc080e7          	jalr	-1796(ra) # 800009cc <acquire>
    release(lk);
    800020d8:	854a                	mv	a0,s2
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	95a080e7          	jalr	-1702(ra) # 80000a34 <release>
  p->chan = chan;
    800020e2:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800020e6:	4785                	li	a5,1
    800020e8:	cc9c                	sw	a5,24(s1)
  sched();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	dce080e7          	jalr	-562(ra) # 80001eb8 <sched>
  p->chan = 0;
    800020f2:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	93c080e7          	jalr	-1732(ra) # 80000a34 <release>
    acquire(lk);
    80002100:	854a                	mv	a0,s2
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	8ca080e7          	jalr	-1846(ra) # 800009cc <acquire>
}
    8000210a:	70a2                	ld	ra,40(sp)
    8000210c:	7402                	ld	s0,32(sp)
    8000210e:	64e2                	ld	s1,24(sp)
    80002110:	6942                	ld	s2,16(sp)
    80002112:	69a2                	ld	s3,8(sp)
    80002114:	6145                	addi	sp,sp,48
    80002116:	8082                	ret
  p->chan = chan;
    80002118:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000211c:	4785                	li	a5,1
    8000211e:	cd1c                	sw	a5,24(a0)
  sched();
    80002120:	00000097          	auipc	ra,0x0
    80002124:	d98080e7          	jalr	-616(ra) # 80001eb8 <sched>
  p->chan = 0;
    80002128:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000212c:	bff9                	j	8000210a <sleep+0x5a>

000000008000212e <wait>:
{
    8000212e:	715d                	addi	sp,sp,-80
    80002130:	e486                	sd	ra,72(sp)
    80002132:	e0a2                	sd	s0,64(sp)
    80002134:	fc26                	sd	s1,56(sp)
    80002136:	f84a                	sd	s2,48(sp)
    80002138:	f44e                	sd	s3,40(sp)
    8000213a:	f052                	sd	s4,32(sp)
    8000213c:	ec56                	sd	s5,24(sp)
    8000213e:	e85a                	sd	s6,16(sp)
    80002140:	e45e                	sd	s7,8(sp)
    80002142:	e062                	sd	s8,0(sp)
    80002144:	0880                	addi	s0,sp,80
    80002146:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	756080e7          	jalr	1878(ra) # 8000189e <myproc>
    80002150:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002152:	8c2a                	mv	s8,a0
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	878080e7          	jalr	-1928(ra) # 800009cc <acquire>
    havekids = 0;
    8000215c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000215e:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002160:	00016997          	auipc	s3,0x16
    80002164:	58098993          	addi	s3,s3,1408 # 800186e0 <tickslock>
        havekids = 1;
    80002168:	4a85                	li	s5,1
    havekids = 0;
    8000216a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000216c:	00011497          	auipc	s1,0x11
    80002170:	b7448493          	addi	s1,s1,-1164 # 80012ce0 <proc>
    80002174:	a08d                	j	800021d6 <wait+0xa8>
          pid = np->pid;
    80002176:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000217a:	000b0e63          	beqz	s6,80002196 <wait+0x68>
    8000217e:	4691                	li	a3,4
    80002180:	03448613          	addi	a2,s1,52
    80002184:	85da                	mv	a1,s6
    80002186:	05093503          	ld	a0,80(s2)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	2ca080e7          	jalr	714(ra) # 80001454 <copyout>
    80002192:	02054263          	bltz	a0,800021b6 <wait+0x88>
          freeproc(np);
    80002196:	8526                	mv	a0,s1
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	922080e7          	jalr	-1758(ra) # 80001aba <freeproc>
          release(&np->lock);
    800021a0:	8526                	mv	a0,s1
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	892080e7          	jalr	-1902(ra) # 80000a34 <release>
          release(&p->lock);
    800021aa:	854a                	mv	a0,s2
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	888080e7          	jalr	-1912(ra) # 80000a34 <release>
          return pid;
    800021b4:	a8a9                	j	8000220e <wait+0xe0>
            release(&np->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	87c080e7          	jalr	-1924(ra) # 80000a34 <release>
            release(&p->lock);
    800021c0:	854a                	mv	a0,s2
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	872080e7          	jalr	-1934(ra) # 80000a34 <release>
            return -1;
    800021ca:	59fd                	li	s3,-1
    800021cc:	a089                	j	8000220e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800021ce:	16848493          	addi	s1,s1,360
    800021d2:	03348463          	beq	s1,s3,800021fa <wait+0xcc>
      if(np->parent == p){
    800021d6:	709c                	ld	a5,32(s1)
    800021d8:	ff279be3          	bne	a5,s2,800021ce <wait+0xa0>
        acquire(&np->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	ffffe097          	auipc	ra,0xffffe
    800021e2:	7ee080e7          	jalr	2030(ra) # 800009cc <acquire>
        if(np->state == ZOMBIE){
    800021e6:	4c9c                	lw	a5,24(s1)
    800021e8:	f94787e3          	beq	a5,s4,80002176 <wait+0x48>
        release(&np->lock);
    800021ec:	8526                	mv	a0,s1
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	846080e7          	jalr	-1978(ra) # 80000a34 <release>
        havekids = 1;
    800021f6:	8756                	mv	a4,s5
    800021f8:	bfd9                	j	800021ce <wait+0xa0>
    if(!havekids || p->killed){
    800021fa:	c701                	beqz	a4,80002202 <wait+0xd4>
    800021fc:	03092783          	lw	a5,48(s2)
    80002200:	c785                	beqz	a5,80002228 <wait+0xfa>
      release(&p->lock);
    80002202:	854a                	mv	a0,s2
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	830080e7          	jalr	-2000(ra) # 80000a34 <release>
      return -1;
    8000220c:	59fd                	li	s3,-1
}
    8000220e:	854e                	mv	a0,s3
    80002210:	60a6                	ld	ra,72(sp)
    80002212:	6406                	ld	s0,64(sp)
    80002214:	74e2                	ld	s1,56(sp)
    80002216:	7942                	ld	s2,48(sp)
    80002218:	79a2                	ld	s3,40(sp)
    8000221a:	7a02                	ld	s4,32(sp)
    8000221c:	6ae2                	ld	s5,24(sp)
    8000221e:	6b42                	ld	s6,16(sp)
    80002220:	6ba2                	ld	s7,8(sp)
    80002222:	6c02                	ld	s8,0(sp)
    80002224:	6161                	addi	sp,sp,80
    80002226:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002228:	85e2                	mv	a1,s8
    8000222a:	854a                	mv	a0,s2
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	e84080e7          	jalr	-380(ra) # 800020b0 <sleep>
    havekids = 0;
    80002234:	bf1d                	j	8000216a <wait+0x3c>

0000000080002236 <wakeup>:
{
    80002236:	7139                	addi	sp,sp,-64
    80002238:	fc06                	sd	ra,56(sp)
    8000223a:	f822                	sd	s0,48(sp)
    8000223c:	f426                	sd	s1,40(sp)
    8000223e:	f04a                	sd	s2,32(sp)
    80002240:	ec4e                	sd	s3,24(sp)
    80002242:	e852                	sd	s4,16(sp)
    80002244:	e456                	sd	s5,8(sp)
    80002246:	0080                	addi	s0,sp,64
    80002248:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000224a:	00011497          	auipc	s1,0x11
    8000224e:	a9648493          	addi	s1,s1,-1386 # 80012ce0 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002252:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002254:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002256:	00016917          	auipc	s2,0x16
    8000225a:	48a90913          	addi	s2,s2,1162 # 800186e0 <tickslock>
    8000225e:	a821                	j	80002276 <wakeup+0x40>
      p->state = RUNNABLE;
    80002260:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	7ce080e7          	jalr	1998(ra) # 80000a34 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000226e:	16848493          	addi	s1,s1,360
    80002272:	01248e63          	beq	s1,s2,8000228e <wakeup+0x58>
    acquire(&p->lock);
    80002276:	8526                	mv	a0,s1
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	754080e7          	jalr	1876(ra) # 800009cc <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002280:	4c9c                	lw	a5,24(s1)
    80002282:	ff3791e3          	bne	a5,s3,80002264 <wakeup+0x2e>
    80002286:	749c                	ld	a5,40(s1)
    80002288:	fd479ee3          	bne	a5,s4,80002264 <wakeup+0x2e>
    8000228c:	bfd1                	j	80002260 <wakeup+0x2a>
}
    8000228e:	70e2                	ld	ra,56(sp)
    80002290:	7442                	ld	s0,48(sp)
    80002292:	74a2                	ld	s1,40(sp)
    80002294:	7902                	ld	s2,32(sp)
    80002296:	69e2                	ld	s3,24(sp)
    80002298:	6a42                	ld	s4,16(sp)
    8000229a:	6aa2                	ld	s5,8(sp)
    8000229c:	6121                	addi	sp,sp,64
    8000229e:	8082                	ret

00000000800022a0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022a0:	7179                	addi	sp,sp,-48
    800022a2:	f406                	sd	ra,40(sp)
    800022a4:	f022                	sd	s0,32(sp)
    800022a6:	ec26                	sd	s1,24(sp)
    800022a8:	e84a                	sd	s2,16(sp)
    800022aa:	e44e                	sd	s3,8(sp)
    800022ac:	1800                	addi	s0,sp,48
    800022ae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022b0:	00011497          	auipc	s1,0x11
    800022b4:	a3048493          	addi	s1,s1,-1488 # 80012ce0 <proc>
    800022b8:	00016997          	auipc	s3,0x16
    800022bc:	42898993          	addi	s3,s3,1064 # 800186e0 <tickslock>
    acquire(&p->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	ffffe097          	auipc	ra,0xffffe
    800022c6:	70a080e7          	jalr	1802(ra) # 800009cc <acquire>
    if(p->pid == pid){
    800022ca:	5c9c                	lw	a5,56(s1)
    800022cc:	01278d63          	beq	a5,s2,800022e6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	ffffe097          	auipc	ra,0xffffe
    800022d6:	762080e7          	jalr	1890(ra) # 80000a34 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022da:	16848493          	addi	s1,s1,360
    800022de:	ff3491e3          	bne	s1,s3,800022c0 <kill+0x20>
  }
  return -1;
    800022e2:	557d                	li	a0,-1
    800022e4:	a821                	j	800022fc <kill+0x5c>
      p->killed = 1;
    800022e6:	4785                	li	a5,1
    800022e8:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800022ea:	4c98                	lw	a4,24(s1)
    800022ec:	00f70f63          	beq	a4,a5,8000230a <kill+0x6a>
      release(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	742080e7          	jalr	1858(ra) # 80000a34 <release>
      return 0;
    800022fa:	4501                	li	a0,0
}
    800022fc:	70a2                	ld	ra,40(sp)
    800022fe:	7402                	ld	s0,32(sp)
    80002300:	64e2                	ld	s1,24(sp)
    80002302:	6942                	ld	s2,16(sp)
    80002304:	69a2                	ld	s3,8(sp)
    80002306:	6145                	addi	sp,sp,48
    80002308:	8082                	ret
        p->state = RUNNABLE;
    8000230a:	4789                	li	a5,2
    8000230c:	cc9c                	sw	a5,24(s1)
    8000230e:	b7cd                	j	800022f0 <kill+0x50>

0000000080002310 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	e052                	sd	s4,0(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	84aa                	mv	s1,a0
    80002322:	892e                	mv	s2,a1
    80002324:	89b2                	mv	s3,a2
    80002326:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	576080e7          	jalr	1398(ra) # 8000189e <myproc>
  if(user_dst){
    80002330:	c08d                	beqz	s1,80002352 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002332:	86d2                	mv	a3,s4
    80002334:	864e                	mv	a2,s3
    80002336:	85ca                	mv	a1,s2
    80002338:	6928                	ld	a0,80(a0)
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	11a080e7          	jalr	282(ra) # 80001454 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002342:	70a2                	ld	ra,40(sp)
    80002344:	7402                	ld	s0,32(sp)
    80002346:	64e2                	ld	s1,24(sp)
    80002348:	6942                	ld	s2,16(sp)
    8000234a:	69a2                	ld	s3,8(sp)
    8000234c:	6a02                	ld	s4,0(sp)
    8000234e:	6145                	addi	sp,sp,48
    80002350:	8082                	ret
    memmove((char *)dst, src, len);
    80002352:	000a061b          	sext.w	a2,s4
    80002356:	85ce                	mv	a1,s3
    80002358:	854a                	mv	a0,s2
    8000235a:	ffffe097          	auipc	ra,0xffffe
    8000235e:	796080e7          	jalr	1942(ra) # 80000af0 <memmove>
    return 0;
    80002362:	8526                	mv	a0,s1
    80002364:	bff9                	j	80002342 <either_copyout+0x32>

0000000080002366 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002366:	7179                	addi	sp,sp,-48
    80002368:	f406                	sd	ra,40(sp)
    8000236a:	f022                	sd	s0,32(sp)
    8000236c:	ec26                	sd	s1,24(sp)
    8000236e:	e84a                	sd	s2,16(sp)
    80002370:	e44e                	sd	s3,8(sp)
    80002372:	e052                	sd	s4,0(sp)
    80002374:	1800                	addi	s0,sp,48
    80002376:	892a                	mv	s2,a0
    80002378:	84ae                	mv	s1,a1
    8000237a:	89b2                	mv	s3,a2
    8000237c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	520080e7          	jalr	1312(ra) # 8000189e <myproc>
  if(user_src){
    80002386:	c08d                	beqz	s1,800023a8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002388:	86d2                	mv	a3,s4
    8000238a:	864e                	mv	a2,s3
    8000238c:	85ca                	mv	a1,s2
    8000238e:	6928                	ld	a0,80(a0)
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	156080e7          	jalr	342(ra) # 800014e6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002398:	70a2                	ld	ra,40(sp)
    8000239a:	7402                	ld	s0,32(sp)
    8000239c:	64e2                	ld	s1,24(sp)
    8000239e:	6942                	ld	s2,16(sp)
    800023a0:	69a2                	ld	s3,8(sp)
    800023a2:	6a02                	ld	s4,0(sp)
    800023a4:	6145                	addi	sp,sp,48
    800023a6:	8082                	ret
    memmove(dst, (char*)src, len);
    800023a8:	000a061b          	sext.w	a2,s4
    800023ac:	85ce                	mv	a1,s3
    800023ae:	854a                	mv	a0,s2
    800023b0:	ffffe097          	auipc	ra,0xffffe
    800023b4:	740080e7          	jalr	1856(ra) # 80000af0 <memmove>
    return 0;
    800023b8:	8526                	mv	a0,s1
    800023ba:	bff9                	j	80002398 <either_copyin+0x32>

00000000800023bc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800023bc:	715d                	addi	sp,sp,-80
    800023be:	e486                	sd	ra,72(sp)
    800023c0:	e0a2                	sd	s0,64(sp)
    800023c2:	fc26                	sd	s1,56(sp)
    800023c4:	f84a                	sd	s2,48(sp)
    800023c6:	f44e                	sd	s3,40(sp)
    800023c8:	f052                	sd	s4,32(sp)
    800023ca:	ec56                	sd	s5,24(sp)
    800023cc:	e85a                	sd	s6,16(sp)
    800023ce:	e45e                	sd	s7,8(sp)
    800023d0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800023d2:	00006517          	auipc	a0,0x6
    800023d6:	dce50513          	addi	a0,a0,-562 # 800081a0 <userret+0x110>
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	1be080e7          	jalr	446(ra) # 80000598 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800023e2:	00011497          	auipc	s1,0x11
    800023e6:	a5648493          	addi	s1,s1,-1450 # 80012e38 <proc+0x158>
    800023ea:	00016917          	auipc	s2,0x16
    800023ee:	44e90913          	addi	s2,s2,1102 # 80018838 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023f2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800023f4:	00006997          	auipc	s3,0x6
    800023f8:	f8c98993          	addi	s3,s3,-116 # 80008380 <userret+0x2f0>
    printf("%d %s %s", p->pid, state, p->name);
    800023fc:	00006a97          	auipc	s5,0x6
    80002400:	f8ca8a93          	addi	s5,s5,-116 # 80008388 <userret+0x2f8>
    printf("\n");
    80002404:	00006a17          	auipc	s4,0x6
    80002408:	d9ca0a13          	addi	s4,s4,-612 # 800081a0 <userret+0x110>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000240c:	00006b97          	auipc	s7,0x6
    80002410:	614b8b93          	addi	s7,s7,1556 # 80008a20 <states.1783>
    80002414:	a00d                	j	80002436 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002416:	ee06a583          	lw	a1,-288(a3)
    8000241a:	8556                	mv	a0,s5
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	17c080e7          	jalr	380(ra) # 80000598 <printf>
    printf("\n");
    80002424:	8552                	mv	a0,s4
    80002426:	ffffe097          	auipc	ra,0xffffe
    8000242a:	172080e7          	jalr	370(ra) # 80000598 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000242e:	16848493          	addi	s1,s1,360
    80002432:	03248163          	beq	s1,s2,80002454 <procdump+0x98>
    if(p->state == UNUSED)
    80002436:	86a6                	mv	a3,s1
    80002438:	ec04a783          	lw	a5,-320(s1)
    8000243c:	dbed                	beqz	a5,8000242e <procdump+0x72>
      state = "???";
    8000243e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002440:	fcfb6be3          	bltu	s6,a5,80002416 <procdump+0x5a>
    80002444:	1782                	slli	a5,a5,0x20
    80002446:	9381                	srli	a5,a5,0x20
    80002448:	078e                	slli	a5,a5,0x3
    8000244a:	97de                	add	a5,a5,s7
    8000244c:	6390                	ld	a2,0(a5)
    8000244e:	f661                	bnez	a2,80002416 <procdump+0x5a>
      state = "???";
    80002450:	864e                	mv	a2,s3
    80002452:	b7d1                	j	80002416 <procdump+0x5a>
  }
}
    80002454:	60a6                	ld	ra,72(sp)
    80002456:	6406                	ld	s0,64(sp)
    80002458:	74e2                	ld	s1,56(sp)
    8000245a:	7942                	ld	s2,48(sp)
    8000245c:	79a2                	ld	s3,40(sp)
    8000245e:	7a02                	ld	s4,32(sp)
    80002460:	6ae2                	ld	s5,24(sp)
    80002462:	6b42                	ld	s6,16(sp)
    80002464:	6ba2                	ld	s7,8(sp)
    80002466:	6161                	addi	sp,sp,80
    80002468:	8082                	ret

000000008000246a <swtch>:
    8000246a:	00153023          	sd	ra,0(a0)
    8000246e:	00253423          	sd	sp,8(a0)
    80002472:	e900                	sd	s0,16(a0)
    80002474:	ed04                	sd	s1,24(a0)
    80002476:	03253023          	sd	s2,32(a0)
    8000247a:	03353423          	sd	s3,40(a0)
    8000247e:	03453823          	sd	s4,48(a0)
    80002482:	03553c23          	sd	s5,56(a0)
    80002486:	05653023          	sd	s6,64(a0)
    8000248a:	05753423          	sd	s7,72(a0)
    8000248e:	05853823          	sd	s8,80(a0)
    80002492:	05953c23          	sd	s9,88(a0)
    80002496:	07a53023          	sd	s10,96(a0)
    8000249a:	07b53423          	sd	s11,104(a0)
    8000249e:	0005b083          	ld	ra,0(a1)
    800024a2:	0085b103          	ld	sp,8(a1)
    800024a6:	6980                	ld	s0,16(a1)
    800024a8:	6d84                	ld	s1,24(a1)
    800024aa:	0205b903          	ld	s2,32(a1)
    800024ae:	0285b983          	ld	s3,40(a1)
    800024b2:	0305ba03          	ld	s4,48(a1)
    800024b6:	0385ba83          	ld	s5,56(a1)
    800024ba:	0405bb03          	ld	s6,64(a1)
    800024be:	0485bb83          	ld	s7,72(a1)
    800024c2:	0505bc03          	ld	s8,80(a1)
    800024c6:	0585bc83          	ld	s9,88(a1)
    800024ca:	0605bd03          	ld	s10,96(a1)
    800024ce:	0685bd83          	ld	s11,104(a1)
    800024d2:	8082                	ret

00000000800024d4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800024d4:	1141                	addi	sp,sp,-16
    800024d6:	e406                	sd	ra,8(sp)
    800024d8:	e022                	sd	s0,0(sp)
    800024da:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800024dc:	00006597          	auipc	a1,0x6
    800024e0:	ee458593          	addi	a1,a1,-284 # 800083c0 <userret+0x330>
    800024e4:	00016517          	auipc	a0,0x16
    800024e8:	1fc50513          	addi	a0,a0,508 # 800186e0 <tickslock>
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	3ce080e7          	jalr	974(ra) # 800008ba <initlock>
}
    800024f4:	60a2                	ld	ra,8(sp)
    800024f6:	6402                	ld	s0,0(sp)
    800024f8:	0141                	addi	sp,sp,16
    800024fa:	8082                	ret

00000000800024fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800024fc:	1141                	addi	sp,sp,-16
    800024fe:	e422                	sd	s0,8(sp)
    80002500:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002502:	00003797          	auipc	a5,0x3
    80002506:	73e78793          	addi	a5,a5,1854 # 80005c40 <kernelvec>
    8000250a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000250e:	6422                	ld	s0,8(sp)
    80002510:	0141                	addi	sp,sp,16
    80002512:	8082                	ret

0000000080002514 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002514:	1141                	addi	sp,sp,-16
    80002516:	e406                	sd	ra,8(sp)
    80002518:	e022                	sd	s0,0(sp)
    8000251a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	382080e7          	jalr	898(ra) # 8000189e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002524:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002528:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000252a:	10079073          	csrw	sstatus,a5
  // turn off interrupts, since we're switching
  // now from kerneltrap() to usertrap().
  intr_off();

  // send interrupts and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000252e:	00006617          	auipc	a2,0x6
    80002532:	ad260613          	addi	a2,a2,-1326 # 80008000 <trampoline>
    80002536:	00006697          	auipc	a3,0x6
    8000253a:	aca68693          	addi	a3,a3,-1334 # 80008000 <trampoline>
    8000253e:	8e91                	sub	a3,a3,a2
    80002540:	040007b7          	lui	a5,0x4000
    80002544:	17fd                	addi	a5,a5,-1
    80002546:	07b2                	slli	a5,a5,0xc
    80002548:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000254a:	10569073          	csrw	stvec,a3

  // set up values that uservec will need when
  // the process next re-enters the kernel.
  p->tf->kernel_satp = r_satp();         // kernel page table
    8000254e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002550:	180026f3          	csrr	a3,satp
    80002554:	e314                	sd	a3,0(a4)
  p->tf->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002556:	6d38                	ld	a4,88(a0)
    80002558:	6134                	ld	a3,64(a0)
    8000255a:	6585                	lui	a1,0x1
    8000255c:	96ae                	add	a3,a3,a1
    8000255e:	e714                	sd	a3,8(a4)
  p->tf->kernel_trap = (uint64)usertrap;
    80002560:	6d38                	ld	a4,88(a0)
    80002562:	00000697          	auipc	a3,0x0
    80002566:	12868693          	addi	a3,a3,296 # 8000268a <usertrap>
    8000256a:	eb14                	sd	a3,16(a4)
  p->tf->kernel_hartid = r_tp();         // hartid for cpuid()
    8000256c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000256e:	8692                	mv	a3,tp
    80002570:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002572:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002576:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000257a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000257e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->tf->epc);
    80002582:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002584:	6f18                	ld	a4,24(a4)
    80002586:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000258a:	692c                	ld	a1,80(a0)
    8000258c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000258e:	00006717          	auipc	a4,0x6
    80002592:	b0270713          	addi	a4,a4,-1278 # 80008090 <userret>
    80002596:	8f11                	sub	a4,a4,a2
    80002598:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000259a:	577d                	li	a4,-1
    8000259c:	177e                	slli	a4,a4,0x3f
    8000259e:	8dd9                	or	a1,a1,a4
    800025a0:	02000537          	lui	a0,0x2000
    800025a4:	157d                	addi	a0,a0,-1
    800025a6:	0536                	slli	a0,a0,0xd
    800025a8:	9782                	jalr	a5
}
    800025aa:	60a2                	ld	ra,8(sp)
    800025ac:	6402                	ld	s0,0(sp)
    800025ae:	0141                	addi	sp,sp,16
    800025b0:	8082                	ret

00000000800025b2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800025b2:	1101                	addi	sp,sp,-32
    800025b4:	ec06                	sd	ra,24(sp)
    800025b6:	e822                	sd	s0,16(sp)
    800025b8:	e426                	sd	s1,8(sp)
    800025ba:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800025bc:	00016497          	auipc	s1,0x16
    800025c0:	12448493          	addi	s1,s1,292 # 800186e0 <tickslock>
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	406080e7          	jalr	1030(ra) # 800009cc <acquire>
  ticks++;
    800025ce:	00028517          	auipc	a0,0x28
    800025d2:	a7250513          	addi	a0,a0,-1422 # 8002a040 <ticks>
    800025d6:	411c                	lw	a5,0(a0)
    800025d8:	2785                	addiw	a5,a5,1
    800025da:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800025dc:	00000097          	auipc	ra,0x0
    800025e0:	c5a080e7          	jalr	-934(ra) # 80002236 <wakeup>
  release(&tickslock);
    800025e4:	8526                	mv	a0,s1
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	44e080e7          	jalr	1102(ra) # 80000a34 <release>
}
    800025ee:	60e2                	ld	ra,24(sp)
    800025f0:	6442                	ld	s0,16(sp)
    800025f2:	64a2                	ld	s1,8(sp)
    800025f4:	6105                	addi	sp,sp,32
    800025f6:	8082                	ret

00000000800025f8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800025f8:	1101                	addi	sp,sp,-32
    800025fa:	ec06                	sd	ra,24(sp)
    800025fc:	e822                	sd	s0,16(sp)
    800025fe:	e426                	sd	s1,8(sp)
    80002600:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002602:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002606:	00074d63          	bltz	a4,80002620 <devintr+0x28>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    }

    plic_complete(irq);
    return 1;
  } else if(scause == 0x8000000000000001L){
    8000260a:	57fd                	li	a5,-1
    8000260c:	17fe                	slli	a5,a5,0x3f
    8000260e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002610:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002612:	04f70b63          	beq	a4,a5,80002668 <devintr+0x70>
  }
}
    80002616:	60e2                	ld	ra,24(sp)
    80002618:	6442                	ld	s0,16(sp)
    8000261a:	64a2                	ld	s1,8(sp)
    8000261c:	6105                	addi	sp,sp,32
    8000261e:	8082                	ret
     (scause & 0xff) == 9){
    80002620:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002624:	46a5                	li	a3,9
    80002626:	fed792e3          	bne	a5,a3,8000260a <devintr+0x12>
    int irq = plic_claim();
    8000262a:	00003097          	auipc	ra,0x3
    8000262e:	730080e7          	jalr	1840(ra) # 80005d5a <plic_claim>
    80002632:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002634:	47a9                	li	a5,10
    80002636:	00f50e63          	beq	a0,a5,80002652 <devintr+0x5a>
    } else if(irq == VIRTIO0_IRQ || irq == VIRTIO1_IRQ ){
    8000263a:	fff5079b          	addiw	a5,a0,-1
    8000263e:	4705                	li	a4,1
    80002640:	00f77e63          	bgeu	a4,a5,8000265c <devintr+0x64>
    plic_complete(irq);
    80002644:	8526                	mv	a0,s1
    80002646:	00003097          	auipc	ra,0x3
    8000264a:	738080e7          	jalr	1848(ra) # 80005d7e <plic_complete>
    return 1;
    8000264e:	4505                	li	a0,1
    80002650:	b7d9                	j	80002616 <devintr+0x1e>
      uartintr();
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	1e2080e7          	jalr	482(ra) # 80000834 <uartintr>
    8000265a:	b7ed                	j	80002644 <devintr+0x4c>
      virtio_disk_intr(irq - VIRTIO0_IRQ);
    8000265c:	853e                	mv	a0,a5
    8000265e:	00004097          	auipc	ra,0x4
    80002662:	cf0080e7          	jalr	-784(ra) # 8000634e <virtio_disk_intr>
    80002666:	bff9                	j	80002644 <devintr+0x4c>
    if(cpuid() == 0){
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	20a080e7          	jalr	522(ra) # 80001872 <cpuid>
    80002670:	c901                	beqz	a0,80002680 <devintr+0x88>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002672:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002676:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002678:	14479073          	csrw	sip,a5
    return 2;
    8000267c:	4509                	li	a0,2
    8000267e:	bf61                	j	80002616 <devintr+0x1e>
      clockintr();
    80002680:	00000097          	auipc	ra,0x0
    80002684:	f32080e7          	jalr	-206(ra) # 800025b2 <clockintr>
    80002688:	b7ed                	j	80002672 <devintr+0x7a>

000000008000268a <usertrap>:
{
    8000268a:	1101                	addi	sp,sp,-32
    8000268c:	ec06                	sd	ra,24(sp)
    8000268e:	e822                	sd	s0,16(sp)
    80002690:	e426                	sd	s1,8(sp)
    80002692:	e04a                	sd	s2,0(sp)
    80002694:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002696:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000269a:	1007f793          	andi	a5,a5,256
    8000269e:	e7bd                	bnez	a5,8000270c <usertrap+0x82>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a0:	00003797          	auipc	a5,0x3
    800026a4:	5a078793          	addi	a5,a5,1440 # 80005c40 <kernelvec>
    800026a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800026ac:	fffff097          	auipc	ra,0xfffff
    800026b0:	1f2080e7          	jalr	498(ra) # 8000189e <myproc>
    800026b4:	84aa                	mv	s1,a0
  p->tf->epc = r_sepc();
    800026b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026b8:	14102773          	csrr	a4,sepc
    800026bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800026c2:	47a1                	li	a5,8
    800026c4:	06f71263          	bne	a4,a5,80002728 <usertrap+0x9e>
    if(p->killed)
    800026c8:	591c                	lw	a5,48(a0)
    800026ca:	eba9                	bnez	a5,8000271c <usertrap+0x92>
    p->tf->epc += 4;
    800026cc:	6cb8                	ld	a4,88(s1)
    800026ce:	6f1c                	ld	a5,24(a4)
    800026d0:	0791                	addi	a5,a5,4
    800026d2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sie" : "=r" (x) );
    800026d4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800026d8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800026dc:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800026e4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e8:	10079073          	csrw	sstatus,a5
    syscall();
    800026ec:	00000097          	auipc	ra,0x0
    800026f0:	2e0080e7          	jalr	736(ra) # 800029cc <syscall>
  if(p->killed)
    800026f4:	589c                	lw	a5,48(s1)
    800026f6:	ebc1                	bnez	a5,80002786 <usertrap+0xfc>
  usertrapret();
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	e1c080e7          	jalr	-484(ra) # 80002514 <usertrapret>
}
    80002700:	60e2                	ld	ra,24(sp)
    80002702:	6442                	ld	s0,16(sp)
    80002704:	64a2                	ld	s1,8(sp)
    80002706:	6902                	ld	s2,0(sp)
    80002708:	6105                	addi	sp,sp,32
    8000270a:	8082                	ret
    panic("usertrap: not from user mode");
    8000270c:	00006517          	auipc	a0,0x6
    80002710:	cbc50513          	addi	a0,a0,-836 # 800083c8 <userret+0x338>
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	e3a080e7          	jalr	-454(ra) # 8000054e <panic>
      exit(-1);
    8000271c:	557d                	li	a0,-1
    8000271e:	00000097          	auipc	ra,0x0
    80002722:	870080e7          	jalr	-1936(ra) # 80001f8e <exit>
    80002726:	b75d                	j	800026cc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002728:	00000097          	auipc	ra,0x0
    8000272c:	ed0080e7          	jalr	-304(ra) # 800025f8 <devintr>
    80002730:	892a                	mv	s2,a0
    80002732:	c501                	beqz	a0,8000273a <usertrap+0xb0>
  if(p->killed)
    80002734:	589c                	lw	a5,48(s1)
    80002736:	c3a1                	beqz	a5,80002776 <usertrap+0xec>
    80002738:	a815                	j	8000276c <usertrap+0xe2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000273a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000273e:	5c90                	lw	a2,56(s1)
    80002740:	00006517          	auipc	a0,0x6
    80002744:	ca850513          	addi	a0,a0,-856 # 800083e8 <userret+0x358>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	e50080e7          	jalr	-432(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002750:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002754:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002758:	00006517          	auipc	a0,0x6
    8000275c:	cc050513          	addi	a0,a0,-832 # 80008418 <userret+0x388>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	e38080e7          	jalr	-456(ra) # 80000598 <printf>
    p->killed = 1;
    80002768:	4785                	li	a5,1
    8000276a:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000276c:	557d                	li	a0,-1
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	820080e7          	jalr	-2016(ra) # 80001f8e <exit>
  if(which_dev == 2)
    80002776:	4789                	li	a5,2
    80002778:	f8f910e3          	bne	s2,a5,800026f8 <usertrap+0x6e>
    yield();
    8000277c:	00000097          	auipc	ra,0x0
    80002780:	8f8080e7          	jalr	-1800(ra) # 80002074 <yield>
    80002784:	bf95                	j	800026f8 <usertrap+0x6e>
  int which_dev = 0;
    80002786:	4901                	li	s2,0
    80002788:	b7d5                	j	8000276c <usertrap+0xe2>

000000008000278a <kerneltrap>:
{
    8000278a:	7179                	addi	sp,sp,-48
    8000278c:	f406                	sd	ra,40(sp)
    8000278e:	f022                	sd	s0,32(sp)
    80002790:	ec26                	sd	s1,24(sp)
    80002792:	e84a                	sd	s2,16(sp)
    80002794:	e44e                	sd	s3,8(sp)
    80002796:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002798:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000279c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800027a4:	1004f793          	andi	a5,s1,256
    800027a8:	cb85                	beqz	a5,800027d8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027aa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800027ae:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800027b0:	ef85                	bnez	a5,800027e8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800027b2:	00000097          	auipc	ra,0x0
    800027b6:	e46080e7          	jalr	-442(ra) # 800025f8 <devintr>
    800027ba:	cd1d                	beqz	a0,800027f8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800027bc:	4789                	li	a5,2
    800027be:	06f50a63          	beq	a0,a5,80002832 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027c2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027c6:	10049073          	csrw	sstatus,s1
}
    800027ca:	70a2                	ld	ra,40(sp)
    800027cc:	7402                	ld	s0,32(sp)
    800027ce:	64e2                	ld	s1,24(sp)
    800027d0:	6942                	ld	s2,16(sp)
    800027d2:	69a2                	ld	s3,8(sp)
    800027d4:	6145                	addi	sp,sp,48
    800027d6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800027d8:	00006517          	auipc	a0,0x6
    800027dc:	c6050513          	addi	a0,a0,-928 # 80008438 <userret+0x3a8>
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	d6e080e7          	jalr	-658(ra) # 8000054e <panic>
    panic("kerneltrap: interrupts enabled");
    800027e8:	00006517          	auipc	a0,0x6
    800027ec:	c7850513          	addi	a0,a0,-904 # 80008460 <userret+0x3d0>
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	d5e080e7          	jalr	-674(ra) # 8000054e <panic>
    printf("scause %p\n", scause);
    800027f8:	85ce                	mv	a1,s3
    800027fa:	00006517          	auipc	a0,0x6
    800027fe:	c8650513          	addi	a0,a0,-890 # 80008480 <userret+0x3f0>
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	d96080e7          	jalr	-618(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000280e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002812:	00006517          	auipc	a0,0x6
    80002816:	c7e50513          	addi	a0,a0,-898 # 80008490 <userret+0x400>
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	d7e080e7          	jalr	-642(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002822:	00006517          	auipc	a0,0x6
    80002826:	c8650513          	addi	a0,a0,-890 # 800084a8 <userret+0x418>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d24080e7          	jalr	-732(ra) # 8000054e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	06c080e7          	jalr	108(ra) # 8000189e <myproc>
    8000283a:	d541                	beqz	a0,800027c2 <kerneltrap+0x38>
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	062080e7          	jalr	98(ra) # 8000189e <myproc>
    80002844:	4d18                	lw	a4,24(a0)
    80002846:	478d                	li	a5,3
    80002848:	f6f71de3          	bne	a4,a5,800027c2 <kerneltrap+0x38>
    yield();
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	828080e7          	jalr	-2008(ra) # 80002074 <yield>
    80002854:	b7bd                	j	800027c2 <kerneltrap+0x38>

0000000080002856 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002856:	1101                	addi	sp,sp,-32
    80002858:	ec06                	sd	ra,24(sp)
    8000285a:	e822                	sd	s0,16(sp)
    8000285c:	e426                	sd	s1,8(sp)
    8000285e:	1000                	addi	s0,sp,32
    80002860:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	03c080e7          	jalr	60(ra) # 8000189e <myproc>
  switch (n) {
    8000286a:	4795                	li	a5,5
    8000286c:	0497e163          	bltu	a5,s1,800028ae <argraw+0x58>
    80002870:	048a                	slli	s1,s1,0x2
    80002872:	00006717          	auipc	a4,0x6
    80002876:	1d670713          	addi	a4,a4,470 # 80008a48 <states.1783+0x28>
    8000287a:	94ba                	add	s1,s1,a4
    8000287c:	409c                	lw	a5,0(s1)
    8000287e:	97ba                	add	a5,a5,a4
    80002880:	8782                	jr	a5
  case 0:
    return p->tf->a0;
    80002882:	6d3c                	ld	a5,88(a0)
    80002884:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->tf->a5;
  }
  panic("argraw");
  return -1;
}
    80002886:	60e2                	ld	ra,24(sp)
    80002888:	6442                	ld	s0,16(sp)
    8000288a:	64a2                	ld	s1,8(sp)
    8000288c:	6105                	addi	sp,sp,32
    8000288e:	8082                	ret
    return p->tf->a1;
    80002890:	6d3c                	ld	a5,88(a0)
    80002892:	7fa8                	ld	a0,120(a5)
    80002894:	bfcd                	j	80002886 <argraw+0x30>
    return p->tf->a2;
    80002896:	6d3c                	ld	a5,88(a0)
    80002898:	63c8                	ld	a0,128(a5)
    8000289a:	b7f5                	j	80002886 <argraw+0x30>
    return p->tf->a3;
    8000289c:	6d3c                	ld	a5,88(a0)
    8000289e:	67c8                	ld	a0,136(a5)
    800028a0:	b7dd                	j	80002886 <argraw+0x30>
    return p->tf->a4;
    800028a2:	6d3c                	ld	a5,88(a0)
    800028a4:	6bc8                	ld	a0,144(a5)
    800028a6:	b7c5                	j	80002886 <argraw+0x30>
    return p->tf->a5;
    800028a8:	6d3c                	ld	a5,88(a0)
    800028aa:	6fc8                	ld	a0,152(a5)
    800028ac:	bfe9                	j	80002886 <argraw+0x30>
  panic("argraw");
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	c0a50513          	addi	a0,a0,-1014 # 800084b8 <userret+0x428>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	c98080e7          	jalr	-872(ra) # 8000054e <panic>

00000000800028be <fetchaddr>:
{
    800028be:	1101                	addi	sp,sp,-32
    800028c0:	ec06                	sd	ra,24(sp)
    800028c2:	e822                	sd	s0,16(sp)
    800028c4:	e426                	sd	s1,8(sp)
    800028c6:	e04a                	sd	s2,0(sp)
    800028c8:	1000                	addi	s0,sp,32
    800028ca:	84aa                	mv	s1,a0
    800028cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800028ce:	fffff097          	auipc	ra,0xfffff
    800028d2:	fd0080e7          	jalr	-48(ra) # 8000189e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800028d6:	653c                	ld	a5,72(a0)
    800028d8:	02f4f863          	bgeu	s1,a5,80002908 <fetchaddr+0x4a>
    800028dc:	00848713          	addi	a4,s1,8
    800028e0:	02e7e663          	bltu	a5,a4,8000290c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800028e4:	46a1                	li	a3,8
    800028e6:	8626                	mv	a2,s1
    800028e8:	85ca                	mv	a1,s2
    800028ea:	6928                	ld	a0,80(a0)
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	bfa080e7          	jalr	-1030(ra) # 800014e6 <copyin>
    800028f4:	00a03533          	snez	a0,a0
    800028f8:	40a00533          	neg	a0,a0
}
    800028fc:	60e2                	ld	ra,24(sp)
    800028fe:	6442                	ld	s0,16(sp)
    80002900:	64a2                	ld	s1,8(sp)
    80002902:	6902                	ld	s2,0(sp)
    80002904:	6105                	addi	sp,sp,32
    80002906:	8082                	ret
    return -1;
    80002908:	557d                	li	a0,-1
    8000290a:	bfcd                	j	800028fc <fetchaddr+0x3e>
    8000290c:	557d                	li	a0,-1
    8000290e:	b7fd                	j	800028fc <fetchaddr+0x3e>

0000000080002910 <fetchstr>:
{
    80002910:	7179                	addi	sp,sp,-48
    80002912:	f406                	sd	ra,40(sp)
    80002914:	f022                	sd	s0,32(sp)
    80002916:	ec26                	sd	s1,24(sp)
    80002918:	e84a                	sd	s2,16(sp)
    8000291a:	e44e                	sd	s3,8(sp)
    8000291c:	1800                	addi	s0,sp,48
    8000291e:	892a                	mv	s2,a0
    80002920:	84ae                	mv	s1,a1
    80002922:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	f7a080e7          	jalr	-134(ra) # 8000189e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000292c:	86ce                	mv	a3,s3
    8000292e:	864a                	mv	a2,s2
    80002930:	85a6                	mv	a1,s1
    80002932:	6928                	ld	a0,80(a0)
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	c44080e7          	jalr	-956(ra) # 80001578 <copyinstr>
  if(err < 0)
    8000293c:	00054763          	bltz	a0,8000294a <fetchstr+0x3a>
  return strlen(buf);
    80002940:	8526                	mv	a0,s1
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	2d6080e7          	jalr	726(ra) # 80000c18 <strlen>
}
    8000294a:	70a2                	ld	ra,40(sp)
    8000294c:	7402                	ld	s0,32(sp)
    8000294e:	64e2                	ld	s1,24(sp)
    80002950:	6942                	ld	s2,16(sp)
    80002952:	69a2                	ld	s3,8(sp)
    80002954:	6145                	addi	sp,sp,48
    80002956:	8082                	ret

0000000080002958 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002958:	1101                	addi	sp,sp,-32
    8000295a:	ec06                	sd	ra,24(sp)
    8000295c:	e822                	sd	s0,16(sp)
    8000295e:	e426                	sd	s1,8(sp)
    80002960:	1000                	addi	s0,sp,32
    80002962:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002964:	00000097          	auipc	ra,0x0
    80002968:	ef2080e7          	jalr	-270(ra) # 80002856 <argraw>
    8000296c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000296e:	4501                	li	a0,0
    80002970:	60e2                	ld	ra,24(sp)
    80002972:	6442                	ld	s0,16(sp)
    80002974:	64a2                	ld	s1,8(sp)
    80002976:	6105                	addi	sp,sp,32
    80002978:	8082                	ret

000000008000297a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000297a:	1101                	addi	sp,sp,-32
    8000297c:	ec06                	sd	ra,24(sp)
    8000297e:	e822                	sd	s0,16(sp)
    80002980:	e426                	sd	s1,8(sp)
    80002982:	1000                	addi	s0,sp,32
    80002984:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	ed0080e7          	jalr	-304(ra) # 80002856 <argraw>
    8000298e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002990:	4501                	li	a0,0
    80002992:	60e2                	ld	ra,24(sp)
    80002994:	6442                	ld	s0,16(sp)
    80002996:	64a2                	ld	s1,8(sp)
    80002998:	6105                	addi	sp,sp,32
    8000299a:	8082                	ret

000000008000299c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000299c:	1101                	addi	sp,sp,-32
    8000299e:	ec06                	sd	ra,24(sp)
    800029a0:	e822                	sd	s0,16(sp)
    800029a2:	e426                	sd	s1,8(sp)
    800029a4:	e04a                	sd	s2,0(sp)
    800029a6:	1000                	addi	s0,sp,32
    800029a8:	84ae                	mv	s1,a1
    800029aa:	8932                	mv	s2,a2
  *ip = argraw(n);
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	eaa080e7          	jalr	-342(ra) # 80002856 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800029b4:	864a                	mv	a2,s2
    800029b6:	85a6                	mv	a1,s1
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	f58080e7          	jalr	-168(ra) # 80002910 <fetchstr>
}
    800029c0:	60e2                	ld	ra,24(sp)
    800029c2:	6442                	ld	s0,16(sp)
    800029c4:	64a2                	ld	s1,8(sp)
    800029c6:	6902                	ld	s2,0(sp)
    800029c8:	6105                	addi	sp,sp,32
    800029ca:	8082                	ret

00000000800029cc <syscall>:
[SYS_crash]   sys_crash,
};

void
syscall(void)
{
    800029cc:	1101                	addi	sp,sp,-32
    800029ce:	ec06                	sd	ra,24(sp)
    800029d0:	e822                	sd	s0,16(sp)
    800029d2:	e426                	sd	s1,8(sp)
    800029d4:	e04a                	sd	s2,0(sp)
    800029d6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	ec6080e7          	jalr	-314(ra) # 8000189e <myproc>
    800029e0:	84aa                	mv	s1,a0

  num = p->tf->a7;
    800029e2:	05853903          	ld	s2,88(a0)
    800029e6:	0a893783          	ld	a5,168(s2)
    800029ea:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800029ee:	37fd                	addiw	a5,a5,-1
    800029f0:	4759                	li	a4,22
    800029f2:	00f76f63          	bltu	a4,a5,80002a10 <syscall+0x44>
    800029f6:	00369713          	slli	a4,a3,0x3
    800029fa:	00006797          	auipc	a5,0x6
    800029fe:	06678793          	addi	a5,a5,102 # 80008a60 <syscalls>
    80002a02:	97ba                	add	a5,a5,a4
    80002a04:	639c                	ld	a5,0(a5)
    80002a06:	c789                	beqz	a5,80002a10 <syscall+0x44>
    p->tf->a0 = syscalls[num]();
    80002a08:	9782                	jalr	a5
    80002a0a:	06a93823          	sd	a0,112(s2)
    80002a0e:	a839                	j	80002a2c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002a10:	15848613          	addi	a2,s1,344
    80002a14:	5c8c                	lw	a1,56(s1)
    80002a16:	00006517          	auipc	a0,0x6
    80002a1a:	aaa50513          	addi	a0,a0,-1366 # 800084c0 <userret+0x430>
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	b7a080e7          	jalr	-1158(ra) # 80000598 <printf>
            p->pid, p->name, num);
    p->tf->a0 = -1;
    80002a26:	6cbc                	ld	a5,88(s1)
    80002a28:	577d                	li	a4,-1
    80002a2a:	fbb8                	sd	a4,112(a5)
  }
}
    80002a2c:	60e2                	ld	ra,24(sp)
    80002a2e:	6442                	ld	s0,16(sp)
    80002a30:	64a2                	ld	s1,8(sp)
    80002a32:	6902                	ld	s2,0(sp)
    80002a34:	6105                	addi	sp,sp,32
    80002a36:	8082                	ret

0000000080002a38 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002a38:	1101                	addi	sp,sp,-32
    80002a3a:	ec06                	sd	ra,24(sp)
    80002a3c:	e822                	sd	s0,16(sp)
    80002a3e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002a40:	fec40593          	addi	a1,s0,-20
    80002a44:	4501                	li	a0,0
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	f12080e7          	jalr	-238(ra) # 80002958 <argint>
    return -1;
    80002a4e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002a50:	00054963          	bltz	a0,80002a62 <sys_exit+0x2a>
  exit(n);
    80002a54:	fec42503          	lw	a0,-20(s0)
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	536080e7          	jalr	1334(ra) # 80001f8e <exit>
  return 0;  // not reached
    80002a60:	4781                	li	a5,0
}
    80002a62:	853e                	mv	a0,a5
    80002a64:	60e2                	ld	ra,24(sp)
    80002a66:	6442                	ld	s0,16(sp)
    80002a68:	6105                	addi	sp,sp,32
    80002a6a:	8082                	ret

0000000080002a6c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002a6c:	1141                	addi	sp,sp,-16
    80002a6e:	e406                	sd	ra,8(sp)
    80002a70:	e022                	sd	s0,0(sp)
    80002a72:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	e2a080e7          	jalr	-470(ra) # 8000189e <myproc>
}
    80002a7c:	5d08                	lw	a0,56(a0)
    80002a7e:	60a2                	ld	ra,8(sp)
    80002a80:	6402                	ld	s0,0(sp)
    80002a82:	0141                	addi	sp,sp,16
    80002a84:	8082                	ret

0000000080002a86 <sys_fork>:

uint64
sys_fork(void)
{
    80002a86:	1141                	addi	sp,sp,-16
    80002a88:	e406                	sd	ra,8(sp)
    80002a8a:	e022                	sd	s0,0(sp)
    80002a8c:	0800                	addi	s0,sp,16
  return fork();
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	17e080e7          	jalr	382(ra) # 80001c0c <fork>
}
    80002a96:	60a2                	ld	ra,8(sp)
    80002a98:	6402                	ld	s0,0(sp)
    80002a9a:	0141                	addi	sp,sp,16
    80002a9c:	8082                	ret

0000000080002a9e <sys_wait>:

uint64
sys_wait(void)
{
    80002a9e:	1101                	addi	sp,sp,-32
    80002aa0:	ec06                	sd	ra,24(sp)
    80002aa2:	e822                	sd	s0,16(sp)
    80002aa4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002aa6:	fe840593          	addi	a1,s0,-24
    80002aaa:	4501                	li	a0,0
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	ece080e7          	jalr	-306(ra) # 8000297a <argaddr>
    80002ab4:	87aa                	mv	a5,a0
    return -1;
    80002ab6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ab8:	0007c863          	bltz	a5,80002ac8 <sys_wait+0x2a>
  return wait(p);
    80002abc:	fe843503          	ld	a0,-24(s0)
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	66e080e7          	jalr	1646(ra) # 8000212e <wait>
}
    80002ac8:	60e2                	ld	ra,24(sp)
    80002aca:	6442                	ld	s0,16(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret

0000000080002ad0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ad0:	7179                	addi	sp,sp,-48
    80002ad2:	f406                	sd	ra,40(sp)
    80002ad4:	f022                	sd	s0,32(sp)
    80002ad6:	ec26                	sd	s1,24(sp)
    80002ad8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ada:	fdc40593          	addi	a1,s0,-36
    80002ade:	4501                	li	a0,0
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	e78080e7          	jalr	-392(ra) # 80002958 <argint>
    80002ae8:	87aa                	mv	a5,a0
    return -1;
    80002aea:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002aec:	0207c063          	bltz	a5,80002b0c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	dae080e7          	jalr	-594(ra) # 8000189e <myproc>
    80002af8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002afa:	fdc42503          	lw	a0,-36(s0)
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	096080e7          	jalr	150(ra) # 80001b94 <growproc>
    80002b06:	00054863          	bltz	a0,80002b16 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002b0a:	8526                	mv	a0,s1
}
    80002b0c:	70a2                	ld	ra,40(sp)
    80002b0e:	7402                	ld	s0,32(sp)
    80002b10:	64e2                	ld	s1,24(sp)
    80002b12:	6145                	addi	sp,sp,48
    80002b14:	8082                	ret
    return -1;
    80002b16:	557d                	li	a0,-1
    80002b18:	bfd5                	j	80002b0c <sys_sbrk+0x3c>

0000000080002b1a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002b1a:	7139                	addi	sp,sp,-64
    80002b1c:	fc06                	sd	ra,56(sp)
    80002b1e:	f822                	sd	s0,48(sp)
    80002b20:	f426                	sd	s1,40(sp)
    80002b22:	f04a                	sd	s2,32(sp)
    80002b24:	ec4e                	sd	s3,24(sp)
    80002b26:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002b28:	fcc40593          	addi	a1,s0,-52
    80002b2c:	4501                	li	a0,0
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	e2a080e7          	jalr	-470(ra) # 80002958 <argint>
    return -1;
    80002b36:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b38:	06054563          	bltz	a0,80002ba2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002b3c:	00016517          	auipc	a0,0x16
    80002b40:	ba450513          	addi	a0,a0,-1116 # 800186e0 <tickslock>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	e88080e7          	jalr	-376(ra) # 800009cc <acquire>
  ticks0 = ticks;
    80002b4c:	00027917          	auipc	s2,0x27
    80002b50:	4f492903          	lw	s2,1268(s2) # 8002a040 <ticks>
  while(ticks - ticks0 < n){
    80002b54:	fcc42783          	lw	a5,-52(s0)
    80002b58:	cf85                	beqz	a5,80002b90 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002b5a:	00016997          	auipc	s3,0x16
    80002b5e:	b8698993          	addi	s3,s3,-1146 # 800186e0 <tickslock>
    80002b62:	00027497          	auipc	s1,0x27
    80002b66:	4de48493          	addi	s1,s1,1246 # 8002a040 <ticks>
    if(myproc()->killed){
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	d34080e7          	jalr	-716(ra) # 8000189e <myproc>
    80002b72:	591c                	lw	a5,48(a0)
    80002b74:	ef9d                	bnez	a5,80002bb2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002b76:	85ce                	mv	a1,s3
    80002b78:	8526                	mv	a0,s1
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	536080e7          	jalr	1334(ra) # 800020b0 <sleep>
  while(ticks - ticks0 < n){
    80002b82:	409c                	lw	a5,0(s1)
    80002b84:	412787bb          	subw	a5,a5,s2
    80002b88:	fcc42703          	lw	a4,-52(s0)
    80002b8c:	fce7efe3          	bltu	a5,a4,80002b6a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002b90:	00016517          	auipc	a0,0x16
    80002b94:	b5050513          	addi	a0,a0,-1200 # 800186e0 <tickslock>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	e9c080e7          	jalr	-356(ra) # 80000a34 <release>
  return 0;
    80002ba0:	4781                	li	a5,0
}
    80002ba2:	853e                	mv	a0,a5
    80002ba4:	70e2                	ld	ra,56(sp)
    80002ba6:	7442                	ld	s0,48(sp)
    80002ba8:	74a2                	ld	s1,40(sp)
    80002baa:	7902                	ld	s2,32(sp)
    80002bac:	69e2                	ld	s3,24(sp)
    80002bae:	6121                	addi	sp,sp,64
    80002bb0:	8082                	ret
      release(&tickslock);
    80002bb2:	00016517          	auipc	a0,0x16
    80002bb6:	b2e50513          	addi	a0,a0,-1234 # 800186e0 <tickslock>
    80002bba:	ffffe097          	auipc	ra,0xffffe
    80002bbe:	e7a080e7          	jalr	-390(ra) # 80000a34 <release>
      return -1;
    80002bc2:	57fd                	li	a5,-1
    80002bc4:	bff9                	j	80002ba2 <sys_sleep+0x88>

0000000080002bc6 <sys_kill>:

uint64
sys_kill(void)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002bce:	fec40593          	addi	a1,s0,-20
    80002bd2:	4501                	li	a0,0
    80002bd4:	00000097          	auipc	ra,0x0
    80002bd8:	d84080e7          	jalr	-636(ra) # 80002958 <argint>
    80002bdc:	87aa                	mv	a5,a0
    return -1;
    80002bde:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002be0:	0007c863          	bltz	a5,80002bf0 <sys_kill+0x2a>
  return kill(pid);
    80002be4:	fec42503          	lw	a0,-20(s0)
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	6b8080e7          	jalr	1720(ra) # 800022a0 <kill>
}
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret

0000000080002bf8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002bf8:	1101                	addi	sp,sp,-32
    80002bfa:	ec06                	sd	ra,24(sp)
    80002bfc:	e822                	sd	s0,16(sp)
    80002bfe:	e426                	sd	s1,8(sp)
    80002c00:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002c02:	00016517          	auipc	a0,0x16
    80002c06:	ade50513          	addi	a0,a0,-1314 # 800186e0 <tickslock>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	dc2080e7          	jalr	-574(ra) # 800009cc <acquire>
  xticks = ticks;
    80002c12:	00027497          	auipc	s1,0x27
    80002c16:	42e4a483          	lw	s1,1070(s1) # 8002a040 <ticks>
  release(&tickslock);
    80002c1a:	00016517          	auipc	a0,0x16
    80002c1e:	ac650513          	addi	a0,a0,-1338 # 800186e0 <tickslock>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	e12080e7          	jalr	-494(ra) # 80000a34 <release>
  return xticks;
}
    80002c2a:	02049513          	slli	a0,s1,0x20
    80002c2e:	9101                	srli	a0,a0,0x20
    80002c30:	60e2                	ld	ra,24(sp)
    80002c32:	6442                	ld	s0,16(sp)
    80002c34:	64a2                	ld	s1,8(sp)
    80002c36:	6105                	addi	sp,sp,32
    80002c38:	8082                	ret

0000000080002c3a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002c3a:	7179                	addi	sp,sp,-48
    80002c3c:	f406                	sd	ra,40(sp)
    80002c3e:	f022                	sd	s0,32(sp)
    80002c40:	ec26                	sd	s1,24(sp)
    80002c42:	e84a                	sd	s2,16(sp)
    80002c44:	e44e                	sd	s3,8(sp)
    80002c46:	e052                	sd	s4,0(sp)
    80002c48:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002c4a:	00006597          	auipc	a1,0x6
    80002c4e:	89658593          	addi	a1,a1,-1898 # 800084e0 <userret+0x450>
    80002c52:	00016517          	auipc	a0,0x16
    80002c56:	aa650513          	addi	a0,a0,-1370 # 800186f8 <bcache>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	c60080e7          	jalr	-928(ra) # 800008ba <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002c62:	0001e797          	auipc	a5,0x1e
    80002c66:	a9678793          	addi	a5,a5,-1386 # 800206f8 <bcache+0x8000>
    80002c6a:	0001e717          	auipc	a4,0x1e
    80002c6e:	de670713          	addi	a4,a4,-538 # 80020a50 <bcache+0x8358>
    80002c72:	3ae7b023          	sd	a4,928(a5)
  bcache.head.next = &bcache.head;
    80002c76:	3ae7b423          	sd	a4,936(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002c7a:	00016497          	auipc	s1,0x16
    80002c7e:	a9648493          	addi	s1,s1,-1386 # 80018710 <bcache+0x18>
    b->next = bcache.head.next;
    80002c82:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002c84:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002c86:	00006a17          	auipc	s4,0x6
    80002c8a:	862a0a13          	addi	s4,s4,-1950 # 800084e8 <userret+0x458>
    b->next = bcache.head.next;
    80002c8e:	3a893783          	ld	a5,936(s2)
    80002c92:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002c94:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002c98:	85d2                	mv	a1,s4
    80002c9a:	01048513          	addi	a0,s1,16
    80002c9e:	00001097          	auipc	ra,0x1
    80002ca2:	6f2080e7          	jalr	1778(ra) # 80004390 <initsleeplock>
    bcache.head.next->prev = b;
    80002ca6:	3a893783          	ld	a5,936(s2)
    80002caa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002cac:	3a993423          	sd	s1,936(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002cb0:	46048493          	addi	s1,s1,1120
    80002cb4:	fd349de3          	bne	s1,s3,80002c8e <binit+0x54>
  }
}
    80002cb8:	70a2                	ld	ra,40(sp)
    80002cba:	7402                	ld	s0,32(sp)
    80002cbc:	64e2                	ld	s1,24(sp)
    80002cbe:	6942                	ld	s2,16(sp)
    80002cc0:	69a2                	ld	s3,8(sp)
    80002cc2:	6a02                	ld	s4,0(sp)
    80002cc4:	6145                	addi	sp,sp,48
    80002cc6:	8082                	ret

0000000080002cc8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002cc8:	7179                	addi	sp,sp,-48
    80002cca:	f406                	sd	ra,40(sp)
    80002ccc:	f022                	sd	s0,32(sp)
    80002cce:	ec26                	sd	s1,24(sp)
    80002cd0:	e84a                	sd	s2,16(sp)
    80002cd2:	e44e                	sd	s3,8(sp)
    80002cd4:	1800                	addi	s0,sp,48
    80002cd6:	89aa                	mv	s3,a0
    80002cd8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002cda:	00016517          	auipc	a0,0x16
    80002cde:	a1e50513          	addi	a0,a0,-1506 # 800186f8 <bcache>
    80002ce2:	ffffe097          	auipc	ra,0xffffe
    80002ce6:	cea080e7          	jalr	-790(ra) # 800009cc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002cea:	0001e497          	auipc	s1,0x1e
    80002cee:	db64b483          	ld	s1,-586(s1) # 80020aa0 <bcache+0x83a8>
    80002cf2:	0001e797          	auipc	a5,0x1e
    80002cf6:	d5e78793          	addi	a5,a5,-674 # 80020a50 <bcache+0x8358>
    80002cfa:	02f48f63          	beq	s1,a5,80002d38 <bread+0x70>
    80002cfe:	873e                	mv	a4,a5
    80002d00:	a021                	j	80002d08 <bread+0x40>
    80002d02:	68a4                	ld	s1,80(s1)
    80002d04:	02e48a63          	beq	s1,a4,80002d38 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002d08:	449c                	lw	a5,8(s1)
    80002d0a:	ff379ce3          	bne	a5,s3,80002d02 <bread+0x3a>
    80002d0e:	44dc                	lw	a5,12(s1)
    80002d10:	ff2799e3          	bne	a5,s2,80002d02 <bread+0x3a>
      b->refcnt++;
    80002d14:	40bc                	lw	a5,64(s1)
    80002d16:	2785                	addiw	a5,a5,1
    80002d18:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002d1a:	00016517          	auipc	a0,0x16
    80002d1e:	9de50513          	addi	a0,a0,-1570 # 800186f8 <bcache>
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	d12080e7          	jalr	-750(ra) # 80000a34 <release>
      acquiresleep(&b->lock);
    80002d2a:	01048513          	addi	a0,s1,16
    80002d2e:	00001097          	auipc	ra,0x1
    80002d32:	69c080e7          	jalr	1692(ra) # 800043ca <acquiresleep>
      return b;
    80002d36:	a8b9                	j	80002d94 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002d38:	0001e497          	auipc	s1,0x1e
    80002d3c:	d604b483          	ld	s1,-672(s1) # 80020a98 <bcache+0x83a0>
    80002d40:	0001e797          	auipc	a5,0x1e
    80002d44:	d1078793          	addi	a5,a5,-752 # 80020a50 <bcache+0x8358>
    80002d48:	00f48863          	beq	s1,a5,80002d58 <bread+0x90>
    80002d4c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002d4e:	40bc                	lw	a5,64(s1)
    80002d50:	cf81                	beqz	a5,80002d68 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002d52:	64a4                	ld	s1,72(s1)
    80002d54:	fee49de3          	bne	s1,a4,80002d4e <bread+0x86>
  panic("bget: no buffers");
    80002d58:	00005517          	auipc	a0,0x5
    80002d5c:	79850513          	addi	a0,a0,1944 # 800084f0 <userret+0x460>
    80002d60:	ffffd097          	auipc	ra,0xffffd
    80002d64:	7ee080e7          	jalr	2030(ra) # 8000054e <panic>
      b->dev = dev;
    80002d68:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002d6c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002d70:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002d74:	4785                	li	a5,1
    80002d76:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002d78:	00016517          	auipc	a0,0x16
    80002d7c:	98050513          	addi	a0,a0,-1664 # 800186f8 <bcache>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	cb4080e7          	jalr	-844(ra) # 80000a34 <release>
      acquiresleep(&b->lock);
    80002d88:	01048513          	addi	a0,s1,16
    80002d8c:	00001097          	auipc	ra,0x1
    80002d90:	63e080e7          	jalr	1598(ra) # 800043ca <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002d94:	409c                	lw	a5,0(s1)
    80002d96:	cb89                	beqz	a5,80002da8 <bread+0xe0>
    virtio_disk_rw(b->dev, b, 0);
    b->valid = 1;
  }
  return b;
}
    80002d98:	8526                	mv	a0,s1
    80002d9a:	70a2                	ld	ra,40(sp)
    80002d9c:	7402                	ld	s0,32(sp)
    80002d9e:	64e2                	ld	s1,24(sp)
    80002da0:	6942                	ld	s2,16(sp)
    80002da2:	69a2                	ld	s3,8(sp)
    80002da4:	6145                	addi	sp,sp,48
    80002da6:	8082                	ret
    virtio_disk_rw(b->dev, b, 0);
    80002da8:	4601                	li	a2,0
    80002daa:	85a6                	mv	a1,s1
    80002dac:	4488                	lw	a0,8(s1)
    80002dae:	00003097          	auipc	ra,0x3
    80002db2:	27e080e7          	jalr	638(ra) # 8000602c <virtio_disk_rw>
    b->valid = 1;
    80002db6:	4785                	li	a5,1
    80002db8:	c09c                	sw	a5,0(s1)
  return b;
    80002dba:	bff9                	j	80002d98 <bread+0xd0>

0000000080002dbc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002dbc:	1101                	addi	sp,sp,-32
    80002dbe:	ec06                	sd	ra,24(sp)
    80002dc0:	e822                	sd	s0,16(sp)
    80002dc2:	e426                	sd	s1,8(sp)
    80002dc4:	1000                	addi	s0,sp,32
    80002dc6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002dc8:	0541                	addi	a0,a0,16
    80002dca:	00001097          	auipc	ra,0x1
    80002dce:	69a080e7          	jalr	1690(ra) # 80004464 <holdingsleep>
    80002dd2:	cd09                	beqz	a0,80002dec <bwrite+0x30>
    panic("bwrite");
  virtio_disk_rw(b->dev, b, 1);
    80002dd4:	4605                	li	a2,1
    80002dd6:	85a6                	mv	a1,s1
    80002dd8:	4488                	lw	a0,8(s1)
    80002dda:	00003097          	auipc	ra,0x3
    80002dde:	252080e7          	jalr	594(ra) # 8000602c <virtio_disk_rw>
}
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	64a2                	ld	s1,8(sp)
    80002de8:	6105                	addi	sp,sp,32
    80002dea:	8082                	ret
    panic("bwrite");
    80002dec:	00005517          	auipc	a0,0x5
    80002df0:	71c50513          	addi	a0,a0,1820 # 80008508 <userret+0x478>
    80002df4:	ffffd097          	auipc	ra,0xffffd
    80002df8:	75a080e7          	jalr	1882(ra) # 8000054e <panic>

0000000080002dfc <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	e426                	sd	s1,8(sp)
    80002e04:	e04a                	sd	s2,0(sp)
    80002e06:	1000                	addi	s0,sp,32
    80002e08:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002e0a:	01050913          	addi	s2,a0,16
    80002e0e:	854a                	mv	a0,s2
    80002e10:	00001097          	auipc	ra,0x1
    80002e14:	654080e7          	jalr	1620(ra) # 80004464 <holdingsleep>
    80002e18:	c92d                	beqz	a0,80002e8a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002e1a:	854a                	mv	a0,s2
    80002e1c:	00001097          	auipc	ra,0x1
    80002e20:	604080e7          	jalr	1540(ra) # 80004420 <releasesleep>

  acquire(&bcache.lock);
    80002e24:	00016517          	auipc	a0,0x16
    80002e28:	8d450513          	addi	a0,a0,-1836 # 800186f8 <bcache>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	ba0080e7          	jalr	-1120(ra) # 800009cc <acquire>
  b->refcnt--;
    80002e34:	40bc                	lw	a5,64(s1)
    80002e36:	37fd                	addiw	a5,a5,-1
    80002e38:	0007871b          	sext.w	a4,a5
    80002e3c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002e3e:	eb05                	bnez	a4,80002e6e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002e40:	68bc                	ld	a5,80(s1)
    80002e42:	64b8                	ld	a4,72(s1)
    80002e44:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002e46:	64bc                	ld	a5,72(s1)
    80002e48:	68b8                	ld	a4,80(s1)
    80002e4a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002e4c:	0001e797          	auipc	a5,0x1e
    80002e50:	8ac78793          	addi	a5,a5,-1876 # 800206f8 <bcache+0x8000>
    80002e54:	3a87b703          	ld	a4,936(a5)
    80002e58:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002e5a:	0001e717          	auipc	a4,0x1e
    80002e5e:	bf670713          	addi	a4,a4,-1034 # 80020a50 <bcache+0x8358>
    80002e62:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002e64:	3a87b703          	ld	a4,936(a5)
    80002e68:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002e6a:	3a97b423          	sd	s1,936(a5)
  }
  
  release(&bcache.lock);
    80002e6e:	00016517          	auipc	a0,0x16
    80002e72:	88a50513          	addi	a0,a0,-1910 # 800186f8 <bcache>
    80002e76:	ffffe097          	auipc	ra,0xffffe
    80002e7a:	bbe080e7          	jalr	-1090(ra) # 80000a34 <release>
}
    80002e7e:	60e2                	ld	ra,24(sp)
    80002e80:	6442                	ld	s0,16(sp)
    80002e82:	64a2                	ld	s1,8(sp)
    80002e84:	6902                	ld	s2,0(sp)
    80002e86:	6105                	addi	sp,sp,32
    80002e88:	8082                	ret
    panic("brelse");
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	68650513          	addi	a0,a0,1670 # 80008510 <userret+0x480>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6bc080e7          	jalr	1724(ra) # 8000054e <panic>

0000000080002e9a <bpin>:

void
bpin(struct buf *b) {
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	e426                	sd	s1,8(sp)
    80002ea2:	1000                	addi	s0,sp,32
    80002ea4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ea6:	00016517          	auipc	a0,0x16
    80002eaa:	85250513          	addi	a0,a0,-1966 # 800186f8 <bcache>
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	b1e080e7          	jalr	-1250(ra) # 800009cc <acquire>
  b->refcnt++;
    80002eb6:	40bc                	lw	a5,64(s1)
    80002eb8:	2785                	addiw	a5,a5,1
    80002eba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ebc:	00016517          	auipc	a0,0x16
    80002ec0:	83c50513          	addi	a0,a0,-1988 # 800186f8 <bcache>
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	b70080e7          	jalr	-1168(ra) # 80000a34 <release>
}
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	64a2                	ld	s1,8(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret

0000000080002ed6 <bunpin>:

void
bunpin(struct buf *b) {
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	e426                	sd	s1,8(sp)
    80002ede:	1000                	addi	s0,sp,32
    80002ee0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ee2:	00016517          	auipc	a0,0x16
    80002ee6:	81650513          	addi	a0,a0,-2026 # 800186f8 <bcache>
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	ae2080e7          	jalr	-1310(ra) # 800009cc <acquire>
  b->refcnt--;
    80002ef2:	40bc                	lw	a5,64(s1)
    80002ef4:	37fd                	addiw	a5,a5,-1
    80002ef6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ef8:	00016517          	auipc	a0,0x16
    80002efc:	80050513          	addi	a0,a0,-2048 # 800186f8 <bcache>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	b34080e7          	jalr	-1228(ra) # 80000a34 <release>
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret

0000000080002f12 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	e426                	sd	s1,8(sp)
    80002f1a:	e04a                	sd	s2,0(sp)
    80002f1c:	1000                	addi	s0,sp,32
    80002f1e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002f20:	00d5d59b          	srliw	a1,a1,0xd
    80002f24:	0001e797          	auipc	a5,0x1e
    80002f28:	fa87a783          	lw	a5,-88(a5) # 80020ecc <sb+0x1c>
    80002f2c:	9dbd                	addw	a1,a1,a5
    80002f2e:	00000097          	auipc	ra,0x0
    80002f32:	d9a080e7          	jalr	-614(ra) # 80002cc8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002f36:	0074f713          	andi	a4,s1,7
    80002f3a:	4785                	li	a5,1
    80002f3c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002f40:	14ce                	slli	s1,s1,0x33
    80002f42:	90d9                	srli	s1,s1,0x36
    80002f44:	00950733          	add	a4,a0,s1
    80002f48:	06074703          	lbu	a4,96(a4)
    80002f4c:	00e7f6b3          	and	a3,a5,a4
    80002f50:	c69d                	beqz	a3,80002f7e <bfree+0x6c>
    80002f52:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002f54:	94aa                	add	s1,s1,a0
    80002f56:	fff7c793          	not	a5,a5
    80002f5a:	8ff9                	and	a5,a5,a4
    80002f5c:	06f48023          	sb	a5,96(s1)
  log_write(bp);
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	1d2080e7          	jalr	466(ra) # 80004132 <log_write>
  brelse(bp);
    80002f68:	854a                	mv	a0,s2
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	e92080e7          	jalr	-366(ra) # 80002dfc <brelse>
}
    80002f72:	60e2                	ld	ra,24(sp)
    80002f74:	6442                	ld	s0,16(sp)
    80002f76:	64a2                	ld	s1,8(sp)
    80002f78:	6902                	ld	s2,0(sp)
    80002f7a:	6105                	addi	sp,sp,32
    80002f7c:	8082                	ret
    panic("freeing free block");
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	59a50513          	addi	a0,a0,1434 # 80008518 <userret+0x488>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	5c8080e7          	jalr	1480(ra) # 8000054e <panic>

0000000080002f8e <balloc>:
{
    80002f8e:	711d                	addi	sp,sp,-96
    80002f90:	ec86                	sd	ra,88(sp)
    80002f92:	e8a2                	sd	s0,80(sp)
    80002f94:	e4a6                	sd	s1,72(sp)
    80002f96:	e0ca                	sd	s2,64(sp)
    80002f98:	fc4e                	sd	s3,56(sp)
    80002f9a:	f852                	sd	s4,48(sp)
    80002f9c:	f456                	sd	s5,40(sp)
    80002f9e:	f05a                	sd	s6,32(sp)
    80002fa0:	ec5e                	sd	s7,24(sp)
    80002fa2:	e862                	sd	s8,16(sp)
    80002fa4:	e466                	sd	s9,8(sp)
    80002fa6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002fa8:	0001e797          	auipc	a5,0x1e
    80002fac:	f0c7a783          	lw	a5,-244(a5) # 80020eb4 <sb+0x4>
    80002fb0:	cbd1                	beqz	a5,80003044 <balloc+0xb6>
    80002fb2:	8baa                	mv	s7,a0
    80002fb4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002fb6:	0001eb17          	auipc	s6,0x1e
    80002fba:	efab0b13          	addi	s6,s6,-262 # 80020eb0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002fbe:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002fc0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002fc2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002fc4:	6c89                	lui	s9,0x2
    80002fc6:	a831                	j	80002fe2 <balloc+0x54>
    brelse(bp);
    80002fc8:	854a                	mv	a0,s2
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	e32080e7          	jalr	-462(ra) # 80002dfc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002fd2:	015c87bb          	addw	a5,s9,s5
    80002fd6:	00078a9b          	sext.w	s5,a5
    80002fda:	004b2703          	lw	a4,4(s6)
    80002fde:	06eaf363          	bgeu	s5,a4,80003044 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80002fe2:	41fad79b          	sraiw	a5,s5,0x1f
    80002fe6:	0137d79b          	srliw	a5,a5,0x13
    80002fea:	015787bb          	addw	a5,a5,s5
    80002fee:	40d7d79b          	sraiw	a5,a5,0xd
    80002ff2:	01cb2583          	lw	a1,28(s6)
    80002ff6:	9dbd                	addw	a1,a1,a5
    80002ff8:	855e                	mv	a0,s7
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	cce080e7          	jalr	-818(ra) # 80002cc8 <bread>
    80003002:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003004:	004b2503          	lw	a0,4(s6)
    80003008:	000a849b          	sext.w	s1,s5
    8000300c:	8662                	mv	a2,s8
    8000300e:	faa4fde3          	bgeu	s1,a0,80002fc8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003012:	41f6579b          	sraiw	a5,a2,0x1f
    80003016:	01d7d69b          	srliw	a3,a5,0x1d
    8000301a:	00c6873b          	addw	a4,a3,a2
    8000301e:	00777793          	andi	a5,a4,7
    80003022:	9f95                	subw	a5,a5,a3
    80003024:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003028:	4037571b          	sraiw	a4,a4,0x3
    8000302c:	00e906b3          	add	a3,s2,a4
    80003030:	0606c683          	lbu	a3,96(a3)
    80003034:	00d7f5b3          	and	a1,a5,a3
    80003038:	cd91                	beqz	a1,80003054 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000303a:	2605                	addiw	a2,a2,1
    8000303c:	2485                	addiw	s1,s1,1
    8000303e:	fd4618e3          	bne	a2,s4,8000300e <balloc+0x80>
    80003042:	b759                	j	80002fc8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003044:	00005517          	auipc	a0,0x5
    80003048:	4ec50513          	addi	a0,a0,1260 # 80008530 <userret+0x4a0>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	502080e7          	jalr	1282(ra) # 8000054e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003054:	974a                	add	a4,a4,s2
    80003056:	8fd5                	or	a5,a5,a3
    80003058:	06f70023          	sb	a5,96(a4)
        log_write(bp);
    8000305c:	854a                	mv	a0,s2
    8000305e:	00001097          	auipc	ra,0x1
    80003062:	0d4080e7          	jalr	212(ra) # 80004132 <log_write>
        brelse(bp);
    80003066:	854a                	mv	a0,s2
    80003068:	00000097          	auipc	ra,0x0
    8000306c:	d94080e7          	jalr	-620(ra) # 80002dfc <brelse>
  bp = bread(dev, bno);
    80003070:	85a6                	mv	a1,s1
    80003072:	855e                	mv	a0,s7
    80003074:	00000097          	auipc	ra,0x0
    80003078:	c54080e7          	jalr	-940(ra) # 80002cc8 <bread>
    8000307c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000307e:	40000613          	li	a2,1024
    80003082:	4581                	li	a1,0
    80003084:	06050513          	addi	a0,a0,96
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	a08080e7          	jalr	-1528(ra) # 80000a90 <memset>
  log_write(bp);
    80003090:	854a                	mv	a0,s2
    80003092:	00001097          	auipc	ra,0x1
    80003096:	0a0080e7          	jalr	160(ra) # 80004132 <log_write>
  brelse(bp);
    8000309a:	854a                	mv	a0,s2
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	d60080e7          	jalr	-672(ra) # 80002dfc <brelse>
}
    800030a4:	8526                	mv	a0,s1
    800030a6:	60e6                	ld	ra,88(sp)
    800030a8:	6446                	ld	s0,80(sp)
    800030aa:	64a6                	ld	s1,72(sp)
    800030ac:	6906                	ld	s2,64(sp)
    800030ae:	79e2                	ld	s3,56(sp)
    800030b0:	7a42                	ld	s4,48(sp)
    800030b2:	7aa2                	ld	s5,40(sp)
    800030b4:	7b02                	ld	s6,32(sp)
    800030b6:	6be2                	ld	s7,24(sp)
    800030b8:	6c42                	ld	s8,16(sp)
    800030ba:	6ca2                	ld	s9,8(sp)
    800030bc:	6125                	addi	sp,sp,96
    800030be:	8082                	ret

00000000800030c0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800030c0:	7179                	addi	sp,sp,-48
    800030c2:	f406                	sd	ra,40(sp)
    800030c4:	f022                	sd	s0,32(sp)
    800030c6:	ec26                	sd	s1,24(sp)
    800030c8:	e84a                	sd	s2,16(sp)
    800030ca:	e44e                	sd	s3,8(sp)
    800030cc:	e052                	sd	s4,0(sp)
    800030ce:	1800                	addi	s0,sp,48
    800030d0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800030d2:	47ad                	li	a5,11
    800030d4:	04b7fe63          	bgeu	a5,a1,80003130 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800030d8:	ff45849b          	addiw	s1,a1,-12
    800030dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800030e0:	0ff00793          	li	a5,255
    800030e4:	0ae7e363          	bltu	a5,a4,8000318a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800030e8:	08052583          	lw	a1,128(a0)
    800030ec:	c5ad                	beqz	a1,80003156 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800030ee:	00092503          	lw	a0,0(s2)
    800030f2:	00000097          	auipc	ra,0x0
    800030f6:	bd6080e7          	jalr	-1066(ra) # 80002cc8 <bread>
    800030fa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800030fc:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003100:	02049593          	slli	a1,s1,0x20
    80003104:	9181                	srli	a1,a1,0x20
    80003106:	058a                	slli	a1,a1,0x2
    80003108:	00b784b3          	add	s1,a5,a1
    8000310c:	0004a983          	lw	s3,0(s1)
    80003110:	04098d63          	beqz	s3,8000316a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003114:	8552                	mv	a0,s4
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	ce6080e7          	jalr	-794(ra) # 80002dfc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000311e:	854e                	mv	a0,s3
    80003120:	70a2                	ld	ra,40(sp)
    80003122:	7402                	ld	s0,32(sp)
    80003124:	64e2                	ld	s1,24(sp)
    80003126:	6942                	ld	s2,16(sp)
    80003128:	69a2                	ld	s3,8(sp)
    8000312a:	6a02                	ld	s4,0(sp)
    8000312c:	6145                	addi	sp,sp,48
    8000312e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003130:	02059493          	slli	s1,a1,0x20
    80003134:	9081                	srli	s1,s1,0x20
    80003136:	048a                	slli	s1,s1,0x2
    80003138:	94aa                	add	s1,s1,a0
    8000313a:	0504a983          	lw	s3,80(s1)
    8000313e:	fe0990e3          	bnez	s3,8000311e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003142:	4108                	lw	a0,0(a0)
    80003144:	00000097          	auipc	ra,0x0
    80003148:	e4a080e7          	jalr	-438(ra) # 80002f8e <balloc>
    8000314c:	0005099b          	sext.w	s3,a0
    80003150:	0534a823          	sw	s3,80(s1)
    80003154:	b7e9                	j	8000311e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003156:	4108                	lw	a0,0(a0)
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	e36080e7          	jalr	-458(ra) # 80002f8e <balloc>
    80003160:	0005059b          	sext.w	a1,a0
    80003164:	08b92023          	sw	a1,128(s2)
    80003168:	b759                	j	800030ee <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000316a:	00092503          	lw	a0,0(s2)
    8000316e:	00000097          	auipc	ra,0x0
    80003172:	e20080e7          	jalr	-480(ra) # 80002f8e <balloc>
    80003176:	0005099b          	sext.w	s3,a0
    8000317a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000317e:	8552                	mv	a0,s4
    80003180:	00001097          	auipc	ra,0x1
    80003184:	fb2080e7          	jalr	-78(ra) # 80004132 <log_write>
    80003188:	b771                	j	80003114 <bmap+0x54>
  panic("bmap: out of range");
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	3be50513          	addi	a0,a0,958 # 80008548 <userret+0x4b8>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	3bc080e7          	jalr	956(ra) # 8000054e <panic>

000000008000319a <iget>:
{
    8000319a:	7179                	addi	sp,sp,-48
    8000319c:	f406                	sd	ra,40(sp)
    8000319e:	f022                	sd	s0,32(sp)
    800031a0:	ec26                	sd	s1,24(sp)
    800031a2:	e84a                	sd	s2,16(sp)
    800031a4:	e44e                	sd	s3,8(sp)
    800031a6:	e052                	sd	s4,0(sp)
    800031a8:	1800                	addi	s0,sp,48
    800031aa:	89aa                	mv	s3,a0
    800031ac:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800031ae:	0001e517          	auipc	a0,0x1e
    800031b2:	d2250513          	addi	a0,a0,-734 # 80020ed0 <icache>
    800031b6:	ffffe097          	auipc	ra,0xffffe
    800031ba:	816080e7          	jalr	-2026(ra) # 800009cc <acquire>
  empty = 0;
    800031be:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800031c0:	0001e497          	auipc	s1,0x1e
    800031c4:	d2848493          	addi	s1,s1,-728 # 80020ee8 <icache+0x18>
    800031c8:	0001f697          	auipc	a3,0x1f
    800031cc:	7b068693          	addi	a3,a3,1968 # 80022978 <log>
    800031d0:	a039                	j	800031de <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800031d2:	02090b63          	beqz	s2,80003208 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800031d6:	08848493          	addi	s1,s1,136
    800031da:	02d48a63          	beq	s1,a3,8000320e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800031de:	449c                	lw	a5,8(s1)
    800031e0:	fef059e3          	blez	a5,800031d2 <iget+0x38>
    800031e4:	4098                	lw	a4,0(s1)
    800031e6:	ff3716e3          	bne	a4,s3,800031d2 <iget+0x38>
    800031ea:	40d8                	lw	a4,4(s1)
    800031ec:	ff4713e3          	bne	a4,s4,800031d2 <iget+0x38>
      ip->ref++;
    800031f0:	2785                	addiw	a5,a5,1
    800031f2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800031f4:	0001e517          	auipc	a0,0x1e
    800031f8:	cdc50513          	addi	a0,a0,-804 # 80020ed0 <icache>
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	838080e7          	jalr	-1992(ra) # 80000a34 <release>
      return ip;
    80003204:	8926                	mv	s2,s1
    80003206:	a03d                	j	80003234 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003208:	f7f9                	bnez	a5,800031d6 <iget+0x3c>
    8000320a:	8926                	mv	s2,s1
    8000320c:	b7e9                	j	800031d6 <iget+0x3c>
  if(empty == 0)
    8000320e:	02090c63          	beqz	s2,80003246 <iget+0xac>
  ip->dev = dev;
    80003212:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003216:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000321a:	4785                	li	a5,1
    8000321c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003220:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003224:	0001e517          	auipc	a0,0x1e
    80003228:	cac50513          	addi	a0,a0,-852 # 80020ed0 <icache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	808080e7          	jalr	-2040(ra) # 80000a34 <release>
}
    80003234:	854a                	mv	a0,s2
    80003236:	70a2                	ld	ra,40(sp)
    80003238:	7402                	ld	s0,32(sp)
    8000323a:	64e2                	ld	s1,24(sp)
    8000323c:	6942                	ld	s2,16(sp)
    8000323e:	69a2                	ld	s3,8(sp)
    80003240:	6a02                	ld	s4,0(sp)
    80003242:	6145                	addi	sp,sp,48
    80003244:	8082                	ret
    panic("iget: no inodes");
    80003246:	00005517          	auipc	a0,0x5
    8000324a:	31a50513          	addi	a0,a0,794 # 80008560 <userret+0x4d0>
    8000324e:	ffffd097          	auipc	ra,0xffffd
    80003252:	300080e7          	jalr	768(ra) # 8000054e <panic>

0000000080003256 <fsinit>:
fsinit(int dev) {
    80003256:	7179                	addi	sp,sp,-48
    80003258:	f406                	sd	ra,40(sp)
    8000325a:	f022                	sd	s0,32(sp)
    8000325c:	ec26                	sd	s1,24(sp)
    8000325e:	e84a                	sd	s2,16(sp)
    80003260:	e44e                	sd	s3,8(sp)
    80003262:	1800                	addi	s0,sp,48
    80003264:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003266:	4585                	li	a1,1
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	a60080e7          	jalr	-1440(ra) # 80002cc8 <bread>
    80003270:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003272:	0001e997          	auipc	s3,0x1e
    80003276:	c3e98993          	addi	s3,s3,-962 # 80020eb0 <sb>
    8000327a:	02000613          	li	a2,32
    8000327e:	06050593          	addi	a1,a0,96
    80003282:	854e                	mv	a0,s3
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	86c080e7          	jalr	-1940(ra) # 80000af0 <memmove>
  brelse(bp);
    8000328c:	8526                	mv	a0,s1
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	b6e080e7          	jalr	-1170(ra) # 80002dfc <brelse>
  if(sb.magic != FSMAGIC)
    80003296:	0009a703          	lw	a4,0(s3)
    8000329a:	102037b7          	lui	a5,0x10203
    8000329e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800032a2:	02f71263          	bne	a4,a5,800032c6 <fsinit+0x70>
  initlog(dev, &sb);
    800032a6:	0001e597          	auipc	a1,0x1e
    800032aa:	c0a58593          	addi	a1,a1,-1014 # 80020eb0 <sb>
    800032ae:	854a                	mv	a0,s2
    800032b0:	00001097          	auipc	ra,0x1
    800032b4:	bfc080e7          	jalr	-1028(ra) # 80003eac <initlog>
}
    800032b8:	70a2                	ld	ra,40(sp)
    800032ba:	7402                	ld	s0,32(sp)
    800032bc:	64e2                	ld	s1,24(sp)
    800032be:	6942                	ld	s2,16(sp)
    800032c0:	69a2                	ld	s3,8(sp)
    800032c2:	6145                	addi	sp,sp,48
    800032c4:	8082                	ret
    panic("invalid file system");
    800032c6:	00005517          	auipc	a0,0x5
    800032ca:	2aa50513          	addi	a0,a0,682 # 80008570 <userret+0x4e0>
    800032ce:	ffffd097          	auipc	ra,0xffffd
    800032d2:	280080e7          	jalr	640(ra) # 8000054e <panic>

00000000800032d6 <iinit>:
{
    800032d6:	7179                	addi	sp,sp,-48
    800032d8:	f406                	sd	ra,40(sp)
    800032da:	f022                	sd	s0,32(sp)
    800032dc:	ec26                	sd	s1,24(sp)
    800032de:	e84a                	sd	s2,16(sp)
    800032e0:	e44e                	sd	s3,8(sp)
    800032e2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800032e4:	00005597          	auipc	a1,0x5
    800032e8:	2a458593          	addi	a1,a1,676 # 80008588 <userret+0x4f8>
    800032ec:	0001e517          	auipc	a0,0x1e
    800032f0:	be450513          	addi	a0,a0,-1052 # 80020ed0 <icache>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	5c6080e7          	jalr	1478(ra) # 800008ba <initlock>
  for(i = 0; i < NINODE; i++) {
    800032fc:	0001e497          	auipc	s1,0x1e
    80003300:	bfc48493          	addi	s1,s1,-1028 # 80020ef8 <icache+0x28>
    80003304:	0001f997          	auipc	s3,0x1f
    80003308:	68498993          	addi	s3,s3,1668 # 80022988 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000330c:	00005917          	auipc	s2,0x5
    80003310:	28490913          	addi	s2,s2,644 # 80008590 <userret+0x500>
    80003314:	85ca                	mv	a1,s2
    80003316:	8526                	mv	a0,s1
    80003318:	00001097          	auipc	ra,0x1
    8000331c:	078080e7          	jalr	120(ra) # 80004390 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003320:	08848493          	addi	s1,s1,136
    80003324:	ff3498e3          	bne	s1,s3,80003314 <iinit+0x3e>
}
    80003328:	70a2                	ld	ra,40(sp)
    8000332a:	7402                	ld	s0,32(sp)
    8000332c:	64e2                	ld	s1,24(sp)
    8000332e:	6942                	ld	s2,16(sp)
    80003330:	69a2                	ld	s3,8(sp)
    80003332:	6145                	addi	sp,sp,48
    80003334:	8082                	ret

0000000080003336 <ialloc>:
{
    80003336:	715d                	addi	sp,sp,-80
    80003338:	e486                	sd	ra,72(sp)
    8000333a:	e0a2                	sd	s0,64(sp)
    8000333c:	fc26                	sd	s1,56(sp)
    8000333e:	f84a                	sd	s2,48(sp)
    80003340:	f44e                	sd	s3,40(sp)
    80003342:	f052                	sd	s4,32(sp)
    80003344:	ec56                	sd	s5,24(sp)
    80003346:	e85a                	sd	s6,16(sp)
    80003348:	e45e                	sd	s7,8(sp)
    8000334a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000334c:	0001e717          	auipc	a4,0x1e
    80003350:	b7072703          	lw	a4,-1168(a4) # 80020ebc <sb+0xc>
    80003354:	4785                	li	a5,1
    80003356:	04e7fa63          	bgeu	a5,a4,800033aa <ialloc+0x74>
    8000335a:	8aaa                	mv	s5,a0
    8000335c:	8bae                	mv	s7,a1
    8000335e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003360:	0001ea17          	auipc	s4,0x1e
    80003364:	b50a0a13          	addi	s4,s4,-1200 # 80020eb0 <sb>
    80003368:	00048b1b          	sext.w	s6,s1
    8000336c:	0044d593          	srli	a1,s1,0x4
    80003370:	018a2783          	lw	a5,24(s4)
    80003374:	9dbd                	addw	a1,a1,a5
    80003376:	8556                	mv	a0,s5
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	950080e7          	jalr	-1712(ra) # 80002cc8 <bread>
    80003380:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003382:	06050993          	addi	s3,a0,96
    80003386:	00f4f793          	andi	a5,s1,15
    8000338a:	079a                	slli	a5,a5,0x6
    8000338c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000338e:	00099783          	lh	a5,0(s3)
    80003392:	c785                	beqz	a5,800033ba <ialloc+0x84>
    brelse(bp);
    80003394:	00000097          	auipc	ra,0x0
    80003398:	a68080e7          	jalr	-1432(ra) # 80002dfc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000339c:	0485                	addi	s1,s1,1
    8000339e:	00ca2703          	lw	a4,12(s4)
    800033a2:	0004879b          	sext.w	a5,s1
    800033a6:	fce7e1e3          	bltu	a5,a4,80003368 <ialloc+0x32>
  panic("ialloc: no inodes");
    800033aa:	00005517          	auipc	a0,0x5
    800033ae:	1ee50513          	addi	a0,a0,494 # 80008598 <userret+0x508>
    800033b2:	ffffd097          	auipc	ra,0xffffd
    800033b6:	19c080e7          	jalr	412(ra) # 8000054e <panic>
      memset(dip, 0, sizeof(*dip));
    800033ba:	04000613          	li	a2,64
    800033be:	4581                	li	a1,0
    800033c0:	854e                	mv	a0,s3
    800033c2:	ffffd097          	auipc	ra,0xffffd
    800033c6:	6ce080e7          	jalr	1742(ra) # 80000a90 <memset>
      dip->type = type;
    800033ca:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800033ce:	854a                	mv	a0,s2
    800033d0:	00001097          	auipc	ra,0x1
    800033d4:	d62080e7          	jalr	-670(ra) # 80004132 <log_write>
      brelse(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00000097          	auipc	ra,0x0
    800033de:	a22080e7          	jalr	-1502(ra) # 80002dfc <brelse>
      return iget(dev, inum);
    800033e2:	85da                	mv	a1,s6
    800033e4:	8556                	mv	a0,s5
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	db4080e7          	jalr	-588(ra) # 8000319a <iget>
}
    800033ee:	60a6                	ld	ra,72(sp)
    800033f0:	6406                	ld	s0,64(sp)
    800033f2:	74e2                	ld	s1,56(sp)
    800033f4:	7942                	ld	s2,48(sp)
    800033f6:	79a2                	ld	s3,40(sp)
    800033f8:	7a02                	ld	s4,32(sp)
    800033fa:	6ae2                	ld	s5,24(sp)
    800033fc:	6b42                	ld	s6,16(sp)
    800033fe:	6ba2                	ld	s7,8(sp)
    80003400:	6161                	addi	sp,sp,80
    80003402:	8082                	ret

0000000080003404 <iupdate>:
{
    80003404:	1101                	addi	sp,sp,-32
    80003406:	ec06                	sd	ra,24(sp)
    80003408:	e822                	sd	s0,16(sp)
    8000340a:	e426                	sd	s1,8(sp)
    8000340c:	e04a                	sd	s2,0(sp)
    8000340e:	1000                	addi	s0,sp,32
    80003410:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003412:	415c                	lw	a5,4(a0)
    80003414:	0047d79b          	srliw	a5,a5,0x4
    80003418:	0001e597          	auipc	a1,0x1e
    8000341c:	ab05a583          	lw	a1,-1360(a1) # 80020ec8 <sb+0x18>
    80003420:	9dbd                	addw	a1,a1,a5
    80003422:	4108                	lw	a0,0(a0)
    80003424:	00000097          	auipc	ra,0x0
    80003428:	8a4080e7          	jalr	-1884(ra) # 80002cc8 <bread>
    8000342c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000342e:	06050793          	addi	a5,a0,96
    80003432:	40c8                	lw	a0,4(s1)
    80003434:	893d                	andi	a0,a0,15
    80003436:	051a                	slli	a0,a0,0x6
    80003438:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000343a:	04449703          	lh	a4,68(s1)
    8000343e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003442:	04649703          	lh	a4,70(s1)
    80003446:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000344a:	04849703          	lh	a4,72(s1)
    8000344e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003452:	04a49703          	lh	a4,74(s1)
    80003456:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000345a:	44f8                	lw	a4,76(s1)
    8000345c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000345e:	03400613          	li	a2,52
    80003462:	05048593          	addi	a1,s1,80
    80003466:	0531                	addi	a0,a0,12
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	688080e7          	jalr	1672(ra) # 80000af0 <memmove>
  log_write(bp);
    80003470:	854a                	mv	a0,s2
    80003472:	00001097          	auipc	ra,0x1
    80003476:	cc0080e7          	jalr	-832(ra) # 80004132 <log_write>
  brelse(bp);
    8000347a:	854a                	mv	a0,s2
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	980080e7          	jalr	-1664(ra) # 80002dfc <brelse>
}
    80003484:	60e2                	ld	ra,24(sp)
    80003486:	6442                	ld	s0,16(sp)
    80003488:	64a2                	ld	s1,8(sp)
    8000348a:	6902                	ld	s2,0(sp)
    8000348c:	6105                	addi	sp,sp,32
    8000348e:	8082                	ret

0000000080003490 <idup>:
{
    80003490:	1101                	addi	sp,sp,-32
    80003492:	ec06                	sd	ra,24(sp)
    80003494:	e822                	sd	s0,16(sp)
    80003496:	e426                	sd	s1,8(sp)
    80003498:	1000                	addi	s0,sp,32
    8000349a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000349c:	0001e517          	auipc	a0,0x1e
    800034a0:	a3450513          	addi	a0,a0,-1484 # 80020ed0 <icache>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	528080e7          	jalr	1320(ra) # 800009cc <acquire>
  ip->ref++;
    800034ac:	449c                	lw	a5,8(s1)
    800034ae:	2785                	addiw	a5,a5,1
    800034b0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800034b2:	0001e517          	auipc	a0,0x1e
    800034b6:	a1e50513          	addi	a0,a0,-1506 # 80020ed0 <icache>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	57a080e7          	jalr	1402(ra) # 80000a34 <release>
}
    800034c2:	8526                	mv	a0,s1
    800034c4:	60e2                	ld	ra,24(sp)
    800034c6:	6442                	ld	s0,16(sp)
    800034c8:	64a2                	ld	s1,8(sp)
    800034ca:	6105                	addi	sp,sp,32
    800034cc:	8082                	ret

00000000800034ce <ilock>:
{
    800034ce:	1101                	addi	sp,sp,-32
    800034d0:	ec06                	sd	ra,24(sp)
    800034d2:	e822                	sd	s0,16(sp)
    800034d4:	e426                	sd	s1,8(sp)
    800034d6:	e04a                	sd	s2,0(sp)
    800034d8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800034da:	c115                	beqz	a0,800034fe <ilock+0x30>
    800034dc:	84aa                	mv	s1,a0
    800034de:	451c                	lw	a5,8(a0)
    800034e0:	00f05f63          	blez	a5,800034fe <ilock+0x30>
  acquiresleep(&ip->lock);
    800034e4:	0541                	addi	a0,a0,16
    800034e6:	00001097          	auipc	ra,0x1
    800034ea:	ee4080e7          	jalr	-284(ra) # 800043ca <acquiresleep>
  if(ip->valid == 0){
    800034ee:	40bc                	lw	a5,64(s1)
    800034f0:	cf99                	beqz	a5,8000350e <ilock+0x40>
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6902                	ld	s2,0(sp)
    800034fa:	6105                	addi	sp,sp,32
    800034fc:	8082                	ret
    panic("ilock");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	0b250513          	addi	a0,a0,178 # 800085b0 <userret+0x520>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	048080e7          	jalr	72(ra) # 8000054e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000350e:	40dc                	lw	a5,4(s1)
    80003510:	0047d79b          	srliw	a5,a5,0x4
    80003514:	0001e597          	auipc	a1,0x1e
    80003518:	9b45a583          	lw	a1,-1612(a1) # 80020ec8 <sb+0x18>
    8000351c:	9dbd                	addw	a1,a1,a5
    8000351e:	4088                	lw	a0,0(s1)
    80003520:	fffff097          	auipc	ra,0xfffff
    80003524:	7a8080e7          	jalr	1960(ra) # 80002cc8 <bread>
    80003528:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000352a:	06050593          	addi	a1,a0,96
    8000352e:	40dc                	lw	a5,4(s1)
    80003530:	8bbd                	andi	a5,a5,15
    80003532:	079a                	slli	a5,a5,0x6
    80003534:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003536:	00059783          	lh	a5,0(a1)
    8000353a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000353e:	00259783          	lh	a5,2(a1)
    80003542:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003546:	00459783          	lh	a5,4(a1)
    8000354a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000354e:	00659783          	lh	a5,6(a1)
    80003552:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003556:	459c                	lw	a5,8(a1)
    80003558:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000355a:	03400613          	li	a2,52
    8000355e:	05b1                	addi	a1,a1,12
    80003560:	05048513          	addi	a0,s1,80
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	58c080e7          	jalr	1420(ra) # 80000af0 <memmove>
    brelse(bp);
    8000356c:	854a                	mv	a0,s2
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	88e080e7          	jalr	-1906(ra) # 80002dfc <brelse>
    ip->valid = 1;
    80003576:	4785                	li	a5,1
    80003578:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000357a:	04449783          	lh	a5,68(s1)
    8000357e:	fbb5                	bnez	a5,800034f2 <ilock+0x24>
      panic("ilock: no type");
    80003580:	00005517          	auipc	a0,0x5
    80003584:	03850513          	addi	a0,a0,56 # 800085b8 <userret+0x528>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	fc6080e7          	jalr	-58(ra) # 8000054e <panic>

0000000080003590 <iunlock>:
{
    80003590:	1101                	addi	sp,sp,-32
    80003592:	ec06                	sd	ra,24(sp)
    80003594:	e822                	sd	s0,16(sp)
    80003596:	e426                	sd	s1,8(sp)
    80003598:	e04a                	sd	s2,0(sp)
    8000359a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000359c:	c905                	beqz	a0,800035cc <iunlock+0x3c>
    8000359e:	84aa                	mv	s1,a0
    800035a0:	01050913          	addi	s2,a0,16
    800035a4:	854a                	mv	a0,s2
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	ebe080e7          	jalr	-322(ra) # 80004464 <holdingsleep>
    800035ae:	cd19                	beqz	a0,800035cc <iunlock+0x3c>
    800035b0:	449c                	lw	a5,8(s1)
    800035b2:	00f05d63          	blez	a5,800035cc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800035b6:	854a                	mv	a0,s2
    800035b8:	00001097          	auipc	ra,0x1
    800035bc:	e68080e7          	jalr	-408(ra) # 80004420 <releasesleep>
}
    800035c0:	60e2                	ld	ra,24(sp)
    800035c2:	6442                	ld	s0,16(sp)
    800035c4:	64a2                	ld	s1,8(sp)
    800035c6:	6902                	ld	s2,0(sp)
    800035c8:	6105                	addi	sp,sp,32
    800035ca:	8082                	ret
    panic("iunlock");
    800035cc:	00005517          	auipc	a0,0x5
    800035d0:	ffc50513          	addi	a0,a0,-4 # 800085c8 <userret+0x538>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	f7a080e7          	jalr	-134(ra) # 8000054e <panic>

00000000800035dc <iput>:
{
    800035dc:	7139                	addi	sp,sp,-64
    800035de:	fc06                	sd	ra,56(sp)
    800035e0:	f822                	sd	s0,48(sp)
    800035e2:	f426                	sd	s1,40(sp)
    800035e4:	f04a                	sd	s2,32(sp)
    800035e6:	ec4e                	sd	s3,24(sp)
    800035e8:	e852                	sd	s4,16(sp)
    800035ea:	e456                	sd	s5,8(sp)
    800035ec:	0080                	addi	s0,sp,64
    800035ee:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800035f0:	0001e517          	auipc	a0,0x1e
    800035f4:	8e050513          	addi	a0,a0,-1824 # 80020ed0 <icache>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	3d4080e7          	jalr	980(ra) # 800009cc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003600:	4498                	lw	a4,8(s1)
    80003602:	4785                	li	a5,1
    80003604:	02f70663          	beq	a4,a5,80003630 <iput+0x54>
  ip->ref--;
    80003608:	449c                	lw	a5,8(s1)
    8000360a:	37fd                	addiw	a5,a5,-1
    8000360c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000360e:	0001e517          	auipc	a0,0x1e
    80003612:	8c250513          	addi	a0,a0,-1854 # 80020ed0 <icache>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	41e080e7          	jalr	1054(ra) # 80000a34 <release>
}
    8000361e:	70e2                	ld	ra,56(sp)
    80003620:	7442                	ld	s0,48(sp)
    80003622:	74a2                	ld	s1,40(sp)
    80003624:	7902                	ld	s2,32(sp)
    80003626:	69e2                	ld	s3,24(sp)
    80003628:	6a42                	ld	s4,16(sp)
    8000362a:	6aa2                	ld	s5,8(sp)
    8000362c:	6121                	addi	sp,sp,64
    8000362e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003630:	40bc                	lw	a5,64(s1)
    80003632:	dbf9                	beqz	a5,80003608 <iput+0x2c>
    80003634:	04a49783          	lh	a5,74(s1)
    80003638:	fbe1                	bnez	a5,80003608 <iput+0x2c>
    acquiresleep(&ip->lock);
    8000363a:	01048a13          	addi	s4,s1,16
    8000363e:	8552                	mv	a0,s4
    80003640:	00001097          	auipc	ra,0x1
    80003644:	d8a080e7          	jalr	-630(ra) # 800043ca <acquiresleep>
    release(&icache.lock);
    80003648:	0001e517          	auipc	a0,0x1e
    8000364c:	88850513          	addi	a0,a0,-1912 # 80020ed0 <icache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	3e4080e7          	jalr	996(ra) # 80000a34 <release>
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003658:	05048913          	addi	s2,s1,80
    8000365c:	08048993          	addi	s3,s1,128
    80003660:	a819                	j	80003676 <iput+0x9a>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    80003662:	4088                	lw	a0,0(s1)
    80003664:	00000097          	auipc	ra,0x0
    80003668:	8ae080e7          	jalr	-1874(ra) # 80002f12 <bfree>
      ip->addrs[i] = 0;
    8000366c:	00092023          	sw	zero,0(s2)
  for(i = 0; i < NDIRECT; i++){
    80003670:	0911                	addi	s2,s2,4
    80003672:	01390663          	beq	s2,s3,8000367e <iput+0xa2>
    if(ip->addrs[i]){
    80003676:	00092583          	lw	a1,0(s2)
    8000367a:	d9fd                	beqz	a1,80003670 <iput+0x94>
    8000367c:	b7dd                	j	80003662 <iput+0x86>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000367e:	0804a583          	lw	a1,128(s1)
    80003682:	ed9d                	bnez	a1,800036c0 <iput+0xe4>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003684:	0404a623          	sw	zero,76(s1)
  iupdate(ip);
    80003688:	8526                	mv	a0,s1
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	d7a080e7          	jalr	-646(ra) # 80003404 <iupdate>
    ip->type = 0;
    80003692:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003696:	8526                	mv	a0,s1
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	d6c080e7          	jalr	-660(ra) # 80003404 <iupdate>
    ip->valid = 0;
    800036a0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800036a4:	8552                	mv	a0,s4
    800036a6:	00001097          	auipc	ra,0x1
    800036aa:	d7a080e7          	jalr	-646(ra) # 80004420 <releasesleep>
    acquire(&icache.lock);
    800036ae:	0001e517          	auipc	a0,0x1e
    800036b2:	82250513          	addi	a0,a0,-2014 # 80020ed0 <icache>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	316080e7          	jalr	790(ra) # 800009cc <acquire>
    800036be:	b7a9                	j	80003608 <iput+0x2c>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800036c0:	4088                	lw	a0,0(s1)
    800036c2:	fffff097          	auipc	ra,0xfffff
    800036c6:	606080e7          	jalr	1542(ra) # 80002cc8 <bread>
    800036ca:	8aaa                	mv	s5,a0
    for(j = 0; j < NINDIRECT; j++){
    800036cc:	06050913          	addi	s2,a0,96
    800036d0:	46050993          	addi	s3,a0,1120
    800036d4:	a809                	j	800036e6 <iput+0x10a>
        bfree(ip->dev, a[j]);
    800036d6:	4088                	lw	a0,0(s1)
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	83a080e7          	jalr	-1990(ra) # 80002f12 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800036e0:	0911                	addi	s2,s2,4
    800036e2:	01390663          	beq	s2,s3,800036ee <iput+0x112>
      if(a[j])
    800036e6:	00092583          	lw	a1,0(s2)
    800036ea:	d9fd                	beqz	a1,800036e0 <iput+0x104>
    800036ec:	b7ed                	j	800036d6 <iput+0xfa>
    brelse(bp);
    800036ee:	8556                	mv	a0,s5
    800036f0:	fffff097          	auipc	ra,0xfffff
    800036f4:	70c080e7          	jalr	1804(ra) # 80002dfc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800036f8:	0804a583          	lw	a1,128(s1)
    800036fc:	4088                	lw	a0,0(s1)
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	814080e7          	jalr	-2028(ra) # 80002f12 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003706:	0804a023          	sw	zero,128(s1)
    8000370a:	bfad                	j	80003684 <iput+0xa8>

000000008000370c <iunlockput>:
{
    8000370c:	1101                	addi	sp,sp,-32
    8000370e:	ec06                	sd	ra,24(sp)
    80003710:	e822                	sd	s0,16(sp)
    80003712:	e426                	sd	s1,8(sp)
    80003714:	1000                	addi	s0,sp,32
    80003716:	84aa                	mv	s1,a0
  iunlock(ip);
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	e78080e7          	jalr	-392(ra) # 80003590 <iunlock>
  iput(ip);
    80003720:	8526                	mv	a0,s1
    80003722:	00000097          	auipc	ra,0x0
    80003726:	eba080e7          	jalr	-326(ra) # 800035dc <iput>
}
    8000372a:	60e2                	ld	ra,24(sp)
    8000372c:	6442                	ld	s0,16(sp)
    8000372e:	64a2                	ld	s1,8(sp)
    80003730:	6105                	addi	sp,sp,32
    80003732:	8082                	ret

0000000080003734 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003734:	1141                	addi	sp,sp,-16
    80003736:	e422                	sd	s0,8(sp)
    80003738:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000373a:	411c                	lw	a5,0(a0)
    8000373c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000373e:	415c                	lw	a5,4(a0)
    80003740:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003742:	04451783          	lh	a5,68(a0)
    80003746:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000374a:	04a51783          	lh	a5,74(a0)
    8000374e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003752:	04c56783          	lwu	a5,76(a0)
    80003756:	e99c                	sd	a5,16(a1)
}
    80003758:	6422                	ld	s0,8(sp)
    8000375a:	0141                	addi	sp,sp,16
    8000375c:	8082                	ret

000000008000375e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000375e:	457c                	lw	a5,76(a0)
    80003760:	0ed7e563          	bltu	a5,a3,8000384a <readi+0xec>
{
    80003764:	7159                	addi	sp,sp,-112
    80003766:	f486                	sd	ra,104(sp)
    80003768:	f0a2                	sd	s0,96(sp)
    8000376a:	eca6                	sd	s1,88(sp)
    8000376c:	e8ca                	sd	s2,80(sp)
    8000376e:	e4ce                	sd	s3,72(sp)
    80003770:	e0d2                	sd	s4,64(sp)
    80003772:	fc56                	sd	s5,56(sp)
    80003774:	f85a                	sd	s6,48(sp)
    80003776:	f45e                	sd	s7,40(sp)
    80003778:	f062                	sd	s8,32(sp)
    8000377a:	ec66                	sd	s9,24(sp)
    8000377c:	e86a                	sd	s10,16(sp)
    8000377e:	e46e                	sd	s11,8(sp)
    80003780:	1880                	addi	s0,sp,112
    80003782:	8baa                	mv	s7,a0
    80003784:	8c2e                	mv	s8,a1
    80003786:	8ab2                	mv	s5,a2
    80003788:	8936                	mv	s2,a3
    8000378a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000378c:	9f35                	addw	a4,a4,a3
    8000378e:	0cd76063          	bltu	a4,a3,8000384e <readi+0xf0>
    return -1;
  if(off + n > ip->size)
    80003792:	00e7f463          	bgeu	a5,a4,8000379a <readi+0x3c>
    n = ip->size - off;
    80003796:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000379a:	080b0763          	beqz	s6,80003828 <readi+0xca>
    8000379e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800037a0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800037a4:	5cfd                	li	s9,-1
    800037a6:	a82d                	j	800037e0 <readi+0x82>
    800037a8:	02099d93          	slli	s11,s3,0x20
    800037ac:	020ddd93          	srli	s11,s11,0x20
    800037b0:	06048613          	addi	a2,s1,96
    800037b4:	86ee                	mv	a3,s11
    800037b6:	963a                	add	a2,a2,a4
    800037b8:	85d6                	mv	a1,s5
    800037ba:	8562                	mv	a0,s8
    800037bc:	fffff097          	auipc	ra,0xfffff
    800037c0:	b54080e7          	jalr	-1196(ra) # 80002310 <either_copyout>
    800037c4:	05950d63          	beq	a0,s9,8000381e <readi+0xc0>
      brelse(bp);
      break;
    }
    brelse(bp);
    800037c8:	8526                	mv	a0,s1
    800037ca:	fffff097          	auipc	ra,0xfffff
    800037ce:	632080e7          	jalr	1586(ra) # 80002dfc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800037d2:	01498a3b          	addw	s4,s3,s4
    800037d6:	0129893b          	addw	s2,s3,s2
    800037da:	9aee                	add	s5,s5,s11
    800037dc:	056a7663          	bgeu	s4,s6,80003828 <readi+0xca>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800037e0:	000ba483          	lw	s1,0(s7)
    800037e4:	00a9559b          	srliw	a1,s2,0xa
    800037e8:	855e                	mv	a0,s7
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	8d6080e7          	jalr	-1834(ra) # 800030c0 <bmap>
    800037f2:	0005059b          	sext.w	a1,a0
    800037f6:	8526                	mv	a0,s1
    800037f8:	fffff097          	auipc	ra,0xfffff
    800037fc:	4d0080e7          	jalr	1232(ra) # 80002cc8 <bread>
    80003800:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003802:	3ff97713          	andi	a4,s2,1023
    80003806:	40ed07bb          	subw	a5,s10,a4
    8000380a:	414b06bb          	subw	a3,s6,s4
    8000380e:	89be                	mv	s3,a5
    80003810:	2781                	sext.w	a5,a5
    80003812:	0006861b          	sext.w	a2,a3
    80003816:	f8f679e3          	bgeu	a2,a5,800037a8 <readi+0x4a>
    8000381a:	89b6                	mv	s3,a3
    8000381c:	b771                	j	800037a8 <readi+0x4a>
      brelse(bp);
    8000381e:	8526                	mv	a0,s1
    80003820:	fffff097          	auipc	ra,0xfffff
    80003824:	5dc080e7          	jalr	1500(ra) # 80002dfc <brelse>
  }
  return n;
    80003828:	000b051b          	sext.w	a0,s6
}
    8000382c:	70a6                	ld	ra,104(sp)
    8000382e:	7406                	ld	s0,96(sp)
    80003830:	64e6                	ld	s1,88(sp)
    80003832:	6946                	ld	s2,80(sp)
    80003834:	69a6                	ld	s3,72(sp)
    80003836:	6a06                	ld	s4,64(sp)
    80003838:	7ae2                	ld	s5,56(sp)
    8000383a:	7b42                	ld	s6,48(sp)
    8000383c:	7ba2                	ld	s7,40(sp)
    8000383e:	7c02                	ld	s8,32(sp)
    80003840:	6ce2                	ld	s9,24(sp)
    80003842:	6d42                	ld	s10,16(sp)
    80003844:	6da2                	ld	s11,8(sp)
    80003846:	6165                	addi	sp,sp,112
    80003848:	8082                	ret
    return -1;
    8000384a:	557d                	li	a0,-1
}
    8000384c:	8082                	ret
    return -1;
    8000384e:	557d                	li	a0,-1
    80003850:	bff1                	j	8000382c <readi+0xce>

0000000080003852 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003852:	457c                	lw	a5,76(a0)
    80003854:	10d7e763          	bltu	a5,a3,80003962 <writei+0x110>
{
    80003858:	7159                	addi	sp,sp,-112
    8000385a:	f486                	sd	ra,104(sp)
    8000385c:	f0a2                	sd	s0,96(sp)
    8000385e:	eca6                	sd	s1,88(sp)
    80003860:	e8ca                	sd	s2,80(sp)
    80003862:	e4ce                	sd	s3,72(sp)
    80003864:	e0d2                	sd	s4,64(sp)
    80003866:	fc56                	sd	s5,56(sp)
    80003868:	f85a                	sd	s6,48(sp)
    8000386a:	f45e                	sd	s7,40(sp)
    8000386c:	f062                	sd	s8,32(sp)
    8000386e:	ec66                	sd	s9,24(sp)
    80003870:	e86a                	sd	s10,16(sp)
    80003872:	e46e                	sd	s11,8(sp)
    80003874:	1880                	addi	s0,sp,112
    80003876:	8baa                	mv	s7,a0
    80003878:	8c2e                	mv	s8,a1
    8000387a:	8ab2                	mv	s5,a2
    8000387c:	8936                	mv	s2,a3
    8000387e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003880:	00e687bb          	addw	a5,a3,a4
    80003884:	0ed7e163          	bltu	a5,a3,80003966 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003888:	00043737          	lui	a4,0x43
    8000388c:	0cf76f63          	bltu	a4,a5,8000396a <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003890:	0a0b0063          	beqz	s6,80003930 <writei+0xde>
    80003894:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003896:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000389a:	5cfd                	li	s9,-1
    8000389c:	a091                	j	800038e0 <writei+0x8e>
    8000389e:	02099d93          	slli	s11,s3,0x20
    800038a2:	020ddd93          	srli	s11,s11,0x20
    800038a6:	06048513          	addi	a0,s1,96
    800038aa:	86ee                	mv	a3,s11
    800038ac:	8656                	mv	a2,s5
    800038ae:	85e2                	mv	a1,s8
    800038b0:	953a                	add	a0,a0,a4
    800038b2:	fffff097          	auipc	ra,0xfffff
    800038b6:	ab4080e7          	jalr	-1356(ra) # 80002366 <either_copyin>
    800038ba:	07950263          	beq	a0,s9,8000391e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800038be:	8526                	mv	a0,s1
    800038c0:	00001097          	auipc	ra,0x1
    800038c4:	872080e7          	jalr	-1934(ra) # 80004132 <log_write>
    brelse(bp);
    800038c8:	8526                	mv	a0,s1
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	532080e7          	jalr	1330(ra) # 80002dfc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800038d2:	01498a3b          	addw	s4,s3,s4
    800038d6:	0129893b          	addw	s2,s3,s2
    800038da:	9aee                	add	s5,s5,s11
    800038dc:	056a7663          	bgeu	s4,s6,80003928 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800038e0:	000ba483          	lw	s1,0(s7)
    800038e4:	00a9559b          	srliw	a1,s2,0xa
    800038e8:	855e                	mv	a0,s7
    800038ea:	fffff097          	auipc	ra,0xfffff
    800038ee:	7d6080e7          	jalr	2006(ra) # 800030c0 <bmap>
    800038f2:	0005059b          	sext.w	a1,a0
    800038f6:	8526                	mv	a0,s1
    800038f8:	fffff097          	auipc	ra,0xfffff
    800038fc:	3d0080e7          	jalr	976(ra) # 80002cc8 <bread>
    80003900:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003902:	3ff97713          	andi	a4,s2,1023
    80003906:	40ed07bb          	subw	a5,s10,a4
    8000390a:	414b06bb          	subw	a3,s6,s4
    8000390e:	89be                	mv	s3,a5
    80003910:	2781                	sext.w	a5,a5
    80003912:	0006861b          	sext.w	a2,a3
    80003916:	f8f674e3          	bgeu	a2,a5,8000389e <writei+0x4c>
    8000391a:	89b6                	mv	s3,a3
    8000391c:	b749                	j	8000389e <writei+0x4c>
      brelse(bp);
    8000391e:	8526                	mv	a0,s1
    80003920:	fffff097          	auipc	ra,0xfffff
    80003924:	4dc080e7          	jalr	1244(ra) # 80002dfc <brelse>
  }

  if(n > 0 && off > ip->size){
    80003928:	04cba783          	lw	a5,76(s7)
    8000392c:	0327e363          	bltu	a5,s2,80003952 <writei+0x100>
    ip->size = off;
    iupdate(ip);
  }
  return n;
    80003930:	000b051b          	sext.w	a0,s6
}
    80003934:	70a6                	ld	ra,104(sp)
    80003936:	7406                	ld	s0,96(sp)
    80003938:	64e6                	ld	s1,88(sp)
    8000393a:	6946                	ld	s2,80(sp)
    8000393c:	69a6                	ld	s3,72(sp)
    8000393e:	6a06                	ld	s4,64(sp)
    80003940:	7ae2                	ld	s5,56(sp)
    80003942:	7b42                	ld	s6,48(sp)
    80003944:	7ba2                	ld	s7,40(sp)
    80003946:	7c02                	ld	s8,32(sp)
    80003948:	6ce2                	ld	s9,24(sp)
    8000394a:	6d42                	ld	s10,16(sp)
    8000394c:	6da2                	ld	s11,8(sp)
    8000394e:	6165                	addi	sp,sp,112
    80003950:	8082                	ret
    ip->size = off;
    80003952:	052ba623          	sw	s2,76(s7)
    iupdate(ip);
    80003956:	855e                	mv	a0,s7
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	aac080e7          	jalr	-1364(ra) # 80003404 <iupdate>
    80003960:	bfc1                	j	80003930 <writei+0xde>
    return -1;
    80003962:	557d                	li	a0,-1
}
    80003964:	8082                	ret
    return -1;
    80003966:	557d                	li	a0,-1
    80003968:	b7f1                	j	80003934 <writei+0xe2>
    return -1;
    8000396a:	557d                	li	a0,-1
    8000396c:	b7e1                	j	80003934 <writei+0xe2>

000000008000396e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000396e:	1141                	addi	sp,sp,-16
    80003970:	e406                	sd	ra,8(sp)
    80003972:	e022                	sd	s0,0(sp)
    80003974:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003976:	4639                	li	a2,14
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	1f4080e7          	jalr	500(ra) # 80000b6c <strncmp>
}
    80003980:	60a2                	ld	ra,8(sp)
    80003982:	6402                	ld	s0,0(sp)
    80003984:	0141                	addi	sp,sp,16
    80003986:	8082                	ret

0000000080003988 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003988:	7139                	addi	sp,sp,-64
    8000398a:	fc06                	sd	ra,56(sp)
    8000398c:	f822                	sd	s0,48(sp)
    8000398e:	f426                	sd	s1,40(sp)
    80003990:	f04a                	sd	s2,32(sp)
    80003992:	ec4e                	sd	s3,24(sp)
    80003994:	e852                	sd	s4,16(sp)
    80003996:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003998:	04451703          	lh	a4,68(a0)
    8000399c:	4785                	li	a5,1
    8000399e:	00f71a63          	bne	a4,a5,800039b2 <dirlookup+0x2a>
    800039a2:	892a                	mv	s2,a0
    800039a4:	89ae                	mv	s3,a1
    800039a6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800039a8:	457c                	lw	a5,76(a0)
    800039aa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800039ac:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039ae:	e79d                	bnez	a5,800039dc <dirlookup+0x54>
    800039b0:	a8a5                	j	80003a28 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800039b2:	00005517          	auipc	a0,0x5
    800039b6:	c1e50513          	addi	a0,a0,-994 # 800085d0 <userret+0x540>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	b94080e7          	jalr	-1132(ra) # 8000054e <panic>
      panic("dirlookup read");
    800039c2:	00005517          	auipc	a0,0x5
    800039c6:	c2650513          	addi	a0,a0,-986 # 800085e8 <userret+0x558>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	b84080e7          	jalr	-1148(ra) # 8000054e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039d2:	24c1                	addiw	s1,s1,16
    800039d4:	04c92783          	lw	a5,76(s2)
    800039d8:	04f4f763          	bgeu	s1,a5,80003a26 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800039dc:	4741                	li	a4,16
    800039de:	86a6                	mv	a3,s1
    800039e0:	fc040613          	addi	a2,s0,-64
    800039e4:	4581                	li	a1,0
    800039e6:	854a                	mv	a0,s2
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	d76080e7          	jalr	-650(ra) # 8000375e <readi>
    800039f0:	47c1                	li	a5,16
    800039f2:	fcf518e3          	bne	a0,a5,800039c2 <dirlookup+0x3a>
    if(de.inum == 0)
    800039f6:	fc045783          	lhu	a5,-64(s0)
    800039fa:	dfe1                	beqz	a5,800039d2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800039fc:	fc240593          	addi	a1,s0,-62
    80003a00:	854e                	mv	a0,s3
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	f6c080e7          	jalr	-148(ra) # 8000396e <namecmp>
    80003a0a:	f561                	bnez	a0,800039d2 <dirlookup+0x4a>
      if(poff)
    80003a0c:	000a0463          	beqz	s4,80003a14 <dirlookup+0x8c>
        *poff = off;
    80003a10:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003a14:	fc045583          	lhu	a1,-64(s0)
    80003a18:	00092503          	lw	a0,0(s2)
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	77e080e7          	jalr	1918(ra) # 8000319a <iget>
    80003a24:	a011                	j	80003a28 <dirlookup+0xa0>
  return 0;
    80003a26:	4501                	li	a0,0
}
    80003a28:	70e2                	ld	ra,56(sp)
    80003a2a:	7442                	ld	s0,48(sp)
    80003a2c:	74a2                	ld	s1,40(sp)
    80003a2e:	7902                	ld	s2,32(sp)
    80003a30:	69e2                	ld	s3,24(sp)
    80003a32:	6a42                	ld	s4,16(sp)
    80003a34:	6121                	addi	sp,sp,64
    80003a36:	8082                	ret

0000000080003a38 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003a38:	711d                	addi	sp,sp,-96
    80003a3a:	ec86                	sd	ra,88(sp)
    80003a3c:	e8a2                	sd	s0,80(sp)
    80003a3e:	e4a6                	sd	s1,72(sp)
    80003a40:	e0ca                	sd	s2,64(sp)
    80003a42:	fc4e                	sd	s3,56(sp)
    80003a44:	f852                	sd	s4,48(sp)
    80003a46:	f456                	sd	s5,40(sp)
    80003a48:	f05a                	sd	s6,32(sp)
    80003a4a:	ec5e                	sd	s7,24(sp)
    80003a4c:	e862                	sd	s8,16(sp)
    80003a4e:	e466                	sd	s9,8(sp)
    80003a50:	1080                	addi	s0,sp,96
    80003a52:	84aa                	mv	s1,a0
    80003a54:	8b2e                	mv	s6,a1
    80003a56:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003a58:	00054703          	lbu	a4,0(a0)
    80003a5c:	02f00793          	li	a5,47
    80003a60:	02f70363          	beq	a4,a5,80003a86 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003a64:	ffffe097          	auipc	ra,0xffffe
    80003a68:	e3a080e7          	jalr	-454(ra) # 8000189e <myproc>
    80003a6c:	15053503          	ld	a0,336(a0)
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	a20080e7          	jalr	-1504(ra) # 80003490 <idup>
    80003a78:	89aa                	mv	s3,a0
  while(*path == '/')
    80003a7a:	02f00913          	li	s2,47
  len = path - s;
    80003a7e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003a80:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003a82:	4c05                	li	s8,1
    80003a84:	a865                	j	80003b3c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003a86:	4585                	li	a1,1
    80003a88:	4501                	li	a0,0
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	710080e7          	jalr	1808(ra) # 8000319a <iget>
    80003a92:	89aa                	mv	s3,a0
    80003a94:	b7dd                	j	80003a7a <namex+0x42>
      iunlockput(ip);
    80003a96:	854e                	mv	a0,s3
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	c74080e7          	jalr	-908(ra) # 8000370c <iunlockput>
      return 0;
    80003aa0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003aa2:	854e                	mv	a0,s3
    80003aa4:	60e6                	ld	ra,88(sp)
    80003aa6:	6446                	ld	s0,80(sp)
    80003aa8:	64a6                	ld	s1,72(sp)
    80003aaa:	6906                	ld	s2,64(sp)
    80003aac:	79e2                	ld	s3,56(sp)
    80003aae:	7a42                	ld	s4,48(sp)
    80003ab0:	7aa2                	ld	s5,40(sp)
    80003ab2:	7b02                	ld	s6,32(sp)
    80003ab4:	6be2                	ld	s7,24(sp)
    80003ab6:	6c42                	ld	s8,16(sp)
    80003ab8:	6ca2                	ld	s9,8(sp)
    80003aba:	6125                	addi	sp,sp,96
    80003abc:	8082                	ret
      iunlock(ip);
    80003abe:	854e                	mv	a0,s3
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	ad0080e7          	jalr	-1328(ra) # 80003590 <iunlock>
      return ip;
    80003ac8:	bfe9                	j	80003aa2 <namex+0x6a>
      iunlockput(ip);
    80003aca:	854e                	mv	a0,s3
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	c40080e7          	jalr	-960(ra) # 8000370c <iunlockput>
      return 0;
    80003ad4:	89d2                	mv	s3,s4
    80003ad6:	b7f1                	j	80003aa2 <namex+0x6a>
  len = path - s;
    80003ad8:	40b48633          	sub	a2,s1,a1
    80003adc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ae0:	094cd463          	bge	s9,s4,80003b68 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ae4:	4639                	li	a2,14
    80003ae6:	8556                	mv	a0,s5
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	008080e7          	jalr	8(ra) # 80000af0 <memmove>
  while(*path == '/')
    80003af0:	0004c783          	lbu	a5,0(s1)
    80003af4:	01279763          	bne	a5,s2,80003b02 <namex+0xca>
    path++;
    80003af8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003afa:	0004c783          	lbu	a5,0(s1)
    80003afe:	ff278de3          	beq	a5,s2,80003af8 <namex+0xc0>
    ilock(ip);
    80003b02:	854e                	mv	a0,s3
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	9ca080e7          	jalr	-1590(ra) # 800034ce <ilock>
    if(ip->type != T_DIR){
    80003b0c:	04499783          	lh	a5,68(s3)
    80003b10:	f98793e3          	bne	a5,s8,80003a96 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003b14:	000b0563          	beqz	s6,80003b1e <namex+0xe6>
    80003b18:	0004c783          	lbu	a5,0(s1)
    80003b1c:	d3cd                	beqz	a5,80003abe <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003b1e:	865e                	mv	a2,s7
    80003b20:	85d6                	mv	a1,s5
    80003b22:	854e                	mv	a0,s3
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	e64080e7          	jalr	-412(ra) # 80003988 <dirlookup>
    80003b2c:	8a2a                	mv	s4,a0
    80003b2e:	dd51                	beqz	a0,80003aca <namex+0x92>
    iunlockput(ip);
    80003b30:	854e                	mv	a0,s3
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	bda080e7          	jalr	-1062(ra) # 8000370c <iunlockput>
    ip = next;
    80003b3a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003b3c:	0004c783          	lbu	a5,0(s1)
    80003b40:	05279763          	bne	a5,s2,80003b8e <namex+0x156>
    path++;
    80003b44:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003b46:	0004c783          	lbu	a5,0(s1)
    80003b4a:	ff278de3          	beq	a5,s2,80003b44 <namex+0x10c>
  if(*path == 0)
    80003b4e:	c79d                	beqz	a5,80003b7c <namex+0x144>
    path++;
    80003b50:	85a6                	mv	a1,s1
  len = path - s;
    80003b52:	8a5e                	mv	s4,s7
    80003b54:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003b56:	01278963          	beq	a5,s2,80003b68 <namex+0x130>
    80003b5a:	dfbd                	beqz	a5,80003ad8 <namex+0xa0>
    path++;
    80003b5c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003b5e:	0004c783          	lbu	a5,0(s1)
    80003b62:	ff279ce3          	bne	a5,s2,80003b5a <namex+0x122>
    80003b66:	bf8d                	j	80003ad8 <namex+0xa0>
    memmove(name, s, len);
    80003b68:	2601                	sext.w	a2,a2
    80003b6a:	8556                	mv	a0,s5
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	f84080e7          	jalr	-124(ra) # 80000af0 <memmove>
    name[len] = 0;
    80003b74:	9a56                	add	s4,s4,s5
    80003b76:	000a0023          	sb	zero,0(s4)
    80003b7a:	bf9d                	j	80003af0 <namex+0xb8>
  if(nameiparent){
    80003b7c:	f20b03e3          	beqz	s6,80003aa2 <namex+0x6a>
    iput(ip);
    80003b80:	854e                	mv	a0,s3
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	a5a080e7          	jalr	-1446(ra) # 800035dc <iput>
    return 0;
    80003b8a:	4981                	li	s3,0
    80003b8c:	bf19                	j	80003aa2 <namex+0x6a>
  if(*path == 0)
    80003b8e:	d7fd                	beqz	a5,80003b7c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003b90:	0004c783          	lbu	a5,0(s1)
    80003b94:	85a6                	mv	a1,s1
    80003b96:	b7d1                	j	80003b5a <namex+0x122>

0000000080003b98 <dirlink>:
{
    80003b98:	7139                	addi	sp,sp,-64
    80003b9a:	fc06                	sd	ra,56(sp)
    80003b9c:	f822                	sd	s0,48(sp)
    80003b9e:	f426                	sd	s1,40(sp)
    80003ba0:	f04a                	sd	s2,32(sp)
    80003ba2:	ec4e                	sd	s3,24(sp)
    80003ba4:	e852                	sd	s4,16(sp)
    80003ba6:	0080                	addi	s0,sp,64
    80003ba8:	892a                	mv	s2,a0
    80003baa:	8a2e                	mv	s4,a1
    80003bac:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003bae:	4601                	li	a2,0
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	dd8080e7          	jalr	-552(ra) # 80003988 <dirlookup>
    80003bb8:	e93d                	bnez	a0,80003c2e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bba:	04c92483          	lw	s1,76(s2)
    80003bbe:	c49d                	beqz	s1,80003bec <dirlink+0x54>
    80003bc0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bc2:	4741                	li	a4,16
    80003bc4:	86a6                	mv	a3,s1
    80003bc6:	fc040613          	addi	a2,s0,-64
    80003bca:	4581                	li	a1,0
    80003bcc:	854a                	mv	a0,s2
    80003bce:	00000097          	auipc	ra,0x0
    80003bd2:	b90080e7          	jalr	-1136(ra) # 8000375e <readi>
    80003bd6:	47c1                	li	a5,16
    80003bd8:	06f51163          	bne	a0,a5,80003c3a <dirlink+0xa2>
    if(de.inum == 0)
    80003bdc:	fc045783          	lhu	a5,-64(s0)
    80003be0:	c791                	beqz	a5,80003bec <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003be2:	24c1                	addiw	s1,s1,16
    80003be4:	04c92783          	lw	a5,76(s2)
    80003be8:	fcf4ede3          	bltu	s1,a5,80003bc2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003bec:	4639                	li	a2,14
    80003bee:	85d2                	mv	a1,s4
    80003bf0:	fc240513          	addi	a0,s0,-62
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	fb4080e7          	jalr	-76(ra) # 80000ba8 <strncpy>
  de.inum = inum;
    80003bfc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c00:	4741                	li	a4,16
    80003c02:	86a6                	mv	a3,s1
    80003c04:	fc040613          	addi	a2,s0,-64
    80003c08:	4581                	li	a1,0
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	c46080e7          	jalr	-954(ra) # 80003852 <writei>
    80003c14:	872a                	mv	a4,a0
    80003c16:	47c1                	li	a5,16
  return 0;
    80003c18:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c1a:	02f71863          	bne	a4,a5,80003c4a <dirlink+0xb2>
}
    80003c1e:	70e2                	ld	ra,56(sp)
    80003c20:	7442                	ld	s0,48(sp)
    80003c22:	74a2                	ld	s1,40(sp)
    80003c24:	7902                	ld	s2,32(sp)
    80003c26:	69e2                	ld	s3,24(sp)
    80003c28:	6a42                	ld	s4,16(sp)
    80003c2a:	6121                	addi	sp,sp,64
    80003c2c:	8082                	ret
    iput(ip);
    80003c2e:	00000097          	auipc	ra,0x0
    80003c32:	9ae080e7          	jalr	-1618(ra) # 800035dc <iput>
    return -1;
    80003c36:	557d                	li	a0,-1
    80003c38:	b7dd                	j	80003c1e <dirlink+0x86>
      panic("dirlink read");
    80003c3a:	00005517          	auipc	a0,0x5
    80003c3e:	9be50513          	addi	a0,a0,-1602 # 800085f8 <userret+0x568>
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	90c080e7          	jalr	-1780(ra) # 8000054e <panic>
    panic("dirlink");
    80003c4a:	00005517          	auipc	a0,0x5
    80003c4e:	b5e50513          	addi	a0,a0,-1186 # 800087a8 <userret+0x718>
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	8fc080e7          	jalr	-1796(ra) # 8000054e <panic>

0000000080003c5a <namei>:

struct inode*
namei(char *path)
{
    80003c5a:	1101                	addi	sp,sp,-32
    80003c5c:	ec06                	sd	ra,24(sp)
    80003c5e:	e822                	sd	s0,16(sp)
    80003c60:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003c62:	fe040613          	addi	a2,s0,-32
    80003c66:	4581                	li	a1,0
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	dd0080e7          	jalr	-560(ra) # 80003a38 <namex>
}
    80003c70:	60e2                	ld	ra,24(sp)
    80003c72:	6442                	ld	s0,16(sp)
    80003c74:	6105                	addi	sp,sp,32
    80003c76:	8082                	ret

0000000080003c78 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003c78:	1141                	addi	sp,sp,-16
    80003c7a:	e406                	sd	ra,8(sp)
    80003c7c:	e022                	sd	s0,0(sp)
    80003c7e:	0800                	addi	s0,sp,16
    80003c80:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003c82:	4585                	li	a1,1
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	db4080e7          	jalr	-588(ra) # 80003a38 <namex>
}
    80003c8c:	60a2                	ld	ra,8(sp)
    80003c8e:	6402                	ld	s0,0(sp)
    80003c90:	0141                	addi	sp,sp,16
    80003c92:	8082                	ret

0000000080003c94 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(int dev)
{
    80003c94:	7179                	addi	sp,sp,-48
    80003c96:	f406                	sd	ra,40(sp)
    80003c98:	f022                	sd	s0,32(sp)
    80003c9a:	ec26                	sd	s1,24(sp)
    80003c9c:	e84a                	sd	s2,16(sp)
    80003c9e:	e44e                	sd	s3,8(sp)
    80003ca0:	1800                	addi	s0,sp,48
    80003ca2:	84aa                	mv	s1,a0
  struct buf *buf = bread(dev, log[dev].start);
    80003ca4:	0a800993          	li	s3,168
    80003ca8:	033507b3          	mul	a5,a0,s3
    80003cac:	0001f997          	auipc	s3,0x1f
    80003cb0:	ccc98993          	addi	s3,s3,-820 # 80022978 <log>
    80003cb4:	99be                	add	s3,s3,a5
    80003cb6:	0189a583          	lw	a1,24(s3)
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	00e080e7          	jalr	14(ra) # 80002cc8 <bread>
    80003cc2:	892a                	mv	s2,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log[dev].lh.n;
    80003cc4:	02c9a783          	lw	a5,44(s3)
    80003cc8:	d13c                	sw	a5,96(a0)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003cca:	02c9a783          	lw	a5,44(s3)
    80003cce:	02f05763          	blez	a5,80003cfc <write_head+0x68>
    80003cd2:	0a800793          	li	a5,168
    80003cd6:	02f487b3          	mul	a5,s1,a5
    80003cda:	0001f717          	auipc	a4,0x1f
    80003cde:	cce70713          	addi	a4,a4,-818 # 800229a8 <log+0x30>
    80003ce2:	97ba                	add	a5,a5,a4
    80003ce4:	06450693          	addi	a3,a0,100
    80003ce8:	4701                	li	a4,0
    80003cea:	85ce                	mv	a1,s3
    hb->block[i] = log[dev].lh.block[i];
    80003cec:	4390                	lw	a2,0(a5)
    80003cee:	c290                	sw	a2,0(a3)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003cf0:	2705                	addiw	a4,a4,1
    80003cf2:	0791                	addi	a5,a5,4
    80003cf4:	0691                	addi	a3,a3,4
    80003cf6:	55d0                	lw	a2,44(a1)
    80003cf8:	fec74ae3          	blt	a4,a2,80003cec <write_head+0x58>
  }
  bwrite(buf);
    80003cfc:	854a                	mv	a0,s2
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	0be080e7          	jalr	190(ra) # 80002dbc <bwrite>
  brelse(buf);
    80003d06:	854a                	mv	a0,s2
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	0f4080e7          	jalr	244(ra) # 80002dfc <brelse>
}
    80003d10:	70a2                	ld	ra,40(sp)
    80003d12:	7402                	ld	s0,32(sp)
    80003d14:	64e2                	ld	s1,24(sp)
    80003d16:	6942                	ld	s2,16(sp)
    80003d18:	69a2                	ld	s3,8(sp)
    80003d1a:	6145                	addi	sp,sp,48
    80003d1c:	8082                	ret

0000000080003d1e <write_log>:
static void
write_log(int dev)
{
  int tail;

  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003d1e:	0a800793          	li	a5,168
    80003d22:	02f50733          	mul	a4,a0,a5
    80003d26:	0001f797          	auipc	a5,0x1f
    80003d2a:	c5278793          	addi	a5,a5,-942 # 80022978 <log>
    80003d2e:	97ba                	add	a5,a5,a4
    80003d30:	57dc                	lw	a5,44(a5)
    80003d32:	0af05663          	blez	a5,80003dde <write_log+0xc0>
{
    80003d36:	7139                	addi	sp,sp,-64
    80003d38:	fc06                	sd	ra,56(sp)
    80003d3a:	f822                	sd	s0,48(sp)
    80003d3c:	f426                	sd	s1,40(sp)
    80003d3e:	f04a                	sd	s2,32(sp)
    80003d40:	ec4e                	sd	s3,24(sp)
    80003d42:	e852                	sd	s4,16(sp)
    80003d44:	e456                	sd	s5,8(sp)
    80003d46:	e05a                	sd	s6,0(sp)
    80003d48:	0080                	addi	s0,sp,64
    80003d4a:	0001f797          	auipc	a5,0x1f
    80003d4e:	c5e78793          	addi	a5,a5,-930 # 800229a8 <log+0x30>
    80003d52:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003d56:	4981                	li	s3,0
    struct buf *to = bread(dev, log[dev].start+tail+1); // log block
    80003d58:	00050b1b          	sext.w	s6,a0
    80003d5c:	0001fa97          	auipc	s5,0x1f
    80003d60:	c1ca8a93          	addi	s5,s5,-996 # 80022978 <log>
    80003d64:	9aba                	add	s5,s5,a4
    80003d66:	018aa583          	lw	a1,24(s5)
    80003d6a:	013585bb          	addw	a1,a1,s3
    80003d6e:	2585                	addiw	a1,a1,1
    80003d70:	855a                	mv	a0,s6
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	f56080e7          	jalr	-170(ra) # 80002cc8 <bread>
    80003d7a:	84aa                	mv	s1,a0
    struct buf *from = bread(dev, log[dev].lh.block[tail]); // cache block
    80003d7c:	000a2583          	lw	a1,0(s4)
    80003d80:	855a                	mv	a0,s6
    80003d82:	fffff097          	auipc	ra,0xfffff
    80003d86:	f46080e7          	jalr	-186(ra) # 80002cc8 <bread>
    80003d8a:	892a                	mv	s2,a0
    memmove(to->data, from->data, BSIZE);
    80003d8c:	40000613          	li	a2,1024
    80003d90:	06050593          	addi	a1,a0,96
    80003d94:	06048513          	addi	a0,s1,96
    80003d98:	ffffd097          	auipc	ra,0xffffd
    80003d9c:	d58080e7          	jalr	-680(ra) # 80000af0 <memmove>
    bwrite(to);  // write the log
    80003da0:	8526                	mv	a0,s1
    80003da2:	fffff097          	auipc	ra,0xfffff
    80003da6:	01a080e7          	jalr	26(ra) # 80002dbc <bwrite>
    brelse(from);
    80003daa:	854a                	mv	a0,s2
    80003dac:	fffff097          	auipc	ra,0xfffff
    80003db0:	050080e7          	jalr	80(ra) # 80002dfc <brelse>
    brelse(to);
    80003db4:	8526                	mv	a0,s1
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	046080e7          	jalr	70(ra) # 80002dfc <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003dbe:	2985                	addiw	s3,s3,1
    80003dc0:	0a11                	addi	s4,s4,4
    80003dc2:	02caa783          	lw	a5,44(s5)
    80003dc6:	faf9c0e3          	blt	s3,a5,80003d66 <write_log+0x48>
  }
}
    80003dca:	70e2                	ld	ra,56(sp)
    80003dcc:	7442                	ld	s0,48(sp)
    80003dce:	74a2                	ld	s1,40(sp)
    80003dd0:	7902                	ld	s2,32(sp)
    80003dd2:	69e2                	ld	s3,24(sp)
    80003dd4:	6a42                	ld	s4,16(sp)
    80003dd6:	6aa2                	ld	s5,8(sp)
    80003dd8:	6b02                	ld	s6,0(sp)
    80003dda:	6121                	addi	sp,sp,64
    80003ddc:	8082                	ret
    80003dde:	8082                	ret

0000000080003de0 <install_trans>:
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003de0:	0a800793          	li	a5,168
    80003de4:	02f50733          	mul	a4,a0,a5
    80003de8:	0001f797          	auipc	a5,0x1f
    80003dec:	b9078793          	addi	a5,a5,-1136 # 80022978 <log>
    80003df0:	97ba                	add	a5,a5,a4
    80003df2:	57dc                	lw	a5,44(a5)
    80003df4:	0af05b63          	blez	a5,80003eaa <install_trans+0xca>
{
    80003df8:	7139                	addi	sp,sp,-64
    80003dfa:	fc06                	sd	ra,56(sp)
    80003dfc:	f822                	sd	s0,48(sp)
    80003dfe:	f426                	sd	s1,40(sp)
    80003e00:	f04a                	sd	s2,32(sp)
    80003e02:	ec4e                	sd	s3,24(sp)
    80003e04:	e852                	sd	s4,16(sp)
    80003e06:	e456                	sd	s5,8(sp)
    80003e08:	e05a                	sd	s6,0(sp)
    80003e0a:	0080                	addi	s0,sp,64
    80003e0c:	0001f797          	auipc	a5,0x1f
    80003e10:	b9c78793          	addi	a5,a5,-1124 # 800229a8 <log+0x30>
    80003e14:	00f70a33          	add	s4,a4,a5
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003e18:	4981                	li	s3,0
    struct buf *lbuf = bread(dev, log[dev].start+tail+1); // read log block
    80003e1a:	00050b1b          	sext.w	s6,a0
    80003e1e:	0001fa97          	auipc	s5,0x1f
    80003e22:	b5aa8a93          	addi	s5,s5,-1190 # 80022978 <log>
    80003e26:	9aba                	add	s5,s5,a4
    80003e28:	018aa583          	lw	a1,24(s5)
    80003e2c:	013585bb          	addw	a1,a1,s3
    80003e30:	2585                	addiw	a1,a1,1
    80003e32:	855a                	mv	a0,s6
    80003e34:	fffff097          	auipc	ra,0xfffff
    80003e38:	e94080e7          	jalr	-364(ra) # 80002cc8 <bread>
    80003e3c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(dev, log[dev].lh.block[tail]); // read dst
    80003e3e:	000a2583          	lw	a1,0(s4)
    80003e42:	855a                	mv	a0,s6
    80003e44:	fffff097          	auipc	ra,0xfffff
    80003e48:	e84080e7          	jalr	-380(ra) # 80002cc8 <bread>
    80003e4c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003e4e:	40000613          	li	a2,1024
    80003e52:	06090593          	addi	a1,s2,96
    80003e56:	06050513          	addi	a0,a0,96
    80003e5a:	ffffd097          	auipc	ra,0xffffd
    80003e5e:	c96080e7          	jalr	-874(ra) # 80000af0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003e62:	8526                	mv	a0,s1
    80003e64:	fffff097          	auipc	ra,0xfffff
    80003e68:	f58080e7          	jalr	-168(ra) # 80002dbc <bwrite>
    bunpin(dbuf);
    80003e6c:	8526                	mv	a0,s1
    80003e6e:	fffff097          	auipc	ra,0xfffff
    80003e72:	068080e7          	jalr	104(ra) # 80002ed6 <bunpin>
    brelse(lbuf);
    80003e76:	854a                	mv	a0,s2
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	f84080e7          	jalr	-124(ra) # 80002dfc <brelse>
    brelse(dbuf);
    80003e80:	8526                	mv	a0,s1
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	f7a080e7          	jalr	-134(ra) # 80002dfc <brelse>
  for (tail = 0; tail < log[dev].lh.n; tail++) {
    80003e8a:	2985                	addiw	s3,s3,1
    80003e8c:	0a11                	addi	s4,s4,4
    80003e8e:	02caa783          	lw	a5,44(s5)
    80003e92:	f8f9cbe3          	blt	s3,a5,80003e28 <install_trans+0x48>
}
    80003e96:	70e2                	ld	ra,56(sp)
    80003e98:	7442                	ld	s0,48(sp)
    80003e9a:	74a2                	ld	s1,40(sp)
    80003e9c:	7902                	ld	s2,32(sp)
    80003e9e:	69e2                	ld	s3,24(sp)
    80003ea0:	6a42                	ld	s4,16(sp)
    80003ea2:	6aa2                	ld	s5,8(sp)
    80003ea4:	6b02                	ld	s6,0(sp)
    80003ea6:	6121                	addi	sp,sp,64
    80003ea8:	8082                	ret
    80003eaa:	8082                	ret

0000000080003eac <initlog>:
{
    80003eac:	7179                	addi	sp,sp,-48
    80003eae:	f406                	sd	ra,40(sp)
    80003eb0:	f022                	sd	s0,32(sp)
    80003eb2:	ec26                	sd	s1,24(sp)
    80003eb4:	e84a                	sd	s2,16(sp)
    80003eb6:	e44e                	sd	s3,8(sp)
    80003eb8:	e052                	sd	s4,0(sp)
    80003eba:	1800                	addi	s0,sp,48
    80003ebc:	84aa                	mv	s1,a0
    80003ebe:	8a2e                	mv	s4,a1
  initlock(&log[dev].lock, "log");
    80003ec0:	0a800713          	li	a4,168
    80003ec4:	02e509b3          	mul	s3,a0,a4
    80003ec8:	0001f917          	auipc	s2,0x1f
    80003ecc:	ab090913          	addi	s2,s2,-1360 # 80022978 <log>
    80003ed0:	994e                	add	s2,s2,s3
    80003ed2:	00004597          	auipc	a1,0x4
    80003ed6:	73658593          	addi	a1,a1,1846 # 80008608 <userret+0x578>
    80003eda:	854a                	mv	a0,s2
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	9de080e7          	jalr	-1570(ra) # 800008ba <initlock>
  log[dev].start = sb->logstart;
    80003ee4:	014a2583          	lw	a1,20(s4)
    80003ee8:	00b92c23          	sw	a1,24(s2)
  log[dev].size = sb->nlog;
    80003eec:	010a2783          	lw	a5,16(s4)
    80003ef0:	00f92e23          	sw	a5,28(s2)
  log[dev].dev = dev;
    80003ef4:	02992423          	sw	s1,40(s2)
  struct buf *buf = bread(dev, log[dev].start);
    80003ef8:	8526                	mv	a0,s1
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	dce080e7          	jalr	-562(ra) # 80002cc8 <bread>
  log[dev].lh.n = lh->n;
    80003f02:	513c                	lw	a5,96(a0)
    80003f04:	02f92623          	sw	a5,44(s2)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003f08:	02f05663          	blez	a5,80003f34 <initlog+0x88>
    80003f0c:	06450693          	addi	a3,a0,100
    80003f10:	0001f717          	auipc	a4,0x1f
    80003f14:	a9870713          	addi	a4,a4,-1384 # 800229a8 <log+0x30>
    80003f18:	974e                	add	a4,a4,s3
    80003f1a:	37fd                	addiw	a5,a5,-1
    80003f1c:	1782                	slli	a5,a5,0x20
    80003f1e:	9381                	srli	a5,a5,0x20
    80003f20:	078a                	slli	a5,a5,0x2
    80003f22:	06850613          	addi	a2,a0,104
    80003f26:	97b2                	add	a5,a5,a2
    log[dev].lh.block[i] = lh->block[i];
    80003f28:	4290                	lw	a2,0(a3)
    80003f2a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log[dev].lh.n; i++) {
    80003f2c:	0691                	addi	a3,a3,4
    80003f2e:	0711                	addi	a4,a4,4
    80003f30:	fef69ce3          	bne	a3,a5,80003f28 <initlog+0x7c>
  brelse(buf);
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	ec8080e7          	jalr	-312(ra) # 80002dfc <brelse>
  install_trans(dev); // if committed, copy from log to disk
    80003f3c:	8526                	mv	a0,s1
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	ea2080e7          	jalr	-350(ra) # 80003de0 <install_trans>
  log[dev].lh.n = 0;
    80003f46:	0a800793          	li	a5,168
    80003f4a:	02f48733          	mul	a4,s1,a5
    80003f4e:	0001f797          	auipc	a5,0x1f
    80003f52:	a2a78793          	addi	a5,a5,-1494 # 80022978 <log>
    80003f56:	97ba                	add	a5,a5,a4
    80003f58:	0207a623          	sw	zero,44(a5)
  write_head(dev); // clear the log
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	d36080e7          	jalr	-714(ra) # 80003c94 <write_head>
}
    80003f66:	70a2                	ld	ra,40(sp)
    80003f68:	7402                	ld	s0,32(sp)
    80003f6a:	64e2                	ld	s1,24(sp)
    80003f6c:	6942                	ld	s2,16(sp)
    80003f6e:	69a2                	ld	s3,8(sp)
    80003f70:	6a02                	ld	s4,0(sp)
    80003f72:	6145                	addi	sp,sp,48
    80003f74:	8082                	ret

0000000080003f76 <begin_op>:
{
    80003f76:	7139                	addi	sp,sp,-64
    80003f78:	fc06                	sd	ra,56(sp)
    80003f7a:	f822                	sd	s0,48(sp)
    80003f7c:	f426                	sd	s1,40(sp)
    80003f7e:	f04a                	sd	s2,32(sp)
    80003f80:	ec4e                	sd	s3,24(sp)
    80003f82:	e852                	sd	s4,16(sp)
    80003f84:	e456                	sd	s5,8(sp)
    80003f86:	0080                	addi	s0,sp,64
    80003f88:	8aaa                	mv	s5,a0
  acquire(&log[dev].lock);
    80003f8a:	0a800913          	li	s2,168
    80003f8e:	032507b3          	mul	a5,a0,s2
    80003f92:	0001f917          	auipc	s2,0x1f
    80003f96:	9e690913          	addi	s2,s2,-1562 # 80022978 <log>
    80003f9a:	993e                	add	s2,s2,a5
    80003f9c:	854a                	mv	a0,s2
    80003f9e:	ffffd097          	auipc	ra,0xffffd
    80003fa2:	a2e080e7          	jalr	-1490(ra) # 800009cc <acquire>
    if(log[dev].committing){
    80003fa6:	0001f997          	auipc	s3,0x1f
    80003faa:	9d298993          	addi	s3,s3,-1582 # 80022978 <log>
    80003fae:	84ca                	mv	s1,s2
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fb0:	4a79                	li	s4,30
    80003fb2:	a039                	j	80003fc0 <begin_op+0x4a>
      sleep(&log, &log[dev].lock);
    80003fb4:	85ca                	mv	a1,s2
    80003fb6:	854e                	mv	a0,s3
    80003fb8:	ffffe097          	auipc	ra,0xffffe
    80003fbc:	0f8080e7          	jalr	248(ra) # 800020b0 <sleep>
    if(log[dev].committing){
    80003fc0:	50dc                	lw	a5,36(s1)
    80003fc2:	fbed                	bnez	a5,80003fb4 <begin_op+0x3e>
    } else if(log[dev].lh.n + (log[dev].outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fc4:	509c                	lw	a5,32(s1)
    80003fc6:	0017871b          	addiw	a4,a5,1
    80003fca:	0007069b          	sext.w	a3,a4
    80003fce:	0027179b          	slliw	a5,a4,0x2
    80003fd2:	9fb9                	addw	a5,a5,a4
    80003fd4:	0017979b          	slliw	a5,a5,0x1
    80003fd8:	54d8                	lw	a4,44(s1)
    80003fda:	9fb9                	addw	a5,a5,a4
    80003fdc:	00fa5963          	bge	s4,a5,80003fee <begin_op+0x78>
      sleep(&log, &log[dev].lock);
    80003fe0:	85ca                	mv	a1,s2
    80003fe2:	854e                	mv	a0,s3
    80003fe4:	ffffe097          	auipc	ra,0xffffe
    80003fe8:	0cc080e7          	jalr	204(ra) # 800020b0 <sleep>
    80003fec:	bfd1                	j	80003fc0 <begin_op+0x4a>
      log[dev].outstanding += 1;
    80003fee:	0a800513          	li	a0,168
    80003ff2:	02aa8ab3          	mul	s5,s5,a0
    80003ff6:	0001f797          	auipc	a5,0x1f
    80003ffa:	98278793          	addi	a5,a5,-1662 # 80022978 <log>
    80003ffe:	9abe                	add	s5,s5,a5
    80004000:	02daa023          	sw	a3,32(s5)
      release(&log[dev].lock);
    80004004:	854a                	mv	a0,s2
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	a2e080e7          	jalr	-1490(ra) # 80000a34 <release>
}
    8000400e:	70e2                	ld	ra,56(sp)
    80004010:	7442                	ld	s0,48(sp)
    80004012:	74a2                	ld	s1,40(sp)
    80004014:	7902                	ld	s2,32(sp)
    80004016:	69e2                	ld	s3,24(sp)
    80004018:	6a42                	ld	s4,16(sp)
    8000401a:	6aa2                	ld	s5,8(sp)
    8000401c:	6121                	addi	sp,sp,64
    8000401e:	8082                	ret

0000000080004020 <end_op>:
{
    80004020:	7179                	addi	sp,sp,-48
    80004022:	f406                	sd	ra,40(sp)
    80004024:	f022                	sd	s0,32(sp)
    80004026:	ec26                	sd	s1,24(sp)
    80004028:	e84a                	sd	s2,16(sp)
    8000402a:	e44e                	sd	s3,8(sp)
    8000402c:	1800                	addi	s0,sp,48
    8000402e:	892a                	mv	s2,a0
  acquire(&log[dev].lock);
    80004030:	0a800493          	li	s1,168
    80004034:	029507b3          	mul	a5,a0,s1
    80004038:	0001f497          	auipc	s1,0x1f
    8000403c:	94048493          	addi	s1,s1,-1728 # 80022978 <log>
    80004040:	94be                	add	s1,s1,a5
    80004042:	8526                	mv	a0,s1
    80004044:	ffffd097          	auipc	ra,0xffffd
    80004048:	988080e7          	jalr	-1656(ra) # 800009cc <acquire>
  log[dev].outstanding -= 1;
    8000404c:	509c                	lw	a5,32(s1)
    8000404e:	37fd                	addiw	a5,a5,-1
    80004050:	0007871b          	sext.w	a4,a5
    80004054:	d09c                	sw	a5,32(s1)
  if(log[dev].committing)
    80004056:	50dc                	lw	a5,36(s1)
    80004058:	e3ad                	bnez	a5,800040ba <end_op+0x9a>
  if(log[dev].outstanding == 0){
    8000405a:	eb25                	bnez	a4,800040ca <end_op+0xaa>
    log[dev].committing = 1;
    8000405c:	0a800993          	li	s3,168
    80004060:	033907b3          	mul	a5,s2,s3
    80004064:	0001f997          	auipc	s3,0x1f
    80004068:	91498993          	addi	s3,s3,-1772 # 80022978 <log>
    8000406c:	99be                	add	s3,s3,a5
    8000406e:	4785                	li	a5,1
    80004070:	02f9a223          	sw	a5,36(s3)
  release(&log[dev].lock);
    80004074:	8526                	mv	a0,s1
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	9be080e7          	jalr	-1602(ra) # 80000a34 <release>

static void
commit(int dev)
{
  if (log[dev].lh.n > 0) {
    8000407e:	02c9a783          	lw	a5,44(s3)
    80004082:	06f04863          	bgtz	a5,800040f2 <end_op+0xd2>
    acquire(&log[dev].lock);
    80004086:	8526                	mv	a0,s1
    80004088:	ffffd097          	auipc	ra,0xffffd
    8000408c:	944080e7          	jalr	-1724(ra) # 800009cc <acquire>
    log[dev].committing = 0;
    80004090:	0001f517          	auipc	a0,0x1f
    80004094:	8e850513          	addi	a0,a0,-1816 # 80022978 <log>
    80004098:	0a800793          	li	a5,168
    8000409c:	02f90933          	mul	s2,s2,a5
    800040a0:	992a                	add	s2,s2,a0
    800040a2:	02092223          	sw	zero,36(s2)
    wakeup(&log);
    800040a6:	ffffe097          	auipc	ra,0xffffe
    800040aa:	190080e7          	jalr	400(ra) # 80002236 <wakeup>
    release(&log[dev].lock);
    800040ae:	8526                	mv	a0,s1
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	984080e7          	jalr	-1660(ra) # 80000a34 <release>
}
    800040b8:	a035                	j	800040e4 <end_op+0xc4>
    panic("log[dev].committing");
    800040ba:	00004517          	auipc	a0,0x4
    800040be:	55650513          	addi	a0,a0,1366 # 80008610 <userret+0x580>
    800040c2:	ffffc097          	auipc	ra,0xffffc
    800040c6:	48c080e7          	jalr	1164(ra) # 8000054e <panic>
    wakeup(&log);
    800040ca:	0001f517          	auipc	a0,0x1f
    800040ce:	8ae50513          	addi	a0,a0,-1874 # 80022978 <log>
    800040d2:	ffffe097          	auipc	ra,0xffffe
    800040d6:	164080e7          	jalr	356(ra) # 80002236 <wakeup>
  release(&log[dev].lock);
    800040da:	8526                	mv	a0,s1
    800040dc:	ffffd097          	auipc	ra,0xffffd
    800040e0:	958080e7          	jalr	-1704(ra) # 80000a34 <release>
}
    800040e4:	70a2                	ld	ra,40(sp)
    800040e6:	7402                	ld	s0,32(sp)
    800040e8:	64e2                	ld	s1,24(sp)
    800040ea:	6942                	ld	s2,16(sp)
    800040ec:	69a2                	ld	s3,8(sp)
    800040ee:	6145                	addi	sp,sp,48
    800040f0:	8082                	ret
    write_log(dev);     // Write modified blocks from cache to log
    800040f2:	854a                	mv	a0,s2
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	c2a080e7          	jalr	-982(ra) # 80003d1e <write_log>
    write_head(dev);    // Write header to disk -- the real commit
    800040fc:	854a                	mv	a0,s2
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	b96080e7          	jalr	-1130(ra) # 80003c94 <write_head>
    install_trans(dev); // Now install writes to home locations
    80004106:	854a                	mv	a0,s2
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	cd8080e7          	jalr	-808(ra) # 80003de0 <install_trans>
    log[dev].lh.n = 0;
    80004110:	0a800793          	li	a5,168
    80004114:	02f90733          	mul	a4,s2,a5
    80004118:	0001f797          	auipc	a5,0x1f
    8000411c:	86078793          	addi	a5,a5,-1952 # 80022978 <log>
    80004120:	97ba                	add	a5,a5,a4
    80004122:	0207a623          	sw	zero,44(a5)
    write_head(dev);    // Erase the transaction from the log
    80004126:	854a                	mv	a0,s2
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	b6c080e7          	jalr	-1172(ra) # 80003c94 <write_head>
    80004130:	bf99                	j	80004086 <end_op+0x66>

0000000080004132 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004132:	7179                	addi	sp,sp,-48
    80004134:	f406                	sd	ra,40(sp)
    80004136:	f022                	sd	s0,32(sp)
    80004138:	ec26                	sd	s1,24(sp)
    8000413a:	e84a                	sd	s2,16(sp)
    8000413c:	e44e                	sd	s3,8(sp)
    8000413e:	e052                	sd	s4,0(sp)
    80004140:	1800                	addi	s0,sp,48
  int i;

  int dev = b->dev;
    80004142:	00852903          	lw	s2,8(a0)
  if (log[dev].lh.n >= LOGSIZE || log[dev].lh.n >= log[dev].size - 1)
    80004146:	0a800793          	li	a5,168
    8000414a:	02f90733          	mul	a4,s2,a5
    8000414e:	0001f797          	auipc	a5,0x1f
    80004152:	82a78793          	addi	a5,a5,-2006 # 80022978 <log>
    80004156:	97ba                	add	a5,a5,a4
    80004158:	57d4                	lw	a3,44(a5)
    8000415a:	47f5                	li	a5,29
    8000415c:	0ad7cc63          	blt	a5,a3,80004214 <log_write+0xe2>
    80004160:	89aa                	mv	s3,a0
    80004162:	0001f797          	auipc	a5,0x1f
    80004166:	81678793          	addi	a5,a5,-2026 # 80022978 <log>
    8000416a:	97ba                	add	a5,a5,a4
    8000416c:	4fdc                	lw	a5,28(a5)
    8000416e:	37fd                	addiw	a5,a5,-1
    80004170:	0af6d263          	bge	a3,a5,80004214 <log_write+0xe2>
    panic("too big a transaction");
  if (log[dev].outstanding < 1)
    80004174:	0a800793          	li	a5,168
    80004178:	02f90733          	mul	a4,s2,a5
    8000417c:	0001e797          	auipc	a5,0x1e
    80004180:	7fc78793          	addi	a5,a5,2044 # 80022978 <log>
    80004184:	97ba                	add	a5,a5,a4
    80004186:	539c                	lw	a5,32(a5)
    80004188:	08f05e63          	blez	a5,80004224 <log_write+0xf2>
    panic("log_write outside of trans");

  acquire(&log[dev].lock);
    8000418c:	0a800793          	li	a5,168
    80004190:	02f904b3          	mul	s1,s2,a5
    80004194:	0001ea17          	auipc	s4,0x1e
    80004198:	7e4a0a13          	addi	s4,s4,2020 # 80022978 <log>
    8000419c:	9a26                	add	s4,s4,s1
    8000419e:	8552                	mv	a0,s4
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	82c080e7          	jalr	-2004(ra) # 800009cc <acquire>
  for (i = 0; i < log[dev].lh.n; i++) {
    800041a8:	02ca2603          	lw	a2,44(s4)
    800041ac:	08c05463          	blez	a2,80004234 <log_write+0x102>
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    800041b0:	00c9a583          	lw	a1,12(s3)
    800041b4:	0001e797          	auipc	a5,0x1e
    800041b8:	7f478793          	addi	a5,a5,2036 # 800229a8 <log+0x30>
    800041bc:	97a6                	add	a5,a5,s1
  for (i = 0; i < log[dev].lh.n; i++) {
    800041be:	4701                	li	a4,0
    if (log[dev].lh.block[i] == b->blockno)   // log absorbtion
    800041c0:	4394                	lw	a3,0(a5)
    800041c2:	06b68a63          	beq	a3,a1,80004236 <log_write+0x104>
  for (i = 0; i < log[dev].lh.n; i++) {
    800041c6:	2705                	addiw	a4,a4,1
    800041c8:	0791                	addi	a5,a5,4
    800041ca:	fec71be3          	bne	a4,a2,800041c0 <log_write+0x8e>
      break;
  }
  log[dev].lh.block[i] = b->blockno;
    800041ce:	02a00793          	li	a5,42
    800041d2:	02f907b3          	mul	a5,s2,a5
    800041d6:	97b2                	add	a5,a5,a2
    800041d8:	07a1                	addi	a5,a5,8
    800041da:	078a                	slli	a5,a5,0x2
    800041dc:	0001e717          	auipc	a4,0x1e
    800041e0:	79c70713          	addi	a4,a4,1948 # 80022978 <log>
    800041e4:	97ba                	add	a5,a5,a4
    800041e6:	00c9a703          	lw	a4,12(s3)
    800041ea:	cb98                	sw	a4,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    bpin(b);
    800041ec:	854e                	mv	a0,s3
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	cac080e7          	jalr	-852(ra) # 80002e9a <bpin>
    log[dev].lh.n++;
    800041f6:	0a800793          	li	a5,168
    800041fa:	02f90933          	mul	s2,s2,a5
    800041fe:	0001e797          	auipc	a5,0x1e
    80004202:	77a78793          	addi	a5,a5,1914 # 80022978 <log>
    80004206:	993e                	add	s2,s2,a5
    80004208:	02c92783          	lw	a5,44(s2)
    8000420c:	2785                	addiw	a5,a5,1
    8000420e:	02f92623          	sw	a5,44(s2)
    80004212:	a099                	j	80004258 <log_write+0x126>
    panic("too big a transaction");
    80004214:	00004517          	auipc	a0,0x4
    80004218:	41450513          	addi	a0,a0,1044 # 80008628 <userret+0x598>
    8000421c:	ffffc097          	auipc	ra,0xffffc
    80004220:	332080e7          	jalr	818(ra) # 8000054e <panic>
    panic("log_write outside of trans");
    80004224:	00004517          	auipc	a0,0x4
    80004228:	41c50513          	addi	a0,a0,1052 # 80008640 <userret+0x5b0>
    8000422c:	ffffc097          	auipc	ra,0xffffc
    80004230:	322080e7          	jalr	802(ra) # 8000054e <panic>
  for (i = 0; i < log[dev].lh.n; i++) {
    80004234:	4701                	li	a4,0
  log[dev].lh.block[i] = b->blockno;
    80004236:	02a00793          	li	a5,42
    8000423a:	02f907b3          	mul	a5,s2,a5
    8000423e:	97ba                	add	a5,a5,a4
    80004240:	07a1                	addi	a5,a5,8
    80004242:	078a                	slli	a5,a5,0x2
    80004244:	0001e697          	auipc	a3,0x1e
    80004248:	73468693          	addi	a3,a3,1844 # 80022978 <log>
    8000424c:	97b6                	add	a5,a5,a3
    8000424e:	00c9a683          	lw	a3,12(s3)
    80004252:	cb94                	sw	a3,16(a5)
  if (i == log[dev].lh.n) {  // Add new block to log?
    80004254:	f8e60ce3          	beq	a2,a4,800041ec <log_write+0xba>
  }
  release(&log[dev].lock);
    80004258:	8552                	mv	a0,s4
    8000425a:	ffffc097          	auipc	ra,0xffffc
    8000425e:	7da080e7          	jalr	2010(ra) # 80000a34 <release>
}
    80004262:	70a2                	ld	ra,40(sp)
    80004264:	7402                	ld	s0,32(sp)
    80004266:	64e2                	ld	s1,24(sp)
    80004268:	6942                	ld	s2,16(sp)
    8000426a:	69a2                	ld	s3,8(sp)
    8000426c:	6a02                	ld	s4,0(sp)
    8000426e:	6145                	addi	sp,sp,48
    80004270:	8082                	ret

0000000080004272 <crash_op>:

// crash before commit or after commit
void
crash_op(int dev, int docommit)
{
    80004272:	7179                	addi	sp,sp,-48
    80004274:	f406                	sd	ra,40(sp)
    80004276:	f022                	sd	s0,32(sp)
    80004278:	ec26                	sd	s1,24(sp)
    8000427a:	e84a                	sd	s2,16(sp)
    8000427c:	e44e                	sd	s3,8(sp)
    8000427e:	1800                	addi	s0,sp,48
    80004280:	84aa                	mv	s1,a0
    80004282:	89ae                	mv	s3,a1
  int do_commit = 0;
    
  acquire(&log[dev].lock);
    80004284:	0a800913          	li	s2,168
    80004288:	032507b3          	mul	a5,a0,s2
    8000428c:	0001e917          	auipc	s2,0x1e
    80004290:	6ec90913          	addi	s2,s2,1772 # 80022978 <log>
    80004294:	993e                	add	s2,s2,a5
    80004296:	854a                	mv	a0,s2
    80004298:	ffffc097          	auipc	ra,0xffffc
    8000429c:	734080e7          	jalr	1844(ra) # 800009cc <acquire>

  if (dev < 0 || dev >= NDISK)
    800042a0:	0004871b          	sext.w	a4,s1
    800042a4:	4785                	li	a5,1
    800042a6:	0ae7e063          	bltu	a5,a4,80004346 <crash_op+0xd4>
    panic("end_op: invalid disk");
  if(log[dev].outstanding == 0)
    800042aa:	0a800793          	li	a5,168
    800042ae:	02f48733          	mul	a4,s1,a5
    800042b2:	0001e797          	auipc	a5,0x1e
    800042b6:	6c678793          	addi	a5,a5,1734 # 80022978 <log>
    800042ba:	97ba                	add	a5,a5,a4
    800042bc:	539c                	lw	a5,32(a5)
    800042be:	cfc1                	beqz	a5,80004356 <crash_op+0xe4>
    panic("end_op: already closed");
  log[dev].outstanding -= 1;
    800042c0:	37fd                	addiw	a5,a5,-1
    800042c2:	0007861b          	sext.w	a2,a5
    800042c6:	0a800713          	li	a4,168
    800042ca:	02e486b3          	mul	a3,s1,a4
    800042ce:	0001e717          	auipc	a4,0x1e
    800042d2:	6aa70713          	addi	a4,a4,1706 # 80022978 <log>
    800042d6:	9736                	add	a4,a4,a3
    800042d8:	d31c                	sw	a5,32(a4)
  if(log[dev].committing)
    800042da:	535c                	lw	a5,36(a4)
    800042dc:	e7c9                	bnez	a5,80004366 <crash_op+0xf4>
    panic("log[dev].committing");
  if(log[dev].outstanding == 0){
    800042de:	ee41                	bnez	a2,80004376 <crash_op+0x104>
    do_commit = 1;
    log[dev].committing = 1;
    800042e0:	0a800793          	li	a5,168
    800042e4:	02f48733          	mul	a4,s1,a5
    800042e8:	0001e797          	auipc	a5,0x1e
    800042ec:	69078793          	addi	a5,a5,1680 # 80022978 <log>
    800042f0:	97ba                	add	a5,a5,a4
    800042f2:	4705                	li	a4,1
    800042f4:	d3d8                	sw	a4,36(a5)
  }
  
  release(&log[dev].lock);
    800042f6:	854a                	mv	a0,s2
    800042f8:	ffffc097          	auipc	ra,0xffffc
    800042fc:	73c080e7          	jalr	1852(ra) # 80000a34 <release>

  if(docommit & do_commit){
    80004300:	0019f993          	andi	s3,s3,1
    80004304:	06098e63          	beqz	s3,80004380 <crash_op+0x10e>
    printf("crash_op: commit\n");
    80004308:	00004517          	auipc	a0,0x4
    8000430c:	38850513          	addi	a0,a0,904 # 80008690 <userret+0x600>
    80004310:	ffffc097          	auipc	ra,0xffffc
    80004314:	288080e7          	jalr	648(ra) # 80000598 <printf>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.

    if (log[dev].lh.n > 0) {
    80004318:	0a800793          	li	a5,168
    8000431c:	02f48733          	mul	a4,s1,a5
    80004320:	0001e797          	auipc	a5,0x1e
    80004324:	65878793          	addi	a5,a5,1624 # 80022978 <log>
    80004328:	97ba                	add	a5,a5,a4
    8000432a:	57dc                	lw	a5,44(a5)
    8000432c:	04f05a63          	blez	a5,80004380 <crash_op+0x10e>
      write_log(dev);     // Write modified blocks from cache to log
    80004330:	8526                	mv	a0,s1
    80004332:	00000097          	auipc	ra,0x0
    80004336:	9ec080e7          	jalr	-1556(ra) # 80003d1e <write_log>
      write_head(dev);    // Write header to disk -- the real commit
    8000433a:	8526                	mv	a0,s1
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	958080e7          	jalr	-1704(ra) # 80003c94 <write_head>
    80004344:	a835                	j	80004380 <crash_op+0x10e>
    panic("end_op: invalid disk");
    80004346:	00004517          	auipc	a0,0x4
    8000434a:	31a50513          	addi	a0,a0,794 # 80008660 <userret+0x5d0>
    8000434e:	ffffc097          	auipc	ra,0xffffc
    80004352:	200080e7          	jalr	512(ra) # 8000054e <panic>
    panic("end_op: already closed");
    80004356:	00004517          	auipc	a0,0x4
    8000435a:	32250513          	addi	a0,a0,802 # 80008678 <userret+0x5e8>
    8000435e:	ffffc097          	auipc	ra,0xffffc
    80004362:	1f0080e7          	jalr	496(ra) # 8000054e <panic>
    panic("log[dev].committing");
    80004366:	00004517          	auipc	a0,0x4
    8000436a:	2aa50513          	addi	a0,a0,682 # 80008610 <userret+0x580>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	1e0080e7          	jalr	480(ra) # 8000054e <panic>
  release(&log[dev].lock);
    80004376:	854a                	mv	a0,s2
    80004378:	ffffc097          	auipc	ra,0xffffc
    8000437c:	6bc080e7          	jalr	1724(ra) # 80000a34 <release>
    }
  }
  panic("crashed file system; please restart xv6 and run crashtest\n");
    80004380:	00004517          	auipc	a0,0x4
    80004384:	32850513          	addi	a0,a0,808 # 800086a8 <userret+0x618>
    80004388:	ffffc097          	auipc	ra,0xffffc
    8000438c:	1c6080e7          	jalr	454(ra) # 8000054e <panic>

0000000080004390 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004390:	1101                	addi	sp,sp,-32
    80004392:	ec06                	sd	ra,24(sp)
    80004394:	e822                	sd	s0,16(sp)
    80004396:	e426                	sd	s1,8(sp)
    80004398:	e04a                	sd	s2,0(sp)
    8000439a:	1000                	addi	s0,sp,32
    8000439c:	84aa                	mv	s1,a0
    8000439e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043a0:	00004597          	auipc	a1,0x4
    800043a4:	34858593          	addi	a1,a1,840 # 800086e8 <userret+0x658>
    800043a8:	0521                	addi	a0,a0,8
    800043aa:	ffffc097          	auipc	ra,0xffffc
    800043ae:	510080e7          	jalr	1296(ra) # 800008ba <initlock>
  lk->name = name;
    800043b2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043ba:	0204a423          	sw	zero,40(s1)
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	e426                	sd	s1,8(sp)
    800043d2:	e04a                	sd	s2,0(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d8:	00850913          	addi	s2,a0,8
    800043dc:	854a                	mv	a0,s2
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	5ee080e7          	jalr	1518(ra) # 800009cc <acquire>
  while (lk->locked) {
    800043e6:	409c                	lw	a5,0(s1)
    800043e8:	cb89                	beqz	a5,800043fa <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043ea:	85ca                	mv	a1,s2
    800043ec:	8526                	mv	a0,s1
    800043ee:	ffffe097          	auipc	ra,0xffffe
    800043f2:	cc2080e7          	jalr	-830(ra) # 800020b0 <sleep>
  while (lk->locked) {
    800043f6:	409c                	lw	a5,0(s1)
    800043f8:	fbed                	bnez	a5,800043ea <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043fa:	4785                	li	a5,1
    800043fc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	4a0080e7          	jalr	1184(ra) # 8000189e <myproc>
    80004406:	5d1c                	lw	a5,56(a0)
    80004408:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000440a:	854a                	mv	a0,s2
    8000440c:	ffffc097          	auipc	ra,0xffffc
    80004410:	628080e7          	jalr	1576(ra) # 80000a34 <release>
}
    80004414:	60e2                	ld	ra,24(sp)
    80004416:	6442                	ld	s0,16(sp)
    80004418:	64a2                	ld	s1,8(sp)
    8000441a:	6902                	ld	s2,0(sp)
    8000441c:	6105                	addi	sp,sp,32
    8000441e:	8082                	ret

0000000080004420 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004420:	1101                	addi	sp,sp,-32
    80004422:	ec06                	sd	ra,24(sp)
    80004424:	e822                	sd	s0,16(sp)
    80004426:	e426                	sd	s1,8(sp)
    80004428:	e04a                	sd	s2,0(sp)
    8000442a:	1000                	addi	s0,sp,32
    8000442c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000442e:	00850913          	addi	s2,a0,8
    80004432:	854a                	mv	a0,s2
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	598080e7          	jalr	1432(ra) # 800009cc <acquire>
  lk->locked = 0;
    8000443c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004440:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004444:	8526                	mv	a0,s1
    80004446:	ffffe097          	auipc	ra,0xffffe
    8000444a:	df0080e7          	jalr	-528(ra) # 80002236 <wakeup>
  release(&lk->lk);
    8000444e:	854a                	mv	a0,s2
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	5e4080e7          	jalr	1508(ra) # 80000a34 <release>
}
    80004458:	60e2                	ld	ra,24(sp)
    8000445a:	6442                	ld	s0,16(sp)
    8000445c:	64a2                	ld	s1,8(sp)
    8000445e:	6902                	ld	s2,0(sp)
    80004460:	6105                	addi	sp,sp,32
    80004462:	8082                	ret

0000000080004464 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004464:	7179                	addi	sp,sp,-48
    80004466:	f406                	sd	ra,40(sp)
    80004468:	f022                	sd	s0,32(sp)
    8000446a:	ec26                	sd	s1,24(sp)
    8000446c:	e84a                	sd	s2,16(sp)
    8000446e:	e44e                	sd	s3,8(sp)
    80004470:	1800                	addi	s0,sp,48
    80004472:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004474:	00850913          	addi	s2,a0,8
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	552080e7          	jalr	1362(ra) # 800009cc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004482:	409c                	lw	a5,0(s1)
    80004484:	ef99                	bnez	a5,800044a2 <holdingsleep+0x3e>
    80004486:	4481                	li	s1,0
  release(&lk->lk);
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	5aa080e7          	jalr	1450(ra) # 80000a34 <release>
  return r;
}
    80004492:	8526                	mv	a0,s1
    80004494:	70a2                	ld	ra,40(sp)
    80004496:	7402                	ld	s0,32(sp)
    80004498:	64e2                	ld	s1,24(sp)
    8000449a:	6942                	ld	s2,16(sp)
    8000449c:	69a2                	ld	s3,8(sp)
    8000449e:	6145                	addi	sp,sp,48
    800044a0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a2:	0284a983          	lw	s3,40(s1)
    800044a6:	ffffd097          	auipc	ra,0xffffd
    800044aa:	3f8080e7          	jalr	1016(ra) # 8000189e <myproc>
    800044ae:	5d04                	lw	s1,56(a0)
    800044b0:	413484b3          	sub	s1,s1,s3
    800044b4:	0014b493          	seqz	s1,s1
    800044b8:	bfc1                	j	80004488 <holdingsleep+0x24>

00000000800044ba <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044ba:	1141                	addi	sp,sp,-16
    800044bc:	e406                	sd	ra,8(sp)
    800044be:	e022                	sd	s0,0(sp)
    800044c0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044c2:	00004597          	auipc	a1,0x4
    800044c6:	23658593          	addi	a1,a1,566 # 800086f8 <userret+0x668>
    800044ca:	0001e517          	auipc	a0,0x1e
    800044ce:	69e50513          	addi	a0,a0,1694 # 80022b68 <ftable>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	3e8080e7          	jalr	1000(ra) # 800008ba <initlock>
}
    800044da:	60a2                	ld	ra,8(sp)
    800044dc:	6402                	ld	s0,0(sp)
    800044de:	0141                	addi	sp,sp,16
    800044e0:	8082                	ret

00000000800044e2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ec:	0001e517          	auipc	a0,0x1e
    800044f0:	67c50513          	addi	a0,a0,1660 # 80022b68 <ftable>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	4d8080e7          	jalr	1240(ra) # 800009cc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044fc:	0001e497          	auipc	s1,0x1e
    80004500:	68448493          	addi	s1,s1,1668 # 80022b80 <ftable+0x18>
    80004504:	0001f717          	auipc	a4,0x1f
    80004508:	61c70713          	addi	a4,a4,1564 # 80023b20 <ftable+0xfb8>
    if(f->ref == 0){
    8000450c:	40dc                	lw	a5,4(s1)
    8000450e:	cf99                	beqz	a5,8000452c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004510:	02848493          	addi	s1,s1,40
    80004514:	fee49ce3          	bne	s1,a4,8000450c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004518:	0001e517          	auipc	a0,0x1e
    8000451c:	65050513          	addi	a0,a0,1616 # 80022b68 <ftable>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	514080e7          	jalr	1300(ra) # 80000a34 <release>
  return 0;
    80004528:	4481                	li	s1,0
    8000452a:	a819                	j	80004540 <filealloc+0x5e>
      f->ref = 1;
    8000452c:	4785                	li	a5,1
    8000452e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004530:	0001e517          	auipc	a0,0x1e
    80004534:	63850513          	addi	a0,a0,1592 # 80022b68 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	4fc080e7          	jalr	1276(ra) # 80000a34 <release>
}
    80004540:	8526                	mv	a0,s1
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6105                	addi	sp,sp,32
    8000454a:	8082                	ret

000000008000454c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000454c:	1101                	addi	sp,sp,-32
    8000454e:	ec06                	sd	ra,24(sp)
    80004550:	e822                	sd	s0,16(sp)
    80004552:	e426                	sd	s1,8(sp)
    80004554:	1000                	addi	s0,sp,32
    80004556:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004558:	0001e517          	auipc	a0,0x1e
    8000455c:	61050513          	addi	a0,a0,1552 # 80022b68 <ftable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	46c080e7          	jalr	1132(ra) # 800009cc <acquire>
  if(f->ref < 1)
    80004568:	40dc                	lw	a5,4(s1)
    8000456a:	02f05263          	blez	a5,8000458e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000456e:	2785                	addiw	a5,a5,1
    80004570:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004572:	0001e517          	auipc	a0,0x1e
    80004576:	5f650513          	addi	a0,a0,1526 # 80022b68 <ftable>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	4ba080e7          	jalr	1210(ra) # 80000a34 <release>
  return f;
}
    80004582:	8526                	mv	a0,s1
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret
    panic("filedup");
    8000458e:	00004517          	auipc	a0,0x4
    80004592:	17250513          	addi	a0,a0,370 # 80008700 <userret+0x670>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	fb8080e7          	jalr	-72(ra) # 8000054e <panic>

000000008000459e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000459e:	7139                	addi	sp,sp,-64
    800045a0:	fc06                	sd	ra,56(sp)
    800045a2:	f822                	sd	s0,48(sp)
    800045a4:	f426                	sd	s1,40(sp)
    800045a6:	f04a                	sd	s2,32(sp)
    800045a8:	ec4e                	sd	s3,24(sp)
    800045aa:	e852                	sd	s4,16(sp)
    800045ac:	e456                	sd	s5,8(sp)
    800045ae:	0080                	addi	s0,sp,64
    800045b0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045b2:	0001e517          	auipc	a0,0x1e
    800045b6:	5b650513          	addi	a0,a0,1462 # 80022b68 <ftable>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	412080e7          	jalr	1042(ra) # 800009cc <acquire>
  if(f->ref < 1)
    800045c2:	40dc                	lw	a5,4(s1)
    800045c4:	06f05563          	blez	a5,8000462e <fileclose+0x90>
    panic("fileclose");
  if(--f->ref > 0){
    800045c8:	37fd                	addiw	a5,a5,-1
    800045ca:	0007871b          	sext.w	a4,a5
    800045ce:	c0dc                	sw	a5,4(s1)
    800045d0:	06e04763          	bgtz	a4,8000463e <fileclose+0xa0>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045d4:	0004a903          	lw	s2,0(s1)
    800045d8:	0094ca83          	lbu	s5,9(s1)
    800045dc:	0104ba03          	ld	s4,16(s1)
    800045e0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045e4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045e8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ec:	0001e517          	auipc	a0,0x1e
    800045f0:	57c50513          	addi	a0,a0,1404 # 80022b68 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	440080e7          	jalr	1088(ra) # 80000a34 <release>

  if(ff.type == FD_PIPE){
    800045fc:	4785                	li	a5,1
    800045fe:	06f90163          	beq	s2,a5,80004660 <fileclose+0xc2>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004602:	3979                	addiw	s2,s2,-2
    80004604:	4785                	li	a5,1
    80004606:	0527e463          	bltu	a5,s2,8000464e <fileclose+0xb0>
    begin_op(ff.ip->dev);
    8000460a:	0009a503          	lw	a0,0(s3)
    8000460e:	00000097          	auipc	ra,0x0
    80004612:	968080e7          	jalr	-1688(ra) # 80003f76 <begin_op>
    iput(ff.ip);
    80004616:	854e                	mv	a0,s3
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	fc4080e7          	jalr	-60(ra) # 800035dc <iput>
    end_op(ff.ip->dev);
    80004620:	0009a503          	lw	a0,0(s3)
    80004624:	00000097          	auipc	ra,0x0
    80004628:	9fc080e7          	jalr	-1540(ra) # 80004020 <end_op>
    8000462c:	a00d                	j	8000464e <fileclose+0xb0>
    panic("fileclose");
    8000462e:	00004517          	auipc	a0,0x4
    80004632:	0da50513          	addi	a0,a0,218 # 80008708 <userret+0x678>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	f18080e7          	jalr	-232(ra) # 8000054e <panic>
    release(&ftable.lock);
    8000463e:	0001e517          	auipc	a0,0x1e
    80004642:	52a50513          	addi	a0,a0,1322 # 80022b68 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	3ee080e7          	jalr	1006(ra) # 80000a34 <release>
  }
}
    8000464e:	70e2                	ld	ra,56(sp)
    80004650:	7442                	ld	s0,48(sp)
    80004652:	74a2                	ld	s1,40(sp)
    80004654:	7902                	ld	s2,32(sp)
    80004656:	69e2                	ld	s3,24(sp)
    80004658:	6a42                	ld	s4,16(sp)
    8000465a:	6aa2                	ld	s5,8(sp)
    8000465c:	6121                	addi	sp,sp,64
    8000465e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004660:	85d6                	mv	a1,s5
    80004662:	8552                	mv	a0,s4
    80004664:	00000097          	auipc	ra,0x0
    80004668:	348080e7          	jalr	840(ra) # 800049ac <pipeclose>
    8000466c:	b7cd                	j	8000464e <fileclose+0xb0>

000000008000466e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000466e:	715d                	addi	sp,sp,-80
    80004670:	e486                	sd	ra,72(sp)
    80004672:	e0a2                	sd	s0,64(sp)
    80004674:	fc26                	sd	s1,56(sp)
    80004676:	f84a                	sd	s2,48(sp)
    80004678:	f44e                	sd	s3,40(sp)
    8000467a:	0880                	addi	s0,sp,80
    8000467c:	84aa                	mv	s1,a0
    8000467e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004680:	ffffd097          	auipc	ra,0xffffd
    80004684:	21e080e7          	jalr	542(ra) # 8000189e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004688:	409c                	lw	a5,0(s1)
    8000468a:	37f9                	addiw	a5,a5,-2
    8000468c:	4705                	li	a4,1
    8000468e:	04f76763          	bltu	a4,a5,800046dc <filestat+0x6e>
    80004692:	892a                	mv	s2,a0
    ilock(f->ip);
    80004694:	6c88                	ld	a0,24(s1)
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	e38080e7          	jalr	-456(ra) # 800034ce <ilock>
    stati(f->ip, &st);
    8000469e:	fb840593          	addi	a1,s0,-72
    800046a2:	6c88                	ld	a0,24(s1)
    800046a4:	fffff097          	auipc	ra,0xfffff
    800046a8:	090080e7          	jalr	144(ra) # 80003734 <stati>
    iunlock(f->ip);
    800046ac:	6c88                	ld	a0,24(s1)
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	ee2080e7          	jalr	-286(ra) # 80003590 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046b6:	46e1                	li	a3,24
    800046b8:	fb840613          	addi	a2,s0,-72
    800046bc:	85ce                	mv	a1,s3
    800046be:	05093503          	ld	a0,80(s2)
    800046c2:	ffffd097          	auipc	ra,0xffffd
    800046c6:	d92080e7          	jalr	-622(ra) # 80001454 <copyout>
    800046ca:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ce:	60a6                	ld	ra,72(sp)
    800046d0:	6406                	ld	s0,64(sp)
    800046d2:	74e2                	ld	s1,56(sp)
    800046d4:	7942                	ld	s2,48(sp)
    800046d6:	79a2                	ld	s3,40(sp)
    800046d8:	6161                	addi	sp,sp,80
    800046da:	8082                	ret
  return -1;
    800046dc:	557d                	li	a0,-1
    800046de:	bfc5                	j	800046ce <filestat+0x60>

00000000800046e0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046e0:	7179                	addi	sp,sp,-48
    800046e2:	f406                	sd	ra,40(sp)
    800046e4:	f022                	sd	s0,32(sp)
    800046e6:	ec26                	sd	s1,24(sp)
    800046e8:	e84a                	sd	s2,16(sp)
    800046ea:	e44e                	sd	s3,8(sp)
    800046ec:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046ee:	00854783          	lbu	a5,8(a0)
    800046f2:	cfc1                	beqz	a5,8000478a <fileread+0xaa>
    800046f4:	84aa                	mv	s1,a0
    800046f6:	89ae                	mv	s3,a1
    800046f8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046fa:	411c                	lw	a5,0(a0)
    800046fc:	4705                	li	a4,1
    800046fe:	04e78963          	beq	a5,a4,80004750 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004702:	470d                	li	a4,3
    80004704:	04e78d63          	beq	a5,a4,8000475e <fileread+0x7e>
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004708:	4709                	li	a4,2
    8000470a:	06e79863          	bne	a5,a4,8000477a <fileread+0x9a>
    ilock(f->ip);
    8000470e:	6d08                	ld	a0,24(a0)
    80004710:	fffff097          	auipc	ra,0xfffff
    80004714:	dbe080e7          	jalr	-578(ra) # 800034ce <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004718:	874a                	mv	a4,s2
    8000471a:	5094                	lw	a3,32(s1)
    8000471c:	864e                	mv	a2,s3
    8000471e:	4585                	li	a1,1
    80004720:	6c88                	ld	a0,24(s1)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	03c080e7          	jalr	60(ra) # 8000375e <readi>
    8000472a:	892a                	mv	s2,a0
    8000472c:	00a05563          	blez	a0,80004736 <fileread+0x56>
      f->off += r;
    80004730:	509c                	lw	a5,32(s1)
    80004732:	9fa9                	addw	a5,a5,a0
    80004734:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004736:	6c88                	ld	a0,24(s1)
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	e58080e7          	jalr	-424(ra) # 80003590 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004740:	854a                	mv	a0,s2
    80004742:	70a2                	ld	ra,40(sp)
    80004744:	7402                	ld	s0,32(sp)
    80004746:	64e2                	ld	s1,24(sp)
    80004748:	6942                	ld	s2,16(sp)
    8000474a:	69a2                	ld	s3,8(sp)
    8000474c:	6145                	addi	sp,sp,48
    8000474e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004750:	6908                	ld	a0,16(a0)
    80004752:	00000097          	auipc	ra,0x0
    80004756:	3de080e7          	jalr	990(ra) # 80004b30 <piperead>
    8000475a:	892a                	mv	s2,a0
    8000475c:	b7d5                	j	80004740 <fileread+0x60>
    r = devsw[f->major].read(1, addr, n);
    8000475e:	02451783          	lh	a5,36(a0)
    80004762:	00479713          	slli	a4,a5,0x4
    80004766:	0001e797          	auipc	a5,0x1e
    8000476a:	36278793          	addi	a5,a5,866 # 80022ac8 <devsw>
    8000476e:	97ba                	add	a5,a5,a4
    80004770:	639c                	ld	a5,0(a5)
    80004772:	4505                	li	a0,1
    80004774:	9782                	jalr	a5
    80004776:	892a                	mv	s2,a0
    80004778:	b7e1                	j	80004740 <fileread+0x60>
    panic("fileread");
    8000477a:	00004517          	auipc	a0,0x4
    8000477e:	f9e50513          	addi	a0,a0,-98 # 80008718 <userret+0x688>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	dcc080e7          	jalr	-564(ra) # 8000054e <panic>
    return -1;
    8000478a:	597d                	li	s2,-1
    8000478c:	bf55                	j	80004740 <fileread+0x60>

000000008000478e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000478e:	00954783          	lbu	a5,9(a0)
    80004792:	12078e63          	beqz	a5,800048ce <filewrite+0x140>
{
    80004796:	715d                	addi	sp,sp,-80
    80004798:	e486                	sd	ra,72(sp)
    8000479a:	e0a2                	sd	s0,64(sp)
    8000479c:	fc26                	sd	s1,56(sp)
    8000479e:	f84a                	sd	s2,48(sp)
    800047a0:	f44e                	sd	s3,40(sp)
    800047a2:	f052                	sd	s4,32(sp)
    800047a4:	ec56                	sd	s5,24(sp)
    800047a6:	e85a                	sd	s6,16(sp)
    800047a8:	e45e                	sd	s7,8(sp)
    800047aa:	e062                	sd	s8,0(sp)
    800047ac:	0880                	addi	s0,sp,80
    800047ae:	84aa                	mv	s1,a0
    800047b0:	8aae                	mv	s5,a1
    800047b2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b4:	411c                	lw	a5,0(a0)
    800047b6:	4705                	li	a4,1
    800047b8:	02e78263          	beq	a5,a4,800047dc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047bc:	470d                	li	a4,3
    800047be:	02e78563          	beq	a5,a4,800047e8 <filewrite+0x5a>
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047c2:	4709                	li	a4,2
    800047c4:	0ee79d63          	bne	a5,a4,800048be <filewrite+0x130>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047c8:	0ec05763          	blez	a2,800048b6 <filewrite+0x128>
    int i = 0;
    800047cc:	4981                	li	s3,0
    800047ce:	6b05                	lui	s6,0x1
    800047d0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047d4:	6b85                	lui	s7,0x1
    800047d6:	c00b8b9b          	addiw	s7,s7,-1024
    800047da:	a051                	j	8000485e <filewrite+0xd0>
    ret = pipewrite(f->pipe, addr, n);
    800047dc:	6908                	ld	a0,16(a0)
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	23e080e7          	jalr	574(ra) # 80004a1c <pipewrite>
    800047e6:	a065                	j	8000488e <filewrite+0x100>
    ret = devsw[f->major].write(1, addr, n);
    800047e8:	02451783          	lh	a5,36(a0)
    800047ec:	00479713          	slli	a4,a5,0x4
    800047f0:	0001e797          	auipc	a5,0x1e
    800047f4:	2d878793          	addi	a5,a5,728 # 80022ac8 <devsw>
    800047f8:	97ba                	add	a5,a5,a4
    800047fa:	679c                	ld	a5,8(a5)
    800047fc:	4505                	li	a0,1
    800047fe:	9782                	jalr	a5
    80004800:	a079                	j	8000488e <filewrite+0x100>
    80004802:	00090c1b          	sext.w	s8,s2
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op(f->ip->dev);
    80004806:	6c9c                	ld	a5,24(s1)
    80004808:	4388                	lw	a0,0(a5)
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	76c080e7          	jalr	1900(ra) # 80003f76 <begin_op>
      ilock(f->ip);
    80004812:	6c88                	ld	a0,24(s1)
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	cba080e7          	jalr	-838(ra) # 800034ce <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000481c:	8762                	mv	a4,s8
    8000481e:	5094                	lw	a3,32(s1)
    80004820:	01598633          	add	a2,s3,s5
    80004824:	4585                	li	a1,1
    80004826:	6c88                	ld	a0,24(s1)
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	02a080e7          	jalr	42(ra) # 80003852 <writei>
    80004830:	892a                	mv	s2,a0
    80004832:	02a05e63          	blez	a0,8000486e <filewrite+0xe0>
        f->off += r;
    80004836:	509c                	lw	a5,32(s1)
    80004838:	9fa9                	addw	a5,a5,a0
    8000483a:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    8000483c:	6c88                	ld	a0,24(s1)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	d52080e7          	jalr	-686(ra) # 80003590 <iunlock>
      end_op(f->ip->dev);
    80004846:	6c9c                	ld	a5,24(s1)
    80004848:	4388                	lw	a0,0(a5)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	7d6080e7          	jalr	2006(ra) # 80004020 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004852:	052c1a63          	bne	s8,s2,800048a6 <filewrite+0x118>
        panic("short filewrite");
      i += r;
    80004856:	013909bb          	addw	s3,s2,s3
    while(i < n){
    8000485a:	0349d763          	bge	s3,s4,80004888 <filewrite+0xfa>
      int n1 = n - i;
    8000485e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004862:	893e                	mv	s2,a5
    80004864:	2781                	sext.w	a5,a5
    80004866:	f8fb5ee3          	bge	s6,a5,80004802 <filewrite+0x74>
    8000486a:	895e                	mv	s2,s7
    8000486c:	bf59                	j	80004802 <filewrite+0x74>
      iunlock(f->ip);
    8000486e:	6c88                	ld	a0,24(s1)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	d20080e7          	jalr	-736(ra) # 80003590 <iunlock>
      end_op(f->ip->dev);
    80004878:	6c9c                	ld	a5,24(s1)
    8000487a:	4388                	lw	a0,0(a5)
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	7a4080e7          	jalr	1956(ra) # 80004020 <end_op>
      if(r < 0)
    80004884:	fc0957e3          	bgez	s2,80004852 <filewrite+0xc4>
    }
    ret = (i == n ? n : -1);
    80004888:	8552                	mv	a0,s4
    8000488a:	033a1863          	bne	s4,s3,800048ba <filewrite+0x12c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000488e:	60a6                	ld	ra,72(sp)
    80004890:	6406                	ld	s0,64(sp)
    80004892:	74e2                	ld	s1,56(sp)
    80004894:	7942                	ld	s2,48(sp)
    80004896:	79a2                	ld	s3,40(sp)
    80004898:	7a02                	ld	s4,32(sp)
    8000489a:	6ae2                	ld	s5,24(sp)
    8000489c:	6b42                	ld	s6,16(sp)
    8000489e:	6ba2                	ld	s7,8(sp)
    800048a0:	6c02                	ld	s8,0(sp)
    800048a2:	6161                	addi	sp,sp,80
    800048a4:	8082                	ret
        panic("short filewrite");
    800048a6:	00004517          	auipc	a0,0x4
    800048aa:	e8250513          	addi	a0,a0,-382 # 80008728 <userret+0x698>
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	ca0080e7          	jalr	-864(ra) # 8000054e <panic>
    int i = 0;
    800048b6:	4981                	li	s3,0
    800048b8:	bfc1                	j	80004888 <filewrite+0xfa>
    ret = (i == n ? n : -1);
    800048ba:	557d                	li	a0,-1
    800048bc:	bfc9                	j	8000488e <filewrite+0x100>
    panic("filewrite");
    800048be:	00004517          	auipc	a0,0x4
    800048c2:	e7a50513          	addi	a0,a0,-390 # 80008738 <userret+0x6a8>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	c88080e7          	jalr	-888(ra) # 8000054e <panic>
    return -1;
    800048ce:	557d                	li	a0,-1
}
    800048d0:	8082                	ret

00000000800048d2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048d2:	7179                	addi	sp,sp,-48
    800048d4:	f406                	sd	ra,40(sp)
    800048d6:	f022                	sd	s0,32(sp)
    800048d8:	ec26                	sd	s1,24(sp)
    800048da:	e84a                	sd	s2,16(sp)
    800048dc:	e44e                	sd	s3,8(sp)
    800048de:	e052                	sd	s4,0(sp)
    800048e0:	1800                	addi	s0,sp,48
    800048e2:	84aa                	mv	s1,a0
    800048e4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048e6:	0005b023          	sd	zero,0(a1)
    800048ea:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048ee:	00000097          	auipc	ra,0x0
    800048f2:	bf4080e7          	jalr	-1036(ra) # 800044e2 <filealloc>
    800048f6:	e088                	sd	a0,0(s1)
    800048f8:	c551                	beqz	a0,80004984 <pipealloc+0xb2>
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	be8080e7          	jalr	-1048(ra) # 800044e2 <filealloc>
    80004902:	00aa3023          	sd	a0,0(s4)
    80004906:	c92d                	beqz	a0,80004978 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	f98080e7          	jalr	-104(ra) # 800008a0 <kalloc>
    80004910:	892a                	mv	s2,a0
    80004912:	c125                	beqz	a0,80004972 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004914:	4985                	li	s3,1
    80004916:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000491a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000491e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004922:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004926:	00004597          	auipc	a1,0x4
    8000492a:	e2258593          	addi	a1,a1,-478 # 80008748 <userret+0x6b8>
    8000492e:	ffffc097          	auipc	ra,0xffffc
    80004932:	f8c080e7          	jalr	-116(ra) # 800008ba <initlock>
  (*f0)->type = FD_PIPE;
    80004936:	609c                	ld	a5,0(s1)
    80004938:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000493c:	609c                	ld	a5,0(s1)
    8000493e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004942:	609c                	ld	a5,0(s1)
    80004944:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004948:	609c                	ld	a5,0(s1)
    8000494a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000494e:	000a3783          	ld	a5,0(s4)
    80004952:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004956:	000a3783          	ld	a5,0(s4)
    8000495a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000495e:	000a3783          	ld	a5,0(s4)
    80004962:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004966:	000a3783          	ld	a5,0(s4)
    8000496a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000496e:	4501                	li	a0,0
    80004970:	a025                	j	80004998 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004972:	6088                	ld	a0,0(s1)
    80004974:	e501                	bnez	a0,8000497c <pipealloc+0xaa>
    80004976:	a039                	j	80004984 <pipealloc+0xb2>
    80004978:	6088                	ld	a0,0(s1)
    8000497a:	c51d                	beqz	a0,800049a8 <pipealloc+0xd6>
    fileclose(*f0);
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	c22080e7          	jalr	-990(ra) # 8000459e <fileclose>
  if(*f1)
    80004984:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004988:	557d                	li	a0,-1
  if(*f1)
    8000498a:	c799                	beqz	a5,80004998 <pipealloc+0xc6>
    fileclose(*f1);
    8000498c:	853e                	mv	a0,a5
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	c10080e7          	jalr	-1008(ra) # 8000459e <fileclose>
  return -1;
    80004996:	557d                	li	a0,-1
}
    80004998:	70a2                	ld	ra,40(sp)
    8000499a:	7402                	ld	s0,32(sp)
    8000499c:	64e2                	ld	s1,24(sp)
    8000499e:	6942                	ld	s2,16(sp)
    800049a0:	69a2                	ld	s3,8(sp)
    800049a2:	6a02                	ld	s4,0(sp)
    800049a4:	6145                	addi	sp,sp,48
    800049a6:	8082                	ret
  return -1;
    800049a8:	557d                	li	a0,-1
    800049aa:	b7fd                	j	80004998 <pipealloc+0xc6>

00000000800049ac <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049ac:	1101                	addi	sp,sp,-32
    800049ae:	ec06                	sd	ra,24(sp)
    800049b0:	e822                	sd	s0,16(sp)
    800049b2:	e426                	sd	s1,8(sp)
    800049b4:	e04a                	sd	s2,0(sp)
    800049b6:	1000                	addi	s0,sp,32
    800049b8:	84aa                	mv	s1,a0
    800049ba:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	010080e7          	jalr	16(ra) # 800009cc <acquire>
  if(writable){
    800049c4:	02090d63          	beqz	s2,800049fe <pipeclose+0x52>
    pi->writeopen = 0;
    800049c8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049cc:	21848513          	addi	a0,s1,536
    800049d0:	ffffe097          	auipc	ra,0xffffe
    800049d4:	866080e7          	jalr	-1946(ra) # 80002236 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049d8:	2204b783          	ld	a5,544(s1)
    800049dc:	eb95                	bnez	a5,80004a10 <pipeclose+0x64>
    release(&pi->lock);
    800049de:	8526                	mv	a0,s1
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	054080e7          	jalr	84(ra) # 80000a34 <release>
    kfree((char*)pi);
    800049e8:	8526                	mv	a0,s1
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	e9e080e7          	jalr	-354(ra) # 80000888 <kfree>
  } else
    release(&pi->lock);
}
    800049f2:	60e2                	ld	ra,24(sp)
    800049f4:	6442                	ld	s0,16(sp)
    800049f6:	64a2                	ld	s1,8(sp)
    800049f8:	6902                	ld	s2,0(sp)
    800049fa:	6105                	addi	sp,sp,32
    800049fc:	8082                	ret
    pi->readopen = 0;
    800049fe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a02:	21c48513          	addi	a0,s1,540
    80004a06:	ffffe097          	auipc	ra,0xffffe
    80004a0a:	830080e7          	jalr	-2000(ra) # 80002236 <wakeup>
    80004a0e:	b7e9                	j	800049d8 <pipeclose+0x2c>
    release(&pi->lock);
    80004a10:	8526                	mv	a0,s1
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	022080e7          	jalr	34(ra) # 80000a34 <release>
}
    80004a1a:	bfe1                	j	800049f2 <pipeclose+0x46>

0000000080004a1c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a1c:	7159                	addi	sp,sp,-112
    80004a1e:	f486                	sd	ra,104(sp)
    80004a20:	f0a2                	sd	s0,96(sp)
    80004a22:	eca6                	sd	s1,88(sp)
    80004a24:	e8ca                	sd	s2,80(sp)
    80004a26:	e4ce                	sd	s3,72(sp)
    80004a28:	e0d2                	sd	s4,64(sp)
    80004a2a:	fc56                	sd	s5,56(sp)
    80004a2c:	f85a                	sd	s6,48(sp)
    80004a2e:	f45e                	sd	s7,40(sp)
    80004a30:	f062                	sd	s8,32(sp)
    80004a32:	ec66                	sd	s9,24(sp)
    80004a34:	1880                	addi	s0,sp,112
    80004a36:	84aa                	mv	s1,a0
    80004a38:	8b2e                	mv	s6,a1
    80004a3a:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	e62080e7          	jalr	-414(ra) # 8000189e <myproc>
    80004a44:	8c2a                	mv	s8,a0

  acquire(&pi->lock);
    80004a46:	8526                	mv	a0,s1
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	f84080e7          	jalr	-124(ra) # 800009cc <acquire>
  for(i = 0; i < n; i++){
    80004a50:	0b505063          	blez	s5,80004af0 <pipewrite+0xd4>
    80004a54:	8926                	mv	s2,s1
    80004a56:	fffa8b9b          	addiw	s7,s5,-1
    80004a5a:	1b82                	slli	s7,s7,0x20
    80004a5c:	020bdb93          	srli	s7,s7,0x20
    80004a60:	001b0793          	addi	a5,s6,1
    80004a64:	9bbe                	add	s7,s7,a5
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || myproc()->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a66:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a6a:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a6e:	5cfd                	li	s9,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a70:	2184a783          	lw	a5,536(s1)
    80004a74:	21c4a703          	lw	a4,540(s1)
    80004a78:	2007879b          	addiw	a5,a5,512
    80004a7c:	02f71e63          	bne	a4,a5,80004ab8 <pipewrite+0x9c>
      if(pi->readopen == 0 || myproc()->killed){
    80004a80:	2204a783          	lw	a5,544(s1)
    80004a84:	c3d9                	beqz	a5,80004b0a <pipewrite+0xee>
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	e18080e7          	jalr	-488(ra) # 8000189e <myproc>
    80004a8e:	591c                	lw	a5,48(a0)
    80004a90:	efad                	bnez	a5,80004b0a <pipewrite+0xee>
      wakeup(&pi->nread);
    80004a92:	8552                	mv	a0,s4
    80004a94:	ffffd097          	auipc	ra,0xffffd
    80004a98:	7a2080e7          	jalr	1954(ra) # 80002236 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a9c:	85ca                	mv	a1,s2
    80004a9e:	854e                	mv	a0,s3
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	610080e7          	jalr	1552(ra) # 800020b0 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004aa8:	2184a783          	lw	a5,536(s1)
    80004aac:	21c4a703          	lw	a4,540(s1)
    80004ab0:	2007879b          	addiw	a5,a5,512
    80004ab4:	fcf706e3          	beq	a4,a5,80004a80 <pipewrite+0x64>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ab8:	4685                	li	a3,1
    80004aba:	865a                	mv	a2,s6
    80004abc:	f9f40593          	addi	a1,s0,-97
    80004ac0:	050c3503          	ld	a0,80(s8) # 1050 <_entry-0x7fffefb0>
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	a22080e7          	jalr	-1502(ra) # 800014e6 <copyin>
    80004acc:	03950263          	beq	a0,s9,80004af0 <pipewrite+0xd4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ad0:	21c4a783          	lw	a5,540(s1)
    80004ad4:	0017871b          	addiw	a4,a5,1
    80004ad8:	20e4ae23          	sw	a4,540(s1)
    80004adc:	1ff7f793          	andi	a5,a5,511
    80004ae0:	97a6                	add	a5,a5,s1
    80004ae2:	f9f44703          	lbu	a4,-97(s0)
    80004ae6:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004aea:	0b05                	addi	s6,s6,1
    80004aec:	f97b12e3          	bne	s6,s7,80004a70 <pipewrite+0x54>
  }
  wakeup(&pi->nread);
    80004af0:	21848513          	addi	a0,s1,536
    80004af4:	ffffd097          	auipc	ra,0xffffd
    80004af8:	742080e7          	jalr	1858(ra) # 80002236 <wakeup>
  release(&pi->lock);
    80004afc:	8526                	mv	a0,s1
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	f36080e7          	jalr	-202(ra) # 80000a34 <release>
  return n;
    80004b06:	8556                	mv	a0,s5
    80004b08:	a039                	j	80004b16 <pipewrite+0xfa>
        release(&pi->lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	f28080e7          	jalr	-216(ra) # 80000a34 <release>
        return -1;
    80004b14:	557d                	li	a0,-1
}
    80004b16:	70a6                	ld	ra,104(sp)
    80004b18:	7406                	ld	s0,96(sp)
    80004b1a:	64e6                	ld	s1,88(sp)
    80004b1c:	6946                	ld	s2,80(sp)
    80004b1e:	69a6                	ld	s3,72(sp)
    80004b20:	6a06                	ld	s4,64(sp)
    80004b22:	7ae2                	ld	s5,56(sp)
    80004b24:	7b42                	ld	s6,48(sp)
    80004b26:	7ba2                	ld	s7,40(sp)
    80004b28:	7c02                	ld	s8,32(sp)
    80004b2a:	6ce2                	ld	s9,24(sp)
    80004b2c:	6165                	addi	sp,sp,112
    80004b2e:	8082                	ret

0000000080004b30 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b30:	715d                	addi	sp,sp,-80
    80004b32:	e486                	sd	ra,72(sp)
    80004b34:	e0a2                	sd	s0,64(sp)
    80004b36:	fc26                	sd	s1,56(sp)
    80004b38:	f84a                	sd	s2,48(sp)
    80004b3a:	f44e                	sd	s3,40(sp)
    80004b3c:	f052                	sd	s4,32(sp)
    80004b3e:	ec56                	sd	s5,24(sp)
    80004b40:	e85a                	sd	s6,16(sp)
    80004b42:	0880                	addi	s0,sp,80
    80004b44:	84aa                	mv	s1,a0
    80004b46:	892e                	mv	s2,a1
    80004b48:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	d54080e7          	jalr	-684(ra) # 8000189e <myproc>
    80004b52:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    80004b54:	8b26                	mv	s6,s1
    80004b56:	8526                	mv	a0,s1
    80004b58:	ffffc097          	auipc	ra,0xffffc
    80004b5c:	e74080e7          	jalr	-396(ra) # 800009cc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b60:	2184a703          	lw	a4,536(s1)
    80004b64:	21c4a783          	lw	a5,540(s1)
    if(myproc()->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b68:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b6c:	02f71763          	bne	a4,a5,80004b9a <piperead+0x6a>
    80004b70:	2244a783          	lw	a5,548(s1)
    80004b74:	c39d                	beqz	a5,80004b9a <piperead+0x6a>
    if(myproc()->killed){
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	d28080e7          	jalr	-728(ra) # 8000189e <myproc>
    80004b7e:	591c                	lw	a5,48(a0)
    80004b80:	ebc1                	bnez	a5,80004c10 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b82:	85da                	mv	a1,s6
    80004b84:	854e                	mv	a0,s3
    80004b86:	ffffd097          	auipc	ra,0xffffd
    80004b8a:	52a080e7          	jalr	1322(ra) # 800020b0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8e:	2184a703          	lw	a4,536(s1)
    80004b92:	21c4a783          	lw	a5,540(s1)
    80004b96:	fcf70de3          	beq	a4,a5,80004b70 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b9a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b9c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b9e:	05405363          	blez	s4,80004be4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004ba2:	2184a783          	lw	a5,536(s1)
    80004ba6:	21c4a703          	lw	a4,540(s1)
    80004baa:	02f70d63          	beq	a4,a5,80004be4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bae:	0017871b          	addiw	a4,a5,1
    80004bb2:	20e4ac23          	sw	a4,536(s1)
    80004bb6:	1ff7f793          	andi	a5,a5,511
    80004bba:	97a6                	add	a5,a5,s1
    80004bbc:	0187c783          	lbu	a5,24(a5)
    80004bc0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc4:	4685                	li	a3,1
    80004bc6:	fbf40613          	addi	a2,s0,-65
    80004bca:	85ca                	mv	a1,s2
    80004bcc:	050ab503          	ld	a0,80(s5)
    80004bd0:	ffffd097          	auipc	ra,0xffffd
    80004bd4:	884080e7          	jalr	-1916(ra) # 80001454 <copyout>
    80004bd8:	01650663          	beq	a0,s6,80004be4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bdc:	2985                	addiw	s3,s3,1
    80004bde:	0905                	addi	s2,s2,1
    80004be0:	fd3a11e3          	bne	s4,s3,80004ba2 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004be4:	21c48513          	addi	a0,s1,540
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	64e080e7          	jalr	1614(ra) # 80002236 <wakeup>
  release(&pi->lock);
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	e42080e7          	jalr	-446(ra) # 80000a34 <release>
  return i;
}
    80004bfa:	854e                	mv	a0,s3
    80004bfc:	60a6                	ld	ra,72(sp)
    80004bfe:	6406                	ld	s0,64(sp)
    80004c00:	74e2                	ld	s1,56(sp)
    80004c02:	7942                	ld	s2,48(sp)
    80004c04:	79a2                	ld	s3,40(sp)
    80004c06:	7a02                	ld	s4,32(sp)
    80004c08:	6ae2                	ld	s5,24(sp)
    80004c0a:	6b42                	ld	s6,16(sp)
    80004c0c:	6161                	addi	sp,sp,80
    80004c0e:	8082                	ret
      release(&pi->lock);
    80004c10:	8526                	mv	a0,s1
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	e22080e7          	jalr	-478(ra) # 80000a34 <release>
      return -1;
    80004c1a:	59fd                	li	s3,-1
    80004c1c:	bff9                	j	80004bfa <piperead+0xca>

0000000080004c1e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c1e:	df010113          	addi	sp,sp,-528
    80004c22:	20113423          	sd	ra,520(sp)
    80004c26:	20813023          	sd	s0,512(sp)
    80004c2a:	ffa6                	sd	s1,504(sp)
    80004c2c:	fbca                	sd	s2,496(sp)
    80004c2e:	f7ce                	sd	s3,488(sp)
    80004c30:	f3d2                	sd	s4,480(sp)
    80004c32:	efd6                	sd	s5,472(sp)
    80004c34:	ebda                	sd	s6,464(sp)
    80004c36:	e7de                	sd	s7,456(sp)
    80004c38:	e3e2                	sd	s8,448(sp)
    80004c3a:	ff66                	sd	s9,440(sp)
    80004c3c:	fb6a                	sd	s10,432(sp)
    80004c3e:	f76e                	sd	s11,424(sp)
    80004c40:	0c00                	addi	s0,sp,528
    80004c42:	84aa                	mv	s1,a0
    80004c44:	dea43c23          	sd	a0,-520(s0)
    80004c48:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	c52080e7          	jalr	-942(ra) # 8000189e <myproc>
    80004c54:	892a                	mv	s2,a0

  begin_op(ROOTDEV);
    80004c56:	4501                	li	a0,0
    80004c58:	fffff097          	auipc	ra,0xfffff
    80004c5c:	31e080e7          	jalr	798(ra) # 80003f76 <begin_op>

  if((ip = namei(path)) == 0){
    80004c60:	8526                	mv	a0,s1
    80004c62:	fffff097          	auipc	ra,0xfffff
    80004c66:	ff8080e7          	jalr	-8(ra) # 80003c5a <namei>
    80004c6a:	c935                	beqz	a0,80004cde <exec+0xc0>
    80004c6c:	84aa                	mv	s1,a0
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	860080e7          	jalr	-1952(ra) # 800034ce <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c76:	04000713          	li	a4,64
    80004c7a:	4681                	li	a3,0
    80004c7c:	e4840613          	addi	a2,s0,-440
    80004c80:	4581                	li	a1,0
    80004c82:	8526                	mv	a0,s1
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	ada080e7          	jalr	-1318(ra) # 8000375e <readi>
    80004c8c:	04000793          	li	a5,64
    80004c90:	00f51a63          	bne	a0,a5,80004ca4 <exec+0x86>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c94:	e4842703          	lw	a4,-440(s0)
    80004c98:	464c47b7          	lui	a5,0x464c4
    80004c9c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ca0:	04f70663          	beq	a4,a5,80004cec <exec+0xce>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	a66080e7          	jalr	-1434(ra) # 8000370c <iunlockput>
    end_op(ROOTDEV);
    80004cae:	4501                	li	a0,0
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	370080e7          	jalr	880(ra) # 80004020 <end_op>
  }
  return -1;
    80004cb8:	557d                	li	a0,-1
}
    80004cba:	20813083          	ld	ra,520(sp)
    80004cbe:	20013403          	ld	s0,512(sp)
    80004cc2:	74fe                	ld	s1,504(sp)
    80004cc4:	795e                	ld	s2,496(sp)
    80004cc6:	79be                	ld	s3,488(sp)
    80004cc8:	7a1e                	ld	s4,480(sp)
    80004cca:	6afe                	ld	s5,472(sp)
    80004ccc:	6b5e                	ld	s6,464(sp)
    80004cce:	6bbe                	ld	s7,456(sp)
    80004cd0:	6c1e                	ld	s8,448(sp)
    80004cd2:	7cfa                	ld	s9,440(sp)
    80004cd4:	7d5a                	ld	s10,432(sp)
    80004cd6:	7dba                	ld	s11,424(sp)
    80004cd8:	21010113          	addi	sp,sp,528
    80004cdc:	8082                	ret
    end_op(ROOTDEV);
    80004cde:	4501                	li	a0,0
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	340080e7          	jalr	832(ra) # 80004020 <end_op>
    return -1;
    80004ce8:	557d                	li	a0,-1
    80004cea:	bfc1                	j	80004cba <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cec:	854a                	mv	a0,s2
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	c74080e7          	jalr	-908(ra) # 80001962 <proc_pagetable>
    80004cf6:	8c2a                	mv	s8,a0
    80004cf8:	d555                	beqz	a0,80004ca4 <exec+0x86>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cfa:	e6842983          	lw	s3,-408(s0)
    80004cfe:	e8045783          	lhu	a5,-384(s0)
    80004d02:	c7fd                	beqz	a5,80004df0 <exec+0x1d2>
  sz = 0;
    80004d04:	e0043423          	sd	zero,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d08:	4b81                	li	s7,0
    if(ph.vaddr % PGSIZE != 0)
    80004d0a:	6b05                	lui	s6,0x1
    80004d0c:	fffb0793          	addi	a5,s6,-1 # fff <_entry-0x7ffff001>
    80004d10:	def43823          	sd	a5,-528(s0)
    80004d14:	a0a5                	j	80004d7c <exec+0x15e>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d16:	00004517          	auipc	a0,0x4
    80004d1a:	a3a50513          	addi	a0,a0,-1478 # 80008750 <userret+0x6c0>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	830080e7          	jalr	-2000(ra) # 8000054e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d26:	8756                	mv	a4,s5
    80004d28:	012d86bb          	addw	a3,s11,s2
    80004d2c:	4581                	li	a1,0
    80004d2e:	8526                	mv	a0,s1
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	a2e080e7          	jalr	-1490(ra) # 8000375e <readi>
    80004d38:	2501                	sext.w	a0,a0
    80004d3a:	10aa9263          	bne	s5,a0,80004e3e <exec+0x220>
  for(i = 0; i < sz; i += PGSIZE){
    80004d3e:	6785                	lui	a5,0x1
    80004d40:	0127893b          	addw	s2,a5,s2
    80004d44:	77fd                	lui	a5,0xfffff
    80004d46:	01478a3b          	addw	s4,a5,s4
    80004d4a:	03997263          	bgeu	s2,s9,80004d6e <exec+0x150>
    pa = walkaddr(pagetable, va + i);
    80004d4e:	02091593          	slli	a1,s2,0x20
    80004d52:	9181                	srli	a1,a1,0x20
    80004d54:	95ea                	add	a1,a1,s10
    80004d56:	8562                	mv	a0,s8
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	136080e7          	jalr	310(ra) # 80000e8e <walkaddr>
    80004d60:	862a                	mv	a2,a0
    if(pa == 0)
    80004d62:	d955                	beqz	a0,80004d16 <exec+0xf8>
      n = PGSIZE;
    80004d64:	8ada                	mv	s5,s6
    if(sz - i < PGSIZE)
    80004d66:	fd6a70e3          	bgeu	s4,s6,80004d26 <exec+0x108>
      n = sz - i;
    80004d6a:	8ad2                	mv	s5,s4
    80004d6c:	bf6d                	j	80004d26 <exec+0x108>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d6e:	2b85                	addiw	s7,s7,1
    80004d70:	0389899b          	addiw	s3,s3,56
    80004d74:	e8045783          	lhu	a5,-384(s0)
    80004d78:	06fbde63          	bge	s7,a5,80004df4 <exec+0x1d6>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d7c:	2981                	sext.w	s3,s3
    80004d7e:	03800713          	li	a4,56
    80004d82:	86ce                	mv	a3,s3
    80004d84:	e1040613          	addi	a2,s0,-496
    80004d88:	4581                	li	a1,0
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	9d2080e7          	jalr	-1582(ra) # 8000375e <readi>
    80004d94:	03800793          	li	a5,56
    80004d98:	0af51363          	bne	a0,a5,80004e3e <exec+0x220>
    if(ph.type != ELF_PROG_LOAD)
    80004d9c:	e1042783          	lw	a5,-496(s0)
    80004da0:	4705                	li	a4,1
    80004da2:	fce796e3          	bne	a5,a4,80004d6e <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004da6:	e3843603          	ld	a2,-456(s0)
    80004daa:	e3043783          	ld	a5,-464(s0)
    80004dae:	08f66863          	bltu	a2,a5,80004e3e <exec+0x220>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004db2:	e2043783          	ld	a5,-480(s0)
    80004db6:	963e                	add	a2,a2,a5
    80004db8:	08f66363          	bltu	a2,a5,80004e3e <exec+0x220>
    if((sz = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004dbc:	e0843583          	ld	a1,-504(s0)
    80004dc0:	8562                	mv	a0,s8
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	4b8080e7          	jalr	1208(ra) # 8000127a <uvmalloc>
    80004dca:	e0a43423          	sd	a0,-504(s0)
    80004dce:	c925                	beqz	a0,80004e3e <exec+0x220>
    if(ph.vaddr % PGSIZE != 0)
    80004dd0:	e2043d03          	ld	s10,-480(s0)
    80004dd4:	df043783          	ld	a5,-528(s0)
    80004dd8:	00fd77b3          	and	a5,s10,a5
    80004ddc:	e3ad                	bnez	a5,80004e3e <exec+0x220>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004dde:	e1842d83          	lw	s11,-488(s0)
    80004de2:	e3042c83          	lw	s9,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004de6:	f80c84e3          	beqz	s9,80004d6e <exec+0x150>
    80004dea:	8a66                	mv	s4,s9
    80004dec:	4901                	li	s2,0
    80004dee:	b785                	j	80004d4e <exec+0x130>
  sz = 0;
    80004df0:	e0043423          	sd	zero,-504(s0)
  iunlockput(ip);
    80004df4:	8526                	mv	a0,s1
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	916080e7          	jalr	-1770(ra) # 8000370c <iunlockput>
  end_op(ROOTDEV);
    80004dfe:	4501                	li	a0,0
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	220080e7          	jalr	544(ra) # 80004020 <end_op>
  p = myproc();
    80004e08:	ffffd097          	auipc	ra,0xffffd
    80004e0c:	a96080e7          	jalr	-1386(ra) # 8000189e <myproc>
    80004e10:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e12:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e16:	6585                	lui	a1,0x1
    80004e18:	15fd                	addi	a1,a1,-1
    80004e1a:	e0843783          	ld	a5,-504(s0)
    80004e1e:	00b78b33          	add	s6,a5,a1
    80004e22:	75fd                	lui	a1,0xfffff
    80004e24:	00bb75b3          	and	a1,s6,a1
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e28:	6609                	lui	a2,0x2
    80004e2a:	962e                	add	a2,a2,a1
    80004e2c:	8562                	mv	a0,s8
    80004e2e:	ffffc097          	auipc	ra,0xffffc
    80004e32:	44c080e7          	jalr	1100(ra) # 8000127a <uvmalloc>
    80004e36:	e0a43423          	sd	a0,-504(s0)
  ip = 0;
    80004e3a:	4481                	li	s1,0
  if((sz = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e3c:	ed01                	bnez	a0,80004e54 <exec+0x236>
    proc_freepagetable(pagetable, sz);
    80004e3e:	e0843583          	ld	a1,-504(s0)
    80004e42:	8562                	mv	a0,s8
    80004e44:	ffffd097          	auipc	ra,0xffffd
    80004e48:	c1e080e7          	jalr	-994(ra) # 80001a62 <proc_freepagetable>
  if(ip){
    80004e4c:	e4049ce3          	bnez	s1,80004ca4 <exec+0x86>
  return -1;
    80004e50:	557d                	li	a0,-1
    80004e52:	b5a5                	j	80004cba <exec+0x9c>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e54:	75f9                	lui	a1,0xffffe
    80004e56:	84aa                	mv	s1,a0
    80004e58:	95aa                	add	a1,a1,a0
    80004e5a:	8562                	mv	a0,s8
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	5c6080e7          	jalr	1478(ra) # 80001422 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e64:	7afd                	lui	s5,0xfffff
    80004e66:	9aa6                	add	s5,s5,s1
  for(argc = 0; argv[argc]; argc++) {
    80004e68:	e0043783          	ld	a5,-512(s0)
    80004e6c:	6388                	ld	a0,0(a5)
    80004e6e:	c135                	beqz	a0,80004ed2 <exec+0x2b4>
    80004e70:	e8840993          	addi	s3,s0,-376
    80004e74:	f8840c93          	addi	s9,s0,-120
    80004e78:	4901                	li	s2,0
    sp -= strlen(argv[argc]) + 1;
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	d9e080e7          	jalr	-610(ra) # 80000c18 <strlen>
    80004e82:	2505                	addiw	a0,a0,1
    80004e84:	8c89                	sub	s1,s1,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e86:	98c1                	andi	s1,s1,-16
    if(sp < stackbase)
    80004e88:	0f54ea63          	bltu	s1,s5,80004f7c <exec+0x35e>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e8c:	e0043b03          	ld	s6,-512(s0)
    80004e90:	000b3a03          	ld	s4,0(s6)
    80004e94:	8552                	mv	a0,s4
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	d82080e7          	jalr	-638(ra) # 80000c18 <strlen>
    80004e9e:	0015069b          	addiw	a3,a0,1
    80004ea2:	8652                	mv	a2,s4
    80004ea4:	85a6                	mv	a1,s1
    80004ea6:	8562                	mv	a0,s8
    80004ea8:	ffffc097          	auipc	ra,0xffffc
    80004eac:	5ac080e7          	jalr	1452(ra) # 80001454 <copyout>
    80004eb0:	0c054863          	bltz	a0,80004f80 <exec+0x362>
    ustack[argc] = sp;
    80004eb4:	0099b023          	sd	s1,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eb8:	0905                	addi	s2,s2,1
    80004eba:	008b0793          	addi	a5,s6,8
    80004ebe:	e0f43023          	sd	a5,-512(s0)
    80004ec2:	008b3503          	ld	a0,8(s6)
    80004ec6:	c909                	beqz	a0,80004ed8 <exec+0x2ba>
    if(argc >= MAXARG)
    80004ec8:	09a1                	addi	s3,s3,8
    80004eca:	fb3c98e3          	bne	s9,s3,80004e7a <exec+0x25c>
  ip = 0;
    80004ece:	4481                	li	s1,0
    80004ed0:	b7bd                	j	80004e3e <exec+0x220>
  sp = sz;
    80004ed2:	e0843483          	ld	s1,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004ed6:	4901                	li	s2,0
  ustack[argc] = 0;
    80004ed8:	00391793          	slli	a5,s2,0x3
    80004edc:	f9040713          	addi	a4,s0,-112
    80004ee0:	97ba                	add	a5,a5,a4
    80004ee2:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd4e9c>
  sp -= (argc+1) * sizeof(uint64);
    80004ee6:	00190693          	addi	a3,s2,1
    80004eea:	068e                	slli	a3,a3,0x3
    80004eec:	8c95                	sub	s1,s1,a3
  sp -= sp % 16;
    80004eee:	ff04f993          	andi	s3,s1,-16
  ip = 0;
    80004ef2:	4481                	li	s1,0
  if(sp < stackbase)
    80004ef4:	f559e5e3          	bltu	s3,s5,80004e3e <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef8:	e8840613          	addi	a2,s0,-376
    80004efc:	85ce                	mv	a1,s3
    80004efe:	8562                	mv	a0,s8
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	554080e7          	jalr	1364(ra) # 80001454 <copyout>
    80004f08:	06054e63          	bltz	a0,80004f84 <exec+0x366>
  p->tf->a1 = sp;
    80004f0c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f10:	0737bc23          	sd	s3,120(a5)
  for(last=s=path; *s; s++)
    80004f14:	df843783          	ld	a5,-520(s0)
    80004f18:	0007c703          	lbu	a4,0(a5)
    80004f1c:	cf11                	beqz	a4,80004f38 <exec+0x31a>
    80004f1e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f20:	02f00693          	li	a3,47
    80004f24:	a029                	j	80004f2e <exec+0x310>
  for(last=s=path; *s; s++)
    80004f26:	0785                	addi	a5,a5,1
    80004f28:	fff7c703          	lbu	a4,-1(a5)
    80004f2c:	c711                	beqz	a4,80004f38 <exec+0x31a>
    if(*s == '/')
    80004f2e:	fed71ce3          	bne	a4,a3,80004f26 <exec+0x308>
      last = s+1;
    80004f32:	def43c23          	sd	a5,-520(s0)
    80004f36:	bfc5                	j	80004f26 <exec+0x308>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f38:	4641                	li	a2,16
    80004f3a:	df843583          	ld	a1,-520(s0)
    80004f3e:	158b8513          	addi	a0,s7,344
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	ca4080e7          	jalr	-860(ra) # 80000be6 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f4a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f4e:	058bb823          	sd	s8,80(s7)
  p->sz = sz;
    80004f52:	e0843783          	ld	a5,-504(s0)
    80004f56:	04fbb423          	sd	a5,72(s7)
  p->tf->epc = elf.entry;  // initial program counter = main
    80004f5a:	058bb783          	ld	a5,88(s7)
    80004f5e:	e6043703          	ld	a4,-416(s0)
    80004f62:	ef98                	sd	a4,24(a5)
  p->tf->sp = sp; // initial stack pointer
    80004f64:	058bb783          	ld	a5,88(s7)
    80004f68:	0337b823          	sd	s3,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f6c:	85ea                	mv	a1,s10
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	af4080e7          	jalr	-1292(ra) # 80001a62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f76:	0009051b          	sext.w	a0,s2
    80004f7a:	b381                	j	80004cba <exec+0x9c>
  ip = 0;
    80004f7c:	4481                	li	s1,0
    80004f7e:	b5c1                	j	80004e3e <exec+0x220>
    80004f80:	4481                	li	s1,0
    80004f82:	bd75                	j	80004e3e <exec+0x220>
    80004f84:	4481                	li	s1,0
    80004f86:	bd65                	j	80004e3e <exec+0x220>

0000000080004f88 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f88:	7179                	addi	sp,sp,-48
    80004f8a:	f406                	sd	ra,40(sp)
    80004f8c:	f022                	sd	s0,32(sp)
    80004f8e:	ec26                	sd	s1,24(sp)
    80004f90:	e84a                	sd	s2,16(sp)
    80004f92:	1800                	addi	s0,sp,48
    80004f94:	892e                	mv	s2,a1
    80004f96:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f98:	fdc40593          	addi	a1,s0,-36
    80004f9c:	ffffe097          	auipc	ra,0xffffe
    80004fa0:	9bc080e7          	jalr	-1604(ra) # 80002958 <argint>
    80004fa4:	04054063          	bltz	a0,80004fe4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fa8:	fdc42703          	lw	a4,-36(s0)
    80004fac:	47bd                	li	a5,15
    80004fae:	02e7ed63          	bltu	a5,a4,80004fe8 <argfd+0x60>
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	8ec080e7          	jalr	-1812(ra) # 8000189e <myproc>
    80004fba:	fdc42703          	lw	a4,-36(s0)
    80004fbe:	01a70793          	addi	a5,a4,26
    80004fc2:	078e                	slli	a5,a5,0x3
    80004fc4:	953e                	add	a0,a0,a5
    80004fc6:	611c                	ld	a5,0(a0)
    80004fc8:	c395                	beqz	a5,80004fec <argfd+0x64>
    return -1;
  if(pfd)
    80004fca:	00090463          	beqz	s2,80004fd2 <argfd+0x4a>
    *pfd = fd;
    80004fce:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fd2:	4501                	li	a0,0
  if(pf)
    80004fd4:	c091                	beqz	s1,80004fd8 <argfd+0x50>
    *pf = f;
    80004fd6:	e09c                	sd	a5,0(s1)
}
    80004fd8:	70a2                	ld	ra,40(sp)
    80004fda:	7402                	ld	s0,32(sp)
    80004fdc:	64e2                	ld	s1,24(sp)
    80004fde:	6942                	ld	s2,16(sp)
    80004fe0:	6145                	addi	sp,sp,48
    80004fe2:	8082                	ret
    return -1;
    80004fe4:	557d                	li	a0,-1
    80004fe6:	bfcd                	j	80004fd8 <argfd+0x50>
    return -1;
    80004fe8:	557d                	li	a0,-1
    80004fea:	b7fd                	j	80004fd8 <argfd+0x50>
    80004fec:	557d                	li	a0,-1
    80004fee:	b7ed                	j	80004fd8 <argfd+0x50>

0000000080004ff0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ff0:	1101                	addi	sp,sp,-32
    80004ff2:	ec06                	sd	ra,24(sp)
    80004ff4:	e822                	sd	s0,16(sp)
    80004ff6:	e426                	sd	s1,8(sp)
    80004ff8:	1000                	addi	s0,sp,32
    80004ffa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	8a2080e7          	jalr	-1886(ra) # 8000189e <myproc>
    80005004:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005006:	0d050793          	addi	a5,a0,208
    8000500a:	4501                	li	a0,0
    8000500c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000500e:	6398                	ld	a4,0(a5)
    80005010:	cb19                	beqz	a4,80005026 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005012:	2505                	addiw	a0,a0,1
    80005014:	07a1                	addi	a5,a5,8
    80005016:	fed51ce3          	bne	a0,a3,8000500e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000501a:	557d                	li	a0,-1
}
    8000501c:	60e2                	ld	ra,24(sp)
    8000501e:	6442                	ld	s0,16(sp)
    80005020:	64a2                	ld	s1,8(sp)
    80005022:	6105                	addi	sp,sp,32
    80005024:	8082                	ret
      p->ofile[fd] = f;
    80005026:	01a50793          	addi	a5,a0,26
    8000502a:	078e                	slli	a5,a5,0x3
    8000502c:	963e                	add	a2,a2,a5
    8000502e:	e204                	sd	s1,0(a2)
      return fd;
    80005030:	b7f5                	j	8000501c <fdalloc+0x2c>

0000000080005032 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005032:	715d                	addi	sp,sp,-80
    80005034:	e486                	sd	ra,72(sp)
    80005036:	e0a2                	sd	s0,64(sp)
    80005038:	fc26                	sd	s1,56(sp)
    8000503a:	f84a                	sd	s2,48(sp)
    8000503c:	f44e                	sd	s3,40(sp)
    8000503e:	f052                	sd	s4,32(sp)
    80005040:	ec56                	sd	s5,24(sp)
    80005042:	0880                	addi	s0,sp,80
    80005044:	89ae                	mv	s3,a1
    80005046:	8ab2                	mv	s5,a2
    80005048:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000504a:	fb040593          	addi	a1,s0,-80
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	c2a080e7          	jalr	-982(ra) # 80003c78 <nameiparent>
    80005056:	892a                	mv	s2,a0
    80005058:	12050e63          	beqz	a0,80005194 <create+0x162>
    return 0;

  ilock(dp);
    8000505c:	ffffe097          	auipc	ra,0xffffe
    80005060:	472080e7          	jalr	1138(ra) # 800034ce <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005064:	4601                	li	a2,0
    80005066:	fb040593          	addi	a1,s0,-80
    8000506a:	854a                	mv	a0,s2
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	91c080e7          	jalr	-1764(ra) # 80003988 <dirlookup>
    80005074:	84aa                	mv	s1,a0
    80005076:	c921                	beqz	a0,800050c6 <create+0x94>
    iunlockput(dp);
    80005078:	854a                	mv	a0,s2
    8000507a:	ffffe097          	auipc	ra,0xffffe
    8000507e:	692080e7          	jalr	1682(ra) # 8000370c <iunlockput>
    ilock(ip);
    80005082:	8526                	mv	a0,s1
    80005084:	ffffe097          	auipc	ra,0xffffe
    80005088:	44a080e7          	jalr	1098(ra) # 800034ce <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000508c:	2981                	sext.w	s3,s3
    8000508e:	4789                	li	a5,2
    80005090:	02f99463          	bne	s3,a5,800050b8 <create+0x86>
    80005094:	0444d783          	lhu	a5,68(s1)
    80005098:	37f9                	addiw	a5,a5,-2
    8000509a:	17c2                	slli	a5,a5,0x30
    8000509c:	93c1                	srli	a5,a5,0x30
    8000509e:	4705                	li	a4,1
    800050a0:	00f76c63          	bltu	a4,a5,800050b8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050a4:	8526                	mv	a0,s1
    800050a6:	60a6                	ld	ra,72(sp)
    800050a8:	6406                	ld	s0,64(sp)
    800050aa:	74e2                	ld	s1,56(sp)
    800050ac:	7942                	ld	s2,48(sp)
    800050ae:	79a2                	ld	s3,40(sp)
    800050b0:	7a02                	ld	s4,32(sp)
    800050b2:	6ae2                	ld	s5,24(sp)
    800050b4:	6161                	addi	sp,sp,80
    800050b6:	8082                	ret
    iunlockput(ip);
    800050b8:	8526                	mv	a0,s1
    800050ba:	ffffe097          	auipc	ra,0xffffe
    800050be:	652080e7          	jalr	1618(ra) # 8000370c <iunlockput>
    return 0;
    800050c2:	4481                	li	s1,0
    800050c4:	b7c5                	j	800050a4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050c6:	85ce                	mv	a1,s3
    800050c8:	00092503          	lw	a0,0(s2)
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	26a080e7          	jalr	618(ra) # 80003336 <ialloc>
    800050d4:	84aa                	mv	s1,a0
    800050d6:	c521                	beqz	a0,8000511e <create+0xec>
  ilock(ip);
    800050d8:	ffffe097          	auipc	ra,0xffffe
    800050dc:	3f6080e7          	jalr	1014(ra) # 800034ce <ilock>
  ip->major = major;
    800050e0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050e4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050e8:	4a05                	li	s4,1
    800050ea:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050ee:	8526                	mv	a0,s1
    800050f0:	ffffe097          	auipc	ra,0xffffe
    800050f4:	314080e7          	jalr	788(ra) # 80003404 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050f8:	2981                	sext.w	s3,s3
    800050fa:	03498a63          	beq	s3,s4,8000512e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800050fe:	40d0                	lw	a2,4(s1)
    80005100:	fb040593          	addi	a1,s0,-80
    80005104:	854a                	mv	a0,s2
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	a92080e7          	jalr	-1390(ra) # 80003b98 <dirlink>
    8000510e:	06054b63          	bltz	a0,80005184 <create+0x152>
  iunlockput(dp);
    80005112:	854a                	mv	a0,s2
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	5f8080e7          	jalr	1528(ra) # 8000370c <iunlockput>
  return ip;
    8000511c:	b761                	j	800050a4 <create+0x72>
    panic("create: ialloc");
    8000511e:	00003517          	auipc	a0,0x3
    80005122:	65250513          	addi	a0,a0,1618 # 80008770 <userret+0x6e0>
    80005126:	ffffb097          	auipc	ra,0xffffb
    8000512a:	428080e7          	jalr	1064(ra) # 8000054e <panic>
    dp->nlink++;  // for ".."
    8000512e:	04a95783          	lhu	a5,74(s2)
    80005132:	2785                	addiw	a5,a5,1
    80005134:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005138:	854a                	mv	a0,s2
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	2ca080e7          	jalr	714(ra) # 80003404 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005142:	40d0                	lw	a2,4(s1)
    80005144:	00003597          	auipc	a1,0x3
    80005148:	63c58593          	addi	a1,a1,1596 # 80008780 <userret+0x6f0>
    8000514c:	8526                	mv	a0,s1
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	a4a080e7          	jalr	-1462(ra) # 80003b98 <dirlink>
    80005156:	00054f63          	bltz	a0,80005174 <create+0x142>
    8000515a:	00492603          	lw	a2,4(s2)
    8000515e:	00003597          	auipc	a1,0x3
    80005162:	62a58593          	addi	a1,a1,1578 # 80008788 <userret+0x6f8>
    80005166:	8526                	mv	a0,s1
    80005168:	fffff097          	auipc	ra,0xfffff
    8000516c:	a30080e7          	jalr	-1488(ra) # 80003b98 <dirlink>
    80005170:	f80557e3          	bgez	a0,800050fe <create+0xcc>
      panic("create dots");
    80005174:	00003517          	auipc	a0,0x3
    80005178:	61c50513          	addi	a0,a0,1564 # 80008790 <userret+0x700>
    8000517c:	ffffb097          	auipc	ra,0xffffb
    80005180:	3d2080e7          	jalr	978(ra) # 8000054e <panic>
    panic("create: dirlink");
    80005184:	00003517          	auipc	a0,0x3
    80005188:	61c50513          	addi	a0,a0,1564 # 800087a0 <userret+0x710>
    8000518c:	ffffb097          	auipc	ra,0xffffb
    80005190:	3c2080e7          	jalr	962(ra) # 8000054e <panic>
    return 0;
    80005194:	84aa                	mv	s1,a0
    80005196:	b739                	j	800050a4 <create+0x72>

0000000080005198 <sys_dup>:
{
    80005198:	7179                	addi	sp,sp,-48
    8000519a:	f406                	sd	ra,40(sp)
    8000519c:	f022                	sd	s0,32(sp)
    8000519e:	ec26                	sd	s1,24(sp)
    800051a0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051a2:	fd840613          	addi	a2,s0,-40
    800051a6:	4581                	li	a1,0
    800051a8:	4501                	li	a0,0
    800051aa:	00000097          	auipc	ra,0x0
    800051ae:	dde080e7          	jalr	-546(ra) # 80004f88 <argfd>
    return -1;
    800051b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051b4:	02054363          	bltz	a0,800051da <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051b8:	fd843503          	ld	a0,-40(s0)
    800051bc:	00000097          	auipc	ra,0x0
    800051c0:	e34080e7          	jalr	-460(ra) # 80004ff0 <fdalloc>
    800051c4:	84aa                	mv	s1,a0
    return -1;
    800051c6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051c8:	00054963          	bltz	a0,800051da <sys_dup+0x42>
  filedup(f);
    800051cc:	fd843503          	ld	a0,-40(s0)
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	37c080e7          	jalr	892(ra) # 8000454c <filedup>
  return fd;
    800051d8:	87a6                	mv	a5,s1
}
    800051da:	853e                	mv	a0,a5
    800051dc:	70a2                	ld	ra,40(sp)
    800051de:	7402                	ld	s0,32(sp)
    800051e0:	64e2                	ld	s1,24(sp)
    800051e2:	6145                	addi	sp,sp,48
    800051e4:	8082                	ret

00000000800051e6 <sys_read>:
{
    800051e6:	7179                	addi	sp,sp,-48
    800051e8:	f406                	sd	ra,40(sp)
    800051ea:	f022                	sd	s0,32(sp)
    800051ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ee:	fe840613          	addi	a2,s0,-24
    800051f2:	4581                	li	a1,0
    800051f4:	4501                	li	a0,0
    800051f6:	00000097          	auipc	ra,0x0
    800051fa:	d92080e7          	jalr	-622(ra) # 80004f88 <argfd>
    return -1;
    800051fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005200:	04054163          	bltz	a0,80005242 <sys_read+0x5c>
    80005204:	fe440593          	addi	a1,s0,-28
    80005208:	4509                	li	a0,2
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	74e080e7          	jalr	1870(ra) # 80002958 <argint>
    return -1;
    80005212:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005214:	02054763          	bltz	a0,80005242 <sys_read+0x5c>
    80005218:	fd840593          	addi	a1,s0,-40
    8000521c:	4505                	li	a0,1
    8000521e:	ffffd097          	auipc	ra,0xffffd
    80005222:	75c080e7          	jalr	1884(ra) # 8000297a <argaddr>
    return -1;
    80005226:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005228:	00054d63          	bltz	a0,80005242 <sys_read+0x5c>
  return fileread(f, p, n);
    8000522c:	fe442603          	lw	a2,-28(s0)
    80005230:	fd843583          	ld	a1,-40(s0)
    80005234:	fe843503          	ld	a0,-24(s0)
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	4a8080e7          	jalr	1192(ra) # 800046e0 <fileread>
    80005240:	87aa                	mv	a5,a0
}
    80005242:	853e                	mv	a0,a5
    80005244:	70a2                	ld	ra,40(sp)
    80005246:	7402                	ld	s0,32(sp)
    80005248:	6145                	addi	sp,sp,48
    8000524a:	8082                	ret

000000008000524c <sys_write>:
{
    8000524c:	7179                	addi	sp,sp,-48
    8000524e:	f406                	sd	ra,40(sp)
    80005250:	f022                	sd	s0,32(sp)
    80005252:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005254:	fe840613          	addi	a2,s0,-24
    80005258:	4581                	li	a1,0
    8000525a:	4501                	li	a0,0
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	d2c080e7          	jalr	-724(ra) # 80004f88 <argfd>
    return -1;
    80005264:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005266:	04054163          	bltz	a0,800052a8 <sys_write+0x5c>
    8000526a:	fe440593          	addi	a1,s0,-28
    8000526e:	4509                	li	a0,2
    80005270:	ffffd097          	auipc	ra,0xffffd
    80005274:	6e8080e7          	jalr	1768(ra) # 80002958 <argint>
    return -1;
    80005278:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527a:	02054763          	bltz	a0,800052a8 <sys_write+0x5c>
    8000527e:	fd840593          	addi	a1,s0,-40
    80005282:	4505                	li	a0,1
    80005284:	ffffd097          	auipc	ra,0xffffd
    80005288:	6f6080e7          	jalr	1782(ra) # 8000297a <argaddr>
    return -1;
    8000528c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528e:	00054d63          	bltz	a0,800052a8 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005292:	fe442603          	lw	a2,-28(s0)
    80005296:	fd843583          	ld	a1,-40(s0)
    8000529a:	fe843503          	ld	a0,-24(s0)
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	4f0080e7          	jalr	1264(ra) # 8000478e <filewrite>
    800052a6:	87aa                	mv	a5,a0
}
    800052a8:	853e                	mv	a0,a5
    800052aa:	70a2                	ld	ra,40(sp)
    800052ac:	7402                	ld	s0,32(sp)
    800052ae:	6145                	addi	sp,sp,48
    800052b0:	8082                	ret

00000000800052b2 <sys_close>:
{
    800052b2:	1101                	addi	sp,sp,-32
    800052b4:	ec06                	sd	ra,24(sp)
    800052b6:	e822                	sd	s0,16(sp)
    800052b8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052ba:	fe040613          	addi	a2,s0,-32
    800052be:	fec40593          	addi	a1,s0,-20
    800052c2:	4501                	li	a0,0
    800052c4:	00000097          	auipc	ra,0x0
    800052c8:	cc4080e7          	jalr	-828(ra) # 80004f88 <argfd>
    return -1;
    800052cc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052ce:	02054463          	bltz	a0,800052f6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	5cc080e7          	jalr	1484(ra) # 8000189e <myproc>
    800052da:	fec42783          	lw	a5,-20(s0)
    800052de:	07e9                	addi	a5,a5,26
    800052e0:	078e                	slli	a5,a5,0x3
    800052e2:	97aa                	add	a5,a5,a0
    800052e4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052e8:	fe043503          	ld	a0,-32(s0)
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	2b2080e7          	jalr	690(ra) # 8000459e <fileclose>
  return 0;
    800052f4:	4781                	li	a5,0
}
    800052f6:	853e                	mv	a0,a5
    800052f8:	60e2                	ld	ra,24(sp)
    800052fa:	6442                	ld	s0,16(sp)
    800052fc:	6105                	addi	sp,sp,32
    800052fe:	8082                	ret

0000000080005300 <sys_fstat>:
{
    80005300:	1101                	addi	sp,sp,-32
    80005302:	ec06                	sd	ra,24(sp)
    80005304:	e822                	sd	s0,16(sp)
    80005306:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005308:	fe840613          	addi	a2,s0,-24
    8000530c:	4581                	li	a1,0
    8000530e:	4501                	li	a0,0
    80005310:	00000097          	auipc	ra,0x0
    80005314:	c78080e7          	jalr	-904(ra) # 80004f88 <argfd>
    return -1;
    80005318:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000531a:	02054563          	bltz	a0,80005344 <sys_fstat+0x44>
    8000531e:	fe040593          	addi	a1,s0,-32
    80005322:	4505                	li	a0,1
    80005324:	ffffd097          	auipc	ra,0xffffd
    80005328:	656080e7          	jalr	1622(ra) # 8000297a <argaddr>
    return -1;
    8000532c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000532e:	00054b63          	bltz	a0,80005344 <sys_fstat+0x44>
  return filestat(f, st);
    80005332:	fe043583          	ld	a1,-32(s0)
    80005336:	fe843503          	ld	a0,-24(s0)
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	334080e7          	jalr	820(ra) # 8000466e <filestat>
    80005342:	87aa                	mv	a5,a0
}
    80005344:	853e                	mv	a0,a5
    80005346:	60e2                	ld	ra,24(sp)
    80005348:	6442                	ld	s0,16(sp)
    8000534a:	6105                	addi	sp,sp,32
    8000534c:	8082                	ret

000000008000534e <sys_link>:
{
    8000534e:	7169                	addi	sp,sp,-304
    80005350:	f606                	sd	ra,296(sp)
    80005352:	f222                	sd	s0,288(sp)
    80005354:	ee26                	sd	s1,280(sp)
    80005356:	ea4a                	sd	s2,272(sp)
    80005358:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000535a:	08000613          	li	a2,128
    8000535e:	ed040593          	addi	a1,s0,-304
    80005362:	4501                	li	a0,0
    80005364:	ffffd097          	auipc	ra,0xffffd
    80005368:	638080e7          	jalr	1592(ra) # 8000299c <argstr>
    return -1;
    8000536c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000536e:	12054363          	bltz	a0,80005494 <sys_link+0x146>
    80005372:	08000613          	li	a2,128
    80005376:	f5040593          	addi	a1,s0,-176
    8000537a:	4505                	li	a0,1
    8000537c:	ffffd097          	auipc	ra,0xffffd
    80005380:	620080e7          	jalr	1568(ra) # 8000299c <argstr>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005386:	10054763          	bltz	a0,80005494 <sys_link+0x146>
  begin_op(ROOTDEV);
    8000538a:	4501                	li	a0,0
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	bea080e7          	jalr	-1046(ra) # 80003f76 <begin_op>
  if((ip = namei(old)) == 0){
    80005394:	ed040513          	addi	a0,s0,-304
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	8c2080e7          	jalr	-1854(ra) # 80003c5a <namei>
    800053a0:	84aa                	mv	s1,a0
    800053a2:	c559                	beqz	a0,80005430 <sys_link+0xe2>
  ilock(ip);
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	12a080e7          	jalr	298(ra) # 800034ce <ilock>
  if(ip->type == T_DIR){
    800053ac:	04449703          	lh	a4,68(s1)
    800053b0:	4785                	li	a5,1
    800053b2:	08f70663          	beq	a4,a5,8000543e <sys_link+0xf0>
  ip->nlink++;
    800053b6:	04a4d783          	lhu	a5,74(s1)
    800053ba:	2785                	addiw	a5,a5,1
    800053bc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053c0:	8526                	mv	a0,s1
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	042080e7          	jalr	66(ra) # 80003404 <iupdate>
  iunlock(ip);
    800053ca:	8526                	mv	a0,s1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	1c4080e7          	jalr	452(ra) # 80003590 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053d4:	fd040593          	addi	a1,s0,-48
    800053d8:	f5040513          	addi	a0,s0,-176
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	89c080e7          	jalr	-1892(ra) # 80003c78 <nameiparent>
    800053e4:	892a                	mv	s2,a0
    800053e6:	cd2d                	beqz	a0,80005460 <sys_link+0x112>
  ilock(dp);
    800053e8:	ffffe097          	auipc	ra,0xffffe
    800053ec:	0e6080e7          	jalr	230(ra) # 800034ce <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053f0:	00092703          	lw	a4,0(s2)
    800053f4:	409c                	lw	a5,0(s1)
    800053f6:	06f71063          	bne	a4,a5,80005456 <sys_link+0x108>
    800053fa:	40d0                	lw	a2,4(s1)
    800053fc:	fd040593          	addi	a1,s0,-48
    80005400:	854a                	mv	a0,s2
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	796080e7          	jalr	1942(ra) # 80003b98 <dirlink>
    8000540a:	04054663          	bltz	a0,80005456 <sys_link+0x108>
  iunlockput(dp);
    8000540e:	854a                	mv	a0,s2
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	2fc080e7          	jalr	764(ra) # 8000370c <iunlockput>
  iput(ip);
    80005418:	8526                	mv	a0,s1
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	1c2080e7          	jalr	450(ra) # 800035dc <iput>
  end_op(ROOTDEV);
    80005422:	4501                	li	a0,0
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	bfc080e7          	jalr	-1028(ra) # 80004020 <end_op>
  return 0;
    8000542c:	4781                	li	a5,0
    8000542e:	a09d                	j	80005494 <sys_link+0x146>
    end_op(ROOTDEV);
    80005430:	4501                	li	a0,0
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	bee080e7          	jalr	-1042(ra) # 80004020 <end_op>
    return -1;
    8000543a:	57fd                	li	a5,-1
    8000543c:	a8a1                	j	80005494 <sys_link+0x146>
    iunlockput(ip);
    8000543e:	8526                	mv	a0,s1
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	2cc080e7          	jalr	716(ra) # 8000370c <iunlockput>
    end_op(ROOTDEV);
    80005448:	4501                	li	a0,0
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	bd6080e7          	jalr	-1066(ra) # 80004020 <end_op>
    return -1;
    80005452:	57fd                	li	a5,-1
    80005454:	a081                	j	80005494 <sys_link+0x146>
    iunlockput(dp);
    80005456:	854a                	mv	a0,s2
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	2b4080e7          	jalr	692(ra) # 8000370c <iunlockput>
  ilock(ip);
    80005460:	8526                	mv	a0,s1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	06c080e7          	jalr	108(ra) # 800034ce <ilock>
  ip->nlink--;
    8000546a:	04a4d783          	lhu	a5,74(s1)
    8000546e:	37fd                	addiw	a5,a5,-1
    80005470:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	f8e080e7          	jalr	-114(ra) # 80003404 <iupdate>
  iunlockput(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	28c080e7          	jalr	652(ra) # 8000370c <iunlockput>
  end_op(ROOTDEV);
    80005488:	4501                	li	a0,0
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	b96080e7          	jalr	-1130(ra) # 80004020 <end_op>
  return -1;
    80005492:	57fd                	li	a5,-1
}
    80005494:	853e                	mv	a0,a5
    80005496:	70b2                	ld	ra,296(sp)
    80005498:	7412                	ld	s0,288(sp)
    8000549a:	64f2                	ld	s1,280(sp)
    8000549c:	6952                	ld	s2,272(sp)
    8000549e:	6155                	addi	sp,sp,304
    800054a0:	8082                	ret

00000000800054a2 <sys_unlink>:
{
    800054a2:	7151                	addi	sp,sp,-240
    800054a4:	f586                	sd	ra,232(sp)
    800054a6:	f1a2                	sd	s0,224(sp)
    800054a8:	eda6                	sd	s1,216(sp)
    800054aa:	e9ca                	sd	s2,208(sp)
    800054ac:	e5ce                	sd	s3,200(sp)
    800054ae:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054b0:	08000613          	li	a2,128
    800054b4:	f3040593          	addi	a1,s0,-208
    800054b8:	4501                	li	a0,0
    800054ba:	ffffd097          	auipc	ra,0xffffd
    800054be:	4e2080e7          	jalr	1250(ra) # 8000299c <argstr>
    800054c2:	18054463          	bltz	a0,8000564a <sys_unlink+0x1a8>
  begin_op(ROOTDEV);
    800054c6:	4501                	li	a0,0
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	aae080e7          	jalr	-1362(ra) # 80003f76 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054d0:	fb040593          	addi	a1,s0,-80
    800054d4:	f3040513          	addi	a0,s0,-208
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	7a0080e7          	jalr	1952(ra) # 80003c78 <nameiparent>
    800054e0:	84aa                	mv	s1,a0
    800054e2:	cd61                	beqz	a0,800055ba <sys_unlink+0x118>
  ilock(dp);
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	fea080e7          	jalr	-22(ra) # 800034ce <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054ec:	00003597          	auipc	a1,0x3
    800054f0:	29458593          	addi	a1,a1,660 # 80008780 <userret+0x6f0>
    800054f4:	fb040513          	addi	a0,s0,-80
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	476080e7          	jalr	1142(ra) # 8000396e <namecmp>
    80005500:	14050c63          	beqz	a0,80005658 <sys_unlink+0x1b6>
    80005504:	00003597          	auipc	a1,0x3
    80005508:	28458593          	addi	a1,a1,644 # 80008788 <userret+0x6f8>
    8000550c:	fb040513          	addi	a0,s0,-80
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	45e080e7          	jalr	1118(ra) # 8000396e <namecmp>
    80005518:	14050063          	beqz	a0,80005658 <sys_unlink+0x1b6>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000551c:	f2c40613          	addi	a2,s0,-212
    80005520:	fb040593          	addi	a1,s0,-80
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	462080e7          	jalr	1122(ra) # 80003988 <dirlookup>
    8000552e:	892a                	mv	s2,a0
    80005530:	12050463          	beqz	a0,80005658 <sys_unlink+0x1b6>
  ilock(ip);
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	f9a080e7          	jalr	-102(ra) # 800034ce <ilock>
  if(ip->nlink < 1)
    8000553c:	04a91783          	lh	a5,74(s2)
    80005540:	08f05463          	blez	a5,800055c8 <sys_unlink+0x126>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005544:	04491703          	lh	a4,68(s2)
    80005548:	4785                	li	a5,1
    8000554a:	08f70763          	beq	a4,a5,800055d8 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    8000554e:	4641                	li	a2,16
    80005550:	4581                	li	a1,0
    80005552:	fc040513          	addi	a0,s0,-64
    80005556:	ffffb097          	auipc	ra,0xffffb
    8000555a:	53a080e7          	jalr	1338(ra) # 80000a90 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000555e:	4741                	li	a4,16
    80005560:	f2c42683          	lw	a3,-212(s0)
    80005564:	fc040613          	addi	a2,s0,-64
    80005568:	4581                	li	a1,0
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	2e6080e7          	jalr	742(ra) # 80003852 <writei>
    80005574:	47c1                	li	a5,16
    80005576:	0af51763          	bne	a0,a5,80005624 <sys_unlink+0x182>
  if(ip->type == T_DIR){
    8000557a:	04491703          	lh	a4,68(s2)
    8000557e:	4785                	li	a5,1
    80005580:	0af70a63          	beq	a4,a5,80005634 <sys_unlink+0x192>
  iunlockput(dp);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	186080e7          	jalr	390(ra) # 8000370c <iunlockput>
  ip->nlink--;
    8000558e:	04a95783          	lhu	a5,74(s2)
    80005592:	37fd                	addiw	a5,a5,-1
    80005594:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005598:	854a                	mv	a0,s2
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	e6a080e7          	jalr	-406(ra) # 80003404 <iupdate>
  iunlockput(ip);
    800055a2:	854a                	mv	a0,s2
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	168080e7          	jalr	360(ra) # 8000370c <iunlockput>
  end_op(ROOTDEV);
    800055ac:	4501                	li	a0,0
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	a72080e7          	jalr	-1422(ra) # 80004020 <end_op>
  return 0;
    800055b6:	4501                	li	a0,0
    800055b8:	a85d                	j	8000566e <sys_unlink+0x1cc>
    end_op(ROOTDEV);
    800055ba:	4501                	li	a0,0
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	a64080e7          	jalr	-1436(ra) # 80004020 <end_op>
    return -1;
    800055c4:	557d                	li	a0,-1
    800055c6:	a065                	j	8000566e <sys_unlink+0x1cc>
    panic("unlink: nlink < 1");
    800055c8:	00003517          	auipc	a0,0x3
    800055cc:	1e850513          	addi	a0,a0,488 # 800087b0 <userret+0x720>
    800055d0:	ffffb097          	auipc	ra,0xffffb
    800055d4:	f7e080e7          	jalr	-130(ra) # 8000054e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055d8:	04c92703          	lw	a4,76(s2)
    800055dc:	02000793          	li	a5,32
    800055e0:	f6e7f7e3          	bgeu	a5,a4,8000554e <sys_unlink+0xac>
    800055e4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e8:	4741                	li	a4,16
    800055ea:	86ce                	mv	a3,s3
    800055ec:	f1840613          	addi	a2,s0,-232
    800055f0:	4581                	li	a1,0
    800055f2:	854a                	mv	a0,s2
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	16a080e7          	jalr	362(ra) # 8000375e <readi>
    800055fc:	47c1                	li	a5,16
    800055fe:	00f51b63          	bne	a0,a5,80005614 <sys_unlink+0x172>
    if(de.inum != 0)
    80005602:	f1845783          	lhu	a5,-232(s0)
    80005606:	e7a1                	bnez	a5,8000564e <sys_unlink+0x1ac>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005608:	29c1                	addiw	s3,s3,16
    8000560a:	04c92783          	lw	a5,76(s2)
    8000560e:	fcf9ede3          	bltu	s3,a5,800055e8 <sys_unlink+0x146>
    80005612:	bf35                	j	8000554e <sys_unlink+0xac>
      panic("isdirempty: readi");
    80005614:	00003517          	auipc	a0,0x3
    80005618:	1b450513          	addi	a0,a0,436 # 800087c8 <userret+0x738>
    8000561c:	ffffb097          	auipc	ra,0xffffb
    80005620:	f32080e7          	jalr	-206(ra) # 8000054e <panic>
    panic("unlink: writei");
    80005624:	00003517          	auipc	a0,0x3
    80005628:	1bc50513          	addi	a0,a0,444 # 800087e0 <userret+0x750>
    8000562c:	ffffb097          	auipc	ra,0xffffb
    80005630:	f22080e7          	jalr	-222(ra) # 8000054e <panic>
    dp->nlink--;
    80005634:	04a4d783          	lhu	a5,74(s1)
    80005638:	37fd                	addiw	a5,a5,-1
    8000563a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	dc4080e7          	jalr	-572(ra) # 80003404 <iupdate>
    80005648:	bf35                	j	80005584 <sys_unlink+0xe2>
    return -1;
    8000564a:	557d                	li	a0,-1
    8000564c:	a00d                	j	8000566e <sys_unlink+0x1cc>
    iunlockput(ip);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	0bc080e7          	jalr	188(ra) # 8000370c <iunlockput>
  iunlockput(dp);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	0b2080e7          	jalr	178(ra) # 8000370c <iunlockput>
  end_op(ROOTDEV);
    80005662:	4501                	li	a0,0
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	9bc080e7          	jalr	-1604(ra) # 80004020 <end_op>
  return -1;
    8000566c:	557d                	li	a0,-1
}
    8000566e:	70ae                	ld	ra,232(sp)
    80005670:	740e                	ld	s0,224(sp)
    80005672:	64ee                	ld	s1,216(sp)
    80005674:	694e                	ld	s2,208(sp)
    80005676:	69ae                	ld	s3,200(sp)
    80005678:	616d                	addi	sp,sp,240
    8000567a:	8082                	ret

000000008000567c <sys_open>:

uint64
sys_open(void)
{
    8000567c:	7131                	addi	sp,sp,-192
    8000567e:	fd06                	sd	ra,184(sp)
    80005680:	f922                	sd	s0,176(sp)
    80005682:	f526                	sd	s1,168(sp)
    80005684:	f14a                	sd	s2,160(sp)
    80005686:	ed4e                	sd	s3,152(sp)
    80005688:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000568a:	08000613          	li	a2,128
    8000568e:	f5040593          	addi	a1,s0,-176
    80005692:	4501                	li	a0,0
    80005694:	ffffd097          	auipc	ra,0xffffd
    80005698:	308080e7          	jalr	776(ra) # 8000299c <argstr>
    return -1;
    8000569c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000569e:	0a054963          	bltz	a0,80005750 <sys_open+0xd4>
    800056a2:	f4c40593          	addi	a1,s0,-180
    800056a6:	4505                	li	a0,1
    800056a8:	ffffd097          	auipc	ra,0xffffd
    800056ac:	2b0080e7          	jalr	688(ra) # 80002958 <argint>
    800056b0:	0a054063          	bltz	a0,80005750 <sys_open+0xd4>

  begin_op(ROOTDEV);
    800056b4:	4501                	li	a0,0
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	8c0080e7          	jalr	-1856(ra) # 80003f76 <begin_op>

  if(omode & O_CREATE){
    800056be:	f4c42783          	lw	a5,-180(s0)
    800056c2:	2007f793          	andi	a5,a5,512
    800056c6:	c3dd                	beqz	a5,8000576c <sys_open+0xf0>
    ip = create(path, T_FILE, 0, 0);
    800056c8:	4681                	li	a3,0
    800056ca:	4601                	li	a2,0
    800056cc:	4589                	li	a1,2
    800056ce:	f5040513          	addi	a0,s0,-176
    800056d2:	00000097          	auipc	ra,0x0
    800056d6:	960080e7          	jalr	-1696(ra) # 80005032 <create>
    800056da:	892a                	mv	s2,a0
    if(ip == 0){
    800056dc:	c151                	beqz	a0,80005760 <sys_open+0xe4>
      end_op(ROOTDEV);
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056de:	04491703          	lh	a4,68(s2)
    800056e2:	478d                	li	a5,3
    800056e4:	00f71763          	bne	a4,a5,800056f2 <sys_open+0x76>
    800056e8:	04695703          	lhu	a4,70(s2)
    800056ec:	47a5                	li	a5,9
    800056ee:	0ce7e663          	bltu	a5,a4,800057ba <sys_open+0x13e>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	df0080e7          	jalr	-528(ra) # 800044e2 <filealloc>
    800056fa:	89aa                	mv	s3,a0
    800056fc:	c57d                	beqz	a0,800057ea <sys_open+0x16e>
    800056fe:	00000097          	auipc	ra,0x0
    80005702:	8f2080e7          	jalr	-1806(ra) # 80004ff0 <fdalloc>
    80005706:	84aa                	mv	s1,a0
    80005708:	0c054c63          	bltz	a0,800057e0 <sys_open+0x164>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000570c:	04491703          	lh	a4,68(s2)
    80005710:	478d                	li	a5,3
    80005712:	0cf70063          	beq	a4,a5,800057d2 <sys_open+0x156>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005716:	4789                	li	a5,2
    80005718:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000571c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005720:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005724:	f4c42783          	lw	a5,-180(s0)
    80005728:	0017c713          	xori	a4,a5,1
    8000572c:	8b05                	andi	a4,a4,1
    8000572e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005732:	8b8d                	andi	a5,a5,3
    80005734:	00f037b3          	snez	a5,a5
    80005738:	00f984a3          	sb	a5,9(s3)

  iunlock(ip);
    8000573c:	854a                	mv	a0,s2
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	e52080e7          	jalr	-430(ra) # 80003590 <iunlock>
  end_op(ROOTDEV);
    80005746:	4501                	li	a0,0
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	8d8080e7          	jalr	-1832(ra) # 80004020 <end_op>

  return fd;
}
    80005750:	8526                	mv	a0,s1
    80005752:	70ea                	ld	ra,184(sp)
    80005754:	744a                	ld	s0,176(sp)
    80005756:	74aa                	ld	s1,168(sp)
    80005758:	790a                	ld	s2,160(sp)
    8000575a:	69ea                	ld	s3,152(sp)
    8000575c:	6129                	addi	sp,sp,192
    8000575e:	8082                	ret
      end_op(ROOTDEV);
    80005760:	4501                	li	a0,0
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	8be080e7          	jalr	-1858(ra) # 80004020 <end_op>
      return -1;
    8000576a:	b7dd                	j	80005750 <sys_open+0xd4>
    if((ip = namei(path)) == 0){
    8000576c:	f5040513          	addi	a0,s0,-176
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	4ea080e7          	jalr	1258(ra) # 80003c5a <namei>
    80005778:	892a                	mv	s2,a0
    8000577a:	c90d                	beqz	a0,800057ac <sys_open+0x130>
    ilock(ip);
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	d52080e7          	jalr	-686(ra) # 800034ce <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005784:	04491703          	lh	a4,68(s2)
    80005788:	4785                	li	a5,1
    8000578a:	f4f71ae3          	bne	a4,a5,800056de <sys_open+0x62>
    8000578e:	f4c42783          	lw	a5,-180(s0)
    80005792:	d3a5                	beqz	a5,800056f2 <sys_open+0x76>
      iunlockput(ip);
    80005794:	854a                	mv	a0,s2
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	f76080e7          	jalr	-138(ra) # 8000370c <iunlockput>
      end_op(ROOTDEV);
    8000579e:	4501                	li	a0,0
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	880080e7          	jalr	-1920(ra) # 80004020 <end_op>
      return -1;
    800057a8:	54fd                	li	s1,-1
    800057aa:	b75d                	j	80005750 <sys_open+0xd4>
      end_op(ROOTDEV);
    800057ac:	4501                	li	a0,0
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	872080e7          	jalr	-1934(ra) # 80004020 <end_op>
      return -1;
    800057b6:	54fd                	li	s1,-1
    800057b8:	bf61                	j	80005750 <sys_open+0xd4>
    iunlockput(ip);
    800057ba:	854a                	mv	a0,s2
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	f50080e7          	jalr	-176(ra) # 8000370c <iunlockput>
    end_op(ROOTDEV);
    800057c4:	4501                	li	a0,0
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	85a080e7          	jalr	-1958(ra) # 80004020 <end_op>
    return -1;
    800057ce:	54fd                	li	s1,-1
    800057d0:	b741                	j	80005750 <sys_open+0xd4>
    f->type = FD_DEVICE;
    800057d2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057d6:	04691783          	lh	a5,70(s2)
    800057da:	02f99223          	sh	a5,36(s3)
    800057de:	b789                	j	80005720 <sys_open+0xa4>
      fileclose(f);
    800057e0:	854e                	mv	a0,s3
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	dbc080e7          	jalr	-580(ra) # 8000459e <fileclose>
    iunlockput(ip);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	f20080e7          	jalr	-224(ra) # 8000370c <iunlockput>
    end_op(ROOTDEV);
    800057f4:	4501                	li	a0,0
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	82a080e7          	jalr	-2006(ra) # 80004020 <end_op>
    return -1;
    800057fe:	54fd                	li	s1,-1
    80005800:	bf81                	j	80005750 <sys_open+0xd4>

0000000080005802 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005802:	7175                	addi	sp,sp,-144
    80005804:	e506                	sd	ra,136(sp)
    80005806:	e122                	sd	s0,128(sp)
    80005808:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op(ROOTDEV);
    8000580a:	4501                	li	a0,0
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	76a080e7          	jalr	1898(ra) # 80003f76 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005814:	08000613          	li	a2,128
    80005818:	f7040593          	addi	a1,s0,-144
    8000581c:	4501                	li	a0,0
    8000581e:	ffffd097          	auipc	ra,0xffffd
    80005822:	17e080e7          	jalr	382(ra) # 8000299c <argstr>
    80005826:	02054a63          	bltz	a0,8000585a <sys_mkdir+0x58>
    8000582a:	4681                	li	a3,0
    8000582c:	4601                	li	a2,0
    8000582e:	4585                	li	a1,1
    80005830:	f7040513          	addi	a0,s0,-144
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	7fe080e7          	jalr	2046(ra) # 80005032 <create>
    8000583c:	cd19                	beqz	a0,8000585a <sys_mkdir+0x58>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	ece080e7          	jalr	-306(ra) # 8000370c <iunlockput>
  end_op(ROOTDEV);
    80005846:	4501                	li	a0,0
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	7d8080e7          	jalr	2008(ra) # 80004020 <end_op>
  return 0;
    80005850:	4501                	li	a0,0
}
    80005852:	60aa                	ld	ra,136(sp)
    80005854:	640a                	ld	s0,128(sp)
    80005856:	6149                	addi	sp,sp,144
    80005858:	8082                	ret
    end_op(ROOTDEV);
    8000585a:	4501                	li	a0,0
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	7c4080e7          	jalr	1988(ra) # 80004020 <end_op>
    return -1;
    80005864:	557d                	li	a0,-1
    80005866:	b7f5                	j	80005852 <sys_mkdir+0x50>

0000000080005868 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005868:	7135                	addi	sp,sp,-160
    8000586a:	ed06                	sd	ra,152(sp)
    8000586c:	e922                	sd	s0,144(sp)
    8000586e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op(ROOTDEV);
    80005870:	4501                	li	a0,0
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	704080e7          	jalr	1796(ra) # 80003f76 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000587a:	08000613          	li	a2,128
    8000587e:	f7040593          	addi	a1,s0,-144
    80005882:	4501                	li	a0,0
    80005884:	ffffd097          	auipc	ra,0xffffd
    80005888:	118080e7          	jalr	280(ra) # 8000299c <argstr>
    8000588c:	04054b63          	bltz	a0,800058e2 <sys_mknod+0x7a>
     argint(1, &major) < 0 ||
    80005890:	f6c40593          	addi	a1,s0,-148
    80005894:	4505                	li	a0,1
    80005896:	ffffd097          	auipc	ra,0xffffd
    8000589a:	0c2080e7          	jalr	194(ra) # 80002958 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000589e:	04054263          	bltz	a0,800058e2 <sys_mknod+0x7a>
     argint(2, &minor) < 0 ||
    800058a2:	f6840593          	addi	a1,s0,-152
    800058a6:	4509                	li	a0,2
    800058a8:	ffffd097          	auipc	ra,0xffffd
    800058ac:	0b0080e7          	jalr	176(ra) # 80002958 <argint>
     argint(1, &major) < 0 ||
    800058b0:	02054963          	bltz	a0,800058e2 <sys_mknod+0x7a>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058b4:	f6841683          	lh	a3,-152(s0)
    800058b8:	f6c41603          	lh	a2,-148(s0)
    800058bc:	458d                	li	a1,3
    800058be:	f7040513          	addi	a0,s0,-144
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	770080e7          	jalr	1904(ra) # 80005032 <create>
     argint(2, &minor) < 0 ||
    800058ca:	cd01                	beqz	a0,800058e2 <sys_mknod+0x7a>
    end_op(ROOTDEV);
    return -1;
  }
  iunlockput(ip);
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	e40080e7          	jalr	-448(ra) # 8000370c <iunlockput>
  end_op(ROOTDEV);
    800058d4:	4501                	li	a0,0
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	74a080e7          	jalr	1866(ra) # 80004020 <end_op>
  return 0;
    800058de:	4501                	li	a0,0
    800058e0:	a039                	j	800058ee <sys_mknod+0x86>
    end_op(ROOTDEV);
    800058e2:	4501                	li	a0,0
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	73c080e7          	jalr	1852(ra) # 80004020 <end_op>
    return -1;
    800058ec:	557d                	li	a0,-1
}
    800058ee:	60ea                	ld	ra,152(sp)
    800058f0:	644a                	ld	s0,144(sp)
    800058f2:	610d                	addi	sp,sp,160
    800058f4:	8082                	ret

00000000800058f6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058f6:	7135                	addi	sp,sp,-160
    800058f8:	ed06                	sd	ra,152(sp)
    800058fa:	e922                	sd	s0,144(sp)
    800058fc:	e526                	sd	s1,136(sp)
    800058fe:	e14a                	sd	s2,128(sp)
    80005900:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005902:	ffffc097          	auipc	ra,0xffffc
    80005906:	f9c080e7          	jalr	-100(ra) # 8000189e <myproc>
    8000590a:	892a                	mv	s2,a0
  
  begin_op(ROOTDEV);
    8000590c:	4501                	li	a0,0
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	668080e7          	jalr	1640(ra) # 80003f76 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005916:	08000613          	li	a2,128
    8000591a:	f6040593          	addi	a1,s0,-160
    8000591e:	4501                	li	a0,0
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	07c080e7          	jalr	124(ra) # 8000299c <argstr>
    80005928:	04054c63          	bltz	a0,80005980 <sys_chdir+0x8a>
    8000592c:	f6040513          	addi	a0,s0,-160
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	32a080e7          	jalr	810(ra) # 80003c5a <namei>
    80005938:	84aa                	mv	s1,a0
    8000593a:	c139                	beqz	a0,80005980 <sys_chdir+0x8a>
    end_op(ROOTDEV);
    return -1;
  }
  ilock(ip);
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	b92080e7          	jalr	-1134(ra) # 800034ce <ilock>
  if(ip->type != T_DIR){
    80005944:	04449703          	lh	a4,68(s1)
    80005948:	4785                	li	a5,1
    8000594a:	04f71263          	bne	a4,a5,8000598e <sys_chdir+0x98>
    iunlockput(ip);
    end_op(ROOTDEV);
    return -1;
  }
  iunlock(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	c40080e7          	jalr	-960(ra) # 80003590 <iunlock>
  iput(p->cwd);
    80005958:	15093503          	ld	a0,336(s2)
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	c80080e7          	jalr	-896(ra) # 800035dc <iput>
  end_op(ROOTDEV);
    80005964:	4501                	li	a0,0
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	6ba080e7          	jalr	1722(ra) # 80004020 <end_op>
  p->cwd = ip;
    8000596e:	14993823          	sd	s1,336(s2)
  return 0;
    80005972:	4501                	li	a0,0
}
    80005974:	60ea                	ld	ra,152(sp)
    80005976:	644a                	ld	s0,144(sp)
    80005978:	64aa                	ld	s1,136(sp)
    8000597a:	690a                	ld	s2,128(sp)
    8000597c:	610d                	addi	sp,sp,160
    8000597e:	8082                	ret
    end_op(ROOTDEV);
    80005980:	4501                	li	a0,0
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	69e080e7          	jalr	1694(ra) # 80004020 <end_op>
    return -1;
    8000598a:	557d                	li	a0,-1
    8000598c:	b7e5                	j	80005974 <sys_chdir+0x7e>
    iunlockput(ip);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	d7c080e7          	jalr	-644(ra) # 8000370c <iunlockput>
    end_op(ROOTDEV);
    80005998:	4501                	li	a0,0
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	686080e7          	jalr	1670(ra) # 80004020 <end_op>
    return -1;
    800059a2:	557d                	li	a0,-1
    800059a4:	bfc1                	j	80005974 <sys_chdir+0x7e>

00000000800059a6 <sys_exec>:

uint64
sys_exec(void)
{
    800059a6:	7145                	addi	sp,sp,-464
    800059a8:	e786                	sd	ra,456(sp)
    800059aa:	e3a2                	sd	s0,448(sp)
    800059ac:	ff26                	sd	s1,440(sp)
    800059ae:	fb4a                	sd	s2,432(sp)
    800059b0:	f74e                	sd	s3,424(sp)
    800059b2:	f352                	sd	s4,416(sp)
    800059b4:	ef56                	sd	s5,408(sp)
    800059b6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059b8:	08000613          	li	a2,128
    800059bc:	f4040593          	addi	a1,s0,-192
    800059c0:	4501                	li	a0,0
    800059c2:	ffffd097          	auipc	ra,0xffffd
    800059c6:	fda080e7          	jalr	-38(ra) # 8000299c <argstr>
    800059ca:	0c054863          	bltz	a0,80005a9a <sys_exec+0xf4>
    800059ce:	e3840593          	addi	a1,s0,-456
    800059d2:	4505                	li	a0,1
    800059d4:	ffffd097          	auipc	ra,0xffffd
    800059d8:	fa6080e7          	jalr	-90(ra) # 8000297a <argaddr>
    800059dc:	0c054963          	bltz	a0,80005aae <sys_exec+0x108>
    return -1;
  }
  memset(argv, 0, sizeof(argv));
    800059e0:	10000613          	li	a2,256
    800059e4:	4581                	li	a1,0
    800059e6:	e4040513          	addi	a0,s0,-448
    800059ea:	ffffb097          	auipc	ra,0xffffb
    800059ee:	0a6080e7          	jalr	166(ra) # 80000a90 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059f2:	e4040993          	addi	s3,s0,-448
  memset(argv, 0, sizeof(argv));
    800059f6:	894e                	mv	s2,s3
    800059f8:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    800059fa:	02000a13          	li	s4,32
    800059fe:	00048a9b          	sext.w	s5,s1
      return -1;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a02:	00349513          	slli	a0,s1,0x3
    80005a06:	e3040593          	addi	a1,s0,-464
    80005a0a:	e3843783          	ld	a5,-456(s0)
    80005a0e:	953e                	add	a0,a0,a5
    80005a10:	ffffd097          	auipc	ra,0xffffd
    80005a14:	eae080e7          	jalr	-338(ra) # 800028be <fetchaddr>
    80005a18:	08054d63          	bltz	a0,80005ab2 <sys_exec+0x10c>
      return -1;
    }
    if(uarg == 0){
    80005a1c:	e3043783          	ld	a5,-464(s0)
    80005a20:	cb85                	beqz	a5,80005a50 <sys_exec+0xaa>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	e7e080e7          	jalr	-386(ra) # 800008a0 <kalloc>
    80005a2a:	85aa                	mv	a1,a0
    80005a2c:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80005a30:	cd29                	beqz	a0,80005a8a <sys_exec+0xe4>
      panic("sys_exec kalloc");
    if(fetchstr(uarg, argv[i], PGSIZE) < 0){
    80005a32:	6605                	lui	a2,0x1
    80005a34:	e3043503          	ld	a0,-464(s0)
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	ed8080e7          	jalr	-296(ra) # 80002910 <fetchstr>
    80005a40:	06054b63          	bltz	a0,80005ab6 <sys_exec+0x110>
    if(i >= NELEM(argv)){
    80005a44:	0485                	addi	s1,s1,1
    80005a46:	0921                	addi	s2,s2,8
    80005a48:	fb449be3          	bne	s1,s4,800059fe <sys_exec+0x58>
      return -1;
    80005a4c:	557d                	li	a0,-1
    80005a4e:	a0b9                	j	80005a9c <sys_exec+0xf6>
      argv[i] = 0;
    80005a50:	0a8e                	slli	s5,s5,0x3
    80005a52:	fc040793          	addi	a5,s0,-64
    80005a56:	9abe                	add	s5,s5,a5
    80005a58:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd4e24>
      return -1;
    }
  }

  int ret = exec(path, argv);
    80005a5c:	e4040593          	addi	a1,s0,-448
    80005a60:	f4040513          	addi	a0,s0,-192
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	1ba080e7          	jalr	442(ra) # 80004c1e <exec>
    80005a6c:	84aa                	mv	s1,a0

  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a6e:	10098913          	addi	s2,s3,256
    80005a72:	0009b503          	ld	a0,0(s3)
    80005a76:	c901                	beqz	a0,80005a86 <sys_exec+0xe0>
    kfree(argv[i]);
    80005a78:	ffffb097          	auipc	ra,0xffffb
    80005a7c:	e10080e7          	jalr	-496(ra) # 80000888 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a80:	09a1                	addi	s3,s3,8
    80005a82:	ff2998e3          	bne	s3,s2,80005a72 <sys_exec+0xcc>

  return ret;
    80005a86:	8526                	mv	a0,s1
    80005a88:	a811                	j	80005a9c <sys_exec+0xf6>
      panic("sys_exec kalloc");
    80005a8a:	00003517          	auipc	a0,0x3
    80005a8e:	d6650513          	addi	a0,a0,-666 # 800087f0 <userret+0x760>
    80005a92:	ffffb097          	auipc	ra,0xffffb
    80005a96:	abc080e7          	jalr	-1348(ra) # 8000054e <panic>
    return -1;
    80005a9a:	557d                	li	a0,-1
}
    80005a9c:	60be                	ld	ra,456(sp)
    80005a9e:	641e                	ld	s0,448(sp)
    80005aa0:	74fa                	ld	s1,440(sp)
    80005aa2:	795a                	ld	s2,432(sp)
    80005aa4:	79ba                	ld	s3,424(sp)
    80005aa6:	7a1a                	ld	s4,416(sp)
    80005aa8:	6afa                	ld	s5,408(sp)
    80005aaa:	6179                	addi	sp,sp,464
    80005aac:	8082                	ret
    return -1;
    80005aae:	557d                	li	a0,-1
    80005ab0:	b7f5                	j	80005a9c <sys_exec+0xf6>
      return -1;
    80005ab2:	557d                	li	a0,-1
    80005ab4:	b7e5                	j	80005a9c <sys_exec+0xf6>
      return -1;
    80005ab6:	557d                	li	a0,-1
    80005ab8:	b7d5                	j	80005a9c <sys_exec+0xf6>

0000000080005aba <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aba:	7139                	addi	sp,sp,-64
    80005abc:	fc06                	sd	ra,56(sp)
    80005abe:	f822                	sd	s0,48(sp)
    80005ac0:	f426                	sd	s1,40(sp)
    80005ac2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ac4:	ffffc097          	auipc	ra,0xffffc
    80005ac8:	dda080e7          	jalr	-550(ra) # 8000189e <myproc>
    80005acc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ace:	fd840593          	addi	a1,s0,-40
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	ea6080e7          	jalr	-346(ra) # 8000297a <argaddr>
    return -1;
    80005adc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ade:	0e054063          	bltz	a0,80005bbe <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ae2:	fc840593          	addi	a1,s0,-56
    80005ae6:	fd040513          	addi	a0,s0,-48
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	de8080e7          	jalr	-536(ra) # 800048d2 <pipealloc>
    return -1;
    80005af2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005af4:	0c054563          	bltz	a0,80005bbe <sys_pipe+0x104>
  fd0 = -1;
    80005af8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005afc:	fd043503          	ld	a0,-48(s0)
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	4f0080e7          	jalr	1264(ra) # 80004ff0 <fdalloc>
    80005b08:	fca42223          	sw	a0,-60(s0)
    80005b0c:	08054c63          	bltz	a0,80005ba4 <sys_pipe+0xea>
    80005b10:	fc843503          	ld	a0,-56(s0)
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	4dc080e7          	jalr	1244(ra) # 80004ff0 <fdalloc>
    80005b1c:	fca42023          	sw	a0,-64(s0)
    80005b20:	06054863          	bltz	a0,80005b90 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b24:	4691                	li	a3,4
    80005b26:	fc440613          	addi	a2,s0,-60
    80005b2a:	fd843583          	ld	a1,-40(s0)
    80005b2e:	68a8                	ld	a0,80(s1)
    80005b30:	ffffc097          	auipc	ra,0xffffc
    80005b34:	924080e7          	jalr	-1756(ra) # 80001454 <copyout>
    80005b38:	02054063          	bltz	a0,80005b58 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b3c:	4691                	li	a3,4
    80005b3e:	fc040613          	addi	a2,s0,-64
    80005b42:	fd843583          	ld	a1,-40(s0)
    80005b46:	0591                	addi	a1,a1,4
    80005b48:	68a8                	ld	a0,80(s1)
    80005b4a:	ffffc097          	auipc	ra,0xffffc
    80005b4e:	90a080e7          	jalr	-1782(ra) # 80001454 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b52:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b54:	06055563          	bgez	a0,80005bbe <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b58:	fc442783          	lw	a5,-60(s0)
    80005b5c:	07e9                	addi	a5,a5,26
    80005b5e:	078e                	slli	a5,a5,0x3
    80005b60:	97a6                	add	a5,a5,s1
    80005b62:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b66:	fc042503          	lw	a0,-64(s0)
    80005b6a:	0569                	addi	a0,a0,26
    80005b6c:	050e                	slli	a0,a0,0x3
    80005b6e:	9526                	add	a0,a0,s1
    80005b70:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b74:	fd043503          	ld	a0,-48(s0)
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	a26080e7          	jalr	-1498(ra) # 8000459e <fileclose>
    fileclose(wf);
    80005b80:	fc843503          	ld	a0,-56(s0)
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	a1a080e7          	jalr	-1510(ra) # 8000459e <fileclose>
    return -1;
    80005b8c:	57fd                	li	a5,-1
    80005b8e:	a805                	j	80005bbe <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b90:	fc442783          	lw	a5,-60(s0)
    80005b94:	0007c863          	bltz	a5,80005ba4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b98:	01a78513          	addi	a0,a5,26
    80005b9c:	050e                	slli	a0,a0,0x3
    80005b9e:	9526                	add	a0,a0,s1
    80005ba0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ba4:	fd043503          	ld	a0,-48(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	9f6080e7          	jalr	-1546(ra) # 8000459e <fileclose>
    fileclose(wf);
    80005bb0:	fc843503          	ld	a0,-56(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	9ea080e7          	jalr	-1558(ra) # 8000459e <fileclose>
    return -1;
    80005bbc:	57fd                	li	a5,-1
}
    80005bbe:	853e                	mv	a0,a5
    80005bc0:	70e2                	ld	ra,56(sp)
    80005bc2:	7442                	ld	s0,48(sp)
    80005bc4:	74a2                	ld	s1,40(sp)
    80005bc6:	6121                	addi	sp,sp,64
    80005bc8:	8082                	ret

0000000080005bca <sys_crash>:

// system call to test crashes
uint64
sys_crash(void)
{
    80005bca:	7171                	addi	sp,sp,-176
    80005bcc:	f506                	sd	ra,168(sp)
    80005bce:	f122                	sd	s0,160(sp)
    80005bd0:	ed26                	sd	s1,152(sp)
    80005bd2:	1900                	addi	s0,sp,176
  char path[MAXPATH];
  struct inode *ip;
  int crash;
  
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005bd4:	08000613          	li	a2,128
    80005bd8:	f6040593          	addi	a1,s0,-160
    80005bdc:	4501                	li	a0,0
    80005bde:	ffffd097          	auipc	ra,0xffffd
    80005be2:	dbe080e7          	jalr	-578(ra) # 8000299c <argstr>
    return -1;
    80005be6:	57fd                	li	a5,-1
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005be8:	04054363          	bltz	a0,80005c2e <sys_crash+0x64>
    80005bec:	f5c40593          	addi	a1,s0,-164
    80005bf0:	4505                	li	a0,1
    80005bf2:	ffffd097          	auipc	ra,0xffffd
    80005bf6:	d66080e7          	jalr	-666(ra) # 80002958 <argint>
    return -1;
    80005bfa:	57fd                	li	a5,-1
  if(argstr(0, path, MAXPATH) < 0 || argint(1, &crash) < 0)
    80005bfc:	02054963          	bltz	a0,80005c2e <sys_crash+0x64>
  ip = create(path, T_FILE, 0, 0);
    80005c00:	4681                	li	a3,0
    80005c02:	4601                	li	a2,0
    80005c04:	4589                	li	a1,2
    80005c06:	f6040513          	addi	a0,s0,-160
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	428080e7          	jalr	1064(ra) # 80005032 <create>
    80005c12:	84aa                	mv	s1,a0
  if(ip == 0){
    80005c14:	c11d                	beqz	a0,80005c3a <sys_crash+0x70>
    return -1;
  }
  iunlockput(ip);
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	af6080e7          	jalr	-1290(ra) # 8000370c <iunlockput>
  crash_op(ip->dev, crash);
    80005c1e:	f5c42583          	lw	a1,-164(s0)
    80005c22:	4088                	lw	a0,0(s1)
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	64e080e7          	jalr	1614(ra) # 80004272 <crash_op>
  return 0;
    80005c2c:	4781                	li	a5,0
}
    80005c2e:	853e                	mv	a0,a5
    80005c30:	70aa                	ld	ra,168(sp)
    80005c32:	740a                	ld	s0,160(sp)
    80005c34:	64ea                	ld	s1,152(sp)
    80005c36:	614d                	addi	sp,sp,176
    80005c38:	8082                	ret
    return -1;
    80005c3a:	57fd                	li	a5,-1
    80005c3c:	bfcd                	j	80005c2e <sys_crash+0x64>
	...

0000000080005c40 <kernelvec>:
    80005c40:	7111                	addi	sp,sp,-256
    80005c42:	e006                	sd	ra,0(sp)
    80005c44:	e40a                	sd	sp,8(sp)
    80005c46:	e80e                	sd	gp,16(sp)
    80005c48:	ec12                	sd	tp,24(sp)
    80005c4a:	f016                	sd	t0,32(sp)
    80005c4c:	f41a                	sd	t1,40(sp)
    80005c4e:	f81e                	sd	t2,48(sp)
    80005c50:	fc22                	sd	s0,56(sp)
    80005c52:	e0a6                	sd	s1,64(sp)
    80005c54:	e4aa                	sd	a0,72(sp)
    80005c56:	e8ae                	sd	a1,80(sp)
    80005c58:	ecb2                	sd	a2,88(sp)
    80005c5a:	f0b6                	sd	a3,96(sp)
    80005c5c:	f4ba                	sd	a4,104(sp)
    80005c5e:	f8be                	sd	a5,112(sp)
    80005c60:	fcc2                	sd	a6,120(sp)
    80005c62:	e146                	sd	a7,128(sp)
    80005c64:	e54a                	sd	s2,136(sp)
    80005c66:	e94e                	sd	s3,144(sp)
    80005c68:	ed52                	sd	s4,152(sp)
    80005c6a:	f156                	sd	s5,160(sp)
    80005c6c:	f55a                	sd	s6,168(sp)
    80005c6e:	f95e                	sd	s7,176(sp)
    80005c70:	fd62                	sd	s8,184(sp)
    80005c72:	e1e6                	sd	s9,192(sp)
    80005c74:	e5ea                	sd	s10,200(sp)
    80005c76:	e9ee                	sd	s11,208(sp)
    80005c78:	edf2                	sd	t3,216(sp)
    80005c7a:	f1f6                	sd	t4,224(sp)
    80005c7c:	f5fa                	sd	t5,232(sp)
    80005c7e:	f9fe                	sd	t6,240(sp)
    80005c80:	b0bfc0ef          	jal	ra,8000278a <kerneltrap>
    80005c84:	6082                	ld	ra,0(sp)
    80005c86:	6122                	ld	sp,8(sp)
    80005c88:	61c2                	ld	gp,16(sp)
    80005c8a:	7282                	ld	t0,32(sp)
    80005c8c:	7322                	ld	t1,40(sp)
    80005c8e:	73c2                	ld	t2,48(sp)
    80005c90:	7462                	ld	s0,56(sp)
    80005c92:	6486                	ld	s1,64(sp)
    80005c94:	6526                	ld	a0,72(sp)
    80005c96:	65c6                	ld	a1,80(sp)
    80005c98:	6666                	ld	a2,88(sp)
    80005c9a:	7686                	ld	a3,96(sp)
    80005c9c:	7726                	ld	a4,104(sp)
    80005c9e:	77c6                	ld	a5,112(sp)
    80005ca0:	7866                	ld	a6,120(sp)
    80005ca2:	688a                	ld	a7,128(sp)
    80005ca4:	692a                	ld	s2,136(sp)
    80005ca6:	69ca                	ld	s3,144(sp)
    80005ca8:	6a6a                	ld	s4,152(sp)
    80005caa:	7a8a                	ld	s5,160(sp)
    80005cac:	7b2a                	ld	s6,168(sp)
    80005cae:	7bca                	ld	s7,176(sp)
    80005cb0:	7c6a                	ld	s8,184(sp)
    80005cb2:	6c8e                	ld	s9,192(sp)
    80005cb4:	6d2e                	ld	s10,200(sp)
    80005cb6:	6dce                	ld	s11,208(sp)
    80005cb8:	6e6e                	ld	t3,216(sp)
    80005cba:	7e8e                	ld	t4,224(sp)
    80005cbc:	7f2e                	ld	t5,232(sp)
    80005cbe:	7fce                	ld	t6,240(sp)
    80005cc0:	6111                	addi	sp,sp,256
    80005cc2:	10200073          	sret
    80005cc6:	00000013          	nop
    80005cca:	00000013          	nop
    80005cce:	0001                	nop

0000000080005cd0 <timervec>:
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	e10c                	sd	a1,0(a0)
    80005cd6:	e510                	sd	a2,8(a0)
    80005cd8:	e914                	sd	a3,16(a0)
    80005cda:	710c                	ld	a1,32(a0)
    80005cdc:	7510                	ld	a2,40(a0)
    80005cde:	6194                	ld	a3,0(a1)
    80005ce0:	96b2                	add	a3,a3,a2
    80005ce2:	e194                	sd	a3,0(a1)
    80005ce4:	4589                	li	a1,2
    80005ce6:	14459073          	csrw	sip,a1
    80005cea:	6914                	ld	a3,16(a0)
    80005cec:	6510                	ld	a2,8(a0)
    80005cee:	610c                	ld	a1,0(a0)
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	30200073          	mret
	...

0000000080005cfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cfa:	1141                	addi	sp,sp,-16
    80005cfc:	e422                	sd	s0,8(sp)
    80005cfe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d00:	0c0007b7          	lui	a5,0xc000
    80005d04:	4705                	li	a4,1
    80005d06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d08:	c3d8                	sw	a4,4(a5)
}
    80005d0a:	6422                	ld	s0,8(sp)
    80005d0c:	0141                	addi	sp,sp,16
    80005d0e:	8082                	ret

0000000080005d10 <plicinithart>:

void
plicinithart(void)
{
    80005d10:	1141                	addi	sp,sp,-16
    80005d12:	e406                	sd	ra,8(sp)
    80005d14:	e022                	sd	s0,0(sp)
    80005d16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	b5a080e7          	jalr	-1190(ra) # 80001872 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d20:	0085171b          	slliw	a4,a0,0x8
    80005d24:	0c0027b7          	lui	a5,0xc002
    80005d28:	97ba                	add	a5,a5,a4
    80005d2a:	40200713          	li	a4,1026
    80005d2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d32:	00d5151b          	slliw	a0,a0,0xd
    80005d36:	0c2017b7          	lui	a5,0xc201
    80005d3a:	953e                	add	a0,a0,a5
    80005d3c:	00052023          	sw	zero,0(a0)
}
    80005d40:	60a2                	ld	ra,8(sp)
    80005d42:	6402                	ld	s0,0(sp)
    80005d44:	0141                	addi	sp,sp,16
    80005d46:	8082                	ret

0000000080005d48 <plic_pending>:

// return a bitmap of which IRQs are waiting
// to be served.
uint64
plic_pending(void)
{
    80005d48:	1141                	addi	sp,sp,-16
    80005d4a:	e422                	sd	s0,8(sp)
    80005d4c:	0800                	addi	s0,sp,16
  //mask = *(uint32*)(PLIC + 0x1000);
  //mask |= (uint64)*(uint32*)(PLIC + 0x1004) << 32;
  mask = *(uint64*)PLIC_PENDING;

  return mask;
}
    80005d4e:	0c0017b7          	lui	a5,0xc001
    80005d52:	6388                	ld	a0,0(a5)
    80005d54:	6422                	ld	s0,8(sp)
    80005d56:	0141                	addi	sp,sp,16
    80005d58:	8082                	ret

0000000080005d5a <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d5a:	1141                	addi	sp,sp,-16
    80005d5c:	e406                	sd	ra,8(sp)
    80005d5e:	e022                	sd	s0,0(sp)
    80005d60:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d62:	ffffc097          	auipc	ra,0xffffc
    80005d66:	b10080e7          	jalr	-1264(ra) # 80001872 <cpuid>
  //int irq = *(uint32*)(PLIC + 0x201004);
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d6a:	00d5179b          	slliw	a5,a0,0xd
    80005d6e:	0c201537          	lui	a0,0xc201
    80005d72:	953e                	add	a0,a0,a5
  return irq;
}
    80005d74:	4148                	lw	a0,4(a0)
    80005d76:	60a2                	ld	ra,8(sp)
    80005d78:	6402                	ld	s0,0(sp)
    80005d7a:	0141                	addi	sp,sp,16
    80005d7c:	8082                	ret

0000000080005d7e <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d7e:	1101                	addi	sp,sp,-32
    80005d80:	ec06                	sd	ra,24(sp)
    80005d82:	e822                	sd	s0,16(sp)
    80005d84:	e426                	sd	s1,8(sp)
    80005d86:	1000                	addi	s0,sp,32
    80005d88:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d8a:	ffffc097          	auipc	ra,0xffffc
    80005d8e:	ae8080e7          	jalr	-1304(ra) # 80001872 <cpuid>
  //*(uint32*)(PLIC + 0x201004) = irq;
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d92:	00d5151b          	slliw	a0,a0,0xd
    80005d96:	0c2017b7          	lui	a5,0xc201
    80005d9a:	97aa                	add	a5,a5,a0
    80005d9c:	c3c4                	sw	s1,4(a5)
}
    80005d9e:	60e2                	ld	ra,24(sp)
    80005da0:	6442                	ld	s0,16(sp)
    80005da2:	64a2                	ld	s1,8(sp)
    80005da4:	6105                	addi	sp,sp,32
    80005da6:	8082                	ret

0000000080005da8 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int n, int i)
{
    80005da8:	1141                	addi	sp,sp,-16
    80005daa:	e406                	sd	ra,8(sp)
    80005dac:	e022                	sd	s0,0(sp)
    80005dae:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005db0:	479d                	li	a5,7
    80005db2:	06b7c963          	blt	a5,a1,80005e24 <free_desc+0x7c>
    panic("virtio_disk_intr 1");
  if(disk[n].free[i])
    80005db6:	00151793          	slli	a5,a0,0x1
    80005dba:	97aa                	add	a5,a5,a0
    80005dbc:	00c79713          	slli	a4,a5,0xc
    80005dc0:	0001e797          	auipc	a5,0x1e
    80005dc4:	24078793          	addi	a5,a5,576 # 80024000 <disk>
    80005dc8:	97ba                	add	a5,a5,a4
    80005dca:	97ae                	add	a5,a5,a1
    80005dcc:	6709                	lui	a4,0x2
    80005dce:	97ba                	add	a5,a5,a4
    80005dd0:	0187c783          	lbu	a5,24(a5)
    80005dd4:	e3a5                	bnez	a5,80005e34 <free_desc+0x8c>
    panic("virtio_disk_intr 2");
  disk[n].desc[i].addr = 0;
    80005dd6:	0001e817          	auipc	a6,0x1e
    80005dda:	22a80813          	addi	a6,a6,554 # 80024000 <disk>
    80005dde:	00151693          	slli	a3,a0,0x1
    80005de2:	00a68733          	add	a4,a3,a0
    80005de6:	0732                	slli	a4,a4,0xc
    80005de8:	00e807b3          	add	a5,a6,a4
    80005dec:	6709                	lui	a4,0x2
    80005dee:	00f70633          	add	a2,a4,a5
    80005df2:	6210                	ld	a2,0(a2)
    80005df4:	00459893          	slli	a7,a1,0x4
    80005df8:	9646                	add	a2,a2,a7
    80005dfa:	00063023          	sd	zero,0(a2) # 1000 <_entry-0x7ffff000>
  disk[n].free[i] = 1;
    80005dfe:	97ae                	add	a5,a5,a1
    80005e00:	97ba                	add	a5,a5,a4
    80005e02:	4605                	li	a2,1
    80005e04:	00c78c23          	sb	a2,24(a5)
  wakeup(&disk[n].free[0]);
    80005e08:	96aa                	add	a3,a3,a0
    80005e0a:	06b2                	slli	a3,a3,0xc
    80005e0c:	0761                	addi	a4,a4,24
    80005e0e:	96ba                	add	a3,a3,a4
    80005e10:	00d80533          	add	a0,a6,a3
    80005e14:	ffffc097          	auipc	ra,0xffffc
    80005e18:	422080e7          	jalr	1058(ra) # 80002236 <wakeup>
}
    80005e1c:	60a2                	ld	ra,8(sp)
    80005e1e:	6402                	ld	s0,0(sp)
    80005e20:	0141                	addi	sp,sp,16
    80005e22:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e24:	00003517          	auipc	a0,0x3
    80005e28:	9dc50513          	addi	a0,a0,-1572 # 80008800 <userret+0x770>
    80005e2c:	ffffa097          	auipc	ra,0xffffa
    80005e30:	722080e7          	jalr	1826(ra) # 8000054e <panic>
    panic("virtio_disk_intr 2");
    80005e34:	00003517          	auipc	a0,0x3
    80005e38:	9e450513          	addi	a0,a0,-1564 # 80008818 <userret+0x788>
    80005e3c:	ffffa097          	auipc	ra,0xffffa
    80005e40:	712080e7          	jalr	1810(ra) # 8000054e <panic>

0000000080005e44 <virtio_disk_init>:
  __sync_synchronize();
    80005e44:	0ff0000f          	fence
  if(disk[n].init)
    80005e48:	00151793          	slli	a5,a0,0x1
    80005e4c:	97aa                	add	a5,a5,a0
    80005e4e:	07b2                	slli	a5,a5,0xc
    80005e50:	0001e717          	auipc	a4,0x1e
    80005e54:	1b070713          	addi	a4,a4,432 # 80024000 <disk>
    80005e58:	973e                	add	a4,a4,a5
    80005e5a:	6789                	lui	a5,0x2
    80005e5c:	97ba                	add	a5,a5,a4
    80005e5e:	0a87a783          	lw	a5,168(a5) # 20a8 <_entry-0x7fffdf58>
    80005e62:	c391                	beqz	a5,80005e66 <virtio_disk_init+0x22>
    80005e64:	8082                	ret
{
    80005e66:	7139                	addi	sp,sp,-64
    80005e68:	fc06                	sd	ra,56(sp)
    80005e6a:	f822                	sd	s0,48(sp)
    80005e6c:	f426                	sd	s1,40(sp)
    80005e6e:	f04a                	sd	s2,32(sp)
    80005e70:	ec4e                	sd	s3,24(sp)
    80005e72:	e852                	sd	s4,16(sp)
    80005e74:	e456                	sd	s5,8(sp)
    80005e76:	0080                	addi	s0,sp,64
    80005e78:	84aa                	mv	s1,a0
  printf("virtio disk init %d\n", n);
    80005e7a:	85aa                	mv	a1,a0
    80005e7c:	00003517          	auipc	a0,0x3
    80005e80:	9b450513          	addi	a0,a0,-1612 # 80008830 <userret+0x7a0>
    80005e84:	ffffa097          	auipc	ra,0xffffa
    80005e88:	714080e7          	jalr	1812(ra) # 80000598 <printf>
  initlock(&disk[n].vdisk_lock, "virtio_disk");
    80005e8c:	00149993          	slli	s3,s1,0x1
    80005e90:	99a6                	add	s3,s3,s1
    80005e92:	09b2                	slli	s3,s3,0xc
    80005e94:	6789                	lui	a5,0x2
    80005e96:	0b078793          	addi	a5,a5,176 # 20b0 <_entry-0x7fffdf50>
    80005e9a:	97ce                	add	a5,a5,s3
    80005e9c:	00003597          	auipc	a1,0x3
    80005ea0:	9ac58593          	addi	a1,a1,-1620 # 80008848 <userret+0x7b8>
    80005ea4:	0001e517          	auipc	a0,0x1e
    80005ea8:	15c50513          	addi	a0,a0,348 # 80024000 <disk>
    80005eac:	953e                	add	a0,a0,a5
    80005eae:	ffffb097          	auipc	ra,0xffffb
    80005eb2:	a0c080e7          	jalr	-1524(ra) # 800008ba <initlock>
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb6:	0014891b          	addiw	s2,s1,1
    80005eba:	00c9191b          	slliw	s2,s2,0xc
    80005ebe:	100007b7          	lui	a5,0x10000
    80005ec2:	97ca                	add	a5,a5,s2
    80005ec4:	4398                	lw	a4,0(a5)
    80005ec6:	2701                	sext.w	a4,a4
    80005ec8:	747277b7          	lui	a5,0x74727
    80005ecc:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ed0:	12f71663          	bne	a4,a5,80005ffc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005ed4:	100007b7          	lui	a5,0x10000
    80005ed8:	0791                	addi	a5,a5,4
    80005eda:	97ca                	add	a5,a5,s2
    80005edc:	439c                	lw	a5,0(a5)
    80005ede:	2781                	sext.w	a5,a5
  if(*R(n, VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ee0:	4705                	li	a4,1
    80005ee2:	10e79d63          	bne	a5,a4,80005ffc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ee6:	100007b7          	lui	a5,0x10000
    80005eea:	07a1                	addi	a5,a5,8
    80005eec:	97ca                	add	a5,a5,s2
    80005eee:	439c                	lw	a5,0(a5)
    80005ef0:	2781                	sext.w	a5,a5
     *R(n, VIRTIO_MMIO_VERSION) != 1 ||
    80005ef2:	4709                	li	a4,2
    80005ef4:	10e79463          	bne	a5,a4,80005ffc <virtio_disk_init+0x1b8>
     *R(n, VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ef8:	100007b7          	lui	a5,0x10000
    80005efc:	07b1                	addi	a5,a5,12
    80005efe:	97ca                	add	a5,a5,s2
    80005f00:	4398                	lw	a4,0(a5)
    80005f02:	2701                	sext.w	a4,a4
     *R(n, VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f04:	554d47b7          	lui	a5,0x554d4
    80005f08:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f0c:	0ef71863          	bne	a4,a5,80005ffc <virtio_disk_init+0x1b8>
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f10:	100007b7          	lui	a5,0x10000
    80005f14:	07078693          	addi	a3,a5,112 # 10000070 <_entry-0x6fffff90>
    80005f18:	96ca                	add	a3,a3,s2
    80005f1a:	4705                	li	a4,1
    80005f1c:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f1e:	470d                	li	a4,3
    80005f20:	c298                	sw	a4,0(a3)
  uint64 features = *R(n, VIRTIO_MMIO_DEVICE_FEATURES);
    80005f22:	01078713          	addi	a4,a5,16
    80005f26:	974a                	add	a4,a4,s2
    80005f28:	430c                	lw	a1,0(a4)
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f2a:	02078613          	addi	a2,a5,32
    80005f2e:	964a                	add	a2,a2,s2
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f30:	c7ffe737          	lui	a4,0xc7ffe
    80005f34:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd4703>
    80005f38:	8f6d                	and	a4,a4,a1
  *R(n, VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f3a:	2701                	sext.w	a4,a4
    80005f3c:	c218                	sw	a4,0(a2)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f3e:	472d                	li	a4,11
    80005f40:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_STATUS) = status;
    80005f42:	473d                	li	a4,15
    80005f44:	c298                	sw	a4,0(a3)
  *R(n, VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f46:	02878713          	addi	a4,a5,40
    80005f4a:	974a                	add	a4,a4,s2
    80005f4c:	6685                	lui	a3,0x1
    80005f4e:	c314                	sw	a3,0(a4)
  *R(n, VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f50:	03078713          	addi	a4,a5,48
    80005f54:	974a                	add	a4,a4,s2
    80005f56:	00072023          	sw	zero,0(a4)
  uint32 max = *R(n, VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f5a:	03478793          	addi	a5,a5,52
    80005f5e:	97ca                	add	a5,a5,s2
    80005f60:	439c                	lw	a5,0(a5)
    80005f62:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f64:	c7c5                	beqz	a5,8000600c <virtio_disk_init+0x1c8>
  if(max < NUM)
    80005f66:	471d                	li	a4,7
    80005f68:	0af77a63          	bgeu	a4,a5,8000601c <virtio_disk_init+0x1d8>
  *R(n, VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f6c:	10000ab7          	lui	s5,0x10000
    80005f70:	038a8793          	addi	a5,s5,56 # 10000038 <_entry-0x6fffffc8>
    80005f74:	97ca                	add	a5,a5,s2
    80005f76:	4721                	li	a4,8
    80005f78:	c398                	sw	a4,0(a5)
  memset(disk[n].pages, 0, sizeof(disk[n].pages));
    80005f7a:	0001ea17          	auipc	s4,0x1e
    80005f7e:	086a0a13          	addi	s4,s4,134 # 80024000 <disk>
    80005f82:	99d2                	add	s3,s3,s4
    80005f84:	6609                	lui	a2,0x2
    80005f86:	4581                	li	a1,0
    80005f88:	854e                	mv	a0,s3
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	b06080e7          	jalr	-1274(ra) # 80000a90 <memset>
  *R(n, VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk[n].pages) >> PGSHIFT;
    80005f92:	040a8a93          	addi	s5,s5,64
    80005f96:	9956                	add	s2,s2,s5
    80005f98:	00c9d793          	srli	a5,s3,0xc
    80005f9c:	2781                	sext.w	a5,a5
    80005f9e:	00f92023          	sw	a5,0(s2)
  disk[n].desc = (struct VRingDesc *) disk[n].pages;
    80005fa2:	00149513          	slli	a0,s1,0x1
    80005fa6:	009507b3          	add	a5,a0,s1
    80005faa:	07b2                	slli	a5,a5,0xc
    80005fac:	97d2                	add	a5,a5,s4
    80005fae:	6689                	lui	a3,0x2
    80005fb0:	97b6                	add	a5,a5,a3
    80005fb2:	0137b023          	sd	s3,0(a5)
  disk[n].avail = (uint16*)(((char*)disk[n].desc) + NUM*sizeof(struct VRingDesc));
    80005fb6:	08098713          	addi	a4,s3,128
    80005fba:	e798                	sd	a4,8(a5)
  disk[n].used = (struct UsedArea *) (disk[n].pages + PGSIZE);
    80005fbc:	6705                	lui	a4,0x1
    80005fbe:	99ba                	add	s3,s3,a4
    80005fc0:	0137b823          	sd	s3,16(a5)
    disk[n].free[i] = 1;
    80005fc4:	4705                	li	a4,1
    80005fc6:	00e78c23          	sb	a4,24(a5)
    80005fca:	00e78ca3          	sb	a4,25(a5)
    80005fce:	00e78d23          	sb	a4,26(a5)
    80005fd2:	00e78da3          	sb	a4,27(a5)
    80005fd6:	00e78e23          	sb	a4,28(a5)
    80005fda:	00e78ea3          	sb	a4,29(a5)
    80005fde:	00e78f23          	sb	a4,30(a5)
    80005fe2:	00e78fa3          	sb	a4,31(a5)
  disk[n].init = 1;
    80005fe6:	0ae7a423          	sw	a4,168(a5)
}
    80005fea:	70e2                	ld	ra,56(sp)
    80005fec:	7442                	ld	s0,48(sp)
    80005fee:	74a2                	ld	s1,40(sp)
    80005ff0:	7902                	ld	s2,32(sp)
    80005ff2:	69e2                	ld	s3,24(sp)
    80005ff4:	6a42                	ld	s4,16(sp)
    80005ff6:	6aa2                	ld	s5,8(sp)
    80005ff8:	6121                	addi	sp,sp,64
    80005ffa:	8082                	ret
    panic("could not find virtio disk");
    80005ffc:	00003517          	auipc	a0,0x3
    80006000:	85c50513          	addi	a0,a0,-1956 # 80008858 <userret+0x7c8>
    80006004:	ffffa097          	auipc	ra,0xffffa
    80006008:	54a080e7          	jalr	1354(ra) # 8000054e <panic>
    panic("virtio disk has no queue 0");
    8000600c:	00003517          	auipc	a0,0x3
    80006010:	86c50513          	addi	a0,a0,-1940 # 80008878 <userret+0x7e8>
    80006014:	ffffa097          	auipc	ra,0xffffa
    80006018:	53a080e7          	jalr	1338(ra) # 8000054e <panic>
    panic("virtio disk max queue too short");
    8000601c:	00003517          	auipc	a0,0x3
    80006020:	87c50513          	addi	a0,a0,-1924 # 80008898 <userret+0x808>
    80006024:	ffffa097          	auipc	ra,0xffffa
    80006028:	52a080e7          	jalr	1322(ra) # 8000054e <panic>

000000008000602c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(int n, struct buf *b, int write)
{
    8000602c:	7135                	addi	sp,sp,-160
    8000602e:	ed06                	sd	ra,152(sp)
    80006030:	e922                	sd	s0,144(sp)
    80006032:	e526                	sd	s1,136(sp)
    80006034:	e14a                	sd	s2,128(sp)
    80006036:	fcce                	sd	s3,120(sp)
    80006038:	f8d2                	sd	s4,112(sp)
    8000603a:	f4d6                	sd	s5,104(sp)
    8000603c:	f0da                	sd	s6,96(sp)
    8000603e:	ecde                	sd	s7,88(sp)
    80006040:	e8e2                	sd	s8,80(sp)
    80006042:	e4e6                	sd	s9,72(sp)
    80006044:	e0ea                	sd	s10,64(sp)
    80006046:	fc6e                	sd	s11,56(sp)
    80006048:	1100                	addi	s0,sp,160
    8000604a:	892a                	mv	s2,a0
    8000604c:	89ae                	mv	s3,a1
    8000604e:	8db2                	mv	s11,a2
  uint64 sector = b->blockno * (BSIZE / 512);
    80006050:	45dc                	lw	a5,12(a1)
    80006052:	0017979b          	slliw	a5,a5,0x1
    80006056:	1782                	slli	a5,a5,0x20
    80006058:	9381                	srli	a5,a5,0x20
    8000605a:	f6f43423          	sd	a5,-152(s0)

  acquire(&disk[n].vdisk_lock);
    8000605e:	00151493          	slli	s1,a0,0x1
    80006062:	94aa                	add	s1,s1,a0
    80006064:	04b2                	slli	s1,s1,0xc
    80006066:	6a89                	lui	s5,0x2
    80006068:	0b0a8a13          	addi	s4,s5,176 # 20b0 <_entry-0x7fffdf50>
    8000606c:	9a26                	add	s4,s4,s1
    8000606e:	0001eb97          	auipc	s7,0x1e
    80006072:	f92b8b93          	addi	s7,s7,-110 # 80024000 <disk>
    80006076:	9a5e                	add	s4,s4,s7
    80006078:	8552                	mv	a0,s4
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	952080e7          	jalr	-1710(ra) # 800009cc <acquire>
  int idx[3];
  while(1){
    if(alloc3_desc(n, idx) == 0) {
      break;
    }
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    80006082:	0ae1                	addi	s5,s5,24
    80006084:	94d6                	add	s1,s1,s5
    80006086:	01748ab3          	add	s5,s1,s7
    8000608a:	8d56                	mv	s10,s5
  for(int i = 0; i < 3; i++){
    8000608c:	4b81                	li	s7,0
  for(int i = 0; i < NUM; i++){
    8000608e:	4ca1                	li	s9,8
      disk[n].free[i] = 0;
    80006090:	00191b13          	slli	s6,s2,0x1
    80006094:	9b4a                	add	s6,s6,s2
    80006096:	00cb1793          	slli	a5,s6,0xc
    8000609a:	0001eb17          	auipc	s6,0x1e
    8000609e:	f66b0b13          	addi	s6,s6,-154 # 80024000 <disk>
    800060a2:	9b3e                	add	s6,s6,a5
  for(int i = 0; i < NUM; i++){
    800060a4:	8c5e                	mv	s8,s7
    800060a6:	a8ad                	j	80006120 <virtio_disk_rw+0xf4>
      disk[n].free[i] = 0;
    800060a8:	00fb06b3          	add	a3,s6,a5
    800060ac:	96aa                	add	a3,a3,a0
    800060ae:	00068c23          	sb	zero,24(a3) # 2018 <_entry-0x7fffdfe8>
    idx[i] = alloc_desc(n);
    800060b2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060b4:	0207c363          	bltz	a5,800060da <virtio_disk_rw+0xae>
  for(int i = 0; i < 3; i++){
    800060b8:	2485                	addiw	s1,s1,1
    800060ba:	0711                	addi	a4,a4,4
    800060bc:	1eb48363          	beq	s1,a1,800062a2 <virtio_disk_rw+0x276>
    idx[i] = alloc_desc(n);
    800060c0:	863a                	mv	a2,a4
    800060c2:	86ea                	mv	a3,s10
  for(int i = 0; i < NUM; i++){
    800060c4:	87e2                	mv	a5,s8
    if(disk[n].free[i]){
    800060c6:	0006c803          	lbu	a6,0(a3)
    800060ca:	fc081fe3          	bnez	a6,800060a8 <virtio_disk_rw+0x7c>
  for(int i = 0; i < NUM; i++){
    800060ce:	2785                	addiw	a5,a5,1
    800060d0:	0685                	addi	a3,a3,1
    800060d2:	ff979ae3          	bne	a5,s9,800060c6 <virtio_disk_rw+0x9a>
    idx[i] = alloc_desc(n);
    800060d6:	57fd                	li	a5,-1
    800060d8:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060da:	02905d63          	blez	s1,80006114 <virtio_disk_rw+0xe8>
        free_desc(n, idx[j]);
    800060de:	f8042583          	lw	a1,-128(s0)
    800060e2:	854a                	mv	a0,s2
    800060e4:	00000097          	auipc	ra,0x0
    800060e8:	cc4080e7          	jalr	-828(ra) # 80005da8 <free_desc>
      for(int j = 0; j < i; j++)
    800060ec:	4785                	li	a5,1
    800060ee:	0297d363          	bge	a5,s1,80006114 <virtio_disk_rw+0xe8>
        free_desc(n, idx[j]);
    800060f2:	f8442583          	lw	a1,-124(s0)
    800060f6:	854a                	mv	a0,s2
    800060f8:	00000097          	auipc	ra,0x0
    800060fc:	cb0080e7          	jalr	-848(ra) # 80005da8 <free_desc>
      for(int j = 0; j < i; j++)
    80006100:	4789                	li	a5,2
    80006102:	0097d963          	bge	a5,s1,80006114 <virtio_disk_rw+0xe8>
        free_desc(n, idx[j]);
    80006106:	f8842583          	lw	a1,-120(s0)
    8000610a:	854a                	mv	a0,s2
    8000610c:	00000097          	auipc	ra,0x0
    80006110:	c9c080e7          	jalr	-868(ra) # 80005da8 <free_desc>
    sleep(&disk[n].free[0], &disk[n].vdisk_lock);
    80006114:	85d2                	mv	a1,s4
    80006116:	8556                	mv	a0,s5
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	f98080e7          	jalr	-104(ra) # 800020b0 <sleep>
  for(int i = 0; i < 3; i++){
    80006120:	f8040713          	addi	a4,s0,-128
    80006124:	84de                	mv	s1,s7
      disk[n].free[i] = 0;
    80006126:	6509                	lui	a0,0x2
  for(int i = 0; i < 3; i++){
    80006128:	458d                	li	a1,3
    8000612a:	bf59                	j	800060c0 <virtio_disk_rw+0x94>
  disk[n].desc[idx[0]].next = idx[1];

  disk[n].desc[idx[1]].addr = (uint64) b->data;
  disk[n].desc[idx[1]].len = BSIZE;
  if(write)
    disk[n].desc[idx[1]].flags = 0; // device reads b->data
    8000612c:	00191793          	slli	a5,s2,0x1
    80006130:	97ca                	add	a5,a5,s2
    80006132:	07b2                	slli	a5,a5,0xc
    80006134:	0001e717          	auipc	a4,0x1e
    80006138:	ecc70713          	addi	a4,a4,-308 # 80024000 <disk>
    8000613c:	973e                	add	a4,a4,a5
    8000613e:	6789                	lui	a5,0x2
    80006140:	97ba                	add	a5,a5,a4
    80006142:	639c                	ld	a5,0(a5)
    80006144:	97b6                	add	a5,a5,a3
    80006146:	00079623          	sh	zero,12(a5) # 200c <_entry-0x7fffdff4>
  else
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk[n].desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000614a:	0001e517          	auipc	a0,0x1e
    8000614e:	eb650513          	addi	a0,a0,-330 # 80024000 <disk>
    80006152:	00191793          	slli	a5,s2,0x1
    80006156:	01278733          	add	a4,a5,s2
    8000615a:	0732                	slli	a4,a4,0xc
    8000615c:	972a                	add	a4,a4,a0
    8000615e:	6609                	lui	a2,0x2
    80006160:	9732                	add	a4,a4,a2
    80006162:	630c                	ld	a1,0(a4)
    80006164:	95b6                	add	a1,a1,a3
    80006166:	00c5d603          	lhu	a2,12(a1)
    8000616a:	00166613          	ori	a2,a2,1
    8000616e:	00c59623          	sh	a2,12(a1)
  disk[n].desc[idx[1]].next = idx[2];
    80006172:	f8842603          	lw	a2,-120(s0)
    80006176:	630c                	ld	a1,0(a4)
    80006178:	96ae                	add	a3,a3,a1
    8000617a:	00c69723          	sh	a2,14(a3)

  disk[n].info[idx[0]].status = 0;
    8000617e:	97ca                	add	a5,a5,s2
    80006180:	07a2                	slli	a5,a5,0x8
    80006182:	97a6                	add	a5,a5,s1
    80006184:	20078793          	addi	a5,a5,512
    80006188:	0792                	slli	a5,a5,0x4
    8000618a:	97aa                	add	a5,a5,a0
    8000618c:	02078823          	sb	zero,48(a5)
  disk[n].desc[idx[2]].addr = (uint64) &disk[n].info[idx[0]].status;
    80006190:	00461693          	slli	a3,a2,0x4
    80006194:	00073803          	ld	a6,0(a4)
    80006198:	9836                	add	a6,a6,a3
    8000619a:	20348613          	addi	a2,s1,515
    8000619e:	00191593          	slli	a1,s2,0x1
    800061a2:	95ca                	add	a1,a1,s2
    800061a4:	05a2                	slli	a1,a1,0x8
    800061a6:	962e                	add	a2,a2,a1
    800061a8:	0612                	slli	a2,a2,0x4
    800061aa:	962a                	add	a2,a2,a0
    800061ac:	00c83023          	sd	a2,0(a6)
  disk[n].desc[idx[2]].len = 1;
    800061b0:	630c                	ld	a1,0(a4)
    800061b2:	95b6                	add	a1,a1,a3
    800061b4:	4605                	li	a2,1
    800061b6:	c590                	sw	a2,8(a1)
  disk[n].desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061b8:	630c                	ld	a1,0(a4)
    800061ba:	95b6                	add	a1,a1,a3
    800061bc:	4509                	li	a0,2
    800061be:	00a59623          	sh	a0,12(a1)
  disk[n].desc[idx[2]].next = 0;
    800061c2:	630c                	ld	a1,0(a4)
    800061c4:	96ae                	add	a3,a3,a1
    800061c6:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061ca:	00c9a223          	sw	a2,4(s3)
  disk[n].info[idx[0]].b = b;
    800061ce:	0337b423          	sd	s3,40(a5)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk[n].avail[2 + (disk[n].avail[1] % NUM)] = idx[0];
    800061d2:	6714                	ld	a3,8(a4)
    800061d4:	0026d783          	lhu	a5,2(a3)
    800061d8:	8b9d                	andi	a5,a5,7
    800061da:	0789                	addi	a5,a5,2
    800061dc:	0786                	slli	a5,a5,0x1
    800061de:	97b6                	add	a5,a5,a3
    800061e0:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800061e4:	0ff0000f          	fence
  disk[n].avail[1] = disk[n].avail[1] + 1;
    800061e8:	6718                	ld	a4,8(a4)
    800061ea:	00275783          	lhu	a5,2(a4)
    800061ee:	2785                	addiw	a5,a5,1
    800061f0:	00f71123          	sh	a5,2(a4)

  *R(n, VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061f4:	0019079b          	addiw	a5,s2,1
    800061f8:	00c7979b          	slliw	a5,a5,0xc
    800061fc:	10000737          	lui	a4,0x10000
    80006200:	05070713          	addi	a4,a4,80 # 10000050 <_entry-0x6fffffb0>
    80006204:	97ba                	add	a5,a5,a4
    80006206:	0007a023          	sw	zero,0(a5)

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000620a:	0049a783          	lw	a5,4(s3)
    8000620e:	00c79d63          	bne	a5,a2,80006228 <virtio_disk_rw+0x1fc>
    80006212:	4485                	li	s1,1
    sleep(b, &disk[n].vdisk_lock);
    80006214:	85d2                	mv	a1,s4
    80006216:	854e                	mv	a0,s3
    80006218:	ffffc097          	auipc	ra,0xffffc
    8000621c:	e98080e7          	jalr	-360(ra) # 800020b0 <sleep>
  while(b->disk == 1) {
    80006220:	0049a783          	lw	a5,4(s3)
    80006224:	fe9788e3          	beq	a5,s1,80006214 <virtio_disk_rw+0x1e8>
  }

  disk[n].info[idx[0]].b = 0;
    80006228:	f8042483          	lw	s1,-128(s0)
    8000622c:	00191793          	slli	a5,s2,0x1
    80006230:	97ca                	add	a5,a5,s2
    80006232:	07a2                	slli	a5,a5,0x8
    80006234:	97a6                	add	a5,a5,s1
    80006236:	20078793          	addi	a5,a5,512
    8000623a:	0792                	slli	a5,a5,0x4
    8000623c:	0001e717          	auipc	a4,0x1e
    80006240:	dc470713          	addi	a4,a4,-572 # 80024000 <disk>
    80006244:	97ba                	add	a5,a5,a4
    80006246:	0207b423          	sd	zero,40(a5)
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    8000624a:	00191793          	slli	a5,s2,0x1
    8000624e:	97ca                	add	a5,a5,s2
    80006250:	07b2                	slli	a5,a5,0xc
    80006252:	97ba                	add	a5,a5,a4
    80006254:	6989                	lui	s3,0x2
    80006256:	99be                	add	s3,s3,a5
    free_desc(n, i);
    80006258:	85a6                	mv	a1,s1
    8000625a:	854a                	mv	a0,s2
    8000625c:	00000097          	auipc	ra,0x0
    80006260:	b4c080e7          	jalr	-1204(ra) # 80005da8 <free_desc>
    if(disk[n].desc[i].flags & VRING_DESC_F_NEXT)
    80006264:	0492                	slli	s1,s1,0x4
    80006266:	0009b783          	ld	a5,0(s3) # 2000 <_entry-0x7fffe000>
    8000626a:	94be                	add	s1,s1,a5
    8000626c:	00c4d783          	lhu	a5,12(s1)
    80006270:	8b85                	andi	a5,a5,1
    80006272:	c781                	beqz	a5,8000627a <virtio_disk_rw+0x24e>
      i = disk[n].desc[i].next;
    80006274:	00e4d483          	lhu	s1,14(s1)
    free_desc(n, i);
    80006278:	b7c5                	j	80006258 <virtio_disk_rw+0x22c>
  free_chain(n, idx[0]);

  release(&disk[n].vdisk_lock);
    8000627a:	8552                	mv	a0,s4
    8000627c:	ffffa097          	auipc	ra,0xffffa
    80006280:	7b8080e7          	jalr	1976(ra) # 80000a34 <release>
}
    80006284:	60ea                	ld	ra,152(sp)
    80006286:	644a                	ld	s0,144(sp)
    80006288:	64aa                	ld	s1,136(sp)
    8000628a:	690a                	ld	s2,128(sp)
    8000628c:	79e6                	ld	s3,120(sp)
    8000628e:	7a46                	ld	s4,112(sp)
    80006290:	7aa6                	ld	s5,104(sp)
    80006292:	7b06                	ld	s6,96(sp)
    80006294:	6be6                	ld	s7,88(sp)
    80006296:	6c46                	ld	s8,80(sp)
    80006298:	6ca6                	ld	s9,72(sp)
    8000629a:	6d06                	ld	s10,64(sp)
    8000629c:	7de2                	ld	s11,56(sp)
    8000629e:	610d                	addi	sp,sp,160
    800062a0:	8082                	ret
  if(write)
    800062a2:	01b037b3          	snez	a5,s11
    800062a6:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800062aa:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800062ae:	f6843783          	ld	a5,-152(s0)
    800062b2:	f6f43c23          	sd	a5,-136(s0)
  disk[n].desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800062b6:	f8042483          	lw	s1,-128(s0)
    800062ba:	00449b13          	slli	s6,s1,0x4
    800062be:	00191793          	slli	a5,s2,0x1
    800062c2:	97ca                	add	a5,a5,s2
    800062c4:	07b2                	slli	a5,a5,0xc
    800062c6:	0001ea97          	auipc	s5,0x1e
    800062ca:	d3aa8a93          	addi	s5,s5,-710 # 80024000 <disk>
    800062ce:	97d6                	add	a5,a5,s5
    800062d0:	6a89                	lui	s5,0x2
    800062d2:	9abe                	add	s5,s5,a5
    800062d4:	000abb83          	ld	s7,0(s5) # 2000 <_entry-0x7fffe000>
    800062d8:	9bda                	add	s7,s7,s6
    800062da:	f7040513          	addi	a0,s0,-144
    800062de:	ffffb097          	auipc	ra,0xffffb
    800062e2:	be6080e7          	jalr	-1050(ra) # 80000ec4 <kvmpa>
    800062e6:	00abb023          	sd	a0,0(s7)
  disk[n].desc[idx[0]].len = sizeof(buf0);
    800062ea:	000ab783          	ld	a5,0(s5)
    800062ee:	97da                	add	a5,a5,s6
    800062f0:	4741                	li	a4,16
    800062f2:	c798                	sw	a4,8(a5)
  disk[n].desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062f4:	000ab783          	ld	a5,0(s5)
    800062f8:	97da                	add	a5,a5,s6
    800062fa:	4705                	li	a4,1
    800062fc:	00e79623          	sh	a4,12(a5)
  disk[n].desc[idx[0]].next = idx[1];
    80006300:	f8442683          	lw	a3,-124(s0)
    80006304:	000ab783          	ld	a5,0(s5)
    80006308:	9b3e                	add	s6,s6,a5
    8000630a:	00db1723          	sh	a3,14(s6)
  disk[n].desc[idx[1]].addr = (uint64) b->data;
    8000630e:	0692                	slli	a3,a3,0x4
    80006310:	000ab783          	ld	a5,0(s5)
    80006314:	97b6                	add	a5,a5,a3
    80006316:	06098713          	addi	a4,s3,96
    8000631a:	e398                	sd	a4,0(a5)
  disk[n].desc[idx[1]].len = BSIZE;
    8000631c:	000ab783          	ld	a5,0(s5)
    80006320:	97b6                	add	a5,a5,a3
    80006322:	40000713          	li	a4,1024
    80006326:	c798                	sw	a4,8(a5)
  if(write)
    80006328:	e00d92e3          	bnez	s11,8000612c <virtio_disk_rw+0x100>
    disk[n].desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000632c:	00191793          	slli	a5,s2,0x1
    80006330:	97ca                	add	a5,a5,s2
    80006332:	07b2                	slli	a5,a5,0xc
    80006334:	0001e717          	auipc	a4,0x1e
    80006338:	ccc70713          	addi	a4,a4,-820 # 80024000 <disk>
    8000633c:	973e                	add	a4,a4,a5
    8000633e:	6789                	lui	a5,0x2
    80006340:	97ba                	add	a5,a5,a4
    80006342:	639c                	ld	a5,0(a5)
    80006344:	97b6                	add	a5,a5,a3
    80006346:	4709                	li	a4,2
    80006348:	00e79623          	sh	a4,12(a5) # 200c <_entry-0x7fffdff4>
    8000634c:	bbfd                	j	8000614a <virtio_disk_rw+0x11e>

000000008000634e <virtio_disk_intr>:

void
virtio_disk_intr(int n)
{
    8000634e:	7139                	addi	sp,sp,-64
    80006350:	fc06                	sd	ra,56(sp)
    80006352:	f822                	sd	s0,48(sp)
    80006354:	f426                	sd	s1,40(sp)
    80006356:	f04a                	sd	s2,32(sp)
    80006358:	ec4e                	sd	s3,24(sp)
    8000635a:	e852                	sd	s4,16(sp)
    8000635c:	e456                	sd	s5,8(sp)
    8000635e:	0080                	addi	s0,sp,64
    80006360:	84aa                	mv	s1,a0
  acquire(&disk[n].vdisk_lock);
    80006362:	00151913          	slli	s2,a0,0x1
    80006366:	00a90a33          	add	s4,s2,a0
    8000636a:	0a32                	slli	s4,s4,0xc
    8000636c:	6989                	lui	s3,0x2
    8000636e:	0b098793          	addi	a5,s3,176 # 20b0 <_entry-0x7fffdf50>
    80006372:	9a3e                	add	s4,s4,a5
    80006374:	0001ea97          	auipc	s5,0x1e
    80006378:	c8ca8a93          	addi	s5,s5,-884 # 80024000 <disk>
    8000637c:	9a56                	add	s4,s4,s5
    8000637e:	8552                	mv	a0,s4
    80006380:	ffffa097          	auipc	ra,0xffffa
    80006384:	64c080e7          	jalr	1612(ra) # 800009cc <acquire>

  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    80006388:	9926                	add	s2,s2,s1
    8000638a:	0932                	slli	s2,s2,0xc
    8000638c:	9956                	add	s2,s2,s5
    8000638e:	99ca                	add	s3,s3,s2
    80006390:	0209d783          	lhu	a5,32(s3)
    80006394:	0109b703          	ld	a4,16(s3)
    80006398:	00275683          	lhu	a3,2(a4)
    8000639c:	8ebd                	xor	a3,a3,a5
    8000639e:	8a9d                	andi	a3,a3,7
    800063a0:	c2a5                	beqz	a3,80006400 <virtio_disk_intr+0xb2>
    int id = disk[n].used->elems[disk[n].used_idx].id;

    if(disk[n].info[id].status != 0)
    800063a2:	8956                	mv	s2,s5
    800063a4:	00149693          	slli	a3,s1,0x1
    800063a8:	96a6                	add	a3,a3,s1
    800063aa:	00869993          	slli	s3,a3,0x8
      panic("virtio_disk_intr status");
    
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk[n].info[id].b);

    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    800063ae:	06b2                	slli	a3,a3,0xc
    800063b0:	96d6                	add	a3,a3,s5
    800063b2:	6489                	lui	s1,0x2
    800063b4:	94b6                	add	s1,s1,a3
    int id = disk[n].used->elems[disk[n].used_idx].id;
    800063b6:	078e                	slli	a5,a5,0x3
    800063b8:	97ba                	add	a5,a5,a4
    800063ba:	43dc                	lw	a5,4(a5)
    if(disk[n].info[id].status != 0)
    800063bc:	00f98733          	add	a4,s3,a5
    800063c0:	20070713          	addi	a4,a4,512
    800063c4:	0712                	slli	a4,a4,0x4
    800063c6:	974a                	add	a4,a4,s2
    800063c8:	03074703          	lbu	a4,48(a4)
    800063cc:	eb21                	bnez	a4,8000641c <virtio_disk_intr+0xce>
    disk[n].info[id].b->disk = 0;   // disk is done with buf
    800063ce:	97ce                	add	a5,a5,s3
    800063d0:	20078793          	addi	a5,a5,512
    800063d4:	0792                	slli	a5,a5,0x4
    800063d6:	97ca                	add	a5,a5,s2
    800063d8:	7798                	ld	a4,40(a5)
    800063da:	00072223          	sw	zero,4(a4)
    wakeup(disk[n].info[id].b);
    800063de:	7788                	ld	a0,40(a5)
    800063e0:	ffffc097          	auipc	ra,0xffffc
    800063e4:	e56080e7          	jalr	-426(ra) # 80002236 <wakeup>
    disk[n].used_idx = (disk[n].used_idx + 1) % NUM;
    800063e8:	0204d783          	lhu	a5,32(s1) # 2020 <_entry-0x7fffdfe0>
    800063ec:	2785                	addiw	a5,a5,1
    800063ee:	8b9d                	andi	a5,a5,7
    800063f0:	02f49023          	sh	a5,32(s1)
  while((disk[n].used_idx % NUM) != (disk[n].used->id % NUM)){
    800063f4:	6898                	ld	a4,16(s1)
    800063f6:	00275683          	lhu	a3,2(a4)
    800063fa:	8a9d                	andi	a3,a3,7
    800063fc:	faf69de3          	bne	a3,a5,800063b6 <virtio_disk_intr+0x68>
  }

  release(&disk[n].vdisk_lock);
    80006400:	8552                	mv	a0,s4
    80006402:	ffffa097          	auipc	ra,0xffffa
    80006406:	632080e7          	jalr	1586(ra) # 80000a34 <release>
}
    8000640a:	70e2                	ld	ra,56(sp)
    8000640c:	7442                	ld	s0,48(sp)
    8000640e:	74a2                	ld	s1,40(sp)
    80006410:	7902                	ld	s2,32(sp)
    80006412:	69e2                	ld	s3,24(sp)
    80006414:	6a42                	ld	s4,16(sp)
    80006416:	6aa2                	ld	s5,8(sp)
    80006418:	6121                	addi	sp,sp,64
    8000641a:	8082                	ret
      panic("virtio_disk_intr status");
    8000641c:	00002517          	auipc	a0,0x2
    80006420:	49c50513          	addi	a0,a0,1180 # 800088b8 <userret+0x828>
    80006424:	ffffa097          	auipc	ra,0xffffa
    80006428:	12a080e7          	jalr	298(ra) # 8000054e <panic>

000000008000642c <bit_isset>:
static Sz_info *bd_sizes; 
static void *bd_base;   // start address of memory managed by the buddy allocator
static struct spinlock lock;

// Return 1 if bit at position index in array is set to 1
int bit_isset(char *array, int index) {
    8000642c:	1141                	addi	sp,sp,-16
    8000642e:	e422                	sd	s0,8(sp)
    80006430:	0800                	addi	s0,sp,16
  char b = array[index/8];
  char m = (1 << (index % 8));
    80006432:	41f5d79b          	sraiw	a5,a1,0x1f
    80006436:	01d7d79b          	srliw	a5,a5,0x1d
    8000643a:	9dbd                	addw	a1,a1,a5
    8000643c:	0075f713          	andi	a4,a1,7
    80006440:	9f1d                	subw	a4,a4,a5
    80006442:	4785                	li	a5,1
    80006444:	00e797bb          	sllw	a5,a5,a4
  char b = array[index/8];
    80006448:	4035d59b          	sraiw	a1,a1,0x3
    8000644c:	95aa                	add	a1,a1,a0
  return (b & m) == m;
    8000644e:	0005c503          	lbu	a0,0(a1)
    80006452:	8d7d                	and	a0,a0,a5
    80006454:	0ff7f793          	andi	a5,a5,255
    80006458:	8d1d                	sub	a0,a0,a5
}
    8000645a:	00153513          	seqz	a0,a0
    8000645e:	6422                	ld	s0,8(sp)
    80006460:	0141                	addi	sp,sp,16
    80006462:	8082                	ret

0000000080006464 <bit_set>:

// Set bit at position index in array to 1
void bit_set(char *array, int index) {
    80006464:	1141                	addi	sp,sp,-16
    80006466:	e422                	sd	s0,8(sp)
    80006468:	0800                	addi	s0,sp,16
  char b = array[index/8];
    8000646a:	41f5d79b          	sraiw	a5,a1,0x1f
    8000646e:	01d7d79b          	srliw	a5,a5,0x1d
    80006472:	9dbd                	addw	a1,a1,a5
    80006474:	4035d71b          	sraiw	a4,a1,0x3
    80006478:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    8000647a:	899d                	andi	a1,a1,7
    8000647c:	9d9d                	subw	a1,a1,a5
  array[index/8] = (b | m);
    8000647e:	4785                	li	a5,1
    80006480:	00b795bb          	sllw	a1,a5,a1
    80006484:	00054783          	lbu	a5,0(a0)
    80006488:	8ddd                	or	a1,a1,a5
    8000648a:	00b50023          	sb	a1,0(a0)
}
    8000648e:	6422                	ld	s0,8(sp)
    80006490:	0141                	addi	sp,sp,16
    80006492:	8082                	ret

0000000080006494 <bit_clear>:

// Clear bit at position index in array
void bit_clear(char *array, int index) {
    80006494:	1141                	addi	sp,sp,-16
    80006496:	e422                	sd	s0,8(sp)
    80006498:	0800                	addi	s0,sp,16
  char b = array[index/8];
    8000649a:	41f5d79b          	sraiw	a5,a1,0x1f
    8000649e:	01d7d79b          	srliw	a5,a5,0x1d
    800064a2:	9dbd                	addw	a1,a1,a5
    800064a4:	4035d71b          	sraiw	a4,a1,0x3
    800064a8:	953a                	add	a0,a0,a4
  char m = (1 << (index % 8));
    800064aa:	899d                	andi	a1,a1,7
    800064ac:	9d9d                	subw	a1,a1,a5
  array[index/8] = (b & ~m);
    800064ae:	4785                	li	a5,1
    800064b0:	00b795bb          	sllw	a1,a5,a1
    800064b4:	fff5c593          	not	a1,a1
    800064b8:	00054783          	lbu	a5,0(a0)
    800064bc:	8dfd                	and	a1,a1,a5
    800064be:	00b50023          	sb	a1,0(a0)
}
    800064c2:	6422                	ld	s0,8(sp)
    800064c4:	0141                	addi	sp,sp,16
    800064c6:	8082                	ret

00000000800064c8 <bd_print_vector>:

// Print a bit vector as a list of ranges of 1 bits
void
bd_print_vector(char *vector, int len) {
    800064c8:	715d                	addi	sp,sp,-80
    800064ca:	e486                	sd	ra,72(sp)
    800064cc:	e0a2                	sd	s0,64(sp)
    800064ce:	fc26                	sd	s1,56(sp)
    800064d0:	f84a                	sd	s2,48(sp)
    800064d2:	f44e                	sd	s3,40(sp)
    800064d4:	f052                	sd	s4,32(sp)
    800064d6:	ec56                	sd	s5,24(sp)
    800064d8:	e85a                	sd	s6,16(sp)
    800064da:	e45e                	sd	s7,8(sp)
    800064dc:	0880                	addi	s0,sp,80
    800064de:	8a2e                	mv	s4,a1
  int last, lb;
  
  last = 1;
  lb = 0;
  for (int b = 0; b < len; b++) {
    800064e0:	08b05b63          	blez	a1,80006576 <bd_print_vector+0xae>
    800064e4:	89aa                	mv	s3,a0
    800064e6:	4481                	li	s1,0
  lb = 0;
    800064e8:	4a81                	li	s5,0
  last = 1;
    800064ea:	4905                	li	s2,1
    if (last == bit_isset(vector, b))
      continue;
    if(last == 1)
    800064ec:	4b05                	li	s6,1
      printf(" [%d, %d)", lb, b);
    800064ee:	00002b97          	auipc	s7,0x2
    800064f2:	3e2b8b93          	addi	s7,s7,994 # 800088d0 <userret+0x840>
    800064f6:	a01d                	j	8000651c <bd_print_vector+0x54>
    800064f8:	8626                	mv	a2,s1
    800064fa:	85d6                	mv	a1,s5
    800064fc:	855e                	mv	a0,s7
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	09a080e7          	jalr	154(ra) # 80000598 <printf>
    lb = b;
    last = bit_isset(vector, b);
    80006506:	85a6                	mv	a1,s1
    80006508:	854e                	mv	a0,s3
    8000650a:	00000097          	auipc	ra,0x0
    8000650e:	f22080e7          	jalr	-222(ra) # 8000642c <bit_isset>
    80006512:	892a                	mv	s2,a0
    80006514:	8aa6                	mv	s5,s1
  for (int b = 0; b < len; b++) {
    80006516:	2485                	addiw	s1,s1,1
    80006518:	009a0d63          	beq	s4,s1,80006532 <bd_print_vector+0x6a>
    if (last == bit_isset(vector, b))
    8000651c:	85a6                	mv	a1,s1
    8000651e:	854e                	mv	a0,s3
    80006520:	00000097          	auipc	ra,0x0
    80006524:	f0c080e7          	jalr	-244(ra) # 8000642c <bit_isset>
    80006528:	ff2507e3          	beq	a0,s2,80006516 <bd_print_vector+0x4e>
    if(last == 1)
    8000652c:	fd691de3          	bne	s2,s6,80006506 <bd_print_vector+0x3e>
    80006530:	b7e1                	j	800064f8 <bd_print_vector+0x30>
  }
  if(lb == 0 || last == 1) {
    80006532:	000a8563          	beqz	s5,8000653c <bd_print_vector+0x74>
    80006536:	4785                	li	a5,1
    80006538:	00f91c63          	bne	s2,a5,80006550 <bd_print_vector+0x88>
    printf(" [%d, %d)", lb, len);
    8000653c:	8652                	mv	a2,s4
    8000653e:	85d6                	mv	a1,s5
    80006540:	00002517          	auipc	a0,0x2
    80006544:	39050513          	addi	a0,a0,912 # 800088d0 <userret+0x840>
    80006548:	ffffa097          	auipc	ra,0xffffa
    8000654c:	050080e7          	jalr	80(ra) # 80000598 <printf>
  }
  printf("\n");
    80006550:	00002517          	auipc	a0,0x2
    80006554:	c5050513          	addi	a0,a0,-944 # 800081a0 <userret+0x110>
    80006558:	ffffa097          	auipc	ra,0xffffa
    8000655c:	040080e7          	jalr	64(ra) # 80000598 <printf>
}
    80006560:	60a6                	ld	ra,72(sp)
    80006562:	6406                	ld	s0,64(sp)
    80006564:	74e2                	ld	s1,56(sp)
    80006566:	7942                	ld	s2,48(sp)
    80006568:	79a2                	ld	s3,40(sp)
    8000656a:	7a02                	ld	s4,32(sp)
    8000656c:	6ae2                	ld	s5,24(sp)
    8000656e:	6b42                	ld	s6,16(sp)
    80006570:	6ba2                	ld	s7,8(sp)
    80006572:	6161                	addi	sp,sp,80
    80006574:	8082                	ret
  lb = 0;
    80006576:	4a81                	li	s5,0
    80006578:	b7d1                	j	8000653c <bd_print_vector+0x74>

000000008000657a <bd_print>:

// Print buddy's data structures
void
bd_print() {
  for (int k = 0; k < nsizes; k++) {
    8000657a:	00024697          	auipc	a3,0x24
    8000657e:	ade6a683          	lw	a3,-1314(a3) # 8002a058 <nsizes>
    80006582:	10d05063          	blez	a3,80006682 <bd_print+0x108>
bd_print() {
    80006586:	711d                	addi	sp,sp,-96
    80006588:	ec86                	sd	ra,88(sp)
    8000658a:	e8a2                	sd	s0,80(sp)
    8000658c:	e4a6                	sd	s1,72(sp)
    8000658e:	e0ca                	sd	s2,64(sp)
    80006590:	fc4e                	sd	s3,56(sp)
    80006592:	f852                	sd	s4,48(sp)
    80006594:	f456                	sd	s5,40(sp)
    80006596:	f05a                	sd	s6,32(sp)
    80006598:	ec5e                	sd	s7,24(sp)
    8000659a:	e862                	sd	s8,16(sp)
    8000659c:	e466                	sd	s9,8(sp)
    8000659e:	e06a                	sd	s10,0(sp)
    800065a0:	1080                	addi	s0,sp,96
  for (int k = 0; k < nsizes; k++) {
    800065a2:	4481                	li	s1,0
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    800065a4:	4a85                	li	s5,1
    800065a6:	4c41                	li	s8,16
    800065a8:	00002b97          	auipc	s7,0x2
    800065ac:	338b8b93          	addi	s7,s7,824 # 800088e0 <userret+0x850>
    lst_print(&bd_sizes[k].free);
    800065b0:	00024a17          	auipc	s4,0x24
    800065b4:	aa0a0a13          	addi	s4,s4,-1376 # 8002a050 <bd_sizes>
    printf("  alloc:");
    800065b8:	00002b17          	auipc	s6,0x2
    800065bc:	350b0b13          	addi	s6,s6,848 # 80008908 <userret+0x878>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    800065c0:	00024997          	auipc	s3,0x24
    800065c4:	a9898993          	addi	s3,s3,-1384 # 8002a058 <nsizes>
    if(k > 0) {
      printf("  split:");
    800065c8:	00002c97          	auipc	s9,0x2
    800065cc:	350c8c93          	addi	s9,s9,848 # 80008918 <userret+0x888>
    800065d0:	a801                	j	800065e0 <bd_print+0x66>
  for (int k = 0; k < nsizes; k++) {
    800065d2:	0009a683          	lw	a3,0(s3)
    800065d6:	0485                	addi	s1,s1,1
    800065d8:	0004879b          	sext.w	a5,s1
    800065dc:	08d7d563          	bge	a5,a3,80006666 <bd_print+0xec>
    800065e0:	0004891b          	sext.w	s2,s1
    printf("size %d (blksz %d nblk %d): free list: ", k, BLK_SIZE(k), NBLK(k));
    800065e4:	36fd                	addiw	a3,a3,-1
    800065e6:	9e85                	subw	a3,a3,s1
    800065e8:	00da96bb          	sllw	a3,s5,a3
    800065ec:	009c1633          	sll	a2,s8,s1
    800065f0:	85ca                	mv	a1,s2
    800065f2:	855e                	mv	a0,s7
    800065f4:	ffffa097          	auipc	ra,0xffffa
    800065f8:	fa4080e7          	jalr	-92(ra) # 80000598 <printf>
    lst_print(&bd_sizes[k].free);
    800065fc:	00549d13          	slli	s10,s1,0x5
    80006600:	000a3503          	ld	a0,0(s4)
    80006604:	956a                	add	a0,a0,s10
    80006606:	00001097          	auipc	ra,0x1
    8000660a:	a4e080e7          	jalr	-1458(ra) # 80007054 <lst_print>
    printf("  alloc:");
    8000660e:	855a                	mv	a0,s6
    80006610:	ffffa097          	auipc	ra,0xffffa
    80006614:	f88080e7          	jalr	-120(ra) # 80000598 <printf>
    bd_print_vector(bd_sizes[k].alloc, NBLK(k));
    80006618:	0009a583          	lw	a1,0(s3)
    8000661c:	35fd                	addiw	a1,a1,-1
    8000661e:	412585bb          	subw	a1,a1,s2
    80006622:	000a3783          	ld	a5,0(s4)
    80006626:	97ea                	add	a5,a5,s10
    80006628:	00ba95bb          	sllw	a1,s5,a1
    8000662c:	6b88                	ld	a0,16(a5)
    8000662e:	00000097          	auipc	ra,0x0
    80006632:	e9a080e7          	jalr	-358(ra) # 800064c8 <bd_print_vector>
    if(k > 0) {
    80006636:	f9205ee3          	blez	s2,800065d2 <bd_print+0x58>
      printf("  split:");
    8000663a:	8566                	mv	a0,s9
    8000663c:	ffffa097          	auipc	ra,0xffffa
    80006640:	f5c080e7          	jalr	-164(ra) # 80000598 <printf>
      bd_print_vector(bd_sizes[k].split, NBLK(k));
    80006644:	0009a583          	lw	a1,0(s3)
    80006648:	35fd                	addiw	a1,a1,-1
    8000664a:	412585bb          	subw	a1,a1,s2
    8000664e:	000a3783          	ld	a5,0(s4)
    80006652:	9d3e                	add	s10,s10,a5
    80006654:	00ba95bb          	sllw	a1,s5,a1
    80006658:	018d3503          	ld	a0,24(s10)
    8000665c:	00000097          	auipc	ra,0x0
    80006660:	e6c080e7          	jalr	-404(ra) # 800064c8 <bd_print_vector>
    80006664:	b7bd                	j	800065d2 <bd_print+0x58>
    }
  }
}
    80006666:	60e6                	ld	ra,88(sp)
    80006668:	6446                	ld	s0,80(sp)
    8000666a:	64a6                	ld	s1,72(sp)
    8000666c:	6906                	ld	s2,64(sp)
    8000666e:	79e2                	ld	s3,56(sp)
    80006670:	7a42                	ld	s4,48(sp)
    80006672:	7aa2                	ld	s5,40(sp)
    80006674:	7b02                	ld	s6,32(sp)
    80006676:	6be2                	ld	s7,24(sp)
    80006678:	6c42                	ld	s8,16(sp)
    8000667a:	6ca2                	ld	s9,8(sp)
    8000667c:	6d02                	ld	s10,0(sp)
    8000667e:	6125                	addi	sp,sp,96
    80006680:	8082                	ret
    80006682:	8082                	ret

0000000080006684 <firstk>:

// What is the first k such that 2^k >= n?
int
firstk(uint64 n) {
    80006684:	1141                	addi	sp,sp,-16
    80006686:	e422                	sd	s0,8(sp)
    80006688:	0800                	addi	s0,sp,16
  int k = 0;
  uint64 size = LEAF_SIZE;

  while (size < n) {
    8000668a:	47c1                	li	a5,16
    8000668c:	00a7fb63          	bgeu	a5,a0,800066a2 <firstk+0x1e>
    80006690:	872a                	mv	a4,a0
  int k = 0;
    80006692:	4501                	li	a0,0
    k++;
    80006694:	2505                	addiw	a0,a0,1
    size *= 2;
    80006696:	0786                	slli	a5,a5,0x1
  while (size < n) {
    80006698:	fee7eee3          	bltu	a5,a4,80006694 <firstk+0x10>
  }
  return k;
}
    8000669c:	6422                	ld	s0,8(sp)
    8000669e:	0141                	addi	sp,sp,16
    800066a0:	8082                	ret
  int k = 0;
    800066a2:	4501                	li	a0,0
    800066a4:	bfe5                	j	8000669c <firstk+0x18>

00000000800066a6 <blk_index>:

// Compute the block index for address p at size k
int
blk_index(int k, char *p) {
    800066a6:	1141                	addi	sp,sp,-16
    800066a8:	e422                	sd	s0,8(sp)
    800066aa:	0800                	addi	s0,sp,16
  int n = p - (char *) bd_base;
  return n / BLK_SIZE(k);
    800066ac:	00024797          	auipc	a5,0x24
    800066b0:	99c7b783          	ld	a5,-1636(a5) # 8002a048 <bd_base>
    800066b4:	9d9d                	subw	a1,a1,a5
    800066b6:	47c1                	li	a5,16
    800066b8:	00a79533          	sll	a0,a5,a0
    800066bc:	02a5c533          	div	a0,a1,a0
}
    800066c0:	2501                	sext.w	a0,a0
    800066c2:	6422                	ld	s0,8(sp)
    800066c4:	0141                	addi	sp,sp,16
    800066c6:	8082                	ret

00000000800066c8 <addr>:

// Convert a block index at size k back into an address
void *addr(int k, int bi) {
    800066c8:	1141                	addi	sp,sp,-16
    800066ca:	e422                	sd	s0,8(sp)
    800066cc:	0800                	addi	s0,sp,16
  int n = bi * BLK_SIZE(k);
    800066ce:	47c1                	li	a5,16
    800066d0:	00a797b3          	sll	a5,a5,a0
  return (char *) bd_base + n;
    800066d4:	02b787bb          	mulw	a5,a5,a1
}
    800066d8:	00024517          	auipc	a0,0x24
    800066dc:	97053503          	ld	a0,-1680(a0) # 8002a048 <bd_base>
    800066e0:	953e                	add	a0,a0,a5
    800066e2:	6422                	ld	s0,8(sp)
    800066e4:	0141                	addi	sp,sp,16
    800066e6:	8082                	ret

00000000800066e8 <bd_malloc>:

// allocate nbytes, but malloc won't return anything smaller than LEAF_SIZE
void *
bd_malloc(uint64 nbytes)
{
    800066e8:	7159                	addi	sp,sp,-112
    800066ea:	f486                	sd	ra,104(sp)
    800066ec:	f0a2                	sd	s0,96(sp)
    800066ee:	eca6                	sd	s1,88(sp)
    800066f0:	e8ca                	sd	s2,80(sp)
    800066f2:	e4ce                	sd	s3,72(sp)
    800066f4:	e0d2                	sd	s4,64(sp)
    800066f6:	fc56                	sd	s5,56(sp)
    800066f8:	f85a                	sd	s6,48(sp)
    800066fa:	f45e                	sd	s7,40(sp)
    800066fc:	f062                	sd	s8,32(sp)
    800066fe:	ec66                	sd	s9,24(sp)
    80006700:	e86a                	sd	s10,16(sp)
    80006702:	e46e                	sd	s11,8(sp)
    80006704:	1880                	addi	s0,sp,112
    80006706:	84aa                	mv	s1,a0
  int fk, k;

  acquire(&lock);
    80006708:	00024517          	auipc	a0,0x24
    8000670c:	8f850513          	addi	a0,a0,-1800 # 8002a000 <lock>
    80006710:	ffffa097          	auipc	ra,0xffffa
    80006714:	2bc080e7          	jalr	700(ra) # 800009cc <acquire>

  // Find a free block >= nbytes, starting with smallest k possible
  fk = firstk(nbytes);
    80006718:	8526                	mv	a0,s1
    8000671a:	00000097          	auipc	ra,0x0
    8000671e:	f6a080e7          	jalr	-150(ra) # 80006684 <firstk>
  for (k = fk; k < nsizes; k++) {
    80006722:	00024797          	auipc	a5,0x24
    80006726:	9367a783          	lw	a5,-1738(a5) # 8002a058 <nsizes>
    8000672a:	02f55d63          	bge	a0,a5,80006764 <bd_malloc+0x7c>
    8000672e:	8c2a                	mv	s8,a0
    80006730:	00551913          	slli	s2,a0,0x5
    80006734:	84aa                	mv	s1,a0
    if(!lst_empty(&bd_sizes[k].free))
    80006736:	00024997          	auipc	s3,0x24
    8000673a:	91a98993          	addi	s3,s3,-1766 # 8002a050 <bd_sizes>
  for (k = fk; k < nsizes; k++) {
    8000673e:	00024a17          	auipc	s4,0x24
    80006742:	91aa0a13          	addi	s4,s4,-1766 # 8002a058 <nsizes>
    if(!lst_empty(&bd_sizes[k].free))
    80006746:	0009b503          	ld	a0,0(s3)
    8000674a:	954a                	add	a0,a0,s2
    8000674c:	00001097          	auipc	ra,0x1
    80006750:	88e080e7          	jalr	-1906(ra) # 80006fda <lst_empty>
    80006754:	c115                	beqz	a0,80006778 <bd_malloc+0x90>
  for (k = fk; k < nsizes; k++) {
    80006756:	2485                	addiw	s1,s1,1
    80006758:	02090913          	addi	s2,s2,32
    8000675c:	000a2783          	lw	a5,0(s4)
    80006760:	fef4c3e3          	blt	s1,a5,80006746 <bd_malloc+0x5e>
      break;
  }
  if(k >= nsizes) { // No free blocks?
    release(&lock);
    80006764:	00024517          	auipc	a0,0x24
    80006768:	89c50513          	addi	a0,a0,-1892 # 8002a000 <lock>
    8000676c:	ffffa097          	auipc	ra,0xffffa
    80006770:	2c8080e7          	jalr	712(ra) # 80000a34 <release>
    return 0;
    80006774:	4b01                	li	s6,0
    80006776:	a0e1                	j	8000683e <bd_malloc+0x156>
  if(k >= nsizes) { // No free blocks?
    80006778:	00024797          	auipc	a5,0x24
    8000677c:	8e07a783          	lw	a5,-1824(a5) # 8002a058 <nsizes>
    80006780:	fef4d2e3          	bge	s1,a5,80006764 <bd_malloc+0x7c>
  }

  // Found a block; pop it and potentially split it.
  char *p = lst_pop(&bd_sizes[k].free);
    80006784:	00549993          	slli	s3,s1,0x5
    80006788:	00024917          	auipc	s2,0x24
    8000678c:	8c890913          	addi	s2,s2,-1848 # 8002a050 <bd_sizes>
    80006790:	00093503          	ld	a0,0(s2)
    80006794:	954e                	add	a0,a0,s3
    80006796:	00001097          	auipc	ra,0x1
    8000679a:	870080e7          	jalr	-1936(ra) # 80007006 <lst_pop>
    8000679e:	8b2a                	mv	s6,a0
  return n / BLK_SIZE(k);
    800067a0:	00024597          	auipc	a1,0x24
    800067a4:	8a85b583          	ld	a1,-1880(a1) # 8002a048 <bd_base>
    800067a8:	40b505bb          	subw	a1,a0,a1
    800067ac:	47c1                	li	a5,16
    800067ae:	009797b3          	sll	a5,a5,s1
    800067b2:	02f5c5b3          	div	a1,a1,a5
  bit_set(bd_sizes[k].alloc, blk_index(k, p));
    800067b6:	00093783          	ld	a5,0(s2)
    800067ba:	97ce                	add	a5,a5,s3
    800067bc:	2581                	sext.w	a1,a1
    800067be:	6b88                	ld	a0,16(a5)
    800067c0:	00000097          	auipc	ra,0x0
    800067c4:	ca4080e7          	jalr	-860(ra) # 80006464 <bit_set>
  for(; k > fk; k--) {
    800067c8:	069c5363          	bge	s8,s1,8000682e <bd_malloc+0x146>
    // split a block at size k and mark one half allocated at size k-1
    // and put the buddy on the free list at size k-1
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800067cc:	4bc1                	li	s7,16
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800067ce:	8dca                	mv	s11,s2
  int n = p - (char *) bd_base;
    800067d0:	00024d17          	auipc	s10,0x24
    800067d4:	878d0d13          	addi	s10,s10,-1928 # 8002a048 <bd_base>
    char *q = p + BLK_SIZE(k-1);   // p's buddy
    800067d8:	85a6                	mv	a1,s1
    800067da:	34fd                	addiw	s1,s1,-1
    800067dc:	009b9ab3          	sll	s5,s7,s1
    800067e0:	015b0cb3          	add	s9,s6,s5
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800067e4:	000dba03          	ld	s4,0(s11)
  int n = p - (char *) bd_base;
    800067e8:	000d3903          	ld	s2,0(s10)
  return n / BLK_SIZE(k);
    800067ec:	412b093b          	subw	s2,s6,s2
    800067f0:	00bb95b3          	sll	a1,s7,a1
    800067f4:	02b945b3          	div	a1,s2,a1
    bit_set(bd_sizes[k].split, blk_index(k, p));
    800067f8:	013a07b3          	add	a5,s4,s3
    800067fc:	2581                	sext.w	a1,a1
    800067fe:	6f88                	ld	a0,24(a5)
    80006800:	00000097          	auipc	ra,0x0
    80006804:	c64080e7          	jalr	-924(ra) # 80006464 <bit_set>
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006808:	1981                	addi	s3,s3,-32
    8000680a:	9a4e                	add	s4,s4,s3
  return n / BLK_SIZE(k);
    8000680c:	035945b3          	div	a1,s2,s5
    bit_set(bd_sizes[k-1].alloc, blk_index(k-1, p));
    80006810:	2581                	sext.w	a1,a1
    80006812:	010a3503          	ld	a0,16(s4)
    80006816:	00000097          	auipc	ra,0x0
    8000681a:	c4e080e7          	jalr	-946(ra) # 80006464 <bit_set>
    lst_push(&bd_sizes[k-1].free, q);
    8000681e:	85e6                	mv	a1,s9
    80006820:	8552                	mv	a0,s4
    80006822:	00001097          	auipc	ra,0x1
    80006826:	81a080e7          	jalr	-2022(ra) # 8000703c <lst_push>
  for(; k > fk; k--) {
    8000682a:	fb8497e3          	bne	s1,s8,800067d8 <bd_malloc+0xf0>
  }
  release(&lock);
    8000682e:	00023517          	auipc	a0,0x23
    80006832:	7d250513          	addi	a0,a0,2002 # 8002a000 <lock>
    80006836:	ffffa097          	auipc	ra,0xffffa
    8000683a:	1fe080e7          	jalr	510(ra) # 80000a34 <release>

  return p;
}
    8000683e:	855a                	mv	a0,s6
    80006840:	70a6                	ld	ra,104(sp)
    80006842:	7406                	ld	s0,96(sp)
    80006844:	64e6                	ld	s1,88(sp)
    80006846:	6946                	ld	s2,80(sp)
    80006848:	69a6                	ld	s3,72(sp)
    8000684a:	6a06                	ld	s4,64(sp)
    8000684c:	7ae2                	ld	s5,56(sp)
    8000684e:	7b42                	ld	s6,48(sp)
    80006850:	7ba2                	ld	s7,40(sp)
    80006852:	7c02                	ld	s8,32(sp)
    80006854:	6ce2                	ld	s9,24(sp)
    80006856:	6d42                	ld	s10,16(sp)
    80006858:	6da2                	ld	s11,8(sp)
    8000685a:	6165                	addi	sp,sp,112
    8000685c:	8082                	ret

000000008000685e <size>:

// Find the size of the block that p points to.
int
size(char *p) {
    8000685e:	7139                	addi	sp,sp,-64
    80006860:	fc06                	sd	ra,56(sp)
    80006862:	f822                	sd	s0,48(sp)
    80006864:	f426                	sd	s1,40(sp)
    80006866:	f04a                	sd	s2,32(sp)
    80006868:	ec4e                	sd	s3,24(sp)
    8000686a:	e852                	sd	s4,16(sp)
    8000686c:	e456                	sd	s5,8(sp)
    8000686e:	e05a                	sd	s6,0(sp)
    80006870:	0080                	addi	s0,sp,64
  for (int k = 0; k < nsizes; k++) {
    80006872:	00023a97          	auipc	s5,0x23
    80006876:	7e6aaa83          	lw	s5,2022(s5) # 8002a058 <nsizes>
  return n / BLK_SIZE(k);
    8000687a:	00023a17          	auipc	s4,0x23
    8000687e:	7cea3a03          	ld	s4,1998(s4) # 8002a048 <bd_base>
    80006882:	41450a3b          	subw	s4,a0,s4
    80006886:	00023497          	auipc	s1,0x23
    8000688a:	7ca4b483          	ld	s1,1994(s1) # 8002a050 <bd_sizes>
    8000688e:	03848493          	addi	s1,s1,56
  for (int k = 0; k < nsizes; k++) {
    80006892:	4901                	li	s2,0
  return n / BLK_SIZE(k);
    80006894:	4b41                	li	s6,16
  for (int k = 0; k < nsizes; k++) {
    80006896:	03595363          	bge	s2,s5,800068bc <size+0x5e>
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    8000689a:	0019099b          	addiw	s3,s2,1
  return n / BLK_SIZE(k);
    8000689e:	013b15b3          	sll	a1,s6,s3
    800068a2:	02ba45b3          	div	a1,s4,a1
    if(bit_isset(bd_sizes[k+1].split, blk_index(k+1, p))) {
    800068a6:	2581                	sext.w	a1,a1
    800068a8:	6088                	ld	a0,0(s1)
    800068aa:	00000097          	auipc	ra,0x0
    800068ae:	b82080e7          	jalr	-1150(ra) # 8000642c <bit_isset>
    800068b2:	02048493          	addi	s1,s1,32
    800068b6:	e501                	bnez	a0,800068be <size+0x60>
  for (int k = 0; k < nsizes; k++) {
    800068b8:	894e                	mv	s2,s3
    800068ba:	bff1                	j	80006896 <size+0x38>
      return k;
    }
  }
  return 0;
    800068bc:	4901                	li	s2,0
}
    800068be:	854a                	mv	a0,s2
    800068c0:	70e2                	ld	ra,56(sp)
    800068c2:	7442                	ld	s0,48(sp)
    800068c4:	74a2                	ld	s1,40(sp)
    800068c6:	7902                	ld	s2,32(sp)
    800068c8:	69e2                	ld	s3,24(sp)
    800068ca:	6a42                	ld	s4,16(sp)
    800068cc:	6aa2                	ld	s5,8(sp)
    800068ce:	6b02                	ld	s6,0(sp)
    800068d0:	6121                	addi	sp,sp,64
    800068d2:	8082                	ret

00000000800068d4 <bd_free>:

// Free memory pointed to by p, which was earlier allocated using
// bd_malloc.
void
bd_free(void *p) {
    800068d4:	7159                	addi	sp,sp,-112
    800068d6:	f486                	sd	ra,104(sp)
    800068d8:	f0a2                	sd	s0,96(sp)
    800068da:	eca6                	sd	s1,88(sp)
    800068dc:	e8ca                	sd	s2,80(sp)
    800068de:	e4ce                	sd	s3,72(sp)
    800068e0:	e0d2                	sd	s4,64(sp)
    800068e2:	fc56                	sd	s5,56(sp)
    800068e4:	f85a                	sd	s6,48(sp)
    800068e6:	f45e                	sd	s7,40(sp)
    800068e8:	f062                	sd	s8,32(sp)
    800068ea:	ec66                	sd	s9,24(sp)
    800068ec:	e86a                	sd	s10,16(sp)
    800068ee:	e46e                	sd	s11,8(sp)
    800068f0:	1880                	addi	s0,sp,112
    800068f2:	8aaa                	mv	s5,a0
  void *q;
  int k;

  acquire(&lock);
    800068f4:	00023517          	auipc	a0,0x23
    800068f8:	70c50513          	addi	a0,a0,1804 # 8002a000 <lock>
    800068fc:	ffffa097          	auipc	ra,0xffffa
    80006900:	0d0080e7          	jalr	208(ra) # 800009cc <acquire>
  for (k = size(p); k < MAXSIZE; k++) {
    80006904:	8556                	mv	a0,s5
    80006906:	00000097          	auipc	ra,0x0
    8000690a:	f58080e7          	jalr	-168(ra) # 8000685e <size>
    8000690e:	84aa                	mv	s1,a0
    80006910:	00023797          	auipc	a5,0x23
    80006914:	7487a783          	lw	a5,1864(a5) # 8002a058 <nsizes>
    80006918:	37fd                	addiw	a5,a5,-1
    8000691a:	0af55d63          	bge	a0,a5,800069d4 <bd_free+0x100>
    8000691e:	00551a13          	slli	s4,a0,0x5
  int n = p - (char *) bd_base;
    80006922:	00023c17          	auipc	s8,0x23
    80006926:	726c0c13          	addi	s8,s8,1830 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    8000692a:	4bc1                	li	s7,16
    int bi = blk_index(k, p);
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    8000692c:	00023b17          	auipc	s6,0x23
    80006930:	724b0b13          	addi	s6,s6,1828 # 8002a050 <bd_sizes>
  for (k = size(p); k < MAXSIZE; k++) {
    80006934:	00023c97          	auipc	s9,0x23
    80006938:	724c8c93          	addi	s9,s9,1828 # 8002a058 <nsizes>
    8000693c:	a82d                	j	80006976 <bd_free+0xa2>
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    8000693e:	fff58d9b          	addiw	s11,a1,-1
    80006942:	a881                	j	80006992 <bd_free+0xbe>
    if(buddy % 2 == 0) {
      p = q;
    }
    // at size k+1, mark that the merged buddy pair isn't split
    // anymore
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    80006944:	020a0a13          	addi	s4,s4,32
    80006948:	2485                	addiw	s1,s1,1
  int n = p - (char *) bd_base;
    8000694a:	000c3583          	ld	a1,0(s8)
  return n / BLK_SIZE(k);
    8000694e:	40ba85bb          	subw	a1,s5,a1
    80006952:	009b97b3          	sll	a5,s7,s1
    80006956:	02f5c5b3          	div	a1,a1,a5
    bit_clear(bd_sizes[k+1].split, blk_index(k+1, p));
    8000695a:	000b3783          	ld	a5,0(s6)
    8000695e:	97d2                	add	a5,a5,s4
    80006960:	2581                	sext.w	a1,a1
    80006962:	6f88                	ld	a0,24(a5)
    80006964:	00000097          	auipc	ra,0x0
    80006968:	b30080e7          	jalr	-1232(ra) # 80006494 <bit_clear>
  for (k = size(p); k < MAXSIZE; k++) {
    8000696c:	000ca783          	lw	a5,0(s9)
    80006970:	37fd                	addiw	a5,a5,-1
    80006972:	06f4d163          	bge	s1,a5,800069d4 <bd_free+0x100>
  int n = p - (char *) bd_base;
    80006976:	000c3903          	ld	s2,0(s8)
  return n / BLK_SIZE(k);
    8000697a:	009b99b3          	sll	s3,s7,s1
    8000697e:	412a87bb          	subw	a5,s5,s2
    80006982:	0337c7b3          	div	a5,a5,s3
    80006986:	0007859b          	sext.w	a1,a5
    int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    8000698a:	8b85                	andi	a5,a5,1
    8000698c:	fbcd                	bnez	a5,8000693e <bd_free+0x6a>
    8000698e:	00158d9b          	addiw	s11,a1,1
    bit_clear(bd_sizes[k].alloc, bi);  // free p at size k
    80006992:	000b3d03          	ld	s10,0(s6)
    80006996:	9d52                	add	s10,s10,s4
    80006998:	010d3503          	ld	a0,16(s10)
    8000699c:	00000097          	auipc	ra,0x0
    800069a0:	af8080e7          	jalr	-1288(ra) # 80006494 <bit_clear>
    if (bit_isset(bd_sizes[k].alloc, buddy)) {  // is buddy allocated?
    800069a4:	85ee                	mv	a1,s11
    800069a6:	010d3503          	ld	a0,16(s10)
    800069aa:	00000097          	auipc	ra,0x0
    800069ae:	a82080e7          	jalr	-1406(ra) # 8000642c <bit_isset>
    800069b2:	e10d                	bnez	a0,800069d4 <bd_free+0x100>
  int n = bi * BLK_SIZE(k);
    800069b4:	000d8d1b          	sext.w	s10,s11
  return (char *) bd_base + n;
    800069b8:	03b989bb          	mulw	s3,s3,s11
    800069bc:	994e                	add	s2,s2,s3
    lst_remove(q);    // remove buddy from free list
    800069be:	854a                	mv	a0,s2
    800069c0:	00000097          	auipc	ra,0x0
    800069c4:	630080e7          	jalr	1584(ra) # 80006ff0 <lst_remove>
    if(buddy % 2 == 0) {
    800069c8:	001d7d13          	andi	s10,s10,1
    800069cc:	f60d1ce3          	bnez	s10,80006944 <bd_free+0x70>
      p = q;
    800069d0:	8aca                	mv	s5,s2
    800069d2:	bf8d                	j	80006944 <bd_free+0x70>
  }
  lst_push(&bd_sizes[k].free, p);
    800069d4:	0496                	slli	s1,s1,0x5
    800069d6:	85d6                	mv	a1,s5
    800069d8:	00023517          	auipc	a0,0x23
    800069dc:	67853503          	ld	a0,1656(a0) # 8002a050 <bd_sizes>
    800069e0:	9526                	add	a0,a0,s1
    800069e2:	00000097          	auipc	ra,0x0
    800069e6:	65a080e7          	jalr	1626(ra) # 8000703c <lst_push>
  release(&lock);
    800069ea:	00023517          	auipc	a0,0x23
    800069ee:	61650513          	addi	a0,a0,1558 # 8002a000 <lock>
    800069f2:	ffffa097          	auipc	ra,0xffffa
    800069f6:	042080e7          	jalr	66(ra) # 80000a34 <release>
}
    800069fa:	70a6                	ld	ra,104(sp)
    800069fc:	7406                	ld	s0,96(sp)
    800069fe:	64e6                	ld	s1,88(sp)
    80006a00:	6946                	ld	s2,80(sp)
    80006a02:	69a6                	ld	s3,72(sp)
    80006a04:	6a06                	ld	s4,64(sp)
    80006a06:	7ae2                	ld	s5,56(sp)
    80006a08:	7b42                	ld	s6,48(sp)
    80006a0a:	7ba2                	ld	s7,40(sp)
    80006a0c:	7c02                	ld	s8,32(sp)
    80006a0e:	6ce2                	ld	s9,24(sp)
    80006a10:	6d42                	ld	s10,16(sp)
    80006a12:	6da2                	ld	s11,8(sp)
    80006a14:	6165                	addi	sp,sp,112
    80006a16:	8082                	ret

0000000080006a18 <blk_index_next>:

// Compute the first block at size k that doesn't contain p
int
blk_index_next(int k, char *p) {
    80006a18:	1141                	addi	sp,sp,-16
    80006a1a:	e422                	sd	s0,8(sp)
    80006a1c:	0800                	addi	s0,sp,16
  int n = (p - (char *) bd_base) / BLK_SIZE(k);
    80006a1e:	00023797          	auipc	a5,0x23
    80006a22:	62a7b783          	ld	a5,1578(a5) # 8002a048 <bd_base>
    80006a26:	8d9d                	sub	a1,a1,a5
    80006a28:	47c1                	li	a5,16
    80006a2a:	00a797b3          	sll	a5,a5,a0
    80006a2e:	02f5c533          	div	a0,a1,a5
    80006a32:	2501                	sext.w	a0,a0
  if((p - (char*) bd_base) % BLK_SIZE(k) != 0)
    80006a34:	02f5e5b3          	rem	a1,a1,a5
    80006a38:	c191                	beqz	a1,80006a3c <blk_index_next+0x24>
      n++;
    80006a3a:	2505                	addiw	a0,a0,1
  return n ;
}
    80006a3c:	6422                	ld	s0,8(sp)
    80006a3e:	0141                	addi	sp,sp,16
    80006a40:	8082                	ret

0000000080006a42 <log2>:

int
log2(uint64 n) {
    80006a42:	1141                	addi	sp,sp,-16
    80006a44:	e422                	sd	s0,8(sp)
    80006a46:	0800                	addi	s0,sp,16
  int k = 0;
  while (n > 1) {
    80006a48:	4705                	li	a4,1
    80006a4a:	00a77b63          	bgeu	a4,a0,80006a60 <log2+0x1e>
    80006a4e:	87aa                	mv	a5,a0
  int k = 0;
    80006a50:	4501                	li	a0,0
    k++;
    80006a52:	2505                	addiw	a0,a0,1
    n = n >> 1;
    80006a54:	8385                	srli	a5,a5,0x1
  while (n > 1) {
    80006a56:	fef76ee3          	bltu	a4,a5,80006a52 <log2+0x10>
  }
  return k;
}
    80006a5a:	6422                	ld	s0,8(sp)
    80006a5c:	0141                	addi	sp,sp,16
    80006a5e:	8082                	ret
  int k = 0;
    80006a60:	4501                	li	a0,0
    80006a62:	bfe5                	j	80006a5a <log2+0x18>

0000000080006a64 <bd_mark>:

// Mark memory from [start, stop), starting at size 0, as allocated. 
void
bd_mark(void *start, void *stop)
{
    80006a64:	711d                	addi	sp,sp,-96
    80006a66:	ec86                	sd	ra,88(sp)
    80006a68:	e8a2                	sd	s0,80(sp)
    80006a6a:	e4a6                	sd	s1,72(sp)
    80006a6c:	e0ca                	sd	s2,64(sp)
    80006a6e:	fc4e                	sd	s3,56(sp)
    80006a70:	f852                	sd	s4,48(sp)
    80006a72:	f456                	sd	s5,40(sp)
    80006a74:	f05a                	sd	s6,32(sp)
    80006a76:	ec5e                	sd	s7,24(sp)
    80006a78:	e862                	sd	s8,16(sp)
    80006a7a:	e466                	sd	s9,8(sp)
    80006a7c:	e06a                	sd	s10,0(sp)
    80006a7e:	1080                	addi	s0,sp,96
  int bi, bj;

  if (((uint64) start % LEAF_SIZE != 0) || ((uint64) stop % LEAF_SIZE != 0))
    80006a80:	00b56933          	or	s2,a0,a1
    80006a84:	00f97913          	andi	s2,s2,15
    80006a88:	04091263          	bnez	s2,80006acc <bd_mark+0x68>
    80006a8c:	8b2a                	mv	s6,a0
    80006a8e:	8bae                	mv	s7,a1
    panic("bd_mark");

  for (int k = 0; k < nsizes; k++) {
    80006a90:	00023c17          	auipc	s8,0x23
    80006a94:	5c8c2c03          	lw	s8,1480(s8) # 8002a058 <nsizes>
    80006a98:	4981                	li	s3,0
  int n = p - (char *) bd_base;
    80006a9a:	00023d17          	auipc	s10,0x23
    80006a9e:	5aed0d13          	addi	s10,s10,1454 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006aa2:	4cc1                	li	s9,16
    bi = blk_index(k, start);
    bj = blk_index_next(k, stop);
    for(; bi < bj; bi++) {
      if(k > 0) {
        // if a block is allocated at size k, mark it as split too.
        bit_set(bd_sizes[k].split, bi);
    80006aa4:	00023a97          	auipc	s5,0x23
    80006aa8:	5aca8a93          	addi	s5,s5,1452 # 8002a050 <bd_sizes>
  for (int k = 0; k < nsizes; k++) {
    80006aac:	07804563          	bgtz	s8,80006b16 <bd_mark+0xb2>
      }
      bit_set(bd_sizes[k].alloc, bi);
    }
  }
}
    80006ab0:	60e6                	ld	ra,88(sp)
    80006ab2:	6446                	ld	s0,80(sp)
    80006ab4:	64a6                	ld	s1,72(sp)
    80006ab6:	6906                	ld	s2,64(sp)
    80006ab8:	79e2                	ld	s3,56(sp)
    80006aba:	7a42                	ld	s4,48(sp)
    80006abc:	7aa2                	ld	s5,40(sp)
    80006abe:	7b02                	ld	s6,32(sp)
    80006ac0:	6be2                	ld	s7,24(sp)
    80006ac2:	6c42                	ld	s8,16(sp)
    80006ac4:	6ca2                	ld	s9,8(sp)
    80006ac6:	6d02                	ld	s10,0(sp)
    80006ac8:	6125                	addi	sp,sp,96
    80006aca:	8082                	ret
    panic("bd_mark");
    80006acc:	00002517          	auipc	a0,0x2
    80006ad0:	e5c50513          	addi	a0,a0,-420 # 80008928 <userret+0x898>
    80006ad4:	ffffa097          	auipc	ra,0xffffa
    80006ad8:	a7a080e7          	jalr	-1414(ra) # 8000054e <panic>
      bit_set(bd_sizes[k].alloc, bi);
    80006adc:	000ab783          	ld	a5,0(s5)
    80006ae0:	97ca                	add	a5,a5,s2
    80006ae2:	85a6                	mv	a1,s1
    80006ae4:	6b88                	ld	a0,16(a5)
    80006ae6:	00000097          	auipc	ra,0x0
    80006aea:	97e080e7          	jalr	-1666(ra) # 80006464 <bit_set>
    for(; bi < bj; bi++) {
    80006aee:	2485                	addiw	s1,s1,1
    80006af0:	009a0e63          	beq	s4,s1,80006b0c <bd_mark+0xa8>
      if(k > 0) {
    80006af4:	ff3054e3          	blez	s3,80006adc <bd_mark+0x78>
        bit_set(bd_sizes[k].split, bi);
    80006af8:	000ab783          	ld	a5,0(s5)
    80006afc:	97ca                	add	a5,a5,s2
    80006afe:	85a6                	mv	a1,s1
    80006b00:	6f88                	ld	a0,24(a5)
    80006b02:	00000097          	auipc	ra,0x0
    80006b06:	962080e7          	jalr	-1694(ra) # 80006464 <bit_set>
    80006b0a:	bfc9                	j	80006adc <bd_mark+0x78>
  for (int k = 0; k < nsizes; k++) {
    80006b0c:	2985                	addiw	s3,s3,1
    80006b0e:	02090913          	addi	s2,s2,32
    80006b12:	f9898fe3          	beq	s3,s8,80006ab0 <bd_mark+0x4c>
  int n = p - (char *) bd_base;
    80006b16:	000d3483          	ld	s1,0(s10)
  return n / BLK_SIZE(k);
    80006b1a:	409b04bb          	subw	s1,s6,s1
    80006b1e:	013c97b3          	sll	a5,s9,s3
    80006b22:	02f4c4b3          	div	s1,s1,a5
    80006b26:	2481                	sext.w	s1,s1
    bj = blk_index_next(k, stop);
    80006b28:	85de                	mv	a1,s7
    80006b2a:	854e                	mv	a0,s3
    80006b2c:	00000097          	auipc	ra,0x0
    80006b30:	eec080e7          	jalr	-276(ra) # 80006a18 <blk_index_next>
    80006b34:	8a2a                	mv	s4,a0
    for(; bi < bj; bi++) {
    80006b36:	faa4cfe3          	blt	s1,a0,80006af4 <bd_mark+0x90>
    80006b3a:	bfc9                	j	80006b0c <bd_mark+0xa8>

0000000080006b3c <bd_initfree_pair>:

// If a block is marked as allocated and the buddy is free, put the
// buddy on the free list at size k.
int
bd_initfree_pair(int k, int bi) {
    80006b3c:	7139                	addi	sp,sp,-64
    80006b3e:	fc06                	sd	ra,56(sp)
    80006b40:	f822                	sd	s0,48(sp)
    80006b42:	f426                	sd	s1,40(sp)
    80006b44:	f04a                	sd	s2,32(sp)
    80006b46:	ec4e                	sd	s3,24(sp)
    80006b48:	e852                	sd	s4,16(sp)
    80006b4a:	e456                	sd	s5,8(sp)
    80006b4c:	e05a                	sd	s6,0(sp)
    80006b4e:	0080                	addi	s0,sp,64
    80006b50:	89aa                	mv	s3,a0
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006b52:	00058a9b          	sext.w	s5,a1
    80006b56:	0015f793          	andi	a5,a1,1
    80006b5a:	ebad                	bnez	a5,80006bcc <bd_initfree_pair+0x90>
    80006b5c:	00158a1b          	addiw	s4,a1,1
  int free = 0;
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006b60:	00599493          	slli	s1,s3,0x5
    80006b64:	00023797          	auipc	a5,0x23
    80006b68:	4ec7b783          	ld	a5,1260(a5) # 8002a050 <bd_sizes>
    80006b6c:	94be                	add	s1,s1,a5
    80006b6e:	0104bb03          	ld	s6,16(s1)
    80006b72:	855a                	mv	a0,s6
    80006b74:	00000097          	auipc	ra,0x0
    80006b78:	8b8080e7          	jalr	-1864(ra) # 8000642c <bit_isset>
    80006b7c:	892a                	mv	s2,a0
    80006b7e:	85d2                	mv	a1,s4
    80006b80:	855a                	mv	a0,s6
    80006b82:	00000097          	auipc	ra,0x0
    80006b86:	8aa080e7          	jalr	-1878(ra) # 8000642c <bit_isset>
  int free = 0;
    80006b8a:	4b01                	li	s6,0
  if(bit_isset(bd_sizes[k].alloc, bi) !=  bit_isset(bd_sizes[k].alloc, buddy)) {
    80006b8c:	02a90563          	beq	s2,a0,80006bb6 <bd_initfree_pair+0x7a>
    // one of the pair is free
    free = BLK_SIZE(k);
    80006b90:	45c1                	li	a1,16
    80006b92:	013599b3          	sll	s3,a1,s3
    80006b96:	00098b1b          	sext.w	s6,s3
    if(bit_isset(bd_sizes[k].alloc, bi))
    80006b9a:	02090c63          	beqz	s2,80006bd2 <bd_initfree_pair+0x96>
  return (char *) bd_base + n;
    80006b9e:	034989bb          	mulw	s3,s3,s4
      lst_push(&bd_sizes[k].free, addr(k, buddy));   // put buddy on free list
    80006ba2:	00023597          	auipc	a1,0x23
    80006ba6:	4a65b583          	ld	a1,1190(a1) # 8002a048 <bd_base>
    80006baa:	95ce                	add	a1,a1,s3
    80006bac:	8526                	mv	a0,s1
    80006bae:	00000097          	auipc	ra,0x0
    80006bb2:	48e080e7          	jalr	1166(ra) # 8000703c <lst_push>
    else
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
  }
  return free;
}
    80006bb6:	855a                	mv	a0,s6
    80006bb8:	70e2                	ld	ra,56(sp)
    80006bba:	7442                	ld	s0,48(sp)
    80006bbc:	74a2                	ld	s1,40(sp)
    80006bbe:	7902                	ld	s2,32(sp)
    80006bc0:	69e2                	ld	s3,24(sp)
    80006bc2:	6a42                	ld	s4,16(sp)
    80006bc4:	6aa2                	ld	s5,8(sp)
    80006bc6:	6b02                	ld	s6,0(sp)
    80006bc8:	6121                	addi	sp,sp,64
    80006bca:	8082                	ret
  int buddy = (bi % 2 == 0) ? bi+1 : bi-1;
    80006bcc:	fff58a1b          	addiw	s4,a1,-1
    80006bd0:	bf41                	j	80006b60 <bd_initfree_pair+0x24>
  return (char *) bd_base + n;
    80006bd2:	035989bb          	mulw	s3,s3,s5
      lst_push(&bd_sizes[k].free, addr(k, bi));      // put bi on free list
    80006bd6:	00023597          	auipc	a1,0x23
    80006bda:	4725b583          	ld	a1,1138(a1) # 8002a048 <bd_base>
    80006bde:	95ce                	add	a1,a1,s3
    80006be0:	8526                	mv	a0,s1
    80006be2:	00000097          	auipc	ra,0x0
    80006be6:	45a080e7          	jalr	1114(ra) # 8000703c <lst_push>
    80006bea:	b7f1                	j	80006bb6 <bd_initfree_pair+0x7a>

0000000080006bec <bd_initfree>:
  
// Initialize the free lists for each size k.  For each size k, there
// are only two pairs that may have a buddy that should be on free list:
// bd_left and bd_right.
int
bd_initfree(void *bd_left, void *bd_right) {
    80006bec:	711d                	addi	sp,sp,-96
    80006bee:	ec86                	sd	ra,88(sp)
    80006bf0:	e8a2                	sd	s0,80(sp)
    80006bf2:	e4a6                	sd	s1,72(sp)
    80006bf4:	e0ca                	sd	s2,64(sp)
    80006bf6:	fc4e                	sd	s3,56(sp)
    80006bf8:	f852                	sd	s4,48(sp)
    80006bfa:	f456                	sd	s5,40(sp)
    80006bfc:	f05a                	sd	s6,32(sp)
    80006bfe:	ec5e                	sd	s7,24(sp)
    80006c00:	e862                	sd	s8,16(sp)
    80006c02:	e466                	sd	s9,8(sp)
    80006c04:	e06a                	sd	s10,0(sp)
    80006c06:	1080                	addi	s0,sp,96
  int free = 0;

  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006c08:	00023717          	auipc	a4,0x23
    80006c0c:	45072703          	lw	a4,1104(a4) # 8002a058 <nsizes>
    80006c10:	4785                	li	a5,1
    80006c12:	06e7db63          	bge	a5,a4,80006c88 <bd_initfree+0x9c>
    80006c16:	8aaa                	mv	s5,a0
    80006c18:	8b2e                	mv	s6,a1
    80006c1a:	4901                	li	s2,0
  int free = 0;
    80006c1c:	4a01                	li	s4,0
  int n = p - (char *) bd_base;
    80006c1e:	00023c97          	auipc	s9,0x23
    80006c22:	42ac8c93          	addi	s9,s9,1066 # 8002a048 <bd_base>
  return n / BLK_SIZE(k);
    80006c26:	4c41                	li	s8,16
  for (int k = 0; k < MAXSIZE; k++) {   // skip max size
    80006c28:	00023b97          	auipc	s7,0x23
    80006c2c:	430b8b93          	addi	s7,s7,1072 # 8002a058 <nsizes>
    80006c30:	a039                	j	80006c3e <bd_initfree+0x52>
    80006c32:	2905                	addiw	s2,s2,1
    80006c34:	000ba783          	lw	a5,0(s7)
    80006c38:	37fd                	addiw	a5,a5,-1
    80006c3a:	04f95863          	bge	s2,a5,80006c8a <bd_initfree+0x9e>
    int left = blk_index_next(k, bd_left);
    80006c3e:	85d6                	mv	a1,s5
    80006c40:	854a                	mv	a0,s2
    80006c42:	00000097          	auipc	ra,0x0
    80006c46:	dd6080e7          	jalr	-554(ra) # 80006a18 <blk_index_next>
    80006c4a:	89aa                	mv	s3,a0
  int n = p - (char *) bd_base;
    80006c4c:	000cb483          	ld	s1,0(s9)
  return n / BLK_SIZE(k);
    80006c50:	409b04bb          	subw	s1,s6,s1
    80006c54:	012c17b3          	sll	a5,s8,s2
    80006c58:	02f4c4b3          	div	s1,s1,a5
    80006c5c:	2481                	sext.w	s1,s1
    int right = blk_index(k, bd_right);
    free += bd_initfree_pair(k, left);
    80006c5e:	85aa                	mv	a1,a0
    80006c60:	854a                	mv	a0,s2
    80006c62:	00000097          	auipc	ra,0x0
    80006c66:	eda080e7          	jalr	-294(ra) # 80006b3c <bd_initfree_pair>
    80006c6a:	01450d3b          	addw	s10,a0,s4
    80006c6e:	000d0a1b          	sext.w	s4,s10
    if(right <= left)
    80006c72:	fc99d0e3          	bge	s3,s1,80006c32 <bd_initfree+0x46>
      continue;
    free += bd_initfree_pair(k, right);
    80006c76:	85a6                	mv	a1,s1
    80006c78:	854a                	mv	a0,s2
    80006c7a:	00000097          	auipc	ra,0x0
    80006c7e:	ec2080e7          	jalr	-318(ra) # 80006b3c <bd_initfree_pair>
    80006c82:	00ad0a3b          	addw	s4,s10,a0
    80006c86:	b775                	j	80006c32 <bd_initfree+0x46>
  int free = 0;
    80006c88:	4a01                	li	s4,0
  }
  return free;
}
    80006c8a:	8552                	mv	a0,s4
    80006c8c:	60e6                	ld	ra,88(sp)
    80006c8e:	6446                	ld	s0,80(sp)
    80006c90:	64a6                	ld	s1,72(sp)
    80006c92:	6906                	ld	s2,64(sp)
    80006c94:	79e2                	ld	s3,56(sp)
    80006c96:	7a42                	ld	s4,48(sp)
    80006c98:	7aa2                	ld	s5,40(sp)
    80006c9a:	7b02                	ld	s6,32(sp)
    80006c9c:	6be2                	ld	s7,24(sp)
    80006c9e:	6c42                	ld	s8,16(sp)
    80006ca0:	6ca2                	ld	s9,8(sp)
    80006ca2:	6d02                	ld	s10,0(sp)
    80006ca4:	6125                	addi	sp,sp,96
    80006ca6:	8082                	ret

0000000080006ca8 <bd_mark_data_structures>:

// Mark the range [bd_base,p) as allocated
int
bd_mark_data_structures(char *p) {
    80006ca8:	7179                	addi	sp,sp,-48
    80006caa:	f406                	sd	ra,40(sp)
    80006cac:	f022                	sd	s0,32(sp)
    80006cae:	ec26                	sd	s1,24(sp)
    80006cb0:	e84a                	sd	s2,16(sp)
    80006cb2:	e44e                	sd	s3,8(sp)
    80006cb4:	1800                	addi	s0,sp,48
    80006cb6:	892a                	mv	s2,a0
  int meta = p - (char*)bd_base;
    80006cb8:	00023997          	auipc	s3,0x23
    80006cbc:	39098993          	addi	s3,s3,912 # 8002a048 <bd_base>
    80006cc0:	0009b483          	ld	s1,0(s3)
    80006cc4:	409504bb          	subw	s1,a0,s1
  printf("bd: %d meta bytes for managing %d bytes of memory\n", meta, BLK_SIZE(MAXSIZE));
    80006cc8:	00023797          	auipc	a5,0x23
    80006ccc:	3907a783          	lw	a5,912(a5) # 8002a058 <nsizes>
    80006cd0:	37fd                	addiw	a5,a5,-1
    80006cd2:	4641                	li	a2,16
    80006cd4:	00f61633          	sll	a2,a2,a5
    80006cd8:	85a6                	mv	a1,s1
    80006cda:	00002517          	auipc	a0,0x2
    80006cde:	c5650513          	addi	a0,a0,-938 # 80008930 <userret+0x8a0>
    80006ce2:	ffffa097          	auipc	ra,0xffffa
    80006ce6:	8b6080e7          	jalr	-1866(ra) # 80000598 <printf>
  bd_mark(bd_base, p);
    80006cea:	85ca                	mv	a1,s2
    80006cec:	0009b503          	ld	a0,0(s3)
    80006cf0:	00000097          	auipc	ra,0x0
    80006cf4:	d74080e7          	jalr	-652(ra) # 80006a64 <bd_mark>
  return meta;
}
    80006cf8:	8526                	mv	a0,s1
    80006cfa:	70a2                	ld	ra,40(sp)
    80006cfc:	7402                	ld	s0,32(sp)
    80006cfe:	64e2                	ld	s1,24(sp)
    80006d00:	6942                	ld	s2,16(sp)
    80006d02:	69a2                	ld	s3,8(sp)
    80006d04:	6145                	addi	sp,sp,48
    80006d06:	8082                	ret

0000000080006d08 <bd_mark_unavailable>:

// Mark the range [end, HEAPSIZE) as allocated
int
bd_mark_unavailable(void *end, void *left) {
    80006d08:	1101                	addi	sp,sp,-32
    80006d0a:	ec06                	sd	ra,24(sp)
    80006d0c:	e822                	sd	s0,16(sp)
    80006d0e:	e426                	sd	s1,8(sp)
    80006d10:	1000                	addi	s0,sp,32
  int unavailable = BLK_SIZE(MAXSIZE)-(end-bd_base);
    80006d12:	00023497          	auipc	s1,0x23
    80006d16:	3464a483          	lw	s1,838(s1) # 8002a058 <nsizes>
    80006d1a:	fff4879b          	addiw	a5,s1,-1
    80006d1e:	44c1                	li	s1,16
    80006d20:	00f494b3          	sll	s1,s1,a5
    80006d24:	00023797          	auipc	a5,0x23
    80006d28:	3247b783          	ld	a5,804(a5) # 8002a048 <bd_base>
    80006d2c:	8d1d                	sub	a0,a0,a5
    80006d2e:	40a4853b          	subw	a0,s1,a0
    80006d32:	0005049b          	sext.w	s1,a0
  if(unavailable > 0)
    80006d36:	00905a63          	blez	s1,80006d4a <bd_mark_unavailable+0x42>
    unavailable = ROUNDUP(unavailable, LEAF_SIZE);
    80006d3a:	357d                	addiw	a0,a0,-1
    80006d3c:	41f5549b          	sraiw	s1,a0,0x1f
    80006d40:	01c4d49b          	srliw	s1,s1,0x1c
    80006d44:	9ca9                	addw	s1,s1,a0
    80006d46:	98c1                	andi	s1,s1,-16
    80006d48:	24c1                	addiw	s1,s1,16
  printf("bd: 0x%x bytes unavailable\n", unavailable);
    80006d4a:	85a6                	mv	a1,s1
    80006d4c:	00002517          	auipc	a0,0x2
    80006d50:	c1c50513          	addi	a0,a0,-996 # 80008968 <userret+0x8d8>
    80006d54:	ffffa097          	auipc	ra,0xffffa
    80006d58:	844080e7          	jalr	-1980(ra) # 80000598 <printf>

  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006d5c:	00023717          	auipc	a4,0x23
    80006d60:	2ec73703          	ld	a4,748(a4) # 8002a048 <bd_base>
    80006d64:	00023597          	auipc	a1,0x23
    80006d68:	2f45a583          	lw	a1,756(a1) # 8002a058 <nsizes>
    80006d6c:	fff5879b          	addiw	a5,a1,-1
    80006d70:	45c1                	li	a1,16
    80006d72:	00f595b3          	sll	a1,a1,a5
    80006d76:	40958533          	sub	a0,a1,s1
  bd_mark(bd_end, bd_base+BLK_SIZE(MAXSIZE));
    80006d7a:	95ba                	add	a1,a1,a4
    80006d7c:	953a                	add	a0,a0,a4
    80006d7e:	00000097          	auipc	ra,0x0
    80006d82:	ce6080e7          	jalr	-794(ra) # 80006a64 <bd_mark>
  return unavailable;
}
    80006d86:	8526                	mv	a0,s1
    80006d88:	60e2                	ld	ra,24(sp)
    80006d8a:	6442                	ld	s0,16(sp)
    80006d8c:	64a2                	ld	s1,8(sp)
    80006d8e:	6105                	addi	sp,sp,32
    80006d90:	8082                	ret

0000000080006d92 <bd_init>:

// Initialize the buddy allocator: it manages memory from [base, end).
void
bd_init(void *base, void *end) {
    80006d92:	715d                	addi	sp,sp,-80
    80006d94:	e486                	sd	ra,72(sp)
    80006d96:	e0a2                	sd	s0,64(sp)
    80006d98:	fc26                	sd	s1,56(sp)
    80006d9a:	f84a                	sd	s2,48(sp)
    80006d9c:	f44e                	sd	s3,40(sp)
    80006d9e:	f052                	sd	s4,32(sp)
    80006da0:	ec56                	sd	s5,24(sp)
    80006da2:	e85a                	sd	s6,16(sp)
    80006da4:	e45e                	sd	s7,8(sp)
    80006da6:	e062                	sd	s8,0(sp)
    80006da8:	0880                	addi	s0,sp,80
    80006daa:	8c2e                	mv	s8,a1
  char *p = (char *) ROUNDUP((uint64)base, LEAF_SIZE);
    80006dac:	fff50493          	addi	s1,a0,-1
    80006db0:	98c1                	andi	s1,s1,-16
    80006db2:	04c1                	addi	s1,s1,16
  int sz;

  initlock(&lock, "buddy");
    80006db4:	00002597          	auipc	a1,0x2
    80006db8:	bd458593          	addi	a1,a1,-1068 # 80008988 <userret+0x8f8>
    80006dbc:	00023517          	auipc	a0,0x23
    80006dc0:	24450513          	addi	a0,a0,580 # 8002a000 <lock>
    80006dc4:	ffffa097          	auipc	ra,0xffffa
    80006dc8:	af6080e7          	jalr	-1290(ra) # 800008ba <initlock>
  bd_base = (void *) p;
    80006dcc:	00023797          	auipc	a5,0x23
    80006dd0:	2697be23          	sd	s1,636(a5) # 8002a048 <bd_base>

  // compute the number of sizes we need to manage [base, end)
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006dd4:	409c0933          	sub	s2,s8,s1
    80006dd8:	43f95513          	srai	a0,s2,0x3f
    80006ddc:	893d                	andi	a0,a0,15
    80006dde:	954a                	add	a0,a0,s2
    80006de0:	8511                	srai	a0,a0,0x4
    80006de2:	00000097          	auipc	ra,0x0
    80006de6:	c60080e7          	jalr	-928(ra) # 80006a42 <log2>
  if((char*)end-p > BLK_SIZE(MAXSIZE)) {
    80006dea:	47c1                	li	a5,16
    80006dec:	00a797b3          	sll	a5,a5,a0
    80006df0:	1b27c663          	blt	a5,s2,80006f9c <bd_init+0x20a>
  nsizes = log2(((char *)end-p)/LEAF_SIZE) + 1;
    80006df4:	2505                	addiw	a0,a0,1
    80006df6:	00023797          	auipc	a5,0x23
    80006dfa:	26a7a123          	sw	a0,610(a5) # 8002a058 <nsizes>
    nsizes++;  // round up to the next power of 2
  }

  printf("bd: memory sz is %d bytes; allocate an size array of length %d\n",
    80006dfe:	00023997          	auipc	s3,0x23
    80006e02:	25a98993          	addi	s3,s3,602 # 8002a058 <nsizes>
    80006e06:	0009a603          	lw	a2,0(s3)
    80006e0a:	85ca                	mv	a1,s2
    80006e0c:	00002517          	auipc	a0,0x2
    80006e10:	b8450513          	addi	a0,a0,-1148 # 80008990 <userret+0x900>
    80006e14:	ffff9097          	auipc	ra,0xffff9
    80006e18:	784080e7          	jalr	1924(ra) # 80000598 <printf>
         (char*) end - p, nsizes);

  // allocate bd_sizes array
  bd_sizes = (Sz_info *) p;
    80006e1c:	00023797          	auipc	a5,0x23
    80006e20:	2297ba23          	sd	s1,564(a5) # 8002a050 <bd_sizes>
  p += sizeof(Sz_info) * nsizes;
    80006e24:	0009a603          	lw	a2,0(s3)
    80006e28:	00561913          	slli	s2,a2,0x5
    80006e2c:	9926                	add	s2,s2,s1
  memset(bd_sizes, 0, sizeof(Sz_info) * nsizes);
    80006e2e:	0056161b          	slliw	a2,a2,0x5
    80006e32:	4581                	li	a1,0
    80006e34:	8526                	mv	a0,s1
    80006e36:	ffffa097          	auipc	ra,0xffffa
    80006e3a:	c5a080e7          	jalr	-934(ra) # 80000a90 <memset>

  // initialize free list and allocate the alloc array for each size k
  for (int k = 0; k < nsizes; k++) {
    80006e3e:	0009a783          	lw	a5,0(s3)
    80006e42:	06f05a63          	blez	a5,80006eb6 <bd_init+0x124>
    80006e46:	4981                	li	s3,0
    lst_init(&bd_sizes[k].free);
    80006e48:	00023a97          	auipc	s5,0x23
    80006e4c:	208a8a93          	addi	s5,s5,520 # 8002a050 <bd_sizes>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    80006e50:	00023a17          	auipc	s4,0x23
    80006e54:	208a0a13          	addi	s4,s4,520 # 8002a058 <nsizes>
    80006e58:	4b05                	li	s6,1
    lst_init(&bd_sizes[k].free);
    80006e5a:	00599b93          	slli	s7,s3,0x5
    80006e5e:	000ab503          	ld	a0,0(s5)
    80006e62:	955e                	add	a0,a0,s7
    80006e64:	00000097          	auipc	ra,0x0
    80006e68:	166080e7          	jalr	358(ra) # 80006fca <lst_init>
    sz = sizeof(char)* ROUNDUP(NBLK(k), 8)/8;
    80006e6c:	000a2483          	lw	s1,0(s4)
    80006e70:	34fd                	addiw	s1,s1,-1
    80006e72:	413484bb          	subw	s1,s1,s3
    80006e76:	009b14bb          	sllw	s1,s6,s1
    80006e7a:	fff4879b          	addiw	a5,s1,-1
    80006e7e:	41f7d49b          	sraiw	s1,a5,0x1f
    80006e82:	01d4d49b          	srliw	s1,s1,0x1d
    80006e86:	9cbd                	addw	s1,s1,a5
    80006e88:	98e1                	andi	s1,s1,-8
    80006e8a:	24a1                	addiw	s1,s1,8
    bd_sizes[k].alloc = p;
    80006e8c:	000ab783          	ld	a5,0(s5)
    80006e90:	9bbe                	add	s7,s7,a5
    80006e92:	012bb823          	sd	s2,16(s7)
    memset(bd_sizes[k].alloc, 0, sz);
    80006e96:	848d                	srai	s1,s1,0x3
    80006e98:	8626                	mv	a2,s1
    80006e9a:	4581                	li	a1,0
    80006e9c:	854a                	mv	a0,s2
    80006e9e:	ffffa097          	auipc	ra,0xffffa
    80006ea2:	bf2080e7          	jalr	-1038(ra) # 80000a90 <memset>
    p += sz;
    80006ea6:	9926                	add	s2,s2,s1
  for (int k = 0; k < nsizes; k++) {
    80006ea8:	0985                	addi	s3,s3,1
    80006eaa:	000a2703          	lw	a4,0(s4)
    80006eae:	0009879b          	sext.w	a5,s3
    80006eb2:	fae7c4e3          	blt	a5,a4,80006e5a <bd_init+0xc8>
  }

  // allocate the split array for each size k, except for k = 0, since
  // we will not split blocks of size k = 0, the smallest size.
  for (int k = 1; k < nsizes; k++) {
    80006eb6:	00023797          	auipc	a5,0x23
    80006eba:	1a27a783          	lw	a5,418(a5) # 8002a058 <nsizes>
    80006ebe:	4705                	li	a4,1
    80006ec0:	06f75163          	bge	a4,a5,80006f22 <bd_init+0x190>
    80006ec4:	02000a13          	li	s4,32
    80006ec8:	4985                	li	s3,1
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006eca:	4b85                	li	s7,1
    bd_sizes[k].split = p;
    80006ecc:	00023b17          	auipc	s6,0x23
    80006ed0:	184b0b13          	addi	s6,s6,388 # 8002a050 <bd_sizes>
  for (int k = 1; k < nsizes; k++) {
    80006ed4:	00023a97          	auipc	s5,0x23
    80006ed8:	184a8a93          	addi	s5,s5,388 # 8002a058 <nsizes>
    sz = sizeof(char)* (ROUNDUP(NBLK(k), 8))/8;
    80006edc:	37fd                	addiw	a5,a5,-1
    80006ede:	413787bb          	subw	a5,a5,s3
    80006ee2:	00fb94bb          	sllw	s1,s7,a5
    80006ee6:	fff4879b          	addiw	a5,s1,-1
    80006eea:	41f7d49b          	sraiw	s1,a5,0x1f
    80006eee:	01d4d49b          	srliw	s1,s1,0x1d
    80006ef2:	9cbd                	addw	s1,s1,a5
    80006ef4:	98e1                	andi	s1,s1,-8
    80006ef6:	24a1                	addiw	s1,s1,8
    bd_sizes[k].split = p;
    80006ef8:	000b3783          	ld	a5,0(s6)
    80006efc:	97d2                	add	a5,a5,s4
    80006efe:	0127bc23          	sd	s2,24(a5)
    memset(bd_sizes[k].split, 0, sz);
    80006f02:	848d                	srai	s1,s1,0x3
    80006f04:	8626                	mv	a2,s1
    80006f06:	4581                	li	a1,0
    80006f08:	854a                	mv	a0,s2
    80006f0a:	ffffa097          	auipc	ra,0xffffa
    80006f0e:	b86080e7          	jalr	-1146(ra) # 80000a90 <memset>
    p += sz;
    80006f12:	9926                	add	s2,s2,s1
  for (int k = 1; k < nsizes; k++) {
    80006f14:	2985                	addiw	s3,s3,1
    80006f16:	000aa783          	lw	a5,0(s5)
    80006f1a:	020a0a13          	addi	s4,s4,32
    80006f1e:	faf9cfe3          	blt	s3,a5,80006edc <bd_init+0x14a>
  }
  p = (char *) ROUNDUP((uint64) p, LEAF_SIZE);
    80006f22:	197d                	addi	s2,s2,-1
    80006f24:	ff097913          	andi	s2,s2,-16
    80006f28:	0941                	addi	s2,s2,16

  // done allocating; mark the memory range [base, p) as allocated, so
  // that buddy will not hand out that memory.
  int meta = bd_mark_data_structures(p);
    80006f2a:	854a                	mv	a0,s2
    80006f2c:	00000097          	auipc	ra,0x0
    80006f30:	d7c080e7          	jalr	-644(ra) # 80006ca8 <bd_mark_data_structures>
    80006f34:	8a2a                	mv	s4,a0
  
  // mark the unavailable memory range [end, HEAP_SIZE) as allocated,
  // so that buddy will not hand out that memory.
  int unavailable = bd_mark_unavailable(end, p);
    80006f36:	85ca                	mv	a1,s2
    80006f38:	8562                	mv	a0,s8
    80006f3a:	00000097          	auipc	ra,0x0
    80006f3e:	dce080e7          	jalr	-562(ra) # 80006d08 <bd_mark_unavailable>
    80006f42:	89aa                	mv	s3,a0
  void *bd_end = bd_base+BLK_SIZE(MAXSIZE)-unavailable;
    80006f44:	00023a97          	auipc	s5,0x23
    80006f48:	114a8a93          	addi	s5,s5,276 # 8002a058 <nsizes>
    80006f4c:	000aa783          	lw	a5,0(s5)
    80006f50:	37fd                	addiw	a5,a5,-1
    80006f52:	44c1                	li	s1,16
    80006f54:	00f497b3          	sll	a5,s1,a5
    80006f58:	8f89                	sub	a5,a5,a0
  
  // initialize free lists for each size k
  int free = bd_initfree(p, bd_end);
    80006f5a:	00023597          	auipc	a1,0x23
    80006f5e:	0ee5b583          	ld	a1,238(a1) # 8002a048 <bd_base>
    80006f62:	95be                	add	a1,a1,a5
    80006f64:	854a                	mv	a0,s2
    80006f66:	00000097          	auipc	ra,0x0
    80006f6a:	c86080e7          	jalr	-890(ra) # 80006bec <bd_initfree>

  // check if the amount that is free is what we expect
  if(free != BLK_SIZE(MAXSIZE)-meta-unavailable) {
    80006f6e:	000aa603          	lw	a2,0(s5)
    80006f72:	367d                	addiw	a2,a2,-1
    80006f74:	00c49633          	sll	a2,s1,a2
    80006f78:	41460633          	sub	a2,a2,s4
    80006f7c:	41360633          	sub	a2,a2,s3
    80006f80:	02c51463          	bne	a0,a2,80006fa8 <bd_init+0x216>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    panic("bd_init: free mem");
  }
}
    80006f84:	60a6                	ld	ra,72(sp)
    80006f86:	6406                	ld	s0,64(sp)
    80006f88:	74e2                	ld	s1,56(sp)
    80006f8a:	7942                	ld	s2,48(sp)
    80006f8c:	79a2                	ld	s3,40(sp)
    80006f8e:	7a02                	ld	s4,32(sp)
    80006f90:	6ae2                	ld	s5,24(sp)
    80006f92:	6b42                	ld	s6,16(sp)
    80006f94:	6ba2                	ld	s7,8(sp)
    80006f96:	6c02                	ld	s8,0(sp)
    80006f98:	6161                	addi	sp,sp,80
    80006f9a:	8082                	ret
    nsizes++;  // round up to the next power of 2
    80006f9c:	2509                	addiw	a0,a0,2
    80006f9e:	00023797          	auipc	a5,0x23
    80006fa2:	0aa7ad23          	sw	a0,186(a5) # 8002a058 <nsizes>
    80006fa6:	bda1                	j	80006dfe <bd_init+0x6c>
    printf("free %d %d\n", free, BLK_SIZE(MAXSIZE)-meta-unavailable);
    80006fa8:	85aa                	mv	a1,a0
    80006faa:	00002517          	auipc	a0,0x2
    80006fae:	a2650513          	addi	a0,a0,-1498 # 800089d0 <userret+0x940>
    80006fb2:	ffff9097          	auipc	ra,0xffff9
    80006fb6:	5e6080e7          	jalr	1510(ra) # 80000598 <printf>
    panic("bd_init: free mem");
    80006fba:	00002517          	auipc	a0,0x2
    80006fbe:	a2650513          	addi	a0,a0,-1498 # 800089e0 <userret+0x950>
    80006fc2:	ffff9097          	auipc	ra,0xffff9
    80006fc6:	58c080e7          	jalr	1420(ra) # 8000054e <panic>

0000000080006fca <lst_init>:
// fast. circular simplifies code, because don't have to check for
// empty list in insert and remove.

void
lst_init(struct list *lst)
{
    80006fca:	1141                	addi	sp,sp,-16
    80006fcc:	e422                	sd	s0,8(sp)
    80006fce:	0800                	addi	s0,sp,16
  lst->next = lst;
    80006fd0:	e108                	sd	a0,0(a0)
  lst->prev = lst;
    80006fd2:	e508                	sd	a0,8(a0)
}
    80006fd4:	6422                	ld	s0,8(sp)
    80006fd6:	0141                	addi	sp,sp,16
    80006fd8:	8082                	ret

0000000080006fda <lst_empty>:

int
lst_empty(struct list *lst) {
    80006fda:	1141                	addi	sp,sp,-16
    80006fdc:	e422                	sd	s0,8(sp)
    80006fde:	0800                	addi	s0,sp,16
  return lst->next == lst;
    80006fe0:	611c                	ld	a5,0(a0)
    80006fe2:	40a78533          	sub	a0,a5,a0
}
    80006fe6:	00153513          	seqz	a0,a0
    80006fea:	6422                	ld	s0,8(sp)
    80006fec:	0141                	addi	sp,sp,16
    80006fee:	8082                	ret

0000000080006ff0 <lst_remove>:

void
lst_remove(struct list *e) {
    80006ff0:	1141                	addi	sp,sp,-16
    80006ff2:	e422                	sd	s0,8(sp)
    80006ff4:	0800                	addi	s0,sp,16
  e->prev->next = e->next;
    80006ff6:	6518                	ld	a4,8(a0)
    80006ff8:	611c                	ld	a5,0(a0)
    80006ffa:	e31c                	sd	a5,0(a4)
  e->next->prev = e->prev;
    80006ffc:	6518                	ld	a4,8(a0)
    80006ffe:	e798                	sd	a4,8(a5)
}
    80007000:	6422                	ld	s0,8(sp)
    80007002:	0141                	addi	sp,sp,16
    80007004:	8082                	ret

0000000080007006 <lst_pop>:

void*
lst_pop(struct list *lst) {
    80007006:	1101                	addi	sp,sp,-32
    80007008:	ec06                	sd	ra,24(sp)
    8000700a:	e822                	sd	s0,16(sp)
    8000700c:	e426                	sd	s1,8(sp)
    8000700e:	1000                	addi	s0,sp,32
  if(lst->next == lst)
    80007010:	6104                	ld	s1,0(a0)
    80007012:	00a48d63          	beq	s1,a0,8000702c <lst_pop+0x26>
    panic("lst_pop");
  struct list *p = lst->next;
  lst_remove(p);
    80007016:	8526                	mv	a0,s1
    80007018:	00000097          	auipc	ra,0x0
    8000701c:	fd8080e7          	jalr	-40(ra) # 80006ff0 <lst_remove>
  return (void *)p;
}
    80007020:	8526                	mv	a0,s1
    80007022:	60e2                	ld	ra,24(sp)
    80007024:	6442                	ld	s0,16(sp)
    80007026:	64a2                	ld	s1,8(sp)
    80007028:	6105                	addi	sp,sp,32
    8000702a:	8082                	ret
    panic("lst_pop");
    8000702c:	00002517          	auipc	a0,0x2
    80007030:	9cc50513          	addi	a0,a0,-1588 # 800089f8 <userret+0x968>
    80007034:	ffff9097          	auipc	ra,0xffff9
    80007038:	51a080e7          	jalr	1306(ra) # 8000054e <panic>

000000008000703c <lst_push>:

void
lst_push(struct list *lst, void *p)
{
    8000703c:	1141                	addi	sp,sp,-16
    8000703e:	e422                	sd	s0,8(sp)
    80007040:	0800                	addi	s0,sp,16
  struct list *e = (struct list *) p;
  e->next = lst->next;
    80007042:	611c                	ld	a5,0(a0)
    80007044:	e19c                	sd	a5,0(a1)
  e->prev = lst;
    80007046:	e588                	sd	a0,8(a1)
  lst->next->prev = p;
    80007048:	611c                	ld	a5,0(a0)
    8000704a:	e78c                	sd	a1,8(a5)
  lst->next = e;
    8000704c:	e10c                	sd	a1,0(a0)
}
    8000704e:	6422                	ld	s0,8(sp)
    80007050:	0141                	addi	sp,sp,16
    80007052:	8082                	ret

0000000080007054 <lst_print>:

void
lst_print(struct list *lst)
{
    80007054:	7179                	addi	sp,sp,-48
    80007056:	f406                	sd	ra,40(sp)
    80007058:	f022                	sd	s0,32(sp)
    8000705a:	ec26                	sd	s1,24(sp)
    8000705c:	e84a                	sd	s2,16(sp)
    8000705e:	e44e                	sd	s3,8(sp)
    80007060:	1800                	addi	s0,sp,48
  for (struct list *p = lst->next; p != lst; p = p->next) {
    80007062:	6104                	ld	s1,0(a0)
    80007064:	02950063          	beq	a0,s1,80007084 <lst_print+0x30>
    80007068:	892a                	mv	s2,a0
    printf(" %p", p);
    8000706a:	00002997          	auipc	s3,0x2
    8000706e:	99698993          	addi	s3,s3,-1642 # 80008a00 <userret+0x970>
    80007072:	85a6                	mv	a1,s1
    80007074:	854e                	mv	a0,s3
    80007076:	ffff9097          	auipc	ra,0xffff9
    8000707a:	522080e7          	jalr	1314(ra) # 80000598 <printf>
  for (struct list *p = lst->next; p != lst; p = p->next) {
    8000707e:	6084                	ld	s1,0(s1)
    80007080:	fe9919e3          	bne	s2,s1,80007072 <lst_print+0x1e>
  }
  printf("\n");
    80007084:	00001517          	auipc	a0,0x1
    80007088:	11c50513          	addi	a0,a0,284 # 800081a0 <userret+0x110>
    8000708c:	ffff9097          	auipc	ra,0xffff9
    80007090:	50c080e7          	jalr	1292(ra) # 80000598 <printf>
}
    80007094:	70a2                	ld	ra,40(sp)
    80007096:	7402                	ld	s0,32(sp)
    80007098:	64e2                	ld	s1,24(sp)
    8000709a:	6942                	ld	s2,16(sp)
    8000709c:	69a2                	ld	s3,8(sp)
    8000709e:	6145                	addi	sp,sp,48
    800070a0:	8082                	ret
	...

0000000080008000 <trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
