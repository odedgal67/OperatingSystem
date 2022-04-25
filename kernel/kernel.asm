
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	f3c78793          	addi	a5,a5,-196 # 80005fa0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdf7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	566080e7          	jalr	1382(ra) # 80002692 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	0000a517          	auipc	a0,0xa
    80000190:	f0450513          	addi	a0,a0,-252 # 8000a090 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ef448493          	addi	s1,s1,-268 # 8000a090 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f8290913          	addi	s2,s2,-126 # 8000a128 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	884080e7          	jalr	-1916(ra) # 80001a48 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	08e080e7          	jalr	142(ra) # 80002262 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	42c080e7          	jalr	1068(ra) # 8000263c <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	0000a517          	auipc	a0,0xa
    80000228:	e6c50513          	addi	a0,a0,-404 # 8000a090 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e5650513          	addi	a0,a0,-426 # 8000a090 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	0000a717          	auipc	a4,0xa
    80000276:	eaf72b23          	sw	a5,-330(a4) # 8000a128 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	0000a517          	auipc	a0,0xa
    800002d0:	dc450513          	addi	a0,a0,-572 # 8000a090 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3f6080e7          	jalr	1014(ra) # 800026e8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d9650513          	addi	a0,a0,-618 # 8000a090 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	0000a717          	auipc	a4,0xa
    80000322:	d7270713          	addi	a4,a4,-654 # 8000a090 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	0000a797          	auipc	a5,0xa
    8000034c:	d4878793          	addi	a5,a5,-696 # 8000a090 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	0000a797          	auipc	a5,0xa
    8000037a:	db27a783          	lw	a5,-590(a5) # 8000a128 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	d0670713          	addi	a4,a4,-762 # 8000a090 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	cf648493          	addi	s1,s1,-778 # 8000a090 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	0000a717          	auipc	a4,0xa
    800003da:	cba70713          	addi	a4,a4,-838 # 8000a090 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d4f72223          	sw	a5,-700(a4) # 8000a130 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	0000a797          	auipc	a5,0xa
    80000416:	c7e78793          	addi	a5,a5,-898 # 8000a090 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	0000a797          	auipc	a5,0xa
    8000043a:	cec7ab23          	sw	a2,-778(a5) # 8000a12c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cea50513          	addi	a0,a0,-790 # 8000a128 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fa8080e7          	jalr	-88(ra) # 800023ee <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	0000a517          	auipc	a0,0xa
    80000464:	c3050513          	addi	a0,a0,-976 # 8000a090 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	03078793          	addi	a5,a5,48 # 8001a4a8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	0000a797          	auipc	a5,0xa
    8000054e:	c007a323          	sw	zero,-1018(a5) # 8000a150 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	0000ad97          	auipc	s11,0xa
    800005be:	b96dad83          	lw	s11,-1130(s11) # 8000a150 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	0000a517          	auipc	a0,0xa
    800005fc:	b4050513          	addi	a0,a0,-1216 # 8000a138 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	0000a517          	auipc	a0,0xa
    80000760:	9dc50513          	addi	a0,a0,-1572 # 8000a138 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	0000a497          	auipc	s1,0xa
    8000077c:	9c048493          	addi	s1,s1,-1600 # 8000a138 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	0000a517          	auipc	a0,0xa
    800007dc:	98050513          	addi	a0,a0,-1664 # 8000a158 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	0000aa17          	auipc	s4,0xa
    8000086e:	8eea0a13          	addi	s4,s4,-1810 # 8000a158 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b4e080e7          	jalr	-1202(ra) # 800023ee <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	0000a517          	auipc	a0,0xa
    800008e0:	87c50513          	addi	a0,a0,-1924 # 8000a158 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	0000aa17          	auipc	s4,0xa
    80000914:	848a0a13          	addi	s4,s4,-1976 # 8000a158 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	936080e7          	jalr	-1738(ra) # 80002262 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	0000a497          	auipc	s1,0xa
    80000946:	81648493          	addi	s1,s1,-2026 # 8000a158 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00009497          	auipc	s1,0x9
    800009ce:	78e48493          	addi	s1,s1,1934 # 8000a158 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	0001e797          	auipc	a5,0x1e
    80000a10:	5f478793          	addi	a5,a5,1524 # 8001f000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00009917          	auipc	s2,0x9
    80000a30:	76490913          	addi	s2,s2,1892 # 8000a190 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00009517          	auipc	a0,0x9
    80000acc:	6c850513          	addi	a0,a0,1736 # 8000a190 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	0001e517          	auipc	a0,0x1e
    80000ae0:	52450513          	addi	a0,a0,1316 # 8001f000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00009497          	auipc	s1,0x9
    80000b02:	69248493          	addi	s1,s1,1682 # 8000a190 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00009517          	auipc	a0,0x9
    80000b1a:	67a50513          	addi	a0,a0,1658 # 8000a190 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00009517          	auipc	a0,0x9
    80000b46:	64e50513          	addi	a0,a0,1614 # 8000a190 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	eae080e7          	jalr	-338(ra) # 80001a2c <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	e7c080e7          	jalr	-388(ra) # 80001a2c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e70080e7          	jalr	-400(ra) # 80001a2c <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	e58080e7          	jalr	-424(ra) # 80001a2c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	e18080e7          	jalr	-488(ra) # 80001a2c <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	dec080e7          	jalr	-532(ra) # 80001a2c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b86080e7          	jalr	-1146(ra) # 80001a1c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	b6a080e7          	jalr	-1174(ra) # 80001a1c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	b20080e7          	jalr	-1248(ra) # 800029f4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	104080e7          	jalr	260(ra) # 80005fe0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	142080e7          	jalr	322(ra) # 80002026 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	a18080e7          	jalr	-1512(ra) # 8000195c <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	a80080e7          	jalr	-1408(ra) # 800029cc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	aa0080e7          	jalr	-1376(ra) # 800029f4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	06e080e7          	jalr	110(ra) # 80005fca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	07c080e7          	jalr	124(ra) # 80005fe0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	256080e7          	jalr	598(ra) # 800031c2 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	8e6080e7          	jalr	-1818(ra) # 8000385a <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	890080e7          	jalr	-1904(ra) # 8000480c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	17e080e7          	jalr	382(ra) # 80006102 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d9c080e7          	jalr	-612(ra) # 80001d28 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	686080e7          	jalr	1670(ra) # 800018c6 <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <updateAllProcsStats>:
// must be acquired before any p->lock.
struct spinlock wait_lock;

void
updateAllProcsStats(void)
{
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	0080                	addi	s0,sp,64
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    80001850:	00009497          	auipc	s1,0x9
    80001854:	a1048493          	addi	s1,s1,-1520 # 8000a260 <proc>
  {
    acquire(&p->lock);
    if(p->state==RUNNING)
    80001858:	4991                	li	s3,4
    {
      p->total_running_time++;
    }
    else if(p->state == RUNNABLE)
    8000185a:	4a0d                	li	s4,3
    {
      p->total_runnable_time++;
    }
    else if(p->state == SLEEPING)
    8000185c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++)
    8000185e:	0000f917          	auipc	s2,0xf
    80001862:	a0290913          	addi	s2,s2,-1534 # 80010260 <tickslock>
    80001866:	a839                	j	80001884 <updateAllProcsStats+0x46>
      p->total_running_time++;
    80001868:	1744a783          	lw	a5,372(s1)
    8000186c:	2785                	addiw	a5,a5,1
    8000186e:	16f4aa23          	sw	a5,372(s1)
    {
      p->total_sleeping_time++;
    }
    release(&p->lock);
    80001872:	8526                	mv	a0,s1
    80001874:	fffff097          	auipc	ra,0xfffff
    80001878:	424080e7          	jalr	1060(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++)
    8000187c:	18048493          	addi	s1,s1,384
    80001880:	03248a63          	beq	s1,s2,800018b4 <updateAllProcsStats+0x76>
    acquire(&p->lock);
    80001884:	8526                	mv	a0,s1
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	35e080e7          	jalr	862(ra) # 80000be4 <acquire>
    if(p->state==RUNNING)
    8000188e:	4c9c                	lw	a5,24(s1)
    80001890:	fd378ce3          	beq	a5,s3,80001868 <updateAllProcsStats+0x2a>
    else if(p->state == RUNNABLE)
    80001894:	01478a63          	beq	a5,s4,800018a8 <updateAllProcsStats+0x6a>
    else if(p->state == SLEEPING)
    80001898:	fd579de3          	bne	a5,s5,80001872 <updateAllProcsStats+0x34>
      p->total_sleeping_time++;
    8000189c:	17c4a783          	lw	a5,380(s1)
    800018a0:	2785                	addiw	a5,a5,1
    800018a2:	16f4ae23          	sw	a5,380(s1)
    800018a6:	b7f1                	j	80001872 <updateAllProcsStats+0x34>
      p->total_runnable_time++;
    800018a8:	1784a783          	lw	a5,376(s1)
    800018ac:	2785                	addiw	a5,a5,1
    800018ae:	16f4ac23          	sw	a5,376(s1)
    800018b2:	b7c1                	j	80001872 <updateAllProcsStats+0x34>
  }
}
    800018b4:	70e2                	ld	ra,56(sp)
    800018b6:	7442                	ld	s0,48(sp)
    800018b8:	74a2                	ld	s1,40(sp)
    800018ba:	7902                	ld	s2,32(sp)
    800018bc:	69e2                	ld	s3,24(sp)
    800018be:	6a42                	ld	s4,16(sp)
    800018c0:	6aa2                	ld	s5,8(sp)
    800018c2:	6121                	addi	sp,sp,64
    800018c4:	8082                	ret

00000000800018c6 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018c6:	7139                	addi	sp,sp,-64
    800018c8:	fc06                	sd	ra,56(sp)
    800018ca:	f822                	sd	s0,48(sp)
    800018cc:	f426                	sd	s1,40(sp)
    800018ce:	f04a                	sd	s2,32(sp)
    800018d0:	ec4e                	sd	s3,24(sp)
    800018d2:	e852                	sd	s4,16(sp)
    800018d4:	e456                	sd	s5,8(sp)
    800018d6:	e05a                	sd	s6,0(sp)
    800018d8:	0080                	addi	s0,sp,64
    800018da:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018dc:	00009497          	auipc	s1,0x9
    800018e0:	98448493          	addi	s1,s1,-1660 # 8000a260 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018e4:	8b26                	mv	s6,s1
    800018e6:	00006a97          	auipc	s5,0x6
    800018ea:	71aa8a93          	addi	s5,s5,1818 # 80008000 <etext>
    800018ee:	04000937          	lui	s2,0x4000
    800018f2:	197d                	addi	s2,s2,-1
    800018f4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018f6:	0000fa17          	auipc	s4,0xf
    800018fa:	96aa0a13          	addi	s4,s4,-1686 # 80010260 <tickslock>
    char *pa = kalloc();
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	1f6080e7          	jalr	502(ra) # 80000af4 <kalloc>
    80001906:	862a                	mv	a2,a0
    if(pa == 0)
    80001908:	c131                	beqz	a0,8000194c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000190a:	416485b3          	sub	a1,s1,s6
    8000190e:	859d                	srai	a1,a1,0x7
    80001910:	000ab783          	ld	a5,0(s5)
    80001914:	02f585b3          	mul	a1,a1,a5
    80001918:	2585                	addiw	a1,a1,1
    8000191a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000191e:	4719                	li	a4,6
    80001920:	6685                	lui	a3,0x1
    80001922:	40b905b3          	sub	a1,s2,a1
    80001926:	854e                	mv	a0,s3
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	828080e7          	jalr	-2008(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	18048493          	addi	s1,s1,384
    80001934:	fd4495e3          	bne	s1,s4,800018fe <proc_mapstacks+0x38>
  }
}
    80001938:	70e2                	ld	ra,56(sp)
    8000193a:	7442                	ld	s0,48(sp)
    8000193c:	74a2                	ld	s1,40(sp)
    8000193e:	7902                	ld	s2,32(sp)
    80001940:	69e2                	ld	s3,24(sp)
    80001942:	6a42                	ld	s4,16(sp)
    80001944:	6aa2                	ld	s5,8(sp)
    80001946:	6b02                	ld	s6,0(sp)
    80001948:	6121                	addi	sp,sp,64
    8000194a:	8082                	ret
      panic("kalloc");
    8000194c:	00007517          	auipc	a0,0x7
    80001950:	88c50513          	addi	a0,a0,-1908 # 800081d8 <digits+0x198>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	bea080e7          	jalr	-1046(ra) # 8000053e <panic>

000000008000195c <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    8000195c:	7139                	addi	sp,sp,-64
    8000195e:	fc06                	sd	ra,56(sp)
    80001960:	f822                	sd	s0,48(sp)
    80001962:	f426                	sd	s1,40(sp)
    80001964:	f04a                	sd	s2,32(sp)
    80001966:	ec4e                	sd	s3,24(sp)
    80001968:	e852                	sd	s4,16(sp)
    8000196a:	e456                	sd	s5,8(sp)
    8000196c:	e05a                	sd	s6,0(sp)
    8000196e:	0080                	addi	s0,sp,64
  struct proc *p;
  start_time = ticks;
    80001970:	00007797          	auipc	a5,0x7
    80001974:	6e07a783          	lw	a5,1760(a5) # 80009050 <ticks>
    80001978:	00007717          	auipc	a4,0x7
    8000197c:	6cf72023          	sw	a5,1728(a4) # 80009038 <start_time>
  initlock(&pid_lock, "nextpid");
    80001980:	00007597          	auipc	a1,0x7
    80001984:	86058593          	addi	a1,a1,-1952 # 800081e0 <digits+0x1a0>
    80001988:	00009517          	auipc	a0,0x9
    8000198c:	82850513          	addi	a0,a0,-2008 # 8000a1b0 <pid_lock>
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	1c4080e7          	jalr	452(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001998:	00007597          	auipc	a1,0x7
    8000199c:	85058593          	addi	a1,a1,-1968 # 800081e8 <digits+0x1a8>
    800019a0:	00009517          	auipc	a0,0x9
    800019a4:	82850513          	addi	a0,a0,-2008 # 8000a1c8 <wait_lock>
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	1ac080e7          	jalr	428(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b0:	00009497          	auipc	s1,0x9
    800019b4:	8b048493          	addi	s1,s1,-1872 # 8000a260 <proc>
      initlock(&p->lock, "proc");
    800019b8:	00007b17          	auipc	s6,0x7
    800019bc:	840b0b13          	addi	s6,s6,-1984 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    800019c0:	8aa6                	mv	s5,s1
    800019c2:	00006a17          	auipc	s4,0x6
    800019c6:	63ea0a13          	addi	s4,s4,1598 # 80008000 <etext>
    800019ca:	04000937          	lui	s2,0x4000
    800019ce:	197d                	addi	s2,s2,-1
    800019d0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d2:	0000f997          	auipc	s3,0xf
    800019d6:	88e98993          	addi	s3,s3,-1906 # 80010260 <tickslock>
      initlock(&p->lock, "proc");
    800019da:	85da                	mv	a1,s6
    800019dc:	8526                	mv	a0,s1
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	176080e7          	jalr	374(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019e6:	415487b3          	sub	a5,s1,s5
    800019ea:	879d                	srai	a5,a5,0x7
    800019ec:	000a3703          	ld	a4,0(s4)
    800019f0:	02e787b3          	mul	a5,a5,a4
    800019f4:	2785                	addiw	a5,a5,1
    800019f6:	00d7979b          	slliw	a5,a5,0xd
    800019fa:	40f907b3          	sub	a5,s2,a5
    800019fe:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a00:	18048493          	addi	s1,s1,384
    80001a04:	fd349be3          	bne	s1,s3,800019da <procinit+0x7e>
  }
}
    80001a08:	70e2                	ld	ra,56(sp)
    80001a0a:	7442                	ld	s0,48(sp)
    80001a0c:	74a2                	ld	s1,40(sp)
    80001a0e:	7902                	ld	s2,32(sp)
    80001a10:	69e2                	ld	s3,24(sp)
    80001a12:	6a42                	ld	s4,16(sp)
    80001a14:	6aa2                	ld	s5,8(sp)
    80001a16:	6b02                	ld	s6,0(sp)
    80001a18:	6121                	addi	sp,sp,64
    80001a1a:	8082                	ret

0000000080001a1c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a1c:	1141                	addi	sp,sp,-16
    80001a1e:	e422                	sd	s0,8(sp)
    80001a20:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a22:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a24:	2501                	sext.w	a0,a0
    80001a26:	6422                	ld	s0,8(sp)
    80001a28:	0141                	addi	sp,sp,16
    80001a2a:	8082                	ret

0000000080001a2c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a2c:	1141                	addi	sp,sp,-16
    80001a2e:	e422                	sd	s0,8(sp)
    80001a30:	0800                	addi	s0,sp,16
    80001a32:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a34:	2781                	sext.w	a5,a5
    80001a36:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a38:	00008517          	auipc	a0,0x8
    80001a3c:	7a850513          	addi	a0,a0,1960 # 8000a1e0 <cpus>
    80001a40:	953e                	add	a0,a0,a5
    80001a42:	6422                	ld	s0,8(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret

0000000080001a48 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a48:	1101                	addi	sp,sp,-32
    80001a4a:	ec06                	sd	ra,24(sp)
    80001a4c:	e822                	sd	s0,16(sp)
    80001a4e:	e426                	sd	s1,8(sp)
    80001a50:	1000                	addi	s0,sp,32
  push_off();
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	146080e7          	jalr	326(ra) # 80000b98 <push_off>
    80001a5a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a5c:	2781                	sext.w	a5,a5
    80001a5e:	079e                	slli	a5,a5,0x7
    80001a60:	00008717          	auipc	a4,0x8
    80001a64:	75070713          	addi	a4,a4,1872 # 8000a1b0 <pid_lock>
    80001a68:	97ba                	add	a5,a5,a4
    80001a6a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	1cc080e7          	jalr	460(ra) # 80000c38 <pop_off>
  return p;
}
    80001a74:	8526                	mv	a0,s1
    80001a76:	60e2                	ld	ra,24(sp)
    80001a78:	6442                	ld	s0,16(sp)
    80001a7a:	64a2                	ld	s1,8(sp)
    80001a7c:	6105                	addi	sp,sp,32
    80001a7e:	8082                	ret

0000000080001a80 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a80:	1141                	addi	sp,sp,-16
    80001a82:	e406                	sd	ra,8(sp)
    80001a84:	e022                	sd	s0,0(sp)
    80001a86:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a88:	00000097          	auipc	ra,0x0
    80001a8c:	fc0080e7          	jalr	-64(ra) # 80001a48 <myproc>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	208080e7          	jalr	520(ra) # 80000c98 <release>

  if (first) {
    80001a98:	00007797          	auipc	a5,0x7
    80001a9c:	e187a783          	lw	a5,-488(a5) # 800088b0 <first.1713>
    80001aa0:	eb89                	bnez	a5,80001ab2 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aa2:	00001097          	auipc	ra,0x1
    80001aa6:	f6a080e7          	jalr	-150(ra) # 80002a0c <usertrapret>
}
    80001aaa:	60a2                	ld	ra,8(sp)
    80001aac:	6402                	ld	s0,0(sp)
    80001aae:	0141                	addi	sp,sp,16
    80001ab0:	8082                	ret
    first = 0;
    80001ab2:	00007797          	auipc	a5,0x7
    80001ab6:	de07af23          	sw	zero,-514(a5) # 800088b0 <first.1713>
    fsinit(ROOTDEV);
    80001aba:	4505                	li	a0,1
    80001abc:	00002097          	auipc	ra,0x2
    80001ac0:	d1e080e7          	jalr	-738(ra) # 800037da <fsinit>
    80001ac4:	bff9                	j	80001aa2 <forkret+0x22>

0000000080001ac6 <allocpid>:
allocpid() {
    80001ac6:	1101                	addi	sp,sp,-32
    80001ac8:	ec06                	sd	ra,24(sp)
    80001aca:	e822                	sd	s0,16(sp)
    80001acc:	e426                	sd	s1,8(sp)
    80001ace:	e04a                	sd	s2,0(sp)
    80001ad0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ad2:	00008917          	auipc	s2,0x8
    80001ad6:	6de90913          	addi	s2,s2,1758 # 8000a1b0 <pid_lock>
    80001ada:	854a                	mv	a0,s2
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	108080e7          	jalr	264(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001ae4:	00007797          	auipc	a5,0x7
    80001ae8:	dd078793          	addi	a5,a5,-560 # 800088b4 <nextpid>
    80001aec:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aee:	0014871b          	addiw	a4,s1,1
    80001af2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001af4:	854a                	mv	a0,s2
    80001af6:	fffff097          	auipc	ra,0xfffff
    80001afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>
}
    80001afe:	8526                	mv	a0,s1
    80001b00:	60e2                	ld	ra,24(sp)
    80001b02:	6442                	ld	s0,16(sp)
    80001b04:	64a2                	ld	s1,8(sp)
    80001b06:	6902                	ld	s2,0(sp)
    80001b08:	6105                	addi	sp,sp,32
    80001b0a:	8082                	ret

0000000080001b0c <proc_pagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	820080e7          	jalr	-2016(ra) # 8000133a <uvmcreate>
    80001b22:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b24:	c121                	beqz	a0,80001b64 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b26:	4729                	li	a4,10
    80001b28:	00005697          	auipc	a3,0x5
    80001b2c:	4d868693          	addi	a3,a3,1240 # 80007000 <_trampoline>
    80001b30:	6605                	lui	a2,0x1
    80001b32:	040005b7          	lui	a1,0x4000
    80001b36:	15fd                	addi	a1,a1,-1
    80001b38:	05b2                	slli	a1,a1,0xc
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	576080e7          	jalr	1398(ra) # 800010b0 <mappages>
    80001b42:	02054863          	bltz	a0,80001b72 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b46:	4719                	li	a4,6
    80001b48:	05893683          	ld	a3,88(s2)
    80001b4c:	6605                	lui	a2,0x1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	558080e7          	jalr	1368(ra) # 800010b0 <mappages>
    80001b60:	02054163          	bltz	a0,80001b82 <proc_pagetable+0x76>
}
    80001b64:	8526                	mv	a0,s1
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret
    uvmfree(pagetable, 0);
    80001b72:	4581                	li	a1,0
    80001b74:	8526                	mv	a0,s1
    80001b76:	00000097          	auipc	ra,0x0
    80001b7a:	9c0080e7          	jalr	-1600(ra) # 80001536 <uvmfree>
    return 0;
    80001b7e:	4481                	li	s1,0
    80001b80:	b7d5                	j	80001b64 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b82:	4681                	li	a3,0
    80001b84:	4605                	li	a2,1
    80001b86:	040005b7          	lui	a1,0x4000
    80001b8a:	15fd                	addi	a1,a1,-1
    80001b8c:	05b2                	slli	a1,a1,0xc
    80001b8e:	8526                	mv	a0,s1
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	6e6080e7          	jalr	1766(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b98:	4581                	li	a1,0
    80001b9a:	8526                	mv	a0,s1
    80001b9c:	00000097          	auipc	ra,0x0
    80001ba0:	99a080e7          	jalr	-1638(ra) # 80001536 <uvmfree>
    return 0;
    80001ba4:	4481                	li	s1,0
    80001ba6:	bf7d                	j	80001b64 <proc_pagetable+0x58>

0000000080001ba8 <proc_freepagetable>:
{
    80001ba8:	1101                	addi	sp,sp,-32
    80001baa:	ec06                	sd	ra,24(sp)
    80001bac:	e822                	sd	s0,16(sp)
    80001bae:	e426                	sd	s1,8(sp)
    80001bb0:	e04a                	sd	s2,0(sp)
    80001bb2:	1000                	addi	s0,sp,32
    80001bb4:	84aa                	mv	s1,a0
    80001bb6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb8:	4681                	li	a3,0
    80001bba:	4605                	li	a2,1
    80001bbc:	040005b7          	lui	a1,0x4000
    80001bc0:	15fd                	addi	a1,a1,-1
    80001bc2:	05b2                	slli	a1,a1,0xc
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	6b2080e7          	jalr	1714(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bcc:	4681                	li	a3,0
    80001bce:	4605                	li	a2,1
    80001bd0:	020005b7          	lui	a1,0x2000
    80001bd4:	15fd                	addi	a1,a1,-1
    80001bd6:	05b6                	slli	a1,a1,0xd
    80001bd8:	8526                	mv	a0,s1
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	69c080e7          	jalr	1692(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001be2:	85ca                	mv	a1,s2
    80001be4:	8526                	mv	a0,s1
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	950080e7          	jalr	-1712(ra) # 80001536 <uvmfree>
}
    80001bee:	60e2                	ld	ra,24(sp)
    80001bf0:	6442                	ld	s0,16(sp)
    80001bf2:	64a2                	ld	s1,8(sp)
    80001bf4:	6902                	ld	s2,0(sp)
    80001bf6:	6105                	addi	sp,sp,32
    80001bf8:	8082                	ret

0000000080001bfa <freeproc>:
{
    80001bfa:	1101                	addi	sp,sp,-32
    80001bfc:	ec06                	sd	ra,24(sp)
    80001bfe:	e822                	sd	s0,16(sp)
    80001c00:	e426                	sd	s1,8(sp)
    80001c02:	1000                	addi	s0,sp,32
    80001c04:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c06:	6d28                	ld	a0,88(a0)
    80001c08:	c509                	beqz	a0,80001c12 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	dee080e7          	jalr	-530(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c12:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c16:	68a8                	ld	a0,80(s1)
    80001c18:	c511                	beqz	a0,80001c24 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c1a:	64ac                	ld	a1,72(s1)
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	f8c080e7          	jalr	-116(ra) # 80001ba8 <proc_freepagetable>
  p->pagetable = 0;
    80001c24:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c28:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c2c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c30:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c34:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c38:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c3c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c40:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c44:	0004ac23          	sw	zero,24(s1)
}
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6105                	addi	sp,sp,32
    80001c50:	8082                	ret

0000000080001c52 <allocproc>:
{
    80001c52:	1101                	addi	sp,sp,-32
    80001c54:	ec06                	sd	ra,24(sp)
    80001c56:	e822                	sd	s0,16(sp)
    80001c58:	e426                	sd	s1,8(sp)
    80001c5a:	e04a                	sd	s2,0(sp)
    80001c5c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5e:	00008497          	auipc	s1,0x8
    80001c62:	60248493          	addi	s1,s1,1538 # 8000a260 <proc>
    80001c66:	0000e917          	auipc	s2,0xe
    80001c6a:	5fa90913          	addi	s2,s2,1530 # 80010260 <tickslock>
    acquire(&p->lock);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	f74080e7          	jalr	-140(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c78:	4c9c                	lw	a5,24(s1)
    80001c7a:	cf81                	beqz	a5,80001c92 <allocproc+0x40>
      release(&p->lock);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	01a080e7          	jalr	26(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c86:	18048493          	addi	s1,s1,384
    80001c8a:	ff2492e3          	bne	s1,s2,80001c6e <allocproc+0x1c>
  return 0;
    80001c8e:	4481                	li	s1,0
    80001c90:	a8a9                	j	80001cea <allocproc+0x98>
  p->pid = allocpid();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	e34080e7          	jalr	-460(ra) # 80001ac6 <allocpid>
    80001c9a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c9c:	4785                	li	a5,1
    80001c9e:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001ca0:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001ca4:	1604a623          	sw	zero,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	e4c080e7          	jalr	-436(ra) # 80000af4 <kalloc>
    80001cb0:	892a                	mv	s2,a0
    80001cb2:	eca8                	sd	a0,88(s1)
    80001cb4:	c131                	beqz	a0,80001cf8 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	e54080e7          	jalr	-428(ra) # 80001b0c <proc_pagetable>
    80001cc0:	892a                	mv	s2,a0
    80001cc2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc4:	c531                	beqz	a0,80001d10 <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001cc6:	07000613          	li	a2,112
    80001cca:	4581                	li	a1,0
    80001ccc:	06048513          	addi	a0,s1,96
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	010080e7          	jalr	16(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001cd8:	00000797          	auipc	a5,0x0
    80001cdc:	da878793          	addi	a5,a5,-600 # 80001a80 <forkret>
    80001ce0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce2:	60bc                	ld	a5,64(s1)
    80001ce4:	6705                	lui	a4,0x1
    80001ce6:	97ba                	add	a5,a5,a4
    80001ce8:	f4bc                	sd	a5,104(s1)
}
    80001cea:	8526                	mv	a0,s1
    80001cec:	60e2                	ld	ra,24(sp)
    80001cee:	6442                	ld	s0,16(sp)
    80001cf0:	64a2                	ld	s1,8(sp)
    80001cf2:	6902                	ld	s2,0(sp)
    80001cf4:	6105                	addi	sp,sp,32
    80001cf6:	8082                	ret
    freeproc(p);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	f00080e7          	jalr	-256(ra) # 80001bfa <freeproc>
    release(&p->lock);
    80001d02:	8526                	mv	a0,s1
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	f94080e7          	jalr	-108(ra) # 80000c98 <release>
    return 0;
    80001d0c:	84ca                	mv	s1,s2
    80001d0e:	bff1                	j	80001cea <allocproc+0x98>
    freeproc(p);
    80001d10:	8526                	mv	a0,s1
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	ee8080e7          	jalr	-280(ra) # 80001bfa <freeproc>
    release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f7c080e7          	jalr	-132(ra) # 80000c98 <release>
    return 0;
    80001d24:	84ca                	mv	s1,s2
    80001d26:	b7d1                	j	80001cea <allocproc+0x98>

0000000080001d28 <userinit>:
{
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	f20080e7          	jalr	-224(ra) # 80001c52 <allocproc>
    80001d3a:	84aa                	mv	s1,a0
  initproc = p;
    80001d3c:	00007797          	auipc	a5,0x7
    80001d40:	2ea7b623          	sd	a0,748(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d44:	03400613          	li	a2,52
    80001d48:	00007597          	auipc	a1,0x7
    80001d4c:	b7858593          	addi	a1,a1,-1160 # 800088c0 <initcode>
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	616080e7          	jalr	1558(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d5a:	6785                	lui	a5,0x1
    80001d5c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d5e:	6cb8                	ld	a4,88(s1)
    80001d60:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d64:	6cb8                	ld	a4,88(s1)
    80001d66:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d68:	4641                	li	a2,16
    80001d6a:	00006597          	auipc	a1,0x6
    80001d6e:	49658593          	addi	a1,a1,1174 # 80008200 <digits+0x1c0>
    80001d72:	15848513          	addi	a0,s1,344
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	0bc080e7          	jalr	188(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d7e:	00006517          	auipc	a0,0x6
    80001d82:	49250513          	addi	a0,a0,1170 # 80008210 <digits+0x1d0>
    80001d86:	00002097          	auipc	ra,0x2
    80001d8a:	482080e7          	jalr	1154(ra) # 80004208 <namei>
    80001d8e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d92:	478d                	li	a5,3
    80001d94:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001d96:	00007797          	auipc	a5,0x7
    80001d9a:	2ba7a783          	lw	a5,698(a5) # 80009050 <ticks>
    80001d9e:	16f4a823          	sw	a5,368(s1)
  release(&p->lock);
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	ef4080e7          	jalr	-268(ra) # 80000c98 <release>
}
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6105                	addi	sp,sp,32
    80001db4:	8082                	ret

0000000080001db6 <growproc>:
{
    80001db6:	1101                	addi	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	e04a                	sd	s2,0(sp)
    80001dc0:	1000                	addi	s0,sp,32
    80001dc2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	c84080e7          	jalr	-892(ra) # 80001a48 <myproc>
    80001dcc:	892a                	mv	s2,a0
  sz = p->sz;
    80001dce:	652c                	ld	a1,72(a0)
    80001dd0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dd4:	00904f63          	bgtz	s1,80001df2 <growproc+0x3c>
  } else if(n < 0){
    80001dd8:	0204cc63          	bltz	s1,80001e10 <growproc+0x5a>
  p->sz = sz;
    80001ddc:	1602                	slli	a2,a2,0x20
    80001dde:	9201                	srli	a2,a2,0x20
    80001de0:	04c93423          	sd	a2,72(s2)
  return 0;
    80001de4:	4501                	li	a0,0
}
    80001de6:	60e2                	ld	ra,24(sp)
    80001de8:	6442                	ld	s0,16(sp)
    80001dea:	64a2                	ld	s1,8(sp)
    80001dec:	6902                	ld	s2,0(sp)
    80001dee:	6105                	addi	sp,sp,32
    80001df0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001df2:	9e25                	addw	a2,a2,s1
    80001df4:	1602                	slli	a2,a2,0x20
    80001df6:	9201                	srli	a2,a2,0x20
    80001df8:	1582                	slli	a1,a1,0x20
    80001dfa:	9181                	srli	a1,a1,0x20
    80001dfc:	6928                	ld	a0,80(a0)
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	624080e7          	jalr	1572(ra) # 80001422 <uvmalloc>
    80001e06:	0005061b          	sext.w	a2,a0
    80001e0a:	fa69                	bnez	a2,80001ddc <growproc+0x26>
      return -1;
    80001e0c:	557d                	li	a0,-1
    80001e0e:	bfe1                	j	80001de6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e10:	9e25                	addw	a2,a2,s1
    80001e12:	1602                	slli	a2,a2,0x20
    80001e14:	9201                	srli	a2,a2,0x20
    80001e16:	1582                	slli	a1,a1,0x20
    80001e18:	9181                	srli	a1,a1,0x20
    80001e1a:	6928                	ld	a0,80(a0)
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	5be080e7          	jalr	1470(ra) # 800013da <uvmdealloc>
    80001e24:	0005061b          	sext.w	a2,a0
    80001e28:	bf55                	j	80001ddc <growproc+0x26>

0000000080001e2a <fork>:
{
    80001e2a:	7179                	addi	sp,sp,-48
    80001e2c:	f406                	sd	ra,40(sp)
    80001e2e:	f022                	sd	s0,32(sp)
    80001e30:	ec26                	sd	s1,24(sp)
    80001e32:	e84a                	sd	s2,16(sp)
    80001e34:	e44e                	sd	s3,8(sp)
    80001e36:	e052                	sd	s4,0(sp)
    80001e38:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	c0e080e7          	jalr	-1010(ra) # 80001a48 <myproc>
    80001e42:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e44:	00000097          	auipc	ra,0x0
    80001e48:	e0e080e7          	jalr	-498(ra) # 80001c52 <allocproc>
    80001e4c:	12050163          	beqz	a0,80001f6e <fork+0x144>
    80001e50:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e52:	04893603          	ld	a2,72(s2)
    80001e56:	692c                	ld	a1,80(a0)
    80001e58:	05093503          	ld	a0,80(s2)
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	712080e7          	jalr	1810(ra) # 8000156e <uvmcopy>
    80001e64:	04054663          	bltz	a0,80001eb0 <fork+0x86>
  np->sz = p->sz;
    80001e68:	04893783          	ld	a5,72(s2)
    80001e6c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e70:	05893683          	ld	a3,88(s2)
    80001e74:	87b6                	mv	a5,a3
    80001e76:	0589b703          	ld	a4,88(s3)
    80001e7a:	12068693          	addi	a3,a3,288
    80001e7e:	0007b803          	ld	a6,0(a5)
    80001e82:	6788                	ld	a0,8(a5)
    80001e84:	6b8c                	ld	a1,16(a5)
    80001e86:	6f90                	ld	a2,24(a5)
    80001e88:	01073023          	sd	a6,0(a4)
    80001e8c:	e708                	sd	a0,8(a4)
    80001e8e:	eb0c                	sd	a1,16(a4)
    80001e90:	ef10                	sd	a2,24(a4)
    80001e92:	02078793          	addi	a5,a5,32
    80001e96:	02070713          	addi	a4,a4,32
    80001e9a:	fed792e3          	bne	a5,a3,80001e7e <fork+0x54>
  np->trapframe->a0 = 0;
    80001e9e:	0589b783          	ld	a5,88(s3)
    80001ea2:	0607b823          	sd	zero,112(a5)
    80001ea6:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001eaa:	15000a13          	li	s4,336
    80001eae:	a03d                	j	80001edc <fork+0xb2>
    freeproc(np);
    80001eb0:	854e                	mv	a0,s3
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	d48080e7          	jalr	-696(ra) # 80001bfa <freeproc>
    release(&np->lock);
    80001eba:	854e                	mv	a0,s3
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	ddc080e7          	jalr	-548(ra) # 80000c98 <release>
    return -1;
    80001ec4:	5a7d                	li	s4,-1
    80001ec6:	a859                	j	80001f5c <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ec8:	00003097          	auipc	ra,0x3
    80001ecc:	9d6080e7          	jalr	-1578(ra) # 8000489e <filedup>
    80001ed0:	009987b3          	add	a5,s3,s1
    80001ed4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ed6:	04a1                	addi	s1,s1,8
    80001ed8:	01448763          	beq	s1,s4,80001ee6 <fork+0xbc>
    if(p->ofile[i])
    80001edc:	009907b3          	add	a5,s2,s1
    80001ee0:	6388                	ld	a0,0(a5)
    80001ee2:	f17d                	bnez	a0,80001ec8 <fork+0x9e>
    80001ee4:	bfcd                	j	80001ed6 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ee6:	15093503          	ld	a0,336(s2)
    80001eea:	00002097          	auipc	ra,0x2
    80001eee:	b2a080e7          	jalr	-1238(ra) # 80003a14 <idup>
    80001ef2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef6:	4641                	li	a2,16
    80001ef8:	15890593          	addi	a1,s2,344
    80001efc:	15898513          	addi	a0,s3,344
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	f32080e7          	jalr	-206(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f08:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f0c:	854e                	mv	a0,s3
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	d8a080e7          	jalr	-630(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f16:	00008497          	auipc	s1,0x8
    80001f1a:	2b248493          	addi	s1,s1,690 # 8000a1c8 <wait_lock>
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	cc4080e7          	jalr	-828(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f28:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d6a080e7          	jalr	-662(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f36:	854e                	mv	a0,s3
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	cac080e7          	jalr	-852(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f40:	478d                	li	a5,3
    80001f42:	00f9ac23          	sw	a5,24(s3)
  np->last_runnable_time = ticks;
    80001f46:	00007797          	auipc	a5,0x7
    80001f4a:	10a7a783          	lw	a5,266(a5) # 80009050 <ticks>
    80001f4e:	16f9a823          	sw	a5,368(s3)
  release(&np->lock);
    80001f52:	854e                	mv	a0,s3
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
}
    80001f5c:	8552                	mv	a0,s4
    80001f5e:	70a2                	ld	ra,40(sp)
    80001f60:	7402                	ld	s0,32(sp)
    80001f62:	64e2                	ld	s1,24(sp)
    80001f64:	6942                	ld	s2,16(sp)
    80001f66:	69a2                	ld	s3,8(sp)
    80001f68:	6a02                	ld	s4,0(sp)
    80001f6a:	6145                	addi	sp,sp,48
    80001f6c:	8082                	ret
    return -1;
    80001f6e:	5a7d                	li	s4,-1
    80001f70:	b7f5                	j	80001f5c <fork+0x132>

0000000080001f72 <updateGlobalStats>:
{
    80001f72:	1141                	addi	sp,sp,-16
    80001f74:	e422                	sd	s0,8(sp)
    80001f76:	0800                	addi	s0,sp,16
  if(p!= 0)
    80001f78:	c545                	beqz	a0,80002020 <updateGlobalStats+0xae>
    running_processes_mean = (((running_processes_mean * (num_exit_procceses)) + p->total_running_time) / (num_exit_procceses + 1));
    80001f7a:	00007697          	auipc	a3,0x7
    80001f7e:	0c26a683          	lw	a3,194(a3) # 8000903c <num_exit_procceses>
    80001f82:	17452583          	lw	a1,372(a0)
    80001f86:	0016861b          	addiw	a2,a3,1
    80001f8a:	00007797          	auipc	a5,0x7
    80001f8e:	0be78793          	addi	a5,a5,190 # 80009048 <running_processes_mean>
    80001f92:	4398                	lw	a4,0(a5)
    80001f94:	02d7073b          	mulw	a4,a4,a3
    80001f98:	9f2d                	addw	a4,a4,a1
    80001f9a:	02c7573b          	divuw	a4,a4,a2
    80001f9e:	c398                	sw	a4,0(a5)
    sleeping_processes_mean = (((sleeping_processes_mean * (num_exit_procceses)) + p->total_sleeping_time) / (num_exit_procceses + 1));
    80001fa0:	00007797          	auipc	a5,0x7
    80001fa4:	0ac78793          	addi	a5,a5,172 # 8000904c <sleeping_processes_mean>
    80001fa8:	4398                	lw	a4,0(a5)
    80001faa:	02d7073b          	mulw	a4,a4,a3
    80001fae:	17c52803          	lw	a6,380(a0)
    80001fb2:	0107073b          	addw	a4,a4,a6
    80001fb6:	02c7573b          	divuw	a4,a4,a2
    80001fba:	c398                	sw	a4,0(a5)
    runnable_time_mean = (((runnable_time_mean * (num_exit_procceses)) + p->total_runnable_time) / (num_exit_procceses + 1));
    80001fbc:	00007717          	auipc	a4,0x7
    80001fc0:	08870713          	addi	a4,a4,136 # 80009044 <runnable_time_mean>
    80001fc4:	431c                	lw	a5,0(a4)
    80001fc6:	02d787bb          	mulw	a5,a5,a3
    80001fca:	17852683          	lw	a3,376(a0)
    80001fce:	9fb5                	addw	a5,a5,a3
    80001fd0:	02c7d7bb          	divuw	a5,a5,a2
    80001fd4:	c31c                	sw	a5,0(a4)
    if(p->pid != SHELL_PID && p->pid != initproc->pid) // Only update if not shell or init process
    80001fd6:	591c                	lw	a5,48(a0)
    80001fd8:	4709                	li	a4,2
    80001fda:	04e78363          	beq	a5,a4,80002020 <updateGlobalStats+0xae>
    80001fde:	00007717          	auipc	a4,0x7
    80001fe2:	04a73703          	ld	a4,74(a4) # 80009028 <initproc>
    80001fe6:	5b18                	lw	a4,48(a4)
    80001fe8:	02f70c63          	beq	a4,a5,80002020 <updateGlobalStats+0xae>
      program_time = program_time + p->total_running_time;
    80001fec:	00007717          	auipc	a4,0x7
    80001ff0:	05470713          	addi	a4,a4,84 # 80009040 <program_time>
    80001ff4:	431c                	lw	a5,0(a4)
    80001ff6:	9dbd                	addw	a1,a1,a5
    80001ff8:	c30c                	sw	a1,0(a4)
      cpu_utilization = 100*program_time / (ticks - start_time);
    80001ffa:	06400793          	li	a5,100
    80001ffe:	02b787bb          	mulw	a5,a5,a1
    80002002:	00007717          	auipc	a4,0x7
    80002006:	04e72703          	lw	a4,78(a4) # 80009050 <ticks>
    8000200a:	00007697          	auipc	a3,0x7
    8000200e:	02e6a683          	lw	a3,46(a3) # 80009038 <start_time>
    80002012:	9f15                	subw	a4,a4,a3
    80002014:	02e7d7bb          	divuw	a5,a5,a4
    80002018:	00007717          	auipc	a4,0x7
    8000201c:	00f72e23          	sw	a5,28(a4) # 80009034 <cpu_utilization>
}
    80002020:	6422                	ld	s0,8(sp)
    80002022:	0141                	addi	sp,sp,16
    80002024:	8082                	ret

0000000080002026 <scheduler>:
{
    80002026:	711d                	addi	sp,sp,-96
    80002028:	ec86                	sd	ra,88(sp)
    8000202a:	e8a2                	sd	s0,80(sp)
    8000202c:	e4a6                	sd	s1,72(sp)
    8000202e:	e0ca                	sd	s2,64(sp)
    80002030:	fc4e                	sd	s3,56(sp)
    80002032:	f852                	sd	s4,48(sp)
    80002034:	f456                	sd	s5,40(sp)
    80002036:	f05a                	sd	s6,32(sp)
    80002038:	ec5e                	sd	s7,24(sp)
    8000203a:	e862                	sd	s8,16(sp)
    8000203c:	e466                	sd	s9,8(sp)
    8000203e:	1080                	addi	s0,sp,96
    80002040:	8792                	mv	a5,tp
  int id = r_tp();
    80002042:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002044:	00779c13          	slli	s8,a5,0x7
    80002048:	00008717          	auipc	a4,0x8
    8000204c:	16870713          	addi	a4,a4,360 # 8000a1b0 <pid_lock>
    80002050:	9762                	add	a4,a4,s8
    80002052:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80002056:	00008717          	auipc	a4,0x8
    8000205a:	19270713          	addi	a4,a4,402 # 8000a1e8 <cpus+0x8>
    8000205e:	9c3a                	add	s8,s8,a4
    if(ticks<unpauseTicks)
    80002060:	00007b17          	auipc	s6,0x7
    80002064:	ff0b0b13          	addi	s6,s6,-16 # 80009050 <ticks>
          c->proc = p;
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	00008b97          	auipc	s7,0x8
    8000206e:	146b8b93          	addi	s7,s7,326 # 8000a1b0 <pid_lock>
    80002072:	9bbe                	add	s7,s7,a5
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    80002074:	00007a17          	auipc	s4,0x7
    80002078:	fb4a0a13          	addi	s4,s4,-76 # 80009028 <initproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000207c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002080:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002084:	10079073          	csrw	sstatus,a5
    if(ticks<unpauseTicks)
    80002088:	000b2703          	lw	a4,0(s6)
    8000208c:	00007797          	auipc	a5,0x7
    80002090:	fa47a783          	lw	a5,-92(a5) # 80009030 <unpauseTicks>
    80002094:	04f77e63          	bgeu	a4,a5,800020f0 <scheduler+0xca>
        for(p = proc; p < &proc[NPROC]; p++){
    80002098:	00008497          	auipc	s1,0x8
    8000209c:	1c848493          	addi	s1,s1,456 # 8000a260 <proc>
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    800020a0:	4989                	li	s3,2
          if(p->state == RUNNING)
    800020a2:	4a91                	li	s5,4
              p->state = RUNNABLE;
    800020a4:	4c8d                	li	s9,3
        for(p = proc; p < &proc[NPROC]; p++){
    800020a6:	0000e917          	auipc	s2,0xe
    800020aa:	1ba90913          	addi	s2,s2,442 # 80010260 <tickslock>
    800020ae:	a811                	j	800020c2 <scheduler+0x9c>
          release(&p->lock);
    800020b0:	8526                	mv	a0,s1
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	be6080e7          	jalr	-1050(ra) # 80000c98 <release>
        for(p = proc; p < &proc[NPROC]; p++){
    800020ba:	18048493          	addi	s1,s1,384
    800020be:	fb248fe3          	beq	s1,s2,8000207c <scheduler+0x56>
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    800020c2:	589c                	lw	a5,48(s1)
    800020c4:	ff378be3          	beq	a5,s3,800020ba <scheduler+0x94>
    800020c8:	000a3703          	ld	a4,0(s4)
    800020cc:	5b18                	lw	a4,48(a4)
    800020ce:	fef706e3          	beq	a4,a5,800020ba <scheduler+0x94>
          acquire(&p->lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	b10080e7          	jalr	-1264(ra) # 80000be4 <acquire>
          if(p->state == RUNNING)
    800020dc:	4c9c                	lw	a5,24(s1)
    800020de:	fd5799e3          	bne	a5,s5,800020b0 <scheduler+0x8a>
              p->state = RUNNABLE;
    800020e2:	0194ac23          	sw	s9,24(s1)
              p->last_runnable_time = ticks;
    800020e6:	000b2783          	lw	a5,0(s6)
    800020ea:	16f4a823          	sw	a5,368(s1)
    800020ee:	b7c9                	j	800020b0 <scheduler+0x8a>
       for(p = proc; p < &proc[NPROC]; p++){
    800020f0:	00008497          	auipc	s1,0x8
    800020f4:	17048493          	addi	s1,s1,368 # 8000a260 <proc>
          if(p->state == RUNNABLE) {
    800020f8:	498d                	li	s3,3
          p->state = RUNNING;
    800020fa:	4a91                	li	s5,4
       for(p = proc; p < &proc[NPROC]; p++){
    800020fc:	0000e917          	auipc	s2,0xe
    80002100:	16490913          	addi	s2,s2,356 # 80010260 <tickslock>
    80002104:	a03d                	j	80002132 <scheduler+0x10c>
          p->state = RUNNING;
    80002106:	0154ac23          	sw	s5,24(s1)
          c->proc = p;
    8000210a:	029bb823          	sd	s1,48(s7)
          swtch(&c->context, &p->context);
    8000210e:	06048593          	addi	a1,s1,96
    80002112:	8562                	mv	a0,s8
    80002114:	00001097          	auipc	ra,0x1
    80002118:	84e080e7          	jalr	-1970(ra) # 80002962 <swtch>
          c->proc = 0;
    8000211c:	020bb823          	sd	zero,48(s7)
        release(&p->lock);
    80002120:	8526                	mv	a0,s1
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	b76080e7          	jalr	-1162(ra) # 80000c98 <release>
       for(p = proc; p < &proc[NPROC]; p++){
    8000212a:	18048493          	addi	s1,s1,384
    8000212e:	f52487e3          	beq	s1,s2,8000207c <scheduler+0x56>
          acquire(&p->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	ab0080e7          	jalr	-1360(ra) # 80000be4 <acquire>
          if(p->state == RUNNABLE) {
    8000213c:	4c9c                	lw	a5,24(s1)
    8000213e:	ff3791e3          	bne	a5,s3,80002120 <scheduler+0xfa>
    80002142:	b7d1                	j	80002106 <scheduler+0xe0>

0000000080002144 <sched>:
{
    80002144:	7179                	addi	sp,sp,-48
    80002146:	f406                	sd	ra,40(sp)
    80002148:	f022                	sd	s0,32(sp)
    8000214a:	ec26                	sd	s1,24(sp)
    8000214c:	e84a                	sd	s2,16(sp)
    8000214e:	e44e                	sd	s3,8(sp)
    80002150:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002152:	00000097          	auipc	ra,0x0
    80002156:	8f6080e7          	jalr	-1802(ra) # 80001a48 <myproc>
    8000215a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	a0e080e7          	jalr	-1522(ra) # 80000b6a <holding>
    80002164:	c93d                	beqz	a0,800021da <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002166:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002168:	2781                	sext.w	a5,a5
    8000216a:	079e                	slli	a5,a5,0x7
    8000216c:	00008717          	auipc	a4,0x8
    80002170:	04470713          	addi	a4,a4,68 # 8000a1b0 <pid_lock>
    80002174:	97ba                	add	a5,a5,a4
    80002176:	0a87a703          	lw	a4,168(a5)
    8000217a:	4785                	li	a5,1
    8000217c:	06f71763          	bne	a4,a5,800021ea <sched+0xa6>
  if(p->state == RUNNING)
    80002180:	4c98                	lw	a4,24(s1)
    80002182:	4791                	li	a5,4
    80002184:	06f70b63          	beq	a4,a5,800021fa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002188:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000218c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000218e:	efb5                	bnez	a5,8000220a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002190:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002192:	00008917          	auipc	s2,0x8
    80002196:	01e90913          	addi	s2,s2,30 # 8000a1b0 <pid_lock>
    8000219a:	2781                	sext.w	a5,a5
    8000219c:	079e                	slli	a5,a5,0x7
    8000219e:	97ca                	add	a5,a5,s2
    800021a0:	0ac7a983          	lw	s3,172(a5)
    800021a4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021a6:	2781                	sext.w	a5,a5
    800021a8:	079e                	slli	a5,a5,0x7
    800021aa:	00008597          	auipc	a1,0x8
    800021ae:	03e58593          	addi	a1,a1,62 # 8000a1e8 <cpus+0x8>
    800021b2:	95be                	add	a1,a1,a5
    800021b4:	06048513          	addi	a0,s1,96
    800021b8:	00000097          	auipc	ra,0x0
    800021bc:	7aa080e7          	jalr	1962(ra) # 80002962 <swtch>
    800021c0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021c2:	2781                	sext.w	a5,a5
    800021c4:	079e                	slli	a5,a5,0x7
    800021c6:	97ca                	add	a5,a5,s2
    800021c8:	0b37a623          	sw	s3,172(a5)
}
    800021cc:	70a2                	ld	ra,40(sp)
    800021ce:	7402                	ld	s0,32(sp)
    800021d0:	64e2                	ld	s1,24(sp)
    800021d2:	6942                	ld	s2,16(sp)
    800021d4:	69a2                	ld	s3,8(sp)
    800021d6:	6145                	addi	sp,sp,48
    800021d8:	8082                	ret
    panic("sched p->lock");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	03e50513          	addi	a0,a0,62 # 80008218 <digits+0x1d8>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	35c080e7          	jalr	860(ra) # 8000053e <panic>
    panic("sched locks");
    800021ea:	00006517          	auipc	a0,0x6
    800021ee:	03e50513          	addi	a0,a0,62 # 80008228 <digits+0x1e8>
    800021f2:	ffffe097          	auipc	ra,0xffffe
    800021f6:	34c080e7          	jalr	844(ra) # 8000053e <panic>
    panic("sched running");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	03e50513          	addi	a0,a0,62 # 80008238 <digits+0x1f8>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	33c080e7          	jalr	828(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000220a:	00006517          	auipc	a0,0x6
    8000220e:	03e50513          	addi	a0,a0,62 # 80008248 <digits+0x208>
    80002212:	ffffe097          	auipc	ra,0xffffe
    80002216:	32c080e7          	jalr	812(ra) # 8000053e <panic>

000000008000221a <yield>:
{
    8000221a:	1101                	addi	sp,sp,-32
    8000221c:	ec06                	sd	ra,24(sp)
    8000221e:	e822                	sd	s0,16(sp)
    80002220:	e426                	sd	s1,8(sp)
    80002222:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	824080e7          	jalr	-2012(ra) # 80001a48 <myproc>
    8000222c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9b6080e7          	jalr	-1610(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002236:	478d                	li	a5,3
    80002238:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    8000223a:	00007797          	auipc	a5,0x7
    8000223e:	e167a783          	lw	a5,-490(a5) # 80009050 <ticks>
    80002242:	16f4a823          	sw	a5,368(s1)
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	efe080e7          	jalr	-258(ra) # 80002144 <sched>
  release(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>
}
    80002258:	60e2                	ld	ra,24(sp)
    8000225a:	6442                	ld	s0,16(sp)
    8000225c:	64a2                	ld	s1,8(sp)
    8000225e:	6105                	addi	sp,sp,32
    80002260:	8082                	ret

0000000080002262 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002262:	7179                	addi	sp,sp,-48
    80002264:	f406                	sd	ra,40(sp)
    80002266:	f022                	sd	s0,32(sp)
    80002268:	ec26                	sd	s1,24(sp)
    8000226a:	e84a                	sd	s2,16(sp)
    8000226c:	e44e                	sd	s3,8(sp)
    8000226e:	1800                	addi	s0,sp,48
    80002270:	89aa                	mv	s3,a0
    80002272:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	7d4080e7          	jalr	2004(ra) # 80001a48 <myproc>
    8000227c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	966080e7          	jalr	-1690(ra) # 80000be4 <acquire>
  release(lk);
    80002286:	854a                	mv	a0,s2
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	a10080e7          	jalr	-1520(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002290:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002294:	4789                	li	a5,2
    80002296:	cc9c                	sw	a5,24(s1)

  sched();
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	eac080e7          	jalr	-340(ra) # 80002144 <sched>

  // Tidy up.
  p->chan = 0;
    800022a0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
  acquire(lk);
    800022ae:	854a                	mv	a0,s2
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	934080e7          	jalr	-1740(ra) # 80000be4 <acquire>
}
    800022b8:	70a2                	ld	ra,40(sp)
    800022ba:	7402                	ld	s0,32(sp)
    800022bc:	64e2                	ld	s1,24(sp)
    800022be:	6942                	ld	s2,16(sp)
    800022c0:	69a2                	ld	s3,8(sp)
    800022c2:	6145                	addi	sp,sp,48
    800022c4:	8082                	ret

00000000800022c6 <wait>:
{
    800022c6:	715d                	addi	sp,sp,-80
    800022c8:	e486                	sd	ra,72(sp)
    800022ca:	e0a2                	sd	s0,64(sp)
    800022cc:	fc26                	sd	s1,56(sp)
    800022ce:	f84a                	sd	s2,48(sp)
    800022d0:	f44e                	sd	s3,40(sp)
    800022d2:	f052                	sd	s4,32(sp)
    800022d4:	ec56                	sd	s5,24(sp)
    800022d6:	e85a                	sd	s6,16(sp)
    800022d8:	e45e                	sd	s7,8(sp)
    800022da:	e062                	sd	s8,0(sp)
    800022dc:	0880                	addi	s0,sp,80
    800022de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	768080e7          	jalr	1896(ra) # 80001a48 <myproc>
    800022e8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022ea:	00008517          	auipc	a0,0x8
    800022ee:	ede50513          	addi	a0,a0,-290 # 8000a1c8 <wait_lock>
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8f2080e7          	jalr	-1806(ra) # 80000be4 <acquire>
    havekids = 0;
    800022fa:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022fc:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022fe:	0000e997          	auipc	s3,0xe
    80002302:	f6298993          	addi	s3,s3,-158 # 80010260 <tickslock>
        havekids = 1;
    80002306:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002308:	00008c17          	auipc	s8,0x8
    8000230c:	ec0c0c13          	addi	s8,s8,-320 # 8000a1c8 <wait_lock>
    havekids = 0;
    80002310:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002312:	00008497          	auipc	s1,0x8
    80002316:	f4e48493          	addi	s1,s1,-178 # 8000a260 <proc>
    8000231a:	a0bd                	j	80002388 <wait+0xc2>
          pid = np->pid;
    8000231c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002320:	000b0e63          	beqz	s6,8000233c <wait+0x76>
    80002324:	4691                	li	a3,4
    80002326:	02c48613          	addi	a2,s1,44
    8000232a:	85da                	mv	a1,s6
    8000232c:	05093503          	ld	a0,80(s2)
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	342080e7          	jalr	834(ra) # 80001672 <copyout>
    80002338:	02054563          	bltz	a0,80002362 <wait+0x9c>
          freeproc(np);
    8000233c:	8526                	mv	a0,s1
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	8bc080e7          	jalr	-1860(ra) # 80001bfa <freeproc>
          release(&np->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	950080e7          	jalr	-1712(ra) # 80000c98 <release>
          release(&wait_lock);
    80002350:	00008517          	auipc	a0,0x8
    80002354:	e7850513          	addi	a0,a0,-392 # 8000a1c8 <wait_lock>
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	940080e7          	jalr	-1728(ra) # 80000c98 <release>
          return pid;
    80002360:	a09d                	j	800023c6 <wait+0x100>
            release(&np->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
            release(&wait_lock);
    8000236c:	00008517          	auipc	a0,0x8
    80002370:	e5c50513          	addi	a0,a0,-420 # 8000a1c8 <wait_lock>
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
            return -1;
    8000237c:	59fd                	li	s3,-1
    8000237e:	a0a1                	j	800023c6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002380:	18048493          	addi	s1,s1,384
    80002384:	03348463          	beq	s1,s3,800023ac <wait+0xe6>
      if(np->parent == p){
    80002388:	7c9c                	ld	a5,56(s1)
    8000238a:	ff279be3          	bne	a5,s2,80002380 <wait+0xba>
        acquire(&np->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	854080e7          	jalr	-1964(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002398:	4c9c                	lw	a5,24(s1)
    8000239a:	f94781e3          	beq	a5,s4,8000231c <wait+0x56>
        release(&np->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8f8080e7          	jalr	-1800(ra) # 80000c98 <release>
        havekids = 1;
    800023a8:	8756                	mv	a4,s5
    800023aa:	bfd9                	j	80002380 <wait+0xba>
    if(!havekids || p->killed){
    800023ac:	c701                	beqz	a4,800023b4 <wait+0xee>
    800023ae:	02892783          	lw	a5,40(s2)
    800023b2:	c79d                	beqz	a5,800023e0 <wait+0x11a>
      release(&wait_lock);
    800023b4:	00008517          	auipc	a0,0x8
    800023b8:	e1450513          	addi	a0,a0,-492 # 8000a1c8 <wait_lock>
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8dc080e7          	jalr	-1828(ra) # 80000c98 <release>
      return -1;
    800023c4:	59fd                	li	s3,-1
}
    800023c6:	854e                	mv	a0,s3
    800023c8:	60a6                	ld	ra,72(sp)
    800023ca:	6406                	ld	s0,64(sp)
    800023cc:	74e2                	ld	s1,56(sp)
    800023ce:	7942                	ld	s2,48(sp)
    800023d0:	79a2                	ld	s3,40(sp)
    800023d2:	7a02                	ld	s4,32(sp)
    800023d4:	6ae2                	ld	s5,24(sp)
    800023d6:	6b42                	ld	s6,16(sp)
    800023d8:	6ba2                	ld	s7,8(sp)
    800023da:	6c02                	ld	s8,0(sp)
    800023dc:	6161                	addi	sp,sp,80
    800023de:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023e0:	85e2                	mv	a1,s8
    800023e2:	854a                	mv	a0,s2
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	e7e080e7          	jalr	-386(ra) # 80002262 <sleep>
    havekids = 0;
    800023ec:	b715                	j	80002310 <wait+0x4a>

00000000800023ee <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023ee:	7139                	addi	sp,sp,-64
    800023f0:	fc06                	sd	ra,56(sp)
    800023f2:	f822                	sd	s0,48(sp)
    800023f4:	f426                	sd	s1,40(sp)
    800023f6:	f04a                	sd	s2,32(sp)
    800023f8:	ec4e                	sd	s3,24(sp)
    800023fa:	e852                	sd	s4,16(sp)
    800023fc:	e456                	sd	s5,8(sp)
    800023fe:	e05a                	sd	s6,0(sp)
    80002400:	0080                	addi	s0,sp,64
    80002402:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002404:	00008497          	auipc	s1,0x8
    80002408:	e5c48493          	addi	s1,s1,-420 # 8000a260 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000240c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000240e:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    80002410:	00007a97          	auipc	s5,0x7
    80002414:	c40a8a93          	addi	s5,s5,-960 # 80009050 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002418:	0000e917          	auipc	s2,0xe
    8000241c:	e4890913          	addi	s2,s2,-440 # 80010260 <tickslock>
    80002420:	a005                	j	80002440 <wakeup+0x52>
        p->state = RUNNABLE;
    80002422:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002426:	000aa783          	lw	a5,0(s5)
    8000242a:	16f4a823          	sw	a5,368(s1)
      }
      release(&p->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002438:	18048493          	addi	s1,s1,384
    8000243c:	03248463          	beq	s1,s2,80002464 <wakeup+0x76>
    if(p != myproc()){
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	608080e7          	jalr	1544(ra) # 80001a48 <myproc>
    80002448:	fea488e3          	beq	s1,a0,80002438 <wakeup+0x4a>
      acquire(&p->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	796080e7          	jalr	1942(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002456:	4c9c                	lw	a5,24(s1)
    80002458:	fd379be3          	bne	a5,s3,8000242e <wakeup+0x40>
    8000245c:	709c                	ld	a5,32(s1)
    8000245e:	fd4798e3          	bne	a5,s4,8000242e <wakeup+0x40>
    80002462:	b7c1                	j	80002422 <wakeup+0x34>
    }
  }
}
    80002464:	70e2                	ld	ra,56(sp)
    80002466:	7442                	ld	s0,48(sp)
    80002468:	74a2                	ld	s1,40(sp)
    8000246a:	7902                	ld	s2,32(sp)
    8000246c:	69e2                	ld	s3,24(sp)
    8000246e:	6a42                	ld	s4,16(sp)
    80002470:	6aa2                	ld	s5,8(sp)
    80002472:	6b02                	ld	s6,0(sp)
    80002474:	6121                	addi	sp,sp,64
    80002476:	8082                	ret

0000000080002478 <reparent>:
{
    80002478:	7179                	addi	sp,sp,-48
    8000247a:	f406                	sd	ra,40(sp)
    8000247c:	f022                	sd	s0,32(sp)
    8000247e:	ec26                	sd	s1,24(sp)
    80002480:	e84a                	sd	s2,16(sp)
    80002482:	e44e                	sd	s3,8(sp)
    80002484:	e052                	sd	s4,0(sp)
    80002486:	1800                	addi	s0,sp,48
    80002488:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000248a:	00008497          	auipc	s1,0x8
    8000248e:	dd648493          	addi	s1,s1,-554 # 8000a260 <proc>
      pp->parent = initproc;
    80002492:	00007a17          	auipc	s4,0x7
    80002496:	b96a0a13          	addi	s4,s4,-1130 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249a:	0000e997          	auipc	s3,0xe
    8000249e:	dc698993          	addi	s3,s3,-570 # 80010260 <tickslock>
    800024a2:	a029                	j	800024ac <reparent+0x34>
    800024a4:	18048493          	addi	s1,s1,384
    800024a8:	01348d63          	beq	s1,s3,800024c2 <reparent+0x4a>
    if(pp->parent == p){
    800024ac:	7c9c                	ld	a5,56(s1)
    800024ae:	ff279be3          	bne	a5,s2,800024a4 <reparent+0x2c>
      pp->parent = initproc;
    800024b2:	000a3503          	ld	a0,0(s4)
    800024b6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	f36080e7          	jalr	-202(ra) # 800023ee <wakeup>
    800024c0:	b7d5                	j	800024a4 <reparent+0x2c>
}
    800024c2:	70a2                	ld	ra,40(sp)
    800024c4:	7402                	ld	s0,32(sp)
    800024c6:	64e2                	ld	s1,24(sp)
    800024c8:	6942                	ld	s2,16(sp)
    800024ca:	69a2                	ld	s3,8(sp)
    800024cc:	6a02                	ld	s4,0(sp)
    800024ce:	6145                	addi	sp,sp,48
    800024d0:	8082                	ret

00000000800024d2 <exit>:
{
    800024d2:	7179                	addi	sp,sp,-48
    800024d4:	f406                	sd	ra,40(sp)
    800024d6:	f022                	sd	s0,32(sp)
    800024d8:	ec26                	sd	s1,24(sp)
    800024da:	e84a                	sd	s2,16(sp)
    800024dc:	e44e                	sd	s3,8(sp)
    800024de:	e052                	sd	s4,0(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	564080e7          	jalr	1380(ra) # 80001a48 <myproc>
    800024ec:	89aa                	mv	s3,a0
  updateGlobalStats(p);
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	a84080e7          	jalr	-1404(ra) # 80001f72 <updateGlobalStats>
  num_exit_procceses++;
    800024f6:	00007717          	auipc	a4,0x7
    800024fa:	b4670713          	addi	a4,a4,-1210 # 8000903c <num_exit_procceses>
    800024fe:	431c                	lw	a5,0(a4)
    80002500:	2785                	addiw	a5,a5,1
    80002502:	c31c                	sw	a5,0(a4)
  if(p == initproc)
    80002504:	00007797          	auipc	a5,0x7
    80002508:	b247b783          	ld	a5,-1244(a5) # 80009028 <initproc>
    8000250c:	0d098493          	addi	s1,s3,208
    80002510:	15098913          	addi	s2,s3,336
    80002514:	03379363          	bne	a5,s3,8000253a <exit+0x68>
    panic("init exiting");
    80002518:	00006517          	auipc	a0,0x6
    8000251c:	d4850513          	addi	a0,a0,-696 # 80008260 <digits+0x220>
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	01e080e7          	jalr	30(ra) # 8000053e <panic>
      fileclose(f);
    80002528:	00002097          	auipc	ra,0x2
    8000252c:	3c8080e7          	jalr	968(ra) # 800048f0 <fileclose>
      p->ofile[fd] = 0;
    80002530:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002534:	04a1                	addi	s1,s1,8
    80002536:	01248563          	beq	s1,s2,80002540 <exit+0x6e>
    if(p->ofile[fd]){
    8000253a:	6088                	ld	a0,0(s1)
    8000253c:	f575                	bnez	a0,80002528 <exit+0x56>
    8000253e:	bfdd                	j	80002534 <exit+0x62>
  begin_op();
    80002540:	00002097          	auipc	ra,0x2
    80002544:	ee4080e7          	jalr	-284(ra) # 80004424 <begin_op>
  iput(p->cwd);
    80002548:	1509b503          	ld	a0,336(s3)
    8000254c:	00001097          	auipc	ra,0x1
    80002550:	6c0080e7          	jalr	1728(ra) # 80003c0c <iput>
  end_op();
    80002554:	00002097          	auipc	ra,0x2
    80002558:	f50080e7          	jalr	-176(ra) # 800044a4 <end_op>
  p->cwd = 0;
    8000255c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002560:	00008497          	auipc	s1,0x8
    80002564:	c6848493          	addi	s1,s1,-920 # 8000a1c8 <wait_lock>
    80002568:	8526                	mv	a0,s1
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	67a080e7          	jalr	1658(ra) # 80000be4 <acquire>
  reparent(p);
    80002572:	854e                	mv	a0,s3
    80002574:	00000097          	auipc	ra,0x0
    80002578:	f04080e7          	jalr	-252(ra) # 80002478 <reparent>
  wakeup(p->parent);
    8000257c:	0389b503          	ld	a0,56(s3)
    80002580:	00000097          	auipc	ra,0x0
    80002584:	e6e080e7          	jalr	-402(ra) # 800023ee <wakeup>
  acquire(&p->lock);
    80002588:	854e                	mv	a0,s3
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	65a080e7          	jalr	1626(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002592:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002596:	4795                	li	a5,5
    80002598:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	6fa080e7          	jalr	1786(ra) # 80000c98 <release>
  sched();
    800025a6:	00000097          	auipc	ra,0x0
    800025aa:	b9e080e7          	jalr	-1122(ra) # 80002144 <sched>
  panic("zombie exit");
    800025ae:	00006517          	auipc	a0,0x6
    800025b2:	cc250513          	addi	a0,a0,-830 # 80008270 <digits+0x230>
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>

00000000800025be <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	1800                	addi	s0,sp,48
    800025cc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025ce:	00008497          	auipc	s1,0x8
    800025d2:	c9248493          	addi	s1,s1,-878 # 8000a260 <proc>
    800025d6:	0000e997          	auipc	s3,0xe
    800025da:	c8a98993          	addi	s3,s3,-886 # 80010260 <tickslock>
    acquire(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	604080e7          	jalr	1540(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025e8:	589c                	lw	a5,48(s1)
    800025ea:	01278d63          	beq	a5,s2,80002604 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	6a8080e7          	jalr	1704(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f8:	18048493          	addi	s1,s1,384
    800025fc:	ff3491e3          	bne	s1,s3,800025de <kill+0x20>
  }
  return -1;
    80002600:	557d                	li	a0,-1
    80002602:	a829                	j	8000261c <kill+0x5e>
      p->killed = 1;
    80002604:	4785                	li	a5,1
    80002606:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002608:	4c98                	lw	a4,24(s1)
    8000260a:	4789                	li	a5,2
    8000260c:	00f70f63          	beq	a4,a5,8000262a <kill+0x6c>
      release(&p->lock);
    80002610:	8526                	mv	a0,s1
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	686080e7          	jalr	1670(ra) # 80000c98 <release>
      return 0;
    8000261a:	4501                	li	a0,0
}
    8000261c:	70a2                	ld	ra,40(sp)
    8000261e:	7402                	ld	s0,32(sp)
    80002620:	64e2                	ld	s1,24(sp)
    80002622:	6942                	ld	s2,16(sp)
    80002624:	69a2                	ld	s3,8(sp)
    80002626:	6145                	addi	sp,sp,48
    80002628:	8082                	ret
        p->state = RUNNABLE;
    8000262a:	478d                	li	a5,3
    8000262c:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    8000262e:	00007797          	auipc	a5,0x7
    80002632:	a227a783          	lw	a5,-1502(a5) # 80009050 <ticks>
    80002636:	16f4a823          	sw	a5,368(s1)
    8000263a:	bfd9                	j	80002610 <kill+0x52>

000000008000263c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000263c:	7179                	addi	sp,sp,-48
    8000263e:	f406                	sd	ra,40(sp)
    80002640:	f022                	sd	s0,32(sp)
    80002642:	ec26                	sd	s1,24(sp)
    80002644:	e84a                	sd	s2,16(sp)
    80002646:	e44e                	sd	s3,8(sp)
    80002648:	e052                	sd	s4,0(sp)
    8000264a:	1800                	addi	s0,sp,48
    8000264c:	84aa                	mv	s1,a0
    8000264e:	892e                	mv	s2,a1
    80002650:	89b2                	mv	s3,a2
    80002652:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	3f4080e7          	jalr	1012(ra) # 80001a48 <myproc>
  if(user_dst){
    8000265c:	c08d                	beqz	s1,8000267e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000265e:	86d2                	mv	a3,s4
    80002660:	864e                	mv	a2,s3
    80002662:	85ca                	mv	a1,s2
    80002664:	6928                	ld	a0,80(a0)
    80002666:	fffff097          	auipc	ra,0xfffff
    8000266a:	00c080e7          	jalr	12(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000266e:	70a2                	ld	ra,40(sp)
    80002670:	7402                	ld	s0,32(sp)
    80002672:	64e2                	ld	s1,24(sp)
    80002674:	6942                	ld	s2,16(sp)
    80002676:	69a2                	ld	s3,8(sp)
    80002678:	6a02                	ld	s4,0(sp)
    8000267a:	6145                	addi	sp,sp,48
    8000267c:	8082                	ret
    memmove((char *)dst, src, len);
    8000267e:	000a061b          	sext.w	a2,s4
    80002682:	85ce                	mv	a1,s3
    80002684:	854a                	mv	a0,s2
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	6ba080e7          	jalr	1722(ra) # 80000d40 <memmove>
    return 0;
    8000268e:	8526                	mv	a0,s1
    80002690:	bff9                	j	8000266e <either_copyout+0x32>

0000000080002692 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002692:	7179                	addi	sp,sp,-48
    80002694:	f406                	sd	ra,40(sp)
    80002696:	f022                	sd	s0,32(sp)
    80002698:	ec26                	sd	s1,24(sp)
    8000269a:	e84a                	sd	s2,16(sp)
    8000269c:	e44e                	sd	s3,8(sp)
    8000269e:	e052                	sd	s4,0(sp)
    800026a0:	1800                	addi	s0,sp,48
    800026a2:	892a                	mv	s2,a0
    800026a4:	84ae                	mv	s1,a1
    800026a6:	89b2                	mv	s3,a2
    800026a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026aa:	fffff097          	auipc	ra,0xfffff
    800026ae:	39e080e7          	jalr	926(ra) # 80001a48 <myproc>
  if(user_src){
    800026b2:	c08d                	beqz	s1,800026d4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026b4:	86d2                	mv	a3,s4
    800026b6:	864e                	mv	a2,s3
    800026b8:	85ca                	mv	a1,s2
    800026ba:	6928                	ld	a0,80(a0)
    800026bc:	fffff097          	auipc	ra,0xfffff
    800026c0:	042080e7          	jalr	66(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026c4:	70a2                	ld	ra,40(sp)
    800026c6:	7402                	ld	s0,32(sp)
    800026c8:	64e2                	ld	s1,24(sp)
    800026ca:	6942                	ld	s2,16(sp)
    800026cc:	69a2                	ld	s3,8(sp)
    800026ce:	6a02                	ld	s4,0(sp)
    800026d0:	6145                	addi	sp,sp,48
    800026d2:	8082                	ret
    memmove(dst, (char*)src, len);
    800026d4:	000a061b          	sext.w	a2,s4
    800026d8:	85ce                	mv	a1,s3
    800026da:	854a                	mv	a0,s2
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	664080e7          	jalr	1636(ra) # 80000d40 <memmove>
    return 0;
    800026e4:	8526                	mv	a0,s1
    800026e6:	bff9                	j	800026c4 <either_copyin+0x32>

00000000800026e8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026e8:	715d                	addi	sp,sp,-80
    800026ea:	e486                	sd	ra,72(sp)
    800026ec:	e0a2                	sd	s0,64(sp)
    800026ee:	fc26                	sd	s1,56(sp)
    800026f0:	f84a                	sd	s2,48(sp)
    800026f2:	f44e                	sd	s3,40(sp)
    800026f4:	f052                	sd	s4,32(sp)
    800026f6:	ec56                	sd	s5,24(sp)
    800026f8:	e85a                	sd	s6,16(sp)
    800026fa:	e45e                	sd	s7,8(sp)
    800026fc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026fe:	00006517          	auipc	a0,0x6
    80002702:	9ca50513          	addi	a0,a0,-1590 # 800080c8 <digits+0x88>
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	e82080e7          	jalr	-382(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000270e:	00008497          	auipc	s1,0x8
    80002712:	caa48493          	addi	s1,s1,-854 # 8000a3b8 <proc+0x158>
    80002716:	0000e917          	auipc	s2,0xe
    8000271a:	ca290913          	addi	s2,s2,-862 # 800103b8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000271e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002720:	00006997          	auipc	s3,0x6
    80002724:	b6098993          	addi	s3,s3,-1184 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002728:	00006a97          	auipc	s5,0x6
    8000272c:	b60a8a93          	addi	s5,s5,-1184 # 80008288 <digits+0x248>
    printf("\n");
    80002730:	00006a17          	auipc	s4,0x6
    80002734:	998a0a13          	addi	s4,s4,-1640 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002738:	00006b97          	auipc	s7,0x6
    8000273c:	c00b8b93          	addi	s7,s7,-1024 # 80008338 <states.1750>
    80002740:	a00d                	j	80002762 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002742:	ed86a583          	lw	a1,-296(a3)
    80002746:	8556                	mv	a0,s5
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	e40080e7          	jalr	-448(ra) # 80000588 <printf>
    printf("\n");
    80002750:	8552                	mv	a0,s4
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	e36080e7          	jalr	-458(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000275a:	18048493          	addi	s1,s1,384
    8000275e:	03248163          	beq	s1,s2,80002780 <procdump+0x98>
    if(p->state == UNUSED)
    80002762:	86a6                	mv	a3,s1
    80002764:	ec04a783          	lw	a5,-320(s1)
    80002768:	dbed                	beqz	a5,8000275a <procdump+0x72>
      state = "???";
    8000276a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000276c:	fcfb6be3          	bltu	s6,a5,80002742 <procdump+0x5a>
    80002770:	1782                	slli	a5,a5,0x20
    80002772:	9381                	srli	a5,a5,0x20
    80002774:	078e                	slli	a5,a5,0x3
    80002776:	97de                	add	a5,a5,s7
    80002778:	6390                	ld	a2,0(a5)
    8000277a:	f661                	bnez	a2,80002742 <procdump+0x5a>
      state = "???";
    8000277c:	864e                	mv	a2,s3
    8000277e:	b7d1                	j	80002742 <procdump+0x5a>
  }
}
    80002780:	60a6                	ld	ra,72(sp)
    80002782:	6406                	ld	s0,64(sp)
    80002784:	74e2                	ld	s1,56(sp)
    80002786:	7942                	ld	s2,48(sp)
    80002788:	79a2                	ld	s3,40(sp)
    8000278a:	7a02                	ld	s4,32(sp)
    8000278c:	6ae2                	ld	s5,24(sp)
    8000278e:	6b42                	ld	s6,16(sp)
    80002790:	6ba2                	ld	s7,8(sp)
    80002792:	6161                	addi	sp,sp,80
    80002794:	8082                	ret

0000000080002796 <pause_system>:

int
pause_system(int seconds)
{
    80002796:	1101                	addi	sp,sp,-32
    80002798:	ec06                	sd	ra,24(sp)
    8000279a:	e822                	sd	s0,16(sp)
    8000279c:	e426                	sd	s1,8(sp)
    8000279e:	1000                	addi	s0,sp,32
    800027a0:	84aa                	mv	s1,a0
  acquire(&tickslock);
    800027a2:	0000e517          	auipc	a0,0xe
    800027a6:	abe50513          	addi	a0,a0,-1346 # 80010260 <tickslock>
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	43a080e7          	jalr	1082(ra) # 80000be4 <acquire>
  unpauseTicks = ticks + (seconds*10);
    800027b2:	0024979b          	slliw	a5,s1,0x2
    800027b6:	9fa5                	addw	a5,a5,s1
    800027b8:	0017979b          	slliw	a5,a5,0x1
    800027bc:	00007717          	auipc	a4,0x7
    800027c0:	89472703          	lw	a4,-1900(a4) # 80009050 <ticks>
    800027c4:	9fb9                	addw	a5,a5,a4
    800027c6:	00007717          	auipc	a4,0x7
    800027ca:	86f72523          	sw	a5,-1942(a4) # 80009030 <unpauseTicks>
  release(&tickslock);
    800027ce:	0000e517          	auipc	a0,0xe
    800027d2:	a9250513          	addi	a0,a0,-1390 # 80010260 <tickslock>
    800027d6:	ffffe097          	auipc	ra,0xffffe
    800027da:	4c2080e7          	jalr	1218(ra) # 80000c98 <release>
  yield();
    800027de:	00000097          	auipc	ra,0x0
    800027e2:	a3c080e7          	jalr	-1476(ra) # 8000221a <yield>
  return 0;
}
    800027e6:	4501                	li	a0,0
    800027e8:	60e2                	ld	ra,24(sp)
    800027ea:	6442                	ld	s0,16(sp)
    800027ec:	64a2                	ld	s1,8(sp)
    800027ee:	6105                	addi	sp,sp,32
    800027f0:	8082                	ret

00000000800027f2 <kill_system>:

int
kill_system(void)
{
    800027f2:	7179                	addi	sp,sp,-48
    800027f4:	f406                	sd	ra,40(sp)
    800027f6:	f022                	sd	s0,32(sp)
    800027f8:	ec26                	sd	s1,24(sp)
    800027fa:	e84a                	sd	s2,16(sp)
    800027fc:	e44e                	sd	s3,8(sp)
    800027fe:	e052                	sd	s4,0(sp)
    80002800:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    80002802:	00008497          	auipc	s1,0x8
    80002806:	a5e48493          	addi	s1,s1,-1442 # 8000a260 <proc>
  {
    if(p->pid != initproc->pid && p->pid != SHELL_PID) //Dont kill shell and init processes
    8000280a:	00007997          	auipc	s3,0x7
    8000280e:	81e98993          	addi	s3,s3,-2018 # 80009028 <initproc>
    80002812:	4a09                	li	s4,2
  for(p = proc; p < &proc[NPROC]; p++)
    80002814:	0000e917          	auipc	s2,0xe
    80002818:	a4c90913          	addi	s2,s2,-1460 # 80010260 <tickslock>
    8000281c:	a809                	j	8000282e <kill_system+0x3c>
    {
      kill(p->pid);
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	da0080e7          	jalr	-608(ra) # 800025be <kill>
  for(p = proc; p < &proc[NPROC]; p++)
    80002826:	18048493          	addi	s1,s1,384
    8000282a:	01248b63          	beq	s1,s2,80002840 <kill_system+0x4e>
    if(p->pid != initproc->pid && p->pid != SHELL_PID) //Dont kill shell and init processes
    8000282e:	5888                	lw	a0,48(s1)
    80002830:	0009b783          	ld	a5,0(s3)
    80002834:	5b9c                	lw	a5,48(a5)
    80002836:	fea788e3          	beq	a5,a0,80002826 <kill_system+0x34>
    8000283a:	ff4506e3          	beq	a0,s4,80002826 <kill_system+0x34>
    8000283e:	b7c5                	j	8000281e <kill_system+0x2c>
    }
  }
  return 0;
}
    80002840:	4501                	li	a0,0
    80002842:	70a2                	ld	ra,40(sp)
    80002844:	7402                	ld	s0,32(sp)
    80002846:	64e2                	ld	s1,24(sp)
    80002848:	6942                	ld	s2,16(sp)
    8000284a:	69a2                	ld	s3,8(sp)
    8000284c:	6a02                	ld	s4,0(sp)
    8000284e:	6145                	addi	sp,sp,48
    80002850:	8082                	ret

0000000080002852 <debug>:

void
debug(void)
{
    80002852:	7179                	addi	sp,sp,-48
    80002854:	f406                	sd	ra,40(sp)
    80002856:	f022                	sd	s0,32(sp)
    80002858:	ec26                	sd	s1,24(sp)
    8000285a:	e84a                	sd	s2,16(sp)
    8000285c:	e44e                	sd	s3,8(sp)
    8000285e:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    80002860:	00008497          	auipc	s1,0x8
    80002864:	b5848493          	addi	s1,s1,-1192 # 8000a3b8 <proc+0x158>
    80002868:	0000e997          	auipc	s3,0xe
    8000286c:	b5098993          	addi	s3,s3,-1200 # 800103b8 <bcache+0x140>
  {
    printf("name - %s    pid - %d\n", p->name, p->pid);
    80002870:	00006917          	auipc	s2,0x6
    80002874:	a2890913          	addi	s2,s2,-1496 # 80008298 <digits+0x258>
    80002878:	ed84a603          	lw	a2,-296(s1)
    8000287c:	85a6                	mv	a1,s1
    8000287e:	854a                	mv	a0,s2
    80002880:	ffffe097          	auipc	ra,0xffffe
    80002884:	d08080e7          	jalr	-760(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++)
    80002888:	18048493          	addi	s1,s1,384
    8000288c:	ff3496e3          	bne	s1,s3,80002878 <debug+0x26>
  }

}
    80002890:	70a2                	ld	ra,40(sp)
    80002892:	7402                	ld	s0,32(sp)
    80002894:	64e2                	ld	s1,24(sp)
    80002896:	6942                	ld	s2,16(sp)
    80002898:	69a2                	ld	s3,8(sp)
    8000289a:	6145                	addi	sp,sp,48
    8000289c:	8082                	ret

000000008000289e <print_stats>:

void
print_stats(void)
{
    8000289e:	1141                	addi	sp,sp,-16
    800028a0:	e406                	sd	ra,8(sp)
    800028a2:	e022                	sd	s0,0(sp)
    800028a4:	0800                	addi	s0,sp,16
  printf("%s : %d\n", "Mean Sleeping", sleeping_processes_mean);
    800028a6:	00006617          	auipc	a2,0x6
    800028aa:	7a662603          	lw	a2,1958(a2) # 8000904c <sleeping_processes_mean>
    800028ae:	00006597          	auipc	a1,0x6
    800028b2:	a0258593          	addi	a1,a1,-1534 # 800082b0 <digits+0x270>
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	a0a50513          	addi	a0,a0,-1526 # 800082c0 <digits+0x280>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	cca080e7          	jalr	-822(ra) # 80000588 <printf>
  printf("%s : %d\n", "Mean Running", running_processes_mean);
    800028c6:	00006617          	auipc	a2,0x6
    800028ca:	78262603          	lw	a2,1922(a2) # 80009048 <running_processes_mean>
    800028ce:	00006597          	auipc	a1,0x6
    800028d2:	a0258593          	addi	a1,a1,-1534 # 800082d0 <digits+0x290>
    800028d6:	00006517          	auipc	a0,0x6
    800028da:	9ea50513          	addi	a0,a0,-1558 # 800082c0 <digits+0x280>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	caa080e7          	jalr	-854(ra) # 80000588 <printf>
  printf("%s : %d\n", "Mean Runnable", runnable_time_mean);
    800028e6:	00006617          	auipc	a2,0x6
    800028ea:	75e62603          	lw	a2,1886(a2) # 80009044 <runnable_time_mean>
    800028ee:	00006597          	auipc	a1,0x6
    800028f2:	9f258593          	addi	a1,a1,-1550 # 800082e0 <digits+0x2a0>
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	9ca50513          	addi	a0,a0,-1590 # 800082c0 <digits+0x280>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c8a080e7          	jalr	-886(ra) # 80000588 <printf>
  printf("%s : %d\n", "Program TIme", program_time);
    80002906:	00006617          	auipc	a2,0x6
    8000290a:	73a62603          	lw	a2,1850(a2) # 80009040 <program_time>
    8000290e:	00006597          	auipc	a1,0x6
    80002912:	9e258593          	addi	a1,a1,-1566 # 800082f0 <digits+0x2b0>
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	9aa50513          	addi	a0,a0,-1622 # 800082c0 <digits+0x280>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c6a080e7          	jalr	-918(ra) # 80000588 <printf>
  printf("%s : %d\n", "Cpu Utilization", cpu_utilization);
    80002926:	00006617          	auipc	a2,0x6
    8000292a:	70e62603          	lw	a2,1806(a2) # 80009034 <cpu_utilization>
    8000292e:	00006597          	auipc	a1,0x6
    80002932:	9d258593          	addi	a1,a1,-1582 # 80008300 <digits+0x2c0>
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	98a50513          	addi	a0,a0,-1654 # 800082c0 <digits+0x280>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c4a080e7          	jalr	-950(ra) # 80000588 <printf>
}
    80002946:	60a2                	ld	ra,8(sp)
    80002948:	6402                	ld	s0,0(sp)
    8000294a:	0141                	addi	sp,sp,16
    8000294c:	8082                	ret

000000008000294e <get_utilization>:

int get_utilization(void)
{
    8000294e:	1141                	addi	sp,sp,-16
    80002950:	e422                	sd	s0,8(sp)
    80002952:	0800                	addi	s0,sp,16
  return cpu_utilization;
}
    80002954:	00006517          	auipc	a0,0x6
    80002958:	6e052503          	lw	a0,1760(a0) # 80009034 <cpu_utilization>
    8000295c:	6422                	ld	s0,8(sp)
    8000295e:	0141                	addi	sp,sp,16
    80002960:	8082                	ret

0000000080002962 <swtch>:
    80002962:	00153023          	sd	ra,0(a0)
    80002966:	00253423          	sd	sp,8(a0)
    8000296a:	e900                	sd	s0,16(a0)
    8000296c:	ed04                	sd	s1,24(a0)
    8000296e:	03253023          	sd	s2,32(a0)
    80002972:	03353423          	sd	s3,40(a0)
    80002976:	03453823          	sd	s4,48(a0)
    8000297a:	03553c23          	sd	s5,56(a0)
    8000297e:	05653023          	sd	s6,64(a0)
    80002982:	05753423          	sd	s7,72(a0)
    80002986:	05853823          	sd	s8,80(a0)
    8000298a:	05953c23          	sd	s9,88(a0)
    8000298e:	07a53023          	sd	s10,96(a0)
    80002992:	07b53423          	sd	s11,104(a0)
    80002996:	0005b083          	ld	ra,0(a1)
    8000299a:	0085b103          	ld	sp,8(a1)
    8000299e:	6980                	ld	s0,16(a1)
    800029a0:	6d84                	ld	s1,24(a1)
    800029a2:	0205b903          	ld	s2,32(a1)
    800029a6:	0285b983          	ld	s3,40(a1)
    800029aa:	0305ba03          	ld	s4,48(a1)
    800029ae:	0385ba83          	ld	s5,56(a1)
    800029b2:	0405bb03          	ld	s6,64(a1)
    800029b6:	0485bb83          	ld	s7,72(a1)
    800029ba:	0505bc03          	ld	s8,80(a1)
    800029be:	0585bc83          	ld	s9,88(a1)
    800029c2:	0605bd03          	ld	s10,96(a1)
    800029c6:	0685bd83          	ld	s11,104(a1)
    800029ca:	8082                	ret

00000000800029cc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029cc:	1141                	addi	sp,sp,-16
    800029ce:	e406                	sd	ra,8(sp)
    800029d0:	e022                	sd	s0,0(sp)
    800029d2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029d4:	00006597          	auipc	a1,0x6
    800029d8:	99458593          	addi	a1,a1,-1644 # 80008368 <states.1750+0x30>
    800029dc:	0000e517          	auipc	a0,0xe
    800029e0:	88450513          	addi	a0,a0,-1916 # 80010260 <tickslock>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	170080e7          	jalr	368(ra) # 80000b54 <initlock>
}
    800029ec:	60a2                	ld	ra,8(sp)
    800029ee:	6402                	ld	s0,0(sp)
    800029f0:	0141                	addi	sp,sp,16
    800029f2:	8082                	ret

00000000800029f4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029f4:	1141                	addi	sp,sp,-16
    800029f6:	e422                	sd	s0,8(sp)
    800029f8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fa:	00003797          	auipc	a5,0x3
    800029fe:	51678793          	addi	a5,a5,1302 # 80005f10 <kernelvec>
    80002a02:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a06:	6422                	ld	s0,8(sp)
    80002a08:	0141                	addi	sp,sp,16
    80002a0a:	8082                	ret

0000000080002a0c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a0c:	1141                	addi	sp,sp,-16
    80002a0e:	e406                	sd	ra,8(sp)
    80002a10:	e022                	sd	s0,0(sp)
    80002a12:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a14:	fffff097          	auipc	ra,0xfffff
    80002a18:	034080e7          	jalr	52(ra) # 80001a48 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a22:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a26:	00004617          	auipc	a2,0x4
    80002a2a:	5da60613          	addi	a2,a2,1498 # 80007000 <_trampoline>
    80002a2e:	00004697          	auipc	a3,0x4
    80002a32:	5d268693          	addi	a3,a3,1490 # 80007000 <_trampoline>
    80002a36:	8e91                	sub	a3,a3,a2
    80002a38:	040007b7          	lui	a5,0x4000
    80002a3c:	17fd                	addi	a5,a5,-1
    80002a3e:	07b2                	slli	a5,a5,0xc
    80002a40:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a42:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a46:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a48:	180026f3          	csrr	a3,satp
    80002a4c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a4e:	6d38                	ld	a4,88(a0)
    80002a50:	6134                	ld	a3,64(a0)
    80002a52:	6585                	lui	a1,0x1
    80002a54:	96ae                	add	a3,a3,a1
    80002a56:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a58:	6d38                	ld	a4,88(a0)
    80002a5a:	00000697          	auipc	a3,0x0
    80002a5e:	14668693          	addi	a3,a3,326 # 80002ba0 <usertrap>
    80002a62:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a64:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a66:	8692                	mv	a3,tp
    80002a68:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a6a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a6e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a72:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a76:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a7a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a7c:	6f18                	ld	a4,24(a4)
    80002a7e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a82:	692c                	ld	a1,80(a0)
    80002a84:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a86:	00004717          	auipc	a4,0x4
    80002a8a:	60a70713          	addi	a4,a4,1546 # 80007090 <userret>
    80002a8e:	8f11                	sub	a4,a4,a2
    80002a90:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a92:	577d                	li	a4,-1
    80002a94:	177e                	slli	a4,a4,0x3f
    80002a96:	8dd9                	or	a1,a1,a4
    80002a98:	02000537          	lui	a0,0x2000
    80002a9c:	157d                	addi	a0,a0,-1
    80002a9e:	0536                	slli	a0,a0,0xd
    80002aa0:	9782                	jalr	a5
}
    80002aa2:	60a2                	ld	ra,8(sp)
    80002aa4:	6402                	ld	s0,0(sp)
    80002aa6:	0141                	addi	sp,sp,16
    80002aa8:	8082                	ret

0000000080002aaa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002aaa:	1101                	addi	sp,sp,-32
    80002aac:	ec06                	sd	ra,24(sp)
    80002aae:	e822                	sd	s0,16(sp)
    80002ab0:	e426                	sd	s1,8(sp)
    80002ab2:	e04a                	sd	s2,0(sp)
    80002ab4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ab6:	0000d917          	auipc	s2,0xd
    80002aba:	7aa90913          	addi	s2,s2,1962 # 80010260 <tickslock>
    80002abe:	854a                	mv	a0,s2
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	124080e7          	jalr	292(ra) # 80000be4 <acquire>
  ticks++;
    80002ac8:	00006497          	auipc	s1,0x6
    80002acc:	58848493          	addi	s1,s1,1416 # 80009050 <ticks>
    80002ad0:	409c                	lw	a5,0(s1)
    80002ad2:	2785                	addiw	a5,a5,1
    80002ad4:	c09c                	sw	a5,0(s1)
  updateAllProcsStats();
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	d68080e7          	jalr	-664(ra) # 8000183e <updateAllProcsStats>
  wakeup(&ticks);
    80002ade:	8526                	mv	a0,s1
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	90e080e7          	jalr	-1778(ra) # 800023ee <wakeup>
  release(&tickslock);
    80002ae8:	854a                	mv	a0,s2
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	1ae080e7          	jalr	430(ra) # 80000c98 <release>
}
    80002af2:	60e2                	ld	ra,24(sp)
    80002af4:	6442                	ld	s0,16(sp)
    80002af6:	64a2                	ld	s1,8(sp)
    80002af8:	6902                	ld	s2,0(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret

0000000080002afe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b08:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b0c:	00074d63          	bltz	a4,80002b26 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b10:	57fd                	li	a5,-1
    80002b12:	17fe                	slli	a5,a5,0x3f
    80002b14:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b16:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b18:	06f70363          	beq	a4,a5,80002b7e <devintr+0x80>
  }
}
    80002b1c:	60e2                	ld	ra,24(sp)
    80002b1e:	6442                	ld	s0,16(sp)
    80002b20:	64a2                	ld	s1,8(sp)
    80002b22:	6105                	addi	sp,sp,32
    80002b24:	8082                	ret
     (scause & 0xff) == 9){
    80002b26:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b2a:	46a5                	li	a3,9
    80002b2c:	fed792e3          	bne	a5,a3,80002b10 <devintr+0x12>
    int irq = plic_claim();
    80002b30:	00003097          	auipc	ra,0x3
    80002b34:	4e8080e7          	jalr	1256(ra) # 80006018 <plic_claim>
    80002b38:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b3a:	47a9                	li	a5,10
    80002b3c:	02f50763          	beq	a0,a5,80002b6a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b40:	4785                	li	a5,1
    80002b42:	02f50963          	beq	a0,a5,80002b74 <devintr+0x76>
    return 1;
    80002b46:	4505                	li	a0,1
    } else if(irq){
    80002b48:	d8f1                	beqz	s1,80002b1c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b4a:	85a6                	mv	a1,s1
    80002b4c:	00006517          	auipc	a0,0x6
    80002b50:	82450513          	addi	a0,a0,-2012 # 80008370 <states.1750+0x38>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	a34080e7          	jalr	-1484(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b5c:	8526                	mv	a0,s1
    80002b5e:	00003097          	auipc	ra,0x3
    80002b62:	4de080e7          	jalr	1246(ra) # 8000603c <plic_complete>
    return 1;
    80002b66:	4505                	li	a0,1
    80002b68:	bf55                	j	80002b1c <devintr+0x1e>
      uartintr();
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	e3e080e7          	jalr	-450(ra) # 800009a8 <uartintr>
    80002b72:	b7ed                	j	80002b5c <devintr+0x5e>
      virtio_disk_intr();
    80002b74:	00004097          	auipc	ra,0x4
    80002b78:	9a8080e7          	jalr	-1624(ra) # 8000651c <virtio_disk_intr>
    80002b7c:	b7c5                	j	80002b5c <devintr+0x5e>
    if(cpuid() == 0){
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	e9e080e7          	jalr	-354(ra) # 80001a1c <cpuid>
    80002b86:	c901                	beqz	a0,80002b96 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b88:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b8e:	14479073          	csrw	sip,a5
    return 2;
    80002b92:	4509                	li	a0,2
    80002b94:	b761                	j	80002b1c <devintr+0x1e>
      clockintr();
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	f14080e7          	jalr	-236(ra) # 80002aaa <clockintr>
    80002b9e:	b7ed                	j	80002b88 <devintr+0x8a>

0000000080002ba0 <usertrap>:
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	e04a                	sd	s2,0(sp)
    80002baa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bac:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bb0:	1007f793          	andi	a5,a5,256
    80002bb4:	e3ad                	bnez	a5,80002c16 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb6:	00003797          	auipc	a5,0x3
    80002bba:	35a78793          	addi	a5,a5,858 # 80005f10 <kernelvec>
    80002bbe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	e86080e7          	jalr	-378(ra) # 80001a48 <myproc>
    80002bca:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bcc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bce:	14102773          	csrr	a4,sepc
    80002bd2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bd8:	47a1                	li	a5,8
    80002bda:	04f71c63          	bne	a4,a5,80002c32 <usertrap+0x92>
    if(p->killed)
    80002bde:	551c                	lw	a5,40(a0)
    80002be0:	e3b9                	bnez	a5,80002c26 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002be2:	6cb8                	ld	a4,88(s1)
    80002be4:	6f1c                	ld	a5,24(a4)
    80002be6:	0791                	addi	a5,a5,4
    80002be8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf2:	10079073          	csrw	sstatus,a5
    syscall();
    80002bf6:	00000097          	auipc	ra,0x0
    80002bfa:	2e0080e7          	jalr	736(ra) # 80002ed6 <syscall>
  if(p->killed)
    80002bfe:	549c                	lw	a5,40(s1)
    80002c00:	ebc1                	bnez	a5,80002c90 <usertrap+0xf0>
  usertrapret();
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	e0a080e7          	jalr	-502(ra) # 80002a0c <usertrapret>
}
    80002c0a:	60e2                	ld	ra,24(sp)
    80002c0c:	6442                	ld	s0,16(sp)
    80002c0e:	64a2                	ld	s1,8(sp)
    80002c10:	6902                	ld	s2,0(sp)
    80002c12:	6105                	addi	sp,sp,32
    80002c14:	8082                	ret
    panic("usertrap: not from user mode");
    80002c16:	00005517          	auipc	a0,0x5
    80002c1a:	77a50513          	addi	a0,a0,1914 # 80008390 <states.1750+0x58>
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	920080e7          	jalr	-1760(ra) # 8000053e <panic>
      exit(-1);
    80002c26:	557d                	li	a0,-1
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	8aa080e7          	jalr	-1878(ra) # 800024d2 <exit>
    80002c30:	bf4d                	j	80002be2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	ecc080e7          	jalr	-308(ra) # 80002afe <devintr>
    80002c3a:	892a                	mv	s2,a0
    80002c3c:	c501                	beqz	a0,80002c44 <usertrap+0xa4>
  if(p->killed)
    80002c3e:	549c                	lw	a5,40(s1)
    80002c40:	c3a1                	beqz	a5,80002c80 <usertrap+0xe0>
    80002c42:	a815                	j	80002c76 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c44:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c48:	5890                	lw	a2,48(s1)
    80002c4a:	00005517          	auipc	a0,0x5
    80002c4e:	76650513          	addi	a0,a0,1894 # 800083b0 <states.1750+0x78>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	936080e7          	jalr	-1738(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c5e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	77e50513          	addi	a0,a0,1918 # 800083e0 <states.1750+0xa8>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	91e080e7          	jalr	-1762(ra) # 80000588 <printf>
    p->killed = 1;
    80002c72:	4785                	li	a5,1
    80002c74:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c76:	557d                	li	a0,-1
    80002c78:	00000097          	auipc	ra,0x0
    80002c7c:	85a080e7          	jalr	-1958(ra) # 800024d2 <exit>
  if(which_dev == 2)
    80002c80:	4789                	li	a5,2
    80002c82:	f8f910e3          	bne	s2,a5,80002c02 <usertrap+0x62>
    yield();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	594080e7          	jalr	1428(ra) # 8000221a <yield>
    80002c8e:	bf95                	j	80002c02 <usertrap+0x62>
  int which_dev = 0;
    80002c90:	4901                	li	s2,0
    80002c92:	b7d5                	j	80002c76 <usertrap+0xd6>

0000000080002c94 <kerneltrap>:
{
    80002c94:	7179                	addi	sp,sp,-48
    80002c96:	f406                	sd	ra,40(sp)
    80002c98:	f022                	sd	s0,32(sp)
    80002c9a:	ec26                	sd	s1,24(sp)
    80002c9c:	e84a                	sd	s2,16(sp)
    80002c9e:	e44e                	sd	s3,8(sp)
    80002ca0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002caa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cae:	1004f793          	andi	a5,s1,256
    80002cb2:	cb85                	beqz	a5,80002ce2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cb8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cba:	ef85                	bnez	a5,80002cf2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	e42080e7          	jalr	-446(ra) # 80002afe <devintr>
    80002cc4:	cd1d                	beqz	a0,80002d02 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc6:	4789                	li	a5,2
    80002cc8:	06f50a63          	beq	a0,a5,80002d3c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ccc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd0:	10049073          	csrw	sstatus,s1
}
    80002cd4:	70a2                	ld	ra,40(sp)
    80002cd6:	7402                	ld	s0,32(sp)
    80002cd8:	64e2                	ld	s1,24(sp)
    80002cda:	6942                	ld	s2,16(sp)
    80002cdc:	69a2                	ld	s3,8(sp)
    80002cde:	6145                	addi	sp,sp,48
    80002ce0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	71e50513          	addi	a0,a0,1822 # 80008400 <states.1750+0xc8>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	73650513          	addi	a0,a0,1846 # 80008428 <states.1750+0xf0>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002d02:	85ce                	mv	a1,s3
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	74450513          	addi	a0,a0,1860 # 80008448 <states.1750+0x110>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	87c080e7          	jalr	-1924(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	73c50513          	addi	a0,a0,1852 # 80008458 <states.1750+0x120>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	864080e7          	jalr	-1948(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d2c:	00005517          	auipc	a0,0x5
    80002d30:	74450513          	addi	a0,a0,1860 # 80008470 <states.1750+0x138>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	80a080e7          	jalr	-2038(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	d0c080e7          	jalr	-756(ra) # 80001a48 <myproc>
    80002d44:	d541                	beqz	a0,80002ccc <kerneltrap+0x38>
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	d02080e7          	jalr	-766(ra) # 80001a48 <myproc>
    80002d4e:	4d18                	lw	a4,24(a0)
    80002d50:	4791                	li	a5,4
    80002d52:	f6f71de3          	bne	a4,a5,80002ccc <kerneltrap+0x38>
    yield();
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	4c4080e7          	jalr	1220(ra) # 8000221a <yield>
    80002d5e:	b7bd                	j	80002ccc <kerneltrap+0x38>

0000000080002d60 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d60:	1101                	addi	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	1000                	addi	s0,sp,32
    80002d6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	cdc080e7          	jalr	-804(ra) # 80001a48 <myproc>
  switch (n) {
    80002d74:	4795                	li	a5,5
    80002d76:	0497e163          	bltu	a5,s1,80002db8 <argraw+0x58>
    80002d7a:	048a                	slli	s1,s1,0x2
    80002d7c:	00005717          	auipc	a4,0x5
    80002d80:	72c70713          	addi	a4,a4,1836 # 800084a8 <states.1750+0x170>
    80002d84:	94ba                	add	s1,s1,a4
    80002d86:	409c                	lw	a5,0(s1)
    80002d88:	97ba                	add	a5,a5,a4
    80002d8a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d8c:	6d3c                	ld	a5,88(a0)
    80002d8e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d90:	60e2                	ld	ra,24(sp)
    80002d92:	6442                	ld	s0,16(sp)
    80002d94:	64a2                	ld	s1,8(sp)
    80002d96:	6105                	addi	sp,sp,32
    80002d98:	8082                	ret
    return p->trapframe->a1;
    80002d9a:	6d3c                	ld	a5,88(a0)
    80002d9c:	7fa8                	ld	a0,120(a5)
    80002d9e:	bfcd                	j	80002d90 <argraw+0x30>
    return p->trapframe->a2;
    80002da0:	6d3c                	ld	a5,88(a0)
    80002da2:	63c8                	ld	a0,128(a5)
    80002da4:	b7f5                	j	80002d90 <argraw+0x30>
    return p->trapframe->a3;
    80002da6:	6d3c                	ld	a5,88(a0)
    80002da8:	67c8                	ld	a0,136(a5)
    80002daa:	b7dd                	j	80002d90 <argraw+0x30>
    return p->trapframe->a4;
    80002dac:	6d3c                	ld	a5,88(a0)
    80002dae:	6bc8                	ld	a0,144(a5)
    80002db0:	b7c5                	j	80002d90 <argraw+0x30>
    return p->trapframe->a5;
    80002db2:	6d3c                	ld	a5,88(a0)
    80002db4:	6fc8                	ld	a0,152(a5)
    80002db6:	bfe9                	j	80002d90 <argraw+0x30>
  panic("argraw");
    80002db8:	00005517          	auipc	a0,0x5
    80002dbc:	6c850513          	addi	a0,a0,1736 # 80008480 <states.1750+0x148>
    80002dc0:	ffffd097          	auipc	ra,0xffffd
    80002dc4:	77e080e7          	jalr	1918(ra) # 8000053e <panic>

0000000080002dc8 <fetchaddr>:
{
    80002dc8:	1101                	addi	sp,sp,-32
    80002dca:	ec06                	sd	ra,24(sp)
    80002dcc:	e822                	sd	s0,16(sp)
    80002dce:	e426                	sd	s1,8(sp)
    80002dd0:	e04a                	sd	s2,0(sp)
    80002dd2:	1000                	addi	s0,sp,32
    80002dd4:	84aa                	mv	s1,a0
    80002dd6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	c70080e7          	jalr	-912(ra) # 80001a48 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002de0:	653c                	ld	a5,72(a0)
    80002de2:	02f4f863          	bgeu	s1,a5,80002e12 <fetchaddr+0x4a>
    80002de6:	00848713          	addi	a4,s1,8
    80002dea:	02e7e663          	bltu	a5,a4,80002e16 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dee:	46a1                	li	a3,8
    80002df0:	8626                	mv	a2,s1
    80002df2:	85ca                	mv	a1,s2
    80002df4:	6928                	ld	a0,80(a0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	908080e7          	jalr	-1784(ra) # 800016fe <copyin>
    80002dfe:	00a03533          	snez	a0,a0
    80002e02:	40a00533          	neg	a0,a0
}
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	64a2                	ld	s1,8(sp)
    80002e0c:	6902                	ld	s2,0(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret
    return -1;
    80002e12:	557d                	li	a0,-1
    80002e14:	bfcd                	j	80002e06 <fetchaddr+0x3e>
    80002e16:	557d                	li	a0,-1
    80002e18:	b7fd                	j	80002e06 <fetchaddr+0x3e>

0000000080002e1a <fetchstr>:
{
    80002e1a:	7179                	addi	sp,sp,-48
    80002e1c:	f406                	sd	ra,40(sp)
    80002e1e:	f022                	sd	s0,32(sp)
    80002e20:	ec26                	sd	s1,24(sp)
    80002e22:	e84a                	sd	s2,16(sp)
    80002e24:	e44e                	sd	s3,8(sp)
    80002e26:	1800                	addi	s0,sp,48
    80002e28:	892a                	mv	s2,a0
    80002e2a:	84ae                	mv	s1,a1
    80002e2c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	c1a080e7          	jalr	-998(ra) # 80001a48 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e36:	86ce                	mv	a3,s3
    80002e38:	864a                	mv	a2,s2
    80002e3a:	85a6                	mv	a1,s1
    80002e3c:	6928                	ld	a0,80(a0)
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	94c080e7          	jalr	-1716(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002e46:	00054763          	bltz	a0,80002e54 <fetchstr+0x3a>
  return strlen(buf);
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	018080e7          	jalr	24(ra) # 80000e64 <strlen>
}
    80002e54:	70a2                	ld	ra,40(sp)
    80002e56:	7402                	ld	s0,32(sp)
    80002e58:	64e2                	ld	s1,24(sp)
    80002e5a:	6942                	ld	s2,16(sp)
    80002e5c:	69a2                	ld	s3,8(sp)
    80002e5e:	6145                	addi	sp,sp,48
    80002e60:	8082                	ret

0000000080002e62 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	e426                	sd	s1,8(sp)
    80002e6a:	1000                	addi	s0,sp,32
    80002e6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	ef2080e7          	jalr	-270(ra) # 80002d60 <argraw>
    80002e76:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e78:	4501                	li	a0,0
    80002e7a:	60e2                	ld	ra,24(sp)
    80002e7c:	6442                	ld	s0,16(sp)
    80002e7e:	64a2                	ld	s1,8(sp)
    80002e80:	6105                	addi	sp,sp,32
    80002e82:	8082                	ret

0000000080002e84 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	e426                	sd	s1,8(sp)
    80002e8c:	1000                	addi	s0,sp,32
    80002e8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	ed0080e7          	jalr	-304(ra) # 80002d60 <argraw>
    80002e98:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e9a:	4501                	li	a0,0
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	64a2                	ld	s1,8(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret

0000000080002ea6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	e426                	sd	s1,8(sp)
    80002eae:	e04a                	sd	s2,0(sp)
    80002eb0:	1000                	addi	s0,sp,32
    80002eb2:	84ae                	mv	s1,a1
    80002eb4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	eaa080e7          	jalr	-342(ra) # 80002d60 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ebe:	864a                	mv	a2,s2
    80002ec0:	85a6                	mv	a1,s1
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	f58080e7          	jalr	-168(ra) # 80002e1a <fetchstr>
}
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	64a2                	ld	s1,8(sp)
    80002ed0:	6902                	ld	s2,0(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret

0000000080002ed6 <syscall>:
[SYS_print_stats] sys_print_stats,
};

void
syscall(void)
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	e426                	sd	s1,8(sp)
    80002ede:	e04a                	sd	s2,0(sp)
    80002ee0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ee2:	fffff097          	auipc	ra,0xfffff
    80002ee6:	b66080e7          	jalr	-1178(ra) # 80001a48 <myproc>
    80002eea:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002eec:	05853903          	ld	s2,88(a0)
    80002ef0:	0a893783          	ld	a5,168(s2)
    80002ef4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ef8:	37fd                	addiw	a5,a5,-1
    80002efa:	4761                	li	a4,24
    80002efc:	00f76f63          	bltu	a4,a5,80002f1a <syscall+0x44>
    80002f00:	00369713          	slli	a4,a3,0x3
    80002f04:	00005797          	auipc	a5,0x5
    80002f08:	5bc78793          	addi	a5,a5,1468 # 800084c0 <syscalls>
    80002f0c:	97ba                	add	a5,a5,a4
    80002f0e:	639c                	ld	a5,0(a5)
    80002f10:	c789                	beqz	a5,80002f1a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f12:	9782                	jalr	a5
    80002f14:	06a93823          	sd	a0,112(s2)
    80002f18:	a839                	j	80002f36 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f1a:	15848613          	addi	a2,s1,344
    80002f1e:	588c                	lw	a1,48(s1)
    80002f20:	00005517          	auipc	a0,0x5
    80002f24:	56850513          	addi	a0,a0,1384 # 80008488 <states.1750+0x150>
    80002f28:	ffffd097          	auipc	ra,0xffffd
    80002f2c:	660080e7          	jalr	1632(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f30:	6cbc                	ld	a5,88(s1)
    80002f32:	577d                	li	a4,-1
    80002f34:	fbb8                	sd	a4,112(a5)
  }
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	64a2                	ld	s1,8(sp)
    80002f3c:	6902                	ld	s2,0(sp)
    80002f3e:	6105                	addi	sp,sp,32
    80002f40:	8082                	ret

0000000080002f42 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f42:	1101                	addi	sp,sp,-32
    80002f44:	ec06                	sd	ra,24(sp)
    80002f46:	e822                	sd	s0,16(sp)
    80002f48:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f4a:	fec40593          	addi	a1,s0,-20
    80002f4e:	4501                	li	a0,0
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	f12080e7          	jalr	-238(ra) # 80002e62 <argint>
    return -1;
    80002f58:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f5a:	00054963          	bltz	a0,80002f6c <sys_exit+0x2a>
  exit(n);
    80002f5e:	fec42503          	lw	a0,-20(s0)
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	570080e7          	jalr	1392(ra) # 800024d2 <exit>
  return 0;  // not reached
    80002f6a:	4781                	li	a5,0
}
    80002f6c:	853e                	mv	a0,a5
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	6105                	addi	sp,sp,32
    80002f74:	8082                	ret

0000000080002f76 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f76:	1141                	addi	sp,sp,-16
    80002f78:	e406                	sd	ra,8(sp)
    80002f7a:	e022                	sd	s0,0(sp)
    80002f7c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	aca080e7          	jalr	-1334(ra) # 80001a48 <myproc>
}
    80002f86:	5908                	lw	a0,48(a0)
    80002f88:	60a2                	ld	ra,8(sp)
    80002f8a:	6402                	ld	s0,0(sp)
    80002f8c:	0141                	addi	sp,sp,16
    80002f8e:	8082                	ret

0000000080002f90 <sys_fork>:

uint64
sys_fork(void)
{
    80002f90:	1141                	addi	sp,sp,-16
    80002f92:	e406                	sd	ra,8(sp)
    80002f94:	e022                	sd	s0,0(sp)
    80002f96:	0800                	addi	s0,sp,16
  return fork();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	e92080e7          	jalr	-366(ra) # 80001e2a <fork>
}
    80002fa0:	60a2                	ld	ra,8(sp)
    80002fa2:	6402                	ld	s0,0(sp)
    80002fa4:	0141                	addi	sp,sp,16
    80002fa6:	8082                	ret

0000000080002fa8 <sys_wait>:

uint64
sys_wait(void)
{
    80002fa8:	1101                	addi	sp,sp,-32
    80002faa:	ec06                	sd	ra,24(sp)
    80002fac:	e822                	sd	s0,16(sp)
    80002fae:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fb0:	fe840593          	addi	a1,s0,-24
    80002fb4:	4501                	li	a0,0
    80002fb6:	00000097          	auipc	ra,0x0
    80002fba:	ece080e7          	jalr	-306(ra) # 80002e84 <argaddr>
    80002fbe:	87aa                	mv	a5,a0
    return -1;
    80002fc0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fc2:	0007c863          	bltz	a5,80002fd2 <sys_wait+0x2a>
  return wait(p);
    80002fc6:	fe843503          	ld	a0,-24(s0)
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	2fc080e7          	jalr	764(ra) # 800022c6 <wait>
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fda:	7179                	addi	sp,sp,-48
    80002fdc:	f406                	sd	ra,40(sp)
    80002fde:	f022                	sd	s0,32(sp)
    80002fe0:	ec26                	sd	s1,24(sp)
    80002fe2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fe4:	fdc40593          	addi	a1,s0,-36
    80002fe8:	4501                	li	a0,0
    80002fea:	00000097          	auipc	ra,0x0
    80002fee:	e78080e7          	jalr	-392(ra) # 80002e62 <argint>
    80002ff2:	87aa                	mv	a5,a0
    return -1;
    80002ff4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ff6:	0207c063          	bltz	a5,80003016 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	a4e080e7          	jalr	-1458(ra) # 80001a48 <myproc>
    80003002:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003004:	fdc42503          	lw	a0,-36(s0)
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	dae080e7          	jalr	-594(ra) # 80001db6 <growproc>
    80003010:	00054863          	bltz	a0,80003020 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003014:	8526                	mv	a0,s1
}
    80003016:	70a2                	ld	ra,40(sp)
    80003018:	7402                	ld	s0,32(sp)
    8000301a:	64e2                	ld	s1,24(sp)
    8000301c:	6145                	addi	sp,sp,48
    8000301e:	8082                	ret
    return -1;
    80003020:	557d                	li	a0,-1
    80003022:	bfd5                	j	80003016 <sys_sbrk+0x3c>

0000000080003024 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003024:	7139                	addi	sp,sp,-64
    80003026:	fc06                	sd	ra,56(sp)
    80003028:	f822                	sd	s0,48(sp)
    8000302a:	f426                	sd	s1,40(sp)
    8000302c:	f04a                	sd	s2,32(sp)
    8000302e:	ec4e                	sd	s3,24(sp)
    80003030:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003032:	fcc40593          	addi	a1,s0,-52
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	e2a080e7          	jalr	-470(ra) # 80002e62 <argint>
    return -1;
    80003040:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003042:	06054563          	bltz	a0,800030ac <sys_sleep+0x88>
  acquire(&tickslock);
    80003046:	0000d517          	auipc	a0,0xd
    8000304a:	21a50513          	addi	a0,a0,538 # 80010260 <tickslock>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	b96080e7          	jalr	-1130(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003056:	00006917          	auipc	s2,0x6
    8000305a:	ffa92903          	lw	s2,-6(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    8000305e:	fcc42783          	lw	a5,-52(s0)
    80003062:	cf85                	beqz	a5,8000309a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003064:	0000d997          	auipc	s3,0xd
    80003068:	1fc98993          	addi	s3,s3,508 # 80010260 <tickslock>
    8000306c:	00006497          	auipc	s1,0x6
    80003070:	fe448493          	addi	s1,s1,-28 # 80009050 <ticks>
    if(myproc()->killed){
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	9d4080e7          	jalr	-1580(ra) # 80001a48 <myproc>
    8000307c:	551c                	lw	a5,40(a0)
    8000307e:	ef9d                	bnez	a5,800030bc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003080:	85ce                	mv	a1,s3
    80003082:	8526                	mv	a0,s1
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	1de080e7          	jalr	478(ra) # 80002262 <sleep>
  while(ticks - ticks0 < n){
    8000308c:	409c                	lw	a5,0(s1)
    8000308e:	412787bb          	subw	a5,a5,s2
    80003092:	fcc42703          	lw	a4,-52(s0)
    80003096:	fce7efe3          	bltu	a5,a4,80003074 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000309a:	0000d517          	auipc	a0,0xd
    8000309e:	1c650513          	addi	a0,a0,454 # 80010260 <tickslock>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	bf6080e7          	jalr	-1034(ra) # 80000c98 <release>
  return 0;
    800030aa:	4781                	li	a5,0
}
    800030ac:	853e                	mv	a0,a5
    800030ae:	70e2                	ld	ra,56(sp)
    800030b0:	7442                	ld	s0,48(sp)
    800030b2:	74a2                	ld	s1,40(sp)
    800030b4:	7902                	ld	s2,32(sp)
    800030b6:	69e2                	ld	s3,24(sp)
    800030b8:	6121                	addi	sp,sp,64
    800030ba:	8082                	ret
      release(&tickslock);
    800030bc:	0000d517          	auipc	a0,0xd
    800030c0:	1a450513          	addi	a0,a0,420 # 80010260 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bd4080e7          	jalr	-1068(ra) # 80000c98 <release>
      return -1;
    800030cc:	57fd                	li	a5,-1
    800030ce:	bff9                	j	800030ac <sys_sleep+0x88>

00000000800030d0 <sys_kill>:

uint64
sys_kill(void)
{
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030d8:	fec40593          	addi	a1,s0,-20
    800030dc:	4501                	li	a0,0
    800030de:	00000097          	auipc	ra,0x0
    800030e2:	d84080e7          	jalr	-636(ra) # 80002e62 <argint>
    800030e6:	87aa                	mv	a5,a0
    return -1;
    800030e8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030ea:	0007c863          	bltz	a5,800030fa <sys_kill+0x2a>
  return kill(pid);
    800030ee:	fec42503          	lw	a0,-20(s0)
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	4cc080e7          	jalr	1228(ra) # 800025be <kill>
}
    800030fa:	60e2                	ld	ra,24(sp)
    800030fc:	6442                	ld	s0,16(sp)
    800030fe:	6105                	addi	sp,sp,32
    80003100:	8082                	ret

0000000080003102 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	e426                	sd	s1,8(sp)
    8000310a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000310c:	0000d517          	auipc	a0,0xd
    80003110:	15450513          	addi	a0,a0,340 # 80010260 <tickslock>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	ad0080e7          	jalr	-1328(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000311c:	00006497          	auipc	s1,0x6
    80003120:	f344a483          	lw	s1,-204(s1) # 80009050 <ticks>
  release(&tickslock);
    80003124:	0000d517          	auipc	a0,0xd
    80003128:	13c50513          	addi	a0,a0,316 # 80010260 <tickslock>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
  return xticks;
}
    80003134:	02049513          	slli	a0,s1,0x20
    80003138:	9101                	srli	a0,a0,0x20
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	64a2                	ld	s1,8(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret

0000000080003144 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80003144:	1101                	addi	sp,sp,-32
    80003146:	ec06                	sd	ra,24(sp)
    80003148:	e822                	sd	s0,16(sp)
    8000314a:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    8000314c:	fec40593          	addi	a1,s0,-20
    80003150:	4501                	li	a0,0
    80003152:	00000097          	auipc	ra,0x0
    80003156:	d10080e7          	jalr	-752(ra) # 80002e62 <argint>
    8000315a:	87aa                	mv	a5,a0
    return -1;
    8000315c:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    8000315e:	0007c863          	bltz	a5,8000316e <sys_pause_system+0x2a>
  return pause_system(seconds);
    80003162:	fec42503          	lw	a0,-20(s0)
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	630080e7          	jalr	1584(ra) # 80002796 <pause_system>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	6105                	addi	sp,sp,32
    80003174:	8082                	ret

0000000080003176 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003176:	1141                	addi	sp,sp,-16
    80003178:	e406                	sd	ra,8(sp)
    8000317a:	e022                	sd	s0,0(sp)
    8000317c:	0800                	addi	s0,sp,16
  return kill_system();
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	674080e7          	jalr	1652(ra) # 800027f2 <kill_system>
}
    80003186:	60a2                	ld	ra,8(sp)
    80003188:	6402                	ld	s0,0(sp)
    8000318a:	0141                	addi	sp,sp,16
    8000318c:	8082                	ret

000000008000318e <sys_debug>:

uint64
sys_debug(void)
{
    8000318e:	1141                	addi	sp,sp,-16
    80003190:	e406                	sd	ra,8(sp)
    80003192:	e022                	sd	s0,0(sp)
    80003194:	0800                	addi	s0,sp,16
  debug();
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	6bc080e7          	jalr	1724(ra) # 80002852 <debug>
  return 0;
}
    8000319e:	4501                	li	a0,0
    800031a0:	60a2                	ld	ra,8(sp)
    800031a2:	6402                	ld	s0,0(sp)
    800031a4:	0141                	addi	sp,sp,16
    800031a6:	8082                	ret

00000000800031a8 <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800031a8:	1141                	addi	sp,sp,-16
    800031aa:	e406                	sd	ra,8(sp)
    800031ac:	e022                	sd	s0,0(sp)
    800031ae:	0800                	addi	s0,sp,16
  print_stats();
    800031b0:	fffff097          	auipc	ra,0xfffff
    800031b4:	6ee080e7          	jalr	1774(ra) # 8000289e <print_stats>
  return 0;
}
    800031b8:	4501                	li	a0,0
    800031ba:	60a2                	ld	ra,8(sp)
    800031bc:	6402                	ld	s0,0(sp)
    800031be:	0141                	addi	sp,sp,16
    800031c0:	8082                	ret

00000000800031c2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031c2:	7179                	addi	sp,sp,-48
    800031c4:	f406                	sd	ra,40(sp)
    800031c6:	f022                	sd	s0,32(sp)
    800031c8:	ec26                	sd	s1,24(sp)
    800031ca:	e84a                	sd	s2,16(sp)
    800031cc:	e44e                	sd	s3,8(sp)
    800031ce:	e052                	sd	s4,0(sp)
    800031d0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031d2:	00005597          	auipc	a1,0x5
    800031d6:	3be58593          	addi	a1,a1,958 # 80008590 <syscalls+0xd0>
    800031da:	0000d517          	auipc	a0,0xd
    800031de:	09e50513          	addi	a0,a0,158 # 80010278 <bcache>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	972080e7          	jalr	-1678(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031ea:	00015797          	auipc	a5,0x15
    800031ee:	08e78793          	addi	a5,a5,142 # 80018278 <bcache+0x8000>
    800031f2:	00015717          	auipc	a4,0x15
    800031f6:	2ee70713          	addi	a4,a4,750 # 800184e0 <bcache+0x8268>
    800031fa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031fe:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003202:	0000d497          	auipc	s1,0xd
    80003206:	08e48493          	addi	s1,s1,142 # 80010290 <bcache+0x18>
    b->next = bcache.head.next;
    8000320a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000320c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000320e:	00005a17          	auipc	s4,0x5
    80003212:	38aa0a13          	addi	s4,s4,906 # 80008598 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003216:	2b893783          	ld	a5,696(s2)
    8000321a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000321c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003220:	85d2                	mv	a1,s4
    80003222:	01048513          	addi	a0,s1,16
    80003226:	00001097          	auipc	ra,0x1
    8000322a:	4bc080e7          	jalr	1212(ra) # 800046e2 <initsleeplock>
    bcache.head.next->prev = b;
    8000322e:	2b893783          	ld	a5,696(s2)
    80003232:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003234:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003238:	45848493          	addi	s1,s1,1112
    8000323c:	fd349de3          	bne	s1,s3,80003216 <binit+0x54>
  }
}
    80003240:	70a2                	ld	ra,40(sp)
    80003242:	7402                	ld	s0,32(sp)
    80003244:	64e2                	ld	s1,24(sp)
    80003246:	6942                	ld	s2,16(sp)
    80003248:	69a2                	ld	s3,8(sp)
    8000324a:	6a02                	ld	s4,0(sp)
    8000324c:	6145                	addi	sp,sp,48
    8000324e:	8082                	ret

0000000080003250 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003250:	7179                	addi	sp,sp,-48
    80003252:	f406                	sd	ra,40(sp)
    80003254:	f022                	sd	s0,32(sp)
    80003256:	ec26                	sd	s1,24(sp)
    80003258:	e84a                	sd	s2,16(sp)
    8000325a:	e44e                	sd	s3,8(sp)
    8000325c:	1800                	addi	s0,sp,48
    8000325e:	89aa                	mv	s3,a0
    80003260:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003262:	0000d517          	auipc	a0,0xd
    80003266:	01650513          	addi	a0,a0,22 # 80010278 <bcache>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	97a080e7          	jalr	-1670(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003272:	00015497          	auipc	s1,0x15
    80003276:	2be4b483          	ld	s1,702(s1) # 80018530 <bcache+0x82b8>
    8000327a:	00015797          	auipc	a5,0x15
    8000327e:	26678793          	addi	a5,a5,614 # 800184e0 <bcache+0x8268>
    80003282:	02f48f63          	beq	s1,a5,800032c0 <bread+0x70>
    80003286:	873e                	mv	a4,a5
    80003288:	a021                	j	80003290 <bread+0x40>
    8000328a:	68a4                	ld	s1,80(s1)
    8000328c:	02e48a63          	beq	s1,a4,800032c0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003290:	449c                	lw	a5,8(s1)
    80003292:	ff379ce3          	bne	a5,s3,8000328a <bread+0x3a>
    80003296:	44dc                	lw	a5,12(s1)
    80003298:	ff2799e3          	bne	a5,s2,8000328a <bread+0x3a>
      b->refcnt++;
    8000329c:	40bc                	lw	a5,64(s1)
    8000329e:	2785                	addiw	a5,a5,1
    800032a0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032a2:	0000d517          	auipc	a0,0xd
    800032a6:	fd650513          	addi	a0,a0,-42 # 80010278 <bcache>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800032b2:	01048513          	addi	a0,s1,16
    800032b6:	00001097          	auipc	ra,0x1
    800032ba:	466080e7          	jalr	1126(ra) # 8000471c <acquiresleep>
      return b;
    800032be:	a8b9                	j	8000331c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032c0:	00015497          	auipc	s1,0x15
    800032c4:	2684b483          	ld	s1,616(s1) # 80018528 <bcache+0x82b0>
    800032c8:	00015797          	auipc	a5,0x15
    800032cc:	21878793          	addi	a5,a5,536 # 800184e0 <bcache+0x8268>
    800032d0:	00f48863          	beq	s1,a5,800032e0 <bread+0x90>
    800032d4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032d6:	40bc                	lw	a5,64(s1)
    800032d8:	cf81                	beqz	a5,800032f0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032da:	64a4                	ld	s1,72(s1)
    800032dc:	fee49de3          	bne	s1,a4,800032d6 <bread+0x86>
  panic("bget: no buffers");
    800032e0:	00005517          	auipc	a0,0x5
    800032e4:	2c050513          	addi	a0,a0,704 # 800085a0 <syscalls+0xe0>
    800032e8:	ffffd097          	auipc	ra,0xffffd
    800032ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
      b->dev = dev;
    800032f0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800032f4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800032f8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032fc:	4785                	li	a5,1
    800032fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003300:	0000d517          	auipc	a0,0xd
    80003304:	f7850513          	addi	a0,a0,-136 # 80010278 <bcache>
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	990080e7          	jalr	-1648(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003310:	01048513          	addi	a0,s1,16
    80003314:	00001097          	auipc	ra,0x1
    80003318:	408080e7          	jalr	1032(ra) # 8000471c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000331c:	409c                	lw	a5,0(s1)
    8000331e:	cb89                	beqz	a5,80003330 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003320:	8526                	mv	a0,s1
    80003322:	70a2                	ld	ra,40(sp)
    80003324:	7402                	ld	s0,32(sp)
    80003326:	64e2                	ld	s1,24(sp)
    80003328:	6942                	ld	s2,16(sp)
    8000332a:	69a2                	ld	s3,8(sp)
    8000332c:	6145                	addi	sp,sp,48
    8000332e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003330:	4581                	li	a1,0
    80003332:	8526                	mv	a0,s1
    80003334:	00003097          	auipc	ra,0x3
    80003338:	f12080e7          	jalr	-238(ra) # 80006246 <virtio_disk_rw>
    b->valid = 1;
    8000333c:	4785                	li	a5,1
    8000333e:	c09c                	sw	a5,0(s1)
  return b;
    80003340:	b7c5                	j	80003320 <bread+0xd0>

0000000080003342 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	e426                	sd	s1,8(sp)
    8000334a:	1000                	addi	s0,sp,32
    8000334c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000334e:	0541                	addi	a0,a0,16
    80003350:	00001097          	auipc	ra,0x1
    80003354:	466080e7          	jalr	1126(ra) # 800047b6 <holdingsleep>
    80003358:	cd01                	beqz	a0,80003370 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000335a:	4585                	li	a1,1
    8000335c:	8526                	mv	a0,s1
    8000335e:	00003097          	auipc	ra,0x3
    80003362:	ee8080e7          	jalr	-280(ra) # 80006246 <virtio_disk_rw>
}
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret
    panic("bwrite");
    80003370:	00005517          	auipc	a0,0x5
    80003374:	24850513          	addi	a0,a0,584 # 800085b8 <syscalls+0xf8>
    80003378:	ffffd097          	auipc	ra,0xffffd
    8000337c:	1c6080e7          	jalr	454(ra) # 8000053e <panic>

0000000080003380 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003380:	1101                	addi	sp,sp,-32
    80003382:	ec06                	sd	ra,24(sp)
    80003384:	e822                	sd	s0,16(sp)
    80003386:	e426                	sd	s1,8(sp)
    80003388:	e04a                	sd	s2,0(sp)
    8000338a:	1000                	addi	s0,sp,32
    8000338c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000338e:	01050913          	addi	s2,a0,16
    80003392:	854a                	mv	a0,s2
    80003394:	00001097          	auipc	ra,0x1
    80003398:	422080e7          	jalr	1058(ra) # 800047b6 <holdingsleep>
    8000339c:	c92d                	beqz	a0,8000340e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000339e:	854a                	mv	a0,s2
    800033a0:	00001097          	auipc	ra,0x1
    800033a4:	3d2080e7          	jalr	978(ra) # 80004772 <releasesleep>

  acquire(&bcache.lock);
    800033a8:	0000d517          	auipc	a0,0xd
    800033ac:	ed050513          	addi	a0,a0,-304 # 80010278 <bcache>
    800033b0:	ffffe097          	auipc	ra,0xffffe
    800033b4:	834080e7          	jalr	-1996(ra) # 80000be4 <acquire>
  b->refcnt--;
    800033b8:	40bc                	lw	a5,64(s1)
    800033ba:	37fd                	addiw	a5,a5,-1
    800033bc:	0007871b          	sext.w	a4,a5
    800033c0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033c2:	eb05                	bnez	a4,800033f2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033c4:	68bc                	ld	a5,80(s1)
    800033c6:	64b8                	ld	a4,72(s1)
    800033c8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033ca:	64bc                	ld	a5,72(s1)
    800033cc:	68b8                	ld	a4,80(s1)
    800033ce:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033d0:	00015797          	auipc	a5,0x15
    800033d4:	ea878793          	addi	a5,a5,-344 # 80018278 <bcache+0x8000>
    800033d8:	2b87b703          	ld	a4,696(a5)
    800033dc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033de:	00015717          	auipc	a4,0x15
    800033e2:	10270713          	addi	a4,a4,258 # 800184e0 <bcache+0x8268>
    800033e6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033e8:	2b87b703          	ld	a4,696(a5)
    800033ec:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033ee:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033f2:	0000d517          	auipc	a0,0xd
    800033f6:	e8650513          	addi	a0,a0,-378 # 80010278 <bcache>
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
}
    80003402:	60e2                	ld	ra,24(sp)
    80003404:	6442                	ld	s0,16(sp)
    80003406:	64a2                	ld	s1,8(sp)
    80003408:	6902                	ld	s2,0(sp)
    8000340a:	6105                	addi	sp,sp,32
    8000340c:	8082                	ret
    panic("brelse");
    8000340e:	00005517          	auipc	a0,0x5
    80003412:	1b250513          	addi	a0,a0,434 # 800085c0 <syscalls+0x100>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	128080e7          	jalr	296(ra) # 8000053e <panic>

000000008000341e <bpin>:

void
bpin(struct buf *b) {
    8000341e:	1101                	addi	sp,sp,-32
    80003420:	ec06                	sd	ra,24(sp)
    80003422:	e822                	sd	s0,16(sp)
    80003424:	e426                	sd	s1,8(sp)
    80003426:	1000                	addi	s0,sp,32
    80003428:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000342a:	0000d517          	auipc	a0,0xd
    8000342e:	e4e50513          	addi	a0,a0,-434 # 80010278 <bcache>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	7b2080e7          	jalr	1970(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000343a:	40bc                	lw	a5,64(s1)
    8000343c:	2785                	addiw	a5,a5,1
    8000343e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003440:	0000d517          	auipc	a0,0xd
    80003444:	e3850513          	addi	a0,a0,-456 # 80010278 <bcache>
    80003448:	ffffe097          	auipc	ra,0xffffe
    8000344c:	850080e7          	jalr	-1968(ra) # 80000c98 <release>
}
    80003450:	60e2                	ld	ra,24(sp)
    80003452:	6442                	ld	s0,16(sp)
    80003454:	64a2                	ld	s1,8(sp)
    80003456:	6105                	addi	sp,sp,32
    80003458:	8082                	ret

000000008000345a <bunpin>:

void
bunpin(struct buf *b) {
    8000345a:	1101                	addi	sp,sp,-32
    8000345c:	ec06                	sd	ra,24(sp)
    8000345e:	e822                	sd	s0,16(sp)
    80003460:	e426                	sd	s1,8(sp)
    80003462:	1000                	addi	s0,sp,32
    80003464:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003466:	0000d517          	auipc	a0,0xd
    8000346a:	e1250513          	addi	a0,a0,-494 # 80010278 <bcache>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	776080e7          	jalr	1910(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003476:	40bc                	lw	a5,64(s1)
    80003478:	37fd                	addiw	a5,a5,-1
    8000347a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000347c:	0000d517          	auipc	a0,0xd
    80003480:	dfc50513          	addi	a0,a0,-516 # 80010278 <bcache>
    80003484:	ffffe097          	auipc	ra,0xffffe
    80003488:	814080e7          	jalr	-2028(ra) # 80000c98 <release>
}
    8000348c:	60e2                	ld	ra,24(sp)
    8000348e:	6442                	ld	s0,16(sp)
    80003490:	64a2                	ld	s1,8(sp)
    80003492:	6105                	addi	sp,sp,32
    80003494:	8082                	ret

0000000080003496 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003496:	1101                	addi	sp,sp,-32
    80003498:	ec06                	sd	ra,24(sp)
    8000349a:	e822                	sd	s0,16(sp)
    8000349c:	e426                	sd	s1,8(sp)
    8000349e:	e04a                	sd	s2,0(sp)
    800034a0:	1000                	addi	s0,sp,32
    800034a2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034a4:	00d5d59b          	srliw	a1,a1,0xd
    800034a8:	00015797          	auipc	a5,0x15
    800034ac:	4ac7a783          	lw	a5,1196(a5) # 80018954 <sb+0x1c>
    800034b0:	9dbd                	addw	a1,a1,a5
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	d9e080e7          	jalr	-610(ra) # 80003250 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034ba:	0074f713          	andi	a4,s1,7
    800034be:	4785                	li	a5,1
    800034c0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034c4:	14ce                	slli	s1,s1,0x33
    800034c6:	90d9                	srli	s1,s1,0x36
    800034c8:	00950733          	add	a4,a0,s1
    800034cc:	05874703          	lbu	a4,88(a4)
    800034d0:	00e7f6b3          	and	a3,a5,a4
    800034d4:	c69d                	beqz	a3,80003502 <bfree+0x6c>
    800034d6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034d8:	94aa                	add	s1,s1,a0
    800034da:	fff7c793          	not	a5,a5
    800034de:	8ff9                	and	a5,a5,a4
    800034e0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034e4:	00001097          	auipc	ra,0x1
    800034e8:	118080e7          	jalr	280(ra) # 800045fc <log_write>
  brelse(bp);
    800034ec:	854a                	mv	a0,s2
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	e92080e7          	jalr	-366(ra) # 80003380 <brelse>
}
    800034f6:	60e2                	ld	ra,24(sp)
    800034f8:	6442                	ld	s0,16(sp)
    800034fa:	64a2                	ld	s1,8(sp)
    800034fc:	6902                	ld	s2,0(sp)
    800034fe:	6105                	addi	sp,sp,32
    80003500:	8082                	ret
    panic("freeing free block");
    80003502:	00005517          	auipc	a0,0x5
    80003506:	0c650513          	addi	a0,a0,198 # 800085c8 <syscalls+0x108>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	034080e7          	jalr	52(ra) # 8000053e <panic>

0000000080003512 <balloc>:
{
    80003512:	711d                	addi	sp,sp,-96
    80003514:	ec86                	sd	ra,88(sp)
    80003516:	e8a2                	sd	s0,80(sp)
    80003518:	e4a6                	sd	s1,72(sp)
    8000351a:	e0ca                	sd	s2,64(sp)
    8000351c:	fc4e                	sd	s3,56(sp)
    8000351e:	f852                	sd	s4,48(sp)
    80003520:	f456                	sd	s5,40(sp)
    80003522:	f05a                	sd	s6,32(sp)
    80003524:	ec5e                	sd	s7,24(sp)
    80003526:	e862                	sd	s8,16(sp)
    80003528:	e466                	sd	s9,8(sp)
    8000352a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000352c:	00015797          	auipc	a5,0x15
    80003530:	4107a783          	lw	a5,1040(a5) # 8001893c <sb+0x4>
    80003534:	cbd1                	beqz	a5,800035c8 <balloc+0xb6>
    80003536:	8baa                	mv	s7,a0
    80003538:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000353a:	00015b17          	auipc	s6,0x15
    8000353e:	3feb0b13          	addi	s6,s6,1022 # 80018938 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003542:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003544:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003546:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003548:	6c89                	lui	s9,0x2
    8000354a:	a831                	j	80003566 <balloc+0x54>
    brelse(bp);
    8000354c:	854a                	mv	a0,s2
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	e32080e7          	jalr	-462(ra) # 80003380 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003556:	015c87bb          	addw	a5,s9,s5
    8000355a:	00078a9b          	sext.w	s5,a5
    8000355e:	004b2703          	lw	a4,4(s6)
    80003562:	06eaf363          	bgeu	s5,a4,800035c8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003566:	41fad79b          	sraiw	a5,s5,0x1f
    8000356a:	0137d79b          	srliw	a5,a5,0x13
    8000356e:	015787bb          	addw	a5,a5,s5
    80003572:	40d7d79b          	sraiw	a5,a5,0xd
    80003576:	01cb2583          	lw	a1,28(s6)
    8000357a:	9dbd                	addw	a1,a1,a5
    8000357c:	855e                	mv	a0,s7
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	cd2080e7          	jalr	-814(ra) # 80003250 <bread>
    80003586:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003588:	004b2503          	lw	a0,4(s6)
    8000358c:	000a849b          	sext.w	s1,s5
    80003590:	8662                	mv	a2,s8
    80003592:	faa4fde3          	bgeu	s1,a0,8000354c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003596:	41f6579b          	sraiw	a5,a2,0x1f
    8000359a:	01d7d69b          	srliw	a3,a5,0x1d
    8000359e:	00c6873b          	addw	a4,a3,a2
    800035a2:	00777793          	andi	a5,a4,7
    800035a6:	9f95                	subw	a5,a5,a3
    800035a8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035ac:	4037571b          	sraiw	a4,a4,0x3
    800035b0:	00e906b3          	add	a3,s2,a4
    800035b4:	0586c683          	lbu	a3,88(a3)
    800035b8:	00d7f5b3          	and	a1,a5,a3
    800035bc:	cd91                	beqz	a1,800035d8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035be:	2605                	addiw	a2,a2,1
    800035c0:	2485                	addiw	s1,s1,1
    800035c2:	fd4618e3          	bne	a2,s4,80003592 <balloc+0x80>
    800035c6:	b759                	j	8000354c <balloc+0x3a>
  panic("balloc: out of blocks");
    800035c8:	00005517          	auipc	a0,0x5
    800035cc:	01850513          	addi	a0,a0,24 # 800085e0 <syscalls+0x120>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035d8:	974a                	add	a4,a4,s2
    800035da:	8fd5                	or	a5,a5,a3
    800035dc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800035e0:	854a                	mv	a0,s2
    800035e2:	00001097          	auipc	ra,0x1
    800035e6:	01a080e7          	jalr	26(ra) # 800045fc <log_write>
        brelse(bp);
    800035ea:	854a                	mv	a0,s2
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	d94080e7          	jalr	-620(ra) # 80003380 <brelse>
  bp = bread(dev, bno);
    800035f4:	85a6                	mv	a1,s1
    800035f6:	855e                	mv	a0,s7
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	c58080e7          	jalr	-936(ra) # 80003250 <bread>
    80003600:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003602:	40000613          	li	a2,1024
    80003606:	4581                	li	a1,0
    80003608:	05850513          	addi	a0,a0,88
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	6d4080e7          	jalr	1748(ra) # 80000ce0 <memset>
  log_write(bp);
    80003614:	854a                	mv	a0,s2
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	fe6080e7          	jalr	-26(ra) # 800045fc <log_write>
  brelse(bp);
    8000361e:	854a                	mv	a0,s2
    80003620:	00000097          	auipc	ra,0x0
    80003624:	d60080e7          	jalr	-672(ra) # 80003380 <brelse>
}
    80003628:	8526                	mv	a0,s1
    8000362a:	60e6                	ld	ra,88(sp)
    8000362c:	6446                	ld	s0,80(sp)
    8000362e:	64a6                	ld	s1,72(sp)
    80003630:	6906                	ld	s2,64(sp)
    80003632:	79e2                	ld	s3,56(sp)
    80003634:	7a42                	ld	s4,48(sp)
    80003636:	7aa2                	ld	s5,40(sp)
    80003638:	7b02                	ld	s6,32(sp)
    8000363a:	6be2                	ld	s7,24(sp)
    8000363c:	6c42                	ld	s8,16(sp)
    8000363e:	6ca2                	ld	s9,8(sp)
    80003640:	6125                	addi	sp,sp,96
    80003642:	8082                	ret

0000000080003644 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003644:	7179                	addi	sp,sp,-48
    80003646:	f406                	sd	ra,40(sp)
    80003648:	f022                	sd	s0,32(sp)
    8000364a:	ec26                	sd	s1,24(sp)
    8000364c:	e84a                	sd	s2,16(sp)
    8000364e:	e44e                	sd	s3,8(sp)
    80003650:	e052                	sd	s4,0(sp)
    80003652:	1800                	addi	s0,sp,48
    80003654:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003656:	47ad                	li	a5,11
    80003658:	04b7fe63          	bgeu	a5,a1,800036b4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000365c:	ff45849b          	addiw	s1,a1,-12
    80003660:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003664:	0ff00793          	li	a5,255
    80003668:	0ae7e363          	bltu	a5,a4,8000370e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000366c:	08052583          	lw	a1,128(a0)
    80003670:	c5ad                	beqz	a1,800036da <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003672:	00092503          	lw	a0,0(s2)
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	bda080e7          	jalr	-1062(ra) # 80003250 <bread>
    8000367e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003680:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003684:	02049593          	slli	a1,s1,0x20
    80003688:	9181                	srli	a1,a1,0x20
    8000368a:	058a                	slli	a1,a1,0x2
    8000368c:	00b784b3          	add	s1,a5,a1
    80003690:	0004a983          	lw	s3,0(s1)
    80003694:	04098d63          	beqz	s3,800036ee <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003698:	8552                	mv	a0,s4
    8000369a:	00000097          	auipc	ra,0x0
    8000369e:	ce6080e7          	jalr	-794(ra) # 80003380 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036a2:	854e                	mv	a0,s3
    800036a4:	70a2                	ld	ra,40(sp)
    800036a6:	7402                	ld	s0,32(sp)
    800036a8:	64e2                	ld	s1,24(sp)
    800036aa:	6942                	ld	s2,16(sp)
    800036ac:	69a2                	ld	s3,8(sp)
    800036ae:	6a02                	ld	s4,0(sp)
    800036b0:	6145                	addi	sp,sp,48
    800036b2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800036b4:	02059493          	slli	s1,a1,0x20
    800036b8:	9081                	srli	s1,s1,0x20
    800036ba:	048a                	slli	s1,s1,0x2
    800036bc:	94aa                	add	s1,s1,a0
    800036be:	0504a983          	lw	s3,80(s1)
    800036c2:	fe0990e3          	bnez	s3,800036a2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800036c6:	4108                	lw	a0,0(a0)
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	e4a080e7          	jalr	-438(ra) # 80003512 <balloc>
    800036d0:	0005099b          	sext.w	s3,a0
    800036d4:	0534a823          	sw	s3,80(s1)
    800036d8:	b7e9                	j	800036a2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800036da:	4108                	lw	a0,0(a0)
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	e36080e7          	jalr	-458(ra) # 80003512 <balloc>
    800036e4:	0005059b          	sext.w	a1,a0
    800036e8:	08b92023          	sw	a1,128(s2)
    800036ec:	b759                	j	80003672 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036ee:	00092503          	lw	a0,0(s2)
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	e20080e7          	jalr	-480(ra) # 80003512 <balloc>
    800036fa:	0005099b          	sext.w	s3,a0
    800036fe:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003702:	8552                	mv	a0,s4
    80003704:	00001097          	auipc	ra,0x1
    80003708:	ef8080e7          	jalr	-264(ra) # 800045fc <log_write>
    8000370c:	b771                	j	80003698 <bmap+0x54>
  panic("bmap: out of range");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	eea50513          	addi	a0,a0,-278 # 800085f8 <syscalls+0x138>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>

000000008000371e <iget>:
{
    8000371e:	7179                	addi	sp,sp,-48
    80003720:	f406                	sd	ra,40(sp)
    80003722:	f022                	sd	s0,32(sp)
    80003724:	ec26                	sd	s1,24(sp)
    80003726:	e84a                	sd	s2,16(sp)
    80003728:	e44e                	sd	s3,8(sp)
    8000372a:	e052                	sd	s4,0(sp)
    8000372c:	1800                	addi	s0,sp,48
    8000372e:	89aa                	mv	s3,a0
    80003730:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003732:	00015517          	auipc	a0,0x15
    80003736:	22650513          	addi	a0,a0,550 # 80018958 <itable>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	4aa080e7          	jalr	1194(ra) # 80000be4 <acquire>
  empty = 0;
    80003742:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003744:	00015497          	auipc	s1,0x15
    80003748:	22c48493          	addi	s1,s1,556 # 80018970 <itable+0x18>
    8000374c:	00017697          	auipc	a3,0x17
    80003750:	cb468693          	addi	a3,a3,-844 # 8001a400 <log>
    80003754:	a039                	j	80003762 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003756:	02090b63          	beqz	s2,8000378c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000375a:	08848493          	addi	s1,s1,136
    8000375e:	02d48a63          	beq	s1,a3,80003792 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003762:	449c                	lw	a5,8(s1)
    80003764:	fef059e3          	blez	a5,80003756 <iget+0x38>
    80003768:	4098                	lw	a4,0(s1)
    8000376a:	ff3716e3          	bne	a4,s3,80003756 <iget+0x38>
    8000376e:	40d8                	lw	a4,4(s1)
    80003770:	ff4713e3          	bne	a4,s4,80003756 <iget+0x38>
      ip->ref++;
    80003774:	2785                	addiw	a5,a5,1
    80003776:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003778:	00015517          	auipc	a0,0x15
    8000377c:	1e050513          	addi	a0,a0,480 # 80018958 <itable>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	518080e7          	jalr	1304(ra) # 80000c98 <release>
      return ip;
    80003788:	8926                	mv	s2,s1
    8000378a:	a03d                	j	800037b8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000378c:	f7f9                	bnez	a5,8000375a <iget+0x3c>
    8000378e:	8926                	mv	s2,s1
    80003790:	b7e9                	j	8000375a <iget+0x3c>
  if(empty == 0)
    80003792:	02090c63          	beqz	s2,800037ca <iget+0xac>
  ip->dev = dev;
    80003796:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000379a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000379e:	4785                	li	a5,1
    800037a0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037a4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037a8:	00015517          	auipc	a0,0x15
    800037ac:	1b050513          	addi	a0,a0,432 # 80018958 <itable>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	4e8080e7          	jalr	1256(ra) # 80000c98 <release>
}
    800037b8:	854a                	mv	a0,s2
    800037ba:	70a2                	ld	ra,40(sp)
    800037bc:	7402                	ld	s0,32(sp)
    800037be:	64e2                	ld	s1,24(sp)
    800037c0:	6942                	ld	s2,16(sp)
    800037c2:	69a2                	ld	s3,8(sp)
    800037c4:	6a02                	ld	s4,0(sp)
    800037c6:	6145                	addi	sp,sp,48
    800037c8:	8082                	ret
    panic("iget: no inodes");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	e4650513          	addi	a0,a0,-442 # 80008610 <syscalls+0x150>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d6c080e7          	jalr	-660(ra) # 8000053e <panic>

00000000800037da <fsinit>:
fsinit(int dev) {
    800037da:	7179                	addi	sp,sp,-48
    800037dc:	f406                	sd	ra,40(sp)
    800037de:	f022                	sd	s0,32(sp)
    800037e0:	ec26                	sd	s1,24(sp)
    800037e2:	e84a                	sd	s2,16(sp)
    800037e4:	e44e                	sd	s3,8(sp)
    800037e6:	1800                	addi	s0,sp,48
    800037e8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037ea:	4585                	li	a1,1
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	a64080e7          	jalr	-1436(ra) # 80003250 <bread>
    800037f4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037f6:	00015997          	auipc	s3,0x15
    800037fa:	14298993          	addi	s3,s3,322 # 80018938 <sb>
    800037fe:	02000613          	li	a2,32
    80003802:	05850593          	addi	a1,a0,88
    80003806:	854e                	mv	a0,s3
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	538080e7          	jalr	1336(ra) # 80000d40 <memmove>
  brelse(bp);
    80003810:	8526                	mv	a0,s1
    80003812:	00000097          	auipc	ra,0x0
    80003816:	b6e080e7          	jalr	-1170(ra) # 80003380 <brelse>
  if(sb.magic != FSMAGIC)
    8000381a:	0009a703          	lw	a4,0(s3)
    8000381e:	102037b7          	lui	a5,0x10203
    80003822:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003826:	02f71263          	bne	a4,a5,8000384a <fsinit+0x70>
  initlog(dev, &sb);
    8000382a:	00015597          	auipc	a1,0x15
    8000382e:	10e58593          	addi	a1,a1,270 # 80018938 <sb>
    80003832:	854a                	mv	a0,s2
    80003834:	00001097          	auipc	ra,0x1
    80003838:	b4c080e7          	jalr	-1204(ra) # 80004380 <initlog>
}
    8000383c:	70a2                	ld	ra,40(sp)
    8000383e:	7402                	ld	s0,32(sp)
    80003840:	64e2                	ld	s1,24(sp)
    80003842:	6942                	ld	s2,16(sp)
    80003844:	69a2                	ld	s3,8(sp)
    80003846:	6145                	addi	sp,sp,48
    80003848:	8082                	ret
    panic("invalid file system");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	dd650513          	addi	a0,a0,-554 # 80008620 <syscalls+0x160>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	cec080e7          	jalr	-788(ra) # 8000053e <panic>

000000008000385a <iinit>:
{
    8000385a:	7179                	addi	sp,sp,-48
    8000385c:	f406                	sd	ra,40(sp)
    8000385e:	f022                	sd	s0,32(sp)
    80003860:	ec26                	sd	s1,24(sp)
    80003862:	e84a                	sd	s2,16(sp)
    80003864:	e44e                	sd	s3,8(sp)
    80003866:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003868:	00005597          	auipc	a1,0x5
    8000386c:	dd058593          	addi	a1,a1,-560 # 80008638 <syscalls+0x178>
    80003870:	00015517          	auipc	a0,0x15
    80003874:	0e850513          	addi	a0,a0,232 # 80018958 <itable>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	2dc080e7          	jalr	732(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003880:	00015497          	auipc	s1,0x15
    80003884:	10048493          	addi	s1,s1,256 # 80018980 <itable+0x28>
    80003888:	00017997          	auipc	s3,0x17
    8000388c:	b8898993          	addi	s3,s3,-1144 # 8001a410 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003890:	00005917          	auipc	s2,0x5
    80003894:	db090913          	addi	s2,s2,-592 # 80008640 <syscalls+0x180>
    80003898:	85ca                	mv	a1,s2
    8000389a:	8526                	mv	a0,s1
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	e46080e7          	jalr	-442(ra) # 800046e2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038a4:	08848493          	addi	s1,s1,136
    800038a8:	ff3498e3          	bne	s1,s3,80003898 <iinit+0x3e>
}
    800038ac:	70a2                	ld	ra,40(sp)
    800038ae:	7402                	ld	s0,32(sp)
    800038b0:	64e2                	ld	s1,24(sp)
    800038b2:	6942                	ld	s2,16(sp)
    800038b4:	69a2                	ld	s3,8(sp)
    800038b6:	6145                	addi	sp,sp,48
    800038b8:	8082                	ret

00000000800038ba <ialloc>:
{
    800038ba:	715d                	addi	sp,sp,-80
    800038bc:	e486                	sd	ra,72(sp)
    800038be:	e0a2                	sd	s0,64(sp)
    800038c0:	fc26                	sd	s1,56(sp)
    800038c2:	f84a                	sd	s2,48(sp)
    800038c4:	f44e                	sd	s3,40(sp)
    800038c6:	f052                	sd	s4,32(sp)
    800038c8:	ec56                	sd	s5,24(sp)
    800038ca:	e85a                	sd	s6,16(sp)
    800038cc:	e45e                	sd	s7,8(sp)
    800038ce:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038d0:	00015717          	auipc	a4,0x15
    800038d4:	07472703          	lw	a4,116(a4) # 80018944 <sb+0xc>
    800038d8:	4785                	li	a5,1
    800038da:	04e7fa63          	bgeu	a5,a4,8000392e <ialloc+0x74>
    800038de:	8aaa                	mv	s5,a0
    800038e0:	8bae                	mv	s7,a1
    800038e2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038e4:	00015a17          	auipc	s4,0x15
    800038e8:	054a0a13          	addi	s4,s4,84 # 80018938 <sb>
    800038ec:	00048b1b          	sext.w	s6,s1
    800038f0:	0044d593          	srli	a1,s1,0x4
    800038f4:	018a2783          	lw	a5,24(s4)
    800038f8:	9dbd                	addw	a1,a1,a5
    800038fa:	8556                	mv	a0,s5
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	954080e7          	jalr	-1708(ra) # 80003250 <bread>
    80003904:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003906:	05850993          	addi	s3,a0,88
    8000390a:	00f4f793          	andi	a5,s1,15
    8000390e:	079a                	slli	a5,a5,0x6
    80003910:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003912:	00099783          	lh	a5,0(s3)
    80003916:	c785                	beqz	a5,8000393e <ialloc+0x84>
    brelse(bp);
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	a68080e7          	jalr	-1432(ra) # 80003380 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003920:	0485                	addi	s1,s1,1
    80003922:	00ca2703          	lw	a4,12(s4)
    80003926:	0004879b          	sext.w	a5,s1
    8000392a:	fce7e1e3          	bltu	a5,a4,800038ec <ialloc+0x32>
  panic("ialloc: no inodes");
    8000392e:	00005517          	auipc	a0,0x5
    80003932:	d1a50513          	addi	a0,a0,-742 # 80008648 <syscalls+0x188>
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	c08080e7          	jalr	-1016(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000393e:	04000613          	li	a2,64
    80003942:	4581                	li	a1,0
    80003944:	854e                	mv	a0,s3
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	39a080e7          	jalr	922(ra) # 80000ce0 <memset>
      dip->type = type;
    8000394e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003952:	854a                	mv	a0,s2
    80003954:	00001097          	auipc	ra,0x1
    80003958:	ca8080e7          	jalr	-856(ra) # 800045fc <log_write>
      brelse(bp);
    8000395c:	854a                	mv	a0,s2
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	a22080e7          	jalr	-1502(ra) # 80003380 <brelse>
      return iget(dev, inum);
    80003966:	85da                	mv	a1,s6
    80003968:	8556                	mv	a0,s5
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	db4080e7          	jalr	-588(ra) # 8000371e <iget>
}
    80003972:	60a6                	ld	ra,72(sp)
    80003974:	6406                	ld	s0,64(sp)
    80003976:	74e2                	ld	s1,56(sp)
    80003978:	7942                	ld	s2,48(sp)
    8000397a:	79a2                	ld	s3,40(sp)
    8000397c:	7a02                	ld	s4,32(sp)
    8000397e:	6ae2                	ld	s5,24(sp)
    80003980:	6b42                	ld	s6,16(sp)
    80003982:	6ba2                	ld	s7,8(sp)
    80003984:	6161                	addi	sp,sp,80
    80003986:	8082                	ret

0000000080003988 <iupdate>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003996:	415c                	lw	a5,4(a0)
    80003998:	0047d79b          	srliw	a5,a5,0x4
    8000399c:	00015597          	auipc	a1,0x15
    800039a0:	fb45a583          	lw	a1,-76(a1) # 80018950 <sb+0x18>
    800039a4:	9dbd                	addw	a1,a1,a5
    800039a6:	4108                	lw	a0,0(a0)
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	8a8080e7          	jalr	-1880(ra) # 80003250 <bread>
    800039b0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b2:	05850793          	addi	a5,a0,88
    800039b6:	40c8                	lw	a0,4(s1)
    800039b8:	893d                	andi	a0,a0,15
    800039ba:	051a                	slli	a0,a0,0x6
    800039bc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039be:	04449703          	lh	a4,68(s1)
    800039c2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039c6:	04649703          	lh	a4,70(s1)
    800039ca:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039ce:	04849703          	lh	a4,72(s1)
    800039d2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039d6:	04a49703          	lh	a4,74(s1)
    800039da:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039de:	44f8                	lw	a4,76(s1)
    800039e0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039e2:	03400613          	li	a2,52
    800039e6:	05048593          	addi	a1,s1,80
    800039ea:	0531                	addi	a0,a0,12
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	354080e7          	jalr	852(ra) # 80000d40 <memmove>
  log_write(bp);
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	c06080e7          	jalr	-1018(ra) # 800045fc <log_write>
  brelse(bp);
    800039fe:	854a                	mv	a0,s2
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	980080e7          	jalr	-1664(ra) # 80003380 <brelse>
}
    80003a08:	60e2                	ld	ra,24(sp)
    80003a0a:	6442                	ld	s0,16(sp)
    80003a0c:	64a2                	ld	s1,8(sp)
    80003a0e:	6902                	ld	s2,0(sp)
    80003a10:	6105                	addi	sp,sp,32
    80003a12:	8082                	ret

0000000080003a14 <idup>:
{
    80003a14:	1101                	addi	sp,sp,-32
    80003a16:	ec06                	sd	ra,24(sp)
    80003a18:	e822                	sd	s0,16(sp)
    80003a1a:	e426                	sd	s1,8(sp)
    80003a1c:	1000                	addi	s0,sp,32
    80003a1e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a20:	00015517          	auipc	a0,0x15
    80003a24:	f3850513          	addi	a0,a0,-200 # 80018958 <itable>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	1bc080e7          	jalr	444(ra) # 80000be4 <acquire>
  ip->ref++;
    80003a30:	449c                	lw	a5,8(s1)
    80003a32:	2785                	addiw	a5,a5,1
    80003a34:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a36:	00015517          	auipc	a0,0x15
    80003a3a:	f2250513          	addi	a0,a0,-222 # 80018958 <itable>
    80003a3e:	ffffd097          	auipc	ra,0xffffd
    80003a42:	25a080e7          	jalr	602(ra) # 80000c98 <release>
}
    80003a46:	8526                	mv	a0,s1
    80003a48:	60e2                	ld	ra,24(sp)
    80003a4a:	6442                	ld	s0,16(sp)
    80003a4c:	64a2                	ld	s1,8(sp)
    80003a4e:	6105                	addi	sp,sp,32
    80003a50:	8082                	ret

0000000080003a52 <ilock>:
{
    80003a52:	1101                	addi	sp,sp,-32
    80003a54:	ec06                	sd	ra,24(sp)
    80003a56:	e822                	sd	s0,16(sp)
    80003a58:	e426                	sd	s1,8(sp)
    80003a5a:	e04a                	sd	s2,0(sp)
    80003a5c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a5e:	c115                	beqz	a0,80003a82 <ilock+0x30>
    80003a60:	84aa                	mv	s1,a0
    80003a62:	451c                	lw	a5,8(a0)
    80003a64:	00f05f63          	blez	a5,80003a82 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a68:	0541                	addi	a0,a0,16
    80003a6a:	00001097          	auipc	ra,0x1
    80003a6e:	cb2080e7          	jalr	-846(ra) # 8000471c <acquiresleep>
  if(ip->valid == 0){
    80003a72:	40bc                	lw	a5,64(s1)
    80003a74:	cf99                	beqz	a5,80003a92 <ilock+0x40>
}
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6902                	ld	s2,0(sp)
    80003a7e:	6105                	addi	sp,sp,32
    80003a80:	8082                	ret
    panic("ilock");
    80003a82:	00005517          	auipc	a0,0x5
    80003a86:	bde50513          	addi	a0,a0,-1058 # 80008660 <syscalls+0x1a0>
    80003a8a:	ffffd097          	auipc	ra,0xffffd
    80003a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a92:	40dc                	lw	a5,4(s1)
    80003a94:	0047d79b          	srliw	a5,a5,0x4
    80003a98:	00015597          	auipc	a1,0x15
    80003a9c:	eb85a583          	lw	a1,-328(a1) # 80018950 <sb+0x18>
    80003aa0:	9dbd                	addw	a1,a1,a5
    80003aa2:	4088                	lw	a0,0(s1)
    80003aa4:	fffff097          	auipc	ra,0xfffff
    80003aa8:	7ac080e7          	jalr	1964(ra) # 80003250 <bread>
    80003aac:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003aae:	05850593          	addi	a1,a0,88
    80003ab2:	40dc                	lw	a5,4(s1)
    80003ab4:	8bbd                	andi	a5,a5,15
    80003ab6:	079a                	slli	a5,a5,0x6
    80003ab8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003aba:	00059783          	lh	a5,0(a1)
    80003abe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ac2:	00259783          	lh	a5,2(a1)
    80003ac6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003aca:	00459783          	lh	a5,4(a1)
    80003ace:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ad2:	00659783          	lh	a5,6(a1)
    80003ad6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ada:	459c                	lw	a5,8(a1)
    80003adc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ade:	03400613          	li	a2,52
    80003ae2:	05b1                	addi	a1,a1,12
    80003ae4:	05048513          	addi	a0,s1,80
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	258080e7          	jalr	600(ra) # 80000d40 <memmove>
    brelse(bp);
    80003af0:	854a                	mv	a0,s2
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	88e080e7          	jalr	-1906(ra) # 80003380 <brelse>
    ip->valid = 1;
    80003afa:	4785                	li	a5,1
    80003afc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003afe:	04449783          	lh	a5,68(s1)
    80003b02:	fbb5                	bnez	a5,80003a76 <ilock+0x24>
      panic("ilock: no type");
    80003b04:	00005517          	auipc	a0,0x5
    80003b08:	b6450513          	addi	a0,a0,-1180 # 80008668 <syscalls+0x1a8>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>

0000000080003b14 <iunlock>:
{
    80003b14:	1101                	addi	sp,sp,-32
    80003b16:	ec06                	sd	ra,24(sp)
    80003b18:	e822                	sd	s0,16(sp)
    80003b1a:	e426                	sd	s1,8(sp)
    80003b1c:	e04a                	sd	s2,0(sp)
    80003b1e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b20:	c905                	beqz	a0,80003b50 <iunlock+0x3c>
    80003b22:	84aa                	mv	s1,a0
    80003b24:	01050913          	addi	s2,a0,16
    80003b28:	854a                	mv	a0,s2
    80003b2a:	00001097          	auipc	ra,0x1
    80003b2e:	c8c080e7          	jalr	-884(ra) # 800047b6 <holdingsleep>
    80003b32:	cd19                	beqz	a0,80003b50 <iunlock+0x3c>
    80003b34:	449c                	lw	a5,8(s1)
    80003b36:	00f05d63          	blez	a5,80003b50 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b3a:	854a                	mv	a0,s2
    80003b3c:	00001097          	auipc	ra,0x1
    80003b40:	c36080e7          	jalr	-970(ra) # 80004772 <releasesleep>
}
    80003b44:	60e2                	ld	ra,24(sp)
    80003b46:	6442                	ld	s0,16(sp)
    80003b48:	64a2                	ld	s1,8(sp)
    80003b4a:	6902                	ld	s2,0(sp)
    80003b4c:	6105                	addi	sp,sp,32
    80003b4e:	8082                	ret
    panic("iunlock");
    80003b50:	00005517          	auipc	a0,0x5
    80003b54:	b2850513          	addi	a0,a0,-1240 # 80008678 <syscalls+0x1b8>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	9e6080e7          	jalr	-1562(ra) # 8000053e <panic>

0000000080003b60 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b60:	7179                	addi	sp,sp,-48
    80003b62:	f406                	sd	ra,40(sp)
    80003b64:	f022                	sd	s0,32(sp)
    80003b66:	ec26                	sd	s1,24(sp)
    80003b68:	e84a                	sd	s2,16(sp)
    80003b6a:	e44e                	sd	s3,8(sp)
    80003b6c:	e052                	sd	s4,0(sp)
    80003b6e:	1800                	addi	s0,sp,48
    80003b70:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b72:	05050493          	addi	s1,a0,80
    80003b76:	08050913          	addi	s2,a0,128
    80003b7a:	a021                	j	80003b82 <itrunc+0x22>
    80003b7c:	0491                	addi	s1,s1,4
    80003b7e:	01248d63          	beq	s1,s2,80003b98 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b82:	408c                	lw	a1,0(s1)
    80003b84:	dde5                	beqz	a1,80003b7c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b86:	0009a503          	lw	a0,0(s3)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	90c080e7          	jalr	-1780(ra) # 80003496 <bfree>
      ip->addrs[i] = 0;
    80003b92:	0004a023          	sw	zero,0(s1)
    80003b96:	b7dd                	j	80003b7c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b98:	0809a583          	lw	a1,128(s3)
    80003b9c:	e185                	bnez	a1,80003bbc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b9e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ba2:	854e                	mv	a0,s3
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	de4080e7          	jalr	-540(ra) # 80003988 <iupdate>
}
    80003bac:	70a2                	ld	ra,40(sp)
    80003bae:	7402                	ld	s0,32(sp)
    80003bb0:	64e2                	ld	s1,24(sp)
    80003bb2:	6942                	ld	s2,16(sp)
    80003bb4:	69a2                	ld	s3,8(sp)
    80003bb6:	6a02                	ld	s4,0(sp)
    80003bb8:	6145                	addi	sp,sp,48
    80003bba:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bbc:	0009a503          	lw	a0,0(s3)
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	690080e7          	jalr	1680(ra) # 80003250 <bread>
    80003bc8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bca:	05850493          	addi	s1,a0,88
    80003bce:	45850913          	addi	s2,a0,1112
    80003bd2:	a811                	j	80003be6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003bd4:	0009a503          	lw	a0,0(s3)
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	8be080e7          	jalr	-1858(ra) # 80003496 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003be0:	0491                	addi	s1,s1,4
    80003be2:	01248563          	beq	s1,s2,80003bec <itrunc+0x8c>
      if(a[j])
    80003be6:	408c                	lw	a1,0(s1)
    80003be8:	dde5                	beqz	a1,80003be0 <itrunc+0x80>
    80003bea:	b7ed                	j	80003bd4 <itrunc+0x74>
    brelse(bp);
    80003bec:	8552                	mv	a0,s4
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	792080e7          	jalr	1938(ra) # 80003380 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bf6:	0809a583          	lw	a1,128(s3)
    80003bfa:	0009a503          	lw	a0,0(s3)
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	898080e7          	jalr	-1896(ra) # 80003496 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c06:	0809a023          	sw	zero,128(s3)
    80003c0a:	bf51                	j	80003b9e <itrunc+0x3e>

0000000080003c0c <iput>:
{
    80003c0c:	1101                	addi	sp,sp,-32
    80003c0e:	ec06                	sd	ra,24(sp)
    80003c10:	e822                	sd	s0,16(sp)
    80003c12:	e426                	sd	s1,8(sp)
    80003c14:	e04a                	sd	s2,0(sp)
    80003c16:	1000                	addi	s0,sp,32
    80003c18:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c1a:	00015517          	auipc	a0,0x15
    80003c1e:	d3e50513          	addi	a0,a0,-706 # 80018958 <itable>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	fc2080e7          	jalr	-62(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c2a:	4498                	lw	a4,8(s1)
    80003c2c:	4785                	li	a5,1
    80003c2e:	02f70363          	beq	a4,a5,80003c54 <iput+0x48>
  ip->ref--;
    80003c32:	449c                	lw	a5,8(s1)
    80003c34:	37fd                	addiw	a5,a5,-1
    80003c36:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c38:	00015517          	auipc	a0,0x15
    80003c3c:	d2050513          	addi	a0,a0,-736 # 80018958 <itable>
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	058080e7          	jalr	88(ra) # 80000c98 <release>
}
    80003c48:	60e2                	ld	ra,24(sp)
    80003c4a:	6442                	ld	s0,16(sp)
    80003c4c:	64a2                	ld	s1,8(sp)
    80003c4e:	6902                	ld	s2,0(sp)
    80003c50:	6105                	addi	sp,sp,32
    80003c52:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c54:	40bc                	lw	a5,64(s1)
    80003c56:	dff1                	beqz	a5,80003c32 <iput+0x26>
    80003c58:	04a49783          	lh	a5,74(s1)
    80003c5c:	fbf9                	bnez	a5,80003c32 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c5e:	01048913          	addi	s2,s1,16
    80003c62:	854a                	mv	a0,s2
    80003c64:	00001097          	auipc	ra,0x1
    80003c68:	ab8080e7          	jalr	-1352(ra) # 8000471c <acquiresleep>
    release(&itable.lock);
    80003c6c:	00015517          	auipc	a0,0x15
    80003c70:	cec50513          	addi	a0,a0,-788 # 80018958 <itable>
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
    itrunc(ip);
    80003c7c:	8526                	mv	a0,s1
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	ee2080e7          	jalr	-286(ra) # 80003b60 <itrunc>
    ip->type = 0;
    80003c86:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c8a:	8526                	mv	a0,s1
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	cfc080e7          	jalr	-772(ra) # 80003988 <iupdate>
    ip->valid = 0;
    80003c94:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c98:	854a                	mv	a0,s2
    80003c9a:	00001097          	auipc	ra,0x1
    80003c9e:	ad8080e7          	jalr	-1320(ra) # 80004772 <releasesleep>
    acquire(&itable.lock);
    80003ca2:	00015517          	auipc	a0,0x15
    80003ca6:	cb650513          	addi	a0,a0,-842 # 80018958 <itable>
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	f3a080e7          	jalr	-198(ra) # 80000be4 <acquire>
    80003cb2:	b741                	j	80003c32 <iput+0x26>

0000000080003cb4 <iunlockput>:
{
    80003cb4:	1101                	addi	sp,sp,-32
    80003cb6:	ec06                	sd	ra,24(sp)
    80003cb8:	e822                	sd	s0,16(sp)
    80003cba:	e426                	sd	s1,8(sp)
    80003cbc:	1000                	addi	s0,sp,32
    80003cbe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	e54080e7          	jalr	-428(ra) # 80003b14 <iunlock>
  iput(ip);
    80003cc8:	8526                	mv	a0,s1
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	f42080e7          	jalr	-190(ra) # 80003c0c <iput>
}
    80003cd2:	60e2                	ld	ra,24(sp)
    80003cd4:	6442                	ld	s0,16(sp)
    80003cd6:	64a2                	ld	s1,8(sp)
    80003cd8:	6105                	addi	sp,sp,32
    80003cda:	8082                	ret

0000000080003cdc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cdc:	1141                	addi	sp,sp,-16
    80003cde:	e422                	sd	s0,8(sp)
    80003ce0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ce2:	411c                	lw	a5,0(a0)
    80003ce4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ce6:	415c                	lw	a5,4(a0)
    80003ce8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cea:	04451783          	lh	a5,68(a0)
    80003cee:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cf2:	04a51783          	lh	a5,74(a0)
    80003cf6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cfa:	04c56783          	lwu	a5,76(a0)
    80003cfe:	e99c                	sd	a5,16(a1)
}
    80003d00:	6422                	ld	s0,8(sp)
    80003d02:	0141                	addi	sp,sp,16
    80003d04:	8082                	ret

0000000080003d06 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d06:	457c                	lw	a5,76(a0)
    80003d08:	0ed7e963          	bltu	a5,a3,80003dfa <readi+0xf4>
{
    80003d0c:	7159                	addi	sp,sp,-112
    80003d0e:	f486                	sd	ra,104(sp)
    80003d10:	f0a2                	sd	s0,96(sp)
    80003d12:	eca6                	sd	s1,88(sp)
    80003d14:	e8ca                	sd	s2,80(sp)
    80003d16:	e4ce                	sd	s3,72(sp)
    80003d18:	e0d2                	sd	s4,64(sp)
    80003d1a:	fc56                	sd	s5,56(sp)
    80003d1c:	f85a                	sd	s6,48(sp)
    80003d1e:	f45e                	sd	s7,40(sp)
    80003d20:	f062                	sd	s8,32(sp)
    80003d22:	ec66                	sd	s9,24(sp)
    80003d24:	e86a                	sd	s10,16(sp)
    80003d26:	e46e                	sd	s11,8(sp)
    80003d28:	1880                	addi	s0,sp,112
    80003d2a:	8baa                	mv	s7,a0
    80003d2c:	8c2e                	mv	s8,a1
    80003d2e:	8ab2                	mv	s5,a2
    80003d30:	84b6                	mv	s1,a3
    80003d32:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d34:	9f35                	addw	a4,a4,a3
    return 0;
    80003d36:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d38:	0ad76063          	bltu	a4,a3,80003dd8 <readi+0xd2>
  if(off + n > ip->size)
    80003d3c:	00e7f463          	bgeu	a5,a4,80003d44 <readi+0x3e>
    n = ip->size - off;
    80003d40:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d44:	0a0b0963          	beqz	s6,80003df6 <readi+0xf0>
    80003d48:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d4e:	5cfd                	li	s9,-1
    80003d50:	a82d                	j	80003d8a <readi+0x84>
    80003d52:	020a1d93          	slli	s11,s4,0x20
    80003d56:	020ddd93          	srli	s11,s11,0x20
    80003d5a:	05890613          	addi	a2,s2,88
    80003d5e:	86ee                	mv	a3,s11
    80003d60:	963a                	add	a2,a2,a4
    80003d62:	85d6                	mv	a1,s5
    80003d64:	8562                	mv	a0,s8
    80003d66:	fffff097          	auipc	ra,0xfffff
    80003d6a:	8d6080e7          	jalr	-1834(ra) # 8000263c <either_copyout>
    80003d6e:	05950d63          	beq	a0,s9,80003dc8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d72:	854a                	mv	a0,s2
    80003d74:	fffff097          	auipc	ra,0xfffff
    80003d78:	60c080e7          	jalr	1548(ra) # 80003380 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d7c:	013a09bb          	addw	s3,s4,s3
    80003d80:	009a04bb          	addw	s1,s4,s1
    80003d84:	9aee                	add	s5,s5,s11
    80003d86:	0569f763          	bgeu	s3,s6,80003dd4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d8a:	000ba903          	lw	s2,0(s7)
    80003d8e:	00a4d59b          	srliw	a1,s1,0xa
    80003d92:	855e                	mv	a0,s7
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	8b0080e7          	jalr	-1872(ra) # 80003644 <bmap>
    80003d9c:	0005059b          	sext.w	a1,a0
    80003da0:	854a                	mv	a0,s2
    80003da2:	fffff097          	auipc	ra,0xfffff
    80003da6:	4ae080e7          	jalr	1198(ra) # 80003250 <bread>
    80003daa:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dac:	3ff4f713          	andi	a4,s1,1023
    80003db0:	40ed07bb          	subw	a5,s10,a4
    80003db4:	413b06bb          	subw	a3,s6,s3
    80003db8:	8a3e                	mv	s4,a5
    80003dba:	2781                	sext.w	a5,a5
    80003dbc:	0006861b          	sext.w	a2,a3
    80003dc0:	f8f679e3          	bgeu	a2,a5,80003d52 <readi+0x4c>
    80003dc4:	8a36                	mv	s4,a3
    80003dc6:	b771                	j	80003d52 <readi+0x4c>
      brelse(bp);
    80003dc8:	854a                	mv	a0,s2
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	5b6080e7          	jalr	1462(ra) # 80003380 <brelse>
      tot = -1;
    80003dd2:	59fd                	li	s3,-1
  }
  return tot;
    80003dd4:	0009851b          	sext.w	a0,s3
}
    80003dd8:	70a6                	ld	ra,104(sp)
    80003dda:	7406                	ld	s0,96(sp)
    80003ddc:	64e6                	ld	s1,88(sp)
    80003dde:	6946                	ld	s2,80(sp)
    80003de0:	69a6                	ld	s3,72(sp)
    80003de2:	6a06                	ld	s4,64(sp)
    80003de4:	7ae2                	ld	s5,56(sp)
    80003de6:	7b42                	ld	s6,48(sp)
    80003de8:	7ba2                	ld	s7,40(sp)
    80003dea:	7c02                	ld	s8,32(sp)
    80003dec:	6ce2                	ld	s9,24(sp)
    80003dee:	6d42                	ld	s10,16(sp)
    80003df0:	6da2                	ld	s11,8(sp)
    80003df2:	6165                	addi	sp,sp,112
    80003df4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df6:	89da                	mv	s3,s6
    80003df8:	bff1                	j	80003dd4 <readi+0xce>
    return 0;
    80003dfa:	4501                	li	a0,0
}
    80003dfc:	8082                	ret

0000000080003dfe <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dfe:	457c                	lw	a5,76(a0)
    80003e00:	10d7e863          	bltu	a5,a3,80003f10 <writei+0x112>
{
    80003e04:	7159                	addi	sp,sp,-112
    80003e06:	f486                	sd	ra,104(sp)
    80003e08:	f0a2                	sd	s0,96(sp)
    80003e0a:	eca6                	sd	s1,88(sp)
    80003e0c:	e8ca                	sd	s2,80(sp)
    80003e0e:	e4ce                	sd	s3,72(sp)
    80003e10:	e0d2                	sd	s4,64(sp)
    80003e12:	fc56                	sd	s5,56(sp)
    80003e14:	f85a                	sd	s6,48(sp)
    80003e16:	f45e                	sd	s7,40(sp)
    80003e18:	f062                	sd	s8,32(sp)
    80003e1a:	ec66                	sd	s9,24(sp)
    80003e1c:	e86a                	sd	s10,16(sp)
    80003e1e:	e46e                	sd	s11,8(sp)
    80003e20:	1880                	addi	s0,sp,112
    80003e22:	8b2a                	mv	s6,a0
    80003e24:	8c2e                	mv	s8,a1
    80003e26:	8ab2                	mv	s5,a2
    80003e28:	8936                	mv	s2,a3
    80003e2a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e2c:	00e687bb          	addw	a5,a3,a4
    80003e30:	0ed7e263          	bltu	a5,a3,80003f14 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e34:	00043737          	lui	a4,0x43
    80003e38:	0ef76063          	bltu	a4,a5,80003f18 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e3c:	0c0b8863          	beqz	s7,80003f0c <writei+0x10e>
    80003e40:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e42:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e46:	5cfd                	li	s9,-1
    80003e48:	a091                	j	80003e8c <writei+0x8e>
    80003e4a:	02099d93          	slli	s11,s3,0x20
    80003e4e:	020ddd93          	srli	s11,s11,0x20
    80003e52:	05848513          	addi	a0,s1,88
    80003e56:	86ee                	mv	a3,s11
    80003e58:	8656                	mv	a2,s5
    80003e5a:	85e2                	mv	a1,s8
    80003e5c:	953a                	add	a0,a0,a4
    80003e5e:	fffff097          	auipc	ra,0xfffff
    80003e62:	834080e7          	jalr	-1996(ra) # 80002692 <either_copyin>
    80003e66:	07950263          	beq	a0,s9,80003eca <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e6a:	8526                	mv	a0,s1
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	790080e7          	jalr	1936(ra) # 800045fc <log_write>
    brelse(bp);
    80003e74:	8526                	mv	a0,s1
    80003e76:	fffff097          	auipc	ra,0xfffff
    80003e7a:	50a080e7          	jalr	1290(ra) # 80003380 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e7e:	01498a3b          	addw	s4,s3,s4
    80003e82:	0129893b          	addw	s2,s3,s2
    80003e86:	9aee                	add	s5,s5,s11
    80003e88:	057a7663          	bgeu	s4,s7,80003ed4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e8c:	000b2483          	lw	s1,0(s6)
    80003e90:	00a9559b          	srliw	a1,s2,0xa
    80003e94:	855a                	mv	a0,s6
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	7ae080e7          	jalr	1966(ra) # 80003644 <bmap>
    80003e9e:	0005059b          	sext.w	a1,a0
    80003ea2:	8526                	mv	a0,s1
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	3ac080e7          	jalr	940(ra) # 80003250 <bread>
    80003eac:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eae:	3ff97713          	andi	a4,s2,1023
    80003eb2:	40ed07bb          	subw	a5,s10,a4
    80003eb6:	414b86bb          	subw	a3,s7,s4
    80003eba:	89be                	mv	s3,a5
    80003ebc:	2781                	sext.w	a5,a5
    80003ebe:	0006861b          	sext.w	a2,a3
    80003ec2:	f8f674e3          	bgeu	a2,a5,80003e4a <writei+0x4c>
    80003ec6:	89b6                	mv	s3,a3
    80003ec8:	b749                	j	80003e4a <writei+0x4c>
      brelse(bp);
    80003eca:	8526                	mv	a0,s1
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	4b4080e7          	jalr	1204(ra) # 80003380 <brelse>
  }

  if(off > ip->size)
    80003ed4:	04cb2783          	lw	a5,76(s6)
    80003ed8:	0127f463          	bgeu	a5,s2,80003ee0 <writei+0xe2>
    ip->size = off;
    80003edc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ee0:	855a                	mv	a0,s6
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	aa6080e7          	jalr	-1370(ra) # 80003988 <iupdate>

  return tot;
    80003eea:	000a051b          	sext.w	a0,s4
}
    80003eee:	70a6                	ld	ra,104(sp)
    80003ef0:	7406                	ld	s0,96(sp)
    80003ef2:	64e6                	ld	s1,88(sp)
    80003ef4:	6946                	ld	s2,80(sp)
    80003ef6:	69a6                	ld	s3,72(sp)
    80003ef8:	6a06                	ld	s4,64(sp)
    80003efa:	7ae2                	ld	s5,56(sp)
    80003efc:	7b42                	ld	s6,48(sp)
    80003efe:	7ba2                	ld	s7,40(sp)
    80003f00:	7c02                	ld	s8,32(sp)
    80003f02:	6ce2                	ld	s9,24(sp)
    80003f04:	6d42                	ld	s10,16(sp)
    80003f06:	6da2                	ld	s11,8(sp)
    80003f08:	6165                	addi	sp,sp,112
    80003f0a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f0c:	8a5e                	mv	s4,s7
    80003f0e:	bfc9                	j	80003ee0 <writei+0xe2>
    return -1;
    80003f10:	557d                	li	a0,-1
}
    80003f12:	8082                	ret
    return -1;
    80003f14:	557d                	li	a0,-1
    80003f16:	bfe1                	j	80003eee <writei+0xf0>
    return -1;
    80003f18:	557d                	li	a0,-1
    80003f1a:	bfd1                	j	80003eee <writei+0xf0>

0000000080003f1c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f1c:	1141                	addi	sp,sp,-16
    80003f1e:	e406                	sd	ra,8(sp)
    80003f20:	e022                	sd	s0,0(sp)
    80003f22:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f24:	4639                	li	a2,14
    80003f26:	ffffd097          	auipc	ra,0xffffd
    80003f2a:	e92080e7          	jalr	-366(ra) # 80000db8 <strncmp>
}
    80003f2e:	60a2                	ld	ra,8(sp)
    80003f30:	6402                	ld	s0,0(sp)
    80003f32:	0141                	addi	sp,sp,16
    80003f34:	8082                	ret

0000000080003f36 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f36:	7139                	addi	sp,sp,-64
    80003f38:	fc06                	sd	ra,56(sp)
    80003f3a:	f822                	sd	s0,48(sp)
    80003f3c:	f426                	sd	s1,40(sp)
    80003f3e:	f04a                	sd	s2,32(sp)
    80003f40:	ec4e                	sd	s3,24(sp)
    80003f42:	e852                	sd	s4,16(sp)
    80003f44:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f46:	04451703          	lh	a4,68(a0)
    80003f4a:	4785                	li	a5,1
    80003f4c:	00f71a63          	bne	a4,a5,80003f60 <dirlookup+0x2a>
    80003f50:	892a                	mv	s2,a0
    80003f52:	89ae                	mv	s3,a1
    80003f54:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f56:	457c                	lw	a5,76(a0)
    80003f58:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f5a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5c:	e79d                	bnez	a5,80003f8a <dirlookup+0x54>
    80003f5e:	a8a5                	j	80003fd6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f60:	00004517          	auipc	a0,0x4
    80003f64:	72050513          	addi	a0,a0,1824 # 80008680 <syscalls+0x1c0>
    80003f68:	ffffc097          	auipc	ra,0xffffc
    80003f6c:	5d6080e7          	jalr	1494(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003f70:	00004517          	auipc	a0,0x4
    80003f74:	72850513          	addi	a0,a0,1832 # 80008698 <syscalls+0x1d8>
    80003f78:	ffffc097          	auipc	ra,0xffffc
    80003f7c:	5c6080e7          	jalr	1478(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f80:	24c1                	addiw	s1,s1,16
    80003f82:	04c92783          	lw	a5,76(s2)
    80003f86:	04f4f763          	bgeu	s1,a5,80003fd4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f8a:	4741                	li	a4,16
    80003f8c:	86a6                	mv	a3,s1
    80003f8e:	fc040613          	addi	a2,s0,-64
    80003f92:	4581                	li	a1,0
    80003f94:	854a                	mv	a0,s2
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	d70080e7          	jalr	-656(ra) # 80003d06 <readi>
    80003f9e:	47c1                	li	a5,16
    80003fa0:	fcf518e3          	bne	a0,a5,80003f70 <dirlookup+0x3a>
    if(de.inum == 0)
    80003fa4:	fc045783          	lhu	a5,-64(s0)
    80003fa8:	dfe1                	beqz	a5,80003f80 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003faa:	fc240593          	addi	a1,s0,-62
    80003fae:	854e                	mv	a0,s3
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	f6c080e7          	jalr	-148(ra) # 80003f1c <namecmp>
    80003fb8:	f561                	bnez	a0,80003f80 <dirlookup+0x4a>
      if(poff)
    80003fba:	000a0463          	beqz	s4,80003fc2 <dirlookup+0x8c>
        *poff = off;
    80003fbe:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fc2:	fc045583          	lhu	a1,-64(s0)
    80003fc6:	00092503          	lw	a0,0(s2)
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	754080e7          	jalr	1876(ra) # 8000371e <iget>
    80003fd2:	a011                	j	80003fd6 <dirlookup+0xa0>
  return 0;
    80003fd4:	4501                	li	a0,0
}
    80003fd6:	70e2                	ld	ra,56(sp)
    80003fd8:	7442                	ld	s0,48(sp)
    80003fda:	74a2                	ld	s1,40(sp)
    80003fdc:	7902                	ld	s2,32(sp)
    80003fde:	69e2                	ld	s3,24(sp)
    80003fe0:	6a42                	ld	s4,16(sp)
    80003fe2:	6121                	addi	sp,sp,64
    80003fe4:	8082                	ret

0000000080003fe6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fe6:	711d                	addi	sp,sp,-96
    80003fe8:	ec86                	sd	ra,88(sp)
    80003fea:	e8a2                	sd	s0,80(sp)
    80003fec:	e4a6                	sd	s1,72(sp)
    80003fee:	e0ca                	sd	s2,64(sp)
    80003ff0:	fc4e                	sd	s3,56(sp)
    80003ff2:	f852                	sd	s4,48(sp)
    80003ff4:	f456                	sd	s5,40(sp)
    80003ff6:	f05a                	sd	s6,32(sp)
    80003ff8:	ec5e                	sd	s7,24(sp)
    80003ffa:	e862                	sd	s8,16(sp)
    80003ffc:	e466                	sd	s9,8(sp)
    80003ffe:	1080                	addi	s0,sp,96
    80004000:	84aa                	mv	s1,a0
    80004002:	8b2e                	mv	s6,a1
    80004004:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004006:	00054703          	lbu	a4,0(a0)
    8000400a:	02f00793          	li	a5,47
    8000400e:	02f70363          	beq	a4,a5,80004034 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004012:	ffffe097          	auipc	ra,0xffffe
    80004016:	a36080e7          	jalr	-1482(ra) # 80001a48 <myproc>
    8000401a:	15053503          	ld	a0,336(a0)
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	9f6080e7          	jalr	-1546(ra) # 80003a14 <idup>
    80004026:	89aa                	mv	s3,a0
  while(*path == '/')
    80004028:	02f00913          	li	s2,47
  len = path - s;
    8000402c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000402e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004030:	4c05                	li	s8,1
    80004032:	a865                	j	800040ea <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004034:	4585                	li	a1,1
    80004036:	4505                	li	a0,1
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	6e6080e7          	jalr	1766(ra) # 8000371e <iget>
    80004040:	89aa                	mv	s3,a0
    80004042:	b7dd                	j	80004028 <namex+0x42>
      iunlockput(ip);
    80004044:	854e                	mv	a0,s3
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	c6e080e7          	jalr	-914(ra) # 80003cb4 <iunlockput>
      return 0;
    8000404e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004050:	854e                	mv	a0,s3
    80004052:	60e6                	ld	ra,88(sp)
    80004054:	6446                	ld	s0,80(sp)
    80004056:	64a6                	ld	s1,72(sp)
    80004058:	6906                	ld	s2,64(sp)
    8000405a:	79e2                	ld	s3,56(sp)
    8000405c:	7a42                	ld	s4,48(sp)
    8000405e:	7aa2                	ld	s5,40(sp)
    80004060:	7b02                	ld	s6,32(sp)
    80004062:	6be2                	ld	s7,24(sp)
    80004064:	6c42                	ld	s8,16(sp)
    80004066:	6ca2                	ld	s9,8(sp)
    80004068:	6125                	addi	sp,sp,96
    8000406a:	8082                	ret
      iunlock(ip);
    8000406c:	854e                	mv	a0,s3
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	aa6080e7          	jalr	-1370(ra) # 80003b14 <iunlock>
      return ip;
    80004076:	bfe9                	j	80004050 <namex+0x6a>
      iunlockput(ip);
    80004078:	854e                	mv	a0,s3
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	c3a080e7          	jalr	-966(ra) # 80003cb4 <iunlockput>
      return 0;
    80004082:	89d2                	mv	s3,s4
    80004084:	b7f1                	j	80004050 <namex+0x6a>
  len = path - s;
    80004086:	40b48633          	sub	a2,s1,a1
    8000408a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000408e:	094cd463          	bge	s9,s4,80004116 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004092:	4639                	li	a2,14
    80004094:	8556                	mv	a0,s5
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	caa080e7          	jalr	-854(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000409e:	0004c783          	lbu	a5,0(s1)
    800040a2:	01279763          	bne	a5,s2,800040b0 <namex+0xca>
    path++;
    800040a6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040a8:	0004c783          	lbu	a5,0(s1)
    800040ac:	ff278de3          	beq	a5,s2,800040a6 <namex+0xc0>
    ilock(ip);
    800040b0:	854e                	mv	a0,s3
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	9a0080e7          	jalr	-1632(ra) # 80003a52 <ilock>
    if(ip->type != T_DIR){
    800040ba:	04499783          	lh	a5,68(s3)
    800040be:	f98793e3          	bne	a5,s8,80004044 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040c2:	000b0563          	beqz	s6,800040cc <namex+0xe6>
    800040c6:	0004c783          	lbu	a5,0(s1)
    800040ca:	d3cd                	beqz	a5,8000406c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040cc:	865e                	mv	a2,s7
    800040ce:	85d6                	mv	a1,s5
    800040d0:	854e                	mv	a0,s3
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	e64080e7          	jalr	-412(ra) # 80003f36 <dirlookup>
    800040da:	8a2a                	mv	s4,a0
    800040dc:	dd51                	beqz	a0,80004078 <namex+0x92>
    iunlockput(ip);
    800040de:	854e                	mv	a0,s3
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	bd4080e7          	jalr	-1068(ra) # 80003cb4 <iunlockput>
    ip = next;
    800040e8:	89d2                	mv	s3,s4
  while(*path == '/')
    800040ea:	0004c783          	lbu	a5,0(s1)
    800040ee:	05279763          	bne	a5,s2,8000413c <namex+0x156>
    path++;
    800040f2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040f4:	0004c783          	lbu	a5,0(s1)
    800040f8:	ff278de3          	beq	a5,s2,800040f2 <namex+0x10c>
  if(*path == 0)
    800040fc:	c79d                	beqz	a5,8000412a <namex+0x144>
    path++;
    800040fe:	85a6                	mv	a1,s1
  len = path - s;
    80004100:	8a5e                	mv	s4,s7
    80004102:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004104:	01278963          	beq	a5,s2,80004116 <namex+0x130>
    80004108:	dfbd                	beqz	a5,80004086 <namex+0xa0>
    path++;
    8000410a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000410c:	0004c783          	lbu	a5,0(s1)
    80004110:	ff279ce3          	bne	a5,s2,80004108 <namex+0x122>
    80004114:	bf8d                	j	80004086 <namex+0xa0>
    memmove(name, s, len);
    80004116:	2601                	sext.w	a2,a2
    80004118:	8556                	mv	a0,s5
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	c26080e7          	jalr	-986(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004122:	9a56                	add	s4,s4,s5
    80004124:	000a0023          	sb	zero,0(s4)
    80004128:	bf9d                	j	8000409e <namex+0xb8>
  if(nameiparent){
    8000412a:	f20b03e3          	beqz	s6,80004050 <namex+0x6a>
    iput(ip);
    8000412e:	854e                	mv	a0,s3
    80004130:	00000097          	auipc	ra,0x0
    80004134:	adc080e7          	jalr	-1316(ra) # 80003c0c <iput>
    return 0;
    80004138:	4981                	li	s3,0
    8000413a:	bf19                	j	80004050 <namex+0x6a>
  if(*path == 0)
    8000413c:	d7fd                	beqz	a5,8000412a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000413e:	0004c783          	lbu	a5,0(s1)
    80004142:	85a6                	mv	a1,s1
    80004144:	b7d1                	j	80004108 <namex+0x122>

0000000080004146 <dirlink>:
{
    80004146:	7139                	addi	sp,sp,-64
    80004148:	fc06                	sd	ra,56(sp)
    8000414a:	f822                	sd	s0,48(sp)
    8000414c:	f426                	sd	s1,40(sp)
    8000414e:	f04a                	sd	s2,32(sp)
    80004150:	ec4e                	sd	s3,24(sp)
    80004152:	e852                	sd	s4,16(sp)
    80004154:	0080                	addi	s0,sp,64
    80004156:	892a                	mv	s2,a0
    80004158:	8a2e                	mv	s4,a1
    8000415a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000415c:	4601                	li	a2,0
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	dd8080e7          	jalr	-552(ra) # 80003f36 <dirlookup>
    80004166:	e93d                	bnez	a0,800041dc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004168:	04c92483          	lw	s1,76(s2)
    8000416c:	c49d                	beqz	s1,8000419a <dirlink+0x54>
    8000416e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004170:	4741                	li	a4,16
    80004172:	86a6                	mv	a3,s1
    80004174:	fc040613          	addi	a2,s0,-64
    80004178:	4581                	li	a1,0
    8000417a:	854a                	mv	a0,s2
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	b8a080e7          	jalr	-1142(ra) # 80003d06 <readi>
    80004184:	47c1                	li	a5,16
    80004186:	06f51163          	bne	a0,a5,800041e8 <dirlink+0xa2>
    if(de.inum == 0)
    8000418a:	fc045783          	lhu	a5,-64(s0)
    8000418e:	c791                	beqz	a5,8000419a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004190:	24c1                	addiw	s1,s1,16
    80004192:	04c92783          	lw	a5,76(s2)
    80004196:	fcf4ede3          	bltu	s1,a5,80004170 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000419a:	4639                	li	a2,14
    8000419c:	85d2                	mv	a1,s4
    8000419e:	fc240513          	addi	a0,s0,-62
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	c52080e7          	jalr	-942(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800041aa:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ae:	4741                	li	a4,16
    800041b0:	86a6                	mv	a3,s1
    800041b2:	fc040613          	addi	a2,s0,-64
    800041b6:	4581                	li	a1,0
    800041b8:	854a                	mv	a0,s2
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	c44080e7          	jalr	-956(ra) # 80003dfe <writei>
    800041c2:	872a                	mv	a4,a0
    800041c4:	47c1                	li	a5,16
  return 0;
    800041c6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041c8:	02f71863          	bne	a4,a5,800041f8 <dirlink+0xb2>
}
    800041cc:	70e2                	ld	ra,56(sp)
    800041ce:	7442                	ld	s0,48(sp)
    800041d0:	74a2                	ld	s1,40(sp)
    800041d2:	7902                	ld	s2,32(sp)
    800041d4:	69e2                	ld	s3,24(sp)
    800041d6:	6a42                	ld	s4,16(sp)
    800041d8:	6121                	addi	sp,sp,64
    800041da:	8082                	ret
    iput(ip);
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	a30080e7          	jalr	-1488(ra) # 80003c0c <iput>
    return -1;
    800041e4:	557d                	li	a0,-1
    800041e6:	b7dd                	j	800041cc <dirlink+0x86>
      panic("dirlink read");
    800041e8:	00004517          	auipc	a0,0x4
    800041ec:	4c050513          	addi	a0,a0,1216 # 800086a8 <syscalls+0x1e8>
    800041f0:	ffffc097          	auipc	ra,0xffffc
    800041f4:	34e080e7          	jalr	846(ra) # 8000053e <panic>
    panic("dirlink");
    800041f8:	00004517          	auipc	a0,0x4
    800041fc:	5c050513          	addi	a0,a0,1472 # 800087b8 <syscalls+0x2f8>
    80004200:	ffffc097          	auipc	ra,0xffffc
    80004204:	33e080e7          	jalr	830(ra) # 8000053e <panic>

0000000080004208 <namei>:

struct inode*
namei(char *path)
{
    80004208:	1101                	addi	sp,sp,-32
    8000420a:	ec06                	sd	ra,24(sp)
    8000420c:	e822                	sd	s0,16(sp)
    8000420e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004210:	fe040613          	addi	a2,s0,-32
    80004214:	4581                	li	a1,0
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	dd0080e7          	jalr	-560(ra) # 80003fe6 <namex>
}
    8000421e:	60e2                	ld	ra,24(sp)
    80004220:	6442                	ld	s0,16(sp)
    80004222:	6105                	addi	sp,sp,32
    80004224:	8082                	ret

0000000080004226 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004226:	1141                	addi	sp,sp,-16
    80004228:	e406                	sd	ra,8(sp)
    8000422a:	e022                	sd	s0,0(sp)
    8000422c:	0800                	addi	s0,sp,16
    8000422e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004230:	4585                	li	a1,1
    80004232:	00000097          	auipc	ra,0x0
    80004236:	db4080e7          	jalr	-588(ra) # 80003fe6 <namex>
}
    8000423a:	60a2                	ld	ra,8(sp)
    8000423c:	6402                	ld	s0,0(sp)
    8000423e:	0141                	addi	sp,sp,16
    80004240:	8082                	ret

0000000080004242 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004242:	1101                	addi	sp,sp,-32
    80004244:	ec06                	sd	ra,24(sp)
    80004246:	e822                	sd	s0,16(sp)
    80004248:	e426                	sd	s1,8(sp)
    8000424a:	e04a                	sd	s2,0(sp)
    8000424c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000424e:	00016917          	auipc	s2,0x16
    80004252:	1b290913          	addi	s2,s2,434 # 8001a400 <log>
    80004256:	01892583          	lw	a1,24(s2)
    8000425a:	02892503          	lw	a0,40(s2)
    8000425e:	fffff097          	auipc	ra,0xfffff
    80004262:	ff2080e7          	jalr	-14(ra) # 80003250 <bread>
    80004266:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004268:	02c92683          	lw	a3,44(s2)
    8000426c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000426e:	02d05763          	blez	a3,8000429c <write_head+0x5a>
    80004272:	00016797          	auipc	a5,0x16
    80004276:	1be78793          	addi	a5,a5,446 # 8001a430 <log+0x30>
    8000427a:	05c50713          	addi	a4,a0,92
    8000427e:	36fd                	addiw	a3,a3,-1
    80004280:	1682                	slli	a3,a3,0x20
    80004282:	9281                	srli	a3,a3,0x20
    80004284:	068a                	slli	a3,a3,0x2
    80004286:	00016617          	auipc	a2,0x16
    8000428a:	1ae60613          	addi	a2,a2,430 # 8001a434 <log+0x34>
    8000428e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004290:	4390                	lw	a2,0(a5)
    80004292:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004294:	0791                	addi	a5,a5,4
    80004296:	0711                	addi	a4,a4,4
    80004298:	fed79ce3          	bne	a5,a3,80004290 <write_head+0x4e>
  }
  bwrite(buf);
    8000429c:	8526                	mv	a0,s1
    8000429e:	fffff097          	auipc	ra,0xfffff
    800042a2:	0a4080e7          	jalr	164(ra) # 80003342 <bwrite>
  brelse(buf);
    800042a6:	8526                	mv	a0,s1
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	0d8080e7          	jalr	216(ra) # 80003380 <brelse>
}
    800042b0:	60e2                	ld	ra,24(sp)
    800042b2:	6442                	ld	s0,16(sp)
    800042b4:	64a2                	ld	s1,8(sp)
    800042b6:	6902                	ld	s2,0(sp)
    800042b8:	6105                	addi	sp,sp,32
    800042ba:	8082                	ret

00000000800042bc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042bc:	00016797          	auipc	a5,0x16
    800042c0:	1707a783          	lw	a5,368(a5) # 8001a42c <log+0x2c>
    800042c4:	0af05d63          	blez	a5,8000437e <install_trans+0xc2>
{
    800042c8:	7139                	addi	sp,sp,-64
    800042ca:	fc06                	sd	ra,56(sp)
    800042cc:	f822                	sd	s0,48(sp)
    800042ce:	f426                	sd	s1,40(sp)
    800042d0:	f04a                	sd	s2,32(sp)
    800042d2:	ec4e                	sd	s3,24(sp)
    800042d4:	e852                	sd	s4,16(sp)
    800042d6:	e456                	sd	s5,8(sp)
    800042d8:	e05a                	sd	s6,0(sp)
    800042da:	0080                	addi	s0,sp,64
    800042dc:	8b2a                	mv	s6,a0
    800042de:	00016a97          	auipc	s5,0x16
    800042e2:	152a8a93          	addi	s5,s5,338 # 8001a430 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042e8:	00016997          	auipc	s3,0x16
    800042ec:	11898993          	addi	s3,s3,280 # 8001a400 <log>
    800042f0:	a035                	j	8000431c <install_trans+0x60>
      bunpin(dbuf);
    800042f2:	8526                	mv	a0,s1
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	166080e7          	jalr	358(ra) # 8000345a <bunpin>
    brelse(lbuf);
    800042fc:	854a                	mv	a0,s2
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	082080e7          	jalr	130(ra) # 80003380 <brelse>
    brelse(dbuf);
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	078080e7          	jalr	120(ra) # 80003380 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004310:	2a05                	addiw	s4,s4,1
    80004312:	0a91                	addi	s5,s5,4
    80004314:	02c9a783          	lw	a5,44(s3)
    80004318:	04fa5963          	bge	s4,a5,8000436a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000431c:	0189a583          	lw	a1,24(s3)
    80004320:	014585bb          	addw	a1,a1,s4
    80004324:	2585                	addiw	a1,a1,1
    80004326:	0289a503          	lw	a0,40(s3)
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	f26080e7          	jalr	-218(ra) # 80003250 <bread>
    80004332:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004334:	000aa583          	lw	a1,0(s5)
    80004338:	0289a503          	lw	a0,40(s3)
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	f14080e7          	jalr	-236(ra) # 80003250 <bread>
    80004344:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004346:	40000613          	li	a2,1024
    8000434a:	05890593          	addi	a1,s2,88
    8000434e:	05850513          	addi	a0,a0,88
    80004352:	ffffd097          	auipc	ra,0xffffd
    80004356:	9ee080e7          	jalr	-1554(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000435a:	8526                	mv	a0,s1
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	fe6080e7          	jalr	-26(ra) # 80003342 <bwrite>
    if(recovering == 0)
    80004364:	f80b1ce3          	bnez	s6,800042fc <install_trans+0x40>
    80004368:	b769                	j	800042f2 <install_trans+0x36>
}
    8000436a:	70e2                	ld	ra,56(sp)
    8000436c:	7442                	ld	s0,48(sp)
    8000436e:	74a2                	ld	s1,40(sp)
    80004370:	7902                	ld	s2,32(sp)
    80004372:	69e2                	ld	s3,24(sp)
    80004374:	6a42                	ld	s4,16(sp)
    80004376:	6aa2                	ld	s5,8(sp)
    80004378:	6b02                	ld	s6,0(sp)
    8000437a:	6121                	addi	sp,sp,64
    8000437c:	8082                	ret
    8000437e:	8082                	ret

0000000080004380 <initlog>:
{
    80004380:	7179                	addi	sp,sp,-48
    80004382:	f406                	sd	ra,40(sp)
    80004384:	f022                	sd	s0,32(sp)
    80004386:	ec26                	sd	s1,24(sp)
    80004388:	e84a                	sd	s2,16(sp)
    8000438a:	e44e                	sd	s3,8(sp)
    8000438c:	1800                	addi	s0,sp,48
    8000438e:	892a                	mv	s2,a0
    80004390:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004392:	00016497          	auipc	s1,0x16
    80004396:	06e48493          	addi	s1,s1,110 # 8001a400 <log>
    8000439a:	00004597          	auipc	a1,0x4
    8000439e:	31e58593          	addi	a1,a1,798 # 800086b8 <syscalls+0x1f8>
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffc097          	auipc	ra,0xffffc
    800043a8:	7b0080e7          	jalr	1968(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800043ac:	0149a583          	lw	a1,20(s3)
    800043b0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043b2:	0109a783          	lw	a5,16(s3)
    800043b6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043b8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043bc:	854a                	mv	a0,s2
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	e92080e7          	jalr	-366(ra) # 80003250 <bread>
  log.lh.n = lh->n;
    800043c6:	4d3c                	lw	a5,88(a0)
    800043c8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043ca:	02f05563          	blez	a5,800043f4 <initlog+0x74>
    800043ce:	05c50713          	addi	a4,a0,92
    800043d2:	00016697          	auipc	a3,0x16
    800043d6:	05e68693          	addi	a3,a3,94 # 8001a430 <log+0x30>
    800043da:	37fd                	addiw	a5,a5,-1
    800043dc:	1782                	slli	a5,a5,0x20
    800043de:	9381                	srli	a5,a5,0x20
    800043e0:	078a                	slli	a5,a5,0x2
    800043e2:	06050613          	addi	a2,a0,96
    800043e6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800043e8:	4310                	lw	a2,0(a4)
    800043ea:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800043ec:	0711                	addi	a4,a4,4
    800043ee:	0691                	addi	a3,a3,4
    800043f0:	fef71ce3          	bne	a4,a5,800043e8 <initlog+0x68>
  brelse(buf);
    800043f4:	fffff097          	auipc	ra,0xfffff
    800043f8:	f8c080e7          	jalr	-116(ra) # 80003380 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043fc:	4505                	li	a0,1
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	ebe080e7          	jalr	-322(ra) # 800042bc <install_trans>
  log.lh.n = 0;
    80004406:	00016797          	auipc	a5,0x16
    8000440a:	0207a323          	sw	zero,38(a5) # 8001a42c <log+0x2c>
  write_head(); // clear the log
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	e34080e7          	jalr	-460(ra) # 80004242 <write_head>
}
    80004416:	70a2                	ld	ra,40(sp)
    80004418:	7402                	ld	s0,32(sp)
    8000441a:	64e2                	ld	s1,24(sp)
    8000441c:	6942                	ld	s2,16(sp)
    8000441e:	69a2                	ld	s3,8(sp)
    80004420:	6145                	addi	sp,sp,48
    80004422:	8082                	ret

0000000080004424 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	e04a                	sd	s2,0(sp)
    8000442e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004430:	00016517          	auipc	a0,0x16
    80004434:	fd050513          	addi	a0,a0,-48 # 8001a400 <log>
    80004438:	ffffc097          	auipc	ra,0xffffc
    8000443c:	7ac080e7          	jalr	1964(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004440:	00016497          	auipc	s1,0x16
    80004444:	fc048493          	addi	s1,s1,-64 # 8001a400 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004448:	4979                	li	s2,30
    8000444a:	a039                	j	80004458 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000444c:	85a6                	mv	a1,s1
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffe097          	auipc	ra,0xffffe
    80004454:	e12080e7          	jalr	-494(ra) # 80002262 <sleep>
    if(log.committing){
    80004458:	50dc                	lw	a5,36(s1)
    8000445a:	fbed                	bnez	a5,8000444c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000445c:	509c                	lw	a5,32(s1)
    8000445e:	0017871b          	addiw	a4,a5,1
    80004462:	0007069b          	sext.w	a3,a4
    80004466:	0027179b          	slliw	a5,a4,0x2
    8000446a:	9fb9                	addw	a5,a5,a4
    8000446c:	0017979b          	slliw	a5,a5,0x1
    80004470:	54d8                	lw	a4,44(s1)
    80004472:	9fb9                	addw	a5,a5,a4
    80004474:	00f95963          	bge	s2,a5,80004486 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004478:	85a6                	mv	a1,s1
    8000447a:	8526                	mv	a0,s1
    8000447c:	ffffe097          	auipc	ra,0xffffe
    80004480:	de6080e7          	jalr	-538(ra) # 80002262 <sleep>
    80004484:	bfd1                	j	80004458 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004486:	00016517          	auipc	a0,0x16
    8000448a:	f7a50513          	addi	a0,a0,-134 # 8001a400 <log>
    8000448e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004490:	ffffd097          	auipc	ra,0xffffd
    80004494:	808080e7          	jalr	-2040(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004498:	60e2                	ld	ra,24(sp)
    8000449a:	6442                	ld	s0,16(sp)
    8000449c:	64a2                	ld	s1,8(sp)
    8000449e:	6902                	ld	s2,0(sp)
    800044a0:	6105                	addi	sp,sp,32
    800044a2:	8082                	ret

00000000800044a4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044a4:	7139                	addi	sp,sp,-64
    800044a6:	fc06                	sd	ra,56(sp)
    800044a8:	f822                	sd	s0,48(sp)
    800044aa:	f426                	sd	s1,40(sp)
    800044ac:	f04a                	sd	s2,32(sp)
    800044ae:	ec4e                	sd	s3,24(sp)
    800044b0:	e852                	sd	s4,16(sp)
    800044b2:	e456                	sd	s5,8(sp)
    800044b4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044b6:	00016497          	auipc	s1,0x16
    800044ba:	f4a48493          	addi	s1,s1,-182 # 8001a400 <log>
    800044be:	8526                	mv	a0,s1
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	724080e7          	jalr	1828(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800044c8:	509c                	lw	a5,32(s1)
    800044ca:	37fd                	addiw	a5,a5,-1
    800044cc:	0007891b          	sext.w	s2,a5
    800044d0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044d2:	50dc                	lw	a5,36(s1)
    800044d4:	efb9                	bnez	a5,80004532 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044d6:	06091663          	bnez	s2,80004542 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800044da:	00016497          	auipc	s1,0x16
    800044de:	f2648493          	addi	s1,s1,-218 # 8001a400 <log>
    800044e2:	4785                	li	a5,1
    800044e4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044e6:	8526                	mv	a0,s1
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	7b0080e7          	jalr	1968(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044f0:	54dc                	lw	a5,44(s1)
    800044f2:	06f04763          	bgtz	a5,80004560 <end_op+0xbc>
    acquire(&log.lock);
    800044f6:	00016497          	auipc	s1,0x16
    800044fa:	f0a48493          	addi	s1,s1,-246 # 8001a400 <log>
    800044fe:	8526                	mv	a0,s1
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	6e4080e7          	jalr	1764(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004508:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000450c:	8526                	mv	a0,s1
    8000450e:	ffffe097          	auipc	ra,0xffffe
    80004512:	ee0080e7          	jalr	-288(ra) # 800023ee <wakeup>
    release(&log.lock);
    80004516:	8526                	mv	a0,s1
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	780080e7          	jalr	1920(ra) # 80000c98 <release>
}
    80004520:	70e2                	ld	ra,56(sp)
    80004522:	7442                	ld	s0,48(sp)
    80004524:	74a2                	ld	s1,40(sp)
    80004526:	7902                	ld	s2,32(sp)
    80004528:	69e2                	ld	s3,24(sp)
    8000452a:	6a42                	ld	s4,16(sp)
    8000452c:	6aa2                	ld	s5,8(sp)
    8000452e:	6121                	addi	sp,sp,64
    80004530:	8082                	ret
    panic("log.committing");
    80004532:	00004517          	auipc	a0,0x4
    80004536:	18e50513          	addi	a0,a0,398 # 800086c0 <syscalls+0x200>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	004080e7          	jalr	4(ra) # 8000053e <panic>
    wakeup(&log);
    80004542:	00016497          	auipc	s1,0x16
    80004546:	ebe48493          	addi	s1,s1,-322 # 8001a400 <log>
    8000454a:	8526                	mv	a0,s1
    8000454c:	ffffe097          	auipc	ra,0xffffe
    80004550:	ea2080e7          	jalr	-350(ra) # 800023ee <wakeup>
  release(&log.lock);
    80004554:	8526                	mv	a0,s1
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	742080e7          	jalr	1858(ra) # 80000c98 <release>
  if(do_commit){
    8000455e:	b7c9                	j	80004520 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004560:	00016a97          	auipc	s5,0x16
    80004564:	ed0a8a93          	addi	s5,s5,-304 # 8001a430 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004568:	00016a17          	auipc	s4,0x16
    8000456c:	e98a0a13          	addi	s4,s4,-360 # 8001a400 <log>
    80004570:	018a2583          	lw	a1,24(s4)
    80004574:	012585bb          	addw	a1,a1,s2
    80004578:	2585                	addiw	a1,a1,1
    8000457a:	028a2503          	lw	a0,40(s4)
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	cd2080e7          	jalr	-814(ra) # 80003250 <bread>
    80004586:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004588:	000aa583          	lw	a1,0(s5)
    8000458c:	028a2503          	lw	a0,40(s4)
    80004590:	fffff097          	auipc	ra,0xfffff
    80004594:	cc0080e7          	jalr	-832(ra) # 80003250 <bread>
    80004598:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000459a:	40000613          	li	a2,1024
    8000459e:	05850593          	addi	a1,a0,88
    800045a2:	05848513          	addi	a0,s1,88
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	79a080e7          	jalr	1946(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800045ae:	8526                	mv	a0,s1
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	d92080e7          	jalr	-622(ra) # 80003342 <bwrite>
    brelse(from);
    800045b8:	854e                	mv	a0,s3
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	dc6080e7          	jalr	-570(ra) # 80003380 <brelse>
    brelse(to);
    800045c2:	8526                	mv	a0,s1
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	dbc080e7          	jalr	-580(ra) # 80003380 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045cc:	2905                	addiw	s2,s2,1
    800045ce:	0a91                	addi	s5,s5,4
    800045d0:	02ca2783          	lw	a5,44(s4)
    800045d4:	f8f94ee3          	blt	s2,a5,80004570 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045d8:	00000097          	auipc	ra,0x0
    800045dc:	c6a080e7          	jalr	-918(ra) # 80004242 <write_head>
    install_trans(0); // Now install writes to home locations
    800045e0:	4501                	li	a0,0
    800045e2:	00000097          	auipc	ra,0x0
    800045e6:	cda080e7          	jalr	-806(ra) # 800042bc <install_trans>
    log.lh.n = 0;
    800045ea:	00016797          	auipc	a5,0x16
    800045ee:	e407a123          	sw	zero,-446(a5) # 8001a42c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045f2:	00000097          	auipc	ra,0x0
    800045f6:	c50080e7          	jalr	-944(ra) # 80004242 <write_head>
    800045fa:	bdf5                	j	800044f6 <end_op+0x52>

00000000800045fc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045fc:	1101                	addi	sp,sp,-32
    800045fe:	ec06                	sd	ra,24(sp)
    80004600:	e822                	sd	s0,16(sp)
    80004602:	e426                	sd	s1,8(sp)
    80004604:	e04a                	sd	s2,0(sp)
    80004606:	1000                	addi	s0,sp,32
    80004608:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000460a:	00016917          	auipc	s2,0x16
    8000460e:	df690913          	addi	s2,s2,-522 # 8001a400 <log>
    80004612:	854a                	mv	a0,s2
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	5d0080e7          	jalr	1488(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000461c:	02c92603          	lw	a2,44(s2)
    80004620:	47f5                	li	a5,29
    80004622:	06c7c563          	blt	a5,a2,8000468c <log_write+0x90>
    80004626:	00016797          	auipc	a5,0x16
    8000462a:	df67a783          	lw	a5,-522(a5) # 8001a41c <log+0x1c>
    8000462e:	37fd                	addiw	a5,a5,-1
    80004630:	04f65e63          	bge	a2,a5,8000468c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004634:	00016797          	auipc	a5,0x16
    80004638:	dec7a783          	lw	a5,-532(a5) # 8001a420 <log+0x20>
    8000463c:	06f05063          	blez	a5,8000469c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004640:	4781                	li	a5,0
    80004642:	06c05563          	blez	a2,800046ac <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004646:	44cc                	lw	a1,12(s1)
    80004648:	00016717          	auipc	a4,0x16
    8000464c:	de870713          	addi	a4,a4,-536 # 8001a430 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004650:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004652:	4314                	lw	a3,0(a4)
    80004654:	04b68c63          	beq	a3,a1,800046ac <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004658:	2785                	addiw	a5,a5,1
    8000465a:	0711                	addi	a4,a4,4
    8000465c:	fef61be3          	bne	a2,a5,80004652 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004660:	0621                	addi	a2,a2,8
    80004662:	060a                	slli	a2,a2,0x2
    80004664:	00016797          	auipc	a5,0x16
    80004668:	d9c78793          	addi	a5,a5,-612 # 8001a400 <log>
    8000466c:	963e                	add	a2,a2,a5
    8000466e:	44dc                	lw	a5,12(s1)
    80004670:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004672:	8526                	mv	a0,s1
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	daa080e7          	jalr	-598(ra) # 8000341e <bpin>
    log.lh.n++;
    8000467c:	00016717          	auipc	a4,0x16
    80004680:	d8470713          	addi	a4,a4,-636 # 8001a400 <log>
    80004684:	575c                	lw	a5,44(a4)
    80004686:	2785                	addiw	a5,a5,1
    80004688:	d75c                	sw	a5,44(a4)
    8000468a:	a835                	j	800046c6 <log_write+0xca>
    panic("too big a transaction");
    8000468c:	00004517          	auipc	a0,0x4
    80004690:	04450513          	addi	a0,a0,68 # 800086d0 <syscalls+0x210>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	eaa080e7          	jalr	-342(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000469c:	00004517          	auipc	a0,0x4
    800046a0:	04c50513          	addi	a0,a0,76 # 800086e8 <syscalls+0x228>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	e9a080e7          	jalr	-358(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800046ac:	00878713          	addi	a4,a5,8
    800046b0:	00271693          	slli	a3,a4,0x2
    800046b4:	00016717          	auipc	a4,0x16
    800046b8:	d4c70713          	addi	a4,a4,-692 # 8001a400 <log>
    800046bc:	9736                	add	a4,a4,a3
    800046be:	44d4                	lw	a3,12(s1)
    800046c0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046c2:	faf608e3          	beq	a2,a5,80004672 <log_write+0x76>
  }
  release(&log.lock);
    800046c6:	00016517          	auipc	a0,0x16
    800046ca:	d3a50513          	addi	a0,a0,-710 # 8001a400 <log>
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	5ca080e7          	jalr	1482(ra) # 80000c98 <release>
}
    800046d6:	60e2                	ld	ra,24(sp)
    800046d8:	6442                	ld	s0,16(sp)
    800046da:	64a2                	ld	s1,8(sp)
    800046dc:	6902                	ld	s2,0(sp)
    800046de:	6105                	addi	sp,sp,32
    800046e0:	8082                	ret

00000000800046e2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046e2:	1101                	addi	sp,sp,-32
    800046e4:	ec06                	sd	ra,24(sp)
    800046e6:	e822                	sd	s0,16(sp)
    800046e8:	e426                	sd	s1,8(sp)
    800046ea:	e04a                	sd	s2,0(sp)
    800046ec:	1000                	addi	s0,sp,32
    800046ee:	84aa                	mv	s1,a0
    800046f0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046f2:	00004597          	auipc	a1,0x4
    800046f6:	01658593          	addi	a1,a1,22 # 80008708 <syscalls+0x248>
    800046fa:	0521                	addi	a0,a0,8
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	458080e7          	jalr	1112(ra) # 80000b54 <initlock>
  lk->name = name;
    80004704:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004708:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000470c:	0204a423          	sw	zero,40(s1)
}
    80004710:	60e2                	ld	ra,24(sp)
    80004712:	6442                	ld	s0,16(sp)
    80004714:	64a2                	ld	s1,8(sp)
    80004716:	6902                	ld	s2,0(sp)
    80004718:	6105                	addi	sp,sp,32
    8000471a:	8082                	ret

000000008000471c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000471c:	1101                	addi	sp,sp,-32
    8000471e:	ec06                	sd	ra,24(sp)
    80004720:	e822                	sd	s0,16(sp)
    80004722:	e426                	sd	s1,8(sp)
    80004724:	e04a                	sd	s2,0(sp)
    80004726:	1000                	addi	s0,sp,32
    80004728:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000472a:	00850913          	addi	s2,a0,8
    8000472e:	854a                	mv	a0,s2
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4b4080e7          	jalr	1204(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004738:	409c                	lw	a5,0(s1)
    8000473a:	cb89                	beqz	a5,8000474c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000473c:	85ca                	mv	a1,s2
    8000473e:	8526                	mv	a0,s1
    80004740:	ffffe097          	auipc	ra,0xffffe
    80004744:	b22080e7          	jalr	-1246(ra) # 80002262 <sleep>
  while (lk->locked) {
    80004748:	409c                	lw	a5,0(s1)
    8000474a:	fbed                	bnez	a5,8000473c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000474c:	4785                	li	a5,1
    8000474e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004750:	ffffd097          	auipc	ra,0xffffd
    80004754:	2f8080e7          	jalr	760(ra) # 80001a48 <myproc>
    80004758:	591c                	lw	a5,48(a0)
    8000475a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000475c:	854a                	mv	a0,s2
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	53a080e7          	jalr	1338(ra) # 80000c98 <release>
}
    80004766:	60e2                	ld	ra,24(sp)
    80004768:	6442                	ld	s0,16(sp)
    8000476a:	64a2                	ld	s1,8(sp)
    8000476c:	6902                	ld	s2,0(sp)
    8000476e:	6105                	addi	sp,sp,32
    80004770:	8082                	ret

0000000080004772 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004772:	1101                	addi	sp,sp,-32
    80004774:	ec06                	sd	ra,24(sp)
    80004776:	e822                	sd	s0,16(sp)
    80004778:	e426                	sd	s1,8(sp)
    8000477a:	e04a                	sd	s2,0(sp)
    8000477c:	1000                	addi	s0,sp,32
    8000477e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004780:	00850913          	addi	s2,a0,8
    80004784:	854a                	mv	a0,s2
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	45e080e7          	jalr	1118(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000478e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004792:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004796:	8526                	mv	a0,s1
    80004798:	ffffe097          	auipc	ra,0xffffe
    8000479c:	c56080e7          	jalr	-938(ra) # 800023ee <wakeup>
  release(&lk->lk);
    800047a0:	854a                	mv	a0,s2
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	4f6080e7          	jalr	1270(ra) # 80000c98 <release>
}
    800047aa:	60e2                	ld	ra,24(sp)
    800047ac:	6442                	ld	s0,16(sp)
    800047ae:	64a2                	ld	s1,8(sp)
    800047b0:	6902                	ld	s2,0(sp)
    800047b2:	6105                	addi	sp,sp,32
    800047b4:	8082                	ret

00000000800047b6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047b6:	7179                	addi	sp,sp,-48
    800047b8:	f406                	sd	ra,40(sp)
    800047ba:	f022                	sd	s0,32(sp)
    800047bc:	ec26                	sd	s1,24(sp)
    800047be:	e84a                	sd	s2,16(sp)
    800047c0:	e44e                	sd	s3,8(sp)
    800047c2:	1800                	addi	s0,sp,48
    800047c4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047c6:	00850913          	addi	s2,a0,8
    800047ca:	854a                	mv	a0,s2
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	418080e7          	jalr	1048(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047d4:	409c                	lw	a5,0(s1)
    800047d6:	ef99                	bnez	a5,800047f4 <holdingsleep+0x3e>
    800047d8:	4481                	li	s1,0
  release(&lk->lk);
    800047da:	854a                	mv	a0,s2
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	4bc080e7          	jalr	1212(ra) # 80000c98 <release>
  return r;
}
    800047e4:	8526                	mv	a0,s1
    800047e6:	70a2                	ld	ra,40(sp)
    800047e8:	7402                	ld	s0,32(sp)
    800047ea:	64e2                	ld	s1,24(sp)
    800047ec:	6942                	ld	s2,16(sp)
    800047ee:	69a2                	ld	s3,8(sp)
    800047f0:	6145                	addi	sp,sp,48
    800047f2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047f4:	0284a983          	lw	s3,40(s1)
    800047f8:	ffffd097          	auipc	ra,0xffffd
    800047fc:	250080e7          	jalr	592(ra) # 80001a48 <myproc>
    80004800:	5904                	lw	s1,48(a0)
    80004802:	413484b3          	sub	s1,s1,s3
    80004806:	0014b493          	seqz	s1,s1
    8000480a:	bfc1                	j	800047da <holdingsleep+0x24>

000000008000480c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000480c:	1141                	addi	sp,sp,-16
    8000480e:	e406                	sd	ra,8(sp)
    80004810:	e022                	sd	s0,0(sp)
    80004812:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004814:	00004597          	auipc	a1,0x4
    80004818:	f0458593          	addi	a1,a1,-252 # 80008718 <syscalls+0x258>
    8000481c:	00016517          	auipc	a0,0x16
    80004820:	d2c50513          	addi	a0,a0,-724 # 8001a548 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	330080e7          	jalr	816(ra) # 80000b54 <initlock>
}
    8000482c:	60a2                	ld	ra,8(sp)
    8000482e:	6402                	ld	s0,0(sp)
    80004830:	0141                	addi	sp,sp,16
    80004832:	8082                	ret

0000000080004834 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004834:	1101                	addi	sp,sp,-32
    80004836:	ec06                	sd	ra,24(sp)
    80004838:	e822                	sd	s0,16(sp)
    8000483a:	e426                	sd	s1,8(sp)
    8000483c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000483e:	00016517          	auipc	a0,0x16
    80004842:	d0a50513          	addi	a0,a0,-758 # 8001a548 <ftable>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	39e080e7          	jalr	926(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000484e:	00016497          	auipc	s1,0x16
    80004852:	d1248493          	addi	s1,s1,-750 # 8001a560 <ftable+0x18>
    80004856:	00017717          	auipc	a4,0x17
    8000485a:	caa70713          	addi	a4,a4,-854 # 8001b500 <ftable+0xfb8>
    if(f->ref == 0){
    8000485e:	40dc                	lw	a5,4(s1)
    80004860:	cf99                	beqz	a5,8000487e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004862:	02848493          	addi	s1,s1,40
    80004866:	fee49ce3          	bne	s1,a4,8000485e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000486a:	00016517          	auipc	a0,0x16
    8000486e:	cde50513          	addi	a0,a0,-802 # 8001a548 <ftable>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
  return 0;
    8000487a:	4481                	li	s1,0
    8000487c:	a819                	j	80004892 <filealloc+0x5e>
      f->ref = 1;
    8000487e:	4785                	li	a5,1
    80004880:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004882:	00016517          	auipc	a0,0x16
    80004886:	cc650513          	addi	a0,a0,-826 # 8001a548 <ftable>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	40e080e7          	jalr	1038(ra) # 80000c98 <release>
}
    80004892:	8526                	mv	a0,s1
    80004894:	60e2                	ld	ra,24(sp)
    80004896:	6442                	ld	s0,16(sp)
    80004898:	64a2                	ld	s1,8(sp)
    8000489a:	6105                	addi	sp,sp,32
    8000489c:	8082                	ret

000000008000489e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000489e:	1101                	addi	sp,sp,-32
    800048a0:	ec06                	sd	ra,24(sp)
    800048a2:	e822                	sd	s0,16(sp)
    800048a4:	e426                	sd	s1,8(sp)
    800048a6:	1000                	addi	s0,sp,32
    800048a8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800048aa:	00016517          	auipc	a0,0x16
    800048ae:	c9e50513          	addi	a0,a0,-866 # 8001a548 <ftable>
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	332080e7          	jalr	818(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800048ba:	40dc                	lw	a5,4(s1)
    800048bc:	02f05263          	blez	a5,800048e0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048c0:	2785                	addiw	a5,a5,1
    800048c2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048c4:	00016517          	auipc	a0,0x16
    800048c8:	c8450513          	addi	a0,a0,-892 # 8001a548 <ftable>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	3cc080e7          	jalr	972(ra) # 80000c98 <release>
  return f;
}
    800048d4:	8526                	mv	a0,s1
    800048d6:	60e2                	ld	ra,24(sp)
    800048d8:	6442                	ld	s0,16(sp)
    800048da:	64a2                	ld	s1,8(sp)
    800048dc:	6105                	addi	sp,sp,32
    800048de:	8082                	ret
    panic("filedup");
    800048e0:	00004517          	auipc	a0,0x4
    800048e4:	e4050513          	addi	a0,a0,-448 # 80008720 <syscalls+0x260>
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	c56080e7          	jalr	-938(ra) # 8000053e <panic>

00000000800048f0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048f0:	7139                	addi	sp,sp,-64
    800048f2:	fc06                	sd	ra,56(sp)
    800048f4:	f822                	sd	s0,48(sp)
    800048f6:	f426                	sd	s1,40(sp)
    800048f8:	f04a                	sd	s2,32(sp)
    800048fa:	ec4e                	sd	s3,24(sp)
    800048fc:	e852                	sd	s4,16(sp)
    800048fe:	e456                	sd	s5,8(sp)
    80004900:	0080                	addi	s0,sp,64
    80004902:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004904:	00016517          	auipc	a0,0x16
    80004908:	c4450513          	addi	a0,a0,-956 # 8001a548 <ftable>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	2d8080e7          	jalr	728(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004914:	40dc                	lw	a5,4(s1)
    80004916:	06f05163          	blez	a5,80004978 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000491a:	37fd                	addiw	a5,a5,-1
    8000491c:	0007871b          	sext.w	a4,a5
    80004920:	c0dc                	sw	a5,4(s1)
    80004922:	06e04363          	bgtz	a4,80004988 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004926:	0004a903          	lw	s2,0(s1)
    8000492a:	0094ca83          	lbu	s5,9(s1)
    8000492e:	0104ba03          	ld	s4,16(s1)
    80004932:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004936:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000493a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000493e:	00016517          	auipc	a0,0x16
    80004942:	c0a50513          	addi	a0,a0,-1014 # 8001a548 <ftable>
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	352080e7          	jalr	850(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000494e:	4785                	li	a5,1
    80004950:	04f90d63          	beq	s2,a5,800049aa <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004954:	3979                	addiw	s2,s2,-2
    80004956:	4785                	li	a5,1
    80004958:	0527e063          	bltu	a5,s2,80004998 <fileclose+0xa8>
    begin_op();
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	ac8080e7          	jalr	-1336(ra) # 80004424 <begin_op>
    iput(ff.ip);
    80004964:	854e                	mv	a0,s3
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	2a6080e7          	jalr	678(ra) # 80003c0c <iput>
    end_op();
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	b36080e7          	jalr	-1226(ra) # 800044a4 <end_op>
    80004976:	a00d                	j	80004998 <fileclose+0xa8>
    panic("fileclose");
    80004978:	00004517          	auipc	a0,0x4
    8000497c:	db050513          	addi	a0,a0,-592 # 80008728 <syscalls+0x268>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	bbe080e7          	jalr	-1090(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004988:	00016517          	auipc	a0,0x16
    8000498c:	bc050513          	addi	a0,a0,-1088 # 8001a548 <ftable>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	308080e7          	jalr	776(ra) # 80000c98 <release>
  }
}
    80004998:	70e2                	ld	ra,56(sp)
    8000499a:	7442                	ld	s0,48(sp)
    8000499c:	74a2                	ld	s1,40(sp)
    8000499e:	7902                	ld	s2,32(sp)
    800049a0:	69e2                	ld	s3,24(sp)
    800049a2:	6a42                	ld	s4,16(sp)
    800049a4:	6aa2                	ld	s5,8(sp)
    800049a6:	6121                	addi	sp,sp,64
    800049a8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800049aa:	85d6                	mv	a1,s5
    800049ac:	8552                	mv	a0,s4
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	34c080e7          	jalr	844(ra) # 80004cfa <pipeclose>
    800049b6:	b7cd                	j	80004998 <fileclose+0xa8>

00000000800049b8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049b8:	715d                	addi	sp,sp,-80
    800049ba:	e486                	sd	ra,72(sp)
    800049bc:	e0a2                	sd	s0,64(sp)
    800049be:	fc26                	sd	s1,56(sp)
    800049c0:	f84a                	sd	s2,48(sp)
    800049c2:	f44e                	sd	s3,40(sp)
    800049c4:	0880                	addi	s0,sp,80
    800049c6:	84aa                	mv	s1,a0
    800049c8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049ca:	ffffd097          	auipc	ra,0xffffd
    800049ce:	07e080e7          	jalr	126(ra) # 80001a48 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049d2:	409c                	lw	a5,0(s1)
    800049d4:	37f9                	addiw	a5,a5,-2
    800049d6:	4705                	li	a4,1
    800049d8:	04f76763          	bltu	a4,a5,80004a26 <filestat+0x6e>
    800049dc:	892a                	mv	s2,a0
    ilock(f->ip);
    800049de:	6c88                	ld	a0,24(s1)
    800049e0:	fffff097          	auipc	ra,0xfffff
    800049e4:	072080e7          	jalr	114(ra) # 80003a52 <ilock>
    stati(f->ip, &st);
    800049e8:	fb840593          	addi	a1,s0,-72
    800049ec:	6c88                	ld	a0,24(s1)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	2ee080e7          	jalr	750(ra) # 80003cdc <stati>
    iunlock(f->ip);
    800049f6:	6c88                	ld	a0,24(s1)
    800049f8:	fffff097          	auipc	ra,0xfffff
    800049fc:	11c080e7          	jalr	284(ra) # 80003b14 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a00:	46e1                	li	a3,24
    80004a02:	fb840613          	addi	a2,s0,-72
    80004a06:	85ce                	mv	a1,s3
    80004a08:	05093503          	ld	a0,80(s2)
    80004a0c:	ffffd097          	auipc	ra,0xffffd
    80004a10:	c66080e7          	jalr	-922(ra) # 80001672 <copyout>
    80004a14:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a18:	60a6                	ld	ra,72(sp)
    80004a1a:	6406                	ld	s0,64(sp)
    80004a1c:	74e2                	ld	s1,56(sp)
    80004a1e:	7942                	ld	s2,48(sp)
    80004a20:	79a2                	ld	s3,40(sp)
    80004a22:	6161                	addi	sp,sp,80
    80004a24:	8082                	ret
  return -1;
    80004a26:	557d                	li	a0,-1
    80004a28:	bfc5                	j	80004a18 <filestat+0x60>

0000000080004a2a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a2a:	7179                	addi	sp,sp,-48
    80004a2c:	f406                	sd	ra,40(sp)
    80004a2e:	f022                	sd	s0,32(sp)
    80004a30:	ec26                	sd	s1,24(sp)
    80004a32:	e84a                	sd	s2,16(sp)
    80004a34:	e44e                	sd	s3,8(sp)
    80004a36:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a38:	00854783          	lbu	a5,8(a0)
    80004a3c:	c3d5                	beqz	a5,80004ae0 <fileread+0xb6>
    80004a3e:	84aa                	mv	s1,a0
    80004a40:	89ae                	mv	s3,a1
    80004a42:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a44:	411c                	lw	a5,0(a0)
    80004a46:	4705                	li	a4,1
    80004a48:	04e78963          	beq	a5,a4,80004a9a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a4c:	470d                	li	a4,3
    80004a4e:	04e78d63          	beq	a5,a4,80004aa8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a52:	4709                	li	a4,2
    80004a54:	06e79e63          	bne	a5,a4,80004ad0 <fileread+0xa6>
    ilock(f->ip);
    80004a58:	6d08                	ld	a0,24(a0)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	ff8080e7          	jalr	-8(ra) # 80003a52 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a62:	874a                	mv	a4,s2
    80004a64:	5094                	lw	a3,32(s1)
    80004a66:	864e                	mv	a2,s3
    80004a68:	4585                	li	a1,1
    80004a6a:	6c88                	ld	a0,24(s1)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	29a080e7          	jalr	666(ra) # 80003d06 <readi>
    80004a74:	892a                	mv	s2,a0
    80004a76:	00a05563          	blez	a0,80004a80 <fileread+0x56>
      f->off += r;
    80004a7a:	509c                	lw	a5,32(s1)
    80004a7c:	9fa9                	addw	a5,a5,a0
    80004a7e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a80:	6c88                	ld	a0,24(s1)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	092080e7          	jalr	146(ra) # 80003b14 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a8a:	854a                	mv	a0,s2
    80004a8c:	70a2                	ld	ra,40(sp)
    80004a8e:	7402                	ld	s0,32(sp)
    80004a90:	64e2                	ld	s1,24(sp)
    80004a92:	6942                	ld	s2,16(sp)
    80004a94:	69a2                	ld	s3,8(sp)
    80004a96:	6145                	addi	sp,sp,48
    80004a98:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a9a:	6908                	ld	a0,16(a0)
    80004a9c:	00000097          	auipc	ra,0x0
    80004aa0:	3c8080e7          	jalr	968(ra) # 80004e64 <piperead>
    80004aa4:	892a                	mv	s2,a0
    80004aa6:	b7d5                	j	80004a8a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004aa8:	02451783          	lh	a5,36(a0)
    80004aac:	03079693          	slli	a3,a5,0x30
    80004ab0:	92c1                	srli	a3,a3,0x30
    80004ab2:	4725                	li	a4,9
    80004ab4:	02d76863          	bltu	a4,a3,80004ae4 <fileread+0xba>
    80004ab8:	0792                	slli	a5,a5,0x4
    80004aba:	00016717          	auipc	a4,0x16
    80004abe:	9ee70713          	addi	a4,a4,-1554 # 8001a4a8 <devsw>
    80004ac2:	97ba                	add	a5,a5,a4
    80004ac4:	639c                	ld	a5,0(a5)
    80004ac6:	c38d                	beqz	a5,80004ae8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ac8:	4505                	li	a0,1
    80004aca:	9782                	jalr	a5
    80004acc:	892a                	mv	s2,a0
    80004ace:	bf75                	j	80004a8a <fileread+0x60>
    panic("fileread");
    80004ad0:	00004517          	auipc	a0,0x4
    80004ad4:	c6850513          	addi	a0,a0,-920 # 80008738 <syscalls+0x278>
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	a66080e7          	jalr	-1434(ra) # 8000053e <panic>
    return -1;
    80004ae0:	597d                	li	s2,-1
    80004ae2:	b765                	j	80004a8a <fileread+0x60>
      return -1;
    80004ae4:	597d                	li	s2,-1
    80004ae6:	b755                	j	80004a8a <fileread+0x60>
    80004ae8:	597d                	li	s2,-1
    80004aea:	b745                	j	80004a8a <fileread+0x60>

0000000080004aec <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004aec:	715d                	addi	sp,sp,-80
    80004aee:	e486                	sd	ra,72(sp)
    80004af0:	e0a2                	sd	s0,64(sp)
    80004af2:	fc26                	sd	s1,56(sp)
    80004af4:	f84a                	sd	s2,48(sp)
    80004af6:	f44e                	sd	s3,40(sp)
    80004af8:	f052                	sd	s4,32(sp)
    80004afa:	ec56                	sd	s5,24(sp)
    80004afc:	e85a                	sd	s6,16(sp)
    80004afe:	e45e                	sd	s7,8(sp)
    80004b00:	e062                	sd	s8,0(sp)
    80004b02:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b04:	00954783          	lbu	a5,9(a0)
    80004b08:	10078663          	beqz	a5,80004c14 <filewrite+0x128>
    80004b0c:	892a                	mv	s2,a0
    80004b0e:	8aae                	mv	s5,a1
    80004b10:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b12:	411c                	lw	a5,0(a0)
    80004b14:	4705                	li	a4,1
    80004b16:	02e78263          	beq	a5,a4,80004b3a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b1a:	470d                	li	a4,3
    80004b1c:	02e78663          	beq	a5,a4,80004b48 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b20:	4709                	li	a4,2
    80004b22:	0ee79163          	bne	a5,a4,80004c04 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b26:	0ac05d63          	blez	a2,80004be0 <filewrite+0xf4>
    int i = 0;
    80004b2a:	4981                	li	s3,0
    80004b2c:	6b05                	lui	s6,0x1
    80004b2e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b32:	6b85                	lui	s7,0x1
    80004b34:	c00b8b9b          	addiw	s7,s7,-1024
    80004b38:	a861                	j	80004bd0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b3a:	6908                	ld	a0,16(a0)
    80004b3c:	00000097          	auipc	ra,0x0
    80004b40:	22e080e7          	jalr	558(ra) # 80004d6a <pipewrite>
    80004b44:	8a2a                	mv	s4,a0
    80004b46:	a045                	j	80004be6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b48:	02451783          	lh	a5,36(a0)
    80004b4c:	03079693          	slli	a3,a5,0x30
    80004b50:	92c1                	srli	a3,a3,0x30
    80004b52:	4725                	li	a4,9
    80004b54:	0cd76263          	bltu	a4,a3,80004c18 <filewrite+0x12c>
    80004b58:	0792                	slli	a5,a5,0x4
    80004b5a:	00016717          	auipc	a4,0x16
    80004b5e:	94e70713          	addi	a4,a4,-1714 # 8001a4a8 <devsw>
    80004b62:	97ba                	add	a5,a5,a4
    80004b64:	679c                	ld	a5,8(a5)
    80004b66:	cbdd                	beqz	a5,80004c1c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b68:	4505                	li	a0,1
    80004b6a:	9782                	jalr	a5
    80004b6c:	8a2a                	mv	s4,a0
    80004b6e:	a8a5                	j	80004be6 <filewrite+0xfa>
    80004b70:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	8b0080e7          	jalr	-1872(ra) # 80004424 <begin_op>
      ilock(f->ip);
    80004b7c:	01893503          	ld	a0,24(s2)
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	ed2080e7          	jalr	-302(ra) # 80003a52 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b88:	8762                	mv	a4,s8
    80004b8a:	02092683          	lw	a3,32(s2)
    80004b8e:	01598633          	add	a2,s3,s5
    80004b92:	4585                	li	a1,1
    80004b94:	01893503          	ld	a0,24(s2)
    80004b98:	fffff097          	auipc	ra,0xfffff
    80004b9c:	266080e7          	jalr	614(ra) # 80003dfe <writei>
    80004ba0:	84aa                	mv	s1,a0
    80004ba2:	00a05763          	blez	a0,80004bb0 <filewrite+0xc4>
        f->off += r;
    80004ba6:	02092783          	lw	a5,32(s2)
    80004baa:	9fa9                	addw	a5,a5,a0
    80004bac:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004bb0:	01893503          	ld	a0,24(s2)
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	f60080e7          	jalr	-160(ra) # 80003b14 <iunlock>
      end_op();
    80004bbc:	00000097          	auipc	ra,0x0
    80004bc0:	8e8080e7          	jalr	-1816(ra) # 800044a4 <end_op>

      if(r != n1){
    80004bc4:	009c1f63          	bne	s8,s1,80004be2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004bc8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bcc:	0149db63          	bge	s3,s4,80004be2 <filewrite+0xf6>
      int n1 = n - i;
    80004bd0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004bd4:	84be                	mv	s1,a5
    80004bd6:	2781                	sext.w	a5,a5
    80004bd8:	f8fb5ce3          	bge	s6,a5,80004b70 <filewrite+0x84>
    80004bdc:	84de                	mv	s1,s7
    80004bde:	bf49                	j	80004b70 <filewrite+0x84>
    int i = 0;
    80004be0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004be2:	013a1f63          	bne	s4,s3,80004c00 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004be6:	8552                	mv	a0,s4
    80004be8:	60a6                	ld	ra,72(sp)
    80004bea:	6406                	ld	s0,64(sp)
    80004bec:	74e2                	ld	s1,56(sp)
    80004bee:	7942                	ld	s2,48(sp)
    80004bf0:	79a2                	ld	s3,40(sp)
    80004bf2:	7a02                	ld	s4,32(sp)
    80004bf4:	6ae2                	ld	s5,24(sp)
    80004bf6:	6b42                	ld	s6,16(sp)
    80004bf8:	6ba2                	ld	s7,8(sp)
    80004bfa:	6c02                	ld	s8,0(sp)
    80004bfc:	6161                	addi	sp,sp,80
    80004bfe:	8082                	ret
    ret = (i == n ? n : -1);
    80004c00:	5a7d                	li	s4,-1
    80004c02:	b7d5                	j	80004be6 <filewrite+0xfa>
    panic("filewrite");
    80004c04:	00004517          	auipc	a0,0x4
    80004c08:	b4450513          	addi	a0,a0,-1212 # 80008748 <syscalls+0x288>
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	932080e7          	jalr	-1742(ra) # 8000053e <panic>
    return -1;
    80004c14:	5a7d                	li	s4,-1
    80004c16:	bfc1                	j	80004be6 <filewrite+0xfa>
      return -1;
    80004c18:	5a7d                	li	s4,-1
    80004c1a:	b7f1                	j	80004be6 <filewrite+0xfa>
    80004c1c:	5a7d                	li	s4,-1
    80004c1e:	b7e1                	j	80004be6 <filewrite+0xfa>

0000000080004c20 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c20:	7179                	addi	sp,sp,-48
    80004c22:	f406                	sd	ra,40(sp)
    80004c24:	f022                	sd	s0,32(sp)
    80004c26:	ec26                	sd	s1,24(sp)
    80004c28:	e84a                	sd	s2,16(sp)
    80004c2a:	e44e                	sd	s3,8(sp)
    80004c2c:	e052                	sd	s4,0(sp)
    80004c2e:	1800                	addi	s0,sp,48
    80004c30:	84aa                	mv	s1,a0
    80004c32:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c34:	0005b023          	sd	zero,0(a1)
    80004c38:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c3c:	00000097          	auipc	ra,0x0
    80004c40:	bf8080e7          	jalr	-1032(ra) # 80004834 <filealloc>
    80004c44:	e088                	sd	a0,0(s1)
    80004c46:	c551                	beqz	a0,80004cd2 <pipealloc+0xb2>
    80004c48:	00000097          	auipc	ra,0x0
    80004c4c:	bec080e7          	jalr	-1044(ra) # 80004834 <filealloc>
    80004c50:	00aa3023          	sd	a0,0(s4)
    80004c54:	c92d                	beqz	a0,80004cc6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	e9e080e7          	jalr	-354(ra) # 80000af4 <kalloc>
    80004c5e:	892a                	mv	s2,a0
    80004c60:	c125                	beqz	a0,80004cc0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c62:	4985                	li	s3,1
    80004c64:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c68:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c6c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c70:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c74:	00004597          	auipc	a1,0x4
    80004c78:	ae458593          	addi	a1,a1,-1308 # 80008758 <syscalls+0x298>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	ed8080e7          	jalr	-296(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004c84:	609c                	ld	a5,0(s1)
    80004c86:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c8a:	609c                	ld	a5,0(s1)
    80004c8c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c90:	609c                	ld	a5,0(s1)
    80004c92:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c96:	609c                	ld	a5,0(s1)
    80004c98:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c9c:	000a3783          	ld	a5,0(s4)
    80004ca0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ca4:	000a3783          	ld	a5,0(s4)
    80004ca8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004cac:	000a3783          	ld	a5,0(s4)
    80004cb0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004cb4:	000a3783          	ld	a5,0(s4)
    80004cb8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004cbc:	4501                	li	a0,0
    80004cbe:	a025                	j	80004ce6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cc0:	6088                	ld	a0,0(s1)
    80004cc2:	e501                	bnez	a0,80004cca <pipealloc+0xaa>
    80004cc4:	a039                	j	80004cd2 <pipealloc+0xb2>
    80004cc6:	6088                	ld	a0,0(s1)
    80004cc8:	c51d                	beqz	a0,80004cf6 <pipealloc+0xd6>
    fileclose(*f0);
    80004cca:	00000097          	auipc	ra,0x0
    80004cce:	c26080e7          	jalr	-986(ra) # 800048f0 <fileclose>
  if(*f1)
    80004cd2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cd6:	557d                	li	a0,-1
  if(*f1)
    80004cd8:	c799                	beqz	a5,80004ce6 <pipealloc+0xc6>
    fileclose(*f1);
    80004cda:	853e                	mv	a0,a5
    80004cdc:	00000097          	auipc	ra,0x0
    80004ce0:	c14080e7          	jalr	-1004(ra) # 800048f0 <fileclose>
  return -1;
    80004ce4:	557d                	li	a0,-1
}
    80004ce6:	70a2                	ld	ra,40(sp)
    80004ce8:	7402                	ld	s0,32(sp)
    80004cea:	64e2                	ld	s1,24(sp)
    80004cec:	6942                	ld	s2,16(sp)
    80004cee:	69a2                	ld	s3,8(sp)
    80004cf0:	6a02                	ld	s4,0(sp)
    80004cf2:	6145                	addi	sp,sp,48
    80004cf4:	8082                	ret
  return -1;
    80004cf6:	557d                	li	a0,-1
    80004cf8:	b7fd                	j	80004ce6 <pipealloc+0xc6>

0000000080004cfa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cfa:	1101                	addi	sp,sp,-32
    80004cfc:	ec06                	sd	ra,24(sp)
    80004cfe:	e822                	sd	s0,16(sp)
    80004d00:	e426                	sd	s1,8(sp)
    80004d02:	e04a                	sd	s2,0(sp)
    80004d04:	1000                	addi	s0,sp,32
    80004d06:	84aa                	mv	s1,a0
    80004d08:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	eda080e7          	jalr	-294(ra) # 80000be4 <acquire>
  if(writable){
    80004d12:	02090d63          	beqz	s2,80004d4c <pipeclose+0x52>
    pi->writeopen = 0;
    80004d16:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d1a:	21848513          	addi	a0,s1,536
    80004d1e:	ffffd097          	auipc	ra,0xffffd
    80004d22:	6d0080e7          	jalr	1744(ra) # 800023ee <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d26:	2204b783          	ld	a5,544(s1)
    80004d2a:	eb95                	bnez	a5,80004d5e <pipeclose+0x64>
    release(&pi->lock);
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	f6a080e7          	jalr	-150(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	cc0080e7          	jalr	-832(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004d40:	60e2                	ld	ra,24(sp)
    80004d42:	6442                	ld	s0,16(sp)
    80004d44:	64a2                	ld	s1,8(sp)
    80004d46:	6902                	ld	s2,0(sp)
    80004d48:	6105                	addi	sp,sp,32
    80004d4a:	8082                	ret
    pi->readopen = 0;
    80004d4c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d50:	21c48513          	addi	a0,s1,540
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	69a080e7          	jalr	1690(ra) # 800023ee <wakeup>
    80004d5c:	b7e9                	j	80004d26 <pipeclose+0x2c>
    release(&pi->lock);
    80004d5e:	8526                	mv	a0,s1
    80004d60:	ffffc097          	auipc	ra,0xffffc
    80004d64:	f38080e7          	jalr	-200(ra) # 80000c98 <release>
}
    80004d68:	bfe1                	j	80004d40 <pipeclose+0x46>

0000000080004d6a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d6a:	7159                	addi	sp,sp,-112
    80004d6c:	f486                	sd	ra,104(sp)
    80004d6e:	f0a2                	sd	s0,96(sp)
    80004d70:	eca6                	sd	s1,88(sp)
    80004d72:	e8ca                	sd	s2,80(sp)
    80004d74:	e4ce                	sd	s3,72(sp)
    80004d76:	e0d2                	sd	s4,64(sp)
    80004d78:	fc56                	sd	s5,56(sp)
    80004d7a:	f85a                	sd	s6,48(sp)
    80004d7c:	f45e                	sd	s7,40(sp)
    80004d7e:	f062                	sd	s8,32(sp)
    80004d80:	ec66                	sd	s9,24(sp)
    80004d82:	1880                	addi	s0,sp,112
    80004d84:	84aa                	mv	s1,a0
    80004d86:	8aae                	mv	s5,a1
    80004d88:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	cbe080e7          	jalr	-834(ra) # 80001a48 <myproc>
    80004d92:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d94:	8526                	mv	a0,s1
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	e4e080e7          	jalr	-434(ra) # 80000be4 <acquire>
  while(i < n){
    80004d9e:	0d405163          	blez	s4,80004e60 <pipewrite+0xf6>
    80004da2:	8ba6                	mv	s7,s1
  int i = 0;
    80004da4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004da8:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004dac:	21c48c13          	addi	s8,s1,540
    80004db0:	a08d                	j	80004e12 <pipewrite+0xa8>
      release(&pi->lock);
    80004db2:	8526                	mv	a0,s1
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	ee4080e7          	jalr	-284(ra) # 80000c98 <release>
      return -1;
    80004dbc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004dbe:	854a                	mv	a0,s2
    80004dc0:	70a6                	ld	ra,104(sp)
    80004dc2:	7406                	ld	s0,96(sp)
    80004dc4:	64e6                	ld	s1,88(sp)
    80004dc6:	6946                	ld	s2,80(sp)
    80004dc8:	69a6                	ld	s3,72(sp)
    80004dca:	6a06                	ld	s4,64(sp)
    80004dcc:	7ae2                	ld	s5,56(sp)
    80004dce:	7b42                	ld	s6,48(sp)
    80004dd0:	7ba2                	ld	s7,40(sp)
    80004dd2:	7c02                	ld	s8,32(sp)
    80004dd4:	6ce2                	ld	s9,24(sp)
    80004dd6:	6165                	addi	sp,sp,112
    80004dd8:	8082                	ret
      wakeup(&pi->nread);
    80004dda:	8566                	mv	a0,s9
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	612080e7          	jalr	1554(ra) # 800023ee <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004de4:	85de                	mv	a1,s7
    80004de6:	8562                	mv	a0,s8
    80004de8:	ffffd097          	auipc	ra,0xffffd
    80004dec:	47a080e7          	jalr	1146(ra) # 80002262 <sleep>
    80004df0:	a839                	j	80004e0e <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004df2:	21c4a783          	lw	a5,540(s1)
    80004df6:	0017871b          	addiw	a4,a5,1
    80004dfa:	20e4ae23          	sw	a4,540(s1)
    80004dfe:	1ff7f793          	andi	a5,a5,511
    80004e02:	97a6                	add	a5,a5,s1
    80004e04:	f9f44703          	lbu	a4,-97(s0)
    80004e08:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e0c:	2905                	addiw	s2,s2,1
  while(i < n){
    80004e0e:	03495d63          	bge	s2,s4,80004e48 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004e12:	2204a783          	lw	a5,544(s1)
    80004e16:	dfd1                	beqz	a5,80004db2 <pipewrite+0x48>
    80004e18:	0289a783          	lw	a5,40(s3)
    80004e1c:	fbd9                	bnez	a5,80004db2 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e1e:	2184a783          	lw	a5,536(s1)
    80004e22:	21c4a703          	lw	a4,540(s1)
    80004e26:	2007879b          	addiw	a5,a5,512
    80004e2a:	faf708e3          	beq	a4,a5,80004dda <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e2e:	4685                	li	a3,1
    80004e30:	01590633          	add	a2,s2,s5
    80004e34:	f9f40593          	addi	a1,s0,-97
    80004e38:	0509b503          	ld	a0,80(s3)
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	8c2080e7          	jalr	-1854(ra) # 800016fe <copyin>
    80004e44:	fb6517e3          	bne	a0,s6,80004df2 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004e48:	21848513          	addi	a0,s1,536
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	5a2080e7          	jalr	1442(ra) # 800023ee <wakeup>
  release(&pi->lock);
    80004e54:	8526                	mv	a0,s1
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	e42080e7          	jalr	-446(ra) # 80000c98 <release>
  return i;
    80004e5e:	b785                	j	80004dbe <pipewrite+0x54>
  int i = 0;
    80004e60:	4901                	li	s2,0
    80004e62:	b7dd                	j	80004e48 <pipewrite+0xde>

0000000080004e64 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e64:	715d                	addi	sp,sp,-80
    80004e66:	e486                	sd	ra,72(sp)
    80004e68:	e0a2                	sd	s0,64(sp)
    80004e6a:	fc26                	sd	s1,56(sp)
    80004e6c:	f84a                	sd	s2,48(sp)
    80004e6e:	f44e                	sd	s3,40(sp)
    80004e70:	f052                	sd	s4,32(sp)
    80004e72:	ec56                	sd	s5,24(sp)
    80004e74:	e85a                	sd	s6,16(sp)
    80004e76:	0880                	addi	s0,sp,80
    80004e78:	84aa                	mv	s1,a0
    80004e7a:	892e                	mv	s2,a1
    80004e7c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	bca080e7          	jalr	-1078(ra) # 80001a48 <myproc>
    80004e86:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e88:	8b26                	mv	s6,s1
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e94:	2184a703          	lw	a4,536(s1)
    80004e98:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e9c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ea0:	02f71463          	bne	a4,a5,80004ec8 <piperead+0x64>
    80004ea4:	2244a783          	lw	a5,548(s1)
    80004ea8:	c385                	beqz	a5,80004ec8 <piperead+0x64>
    if(pr->killed){
    80004eaa:	028a2783          	lw	a5,40(s4)
    80004eae:	ebc1                	bnez	a5,80004f3e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004eb0:	85da                	mv	a1,s6
    80004eb2:	854e                	mv	a0,s3
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	3ae080e7          	jalr	942(ra) # 80002262 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ebc:	2184a703          	lw	a4,536(s1)
    80004ec0:	21c4a783          	lw	a5,540(s1)
    80004ec4:	fef700e3          	beq	a4,a5,80004ea4 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec8:	09505263          	blez	s5,80004f4c <piperead+0xe8>
    80004ecc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ece:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ed0:	2184a783          	lw	a5,536(s1)
    80004ed4:	21c4a703          	lw	a4,540(s1)
    80004ed8:	02f70d63          	beq	a4,a5,80004f12 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004edc:	0017871b          	addiw	a4,a5,1
    80004ee0:	20e4ac23          	sw	a4,536(s1)
    80004ee4:	1ff7f793          	andi	a5,a5,511
    80004ee8:	97a6                	add	a5,a5,s1
    80004eea:	0187c783          	lbu	a5,24(a5)
    80004eee:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ef2:	4685                	li	a3,1
    80004ef4:	fbf40613          	addi	a2,s0,-65
    80004ef8:	85ca                	mv	a1,s2
    80004efa:	050a3503          	ld	a0,80(s4)
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	774080e7          	jalr	1908(ra) # 80001672 <copyout>
    80004f06:	01650663          	beq	a0,s6,80004f12 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f0a:	2985                	addiw	s3,s3,1
    80004f0c:	0905                	addi	s2,s2,1
    80004f0e:	fd3a91e3          	bne	s5,s3,80004ed0 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f12:	21c48513          	addi	a0,s1,540
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	4d8080e7          	jalr	1240(ra) # 800023ee <wakeup>
  release(&pi->lock);
    80004f1e:	8526                	mv	a0,s1
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	d78080e7          	jalr	-648(ra) # 80000c98 <release>
  return i;
}
    80004f28:	854e                	mv	a0,s3
    80004f2a:	60a6                	ld	ra,72(sp)
    80004f2c:	6406                	ld	s0,64(sp)
    80004f2e:	74e2                	ld	s1,56(sp)
    80004f30:	7942                	ld	s2,48(sp)
    80004f32:	79a2                	ld	s3,40(sp)
    80004f34:	7a02                	ld	s4,32(sp)
    80004f36:	6ae2                	ld	s5,24(sp)
    80004f38:	6b42                	ld	s6,16(sp)
    80004f3a:	6161                	addi	sp,sp,80
    80004f3c:	8082                	ret
      release(&pi->lock);
    80004f3e:	8526                	mv	a0,s1
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	d58080e7          	jalr	-680(ra) # 80000c98 <release>
      return -1;
    80004f48:	59fd                	li	s3,-1
    80004f4a:	bff9                	j	80004f28 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f4c:	4981                	li	s3,0
    80004f4e:	b7d1                	j	80004f12 <piperead+0xae>

0000000080004f50 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f50:	df010113          	addi	sp,sp,-528
    80004f54:	20113423          	sd	ra,520(sp)
    80004f58:	20813023          	sd	s0,512(sp)
    80004f5c:	ffa6                	sd	s1,504(sp)
    80004f5e:	fbca                	sd	s2,496(sp)
    80004f60:	f7ce                	sd	s3,488(sp)
    80004f62:	f3d2                	sd	s4,480(sp)
    80004f64:	efd6                	sd	s5,472(sp)
    80004f66:	ebda                	sd	s6,464(sp)
    80004f68:	e7de                	sd	s7,456(sp)
    80004f6a:	e3e2                	sd	s8,448(sp)
    80004f6c:	ff66                	sd	s9,440(sp)
    80004f6e:	fb6a                	sd	s10,432(sp)
    80004f70:	f76e                	sd	s11,424(sp)
    80004f72:	0c00                	addi	s0,sp,528
    80004f74:	84aa                	mv	s1,a0
    80004f76:	dea43c23          	sd	a0,-520(s0)
    80004f7a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	aca080e7          	jalr	-1334(ra) # 80001a48 <myproc>
    80004f86:	892a                	mv	s2,a0

  begin_op();
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	49c080e7          	jalr	1180(ra) # 80004424 <begin_op>

  if((ip = namei(path)) == 0){
    80004f90:	8526                	mv	a0,s1
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	276080e7          	jalr	630(ra) # 80004208 <namei>
    80004f9a:	c92d                	beqz	a0,8000500c <exec+0xbc>
    80004f9c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	ab4080e7          	jalr	-1356(ra) # 80003a52 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fa6:	04000713          	li	a4,64
    80004faa:	4681                	li	a3,0
    80004fac:	e5040613          	addi	a2,s0,-432
    80004fb0:	4581                	li	a1,0
    80004fb2:	8526                	mv	a0,s1
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	d52080e7          	jalr	-686(ra) # 80003d06 <readi>
    80004fbc:	04000793          	li	a5,64
    80004fc0:	00f51a63          	bne	a0,a5,80004fd4 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004fc4:	e5042703          	lw	a4,-432(s0)
    80004fc8:	464c47b7          	lui	a5,0x464c4
    80004fcc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fd0:	04f70463          	beq	a4,a5,80005018 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	fffff097          	auipc	ra,0xfffff
    80004fda:	cde080e7          	jalr	-802(ra) # 80003cb4 <iunlockput>
    end_op();
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	4c6080e7          	jalr	1222(ra) # 800044a4 <end_op>
  }
  return -1;
    80004fe6:	557d                	li	a0,-1
}
    80004fe8:	20813083          	ld	ra,520(sp)
    80004fec:	20013403          	ld	s0,512(sp)
    80004ff0:	74fe                	ld	s1,504(sp)
    80004ff2:	795e                	ld	s2,496(sp)
    80004ff4:	79be                	ld	s3,488(sp)
    80004ff6:	7a1e                	ld	s4,480(sp)
    80004ff8:	6afe                	ld	s5,472(sp)
    80004ffa:	6b5e                	ld	s6,464(sp)
    80004ffc:	6bbe                	ld	s7,456(sp)
    80004ffe:	6c1e                	ld	s8,448(sp)
    80005000:	7cfa                	ld	s9,440(sp)
    80005002:	7d5a                	ld	s10,432(sp)
    80005004:	7dba                	ld	s11,424(sp)
    80005006:	21010113          	addi	sp,sp,528
    8000500a:	8082                	ret
    end_op();
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	498080e7          	jalr	1176(ra) # 800044a4 <end_op>
    return -1;
    80005014:	557d                	li	a0,-1
    80005016:	bfc9                	j	80004fe8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005018:	854a                	mv	a0,s2
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	af2080e7          	jalr	-1294(ra) # 80001b0c <proc_pagetable>
    80005022:	8baa                	mv	s7,a0
    80005024:	d945                	beqz	a0,80004fd4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005026:	e7042983          	lw	s3,-400(s0)
    8000502a:	e8845783          	lhu	a5,-376(s0)
    8000502e:	c7ad                	beqz	a5,80005098 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005030:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005032:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005034:	6c85                	lui	s9,0x1
    80005036:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000503a:	def43823          	sd	a5,-528(s0)
    8000503e:	a42d                	j	80005268 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005040:	00003517          	auipc	a0,0x3
    80005044:	72050513          	addi	a0,a0,1824 # 80008760 <syscalls+0x2a0>
    80005048:	ffffb097          	auipc	ra,0xffffb
    8000504c:	4f6080e7          	jalr	1270(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005050:	8756                	mv	a4,s5
    80005052:	012d86bb          	addw	a3,s11,s2
    80005056:	4581                	li	a1,0
    80005058:	8526                	mv	a0,s1
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	cac080e7          	jalr	-852(ra) # 80003d06 <readi>
    80005062:	2501                	sext.w	a0,a0
    80005064:	1aaa9963          	bne	s5,a0,80005216 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005068:	6785                	lui	a5,0x1
    8000506a:	0127893b          	addw	s2,a5,s2
    8000506e:	77fd                	lui	a5,0xfffff
    80005070:	01478a3b          	addw	s4,a5,s4
    80005074:	1f897163          	bgeu	s2,s8,80005256 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005078:	02091593          	slli	a1,s2,0x20
    8000507c:	9181                	srli	a1,a1,0x20
    8000507e:	95ea                	add	a1,a1,s10
    80005080:	855e                	mv	a0,s7
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	fec080e7          	jalr	-20(ra) # 8000106e <walkaddr>
    8000508a:	862a                	mv	a2,a0
    if(pa == 0)
    8000508c:	d955                	beqz	a0,80005040 <exec+0xf0>
      n = PGSIZE;
    8000508e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005090:	fd9a70e3          	bgeu	s4,s9,80005050 <exec+0x100>
      n = sz - i;
    80005094:	8ad2                	mv	s5,s4
    80005096:	bf6d                	j	80005050 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005098:	4901                	li	s2,0
  iunlockput(ip);
    8000509a:	8526                	mv	a0,s1
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	c18080e7          	jalr	-1000(ra) # 80003cb4 <iunlockput>
  end_op();
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	400080e7          	jalr	1024(ra) # 800044a4 <end_op>
  p = myproc();
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	99c080e7          	jalr	-1636(ra) # 80001a48 <myproc>
    800050b4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800050b6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050ba:	6785                	lui	a5,0x1
    800050bc:	17fd                	addi	a5,a5,-1
    800050be:	993e                	add	s2,s2,a5
    800050c0:	757d                	lui	a0,0xfffff
    800050c2:	00a977b3          	and	a5,s2,a0
    800050c6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050ca:	6609                	lui	a2,0x2
    800050cc:	963e                	add	a2,a2,a5
    800050ce:	85be                	mv	a1,a5
    800050d0:	855e                	mv	a0,s7
    800050d2:	ffffc097          	auipc	ra,0xffffc
    800050d6:	350080e7          	jalr	848(ra) # 80001422 <uvmalloc>
    800050da:	8b2a                	mv	s6,a0
  ip = 0;
    800050dc:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050de:	12050c63          	beqz	a0,80005216 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050e2:	75f9                	lui	a1,0xffffe
    800050e4:	95aa                	add	a1,a1,a0
    800050e6:	855e                	mv	a0,s7
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	558080e7          	jalr	1368(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800050f0:	7c7d                	lui	s8,0xfffff
    800050f2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800050f4:	e0043783          	ld	a5,-512(s0)
    800050f8:	6388                	ld	a0,0(a5)
    800050fa:	c535                	beqz	a0,80005166 <exec+0x216>
    800050fc:	e9040993          	addi	s3,s0,-368
    80005100:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005104:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	d5e080e7          	jalr	-674(ra) # 80000e64 <strlen>
    8000510e:	2505                	addiw	a0,a0,1
    80005110:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005114:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005118:	13896363          	bltu	s2,s8,8000523e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000511c:	e0043d83          	ld	s11,-512(s0)
    80005120:	000dba03          	ld	s4,0(s11)
    80005124:	8552                	mv	a0,s4
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	d3e080e7          	jalr	-706(ra) # 80000e64 <strlen>
    8000512e:	0015069b          	addiw	a3,a0,1
    80005132:	8652                	mv	a2,s4
    80005134:	85ca                	mv	a1,s2
    80005136:	855e                	mv	a0,s7
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	53a080e7          	jalr	1338(ra) # 80001672 <copyout>
    80005140:	10054363          	bltz	a0,80005246 <exec+0x2f6>
    ustack[argc] = sp;
    80005144:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005148:	0485                	addi	s1,s1,1
    8000514a:	008d8793          	addi	a5,s11,8
    8000514e:	e0f43023          	sd	a5,-512(s0)
    80005152:	008db503          	ld	a0,8(s11)
    80005156:	c911                	beqz	a0,8000516a <exec+0x21a>
    if(argc >= MAXARG)
    80005158:	09a1                	addi	s3,s3,8
    8000515a:	fb3c96e3          	bne	s9,s3,80005106 <exec+0x1b6>
  sz = sz1;
    8000515e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005162:	4481                	li	s1,0
    80005164:	a84d                	j	80005216 <exec+0x2c6>
  sp = sz;
    80005166:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005168:	4481                	li	s1,0
  ustack[argc] = 0;
    8000516a:	00349793          	slli	a5,s1,0x3
    8000516e:	f9040713          	addi	a4,s0,-112
    80005172:	97ba                	add	a5,a5,a4
    80005174:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005178:	00148693          	addi	a3,s1,1
    8000517c:	068e                	slli	a3,a3,0x3
    8000517e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005182:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005186:	01897663          	bgeu	s2,s8,80005192 <exec+0x242>
  sz = sz1;
    8000518a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000518e:	4481                	li	s1,0
    80005190:	a059                	j	80005216 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005192:	e9040613          	addi	a2,s0,-368
    80005196:	85ca                	mv	a1,s2
    80005198:	855e                	mv	a0,s7
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	4d8080e7          	jalr	1240(ra) # 80001672 <copyout>
    800051a2:	0a054663          	bltz	a0,8000524e <exec+0x2fe>
  p->trapframe->a1 = sp;
    800051a6:	058ab783          	ld	a5,88(s5)
    800051aa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051ae:	df843783          	ld	a5,-520(s0)
    800051b2:	0007c703          	lbu	a4,0(a5)
    800051b6:	cf11                	beqz	a4,800051d2 <exec+0x282>
    800051b8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051ba:	02f00693          	li	a3,47
    800051be:	a039                	j	800051cc <exec+0x27c>
      last = s+1;
    800051c0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800051c4:	0785                	addi	a5,a5,1
    800051c6:	fff7c703          	lbu	a4,-1(a5)
    800051ca:	c701                	beqz	a4,800051d2 <exec+0x282>
    if(*s == '/')
    800051cc:	fed71ce3          	bne	a4,a3,800051c4 <exec+0x274>
    800051d0:	bfc5                	j	800051c0 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800051d2:	4641                	li	a2,16
    800051d4:	df843583          	ld	a1,-520(s0)
    800051d8:	158a8513          	addi	a0,s5,344
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	c56080e7          	jalr	-938(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800051e4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800051e8:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800051ec:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051f0:	058ab783          	ld	a5,88(s5)
    800051f4:	e6843703          	ld	a4,-408(s0)
    800051f8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051fa:	058ab783          	ld	a5,88(s5)
    800051fe:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005202:	85ea                	mv	a1,s10
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	9a4080e7          	jalr	-1628(ra) # 80001ba8 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000520c:	0004851b          	sext.w	a0,s1
    80005210:	bbe1                	j	80004fe8 <exec+0x98>
    80005212:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005216:	e0843583          	ld	a1,-504(s0)
    8000521a:	855e                	mv	a0,s7
    8000521c:	ffffd097          	auipc	ra,0xffffd
    80005220:	98c080e7          	jalr	-1652(ra) # 80001ba8 <proc_freepagetable>
  if(ip){
    80005224:	da0498e3          	bnez	s1,80004fd4 <exec+0x84>
  return -1;
    80005228:	557d                	li	a0,-1
    8000522a:	bb7d                	j	80004fe8 <exec+0x98>
    8000522c:	e1243423          	sd	s2,-504(s0)
    80005230:	b7dd                	j	80005216 <exec+0x2c6>
    80005232:	e1243423          	sd	s2,-504(s0)
    80005236:	b7c5                	j	80005216 <exec+0x2c6>
    80005238:	e1243423          	sd	s2,-504(s0)
    8000523c:	bfe9                	j	80005216 <exec+0x2c6>
  sz = sz1;
    8000523e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005242:	4481                	li	s1,0
    80005244:	bfc9                	j	80005216 <exec+0x2c6>
  sz = sz1;
    80005246:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000524a:	4481                	li	s1,0
    8000524c:	b7e9                	j	80005216 <exec+0x2c6>
  sz = sz1;
    8000524e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005252:	4481                	li	s1,0
    80005254:	b7c9                	j	80005216 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005256:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000525a:	2b05                	addiw	s6,s6,1
    8000525c:	0389899b          	addiw	s3,s3,56
    80005260:	e8845783          	lhu	a5,-376(s0)
    80005264:	e2fb5be3          	bge	s6,a5,8000509a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005268:	2981                	sext.w	s3,s3
    8000526a:	03800713          	li	a4,56
    8000526e:	86ce                	mv	a3,s3
    80005270:	e1840613          	addi	a2,s0,-488
    80005274:	4581                	li	a1,0
    80005276:	8526                	mv	a0,s1
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	a8e080e7          	jalr	-1394(ra) # 80003d06 <readi>
    80005280:	03800793          	li	a5,56
    80005284:	f8f517e3          	bne	a0,a5,80005212 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005288:	e1842783          	lw	a5,-488(s0)
    8000528c:	4705                	li	a4,1
    8000528e:	fce796e3          	bne	a5,a4,8000525a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005292:	e4043603          	ld	a2,-448(s0)
    80005296:	e3843783          	ld	a5,-456(s0)
    8000529a:	f8f669e3          	bltu	a2,a5,8000522c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000529e:	e2843783          	ld	a5,-472(s0)
    800052a2:	963e                	add	a2,a2,a5
    800052a4:	f8f667e3          	bltu	a2,a5,80005232 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052a8:	85ca                	mv	a1,s2
    800052aa:	855e                	mv	a0,s7
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	176080e7          	jalr	374(ra) # 80001422 <uvmalloc>
    800052b4:	e0a43423          	sd	a0,-504(s0)
    800052b8:	d141                	beqz	a0,80005238 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800052ba:	e2843d03          	ld	s10,-472(s0)
    800052be:	df043783          	ld	a5,-528(s0)
    800052c2:	00fd77b3          	and	a5,s10,a5
    800052c6:	fba1                	bnez	a5,80005216 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052c8:	e2042d83          	lw	s11,-480(s0)
    800052cc:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052d0:	f80c03e3          	beqz	s8,80005256 <exec+0x306>
    800052d4:	8a62                	mv	s4,s8
    800052d6:	4901                	li	s2,0
    800052d8:	b345                	j	80005078 <exec+0x128>

00000000800052da <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052da:	7179                	addi	sp,sp,-48
    800052dc:	f406                	sd	ra,40(sp)
    800052de:	f022                	sd	s0,32(sp)
    800052e0:	ec26                	sd	s1,24(sp)
    800052e2:	e84a                	sd	s2,16(sp)
    800052e4:	1800                	addi	s0,sp,48
    800052e6:	892e                	mv	s2,a1
    800052e8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052ea:	fdc40593          	addi	a1,s0,-36
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	b74080e7          	jalr	-1164(ra) # 80002e62 <argint>
    800052f6:	04054063          	bltz	a0,80005336 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052fa:	fdc42703          	lw	a4,-36(s0)
    800052fe:	47bd                	li	a5,15
    80005300:	02e7ed63          	bltu	a5,a4,8000533a <argfd+0x60>
    80005304:	ffffc097          	auipc	ra,0xffffc
    80005308:	744080e7          	jalr	1860(ra) # 80001a48 <myproc>
    8000530c:	fdc42703          	lw	a4,-36(s0)
    80005310:	01a70793          	addi	a5,a4,26
    80005314:	078e                	slli	a5,a5,0x3
    80005316:	953e                	add	a0,a0,a5
    80005318:	611c                	ld	a5,0(a0)
    8000531a:	c395                	beqz	a5,8000533e <argfd+0x64>
    return -1;
  if(pfd)
    8000531c:	00090463          	beqz	s2,80005324 <argfd+0x4a>
    *pfd = fd;
    80005320:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005324:	4501                	li	a0,0
  if(pf)
    80005326:	c091                	beqz	s1,8000532a <argfd+0x50>
    *pf = f;
    80005328:	e09c                	sd	a5,0(s1)
}
    8000532a:	70a2                	ld	ra,40(sp)
    8000532c:	7402                	ld	s0,32(sp)
    8000532e:	64e2                	ld	s1,24(sp)
    80005330:	6942                	ld	s2,16(sp)
    80005332:	6145                	addi	sp,sp,48
    80005334:	8082                	ret
    return -1;
    80005336:	557d                	li	a0,-1
    80005338:	bfcd                	j	8000532a <argfd+0x50>
    return -1;
    8000533a:	557d                	li	a0,-1
    8000533c:	b7fd                	j	8000532a <argfd+0x50>
    8000533e:	557d                	li	a0,-1
    80005340:	b7ed                	j	8000532a <argfd+0x50>

0000000080005342 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005342:	1101                	addi	sp,sp,-32
    80005344:	ec06                	sd	ra,24(sp)
    80005346:	e822                	sd	s0,16(sp)
    80005348:	e426                	sd	s1,8(sp)
    8000534a:	1000                	addi	s0,sp,32
    8000534c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000534e:	ffffc097          	auipc	ra,0xffffc
    80005352:	6fa080e7          	jalr	1786(ra) # 80001a48 <myproc>
    80005356:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005358:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    8000535c:	4501                	li	a0,0
    8000535e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005360:	6398                	ld	a4,0(a5)
    80005362:	cb19                	beqz	a4,80005378 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005364:	2505                	addiw	a0,a0,1
    80005366:	07a1                	addi	a5,a5,8
    80005368:	fed51ce3          	bne	a0,a3,80005360 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000536c:	557d                	li	a0,-1
}
    8000536e:	60e2                	ld	ra,24(sp)
    80005370:	6442                	ld	s0,16(sp)
    80005372:	64a2                	ld	s1,8(sp)
    80005374:	6105                	addi	sp,sp,32
    80005376:	8082                	ret
      p->ofile[fd] = f;
    80005378:	01a50793          	addi	a5,a0,26
    8000537c:	078e                	slli	a5,a5,0x3
    8000537e:	963e                	add	a2,a2,a5
    80005380:	e204                	sd	s1,0(a2)
      return fd;
    80005382:	b7f5                	j	8000536e <fdalloc+0x2c>

0000000080005384 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005384:	715d                	addi	sp,sp,-80
    80005386:	e486                	sd	ra,72(sp)
    80005388:	e0a2                	sd	s0,64(sp)
    8000538a:	fc26                	sd	s1,56(sp)
    8000538c:	f84a                	sd	s2,48(sp)
    8000538e:	f44e                	sd	s3,40(sp)
    80005390:	f052                	sd	s4,32(sp)
    80005392:	ec56                	sd	s5,24(sp)
    80005394:	0880                	addi	s0,sp,80
    80005396:	89ae                	mv	s3,a1
    80005398:	8ab2                	mv	s5,a2
    8000539a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000539c:	fb040593          	addi	a1,s0,-80
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	e86080e7          	jalr	-378(ra) # 80004226 <nameiparent>
    800053a8:	892a                	mv	s2,a0
    800053aa:	12050f63          	beqz	a0,800054e8 <create+0x164>
    return 0;

  ilock(dp);
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	6a4080e7          	jalr	1700(ra) # 80003a52 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053b6:	4601                	li	a2,0
    800053b8:	fb040593          	addi	a1,s0,-80
    800053bc:	854a                	mv	a0,s2
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	b78080e7          	jalr	-1160(ra) # 80003f36 <dirlookup>
    800053c6:	84aa                	mv	s1,a0
    800053c8:	c921                	beqz	a0,80005418 <create+0x94>
    iunlockput(dp);
    800053ca:	854a                	mv	a0,s2
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	8e8080e7          	jalr	-1816(ra) # 80003cb4 <iunlockput>
    ilock(ip);
    800053d4:	8526                	mv	a0,s1
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	67c080e7          	jalr	1660(ra) # 80003a52 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053de:	2981                	sext.w	s3,s3
    800053e0:	4789                	li	a5,2
    800053e2:	02f99463          	bne	s3,a5,8000540a <create+0x86>
    800053e6:	0444d783          	lhu	a5,68(s1)
    800053ea:	37f9                	addiw	a5,a5,-2
    800053ec:	17c2                	slli	a5,a5,0x30
    800053ee:	93c1                	srli	a5,a5,0x30
    800053f0:	4705                	li	a4,1
    800053f2:	00f76c63          	bltu	a4,a5,8000540a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053f6:	8526                	mv	a0,s1
    800053f8:	60a6                	ld	ra,72(sp)
    800053fa:	6406                	ld	s0,64(sp)
    800053fc:	74e2                	ld	s1,56(sp)
    800053fe:	7942                	ld	s2,48(sp)
    80005400:	79a2                	ld	s3,40(sp)
    80005402:	7a02                	ld	s4,32(sp)
    80005404:	6ae2                	ld	s5,24(sp)
    80005406:	6161                	addi	sp,sp,80
    80005408:	8082                	ret
    iunlockput(ip);
    8000540a:	8526                	mv	a0,s1
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	8a8080e7          	jalr	-1880(ra) # 80003cb4 <iunlockput>
    return 0;
    80005414:	4481                	li	s1,0
    80005416:	b7c5                	j	800053f6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005418:	85ce                	mv	a1,s3
    8000541a:	00092503          	lw	a0,0(s2)
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	49c080e7          	jalr	1180(ra) # 800038ba <ialloc>
    80005426:	84aa                	mv	s1,a0
    80005428:	c529                	beqz	a0,80005472 <create+0xee>
  ilock(ip);
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	628080e7          	jalr	1576(ra) # 80003a52 <ilock>
  ip->major = major;
    80005432:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005436:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000543a:	4785                	li	a5,1
    8000543c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005440:	8526                	mv	a0,s1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	546080e7          	jalr	1350(ra) # 80003988 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000544a:	2981                	sext.w	s3,s3
    8000544c:	4785                	li	a5,1
    8000544e:	02f98a63          	beq	s3,a5,80005482 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005452:	40d0                	lw	a2,4(s1)
    80005454:	fb040593          	addi	a1,s0,-80
    80005458:	854a                	mv	a0,s2
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	cec080e7          	jalr	-788(ra) # 80004146 <dirlink>
    80005462:	06054b63          	bltz	a0,800054d8 <create+0x154>
  iunlockput(dp);
    80005466:	854a                	mv	a0,s2
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	84c080e7          	jalr	-1972(ra) # 80003cb4 <iunlockput>
  return ip;
    80005470:	b759                	j	800053f6 <create+0x72>
    panic("create: ialloc");
    80005472:	00003517          	auipc	a0,0x3
    80005476:	30e50513          	addi	a0,a0,782 # 80008780 <syscalls+0x2c0>
    8000547a:	ffffb097          	auipc	ra,0xffffb
    8000547e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005482:	04a95783          	lhu	a5,74(s2)
    80005486:	2785                	addiw	a5,a5,1
    80005488:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000548c:	854a                	mv	a0,s2
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	4fa080e7          	jalr	1274(ra) # 80003988 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005496:	40d0                	lw	a2,4(s1)
    80005498:	00003597          	auipc	a1,0x3
    8000549c:	2f858593          	addi	a1,a1,760 # 80008790 <syscalls+0x2d0>
    800054a0:	8526                	mv	a0,s1
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	ca4080e7          	jalr	-860(ra) # 80004146 <dirlink>
    800054aa:	00054f63          	bltz	a0,800054c8 <create+0x144>
    800054ae:	00492603          	lw	a2,4(s2)
    800054b2:	00003597          	auipc	a1,0x3
    800054b6:	2e658593          	addi	a1,a1,742 # 80008798 <syscalls+0x2d8>
    800054ba:	8526                	mv	a0,s1
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	c8a080e7          	jalr	-886(ra) # 80004146 <dirlink>
    800054c4:	f80557e3          	bgez	a0,80005452 <create+0xce>
      panic("create dots");
    800054c8:	00003517          	auipc	a0,0x3
    800054cc:	2d850513          	addi	a0,a0,728 # 800087a0 <syscalls+0x2e0>
    800054d0:	ffffb097          	auipc	ra,0xffffb
    800054d4:	06e080e7          	jalr	110(ra) # 8000053e <panic>
    panic("create: dirlink");
    800054d8:	00003517          	auipc	a0,0x3
    800054dc:	2d850513          	addi	a0,a0,728 # 800087b0 <syscalls+0x2f0>
    800054e0:	ffffb097          	auipc	ra,0xffffb
    800054e4:	05e080e7          	jalr	94(ra) # 8000053e <panic>
    return 0;
    800054e8:	84aa                	mv	s1,a0
    800054ea:	b731                	j	800053f6 <create+0x72>

00000000800054ec <sys_dup>:
{
    800054ec:	7179                	addi	sp,sp,-48
    800054ee:	f406                	sd	ra,40(sp)
    800054f0:	f022                	sd	s0,32(sp)
    800054f2:	ec26                	sd	s1,24(sp)
    800054f4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054f6:	fd840613          	addi	a2,s0,-40
    800054fa:	4581                	li	a1,0
    800054fc:	4501                	li	a0,0
    800054fe:	00000097          	auipc	ra,0x0
    80005502:	ddc080e7          	jalr	-548(ra) # 800052da <argfd>
    return -1;
    80005506:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005508:	02054363          	bltz	a0,8000552e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000550c:	fd843503          	ld	a0,-40(s0)
    80005510:	00000097          	auipc	ra,0x0
    80005514:	e32080e7          	jalr	-462(ra) # 80005342 <fdalloc>
    80005518:	84aa                	mv	s1,a0
    return -1;
    8000551a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000551c:	00054963          	bltz	a0,8000552e <sys_dup+0x42>
  filedup(f);
    80005520:	fd843503          	ld	a0,-40(s0)
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	37a080e7          	jalr	890(ra) # 8000489e <filedup>
  return fd;
    8000552c:	87a6                	mv	a5,s1
}
    8000552e:	853e                	mv	a0,a5
    80005530:	70a2                	ld	ra,40(sp)
    80005532:	7402                	ld	s0,32(sp)
    80005534:	64e2                	ld	s1,24(sp)
    80005536:	6145                	addi	sp,sp,48
    80005538:	8082                	ret

000000008000553a <sys_read>:
{
    8000553a:	7179                	addi	sp,sp,-48
    8000553c:	f406                	sd	ra,40(sp)
    8000553e:	f022                	sd	s0,32(sp)
    80005540:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005542:	fe840613          	addi	a2,s0,-24
    80005546:	4581                	li	a1,0
    80005548:	4501                	li	a0,0
    8000554a:	00000097          	auipc	ra,0x0
    8000554e:	d90080e7          	jalr	-624(ra) # 800052da <argfd>
    return -1;
    80005552:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005554:	04054163          	bltz	a0,80005596 <sys_read+0x5c>
    80005558:	fe440593          	addi	a1,s0,-28
    8000555c:	4509                	li	a0,2
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	904080e7          	jalr	-1788(ra) # 80002e62 <argint>
    return -1;
    80005566:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005568:	02054763          	bltz	a0,80005596 <sys_read+0x5c>
    8000556c:	fd840593          	addi	a1,s0,-40
    80005570:	4505                	li	a0,1
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	912080e7          	jalr	-1774(ra) # 80002e84 <argaddr>
    return -1;
    8000557a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000557c:	00054d63          	bltz	a0,80005596 <sys_read+0x5c>
  return fileread(f, p, n);
    80005580:	fe442603          	lw	a2,-28(s0)
    80005584:	fd843583          	ld	a1,-40(s0)
    80005588:	fe843503          	ld	a0,-24(s0)
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	49e080e7          	jalr	1182(ra) # 80004a2a <fileread>
    80005594:	87aa                	mv	a5,a0
}
    80005596:	853e                	mv	a0,a5
    80005598:	70a2                	ld	ra,40(sp)
    8000559a:	7402                	ld	s0,32(sp)
    8000559c:	6145                	addi	sp,sp,48
    8000559e:	8082                	ret

00000000800055a0 <sys_write>:
{
    800055a0:	7179                	addi	sp,sp,-48
    800055a2:	f406                	sd	ra,40(sp)
    800055a4:	f022                	sd	s0,32(sp)
    800055a6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a8:	fe840613          	addi	a2,s0,-24
    800055ac:	4581                	li	a1,0
    800055ae:	4501                	li	a0,0
    800055b0:	00000097          	auipc	ra,0x0
    800055b4:	d2a080e7          	jalr	-726(ra) # 800052da <argfd>
    return -1;
    800055b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ba:	04054163          	bltz	a0,800055fc <sys_write+0x5c>
    800055be:	fe440593          	addi	a1,s0,-28
    800055c2:	4509                	li	a0,2
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	89e080e7          	jalr	-1890(ra) # 80002e62 <argint>
    return -1;
    800055cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ce:	02054763          	bltz	a0,800055fc <sys_write+0x5c>
    800055d2:	fd840593          	addi	a1,s0,-40
    800055d6:	4505                	li	a0,1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	8ac080e7          	jalr	-1876(ra) # 80002e84 <argaddr>
    return -1;
    800055e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055e2:	00054d63          	bltz	a0,800055fc <sys_write+0x5c>
  return filewrite(f, p, n);
    800055e6:	fe442603          	lw	a2,-28(s0)
    800055ea:	fd843583          	ld	a1,-40(s0)
    800055ee:	fe843503          	ld	a0,-24(s0)
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	4fa080e7          	jalr	1274(ra) # 80004aec <filewrite>
    800055fa:	87aa                	mv	a5,a0
}
    800055fc:	853e                	mv	a0,a5
    800055fe:	70a2                	ld	ra,40(sp)
    80005600:	7402                	ld	s0,32(sp)
    80005602:	6145                	addi	sp,sp,48
    80005604:	8082                	ret

0000000080005606 <sys_close>:
{
    80005606:	1101                	addi	sp,sp,-32
    80005608:	ec06                	sd	ra,24(sp)
    8000560a:	e822                	sd	s0,16(sp)
    8000560c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000560e:	fe040613          	addi	a2,s0,-32
    80005612:	fec40593          	addi	a1,s0,-20
    80005616:	4501                	li	a0,0
    80005618:	00000097          	auipc	ra,0x0
    8000561c:	cc2080e7          	jalr	-830(ra) # 800052da <argfd>
    return -1;
    80005620:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005622:	02054463          	bltz	a0,8000564a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005626:	ffffc097          	auipc	ra,0xffffc
    8000562a:	422080e7          	jalr	1058(ra) # 80001a48 <myproc>
    8000562e:	fec42783          	lw	a5,-20(s0)
    80005632:	07e9                	addi	a5,a5,26
    80005634:	078e                	slli	a5,a5,0x3
    80005636:	97aa                	add	a5,a5,a0
    80005638:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000563c:	fe043503          	ld	a0,-32(s0)
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	2b0080e7          	jalr	688(ra) # 800048f0 <fileclose>
  return 0;
    80005648:	4781                	li	a5,0
}
    8000564a:	853e                	mv	a0,a5
    8000564c:	60e2                	ld	ra,24(sp)
    8000564e:	6442                	ld	s0,16(sp)
    80005650:	6105                	addi	sp,sp,32
    80005652:	8082                	ret

0000000080005654 <sys_fstat>:
{
    80005654:	1101                	addi	sp,sp,-32
    80005656:	ec06                	sd	ra,24(sp)
    80005658:	e822                	sd	s0,16(sp)
    8000565a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000565c:	fe840613          	addi	a2,s0,-24
    80005660:	4581                	li	a1,0
    80005662:	4501                	li	a0,0
    80005664:	00000097          	auipc	ra,0x0
    80005668:	c76080e7          	jalr	-906(ra) # 800052da <argfd>
    return -1;
    8000566c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000566e:	02054563          	bltz	a0,80005698 <sys_fstat+0x44>
    80005672:	fe040593          	addi	a1,s0,-32
    80005676:	4505                	li	a0,1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	80c080e7          	jalr	-2036(ra) # 80002e84 <argaddr>
    return -1;
    80005680:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005682:	00054b63          	bltz	a0,80005698 <sys_fstat+0x44>
  return filestat(f, st);
    80005686:	fe043583          	ld	a1,-32(s0)
    8000568a:	fe843503          	ld	a0,-24(s0)
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	32a080e7          	jalr	810(ra) # 800049b8 <filestat>
    80005696:	87aa                	mv	a5,a0
}
    80005698:	853e                	mv	a0,a5
    8000569a:	60e2                	ld	ra,24(sp)
    8000569c:	6442                	ld	s0,16(sp)
    8000569e:	6105                	addi	sp,sp,32
    800056a0:	8082                	ret

00000000800056a2 <sys_link>:
{
    800056a2:	7169                	addi	sp,sp,-304
    800056a4:	f606                	sd	ra,296(sp)
    800056a6:	f222                	sd	s0,288(sp)
    800056a8:	ee26                	sd	s1,280(sp)
    800056aa:	ea4a                	sd	s2,272(sp)
    800056ac:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ae:	08000613          	li	a2,128
    800056b2:	ed040593          	addi	a1,s0,-304
    800056b6:	4501                	li	a0,0
    800056b8:	ffffd097          	auipc	ra,0xffffd
    800056bc:	7ee080e7          	jalr	2030(ra) # 80002ea6 <argstr>
    return -1;
    800056c0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c2:	10054e63          	bltz	a0,800057de <sys_link+0x13c>
    800056c6:	08000613          	li	a2,128
    800056ca:	f5040593          	addi	a1,s0,-176
    800056ce:	4505                	li	a0,1
    800056d0:	ffffd097          	auipc	ra,0xffffd
    800056d4:	7d6080e7          	jalr	2006(ra) # 80002ea6 <argstr>
    return -1;
    800056d8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056da:	10054263          	bltz	a0,800057de <sys_link+0x13c>
  begin_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	d46080e7          	jalr	-698(ra) # 80004424 <begin_op>
  if((ip = namei(old)) == 0){
    800056e6:	ed040513          	addi	a0,s0,-304
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	b1e080e7          	jalr	-1250(ra) # 80004208 <namei>
    800056f2:	84aa                	mv	s1,a0
    800056f4:	c551                	beqz	a0,80005780 <sys_link+0xde>
  ilock(ip);
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	35c080e7          	jalr	860(ra) # 80003a52 <ilock>
  if(ip->type == T_DIR){
    800056fe:	04449703          	lh	a4,68(s1)
    80005702:	4785                	li	a5,1
    80005704:	08f70463          	beq	a4,a5,8000578c <sys_link+0xea>
  ip->nlink++;
    80005708:	04a4d783          	lhu	a5,74(s1)
    8000570c:	2785                	addiw	a5,a5,1
    8000570e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005712:	8526                	mv	a0,s1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	274080e7          	jalr	628(ra) # 80003988 <iupdate>
  iunlock(ip);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	3f6080e7          	jalr	1014(ra) # 80003b14 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005726:	fd040593          	addi	a1,s0,-48
    8000572a:	f5040513          	addi	a0,s0,-176
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	af8080e7          	jalr	-1288(ra) # 80004226 <nameiparent>
    80005736:	892a                	mv	s2,a0
    80005738:	c935                	beqz	a0,800057ac <sys_link+0x10a>
  ilock(dp);
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	318080e7          	jalr	792(ra) # 80003a52 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005742:	00092703          	lw	a4,0(s2)
    80005746:	409c                	lw	a5,0(s1)
    80005748:	04f71d63          	bne	a4,a5,800057a2 <sys_link+0x100>
    8000574c:	40d0                	lw	a2,4(s1)
    8000574e:	fd040593          	addi	a1,s0,-48
    80005752:	854a                	mv	a0,s2
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	9f2080e7          	jalr	-1550(ra) # 80004146 <dirlink>
    8000575c:	04054363          	bltz	a0,800057a2 <sys_link+0x100>
  iunlockput(dp);
    80005760:	854a                	mv	a0,s2
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	552080e7          	jalr	1362(ra) # 80003cb4 <iunlockput>
  iput(ip);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	4a0080e7          	jalr	1184(ra) # 80003c0c <iput>
  end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	d30080e7          	jalr	-720(ra) # 800044a4 <end_op>
  return 0;
    8000577c:	4781                	li	a5,0
    8000577e:	a085                	j	800057de <sys_link+0x13c>
    end_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	d24080e7          	jalr	-732(ra) # 800044a4 <end_op>
    return -1;
    80005788:	57fd                	li	a5,-1
    8000578a:	a891                	j	800057de <sys_link+0x13c>
    iunlockput(ip);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	526080e7          	jalr	1318(ra) # 80003cb4 <iunlockput>
    end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	d0e080e7          	jalr	-754(ra) # 800044a4 <end_op>
    return -1;
    8000579e:	57fd                	li	a5,-1
    800057a0:	a83d                	j	800057de <sys_link+0x13c>
    iunlockput(dp);
    800057a2:	854a                	mv	a0,s2
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	510080e7          	jalr	1296(ra) # 80003cb4 <iunlockput>
  ilock(ip);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	2a4080e7          	jalr	676(ra) # 80003a52 <ilock>
  ip->nlink--;
    800057b6:	04a4d783          	lhu	a5,74(s1)
    800057ba:	37fd                	addiw	a5,a5,-1
    800057bc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057c0:	8526                	mv	a0,s1
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	1c6080e7          	jalr	454(ra) # 80003988 <iupdate>
  iunlockput(ip);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	4e8080e7          	jalr	1256(ra) # 80003cb4 <iunlockput>
  end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	cd0080e7          	jalr	-816(ra) # 800044a4 <end_op>
  return -1;
    800057dc:	57fd                	li	a5,-1
}
    800057de:	853e                	mv	a0,a5
    800057e0:	70b2                	ld	ra,296(sp)
    800057e2:	7412                	ld	s0,288(sp)
    800057e4:	64f2                	ld	s1,280(sp)
    800057e6:	6952                	ld	s2,272(sp)
    800057e8:	6155                	addi	sp,sp,304
    800057ea:	8082                	ret

00000000800057ec <sys_unlink>:
{
    800057ec:	7151                	addi	sp,sp,-240
    800057ee:	f586                	sd	ra,232(sp)
    800057f0:	f1a2                	sd	s0,224(sp)
    800057f2:	eda6                	sd	s1,216(sp)
    800057f4:	e9ca                	sd	s2,208(sp)
    800057f6:	e5ce                	sd	s3,200(sp)
    800057f8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057fa:	08000613          	li	a2,128
    800057fe:	f3040593          	addi	a1,s0,-208
    80005802:	4501                	li	a0,0
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	6a2080e7          	jalr	1698(ra) # 80002ea6 <argstr>
    8000580c:	18054163          	bltz	a0,8000598e <sys_unlink+0x1a2>
  begin_op();
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	c14080e7          	jalr	-1004(ra) # 80004424 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005818:	fb040593          	addi	a1,s0,-80
    8000581c:	f3040513          	addi	a0,s0,-208
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	a06080e7          	jalr	-1530(ra) # 80004226 <nameiparent>
    80005828:	84aa                	mv	s1,a0
    8000582a:	c979                	beqz	a0,80005900 <sys_unlink+0x114>
  ilock(dp);
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	226080e7          	jalr	550(ra) # 80003a52 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005834:	00003597          	auipc	a1,0x3
    80005838:	f5c58593          	addi	a1,a1,-164 # 80008790 <syscalls+0x2d0>
    8000583c:	fb040513          	addi	a0,s0,-80
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	6dc080e7          	jalr	1756(ra) # 80003f1c <namecmp>
    80005848:	14050a63          	beqz	a0,8000599c <sys_unlink+0x1b0>
    8000584c:	00003597          	auipc	a1,0x3
    80005850:	f4c58593          	addi	a1,a1,-180 # 80008798 <syscalls+0x2d8>
    80005854:	fb040513          	addi	a0,s0,-80
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	6c4080e7          	jalr	1732(ra) # 80003f1c <namecmp>
    80005860:	12050e63          	beqz	a0,8000599c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005864:	f2c40613          	addi	a2,s0,-212
    80005868:	fb040593          	addi	a1,s0,-80
    8000586c:	8526                	mv	a0,s1
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	6c8080e7          	jalr	1736(ra) # 80003f36 <dirlookup>
    80005876:	892a                	mv	s2,a0
    80005878:	12050263          	beqz	a0,8000599c <sys_unlink+0x1b0>
  ilock(ip);
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	1d6080e7          	jalr	470(ra) # 80003a52 <ilock>
  if(ip->nlink < 1)
    80005884:	04a91783          	lh	a5,74(s2)
    80005888:	08f05263          	blez	a5,8000590c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000588c:	04491703          	lh	a4,68(s2)
    80005890:	4785                	li	a5,1
    80005892:	08f70563          	beq	a4,a5,8000591c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005896:	4641                	li	a2,16
    80005898:	4581                	li	a1,0
    8000589a:	fc040513          	addi	a0,s0,-64
    8000589e:	ffffb097          	auipc	ra,0xffffb
    800058a2:	442080e7          	jalr	1090(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a6:	4741                	li	a4,16
    800058a8:	f2c42683          	lw	a3,-212(s0)
    800058ac:	fc040613          	addi	a2,s0,-64
    800058b0:	4581                	li	a1,0
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	54a080e7          	jalr	1354(ra) # 80003dfe <writei>
    800058bc:	47c1                	li	a5,16
    800058be:	0af51563          	bne	a0,a5,80005968 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058c2:	04491703          	lh	a4,68(s2)
    800058c6:	4785                	li	a5,1
    800058c8:	0af70863          	beq	a4,a5,80005978 <sys_unlink+0x18c>
  iunlockput(dp);
    800058cc:	8526                	mv	a0,s1
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	3e6080e7          	jalr	998(ra) # 80003cb4 <iunlockput>
  ip->nlink--;
    800058d6:	04a95783          	lhu	a5,74(s2)
    800058da:	37fd                	addiw	a5,a5,-1
    800058dc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058e0:	854a                	mv	a0,s2
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	0a6080e7          	jalr	166(ra) # 80003988 <iupdate>
  iunlockput(ip);
    800058ea:	854a                	mv	a0,s2
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	3c8080e7          	jalr	968(ra) # 80003cb4 <iunlockput>
  end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	bb0080e7          	jalr	-1104(ra) # 800044a4 <end_op>
  return 0;
    800058fc:	4501                	li	a0,0
    800058fe:	a84d                	j	800059b0 <sys_unlink+0x1c4>
    end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	ba4080e7          	jalr	-1116(ra) # 800044a4 <end_op>
    return -1;
    80005908:	557d                	li	a0,-1
    8000590a:	a05d                	j	800059b0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000590c:	00003517          	auipc	a0,0x3
    80005910:	eb450513          	addi	a0,a0,-332 # 800087c0 <syscalls+0x300>
    80005914:	ffffb097          	auipc	ra,0xffffb
    80005918:	c2a080e7          	jalr	-982(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000591c:	04c92703          	lw	a4,76(s2)
    80005920:	02000793          	li	a5,32
    80005924:	f6e7f9e3          	bgeu	a5,a4,80005896 <sys_unlink+0xaa>
    80005928:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000592c:	4741                	li	a4,16
    8000592e:	86ce                	mv	a3,s3
    80005930:	f1840613          	addi	a2,s0,-232
    80005934:	4581                	li	a1,0
    80005936:	854a                	mv	a0,s2
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	3ce080e7          	jalr	974(ra) # 80003d06 <readi>
    80005940:	47c1                	li	a5,16
    80005942:	00f51b63          	bne	a0,a5,80005958 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005946:	f1845783          	lhu	a5,-232(s0)
    8000594a:	e7a1                	bnez	a5,80005992 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000594c:	29c1                	addiw	s3,s3,16
    8000594e:	04c92783          	lw	a5,76(s2)
    80005952:	fcf9ede3          	bltu	s3,a5,8000592c <sys_unlink+0x140>
    80005956:	b781                	j	80005896 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005958:	00003517          	auipc	a0,0x3
    8000595c:	e8050513          	addi	a0,a0,-384 # 800087d8 <syscalls+0x318>
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005968:	00003517          	auipc	a0,0x3
    8000596c:	e8850513          	addi	a0,a0,-376 # 800087f0 <syscalls+0x330>
    80005970:	ffffb097          	auipc	ra,0xffffb
    80005974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    dp->nlink--;
    80005978:	04a4d783          	lhu	a5,74(s1)
    8000597c:	37fd                	addiw	a5,a5,-1
    8000597e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005982:	8526                	mv	a0,s1
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	004080e7          	jalr	4(ra) # 80003988 <iupdate>
    8000598c:	b781                	j	800058cc <sys_unlink+0xe0>
    return -1;
    8000598e:	557d                	li	a0,-1
    80005990:	a005                	j	800059b0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005992:	854a                	mv	a0,s2
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	320080e7          	jalr	800(ra) # 80003cb4 <iunlockput>
  iunlockput(dp);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	316080e7          	jalr	790(ra) # 80003cb4 <iunlockput>
  end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	afe080e7          	jalr	-1282(ra) # 800044a4 <end_op>
  return -1;
    800059ae:	557d                	li	a0,-1
}
    800059b0:	70ae                	ld	ra,232(sp)
    800059b2:	740e                	ld	s0,224(sp)
    800059b4:	64ee                	ld	s1,216(sp)
    800059b6:	694e                	ld	s2,208(sp)
    800059b8:	69ae                	ld	s3,200(sp)
    800059ba:	616d                	addi	sp,sp,240
    800059bc:	8082                	ret

00000000800059be <sys_open>:

uint64
sys_open(void)
{
    800059be:	7131                	addi	sp,sp,-192
    800059c0:	fd06                	sd	ra,184(sp)
    800059c2:	f922                	sd	s0,176(sp)
    800059c4:	f526                	sd	s1,168(sp)
    800059c6:	f14a                	sd	s2,160(sp)
    800059c8:	ed4e                	sd	s3,152(sp)
    800059ca:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059cc:	08000613          	li	a2,128
    800059d0:	f5040593          	addi	a1,s0,-176
    800059d4:	4501                	li	a0,0
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	4d0080e7          	jalr	1232(ra) # 80002ea6 <argstr>
    return -1;
    800059de:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059e0:	0c054163          	bltz	a0,80005aa2 <sys_open+0xe4>
    800059e4:	f4c40593          	addi	a1,s0,-180
    800059e8:	4505                	li	a0,1
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	478080e7          	jalr	1144(ra) # 80002e62 <argint>
    800059f2:	0a054863          	bltz	a0,80005aa2 <sys_open+0xe4>

  begin_op();
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	a2e080e7          	jalr	-1490(ra) # 80004424 <begin_op>

  if(omode & O_CREATE){
    800059fe:	f4c42783          	lw	a5,-180(s0)
    80005a02:	2007f793          	andi	a5,a5,512
    80005a06:	cbdd                	beqz	a5,80005abc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a08:	4681                	li	a3,0
    80005a0a:	4601                	li	a2,0
    80005a0c:	4589                	li	a1,2
    80005a0e:	f5040513          	addi	a0,s0,-176
    80005a12:	00000097          	auipc	ra,0x0
    80005a16:	972080e7          	jalr	-1678(ra) # 80005384 <create>
    80005a1a:	892a                	mv	s2,a0
    if(ip == 0){
    80005a1c:	c959                	beqz	a0,80005ab2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a1e:	04491703          	lh	a4,68(s2)
    80005a22:	478d                	li	a5,3
    80005a24:	00f71763          	bne	a4,a5,80005a32 <sys_open+0x74>
    80005a28:	04695703          	lhu	a4,70(s2)
    80005a2c:	47a5                	li	a5,9
    80005a2e:	0ce7ec63          	bltu	a5,a4,80005b06 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	e02080e7          	jalr	-510(ra) # 80004834 <filealloc>
    80005a3a:	89aa                	mv	s3,a0
    80005a3c:	10050263          	beqz	a0,80005b40 <sys_open+0x182>
    80005a40:	00000097          	auipc	ra,0x0
    80005a44:	902080e7          	jalr	-1790(ra) # 80005342 <fdalloc>
    80005a48:	84aa                	mv	s1,a0
    80005a4a:	0e054663          	bltz	a0,80005b36 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a4e:	04491703          	lh	a4,68(s2)
    80005a52:	478d                	li	a5,3
    80005a54:	0cf70463          	beq	a4,a5,80005b1c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a58:	4789                	li	a5,2
    80005a5a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a5e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a62:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a66:	f4c42783          	lw	a5,-180(s0)
    80005a6a:	0017c713          	xori	a4,a5,1
    80005a6e:	8b05                	andi	a4,a4,1
    80005a70:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a74:	0037f713          	andi	a4,a5,3
    80005a78:	00e03733          	snez	a4,a4
    80005a7c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a80:	4007f793          	andi	a5,a5,1024
    80005a84:	c791                	beqz	a5,80005a90 <sys_open+0xd2>
    80005a86:	04491703          	lh	a4,68(s2)
    80005a8a:	4789                	li	a5,2
    80005a8c:	08f70f63          	beq	a4,a5,80005b2a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a90:	854a                	mv	a0,s2
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	082080e7          	jalr	130(ra) # 80003b14 <iunlock>
  end_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	a0a080e7          	jalr	-1526(ra) # 800044a4 <end_op>

  return fd;
}
    80005aa2:	8526                	mv	a0,s1
    80005aa4:	70ea                	ld	ra,184(sp)
    80005aa6:	744a                	ld	s0,176(sp)
    80005aa8:	74aa                	ld	s1,168(sp)
    80005aaa:	790a                	ld	s2,160(sp)
    80005aac:	69ea                	ld	s3,152(sp)
    80005aae:	6129                	addi	sp,sp,192
    80005ab0:	8082                	ret
      end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	9f2080e7          	jalr	-1550(ra) # 800044a4 <end_op>
      return -1;
    80005aba:	b7e5                	j	80005aa2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005abc:	f5040513          	addi	a0,s0,-176
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	748080e7          	jalr	1864(ra) # 80004208 <namei>
    80005ac8:	892a                	mv	s2,a0
    80005aca:	c905                	beqz	a0,80005afa <sys_open+0x13c>
    ilock(ip);
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	f86080e7          	jalr	-122(ra) # 80003a52 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ad4:	04491703          	lh	a4,68(s2)
    80005ad8:	4785                	li	a5,1
    80005ada:	f4f712e3          	bne	a4,a5,80005a1e <sys_open+0x60>
    80005ade:	f4c42783          	lw	a5,-180(s0)
    80005ae2:	dba1                	beqz	a5,80005a32 <sys_open+0x74>
      iunlockput(ip);
    80005ae4:	854a                	mv	a0,s2
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	1ce080e7          	jalr	462(ra) # 80003cb4 <iunlockput>
      end_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	9b6080e7          	jalr	-1610(ra) # 800044a4 <end_op>
      return -1;
    80005af6:	54fd                	li	s1,-1
    80005af8:	b76d                	j	80005aa2 <sys_open+0xe4>
      end_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	9aa080e7          	jalr	-1622(ra) # 800044a4 <end_op>
      return -1;
    80005b02:	54fd                	li	s1,-1
    80005b04:	bf79                	j	80005aa2 <sys_open+0xe4>
    iunlockput(ip);
    80005b06:	854a                	mv	a0,s2
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	1ac080e7          	jalr	428(ra) # 80003cb4 <iunlockput>
    end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	994080e7          	jalr	-1644(ra) # 800044a4 <end_op>
    return -1;
    80005b18:	54fd                	li	s1,-1
    80005b1a:	b761                	j	80005aa2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b1c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b20:	04691783          	lh	a5,70(s2)
    80005b24:	02f99223          	sh	a5,36(s3)
    80005b28:	bf2d                	j	80005a62 <sys_open+0xa4>
    itrunc(ip);
    80005b2a:	854a                	mv	a0,s2
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	034080e7          	jalr	52(ra) # 80003b60 <itrunc>
    80005b34:	bfb1                	j	80005a90 <sys_open+0xd2>
      fileclose(f);
    80005b36:	854e                	mv	a0,s3
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	db8080e7          	jalr	-584(ra) # 800048f0 <fileclose>
    iunlockput(ip);
    80005b40:	854a                	mv	a0,s2
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	172080e7          	jalr	370(ra) # 80003cb4 <iunlockput>
    end_op();
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	95a080e7          	jalr	-1702(ra) # 800044a4 <end_op>
    return -1;
    80005b52:	54fd                	li	s1,-1
    80005b54:	b7b9                	j	80005aa2 <sys_open+0xe4>

0000000080005b56 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b56:	7175                	addi	sp,sp,-144
    80005b58:	e506                	sd	ra,136(sp)
    80005b5a:	e122                	sd	s0,128(sp)
    80005b5c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	8c6080e7          	jalr	-1850(ra) # 80004424 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b66:	08000613          	li	a2,128
    80005b6a:	f7040593          	addi	a1,s0,-144
    80005b6e:	4501                	li	a0,0
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	336080e7          	jalr	822(ra) # 80002ea6 <argstr>
    80005b78:	02054963          	bltz	a0,80005baa <sys_mkdir+0x54>
    80005b7c:	4681                	li	a3,0
    80005b7e:	4601                	li	a2,0
    80005b80:	4585                	li	a1,1
    80005b82:	f7040513          	addi	a0,s0,-144
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	7fe080e7          	jalr	2046(ra) # 80005384 <create>
    80005b8e:	cd11                	beqz	a0,80005baa <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	124080e7          	jalr	292(ra) # 80003cb4 <iunlockput>
  end_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	90c080e7          	jalr	-1780(ra) # 800044a4 <end_op>
  return 0;
    80005ba0:	4501                	li	a0,0
}
    80005ba2:	60aa                	ld	ra,136(sp)
    80005ba4:	640a                	ld	s0,128(sp)
    80005ba6:	6149                	addi	sp,sp,144
    80005ba8:	8082                	ret
    end_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	8fa080e7          	jalr	-1798(ra) # 800044a4 <end_op>
    return -1;
    80005bb2:	557d                	li	a0,-1
    80005bb4:	b7fd                	j	80005ba2 <sys_mkdir+0x4c>

0000000080005bb6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bb6:	7135                	addi	sp,sp,-160
    80005bb8:	ed06                	sd	ra,152(sp)
    80005bba:	e922                	sd	s0,144(sp)
    80005bbc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	866080e7          	jalr	-1946(ra) # 80004424 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bc6:	08000613          	li	a2,128
    80005bca:	f7040593          	addi	a1,s0,-144
    80005bce:	4501                	li	a0,0
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	2d6080e7          	jalr	726(ra) # 80002ea6 <argstr>
    80005bd8:	04054a63          	bltz	a0,80005c2c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005bdc:	f6c40593          	addi	a1,s0,-148
    80005be0:	4505                	li	a0,1
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	280080e7          	jalr	640(ra) # 80002e62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bea:	04054163          	bltz	a0,80005c2c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bee:	f6840593          	addi	a1,s0,-152
    80005bf2:	4509                	li	a0,2
    80005bf4:	ffffd097          	auipc	ra,0xffffd
    80005bf8:	26e080e7          	jalr	622(ra) # 80002e62 <argint>
     argint(1, &major) < 0 ||
    80005bfc:	02054863          	bltz	a0,80005c2c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c00:	f6841683          	lh	a3,-152(s0)
    80005c04:	f6c41603          	lh	a2,-148(s0)
    80005c08:	458d                	li	a1,3
    80005c0a:	f7040513          	addi	a0,s0,-144
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	776080e7          	jalr	1910(ra) # 80005384 <create>
     argint(2, &minor) < 0 ||
    80005c16:	c919                	beqz	a0,80005c2c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	09c080e7          	jalr	156(ra) # 80003cb4 <iunlockput>
  end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	884080e7          	jalr	-1916(ra) # 800044a4 <end_op>
  return 0;
    80005c28:	4501                	li	a0,0
    80005c2a:	a031                	j	80005c36 <sys_mknod+0x80>
    end_op();
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	878080e7          	jalr	-1928(ra) # 800044a4 <end_op>
    return -1;
    80005c34:	557d                	li	a0,-1
}
    80005c36:	60ea                	ld	ra,152(sp)
    80005c38:	644a                	ld	s0,144(sp)
    80005c3a:	610d                	addi	sp,sp,160
    80005c3c:	8082                	ret

0000000080005c3e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c3e:	7135                	addi	sp,sp,-160
    80005c40:	ed06                	sd	ra,152(sp)
    80005c42:	e922                	sd	s0,144(sp)
    80005c44:	e526                	sd	s1,136(sp)
    80005c46:	e14a                	sd	s2,128(sp)
    80005c48:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c4a:	ffffc097          	auipc	ra,0xffffc
    80005c4e:	dfe080e7          	jalr	-514(ra) # 80001a48 <myproc>
    80005c52:	892a                	mv	s2,a0
  
  begin_op();
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	7d0080e7          	jalr	2000(ra) # 80004424 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c5c:	08000613          	li	a2,128
    80005c60:	f6040593          	addi	a1,s0,-160
    80005c64:	4501                	li	a0,0
    80005c66:	ffffd097          	auipc	ra,0xffffd
    80005c6a:	240080e7          	jalr	576(ra) # 80002ea6 <argstr>
    80005c6e:	04054b63          	bltz	a0,80005cc4 <sys_chdir+0x86>
    80005c72:	f6040513          	addi	a0,s0,-160
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	592080e7          	jalr	1426(ra) # 80004208 <namei>
    80005c7e:	84aa                	mv	s1,a0
    80005c80:	c131                	beqz	a0,80005cc4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	dd0080e7          	jalr	-560(ra) # 80003a52 <ilock>
  if(ip->type != T_DIR){
    80005c8a:	04449703          	lh	a4,68(s1)
    80005c8e:	4785                	li	a5,1
    80005c90:	04f71063          	bne	a4,a5,80005cd0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c94:	8526                	mv	a0,s1
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	e7e080e7          	jalr	-386(ra) # 80003b14 <iunlock>
  iput(p->cwd);
    80005c9e:	15093503          	ld	a0,336(s2)
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	f6a080e7          	jalr	-150(ra) # 80003c0c <iput>
  end_op();
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	7fa080e7          	jalr	2042(ra) # 800044a4 <end_op>
  p->cwd = ip;
    80005cb2:	14993823          	sd	s1,336(s2)
  return 0;
    80005cb6:	4501                	li	a0,0
}
    80005cb8:	60ea                	ld	ra,152(sp)
    80005cba:	644a                	ld	s0,144(sp)
    80005cbc:	64aa                	ld	s1,136(sp)
    80005cbe:	690a                	ld	s2,128(sp)
    80005cc0:	610d                	addi	sp,sp,160
    80005cc2:	8082                	ret
    end_op();
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	7e0080e7          	jalr	2016(ra) # 800044a4 <end_op>
    return -1;
    80005ccc:	557d                	li	a0,-1
    80005cce:	b7ed                	j	80005cb8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cd0:	8526                	mv	a0,s1
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	fe2080e7          	jalr	-30(ra) # 80003cb4 <iunlockput>
    end_op();
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	7ca080e7          	jalr	1994(ra) # 800044a4 <end_op>
    return -1;
    80005ce2:	557d                	li	a0,-1
    80005ce4:	bfd1                	j	80005cb8 <sys_chdir+0x7a>

0000000080005ce6 <sys_exec>:

uint64
sys_exec(void)
{
    80005ce6:	7145                	addi	sp,sp,-464
    80005ce8:	e786                	sd	ra,456(sp)
    80005cea:	e3a2                	sd	s0,448(sp)
    80005cec:	ff26                	sd	s1,440(sp)
    80005cee:	fb4a                	sd	s2,432(sp)
    80005cf0:	f74e                	sd	s3,424(sp)
    80005cf2:	f352                	sd	s4,416(sp)
    80005cf4:	ef56                	sd	s5,408(sp)
    80005cf6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cf8:	08000613          	li	a2,128
    80005cfc:	f4040593          	addi	a1,s0,-192
    80005d00:	4501                	li	a0,0
    80005d02:	ffffd097          	auipc	ra,0xffffd
    80005d06:	1a4080e7          	jalr	420(ra) # 80002ea6 <argstr>
    return -1;
    80005d0a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d0c:	0c054a63          	bltz	a0,80005de0 <sys_exec+0xfa>
    80005d10:	e3840593          	addi	a1,s0,-456
    80005d14:	4505                	li	a0,1
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	16e080e7          	jalr	366(ra) # 80002e84 <argaddr>
    80005d1e:	0c054163          	bltz	a0,80005de0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d22:	10000613          	li	a2,256
    80005d26:	4581                	li	a1,0
    80005d28:	e4040513          	addi	a0,s0,-448
    80005d2c:	ffffb097          	auipc	ra,0xffffb
    80005d30:	fb4080e7          	jalr	-76(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d34:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d38:	89a6                	mv	s3,s1
    80005d3a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d3c:	02000a13          	li	s4,32
    80005d40:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d44:	00391513          	slli	a0,s2,0x3
    80005d48:	e3040593          	addi	a1,s0,-464
    80005d4c:	e3843783          	ld	a5,-456(s0)
    80005d50:	953e                	add	a0,a0,a5
    80005d52:	ffffd097          	auipc	ra,0xffffd
    80005d56:	076080e7          	jalr	118(ra) # 80002dc8 <fetchaddr>
    80005d5a:	02054a63          	bltz	a0,80005d8e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d5e:	e3043783          	ld	a5,-464(s0)
    80005d62:	c3b9                	beqz	a5,80005da8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d64:	ffffb097          	auipc	ra,0xffffb
    80005d68:	d90080e7          	jalr	-624(ra) # 80000af4 <kalloc>
    80005d6c:	85aa                	mv	a1,a0
    80005d6e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d72:	cd11                	beqz	a0,80005d8e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d74:	6605                	lui	a2,0x1
    80005d76:	e3043503          	ld	a0,-464(s0)
    80005d7a:	ffffd097          	auipc	ra,0xffffd
    80005d7e:	0a0080e7          	jalr	160(ra) # 80002e1a <fetchstr>
    80005d82:	00054663          	bltz	a0,80005d8e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d86:	0905                	addi	s2,s2,1
    80005d88:	09a1                	addi	s3,s3,8
    80005d8a:	fb491be3          	bne	s2,s4,80005d40 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8e:	10048913          	addi	s2,s1,256
    80005d92:	6088                	ld	a0,0(s1)
    80005d94:	c529                	beqz	a0,80005dde <sys_exec+0xf8>
    kfree(argv[i]);
    80005d96:	ffffb097          	auipc	ra,0xffffb
    80005d9a:	c62080e7          	jalr	-926(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d9e:	04a1                	addi	s1,s1,8
    80005da0:	ff2499e3          	bne	s1,s2,80005d92 <sys_exec+0xac>
  return -1;
    80005da4:	597d                	li	s2,-1
    80005da6:	a82d                	j	80005de0 <sys_exec+0xfa>
      argv[i] = 0;
    80005da8:	0a8e                	slli	s5,s5,0x3
    80005daa:	fc040793          	addi	a5,s0,-64
    80005dae:	9abe                	add	s5,s5,a5
    80005db0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005db4:	e4040593          	addi	a1,s0,-448
    80005db8:	f4040513          	addi	a0,s0,-192
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	194080e7          	jalr	404(ra) # 80004f50 <exec>
    80005dc4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc6:	10048993          	addi	s3,s1,256
    80005dca:	6088                	ld	a0,0(s1)
    80005dcc:	c911                	beqz	a0,80005de0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005dce:	ffffb097          	auipc	ra,0xffffb
    80005dd2:	c2a080e7          	jalr	-982(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dd6:	04a1                	addi	s1,s1,8
    80005dd8:	ff3499e3          	bne	s1,s3,80005dca <sys_exec+0xe4>
    80005ddc:	a011                	j	80005de0 <sys_exec+0xfa>
  return -1;
    80005dde:	597d                	li	s2,-1
}
    80005de0:	854a                	mv	a0,s2
    80005de2:	60be                	ld	ra,456(sp)
    80005de4:	641e                	ld	s0,448(sp)
    80005de6:	74fa                	ld	s1,440(sp)
    80005de8:	795a                	ld	s2,432(sp)
    80005dea:	79ba                	ld	s3,424(sp)
    80005dec:	7a1a                	ld	s4,416(sp)
    80005dee:	6afa                	ld	s5,408(sp)
    80005df0:	6179                	addi	sp,sp,464
    80005df2:	8082                	ret

0000000080005df4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005df4:	7139                	addi	sp,sp,-64
    80005df6:	fc06                	sd	ra,56(sp)
    80005df8:	f822                	sd	s0,48(sp)
    80005dfa:	f426                	sd	s1,40(sp)
    80005dfc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dfe:	ffffc097          	auipc	ra,0xffffc
    80005e02:	c4a080e7          	jalr	-950(ra) # 80001a48 <myproc>
    80005e06:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e08:	fd840593          	addi	a1,s0,-40
    80005e0c:	4501                	li	a0,0
    80005e0e:	ffffd097          	auipc	ra,0xffffd
    80005e12:	076080e7          	jalr	118(ra) # 80002e84 <argaddr>
    return -1;
    80005e16:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e18:	0e054063          	bltz	a0,80005ef8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e1c:	fc840593          	addi	a1,s0,-56
    80005e20:	fd040513          	addi	a0,s0,-48
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	dfc080e7          	jalr	-516(ra) # 80004c20 <pipealloc>
    return -1;
    80005e2c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e2e:	0c054563          	bltz	a0,80005ef8 <sys_pipe+0x104>
  fd0 = -1;
    80005e32:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e36:	fd043503          	ld	a0,-48(s0)
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	508080e7          	jalr	1288(ra) # 80005342 <fdalloc>
    80005e42:	fca42223          	sw	a0,-60(s0)
    80005e46:	08054c63          	bltz	a0,80005ede <sys_pipe+0xea>
    80005e4a:	fc843503          	ld	a0,-56(s0)
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	4f4080e7          	jalr	1268(ra) # 80005342 <fdalloc>
    80005e56:	fca42023          	sw	a0,-64(s0)
    80005e5a:	06054863          	bltz	a0,80005eca <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5e:	4691                	li	a3,4
    80005e60:	fc440613          	addi	a2,s0,-60
    80005e64:	fd843583          	ld	a1,-40(s0)
    80005e68:	68a8                	ld	a0,80(s1)
    80005e6a:	ffffc097          	auipc	ra,0xffffc
    80005e6e:	808080e7          	jalr	-2040(ra) # 80001672 <copyout>
    80005e72:	02054063          	bltz	a0,80005e92 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e76:	4691                	li	a3,4
    80005e78:	fc040613          	addi	a2,s0,-64
    80005e7c:	fd843583          	ld	a1,-40(s0)
    80005e80:	0591                	addi	a1,a1,4
    80005e82:	68a8                	ld	a0,80(s1)
    80005e84:	ffffb097          	auipc	ra,0xffffb
    80005e88:	7ee080e7          	jalr	2030(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e8c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e8e:	06055563          	bgez	a0,80005ef8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e92:	fc442783          	lw	a5,-60(s0)
    80005e96:	07e9                	addi	a5,a5,26
    80005e98:	078e                	slli	a5,a5,0x3
    80005e9a:	97a6                	add	a5,a5,s1
    80005e9c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ea0:	fc042503          	lw	a0,-64(s0)
    80005ea4:	0569                	addi	a0,a0,26
    80005ea6:	050e                	slli	a0,a0,0x3
    80005ea8:	9526                	add	a0,a0,s1
    80005eaa:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005eae:	fd043503          	ld	a0,-48(s0)
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	a3e080e7          	jalr	-1474(ra) # 800048f0 <fileclose>
    fileclose(wf);
    80005eba:	fc843503          	ld	a0,-56(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	a32080e7          	jalr	-1486(ra) # 800048f0 <fileclose>
    return -1;
    80005ec6:	57fd                	li	a5,-1
    80005ec8:	a805                	j	80005ef8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005eca:	fc442783          	lw	a5,-60(s0)
    80005ece:	0007c863          	bltz	a5,80005ede <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ed2:	01a78513          	addi	a0,a5,26
    80005ed6:	050e                	slli	a0,a0,0x3
    80005ed8:	9526                	add	a0,a0,s1
    80005eda:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ede:	fd043503          	ld	a0,-48(s0)
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	a0e080e7          	jalr	-1522(ra) # 800048f0 <fileclose>
    fileclose(wf);
    80005eea:	fc843503          	ld	a0,-56(s0)
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	a02080e7          	jalr	-1534(ra) # 800048f0 <fileclose>
    return -1;
    80005ef6:	57fd                	li	a5,-1
}
    80005ef8:	853e                	mv	a0,a5
    80005efa:	70e2                	ld	ra,56(sp)
    80005efc:	7442                	ld	s0,48(sp)
    80005efe:	74a2                	ld	s1,40(sp)
    80005f00:	6121                	addi	sp,sp,64
    80005f02:	8082                	ret
	...

0000000080005f10 <kernelvec>:
    80005f10:	7111                	addi	sp,sp,-256
    80005f12:	e006                	sd	ra,0(sp)
    80005f14:	e40a                	sd	sp,8(sp)
    80005f16:	e80e                	sd	gp,16(sp)
    80005f18:	ec12                	sd	tp,24(sp)
    80005f1a:	f016                	sd	t0,32(sp)
    80005f1c:	f41a                	sd	t1,40(sp)
    80005f1e:	f81e                	sd	t2,48(sp)
    80005f20:	fc22                	sd	s0,56(sp)
    80005f22:	e0a6                	sd	s1,64(sp)
    80005f24:	e4aa                	sd	a0,72(sp)
    80005f26:	e8ae                	sd	a1,80(sp)
    80005f28:	ecb2                	sd	a2,88(sp)
    80005f2a:	f0b6                	sd	a3,96(sp)
    80005f2c:	f4ba                	sd	a4,104(sp)
    80005f2e:	f8be                	sd	a5,112(sp)
    80005f30:	fcc2                	sd	a6,120(sp)
    80005f32:	e146                	sd	a7,128(sp)
    80005f34:	e54a                	sd	s2,136(sp)
    80005f36:	e94e                	sd	s3,144(sp)
    80005f38:	ed52                	sd	s4,152(sp)
    80005f3a:	f156                	sd	s5,160(sp)
    80005f3c:	f55a                	sd	s6,168(sp)
    80005f3e:	f95e                	sd	s7,176(sp)
    80005f40:	fd62                	sd	s8,184(sp)
    80005f42:	e1e6                	sd	s9,192(sp)
    80005f44:	e5ea                	sd	s10,200(sp)
    80005f46:	e9ee                	sd	s11,208(sp)
    80005f48:	edf2                	sd	t3,216(sp)
    80005f4a:	f1f6                	sd	t4,224(sp)
    80005f4c:	f5fa                	sd	t5,232(sp)
    80005f4e:	f9fe                	sd	t6,240(sp)
    80005f50:	d45fc0ef          	jal	ra,80002c94 <kerneltrap>
    80005f54:	6082                	ld	ra,0(sp)
    80005f56:	6122                	ld	sp,8(sp)
    80005f58:	61c2                	ld	gp,16(sp)
    80005f5a:	7282                	ld	t0,32(sp)
    80005f5c:	7322                	ld	t1,40(sp)
    80005f5e:	73c2                	ld	t2,48(sp)
    80005f60:	7462                	ld	s0,56(sp)
    80005f62:	6486                	ld	s1,64(sp)
    80005f64:	6526                	ld	a0,72(sp)
    80005f66:	65c6                	ld	a1,80(sp)
    80005f68:	6666                	ld	a2,88(sp)
    80005f6a:	7686                	ld	a3,96(sp)
    80005f6c:	7726                	ld	a4,104(sp)
    80005f6e:	77c6                	ld	a5,112(sp)
    80005f70:	7866                	ld	a6,120(sp)
    80005f72:	688a                	ld	a7,128(sp)
    80005f74:	692a                	ld	s2,136(sp)
    80005f76:	69ca                	ld	s3,144(sp)
    80005f78:	6a6a                	ld	s4,152(sp)
    80005f7a:	7a8a                	ld	s5,160(sp)
    80005f7c:	7b2a                	ld	s6,168(sp)
    80005f7e:	7bca                	ld	s7,176(sp)
    80005f80:	7c6a                	ld	s8,184(sp)
    80005f82:	6c8e                	ld	s9,192(sp)
    80005f84:	6d2e                	ld	s10,200(sp)
    80005f86:	6dce                	ld	s11,208(sp)
    80005f88:	6e6e                	ld	t3,216(sp)
    80005f8a:	7e8e                	ld	t4,224(sp)
    80005f8c:	7f2e                	ld	t5,232(sp)
    80005f8e:	7fce                	ld	t6,240(sp)
    80005f90:	6111                	addi	sp,sp,256
    80005f92:	10200073          	sret
    80005f96:	00000013          	nop
    80005f9a:	00000013          	nop
    80005f9e:	0001                	nop

0000000080005fa0 <timervec>:
    80005fa0:	34051573          	csrrw	a0,mscratch,a0
    80005fa4:	e10c                	sd	a1,0(a0)
    80005fa6:	e510                	sd	a2,8(a0)
    80005fa8:	e914                	sd	a3,16(a0)
    80005faa:	6d0c                	ld	a1,24(a0)
    80005fac:	7110                	ld	a2,32(a0)
    80005fae:	6194                	ld	a3,0(a1)
    80005fb0:	96b2                	add	a3,a3,a2
    80005fb2:	e194                	sd	a3,0(a1)
    80005fb4:	4589                	li	a1,2
    80005fb6:	14459073          	csrw	sip,a1
    80005fba:	6914                	ld	a3,16(a0)
    80005fbc:	6510                	ld	a2,8(a0)
    80005fbe:	610c                	ld	a1,0(a0)
    80005fc0:	34051573          	csrrw	a0,mscratch,a0
    80005fc4:	30200073          	mret
	...

0000000080005fca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fca:	1141                	addi	sp,sp,-16
    80005fcc:	e422                	sd	s0,8(sp)
    80005fce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fd0:	0c0007b7          	lui	a5,0xc000
    80005fd4:	4705                	li	a4,1
    80005fd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fd8:	c3d8                	sw	a4,4(a5)
}
    80005fda:	6422                	ld	s0,8(sp)
    80005fdc:	0141                	addi	sp,sp,16
    80005fde:	8082                	ret

0000000080005fe0 <plicinithart>:

void
plicinithart(void)
{
    80005fe0:	1141                	addi	sp,sp,-16
    80005fe2:	e406                	sd	ra,8(sp)
    80005fe4:	e022                	sd	s0,0(sp)
    80005fe6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	a34080e7          	jalr	-1484(ra) # 80001a1c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ff0:	0085171b          	slliw	a4,a0,0x8
    80005ff4:	0c0027b7          	lui	a5,0xc002
    80005ff8:	97ba                	add	a5,a5,a4
    80005ffa:	40200713          	li	a4,1026
    80005ffe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006002:	00d5151b          	slliw	a0,a0,0xd
    80006006:	0c2017b7          	lui	a5,0xc201
    8000600a:	953e                	add	a0,a0,a5
    8000600c:	00052023          	sw	zero,0(a0)
}
    80006010:	60a2                	ld	ra,8(sp)
    80006012:	6402                	ld	s0,0(sp)
    80006014:	0141                	addi	sp,sp,16
    80006016:	8082                	ret

0000000080006018 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006018:	1141                	addi	sp,sp,-16
    8000601a:	e406                	sd	ra,8(sp)
    8000601c:	e022                	sd	s0,0(sp)
    8000601e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006020:	ffffc097          	auipc	ra,0xffffc
    80006024:	9fc080e7          	jalr	-1540(ra) # 80001a1c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006028:	00d5179b          	slliw	a5,a0,0xd
    8000602c:	0c201537          	lui	a0,0xc201
    80006030:	953e                	add	a0,a0,a5
  return irq;
}
    80006032:	4148                	lw	a0,4(a0)
    80006034:	60a2                	ld	ra,8(sp)
    80006036:	6402                	ld	s0,0(sp)
    80006038:	0141                	addi	sp,sp,16
    8000603a:	8082                	ret

000000008000603c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000603c:	1101                	addi	sp,sp,-32
    8000603e:	ec06                	sd	ra,24(sp)
    80006040:	e822                	sd	s0,16(sp)
    80006042:	e426                	sd	s1,8(sp)
    80006044:	1000                	addi	s0,sp,32
    80006046:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	9d4080e7          	jalr	-1580(ra) # 80001a1c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006050:	00d5151b          	slliw	a0,a0,0xd
    80006054:	0c2017b7          	lui	a5,0xc201
    80006058:	97aa                	add	a5,a5,a0
    8000605a:	c3c4                	sw	s1,4(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6105                	addi	sp,sp,32
    80006064:	8082                	ret

0000000080006066 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006066:	1141                	addi	sp,sp,-16
    80006068:	e406                	sd	ra,8(sp)
    8000606a:	e022                	sd	s0,0(sp)
    8000606c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000606e:	479d                	li	a5,7
    80006070:	06a7c963          	blt	a5,a0,800060e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006074:	00016797          	auipc	a5,0x16
    80006078:	f8c78793          	addi	a5,a5,-116 # 8001c000 <disk>
    8000607c:	00a78733          	add	a4,a5,a0
    80006080:	6789                	lui	a5,0x2
    80006082:	97ba                	add	a5,a5,a4
    80006084:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006088:	e7ad                	bnez	a5,800060f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000608a:	00451793          	slli	a5,a0,0x4
    8000608e:	00018717          	auipc	a4,0x18
    80006092:	f7270713          	addi	a4,a4,-142 # 8001e000 <disk+0x2000>
    80006096:	6314                	ld	a3,0(a4)
    80006098:	96be                	add	a3,a3,a5
    8000609a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000609e:	6314                	ld	a3,0(a4)
    800060a0:	96be                	add	a3,a3,a5
    800060a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800060a6:	6314                	ld	a3,0(a4)
    800060a8:	96be                	add	a3,a3,a5
    800060aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800060ae:	6318                	ld	a4,0(a4)
    800060b0:	97ba                	add	a5,a5,a4
    800060b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800060b6:	00016797          	auipc	a5,0x16
    800060ba:	f4a78793          	addi	a5,a5,-182 # 8001c000 <disk>
    800060be:	97aa                	add	a5,a5,a0
    800060c0:	6509                	lui	a0,0x2
    800060c2:	953e                	add	a0,a0,a5
    800060c4:	4785                	li	a5,1
    800060c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060ca:	00018517          	auipc	a0,0x18
    800060ce:	f4e50513          	addi	a0,a0,-178 # 8001e018 <disk+0x2018>
    800060d2:	ffffc097          	auipc	ra,0xffffc
    800060d6:	31c080e7          	jalr	796(ra) # 800023ee <wakeup>
}
    800060da:	60a2                	ld	ra,8(sp)
    800060dc:	6402                	ld	s0,0(sp)
    800060de:	0141                	addi	sp,sp,16
    800060e0:	8082                	ret
    panic("free_desc 1");
    800060e2:	00002517          	auipc	a0,0x2
    800060e6:	71e50513          	addi	a0,a0,1822 # 80008800 <syscalls+0x340>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	454080e7          	jalr	1108(ra) # 8000053e <panic>
    panic("free_desc 2");
    800060f2:	00002517          	auipc	a0,0x2
    800060f6:	71e50513          	addi	a0,a0,1822 # 80008810 <syscalls+0x350>
    800060fa:	ffffa097          	auipc	ra,0xffffa
    800060fe:	444080e7          	jalr	1092(ra) # 8000053e <panic>

0000000080006102 <virtio_disk_init>:
{
    80006102:	1101                	addi	sp,sp,-32
    80006104:	ec06                	sd	ra,24(sp)
    80006106:	e822                	sd	s0,16(sp)
    80006108:	e426                	sd	s1,8(sp)
    8000610a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000610c:	00002597          	auipc	a1,0x2
    80006110:	71458593          	addi	a1,a1,1812 # 80008820 <syscalls+0x360>
    80006114:	00018517          	auipc	a0,0x18
    80006118:	01450513          	addi	a0,a0,20 # 8001e128 <disk+0x2128>
    8000611c:	ffffb097          	auipc	ra,0xffffb
    80006120:	a38080e7          	jalr	-1480(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006124:	100017b7          	lui	a5,0x10001
    80006128:	4398                	lw	a4,0(a5)
    8000612a:	2701                	sext.w	a4,a4
    8000612c:	747277b7          	lui	a5,0x74727
    80006130:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006134:	0ef71163          	bne	a4,a5,80006216 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006138:	100017b7          	lui	a5,0x10001
    8000613c:	43dc                	lw	a5,4(a5)
    8000613e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006140:	4705                	li	a4,1
    80006142:	0ce79a63          	bne	a5,a4,80006216 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006146:	100017b7          	lui	a5,0x10001
    8000614a:	479c                	lw	a5,8(a5)
    8000614c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000614e:	4709                	li	a4,2
    80006150:	0ce79363          	bne	a5,a4,80006216 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006154:	100017b7          	lui	a5,0x10001
    80006158:	47d8                	lw	a4,12(a5)
    8000615a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000615c:	554d47b7          	lui	a5,0x554d4
    80006160:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006164:	0af71963          	bne	a4,a5,80006216 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006168:	100017b7          	lui	a5,0x10001
    8000616c:	4705                	li	a4,1
    8000616e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006170:	470d                	li	a4,3
    80006172:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006174:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006176:	c7ffe737          	lui	a4,0xc7ffe
    8000617a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    8000617e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006180:	2701                	sext.w	a4,a4
    80006182:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006184:	472d                	li	a4,11
    80006186:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006188:	473d                	li	a4,15
    8000618a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000618c:	6705                	lui	a4,0x1
    8000618e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006190:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006194:	5bdc                	lw	a5,52(a5)
    80006196:	2781                	sext.w	a5,a5
  if(max == 0)
    80006198:	c7d9                	beqz	a5,80006226 <virtio_disk_init+0x124>
  if(max < NUM)
    8000619a:	471d                	li	a4,7
    8000619c:	08f77d63          	bgeu	a4,a5,80006236 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061a0:	100014b7          	lui	s1,0x10001
    800061a4:	47a1                	li	a5,8
    800061a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800061a8:	6609                	lui	a2,0x2
    800061aa:	4581                	li	a1,0
    800061ac:	00016517          	auipc	a0,0x16
    800061b0:	e5450513          	addi	a0,a0,-428 # 8001c000 <disk>
    800061b4:	ffffb097          	auipc	ra,0xffffb
    800061b8:	b2c080e7          	jalr	-1236(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800061bc:	00016717          	auipc	a4,0x16
    800061c0:	e4470713          	addi	a4,a4,-444 # 8001c000 <disk>
    800061c4:	00c75793          	srli	a5,a4,0xc
    800061c8:	2781                	sext.w	a5,a5
    800061ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800061cc:	00018797          	auipc	a5,0x18
    800061d0:	e3478793          	addi	a5,a5,-460 # 8001e000 <disk+0x2000>
    800061d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800061d6:	00016717          	auipc	a4,0x16
    800061da:	eaa70713          	addi	a4,a4,-342 # 8001c080 <disk+0x80>
    800061de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800061e0:	00017717          	auipc	a4,0x17
    800061e4:	e2070713          	addi	a4,a4,-480 # 8001d000 <disk+0x1000>
    800061e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061ea:	4705                	li	a4,1
    800061ec:	00e78c23          	sb	a4,24(a5)
    800061f0:	00e78ca3          	sb	a4,25(a5)
    800061f4:	00e78d23          	sb	a4,26(a5)
    800061f8:	00e78da3          	sb	a4,27(a5)
    800061fc:	00e78e23          	sb	a4,28(a5)
    80006200:	00e78ea3          	sb	a4,29(a5)
    80006204:	00e78f23          	sb	a4,30(a5)
    80006208:	00e78fa3          	sb	a4,31(a5)
}
    8000620c:	60e2                	ld	ra,24(sp)
    8000620e:	6442                	ld	s0,16(sp)
    80006210:	64a2                	ld	s1,8(sp)
    80006212:	6105                	addi	sp,sp,32
    80006214:	8082                	ret
    panic("could not find virtio disk");
    80006216:	00002517          	auipc	a0,0x2
    8000621a:	61a50513          	addi	a0,a0,1562 # 80008830 <syscalls+0x370>
    8000621e:	ffffa097          	auipc	ra,0xffffa
    80006222:	320080e7          	jalr	800(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006226:	00002517          	auipc	a0,0x2
    8000622a:	62a50513          	addi	a0,a0,1578 # 80008850 <syscalls+0x390>
    8000622e:	ffffa097          	auipc	ra,0xffffa
    80006232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006236:	00002517          	auipc	a0,0x2
    8000623a:	63a50513          	addi	a0,a0,1594 # 80008870 <syscalls+0x3b0>
    8000623e:	ffffa097          	auipc	ra,0xffffa
    80006242:	300080e7          	jalr	768(ra) # 8000053e <panic>

0000000080006246 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006246:	7159                	addi	sp,sp,-112
    80006248:	f486                	sd	ra,104(sp)
    8000624a:	f0a2                	sd	s0,96(sp)
    8000624c:	eca6                	sd	s1,88(sp)
    8000624e:	e8ca                	sd	s2,80(sp)
    80006250:	e4ce                	sd	s3,72(sp)
    80006252:	e0d2                	sd	s4,64(sp)
    80006254:	fc56                	sd	s5,56(sp)
    80006256:	f85a                	sd	s6,48(sp)
    80006258:	f45e                	sd	s7,40(sp)
    8000625a:	f062                	sd	s8,32(sp)
    8000625c:	ec66                	sd	s9,24(sp)
    8000625e:	e86a                	sd	s10,16(sp)
    80006260:	1880                	addi	s0,sp,112
    80006262:	892a                	mv	s2,a0
    80006264:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006266:	00c52c83          	lw	s9,12(a0)
    8000626a:	001c9c9b          	slliw	s9,s9,0x1
    8000626e:	1c82                	slli	s9,s9,0x20
    80006270:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006274:	00018517          	auipc	a0,0x18
    80006278:	eb450513          	addi	a0,a0,-332 # 8001e128 <disk+0x2128>
    8000627c:	ffffb097          	auipc	ra,0xffffb
    80006280:	968080e7          	jalr	-1688(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006284:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006286:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006288:	00016b97          	auipc	s7,0x16
    8000628c:	d78b8b93          	addi	s7,s7,-648 # 8001c000 <disk>
    80006290:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006292:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006294:	8a4e                	mv	s4,s3
    80006296:	a051                	j	8000631a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006298:	00fb86b3          	add	a3,s7,a5
    8000629c:	96da                	add	a3,a3,s6
    8000629e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800062a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800062a4:	0207c563          	bltz	a5,800062ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800062a8:	2485                	addiw	s1,s1,1
    800062aa:	0711                	addi	a4,a4,4
    800062ac:	25548063          	beq	s1,s5,800064ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800062b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800062b2:	00018697          	auipc	a3,0x18
    800062b6:	d6668693          	addi	a3,a3,-666 # 8001e018 <disk+0x2018>
    800062ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800062bc:	0006c583          	lbu	a1,0(a3)
    800062c0:	fde1                	bnez	a1,80006298 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800062c2:	2785                	addiw	a5,a5,1
    800062c4:	0685                	addi	a3,a3,1
    800062c6:	ff879be3          	bne	a5,s8,800062bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800062ca:	57fd                	li	a5,-1
    800062cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800062ce:	02905a63          	blez	s1,80006302 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062d2:	f9042503          	lw	a0,-112(s0)
    800062d6:	00000097          	auipc	ra,0x0
    800062da:	d90080e7          	jalr	-624(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    800062de:	4785                	li	a5,1
    800062e0:	0297d163          	bge	a5,s1,80006302 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062e4:	f9442503          	lw	a0,-108(s0)
    800062e8:	00000097          	auipc	ra,0x0
    800062ec:	d7e080e7          	jalr	-642(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    800062f0:	4789                	li	a5,2
    800062f2:	0097d863          	bge	a5,s1,80006302 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062f6:	f9842503          	lw	a0,-104(s0)
    800062fa:	00000097          	auipc	ra,0x0
    800062fe:	d6c080e7          	jalr	-660(ra) # 80006066 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006302:	00018597          	auipc	a1,0x18
    80006306:	e2658593          	addi	a1,a1,-474 # 8001e128 <disk+0x2128>
    8000630a:	00018517          	auipc	a0,0x18
    8000630e:	d0e50513          	addi	a0,a0,-754 # 8001e018 <disk+0x2018>
    80006312:	ffffc097          	auipc	ra,0xffffc
    80006316:	f50080e7          	jalr	-176(ra) # 80002262 <sleep>
  for(int i = 0; i < 3; i++){
    8000631a:	f9040713          	addi	a4,s0,-112
    8000631e:	84ce                	mv	s1,s3
    80006320:	bf41                	j	800062b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006322:	20058713          	addi	a4,a1,512
    80006326:	00471693          	slli	a3,a4,0x4
    8000632a:	00016717          	auipc	a4,0x16
    8000632e:	cd670713          	addi	a4,a4,-810 # 8001c000 <disk>
    80006332:	9736                	add	a4,a4,a3
    80006334:	4685                	li	a3,1
    80006336:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000633a:	20058713          	addi	a4,a1,512
    8000633e:	00471693          	slli	a3,a4,0x4
    80006342:	00016717          	auipc	a4,0x16
    80006346:	cbe70713          	addi	a4,a4,-834 # 8001c000 <disk>
    8000634a:	9736                	add	a4,a4,a3
    8000634c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006350:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006354:	7679                	lui	a2,0xffffe
    80006356:	963e                	add	a2,a2,a5
    80006358:	00018697          	auipc	a3,0x18
    8000635c:	ca868693          	addi	a3,a3,-856 # 8001e000 <disk+0x2000>
    80006360:	6298                	ld	a4,0(a3)
    80006362:	9732                	add	a4,a4,a2
    80006364:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006366:	6298                	ld	a4,0(a3)
    80006368:	9732                	add	a4,a4,a2
    8000636a:	4541                	li	a0,16
    8000636c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000636e:	6298                	ld	a4,0(a3)
    80006370:	9732                	add	a4,a4,a2
    80006372:	4505                	li	a0,1
    80006374:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006378:	f9442703          	lw	a4,-108(s0)
    8000637c:	6288                	ld	a0,0(a3)
    8000637e:	962a                	add	a2,a2,a0
    80006380:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006384:	0712                	slli	a4,a4,0x4
    80006386:	6290                	ld	a2,0(a3)
    80006388:	963a                	add	a2,a2,a4
    8000638a:	05890513          	addi	a0,s2,88
    8000638e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006390:	6294                	ld	a3,0(a3)
    80006392:	96ba                	add	a3,a3,a4
    80006394:	40000613          	li	a2,1024
    80006398:	c690                	sw	a2,8(a3)
  if(write)
    8000639a:	140d0063          	beqz	s10,800064da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000639e:	00018697          	auipc	a3,0x18
    800063a2:	c626b683          	ld	a3,-926(a3) # 8001e000 <disk+0x2000>
    800063a6:	96ba                	add	a3,a3,a4
    800063a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063ac:	00016817          	auipc	a6,0x16
    800063b0:	c5480813          	addi	a6,a6,-940 # 8001c000 <disk>
    800063b4:	00018517          	auipc	a0,0x18
    800063b8:	c4c50513          	addi	a0,a0,-948 # 8001e000 <disk+0x2000>
    800063bc:	6114                	ld	a3,0(a0)
    800063be:	96ba                	add	a3,a3,a4
    800063c0:	00c6d603          	lhu	a2,12(a3)
    800063c4:	00166613          	ori	a2,a2,1
    800063c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063cc:	f9842683          	lw	a3,-104(s0)
    800063d0:	6110                	ld	a2,0(a0)
    800063d2:	9732                	add	a4,a4,a2
    800063d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063d8:	20058613          	addi	a2,a1,512
    800063dc:	0612                	slli	a2,a2,0x4
    800063de:	9642                	add	a2,a2,a6
    800063e0:	577d                	li	a4,-1
    800063e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063e6:	00469713          	slli	a4,a3,0x4
    800063ea:	6114                	ld	a3,0(a0)
    800063ec:	96ba                	add	a3,a3,a4
    800063ee:	03078793          	addi	a5,a5,48
    800063f2:	97c2                	add	a5,a5,a6
    800063f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800063f6:	611c                	ld	a5,0(a0)
    800063f8:	97ba                	add	a5,a5,a4
    800063fa:	4685                	li	a3,1
    800063fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063fe:	611c                	ld	a5,0(a0)
    80006400:	97ba                	add	a5,a5,a4
    80006402:	4809                	li	a6,2
    80006404:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006408:	611c                	ld	a5,0(a0)
    8000640a:	973e                	add	a4,a4,a5
    8000640c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006410:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006414:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006418:	6518                	ld	a4,8(a0)
    8000641a:	00275783          	lhu	a5,2(a4)
    8000641e:	8b9d                	andi	a5,a5,7
    80006420:	0786                	slli	a5,a5,0x1
    80006422:	97ba                	add	a5,a5,a4
    80006424:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006428:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000642c:	6518                	ld	a4,8(a0)
    8000642e:	00275783          	lhu	a5,2(a4)
    80006432:	2785                	addiw	a5,a5,1
    80006434:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006438:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006444:	00492703          	lw	a4,4(s2)
    80006448:	4785                	li	a5,1
    8000644a:	02f71163          	bne	a4,a5,8000646c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000644e:	00018997          	auipc	s3,0x18
    80006452:	cda98993          	addi	s3,s3,-806 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    80006456:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006458:	85ce                	mv	a1,s3
    8000645a:	854a                	mv	a0,s2
    8000645c:	ffffc097          	auipc	ra,0xffffc
    80006460:	e06080e7          	jalr	-506(ra) # 80002262 <sleep>
  while(b->disk == 1) {
    80006464:	00492783          	lw	a5,4(s2)
    80006468:	fe9788e3          	beq	a5,s1,80006458 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000646c:	f9042903          	lw	s2,-112(s0)
    80006470:	20090793          	addi	a5,s2,512
    80006474:	00479713          	slli	a4,a5,0x4
    80006478:	00016797          	auipc	a5,0x16
    8000647c:	b8878793          	addi	a5,a5,-1144 # 8001c000 <disk>
    80006480:	97ba                	add	a5,a5,a4
    80006482:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006486:	00018997          	auipc	s3,0x18
    8000648a:	b7a98993          	addi	s3,s3,-1158 # 8001e000 <disk+0x2000>
    8000648e:	00491713          	slli	a4,s2,0x4
    80006492:	0009b783          	ld	a5,0(s3)
    80006496:	97ba                	add	a5,a5,a4
    80006498:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000649c:	854a                	mv	a0,s2
    8000649e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064a2:	00000097          	auipc	ra,0x0
    800064a6:	bc4080e7          	jalr	-1084(ra) # 80006066 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064aa:	8885                	andi	s1,s1,1
    800064ac:	f0ed                	bnez	s1,8000648e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064ae:	00018517          	auipc	a0,0x18
    800064b2:	c7a50513          	addi	a0,a0,-902 # 8001e128 <disk+0x2128>
    800064b6:	ffffa097          	auipc	ra,0xffffa
    800064ba:	7e2080e7          	jalr	2018(ra) # 80000c98 <release>
}
    800064be:	70a6                	ld	ra,104(sp)
    800064c0:	7406                	ld	s0,96(sp)
    800064c2:	64e6                	ld	s1,88(sp)
    800064c4:	6946                	ld	s2,80(sp)
    800064c6:	69a6                	ld	s3,72(sp)
    800064c8:	6a06                	ld	s4,64(sp)
    800064ca:	7ae2                	ld	s5,56(sp)
    800064cc:	7b42                	ld	s6,48(sp)
    800064ce:	7ba2                	ld	s7,40(sp)
    800064d0:	7c02                	ld	s8,32(sp)
    800064d2:	6ce2                	ld	s9,24(sp)
    800064d4:	6d42                	ld	s10,16(sp)
    800064d6:	6165                	addi	sp,sp,112
    800064d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064da:	00018697          	auipc	a3,0x18
    800064de:	b266b683          	ld	a3,-1242(a3) # 8001e000 <disk+0x2000>
    800064e2:	96ba                	add	a3,a3,a4
    800064e4:	4609                	li	a2,2
    800064e6:	00c69623          	sh	a2,12(a3)
    800064ea:	b5c9                	j	800063ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064ec:	f9042583          	lw	a1,-112(s0)
    800064f0:	20058793          	addi	a5,a1,512
    800064f4:	0792                	slli	a5,a5,0x4
    800064f6:	00016517          	auipc	a0,0x16
    800064fa:	bb250513          	addi	a0,a0,-1102 # 8001c0a8 <disk+0xa8>
    800064fe:	953e                	add	a0,a0,a5
  if(write)
    80006500:	e20d11e3          	bnez	s10,80006322 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006504:	20058713          	addi	a4,a1,512
    80006508:	00471693          	slli	a3,a4,0x4
    8000650c:	00016717          	auipc	a4,0x16
    80006510:	af470713          	addi	a4,a4,-1292 # 8001c000 <disk>
    80006514:	9736                	add	a4,a4,a3
    80006516:	0a072423          	sw	zero,168(a4)
    8000651a:	b505                	j	8000633a <virtio_disk_rw+0xf4>

000000008000651c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000651c:	1101                	addi	sp,sp,-32
    8000651e:	ec06                	sd	ra,24(sp)
    80006520:	e822                	sd	s0,16(sp)
    80006522:	e426                	sd	s1,8(sp)
    80006524:	e04a                	sd	s2,0(sp)
    80006526:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006528:	00018517          	auipc	a0,0x18
    8000652c:	c0050513          	addi	a0,a0,-1024 # 8001e128 <disk+0x2128>
    80006530:	ffffa097          	auipc	ra,0xffffa
    80006534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006538:	10001737          	lui	a4,0x10001
    8000653c:	533c                	lw	a5,96(a4)
    8000653e:	8b8d                	andi	a5,a5,3
    80006540:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006542:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006546:	00018797          	auipc	a5,0x18
    8000654a:	aba78793          	addi	a5,a5,-1350 # 8001e000 <disk+0x2000>
    8000654e:	6b94                	ld	a3,16(a5)
    80006550:	0207d703          	lhu	a4,32(a5)
    80006554:	0026d783          	lhu	a5,2(a3)
    80006558:	06f70163          	beq	a4,a5,800065ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000655c:	00016917          	auipc	s2,0x16
    80006560:	aa490913          	addi	s2,s2,-1372 # 8001c000 <disk>
    80006564:	00018497          	auipc	s1,0x18
    80006568:	a9c48493          	addi	s1,s1,-1380 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    8000656c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006570:	6898                	ld	a4,16(s1)
    80006572:	0204d783          	lhu	a5,32(s1)
    80006576:	8b9d                	andi	a5,a5,7
    80006578:	078e                	slli	a5,a5,0x3
    8000657a:	97ba                	add	a5,a5,a4
    8000657c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000657e:	20078713          	addi	a4,a5,512
    80006582:	0712                	slli	a4,a4,0x4
    80006584:	974a                	add	a4,a4,s2
    80006586:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000658a:	e731                	bnez	a4,800065d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000658c:	20078793          	addi	a5,a5,512
    80006590:	0792                	slli	a5,a5,0x4
    80006592:	97ca                	add	a5,a5,s2
    80006594:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006596:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000659a:	ffffc097          	auipc	ra,0xffffc
    8000659e:	e54080e7          	jalr	-428(ra) # 800023ee <wakeup>

    disk.used_idx += 1;
    800065a2:	0204d783          	lhu	a5,32(s1)
    800065a6:	2785                	addiw	a5,a5,1
    800065a8:	17c2                	slli	a5,a5,0x30
    800065aa:	93c1                	srli	a5,a5,0x30
    800065ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065b0:	6898                	ld	a4,16(s1)
    800065b2:	00275703          	lhu	a4,2(a4)
    800065b6:	faf71be3          	bne	a4,a5,8000656c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800065ba:	00018517          	auipc	a0,0x18
    800065be:	b6e50513          	addi	a0,a0,-1170 # 8001e128 <disk+0x2128>
    800065c2:	ffffa097          	auipc	ra,0xffffa
    800065c6:	6d6080e7          	jalr	1750(ra) # 80000c98 <release>
}
    800065ca:	60e2                	ld	ra,24(sp)
    800065cc:	6442                	ld	s0,16(sp)
    800065ce:	64a2                	ld	s1,8(sp)
    800065d0:	6902                	ld	s2,0(sp)
    800065d2:	6105                	addi	sp,sp,32
    800065d4:	8082                	ret
      panic("virtio_disk_intr status");
    800065d6:	00002517          	auipc	a0,0x2
    800065da:	2ba50513          	addi	a0,a0,698 # 80008890 <syscalls+0x3d0>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
