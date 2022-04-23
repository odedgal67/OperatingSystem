
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	d2c78793          	addi	a5,a5,-724 # 80005d90 <timervec>
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
    80000130:	448080e7          	jalr	1096(ra) # 80002574 <either_copyin>
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
    80000190:	ee450513          	addi	a0,a0,-284 # 8000a070 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ed448493          	addi	s1,s1,-300 # 8000a070 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f6290913          	addi	s2,s2,-158 # 8000a108 <cons+0x98>
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
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f86080e7          	jalr	-122(ra) # 8000215a <sleep>
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
    80000214:	30e080e7          	jalr	782(ra) # 8000251e <either_copyout>
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
    80000228:	e4c50513          	addi	a0,a0,-436 # 8000a070 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e3650513          	addi	a0,a0,-458 # 8000a070 <cons>
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
    80000276:	e8f72b23          	sw	a5,-362(a4) # 8000a108 <cons+0x98>
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
    800002d0:	da450513          	addi	a0,a0,-604 # 8000a070 <cons>
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
    800002f6:	2d8080e7          	jalr	728(ra) # 800025ca <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d7650513          	addi	a0,a0,-650 # 8000a070 <cons>
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
    80000322:	d5270713          	addi	a4,a4,-686 # 8000a070 <cons>
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
    8000034c:	d2878793          	addi	a5,a5,-728 # 8000a070 <cons>
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
    8000037a:	d927a783          	lw	a5,-622(a5) # 8000a108 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	ce670713          	addi	a4,a4,-794 # 8000a070 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	cd648493          	addi	s1,s1,-810 # 8000a070 <cons>
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
    800003da:	c9a70713          	addi	a4,a4,-870 # 8000a070 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d2f72223          	sw	a5,-732(a4) # 8000a110 <cons+0xa0>
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
    80000416:	c5e78793          	addi	a5,a5,-930 # 8000a070 <cons>
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
    8000043a:	ccc7ab23          	sw	a2,-810(a5) # 8000a10c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cca50513          	addi	a0,a0,-822 # 8000a108 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	ea0080e7          	jalr	-352(ra) # 800022e6 <wakeup>
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
    80000464:	c1050513          	addi	a0,a0,-1008 # 8000a070 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	e1078793          	addi	a5,a5,-496 # 8001a288 <devsw>
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
    8000054e:	be07a323          	sw	zero,-1050(a5) # 8000a130 <pr+0x18>
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
    800005be:	b76dad83          	lw	s11,-1162(s11) # 8000a130 <pr+0x18>
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
    800005fc:	b2050513          	addi	a0,a0,-1248 # 8000a118 <pr>
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
    80000760:	9bc50513          	addi	a0,a0,-1604 # 8000a118 <pr>
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
    8000077c:	9a048493          	addi	s1,s1,-1632 # 8000a118 <pr>
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
    800007dc:	96050513          	addi	a0,a0,-1696 # 8000a138 <uart_tx_lock>
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
    8000086e:	8cea0a13          	addi	s4,s4,-1842 # 8000a138 <uart_tx_lock>
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
    800008a4:	a46080e7          	jalr	-1466(ra) # 800022e6 <wakeup>
    
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
    800008e0:	85c50513          	addi	a0,a0,-1956 # 8000a138 <uart_tx_lock>
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
    80000914:	828a0a13          	addi	s4,s4,-2008 # 8000a138 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	82e080e7          	jalr	-2002(ra) # 8000215a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00009497          	auipc	s1,0x9
    80000946:	7f648493          	addi	s1,s1,2038 # 8000a138 <uart_tx_lock>
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
    800009ce:	76e48493          	addi	s1,s1,1902 # 8000a138 <uart_tx_lock>
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
    80000a30:	74490913          	addi	s2,s2,1860 # 8000a170 <kmem>
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
    80000acc:	6a850513          	addi	a0,a0,1704 # 8000a170 <kmem>
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
    80000b02:	67248493          	addi	s1,s1,1650 # 8000a170 <kmem>
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
    80000b1a:	65a50513          	addi	a0,a0,1626 # 8000a170 <kmem>
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
    80000b46:	62e50513          	addi	a0,a0,1582 # 8000a170 <kmem>
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
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
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
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
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
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
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
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
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
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
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
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
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
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
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
    80000ed8:	93e080e7          	jalr	-1730(ra) # 80002812 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	ef4080e7          	jalr	-268(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	ff6080e7          	jalr	-10(ra) # 80001eda <scheduler>
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
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	89e080e7          	jalr	-1890(ra) # 800027ea <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8be080e7          	jalr	-1858(ra) # 80002812 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e5e080e7          	jalr	-418(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e6c080e7          	jalr	-404(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	04c080e7          	jalr	76(ra) # 80002fb8 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	6dc080e7          	jalr	1756(ra) # 80003650 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	686080e7          	jalr	1670(ra) # 80004602 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	f6e080e7          	jalr	-146(ra) # 80005ef2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d04080e7          	jalr	-764(ra) # 80001c90 <userinit>
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
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
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

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00009497          	auipc	s1,0x9
    80001858:	9ec48493          	addi	s1,s1,-1556 # 8000a240 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	0000ea17          	auipc	s4,0xe
    80001872:	7d2a0a13          	addi	s4,s4,2002 # 80010040 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17848493          	addi	s1,s1,376
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00009517          	auipc	a0,0x9
    800018f4:	8a050513          	addi	a0,a0,-1888 # 8000a190 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00009517          	auipc	a0,0x9
    8000190c:	8a050513          	addi	a0,a0,-1888 # 8000a1a8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00009497          	auipc	s1,0x9
    8000191c:	92848493          	addi	s1,s1,-1752 # 8000a240 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	0000e997          	auipc	s3,0xe
    8000193e:	70698993          	addi	s3,s3,1798 # 80010040 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	17848493          	addi	s1,s1,376
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00009517          	auipc	a0,0x9
    800019a4:	82050513          	addi	a0,a0,-2016 # 8000a1c0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00008717          	auipc	a4,0x8
    800019cc:	7c870713          	addi	a4,a4,1992 # 8000a190 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	e407a783          	lw	a5,-448(a5) # 80008840 <first.1689>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	e20080e7          	jalr	-480(ra) # 8000282a <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e207a323          	sw	zero,-474(a5) # 80008840 <first.1689>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	bac080e7          	jalr	-1108(ra) # 800035d0 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00008917          	auipc	s2,0x8
    80001a3e:	75690913          	addi	s2,s2,1878 # 8000a190 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	df878793          	addi	a5,a5,-520 # 80008844 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	05893683          	ld	a3,88(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	6d28                	ld	a0,88(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7e:	68a8                	ld	a0,80(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	64ac                	ld	a1,72(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b90:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00008497          	auipc	s1,0x8
    80001bca:	67a48493          	addi	s1,s1,1658 # 8000a240 <proc>
    80001bce:	0000e917          	auipc	s2,0xe
    80001bd2:	47290913          	addi	s2,s2,1138 # 80010040 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	17848493          	addi	s1,s1,376
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a8a9                	j	80001c52 <allocproc+0x98>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c08:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001c0c:	1604a623          	sw	zero,364(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	ee4080e7          	jalr	-284(ra) # 80000af4 <kalloc>
    80001c18:	892a                	mv	s2,a0
    80001c1a:	eca8                	sd	a0,88(s1)
    80001c1c:	c131                	beqz	a0,80001c60 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e54080e7          	jalr	-428(ra) # 80001a74 <proc_pagetable>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c2c:	c531                	beqz	a0,80001c78 <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001c2e:	07000613          	li	a2,112
    80001c32:	4581                	li	a1,0
    80001c34:	06048513          	addi	a0,s1,96
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	0a8080e7          	jalr	168(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c40:	00000797          	auipc	a5,0x0
    80001c44:	da878793          	addi	a5,a5,-600 # 800019e8 <forkret>
    80001c48:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c4a:	60bc                	ld	a5,64(s1)
    80001c4c:	6705                	lui	a4,0x1
    80001c4e:	97ba                	add	a5,a5,a4
    80001c50:	f4bc                	sd	a5,104(s1)
}
    80001c52:	8526                	mv	a0,s1
    80001c54:	60e2                	ld	ra,24(sp)
    80001c56:	6442                	ld	s0,16(sp)
    80001c58:	64a2                	ld	s1,8(sp)
    80001c5a:	6902                	ld	s2,0(sp)
    80001c5c:	6105                	addi	sp,sp,32
    80001c5e:	8082                	ret
    freeproc(p);
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	f00080e7          	jalr	-256(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	02c080e7          	jalr	44(ra) # 80000c98 <release>
    return 0;
    80001c74:	84ca                	mv	s1,s2
    80001c76:	bff1                	j	80001c52 <allocproc+0x98>
    freeproc(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	ee8080e7          	jalr	-280(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	014080e7          	jalr	20(ra) # 80000c98 <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	b7d1                	j	80001c52 <allocproc+0x98>

0000000080001c90 <userinit>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	f20080e7          	jalr	-224(ra) # 80001bba <allocproc>
    80001ca2:	84aa                	mv	s1,a0
  initproc = p;
    80001ca4:	00007797          	auipc	a5,0x7
    80001ca8:	38a7b223          	sd	a0,900(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cac:	03400613          	li	a2,52
    80001cb0:	00007597          	auipc	a1,0x7
    80001cb4:	ba058593          	addi	a1,a1,-1120 # 80008850 <initcode>
    80001cb8:	6928                	ld	a0,80(a0)
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	6ae080e7          	jalr	1710(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cc2:	6785                	lui	a5,0x1
    80001cc4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc6:	6cb8                	ld	a4,88(s1)
    80001cc8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ccc:	6cb8                	ld	a4,88(s1)
    80001cce:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd0:	4641                	li	a2,16
    80001cd2:	00006597          	auipc	a1,0x6
    80001cd6:	52e58593          	addi	a1,a1,1326 # 80008200 <digits+0x1c0>
    80001cda:	15848513          	addi	a0,s1,344
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	154080e7          	jalr	340(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001ce6:	00006517          	auipc	a0,0x6
    80001cea:	52a50513          	addi	a0,a0,1322 # 80008210 <digits+0x1d0>
    80001cee:	00002097          	auipc	ra,0x2
    80001cf2:	310080e7          	jalr	784(ra) # 80003ffe <namei>
    80001cf6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfa:	478d                	li	a5,3
    80001cfc:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001cfe:	00007797          	auipc	a5,0x7
    80001d02:	3367a783          	lw	a5,822(a5) # 80009034 <ticks>
    80001d06:	16f4a823          	sw	a5,368(s1)
  release(&p->lock);
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <growproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
    80001d2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	c84080e7          	jalr	-892(ra) # 800019b0 <myproc>
    80001d34:	892a                	mv	s2,a0
  sz = p->sz;
    80001d36:	652c                	ld	a1,72(a0)
    80001d38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d3c:	00904f63          	bgtz	s1,80001d5a <growproc+0x3c>
  } else if(n < 0){
    80001d40:	0204cc63          	bltz	s1,80001d78 <growproc+0x5a>
  p->sz = sz;
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4c:	4501                	li	a0,0
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6902                	ld	s2,0(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d5a:	9e25                	addw	a2,a2,s1
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	1582                	slli	a1,a1,0x20
    80001d62:	9181                	srli	a1,a1,0x20
    80001d64:	6928                	ld	a0,80(a0)
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	6bc080e7          	jalr	1724(ra) # 80001422 <uvmalloc>
    80001d6e:	0005061b          	sext.w	a2,a0
    80001d72:	fa69                	bnez	a2,80001d44 <growproc+0x26>
      return -1;
    80001d74:	557d                	li	a0,-1
    80001d76:	bfe1                	j	80001d4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d78:	9e25                	addw	a2,a2,s1
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	1582                	slli	a1,a1,0x20
    80001d80:	9181                	srli	a1,a1,0x20
    80001d82:	6928                	ld	a0,80(a0)
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	656080e7          	jalr	1622(ra) # 800013da <uvmdealloc>
    80001d8c:	0005061b          	sext.w	a2,a0
    80001d90:	bf55                	j	80001d44 <growproc+0x26>

0000000080001d92 <fork>:
{
    80001d92:	7179                	addi	sp,sp,-48
    80001d94:	f406                	sd	ra,40(sp)
    80001d96:	f022                	sd	s0,32(sp)
    80001d98:	ec26                	sd	s1,24(sp)
    80001d9a:	e84a                	sd	s2,16(sp)
    80001d9c:	e44e                	sd	s3,8(sp)
    80001d9e:	e052                	sd	s4,0(sp)
    80001da0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	c0e080e7          	jalr	-1010(ra) # 800019b0 <myproc>
    80001daa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e0e080e7          	jalr	-498(ra) # 80001bba <allocproc>
    80001db4:	12050163          	beqz	a0,80001ed6 <fork+0x144>
    80001db8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dba:	04893603          	ld	a2,72(s2)
    80001dbe:	692c                	ld	a1,80(a0)
    80001dc0:	05093503          	ld	a0,80(s2)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	7aa080e7          	jalr	1962(ra) # 8000156e <uvmcopy>
    80001dcc:	04054663          	bltz	a0,80001e18 <fork+0x86>
  np->sz = p->sz;
    80001dd0:	04893783          	ld	a5,72(s2)
    80001dd4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dd8:	05893683          	ld	a3,88(s2)
    80001ddc:	87b6                	mv	a5,a3
    80001dde:	0589b703          	ld	a4,88(s3)
    80001de2:	12068693          	addi	a3,a3,288
    80001de6:	0007b803          	ld	a6,0(a5)
    80001dea:	6788                	ld	a0,8(a5)
    80001dec:	6b8c                	ld	a1,16(a5)
    80001dee:	6f90                	ld	a2,24(a5)
    80001df0:	01073023          	sd	a6,0(a4)
    80001df4:	e708                	sd	a0,8(a4)
    80001df6:	eb0c                	sd	a1,16(a4)
    80001df8:	ef10                	sd	a2,24(a4)
    80001dfa:	02078793          	addi	a5,a5,32
    80001dfe:	02070713          	addi	a4,a4,32
    80001e02:	fed792e3          	bne	a5,a3,80001de6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e06:	0589b783          	ld	a5,88(s3)
    80001e0a:	0607b823          	sd	zero,112(a5)
    80001e0e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e12:	15000a13          	li	s4,336
    80001e16:	a03d                	j	80001e44 <fork+0xb2>
    freeproc(np);
    80001e18:	854e                	mv	a0,s3
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	d48080e7          	jalr	-696(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e22:	854e                	mv	a0,s3
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e74080e7          	jalr	-396(ra) # 80000c98 <release>
    return -1;
    80001e2c:	5a7d                	li	s4,-1
    80001e2e:	a859                	j	80001ec4 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e30:	00003097          	auipc	ra,0x3
    80001e34:	864080e7          	jalr	-1948(ra) # 80004694 <filedup>
    80001e38:	009987b3          	add	a5,s3,s1
    80001e3c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3e:	04a1                	addi	s1,s1,8
    80001e40:	01448763          	beq	s1,s4,80001e4e <fork+0xbc>
    if(p->ofile[i])
    80001e44:	009907b3          	add	a5,s2,s1
    80001e48:	6388                	ld	a0,0(a5)
    80001e4a:	f17d                	bnez	a0,80001e30 <fork+0x9e>
    80001e4c:	bfcd                	j	80001e3e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e4e:	15093503          	ld	a0,336(s2)
    80001e52:	00002097          	auipc	ra,0x2
    80001e56:	9b8080e7          	jalr	-1608(ra) # 8000380a <idup>
    80001e5a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e5e:	4641                	li	a2,16
    80001e60:	15890593          	addi	a1,s2,344
    80001e64:	15898513          	addi	a0,s3,344
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	fca080e7          	jalr	-54(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e70:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e74:	854e                	mv	a0,s3
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e7e:	00008497          	auipc	s1,0x8
    80001e82:	32a48493          	addi	s1,s1,810 # 8000a1a8 <wait_lock>
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	d5c080e7          	jalr	-676(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e90:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e02080e7          	jalr	-510(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e9e:	854e                	mv	a0,s3
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d44080e7          	jalr	-700(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ea8:	478d                	li	a5,3
    80001eaa:	00f9ac23          	sw	a5,24(s3)
  np->last_runnable_time = ticks;
    80001eae:	00007797          	auipc	a5,0x7
    80001eb2:	1867a783          	lw	a5,390(a5) # 80009034 <ticks>
    80001eb6:	16f9a823          	sw	a5,368(s3)
  release(&np->lock);
    80001eba:	854e                	mv	a0,s3
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	ddc080e7          	jalr	-548(ra) # 80000c98 <release>
}
    80001ec4:	8552                	mv	a0,s4
    80001ec6:	70a2                	ld	ra,40(sp)
    80001ec8:	7402                	ld	s0,32(sp)
    80001eca:	64e2                	ld	s1,24(sp)
    80001ecc:	6942                	ld	s2,16(sp)
    80001ece:	69a2                	ld	s3,8(sp)
    80001ed0:	6a02                	ld	s4,0(sp)
    80001ed2:	6145                	addi	sp,sp,48
    80001ed4:	8082                	ret
    return -1;
    80001ed6:	5a7d                	li	s4,-1
    80001ed8:	b7f5                	j	80001ec4 <fork+0x132>

0000000080001eda <scheduler>:
{
    80001eda:	711d                	addi	sp,sp,-96
    80001edc:	ec86                	sd	ra,88(sp)
    80001ede:	e8a2                	sd	s0,80(sp)
    80001ee0:	e4a6                	sd	s1,72(sp)
    80001ee2:	e0ca                	sd	s2,64(sp)
    80001ee4:	fc4e                	sd	s3,56(sp)
    80001ee6:	f852                	sd	s4,48(sp)
    80001ee8:	f456                	sd	s5,40(sp)
    80001eea:	f05a                	sd	s6,32(sp)
    80001eec:	ec5e                	sd	s7,24(sp)
    80001eee:	e862                	sd	s8,16(sp)
    80001ef0:	e466                	sd	s9,8(sp)
    80001ef2:	e06a                	sd	s10,0(sp)
    80001ef4:	1080                	addi	s0,sp,96
    80001ef6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ef8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001efa:	00779693          	slli	a3,a5,0x7
    80001efe:	00008717          	auipc	a4,0x8
    80001f02:	29270713          	addi	a4,a4,658 # 8000a190 <pid_lock>
    80001f06:	9736                	add	a4,a4,a3
    80001f08:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &minProc->context);
    80001f0c:	00008717          	auipc	a4,0x8
    80001f10:	2bc70713          	addi	a4,a4,700 # 8000a1c8 <cpus+0x8>
    80001f14:	00e68d33          	add	s10,a3,a4
    if(ticks<unpauseTicks)
    80001f18:	00007b17          	auipc	s6,0x7
    80001f1c:	11cb0b13          	addi	s6,s6,284 # 80009034 <ticks>
      uint minLastRunnable = 999999;
    80001f20:	000f4bb7          	lui	s7,0xf4
    80001f24:	23fb8b93          	addi	s7,s7,575 # f423f <_entry-0x7ff0bdc1>
        c->proc = minProc;
    80001f28:	00008c17          	auipc	s8,0x8
    80001f2c:	268c0c13          	addi	s8,s8,616 # 8000a190 <pid_lock>
    80001f30:	9c36                	add	s8,s8,a3
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    80001f32:	00007a17          	auipc	s4,0x7
    80001f36:	0f6a0a13          	addi	s4,s4,246 # 80009028 <initproc>
    80001f3a:	a845                	j	80001fea <scheduler+0x110>
          release(&p->lock);
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	d5a080e7          	jalr	-678(ra) # 80000c98 <release>
        for(p = proc; p < &proc[NPROC]; p++)
    80001f46:	17848493          	addi	s1,s1,376
    80001f4a:	0b248063          	beq	s1,s2,80001fea <scheduler+0x110>
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    80001f4e:	589c                	lw	a5,48(s1)
    80001f50:	ff378be3          	beq	a5,s3,80001f46 <scheduler+0x6c>
    80001f54:	000a3703          	ld	a4,0(s4)
    80001f58:	5b18                	lw	a4,48(a4)
    80001f5a:	fef706e3          	beq	a4,a5,80001f46 <scheduler+0x6c>
          acquire(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	c84080e7          	jalr	-892(ra) # 80000be4 <acquire>
          if(p->state == RUNNING)
    80001f68:	4c9c                	lw	a5,24(s1)
    80001f6a:	fd5799e3          	bne	a5,s5,80001f3c <scheduler+0x62>
              p->state = RUNNABLE;
    80001f6e:	0194ac23          	sw	s9,24(s1)
              p->last_runnable_time = ticks;
    80001f72:	000b2783          	lw	a5,0(s6)
    80001f76:	16f4a823          	sw	a5,368(s1)
    80001f7a:	b7c9                	j	80001f3c <scheduler+0x62>
      uint minLastRunnable = 999999;
    80001f7c:	895e                	mv	s2,s7
      struct proc *minProc = &proc[0];
    80001f7e:	00008c97          	auipc	s9,0x8
    80001f82:	2c2c8c93          	addi	s9,s9,706 # 8000a240 <proc>
      for(p = proc; p < &proc[NPROC]; p++)
    80001f86:	84e6                	mv	s1,s9
        if(p->last_runnable_time<minLastRunnable && p->state == RUNNABLE)  //Find the minimum runnable process
    80001f88:	4a8d                	li	s5,3
      for(p = proc; p < &proc[NPROC]; p++)
    80001f8a:	0000e997          	auipc	s3,0xe
    80001f8e:	0b698993          	addi	s3,s3,182 # 80010040 <tickslock>
    80001f92:	a811                	j	80001fa6 <scheduler+0xcc>
        release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	d02080e7          	jalr	-766(ra) # 80000c98 <release>
      for(p = proc; p < &proc[NPROC]; p++)
    80001f9e:	17848493          	addi	s1,s1,376
    80001fa2:	03348263          	beq	s1,s3,80001fc6 <scheduler+0xec>
        acquire(&p->lock);
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	c3c080e7          	jalr	-964(ra) # 80000be4 <acquire>
        if(p->last_runnable_time<minLastRunnable && p->state == RUNNABLE)  //Find the minimum runnable process
    80001fb0:	1704a783          	lw	a5,368(s1)
    80001fb4:	ff27f0e3          	bgeu	a5,s2,80001f94 <scheduler+0xba>
    80001fb8:	4c9c                	lw	a5,24(s1)
    80001fba:	fd579de3          	bne	a5,s5,80001f94 <scheduler+0xba>
          minLastRunnable = p->mean_ticks;
    80001fbe:	1684a903          	lw	s2,360(s1)
    80001fc2:	8ca6                	mv	s9,s1
    80001fc4:	bfc1                	j	80001f94 <scheduler+0xba>
      acquire(&minProc->lock);
    80001fc6:	84e6                	mv	s1,s9
    80001fc8:	8566                	mv	a0,s9
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	c1a080e7          	jalr	-998(ra) # 80000be4 <acquire>
      if(minProc !=0  && minProc->state == RUNNABLE) 
    80001fd2:	000c8763          	beqz	s9,80001fe0 <scheduler+0x106>
    80001fd6:	018ca703          	lw	a4,24(s9)
    80001fda:	478d                	li	a5,3
    80001fdc:	04f70163          	beq	a4,a5,8000201e <scheduler+0x144>
      release(&minProc->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff2:	10079073          	csrw	sstatus,a5
    if(ticks<unpauseTicks)
    80001ff6:	000b2703          	lw	a4,0(s6)
    80001ffa:	00007797          	auipc	a5,0x7
    80001ffe:	0367a783          	lw	a5,54(a5) # 80009030 <unpauseTicks>
    80002002:	f6f77de3          	bgeu	a4,a5,80001f7c <scheduler+0xa2>
        for(p = proc; p < &proc[NPROC]; p++)
    80002006:	00008497          	auipc	s1,0x8
    8000200a:	23a48493          	addi	s1,s1,570 # 8000a240 <proc>
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    8000200e:	4989                	li	s3,2
          if(p->state == RUNNING)
    80002010:	4a91                	li	s5,4
              p->state = RUNNABLE;
    80002012:	4c8d                	li	s9,3
        for(p = proc; p < &proc[NPROC]; p++)
    80002014:	0000e917          	auipc	s2,0xe
    80002018:	02c90913          	addi	s2,s2,44 # 80010040 <tickslock>
    8000201c:	bf0d                	j	80001f4e <scheduler+0x74>
        minProc->state = RUNNING;
    8000201e:	4791                	li	a5,4
    80002020:	00fcac23          	sw	a5,24(s9)
        c->proc = minProc;
    80002024:	039c3823          	sd	s9,48(s8)
        swtch(&c->context, &minProc->context);
    80002028:	060c8593          	addi	a1,s9,96
    8000202c:	856a                	mv	a0,s10
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	752080e7          	jalr	1874(ra) # 80002780 <swtch>
        c->proc = 0;
    80002036:	020c3823          	sd	zero,48(s8)
    8000203a:	b75d                	j	80001fe0 <scheduler+0x106>

000000008000203c <sched>:
{
    8000203c:	7179                	addi	sp,sp,-48
    8000203e:	f406                	sd	ra,40(sp)
    80002040:	f022                	sd	s0,32(sp)
    80002042:	ec26                	sd	s1,24(sp)
    80002044:	e84a                	sd	s2,16(sp)
    80002046:	e44e                	sd	s3,8(sp)
    80002048:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	966080e7          	jalr	-1690(ra) # 800019b0 <myproc>
    80002052:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	b16080e7          	jalr	-1258(ra) # 80000b6a <holding>
    8000205c:	c93d                	beqz	a0,800020d2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000205e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002060:	2781                	sext.w	a5,a5
    80002062:	079e                	slli	a5,a5,0x7
    80002064:	00008717          	auipc	a4,0x8
    80002068:	12c70713          	addi	a4,a4,300 # 8000a190 <pid_lock>
    8000206c:	97ba                	add	a5,a5,a4
    8000206e:	0a87a703          	lw	a4,168(a5)
    80002072:	4785                	li	a5,1
    80002074:	06f71763          	bne	a4,a5,800020e2 <sched+0xa6>
  if(p->state == RUNNING)
    80002078:	4c98                	lw	a4,24(s1)
    8000207a:	4791                	li	a5,4
    8000207c:	06f70b63          	beq	a4,a5,800020f2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002080:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002084:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002086:	efb5                	bnez	a5,80002102 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002088:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000208a:	00008917          	auipc	s2,0x8
    8000208e:	10690913          	addi	s2,s2,262 # 8000a190 <pid_lock>
    80002092:	2781                	sext.w	a5,a5
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	97ca                	add	a5,a5,s2
    80002098:	0ac7a983          	lw	s3,172(a5)
    8000209c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000209e:	2781                	sext.w	a5,a5
    800020a0:	079e                	slli	a5,a5,0x7
    800020a2:	00008597          	auipc	a1,0x8
    800020a6:	12658593          	addi	a1,a1,294 # 8000a1c8 <cpus+0x8>
    800020aa:	95be                	add	a1,a1,a5
    800020ac:	06048513          	addi	a0,s1,96
    800020b0:	00000097          	auipc	ra,0x0
    800020b4:	6d0080e7          	jalr	1744(ra) # 80002780 <swtch>
    800020b8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ba:	2781                	sext.w	a5,a5
    800020bc:	079e                	slli	a5,a5,0x7
    800020be:	97ca                	add	a5,a5,s2
    800020c0:	0b37a623          	sw	s3,172(a5)
}
    800020c4:	70a2                	ld	ra,40(sp)
    800020c6:	7402                	ld	s0,32(sp)
    800020c8:	64e2                	ld	s1,24(sp)
    800020ca:	6942                	ld	s2,16(sp)
    800020cc:	69a2                	ld	s3,8(sp)
    800020ce:	6145                	addi	sp,sp,48
    800020d0:	8082                	ret
    panic("sched p->lock");
    800020d2:	00006517          	auipc	a0,0x6
    800020d6:	14650513          	addi	a0,a0,326 # 80008218 <digits+0x1d8>
    800020da:	ffffe097          	auipc	ra,0xffffe
    800020de:	464080e7          	jalr	1124(ra) # 8000053e <panic>
    panic("sched locks");
    800020e2:	00006517          	auipc	a0,0x6
    800020e6:	14650513          	addi	a0,a0,326 # 80008228 <digits+0x1e8>
    800020ea:	ffffe097          	auipc	ra,0xffffe
    800020ee:	454080e7          	jalr	1108(ra) # 8000053e <panic>
    panic("sched running");
    800020f2:	00006517          	auipc	a0,0x6
    800020f6:	14650513          	addi	a0,a0,326 # 80008238 <digits+0x1f8>
    800020fa:	ffffe097          	auipc	ra,0xffffe
    800020fe:	444080e7          	jalr	1092(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002102:	00006517          	auipc	a0,0x6
    80002106:	14650513          	addi	a0,a0,326 # 80008248 <digits+0x208>
    8000210a:	ffffe097          	auipc	ra,0xffffe
    8000210e:	434080e7          	jalr	1076(ra) # 8000053e <panic>

0000000080002112 <yield>:
{
    80002112:	1101                	addi	sp,sp,-32
    80002114:	ec06                	sd	ra,24(sp)
    80002116:	e822                	sd	s0,16(sp)
    80002118:	e426                	sd	s1,8(sp)
    8000211a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	894080e7          	jalr	-1900(ra) # 800019b0 <myproc>
    80002124:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	abe080e7          	jalr	-1346(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000212e:	478d                	li	a5,3
    80002130:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002132:	00007797          	auipc	a5,0x7
    80002136:	f027a783          	lw	a5,-254(a5) # 80009034 <ticks>
    8000213a:	16f4a823          	sw	a5,368(s1)
  sched();
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	efe080e7          	jalr	-258(ra) # 8000203c <sched>
  release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b50080e7          	jalr	-1200(ra) # 80000c98 <release>
}
    80002150:	60e2                	ld	ra,24(sp)
    80002152:	6442                	ld	s0,16(sp)
    80002154:	64a2                	ld	s1,8(sp)
    80002156:	6105                	addi	sp,sp,32
    80002158:	8082                	ret

000000008000215a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000215a:	7179                	addi	sp,sp,-48
    8000215c:	f406                	sd	ra,40(sp)
    8000215e:	f022                	sd	s0,32(sp)
    80002160:	ec26                	sd	s1,24(sp)
    80002162:	e84a                	sd	s2,16(sp)
    80002164:	e44e                	sd	s3,8(sp)
    80002166:	1800                	addi	s0,sp,48
    80002168:	89aa                	mv	s3,a0
    8000216a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	844080e7          	jalr	-1980(ra) # 800019b0 <myproc>
    80002174:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	a6e080e7          	jalr	-1426(ra) # 80000be4 <acquire>
  release(lk);
    8000217e:	854a                	mv	a0,s2
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	b18080e7          	jalr	-1256(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002188:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000218c:	4789                	li	a5,2
    8000218e:	cc9c                	sw	a5,24(s1)

  sched();
    80002190:	00000097          	auipc	ra,0x0
    80002194:	eac080e7          	jalr	-340(ra) # 8000203c <sched>

  // Tidy up.
  p->chan = 0;
    80002198:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
  acquire(lk);
    800021a6:	854a                	mv	a0,s2
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a3c080e7          	jalr	-1476(ra) # 80000be4 <acquire>
}
    800021b0:	70a2                	ld	ra,40(sp)
    800021b2:	7402                	ld	s0,32(sp)
    800021b4:	64e2                	ld	s1,24(sp)
    800021b6:	6942                	ld	s2,16(sp)
    800021b8:	69a2                	ld	s3,8(sp)
    800021ba:	6145                	addi	sp,sp,48
    800021bc:	8082                	ret

00000000800021be <wait>:
{
    800021be:	715d                	addi	sp,sp,-80
    800021c0:	e486                	sd	ra,72(sp)
    800021c2:	e0a2                	sd	s0,64(sp)
    800021c4:	fc26                	sd	s1,56(sp)
    800021c6:	f84a                	sd	s2,48(sp)
    800021c8:	f44e                	sd	s3,40(sp)
    800021ca:	f052                	sd	s4,32(sp)
    800021cc:	ec56                	sd	s5,24(sp)
    800021ce:	e85a                	sd	s6,16(sp)
    800021d0:	e45e                	sd	s7,8(sp)
    800021d2:	e062                	sd	s8,0(sp)
    800021d4:	0880                	addi	s0,sp,80
    800021d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	7d8080e7          	jalr	2008(ra) # 800019b0 <myproc>
    800021e0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021e2:	00008517          	auipc	a0,0x8
    800021e6:	fc650513          	addi	a0,a0,-58 # 8000a1a8 <wait_lock>
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	9fa080e7          	jalr	-1542(ra) # 80000be4 <acquire>
    havekids = 0;
    800021f2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021f4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021f6:	0000e997          	auipc	s3,0xe
    800021fa:	e4a98993          	addi	s3,s3,-438 # 80010040 <tickslock>
        havekids = 1;
    800021fe:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002200:	00008c17          	auipc	s8,0x8
    80002204:	fa8c0c13          	addi	s8,s8,-88 # 8000a1a8 <wait_lock>
    havekids = 0;
    80002208:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000220a:	00008497          	auipc	s1,0x8
    8000220e:	03648493          	addi	s1,s1,54 # 8000a240 <proc>
    80002212:	a0bd                	j	80002280 <wait+0xc2>
          pid = np->pid;
    80002214:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002218:	000b0e63          	beqz	s6,80002234 <wait+0x76>
    8000221c:	4691                	li	a3,4
    8000221e:	02c48613          	addi	a2,s1,44
    80002222:	85da                	mv	a1,s6
    80002224:	05093503          	ld	a0,80(s2)
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	44a080e7          	jalr	1098(ra) # 80001672 <copyout>
    80002230:	02054563          	bltz	a0,8000225a <wait+0x9c>
          freeproc(np);
    80002234:	8526                	mv	a0,s1
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	92c080e7          	jalr	-1748(ra) # 80001b62 <freeproc>
          release(&np->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
          release(&wait_lock);
    80002248:	00008517          	auipc	a0,0x8
    8000224c:	f6050513          	addi	a0,a0,-160 # 8000a1a8 <wait_lock>
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>
          return pid;
    80002258:	a09d                	j	800022be <wait+0x100>
            release(&np->lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	a3c080e7          	jalr	-1476(ra) # 80000c98 <release>
            release(&wait_lock);
    80002264:	00008517          	auipc	a0,0x8
    80002268:	f4450513          	addi	a0,a0,-188 # 8000a1a8 <wait_lock>
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a2c080e7          	jalr	-1492(ra) # 80000c98 <release>
            return -1;
    80002274:	59fd                	li	s3,-1
    80002276:	a0a1                	j	800022be <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002278:	17848493          	addi	s1,s1,376
    8000227c:	03348463          	beq	s1,s3,800022a4 <wait+0xe6>
      if(np->parent == p){
    80002280:	7c9c                	ld	a5,56(s1)
    80002282:	ff279be3          	bne	a5,s2,80002278 <wait+0xba>
        acquire(&np->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	95c080e7          	jalr	-1700(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002290:	4c9c                	lw	a5,24(s1)
    80002292:	f94781e3          	beq	a5,s4,80002214 <wait+0x56>
        release(&np->lock);
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	a00080e7          	jalr	-1536(ra) # 80000c98 <release>
        havekids = 1;
    800022a0:	8756                	mv	a4,s5
    800022a2:	bfd9                	j	80002278 <wait+0xba>
    if(!havekids || p->killed){
    800022a4:	c701                	beqz	a4,800022ac <wait+0xee>
    800022a6:	02892783          	lw	a5,40(s2)
    800022aa:	c79d                	beqz	a5,800022d8 <wait+0x11a>
      release(&wait_lock);
    800022ac:	00008517          	auipc	a0,0x8
    800022b0:	efc50513          	addi	a0,a0,-260 # 8000a1a8 <wait_lock>
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	9e4080e7          	jalr	-1564(ra) # 80000c98 <release>
      return -1;
    800022bc:	59fd                	li	s3,-1
}
    800022be:	854e                	mv	a0,s3
    800022c0:	60a6                	ld	ra,72(sp)
    800022c2:	6406                	ld	s0,64(sp)
    800022c4:	74e2                	ld	s1,56(sp)
    800022c6:	7942                	ld	s2,48(sp)
    800022c8:	79a2                	ld	s3,40(sp)
    800022ca:	7a02                	ld	s4,32(sp)
    800022cc:	6ae2                	ld	s5,24(sp)
    800022ce:	6b42                	ld	s6,16(sp)
    800022d0:	6ba2                	ld	s7,8(sp)
    800022d2:	6c02                	ld	s8,0(sp)
    800022d4:	6161                	addi	sp,sp,80
    800022d6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022d8:	85e2                	mv	a1,s8
    800022da:	854a                	mv	a0,s2
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	e7e080e7          	jalr	-386(ra) # 8000215a <sleep>
    havekids = 0;
    800022e4:	b715                	j	80002208 <wait+0x4a>

00000000800022e6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022e6:	7139                	addi	sp,sp,-64
    800022e8:	fc06                	sd	ra,56(sp)
    800022ea:	f822                	sd	s0,48(sp)
    800022ec:	f426                	sd	s1,40(sp)
    800022ee:	f04a                	sd	s2,32(sp)
    800022f0:	ec4e                	sd	s3,24(sp)
    800022f2:	e852                	sd	s4,16(sp)
    800022f4:	e456                	sd	s5,8(sp)
    800022f6:	e05a                	sd	s6,0(sp)
    800022f8:	0080                	addi	s0,sp,64
    800022fa:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022fc:	00008497          	auipc	s1,0x8
    80002300:	f4448493          	addi	s1,s1,-188 # 8000a240 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002304:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002306:	4b0d                	li	s6,3
        p->last_runnable_time = ticks;
    80002308:	00007a97          	auipc	s5,0x7
    8000230c:	d2ca8a93          	addi	s5,s5,-724 # 80009034 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002310:	0000e917          	auipc	s2,0xe
    80002314:	d3090913          	addi	s2,s2,-720 # 80010040 <tickslock>
    80002318:	a005                	j	80002338 <wakeup+0x52>
        p->state = RUNNABLE;
    8000231a:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    8000231e:	000aa783          	lw	a5,0(s5)
    80002322:	16f4a823          	sw	a5,368(s1)
      }
      release(&p->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002330:	17848493          	addi	s1,s1,376
    80002334:	03248463          	beq	s1,s2,8000235c <wakeup+0x76>
    if(p != myproc()){
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	678080e7          	jalr	1656(ra) # 800019b0 <myproc>
    80002340:	fea488e3          	beq	s1,a0,80002330 <wakeup+0x4a>
      acquire(&p->lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	89e080e7          	jalr	-1890(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000234e:	4c9c                	lw	a5,24(s1)
    80002350:	fd379be3          	bne	a5,s3,80002326 <wakeup+0x40>
    80002354:	709c                	ld	a5,32(s1)
    80002356:	fd4798e3          	bne	a5,s4,80002326 <wakeup+0x40>
    8000235a:	b7c1                	j	8000231a <wakeup+0x34>
    }
  }
}
    8000235c:	70e2                	ld	ra,56(sp)
    8000235e:	7442                	ld	s0,48(sp)
    80002360:	74a2                	ld	s1,40(sp)
    80002362:	7902                	ld	s2,32(sp)
    80002364:	69e2                	ld	s3,24(sp)
    80002366:	6a42                	ld	s4,16(sp)
    80002368:	6aa2                	ld	s5,8(sp)
    8000236a:	6b02                	ld	s6,0(sp)
    8000236c:	6121                	addi	sp,sp,64
    8000236e:	8082                	ret

0000000080002370 <reparent>:
{
    80002370:	7179                	addi	sp,sp,-48
    80002372:	f406                	sd	ra,40(sp)
    80002374:	f022                	sd	s0,32(sp)
    80002376:	ec26                	sd	s1,24(sp)
    80002378:	e84a                	sd	s2,16(sp)
    8000237a:	e44e                	sd	s3,8(sp)
    8000237c:	e052                	sd	s4,0(sp)
    8000237e:	1800                	addi	s0,sp,48
    80002380:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002382:	00008497          	auipc	s1,0x8
    80002386:	ebe48493          	addi	s1,s1,-322 # 8000a240 <proc>
      pp->parent = initproc;
    8000238a:	00007a17          	auipc	s4,0x7
    8000238e:	c9ea0a13          	addi	s4,s4,-866 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002392:	0000e997          	auipc	s3,0xe
    80002396:	cae98993          	addi	s3,s3,-850 # 80010040 <tickslock>
    8000239a:	a029                	j	800023a4 <reparent+0x34>
    8000239c:	17848493          	addi	s1,s1,376
    800023a0:	01348d63          	beq	s1,s3,800023ba <reparent+0x4a>
    if(pp->parent == p){
    800023a4:	7c9c                	ld	a5,56(s1)
    800023a6:	ff279be3          	bne	a5,s2,8000239c <reparent+0x2c>
      pp->parent = initproc;
    800023aa:	000a3503          	ld	a0,0(s4)
    800023ae:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	f36080e7          	jalr	-202(ra) # 800022e6 <wakeup>
    800023b8:	b7d5                	j	8000239c <reparent+0x2c>
}
    800023ba:	70a2                	ld	ra,40(sp)
    800023bc:	7402                	ld	s0,32(sp)
    800023be:	64e2                	ld	s1,24(sp)
    800023c0:	6942                	ld	s2,16(sp)
    800023c2:	69a2                	ld	s3,8(sp)
    800023c4:	6a02                	ld	s4,0(sp)
    800023c6:	6145                	addi	sp,sp,48
    800023c8:	8082                	ret

00000000800023ca <exit>:
{
    800023ca:	7179                	addi	sp,sp,-48
    800023cc:	f406                	sd	ra,40(sp)
    800023ce:	f022                	sd	s0,32(sp)
    800023d0:	ec26                	sd	s1,24(sp)
    800023d2:	e84a                	sd	s2,16(sp)
    800023d4:	e44e                	sd	s3,8(sp)
    800023d6:	e052                	sd	s4,0(sp)
    800023d8:	1800                	addi	s0,sp,48
    800023da:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	5d4080e7          	jalr	1492(ra) # 800019b0 <myproc>
    800023e4:	89aa                	mv	s3,a0
  if(p == initproc)
    800023e6:	00007797          	auipc	a5,0x7
    800023ea:	c427b783          	ld	a5,-958(a5) # 80009028 <initproc>
    800023ee:	0d050493          	addi	s1,a0,208
    800023f2:	15050913          	addi	s2,a0,336
    800023f6:	02a79363          	bne	a5,a0,8000241c <exit+0x52>
    panic("init exiting");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	e6650513          	addi	a0,a0,-410 # 80008260 <digits+0x220>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	13c080e7          	jalr	316(ra) # 8000053e <panic>
      fileclose(f);
    8000240a:	00002097          	auipc	ra,0x2
    8000240e:	2dc080e7          	jalr	732(ra) # 800046e6 <fileclose>
      p->ofile[fd] = 0;
    80002412:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002416:	04a1                	addi	s1,s1,8
    80002418:	01248563          	beq	s1,s2,80002422 <exit+0x58>
    if(p->ofile[fd]){
    8000241c:	6088                	ld	a0,0(s1)
    8000241e:	f575                	bnez	a0,8000240a <exit+0x40>
    80002420:	bfdd                	j	80002416 <exit+0x4c>
  begin_op();
    80002422:	00002097          	auipc	ra,0x2
    80002426:	df8080e7          	jalr	-520(ra) # 8000421a <begin_op>
  iput(p->cwd);
    8000242a:	1509b503          	ld	a0,336(s3)
    8000242e:	00001097          	auipc	ra,0x1
    80002432:	5d4080e7          	jalr	1492(ra) # 80003a02 <iput>
  end_op();
    80002436:	00002097          	auipc	ra,0x2
    8000243a:	e64080e7          	jalr	-412(ra) # 8000429a <end_op>
  p->cwd = 0;
    8000243e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002442:	00008497          	auipc	s1,0x8
    80002446:	d6648493          	addi	s1,s1,-666 # 8000a1a8 <wait_lock>
    8000244a:	8526                	mv	a0,s1
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	798080e7          	jalr	1944(ra) # 80000be4 <acquire>
  reparent(p);
    80002454:	854e                	mv	a0,s3
    80002456:	00000097          	auipc	ra,0x0
    8000245a:	f1a080e7          	jalr	-230(ra) # 80002370 <reparent>
  wakeup(p->parent);
    8000245e:	0389b503          	ld	a0,56(s3)
    80002462:	00000097          	auipc	ra,0x0
    80002466:	e84080e7          	jalr	-380(ra) # 800022e6 <wakeup>
  acquire(&p->lock);
    8000246a:	854e                	mv	a0,s3
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	778080e7          	jalr	1912(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002474:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002478:	4795                	li	a5,5
    8000247a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	818080e7          	jalr	-2024(ra) # 80000c98 <release>
  sched();
    80002488:	00000097          	auipc	ra,0x0
    8000248c:	bb4080e7          	jalr	-1100(ra) # 8000203c <sched>
  panic("zombie exit");
    80002490:	00006517          	auipc	a0,0x6
    80002494:	de050513          	addi	a0,a0,-544 # 80008270 <digits+0x230>
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	0a6080e7          	jalr	166(ra) # 8000053e <panic>

00000000800024a0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024a0:	7179                	addi	sp,sp,-48
    800024a2:	f406                	sd	ra,40(sp)
    800024a4:	f022                	sd	s0,32(sp)
    800024a6:	ec26                	sd	s1,24(sp)
    800024a8:	e84a                	sd	s2,16(sp)
    800024aa:	e44e                	sd	s3,8(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024b0:	00008497          	auipc	s1,0x8
    800024b4:	d9048493          	addi	s1,s1,-624 # 8000a240 <proc>
    800024b8:	0000e997          	auipc	s3,0xe
    800024bc:	b8898993          	addi	s3,s3,-1144 # 80010040 <tickslock>
    acquire(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	722080e7          	jalr	1826(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024ca:	589c                	lw	a5,48(s1)
    800024cc:	01278d63          	beq	a5,s2,800024e6 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7c6080e7          	jalr	1990(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024da:	17848493          	addi	s1,s1,376
    800024de:	ff3491e3          	bne	s1,s3,800024c0 <kill+0x20>
  }
  return -1;
    800024e2:	557d                	li	a0,-1
    800024e4:	a829                	j	800024fe <kill+0x5e>
      p->killed = 1;
    800024e6:	4785                	li	a5,1
    800024e8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024ea:	4c98                	lw	a4,24(s1)
    800024ec:	4789                	li	a5,2
    800024ee:	00f70f63          	beq	a4,a5,8000250c <kill+0x6c>
      release(&p->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	7a4080e7          	jalr	1956(ra) # 80000c98 <release>
      return 0;
    800024fc:	4501                	li	a0,0
}
    800024fe:	70a2                	ld	ra,40(sp)
    80002500:	7402                	ld	s0,32(sp)
    80002502:	64e2                	ld	s1,24(sp)
    80002504:	6942                	ld	s2,16(sp)
    80002506:	69a2                	ld	s3,8(sp)
    80002508:	6145                	addi	sp,sp,48
    8000250a:	8082                	ret
        p->state = RUNNABLE;
    8000250c:	478d                	li	a5,3
    8000250e:	cc9c                	sw	a5,24(s1)
        p->last_runnable_time = ticks;
    80002510:	00007797          	auipc	a5,0x7
    80002514:	b247a783          	lw	a5,-1244(a5) # 80009034 <ticks>
    80002518:	16f4a823          	sw	a5,368(s1)
    8000251c:	bfd9                	j	800024f2 <kill+0x52>

000000008000251e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000251e:	7179                	addi	sp,sp,-48
    80002520:	f406                	sd	ra,40(sp)
    80002522:	f022                	sd	s0,32(sp)
    80002524:	ec26                	sd	s1,24(sp)
    80002526:	e84a                	sd	s2,16(sp)
    80002528:	e44e                	sd	s3,8(sp)
    8000252a:	e052                	sd	s4,0(sp)
    8000252c:	1800                	addi	s0,sp,48
    8000252e:	84aa                	mv	s1,a0
    80002530:	892e                	mv	s2,a1
    80002532:	89b2                	mv	s3,a2
    80002534:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	47a080e7          	jalr	1146(ra) # 800019b0 <myproc>
  if(user_dst){
    8000253e:	c08d                	beqz	s1,80002560 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002540:	86d2                	mv	a3,s4
    80002542:	864e                	mv	a2,s3
    80002544:	85ca                	mv	a1,s2
    80002546:	6928                	ld	a0,80(a0)
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	12a080e7          	jalr	298(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002550:	70a2                	ld	ra,40(sp)
    80002552:	7402                	ld	s0,32(sp)
    80002554:	64e2                	ld	s1,24(sp)
    80002556:	6942                	ld	s2,16(sp)
    80002558:	69a2                	ld	s3,8(sp)
    8000255a:	6a02                	ld	s4,0(sp)
    8000255c:	6145                	addi	sp,sp,48
    8000255e:	8082                	ret
    memmove((char *)dst, src, len);
    80002560:	000a061b          	sext.w	a2,s4
    80002564:	85ce                	mv	a1,s3
    80002566:	854a                	mv	a0,s2
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	7d8080e7          	jalr	2008(ra) # 80000d40 <memmove>
    return 0;
    80002570:	8526                	mv	a0,s1
    80002572:	bff9                	j	80002550 <either_copyout+0x32>

0000000080002574 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002574:	7179                	addi	sp,sp,-48
    80002576:	f406                	sd	ra,40(sp)
    80002578:	f022                	sd	s0,32(sp)
    8000257a:	ec26                	sd	s1,24(sp)
    8000257c:	e84a                	sd	s2,16(sp)
    8000257e:	e44e                	sd	s3,8(sp)
    80002580:	e052                	sd	s4,0(sp)
    80002582:	1800                	addi	s0,sp,48
    80002584:	892a                	mv	s2,a0
    80002586:	84ae                	mv	s1,a1
    80002588:	89b2                	mv	s3,a2
    8000258a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	424080e7          	jalr	1060(ra) # 800019b0 <myproc>
  if(user_src){
    80002594:	c08d                	beqz	s1,800025b6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002596:	86d2                	mv	a3,s4
    80002598:	864e                	mv	a2,s3
    8000259a:	85ca                	mv	a1,s2
    8000259c:	6928                	ld	a0,80(a0)
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	160080e7          	jalr	352(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025a6:	70a2                	ld	ra,40(sp)
    800025a8:	7402                	ld	s0,32(sp)
    800025aa:	64e2                	ld	s1,24(sp)
    800025ac:	6942                	ld	s2,16(sp)
    800025ae:	69a2                	ld	s3,8(sp)
    800025b0:	6a02                	ld	s4,0(sp)
    800025b2:	6145                	addi	sp,sp,48
    800025b4:	8082                	ret
    memmove(dst, (char*)src, len);
    800025b6:	000a061b          	sext.w	a2,s4
    800025ba:	85ce                	mv	a1,s3
    800025bc:	854a                	mv	a0,s2
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	782080e7          	jalr	1922(ra) # 80000d40 <memmove>
    return 0;
    800025c6:	8526                	mv	a0,s1
    800025c8:	bff9                	j	800025a6 <either_copyin+0x32>

00000000800025ca <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ca:	715d                	addi	sp,sp,-80
    800025cc:	e486                	sd	ra,72(sp)
    800025ce:	e0a2                	sd	s0,64(sp)
    800025d0:	fc26                	sd	s1,56(sp)
    800025d2:	f84a                	sd	s2,48(sp)
    800025d4:	f44e                	sd	s3,40(sp)
    800025d6:	f052                	sd	s4,32(sp)
    800025d8:	ec56                	sd	s5,24(sp)
    800025da:	e85a                	sd	s6,16(sp)
    800025dc:	e45e                	sd	s7,8(sp)
    800025de:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025e0:	00006517          	auipc	a0,0x6
    800025e4:	ae850513          	addi	a0,a0,-1304 # 800080c8 <digits+0x88>
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	fa0080e7          	jalr	-96(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f0:	00008497          	auipc	s1,0x8
    800025f4:	da848493          	addi	s1,s1,-600 # 8000a398 <proc+0x158>
    800025f8:	0000e917          	auipc	s2,0xe
    800025fc:	ba090913          	addi	s2,s2,-1120 # 80010198 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002600:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002602:	00006997          	auipc	s3,0x6
    80002606:	c7e98993          	addi	s3,s3,-898 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000260a:	00006a97          	auipc	s5,0x6
    8000260e:	c7ea8a93          	addi	s5,s5,-898 # 80008288 <digits+0x248>
    printf("\n");
    80002612:	00006a17          	auipc	s4,0x6
    80002616:	ab6a0a13          	addi	s4,s4,-1354 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261a:	00006b97          	auipc	s7,0x6
    8000261e:	cbeb8b93          	addi	s7,s7,-834 # 800082d8 <states.1726>
    80002622:	a00d                	j	80002644 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002624:	ed86a583          	lw	a1,-296(a3)
    80002628:	8556                	mv	a0,s5
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	f5e080e7          	jalr	-162(ra) # 80000588 <printf>
    printf("\n");
    80002632:	8552                	mv	a0,s4
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	f54080e7          	jalr	-172(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263c:	17848493          	addi	s1,s1,376
    80002640:	03248163          	beq	s1,s2,80002662 <procdump+0x98>
    if(p->state == UNUSED)
    80002644:	86a6                	mv	a3,s1
    80002646:	ec04a783          	lw	a5,-320(s1)
    8000264a:	dbed                	beqz	a5,8000263c <procdump+0x72>
      state = "???";
    8000264c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264e:	fcfb6be3          	bltu	s6,a5,80002624 <procdump+0x5a>
    80002652:	1782                	slli	a5,a5,0x20
    80002654:	9381                	srli	a5,a5,0x20
    80002656:	078e                	slli	a5,a5,0x3
    80002658:	97de                	add	a5,a5,s7
    8000265a:	6390                	ld	a2,0(a5)
    8000265c:	f661                	bnez	a2,80002624 <procdump+0x5a>
      state = "???";
    8000265e:	864e                	mv	a2,s3
    80002660:	b7d1                	j	80002624 <procdump+0x5a>
  }
}
    80002662:	60a6                	ld	ra,72(sp)
    80002664:	6406                	ld	s0,64(sp)
    80002666:	74e2                	ld	s1,56(sp)
    80002668:	7942                	ld	s2,48(sp)
    8000266a:	79a2                	ld	s3,40(sp)
    8000266c:	7a02                	ld	s4,32(sp)
    8000266e:	6ae2                	ld	s5,24(sp)
    80002670:	6b42                	ld	s6,16(sp)
    80002672:	6ba2                	ld	s7,8(sp)
    80002674:	6161                	addi	sp,sp,80
    80002676:	8082                	ret

0000000080002678 <pause_system>:

int
pause_system(int seconds)
{
    80002678:	1101                	addi	sp,sp,-32
    8000267a:	ec06                	sd	ra,24(sp)
    8000267c:	e822                	sd	s0,16(sp)
    8000267e:	e426                	sd	s1,8(sp)
    80002680:	1000                	addi	s0,sp,32
    80002682:	84aa                	mv	s1,a0
  acquire(&tickslock);
    80002684:	0000e517          	auipc	a0,0xe
    80002688:	9bc50513          	addi	a0,a0,-1604 # 80010040 <tickslock>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	558080e7          	jalr	1368(ra) # 80000be4 <acquire>
  unpauseTicks = ticks + (seconds*10);
    80002694:	0024979b          	slliw	a5,s1,0x2
    80002698:	9fa5                	addw	a5,a5,s1
    8000269a:	0017979b          	slliw	a5,a5,0x1
    8000269e:	00007717          	auipc	a4,0x7
    800026a2:	99672703          	lw	a4,-1642(a4) # 80009034 <ticks>
    800026a6:	9fb9                	addw	a5,a5,a4
    800026a8:	00007717          	auipc	a4,0x7
    800026ac:	98f72423          	sw	a5,-1656(a4) # 80009030 <unpauseTicks>
  release(&tickslock);
    800026b0:	0000e517          	auipc	a0,0xe
    800026b4:	99050513          	addi	a0,a0,-1648 # 80010040 <tickslock>
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	5e0080e7          	jalr	1504(ra) # 80000c98 <release>
  yield();
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	a52080e7          	jalr	-1454(ra) # 80002112 <yield>
  return 0;
}
    800026c8:	4501                	li	a0,0
    800026ca:	60e2                	ld	ra,24(sp)
    800026cc:	6442                	ld	s0,16(sp)
    800026ce:	64a2                	ld	s1,8(sp)
    800026d0:	6105                	addi	sp,sp,32
    800026d2:	8082                	ret

00000000800026d4 <kill_system>:

int
kill_system(void)
{
    800026d4:	7179                	addi	sp,sp,-48
    800026d6:	f406                	sd	ra,40(sp)
    800026d8:	f022                	sd	s0,32(sp)
    800026da:	ec26                	sd	s1,24(sp)
    800026dc:	e84a                	sd	s2,16(sp)
    800026de:	e44e                	sd	s3,8(sp)
    800026e0:	e052                	sd	s4,0(sp)
    800026e2:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    800026e4:	00008497          	auipc	s1,0x8
    800026e8:	b5c48493          	addi	s1,s1,-1188 # 8000a240 <proc>
  {
    if(p->pid != initproc->pid && p->pid != SHELL_PID) //Dont kill shell and init processes
    800026ec:	00007997          	auipc	s3,0x7
    800026f0:	93c98993          	addi	s3,s3,-1732 # 80009028 <initproc>
    800026f4:	4a09                	li	s4,2
  for(p = proc; p < &proc[NPROC]; p++)
    800026f6:	0000e917          	auipc	s2,0xe
    800026fa:	94a90913          	addi	s2,s2,-1718 # 80010040 <tickslock>
    800026fe:	a809                	j	80002710 <kill_system+0x3c>
    {
      kill(p->pid);
    80002700:	00000097          	auipc	ra,0x0
    80002704:	da0080e7          	jalr	-608(ra) # 800024a0 <kill>
  for(p = proc; p < &proc[NPROC]; p++)
    80002708:	17848493          	addi	s1,s1,376
    8000270c:	01248b63          	beq	s1,s2,80002722 <kill_system+0x4e>
    if(p->pid != initproc->pid && p->pid != SHELL_PID) //Dont kill shell and init processes
    80002710:	5888                	lw	a0,48(s1)
    80002712:	0009b783          	ld	a5,0(s3)
    80002716:	5b9c                	lw	a5,48(a5)
    80002718:	fea788e3          	beq	a5,a0,80002708 <kill_system+0x34>
    8000271c:	ff4506e3          	beq	a0,s4,80002708 <kill_system+0x34>
    80002720:	b7c5                	j	80002700 <kill_system+0x2c>
    }
  }
  return 0;
}
    80002722:	4501                	li	a0,0
    80002724:	70a2                	ld	ra,40(sp)
    80002726:	7402                	ld	s0,32(sp)
    80002728:	64e2                	ld	s1,24(sp)
    8000272a:	6942                	ld	s2,16(sp)
    8000272c:	69a2                	ld	s3,8(sp)
    8000272e:	6a02                	ld	s4,0(sp)
    80002730:	6145                	addi	sp,sp,48
    80002732:	8082                	ret

0000000080002734 <debug>:

void
debug(void)
{
    80002734:	7179                	addi	sp,sp,-48
    80002736:	f406                	sd	ra,40(sp)
    80002738:	f022                	sd	s0,32(sp)
    8000273a:	ec26                	sd	s1,24(sp)
    8000273c:	e84a                	sd	s2,16(sp)
    8000273e:	e44e                	sd	s3,8(sp)
    80002740:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    80002742:	00008497          	auipc	s1,0x8
    80002746:	c5648493          	addi	s1,s1,-938 # 8000a398 <proc+0x158>
    8000274a:	0000e997          	auipc	s3,0xe
    8000274e:	a4e98993          	addi	s3,s3,-1458 # 80010198 <bcache+0x140>
  {
    printf("name - %s    pid - %d\n", p->name, p->pid);
    80002752:	00006917          	auipc	s2,0x6
    80002756:	b4690913          	addi	s2,s2,-1210 # 80008298 <digits+0x258>
    8000275a:	ed84a603          	lw	a2,-296(s1)
    8000275e:	85a6                	mv	a1,s1
    80002760:	854a                	mv	a0,s2
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	e26080e7          	jalr	-474(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++)
    8000276a:	17848493          	addi	s1,s1,376
    8000276e:	ff3496e3          	bne	s1,s3,8000275a <debug+0x26>
  }

}
    80002772:	70a2                	ld	ra,40(sp)
    80002774:	7402                	ld	s0,32(sp)
    80002776:	64e2                	ld	s1,24(sp)
    80002778:	6942                	ld	s2,16(sp)
    8000277a:	69a2                	ld	s3,8(sp)
    8000277c:	6145                	addi	sp,sp,48
    8000277e:	8082                	ret

0000000080002780 <swtch>:
    80002780:	00153023          	sd	ra,0(a0)
    80002784:	00253423          	sd	sp,8(a0)
    80002788:	e900                	sd	s0,16(a0)
    8000278a:	ed04                	sd	s1,24(a0)
    8000278c:	03253023          	sd	s2,32(a0)
    80002790:	03353423          	sd	s3,40(a0)
    80002794:	03453823          	sd	s4,48(a0)
    80002798:	03553c23          	sd	s5,56(a0)
    8000279c:	05653023          	sd	s6,64(a0)
    800027a0:	05753423          	sd	s7,72(a0)
    800027a4:	05853823          	sd	s8,80(a0)
    800027a8:	05953c23          	sd	s9,88(a0)
    800027ac:	07a53023          	sd	s10,96(a0)
    800027b0:	07b53423          	sd	s11,104(a0)
    800027b4:	0005b083          	ld	ra,0(a1)
    800027b8:	0085b103          	ld	sp,8(a1)
    800027bc:	6980                	ld	s0,16(a1)
    800027be:	6d84                	ld	s1,24(a1)
    800027c0:	0205b903          	ld	s2,32(a1)
    800027c4:	0285b983          	ld	s3,40(a1)
    800027c8:	0305ba03          	ld	s4,48(a1)
    800027cc:	0385ba83          	ld	s5,56(a1)
    800027d0:	0405bb03          	ld	s6,64(a1)
    800027d4:	0485bb83          	ld	s7,72(a1)
    800027d8:	0505bc03          	ld	s8,80(a1)
    800027dc:	0585bc83          	ld	s9,88(a1)
    800027e0:	0605bd03          	ld	s10,96(a1)
    800027e4:	0685bd83          	ld	s11,104(a1)
    800027e8:	8082                	ret

00000000800027ea <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027ea:	1141                	addi	sp,sp,-16
    800027ec:	e406                	sd	ra,8(sp)
    800027ee:	e022                	sd	s0,0(sp)
    800027f0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027f2:	00006597          	auipc	a1,0x6
    800027f6:	b1658593          	addi	a1,a1,-1258 # 80008308 <states.1726+0x30>
    800027fa:	0000e517          	auipc	a0,0xe
    800027fe:	84650513          	addi	a0,a0,-1978 # 80010040 <tickslock>
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	352080e7          	jalr	850(ra) # 80000b54 <initlock>
}
    8000280a:	60a2                	ld	ra,8(sp)
    8000280c:	6402                	ld	s0,0(sp)
    8000280e:	0141                	addi	sp,sp,16
    80002810:	8082                	ret

0000000080002812 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002812:	1141                	addi	sp,sp,-16
    80002814:	e422                	sd	s0,8(sp)
    80002816:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002818:	00003797          	auipc	a5,0x3
    8000281c:	4e878793          	addi	a5,a5,1256 # 80005d00 <kernelvec>
    80002820:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002824:	6422                	ld	s0,8(sp)
    80002826:	0141                	addi	sp,sp,16
    80002828:	8082                	ret

000000008000282a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000282a:	1141                	addi	sp,sp,-16
    8000282c:	e406                	sd	ra,8(sp)
    8000282e:	e022                	sd	s0,0(sp)
    80002830:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	17e080e7          	jalr	382(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000283e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002840:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002844:	00004617          	auipc	a2,0x4
    80002848:	7bc60613          	addi	a2,a2,1980 # 80007000 <_trampoline>
    8000284c:	00004697          	auipc	a3,0x4
    80002850:	7b468693          	addi	a3,a3,1972 # 80007000 <_trampoline>
    80002854:	8e91                	sub	a3,a3,a2
    80002856:	040007b7          	lui	a5,0x4000
    8000285a:	17fd                	addi	a5,a5,-1
    8000285c:	07b2                	slli	a5,a5,0xc
    8000285e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002860:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002864:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002866:	180026f3          	csrr	a3,satp
    8000286a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000286c:	6d38                	ld	a4,88(a0)
    8000286e:	6134                	ld	a3,64(a0)
    80002870:	6585                	lui	a1,0x1
    80002872:	96ae                	add	a3,a3,a1
    80002874:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002876:	6d38                	ld	a4,88(a0)
    80002878:	00000697          	auipc	a3,0x0
    8000287c:	13868693          	addi	a3,a3,312 # 800029b0 <usertrap>
    80002880:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002882:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002884:	8692                	mv	a3,tp
    80002886:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000288c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002890:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002894:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002898:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000289a:	6f18                	ld	a4,24(a4)
    8000289c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028a0:	692c                	ld	a1,80(a0)
    800028a2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028a4:	00004717          	auipc	a4,0x4
    800028a8:	7ec70713          	addi	a4,a4,2028 # 80007090 <userret>
    800028ac:	8f11                	sub	a4,a4,a2
    800028ae:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028b0:	577d                	li	a4,-1
    800028b2:	177e                	slli	a4,a4,0x3f
    800028b4:	8dd9                	or	a1,a1,a4
    800028b6:	02000537          	lui	a0,0x2000
    800028ba:	157d                	addi	a0,a0,-1
    800028bc:	0536                	slli	a0,a0,0xd
    800028be:	9782                	jalr	a5
}
    800028c0:	60a2                	ld	ra,8(sp)
    800028c2:	6402                	ld	s0,0(sp)
    800028c4:	0141                	addi	sp,sp,16
    800028c6:	8082                	ret

00000000800028c8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028c8:	1101                	addi	sp,sp,-32
    800028ca:	ec06                	sd	ra,24(sp)
    800028cc:	e822                	sd	s0,16(sp)
    800028ce:	e426                	sd	s1,8(sp)
    800028d0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028d2:	0000d497          	auipc	s1,0xd
    800028d6:	76e48493          	addi	s1,s1,1902 # 80010040 <tickslock>
    800028da:	8526                	mv	a0,s1
    800028dc:	ffffe097          	auipc	ra,0xffffe
    800028e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
  ticks++;
    800028e4:	00006517          	auipc	a0,0x6
    800028e8:	75050513          	addi	a0,a0,1872 # 80009034 <ticks>
    800028ec:	411c                	lw	a5,0(a0)
    800028ee:	2785                	addiw	a5,a5,1
    800028f0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	9f4080e7          	jalr	-1548(ra) # 800022e6 <wakeup>
  release(&tickslock);
    800028fa:	8526                	mv	a0,s1
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	39c080e7          	jalr	924(ra) # 80000c98 <release>
}
    80002904:	60e2                	ld	ra,24(sp)
    80002906:	6442                	ld	s0,16(sp)
    80002908:	64a2                	ld	s1,8(sp)
    8000290a:	6105                	addi	sp,sp,32
    8000290c:	8082                	ret

000000008000290e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000290e:	1101                	addi	sp,sp,-32
    80002910:	ec06                	sd	ra,24(sp)
    80002912:	e822                	sd	s0,16(sp)
    80002914:	e426                	sd	s1,8(sp)
    80002916:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002918:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000291c:	00074d63          	bltz	a4,80002936 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002920:	57fd                	li	a5,-1
    80002922:	17fe                	slli	a5,a5,0x3f
    80002924:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002926:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002928:	06f70363          	beq	a4,a5,8000298e <devintr+0x80>
  }
}
    8000292c:	60e2                	ld	ra,24(sp)
    8000292e:	6442                	ld	s0,16(sp)
    80002930:	64a2                	ld	s1,8(sp)
    80002932:	6105                	addi	sp,sp,32
    80002934:	8082                	ret
     (scause & 0xff) == 9){
    80002936:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000293a:	46a5                	li	a3,9
    8000293c:	fed792e3          	bne	a5,a3,80002920 <devintr+0x12>
    int irq = plic_claim();
    80002940:	00003097          	auipc	ra,0x3
    80002944:	4c8080e7          	jalr	1224(ra) # 80005e08 <plic_claim>
    80002948:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000294a:	47a9                	li	a5,10
    8000294c:	02f50763          	beq	a0,a5,8000297a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002950:	4785                	li	a5,1
    80002952:	02f50963          	beq	a0,a5,80002984 <devintr+0x76>
    return 1;
    80002956:	4505                	li	a0,1
    } else if(irq){
    80002958:	d8f1                	beqz	s1,8000292c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000295a:	85a6                	mv	a1,s1
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	9b450513          	addi	a0,a0,-1612 # 80008310 <states.1726+0x38>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c24080e7          	jalr	-988(ra) # 80000588 <printf>
      plic_complete(irq);
    8000296c:	8526                	mv	a0,s1
    8000296e:	00003097          	auipc	ra,0x3
    80002972:	4be080e7          	jalr	1214(ra) # 80005e2c <plic_complete>
    return 1;
    80002976:	4505                	li	a0,1
    80002978:	bf55                	j	8000292c <devintr+0x1e>
      uartintr();
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	02e080e7          	jalr	46(ra) # 800009a8 <uartintr>
    80002982:	b7ed                	j	8000296c <devintr+0x5e>
      virtio_disk_intr();
    80002984:	00004097          	auipc	ra,0x4
    80002988:	988080e7          	jalr	-1656(ra) # 8000630c <virtio_disk_intr>
    8000298c:	b7c5                	j	8000296c <devintr+0x5e>
    if(cpuid() == 0){
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	ff6080e7          	jalr	-10(ra) # 80001984 <cpuid>
    80002996:	c901                	beqz	a0,800029a6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002998:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000299c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000299e:	14479073          	csrw	sip,a5
    return 2;
    800029a2:	4509                	li	a0,2
    800029a4:	b761                	j	8000292c <devintr+0x1e>
      clockintr();
    800029a6:	00000097          	auipc	ra,0x0
    800029aa:	f22080e7          	jalr	-222(ra) # 800028c8 <clockintr>
    800029ae:	b7ed                	j	80002998 <devintr+0x8a>

00000000800029b0 <usertrap>:
{
    800029b0:	1101                	addi	sp,sp,-32
    800029b2:	ec06                	sd	ra,24(sp)
    800029b4:	e822                	sd	s0,16(sp)
    800029b6:	e426                	sd	s1,8(sp)
    800029b8:	e04a                	sd	s2,0(sp)
    800029ba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029bc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029c0:	1007f793          	andi	a5,a5,256
    800029c4:	e3ad                	bnez	a5,80002a26 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c6:	00003797          	auipc	a5,0x3
    800029ca:	33a78793          	addi	a5,a5,826 # 80005d00 <kernelvec>
    800029ce:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	fde080e7          	jalr	-34(ra) # 800019b0 <myproc>
    800029da:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029dc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029de:	14102773          	csrr	a4,sepc
    800029e2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029e8:	47a1                	li	a5,8
    800029ea:	04f71c63          	bne	a4,a5,80002a42 <usertrap+0x92>
    if(p->killed)
    800029ee:	551c                	lw	a5,40(a0)
    800029f0:	e3b9                	bnez	a5,80002a36 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029f2:	6cb8                	ld	a4,88(s1)
    800029f4:	6f1c                	ld	a5,24(a4)
    800029f6:	0791                	addi	a5,a5,4
    800029f8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029fe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a02:	10079073          	csrw	sstatus,a5
    syscall();
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	2e0080e7          	jalr	736(ra) # 80002ce6 <syscall>
  if(p->killed)
    80002a0e:	549c                	lw	a5,40(s1)
    80002a10:	ebc1                	bnez	a5,80002aa0 <usertrap+0xf0>
  usertrapret();
    80002a12:	00000097          	auipc	ra,0x0
    80002a16:	e18080e7          	jalr	-488(ra) # 8000282a <usertrapret>
}
    80002a1a:	60e2                	ld	ra,24(sp)
    80002a1c:	6442                	ld	s0,16(sp)
    80002a1e:	64a2                	ld	s1,8(sp)
    80002a20:	6902                	ld	s2,0(sp)
    80002a22:	6105                	addi	sp,sp,32
    80002a24:	8082                	ret
    panic("usertrap: not from user mode");
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	90a50513          	addi	a0,a0,-1782 # 80008330 <states.1726+0x58>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b10080e7          	jalr	-1264(ra) # 8000053e <panic>
      exit(-1);
    80002a36:	557d                	li	a0,-1
    80002a38:	00000097          	auipc	ra,0x0
    80002a3c:	992080e7          	jalr	-1646(ra) # 800023ca <exit>
    80002a40:	bf4d                	j	800029f2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a42:	00000097          	auipc	ra,0x0
    80002a46:	ecc080e7          	jalr	-308(ra) # 8000290e <devintr>
    80002a4a:	892a                	mv	s2,a0
    80002a4c:	c501                	beqz	a0,80002a54 <usertrap+0xa4>
  if(p->killed)
    80002a4e:	549c                	lw	a5,40(s1)
    80002a50:	c3a1                	beqz	a5,80002a90 <usertrap+0xe0>
    80002a52:	a815                	j	80002a86 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a54:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a58:	5890                	lw	a2,48(s1)
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	8f650513          	addi	a0,a0,-1802 # 80008350 <states.1726+0x78>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	b26080e7          	jalr	-1242(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a6e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a72:	00006517          	auipc	a0,0x6
    80002a76:	90e50513          	addi	a0,a0,-1778 # 80008380 <states.1726+0xa8>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	b0e080e7          	jalr	-1266(ra) # 80000588 <printf>
    p->killed = 1;
    80002a82:	4785                	li	a5,1
    80002a84:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a86:	557d                	li	a0,-1
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	942080e7          	jalr	-1726(ra) # 800023ca <exit>
  if(which_dev == 2)
    80002a90:	4789                	li	a5,2
    80002a92:	f8f910e3          	bne	s2,a5,80002a12 <usertrap+0x62>
    yield();
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	67c080e7          	jalr	1660(ra) # 80002112 <yield>
    80002a9e:	bf95                	j	80002a12 <usertrap+0x62>
  int which_dev = 0;
    80002aa0:	4901                	li	s2,0
    80002aa2:	b7d5                	j	80002a86 <usertrap+0xd6>

0000000080002aa4 <kerneltrap>:
{
    80002aa4:	7179                	addi	sp,sp,-48
    80002aa6:	f406                	sd	ra,40(sp)
    80002aa8:	f022                	sd	s0,32(sp)
    80002aaa:	ec26                	sd	s1,24(sp)
    80002aac:	e84a                	sd	s2,16(sp)
    80002aae:	e44e                	sd	s3,8(sp)
    80002ab0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aba:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002abe:	1004f793          	andi	a5,s1,256
    80002ac2:	cb85                	beqz	a5,80002af2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ac8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aca:	ef85                	bnez	a5,80002b02 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	e42080e7          	jalr	-446(ra) # 8000290e <devintr>
    80002ad4:	cd1d                	beqz	a0,80002b12 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ad6:	4789                	li	a5,2
    80002ad8:	06f50a63          	beq	a0,a5,80002b4c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002adc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae0:	10049073          	csrw	sstatus,s1
}
    80002ae4:	70a2                	ld	ra,40(sp)
    80002ae6:	7402                	ld	s0,32(sp)
    80002ae8:	64e2                	ld	s1,24(sp)
    80002aea:	6942                	ld	s2,16(sp)
    80002aec:	69a2                	ld	s3,8(sp)
    80002aee:	6145                	addi	sp,sp,48
    80002af0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	8ae50513          	addi	a0,a0,-1874 # 800083a0 <states.1726+0xc8>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b02:	00006517          	auipc	a0,0x6
    80002b06:	8c650513          	addi	a0,a0,-1850 # 800083c8 <states.1726+0xf0>
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	a34080e7          	jalr	-1484(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b12:	85ce                	mv	a1,s3
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	8d450513          	addi	a0,a0,-1836 # 800083e8 <states.1726+0x110>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a6c080e7          	jalr	-1428(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b28:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	8cc50513          	addi	a0,a0,-1844 # 800083f8 <states.1726+0x120>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a54080e7          	jalr	-1452(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b3c:	00006517          	auipc	a0,0x6
    80002b40:	8d450513          	addi	a0,a0,-1836 # 80008410 <states.1726+0x138>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	e64080e7          	jalr	-412(ra) # 800019b0 <myproc>
    80002b54:	d541                	beqz	a0,80002adc <kerneltrap+0x38>
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	e5a080e7          	jalr	-422(ra) # 800019b0 <myproc>
    80002b5e:	4d18                	lw	a4,24(a0)
    80002b60:	4791                	li	a5,4
    80002b62:	f6f71de3          	bne	a4,a5,80002adc <kerneltrap+0x38>
    yield();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	5ac080e7          	jalr	1452(ra) # 80002112 <yield>
    80002b6e:	b7bd                	j	80002adc <kerneltrap+0x38>

0000000080002b70 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	1000                	addi	s0,sp,32
    80002b7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	e34080e7          	jalr	-460(ra) # 800019b0 <myproc>
  switch (n) {
    80002b84:	4795                	li	a5,5
    80002b86:	0497e163          	bltu	a5,s1,80002bc8 <argraw+0x58>
    80002b8a:	048a                	slli	s1,s1,0x2
    80002b8c:	00006717          	auipc	a4,0x6
    80002b90:	8bc70713          	addi	a4,a4,-1860 # 80008448 <states.1726+0x170>
    80002b94:	94ba                	add	s1,s1,a4
    80002b96:	409c                	lw	a5,0(s1)
    80002b98:	97ba                	add	a5,a5,a4
    80002b9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6105                	addi	sp,sp,32
    80002ba8:	8082                	ret
    return p->trapframe->a1;
    80002baa:	6d3c                	ld	a5,88(a0)
    80002bac:	7fa8                	ld	a0,120(a5)
    80002bae:	bfcd                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a2;
    80002bb0:	6d3c                	ld	a5,88(a0)
    80002bb2:	63c8                	ld	a0,128(a5)
    80002bb4:	b7f5                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a3;
    80002bb6:	6d3c                	ld	a5,88(a0)
    80002bb8:	67c8                	ld	a0,136(a5)
    80002bba:	b7dd                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a4;
    80002bbc:	6d3c                	ld	a5,88(a0)
    80002bbe:	6bc8                	ld	a0,144(a5)
    80002bc0:	b7c5                	j	80002ba0 <argraw+0x30>
    return p->trapframe->a5;
    80002bc2:	6d3c                	ld	a5,88(a0)
    80002bc4:	6fc8                	ld	a0,152(a5)
    80002bc6:	bfe9                	j	80002ba0 <argraw+0x30>
  panic("argraw");
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	85850513          	addi	a0,a0,-1960 # 80008420 <states.1726+0x148>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	96e080e7          	jalr	-1682(ra) # 8000053e <panic>

0000000080002bd8 <fetchaddr>:
{
    80002bd8:	1101                	addi	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	e04a                	sd	s2,0(sp)
    80002be2:	1000                	addi	s0,sp,32
    80002be4:	84aa                	mv	s1,a0
    80002be6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	dc8080e7          	jalr	-568(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bf0:	653c                	ld	a5,72(a0)
    80002bf2:	02f4f863          	bgeu	s1,a5,80002c22 <fetchaddr+0x4a>
    80002bf6:	00848713          	addi	a4,s1,8
    80002bfa:	02e7e663          	bltu	a5,a4,80002c26 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bfe:	46a1                	li	a3,8
    80002c00:	8626                	mv	a2,s1
    80002c02:	85ca                	mv	a1,s2
    80002c04:	6928                	ld	a0,80(a0)
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	af8080e7          	jalr	-1288(ra) # 800016fe <copyin>
    80002c0e:	00a03533          	snez	a0,a0
    80002c12:	40a00533          	neg	a0,a0
}
    80002c16:	60e2                	ld	ra,24(sp)
    80002c18:	6442                	ld	s0,16(sp)
    80002c1a:	64a2                	ld	s1,8(sp)
    80002c1c:	6902                	ld	s2,0(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret
    return -1;
    80002c22:	557d                	li	a0,-1
    80002c24:	bfcd                	j	80002c16 <fetchaddr+0x3e>
    80002c26:	557d                	li	a0,-1
    80002c28:	b7fd                	j	80002c16 <fetchaddr+0x3e>

0000000080002c2a <fetchstr>:
{
    80002c2a:	7179                	addi	sp,sp,-48
    80002c2c:	f406                	sd	ra,40(sp)
    80002c2e:	f022                	sd	s0,32(sp)
    80002c30:	ec26                	sd	s1,24(sp)
    80002c32:	e84a                	sd	s2,16(sp)
    80002c34:	e44e                	sd	s3,8(sp)
    80002c36:	1800                	addi	s0,sp,48
    80002c38:	892a                	mv	s2,a0
    80002c3a:	84ae                	mv	s1,a1
    80002c3c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	d72080e7          	jalr	-654(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c46:	86ce                	mv	a3,s3
    80002c48:	864a                	mv	a2,s2
    80002c4a:	85a6                	mv	a1,s1
    80002c4c:	6928                	ld	a0,80(a0)
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	b3c080e7          	jalr	-1220(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c56:	00054763          	bltz	a0,80002c64 <fetchstr+0x3a>
  return strlen(buf);
    80002c5a:	8526                	mv	a0,s1
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	208080e7          	jalr	520(ra) # 80000e64 <strlen>
}
    80002c64:	70a2                	ld	ra,40(sp)
    80002c66:	7402                	ld	s0,32(sp)
    80002c68:	64e2                	ld	s1,24(sp)
    80002c6a:	6942                	ld	s2,16(sp)
    80002c6c:	69a2                	ld	s3,8(sp)
    80002c6e:	6145                	addi	sp,sp,48
    80002c70:	8082                	ret

0000000080002c72 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c72:	1101                	addi	sp,sp,-32
    80002c74:	ec06                	sd	ra,24(sp)
    80002c76:	e822                	sd	s0,16(sp)
    80002c78:	e426                	sd	s1,8(sp)
    80002c7a:	1000                	addi	s0,sp,32
    80002c7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	ef2080e7          	jalr	-270(ra) # 80002b70 <argraw>
    80002c86:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c88:	4501                	li	a0,0
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	64a2                	ld	s1,8(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	1000                	addi	s0,sp,32
    80002c9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	ed0080e7          	jalr	-304(ra) # 80002b70 <argraw>
    80002ca8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002caa:	4501                	li	a0,0
    80002cac:	60e2                	ld	ra,24(sp)
    80002cae:	6442                	ld	s0,16(sp)
    80002cb0:	64a2                	ld	s1,8(sp)
    80002cb2:	6105                	addi	sp,sp,32
    80002cb4:	8082                	ret

0000000080002cb6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cb6:	1101                	addi	sp,sp,-32
    80002cb8:	ec06                	sd	ra,24(sp)
    80002cba:	e822                	sd	s0,16(sp)
    80002cbc:	e426                	sd	s1,8(sp)
    80002cbe:	e04a                	sd	s2,0(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
    80002cc4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cc6:	00000097          	auipc	ra,0x0
    80002cca:	eaa080e7          	jalr	-342(ra) # 80002b70 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cce:	864a                	mv	a2,s2
    80002cd0:	85a6                	mv	a1,s1
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	f58080e7          	jalr	-168(ra) # 80002c2a <fetchstr>
}
    80002cda:	60e2                	ld	ra,24(sp)
    80002cdc:	6442                	ld	s0,16(sp)
    80002cde:	64a2                	ld	s1,8(sp)
    80002ce0:	6902                	ld	s2,0(sp)
    80002ce2:	6105                	addi	sp,sp,32
    80002ce4:	8082                	ret

0000000080002ce6 <syscall>:
[SYS_debug] sys_debug,
};

void
syscall(void)
{
    80002ce6:	1101                	addi	sp,sp,-32
    80002ce8:	ec06                	sd	ra,24(sp)
    80002cea:	e822                	sd	s0,16(sp)
    80002cec:	e426                	sd	s1,8(sp)
    80002cee:	e04a                	sd	s2,0(sp)
    80002cf0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	cbe080e7          	jalr	-834(ra) # 800019b0 <myproc>
    80002cfa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cfc:	05853903          	ld	s2,88(a0)
    80002d00:	0a893783          	ld	a5,168(s2)
    80002d04:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d08:	37fd                	addiw	a5,a5,-1
    80002d0a:	475d                	li	a4,23
    80002d0c:	00f76f63          	bltu	a4,a5,80002d2a <syscall+0x44>
    80002d10:	00369713          	slli	a4,a3,0x3
    80002d14:	00005797          	auipc	a5,0x5
    80002d18:	74c78793          	addi	a5,a5,1868 # 80008460 <syscalls>
    80002d1c:	97ba                	add	a5,a5,a4
    80002d1e:	639c                	ld	a5,0(a5)
    80002d20:	c789                	beqz	a5,80002d2a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d22:	9782                	jalr	a5
    80002d24:	06a93823          	sd	a0,112(s2)
    80002d28:	a839                	j	80002d46 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d2a:	15848613          	addi	a2,s1,344
    80002d2e:	588c                	lw	a1,48(s1)
    80002d30:	00005517          	auipc	a0,0x5
    80002d34:	6f850513          	addi	a0,a0,1784 # 80008428 <states.1726+0x150>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	850080e7          	jalr	-1968(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d40:	6cbc                	ld	a5,88(s1)
    80002d42:	577d                	li	a4,-1
    80002d44:	fbb8                	sd	a4,112(a5)
  }
}
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	64a2                	ld	s1,8(sp)
    80002d4c:	6902                	ld	s2,0(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d5a:	fec40593          	addi	a1,s0,-20
    80002d5e:	4501                	li	a0,0
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	f12080e7          	jalr	-238(ra) # 80002c72 <argint>
    return -1;
    80002d68:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d6a:	00054963          	bltz	a0,80002d7c <sys_exit+0x2a>
  exit(n);
    80002d6e:	fec42503          	lw	a0,-20(s0)
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	658080e7          	jalr	1624(ra) # 800023ca <exit>
  return 0;  // not reached
    80002d7a:	4781                	li	a5,0
}
    80002d7c:	853e                	mv	a0,a5
    80002d7e:	60e2                	ld	ra,24(sp)
    80002d80:	6442                	ld	s0,16(sp)
    80002d82:	6105                	addi	sp,sp,32
    80002d84:	8082                	ret

0000000080002d86 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d86:	1141                	addi	sp,sp,-16
    80002d88:	e406                	sd	ra,8(sp)
    80002d8a:	e022                	sd	s0,0(sp)
    80002d8c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
}
    80002d96:	5908                	lw	a0,48(a0)
    80002d98:	60a2                	ld	ra,8(sp)
    80002d9a:	6402                	ld	s0,0(sp)
    80002d9c:	0141                	addi	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <sys_fork>:

uint64
sys_fork(void)
{
    80002da0:	1141                	addi	sp,sp,-16
    80002da2:	e406                	sd	ra,8(sp)
    80002da4:	e022                	sd	s0,0(sp)
    80002da6:	0800                	addi	s0,sp,16
  return fork();
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	fea080e7          	jalr	-22(ra) # 80001d92 <fork>
}
    80002db0:	60a2                	ld	ra,8(sp)
    80002db2:	6402                	ld	s0,0(sp)
    80002db4:	0141                	addi	sp,sp,16
    80002db6:	8082                	ret

0000000080002db8 <sys_wait>:

uint64
sys_wait(void)
{
    80002db8:	1101                	addi	sp,sp,-32
    80002dba:	ec06                	sd	ra,24(sp)
    80002dbc:	e822                	sd	s0,16(sp)
    80002dbe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dc0:	fe840593          	addi	a1,s0,-24
    80002dc4:	4501                	li	a0,0
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	ece080e7          	jalr	-306(ra) # 80002c94 <argaddr>
    80002dce:	87aa                	mv	a5,a0
    return -1;
    80002dd0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dd2:	0007c863          	bltz	a5,80002de2 <sys_wait+0x2a>
  return wait(p);
    80002dd6:	fe843503          	ld	a0,-24(s0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	3e4080e7          	jalr	996(ra) # 800021be <wait>
}
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dea:	7179                	addi	sp,sp,-48
    80002dec:	f406                	sd	ra,40(sp)
    80002dee:	f022                	sd	s0,32(sp)
    80002df0:	ec26                	sd	s1,24(sp)
    80002df2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002df4:	fdc40593          	addi	a1,s0,-36
    80002df8:	4501                	li	a0,0
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	e78080e7          	jalr	-392(ra) # 80002c72 <argint>
    80002e02:	87aa                	mv	a5,a0
    return -1;
    80002e04:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e06:	0207c063          	bltz	a5,80002e26 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	ba6080e7          	jalr	-1114(ra) # 800019b0 <myproc>
    80002e12:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e14:	fdc42503          	lw	a0,-36(s0)
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	f06080e7          	jalr	-250(ra) # 80001d1e <growproc>
    80002e20:	00054863          	bltz	a0,80002e30 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e24:	8526                	mv	a0,s1
}
    80002e26:	70a2                	ld	ra,40(sp)
    80002e28:	7402                	ld	s0,32(sp)
    80002e2a:	64e2                	ld	s1,24(sp)
    80002e2c:	6145                	addi	sp,sp,48
    80002e2e:	8082                	ret
    return -1;
    80002e30:	557d                	li	a0,-1
    80002e32:	bfd5                	j	80002e26 <sys_sbrk+0x3c>

0000000080002e34 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e34:	7139                	addi	sp,sp,-64
    80002e36:	fc06                	sd	ra,56(sp)
    80002e38:	f822                	sd	s0,48(sp)
    80002e3a:	f426                	sd	s1,40(sp)
    80002e3c:	f04a                	sd	s2,32(sp)
    80002e3e:	ec4e                	sd	s3,24(sp)
    80002e40:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e42:	fcc40593          	addi	a1,s0,-52
    80002e46:	4501                	li	a0,0
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	e2a080e7          	jalr	-470(ra) # 80002c72 <argint>
    return -1;
    80002e50:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e52:	06054563          	bltz	a0,80002ebc <sys_sleep+0x88>
  acquire(&tickslock);
    80002e56:	0000d517          	auipc	a0,0xd
    80002e5a:	1ea50513          	addi	a0,a0,490 # 80010040 <tickslock>
    80002e5e:	ffffe097          	auipc	ra,0xffffe
    80002e62:	d86080e7          	jalr	-634(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e66:	00006917          	auipc	s2,0x6
    80002e6a:	1ce92903          	lw	s2,462(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    80002e6e:	fcc42783          	lw	a5,-52(s0)
    80002e72:	cf85                	beqz	a5,80002eaa <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e74:	0000d997          	auipc	s3,0xd
    80002e78:	1cc98993          	addi	s3,s3,460 # 80010040 <tickslock>
    80002e7c:	00006497          	auipc	s1,0x6
    80002e80:	1b848493          	addi	s1,s1,440 # 80009034 <ticks>
    if(myproc()->killed){
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	b2c080e7          	jalr	-1236(ra) # 800019b0 <myproc>
    80002e8c:	551c                	lw	a5,40(a0)
    80002e8e:	ef9d                	bnez	a5,80002ecc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e90:	85ce                	mv	a1,s3
    80002e92:	8526                	mv	a0,s1
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	2c6080e7          	jalr	710(ra) # 8000215a <sleep>
  while(ticks - ticks0 < n){
    80002e9c:	409c                	lw	a5,0(s1)
    80002e9e:	412787bb          	subw	a5,a5,s2
    80002ea2:	fcc42703          	lw	a4,-52(s0)
    80002ea6:	fce7efe3          	bltu	a5,a4,80002e84 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002eaa:	0000d517          	auipc	a0,0xd
    80002eae:	19650513          	addi	a0,a0,406 # 80010040 <tickslock>
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
  return 0;
    80002eba:	4781                	li	a5,0
}
    80002ebc:	853e                	mv	a0,a5
    80002ebe:	70e2                	ld	ra,56(sp)
    80002ec0:	7442                	ld	s0,48(sp)
    80002ec2:	74a2                	ld	s1,40(sp)
    80002ec4:	7902                	ld	s2,32(sp)
    80002ec6:	69e2                	ld	s3,24(sp)
    80002ec8:	6121                	addi	sp,sp,64
    80002eca:	8082                	ret
      release(&tickslock);
    80002ecc:	0000d517          	auipc	a0,0xd
    80002ed0:	17450513          	addi	a0,a0,372 # 80010040 <tickslock>
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	dc4080e7          	jalr	-572(ra) # 80000c98 <release>
      return -1;
    80002edc:	57fd                	li	a5,-1
    80002ede:	bff9                	j	80002ebc <sys_sleep+0x88>

0000000080002ee0 <sys_kill>:

uint64
sys_kill(void)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ee8:	fec40593          	addi	a1,s0,-20
    80002eec:	4501                	li	a0,0
    80002eee:	00000097          	auipc	ra,0x0
    80002ef2:	d84080e7          	jalr	-636(ra) # 80002c72 <argint>
    80002ef6:	87aa                	mv	a5,a0
    return -1;
    80002ef8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002efa:	0007c863          	bltz	a5,80002f0a <sys_kill+0x2a>
  return kill(pid);
    80002efe:	fec42503          	lw	a0,-20(s0)
    80002f02:	fffff097          	auipc	ra,0xfffff
    80002f06:	59e080e7          	jalr	1438(ra) # 800024a0 <kill>
}
    80002f0a:	60e2                	ld	ra,24(sp)
    80002f0c:	6442                	ld	s0,16(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret

0000000080002f12 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	e426                	sd	s1,8(sp)
    80002f1a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f1c:	0000d517          	auipc	a0,0xd
    80002f20:	12450513          	addi	a0,a0,292 # 80010040 <tickslock>
    80002f24:	ffffe097          	auipc	ra,0xffffe
    80002f28:	cc0080e7          	jalr	-832(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f2c:	00006497          	auipc	s1,0x6
    80002f30:	1084a483          	lw	s1,264(s1) # 80009034 <ticks>
  release(&tickslock);
    80002f34:	0000d517          	auipc	a0,0xd
    80002f38:	10c50513          	addi	a0,a0,268 # 80010040 <tickslock>
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	d5c080e7          	jalr	-676(ra) # 80000c98 <release>
  return xticks;
}
    80002f44:	02049513          	slli	a0,s1,0x20
    80002f48:	9101                	srli	a0,a0,0x20
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	64a2                	ld	s1,8(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret

0000000080002f54 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002f54:	1101                	addi	sp,sp,-32
    80002f56:	ec06                	sd	ra,24(sp)
    80002f58:	e822                	sd	s0,16(sp)
    80002f5a:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80002f5c:	fec40593          	addi	a1,s0,-20
    80002f60:	4501                	li	a0,0
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	d10080e7          	jalr	-752(ra) # 80002c72 <argint>
    80002f6a:	87aa                	mv	a5,a0
    return -1;
    80002f6c:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80002f6e:	0007c863          	bltz	a5,80002f7e <sys_pause_system+0x2a>
  return pause_system(seconds);
    80002f72:	fec42503          	lw	a0,-20(s0)
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	702080e7          	jalr	1794(ra) # 80002678 <pause_system>
}
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	6105                	addi	sp,sp,32
    80002f84:	8082                	ret

0000000080002f86 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002f86:	1141                	addi	sp,sp,-16
    80002f88:	e406                	sd	ra,8(sp)
    80002f8a:	e022                	sd	s0,0(sp)
    80002f8c:	0800                	addi	s0,sp,16
  return kill_system();
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	746080e7          	jalr	1862(ra) # 800026d4 <kill_system>
}
    80002f96:	60a2                	ld	ra,8(sp)
    80002f98:	6402                	ld	s0,0(sp)
    80002f9a:	0141                	addi	sp,sp,16
    80002f9c:	8082                	ret

0000000080002f9e <sys_debug>:

uint64
sys_debug(void)
{
    80002f9e:	1141                	addi	sp,sp,-16
    80002fa0:	e406                	sd	ra,8(sp)
    80002fa2:	e022                	sd	s0,0(sp)
    80002fa4:	0800                	addi	s0,sp,16
  debug();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	78e080e7          	jalr	1934(ra) # 80002734 <debug>
  return 0;
}
    80002fae:	4501                	li	a0,0
    80002fb0:	60a2                	ld	ra,8(sp)
    80002fb2:	6402                	ld	s0,0(sp)
    80002fb4:	0141                	addi	sp,sp,16
    80002fb6:	8082                	ret

0000000080002fb8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fb8:	7179                	addi	sp,sp,-48
    80002fba:	f406                	sd	ra,40(sp)
    80002fbc:	f022                	sd	s0,32(sp)
    80002fbe:	ec26                	sd	s1,24(sp)
    80002fc0:	e84a                	sd	s2,16(sp)
    80002fc2:	e44e                	sd	s3,8(sp)
    80002fc4:	e052                	sd	s4,0(sp)
    80002fc6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fc8:	00005597          	auipc	a1,0x5
    80002fcc:	56058593          	addi	a1,a1,1376 # 80008528 <syscalls+0xc8>
    80002fd0:	0000d517          	auipc	a0,0xd
    80002fd4:	08850513          	addi	a0,a0,136 # 80010058 <bcache>
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	b7c080e7          	jalr	-1156(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fe0:	00015797          	auipc	a5,0x15
    80002fe4:	07878793          	addi	a5,a5,120 # 80018058 <bcache+0x8000>
    80002fe8:	00015717          	auipc	a4,0x15
    80002fec:	2d870713          	addi	a4,a4,728 # 800182c0 <bcache+0x8268>
    80002ff0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ff4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ff8:	0000d497          	auipc	s1,0xd
    80002ffc:	07848493          	addi	s1,s1,120 # 80010070 <bcache+0x18>
    b->next = bcache.head.next;
    80003000:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003002:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003004:	00005a17          	auipc	s4,0x5
    80003008:	52ca0a13          	addi	s4,s4,1324 # 80008530 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000300c:	2b893783          	ld	a5,696(s2)
    80003010:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003012:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003016:	85d2                	mv	a1,s4
    80003018:	01048513          	addi	a0,s1,16
    8000301c:	00001097          	auipc	ra,0x1
    80003020:	4bc080e7          	jalr	1212(ra) # 800044d8 <initsleeplock>
    bcache.head.next->prev = b;
    80003024:	2b893783          	ld	a5,696(s2)
    80003028:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000302a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000302e:	45848493          	addi	s1,s1,1112
    80003032:	fd349de3          	bne	s1,s3,8000300c <binit+0x54>
  }
}
    80003036:	70a2                	ld	ra,40(sp)
    80003038:	7402                	ld	s0,32(sp)
    8000303a:	64e2                	ld	s1,24(sp)
    8000303c:	6942                	ld	s2,16(sp)
    8000303e:	69a2                	ld	s3,8(sp)
    80003040:	6a02                	ld	s4,0(sp)
    80003042:	6145                	addi	sp,sp,48
    80003044:	8082                	ret

0000000080003046 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003046:	7179                	addi	sp,sp,-48
    80003048:	f406                	sd	ra,40(sp)
    8000304a:	f022                	sd	s0,32(sp)
    8000304c:	ec26                	sd	s1,24(sp)
    8000304e:	e84a                	sd	s2,16(sp)
    80003050:	e44e                	sd	s3,8(sp)
    80003052:	1800                	addi	s0,sp,48
    80003054:	89aa                	mv	s3,a0
    80003056:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003058:	0000d517          	auipc	a0,0xd
    8000305c:	00050513          	mv	a0,a0
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	b84080e7          	jalr	-1148(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003068:	00015497          	auipc	s1,0x15
    8000306c:	2a84b483          	ld	s1,680(s1) # 80018310 <bcache+0x82b8>
    80003070:	00015797          	auipc	a5,0x15
    80003074:	25078793          	addi	a5,a5,592 # 800182c0 <bcache+0x8268>
    80003078:	02f48f63          	beq	s1,a5,800030b6 <bread+0x70>
    8000307c:	873e                	mv	a4,a5
    8000307e:	a021                	j	80003086 <bread+0x40>
    80003080:	68a4                	ld	s1,80(s1)
    80003082:	02e48a63          	beq	s1,a4,800030b6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003086:	449c                	lw	a5,8(s1)
    80003088:	ff379ce3          	bne	a5,s3,80003080 <bread+0x3a>
    8000308c:	44dc                	lw	a5,12(s1)
    8000308e:	ff2799e3          	bne	a5,s2,80003080 <bread+0x3a>
      b->refcnt++;
    80003092:	40bc                	lw	a5,64(s1)
    80003094:	2785                	addiw	a5,a5,1
    80003096:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003098:	0000d517          	auipc	a0,0xd
    8000309c:	fc050513          	addi	a0,a0,-64 # 80010058 <bcache>
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	bf8080e7          	jalr	-1032(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030a8:	01048513          	addi	a0,s1,16
    800030ac:	00001097          	auipc	ra,0x1
    800030b0:	466080e7          	jalr	1126(ra) # 80004512 <acquiresleep>
      return b;
    800030b4:	a8b9                	j	80003112 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030b6:	00015497          	auipc	s1,0x15
    800030ba:	2524b483          	ld	s1,594(s1) # 80018308 <bcache+0x82b0>
    800030be:	00015797          	auipc	a5,0x15
    800030c2:	20278793          	addi	a5,a5,514 # 800182c0 <bcache+0x8268>
    800030c6:	00f48863          	beq	s1,a5,800030d6 <bread+0x90>
    800030ca:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030cc:	40bc                	lw	a5,64(s1)
    800030ce:	cf81                	beqz	a5,800030e6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030d0:	64a4                	ld	s1,72(s1)
    800030d2:	fee49de3          	bne	s1,a4,800030cc <bread+0x86>
  panic("bget: no buffers");
    800030d6:	00005517          	auipc	a0,0x5
    800030da:	46250513          	addi	a0,a0,1122 # 80008538 <syscalls+0xd8>
    800030de:	ffffd097          	auipc	ra,0xffffd
    800030e2:	460080e7          	jalr	1120(ra) # 8000053e <panic>
      b->dev = dev;
    800030e6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030ea:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030ee:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030f2:	4785                	li	a5,1
    800030f4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030f6:	0000d517          	auipc	a0,0xd
    800030fa:	f6250513          	addi	a0,a0,-158 # 80010058 <bcache>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	b9a080e7          	jalr	-1126(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003106:	01048513          	addi	a0,s1,16
    8000310a:	00001097          	auipc	ra,0x1
    8000310e:	408080e7          	jalr	1032(ra) # 80004512 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003112:	409c                	lw	a5,0(s1)
    80003114:	cb89                	beqz	a5,80003126 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003116:	8526                	mv	a0,s1
    80003118:	70a2                	ld	ra,40(sp)
    8000311a:	7402                	ld	s0,32(sp)
    8000311c:	64e2                	ld	s1,24(sp)
    8000311e:	6942                	ld	s2,16(sp)
    80003120:	69a2                	ld	s3,8(sp)
    80003122:	6145                	addi	sp,sp,48
    80003124:	8082                	ret
    virtio_disk_rw(b, 0);
    80003126:	4581                	li	a1,0
    80003128:	8526                	mv	a0,s1
    8000312a:	00003097          	auipc	ra,0x3
    8000312e:	f0c080e7          	jalr	-244(ra) # 80006036 <virtio_disk_rw>
    b->valid = 1;
    80003132:	4785                	li	a5,1
    80003134:	c09c                	sw	a5,0(s1)
  return b;
    80003136:	b7c5                	j	80003116 <bread+0xd0>

0000000080003138 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003138:	1101                	addi	sp,sp,-32
    8000313a:	ec06                	sd	ra,24(sp)
    8000313c:	e822                	sd	s0,16(sp)
    8000313e:	e426                	sd	s1,8(sp)
    80003140:	1000                	addi	s0,sp,32
    80003142:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003144:	0541                	addi	a0,a0,16
    80003146:	00001097          	auipc	ra,0x1
    8000314a:	466080e7          	jalr	1126(ra) # 800045ac <holdingsleep>
    8000314e:	cd01                	beqz	a0,80003166 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003150:	4585                	li	a1,1
    80003152:	8526                	mv	a0,s1
    80003154:	00003097          	auipc	ra,0x3
    80003158:	ee2080e7          	jalr	-286(ra) # 80006036 <virtio_disk_rw>
}
    8000315c:	60e2                	ld	ra,24(sp)
    8000315e:	6442                	ld	s0,16(sp)
    80003160:	64a2                	ld	s1,8(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret
    panic("bwrite");
    80003166:	00005517          	auipc	a0,0x5
    8000316a:	3ea50513          	addi	a0,a0,1002 # 80008550 <syscalls+0xf0>
    8000316e:	ffffd097          	auipc	ra,0xffffd
    80003172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>

0000000080003176 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	e04a                	sd	s2,0(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003184:	01050913          	addi	s2,a0,16
    80003188:	854a                	mv	a0,s2
    8000318a:	00001097          	auipc	ra,0x1
    8000318e:	422080e7          	jalr	1058(ra) # 800045ac <holdingsleep>
    80003192:	c92d                	beqz	a0,80003204 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003194:	854a                	mv	a0,s2
    80003196:	00001097          	auipc	ra,0x1
    8000319a:	3d2080e7          	jalr	978(ra) # 80004568 <releasesleep>

  acquire(&bcache.lock);
    8000319e:	0000d517          	auipc	a0,0xd
    800031a2:	eba50513          	addi	a0,a0,-326 # 80010058 <bcache>
    800031a6:	ffffe097          	auipc	ra,0xffffe
    800031aa:	a3e080e7          	jalr	-1474(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031ae:	40bc                	lw	a5,64(s1)
    800031b0:	37fd                	addiw	a5,a5,-1
    800031b2:	0007871b          	sext.w	a4,a5
    800031b6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031b8:	eb05                	bnez	a4,800031e8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031ba:	68bc                	ld	a5,80(s1)
    800031bc:	64b8                	ld	a4,72(s1)
    800031be:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031c0:	64bc                	ld	a5,72(s1)
    800031c2:	68b8                	ld	a4,80(s1)
    800031c4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031c6:	00015797          	auipc	a5,0x15
    800031ca:	e9278793          	addi	a5,a5,-366 # 80018058 <bcache+0x8000>
    800031ce:	2b87b703          	ld	a4,696(a5)
    800031d2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031d4:	00015717          	auipc	a4,0x15
    800031d8:	0ec70713          	addi	a4,a4,236 # 800182c0 <bcache+0x8268>
    800031dc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031de:	2b87b703          	ld	a4,696(a5)
    800031e2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031e4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031e8:	0000d517          	auipc	a0,0xd
    800031ec:	e7050513          	addi	a0,a0,-400 # 80010058 <bcache>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6902                	ld	s2,0(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret
    panic("brelse");
    80003204:	00005517          	auipc	a0,0x5
    80003208:	35450513          	addi	a0,a0,852 # 80008558 <syscalls+0xf8>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	332080e7          	jalr	818(ra) # 8000053e <panic>

0000000080003214 <bpin>:

void
bpin(struct buf *b) {
    80003214:	1101                	addi	sp,sp,-32
    80003216:	ec06                	sd	ra,24(sp)
    80003218:	e822                	sd	s0,16(sp)
    8000321a:	e426                	sd	s1,8(sp)
    8000321c:	1000                	addi	s0,sp,32
    8000321e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003220:	0000d517          	auipc	a0,0xd
    80003224:	e3850513          	addi	a0,a0,-456 # 80010058 <bcache>
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	9bc080e7          	jalr	-1604(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003230:	40bc                	lw	a5,64(s1)
    80003232:	2785                	addiw	a5,a5,1
    80003234:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003236:	0000d517          	auipc	a0,0xd
    8000323a:	e2250513          	addi	a0,a0,-478 # 80010058 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	a5a080e7          	jalr	-1446(ra) # 80000c98 <release>
}
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	64a2                	ld	s1,8(sp)
    8000324c:	6105                	addi	sp,sp,32
    8000324e:	8082                	ret

0000000080003250 <bunpin>:

void
bunpin(struct buf *b) {
    80003250:	1101                	addi	sp,sp,-32
    80003252:	ec06                	sd	ra,24(sp)
    80003254:	e822                	sd	s0,16(sp)
    80003256:	e426                	sd	s1,8(sp)
    80003258:	1000                	addi	s0,sp,32
    8000325a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000325c:	0000d517          	auipc	a0,0xd
    80003260:	dfc50513          	addi	a0,a0,-516 # 80010058 <bcache>
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	980080e7          	jalr	-1664(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000326c:	40bc                	lw	a5,64(s1)
    8000326e:	37fd                	addiw	a5,a5,-1
    80003270:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003272:	0000d517          	auipc	a0,0xd
    80003276:	de650513          	addi	a0,a0,-538 # 80010058 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	a1e080e7          	jalr	-1506(ra) # 80000c98 <release>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	64a2                	ld	s1,8(sp)
    80003288:	6105                	addi	sp,sp,32
    8000328a:	8082                	ret

000000008000328c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000328c:	1101                	addi	sp,sp,-32
    8000328e:	ec06                	sd	ra,24(sp)
    80003290:	e822                	sd	s0,16(sp)
    80003292:	e426                	sd	s1,8(sp)
    80003294:	e04a                	sd	s2,0(sp)
    80003296:	1000                	addi	s0,sp,32
    80003298:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000329a:	00d5d59b          	srliw	a1,a1,0xd
    8000329e:	00015797          	auipc	a5,0x15
    800032a2:	4967a783          	lw	a5,1174(a5) # 80018734 <sb+0x1c>
    800032a6:	9dbd                	addw	a1,a1,a5
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	d9e080e7          	jalr	-610(ra) # 80003046 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032b0:	0074f713          	andi	a4,s1,7
    800032b4:	4785                	li	a5,1
    800032b6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032ba:	14ce                	slli	s1,s1,0x33
    800032bc:	90d9                	srli	s1,s1,0x36
    800032be:	00950733          	add	a4,a0,s1
    800032c2:	05874703          	lbu	a4,88(a4)
    800032c6:	00e7f6b3          	and	a3,a5,a4
    800032ca:	c69d                	beqz	a3,800032f8 <bfree+0x6c>
    800032cc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032ce:	94aa                	add	s1,s1,a0
    800032d0:	fff7c793          	not	a5,a5
    800032d4:	8ff9                	and	a5,a5,a4
    800032d6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032da:	00001097          	auipc	ra,0x1
    800032de:	118080e7          	jalr	280(ra) # 800043f2 <log_write>
  brelse(bp);
    800032e2:	854a                	mv	a0,s2
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	e92080e7          	jalr	-366(ra) # 80003176 <brelse>
}
    800032ec:	60e2                	ld	ra,24(sp)
    800032ee:	6442                	ld	s0,16(sp)
    800032f0:	64a2                	ld	s1,8(sp)
    800032f2:	6902                	ld	s2,0(sp)
    800032f4:	6105                	addi	sp,sp,32
    800032f6:	8082                	ret
    panic("freeing free block");
    800032f8:	00005517          	auipc	a0,0x5
    800032fc:	26850513          	addi	a0,a0,616 # 80008560 <syscalls+0x100>
    80003300:	ffffd097          	auipc	ra,0xffffd
    80003304:	23e080e7          	jalr	574(ra) # 8000053e <panic>

0000000080003308 <balloc>:
{
    80003308:	711d                	addi	sp,sp,-96
    8000330a:	ec86                	sd	ra,88(sp)
    8000330c:	e8a2                	sd	s0,80(sp)
    8000330e:	e4a6                	sd	s1,72(sp)
    80003310:	e0ca                	sd	s2,64(sp)
    80003312:	fc4e                	sd	s3,56(sp)
    80003314:	f852                	sd	s4,48(sp)
    80003316:	f456                	sd	s5,40(sp)
    80003318:	f05a                	sd	s6,32(sp)
    8000331a:	ec5e                	sd	s7,24(sp)
    8000331c:	e862                	sd	s8,16(sp)
    8000331e:	e466                	sd	s9,8(sp)
    80003320:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003322:	00015797          	auipc	a5,0x15
    80003326:	3fa7a783          	lw	a5,1018(a5) # 8001871c <sb+0x4>
    8000332a:	cbd1                	beqz	a5,800033be <balloc+0xb6>
    8000332c:	8baa                	mv	s7,a0
    8000332e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003330:	00015b17          	auipc	s6,0x15
    80003334:	3e8b0b13          	addi	s6,s6,1000 # 80018718 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003338:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000333a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000333e:	6c89                	lui	s9,0x2
    80003340:	a831                	j	8000335c <balloc+0x54>
    brelse(bp);
    80003342:	854a                	mv	a0,s2
    80003344:	00000097          	auipc	ra,0x0
    80003348:	e32080e7          	jalr	-462(ra) # 80003176 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000334c:	015c87bb          	addw	a5,s9,s5
    80003350:	00078a9b          	sext.w	s5,a5
    80003354:	004b2703          	lw	a4,4(s6)
    80003358:	06eaf363          	bgeu	s5,a4,800033be <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000335c:	41fad79b          	sraiw	a5,s5,0x1f
    80003360:	0137d79b          	srliw	a5,a5,0x13
    80003364:	015787bb          	addw	a5,a5,s5
    80003368:	40d7d79b          	sraiw	a5,a5,0xd
    8000336c:	01cb2583          	lw	a1,28(s6)
    80003370:	9dbd                	addw	a1,a1,a5
    80003372:	855e                	mv	a0,s7
    80003374:	00000097          	auipc	ra,0x0
    80003378:	cd2080e7          	jalr	-814(ra) # 80003046 <bread>
    8000337c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000337e:	004b2503          	lw	a0,4(s6)
    80003382:	000a849b          	sext.w	s1,s5
    80003386:	8662                	mv	a2,s8
    80003388:	faa4fde3          	bgeu	s1,a0,80003342 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000338c:	41f6579b          	sraiw	a5,a2,0x1f
    80003390:	01d7d69b          	srliw	a3,a5,0x1d
    80003394:	00c6873b          	addw	a4,a3,a2
    80003398:	00777793          	andi	a5,a4,7
    8000339c:	9f95                	subw	a5,a5,a3
    8000339e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033a2:	4037571b          	sraiw	a4,a4,0x3
    800033a6:	00e906b3          	add	a3,s2,a4
    800033aa:	0586c683          	lbu	a3,88(a3)
    800033ae:	00d7f5b3          	and	a1,a5,a3
    800033b2:	cd91                	beqz	a1,800033ce <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b4:	2605                	addiw	a2,a2,1
    800033b6:	2485                	addiw	s1,s1,1
    800033b8:	fd4618e3          	bne	a2,s4,80003388 <balloc+0x80>
    800033bc:	b759                	j	80003342 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033be:	00005517          	auipc	a0,0x5
    800033c2:	1ba50513          	addi	a0,a0,442 # 80008578 <syscalls+0x118>
    800033c6:	ffffd097          	auipc	ra,0xffffd
    800033ca:	178080e7          	jalr	376(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033ce:	974a                	add	a4,a4,s2
    800033d0:	8fd5                	or	a5,a5,a3
    800033d2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033d6:	854a                	mv	a0,s2
    800033d8:	00001097          	auipc	ra,0x1
    800033dc:	01a080e7          	jalr	26(ra) # 800043f2 <log_write>
        brelse(bp);
    800033e0:	854a                	mv	a0,s2
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	d94080e7          	jalr	-620(ra) # 80003176 <brelse>
  bp = bread(dev, bno);
    800033ea:	85a6                	mv	a1,s1
    800033ec:	855e                	mv	a0,s7
    800033ee:	00000097          	auipc	ra,0x0
    800033f2:	c58080e7          	jalr	-936(ra) # 80003046 <bread>
    800033f6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033f8:	40000613          	li	a2,1024
    800033fc:	4581                	li	a1,0
    800033fe:	05850513          	addi	a0,a0,88
    80003402:	ffffe097          	auipc	ra,0xffffe
    80003406:	8de080e7          	jalr	-1826(ra) # 80000ce0 <memset>
  log_write(bp);
    8000340a:	854a                	mv	a0,s2
    8000340c:	00001097          	auipc	ra,0x1
    80003410:	fe6080e7          	jalr	-26(ra) # 800043f2 <log_write>
  brelse(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	d60080e7          	jalr	-672(ra) # 80003176 <brelse>
}
    8000341e:	8526                	mv	a0,s1
    80003420:	60e6                	ld	ra,88(sp)
    80003422:	6446                	ld	s0,80(sp)
    80003424:	64a6                	ld	s1,72(sp)
    80003426:	6906                	ld	s2,64(sp)
    80003428:	79e2                	ld	s3,56(sp)
    8000342a:	7a42                	ld	s4,48(sp)
    8000342c:	7aa2                	ld	s5,40(sp)
    8000342e:	7b02                	ld	s6,32(sp)
    80003430:	6be2                	ld	s7,24(sp)
    80003432:	6c42                	ld	s8,16(sp)
    80003434:	6ca2                	ld	s9,8(sp)
    80003436:	6125                	addi	sp,sp,96
    80003438:	8082                	ret

000000008000343a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	e84a                	sd	s2,16(sp)
    80003444:	e44e                	sd	s3,8(sp)
    80003446:	e052                	sd	s4,0(sp)
    80003448:	1800                	addi	s0,sp,48
    8000344a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000344c:	47ad                	li	a5,11
    8000344e:	04b7fe63          	bgeu	a5,a1,800034aa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003452:	ff45849b          	addiw	s1,a1,-12
    80003456:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000345a:	0ff00793          	li	a5,255
    8000345e:	0ae7e363          	bltu	a5,a4,80003504 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003462:	08052583          	lw	a1,128(a0)
    80003466:	c5ad                	beqz	a1,800034d0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003468:	00092503          	lw	a0,0(s2)
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	bda080e7          	jalr	-1062(ra) # 80003046 <bread>
    80003474:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003476:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000347a:	02049593          	slli	a1,s1,0x20
    8000347e:	9181                	srli	a1,a1,0x20
    80003480:	058a                	slli	a1,a1,0x2
    80003482:	00b784b3          	add	s1,a5,a1
    80003486:	0004a983          	lw	s3,0(s1)
    8000348a:	04098d63          	beqz	s3,800034e4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000348e:	8552                	mv	a0,s4
    80003490:	00000097          	auipc	ra,0x0
    80003494:	ce6080e7          	jalr	-794(ra) # 80003176 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003498:	854e                	mv	a0,s3
    8000349a:	70a2                	ld	ra,40(sp)
    8000349c:	7402                	ld	s0,32(sp)
    8000349e:	64e2                	ld	s1,24(sp)
    800034a0:	6942                	ld	s2,16(sp)
    800034a2:	69a2                	ld	s3,8(sp)
    800034a4:	6a02                	ld	s4,0(sp)
    800034a6:	6145                	addi	sp,sp,48
    800034a8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034aa:	02059493          	slli	s1,a1,0x20
    800034ae:	9081                	srli	s1,s1,0x20
    800034b0:	048a                	slli	s1,s1,0x2
    800034b2:	94aa                	add	s1,s1,a0
    800034b4:	0504a983          	lw	s3,80(s1)
    800034b8:	fe0990e3          	bnez	s3,80003498 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034bc:	4108                	lw	a0,0(a0)
    800034be:	00000097          	auipc	ra,0x0
    800034c2:	e4a080e7          	jalr	-438(ra) # 80003308 <balloc>
    800034c6:	0005099b          	sext.w	s3,a0
    800034ca:	0534a823          	sw	s3,80(s1)
    800034ce:	b7e9                	j	80003498 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034d0:	4108                	lw	a0,0(a0)
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	e36080e7          	jalr	-458(ra) # 80003308 <balloc>
    800034da:	0005059b          	sext.w	a1,a0
    800034de:	08b92023          	sw	a1,128(s2)
    800034e2:	b759                	j	80003468 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034e4:	00092503          	lw	a0,0(s2)
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	e20080e7          	jalr	-480(ra) # 80003308 <balloc>
    800034f0:	0005099b          	sext.w	s3,a0
    800034f4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034f8:	8552                	mv	a0,s4
    800034fa:	00001097          	auipc	ra,0x1
    800034fe:	ef8080e7          	jalr	-264(ra) # 800043f2 <log_write>
    80003502:	b771                	j	8000348e <bmap+0x54>
  panic("bmap: out of range");
    80003504:	00005517          	auipc	a0,0x5
    80003508:	08c50513          	addi	a0,a0,140 # 80008590 <syscalls+0x130>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	032080e7          	jalr	50(ra) # 8000053e <panic>

0000000080003514 <iget>:
{
    80003514:	7179                	addi	sp,sp,-48
    80003516:	f406                	sd	ra,40(sp)
    80003518:	f022                	sd	s0,32(sp)
    8000351a:	ec26                	sd	s1,24(sp)
    8000351c:	e84a                	sd	s2,16(sp)
    8000351e:	e44e                	sd	s3,8(sp)
    80003520:	e052                	sd	s4,0(sp)
    80003522:	1800                	addi	s0,sp,48
    80003524:	89aa                	mv	s3,a0
    80003526:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003528:	00015517          	auipc	a0,0x15
    8000352c:	21050513          	addi	a0,a0,528 # 80018738 <itable>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  empty = 0;
    80003538:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000353a:	00015497          	auipc	s1,0x15
    8000353e:	21648493          	addi	s1,s1,534 # 80018750 <itable+0x18>
    80003542:	00017697          	auipc	a3,0x17
    80003546:	c9e68693          	addi	a3,a3,-866 # 8001a1e0 <log>
    8000354a:	a039                	j	80003558 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000354c:	02090b63          	beqz	s2,80003582 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003550:	08848493          	addi	s1,s1,136
    80003554:	02d48a63          	beq	s1,a3,80003588 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003558:	449c                	lw	a5,8(s1)
    8000355a:	fef059e3          	blez	a5,8000354c <iget+0x38>
    8000355e:	4098                	lw	a4,0(s1)
    80003560:	ff3716e3          	bne	a4,s3,8000354c <iget+0x38>
    80003564:	40d8                	lw	a4,4(s1)
    80003566:	ff4713e3          	bne	a4,s4,8000354c <iget+0x38>
      ip->ref++;
    8000356a:	2785                	addiw	a5,a5,1
    8000356c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000356e:	00015517          	auipc	a0,0x15
    80003572:	1ca50513          	addi	a0,a0,458 # 80018738 <itable>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	722080e7          	jalr	1826(ra) # 80000c98 <release>
      return ip;
    8000357e:	8926                	mv	s2,s1
    80003580:	a03d                	j	800035ae <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003582:	f7f9                	bnez	a5,80003550 <iget+0x3c>
    80003584:	8926                	mv	s2,s1
    80003586:	b7e9                	j	80003550 <iget+0x3c>
  if(empty == 0)
    80003588:	02090c63          	beqz	s2,800035c0 <iget+0xac>
  ip->dev = dev;
    8000358c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003590:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003594:	4785                	li	a5,1
    80003596:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000359a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000359e:	00015517          	auipc	a0,0x15
    800035a2:	19a50513          	addi	a0,a0,410 # 80018738 <itable>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	6f2080e7          	jalr	1778(ra) # 80000c98 <release>
}
    800035ae:	854a                	mv	a0,s2
    800035b0:	70a2                	ld	ra,40(sp)
    800035b2:	7402                	ld	s0,32(sp)
    800035b4:	64e2                	ld	s1,24(sp)
    800035b6:	6942                	ld	s2,16(sp)
    800035b8:	69a2                	ld	s3,8(sp)
    800035ba:	6a02                	ld	s4,0(sp)
    800035bc:	6145                	addi	sp,sp,48
    800035be:	8082                	ret
    panic("iget: no inodes");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	fe850513          	addi	a0,a0,-24 # 800085a8 <syscalls+0x148>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	f76080e7          	jalr	-138(ra) # 8000053e <panic>

00000000800035d0 <fsinit>:
fsinit(int dev) {
    800035d0:	7179                	addi	sp,sp,-48
    800035d2:	f406                	sd	ra,40(sp)
    800035d4:	f022                	sd	s0,32(sp)
    800035d6:	ec26                	sd	s1,24(sp)
    800035d8:	e84a                	sd	s2,16(sp)
    800035da:	e44e                	sd	s3,8(sp)
    800035dc:	1800                	addi	s0,sp,48
    800035de:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035e0:	4585                	li	a1,1
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	a64080e7          	jalr	-1436(ra) # 80003046 <bread>
    800035ea:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ec:	00015997          	auipc	s3,0x15
    800035f0:	12c98993          	addi	s3,s3,300 # 80018718 <sb>
    800035f4:	02000613          	li	a2,32
    800035f8:	05850593          	addi	a1,a0,88
    800035fc:	854e                	mv	a0,s3
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	742080e7          	jalr	1858(ra) # 80000d40 <memmove>
  brelse(bp);
    80003606:	8526                	mv	a0,s1
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	b6e080e7          	jalr	-1170(ra) # 80003176 <brelse>
  if(sb.magic != FSMAGIC)
    80003610:	0009a703          	lw	a4,0(s3)
    80003614:	102037b7          	lui	a5,0x10203
    80003618:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000361c:	02f71263          	bne	a4,a5,80003640 <fsinit+0x70>
  initlog(dev, &sb);
    80003620:	00015597          	auipc	a1,0x15
    80003624:	0f858593          	addi	a1,a1,248 # 80018718 <sb>
    80003628:	854a                	mv	a0,s2
    8000362a:	00001097          	auipc	ra,0x1
    8000362e:	b4c080e7          	jalr	-1204(ra) # 80004176 <initlog>
}
    80003632:	70a2                	ld	ra,40(sp)
    80003634:	7402                	ld	s0,32(sp)
    80003636:	64e2                	ld	s1,24(sp)
    80003638:	6942                	ld	s2,16(sp)
    8000363a:	69a2                	ld	s3,8(sp)
    8000363c:	6145                	addi	sp,sp,48
    8000363e:	8082                	ret
    panic("invalid file system");
    80003640:	00005517          	auipc	a0,0x5
    80003644:	f7850513          	addi	a0,a0,-136 # 800085b8 <syscalls+0x158>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	ef6080e7          	jalr	-266(ra) # 8000053e <panic>

0000000080003650 <iinit>:
{
    80003650:	7179                	addi	sp,sp,-48
    80003652:	f406                	sd	ra,40(sp)
    80003654:	f022                	sd	s0,32(sp)
    80003656:	ec26                	sd	s1,24(sp)
    80003658:	e84a                	sd	s2,16(sp)
    8000365a:	e44e                	sd	s3,8(sp)
    8000365c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000365e:	00005597          	auipc	a1,0x5
    80003662:	f7258593          	addi	a1,a1,-142 # 800085d0 <syscalls+0x170>
    80003666:	00015517          	auipc	a0,0x15
    8000366a:	0d250513          	addi	a0,a0,210 # 80018738 <itable>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	4e6080e7          	jalr	1254(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003676:	00015497          	auipc	s1,0x15
    8000367a:	0ea48493          	addi	s1,s1,234 # 80018760 <itable+0x28>
    8000367e:	00017997          	auipc	s3,0x17
    80003682:	b7298993          	addi	s3,s3,-1166 # 8001a1f0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003686:	00005917          	auipc	s2,0x5
    8000368a:	f5290913          	addi	s2,s2,-174 # 800085d8 <syscalls+0x178>
    8000368e:	85ca                	mv	a1,s2
    80003690:	8526                	mv	a0,s1
    80003692:	00001097          	auipc	ra,0x1
    80003696:	e46080e7          	jalr	-442(ra) # 800044d8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000369a:	08848493          	addi	s1,s1,136
    8000369e:	ff3498e3          	bne	s1,s3,8000368e <iinit+0x3e>
}
    800036a2:	70a2                	ld	ra,40(sp)
    800036a4:	7402                	ld	s0,32(sp)
    800036a6:	64e2                	ld	s1,24(sp)
    800036a8:	6942                	ld	s2,16(sp)
    800036aa:	69a2                	ld	s3,8(sp)
    800036ac:	6145                	addi	sp,sp,48
    800036ae:	8082                	ret

00000000800036b0 <ialloc>:
{
    800036b0:	715d                	addi	sp,sp,-80
    800036b2:	e486                	sd	ra,72(sp)
    800036b4:	e0a2                	sd	s0,64(sp)
    800036b6:	fc26                	sd	s1,56(sp)
    800036b8:	f84a                	sd	s2,48(sp)
    800036ba:	f44e                	sd	s3,40(sp)
    800036bc:	f052                	sd	s4,32(sp)
    800036be:	ec56                	sd	s5,24(sp)
    800036c0:	e85a                	sd	s6,16(sp)
    800036c2:	e45e                	sd	s7,8(sp)
    800036c4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036c6:	00015717          	auipc	a4,0x15
    800036ca:	05e72703          	lw	a4,94(a4) # 80018724 <sb+0xc>
    800036ce:	4785                	li	a5,1
    800036d0:	04e7fa63          	bgeu	a5,a4,80003724 <ialloc+0x74>
    800036d4:	8aaa                	mv	s5,a0
    800036d6:	8bae                	mv	s7,a1
    800036d8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036da:	00015a17          	auipc	s4,0x15
    800036de:	03ea0a13          	addi	s4,s4,62 # 80018718 <sb>
    800036e2:	00048b1b          	sext.w	s6,s1
    800036e6:	0044d593          	srli	a1,s1,0x4
    800036ea:	018a2783          	lw	a5,24(s4)
    800036ee:	9dbd                	addw	a1,a1,a5
    800036f0:	8556                	mv	a0,s5
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	954080e7          	jalr	-1708(ra) # 80003046 <bread>
    800036fa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036fc:	05850993          	addi	s3,a0,88
    80003700:	00f4f793          	andi	a5,s1,15
    80003704:	079a                	slli	a5,a5,0x6
    80003706:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003708:	00099783          	lh	a5,0(s3)
    8000370c:	c785                	beqz	a5,80003734 <ialloc+0x84>
    brelse(bp);
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	a68080e7          	jalr	-1432(ra) # 80003176 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003716:	0485                	addi	s1,s1,1
    80003718:	00ca2703          	lw	a4,12(s4)
    8000371c:	0004879b          	sext.w	a5,s1
    80003720:	fce7e1e3          	bltu	a5,a4,800036e2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003724:	00005517          	auipc	a0,0x5
    80003728:	ebc50513          	addi	a0,a0,-324 # 800085e0 <syscalls+0x180>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	e12080e7          	jalr	-494(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003734:	04000613          	li	a2,64
    80003738:	4581                	li	a1,0
    8000373a:	854e                	mv	a0,s3
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	5a4080e7          	jalr	1444(ra) # 80000ce0 <memset>
      dip->type = type;
    80003744:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	ca8080e7          	jalr	-856(ra) # 800043f2 <log_write>
      brelse(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00000097          	auipc	ra,0x0
    80003758:	a22080e7          	jalr	-1502(ra) # 80003176 <brelse>
      return iget(dev, inum);
    8000375c:	85da                	mv	a1,s6
    8000375e:	8556                	mv	a0,s5
    80003760:	00000097          	auipc	ra,0x0
    80003764:	db4080e7          	jalr	-588(ra) # 80003514 <iget>
}
    80003768:	60a6                	ld	ra,72(sp)
    8000376a:	6406                	ld	s0,64(sp)
    8000376c:	74e2                	ld	s1,56(sp)
    8000376e:	7942                	ld	s2,48(sp)
    80003770:	79a2                	ld	s3,40(sp)
    80003772:	7a02                	ld	s4,32(sp)
    80003774:	6ae2                	ld	s5,24(sp)
    80003776:	6b42                	ld	s6,16(sp)
    80003778:	6ba2                	ld	s7,8(sp)
    8000377a:	6161                	addi	sp,sp,80
    8000377c:	8082                	ret

000000008000377e <iupdate>:
{
    8000377e:	1101                	addi	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	e04a                	sd	s2,0(sp)
    80003788:	1000                	addi	s0,sp,32
    8000378a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000378c:	415c                	lw	a5,4(a0)
    8000378e:	0047d79b          	srliw	a5,a5,0x4
    80003792:	00015597          	auipc	a1,0x15
    80003796:	f9e5a583          	lw	a1,-98(a1) # 80018730 <sb+0x18>
    8000379a:	9dbd                	addw	a1,a1,a5
    8000379c:	4108                	lw	a0,0(a0)
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	8a8080e7          	jalr	-1880(ra) # 80003046 <bread>
    800037a6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a8:	05850793          	addi	a5,a0,88
    800037ac:	40c8                	lw	a0,4(s1)
    800037ae:	893d                	andi	a0,a0,15
    800037b0:	051a                	slli	a0,a0,0x6
    800037b2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037b4:	04449703          	lh	a4,68(s1)
    800037b8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037bc:	04649703          	lh	a4,70(s1)
    800037c0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037c4:	04849703          	lh	a4,72(s1)
    800037c8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037cc:	04a49703          	lh	a4,74(s1)
    800037d0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037d4:	44f8                	lw	a4,76(s1)
    800037d6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037d8:	03400613          	li	a2,52
    800037dc:	05048593          	addi	a1,s1,80
    800037e0:	0531                	addi	a0,a0,12
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	55e080e7          	jalr	1374(ra) # 80000d40 <memmove>
  log_write(bp);
    800037ea:	854a                	mv	a0,s2
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	c06080e7          	jalr	-1018(ra) # 800043f2 <log_write>
  brelse(bp);
    800037f4:	854a                	mv	a0,s2
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	980080e7          	jalr	-1664(ra) # 80003176 <brelse>
}
    800037fe:	60e2                	ld	ra,24(sp)
    80003800:	6442                	ld	s0,16(sp)
    80003802:	64a2                	ld	s1,8(sp)
    80003804:	6902                	ld	s2,0(sp)
    80003806:	6105                	addi	sp,sp,32
    80003808:	8082                	ret

000000008000380a <idup>:
{
    8000380a:	1101                	addi	sp,sp,-32
    8000380c:	ec06                	sd	ra,24(sp)
    8000380e:	e822                	sd	s0,16(sp)
    80003810:	e426                	sd	s1,8(sp)
    80003812:	1000                	addi	s0,sp,32
    80003814:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003816:	00015517          	auipc	a0,0x15
    8000381a:	f2250513          	addi	a0,a0,-222 # 80018738 <itable>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	3c6080e7          	jalr	966(ra) # 80000be4 <acquire>
  ip->ref++;
    80003826:	449c                	lw	a5,8(s1)
    80003828:	2785                	addiw	a5,a5,1
    8000382a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000382c:	00015517          	auipc	a0,0x15
    80003830:	f0c50513          	addi	a0,a0,-244 # 80018738 <itable>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	464080e7          	jalr	1124(ra) # 80000c98 <release>
}
    8000383c:	8526                	mv	a0,s1
    8000383e:	60e2                	ld	ra,24(sp)
    80003840:	6442                	ld	s0,16(sp)
    80003842:	64a2                	ld	s1,8(sp)
    80003844:	6105                	addi	sp,sp,32
    80003846:	8082                	ret

0000000080003848 <ilock>:
{
    80003848:	1101                	addi	sp,sp,-32
    8000384a:	ec06                	sd	ra,24(sp)
    8000384c:	e822                	sd	s0,16(sp)
    8000384e:	e426                	sd	s1,8(sp)
    80003850:	e04a                	sd	s2,0(sp)
    80003852:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003854:	c115                	beqz	a0,80003878 <ilock+0x30>
    80003856:	84aa                	mv	s1,a0
    80003858:	451c                	lw	a5,8(a0)
    8000385a:	00f05f63          	blez	a5,80003878 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000385e:	0541                	addi	a0,a0,16
    80003860:	00001097          	auipc	ra,0x1
    80003864:	cb2080e7          	jalr	-846(ra) # 80004512 <acquiresleep>
  if(ip->valid == 0){
    80003868:	40bc                	lw	a5,64(s1)
    8000386a:	cf99                	beqz	a5,80003888 <ilock+0x40>
}
    8000386c:	60e2                	ld	ra,24(sp)
    8000386e:	6442                	ld	s0,16(sp)
    80003870:	64a2                	ld	s1,8(sp)
    80003872:	6902                	ld	s2,0(sp)
    80003874:	6105                	addi	sp,sp,32
    80003876:	8082                	ret
    panic("ilock");
    80003878:	00005517          	auipc	a0,0x5
    8000387c:	d8050513          	addi	a0,a0,-640 # 800085f8 <syscalls+0x198>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	cbe080e7          	jalr	-834(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003888:	40dc                	lw	a5,4(s1)
    8000388a:	0047d79b          	srliw	a5,a5,0x4
    8000388e:	00015597          	auipc	a1,0x15
    80003892:	ea25a583          	lw	a1,-350(a1) # 80018730 <sb+0x18>
    80003896:	9dbd                	addw	a1,a1,a5
    80003898:	4088                	lw	a0,0(s1)
    8000389a:	fffff097          	auipc	ra,0xfffff
    8000389e:	7ac080e7          	jalr	1964(ra) # 80003046 <bread>
    800038a2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038a4:	05850593          	addi	a1,a0,88
    800038a8:	40dc                	lw	a5,4(s1)
    800038aa:	8bbd                	andi	a5,a5,15
    800038ac:	079a                	slli	a5,a5,0x6
    800038ae:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038b0:	00059783          	lh	a5,0(a1)
    800038b4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038b8:	00259783          	lh	a5,2(a1)
    800038bc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038c0:	00459783          	lh	a5,4(a1)
    800038c4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038c8:	00659783          	lh	a5,6(a1)
    800038cc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038d0:	459c                	lw	a5,8(a1)
    800038d2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038d4:	03400613          	li	a2,52
    800038d8:	05b1                	addi	a1,a1,12
    800038da:	05048513          	addi	a0,s1,80
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	462080e7          	jalr	1122(ra) # 80000d40 <memmove>
    brelse(bp);
    800038e6:	854a                	mv	a0,s2
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	88e080e7          	jalr	-1906(ra) # 80003176 <brelse>
    ip->valid = 1;
    800038f0:	4785                	li	a5,1
    800038f2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038f4:	04449783          	lh	a5,68(s1)
    800038f8:	fbb5                	bnez	a5,8000386c <ilock+0x24>
      panic("ilock: no type");
    800038fa:	00005517          	auipc	a0,0x5
    800038fe:	d0650513          	addi	a0,a0,-762 # 80008600 <syscalls+0x1a0>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	c3c080e7          	jalr	-964(ra) # 8000053e <panic>

000000008000390a <iunlock>:
{
    8000390a:	1101                	addi	sp,sp,-32
    8000390c:	ec06                	sd	ra,24(sp)
    8000390e:	e822                	sd	s0,16(sp)
    80003910:	e426                	sd	s1,8(sp)
    80003912:	e04a                	sd	s2,0(sp)
    80003914:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003916:	c905                	beqz	a0,80003946 <iunlock+0x3c>
    80003918:	84aa                	mv	s1,a0
    8000391a:	01050913          	addi	s2,a0,16
    8000391e:	854a                	mv	a0,s2
    80003920:	00001097          	auipc	ra,0x1
    80003924:	c8c080e7          	jalr	-884(ra) # 800045ac <holdingsleep>
    80003928:	cd19                	beqz	a0,80003946 <iunlock+0x3c>
    8000392a:	449c                	lw	a5,8(s1)
    8000392c:	00f05d63          	blez	a5,80003946 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003930:	854a                	mv	a0,s2
    80003932:	00001097          	auipc	ra,0x1
    80003936:	c36080e7          	jalr	-970(ra) # 80004568 <releasesleep>
}
    8000393a:	60e2                	ld	ra,24(sp)
    8000393c:	6442                	ld	s0,16(sp)
    8000393e:	64a2                	ld	s1,8(sp)
    80003940:	6902                	ld	s2,0(sp)
    80003942:	6105                	addi	sp,sp,32
    80003944:	8082                	ret
    panic("iunlock");
    80003946:	00005517          	auipc	a0,0x5
    8000394a:	cca50513          	addi	a0,a0,-822 # 80008610 <syscalls+0x1b0>
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>

0000000080003956 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003956:	7179                	addi	sp,sp,-48
    80003958:	f406                	sd	ra,40(sp)
    8000395a:	f022                	sd	s0,32(sp)
    8000395c:	ec26                	sd	s1,24(sp)
    8000395e:	e84a                	sd	s2,16(sp)
    80003960:	e44e                	sd	s3,8(sp)
    80003962:	e052                	sd	s4,0(sp)
    80003964:	1800                	addi	s0,sp,48
    80003966:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003968:	05050493          	addi	s1,a0,80
    8000396c:	08050913          	addi	s2,a0,128
    80003970:	a021                	j	80003978 <itrunc+0x22>
    80003972:	0491                	addi	s1,s1,4
    80003974:	01248d63          	beq	s1,s2,8000398e <itrunc+0x38>
    if(ip->addrs[i]){
    80003978:	408c                	lw	a1,0(s1)
    8000397a:	dde5                	beqz	a1,80003972 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000397c:	0009a503          	lw	a0,0(s3)
    80003980:	00000097          	auipc	ra,0x0
    80003984:	90c080e7          	jalr	-1780(ra) # 8000328c <bfree>
      ip->addrs[i] = 0;
    80003988:	0004a023          	sw	zero,0(s1)
    8000398c:	b7dd                	j	80003972 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000398e:	0809a583          	lw	a1,128(s3)
    80003992:	e185                	bnez	a1,800039b2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003994:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003998:	854e                	mv	a0,s3
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	de4080e7          	jalr	-540(ra) # 8000377e <iupdate>
}
    800039a2:	70a2                	ld	ra,40(sp)
    800039a4:	7402                	ld	s0,32(sp)
    800039a6:	64e2                	ld	s1,24(sp)
    800039a8:	6942                	ld	s2,16(sp)
    800039aa:	69a2                	ld	s3,8(sp)
    800039ac:	6a02                	ld	s4,0(sp)
    800039ae:	6145                	addi	sp,sp,48
    800039b0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039b2:	0009a503          	lw	a0,0(s3)
    800039b6:	fffff097          	auipc	ra,0xfffff
    800039ba:	690080e7          	jalr	1680(ra) # 80003046 <bread>
    800039be:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039c0:	05850493          	addi	s1,a0,88
    800039c4:	45850913          	addi	s2,a0,1112
    800039c8:	a811                	j	800039dc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039ca:	0009a503          	lw	a0,0(s3)
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	8be080e7          	jalr	-1858(ra) # 8000328c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039d6:	0491                	addi	s1,s1,4
    800039d8:	01248563          	beq	s1,s2,800039e2 <itrunc+0x8c>
      if(a[j])
    800039dc:	408c                	lw	a1,0(s1)
    800039de:	dde5                	beqz	a1,800039d6 <itrunc+0x80>
    800039e0:	b7ed                	j	800039ca <itrunc+0x74>
    brelse(bp);
    800039e2:	8552                	mv	a0,s4
    800039e4:	fffff097          	auipc	ra,0xfffff
    800039e8:	792080e7          	jalr	1938(ra) # 80003176 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039ec:	0809a583          	lw	a1,128(s3)
    800039f0:	0009a503          	lw	a0,0(s3)
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	898080e7          	jalr	-1896(ra) # 8000328c <bfree>
    ip->addrs[NDIRECT] = 0;
    800039fc:	0809a023          	sw	zero,128(s3)
    80003a00:	bf51                	j	80003994 <itrunc+0x3e>

0000000080003a02 <iput>:
{
    80003a02:	1101                	addi	sp,sp,-32
    80003a04:	ec06                	sd	ra,24(sp)
    80003a06:	e822                	sd	s0,16(sp)
    80003a08:	e426                	sd	s1,8(sp)
    80003a0a:	e04a                	sd	s2,0(sp)
    80003a0c:	1000                	addi	s0,sp,32
    80003a0e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a10:	00015517          	auipc	a0,0x15
    80003a14:	d2850513          	addi	a0,a0,-728 # 80018738 <itable>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	1cc080e7          	jalr	460(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a20:	4498                	lw	a4,8(s1)
    80003a22:	4785                	li	a5,1
    80003a24:	02f70363          	beq	a4,a5,80003a4a <iput+0x48>
  ip->ref--;
    80003a28:	449c                	lw	a5,8(s1)
    80003a2a:	37fd                	addiw	a5,a5,-1
    80003a2c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a2e:	00015517          	auipc	a0,0x15
    80003a32:	d0a50513          	addi	a0,a0,-758 # 80018738 <itable>
    80003a36:	ffffd097          	auipc	ra,0xffffd
    80003a3a:	262080e7          	jalr	610(ra) # 80000c98 <release>
}
    80003a3e:	60e2                	ld	ra,24(sp)
    80003a40:	6442                	ld	s0,16(sp)
    80003a42:	64a2                	ld	s1,8(sp)
    80003a44:	6902                	ld	s2,0(sp)
    80003a46:	6105                	addi	sp,sp,32
    80003a48:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a4a:	40bc                	lw	a5,64(s1)
    80003a4c:	dff1                	beqz	a5,80003a28 <iput+0x26>
    80003a4e:	04a49783          	lh	a5,74(s1)
    80003a52:	fbf9                	bnez	a5,80003a28 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a54:	01048913          	addi	s2,s1,16
    80003a58:	854a                	mv	a0,s2
    80003a5a:	00001097          	auipc	ra,0x1
    80003a5e:	ab8080e7          	jalr	-1352(ra) # 80004512 <acquiresleep>
    release(&itable.lock);
    80003a62:	00015517          	auipc	a0,0x15
    80003a66:	cd650513          	addi	a0,a0,-810 # 80018738 <itable>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	22e080e7          	jalr	558(ra) # 80000c98 <release>
    itrunc(ip);
    80003a72:	8526                	mv	a0,s1
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	ee2080e7          	jalr	-286(ra) # 80003956 <itrunc>
    ip->type = 0;
    80003a7c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a80:	8526                	mv	a0,s1
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	cfc080e7          	jalr	-772(ra) # 8000377e <iupdate>
    ip->valid = 0;
    80003a8a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	ad8080e7          	jalr	-1320(ra) # 80004568 <releasesleep>
    acquire(&itable.lock);
    80003a98:	00015517          	auipc	a0,0x15
    80003a9c:	ca050513          	addi	a0,a0,-864 # 80018738 <itable>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	144080e7          	jalr	324(ra) # 80000be4 <acquire>
    80003aa8:	b741                	j	80003a28 <iput+0x26>

0000000080003aaa <iunlockput>:
{
    80003aaa:	1101                	addi	sp,sp,-32
    80003aac:	ec06                	sd	ra,24(sp)
    80003aae:	e822                	sd	s0,16(sp)
    80003ab0:	e426                	sd	s1,8(sp)
    80003ab2:	1000                	addi	s0,sp,32
    80003ab4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ab6:	00000097          	auipc	ra,0x0
    80003aba:	e54080e7          	jalr	-428(ra) # 8000390a <iunlock>
  iput(ip);
    80003abe:	8526                	mv	a0,s1
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	f42080e7          	jalr	-190(ra) # 80003a02 <iput>
}
    80003ac8:	60e2                	ld	ra,24(sp)
    80003aca:	6442                	ld	s0,16(sp)
    80003acc:	64a2                	ld	s1,8(sp)
    80003ace:	6105                	addi	sp,sp,32
    80003ad0:	8082                	ret

0000000080003ad2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ad2:	1141                	addi	sp,sp,-16
    80003ad4:	e422                	sd	s0,8(sp)
    80003ad6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ad8:	411c                	lw	a5,0(a0)
    80003ada:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003adc:	415c                	lw	a5,4(a0)
    80003ade:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ae0:	04451783          	lh	a5,68(a0)
    80003ae4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ae8:	04a51783          	lh	a5,74(a0)
    80003aec:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003af0:	04c56783          	lwu	a5,76(a0)
    80003af4:	e99c                	sd	a5,16(a1)
}
    80003af6:	6422                	ld	s0,8(sp)
    80003af8:	0141                	addi	sp,sp,16
    80003afa:	8082                	ret

0000000080003afc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003afc:	457c                	lw	a5,76(a0)
    80003afe:	0ed7e963          	bltu	a5,a3,80003bf0 <readi+0xf4>
{
    80003b02:	7159                	addi	sp,sp,-112
    80003b04:	f486                	sd	ra,104(sp)
    80003b06:	f0a2                	sd	s0,96(sp)
    80003b08:	eca6                	sd	s1,88(sp)
    80003b0a:	e8ca                	sd	s2,80(sp)
    80003b0c:	e4ce                	sd	s3,72(sp)
    80003b0e:	e0d2                	sd	s4,64(sp)
    80003b10:	fc56                	sd	s5,56(sp)
    80003b12:	f85a                	sd	s6,48(sp)
    80003b14:	f45e                	sd	s7,40(sp)
    80003b16:	f062                	sd	s8,32(sp)
    80003b18:	ec66                	sd	s9,24(sp)
    80003b1a:	e86a                	sd	s10,16(sp)
    80003b1c:	e46e                	sd	s11,8(sp)
    80003b1e:	1880                	addi	s0,sp,112
    80003b20:	8baa                	mv	s7,a0
    80003b22:	8c2e                	mv	s8,a1
    80003b24:	8ab2                	mv	s5,a2
    80003b26:	84b6                	mv	s1,a3
    80003b28:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b2a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b2c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b2e:	0ad76063          	bltu	a4,a3,80003bce <readi+0xd2>
  if(off + n > ip->size)
    80003b32:	00e7f463          	bgeu	a5,a4,80003b3a <readi+0x3e>
    n = ip->size - off;
    80003b36:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3a:	0a0b0963          	beqz	s6,80003bec <readi+0xf0>
    80003b3e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b40:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b44:	5cfd                	li	s9,-1
    80003b46:	a82d                	j	80003b80 <readi+0x84>
    80003b48:	020a1d93          	slli	s11,s4,0x20
    80003b4c:	020ddd93          	srli	s11,s11,0x20
    80003b50:	05890613          	addi	a2,s2,88
    80003b54:	86ee                	mv	a3,s11
    80003b56:	963a                	add	a2,a2,a4
    80003b58:	85d6                	mv	a1,s5
    80003b5a:	8562                	mv	a0,s8
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	9c2080e7          	jalr	-1598(ra) # 8000251e <either_copyout>
    80003b64:	05950d63          	beq	a0,s9,80003bbe <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b68:	854a                	mv	a0,s2
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	60c080e7          	jalr	1548(ra) # 80003176 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b72:	013a09bb          	addw	s3,s4,s3
    80003b76:	009a04bb          	addw	s1,s4,s1
    80003b7a:	9aee                	add	s5,s5,s11
    80003b7c:	0569f763          	bgeu	s3,s6,80003bca <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b80:	000ba903          	lw	s2,0(s7)
    80003b84:	00a4d59b          	srliw	a1,s1,0xa
    80003b88:	855e                	mv	a0,s7
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	8b0080e7          	jalr	-1872(ra) # 8000343a <bmap>
    80003b92:	0005059b          	sext.w	a1,a0
    80003b96:	854a                	mv	a0,s2
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	4ae080e7          	jalr	1198(ra) # 80003046 <bread>
    80003ba0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba2:	3ff4f713          	andi	a4,s1,1023
    80003ba6:	40ed07bb          	subw	a5,s10,a4
    80003baa:	413b06bb          	subw	a3,s6,s3
    80003bae:	8a3e                	mv	s4,a5
    80003bb0:	2781                	sext.w	a5,a5
    80003bb2:	0006861b          	sext.w	a2,a3
    80003bb6:	f8f679e3          	bgeu	a2,a5,80003b48 <readi+0x4c>
    80003bba:	8a36                	mv	s4,a3
    80003bbc:	b771                	j	80003b48 <readi+0x4c>
      brelse(bp);
    80003bbe:	854a                	mv	a0,s2
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	5b6080e7          	jalr	1462(ra) # 80003176 <brelse>
      tot = -1;
    80003bc8:	59fd                	li	s3,-1
  }
  return tot;
    80003bca:	0009851b          	sext.w	a0,s3
}
    80003bce:	70a6                	ld	ra,104(sp)
    80003bd0:	7406                	ld	s0,96(sp)
    80003bd2:	64e6                	ld	s1,88(sp)
    80003bd4:	6946                	ld	s2,80(sp)
    80003bd6:	69a6                	ld	s3,72(sp)
    80003bd8:	6a06                	ld	s4,64(sp)
    80003bda:	7ae2                	ld	s5,56(sp)
    80003bdc:	7b42                	ld	s6,48(sp)
    80003bde:	7ba2                	ld	s7,40(sp)
    80003be0:	7c02                	ld	s8,32(sp)
    80003be2:	6ce2                	ld	s9,24(sp)
    80003be4:	6d42                	ld	s10,16(sp)
    80003be6:	6da2                	ld	s11,8(sp)
    80003be8:	6165                	addi	sp,sp,112
    80003bea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bec:	89da                	mv	s3,s6
    80003bee:	bff1                	j	80003bca <readi+0xce>
    return 0;
    80003bf0:	4501                	li	a0,0
}
    80003bf2:	8082                	ret

0000000080003bf4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bf4:	457c                	lw	a5,76(a0)
    80003bf6:	10d7e863          	bltu	a5,a3,80003d06 <writei+0x112>
{
    80003bfa:	7159                	addi	sp,sp,-112
    80003bfc:	f486                	sd	ra,104(sp)
    80003bfe:	f0a2                	sd	s0,96(sp)
    80003c00:	eca6                	sd	s1,88(sp)
    80003c02:	e8ca                	sd	s2,80(sp)
    80003c04:	e4ce                	sd	s3,72(sp)
    80003c06:	e0d2                	sd	s4,64(sp)
    80003c08:	fc56                	sd	s5,56(sp)
    80003c0a:	f85a                	sd	s6,48(sp)
    80003c0c:	f45e                	sd	s7,40(sp)
    80003c0e:	f062                	sd	s8,32(sp)
    80003c10:	ec66                	sd	s9,24(sp)
    80003c12:	e86a                	sd	s10,16(sp)
    80003c14:	e46e                	sd	s11,8(sp)
    80003c16:	1880                	addi	s0,sp,112
    80003c18:	8b2a                	mv	s6,a0
    80003c1a:	8c2e                	mv	s8,a1
    80003c1c:	8ab2                	mv	s5,a2
    80003c1e:	8936                	mv	s2,a3
    80003c20:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c22:	00e687bb          	addw	a5,a3,a4
    80003c26:	0ed7e263          	bltu	a5,a3,80003d0a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c2a:	00043737          	lui	a4,0x43
    80003c2e:	0ef76063          	bltu	a4,a5,80003d0e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c32:	0c0b8863          	beqz	s7,80003d02 <writei+0x10e>
    80003c36:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c38:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c3c:	5cfd                	li	s9,-1
    80003c3e:	a091                	j	80003c82 <writei+0x8e>
    80003c40:	02099d93          	slli	s11,s3,0x20
    80003c44:	020ddd93          	srli	s11,s11,0x20
    80003c48:	05848513          	addi	a0,s1,88
    80003c4c:	86ee                	mv	a3,s11
    80003c4e:	8656                	mv	a2,s5
    80003c50:	85e2                	mv	a1,s8
    80003c52:	953a                	add	a0,a0,a4
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	920080e7          	jalr	-1760(ra) # 80002574 <either_copyin>
    80003c5c:	07950263          	beq	a0,s9,80003cc0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c60:	8526                	mv	a0,s1
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	790080e7          	jalr	1936(ra) # 800043f2 <log_write>
    brelse(bp);
    80003c6a:	8526                	mv	a0,s1
    80003c6c:	fffff097          	auipc	ra,0xfffff
    80003c70:	50a080e7          	jalr	1290(ra) # 80003176 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c74:	01498a3b          	addw	s4,s3,s4
    80003c78:	0129893b          	addw	s2,s3,s2
    80003c7c:	9aee                	add	s5,s5,s11
    80003c7e:	057a7663          	bgeu	s4,s7,80003cca <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c82:	000b2483          	lw	s1,0(s6)
    80003c86:	00a9559b          	srliw	a1,s2,0xa
    80003c8a:	855a                	mv	a0,s6
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	7ae080e7          	jalr	1966(ra) # 8000343a <bmap>
    80003c94:	0005059b          	sext.w	a1,a0
    80003c98:	8526                	mv	a0,s1
    80003c9a:	fffff097          	auipc	ra,0xfffff
    80003c9e:	3ac080e7          	jalr	940(ra) # 80003046 <bread>
    80003ca2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca4:	3ff97713          	andi	a4,s2,1023
    80003ca8:	40ed07bb          	subw	a5,s10,a4
    80003cac:	414b86bb          	subw	a3,s7,s4
    80003cb0:	89be                	mv	s3,a5
    80003cb2:	2781                	sext.w	a5,a5
    80003cb4:	0006861b          	sext.w	a2,a3
    80003cb8:	f8f674e3          	bgeu	a2,a5,80003c40 <writei+0x4c>
    80003cbc:	89b6                	mv	s3,a3
    80003cbe:	b749                	j	80003c40 <writei+0x4c>
      brelse(bp);
    80003cc0:	8526                	mv	a0,s1
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	4b4080e7          	jalr	1204(ra) # 80003176 <brelse>
  }

  if(off > ip->size)
    80003cca:	04cb2783          	lw	a5,76(s6)
    80003cce:	0127f463          	bgeu	a5,s2,80003cd6 <writei+0xe2>
    ip->size = off;
    80003cd2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cd6:	855a                	mv	a0,s6
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	aa6080e7          	jalr	-1370(ra) # 8000377e <iupdate>

  return tot;
    80003ce0:	000a051b          	sext.w	a0,s4
}
    80003ce4:	70a6                	ld	ra,104(sp)
    80003ce6:	7406                	ld	s0,96(sp)
    80003ce8:	64e6                	ld	s1,88(sp)
    80003cea:	6946                	ld	s2,80(sp)
    80003cec:	69a6                	ld	s3,72(sp)
    80003cee:	6a06                	ld	s4,64(sp)
    80003cf0:	7ae2                	ld	s5,56(sp)
    80003cf2:	7b42                	ld	s6,48(sp)
    80003cf4:	7ba2                	ld	s7,40(sp)
    80003cf6:	7c02                	ld	s8,32(sp)
    80003cf8:	6ce2                	ld	s9,24(sp)
    80003cfa:	6d42                	ld	s10,16(sp)
    80003cfc:	6da2                	ld	s11,8(sp)
    80003cfe:	6165                	addi	sp,sp,112
    80003d00:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d02:	8a5e                	mv	s4,s7
    80003d04:	bfc9                	j	80003cd6 <writei+0xe2>
    return -1;
    80003d06:	557d                	li	a0,-1
}
    80003d08:	8082                	ret
    return -1;
    80003d0a:	557d                	li	a0,-1
    80003d0c:	bfe1                	j	80003ce4 <writei+0xf0>
    return -1;
    80003d0e:	557d                	li	a0,-1
    80003d10:	bfd1                	j	80003ce4 <writei+0xf0>

0000000080003d12 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d12:	1141                	addi	sp,sp,-16
    80003d14:	e406                	sd	ra,8(sp)
    80003d16:	e022                	sd	s0,0(sp)
    80003d18:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d1a:	4639                	li	a2,14
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	09c080e7          	jalr	156(ra) # 80000db8 <strncmp>
}
    80003d24:	60a2                	ld	ra,8(sp)
    80003d26:	6402                	ld	s0,0(sp)
    80003d28:	0141                	addi	sp,sp,16
    80003d2a:	8082                	ret

0000000080003d2c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d2c:	7139                	addi	sp,sp,-64
    80003d2e:	fc06                	sd	ra,56(sp)
    80003d30:	f822                	sd	s0,48(sp)
    80003d32:	f426                	sd	s1,40(sp)
    80003d34:	f04a                	sd	s2,32(sp)
    80003d36:	ec4e                	sd	s3,24(sp)
    80003d38:	e852                	sd	s4,16(sp)
    80003d3a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d3c:	04451703          	lh	a4,68(a0)
    80003d40:	4785                	li	a5,1
    80003d42:	00f71a63          	bne	a4,a5,80003d56 <dirlookup+0x2a>
    80003d46:	892a                	mv	s2,a0
    80003d48:	89ae                	mv	s3,a1
    80003d4a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4c:	457c                	lw	a5,76(a0)
    80003d4e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d50:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d52:	e79d                	bnez	a5,80003d80 <dirlookup+0x54>
    80003d54:	a8a5                	j	80003dcc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d56:	00005517          	auipc	a0,0x5
    80003d5a:	8c250513          	addi	a0,a0,-1854 # 80008618 <syscalls+0x1b8>
    80003d5e:	ffffc097          	auipc	ra,0xffffc
    80003d62:	7e0080e7          	jalr	2016(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d66:	00005517          	auipc	a0,0x5
    80003d6a:	8ca50513          	addi	a0,a0,-1846 # 80008630 <syscalls+0x1d0>
    80003d6e:	ffffc097          	auipc	ra,0xffffc
    80003d72:	7d0080e7          	jalr	2000(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d76:	24c1                	addiw	s1,s1,16
    80003d78:	04c92783          	lw	a5,76(s2)
    80003d7c:	04f4f763          	bgeu	s1,a5,80003dca <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d80:	4741                	li	a4,16
    80003d82:	86a6                	mv	a3,s1
    80003d84:	fc040613          	addi	a2,s0,-64
    80003d88:	4581                	li	a1,0
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	d70080e7          	jalr	-656(ra) # 80003afc <readi>
    80003d94:	47c1                	li	a5,16
    80003d96:	fcf518e3          	bne	a0,a5,80003d66 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d9a:	fc045783          	lhu	a5,-64(s0)
    80003d9e:	dfe1                	beqz	a5,80003d76 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003da0:	fc240593          	addi	a1,s0,-62
    80003da4:	854e                	mv	a0,s3
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	f6c080e7          	jalr	-148(ra) # 80003d12 <namecmp>
    80003dae:	f561                	bnez	a0,80003d76 <dirlookup+0x4a>
      if(poff)
    80003db0:	000a0463          	beqz	s4,80003db8 <dirlookup+0x8c>
        *poff = off;
    80003db4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003db8:	fc045583          	lhu	a1,-64(s0)
    80003dbc:	00092503          	lw	a0,0(s2)
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	754080e7          	jalr	1876(ra) # 80003514 <iget>
    80003dc8:	a011                	j	80003dcc <dirlookup+0xa0>
  return 0;
    80003dca:	4501                	li	a0,0
}
    80003dcc:	70e2                	ld	ra,56(sp)
    80003dce:	7442                	ld	s0,48(sp)
    80003dd0:	74a2                	ld	s1,40(sp)
    80003dd2:	7902                	ld	s2,32(sp)
    80003dd4:	69e2                	ld	s3,24(sp)
    80003dd6:	6a42                	ld	s4,16(sp)
    80003dd8:	6121                	addi	sp,sp,64
    80003dda:	8082                	ret

0000000080003ddc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ddc:	711d                	addi	sp,sp,-96
    80003dde:	ec86                	sd	ra,88(sp)
    80003de0:	e8a2                	sd	s0,80(sp)
    80003de2:	e4a6                	sd	s1,72(sp)
    80003de4:	e0ca                	sd	s2,64(sp)
    80003de6:	fc4e                	sd	s3,56(sp)
    80003de8:	f852                	sd	s4,48(sp)
    80003dea:	f456                	sd	s5,40(sp)
    80003dec:	f05a                	sd	s6,32(sp)
    80003dee:	ec5e                	sd	s7,24(sp)
    80003df0:	e862                	sd	s8,16(sp)
    80003df2:	e466                	sd	s9,8(sp)
    80003df4:	1080                	addi	s0,sp,96
    80003df6:	84aa                	mv	s1,a0
    80003df8:	8b2e                	mv	s6,a1
    80003dfa:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dfc:	00054703          	lbu	a4,0(a0)
    80003e00:	02f00793          	li	a5,47
    80003e04:	02f70363          	beq	a4,a5,80003e2a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e08:	ffffe097          	auipc	ra,0xffffe
    80003e0c:	ba8080e7          	jalr	-1112(ra) # 800019b0 <myproc>
    80003e10:	15053503          	ld	a0,336(a0)
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	9f6080e7          	jalr	-1546(ra) # 8000380a <idup>
    80003e1c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e1e:	02f00913          	li	s2,47
  len = path - s;
    80003e22:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e24:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e26:	4c05                	li	s8,1
    80003e28:	a865                	j	80003ee0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e2a:	4585                	li	a1,1
    80003e2c:	4505                	li	a0,1
    80003e2e:	fffff097          	auipc	ra,0xfffff
    80003e32:	6e6080e7          	jalr	1766(ra) # 80003514 <iget>
    80003e36:	89aa                	mv	s3,a0
    80003e38:	b7dd                	j	80003e1e <namex+0x42>
      iunlockput(ip);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	c6e080e7          	jalr	-914(ra) # 80003aaa <iunlockput>
      return 0;
    80003e44:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e46:	854e                	mv	a0,s3
    80003e48:	60e6                	ld	ra,88(sp)
    80003e4a:	6446                	ld	s0,80(sp)
    80003e4c:	64a6                	ld	s1,72(sp)
    80003e4e:	6906                	ld	s2,64(sp)
    80003e50:	79e2                	ld	s3,56(sp)
    80003e52:	7a42                	ld	s4,48(sp)
    80003e54:	7aa2                	ld	s5,40(sp)
    80003e56:	7b02                	ld	s6,32(sp)
    80003e58:	6be2                	ld	s7,24(sp)
    80003e5a:	6c42                	ld	s8,16(sp)
    80003e5c:	6ca2                	ld	s9,8(sp)
    80003e5e:	6125                	addi	sp,sp,96
    80003e60:	8082                	ret
      iunlock(ip);
    80003e62:	854e                	mv	a0,s3
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	aa6080e7          	jalr	-1370(ra) # 8000390a <iunlock>
      return ip;
    80003e6c:	bfe9                	j	80003e46 <namex+0x6a>
      iunlockput(ip);
    80003e6e:	854e                	mv	a0,s3
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	c3a080e7          	jalr	-966(ra) # 80003aaa <iunlockput>
      return 0;
    80003e78:	89d2                	mv	s3,s4
    80003e7a:	b7f1                	j	80003e46 <namex+0x6a>
  len = path - s;
    80003e7c:	40b48633          	sub	a2,s1,a1
    80003e80:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e84:	094cd463          	bge	s9,s4,80003f0c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e88:	4639                	li	a2,14
    80003e8a:	8556                	mv	a0,s5
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	eb4080e7          	jalr	-332(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e94:	0004c783          	lbu	a5,0(s1)
    80003e98:	01279763          	bne	a5,s2,80003ea6 <namex+0xca>
    path++;
    80003e9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e9e:	0004c783          	lbu	a5,0(s1)
    80003ea2:	ff278de3          	beq	a5,s2,80003e9c <namex+0xc0>
    ilock(ip);
    80003ea6:	854e                	mv	a0,s3
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	9a0080e7          	jalr	-1632(ra) # 80003848 <ilock>
    if(ip->type != T_DIR){
    80003eb0:	04499783          	lh	a5,68(s3)
    80003eb4:	f98793e3          	bne	a5,s8,80003e3a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eb8:	000b0563          	beqz	s6,80003ec2 <namex+0xe6>
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	d3cd                	beqz	a5,80003e62 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ec2:	865e                	mv	a2,s7
    80003ec4:	85d6                	mv	a1,s5
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	e64080e7          	jalr	-412(ra) # 80003d2c <dirlookup>
    80003ed0:	8a2a                	mv	s4,a0
    80003ed2:	dd51                	beqz	a0,80003e6e <namex+0x92>
    iunlockput(ip);
    80003ed4:	854e                	mv	a0,s3
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	bd4080e7          	jalr	-1068(ra) # 80003aaa <iunlockput>
    ip = next;
    80003ede:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ee0:	0004c783          	lbu	a5,0(s1)
    80003ee4:	05279763          	bne	a5,s2,80003f32 <namex+0x156>
    path++;
    80003ee8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	ff278de3          	beq	a5,s2,80003ee8 <namex+0x10c>
  if(*path == 0)
    80003ef2:	c79d                	beqz	a5,80003f20 <namex+0x144>
    path++;
    80003ef4:	85a6                	mv	a1,s1
  len = path - s;
    80003ef6:	8a5e                	mv	s4,s7
    80003ef8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003efa:	01278963          	beq	a5,s2,80003f0c <namex+0x130>
    80003efe:	dfbd                	beqz	a5,80003e7c <namex+0xa0>
    path++;
    80003f00:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f02:	0004c783          	lbu	a5,0(s1)
    80003f06:	ff279ce3          	bne	a5,s2,80003efe <namex+0x122>
    80003f0a:	bf8d                	j	80003e7c <namex+0xa0>
    memmove(name, s, len);
    80003f0c:	2601                	sext.w	a2,a2
    80003f0e:	8556                	mv	a0,s5
    80003f10:	ffffd097          	auipc	ra,0xffffd
    80003f14:	e30080e7          	jalr	-464(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f18:	9a56                	add	s4,s4,s5
    80003f1a:	000a0023          	sb	zero,0(s4)
    80003f1e:	bf9d                	j	80003e94 <namex+0xb8>
  if(nameiparent){
    80003f20:	f20b03e3          	beqz	s6,80003e46 <namex+0x6a>
    iput(ip);
    80003f24:	854e                	mv	a0,s3
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	adc080e7          	jalr	-1316(ra) # 80003a02 <iput>
    return 0;
    80003f2e:	4981                	li	s3,0
    80003f30:	bf19                	j	80003e46 <namex+0x6a>
  if(*path == 0)
    80003f32:	d7fd                	beqz	a5,80003f20 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	85a6                	mv	a1,s1
    80003f3a:	b7d1                	j	80003efe <namex+0x122>

0000000080003f3c <dirlink>:
{
    80003f3c:	7139                	addi	sp,sp,-64
    80003f3e:	fc06                	sd	ra,56(sp)
    80003f40:	f822                	sd	s0,48(sp)
    80003f42:	f426                	sd	s1,40(sp)
    80003f44:	f04a                	sd	s2,32(sp)
    80003f46:	ec4e                	sd	s3,24(sp)
    80003f48:	e852                	sd	s4,16(sp)
    80003f4a:	0080                	addi	s0,sp,64
    80003f4c:	892a                	mv	s2,a0
    80003f4e:	8a2e                	mv	s4,a1
    80003f50:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f52:	4601                	li	a2,0
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	dd8080e7          	jalr	-552(ra) # 80003d2c <dirlookup>
    80003f5c:	e93d                	bnez	a0,80003fd2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5e:	04c92483          	lw	s1,76(s2)
    80003f62:	c49d                	beqz	s1,80003f90 <dirlink+0x54>
    80003f64:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f66:	4741                	li	a4,16
    80003f68:	86a6                	mv	a3,s1
    80003f6a:	fc040613          	addi	a2,s0,-64
    80003f6e:	4581                	li	a1,0
    80003f70:	854a                	mv	a0,s2
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	b8a080e7          	jalr	-1142(ra) # 80003afc <readi>
    80003f7a:	47c1                	li	a5,16
    80003f7c:	06f51163          	bne	a0,a5,80003fde <dirlink+0xa2>
    if(de.inum == 0)
    80003f80:	fc045783          	lhu	a5,-64(s0)
    80003f84:	c791                	beqz	a5,80003f90 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f86:	24c1                	addiw	s1,s1,16
    80003f88:	04c92783          	lw	a5,76(s2)
    80003f8c:	fcf4ede3          	bltu	s1,a5,80003f66 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f90:	4639                	li	a2,14
    80003f92:	85d2                	mv	a1,s4
    80003f94:	fc240513          	addi	a0,s0,-62
    80003f98:	ffffd097          	auipc	ra,0xffffd
    80003f9c:	e5c080e7          	jalr	-420(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fa0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa4:	4741                	li	a4,16
    80003fa6:	86a6                	mv	a3,s1
    80003fa8:	fc040613          	addi	a2,s0,-64
    80003fac:	4581                	li	a1,0
    80003fae:	854a                	mv	a0,s2
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	c44080e7          	jalr	-956(ra) # 80003bf4 <writei>
    80003fb8:	872a                	mv	a4,a0
    80003fba:	47c1                	li	a5,16
  return 0;
    80003fbc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fbe:	02f71863          	bne	a4,a5,80003fee <dirlink+0xb2>
}
    80003fc2:	70e2                	ld	ra,56(sp)
    80003fc4:	7442                	ld	s0,48(sp)
    80003fc6:	74a2                	ld	s1,40(sp)
    80003fc8:	7902                	ld	s2,32(sp)
    80003fca:	69e2                	ld	s3,24(sp)
    80003fcc:	6a42                	ld	s4,16(sp)
    80003fce:	6121                	addi	sp,sp,64
    80003fd0:	8082                	ret
    iput(ip);
    80003fd2:	00000097          	auipc	ra,0x0
    80003fd6:	a30080e7          	jalr	-1488(ra) # 80003a02 <iput>
    return -1;
    80003fda:	557d                	li	a0,-1
    80003fdc:	b7dd                	j	80003fc2 <dirlink+0x86>
      panic("dirlink read");
    80003fde:	00004517          	auipc	a0,0x4
    80003fe2:	66250513          	addi	a0,a0,1634 # 80008640 <syscalls+0x1e0>
    80003fe6:	ffffc097          	auipc	ra,0xffffc
    80003fea:	558080e7          	jalr	1368(ra) # 8000053e <panic>
    panic("dirlink");
    80003fee:	00004517          	auipc	a0,0x4
    80003ff2:	76250513          	addi	a0,a0,1890 # 80008750 <syscalls+0x2f0>
    80003ff6:	ffffc097          	auipc	ra,0xffffc
    80003ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>

0000000080003ffe <namei>:

struct inode*
namei(char *path)
{
    80003ffe:	1101                	addi	sp,sp,-32
    80004000:	ec06                	sd	ra,24(sp)
    80004002:	e822                	sd	s0,16(sp)
    80004004:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004006:	fe040613          	addi	a2,s0,-32
    8000400a:	4581                	li	a1,0
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	dd0080e7          	jalr	-560(ra) # 80003ddc <namex>
}
    80004014:	60e2                	ld	ra,24(sp)
    80004016:	6442                	ld	s0,16(sp)
    80004018:	6105                	addi	sp,sp,32
    8000401a:	8082                	ret

000000008000401c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000401c:	1141                	addi	sp,sp,-16
    8000401e:	e406                	sd	ra,8(sp)
    80004020:	e022                	sd	s0,0(sp)
    80004022:	0800                	addi	s0,sp,16
    80004024:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004026:	4585                	li	a1,1
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	db4080e7          	jalr	-588(ra) # 80003ddc <namex>
}
    80004030:	60a2                	ld	ra,8(sp)
    80004032:	6402                	ld	s0,0(sp)
    80004034:	0141                	addi	sp,sp,16
    80004036:	8082                	ret

0000000080004038 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004038:	1101                	addi	sp,sp,-32
    8000403a:	ec06                	sd	ra,24(sp)
    8000403c:	e822                	sd	s0,16(sp)
    8000403e:	e426                	sd	s1,8(sp)
    80004040:	e04a                	sd	s2,0(sp)
    80004042:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004044:	00016917          	auipc	s2,0x16
    80004048:	19c90913          	addi	s2,s2,412 # 8001a1e0 <log>
    8000404c:	01892583          	lw	a1,24(s2)
    80004050:	02892503          	lw	a0,40(s2)
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	ff2080e7          	jalr	-14(ra) # 80003046 <bread>
    8000405c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000405e:	02c92683          	lw	a3,44(s2)
    80004062:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004064:	02d05763          	blez	a3,80004092 <write_head+0x5a>
    80004068:	00016797          	auipc	a5,0x16
    8000406c:	1a878793          	addi	a5,a5,424 # 8001a210 <log+0x30>
    80004070:	05c50713          	addi	a4,a0,92
    80004074:	36fd                	addiw	a3,a3,-1
    80004076:	1682                	slli	a3,a3,0x20
    80004078:	9281                	srli	a3,a3,0x20
    8000407a:	068a                	slli	a3,a3,0x2
    8000407c:	00016617          	auipc	a2,0x16
    80004080:	19860613          	addi	a2,a2,408 # 8001a214 <log+0x34>
    80004084:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004086:	4390                	lw	a2,0(a5)
    80004088:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000408a:	0791                	addi	a5,a5,4
    8000408c:	0711                	addi	a4,a4,4
    8000408e:	fed79ce3          	bne	a5,a3,80004086 <write_head+0x4e>
  }
  bwrite(buf);
    80004092:	8526                	mv	a0,s1
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	0a4080e7          	jalr	164(ra) # 80003138 <bwrite>
  brelse(buf);
    8000409c:	8526                	mv	a0,s1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	0d8080e7          	jalr	216(ra) # 80003176 <brelse>
}
    800040a6:	60e2                	ld	ra,24(sp)
    800040a8:	6442                	ld	s0,16(sp)
    800040aa:	64a2                	ld	s1,8(sp)
    800040ac:	6902                	ld	s2,0(sp)
    800040ae:	6105                	addi	sp,sp,32
    800040b0:	8082                	ret

00000000800040b2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b2:	00016797          	auipc	a5,0x16
    800040b6:	15a7a783          	lw	a5,346(a5) # 8001a20c <log+0x2c>
    800040ba:	0af05d63          	blez	a5,80004174 <install_trans+0xc2>
{
    800040be:	7139                	addi	sp,sp,-64
    800040c0:	fc06                	sd	ra,56(sp)
    800040c2:	f822                	sd	s0,48(sp)
    800040c4:	f426                	sd	s1,40(sp)
    800040c6:	f04a                	sd	s2,32(sp)
    800040c8:	ec4e                	sd	s3,24(sp)
    800040ca:	e852                	sd	s4,16(sp)
    800040cc:	e456                	sd	s5,8(sp)
    800040ce:	e05a                	sd	s6,0(sp)
    800040d0:	0080                	addi	s0,sp,64
    800040d2:	8b2a                	mv	s6,a0
    800040d4:	00016a97          	auipc	s5,0x16
    800040d8:	13ca8a93          	addi	s5,s5,316 # 8001a210 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040dc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040de:	00016997          	auipc	s3,0x16
    800040e2:	10298993          	addi	s3,s3,258 # 8001a1e0 <log>
    800040e6:	a035                	j	80004112 <install_trans+0x60>
      bunpin(dbuf);
    800040e8:	8526                	mv	a0,s1
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	166080e7          	jalr	358(ra) # 80003250 <bunpin>
    brelse(lbuf);
    800040f2:	854a                	mv	a0,s2
    800040f4:	fffff097          	auipc	ra,0xfffff
    800040f8:	082080e7          	jalr	130(ra) # 80003176 <brelse>
    brelse(dbuf);
    800040fc:	8526                	mv	a0,s1
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	078080e7          	jalr	120(ra) # 80003176 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004106:	2a05                	addiw	s4,s4,1
    80004108:	0a91                	addi	s5,s5,4
    8000410a:	02c9a783          	lw	a5,44(s3)
    8000410e:	04fa5963          	bge	s4,a5,80004160 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004112:	0189a583          	lw	a1,24(s3)
    80004116:	014585bb          	addw	a1,a1,s4
    8000411a:	2585                	addiw	a1,a1,1
    8000411c:	0289a503          	lw	a0,40(s3)
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	f26080e7          	jalr	-218(ra) # 80003046 <bread>
    80004128:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000412a:	000aa583          	lw	a1,0(s5)
    8000412e:	0289a503          	lw	a0,40(s3)
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	f14080e7          	jalr	-236(ra) # 80003046 <bread>
    8000413a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000413c:	40000613          	li	a2,1024
    80004140:	05890593          	addi	a1,s2,88
    80004144:	05850513          	addi	a0,a0,88
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	bf8080e7          	jalr	-1032(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004150:	8526                	mv	a0,s1
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	fe6080e7          	jalr	-26(ra) # 80003138 <bwrite>
    if(recovering == 0)
    8000415a:	f80b1ce3          	bnez	s6,800040f2 <install_trans+0x40>
    8000415e:	b769                	j	800040e8 <install_trans+0x36>
}
    80004160:	70e2                	ld	ra,56(sp)
    80004162:	7442                	ld	s0,48(sp)
    80004164:	74a2                	ld	s1,40(sp)
    80004166:	7902                	ld	s2,32(sp)
    80004168:	69e2                	ld	s3,24(sp)
    8000416a:	6a42                	ld	s4,16(sp)
    8000416c:	6aa2                	ld	s5,8(sp)
    8000416e:	6b02                	ld	s6,0(sp)
    80004170:	6121                	addi	sp,sp,64
    80004172:	8082                	ret
    80004174:	8082                	ret

0000000080004176 <initlog>:
{
    80004176:	7179                	addi	sp,sp,-48
    80004178:	f406                	sd	ra,40(sp)
    8000417a:	f022                	sd	s0,32(sp)
    8000417c:	ec26                	sd	s1,24(sp)
    8000417e:	e84a                	sd	s2,16(sp)
    80004180:	e44e                	sd	s3,8(sp)
    80004182:	1800                	addi	s0,sp,48
    80004184:	892a                	mv	s2,a0
    80004186:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004188:	00016497          	auipc	s1,0x16
    8000418c:	05848493          	addi	s1,s1,88 # 8001a1e0 <log>
    80004190:	00004597          	auipc	a1,0x4
    80004194:	4c058593          	addi	a1,a1,1216 # 80008650 <syscalls+0x1f0>
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	9ba080e7          	jalr	-1606(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041a2:	0149a583          	lw	a1,20(s3)
    800041a6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041a8:	0109a783          	lw	a5,16(s3)
    800041ac:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041ae:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041b2:	854a                	mv	a0,s2
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	e92080e7          	jalr	-366(ra) # 80003046 <bread>
  log.lh.n = lh->n;
    800041bc:	4d3c                	lw	a5,88(a0)
    800041be:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041c0:	02f05563          	blez	a5,800041ea <initlog+0x74>
    800041c4:	05c50713          	addi	a4,a0,92
    800041c8:	00016697          	auipc	a3,0x16
    800041cc:	04868693          	addi	a3,a3,72 # 8001a210 <log+0x30>
    800041d0:	37fd                	addiw	a5,a5,-1
    800041d2:	1782                	slli	a5,a5,0x20
    800041d4:	9381                	srli	a5,a5,0x20
    800041d6:	078a                	slli	a5,a5,0x2
    800041d8:	06050613          	addi	a2,a0,96
    800041dc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041de:	4310                	lw	a2,0(a4)
    800041e0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041e2:	0711                	addi	a4,a4,4
    800041e4:	0691                	addi	a3,a3,4
    800041e6:	fef71ce3          	bne	a4,a5,800041de <initlog+0x68>
  brelse(buf);
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	f8c080e7          	jalr	-116(ra) # 80003176 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041f2:	4505                	li	a0,1
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	ebe080e7          	jalr	-322(ra) # 800040b2 <install_trans>
  log.lh.n = 0;
    800041fc:	00016797          	auipc	a5,0x16
    80004200:	0007a823          	sw	zero,16(a5) # 8001a20c <log+0x2c>
  write_head(); // clear the log
    80004204:	00000097          	auipc	ra,0x0
    80004208:	e34080e7          	jalr	-460(ra) # 80004038 <write_head>
}
    8000420c:	70a2                	ld	ra,40(sp)
    8000420e:	7402                	ld	s0,32(sp)
    80004210:	64e2                	ld	s1,24(sp)
    80004212:	6942                	ld	s2,16(sp)
    80004214:	69a2                	ld	s3,8(sp)
    80004216:	6145                	addi	sp,sp,48
    80004218:	8082                	ret

000000008000421a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000421a:	1101                	addi	sp,sp,-32
    8000421c:	ec06                	sd	ra,24(sp)
    8000421e:	e822                	sd	s0,16(sp)
    80004220:	e426                	sd	s1,8(sp)
    80004222:	e04a                	sd	s2,0(sp)
    80004224:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004226:	00016517          	auipc	a0,0x16
    8000422a:	fba50513          	addi	a0,a0,-70 # 8001a1e0 <log>
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	9b6080e7          	jalr	-1610(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004236:	00016497          	auipc	s1,0x16
    8000423a:	faa48493          	addi	s1,s1,-86 # 8001a1e0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000423e:	4979                	li	s2,30
    80004240:	a039                	j	8000424e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004242:	85a6                	mv	a1,s1
    80004244:	8526                	mv	a0,s1
    80004246:	ffffe097          	auipc	ra,0xffffe
    8000424a:	f14080e7          	jalr	-236(ra) # 8000215a <sleep>
    if(log.committing){
    8000424e:	50dc                	lw	a5,36(s1)
    80004250:	fbed                	bnez	a5,80004242 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004252:	509c                	lw	a5,32(s1)
    80004254:	0017871b          	addiw	a4,a5,1
    80004258:	0007069b          	sext.w	a3,a4
    8000425c:	0027179b          	slliw	a5,a4,0x2
    80004260:	9fb9                	addw	a5,a5,a4
    80004262:	0017979b          	slliw	a5,a5,0x1
    80004266:	54d8                	lw	a4,44(s1)
    80004268:	9fb9                	addw	a5,a5,a4
    8000426a:	00f95963          	bge	s2,a5,8000427c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000426e:	85a6                	mv	a1,s1
    80004270:	8526                	mv	a0,s1
    80004272:	ffffe097          	auipc	ra,0xffffe
    80004276:	ee8080e7          	jalr	-280(ra) # 8000215a <sleep>
    8000427a:	bfd1                	j	8000424e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000427c:	00016517          	auipc	a0,0x16
    80004280:	f6450513          	addi	a0,a0,-156 # 8001a1e0 <log>
    80004284:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004286:	ffffd097          	auipc	ra,0xffffd
    8000428a:	a12080e7          	jalr	-1518(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000428e:	60e2                	ld	ra,24(sp)
    80004290:	6442                	ld	s0,16(sp)
    80004292:	64a2                	ld	s1,8(sp)
    80004294:	6902                	ld	s2,0(sp)
    80004296:	6105                	addi	sp,sp,32
    80004298:	8082                	ret

000000008000429a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000429a:	7139                	addi	sp,sp,-64
    8000429c:	fc06                	sd	ra,56(sp)
    8000429e:	f822                	sd	s0,48(sp)
    800042a0:	f426                	sd	s1,40(sp)
    800042a2:	f04a                	sd	s2,32(sp)
    800042a4:	ec4e                	sd	s3,24(sp)
    800042a6:	e852                	sd	s4,16(sp)
    800042a8:	e456                	sd	s5,8(sp)
    800042aa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ac:	00016497          	auipc	s1,0x16
    800042b0:	f3448493          	addi	s1,s1,-204 # 8001a1e0 <log>
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	92e080e7          	jalr	-1746(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042be:	509c                	lw	a5,32(s1)
    800042c0:	37fd                	addiw	a5,a5,-1
    800042c2:	0007891b          	sext.w	s2,a5
    800042c6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042c8:	50dc                	lw	a5,36(s1)
    800042ca:	efb9                	bnez	a5,80004328 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042cc:	06091663          	bnez	s2,80004338 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042d0:	00016497          	auipc	s1,0x16
    800042d4:	f1048493          	addi	s1,s1,-240 # 8001a1e0 <log>
    800042d8:	4785                	li	a5,1
    800042da:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042dc:	8526                	mv	a0,s1
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	9ba080e7          	jalr	-1606(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042e6:	54dc                	lw	a5,44(s1)
    800042e8:	06f04763          	bgtz	a5,80004356 <end_op+0xbc>
    acquire(&log.lock);
    800042ec:	00016497          	auipc	s1,0x16
    800042f0:	ef448493          	addi	s1,s1,-268 # 8001a1e0 <log>
    800042f4:	8526                	mv	a0,s1
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	8ee080e7          	jalr	-1810(ra) # 80000be4 <acquire>
    log.committing = 0;
    800042fe:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004302:	8526                	mv	a0,s1
    80004304:	ffffe097          	auipc	ra,0xffffe
    80004308:	fe2080e7          	jalr	-30(ra) # 800022e6 <wakeup>
    release(&log.lock);
    8000430c:	8526                	mv	a0,s1
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	98a080e7          	jalr	-1654(ra) # 80000c98 <release>
}
    80004316:	70e2                	ld	ra,56(sp)
    80004318:	7442                	ld	s0,48(sp)
    8000431a:	74a2                	ld	s1,40(sp)
    8000431c:	7902                	ld	s2,32(sp)
    8000431e:	69e2                	ld	s3,24(sp)
    80004320:	6a42                	ld	s4,16(sp)
    80004322:	6aa2                	ld	s5,8(sp)
    80004324:	6121                	addi	sp,sp,64
    80004326:	8082                	ret
    panic("log.committing");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	33050513          	addi	a0,a0,816 # 80008658 <syscalls+0x1f8>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	20e080e7          	jalr	526(ra) # 8000053e <panic>
    wakeup(&log);
    80004338:	00016497          	auipc	s1,0x16
    8000433c:	ea848493          	addi	s1,s1,-344 # 8001a1e0 <log>
    80004340:	8526                	mv	a0,s1
    80004342:	ffffe097          	auipc	ra,0xffffe
    80004346:	fa4080e7          	jalr	-92(ra) # 800022e6 <wakeup>
  release(&log.lock);
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
  if(do_commit){
    80004354:	b7c9                	j	80004316 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004356:	00016a97          	auipc	s5,0x16
    8000435a:	ebaa8a93          	addi	s5,s5,-326 # 8001a210 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000435e:	00016a17          	auipc	s4,0x16
    80004362:	e82a0a13          	addi	s4,s4,-382 # 8001a1e0 <log>
    80004366:	018a2583          	lw	a1,24(s4)
    8000436a:	012585bb          	addw	a1,a1,s2
    8000436e:	2585                	addiw	a1,a1,1
    80004370:	028a2503          	lw	a0,40(s4)
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	cd2080e7          	jalr	-814(ra) # 80003046 <bread>
    8000437c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000437e:	000aa583          	lw	a1,0(s5)
    80004382:	028a2503          	lw	a0,40(s4)
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	cc0080e7          	jalr	-832(ra) # 80003046 <bread>
    8000438e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004390:	40000613          	li	a2,1024
    80004394:	05850593          	addi	a1,a0,88
    80004398:	05848513          	addi	a0,s1,88
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	9a4080e7          	jalr	-1628(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043a4:	8526                	mv	a0,s1
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	d92080e7          	jalr	-622(ra) # 80003138 <bwrite>
    brelse(from);
    800043ae:	854e                	mv	a0,s3
    800043b0:	fffff097          	auipc	ra,0xfffff
    800043b4:	dc6080e7          	jalr	-570(ra) # 80003176 <brelse>
    brelse(to);
    800043b8:	8526                	mv	a0,s1
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	dbc080e7          	jalr	-580(ra) # 80003176 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c2:	2905                	addiw	s2,s2,1
    800043c4:	0a91                	addi	s5,s5,4
    800043c6:	02ca2783          	lw	a5,44(s4)
    800043ca:	f8f94ee3          	blt	s2,a5,80004366 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043ce:	00000097          	auipc	ra,0x0
    800043d2:	c6a080e7          	jalr	-918(ra) # 80004038 <write_head>
    install_trans(0); // Now install writes to home locations
    800043d6:	4501                	li	a0,0
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	cda080e7          	jalr	-806(ra) # 800040b2 <install_trans>
    log.lh.n = 0;
    800043e0:	00016797          	auipc	a5,0x16
    800043e4:	e207a623          	sw	zero,-468(a5) # 8001a20c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	c50080e7          	jalr	-944(ra) # 80004038 <write_head>
    800043f0:	bdf5                	j	800042ec <end_op+0x52>

00000000800043f2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043f2:	1101                	addi	sp,sp,-32
    800043f4:	ec06                	sd	ra,24(sp)
    800043f6:	e822                	sd	s0,16(sp)
    800043f8:	e426                	sd	s1,8(sp)
    800043fa:	e04a                	sd	s2,0(sp)
    800043fc:	1000                	addi	s0,sp,32
    800043fe:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004400:	00016917          	auipc	s2,0x16
    80004404:	de090913          	addi	s2,s2,-544 # 8001a1e0 <log>
    80004408:	854a                	mv	a0,s2
    8000440a:	ffffc097          	auipc	ra,0xffffc
    8000440e:	7da080e7          	jalr	2010(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004412:	02c92603          	lw	a2,44(s2)
    80004416:	47f5                	li	a5,29
    80004418:	06c7c563          	blt	a5,a2,80004482 <log_write+0x90>
    8000441c:	00016797          	auipc	a5,0x16
    80004420:	de07a783          	lw	a5,-544(a5) # 8001a1fc <log+0x1c>
    80004424:	37fd                	addiw	a5,a5,-1
    80004426:	04f65e63          	bge	a2,a5,80004482 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000442a:	00016797          	auipc	a5,0x16
    8000442e:	dd67a783          	lw	a5,-554(a5) # 8001a200 <log+0x20>
    80004432:	06f05063          	blez	a5,80004492 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004436:	4781                	li	a5,0
    80004438:	06c05563          	blez	a2,800044a2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000443c:	44cc                	lw	a1,12(s1)
    8000443e:	00016717          	auipc	a4,0x16
    80004442:	dd270713          	addi	a4,a4,-558 # 8001a210 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004446:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004448:	4314                	lw	a3,0(a4)
    8000444a:	04b68c63          	beq	a3,a1,800044a2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000444e:	2785                	addiw	a5,a5,1
    80004450:	0711                	addi	a4,a4,4
    80004452:	fef61be3          	bne	a2,a5,80004448 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004456:	0621                	addi	a2,a2,8
    80004458:	060a                	slli	a2,a2,0x2
    8000445a:	00016797          	auipc	a5,0x16
    8000445e:	d8678793          	addi	a5,a5,-634 # 8001a1e0 <log>
    80004462:	963e                	add	a2,a2,a5
    80004464:	44dc                	lw	a5,12(s1)
    80004466:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004468:	8526                	mv	a0,s1
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	daa080e7          	jalr	-598(ra) # 80003214 <bpin>
    log.lh.n++;
    80004472:	00016717          	auipc	a4,0x16
    80004476:	d6e70713          	addi	a4,a4,-658 # 8001a1e0 <log>
    8000447a:	575c                	lw	a5,44(a4)
    8000447c:	2785                	addiw	a5,a5,1
    8000447e:	d75c                	sw	a5,44(a4)
    80004480:	a835                	j	800044bc <log_write+0xca>
    panic("too big a transaction");
    80004482:	00004517          	auipc	a0,0x4
    80004486:	1e650513          	addi	a0,a0,486 # 80008668 <syscalls+0x208>
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004492:	00004517          	auipc	a0,0x4
    80004496:	1ee50513          	addi	a0,a0,494 # 80008680 <syscalls+0x220>
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044a2:	00878713          	addi	a4,a5,8
    800044a6:	00271693          	slli	a3,a4,0x2
    800044aa:	00016717          	auipc	a4,0x16
    800044ae:	d3670713          	addi	a4,a4,-714 # 8001a1e0 <log>
    800044b2:	9736                	add	a4,a4,a3
    800044b4:	44d4                	lw	a3,12(s1)
    800044b6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044b8:	faf608e3          	beq	a2,a5,80004468 <log_write+0x76>
  }
  release(&log.lock);
    800044bc:	00016517          	auipc	a0,0x16
    800044c0:	d2450513          	addi	a0,a0,-732 # 8001a1e0 <log>
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	7d4080e7          	jalr	2004(ra) # 80000c98 <release>
}
    800044cc:	60e2                	ld	ra,24(sp)
    800044ce:	6442                	ld	s0,16(sp)
    800044d0:	64a2                	ld	s1,8(sp)
    800044d2:	6902                	ld	s2,0(sp)
    800044d4:	6105                	addi	sp,sp,32
    800044d6:	8082                	ret

00000000800044d8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044d8:	1101                	addi	sp,sp,-32
    800044da:	ec06                	sd	ra,24(sp)
    800044dc:	e822                	sd	s0,16(sp)
    800044de:	e426                	sd	s1,8(sp)
    800044e0:	e04a                	sd	s2,0(sp)
    800044e2:	1000                	addi	s0,sp,32
    800044e4:	84aa                	mv	s1,a0
    800044e6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044e8:	00004597          	auipc	a1,0x4
    800044ec:	1b858593          	addi	a1,a1,440 # 800086a0 <syscalls+0x240>
    800044f0:	0521                	addi	a0,a0,8
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	662080e7          	jalr	1634(ra) # 80000b54 <initlock>
  lk->name = name;
    800044fa:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044fe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004502:	0204a423          	sw	zero,40(s1)
}
    80004506:	60e2                	ld	ra,24(sp)
    80004508:	6442                	ld	s0,16(sp)
    8000450a:	64a2                	ld	s1,8(sp)
    8000450c:	6902                	ld	s2,0(sp)
    8000450e:	6105                	addi	sp,sp,32
    80004510:	8082                	ret

0000000080004512 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004512:	1101                	addi	sp,sp,-32
    80004514:	ec06                	sd	ra,24(sp)
    80004516:	e822                	sd	s0,16(sp)
    80004518:	e426                	sd	s1,8(sp)
    8000451a:	e04a                	sd	s2,0(sp)
    8000451c:	1000                	addi	s0,sp,32
    8000451e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004520:	00850913          	addi	s2,a0,8
    80004524:	854a                	mv	a0,s2
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	6be080e7          	jalr	1726(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000452e:	409c                	lw	a5,0(s1)
    80004530:	cb89                	beqz	a5,80004542 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004532:	85ca                	mv	a1,s2
    80004534:	8526                	mv	a0,s1
    80004536:	ffffe097          	auipc	ra,0xffffe
    8000453a:	c24080e7          	jalr	-988(ra) # 8000215a <sleep>
  while (lk->locked) {
    8000453e:	409c                	lw	a5,0(s1)
    80004540:	fbed                	bnez	a5,80004532 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004542:	4785                	li	a5,1
    80004544:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004546:	ffffd097          	auipc	ra,0xffffd
    8000454a:	46a080e7          	jalr	1130(ra) # 800019b0 <myproc>
    8000454e:	591c                	lw	a5,48(a0)
    80004550:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004552:	854a                	mv	a0,s2
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	744080e7          	jalr	1860(ra) # 80000c98 <release>
}
    8000455c:	60e2                	ld	ra,24(sp)
    8000455e:	6442                	ld	s0,16(sp)
    80004560:	64a2                	ld	s1,8(sp)
    80004562:	6902                	ld	s2,0(sp)
    80004564:	6105                	addi	sp,sp,32
    80004566:	8082                	ret

0000000080004568 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	e04a                	sd	s2,0(sp)
    80004572:	1000                	addi	s0,sp,32
    80004574:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004576:	00850913          	addi	s2,a0,8
    8000457a:	854a                	mv	a0,s2
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	668080e7          	jalr	1640(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004584:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004588:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000458c:	8526                	mv	a0,s1
    8000458e:	ffffe097          	auipc	ra,0xffffe
    80004592:	d58080e7          	jalr	-680(ra) # 800022e6 <wakeup>
  release(&lk->lk);
    80004596:	854a                	mv	a0,s2
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	700080e7          	jalr	1792(ra) # 80000c98 <release>
}
    800045a0:	60e2                	ld	ra,24(sp)
    800045a2:	6442                	ld	s0,16(sp)
    800045a4:	64a2                	ld	s1,8(sp)
    800045a6:	6902                	ld	s2,0(sp)
    800045a8:	6105                	addi	sp,sp,32
    800045aa:	8082                	ret

00000000800045ac <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045ac:	7179                	addi	sp,sp,-48
    800045ae:	f406                	sd	ra,40(sp)
    800045b0:	f022                	sd	s0,32(sp)
    800045b2:	ec26                	sd	s1,24(sp)
    800045b4:	e84a                	sd	s2,16(sp)
    800045b6:	e44e                	sd	s3,8(sp)
    800045b8:	1800                	addi	s0,sp,48
    800045ba:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045bc:	00850913          	addi	s2,a0,8
    800045c0:	854a                	mv	a0,s2
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	622080e7          	jalr	1570(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ca:	409c                	lw	a5,0(s1)
    800045cc:	ef99                	bnez	a5,800045ea <holdingsleep+0x3e>
    800045ce:	4481                	li	s1,0
  release(&lk->lk);
    800045d0:	854a                	mv	a0,s2
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6c6080e7          	jalr	1734(ra) # 80000c98 <release>
  return r;
}
    800045da:	8526                	mv	a0,s1
    800045dc:	70a2                	ld	ra,40(sp)
    800045de:	7402                	ld	s0,32(sp)
    800045e0:	64e2                	ld	s1,24(sp)
    800045e2:	6942                	ld	s2,16(sp)
    800045e4:	69a2                	ld	s3,8(sp)
    800045e6:	6145                	addi	sp,sp,48
    800045e8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ea:	0284a983          	lw	s3,40(s1)
    800045ee:	ffffd097          	auipc	ra,0xffffd
    800045f2:	3c2080e7          	jalr	962(ra) # 800019b0 <myproc>
    800045f6:	5904                	lw	s1,48(a0)
    800045f8:	413484b3          	sub	s1,s1,s3
    800045fc:	0014b493          	seqz	s1,s1
    80004600:	bfc1                	j	800045d0 <holdingsleep+0x24>

0000000080004602 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004602:	1141                	addi	sp,sp,-16
    80004604:	e406                	sd	ra,8(sp)
    80004606:	e022                	sd	s0,0(sp)
    80004608:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000460a:	00004597          	auipc	a1,0x4
    8000460e:	0a658593          	addi	a1,a1,166 # 800086b0 <syscalls+0x250>
    80004612:	00016517          	auipc	a0,0x16
    80004616:	d1650513          	addi	a0,a0,-746 # 8001a328 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	53a080e7          	jalr	1338(ra) # 80000b54 <initlock>
}
    80004622:	60a2                	ld	ra,8(sp)
    80004624:	6402                	ld	s0,0(sp)
    80004626:	0141                	addi	sp,sp,16
    80004628:	8082                	ret

000000008000462a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000462a:	1101                	addi	sp,sp,-32
    8000462c:	ec06                	sd	ra,24(sp)
    8000462e:	e822                	sd	s0,16(sp)
    80004630:	e426                	sd	s1,8(sp)
    80004632:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004634:	00016517          	auipc	a0,0x16
    80004638:	cf450513          	addi	a0,a0,-780 # 8001a328 <ftable>
    8000463c:	ffffc097          	auipc	ra,0xffffc
    80004640:	5a8080e7          	jalr	1448(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004644:	00016497          	auipc	s1,0x16
    80004648:	cfc48493          	addi	s1,s1,-772 # 8001a340 <ftable+0x18>
    8000464c:	00017717          	auipc	a4,0x17
    80004650:	c9470713          	addi	a4,a4,-876 # 8001b2e0 <ftable+0xfb8>
    if(f->ref == 0){
    80004654:	40dc                	lw	a5,4(s1)
    80004656:	cf99                	beqz	a5,80004674 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004658:	02848493          	addi	s1,s1,40
    8000465c:	fee49ce3          	bne	s1,a4,80004654 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004660:	00016517          	auipc	a0,0x16
    80004664:	cc850513          	addi	a0,a0,-824 # 8001a328 <ftable>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
  return 0;
    80004670:	4481                	li	s1,0
    80004672:	a819                	j	80004688 <filealloc+0x5e>
      f->ref = 1;
    80004674:	4785                	li	a5,1
    80004676:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004678:	00016517          	auipc	a0,0x16
    8000467c:	cb050513          	addi	a0,a0,-848 # 8001a328 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	618080e7          	jalr	1560(ra) # 80000c98 <release>
}
    80004688:	8526                	mv	a0,s1
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	64a2                	ld	s1,8(sp)
    80004690:	6105                	addi	sp,sp,32
    80004692:	8082                	ret

0000000080004694 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004694:	1101                	addi	sp,sp,-32
    80004696:	ec06                	sd	ra,24(sp)
    80004698:	e822                	sd	s0,16(sp)
    8000469a:	e426                	sd	s1,8(sp)
    8000469c:	1000                	addi	s0,sp,32
    8000469e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046a0:	00016517          	auipc	a0,0x16
    800046a4:	c8850513          	addi	a0,a0,-888 # 8001a328 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	53c080e7          	jalr	1340(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046b0:	40dc                	lw	a5,4(s1)
    800046b2:	02f05263          	blez	a5,800046d6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046b6:	2785                	addiw	a5,a5,1
    800046b8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046ba:	00016517          	auipc	a0,0x16
    800046be:	c6e50513          	addi	a0,a0,-914 # 8001a328 <ftable>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
  return f;
}
    800046ca:	8526                	mv	a0,s1
    800046cc:	60e2                	ld	ra,24(sp)
    800046ce:	6442                	ld	s0,16(sp)
    800046d0:	64a2                	ld	s1,8(sp)
    800046d2:	6105                	addi	sp,sp,32
    800046d4:	8082                	ret
    panic("filedup");
    800046d6:	00004517          	auipc	a0,0x4
    800046da:	fe250513          	addi	a0,a0,-30 # 800086b8 <syscalls+0x258>
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	e60080e7          	jalr	-416(ra) # 8000053e <panic>

00000000800046e6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046e6:	7139                	addi	sp,sp,-64
    800046e8:	fc06                	sd	ra,56(sp)
    800046ea:	f822                	sd	s0,48(sp)
    800046ec:	f426                	sd	s1,40(sp)
    800046ee:	f04a                	sd	s2,32(sp)
    800046f0:	ec4e                	sd	s3,24(sp)
    800046f2:	e852                	sd	s4,16(sp)
    800046f4:	e456                	sd	s5,8(sp)
    800046f6:	0080                	addi	s0,sp,64
    800046f8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046fa:	00016517          	auipc	a0,0x16
    800046fe:	c2e50513          	addi	a0,a0,-978 # 8001a328 <ftable>
    80004702:	ffffc097          	auipc	ra,0xffffc
    80004706:	4e2080e7          	jalr	1250(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000470a:	40dc                	lw	a5,4(s1)
    8000470c:	06f05163          	blez	a5,8000476e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004710:	37fd                	addiw	a5,a5,-1
    80004712:	0007871b          	sext.w	a4,a5
    80004716:	c0dc                	sw	a5,4(s1)
    80004718:	06e04363          	bgtz	a4,8000477e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000471c:	0004a903          	lw	s2,0(s1)
    80004720:	0094ca83          	lbu	s5,9(s1)
    80004724:	0104ba03          	ld	s4,16(s1)
    80004728:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000472c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004730:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004734:	00016517          	auipc	a0,0x16
    80004738:	bf450513          	addi	a0,a0,-1036 # 8001a328 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	55c080e7          	jalr	1372(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004744:	4785                	li	a5,1
    80004746:	04f90d63          	beq	s2,a5,800047a0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000474a:	3979                	addiw	s2,s2,-2
    8000474c:	4785                	li	a5,1
    8000474e:	0527e063          	bltu	a5,s2,8000478e <fileclose+0xa8>
    begin_op();
    80004752:	00000097          	auipc	ra,0x0
    80004756:	ac8080e7          	jalr	-1336(ra) # 8000421a <begin_op>
    iput(ff.ip);
    8000475a:	854e                	mv	a0,s3
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	2a6080e7          	jalr	678(ra) # 80003a02 <iput>
    end_op();
    80004764:	00000097          	auipc	ra,0x0
    80004768:	b36080e7          	jalr	-1226(ra) # 8000429a <end_op>
    8000476c:	a00d                	j	8000478e <fileclose+0xa8>
    panic("fileclose");
    8000476e:	00004517          	auipc	a0,0x4
    80004772:	f5250513          	addi	a0,a0,-174 # 800086c0 <syscalls+0x260>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	dc8080e7          	jalr	-568(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000477e:	00016517          	auipc	a0,0x16
    80004782:	baa50513          	addi	a0,a0,-1110 # 8001a328 <ftable>
    80004786:	ffffc097          	auipc	ra,0xffffc
    8000478a:	512080e7          	jalr	1298(ra) # 80000c98 <release>
  }
}
    8000478e:	70e2                	ld	ra,56(sp)
    80004790:	7442                	ld	s0,48(sp)
    80004792:	74a2                	ld	s1,40(sp)
    80004794:	7902                	ld	s2,32(sp)
    80004796:	69e2                	ld	s3,24(sp)
    80004798:	6a42                	ld	s4,16(sp)
    8000479a:	6aa2                	ld	s5,8(sp)
    8000479c:	6121                	addi	sp,sp,64
    8000479e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047a0:	85d6                	mv	a1,s5
    800047a2:	8552                	mv	a0,s4
    800047a4:	00000097          	auipc	ra,0x0
    800047a8:	34c080e7          	jalr	844(ra) # 80004af0 <pipeclose>
    800047ac:	b7cd                	j	8000478e <fileclose+0xa8>

00000000800047ae <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047ae:	715d                	addi	sp,sp,-80
    800047b0:	e486                	sd	ra,72(sp)
    800047b2:	e0a2                	sd	s0,64(sp)
    800047b4:	fc26                	sd	s1,56(sp)
    800047b6:	f84a                	sd	s2,48(sp)
    800047b8:	f44e                	sd	s3,40(sp)
    800047ba:	0880                	addi	s0,sp,80
    800047bc:	84aa                	mv	s1,a0
    800047be:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047c0:	ffffd097          	auipc	ra,0xffffd
    800047c4:	1f0080e7          	jalr	496(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047c8:	409c                	lw	a5,0(s1)
    800047ca:	37f9                	addiw	a5,a5,-2
    800047cc:	4705                	li	a4,1
    800047ce:	04f76763          	bltu	a4,a5,8000481c <filestat+0x6e>
    800047d2:	892a                	mv	s2,a0
    ilock(f->ip);
    800047d4:	6c88                	ld	a0,24(s1)
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	072080e7          	jalr	114(ra) # 80003848 <ilock>
    stati(f->ip, &st);
    800047de:	fb840593          	addi	a1,s0,-72
    800047e2:	6c88                	ld	a0,24(s1)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	2ee080e7          	jalr	750(ra) # 80003ad2 <stati>
    iunlock(f->ip);
    800047ec:	6c88                	ld	a0,24(s1)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	11c080e7          	jalr	284(ra) # 8000390a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047f6:	46e1                	li	a3,24
    800047f8:	fb840613          	addi	a2,s0,-72
    800047fc:	85ce                	mv	a1,s3
    800047fe:	05093503          	ld	a0,80(s2)
    80004802:	ffffd097          	auipc	ra,0xffffd
    80004806:	e70080e7          	jalr	-400(ra) # 80001672 <copyout>
    8000480a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000480e:	60a6                	ld	ra,72(sp)
    80004810:	6406                	ld	s0,64(sp)
    80004812:	74e2                	ld	s1,56(sp)
    80004814:	7942                	ld	s2,48(sp)
    80004816:	79a2                	ld	s3,40(sp)
    80004818:	6161                	addi	sp,sp,80
    8000481a:	8082                	ret
  return -1;
    8000481c:	557d                	li	a0,-1
    8000481e:	bfc5                	j	8000480e <filestat+0x60>

0000000080004820 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004820:	7179                	addi	sp,sp,-48
    80004822:	f406                	sd	ra,40(sp)
    80004824:	f022                	sd	s0,32(sp)
    80004826:	ec26                	sd	s1,24(sp)
    80004828:	e84a                	sd	s2,16(sp)
    8000482a:	e44e                	sd	s3,8(sp)
    8000482c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000482e:	00854783          	lbu	a5,8(a0)
    80004832:	c3d5                	beqz	a5,800048d6 <fileread+0xb6>
    80004834:	84aa                	mv	s1,a0
    80004836:	89ae                	mv	s3,a1
    80004838:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000483a:	411c                	lw	a5,0(a0)
    8000483c:	4705                	li	a4,1
    8000483e:	04e78963          	beq	a5,a4,80004890 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004842:	470d                	li	a4,3
    80004844:	04e78d63          	beq	a5,a4,8000489e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004848:	4709                	li	a4,2
    8000484a:	06e79e63          	bne	a5,a4,800048c6 <fileread+0xa6>
    ilock(f->ip);
    8000484e:	6d08                	ld	a0,24(a0)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	ff8080e7          	jalr	-8(ra) # 80003848 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004858:	874a                	mv	a4,s2
    8000485a:	5094                	lw	a3,32(s1)
    8000485c:	864e                	mv	a2,s3
    8000485e:	4585                	li	a1,1
    80004860:	6c88                	ld	a0,24(s1)
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	29a080e7          	jalr	666(ra) # 80003afc <readi>
    8000486a:	892a                	mv	s2,a0
    8000486c:	00a05563          	blez	a0,80004876 <fileread+0x56>
      f->off += r;
    80004870:	509c                	lw	a5,32(s1)
    80004872:	9fa9                	addw	a5,a5,a0
    80004874:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004876:	6c88                	ld	a0,24(s1)
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	092080e7          	jalr	146(ra) # 8000390a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004880:	854a                	mv	a0,s2
    80004882:	70a2                	ld	ra,40(sp)
    80004884:	7402                	ld	s0,32(sp)
    80004886:	64e2                	ld	s1,24(sp)
    80004888:	6942                	ld	s2,16(sp)
    8000488a:	69a2                	ld	s3,8(sp)
    8000488c:	6145                	addi	sp,sp,48
    8000488e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004890:	6908                	ld	a0,16(a0)
    80004892:	00000097          	auipc	ra,0x0
    80004896:	3c8080e7          	jalr	968(ra) # 80004c5a <piperead>
    8000489a:	892a                	mv	s2,a0
    8000489c:	b7d5                	j	80004880 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000489e:	02451783          	lh	a5,36(a0)
    800048a2:	03079693          	slli	a3,a5,0x30
    800048a6:	92c1                	srli	a3,a3,0x30
    800048a8:	4725                	li	a4,9
    800048aa:	02d76863          	bltu	a4,a3,800048da <fileread+0xba>
    800048ae:	0792                	slli	a5,a5,0x4
    800048b0:	00016717          	auipc	a4,0x16
    800048b4:	9d870713          	addi	a4,a4,-1576 # 8001a288 <devsw>
    800048b8:	97ba                	add	a5,a5,a4
    800048ba:	639c                	ld	a5,0(a5)
    800048bc:	c38d                	beqz	a5,800048de <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048be:	4505                	li	a0,1
    800048c0:	9782                	jalr	a5
    800048c2:	892a                	mv	s2,a0
    800048c4:	bf75                	j	80004880 <fileread+0x60>
    panic("fileread");
    800048c6:	00004517          	auipc	a0,0x4
    800048ca:	e0a50513          	addi	a0,a0,-502 # 800086d0 <syscalls+0x270>
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	c70080e7          	jalr	-912(ra) # 8000053e <panic>
    return -1;
    800048d6:	597d                	li	s2,-1
    800048d8:	b765                	j	80004880 <fileread+0x60>
      return -1;
    800048da:	597d                	li	s2,-1
    800048dc:	b755                	j	80004880 <fileread+0x60>
    800048de:	597d                	li	s2,-1
    800048e0:	b745                	j	80004880 <fileread+0x60>

00000000800048e2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048e2:	715d                	addi	sp,sp,-80
    800048e4:	e486                	sd	ra,72(sp)
    800048e6:	e0a2                	sd	s0,64(sp)
    800048e8:	fc26                	sd	s1,56(sp)
    800048ea:	f84a                	sd	s2,48(sp)
    800048ec:	f44e                	sd	s3,40(sp)
    800048ee:	f052                	sd	s4,32(sp)
    800048f0:	ec56                	sd	s5,24(sp)
    800048f2:	e85a                	sd	s6,16(sp)
    800048f4:	e45e                	sd	s7,8(sp)
    800048f6:	e062                	sd	s8,0(sp)
    800048f8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048fa:	00954783          	lbu	a5,9(a0)
    800048fe:	10078663          	beqz	a5,80004a0a <filewrite+0x128>
    80004902:	892a                	mv	s2,a0
    80004904:	8aae                	mv	s5,a1
    80004906:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004908:	411c                	lw	a5,0(a0)
    8000490a:	4705                	li	a4,1
    8000490c:	02e78263          	beq	a5,a4,80004930 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004910:	470d                	li	a4,3
    80004912:	02e78663          	beq	a5,a4,8000493e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004916:	4709                	li	a4,2
    80004918:	0ee79163          	bne	a5,a4,800049fa <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000491c:	0ac05d63          	blez	a2,800049d6 <filewrite+0xf4>
    int i = 0;
    80004920:	4981                	li	s3,0
    80004922:	6b05                	lui	s6,0x1
    80004924:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004928:	6b85                	lui	s7,0x1
    8000492a:	c00b8b9b          	addiw	s7,s7,-1024
    8000492e:	a861                	j	800049c6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004930:	6908                	ld	a0,16(a0)
    80004932:	00000097          	auipc	ra,0x0
    80004936:	22e080e7          	jalr	558(ra) # 80004b60 <pipewrite>
    8000493a:	8a2a                	mv	s4,a0
    8000493c:	a045                	j	800049dc <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000493e:	02451783          	lh	a5,36(a0)
    80004942:	03079693          	slli	a3,a5,0x30
    80004946:	92c1                	srli	a3,a3,0x30
    80004948:	4725                	li	a4,9
    8000494a:	0cd76263          	bltu	a4,a3,80004a0e <filewrite+0x12c>
    8000494e:	0792                	slli	a5,a5,0x4
    80004950:	00016717          	auipc	a4,0x16
    80004954:	93870713          	addi	a4,a4,-1736 # 8001a288 <devsw>
    80004958:	97ba                	add	a5,a5,a4
    8000495a:	679c                	ld	a5,8(a5)
    8000495c:	cbdd                	beqz	a5,80004a12 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000495e:	4505                	li	a0,1
    80004960:	9782                	jalr	a5
    80004962:	8a2a                	mv	s4,a0
    80004964:	a8a5                	j	800049dc <filewrite+0xfa>
    80004966:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000496a:	00000097          	auipc	ra,0x0
    8000496e:	8b0080e7          	jalr	-1872(ra) # 8000421a <begin_op>
      ilock(f->ip);
    80004972:	01893503          	ld	a0,24(s2)
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	ed2080e7          	jalr	-302(ra) # 80003848 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000497e:	8762                	mv	a4,s8
    80004980:	02092683          	lw	a3,32(s2)
    80004984:	01598633          	add	a2,s3,s5
    80004988:	4585                	li	a1,1
    8000498a:	01893503          	ld	a0,24(s2)
    8000498e:	fffff097          	auipc	ra,0xfffff
    80004992:	266080e7          	jalr	614(ra) # 80003bf4 <writei>
    80004996:	84aa                	mv	s1,a0
    80004998:	00a05763          	blez	a0,800049a6 <filewrite+0xc4>
        f->off += r;
    8000499c:	02092783          	lw	a5,32(s2)
    800049a0:	9fa9                	addw	a5,a5,a0
    800049a2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049a6:	01893503          	ld	a0,24(s2)
    800049aa:	fffff097          	auipc	ra,0xfffff
    800049ae:	f60080e7          	jalr	-160(ra) # 8000390a <iunlock>
      end_op();
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	8e8080e7          	jalr	-1816(ra) # 8000429a <end_op>

      if(r != n1){
    800049ba:	009c1f63          	bne	s8,s1,800049d8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049be:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049c2:	0149db63          	bge	s3,s4,800049d8 <filewrite+0xf6>
      int n1 = n - i;
    800049c6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049ca:	84be                	mv	s1,a5
    800049cc:	2781                	sext.w	a5,a5
    800049ce:	f8fb5ce3          	bge	s6,a5,80004966 <filewrite+0x84>
    800049d2:	84de                	mv	s1,s7
    800049d4:	bf49                	j	80004966 <filewrite+0x84>
    int i = 0;
    800049d6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049d8:	013a1f63          	bne	s4,s3,800049f6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049dc:	8552                	mv	a0,s4
    800049de:	60a6                	ld	ra,72(sp)
    800049e0:	6406                	ld	s0,64(sp)
    800049e2:	74e2                	ld	s1,56(sp)
    800049e4:	7942                	ld	s2,48(sp)
    800049e6:	79a2                	ld	s3,40(sp)
    800049e8:	7a02                	ld	s4,32(sp)
    800049ea:	6ae2                	ld	s5,24(sp)
    800049ec:	6b42                	ld	s6,16(sp)
    800049ee:	6ba2                	ld	s7,8(sp)
    800049f0:	6c02                	ld	s8,0(sp)
    800049f2:	6161                	addi	sp,sp,80
    800049f4:	8082                	ret
    ret = (i == n ? n : -1);
    800049f6:	5a7d                	li	s4,-1
    800049f8:	b7d5                	j	800049dc <filewrite+0xfa>
    panic("filewrite");
    800049fa:	00004517          	auipc	a0,0x4
    800049fe:	ce650513          	addi	a0,a0,-794 # 800086e0 <syscalls+0x280>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	b3c080e7          	jalr	-1220(ra) # 8000053e <panic>
    return -1;
    80004a0a:	5a7d                	li	s4,-1
    80004a0c:	bfc1                	j	800049dc <filewrite+0xfa>
      return -1;
    80004a0e:	5a7d                	li	s4,-1
    80004a10:	b7f1                	j	800049dc <filewrite+0xfa>
    80004a12:	5a7d                	li	s4,-1
    80004a14:	b7e1                	j	800049dc <filewrite+0xfa>

0000000080004a16 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a16:	7179                	addi	sp,sp,-48
    80004a18:	f406                	sd	ra,40(sp)
    80004a1a:	f022                	sd	s0,32(sp)
    80004a1c:	ec26                	sd	s1,24(sp)
    80004a1e:	e84a                	sd	s2,16(sp)
    80004a20:	e44e                	sd	s3,8(sp)
    80004a22:	e052                	sd	s4,0(sp)
    80004a24:	1800                	addi	s0,sp,48
    80004a26:	84aa                	mv	s1,a0
    80004a28:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a2a:	0005b023          	sd	zero,0(a1)
    80004a2e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	bf8080e7          	jalr	-1032(ra) # 8000462a <filealloc>
    80004a3a:	e088                	sd	a0,0(s1)
    80004a3c:	c551                	beqz	a0,80004ac8 <pipealloc+0xb2>
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	bec080e7          	jalr	-1044(ra) # 8000462a <filealloc>
    80004a46:	00aa3023          	sd	a0,0(s4)
    80004a4a:	c92d                	beqz	a0,80004abc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	0a8080e7          	jalr	168(ra) # 80000af4 <kalloc>
    80004a54:	892a                	mv	s2,a0
    80004a56:	c125                	beqz	a0,80004ab6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a58:	4985                	li	s3,1
    80004a5a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a5e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a62:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a66:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a6a:	00004597          	auipc	a1,0x4
    80004a6e:	c8658593          	addi	a1,a1,-890 # 800086f0 <syscalls+0x290>
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	0e2080e7          	jalr	226(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a7a:	609c                	ld	a5,0(s1)
    80004a7c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a80:	609c                	ld	a5,0(s1)
    80004a82:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a86:	609c                	ld	a5,0(s1)
    80004a88:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a8c:	609c                	ld	a5,0(s1)
    80004a8e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a92:	000a3783          	ld	a5,0(s4)
    80004a96:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a9a:	000a3783          	ld	a5,0(s4)
    80004a9e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004aa2:	000a3783          	ld	a5,0(s4)
    80004aa6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aaa:	000a3783          	ld	a5,0(s4)
    80004aae:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ab2:	4501                	li	a0,0
    80004ab4:	a025                	j	80004adc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ab6:	6088                	ld	a0,0(s1)
    80004ab8:	e501                	bnez	a0,80004ac0 <pipealloc+0xaa>
    80004aba:	a039                	j	80004ac8 <pipealloc+0xb2>
    80004abc:	6088                	ld	a0,0(s1)
    80004abe:	c51d                	beqz	a0,80004aec <pipealloc+0xd6>
    fileclose(*f0);
    80004ac0:	00000097          	auipc	ra,0x0
    80004ac4:	c26080e7          	jalr	-986(ra) # 800046e6 <fileclose>
  if(*f1)
    80004ac8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004acc:	557d                	li	a0,-1
  if(*f1)
    80004ace:	c799                	beqz	a5,80004adc <pipealloc+0xc6>
    fileclose(*f1);
    80004ad0:	853e                	mv	a0,a5
    80004ad2:	00000097          	auipc	ra,0x0
    80004ad6:	c14080e7          	jalr	-1004(ra) # 800046e6 <fileclose>
  return -1;
    80004ada:	557d                	li	a0,-1
}
    80004adc:	70a2                	ld	ra,40(sp)
    80004ade:	7402                	ld	s0,32(sp)
    80004ae0:	64e2                	ld	s1,24(sp)
    80004ae2:	6942                	ld	s2,16(sp)
    80004ae4:	69a2                	ld	s3,8(sp)
    80004ae6:	6a02                	ld	s4,0(sp)
    80004ae8:	6145                	addi	sp,sp,48
    80004aea:	8082                	ret
  return -1;
    80004aec:	557d                	li	a0,-1
    80004aee:	b7fd                	j	80004adc <pipealloc+0xc6>

0000000080004af0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004af0:	1101                	addi	sp,sp,-32
    80004af2:	ec06                	sd	ra,24(sp)
    80004af4:	e822                	sd	s0,16(sp)
    80004af6:	e426                	sd	s1,8(sp)
    80004af8:	e04a                	sd	s2,0(sp)
    80004afa:	1000                	addi	s0,sp,32
    80004afc:	84aa                	mv	s1,a0
    80004afe:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	0e4080e7          	jalr	228(ra) # 80000be4 <acquire>
  if(writable){
    80004b08:	02090d63          	beqz	s2,80004b42 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b0c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b10:	21848513          	addi	a0,s1,536
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	7d2080e7          	jalr	2002(ra) # 800022e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b1c:	2204b783          	ld	a5,544(s1)
    80004b20:	eb95                	bnez	a5,80004b54 <pipeclose+0x64>
    release(&pi->lock);
    80004b22:	8526                	mv	a0,s1
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	174080e7          	jalr	372(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	eca080e7          	jalr	-310(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b36:	60e2                	ld	ra,24(sp)
    80004b38:	6442                	ld	s0,16(sp)
    80004b3a:	64a2                	ld	s1,8(sp)
    80004b3c:	6902                	ld	s2,0(sp)
    80004b3e:	6105                	addi	sp,sp,32
    80004b40:	8082                	ret
    pi->readopen = 0;
    80004b42:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b46:	21c48513          	addi	a0,s1,540
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	79c080e7          	jalr	1948(ra) # 800022e6 <wakeup>
    80004b52:	b7e9                	j	80004b1c <pipeclose+0x2c>
    release(&pi->lock);
    80004b54:	8526                	mv	a0,s1
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	142080e7          	jalr	322(ra) # 80000c98 <release>
}
    80004b5e:	bfe1                	j	80004b36 <pipeclose+0x46>

0000000080004b60 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b60:	7159                	addi	sp,sp,-112
    80004b62:	f486                	sd	ra,104(sp)
    80004b64:	f0a2                	sd	s0,96(sp)
    80004b66:	eca6                	sd	s1,88(sp)
    80004b68:	e8ca                	sd	s2,80(sp)
    80004b6a:	e4ce                	sd	s3,72(sp)
    80004b6c:	e0d2                	sd	s4,64(sp)
    80004b6e:	fc56                	sd	s5,56(sp)
    80004b70:	f85a                	sd	s6,48(sp)
    80004b72:	f45e                	sd	s7,40(sp)
    80004b74:	f062                	sd	s8,32(sp)
    80004b76:	ec66                	sd	s9,24(sp)
    80004b78:	1880                	addi	s0,sp,112
    80004b7a:	84aa                	mv	s1,a0
    80004b7c:	8aae                	mv	s5,a1
    80004b7e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	e30080e7          	jalr	-464(ra) # 800019b0 <myproc>
    80004b88:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b8a:	8526                	mv	a0,s1
    80004b8c:	ffffc097          	auipc	ra,0xffffc
    80004b90:	058080e7          	jalr	88(ra) # 80000be4 <acquire>
  while(i < n){
    80004b94:	0d405163          	blez	s4,80004c56 <pipewrite+0xf6>
    80004b98:	8ba6                	mv	s7,s1
  int i = 0;
    80004b9a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b9c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b9e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ba2:	21c48c13          	addi	s8,s1,540
    80004ba6:	a08d                	j	80004c08 <pipewrite+0xa8>
      release(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
      return -1;
    80004bb2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bb4:	854a                	mv	a0,s2
    80004bb6:	70a6                	ld	ra,104(sp)
    80004bb8:	7406                	ld	s0,96(sp)
    80004bba:	64e6                	ld	s1,88(sp)
    80004bbc:	6946                	ld	s2,80(sp)
    80004bbe:	69a6                	ld	s3,72(sp)
    80004bc0:	6a06                	ld	s4,64(sp)
    80004bc2:	7ae2                	ld	s5,56(sp)
    80004bc4:	7b42                	ld	s6,48(sp)
    80004bc6:	7ba2                	ld	s7,40(sp)
    80004bc8:	7c02                	ld	s8,32(sp)
    80004bca:	6ce2                	ld	s9,24(sp)
    80004bcc:	6165                	addi	sp,sp,112
    80004bce:	8082                	ret
      wakeup(&pi->nread);
    80004bd0:	8566                	mv	a0,s9
    80004bd2:	ffffd097          	auipc	ra,0xffffd
    80004bd6:	714080e7          	jalr	1812(ra) # 800022e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bda:	85de                	mv	a1,s7
    80004bdc:	8562                	mv	a0,s8
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	57c080e7          	jalr	1404(ra) # 8000215a <sleep>
    80004be6:	a839                	j	80004c04 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004be8:	21c4a783          	lw	a5,540(s1)
    80004bec:	0017871b          	addiw	a4,a5,1
    80004bf0:	20e4ae23          	sw	a4,540(s1)
    80004bf4:	1ff7f793          	andi	a5,a5,511
    80004bf8:	97a6                	add	a5,a5,s1
    80004bfa:	f9f44703          	lbu	a4,-97(s0)
    80004bfe:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c02:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c04:	03495d63          	bge	s2,s4,80004c3e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c08:	2204a783          	lw	a5,544(s1)
    80004c0c:	dfd1                	beqz	a5,80004ba8 <pipewrite+0x48>
    80004c0e:	0289a783          	lw	a5,40(s3)
    80004c12:	fbd9                	bnez	a5,80004ba8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c14:	2184a783          	lw	a5,536(s1)
    80004c18:	21c4a703          	lw	a4,540(s1)
    80004c1c:	2007879b          	addiw	a5,a5,512
    80004c20:	faf708e3          	beq	a4,a5,80004bd0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c24:	4685                	li	a3,1
    80004c26:	01590633          	add	a2,s2,s5
    80004c2a:	f9f40593          	addi	a1,s0,-97
    80004c2e:	0509b503          	ld	a0,80(s3)
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	acc080e7          	jalr	-1332(ra) # 800016fe <copyin>
    80004c3a:	fb6517e3          	bne	a0,s6,80004be8 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c3e:	21848513          	addi	a0,s1,536
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	6a4080e7          	jalr	1700(ra) # 800022e6 <wakeup>
  release(&pi->lock);
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	04c080e7          	jalr	76(ra) # 80000c98 <release>
  return i;
    80004c54:	b785                	j	80004bb4 <pipewrite+0x54>
  int i = 0;
    80004c56:	4901                	li	s2,0
    80004c58:	b7dd                	j	80004c3e <pipewrite+0xde>

0000000080004c5a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c5a:	715d                	addi	sp,sp,-80
    80004c5c:	e486                	sd	ra,72(sp)
    80004c5e:	e0a2                	sd	s0,64(sp)
    80004c60:	fc26                	sd	s1,56(sp)
    80004c62:	f84a                	sd	s2,48(sp)
    80004c64:	f44e                	sd	s3,40(sp)
    80004c66:	f052                	sd	s4,32(sp)
    80004c68:	ec56                	sd	s5,24(sp)
    80004c6a:	e85a                	sd	s6,16(sp)
    80004c6c:	0880                	addi	s0,sp,80
    80004c6e:	84aa                	mv	s1,a0
    80004c70:	892e                	mv	s2,a1
    80004c72:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	d3c080e7          	jalr	-708(ra) # 800019b0 <myproc>
    80004c7c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c7e:	8b26                	mv	s6,s1
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	f62080e7          	jalr	-158(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c8a:	2184a703          	lw	a4,536(s1)
    80004c8e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c92:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c96:	02f71463          	bne	a4,a5,80004cbe <piperead+0x64>
    80004c9a:	2244a783          	lw	a5,548(s1)
    80004c9e:	c385                	beqz	a5,80004cbe <piperead+0x64>
    if(pr->killed){
    80004ca0:	028a2783          	lw	a5,40(s4)
    80004ca4:	ebc1                	bnez	a5,80004d34 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ca6:	85da                	mv	a1,s6
    80004ca8:	854e                	mv	a0,s3
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	4b0080e7          	jalr	1200(ra) # 8000215a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb2:	2184a703          	lw	a4,536(s1)
    80004cb6:	21c4a783          	lw	a5,540(s1)
    80004cba:	fef700e3          	beq	a4,a5,80004c9a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cbe:	09505263          	blez	s5,80004d42 <piperead+0xe8>
    80004cc2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cc4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cc6:	2184a783          	lw	a5,536(s1)
    80004cca:	21c4a703          	lw	a4,540(s1)
    80004cce:	02f70d63          	beq	a4,a5,80004d08 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cd2:	0017871b          	addiw	a4,a5,1
    80004cd6:	20e4ac23          	sw	a4,536(s1)
    80004cda:	1ff7f793          	andi	a5,a5,511
    80004cde:	97a6                	add	a5,a5,s1
    80004ce0:	0187c783          	lbu	a5,24(a5)
    80004ce4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce8:	4685                	li	a3,1
    80004cea:	fbf40613          	addi	a2,s0,-65
    80004cee:	85ca                	mv	a1,s2
    80004cf0:	050a3503          	ld	a0,80(s4)
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	97e080e7          	jalr	-1666(ra) # 80001672 <copyout>
    80004cfc:	01650663          	beq	a0,s6,80004d08 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d00:	2985                	addiw	s3,s3,1
    80004d02:	0905                	addi	s2,s2,1
    80004d04:	fd3a91e3          	bne	s5,s3,80004cc6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d08:	21c48513          	addi	a0,s1,540
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	5da080e7          	jalr	1498(ra) # 800022e6 <wakeup>
  release(&pi->lock);
    80004d14:	8526                	mv	a0,s1
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
  return i;
}
    80004d1e:	854e                	mv	a0,s3
    80004d20:	60a6                	ld	ra,72(sp)
    80004d22:	6406                	ld	s0,64(sp)
    80004d24:	74e2                	ld	s1,56(sp)
    80004d26:	7942                	ld	s2,48(sp)
    80004d28:	79a2                	ld	s3,40(sp)
    80004d2a:	7a02                	ld	s4,32(sp)
    80004d2c:	6ae2                	ld	s5,24(sp)
    80004d2e:	6b42                	ld	s6,16(sp)
    80004d30:	6161                	addi	sp,sp,80
    80004d32:	8082                	ret
      release(&pi->lock);
    80004d34:	8526                	mv	a0,s1
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	f62080e7          	jalr	-158(ra) # 80000c98 <release>
      return -1;
    80004d3e:	59fd                	li	s3,-1
    80004d40:	bff9                	j	80004d1e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d42:	4981                	li	s3,0
    80004d44:	b7d1                	j	80004d08 <piperead+0xae>

0000000080004d46 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d46:	df010113          	addi	sp,sp,-528
    80004d4a:	20113423          	sd	ra,520(sp)
    80004d4e:	20813023          	sd	s0,512(sp)
    80004d52:	ffa6                	sd	s1,504(sp)
    80004d54:	fbca                	sd	s2,496(sp)
    80004d56:	f7ce                	sd	s3,488(sp)
    80004d58:	f3d2                	sd	s4,480(sp)
    80004d5a:	efd6                	sd	s5,472(sp)
    80004d5c:	ebda                	sd	s6,464(sp)
    80004d5e:	e7de                	sd	s7,456(sp)
    80004d60:	e3e2                	sd	s8,448(sp)
    80004d62:	ff66                	sd	s9,440(sp)
    80004d64:	fb6a                	sd	s10,432(sp)
    80004d66:	f76e                	sd	s11,424(sp)
    80004d68:	0c00                	addi	s0,sp,528
    80004d6a:	84aa                	mv	s1,a0
    80004d6c:	dea43c23          	sd	a0,-520(s0)
    80004d70:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	c3c080e7          	jalr	-964(ra) # 800019b0 <myproc>
    80004d7c:	892a                	mv	s2,a0

  begin_op();
    80004d7e:	fffff097          	auipc	ra,0xfffff
    80004d82:	49c080e7          	jalr	1180(ra) # 8000421a <begin_op>

  if((ip = namei(path)) == 0){
    80004d86:	8526                	mv	a0,s1
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	276080e7          	jalr	630(ra) # 80003ffe <namei>
    80004d90:	c92d                	beqz	a0,80004e02 <exec+0xbc>
    80004d92:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	ab4080e7          	jalr	-1356(ra) # 80003848 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d9c:	04000713          	li	a4,64
    80004da0:	4681                	li	a3,0
    80004da2:	e5040613          	addi	a2,s0,-432
    80004da6:	4581                	li	a1,0
    80004da8:	8526                	mv	a0,s1
    80004daa:	fffff097          	auipc	ra,0xfffff
    80004dae:	d52080e7          	jalr	-686(ra) # 80003afc <readi>
    80004db2:	04000793          	li	a5,64
    80004db6:	00f51a63          	bne	a0,a5,80004dca <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dba:	e5042703          	lw	a4,-432(s0)
    80004dbe:	464c47b7          	lui	a5,0x464c4
    80004dc2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dc6:	04f70463          	beq	a4,a5,80004e0e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	cde080e7          	jalr	-802(ra) # 80003aaa <iunlockput>
    end_op();
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	4c6080e7          	jalr	1222(ra) # 8000429a <end_op>
  }
  return -1;
    80004ddc:	557d                	li	a0,-1
}
    80004dde:	20813083          	ld	ra,520(sp)
    80004de2:	20013403          	ld	s0,512(sp)
    80004de6:	74fe                	ld	s1,504(sp)
    80004de8:	795e                	ld	s2,496(sp)
    80004dea:	79be                	ld	s3,488(sp)
    80004dec:	7a1e                	ld	s4,480(sp)
    80004dee:	6afe                	ld	s5,472(sp)
    80004df0:	6b5e                	ld	s6,464(sp)
    80004df2:	6bbe                	ld	s7,456(sp)
    80004df4:	6c1e                	ld	s8,448(sp)
    80004df6:	7cfa                	ld	s9,440(sp)
    80004df8:	7d5a                	ld	s10,432(sp)
    80004dfa:	7dba                	ld	s11,424(sp)
    80004dfc:	21010113          	addi	sp,sp,528
    80004e00:	8082                	ret
    end_op();
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	498080e7          	jalr	1176(ra) # 8000429a <end_op>
    return -1;
    80004e0a:	557d                	li	a0,-1
    80004e0c:	bfc9                	j	80004dde <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e0e:	854a                	mv	a0,s2
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	c64080e7          	jalr	-924(ra) # 80001a74 <proc_pagetable>
    80004e18:	8baa                	mv	s7,a0
    80004e1a:	d945                	beqz	a0,80004dca <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e1c:	e7042983          	lw	s3,-400(s0)
    80004e20:	e8845783          	lhu	a5,-376(s0)
    80004e24:	c7ad                	beqz	a5,80004e8e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e26:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e28:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e2a:	6c85                	lui	s9,0x1
    80004e2c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e30:	def43823          	sd	a5,-528(s0)
    80004e34:	a42d                	j	8000505e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e36:	00004517          	auipc	a0,0x4
    80004e3a:	8c250513          	addi	a0,a0,-1854 # 800086f8 <syscalls+0x298>
    80004e3e:	ffffb097          	auipc	ra,0xffffb
    80004e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e46:	8756                	mv	a4,s5
    80004e48:	012d86bb          	addw	a3,s11,s2
    80004e4c:	4581                	li	a1,0
    80004e4e:	8526                	mv	a0,s1
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	cac080e7          	jalr	-852(ra) # 80003afc <readi>
    80004e58:	2501                	sext.w	a0,a0
    80004e5a:	1aaa9963          	bne	s5,a0,8000500c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e5e:	6785                	lui	a5,0x1
    80004e60:	0127893b          	addw	s2,a5,s2
    80004e64:	77fd                	lui	a5,0xfffff
    80004e66:	01478a3b          	addw	s4,a5,s4
    80004e6a:	1f897163          	bgeu	s2,s8,8000504c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e6e:	02091593          	slli	a1,s2,0x20
    80004e72:	9181                	srli	a1,a1,0x20
    80004e74:	95ea                	add	a1,a1,s10
    80004e76:	855e                	mv	a0,s7
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	1f6080e7          	jalr	502(ra) # 8000106e <walkaddr>
    80004e80:	862a                	mv	a2,a0
    if(pa == 0)
    80004e82:	d955                	beqz	a0,80004e36 <exec+0xf0>
      n = PGSIZE;
    80004e84:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e86:	fd9a70e3          	bgeu	s4,s9,80004e46 <exec+0x100>
      n = sz - i;
    80004e8a:	8ad2                	mv	s5,s4
    80004e8c:	bf6d                	j	80004e46 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e8e:	4901                	li	s2,0
  iunlockput(ip);
    80004e90:	8526                	mv	a0,s1
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	c18080e7          	jalr	-1000(ra) # 80003aaa <iunlockput>
  end_op();
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	400080e7          	jalr	1024(ra) # 8000429a <end_op>
  p = myproc();
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	b0e080e7          	jalr	-1266(ra) # 800019b0 <myproc>
    80004eaa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eac:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eb0:	6785                	lui	a5,0x1
    80004eb2:	17fd                	addi	a5,a5,-1
    80004eb4:	993e                	add	s2,s2,a5
    80004eb6:	757d                	lui	a0,0xfffff
    80004eb8:	00a977b3          	and	a5,s2,a0
    80004ebc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ec0:	6609                	lui	a2,0x2
    80004ec2:	963e                	add	a2,a2,a5
    80004ec4:	85be                	mv	a1,a5
    80004ec6:	855e                	mv	a0,s7
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	55a080e7          	jalr	1370(ra) # 80001422 <uvmalloc>
    80004ed0:	8b2a                	mv	s6,a0
  ip = 0;
    80004ed2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ed4:	12050c63          	beqz	a0,8000500c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ed8:	75f9                	lui	a1,0xffffe
    80004eda:	95aa                	add	a1,a1,a0
    80004edc:	855e                	mv	a0,s7
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	762080e7          	jalr	1890(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ee6:	7c7d                	lui	s8,0xfffff
    80004ee8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eea:	e0043783          	ld	a5,-512(s0)
    80004eee:	6388                	ld	a0,0(a5)
    80004ef0:	c535                	beqz	a0,80004f5c <exec+0x216>
    80004ef2:	e9040993          	addi	s3,s0,-368
    80004ef6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004efa:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	f68080e7          	jalr	-152(ra) # 80000e64 <strlen>
    80004f04:	2505                	addiw	a0,a0,1
    80004f06:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f0a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f0e:	13896363          	bltu	s2,s8,80005034 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f12:	e0043d83          	ld	s11,-512(s0)
    80004f16:	000dba03          	ld	s4,0(s11)
    80004f1a:	8552                	mv	a0,s4
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	f48080e7          	jalr	-184(ra) # 80000e64 <strlen>
    80004f24:	0015069b          	addiw	a3,a0,1
    80004f28:	8652                	mv	a2,s4
    80004f2a:	85ca                	mv	a1,s2
    80004f2c:	855e                	mv	a0,s7
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	744080e7          	jalr	1860(ra) # 80001672 <copyout>
    80004f36:	10054363          	bltz	a0,8000503c <exec+0x2f6>
    ustack[argc] = sp;
    80004f3a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f3e:	0485                	addi	s1,s1,1
    80004f40:	008d8793          	addi	a5,s11,8
    80004f44:	e0f43023          	sd	a5,-512(s0)
    80004f48:	008db503          	ld	a0,8(s11)
    80004f4c:	c911                	beqz	a0,80004f60 <exec+0x21a>
    if(argc >= MAXARG)
    80004f4e:	09a1                	addi	s3,s3,8
    80004f50:	fb3c96e3          	bne	s9,s3,80004efc <exec+0x1b6>
  sz = sz1;
    80004f54:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f58:	4481                	li	s1,0
    80004f5a:	a84d                	j	8000500c <exec+0x2c6>
  sp = sz;
    80004f5c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f5e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f60:	00349793          	slli	a5,s1,0x3
    80004f64:	f9040713          	addi	a4,s0,-112
    80004f68:	97ba                	add	a5,a5,a4
    80004f6a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f6e:	00148693          	addi	a3,s1,1
    80004f72:	068e                	slli	a3,a3,0x3
    80004f74:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f78:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f7c:	01897663          	bgeu	s2,s8,80004f88 <exec+0x242>
  sz = sz1;
    80004f80:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f84:	4481                	li	s1,0
    80004f86:	a059                	j	8000500c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f88:	e9040613          	addi	a2,s0,-368
    80004f8c:	85ca                	mv	a1,s2
    80004f8e:	855e                	mv	a0,s7
    80004f90:	ffffc097          	auipc	ra,0xffffc
    80004f94:	6e2080e7          	jalr	1762(ra) # 80001672 <copyout>
    80004f98:	0a054663          	bltz	a0,80005044 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f9c:	058ab783          	ld	a5,88(s5)
    80004fa0:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fa4:	df843783          	ld	a5,-520(s0)
    80004fa8:	0007c703          	lbu	a4,0(a5)
    80004fac:	cf11                	beqz	a4,80004fc8 <exec+0x282>
    80004fae:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fb0:	02f00693          	li	a3,47
    80004fb4:	a039                	j	80004fc2 <exec+0x27c>
      last = s+1;
    80004fb6:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fba:	0785                	addi	a5,a5,1
    80004fbc:	fff7c703          	lbu	a4,-1(a5)
    80004fc0:	c701                	beqz	a4,80004fc8 <exec+0x282>
    if(*s == '/')
    80004fc2:	fed71ce3          	bne	a4,a3,80004fba <exec+0x274>
    80004fc6:	bfc5                	j	80004fb6 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fc8:	4641                	li	a2,16
    80004fca:	df843583          	ld	a1,-520(s0)
    80004fce:	158a8513          	addi	a0,s5,344
    80004fd2:	ffffc097          	auipc	ra,0xffffc
    80004fd6:	e60080e7          	jalr	-416(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fda:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fde:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fe2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fe6:	058ab783          	ld	a5,88(s5)
    80004fea:	e6843703          	ld	a4,-408(s0)
    80004fee:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ff0:	058ab783          	ld	a5,88(s5)
    80004ff4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ff8:	85ea                	mv	a1,s10
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	b16080e7          	jalr	-1258(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005002:	0004851b          	sext.w	a0,s1
    80005006:	bbe1                	j	80004dde <exec+0x98>
    80005008:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000500c:	e0843583          	ld	a1,-504(s0)
    80005010:	855e                	mv	a0,s7
    80005012:	ffffd097          	auipc	ra,0xffffd
    80005016:	afe080e7          	jalr	-1282(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    8000501a:	da0498e3          	bnez	s1,80004dca <exec+0x84>
  return -1;
    8000501e:	557d                	li	a0,-1
    80005020:	bb7d                	j	80004dde <exec+0x98>
    80005022:	e1243423          	sd	s2,-504(s0)
    80005026:	b7dd                	j	8000500c <exec+0x2c6>
    80005028:	e1243423          	sd	s2,-504(s0)
    8000502c:	b7c5                	j	8000500c <exec+0x2c6>
    8000502e:	e1243423          	sd	s2,-504(s0)
    80005032:	bfe9                	j	8000500c <exec+0x2c6>
  sz = sz1;
    80005034:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005038:	4481                	li	s1,0
    8000503a:	bfc9                	j	8000500c <exec+0x2c6>
  sz = sz1;
    8000503c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005040:	4481                	li	s1,0
    80005042:	b7e9                	j	8000500c <exec+0x2c6>
  sz = sz1;
    80005044:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005048:	4481                	li	s1,0
    8000504a:	b7c9                	j	8000500c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000504c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005050:	2b05                	addiw	s6,s6,1
    80005052:	0389899b          	addiw	s3,s3,56
    80005056:	e8845783          	lhu	a5,-376(s0)
    8000505a:	e2fb5be3          	bge	s6,a5,80004e90 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000505e:	2981                	sext.w	s3,s3
    80005060:	03800713          	li	a4,56
    80005064:	86ce                	mv	a3,s3
    80005066:	e1840613          	addi	a2,s0,-488
    8000506a:	4581                	li	a1,0
    8000506c:	8526                	mv	a0,s1
    8000506e:	fffff097          	auipc	ra,0xfffff
    80005072:	a8e080e7          	jalr	-1394(ra) # 80003afc <readi>
    80005076:	03800793          	li	a5,56
    8000507a:	f8f517e3          	bne	a0,a5,80005008 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000507e:	e1842783          	lw	a5,-488(s0)
    80005082:	4705                	li	a4,1
    80005084:	fce796e3          	bne	a5,a4,80005050 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005088:	e4043603          	ld	a2,-448(s0)
    8000508c:	e3843783          	ld	a5,-456(s0)
    80005090:	f8f669e3          	bltu	a2,a5,80005022 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005094:	e2843783          	ld	a5,-472(s0)
    80005098:	963e                	add	a2,a2,a5
    8000509a:	f8f667e3          	bltu	a2,a5,80005028 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000509e:	85ca                	mv	a1,s2
    800050a0:	855e                	mv	a0,s7
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	380080e7          	jalr	896(ra) # 80001422 <uvmalloc>
    800050aa:	e0a43423          	sd	a0,-504(s0)
    800050ae:	d141                	beqz	a0,8000502e <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050b0:	e2843d03          	ld	s10,-472(s0)
    800050b4:	df043783          	ld	a5,-528(s0)
    800050b8:	00fd77b3          	and	a5,s10,a5
    800050bc:	fba1                	bnez	a5,8000500c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050be:	e2042d83          	lw	s11,-480(s0)
    800050c2:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050c6:	f80c03e3          	beqz	s8,8000504c <exec+0x306>
    800050ca:	8a62                	mv	s4,s8
    800050cc:	4901                	li	s2,0
    800050ce:	b345                	j	80004e6e <exec+0x128>

00000000800050d0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050d0:	7179                	addi	sp,sp,-48
    800050d2:	f406                	sd	ra,40(sp)
    800050d4:	f022                	sd	s0,32(sp)
    800050d6:	ec26                	sd	s1,24(sp)
    800050d8:	e84a                	sd	s2,16(sp)
    800050da:	1800                	addi	s0,sp,48
    800050dc:	892e                	mv	s2,a1
    800050de:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050e0:	fdc40593          	addi	a1,s0,-36
    800050e4:	ffffe097          	auipc	ra,0xffffe
    800050e8:	b8e080e7          	jalr	-1138(ra) # 80002c72 <argint>
    800050ec:	04054063          	bltz	a0,8000512c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050f0:	fdc42703          	lw	a4,-36(s0)
    800050f4:	47bd                	li	a5,15
    800050f6:	02e7ed63          	bltu	a5,a4,80005130 <argfd+0x60>
    800050fa:	ffffd097          	auipc	ra,0xffffd
    800050fe:	8b6080e7          	jalr	-1866(ra) # 800019b0 <myproc>
    80005102:	fdc42703          	lw	a4,-36(s0)
    80005106:	01a70793          	addi	a5,a4,26
    8000510a:	078e                	slli	a5,a5,0x3
    8000510c:	953e                	add	a0,a0,a5
    8000510e:	611c                	ld	a5,0(a0)
    80005110:	c395                	beqz	a5,80005134 <argfd+0x64>
    return -1;
  if(pfd)
    80005112:	00090463          	beqz	s2,8000511a <argfd+0x4a>
    *pfd = fd;
    80005116:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000511a:	4501                	li	a0,0
  if(pf)
    8000511c:	c091                	beqz	s1,80005120 <argfd+0x50>
    *pf = f;
    8000511e:	e09c                	sd	a5,0(s1)
}
    80005120:	70a2                	ld	ra,40(sp)
    80005122:	7402                	ld	s0,32(sp)
    80005124:	64e2                	ld	s1,24(sp)
    80005126:	6942                	ld	s2,16(sp)
    80005128:	6145                	addi	sp,sp,48
    8000512a:	8082                	ret
    return -1;
    8000512c:	557d                	li	a0,-1
    8000512e:	bfcd                	j	80005120 <argfd+0x50>
    return -1;
    80005130:	557d                	li	a0,-1
    80005132:	b7fd                	j	80005120 <argfd+0x50>
    80005134:	557d                	li	a0,-1
    80005136:	b7ed                	j	80005120 <argfd+0x50>

0000000080005138 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005138:	1101                	addi	sp,sp,-32
    8000513a:	ec06                	sd	ra,24(sp)
    8000513c:	e822                	sd	s0,16(sp)
    8000513e:	e426                	sd	s1,8(sp)
    80005140:	1000                	addi	s0,sp,32
    80005142:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005144:	ffffd097          	auipc	ra,0xffffd
    80005148:	86c080e7          	jalr	-1940(ra) # 800019b0 <myproc>
    8000514c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000514e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffe00d0>
    80005152:	4501                	li	a0,0
    80005154:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005156:	6398                	ld	a4,0(a5)
    80005158:	cb19                	beqz	a4,8000516e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000515a:	2505                	addiw	a0,a0,1
    8000515c:	07a1                	addi	a5,a5,8
    8000515e:	fed51ce3          	bne	a0,a3,80005156 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005162:	557d                	li	a0,-1
}
    80005164:	60e2                	ld	ra,24(sp)
    80005166:	6442                	ld	s0,16(sp)
    80005168:	64a2                	ld	s1,8(sp)
    8000516a:	6105                	addi	sp,sp,32
    8000516c:	8082                	ret
      p->ofile[fd] = f;
    8000516e:	01a50793          	addi	a5,a0,26
    80005172:	078e                	slli	a5,a5,0x3
    80005174:	963e                	add	a2,a2,a5
    80005176:	e204                	sd	s1,0(a2)
      return fd;
    80005178:	b7f5                	j	80005164 <fdalloc+0x2c>

000000008000517a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000517a:	715d                	addi	sp,sp,-80
    8000517c:	e486                	sd	ra,72(sp)
    8000517e:	e0a2                	sd	s0,64(sp)
    80005180:	fc26                	sd	s1,56(sp)
    80005182:	f84a                	sd	s2,48(sp)
    80005184:	f44e                	sd	s3,40(sp)
    80005186:	f052                	sd	s4,32(sp)
    80005188:	ec56                	sd	s5,24(sp)
    8000518a:	0880                	addi	s0,sp,80
    8000518c:	89ae                	mv	s3,a1
    8000518e:	8ab2                	mv	s5,a2
    80005190:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005192:	fb040593          	addi	a1,s0,-80
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	e86080e7          	jalr	-378(ra) # 8000401c <nameiparent>
    8000519e:	892a                	mv	s2,a0
    800051a0:	12050f63          	beqz	a0,800052de <create+0x164>
    return 0;

  ilock(dp);
    800051a4:	ffffe097          	auipc	ra,0xffffe
    800051a8:	6a4080e7          	jalr	1700(ra) # 80003848 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ac:	4601                	li	a2,0
    800051ae:	fb040593          	addi	a1,s0,-80
    800051b2:	854a                	mv	a0,s2
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	b78080e7          	jalr	-1160(ra) # 80003d2c <dirlookup>
    800051bc:	84aa                	mv	s1,a0
    800051be:	c921                	beqz	a0,8000520e <create+0x94>
    iunlockput(dp);
    800051c0:	854a                	mv	a0,s2
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	8e8080e7          	jalr	-1816(ra) # 80003aaa <iunlockput>
    ilock(ip);
    800051ca:	8526                	mv	a0,s1
    800051cc:	ffffe097          	auipc	ra,0xffffe
    800051d0:	67c080e7          	jalr	1660(ra) # 80003848 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051d4:	2981                	sext.w	s3,s3
    800051d6:	4789                	li	a5,2
    800051d8:	02f99463          	bne	s3,a5,80005200 <create+0x86>
    800051dc:	0444d783          	lhu	a5,68(s1)
    800051e0:	37f9                	addiw	a5,a5,-2
    800051e2:	17c2                	slli	a5,a5,0x30
    800051e4:	93c1                	srli	a5,a5,0x30
    800051e6:	4705                	li	a4,1
    800051e8:	00f76c63          	bltu	a4,a5,80005200 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051ec:	8526                	mv	a0,s1
    800051ee:	60a6                	ld	ra,72(sp)
    800051f0:	6406                	ld	s0,64(sp)
    800051f2:	74e2                	ld	s1,56(sp)
    800051f4:	7942                	ld	s2,48(sp)
    800051f6:	79a2                	ld	s3,40(sp)
    800051f8:	7a02                	ld	s4,32(sp)
    800051fa:	6ae2                	ld	s5,24(sp)
    800051fc:	6161                	addi	sp,sp,80
    800051fe:	8082                	ret
    iunlockput(ip);
    80005200:	8526                	mv	a0,s1
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	8a8080e7          	jalr	-1880(ra) # 80003aaa <iunlockput>
    return 0;
    8000520a:	4481                	li	s1,0
    8000520c:	b7c5                	j	800051ec <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000520e:	85ce                	mv	a1,s3
    80005210:	00092503          	lw	a0,0(s2)
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	49c080e7          	jalr	1180(ra) # 800036b0 <ialloc>
    8000521c:	84aa                	mv	s1,a0
    8000521e:	c529                	beqz	a0,80005268 <create+0xee>
  ilock(ip);
    80005220:	ffffe097          	auipc	ra,0xffffe
    80005224:	628080e7          	jalr	1576(ra) # 80003848 <ilock>
  ip->major = major;
    80005228:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000522c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005230:	4785                	li	a5,1
    80005232:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005236:	8526                	mv	a0,s1
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	546080e7          	jalr	1350(ra) # 8000377e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005240:	2981                	sext.w	s3,s3
    80005242:	4785                	li	a5,1
    80005244:	02f98a63          	beq	s3,a5,80005278 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005248:	40d0                	lw	a2,4(s1)
    8000524a:	fb040593          	addi	a1,s0,-80
    8000524e:	854a                	mv	a0,s2
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	cec080e7          	jalr	-788(ra) # 80003f3c <dirlink>
    80005258:	06054b63          	bltz	a0,800052ce <create+0x154>
  iunlockput(dp);
    8000525c:	854a                	mv	a0,s2
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	84c080e7          	jalr	-1972(ra) # 80003aaa <iunlockput>
  return ip;
    80005266:	b759                	j	800051ec <create+0x72>
    panic("create: ialloc");
    80005268:	00003517          	auipc	a0,0x3
    8000526c:	4b050513          	addi	a0,a0,1200 # 80008718 <syscalls+0x2b8>
    80005270:	ffffb097          	auipc	ra,0xffffb
    80005274:	2ce080e7          	jalr	718(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005278:	04a95783          	lhu	a5,74(s2)
    8000527c:	2785                	addiw	a5,a5,1
    8000527e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005282:	854a                	mv	a0,s2
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	4fa080e7          	jalr	1274(ra) # 8000377e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000528c:	40d0                	lw	a2,4(s1)
    8000528e:	00003597          	auipc	a1,0x3
    80005292:	49a58593          	addi	a1,a1,1178 # 80008728 <syscalls+0x2c8>
    80005296:	8526                	mv	a0,s1
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	ca4080e7          	jalr	-860(ra) # 80003f3c <dirlink>
    800052a0:	00054f63          	bltz	a0,800052be <create+0x144>
    800052a4:	00492603          	lw	a2,4(s2)
    800052a8:	00003597          	auipc	a1,0x3
    800052ac:	48858593          	addi	a1,a1,1160 # 80008730 <syscalls+0x2d0>
    800052b0:	8526                	mv	a0,s1
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	c8a080e7          	jalr	-886(ra) # 80003f3c <dirlink>
    800052ba:	f80557e3          	bgez	a0,80005248 <create+0xce>
      panic("create dots");
    800052be:	00003517          	auipc	a0,0x3
    800052c2:	47a50513          	addi	a0,a0,1146 # 80008738 <syscalls+0x2d8>
    800052c6:	ffffb097          	auipc	ra,0xffffb
    800052ca:	278080e7          	jalr	632(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052ce:	00003517          	auipc	a0,0x3
    800052d2:	47a50513          	addi	a0,a0,1146 # 80008748 <syscalls+0x2e8>
    800052d6:	ffffb097          	auipc	ra,0xffffb
    800052da:	268080e7          	jalr	616(ra) # 8000053e <panic>
    return 0;
    800052de:	84aa                	mv	s1,a0
    800052e0:	b731                	j	800051ec <create+0x72>

00000000800052e2 <sys_dup>:
{
    800052e2:	7179                	addi	sp,sp,-48
    800052e4:	f406                	sd	ra,40(sp)
    800052e6:	f022                	sd	s0,32(sp)
    800052e8:	ec26                	sd	s1,24(sp)
    800052ea:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052ec:	fd840613          	addi	a2,s0,-40
    800052f0:	4581                	li	a1,0
    800052f2:	4501                	li	a0,0
    800052f4:	00000097          	auipc	ra,0x0
    800052f8:	ddc080e7          	jalr	-548(ra) # 800050d0 <argfd>
    return -1;
    800052fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052fe:	02054363          	bltz	a0,80005324 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005302:	fd843503          	ld	a0,-40(s0)
    80005306:	00000097          	auipc	ra,0x0
    8000530a:	e32080e7          	jalr	-462(ra) # 80005138 <fdalloc>
    8000530e:	84aa                	mv	s1,a0
    return -1;
    80005310:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005312:	00054963          	bltz	a0,80005324 <sys_dup+0x42>
  filedup(f);
    80005316:	fd843503          	ld	a0,-40(s0)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	37a080e7          	jalr	890(ra) # 80004694 <filedup>
  return fd;
    80005322:	87a6                	mv	a5,s1
}
    80005324:	853e                	mv	a0,a5
    80005326:	70a2                	ld	ra,40(sp)
    80005328:	7402                	ld	s0,32(sp)
    8000532a:	64e2                	ld	s1,24(sp)
    8000532c:	6145                	addi	sp,sp,48
    8000532e:	8082                	ret

0000000080005330 <sys_read>:
{
    80005330:	7179                	addi	sp,sp,-48
    80005332:	f406                	sd	ra,40(sp)
    80005334:	f022                	sd	s0,32(sp)
    80005336:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005338:	fe840613          	addi	a2,s0,-24
    8000533c:	4581                	li	a1,0
    8000533e:	4501                	li	a0,0
    80005340:	00000097          	auipc	ra,0x0
    80005344:	d90080e7          	jalr	-624(ra) # 800050d0 <argfd>
    return -1;
    80005348:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534a:	04054163          	bltz	a0,8000538c <sys_read+0x5c>
    8000534e:	fe440593          	addi	a1,s0,-28
    80005352:	4509                	li	a0,2
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	91e080e7          	jalr	-1762(ra) # 80002c72 <argint>
    return -1;
    8000535c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000535e:	02054763          	bltz	a0,8000538c <sys_read+0x5c>
    80005362:	fd840593          	addi	a1,s0,-40
    80005366:	4505                	li	a0,1
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	92c080e7          	jalr	-1748(ra) # 80002c94 <argaddr>
    return -1;
    80005370:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005372:	00054d63          	bltz	a0,8000538c <sys_read+0x5c>
  return fileread(f, p, n);
    80005376:	fe442603          	lw	a2,-28(s0)
    8000537a:	fd843583          	ld	a1,-40(s0)
    8000537e:	fe843503          	ld	a0,-24(s0)
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	49e080e7          	jalr	1182(ra) # 80004820 <fileread>
    8000538a:	87aa                	mv	a5,a0
}
    8000538c:	853e                	mv	a0,a5
    8000538e:	70a2                	ld	ra,40(sp)
    80005390:	7402                	ld	s0,32(sp)
    80005392:	6145                	addi	sp,sp,48
    80005394:	8082                	ret

0000000080005396 <sys_write>:
{
    80005396:	7179                	addi	sp,sp,-48
    80005398:	f406                	sd	ra,40(sp)
    8000539a:	f022                	sd	s0,32(sp)
    8000539c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539e:	fe840613          	addi	a2,s0,-24
    800053a2:	4581                	li	a1,0
    800053a4:	4501                	li	a0,0
    800053a6:	00000097          	auipc	ra,0x0
    800053aa:	d2a080e7          	jalr	-726(ra) # 800050d0 <argfd>
    return -1;
    800053ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b0:	04054163          	bltz	a0,800053f2 <sys_write+0x5c>
    800053b4:	fe440593          	addi	a1,s0,-28
    800053b8:	4509                	li	a0,2
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	8b8080e7          	jalr	-1864(ra) # 80002c72 <argint>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c4:	02054763          	bltz	a0,800053f2 <sys_write+0x5c>
    800053c8:	fd840593          	addi	a1,s0,-40
    800053cc:	4505                	li	a0,1
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	8c6080e7          	jalr	-1850(ra) # 80002c94 <argaddr>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d8:	00054d63          	bltz	a0,800053f2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053dc:	fe442603          	lw	a2,-28(s0)
    800053e0:	fd843583          	ld	a1,-40(s0)
    800053e4:	fe843503          	ld	a0,-24(s0)
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	4fa080e7          	jalr	1274(ra) # 800048e2 <filewrite>
    800053f0:	87aa                	mv	a5,a0
}
    800053f2:	853e                	mv	a0,a5
    800053f4:	70a2                	ld	ra,40(sp)
    800053f6:	7402                	ld	s0,32(sp)
    800053f8:	6145                	addi	sp,sp,48
    800053fa:	8082                	ret

00000000800053fc <sys_close>:
{
    800053fc:	1101                	addi	sp,sp,-32
    800053fe:	ec06                	sd	ra,24(sp)
    80005400:	e822                	sd	s0,16(sp)
    80005402:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005404:	fe040613          	addi	a2,s0,-32
    80005408:	fec40593          	addi	a1,s0,-20
    8000540c:	4501                	li	a0,0
    8000540e:	00000097          	auipc	ra,0x0
    80005412:	cc2080e7          	jalr	-830(ra) # 800050d0 <argfd>
    return -1;
    80005416:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005418:	02054463          	bltz	a0,80005440 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000541c:	ffffc097          	auipc	ra,0xffffc
    80005420:	594080e7          	jalr	1428(ra) # 800019b0 <myproc>
    80005424:	fec42783          	lw	a5,-20(s0)
    80005428:	07e9                	addi	a5,a5,26
    8000542a:	078e                	slli	a5,a5,0x3
    8000542c:	97aa                	add	a5,a5,a0
    8000542e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005432:	fe043503          	ld	a0,-32(s0)
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	2b0080e7          	jalr	688(ra) # 800046e6 <fileclose>
  return 0;
    8000543e:	4781                	li	a5,0
}
    80005440:	853e                	mv	a0,a5
    80005442:	60e2                	ld	ra,24(sp)
    80005444:	6442                	ld	s0,16(sp)
    80005446:	6105                	addi	sp,sp,32
    80005448:	8082                	ret

000000008000544a <sys_fstat>:
{
    8000544a:	1101                	addi	sp,sp,-32
    8000544c:	ec06                	sd	ra,24(sp)
    8000544e:	e822                	sd	s0,16(sp)
    80005450:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005452:	fe840613          	addi	a2,s0,-24
    80005456:	4581                	li	a1,0
    80005458:	4501                	li	a0,0
    8000545a:	00000097          	auipc	ra,0x0
    8000545e:	c76080e7          	jalr	-906(ra) # 800050d0 <argfd>
    return -1;
    80005462:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005464:	02054563          	bltz	a0,8000548e <sys_fstat+0x44>
    80005468:	fe040593          	addi	a1,s0,-32
    8000546c:	4505                	li	a0,1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	826080e7          	jalr	-2010(ra) # 80002c94 <argaddr>
    return -1;
    80005476:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005478:	00054b63          	bltz	a0,8000548e <sys_fstat+0x44>
  return filestat(f, st);
    8000547c:	fe043583          	ld	a1,-32(s0)
    80005480:	fe843503          	ld	a0,-24(s0)
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	32a080e7          	jalr	810(ra) # 800047ae <filestat>
    8000548c:	87aa                	mv	a5,a0
}
    8000548e:	853e                	mv	a0,a5
    80005490:	60e2                	ld	ra,24(sp)
    80005492:	6442                	ld	s0,16(sp)
    80005494:	6105                	addi	sp,sp,32
    80005496:	8082                	ret

0000000080005498 <sys_link>:
{
    80005498:	7169                	addi	sp,sp,-304
    8000549a:	f606                	sd	ra,296(sp)
    8000549c:	f222                	sd	s0,288(sp)
    8000549e:	ee26                	sd	s1,280(sp)
    800054a0:	ea4a                	sd	s2,272(sp)
    800054a2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a4:	08000613          	li	a2,128
    800054a8:	ed040593          	addi	a1,s0,-304
    800054ac:	4501                	li	a0,0
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	808080e7          	jalr	-2040(ra) # 80002cb6 <argstr>
    return -1;
    800054b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b8:	10054e63          	bltz	a0,800055d4 <sys_link+0x13c>
    800054bc:	08000613          	li	a2,128
    800054c0:	f5040593          	addi	a1,s0,-176
    800054c4:	4505                	li	a0,1
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	7f0080e7          	jalr	2032(ra) # 80002cb6 <argstr>
    return -1;
    800054ce:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d0:	10054263          	bltz	a0,800055d4 <sys_link+0x13c>
  begin_op();
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	d46080e7          	jalr	-698(ra) # 8000421a <begin_op>
  if((ip = namei(old)) == 0){
    800054dc:	ed040513          	addi	a0,s0,-304
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	b1e080e7          	jalr	-1250(ra) # 80003ffe <namei>
    800054e8:	84aa                	mv	s1,a0
    800054ea:	c551                	beqz	a0,80005576 <sys_link+0xde>
  ilock(ip);
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	35c080e7          	jalr	860(ra) # 80003848 <ilock>
  if(ip->type == T_DIR){
    800054f4:	04449703          	lh	a4,68(s1)
    800054f8:	4785                	li	a5,1
    800054fa:	08f70463          	beq	a4,a5,80005582 <sys_link+0xea>
  ip->nlink++;
    800054fe:	04a4d783          	lhu	a5,74(s1)
    80005502:	2785                	addiw	a5,a5,1
    80005504:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005508:	8526                	mv	a0,s1
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	274080e7          	jalr	628(ra) # 8000377e <iupdate>
  iunlock(ip);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	3f6080e7          	jalr	1014(ra) # 8000390a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000551c:	fd040593          	addi	a1,s0,-48
    80005520:	f5040513          	addi	a0,s0,-176
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	af8080e7          	jalr	-1288(ra) # 8000401c <nameiparent>
    8000552c:	892a                	mv	s2,a0
    8000552e:	c935                	beqz	a0,800055a2 <sys_link+0x10a>
  ilock(dp);
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	318080e7          	jalr	792(ra) # 80003848 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005538:	00092703          	lw	a4,0(s2)
    8000553c:	409c                	lw	a5,0(s1)
    8000553e:	04f71d63          	bne	a4,a5,80005598 <sys_link+0x100>
    80005542:	40d0                	lw	a2,4(s1)
    80005544:	fd040593          	addi	a1,s0,-48
    80005548:	854a                	mv	a0,s2
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	9f2080e7          	jalr	-1550(ra) # 80003f3c <dirlink>
    80005552:	04054363          	bltz	a0,80005598 <sys_link+0x100>
  iunlockput(dp);
    80005556:	854a                	mv	a0,s2
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	552080e7          	jalr	1362(ra) # 80003aaa <iunlockput>
  iput(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	4a0080e7          	jalr	1184(ra) # 80003a02 <iput>
  end_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	d30080e7          	jalr	-720(ra) # 8000429a <end_op>
  return 0;
    80005572:	4781                	li	a5,0
    80005574:	a085                	j	800055d4 <sys_link+0x13c>
    end_op();
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	d24080e7          	jalr	-732(ra) # 8000429a <end_op>
    return -1;
    8000557e:	57fd                	li	a5,-1
    80005580:	a891                	j	800055d4 <sys_link+0x13c>
    iunlockput(ip);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	526080e7          	jalr	1318(ra) # 80003aaa <iunlockput>
    end_op();
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	d0e080e7          	jalr	-754(ra) # 8000429a <end_op>
    return -1;
    80005594:	57fd                	li	a5,-1
    80005596:	a83d                	j	800055d4 <sys_link+0x13c>
    iunlockput(dp);
    80005598:	854a                	mv	a0,s2
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	510080e7          	jalr	1296(ra) # 80003aaa <iunlockput>
  ilock(ip);
    800055a2:	8526                	mv	a0,s1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	2a4080e7          	jalr	676(ra) # 80003848 <ilock>
  ip->nlink--;
    800055ac:	04a4d783          	lhu	a5,74(s1)
    800055b0:	37fd                	addiw	a5,a5,-1
    800055b2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	1c6080e7          	jalr	454(ra) # 8000377e <iupdate>
  iunlockput(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	4e8080e7          	jalr	1256(ra) # 80003aaa <iunlockput>
  end_op();
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	cd0080e7          	jalr	-816(ra) # 8000429a <end_op>
  return -1;
    800055d2:	57fd                	li	a5,-1
}
    800055d4:	853e                	mv	a0,a5
    800055d6:	70b2                	ld	ra,296(sp)
    800055d8:	7412                	ld	s0,288(sp)
    800055da:	64f2                	ld	s1,280(sp)
    800055dc:	6952                	ld	s2,272(sp)
    800055de:	6155                	addi	sp,sp,304
    800055e0:	8082                	ret

00000000800055e2 <sys_unlink>:
{
    800055e2:	7151                	addi	sp,sp,-240
    800055e4:	f586                	sd	ra,232(sp)
    800055e6:	f1a2                	sd	s0,224(sp)
    800055e8:	eda6                	sd	s1,216(sp)
    800055ea:	e9ca                	sd	s2,208(sp)
    800055ec:	e5ce                	sd	s3,200(sp)
    800055ee:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055f0:	08000613          	li	a2,128
    800055f4:	f3040593          	addi	a1,s0,-208
    800055f8:	4501                	li	a0,0
    800055fa:	ffffd097          	auipc	ra,0xffffd
    800055fe:	6bc080e7          	jalr	1724(ra) # 80002cb6 <argstr>
    80005602:	18054163          	bltz	a0,80005784 <sys_unlink+0x1a2>
  begin_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	c14080e7          	jalr	-1004(ra) # 8000421a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000560e:	fb040593          	addi	a1,s0,-80
    80005612:	f3040513          	addi	a0,s0,-208
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	a06080e7          	jalr	-1530(ra) # 8000401c <nameiparent>
    8000561e:	84aa                	mv	s1,a0
    80005620:	c979                	beqz	a0,800056f6 <sys_unlink+0x114>
  ilock(dp);
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	226080e7          	jalr	550(ra) # 80003848 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000562a:	00003597          	auipc	a1,0x3
    8000562e:	0fe58593          	addi	a1,a1,254 # 80008728 <syscalls+0x2c8>
    80005632:	fb040513          	addi	a0,s0,-80
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	6dc080e7          	jalr	1756(ra) # 80003d12 <namecmp>
    8000563e:	14050a63          	beqz	a0,80005792 <sys_unlink+0x1b0>
    80005642:	00003597          	auipc	a1,0x3
    80005646:	0ee58593          	addi	a1,a1,238 # 80008730 <syscalls+0x2d0>
    8000564a:	fb040513          	addi	a0,s0,-80
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	6c4080e7          	jalr	1732(ra) # 80003d12 <namecmp>
    80005656:	12050e63          	beqz	a0,80005792 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000565a:	f2c40613          	addi	a2,s0,-212
    8000565e:	fb040593          	addi	a1,s0,-80
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	6c8080e7          	jalr	1736(ra) # 80003d2c <dirlookup>
    8000566c:	892a                	mv	s2,a0
    8000566e:	12050263          	beqz	a0,80005792 <sys_unlink+0x1b0>
  ilock(ip);
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	1d6080e7          	jalr	470(ra) # 80003848 <ilock>
  if(ip->nlink < 1)
    8000567a:	04a91783          	lh	a5,74(s2)
    8000567e:	08f05263          	blez	a5,80005702 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005682:	04491703          	lh	a4,68(s2)
    80005686:	4785                	li	a5,1
    80005688:	08f70563          	beq	a4,a5,80005712 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000568c:	4641                	li	a2,16
    8000568e:	4581                	li	a1,0
    80005690:	fc040513          	addi	a0,s0,-64
    80005694:	ffffb097          	auipc	ra,0xffffb
    80005698:	64c080e7          	jalr	1612(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000569c:	4741                	li	a4,16
    8000569e:	f2c42683          	lw	a3,-212(s0)
    800056a2:	fc040613          	addi	a2,s0,-64
    800056a6:	4581                	li	a1,0
    800056a8:	8526                	mv	a0,s1
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	54a080e7          	jalr	1354(ra) # 80003bf4 <writei>
    800056b2:	47c1                	li	a5,16
    800056b4:	0af51563          	bne	a0,a5,8000575e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056b8:	04491703          	lh	a4,68(s2)
    800056bc:	4785                	li	a5,1
    800056be:	0af70863          	beq	a4,a5,8000576e <sys_unlink+0x18c>
  iunlockput(dp);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	3e6080e7          	jalr	998(ra) # 80003aaa <iunlockput>
  ip->nlink--;
    800056cc:	04a95783          	lhu	a5,74(s2)
    800056d0:	37fd                	addiw	a5,a5,-1
    800056d2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056d6:	854a                	mv	a0,s2
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	0a6080e7          	jalr	166(ra) # 8000377e <iupdate>
  iunlockput(ip);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	3c8080e7          	jalr	968(ra) # 80003aaa <iunlockput>
  end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	bb0080e7          	jalr	-1104(ra) # 8000429a <end_op>
  return 0;
    800056f2:	4501                	li	a0,0
    800056f4:	a84d                	j	800057a6 <sys_unlink+0x1c4>
    end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	ba4080e7          	jalr	-1116(ra) # 8000429a <end_op>
    return -1;
    800056fe:	557d                	li	a0,-1
    80005700:	a05d                	j	800057a6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005702:	00003517          	auipc	a0,0x3
    80005706:	05650513          	addi	a0,a0,86 # 80008758 <syscalls+0x2f8>
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	e34080e7          	jalr	-460(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005712:	04c92703          	lw	a4,76(s2)
    80005716:	02000793          	li	a5,32
    8000571a:	f6e7f9e3          	bgeu	a5,a4,8000568c <sys_unlink+0xaa>
    8000571e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005722:	4741                	li	a4,16
    80005724:	86ce                	mv	a3,s3
    80005726:	f1840613          	addi	a2,s0,-232
    8000572a:	4581                	li	a1,0
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	3ce080e7          	jalr	974(ra) # 80003afc <readi>
    80005736:	47c1                	li	a5,16
    80005738:	00f51b63          	bne	a0,a5,8000574e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000573c:	f1845783          	lhu	a5,-232(s0)
    80005740:	e7a1                	bnez	a5,80005788 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005742:	29c1                	addiw	s3,s3,16
    80005744:	04c92783          	lw	a5,76(s2)
    80005748:	fcf9ede3          	bltu	s3,a5,80005722 <sys_unlink+0x140>
    8000574c:	b781                	j	8000568c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000574e:	00003517          	auipc	a0,0x3
    80005752:	02250513          	addi	a0,a0,34 # 80008770 <syscalls+0x310>
    80005756:	ffffb097          	auipc	ra,0xffffb
    8000575a:	de8080e7          	jalr	-536(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000575e:	00003517          	auipc	a0,0x3
    80005762:	02a50513          	addi	a0,a0,42 # 80008788 <syscalls+0x328>
    80005766:	ffffb097          	auipc	ra,0xffffb
    8000576a:	dd8080e7          	jalr	-552(ra) # 8000053e <panic>
    dp->nlink--;
    8000576e:	04a4d783          	lhu	a5,74(s1)
    80005772:	37fd                	addiw	a5,a5,-1
    80005774:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	004080e7          	jalr	4(ra) # 8000377e <iupdate>
    80005782:	b781                	j	800056c2 <sys_unlink+0xe0>
    return -1;
    80005784:	557d                	li	a0,-1
    80005786:	a005                	j	800057a6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	320080e7          	jalr	800(ra) # 80003aaa <iunlockput>
  iunlockput(dp);
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	316080e7          	jalr	790(ra) # 80003aaa <iunlockput>
  end_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	afe080e7          	jalr	-1282(ra) # 8000429a <end_op>
  return -1;
    800057a4:	557d                	li	a0,-1
}
    800057a6:	70ae                	ld	ra,232(sp)
    800057a8:	740e                	ld	s0,224(sp)
    800057aa:	64ee                	ld	s1,216(sp)
    800057ac:	694e                	ld	s2,208(sp)
    800057ae:	69ae                	ld	s3,200(sp)
    800057b0:	616d                	addi	sp,sp,240
    800057b2:	8082                	ret

00000000800057b4 <sys_open>:

uint64
sys_open(void)
{
    800057b4:	7131                	addi	sp,sp,-192
    800057b6:	fd06                	sd	ra,184(sp)
    800057b8:	f922                	sd	s0,176(sp)
    800057ba:	f526                	sd	s1,168(sp)
    800057bc:	f14a                	sd	s2,160(sp)
    800057be:	ed4e                	sd	s3,152(sp)
    800057c0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057c2:	08000613          	li	a2,128
    800057c6:	f5040593          	addi	a1,s0,-176
    800057ca:	4501                	li	a0,0
    800057cc:	ffffd097          	auipc	ra,0xffffd
    800057d0:	4ea080e7          	jalr	1258(ra) # 80002cb6 <argstr>
    return -1;
    800057d4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057d6:	0c054163          	bltz	a0,80005898 <sys_open+0xe4>
    800057da:	f4c40593          	addi	a1,s0,-180
    800057de:	4505                	li	a0,1
    800057e0:	ffffd097          	auipc	ra,0xffffd
    800057e4:	492080e7          	jalr	1170(ra) # 80002c72 <argint>
    800057e8:	0a054863          	bltz	a0,80005898 <sys_open+0xe4>

  begin_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	a2e080e7          	jalr	-1490(ra) # 8000421a <begin_op>

  if(omode & O_CREATE){
    800057f4:	f4c42783          	lw	a5,-180(s0)
    800057f8:	2007f793          	andi	a5,a5,512
    800057fc:	cbdd                	beqz	a5,800058b2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057fe:	4681                	li	a3,0
    80005800:	4601                	li	a2,0
    80005802:	4589                	li	a1,2
    80005804:	f5040513          	addi	a0,s0,-176
    80005808:	00000097          	auipc	ra,0x0
    8000580c:	972080e7          	jalr	-1678(ra) # 8000517a <create>
    80005810:	892a                	mv	s2,a0
    if(ip == 0){
    80005812:	c959                	beqz	a0,800058a8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005814:	04491703          	lh	a4,68(s2)
    80005818:	478d                	li	a5,3
    8000581a:	00f71763          	bne	a4,a5,80005828 <sys_open+0x74>
    8000581e:	04695703          	lhu	a4,70(s2)
    80005822:	47a5                	li	a5,9
    80005824:	0ce7ec63          	bltu	a5,a4,800058fc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	e02080e7          	jalr	-510(ra) # 8000462a <filealloc>
    80005830:	89aa                	mv	s3,a0
    80005832:	10050263          	beqz	a0,80005936 <sys_open+0x182>
    80005836:	00000097          	auipc	ra,0x0
    8000583a:	902080e7          	jalr	-1790(ra) # 80005138 <fdalloc>
    8000583e:	84aa                	mv	s1,a0
    80005840:	0e054663          	bltz	a0,8000592c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005844:	04491703          	lh	a4,68(s2)
    80005848:	478d                	li	a5,3
    8000584a:	0cf70463          	beq	a4,a5,80005912 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000584e:	4789                	li	a5,2
    80005850:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005854:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005858:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000585c:	f4c42783          	lw	a5,-180(s0)
    80005860:	0017c713          	xori	a4,a5,1
    80005864:	8b05                	andi	a4,a4,1
    80005866:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000586a:	0037f713          	andi	a4,a5,3
    8000586e:	00e03733          	snez	a4,a4
    80005872:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005876:	4007f793          	andi	a5,a5,1024
    8000587a:	c791                	beqz	a5,80005886 <sys_open+0xd2>
    8000587c:	04491703          	lh	a4,68(s2)
    80005880:	4789                	li	a5,2
    80005882:	08f70f63          	beq	a4,a5,80005920 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005886:	854a                	mv	a0,s2
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	082080e7          	jalr	130(ra) # 8000390a <iunlock>
  end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	a0a080e7          	jalr	-1526(ra) # 8000429a <end_op>

  return fd;
}
    80005898:	8526                	mv	a0,s1
    8000589a:	70ea                	ld	ra,184(sp)
    8000589c:	744a                	ld	s0,176(sp)
    8000589e:	74aa                	ld	s1,168(sp)
    800058a0:	790a                	ld	s2,160(sp)
    800058a2:	69ea                	ld	s3,152(sp)
    800058a4:	6129                	addi	sp,sp,192
    800058a6:	8082                	ret
      end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	9f2080e7          	jalr	-1550(ra) # 8000429a <end_op>
      return -1;
    800058b0:	b7e5                	j	80005898 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058b2:	f5040513          	addi	a0,s0,-176
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	748080e7          	jalr	1864(ra) # 80003ffe <namei>
    800058be:	892a                	mv	s2,a0
    800058c0:	c905                	beqz	a0,800058f0 <sys_open+0x13c>
    ilock(ip);
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	f86080e7          	jalr	-122(ra) # 80003848 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058ca:	04491703          	lh	a4,68(s2)
    800058ce:	4785                	li	a5,1
    800058d0:	f4f712e3          	bne	a4,a5,80005814 <sys_open+0x60>
    800058d4:	f4c42783          	lw	a5,-180(s0)
    800058d8:	dba1                	beqz	a5,80005828 <sys_open+0x74>
      iunlockput(ip);
    800058da:	854a                	mv	a0,s2
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	1ce080e7          	jalr	462(ra) # 80003aaa <iunlockput>
      end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	9b6080e7          	jalr	-1610(ra) # 8000429a <end_op>
      return -1;
    800058ec:	54fd                	li	s1,-1
    800058ee:	b76d                	j	80005898 <sys_open+0xe4>
      end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	9aa080e7          	jalr	-1622(ra) # 8000429a <end_op>
      return -1;
    800058f8:	54fd                	li	s1,-1
    800058fa:	bf79                	j	80005898 <sys_open+0xe4>
    iunlockput(ip);
    800058fc:	854a                	mv	a0,s2
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	1ac080e7          	jalr	428(ra) # 80003aaa <iunlockput>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	994080e7          	jalr	-1644(ra) # 8000429a <end_op>
    return -1;
    8000590e:	54fd                	li	s1,-1
    80005910:	b761                	j	80005898 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005912:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005916:	04691783          	lh	a5,70(s2)
    8000591a:	02f99223          	sh	a5,36(s3)
    8000591e:	bf2d                	j	80005858 <sys_open+0xa4>
    itrunc(ip);
    80005920:	854a                	mv	a0,s2
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	034080e7          	jalr	52(ra) # 80003956 <itrunc>
    8000592a:	bfb1                	j	80005886 <sys_open+0xd2>
      fileclose(f);
    8000592c:	854e                	mv	a0,s3
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	db8080e7          	jalr	-584(ra) # 800046e6 <fileclose>
    iunlockput(ip);
    80005936:	854a                	mv	a0,s2
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	172080e7          	jalr	370(ra) # 80003aaa <iunlockput>
    end_op();
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	95a080e7          	jalr	-1702(ra) # 8000429a <end_op>
    return -1;
    80005948:	54fd                	li	s1,-1
    8000594a:	b7b9                	j	80005898 <sys_open+0xe4>

000000008000594c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000594c:	7175                	addi	sp,sp,-144
    8000594e:	e506                	sd	ra,136(sp)
    80005950:	e122                	sd	s0,128(sp)
    80005952:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	8c6080e7          	jalr	-1850(ra) # 8000421a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000595c:	08000613          	li	a2,128
    80005960:	f7040593          	addi	a1,s0,-144
    80005964:	4501                	li	a0,0
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	350080e7          	jalr	848(ra) # 80002cb6 <argstr>
    8000596e:	02054963          	bltz	a0,800059a0 <sys_mkdir+0x54>
    80005972:	4681                	li	a3,0
    80005974:	4601                	li	a2,0
    80005976:	4585                	li	a1,1
    80005978:	f7040513          	addi	a0,s0,-144
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	7fe080e7          	jalr	2046(ra) # 8000517a <create>
    80005984:	cd11                	beqz	a0,800059a0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	124080e7          	jalr	292(ra) # 80003aaa <iunlockput>
  end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	90c080e7          	jalr	-1780(ra) # 8000429a <end_op>
  return 0;
    80005996:	4501                	li	a0,0
}
    80005998:	60aa                	ld	ra,136(sp)
    8000599a:	640a                	ld	s0,128(sp)
    8000599c:	6149                	addi	sp,sp,144
    8000599e:	8082                	ret
    end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8fa080e7          	jalr	-1798(ra) # 8000429a <end_op>
    return -1;
    800059a8:	557d                	li	a0,-1
    800059aa:	b7fd                	j	80005998 <sys_mkdir+0x4c>

00000000800059ac <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ac:	7135                	addi	sp,sp,-160
    800059ae:	ed06                	sd	ra,152(sp)
    800059b0:	e922                	sd	s0,144(sp)
    800059b2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	866080e7          	jalr	-1946(ra) # 8000421a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059bc:	08000613          	li	a2,128
    800059c0:	f7040593          	addi	a1,s0,-144
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	2f0080e7          	jalr	752(ra) # 80002cb6 <argstr>
    800059ce:	04054a63          	bltz	a0,80005a22 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059d2:	f6c40593          	addi	a1,s0,-148
    800059d6:	4505                	li	a0,1
    800059d8:	ffffd097          	auipc	ra,0xffffd
    800059dc:	29a080e7          	jalr	666(ra) # 80002c72 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059e0:	04054163          	bltz	a0,80005a22 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059e4:	f6840593          	addi	a1,s0,-152
    800059e8:	4509                	li	a0,2
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	288080e7          	jalr	648(ra) # 80002c72 <argint>
     argint(1, &major) < 0 ||
    800059f2:	02054863          	bltz	a0,80005a22 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059f6:	f6841683          	lh	a3,-152(s0)
    800059fa:	f6c41603          	lh	a2,-148(s0)
    800059fe:	458d                	li	a1,3
    80005a00:	f7040513          	addi	a0,s0,-144
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	776080e7          	jalr	1910(ra) # 8000517a <create>
     argint(2, &minor) < 0 ||
    80005a0c:	c919                	beqz	a0,80005a22 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	09c080e7          	jalr	156(ra) # 80003aaa <iunlockput>
  end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	884080e7          	jalr	-1916(ra) # 8000429a <end_op>
  return 0;
    80005a1e:	4501                	li	a0,0
    80005a20:	a031                	j	80005a2c <sys_mknod+0x80>
    end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	878080e7          	jalr	-1928(ra) # 8000429a <end_op>
    return -1;
    80005a2a:	557d                	li	a0,-1
}
    80005a2c:	60ea                	ld	ra,152(sp)
    80005a2e:	644a                	ld	s0,144(sp)
    80005a30:	610d                	addi	sp,sp,160
    80005a32:	8082                	ret

0000000080005a34 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a34:	7135                	addi	sp,sp,-160
    80005a36:	ed06                	sd	ra,152(sp)
    80005a38:	e922                	sd	s0,144(sp)
    80005a3a:	e526                	sd	s1,136(sp)
    80005a3c:	e14a                	sd	s2,128(sp)
    80005a3e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a40:	ffffc097          	auipc	ra,0xffffc
    80005a44:	f70080e7          	jalr	-144(ra) # 800019b0 <myproc>
    80005a48:	892a                	mv	s2,a0
  
  begin_op();
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	7d0080e7          	jalr	2000(ra) # 8000421a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a52:	08000613          	li	a2,128
    80005a56:	f6040593          	addi	a1,s0,-160
    80005a5a:	4501                	li	a0,0
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	25a080e7          	jalr	602(ra) # 80002cb6 <argstr>
    80005a64:	04054b63          	bltz	a0,80005aba <sys_chdir+0x86>
    80005a68:	f6040513          	addi	a0,s0,-160
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	592080e7          	jalr	1426(ra) # 80003ffe <namei>
    80005a74:	84aa                	mv	s1,a0
    80005a76:	c131                	beqz	a0,80005aba <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	dd0080e7          	jalr	-560(ra) # 80003848 <ilock>
  if(ip->type != T_DIR){
    80005a80:	04449703          	lh	a4,68(s1)
    80005a84:	4785                	li	a5,1
    80005a86:	04f71063          	bne	a4,a5,80005ac6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	e7e080e7          	jalr	-386(ra) # 8000390a <iunlock>
  iput(p->cwd);
    80005a94:	15093503          	ld	a0,336(s2)
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	f6a080e7          	jalr	-150(ra) # 80003a02 <iput>
  end_op();
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	7fa080e7          	jalr	2042(ra) # 8000429a <end_op>
  p->cwd = ip;
    80005aa8:	14993823          	sd	s1,336(s2)
  return 0;
    80005aac:	4501                	li	a0,0
}
    80005aae:	60ea                	ld	ra,152(sp)
    80005ab0:	644a                	ld	s0,144(sp)
    80005ab2:	64aa                	ld	s1,136(sp)
    80005ab4:	690a                	ld	s2,128(sp)
    80005ab6:	610d                	addi	sp,sp,160
    80005ab8:	8082                	ret
    end_op();
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	7e0080e7          	jalr	2016(ra) # 8000429a <end_op>
    return -1;
    80005ac2:	557d                	li	a0,-1
    80005ac4:	b7ed                	j	80005aae <sys_chdir+0x7a>
    iunlockput(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	fe2080e7          	jalr	-30(ra) # 80003aaa <iunlockput>
    end_op();
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	7ca080e7          	jalr	1994(ra) # 8000429a <end_op>
    return -1;
    80005ad8:	557d                	li	a0,-1
    80005ada:	bfd1                	j	80005aae <sys_chdir+0x7a>

0000000080005adc <sys_exec>:

uint64
sys_exec(void)
{
    80005adc:	7145                	addi	sp,sp,-464
    80005ade:	e786                	sd	ra,456(sp)
    80005ae0:	e3a2                	sd	s0,448(sp)
    80005ae2:	ff26                	sd	s1,440(sp)
    80005ae4:	fb4a                	sd	s2,432(sp)
    80005ae6:	f74e                	sd	s3,424(sp)
    80005ae8:	f352                	sd	s4,416(sp)
    80005aea:	ef56                	sd	s5,408(sp)
    80005aec:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aee:	08000613          	li	a2,128
    80005af2:	f4040593          	addi	a1,s0,-192
    80005af6:	4501                	li	a0,0
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	1be080e7          	jalr	446(ra) # 80002cb6 <argstr>
    return -1;
    80005b00:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b02:	0c054a63          	bltz	a0,80005bd6 <sys_exec+0xfa>
    80005b06:	e3840593          	addi	a1,s0,-456
    80005b0a:	4505                	li	a0,1
    80005b0c:	ffffd097          	auipc	ra,0xffffd
    80005b10:	188080e7          	jalr	392(ra) # 80002c94 <argaddr>
    80005b14:	0c054163          	bltz	a0,80005bd6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b18:	10000613          	li	a2,256
    80005b1c:	4581                	li	a1,0
    80005b1e:	e4040513          	addi	a0,s0,-448
    80005b22:	ffffb097          	auipc	ra,0xffffb
    80005b26:	1be080e7          	jalr	446(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b2a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b2e:	89a6                	mv	s3,s1
    80005b30:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b32:	02000a13          	li	s4,32
    80005b36:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b3a:	00391513          	slli	a0,s2,0x3
    80005b3e:	e3040593          	addi	a1,s0,-464
    80005b42:	e3843783          	ld	a5,-456(s0)
    80005b46:	953e                	add	a0,a0,a5
    80005b48:	ffffd097          	auipc	ra,0xffffd
    80005b4c:	090080e7          	jalr	144(ra) # 80002bd8 <fetchaddr>
    80005b50:	02054a63          	bltz	a0,80005b84 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b54:	e3043783          	ld	a5,-464(s0)
    80005b58:	c3b9                	beqz	a5,80005b9e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b5a:	ffffb097          	auipc	ra,0xffffb
    80005b5e:	f9a080e7          	jalr	-102(ra) # 80000af4 <kalloc>
    80005b62:	85aa                	mv	a1,a0
    80005b64:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b68:	cd11                	beqz	a0,80005b84 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b6a:	6605                	lui	a2,0x1
    80005b6c:	e3043503          	ld	a0,-464(s0)
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	0ba080e7          	jalr	186(ra) # 80002c2a <fetchstr>
    80005b78:	00054663          	bltz	a0,80005b84 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b7c:	0905                	addi	s2,s2,1
    80005b7e:	09a1                	addi	s3,s3,8
    80005b80:	fb491be3          	bne	s2,s4,80005b36 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b84:	10048913          	addi	s2,s1,256
    80005b88:	6088                	ld	a0,0(s1)
    80005b8a:	c529                	beqz	a0,80005bd4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b8c:	ffffb097          	auipc	ra,0xffffb
    80005b90:	e6c080e7          	jalr	-404(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b94:	04a1                	addi	s1,s1,8
    80005b96:	ff2499e3          	bne	s1,s2,80005b88 <sys_exec+0xac>
  return -1;
    80005b9a:	597d                	li	s2,-1
    80005b9c:	a82d                	j	80005bd6 <sys_exec+0xfa>
      argv[i] = 0;
    80005b9e:	0a8e                	slli	s5,s5,0x3
    80005ba0:	fc040793          	addi	a5,s0,-64
    80005ba4:	9abe                	add	s5,s5,a5
    80005ba6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005baa:	e4040593          	addi	a1,s0,-448
    80005bae:	f4040513          	addi	a0,s0,-192
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	194080e7          	jalr	404(ra) # 80004d46 <exec>
    80005bba:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbc:	10048993          	addi	s3,s1,256
    80005bc0:	6088                	ld	a0,0(s1)
    80005bc2:	c911                	beqz	a0,80005bd6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bc4:	ffffb097          	auipc	ra,0xffffb
    80005bc8:	e34080e7          	jalr	-460(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bcc:	04a1                	addi	s1,s1,8
    80005bce:	ff3499e3          	bne	s1,s3,80005bc0 <sys_exec+0xe4>
    80005bd2:	a011                	j	80005bd6 <sys_exec+0xfa>
  return -1;
    80005bd4:	597d                	li	s2,-1
}
    80005bd6:	854a                	mv	a0,s2
    80005bd8:	60be                	ld	ra,456(sp)
    80005bda:	641e                	ld	s0,448(sp)
    80005bdc:	74fa                	ld	s1,440(sp)
    80005bde:	795a                	ld	s2,432(sp)
    80005be0:	79ba                	ld	s3,424(sp)
    80005be2:	7a1a                	ld	s4,416(sp)
    80005be4:	6afa                	ld	s5,408(sp)
    80005be6:	6179                	addi	sp,sp,464
    80005be8:	8082                	ret

0000000080005bea <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bea:	7139                	addi	sp,sp,-64
    80005bec:	fc06                	sd	ra,56(sp)
    80005bee:	f822                	sd	s0,48(sp)
    80005bf0:	f426                	sd	s1,40(sp)
    80005bf2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bf4:	ffffc097          	auipc	ra,0xffffc
    80005bf8:	dbc080e7          	jalr	-580(ra) # 800019b0 <myproc>
    80005bfc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bfe:	fd840593          	addi	a1,s0,-40
    80005c02:	4501                	li	a0,0
    80005c04:	ffffd097          	auipc	ra,0xffffd
    80005c08:	090080e7          	jalr	144(ra) # 80002c94 <argaddr>
    return -1;
    80005c0c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c0e:	0e054063          	bltz	a0,80005cee <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c12:	fc840593          	addi	a1,s0,-56
    80005c16:	fd040513          	addi	a0,s0,-48
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	dfc080e7          	jalr	-516(ra) # 80004a16 <pipealloc>
    return -1;
    80005c22:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c24:	0c054563          	bltz	a0,80005cee <sys_pipe+0x104>
  fd0 = -1;
    80005c28:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c2c:	fd043503          	ld	a0,-48(s0)
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	508080e7          	jalr	1288(ra) # 80005138 <fdalloc>
    80005c38:	fca42223          	sw	a0,-60(s0)
    80005c3c:	08054c63          	bltz	a0,80005cd4 <sys_pipe+0xea>
    80005c40:	fc843503          	ld	a0,-56(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	4f4080e7          	jalr	1268(ra) # 80005138 <fdalloc>
    80005c4c:	fca42023          	sw	a0,-64(s0)
    80005c50:	06054863          	bltz	a0,80005cc0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c54:	4691                	li	a3,4
    80005c56:	fc440613          	addi	a2,s0,-60
    80005c5a:	fd843583          	ld	a1,-40(s0)
    80005c5e:	68a8                	ld	a0,80(s1)
    80005c60:	ffffc097          	auipc	ra,0xffffc
    80005c64:	a12080e7          	jalr	-1518(ra) # 80001672 <copyout>
    80005c68:	02054063          	bltz	a0,80005c88 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c6c:	4691                	li	a3,4
    80005c6e:	fc040613          	addi	a2,s0,-64
    80005c72:	fd843583          	ld	a1,-40(s0)
    80005c76:	0591                	addi	a1,a1,4
    80005c78:	68a8                	ld	a0,80(s1)
    80005c7a:	ffffc097          	auipc	ra,0xffffc
    80005c7e:	9f8080e7          	jalr	-1544(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c82:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c84:	06055563          	bgez	a0,80005cee <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c88:	fc442783          	lw	a5,-60(s0)
    80005c8c:	07e9                	addi	a5,a5,26
    80005c8e:	078e                	slli	a5,a5,0x3
    80005c90:	97a6                	add	a5,a5,s1
    80005c92:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c96:	fc042503          	lw	a0,-64(s0)
    80005c9a:	0569                	addi	a0,a0,26
    80005c9c:	050e                	slli	a0,a0,0x3
    80005c9e:	9526                	add	a0,a0,s1
    80005ca0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ca4:	fd043503          	ld	a0,-48(s0)
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	a3e080e7          	jalr	-1474(ra) # 800046e6 <fileclose>
    fileclose(wf);
    80005cb0:	fc843503          	ld	a0,-56(s0)
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	a32080e7          	jalr	-1486(ra) # 800046e6 <fileclose>
    return -1;
    80005cbc:	57fd                	li	a5,-1
    80005cbe:	a805                	j	80005cee <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cc0:	fc442783          	lw	a5,-60(s0)
    80005cc4:	0007c863          	bltz	a5,80005cd4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cc8:	01a78513          	addi	a0,a5,26
    80005ccc:	050e                	slli	a0,a0,0x3
    80005cce:	9526                	add	a0,a0,s1
    80005cd0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cd4:	fd043503          	ld	a0,-48(s0)
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	a0e080e7          	jalr	-1522(ra) # 800046e6 <fileclose>
    fileclose(wf);
    80005ce0:	fc843503          	ld	a0,-56(s0)
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	a02080e7          	jalr	-1534(ra) # 800046e6 <fileclose>
    return -1;
    80005cec:	57fd                	li	a5,-1
}
    80005cee:	853e                	mv	a0,a5
    80005cf0:	70e2                	ld	ra,56(sp)
    80005cf2:	7442                	ld	s0,48(sp)
    80005cf4:	74a2                	ld	s1,40(sp)
    80005cf6:	6121                	addi	sp,sp,64
    80005cf8:	8082                	ret
    80005cfa:	0000                	unimp
    80005cfc:	0000                	unimp
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	d65fc0ef          	jal	ra,80002aa4 <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bac080e7          	jalr	-1108(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	b74080e7          	jalr	-1164(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5179b          	slliw	a5,a0,0xd
    80005e1c:	0c201537          	lui	a0,0xc201
    80005e20:	953e                	add	a0,a0,a5
  return irq;
}
    80005e22:	4148                	lw	a0,4(a0)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b4c080e7          	jalr	-1204(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	06a7c963          	blt	a5,a0,80005ed2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	00016797          	auipc	a5,0x16
    80005e68:	19c78793          	addi	a5,a5,412 # 8001c000 <disk>
    80005e6c:	00a78733          	add	a4,a5,a0
    80005e70:	6789                	lui	a5,0x2
    80005e72:	97ba                	add	a5,a5,a4
    80005e74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e78:	e7ad                	bnez	a5,80005ee2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e7a:	00451793          	slli	a5,a0,0x4
    80005e7e:	00018717          	auipc	a4,0x18
    80005e82:	18270713          	addi	a4,a4,386 # 8001e000 <disk+0x2000>
    80005e86:	6314                	ld	a3,0(a4)
    80005e88:	96be                	add	a3,a3,a5
    80005e8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e8e:	6314                	ld	a3,0(a4)
    80005e90:	96be                	add	a3,a3,a5
    80005e92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e96:	6314                	ld	a3,0(a4)
    80005e98:	96be                	add	a3,a3,a5
    80005e9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e9e:	6318                	ld	a4,0(a4)
    80005ea0:	97ba                	add	a5,a5,a4
    80005ea2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ea6:	00016797          	auipc	a5,0x16
    80005eaa:	15a78793          	addi	a5,a5,346 # 8001c000 <disk>
    80005eae:	97aa                	add	a5,a5,a0
    80005eb0:	6509                	lui	a0,0x2
    80005eb2:	953e                	add	a0,a0,a5
    80005eb4:	4785                	li	a5,1
    80005eb6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eba:	00018517          	auipc	a0,0x18
    80005ebe:	15e50513          	addi	a0,a0,350 # 8001e018 <disk+0x2018>
    80005ec2:	ffffc097          	auipc	ra,0xffffc
    80005ec6:	424080e7          	jalr	1060(ra) # 800022e6 <wakeup>
}
    80005eca:	60a2                	ld	ra,8(sp)
    80005ecc:	6402                	ld	s0,0(sp)
    80005ece:	0141                	addi	sp,sp,16
    80005ed0:	8082                	ret
    panic("free_desc 1");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	8c650513          	addi	a0,a0,-1850 # 80008798 <syscalls+0x338>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	8c650513          	addi	a0,a0,-1850 # 800087a8 <syscalls+0x348>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>

0000000080005ef2 <virtio_disk_init>:
{
    80005ef2:	1101                	addi	sp,sp,-32
    80005ef4:	ec06                	sd	ra,24(sp)
    80005ef6:	e822                	sd	s0,16(sp)
    80005ef8:	e426                	sd	s1,8(sp)
    80005efa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005efc:	00003597          	auipc	a1,0x3
    80005f00:	8bc58593          	addi	a1,a1,-1860 # 800087b8 <syscalls+0x358>
    80005f04:	00018517          	auipc	a0,0x18
    80005f08:	22450513          	addi	a0,a0,548 # 8001e128 <disk+0x2128>
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	c48080e7          	jalr	-952(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f14:	100017b7          	lui	a5,0x10001
    80005f18:	4398                	lw	a4,0(a5)
    80005f1a:	2701                	sext.w	a4,a4
    80005f1c:	747277b7          	lui	a5,0x74727
    80005f20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f24:	0ef71163          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	43dc                	lw	a5,4(a5)
    80005f2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f30:	4705                	li	a4,1
    80005f32:	0ce79a63          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f36:	100017b7          	lui	a5,0x10001
    80005f3a:	479c                	lw	a5,8(a5)
    80005f3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f3e:	4709                	li	a4,2
    80005f40:	0ce79363          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	47d8                	lw	a4,12(a5)
    80005f4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f4c:	554d47b7          	lui	a5,0x554d4
    80005f50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f54:	0af71963          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	4705                	li	a4,1
    80005f5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f60:	470d                	li	a4,3
    80005f62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f66:	c7ffe737          	lui	a4,0xc7ffe
    80005f6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    80005f6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f70:	2701                	sext.w	a4,a4
    80005f72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f74:	472d                	li	a4,11
    80005f76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f78:	473d                	li	a4,15
    80005f7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f7c:	6705                	lui	a4,0x1
    80005f7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f84:	5bdc                	lw	a5,52(a5)
    80005f86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f88:	c7d9                	beqz	a5,80006016 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f8a:	471d                	li	a4,7
    80005f8c:	08f77d63          	bgeu	a4,a5,80006026 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f90:	100014b7          	lui	s1,0x10001
    80005f94:	47a1                	li	a5,8
    80005f96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f98:	6609                	lui	a2,0x2
    80005f9a:	4581                	li	a1,0
    80005f9c:	00016517          	auipc	a0,0x16
    80005fa0:	06450513          	addi	a0,a0,100 # 8001c000 <disk>
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	d3c080e7          	jalr	-708(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fac:	00016717          	auipc	a4,0x16
    80005fb0:	05470713          	addi	a4,a4,84 # 8001c000 <disk>
    80005fb4:	00c75793          	srli	a5,a4,0xc
    80005fb8:	2781                	sext.w	a5,a5
    80005fba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fbc:	00018797          	auipc	a5,0x18
    80005fc0:	04478793          	addi	a5,a5,68 # 8001e000 <disk+0x2000>
    80005fc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fc6:	00016717          	auipc	a4,0x16
    80005fca:	0ba70713          	addi	a4,a4,186 # 8001c080 <disk+0x80>
    80005fce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fd0:	00017717          	auipc	a4,0x17
    80005fd4:	03070713          	addi	a4,a4,48 # 8001d000 <disk+0x1000>
    80005fd8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fda:	4705                	li	a4,1
    80005fdc:	00e78c23          	sb	a4,24(a5)
    80005fe0:	00e78ca3          	sb	a4,25(a5)
    80005fe4:	00e78d23          	sb	a4,26(a5)
    80005fe8:	00e78da3          	sb	a4,27(a5)
    80005fec:	00e78e23          	sb	a4,28(a5)
    80005ff0:	00e78ea3          	sb	a4,29(a5)
    80005ff4:	00e78f23          	sb	a4,30(a5)
    80005ff8:	00e78fa3          	sb	a4,31(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6105                	addi	sp,sp,32
    80006004:	8082                	ret
    panic("could not find virtio disk");
    80006006:	00002517          	auipc	a0,0x2
    8000600a:	7c250513          	addi	a0,a0,1986 # 800087c8 <syscalls+0x368>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006016:	00002517          	auipc	a0,0x2
    8000601a:	7d250513          	addi	a0,a0,2002 # 800087e8 <syscalls+0x388>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006026:	00002517          	auipc	a0,0x2
    8000602a:	7e250513          	addi	a0,a0,2018 # 80008808 <syscalls+0x3a8>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	510080e7          	jalr	1296(ra) # 8000053e <panic>

0000000080006036 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006036:	7159                	addi	sp,sp,-112
    80006038:	f486                	sd	ra,104(sp)
    8000603a:	f0a2                	sd	s0,96(sp)
    8000603c:	eca6                	sd	s1,88(sp)
    8000603e:	e8ca                	sd	s2,80(sp)
    80006040:	e4ce                	sd	s3,72(sp)
    80006042:	e0d2                	sd	s4,64(sp)
    80006044:	fc56                	sd	s5,56(sp)
    80006046:	f85a                	sd	s6,48(sp)
    80006048:	f45e                	sd	s7,40(sp)
    8000604a:	f062                	sd	s8,32(sp)
    8000604c:	ec66                	sd	s9,24(sp)
    8000604e:	e86a                	sd	s10,16(sp)
    80006050:	1880                	addi	s0,sp,112
    80006052:	892a                	mv	s2,a0
    80006054:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006056:	00c52c83          	lw	s9,12(a0)
    8000605a:	001c9c9b          	slliw	s9,s9,0x1
    8000605e:	1c82                	slli	s9,s9,0x20
    80006060:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006064:	00018517          	auipc	a0,0x18
    80006068:	0c450513          	addi	a0,a0,196 # 8001e128 <disk+0x2128>
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	b78080e7          	jalr	-1160(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006074:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006076:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006078:	00016b97          	auipc	s7,0x16
    8000607c:	f88b8b93          	addi	s7,s7,-120 # 8001c000 <disk>
    80006080:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006082:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006084:	8a4e                	mv	s4,s3
    80006086:	a051                	j	8000610a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006088:	00fb86b3          	add	a3,s7,a5
    8000608c:	96da                	add	a3,a3,s6
    8000608e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006092:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006094:	0207c563          	bltz	a5,800060be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006098:	2485                	addiw	s1,s1,1
    8000609a:	0711                	addi	a4,a4,4
    8000609c:	25548063          	beq	s1,s5,800062dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060a2:	00018697          	auipc	a3,0x18
    800060a6:	f7668693          	addi	a3,a3,-138 # 8001e018 <disk+0x2018>
    800060aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060ac:	0006c583          	lbu	a1,0(a3)
    800060b0:	fde1                	bnez	a1,80006088 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060b2:	2785                	addiw	a5,a5,1
    800060b4:	0685                	addi	a3,a3,1
    800060b6:	ff879be3          	bne	a5,s8,800060ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ba:	57fd                	li	a5,-1
    800060bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060be:	02905a63          	blez	s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060c2:	f9042503          	lw	a0,-112(s0)
    800060c6:	00000097          	auipc	ra,0x0
    800060ca:	d90080e7          	jalr	-624(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060ce:	4785                	li	a5,1
    800060d0:	0297d163          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060d4:	f9442503          	lw	a0,-108(s0)
    800060d8:	00000097          	auipc	ra,0x0
    800060dc:	d7e080e7          	jalr	-642(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060e0:	4789                	li	a5,2
    800060e2:	0097d863          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060e6:	f9842503          	lw	a0,-104(s0)
    800060ea:	00000097          	auipc	ra,0x0
    800060ee:	d6c080e7          	jalr	-660(ra) # 80005e56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f2:	00018597          	auipc	a1,0x18
    800060f6:	03658593          	addi	a1,a1,54 # 8001e128 <disk+0x2128>
    800060fa:	00018517          	auipc	a0,0x18
    800060fe:	f1e50513          	addi	a0,a0,-226 # 8001e018 <disk+0x2018>
    80006102:	ffffc097          	auipc	ra,0xffffc
    80006106:	058080e7          	jalr	88(ra) # 8000215a <sleep>
  for(int i = 0; i < 3; i++){
    8000610a:	f9040713          	addi	a4,s0,-112
    8000610e:	84ce                	mv	s1,s3
    80006110:	bf41                	j	800060a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006112:	20058713          	addi	a4,a1,512
    80006116:	00471693          	slli	a3,a4,0x4
    8000611a:	00016717          	auipc	a4,0x16
    8000611e:	ee670713          	addi	a4,a4,-282 # 8001c000 <disk>
    80006122:	9736                	add	a4,a4,a3
    80006124:	4685                	li	a3,1
    80006126:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000612a:	20058713          	addi	a4,a1,512
    8000612e:	00471693          	slli	a3,a4,0x4
    80006132:	00016717          	auipc	a4,0x16
    80006136:	ece70713          	addi	a4,a4,-306 # 8001c000 <disk>
    8000613a:	9736                	add	a4,a4,a3
    8000613c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006140:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006144:	7679                	lui	a2,0xffffe
    80006146:	963e                	add	a2,a2,a5
    80006148:	00018697          	auipc	a3,0x18
    8000614c:	eb868693          	addi	a3,a3,-328 # 8001e000 <disk+0x2000>
    80006150:	6298                	ld	a4,0(a3)
    80006152:	9732                	add	a4,a4,a2
    80006154:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006156:	6298                	ld	a4,0(a3)
    80006158:	9732                	add	a4,a4,a2
    8000615a:	4541                	li	a0,16
    8000615c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000615e:	6298                	ld	a4,0(a3)
    80006160:	9732                	add	a4,a4,a2
    80006162:	4505                	li	a0,1
    80006164:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006168:	f9442703          	lw	a4,-108(s0)
    8000616c:	6288                	ld	a0,0(a3)
    8000616e:	962a                	add	a2,a2,a0
    80006170:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006174:	0712                	slli	a4,a4,0x4
    80006176:	6290                	ld	a2,0(a3)
    80006178:	963a                	add	a2,a2,a4
    8000617a:	05890513          	addi	a0,s2,88
    8000617e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006180:	6294                	ld	a3,0(a3)
    80006182:	96ba                	add	a3,a3,a4
    80006184:	40000613          	li	a2,1024
    80006188:	c690                	sw	a2,8(a3)
  if(write)
    8000618a:	140d0063          	beqz	s10,800062ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000618e:	00018697          	auipc	a3,0x18
    80006192:	e726b683          	ld	a3,-398(a3) # 8001e000 <disk+0x2000>
    80006196:	96ba                	add	a3,a3,a4
    80006198:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000619c:	00016817          	auipc	a6,0x16
    800061a0:	e6480813          	addi	a6,a6,-412 # 8001c000 <disk>
    800061a4:	00018517          	auipc	a0,0x18
    800061a8:	e5c50513          	addi	a0,a0,-420 # 8001e000 <disk+0x2000>
    800061ac:	6114                	ld	a3,0(a0)
    800061ae:	96ba                	add	a3,a3,a4
    800061b0:	00c6d603          	lhu	a2,12(a3)
    800061b4:	00166613          	ori	a2,a2,1
    800061b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061bc:	f9842683          	lw	a3,-104(s0)
    800061c0:	6110                	ld	a2,0(a0)
    800061c2:	9732                	add	a4,a4,a2
    800061c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c8:	20058613          	addi	a2,a1,512
    800061cc:	0612                	slli	a2,a2,0x4
    800061ce:	9642                	add	a2,a2,a6
    800061d0:	577d                	li	a4,-1
    800061d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d6:	00469713          	slli	a4,a3,0x4
    800061da:	6114                	ld	a3,0(a0)
    800061dc:	96ba                	add	a3,a3,a4
    800061de:	03078793          	addi	a5,a5,48
    800061e2:	97c2                	add	a5,a5,a6
    800061e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061e6:	611c                	ld	a5,0(a0)
    800061e8:	97ba                	add	a5,a5,a4
    800061ea:	4685                	li	a3,1
    800061ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ee:	611c                	ld	a5,0(a0)
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	4809                	li	a6,2
    800061f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061f8:	611c                	ld	a5,0(a0)
    800061fa:	973e                	add	a4,a4,a5
    800061fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006200:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006204:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006208:	6518                	ld	a4,8(a0)
    8000620a:	00275783          	lhu	a5,2(a4)
    8000620e:	8b9d                	andi	a5,a5,7
    80006210:	0786                	slli	a5,a5,0x1
    80006212:	97ba                	add	a5,a5,a4
    80006214:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006218:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000621c:	6518                	ld	a4,8(a0)
    8000621e:	00275783          	lhu	a5,2(a4)
    80006222:	2785                	addiw	a5,a5,1
    80006224:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006228:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006234:	00492703          	lw	a4,4(s2)
    80006238:	4785                	li	a5,1
    8000623a:	02f71163          	bne	a4,a5,8000625c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000623e:	00018997          	auipc	s3,0x18
    80006242:	eea98993          	addi	s3,s3,-278 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    80006246:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006248:	85ce                	mv	a1,s3
    8000624a:	854a                	mv	a0,s2
    8000624c:	ffffc097          	auipc	ra,0xffffc
    80006250:	f0e080e7          	jalr	-242(ra) # 8000215a <sleep>
  while(b->disk == 1) {
    80006254:	00492783          	lw	a5,4(s2)
    80006258:	fe9788e3          	beq	a5,s1,80006248 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000625c:	f9042903          	lw	s2,-112(s0)
    80006260:	20090793          	addi	a5,s2,512
    80006264:	00479713          	slli	a4,a5,0x4
    80006268:	00016797          	auipc	a5,0x16
    8000626c:	d9878793          	addi	a5,a5,-616 # 8001c000 <disk>
    80006270:	97ba                	add	a5,a5,a4
    80006272:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006276:	00018997          	auipc	s3,0x18
    8000627a:	d8a98993          	addi	s3,s3,-630 # 8001e000 <disk+0x2000>
    8000627e:	00491713          	slli	a4,s2,0x4
    80006282:	0009b783          	ld	a5,0(s3)
    80006286:	97ba                	add	a5,a5,a4
    80006288:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000628c:	854a                	mv	a0,s2
    8000628e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006292:	00000097          	auipc	ra,0x0
    80006296:	bc4080e7          	jalr	-1084(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000629a:	8885                	andi	s1,s1,1
    8000629c:	f0ed                	bnez	s1,8000627e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000629e:	00018517          	auipc	a0,0x18
    800062a2:	e8a50513          	addi	a0,a0,-374 # 8001e128 <disk+0x2128>
    800062a6:	ffffb097          	auipc	ra,0xffffb
    800062aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
}
    800062ae:	70a6                	ld	ra,104(sp)
    800062b0:	7406                	ld	s0,96(sp)
    800062b2:	64e6                	ld	s1,88(sp)
    800062b4:	6946                	ld	s2,80(sp)
    800062b6:	69a6                	ld	s3,72(sp)
    800062b8:	6a06                	ld	s4,64(sp)
    800062ba:	7ae2                	ld	s5,56(sp)
    800062bc:	7b42                	ld	s6,48(sp)
    800062be:	7ba2                	ld	s7,40(sp)
    800062c0:	7c02                	ld	s8,32(sp)
    800062c2:	6ce2                	ld	s9,24(sp)
    800062c4:	6d42                	ld	s10,16(sp)
    800062c6:	6165                	addi	sp,sp,112
    800062c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062ca:	00018697          	auipc	a3,0x18
    800062ce:	d366b683          	ld	a3,-714(a3) # 8001e000 <disk+0x2000>
    800062d2:	96ba                	add	a3,a3,a4
    800062d4:	4609                	li	a2,2
    800062d6:	00c69623          	sh	a2,12(a3)
    800062da:	b5c9                	j	8000619c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062dc:	f9042583          	lw	a1,-112(s0)
    800062e0:	20058793          	addi	a5,a1,512
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	00016517          	auipc	a0,0x16
    800062ea:	dc250513          	addi	a0,a0,-574 # 8001c0a8 <disk+0xa8>
    800062ee:	953e                	add	a0,a0,a5
  if(write)
    800062f0:	e20d11e3          	bnez	s10,80006112 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062f4:	20058713          	addi	a4,a1,512
    800062f8:	00471693          	slli	a3,a4,0x4
    800062fc:	00016717          	auipc	a4,0x16
    80006300:	d0470713          	addi	a4,a4,-764 # 8001c000 <disk>
    80006304:	9736                	add	a4,a4,a3
    80006306:	0a072423          	sw	zero,168(a4)
    8000630a:	b505                	j	8000612a <virtio_disk_rw+0xf4>

000000008000630c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000630c:	1101                	addi	sp,sp,-32
    8000630e:	ec06                	sd	ra,24(sp)
    80006310:	e822                	sd	s0,16(sp)
    80006312:	e426                	sd	s1,8(sp)
    80006314:	e04a                	sd	s2,0(sp)
    80006316:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006318:	00018517          	auipc	a0,0x18
    8000631c:	e1050513          	addi	a0,a0,-496 # 8001e128 <disk+0x2128>
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	8c4080e7          	jalr	-1852(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006328:	10001737          	lui	a4,0x10001
    8000632c:	533c                	lw	a5,96(a4)
    8000632e:	8b8d                	andi	a5,a5,3
    80006330:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006332:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006336:	00018797          	auipc	a5,0x18
    8000633a:	cca78793          	addi	a5,a5,-822 # 8001e000 <disk+0x2000>
    8000633e:	6b94                	ld	a3,16(a5)
    80006340:	0207d703          	lhu	a4,32(a5)
    80006344:	0026d783          	lhu	a5,2(a3)
    80006348:	06f70163          	beq	a4,a5,800063aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000634c:	00016917          	auipc	s2,0x16
    80006350:	cb490913          	addi	s2,s2,-844 # 8001c000 <disk>
    80006354:	00018497          	auipc	s1,0x18
    80006358:	cac48493          	addi	s1,s1,-852 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    8000635c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006360:	6898                	ld	a4,16(s1)
    80006362:	0204d783          	lhu	a5,32(s1)
    80006366:	8b9d                	andi	a5,a5,7
    80006368:	078e                	slli	a5,a5,0x3
    8000636a:	97ba                	add	a5,a5,a4
    8000636c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000636e:	20078713          	addi	a4,a5,512
    80006372:	0712                	slli	a4,a4,0x4
    80006374:	974a                	add	a4,a4,s2
    80006376:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000637a:	e731                	bnez	a4,800063c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000637c:	20078793          	addi	a5,a5,512
    80006380:	0792                	slli	a5,a5,0x4
    80006382:	97ca                	add	a5,a5,s2
    80006384:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006386:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000638a:	ffffc097          	auipc	ra,0xffffc
    8000638e:	f5c080e7          	jalr	-164(ra) # 800022e6 <wakeup>

    disk.used_idx += 1;
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	17c2                	slli	a5,a5,0x30
    8000639a:	93c1                	srli	a5,a5,0x30
    8000639c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063a0:	6898                	ld	a4,16(s1)
    800063a2:	00275703          	lhu	a4,2(a4)
    800063a6:	faf71be3          	bne	a4,a5,8000635c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063aa:	00018517          	auipc	a0,0x18
    800063ae:	d7e50513          	addi	a0,a0,-642 # 8001e128 <disk+0x2128>
    800063b2:	ffffb097          	auipc	ra,0xffffb
    800063b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
}
    800063ba:	60e2                	ld	ra,24(sp)
    800063bc:	6442                	ld	s0,16(sp)
    800063be:	64a2                	ld	s1,8(sp)
    800063c0:	6902                	ld	s2,0(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret
      panic("virtio_disk_intr status");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	46250513          	addi	a0,a0,1122 # 80008828 <syscalls+0x3c8>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
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
