
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
    80000068:	c9c78793          	addi	a5,a5,-868 # 80005d00 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    80000130:	3b6080e7          	jalr	950(ra) # 800024e2 <either_copyin>
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
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
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
    800001d8:	f14080e7          	jalr	-236(ra) # 800020e8 <sleep>
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
    80000214:	27c080e7          	jalr	636(ra) # 8000248c <either_copyout>
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
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
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
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
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
    800002f6:	246080e7          	jalr	582(ra) # 80002538 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e2e080e7          	jalr	-466(ra) # 80002274 <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
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
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
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
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
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
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
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
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
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
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
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
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
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
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
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
    800008a4:	9d4080e7          	jalr	-1580(ra) # 80002274 <wakeup>
    
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
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
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
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7bc080e7          	jalr	1980(ra) # 800020e8 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
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
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
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
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
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
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
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
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
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
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
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
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
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
    80000ed8:	8ac080e7          	jalr	-1876(ra) # 80002780 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e64080e7          	jalr	-412(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	fd6080e7          	jalr	-42(ra) # 80001eba <scheduler>
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
    80000f50:	80c080e7          	jalr	-2036(ra) # 80002758 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	82c080e7          	jalr	-2004(ra) # 80002780 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	dce080e7          	jalr	-562(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	ddc080e7          	jalr	-548(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	fba080e7          	jalr	-70(ra) # 80002f26 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	64a080e7          	jalr	1610(ra) # 800035be <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	5f4080e7          	jalr	1524(ra) # 80004570 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	ede080e7          	jalr	-290(ra) # 80005e62 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	cfc080e7          	jalr	-772(ra) # 80001c88 <userinit>
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
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
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
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	862a0a13          	addi	s4,s4,-1950 # 800170d0 <tickslock>
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
    800018a8:	16848493          	addi	s1,s1,360
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
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
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
    8000193a:	00015997          	auipc	s3,0x15
    8000193e:	79698993          	addi	s3,s3,1942 # 800170d0 <tickslock>
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
    80001968:	16848493          	addi	s1,s1,360
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
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
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
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
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
    80001a04:	e407a783          	lw	a5,-448(a5) # 80008840 <first.1683>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	d8e080e7          	jalr	-626(ra) # 80002798 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	e207a323          	sw	zero,-474(a5) # 80008840 <first.1683>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	b1a080e7          	jalr	-1254(ra) # 8000353e <fsinit>
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
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	86690913          	addi	s2,s2,-1946 # 800112a0 <pid_lock>
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
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b0a48493          	addi	s1,s1,-1270 # 800116d0 <proc>
    80001bce:	00015917          	auipc	s2,0x15
    80001bd2:	50290913          	addi	s2,s2,1282 # 800170d0 <tickslock>
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
    80001bee:	16848493          	addi	s1,s1,360
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a889                	j	80001c4a <allocproc+0x90>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	eec080e7          	jalr	-276(ra) # 80000af4 <kalloc>
    80001c10:	892a                	mv	s2,a0
    80001c12:	eca8                	sd	a0,88(s1)
    80001c14:	c131                	beqz	a0,80001c58 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e5c080e7          	jalr	-420(ra) # 80001a74 <proc_pagetable>
    80001c20:	892a                	mv	s2,a0
    80001c22:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c24:	c531                	beqz	a0,80001c70 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c26:	07000613          	li	a2,112
    80001c2a:	4581                	li	a1,0
    80001c2c:	06048513          	addi	a0,s1,96
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0b0080e7          	jalr	176(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c38:	00000797          	auipc	a5,0x0
    80001c3c:	db078793          	addi	a5,a5,-592 # 800019e8 <forkret>
    80001c40:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c42:	60bc                	ld	a5,64(s1)
    80001c44:	6705                	lui	a4,0x1
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	f4bc                	sd	a5,104(s1)
}
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	60e2                	ld	ra,24(sp)
    80001c4e:	6442                	ld	s0,16(sp)
    80001c50:	64a2                	ld	s1,8(sp)
    80001c52:	6902                	ld	s2,0(sp)
    80001c54:	6105                	addi	sp,sp,32
    80001c56:	8082                	ret
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	f08080e7          	jalr	-248(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	034080e7          	jalr	52(ra) # 80000c98 <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	bff1                	j	80001c4a <allocproc+0x90>
    freeproc(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	ef0080e7          	jalr	-272(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	01c080e7          	jalr	28(ra) # 80000c98 <release>
    return 0;
    80001c84:	84ca                	mv	s1,s2
    80001c86:	b7d1                	j	80001c4a <allocproc+0x90>

0000000080001c88 <userinit>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f28080e7          	jalr	-216(ra) # 80001bba <allocproc>
    80001c9a:	84aa                	mv	s1,a0
  initproc = p;
    80001c9c:	00007797          	auipc	a5,0x7
    80001ca0:	38a7b623          	sd	a0,908(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca4:	03400613          	li	a2,52
    80001ca8:	00007597          	auipc	a1,0x7
    80001cac:	ba858593          	addi	a1,a1,-1112 # 80008850 <initcode>
    80001cb0:	6928                	ld	a0,80(a0)
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	6b6080e7          	jalr	1718(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001cba:	6785                	lui	a5,0x1
    80001cbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc4:	6cb8                	ld	a4,88(s1)
    80001cc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc8:	4641                	li	a2,16
    80001cca:	00006597          	auipc	a1,0x6
    80001cce:	53658593          	addi	a1,a1,1334 # 80008200 <digits+0x1c0>
    80001cd2:	15848513          	addi	a0,s1,344
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	15c080e7          	jalr	348(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cde:	00006517          	auipc	a0,0x6
    80001ce2:	53250513          	addi	a0,a0,1330 # 80008210 <digits+0x1d0>
    80001ce6:	00002097          	auipc	ra,0x2
    80001cea:	286080e7          	jalr	646(ra) # 80003f6c <namei>
    80001cee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf2:	478d                	li	a5,3
    80001cf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	addi	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <growproc>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d18:	00000097          	auipc	ra,0x0
    80001d1c:	c98080e7          	jalr	-872(ra) # 800019b0 <myproc>
    80001d20:	892a                	mv	s2,a0
  sz = p->sz;
    80001d22:	652c                	ld	a1,72(a0)
    80001d24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d28:	00904f63          	bgtz	s1,80001d46 <growproc+0x3c>
  } else if(n < 0){
    80001d2c:	0204cc63          	bltz	s1,80001d64 <growproc+0x5a>
  p->sz = sz;
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d38:	4501                	li	a0,0
}
    80001d3a:	60e2                	ld	ra,24(sp)
    80001d3c:	6442                	ld	s0,16(sp)
    80001d3e:	64a2                	ld	s1,8(sp)
    80001d40:	6902                	ld	s2,0(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d46:	9e25                	addw	a2,a2,s1
    80001d48:	1602                	slli	a2,a2,0x20
    80001d4a:	9201                	srli	a2,a2,0x20
    80001d4c:	1582                	slli	a1,a1,0x20
    80001d4e:	9181                	srli	a1,a1,0x20
    80001d50:	6928                	ld	a0,80(a0)
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	6d0080e7          	jalr	1744(ra) # 80001422 <uvmalloc>
    80001d5a:	0005061b          	sext.w	a2,a0
    80001d5e:	fa69                	bnez	a2,80001d30 <growproc+0x26>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bfe1                	j	80001d3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	9e25                	addw	a2,a2,s1
    80001d66:	1602                	slli	a2,a2,0x20
    80001d68:	9201                	srli	a2,a2,0x20
    80001d6a:	1582                	slli	a1,a1,0x20
    80001d6c:	9181                	srli	a1,a1,0x20
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	66a080e7          	jalr	1642(ra) # 800013da <uvmdealloc>
    80001d78:	0005061b          	sext.w	a2,a0
    80001d7c:	bf55                	j	80001d30 <growproc+0x26>

0000000080001d7e <fork>:
{
    80001d7e:	7179                	addi	sp,sp,-48
    80001d80:	f406                	sd	ra,40(sp)
    80001d82:	f022                	sd	s0,32(sp)
    80001d84:	ec26                	sd	s1,24(sp)
    80001d86:	e84a                	sd	s2,16(sp)
    80001d88:	e44e                	sd	s3,8(sp)
    80001d8a:	e052                	sd	s4,0(sp)
    80001d8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	c22080e7          	jalr	-990(ra) # 800019b0 <myproc>
    80001d96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e22080e7          	jalr	-478(ra) # 80001bba <allocproc>
    80001da0:	10050b63          	beqz	a0,80001eb6 <fork+0x138>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7be080e7          	jalr	1982(ra) # 8000156e <uvmcopy>
    80001db8:	04054663          	bltz	a0,80001e04 <fork+0x86>
  np->sz = p->sz;
    80001dbc:	04893783          	ld	a5,72(s2)
    80001dc0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	05893683          	ld	a3,88(s2)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	0589b703          	ld	a4,88(s3)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df2:	0589b783          	ld	a5,88(s3)
    80001df6:	0607b823          	sd	zero,112(a5)
    80001dfa:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfe:	15000a13          	li	s4,336
    80001e02:	a03d                	j	80001e30 <fork+0xb2>
    freeproc(np);
    80001e04:	854e                	mv	a0,s3
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	d5c080e7          	jalr	-676(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e0e:	854e                	mv	a0,s3
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e88080e7          	jalr	-376(ra) # 80000c98 <release>
    return -1;
    80001e18:	5a7d                	li	s4,-1
    80001e1a:	a069                	j	80001ea4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	7e6080e7          	jalr	2022(ra) # 80004602 <filedup>
    80001e24:	009987b3          	add	a5,s3,s1
    80001e28:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	01448763          	beq	s1,s4,80001e3a <fork+0xbc>
    if(p->ofile[i])
    80001e30:	009907b3          	add	a5,s2,s1
    80001e34:	6388                	ld	a0,0(a5)
    80001e36:	f17d                	bnez	a0,80001e1c <fork+0x9e>
    80001e38:	bfcd                	j	80001e2a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e3a:	15093503          	ld	a0,336(s2)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	93a080e7          	jalr	-1734(ra) # 80003778 <idup>
    80001e46:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	15890593          	addi	a1,s2,344
    80001e50:	15898513          	addi	a0,s3,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	fde080e7          	jalr	-34(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e5c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e60:	854e                	mv	a0,s3
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e36080e7          	jalr	-458(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e6a:	0000f497          	auipc	s1,0xf
    80001e6e:	44e48493          	addi	s1,s1,1102 # 800112b8 <wait_lock>
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	d70080e7          	jalr	-656(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e7c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	d58080e7          	jalr	-680(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e94:	478d                	li	a5,3
    80001e96:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e9a:	854e                	mv	a0,s3
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
}
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	70a2                	ld	ra,40(sp)
    80001ea8:	7402                	ld	s0,32(sp)
    80001eaa:	64e2                	ld	s1,24(sp)
    80001eac:	6942                	ld	s2,16(sp)
    80001eae:	69a2                	ld	s3,8(sp)
    80001eb0:	6a02                	ld	s4,0(sp)
    80001eb2:	6145                	addi	sp,sp,48
    80001eb4:	8082                	ret
    return -1;
    80001eb6:	5a7d                	li	s4,-1
    80001eb8:	b7f5                	j	80001ea4 <fork+0x126>

0000000080001eba <scheduler>:
{
    80001eba:	711d                	addi	sp,sp,-96
    80001ebc:	ec86                	sd	ra,88(sp)
    80001ebe:	e8a2                	sd	s0,80(sp)
    80001ec0:	e4a6                	sd	s1,72(sp)
    80001ec2:	e0ca                	sd	s2,64(sp)
    80001ec4:	fc4e                	sd	s3,56(sp)
    80001ec6:	f852                	sd	s4,48(sp)
    80001ec8:	f456                	sd	s5,40(sp)
    80001eca:	f05a                	sd	s6,32(sp)
    80001ecc:	ec5e                	sd	s7,24(sp)
    80001ece:	e862                	sd	s8,16(sp)
    80001ed0:	e466                	sd	s9,8(sp)
    80001ed2:	e06a                	sd	s10,0(sp)
    80001ed4:	1080                	addi	s0,sp,96
    80001ed6:	8792                	mv	a5,tp
  int id = r_tp();
    80001ed8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eda:	00779b93          	slli	s7,a5,0x7
    80001ede:	0000f717          	auipc	a4,0xf
    80001ee2:	3c270713          	addi	a4,a4,962 # 800112a0 <pid_lock>
    80001ee6:	975e                	add	a4,a4,s7
    80001ee8:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001eec:	0000f717          	auipc	a4,0xf
    80001ef0:	3ec70713          	addi	a4,a4,1004 # 800112d8 <cpus+0x8>
    80001ef4:	9bba                	add	s7,s7,a4
    if(ticks<unpauseTicks)
    80001ef6:	00007c97          	auipc	s9,0x7
    80001efa:	13ec8c93          	addi	s9,s9,318 # 80009034 <ticks>
    80001efe:	00007c17          	auipc	s8,0x7
    80001f02:	132c0c13          	addi	s8,s8,306 # 80009030 <unpauseTicks>
          c->proc = p;
    80001f06:	079e                	slli	a5,a5,0x7
    80001f08:	0000fb17          	auipc	s6,0xf
    80001f0c:	398b0b13          	addi	s6,s6,920 # 800112a0 <pid_lock>
    80001f10:	9b3e                	add	s6,s6,a5
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    80001f12:	00007a17          	auipc	s4,0x7
    80001f16:	116a0a13          	addi	s4,s4,278 # 80009028 <initproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f22:	10079073          	csrw	sstatus,a5
    if(ticks<unpauseTicks)
    80001f26:	000ca703          	lw	a4,0(s9)
    80001f2a:	000c2783          	lw	a5,0(s8)
    80001f2e:	04f77a63          	bgeu	a4,a5,80001f82 <scheduler+0xc8>
        for(p = proc; p < &proc[NPROC]; p++){
    80001f32:	0000f497          	auipc	s1,0xf
    80001f36:	79e48493          	addi	s1,s1,1950 # 800116d0 <proc>
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    80001f3a:	4989                	li	s3,2
          if(p->state == RUNNING) 
    80001f3c:	4a91                	li	s5,4
              p->state = RUNNABLE;
    80001f3e:	4d0d                	li	s10,3
        for(p = proc; p < &proc[NPROC]; p++){
    80001f40:	00015917          	auipc	s2,0x15
    80001f44:	19090913          	addi	s2,s2,400 # 800170d0 <tickslock>
    80001f48:	a811                	j	80001f5c <scheduler+0xa2>
          release(&p->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	d4c080e7          	jalr	-692(ra) # 80000c98 <release>
        for(p = proc; p < &proc[NPROC]; p++){
    80001f54:	16848493          	addi	s1,s1,360
    80001f58:	fd2481e3          	beq	s1,s2,80001f1a <scheduler+0x60>
          if(p->pid == SHELL_PID || p->pid == initproc->pid)
    80001f5c:	589c                	lw	a5,48(s1)
    80001f5e:	ff378be3          	beq	a5,s3,80001f54 <scheduler+0x9a>
    80001f62:	000a3703          	ld	a4,0(s4)
    80001f66:	5b18                	lw	a4,48(a4)
    80001f68:	fef706e3          	beq	a4,a5,80001f54 <scheduler+0x9a>
          acquire(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	c76080e7          	jalr	-906(ra) # 80000be4 <acquire>
          if(p->state == RUNNING) 
    80001f76:	4c9c                	lw	a5,24(s1)
    80001f78:	fd5799e3          	bne	a5,s5,80001f4a <scheduler+0x90>
              p->state = RUNNABLE;
    80001f7c:	01a4ac23          	sw	s10,24(s1)
    80001f80:	b7e9                	j	80001f4a <scheduler+0x90>
       for(p = proc; p < &proc[NPROC]; p++){
    80001f82:	0000f497          	auipc	s1,0xf
    80001f86:	74e48493          	addi	s1,s1,1870 # 800116d0 <proc>
          if(p->state == RUNNABLE) {
    80001f8a:	498d                	li	s3,3
          p->state = RUNNING;
    80001f8c:	4a91                	li	s5,4
       for(p = proc; p < &proc[NPROC]; p++){
    80001f8e:	00015917          	auipc	s2,0x15
    80001f92:	14290913          	addi	s2,s2,322 # 800170d0 <tickslock>
    80001f96:	a03d                	j	80001fc4 <scheduler+0x10a>
          p->state = RUNNING;
    80001f98:	0154ac23          	sw	s5,24(s1)
          c->proc = p;
    80001f9c:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    80001fa0:	06048593          	addi	a1,s1,96
    80001fa4:	855e                	mv	a0,s7
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	748080e7          	jalr	1864(ra) # 800026ee <swtch>
          c->proc = 0;
    80001fae:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	ce4080e7          	jalr	-796(ra) # 80000c98 <release>
       for(p = proc; p < &proc[NPROC]; p++){
    80001fbc:	16848493          	addi	s1,s1,360
    80001fc0:	f5248de3          	beq	s1,s2,80001f1a <scheduler+0x60>
          acquire(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
          if(p->state == RUNNABLE) {
    80001fce:	4c9c                	lw	a5,24(s1)
    80001fd0:	ff3791e3          	bne	a5,s3,80001fb2 <scheduler+0xf8>
    80001fd4:	b7d1                	j	80001f98 <scheduler+0xde>

0000000080001fd6 <sched>:
{
    80001fd6:	7179                	addi	sp,sp,-48
    80001fd8:	f406                	sd	ra,40(sp)
    80001fda:	f022                	sd	s0,32(sp)
    80001fdc:	ec26                	sd	s1,24(sp)
    80001fde:	e84a                	sd	s2,16(sp)
    80001fe0:	e44e                	sd	s3,8(sp)
    80001fe2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	9cc080e7          	jalr	-1588(ra) # 800019b0 <myproc>
    80001fec:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	b7c080e7          	jalr	-1156(ra) # 80000b6a <holding>
    80001ff6:	c93d                	beqz	a0,8000206c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffa:	2781                	sext.w	a5,a5
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	0000f717          	auipc	a4,0xf
    80002002:	2a270713          	addi	a4,a4,674 # 800112a0 <pid_lock>
    80002006:	97ba                	add	a5,a5,a4
    80002008:	0a87a703          	lw	a4,168(a5)
    8000200c:	4785                	li	a5,1
    8000200e:	06f71763          	bne	a4,a5,8000207c <sched+0xa6>
  if(p->state == RUNNING)
    80002012:	4c98                	lw	a4,24(s1)
    80002014:	4791                	li	a5,4
    80002016:	06f70b63          	beq	a4,a5,8000208c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000201e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002020:	efb5                	bnez	a5,8000209c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002024:	0000f917          	auipc	s2,0xf
    80002028:	27c90913          	addi	s2,s2,636 # 800112a0 <pid_lock>
    8000202c:	2781                	sext.w	a5,a5
    8000202e:	079e                	slli	a5,a5,0x7
    80002030:	97ca                	add	a5,a5,s2
    80002032:	0ac7a983          	lw	s3,172(a5)
    80002036:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002038:	2781                	sext.w	a5,a5
    8000203a:	079e                	slli	a5,a5,0x7
    8000203c:	0000f597          	auipc	a1,0xf
    80002040:	29c58593          	addi	a1,a1,668 # 800112d8 <cpus+0x8>
    80002044:	95be                	add	a1,a1,a5
    80002046:	06048513          	addi	a0,s1,96
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	6a4080e7          	jalr	1700(ra) # 800026ee <swtch>
    80002052:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	97ca                	add	a5,a5,s2
    8000205a:	0b37a623          	sw	s3,172(a5)
}
    8000205e:	70a2                	ld	ra,40(sp)
    80002060:	7402                	ld	s0,32(sp)
    80002062:	64e2                	ld	s1,24(sp)
    80002064:	6942                	ld	s2,16(sp)
    80002066:	69a2                	ld	s3,8(sp)
    80002068:	6145                	addi	sp,sp,48
    8000206a:	8082                	ret
    panic("sched p->lock");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	1ac50513          	addi	a0,a0,428 # 80008218 <digits+0x1d8>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4ca080e7          	jalr	1226(ra) # 8000053e <panic>
    panic("sched locks");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	1ac50513          	addi	a0,a0,428 # 80008228 <digits+0x1e8>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4ba080e7          	jalr	1210(ra) # 8000053e <panic>
    panic("sched running");
    8000208c:	00006517          	auipc	a0,0x6
    80002090:	1ac50513          	addi	a0,a0,428 # 80008238 <digits+0x1f8>
    80002094:	ffffe097          	auipc	ra,0xffffe
    80002098:	4aa080e7          	jalr	1194(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	1ac50513          	addi	a0,a0,428 # 80008248 <digits+0x208>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	49a080e7          	jalr	1178(ra) # 8000053e <panic>

00000000800020ac <yield>:
{
    800020ac:	1101                	addi	sp,sp,-32
    800020ae:	ec06                	sd	ra,24(sp)
    800020b0:	e822                	sd	s0,16(sp)
    800020b2:	e426                	sd	s1,8(sp)
    800020b4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	8fa080e7          	jalr	-1798(ra) # 800019b0 <myproc>
    800020be:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b24080e7          	jalr	-1244(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020c8:	478d                	li	a5,3
    800020ca:	cc9c                	sw	a5,24(s1)
  sched();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	f0a080e7          	jalr	-246(ra) # 80001fd6 <sched>
  release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	bc2080e7          	jalr	-1086(ra) # 80000c98 <release>
}
    800020de:	60e2                	ld	ra,24(sp)
    800020e0:	6442                	ld	s0,16(sp)
    800020e2:	64a2                	ld	s1,8(sp)
    800020e4:	6105                	addi	sp,sp,32
    800020e6:	8082                	ret

00000000800020e8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	1800                	addi	s0,sp,48
    800020f6:	89aa                	mv	s3,a0
    800020f8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	8b6080e7          	jalr	-1866(ra) # 800019b0 <myproc>
    80002102:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	ae0080e7          	jalr	-1312(ra) # 80000be4 <acquire>
  release(lk);
    8000210c:	854a                	mv	a0,s2
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002116:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000211a:	4789                	li	a5,2
    8000211c:	cc9c                	sw	a5,24(s1)

  sched();
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	eb8080e7          	jalr	-328(ra) # 80001fd6 <sched>

  // Tidy up.
  p->chan = 0;
    80002126:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	b6c080e7          	jalr	-1172(ra) # 80000c98 <release>
  acquire(lk);
    80002134:	854a                	mv	a0,s2
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	aae080e7          	jalr	-1362(ra) # 80000be4 <acquire>
}
    8000213e:	70a2                	ld	ra,40(sp)
    80002140:	7402                	ld	s0,32(sp)
    80002142:	64e2                	ld	s1,24(sp)
    80002144:	6942                	ld	s2,16(sp)
    80002146:	69a2                	ld	s3,8(sp)
    80002148:	6145                	addi	sp,sp,48
    8000214a:	8082                	ret

000000008000214c <wait>:
{
    8000214c:	715d                	addi	sp,sp,-80
    8000214e:	e486                	sd	ra,72(sp)
    80002150:	e0a2                	sd	s0,64(sp)
    80002152:	fc26                	sd	s1,56(sp)
    80002154:	f84a                	sd	s2,48(sp)
    80002156:	f44e                	sd	s3,40(sp)
    80002158:	f052                	sd	s4,32(sp)
    8000215a:	ec56                	sd	s5,24(sp)
    8000215c:	e85a                	sd	s6,16(sp)
    8000215e:	e45e                	sd	s7,8(sp)
    80002160:	e062                	sd	s8,0(sp)
    80002162:	0880                	addi	s0,sp,80
    80002164:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	84a080e7          	jalr	-1974(ra) # 800019b0 <myproc>
    8000216e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002170:	0000f517          	auipc	a0,0xf
    80002174:	14850513          	addi	a0,a0,328 # 800112b8 <wait_lock>
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	a6c080e7          	jalr	-1428(ra) # 80000be4 <acquire>
    havekids = 0;
    80002180:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002182:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002184:	00015997          	auipc	s3,0x15
    80002188:	f4c98993          	addi	s3,s3,-180 # 800170d0 <tickslock>
        havekids = 1;
    8000218c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000218e:	0000fc17          	auipc	s8,0xf
    80002192:	12ac0c13          	addi	s8,s8,298 # 800112b8 <wait_lock>
    havekids = 0;
    80002196:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002198:	0000f497          	auipc	s1,0xf
    8000219c:	53848493          	addi	s1,s1,1336 # 800116d0 <proc>
    800021a0:	a0bd                	j	8000220e <wait+0xc2>
          pid = np->pid;
    800021a2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021a6:	000b0e63          	beqz	s6,800021c2 <wait+0x76>
    800021aa:	4691                	li	a3,4
    800021ac:	02c48613          	addi	a2,s1,44
    800021b0:	85da                	mv	a1,s6
    800021b2:	05093503          	ld	a0,80(s2)
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	4bc080e7          	jalr	1212(ra) # 80001672 <copyout>
    800021be:	02054563          	bltz	a0,800021e8 <wait+0x9c>
          freeproc(np);
    800021c2:	8526                	mv	a0,s1
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	99e080e7          	jalr	-1634(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	aca080e7          	jalr	-1334(ra) # 80000c98 <release>
          release(&wait_lock);
    800021d6:	0000f517          	auipc	a0,0xf
    800021da:	0e250513          	addi	a0,a0,226 # 800112b8 <wait_lock>
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
          return pid;
    800021e6:	a09d                	j	8000224c <wait+0x100>
            release(&np->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
            release(&wait_lock);
    800021f2:	0000f517          	auipc	a0,0xf
    800021f6:	0c650513          	addi	a0,a0,198 # 800112b8 <wait_lock>
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a9e080e7          	jalr	-1378(ra) # 80000c98 <release>
            return -1;
    80002202:	59fd                	li	s3,-1
    80002204:	a0a1                	j	8000224c <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002206:	16848493          	addi	s1,s1,360
    8000220a:	03348463          	beq	s1,s3,80002232 <wait+0xe6>
      if(np->parent == p){
    8000220e:	7c9c                	ld	a5,56(s1)
    80002210:	ff279be3          	bne	a5,s2,80002206 <wait+0xba>
        acquire(&np->lock);
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000221e:	4c9c                	lw	a5,24(s1)
    80002220:	f94781e3          	beq	a5,s4,800021a2 <wait+0x56>
        release(&np->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a72080e7          	jalr	-1422(ra) # 80000c98 <release>
        havekids = 1;
    8000222e:	8756                	mv	a4,s5
    80002230:	bfd9                	j	80002206 <wait+0xba>
    if(!havekids || p->killed){
    80002232:	c701                	beqz	a4,8000223a <wait+0xee>
    80002234:	02892783          	lw	a5,40(s2)
    80002238:	c79d                	beqz	a5,80002266 <wait+0x11a>
      release(&wait_lock);
    8000223a:	0000f517          	auipc	a0,0xf
    8000223e:	07e50513          	addi	a0,a0,126 # 800112b8 <wait_lock>
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
      return -1;
    8000224a:	59fd                	li	s3,-1
}
    8000224c:	854e                	mv	a0,s3
    8000224e:	60a6                	ld	ra,72(sp)
    80002250:	6406                	ld	s0,64(sp)
    80002252:	74e2                	ld	s1,56(sp)
    80002254:	7942                	ld	s2,48(sp)
    80002256:	79a2                	ld	s3,40(sp)
    80002258:	7a02                	ld	s4,32(sp)
    8000225a:	6ae2                	ld	s5,24(sp)
    8000225c:	6b42                	ld	s6,16(sp)
    8000225e:	6ba2                	ld	s7,8(sp)
    80002260:	6c02                	ld	s8,0(sp)
    80002262:	6161                	addi	sp,sp,80
    80002264:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002266:	85e2                	mv	a1,s8
    80002268:	854a                	mv	a0,s2
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	e7e080e7          	jalr	-386(ra) # 800020e8 <sleep>
    havekids = 0;
    80002272:	b715                	j	80002196 <wait+0x4a>

0000000080002274 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002274:	7139                	addi	sp,sp,-64
    80002276:	fc06                	sd	ra,56(sp)
    80002278:	f822                	sd	s0,48(sp)
    8000227a:	f426                	sd	s1,40(sp)
    8000227c:	f04a                	sd	s2,32(sp)
    8000227e:	ec4e                	sd	s3,24(sp)
    80002280:	e852                	sd	s4,16(sp)
    80002282:	e456                	sd	s5,8(sp)
    80002284:	0080                	addi	s0,sp,64
    80002286:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002288:	0000f497          	auipc	s1,0xf
    8000228c:	44848493          	addi	s1,s1,1096 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002290:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002292:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002294:	00015917          	auipc	s2,0x15
    80002298:	e3c90913          	addi	s2,s2,-452 # 800170d0 <tickslock>
    8000229c:	a821                	j	800022b4 <wakeup+0x40>
        p->state = RUNNABLE;
    8000229e:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9f4080e7          	jalr	-1548(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022ac:	16848493          	addi	s1,s1,360
    800022b0:	03248463          	beq	s1,s2,800022d8 <wakeup+0x64>
    if(p != myproc()){
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	6fc080e7          	jalr	1788(ra) # 800019b0 <myproc>
    800022bc:	fea488e3          	beq	s1,a0,800022ac <wakeup+0x38>
      acquire(&p->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	922080e7          	jalr	-1758(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022ca:	4c9c                	lw	a5,24(s1)
    800022cc:	fd379be3          	bne	a5,s3,800022a2 <wakeup+0x2e>
    800022d0:	709c                	ld	a5,32(s1)
    800022d2:	fd4798e3          	bne	a5,s4,800022a2 <wakeup+0x2e>
    800022d6:	b7e1                	j	8000229e <wakeup+0x2a>
    }
  }
}
    800022d8:	70e2                	ld	ra,56(sp)
    800022da:	7442                	ld	s0,48(sp)
    800022dc:	74a2                	ld	s1,40(sp)
    800022de:	7902                	ld	s2,32(sp)
    800022e0:	69e2                	ld	s3,24(sp)
    800022e2:	6a42                	ld	s4,16(sp)
    800022e4:	6aa2                	ld	s5,8(sp)
    800022e6:	6121                	addi	sp,sp,64
    800022e8:	8082                	ret

00000000800022ea <reparent>:
{
    800022ea:	7179                	addi	sp,sp,-48
    800022ec:	f406                	sd	ra,40(sp)
    800022ee:	f022                	sd	s0,32(sp)
    800022f0:	ec26                	sd	s1,24(sp)
    800022f2:	e84a                	sd	s2,16(sp)
    800022f4:	e44e                	sd	s3,8(sp)
    800022f6:	e052                	sd	s4,0(sp)
    800022f8:	1800                	addi	s0,sp,48
    800022fa:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022fc:	0000f497          	auipc	s1,0xf
    80002300:	3d448493          	addi	s1,s1,980 # 800116d0 <proc>
      pp->parent = initproc;
    80002304:	00007a17          	auipc	s4,0x7
    80002308:	d24a0a13          	addi	s4,s4,-732 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000230c:	00015997          	auipc	s3,0x15
    80002310:	dc498993          	addi	s3,s3,-572 # 800170d0 <tickslock>
    80002314:	a029                	j	8000231e <reparent+0x34>
    80002316:	16848493          	addi	s1,s1,360
    8000231a:	01348d63          	beq	s1,s3,80002334 <reparent+0x4a>
    if(pp->parent == p){
    8000231e:	7c9c                	ld	a5,56(s1)
    80002320:	ff279be3          	bne	a5,s2,80002316 <reparent+0x2c>
      pp->parent = initproc;
    80002324:	000a3503          	ld	a0,0(s4)
    80002328:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000232a:	00000097          	auipc	ra,0x0
    8000232e:	f4a080e7          	jalr	-182(ra) # 80002274 <wakeup>
    80002332:	b7d5                	j	80002316 <reparent+0x2c>
}
    80002334:	70a2                	ld	ra,40(sp)
    80002336:	7402                	ld	s0,32(sp)
    80002338:	64e2                	ld	s1,24(sp)
    8000233a:	6942                	ld	s2,16(sp)
    8000233c:	69a2                	ld	s3,8(sp)
    8000233e:	6a02                	ld	s4,0(sp)
    80002340:	6145                	addi	sp,sp,48
    80002342:	8082                	ret

0000000080002344 <exit>:
{
    80002344:	7179                	addi	sp,sp,-48
    80002346:	f406                	sd	ra,40(sp)
    80002348:	f022                	sd	s0,32(sp)
    8000234a:	ec26                	sd	s1,24(sp)
    8000234c:	e84a                	sd	s2,16(sp)
    8000234e:	e44e                	sd	s3,8(sp)
    80002350:	e052                	sd	s4,0(sp)
    80002352:	1800                	addi	s0,sp,48
    80002354:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	65a080e7          	jalr	1626(ra) # 800019b0 <myproc>
    8000235e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002360:	00007797          	auipc	a5,0x7
    80002364:	cc87b783          	ld	a5,-824(a5) # 80009028 <initproc>
    80002368:	0d050493          	addi	s1,a0,208
    8000236c:	15050913          	addi	s2,a0,336
    80002370:	02a79363          	bne	a5,a0,80002396 <exit+0x52>
    panic("init exiting");
    80002374:	00006517          	auipc	a0,0x6
    80002378:	eec50513          	addi	a0,a0,-276 # 80008260 <digits+0x220>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>
      fileclose(f);
    80002384:	00002097          	auipc	ra,0x2
    80002388:	2d0080e7          	jalr	720(ra) # 80004654 <fileclose>
      p->ofile[fd] = 0;
    8000238c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002390:	04a1                	addi	s1,s1,8
    80002392:	01248563          	beq	s1,s2,8000239c <exit+0x58>
    if(p->ofile[fd]){
    80002396:	6088                	ld	a0,0(s1)
    80002398:	f575                	bnez	a0,80002384 <exit+0x40>
    8000239a:	bfdd                	j	80002390 <exit+0x4c>
  begin_op();
    8000239c:	00002097          	auipc	ra,0x2
    800023a0:	dec080e7          	jalr	-532(ra) # 80004188 <begin_op>
  iput(p->cwd);
    800023a4:	1509b503          	ld	a0,336(s3)
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	5c8080e7          	jalr	1480(ra) # 80003970 <iput>
  end_op();
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	e58080e7          	jalr	-424(ra) # 80004208 <end_op>
  p->cwd = 0;
    800023b8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023bc:	0000f497          	auipc	s1,0xf
    800023c0:	efc48493          	addi	s1,s1,-260 # 800112b8 <wait_lock>
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	81e080e7          	jalr	-2018(ra) # 80000be4 <acquire>
  reparent(p);
    800023ce:	854e                	mv	a0,s3
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	f1a080e7          	jalr	-230(ra) # 800022ea <reparent>
  wakeup(p->parent);
    800023d8:	0389b503          	ld	a0,56(s3)
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	e98080e7          	jalr	-360(ra) # 80002274 <wakeup>
  acquire(&p->lock);
    800023e4:	854e                	mv	a0,s3
    800023e6:	ffffe097          	auipc	ra,0xffffe
    800023ea:	7fe080e7          	jalr	2046(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023ee:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023f2:	4795                	li	a5,5
    800023f4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
  sched();
    80002402:	00000097          	auipc	ra,0x0
    80002406:	bd4080e7          	jalr	-1068(ra) # 80001fd6 <sched>
  panic("zombie exit");
    8000240a:	00006517          	auipc	a0,0x6
    8000240e:	e6650513          	addi	a0,a0,-410 # 80008270 <digits+0x230>
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	12c080e7          	jalr	300(ra) # 8000053e <panic>

000000008000241a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000241a:	7179                	addi	sp,sp,-48
    8000241c:	f406                	sd	ra,40(sp)
    8000241e:	f022                	sd	s0,32(sp)
    80002420:	ec26                	sd	s1,24(sp)
    80002422:	e84a                	sd	s2,16(sp)
    80002424:	e44e                	sd	s3,8(sp)
    80002426:	1800                	addi	s0,sp,48
    80002428:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000242a:	0000f497          	auipc	s1,0xf
    8000242e:	2a648493          	addi	s1,s1,678 # 800116d0 <proc>
    80002432:	00015997          	auipc	s3,0x15
    80002436:	c9e98993          	addi	s3,s3,-866 # 800170d0 <tickslock>
    acquire(&p->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002444:	589c                	lw	a5,48(s1)
    80002446:	01278d63          	beq	a5,s2,80002460 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002454:	16848493          	addi	s1,s1,360
    80002458:	ff3491e3          	bne	s1,s3,8000243a <kill+0x20>
  }
  return -1;
    8000245c:	557d                	li	a0,-1
    8000245e:	a829                	j	80002478 <kill+0x5e>
      p->killed = 1;
    80002460:	4785                	li	a5,1
    80002462:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002464:	4c98                	lw	a4,24(s1)
    80002466:	4789                	li	a5,2
    80002468:	00f70f63          	beq	a4,a5,80002486 <kill+0x6c>
      release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	82a080e7          	jalr	-2006(ra) # 80000c98 <release>
      return 0;
    80002476:	4501                	li	a0,0
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6145                	addi	sp,sp,48
    80002484:	8082                	ret
        p->state = RUNNABLE;
    80002486:	478d                	li	a5,3
    80002488:	cc9c                	sw	a5,24(s1)
    8000248a:	b7cd                	j	8000246c <kill+0x52>

000000008000248c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000248c:	7179                	addi	sp,sp,-48
    8000248e:	f406                	sd	ra,40(sp)
    80002490:	f022                	sd	s0,32(sp)
    80002492:	ec26                	sd	s1,24(sp)
    80002494:	e84a                	sd	s2,16(sp)
    80002496:	e44e                	sd	s3,8(sp)
    80002498:	e052                	sd	s4,0(sp)
    8000249a:	1800                	addi	s0,sp,48
    8000249c:	84aa                	mv	s1,a0
    8000249e:	892e                	mv	s2,a1
    800024a0:	89b2                	mv	s3,a2
    800024a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	50c080e7          	jalr	1292(ra) # 800019b0 <myproc>
  if(user_dst){
    800024ac:	c08d                	beqz	s1,800024ce <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ae:	86d2                	mv	a3,s4
    800024b0:	864e                	mv	a2,s3
    800024b2:	85ca                	mv	a1,s2
    800024b4:	6928                	ld	a0,80(a0)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	1bc080e7          	jalr	444(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024be:	70a2                	ld	ra,40(sp)
    800024c0:	7402                	ld	s0,32(sp)
    800024c2:	64e2                	ld	s1,24(sp)
    800024c4:	6942                	ld	s2,16(sp)
    800024c6:	69a2                	ld	s3,8(sp)
    800024c8:	6a02                	ld	s4,0(sp)
    800024ca:	6145                	addi	sp,sp,48
    800024cc:	8082                	ret
    memmove((char *)dst, src, len);
    800024ce:	000a061b          	sext.w	a2,s4
    800024d2:	85ce                	mv	a1,s3
    800024d4:	854a                	mv	a0,s2
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	86a080e7          	jalr	-1942(ra) # 80000d40 <memmove>
    return 0;
    800024de:	8526                	mv	a0,s1
    800024e0:	bff9                	j	800024be <either_copyout+0x32>

00000000800024e2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e2:	7179                	addi	sp,sp,-48
    800024e4:	f406                	sd	ra,40(sp)
    800024e6:	f022                	sd	s0,32(sp)
    800024e8:	ec26                	sd	s1,24(sp)
    800024ea:	e84a                	sd	s2,16(sp)
    800024ec:	e44e                	sd	s3,8(sp)
    800024ee:	e052                	sd	s4,0(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	892a                	mv	s2,a0
    800024f4:	84ae                	mv	s1,a1
    800024f6:	89b2                	mv	s3,a2
    800024f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	4b6080e7          	jalr	1206(ra) # 800019b0 <myproc>
  if(user_src){
    80002502:	c08d                	beqz	s1,80002524 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002504:	86d2                	mv	a3,s4
    80002506:	864e                	mv	a2,s3
    80002508:	85ca                	mv	a1,s2
    8000250a:	6928                	ld	a0,80(a0)
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	1f2080e7          	jalr	498(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002514:	70a2                	ld	ra,40(sp)
    80002516:	7402                	ld	s0,32(sp)
    80002518:	64e2                	ld	s1,24(sp)
    8000251a:	6942                	ld	s2,16(sp)
    8000251c:	69a2                	ld	s3,8(sp)
    8000251e:	6a02                	ld	s4,0(sp)
    80002520:	6145                	addi	sp,sp,48
    80002522:	8082                	ret
    memmove(dst, (char*)src, len);
    80002524:	000a061b          	sext.w	a2,s4
    80002528:	85ce                	mv	a1,s3
    8000252a:	854a                	mv	a0,s2
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	814080e7          	jalr	-2028(ra) # 80000d40 <memmove>
    return 0;
    80002534:	8526                	mv	a0,s1
    80002536:	bff9                	j	80002514 <either_copyin+0x32>

0000000080002538 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002538:	715d                	addi	sp,sp,-80
    8000253a:	e486                	sd	ra,72(sp)
    8000253c:	e0a2                	sd	s0,64(sp)
    8000253e:	fc26                	sd	s1,56(sp)
    80002540:	f84a                	sd	s2,48(sp)
    80002542:	f44e                	sd	s3,40(sp)
    80002544:	f052                	sd	s4,32(sp)
    80002546:	ec56                	sd	s5,24(sp)
    80002548:	e85a                	sd	s6,16(sp)
    8000254a:	e45e                	sd	s7,8(sp)
    8000254c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000254e:	00006517          	auipc	a0,0x6
    80002552:	b7a50513          	addi	a0,a0,-1158 # 800080c8 <digits+0x88>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	032080e7          	jalr	50(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000255e:	0000f497          	auipc	s1,0xf
    80002562:	2ca48493          	addi	s1,s1,714 # 80011828 <proc+0x158>
    80002566:	00015917          	auipc	s2,0x15
    8000256a:	cc290913          	addi	s2,s2,-830 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002570:	00006997          	auipc	s3,0x6
    80002574:	d1098993          	addi	s3,s3,-752 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002578:	00006a97          	auipc	s5,0x6
    8000257c:	d10a8a93          	addi	s5,s5,-752 # 80008288 <digits+0x248>
    printf("\n");
    80002580:	00006a17          	auipc	s4,0x6
    80002584:	b48a0a13          	addi	s4,s4,-1208 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002588:	00006b97          	auipc	s7,0x6
    8000258c:	d50b8b93          	addi	s7,s7,-688 # 800082d8 <states.1720>
    80002590:	a00d                	j	800025b2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002592:	ed86a583          	lw	a1,-296(a3)
    80002596:	8556                	mv	a0,s5
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	ff0080e7          	jalr	-16(ra) # 80000588 <printf>
    printf("\n");
    800025a0:	8552                	mv	a0,s4
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	fe6080e7          	jalr	-26(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025aa:	16848493          	addi	s1,s1,360
    800025ae:	03248163          	beq	s1,s2,800025d0 <procdump+0x98>
    if(p->state == UNUSED)
    800025b2:	86a6                	mv	a3,s1
    800025b4:	ec04a783          	lw	a5,-320(s1)
    800025b8:	dbed                	beqz	a5,800025aa <procdump+0x72>
      state = "???";
    800025ba:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025bc:	fcfb6be3          	bltu	s6,a5,80002592 <procdump+0x5a>
    800025c0:	1782                	slli	a5,a5,0x20
    800025c2:	9381                	srli	a5,a5,0x20
    800025c4:	078e                	slli	a5,a5,0x3
    800025c6:	97de                	add	a5,a5,s7
    800025c8:	6390                	ld	a2,0(a5)
    800025ca:	f661                	bnez	a2,80002592 <procdump+0x5a>
      state = "???";
    800025cc:	864e                	mv	a2,s3
    800025ce:	b7d1                	j	80002592 <procdump+0x5a>
  }
}
    800025d0:	60a6                	ld	ra,72(sp)
    800025d2:	6406                	ld	s0,64(sp)
    800025d4:	74e2                	ld	s1,56(sp)
    800025d6:	7942                	ld	s2,48(sp)
    800025d8:	79a2                	ld	s3,40(sp)
    800025da:	7a02                	ld	s4,32(sp)
    800025dc:	6ae2                	ld	s5,24(sp)
    800025de:	6b42                	ld	s6,16(sp)
    800025e0:	6ba2                	ld	s7,8(sp)
    800025e2:	6161                	addi	sp,sp,80
    800025e4:	8082                	ret

00000000800025e6 <pause_system>:

int
pause_system(int seconds)
{
    800025e6:	1101                	addi	sp,sp,-32
    800025e8:	ec06                	sd	ra,24(sp)
    800025ea:	e822                	sd	s0,16(sp)
    800025ec:	e426                	sd	s1,8(sp)
    800025ee:	1000                	addi	s0,sp,32
    800025f0:	84aa                	mv	s1,a0
  acquire(&tickslock);
    800025f2:	00015517          	auipc	a0,0x15
    800025f6:	ade50513          	addi	a0,a0,-1314 # 800170d0 <tickslock>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	5ea080e7          	jalr	1514(ra) # 80000be4 <acquire>
  unpauseTicks = ticks + (seconds*10);
    80002602:	0024979b          	slliw	a5,s1,0x2
    80002606:	9fa5                	addw	a5,a5,s1
    80002608:	0017979b          	slliw	a5,a5,0x1
    8000260c:	00007717          	auipc	a4,0x7
    80002610:	a2872703          	lw	a4,-1496(a4) # 80009034 <ticks>
    80002614:	9fb9                	addw	a5,a5,a4
    80002616:	00007717          	auipc	a4,0x7
    8000261a:	a0f72d23          	sw	a5,-1510(a4) # 80009030 <unpauseTicks>
  release(&tickslock);
    8000261e:	00015517          	auipc	a0,0x15
    80002622:	ab250513          	addi	a0,a0,-1358 # 800170d0 <tickslock>
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	672080e7          	jalr	1650(ra) # 80000c98 <release>
  yield();
    8000262e:	00000097          	auipc	ra,0x0
    80002632:	a7e080e7          	jalr	-1410(ra) # 800020ac <yield>
  return 0;
}
    80002636:	4501                	li	a0,0
    80002638:	60e2                	ld	ra,24(sp)
    8000263a:	6442                	ld	s0,16(sp)
    8000263c:	64a2                	ld	s1,8(sp)
    8000263e:	6105                	addi	sp,sp,32
    80002640:	8082                	ret

0000000080002642 <kill_system>:

int
kill_system(void)
{
    80002642:	7179                	addi	sp,sp,-48
    80002644:	f406                	sd	ra,40(sp)
    80002646:	f022                	sd	s0,32(sp)
    80002648:	ec26                	sd	s1,24(sp)
    8000264a:	e84a                	sd	s2,16(sp)
    8000264c:	e44e                	sd	s3,8(sp)
    8000264e:	e052                	sd	s4,0(sp)
    80002650:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    80002652:	0000f497          	auipc	s1,0xf
    80002656:	07e48493          	addi	s1,s1,126 # 800116d0 <proc>
  {
    if(p->pid != initproc->pid && p->pid != SHELL_PID) //Dont kill shell and init processes
    8000265a:	00007997          	auipc	s3,0x7
    8000265e:	9ce98993          	addi	s3,s3,-1586 # 80009028 <initproc>
    80002662:	4a09                	li	s4,2
  for(p = proc; p < &proc[NPROC]; p++)
    80002664:	00015917          	auipc	s2,0x15
    80002668:	a6c90913          	addi	s2,s2,-1428 # 800170d0 <tickslock>
    8000266c:	a809                	j	8000267e <kill_system+0x3c>
    {
      kill(p->pid);
    8000266e:	00000097          	auipc	ra,0x0
    80002672:	dac080e7          	jalr	-596(ra) # 8000241a <kill>
  for(p = proc; p < &proc[NPROC]; p++)
    80002676:	16848493          	addi	s1,s1,360
    8000267a:	01248b63          	beq	s1,s2,80002690 <kill_system+0x4e>
    if(p->pid != initproc->pid && p->pid != SHELL_PID) //Dont kill shell and init processes
    8000267e:	5888                	lw	a0,48(s1)
    80002680:	0009b783          	ld	a5,0(s3)
    80002684:	5b9c                	lw	a5,48(a5)
    80002686:	fea788e3          	beq	a5,a0,80002676 <kill_system+0x34>
    8000268a:	ff4506e3          	beq	a0,s4,80002676 <kill_system+0x34>
    8000268e:	b7c5                	j	8000266e <kill_system+0x2c>
    }
  }
  return 0;
}
    80002690:	4501                	li	a0,0
    80002692:	70a2                	ld	ra,40(sp)
    80002694:	7402                	ld	s0,32(sp)
    80002696:	64e2                	ld	s1,24(sp)
    80002698:	6942                	ld	s2,16(sp)
    8000269a:	69a2                	ld	s3,8(sp)
    8000269c:	6a02                	ld	s4,0(sp)
    8000269e:	6145                	addi	sp,sp,48
    800026a0:	8082                	ret

00000000800026a2 <debug>:

void
debug(void)
{
    800026a2:	7179                	addi	sp,sp,-48
    800026a4:	f406                	sd	ra,40(sp)
    800026a6:	f022                	sd	s0,32(sp)
    800026a8:	ec26                	sd	s1,24(sp)
    800026aa:	e84a                	sd	s2,16(sp)
    800026ac:	e44e                	sd	s3,8(sp)
    800026ae:	1800                	addi	s0,sp,48
  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++)
    800026b0:	0000f497          	auipc	s1,0xf
    800026b4:	17848493          	addi	s1,s1,376 # 80011828 <proc+0x158>
    800026b8:	00015997          	auipc	s3,0x15
    800026bc:	b7098993          	addi	s3,s3,-1168 # 80017228 <bcache+0x140>
  {
    printf("name - %s    pid - %d\n", p->name, p->pid);
    800026c0:	00006917          	auipc	s2,0x6
    800026c4:	bd890913          	addi	s2,s2,-1064 # 80008298 <digits+0x258>
    800026c8:	ed84a603          	lw	a2,-296(s1)
    800026cc:	85a6                	mv	a1,s1
    800026ce:	854a                	mv	a0,s2
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	eb8080e7          	jalr	-328(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++)
    800026d8:	16848493          	addi	s1,s1,360
    800026dc:	ff3496e3          	bne	s1,s3,800026c8 <debug+0x26>
  }

}
    800026e0:	70a2                	ld	ra,40(sp)
    800026e2:	7402                	ld	s0,32(sp)
    800026e4:	64e2                	ld	s1,24(sp)
    800026e6:	6942                	ld	s2,16(sp)
    800026e8:	69a2                	ld	s3,8(sp)
    800026ea:	6145                	addi	sp,sp,48
    800026ec:	8082                	ret

00000000800026ee <swtch>:
    800026ee:	00153023          	sd	ra,0(a0)
    800026f2:	00253423          	sd	sp,8(a0)
    800026f6:	e900                	sd	s0,16(a0)
    800026f8:	ed04                	sd	s1,24(a0)
    800026fa:	03253023          	sd	s2,32(a0)
    800026fe:	03353423          	sd	s3,40(a0)
    80002702:	03453823          	sd	s4,48(a0)
    80002706:	03553c23          	sd	s5,56(a0)
    8000270a:	05653023          	sd	s6,64(a0)
    8000270e:	05753423          	sd	s7,72(a0)
    80002712:	05853823          	sd	s8,80(a0)
    80002716:	05953c23          	sd	s9,88(a0)
    8000271a:	07a53023          	sd	s10,96(a0)
    8000271e:	07b53423          	sd	s11,104(a0)
    80002722:	0005b083          	ld	ra,0(a1)
    80002726:	0085b103          	ld	sp,8(a1)
    8000272a:	6980                	ld	s0,16(a1)
    8000272c:	6d84                	ld	s1,24(a1)
    8000272e:	0205b903          	ld	s2,32(a1)
    80002732:	0285b983          	ld	s3,40(a1)
    80002736:	0305ba03          	ld	s4,48(a1)
    8000273a:	0385ba83          	ld	s5,56(a1)
    8000273e:	0405bb03          	ld	s6,64(a1)
    80002742:	0485bb83          	ld	s7,72(a1)
    80002746:	0505bc03          	ld	s8,80(a1)
    8000274a:	0585bc83          	ld	s9,88(a1)
    8000274e:	0605bd03          	ld	s10,96(a1)
    80002752:	0685bd83          	ld	s11,104(a1)
    80002756:	8082                	ret

0000000080002758 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002758:	1141                	addi	sp,sp,-16
    8000275a:	e406                	sd	ra,8(sp)
    8000275c:	e022                	sd	s0,0(sp)
    8000275e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002760:	00006597          	auipc	a1,0x6
    80002764:	ba858593          	addi	a1,a1,-1112 # 80008308 <states.1720+0x30>
    80002768:	00015517          	auipc	a0,0x15
    8000276c:	96850513          	addi	a0,a0,-1688 # 800170d0 <tickslock>
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	3e4080e7          	jalr	996(ra) # 80000b54 <initlock>
}
    80002778:	60a2                	ld	ra,8(sp)
    8000277a:	6402                	ld	s0,0(sp)
    8000277c:	0141                	addi	sp,sp,16
    8000277e:	8082                	ret

0000000080002780 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002780:	1141                	addi	sp,sp,-16
    80002782:	e422                	sd	s0,8(sp)
    80002784:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002786:	00003797          	auipc	a5,0x3
    8000278a:	4ea78793          	addi	a5,a5,1258 # 80005c70 <kernelvec>
    8000278e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002792:	6422                	ld	s0,8(sp)
    80002794:	0141                	addi	sp,sp,16
    80002796:	8082                	ret

0000000080002798 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002798:	1141                	addi	sp,sp,-16
    8000279a:	e406                	sd	ra,8(sp)
    8000279c:	e022                	sd	s0,0(sp)
    8000279e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	210080e7          	jalr	528(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027ac:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ae:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027b2:	00005617          	auipc	a2,0x5
    800027b6:	84e60613          	addi	a2,a2,-1970 # 80007000 <_trampoline>
    800027ba:	00005697          	auipc	a3,0x5
    800027be:	84668693          	addi	a3,a3,-1978 # 80007000 <_trampoline>
    800027c2:	8e91                	sub	a3,a3,a2
    800027c4:	040007b7          	lui	a5,0x4000
    800027c8:	17fd                	addi	a5,a5,-1
    800027ca:	07b2                	slli	a5,a5,0xc
    800027cc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ce:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027d2:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027d4:	180026f3          	csrr	a3,satp
    800027d8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027da:	6d38                	ld	a4,88(a0)
    800027dc:	6134                	ld	a3,64(a0)
    800027de:	6585                	lui	a1,0x1
    800027e0:	96ae                	add	a3,a3,a1
    800027e2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027e4:	6d38                	ld	a4,88(a0)
    800027e6:	00000697          	auipc	a3,0x0
    800027ea:	13868693          	addi	a3,a3,312 # 8000291e <usertrap>
    800027ee:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027f0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027f2:	8692                	mv	a3,tp
    800027f4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027fa:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027fe:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002802:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002806:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002808:	6f18                	ld	a4,24(a4)
    8000280a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000280e:	692c                	ld	a1,80(a0)
    80002810:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002812:	00005717          	auipc	a4,0x5
    80002816:	87e70713          	addi	a4,a4,-1922 # 80007090 <userret>
    8000281a:	8f11                	sub	a4,a4,a2
    8000281c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000281e:	577d                	li	a4,-1
    80002820:	177e                	slli	a4,a4,0x3f
    80002822:	8dd9                	or	a1,a1,a4
    80002824:	02000537          	lui	a0,0x2000
    80002828:	157d                	addi	a0,a0,-1
    8000282a:	0536                	slli	a0,a0,0xd
    8000282c:	9782                	jalr	a5
}
    8000282e:	60a2                	ld	ra,8(sp)
    80002830:	6402                	ld	s0,0(sp)
    80002832:	0141                	addi	sp,sp,16
    80002834:	8082                	ret

0000000080002836 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002836:	1101                	addi	sp,sp,-32
    80002838:	ec06                	sd	ra,24(sp)
    8000283a:	e822                	sd	s0,16(sp)
    8000283c:	e426                	sd	s1,8(sp)
    8000283e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002840:	00015497          	auipc	s1,0x15
    80002844:	89048493          	addi	s1,s1,-1904 # 800170d0 <tickslock>
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	39a080e7          	jalr	922(ra) # 80000be4 <acquire>
  ticks++;
    80002852:	00006517          	auipc	a0,0x6
    80002856:	7e250513          	addi	a0,a0,2018 # 80009034 <ticks>
    8000285a:	411c                	lw	a5,0(a0)
    8000285c:	2785                	addiw	a5,a5,1
    8000285e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002860:	00000097          	auipc	ra,0x0
    80002864:	a14080e7          	jalr	-1516(ra) # 80002274 <wakeup>
  release(&tickslock);
    80002868:	8526                	mv	a0,s1
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	42e080e7          	jalr	1070(ra) # 80000c98 <release>
}
    80002872:	60e2                	ld	ra,24(sp)
    80002874:	6442                	ld	s0,16(sp)
    80002876:	64a2                	ld	s1,8(sp)
    80002878:	6105                	addi	sp,sp,32
    8000287a:	8082                	ret

000000008000287c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000287c:	1101                	addi	sp,sp,-32
    8000287e:	ec06                	sd	ra,24(sp)
    80002880:	e822                	sd	s0,16(sp)
    80002882:	e426                	sd	s1,8(sp)
    80002884:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002886:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000288a:	00074d63          	bltz	a4,800028a4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000288e:	57fd                	li	a5,-1
    80002890:	17fe                	slli	a5,a5,0x3f
    80002892:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002894:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002896:	06f70363          	beq	a4,a5,800028fc <devintr+0x80>
  }
}
    8000289a:	60e2                	ld	ra,24(sp)
    8000289c:	6442                	ld	s0,16(sp)
    8000289e:	64a2                	ld	s1,8(sp)
    800028a0:	6105                	addi	sp,sp,32
    800028a2:	8082                	ret
     (scause & 0xff) == 9){
    800028a4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028a8:	46a5                	li	a3,9
    800028aa:	fed792e3          	bne	a5,a3,8000288e <devintr+0x12>
    int irq = plic_claim();
    800028ae:	00003097          	auipc	ra,0x3
    800028b2:	4ca080e7          	jalr	1226(ra) # 80005d78 <plic_claim>
    800028b6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028b8:	47a9                	li	a5,10
    800028ba:	02f50763          	beq	a0,a5,800028e8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028be:	4785                	li	a5,1
    800028c0:	02f50963          	beq	a0,a5,800028f2 <devintr+0x76>
    return 1;
    800028c4:	4505                	li	a0,1
    } else if(irq){
    800028c6:	d8f1                	beqz	s1,8000289a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028c8:	85a6                	mv	a1,s1
    800028ca:	00006517          	auipc	a0,0x6
    800028ce:	a4650513          	addi	a0,a0,-1466 # 80008310 <states.1720+0x38>
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	cb6080e7          	jalr	-842(ra) # 80000588 <printf>
      plic_complete(irq);
    800028da:	8526                	mv	a0,s1
    800028dc:	00003097          	auipc	ra,0x3
    800028e0:	4c0080e7          	jalr	1216(ra) # 80005d9c <plic_complete>
    return 1;
    800028e4:	4505                	li	a0,1
    800028e6:	bf55                	j	8000289a <devintr+0x1e>
      uartintr();
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	0c0080e7          	jalr	192(ra) # 800009a8 <uartintr>
    800028f0:	b7ed                	j	800028da <devintr+0x5e>
      virtio_disk_intr();
    800028f2:	00004097          	auipc	ra,0x4
    800028f6:	98a080e7          	jalr	-1654(ra) # 8000627c <virtio_disk_intr>
    800028fa:	b7c5                	j	800028da <devintr+0x5e>
    if(cpuid() == 0){
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	088080e7          	jalr	136(ra) # 80001984 <cpuid>
    80002904:	c901                	beqz	a0,80002914 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002906:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000290a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000290c:	14479073          	csrw	sip,a5
    return 2;
    80002910:	4509                	li	a0,2
    80002912:	b761                	j	8000289a <devintr+0x1e>
      clockintr();
    80002914:	00000097          	auipc	ra,0x0
    80002918:	f22080e7          	jalr	-222(ra) # 80002836 <clockintr>
    8000291c:	b7ed                	j	80002906 <devintr+0x8a>

000000008000291e <usertrap>:
{
    8000291e:	1101                	addi	sp,sp,-32
    80002920:	ec06                	sd	ra,24(sp)
    80002922:	e822                	sd	s0,16(sp)
    80002924:	e426                	sd	s1,8(sp)
    80002926:	e04a                	sd	s2,0(sp)
    80002928:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000292e:	1007f793          	andi	a5,a5,256
    80002932:	e3ad                	bnez	a5,80002994 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002934:	00003797          	auipc	a5,0x3
    80002938:	33c78793          	addi	a5,a5,828 # 80005c70 <kernelvec>
    8000293c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	070080e7          	jalr	112(ra) # 800019b0 <myproc>
    80002948:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000294a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000294c:	14102773          	csrr	a4,sepc
    80002950:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002952:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002956:	47a1                	li	a5,8
    80002958:	04f71c63          	bne	a4,a5,800029b0 <usertrap+0x92>
    if(p->killed)
    8000295c:	551c                	lw	a5,40(a0)
    8000295e:	e3b9                	bnez	a5,800029a4 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002960:	6cb8                	ld	a4,88(s1)
    80002962:	6f1c                	ld	a5,24(a4)
    80002964:	0791                	addi	a5,a5,4
    80002966:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002968:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000296c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002970:	10079073          	csrw	sstatus,a5
    syscall();
    80002974:	00000097          	auipc	ra,0x0
    80002978:	2e0080e7          	jalr	736(ra) # 80002c54 <syscall>
  if(p->killed)
    8000297c:	549c                	lw	a5,40(s1)
    8000297e:	ebc1                	bnez	a5,80002a0e <usertrap+0xf0>
  usertrapret();
    80002980:	00000097          	auipc	ra,0x0
    80002984:	e18080e7          	jalr	-488(ra) # 80002798 <usertrapret>
}
    80002988:	60e2                	ld	ra,24(sp)
    8000298a:	6442                	ld	s0,16(sp)
    8000298c:	64a2                	ld	s1,8(sp)
    8000298e:	6902                	ld	s2,0(sp)
    80002990:	6105                	addi	sp,sp,32
    80002992:	8082                	ret
    panic("usertrap: not from user mode");
    80002994:	00006517          	auipc	a0,0x6
    80002998:	99c50513          	addi	a0,a0,-1636 # 80008330 <states.1720+0x58>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	ba2080e7          	jalr	-1118(ra) # 8000053e <panic>
      exit(-1);
    800029a4:	557d                	li	a0,-1
    800029a6:	00000097          	auipc	ra,0x0
    800029aa:	99e080e7          	jalr	-1634(ra) # 80002344 <exit>
    800029ae:	bf4d                	j	80002960 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	ecc080e7          	jalr	-308(ra) # 8000287c <devintr>
    800029b8:	892a                	mv	s2,a0
    800029ba:	c501                	beqz	a0,800029c2 <usertrap+0xa4>
  if(p->killed)
    800029bc:	549c                	lw	a5,40(s1)
    800029be:	c3a1                	beqz	a5,800029fe <usertrap+0xe0>
    800029c0:	a815                	j	800029f4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029c6:	5890                	lw	a2,48(s1)
    800029c8:	00006517          	auipc	a0,0x6
    800029cc:	98850513          	addi	a0,a0,-1656 # 80008350 <states.1720+0x78>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	bb8080e7          	jalr	-1096(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029dc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	9a050513          	addi	a0,a0,-1632 # 80008380 <states.1720+0xa8>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	ba0080e7          	jalr	-1120(ra) # 80000588 <printf>
    p->killed = 1;
    800029f0:	4785                	li	a5,1
    800029f2:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029f4:	557d                	li	a0,-1
    800029f6:	00000097          	auipc	ra,0x0
    800029fa:	94e080e7          	jalr	-1714(ra) # 80002344 <exit>
  if(which_dev == 2)
    800029fe:	4789                	li	a5,2
    80002a00:	f8f910e3          	bne	s2,a5,80002980 <usertrap+0x62>
    yield();
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	6a8080e7          	jalr	1704(ra) # 800020ac <yield>
    80002a0c:	bf95                	j	80002980 <usertrap+0x62>
  int which_dev = 0;
    80002a0e:	4901                	li	s2,0
    80002a10:	b7d5                	j	800029f4 <usertrap+0xd6>

0000000080002a12 <kerneltrap>:
{
    80002a12:	7179                	addi	sp,sp,-48
    80002a14:	f406                	sd	ra,40(sp)
    80002a16:	f022                	sd	s0,32(sp)
    80002a18:	ec26                	sd	s1,24(sp)
    80002a1a:	e84a                	sd	s2,16(sp)
    80002a1c:	e44e                	sd	s3,8(sp)
    80002a1e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a20:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a24:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a28:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a2c:	1004f793          	andi	a5,s1,256
    80002a30:	cb85                	beqz	a5,80002a60 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a32:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a36:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a38:	ef85                	bnez	a5,80002a70 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a3a:	00000097          	auipc	ra,0x0
    80002a3e:	e42080e7          	jalr	-446(ra) # 8000287c <devintr>
    80002a42:	cd1d                	beqz	a0,80002a80 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a44:	4789                	li	a5,2
    80002a46:	06f50a63          	beq	a0,a5,80002aba <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a4a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a4e:	10049073          	csrw	sstatus,s1
}
    80002a52:	70a2                	ld	ra,40(sp)
    80002a54:	7402                	ld	s0,32(sp)
    80002a56:	64e2                	ld	s1,24(sp)
    80002a58:	6942                	ld	s2,16(sp)
    80002a5a:	69a2                	ld	s3,8(sp)
    80002a5c:	6145                	addi	sp,sp,48
    80002a5e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	94050513          	addi	a0,a0,-1728 # 800083a0 <states.1720+0xc8>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	ad6080e7          	jalr	-1322(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	95850513          	addi	a0,a0,-1704 # 800083c8 <states.1720+0xf0>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	ac6080e7          	jalr	-1338(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a80:	85ce                	mv	a1,s3
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	96650513          	addi	a0,a0,-1690 # 800083e8 <states.1720+0x110>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	afe080e7          	jalr	-1282(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a92:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a96:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	95e50513          	addi	a0,a0,-1698 # 800083f8 <states.1720+0x120>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ae6080e7          	jalr	-1306(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	96650513          	addi	a0,a0,-1690 # 80008410 <states.1720+0x138>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a8c080e7          	jalr	-1396(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	ef6080e7          	jalr	-266(ra) # 800019b0 <myproc>
    80002ac2:	d541                	beqz	a0,80002a4a <kerneltrap+0x38>
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	eec080e7          	jalr	-276(ra) # 800019b0 <myproc>
    80002acc:	4d18                	lw	a4,24(a0)
    80002ace:	4791                	li	a5,4
    80002ad0:	f6f71de3          	bne	a4,a5,80002a4a <kerneltrap+0x38>
    yield();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	5d8080e7          	jalr	1496(ra) # 800020ac <yield>
    80002adc:	b7bd                	j	80002a4a <kerneltrap+0x38>

0000000080002ade <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	1000                	addi	s0,sp,32
    80002ae8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	ec6080e7          	jalr	-314(ra) # 800019b0 <myproc>
  switch (n) {
    80002af2:	4795                	li	a5,5
    80002af4:	0497e163          	bltu	a5,s1,80002b36 <argraw+0x58>
    80002af8:	048a                	slli	s1,s1,0x2
    80002afa:	00006717          	auipc	a4,0x6
    80002afe:	94e70713          	addi	a4,a4,-1714 # 80008448 <states.1720+0x170>
    80002b02:	94ba                	add	s1,s1,a4
    80002b04:	409c                	lw	a5,0(s1)
    80002b06:	97ba                	add	a5,a5,a4
    80002b08:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b0e:	60e2                	ld	ra,24(sp)
    80002b10:	6442                	ld	s0,16(sp)
    80002b12:	64a2                	ld	s1,8(sp)
    80002b14:	6105                	addi	sp,sp,32
    80002b16:	8082                	ret
    return p->trapframe->a1;
    80002b18:	6d3c                	ld	a5,88(a0)
    80002b1a:	7fa8                	ld	a0,120(a5)
    80002b1c:	bfcd                	j	80002b0e <argraw+0x30>
    return p->trapframe->a2;
    80002b1e:	6d3c                	ld	a5,88(a0)
    80002b20:	63c8                	ld	a0,128(a5)
    80002b22:	b7f5                	j	80002b0e <argraw+0x30>
    return p->trapframe->a3;
    80002b24:	6d3c                	ld	a5,88(a0)
    80002b26:	67c8                	ld	a0,136(a5)
    80002b28:	b7dd                	j	80002b0e <argraw+0x30>
    return p->trapframe->a4;
    80002b2a:	6d3c                	ld	a5,88(a0)
    80002b2c:	6bc8                	ld	a0,144(a5)
    80002b2e:	b7c5                	j	80002b0e <argraw+0x30>
    return p->trapframe->a5;
    80002b30:	6d3c                	ld	a5,88(a0)
    80002b32:	6fc8                	ld	a0,152(a5)
    80002b34:	bfe9                	j	80002b0e <argraw+0x30>
  panic("argraw");
    80002b36:	00006517          	auipc	a0,0x6
    80002b3a:	8ea50513          	addi	a0,a0,-1814 # 80008420 <states.1720+0x148>
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	a00080e7          	jalr	-1536(ra) # 8000053e <panic>

0000000080002b46 <fetchaddr>:
{
    80002b46:	1101                	addi	sp,sp,-32
    80002b48:	ec06                	sd	ra,24(sp)
    80002b4a:	e822                	sd	s0,16(sp)
    80002b4c:	e426                	sd	s1,8(sp)
    80002b4e:	e04a                	sd	s2,0(sp)
    80002b50:	1000                	addi	s0,sp,32
    80002b52:	84aa                	mv	s1,a0
    80002b54:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	e5a080e7          	jalr	-422(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b5e:	653c                	ld	a5,72(a0)
    80002b60:	02f4f863          	bgeu	s1,a5,80002b90 <fetchaddr+0x4a>
    80002b64:	00848713          	addi	a4,s1,8
    80002b68:	02e7e663          	bltu	a5,a4,80002b94 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b6c:	46a1                	li	a3,8
    80002b6e:	8626                	mv	a2,s1
    80002b70:	85ca                	mv	a1,s2
    80002b72:	6928                	ld	a0,80(a0)
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	b8a080e7          	jalr	-1142(ra) # 800016fe <copyin>
    80002b7c:	00a03533          	snez	a0,a0
    80002b80:	40a00533          	neg	a0,a0
}
    80002b84:	60e2                	ld	ra,24(sp)
    80002b86:	6442                	ld	s0,16(sp)
    80002b88:	64a2                	ld	s1,8(sp)
    80002b8a:	6902                	ld	s2,0(sp)
    80002b8c:	6105                	addi	sp,sp,32
    80002b8e:	8082                	ret
    return -1;
    80002b90:	557d                	li	a0,-1
    80002b92:	bfcd                	j	80002b84 <fetchaddr+0x3e>
    80002b94:	557d                	li	a0,-1
    80002b96:	b7fd                	j	80002b84 <fetchaddr+0x3e>

0000000080002b98 <fetchstr>:
{
    80002b98:	7179                	addi	sp,sp,-48
    80002b9a:	f406                	sd	ra,40(sp)
    80002b9c:	f022                	sd	s0,32(sp)
    80002b9e:	ec26                	sd	s1,24(sp)
    80002ba0:	e84a                	sd	s2,16(sp)
    80002ba2:	e44e                	sd	s3,8(sp)
    80002ba4:	1800                	addi	s0,sp,48
    80002ba6:	892a                	mv	s2,a0
    80002ba8:	84ae                	mv	s1,a1
    80002baa:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	e04080e7          	jalr	-508(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bb4:	86ce                	mv	a3,s3
    80002bb6:	864a                	mv	a2,s2
    80002bb8:	85a6                	mv	a1,s1
    80002bba:	6928                	ld	a0,80(a0)
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	bce080e7          	jalr	-1074(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002bc4:	00054763          	bltz	a0,80002bd2 <fetchstr+0x3a>
  return strlen(buf);
    80002bc8:	8526                	mv	a0,s1
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	29a080e7          	jalr	666(ra) # 80000e64 <strlen>
}
    80002bd2:	70a2                	ld	ra,40(sp)
    80002bd4:	7402                	ld	s0,32(sp)
    80002bd6:	64e2                	ld	s1,24(sp)
    80002bd8:	6942                	ld	s2,16(sp)
    80002bda:	69a2                	ld	s3,8(sp)
    80002bdc:	6145                	addi	sp,sp,48
    80002bde:	8082                	ret

0000000080002be0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002be0:	1101                	addi	sp,sp,-32
    80002be2:	ec06                	sd	ra,24(sp)
    80002be4:	e822                	sd	s0,16(sp)
    80002be6:	e426                	sd	s1,8(sp)
    80002be8:	1000                	addi	s0,sp,32
    80002bea:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	ef2080e7          	jalr	-270(ra) # 80002ade <argraw>
    80002bf4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bf6:	4501                	li	a0,0
    80002bf8:	60e2                	ld	ra,24(sp)
    80002bfa:	6442                	ld	s0,16(sp)
    80002bfc:	64a2                	ld	s1,8(sp)
    80002bfe:	6105                	addi	sp,sp,32
    80002c00:	8082                	ret

0000000080002c02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	1000                	addi	s0,sp,32
    80002c0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	ed0080e7          	jalr	-304(ra) # 80002ade <argraw>
    80002c16:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c18:	4501                	li	a0,0
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	e04a                	sd	s2,0(sp)
    80002c2e:	1000                	addi	s0,sp,32
    80002c30:	84ae                	mv	s1,a1
    80002c32:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	eaa080e7          	jalr	-342(ra) # 80002ade <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c3c:	864a                	mv	a2,s2
    80002c3e:	85a6                	mv	a1,s1
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	f58080e7          	jalr	-168(ra) # 80002b98 <fetchstr>
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6902                	ld	s2,0(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <syscall>:
[SYS_debug] sys_debug,
};

void
syscall(void)
{
    80002c54:	1101                	addi	sp,sp,-32
    80002c56:	ec06                	sd	ra,24(sp)
    80002c58:	e822                	sd	s0,16(sp)
    80002c5a:	e426                	sd	s1,8(sp)
    80002c5c:	e04a                	sd	s2,0(sp)
    80002c5e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	d50080e7          	jalr	-688(ra) # 800019b0 <myproc>
    80002c68:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c6a:	05853903          	ld	s2,88(a0)
    80002c6e:	0a893783          	ld	a5,168(s2)
    80002c72:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c76:	37fd                	addiw	a5,a5,-1
    80002c78:	475d                	li	a4,23
    80002c7a:	00f76f63          	bltu	a4,a5,80002c98 <syscall+0x44>
    80002c7e:	00369713          	slli	a4,a3,0x3
    80002c82:	00005797          	auipc	a5,0x5
    80002c86:	7de78793          	addi	a5,a5,2014 # 80008460 <syscalls>
    80002c8a:	97ba                	add	a5,a5,a4
    80002c8c:	639c                	ld	a5,0(a5)
    80002c8e:	c789                	beqz	a5,80002c98 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c90:	9782                	jalr	a5
    80002c92:	06a93823          	sd	a0,112(s2)
    80002c96:	a839                	j	80002cb4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c98:	15848613          	addi	a2,s1,344
    80002c9c:	588c                	lw	a1,48(s1)
    80002c9e:	00005517          	auipc	a0,0x5
    80002ca2:	78a50513          	addi	a0,a0,1930 # 80008428 <states.1720+0x150>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	8e2080e7          	jalr	-1822(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cae:	6cbc                	ld	a5,88(s1)
    80002cb0:	577d                	li	a4,-1
    80002cb2:	fbb8                	sd	a4,112(a5)
  }
}
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	64a2                	ld	s1,8(sp)
    80002cba:	6902                	ld	s2,0(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret

0000000080002cc0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cc8:	fec40593          	addi	a1,s0,-20
    80002ccc:	4501                	li	a0,0
    80002cce:	00000097          	auipc	ra,0x0
    80002cd2:	f12080e7          	jalr	-238(ra) # 80002be0 <argint>
    return -1;
    80002cd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cd8:	00054963          	bltz	a0,80002cea <sys_exit+0x2a>
  exit(n);
    80002cdc:	fec42503          	lw	a0,-20(s0)
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	664080e7          	jalr	1636(ra) # 80002344 <exit>
  return 0;  // not reached
    80002ce8:	4781                	li	a5,0
}
    80002cea:	853e                	mv	a0,a5
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	6105                	addi	sp,sp,32
    80002cf2:	8082                	ret

0000000080002cf4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cf4:	1141                	addi	sp,sp,-16
    80002cf6:	e406                	sd	ra,8(sp)
    80002cf8:	e022                	sd	s0,0(sp)
    80002cfa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	cb4080e7          	jalr	-844(ra) # 800019b0 <myproc>
}
    80002d04:	5908                	lw	a0,48(a0)
    80002d06:	60a2                	ld	ra,8(sp)
    80002d08:	6402                	ld	s0,0(sp)
    80002d0a:	0141                	addi	sp,sp,16
    80002d0c:	8082                	ret

0000000080002d0e <sys_fork>:

uint64
sys_fork(void)
{
    80002d0e:	1141                	addi	sp,sp,-16
    80002d10:	e406                	sd	ra,8(sp)
    80002d12:	e022                	sd	s0,0(sp)
    80002d14:	0800                	addi	s0,sp,16
  return fork();
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	068080e7          	jalr	104(ra) # 80001d7e <fork>
}
    80002d1e:	60a2                	ld	ra,8(sp)
    80002d20:	6402                	ld	s0,0(sp)
    80002d22:	0141                	addi	sp,sp,16
    80002d24:	8082                	ret

0000000080002d26 <sys_wait>:

uint64
sys_wait(void)
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d2e:	fe840593          	addi	a1,s0,-24
    80002d32:	4501                	li	a0,0
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	ece080e7          	jalr	-306(ra) # 80002c02 <argaddr>
    80002d3c:	87aa                	mv	a5,a0
    return -1;
    80002d3e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d40:	0007c863          	bltz	a5,80002d50 <sys_wait+0x2a>
  return wait(p);
    80002d44:	fe843503          	ld	a0,-24(s0)
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	404080e7          	jalr	1028(ra) # 8000214c <wait>
}
    80002d50:	60e2                	ld	ra,24(sp)
    80002d52:	6442                	ld	s0,16(sp)
    80002d54:	6105                	addi	sp,sp,32
    80002d56:	8082                	ret

0000000080002d58 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d58:	7179                	addi	sp,sp,-48
    80002d5a:	f406                	sd	ra,40(sp)
    80002d5c:	f022                	sd	s0,32(sp)
    80002d5e:	ec26                	sd	s1,24(sp)
    80002d60:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d62:	fdc40593          	addi	a1,s0,-36
    80002d66:	4501                	li	a0,0
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	e78080e7          	jalr	-392(ra) # 80002be0 <argint>
    80002d70:	87aa                	mv	a5,a0
    return -1;
    80002d72:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d74:	0207c063          	bltz	a5,80002d94 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d78:	fffff097          	auipc	ra,0xfffff
    80002d7c:	c38080e7          	jalr	-968(ra) # 800019b0 <myproc>
    80002d80:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d82:	fdc42503          	lw	a0,-36(s0)
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	f84080e7          	jalr	-124(ra) # 80001d0a <growproc>
    80002d8e:	00054863          	bltz	a0,80002d9e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d92:	8526                	mv	a0,s1
}
    80002d94:	70a2                	ld	ra,40(sp)
    80002d96:	7402                	ld	s0,32(sp)
    80002d98:	64e2                	ld	s1,24(sp)
    80002d9a:	6145                	addi	sp,sp,48
    80002d9c:	8082                	ret
    return -1;
    80002d9e:	557d                	li	a0,-1
    80002da0:	bfd5                	j	80002d94 <sys_sbrk+0x3c>

0000000080002da2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002da2:	7139                	addi	sp,sp,-64
    80002da4:	fc06                	sd	ra,56(sp)
    80002da6:	f822                	sd	s0,48(sp)
    80002da8:	f426                	sd	s1,40(sp)
    80002daa:	f04a                	sd	s2,32(sp)
    80002dac:	ec4e                	sd	s3,24(sp)
    80002dae:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002db0:	fcc40593          	addi	a1,s0,-52
    80002db4:	4501                	li	a0,0
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	e2a080e7          	jalr	-470(ra) # 80002be0 <argint>
    return -1;
    80002dbe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dc0:	06054563          	bltz	a0,80002e2a <sys_sleep+0x88>
  acquire(&tickslock);
    80002dc4:	00014517          	auipc	a0,0x14
    80002dc8:	30c50513          	addi	a0,a0,780 # 800170d0 <tickslock>
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	e18080e7          	jalr	-488(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002dd4:	00006917          	auipc	s2,0x6
    80002dd8:	26092903          	lw	s2,608(s2) # 80009034 <ticks>
  while(ticks - ticks0 < n){
    80002ddc:	fcc42783          	lw	a5,-52(s0)
    80002de0:	cf85                	beqz	a5,80002e18 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002de2:	00014997          	auipc	s3,0x14
    80002de6:	2ee98993          	addi	s3,s3,750 # 800170d0 <tickslock>
    80002dea:	00006497          	auipc	s1,0x6
    80002dee:	24a48493          	addi	s1,s1,586 # 80009034 <ticks>
    if(myproc()->killed){
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	bbe080e7          	jalr	-1090(ra) # 800019b0 <myproc>
    80002dfa:	551c                	lw	a5,40(a0)
    80002dfc:	ef9d                	bnez	a5,80002e3a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dfe:	85ce                	mv	a1,s3
    80002e00:	8526                	mv	a0,s1
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	2e6080e7          	jalr	742(ra) # 800020e8 <sleep>
  while(ticks - ticks0 < n){
    80002e0a:	409c                	lw	a5,0(s1)
    80002e0c:	412787bb          	subw	a5,a5,s2
    80002e10:	fcc42703          	lw	a4,-52(s0)
    80002e14:	fce7efe3          	bltu	a5,a4,80002df2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e18:	00014517          	auipc	a0,0x14
    80002e1c:	2b850513          	addi	a0,a0,696 # 800170d0 <tickslock>
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	e78080e7          	jalr	-392(ra) # 80000c98 <release>
  return 0;
    80002e28:	4781                	li	a5,0
}
    80002e2a:	853e                	mv	a0,a5
    80002e2c:	70e2                	ld	ra,56(sp)
    80002e2e:	7442                	ld	s0,48(sp)
    80002e30:	74a2                	ld	s1,40(sp)
    80002e32:	7902                	ld	s2,32(sp)
    80002e34:	69e2                	ld	s3,24(sp)
    80002e36:	6121                	addi	sp,sp,64
    80002e38:	8082                	ret
      release(&tickslock);
    80002e3a:	00014517          	auipc	a0,0x14
    80002e3e:	29650513          	addi	a0,a0,662 # 800170d0 <tickslock>
    80002e42:	ffffe097          	auipc	ra,0xffffe
    80002e46:	e56080e7          	jalr	-426(ra) # 80000c98 <release>
      return -1;
    80002e4a:	57fd                	li	a5,-1
    80002e4c:	bff9                	j	80002e2a <sys_sleep+0x88>

0000000080002e4e <sys_kill>:

uint64
sys_kill(void)
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e56:	fec40593          	addi	a1,s0,-20
    80002e5a:	4501                	li	a0,0
    80002e5c:	00000097          	auipc	ra,0x0
    80002e60:	d84080e7          	jalr	-636(ra) # 80002be0 <argint>
    80002e64:	87aa                	mv	a5,a0
    return -1;
    80002e66:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e68:	0007c863          	bltz	a5,80002e78 <sys_kill+0x2a>
  return kill(pid);
    80002e6c:	fec42503          	lw	a0,-20(s0)
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	5aa080e7          	jalr	1450(ra) # 8000241a <kill>
}
    80002e78:	60e2                	ld	ra,24(sp)
    80002e7a:	6442                	ld	s0,16(sp)
    80002e7c:	6105                	addi	sp,sp,32
    80002e7e:	8082                	ret

0000000080002e80 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e80:	1101                	addi	sp,sp,-32
    80002e82:	ec06                	sd	ra,24(sp)
    80002e84:	e822                	sd	s0,16(sp)
    80002e86:	e426                	sd	s1,8(sp)
    80002e88:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e8a:	00014517          	auipc	a0,0x14
    80002e8e:	24650513          	addi	a0,a0,582 # 800170d0 <tickslock>
    80002e92:	ffffe097          	auipc	ra,0xffffe
    80002e96:	d52080e7          	jalr	-686(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e9a:	00006497          	auipc	s1,0x6
    80002e9e:	19a4a483          	lw	s1,410(s1) # 80009034 <ticks>
  release(&tickslock);
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	22e50513          	addi	a0,a0,558 # 800170d0 <tickslock>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
  return xticks;
}
    80002eb2:	02049513          	slli	a0,s1,0x20
    80002eb6:	9101                	srli	a0,a0,0x20
    80002eb8:	60e2                	ld	ra,24(sp)
    80002eba:	6442                	ld	s0,16(sp)
    80002ebc:	64a2                	ld	s1,8(sp)
    80002ebe:	6105                	addi	sp,sp,32
    80002ec0:	8082                	ret

0000000080002ec2 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002ec2:	1101                	addi	sp,sp,-32
    80002ec4:	ec06                	sd	ra,24(sp)
    80002ec6:	e822                	sd	s0,16(sp)
    80002ec8:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80002eca:	fec40593          	addi	a1,s0,-20
    80002ece:	4501                	li	a0,0
    80002ed0:	00000097          	auipc	ra,0x0
    80002ed4:	d10080e7          	jalr	-752(ra) # 80002be0 <argint>
    80002ed8:	87aa                	mv	a5,a0
    return -1;
    80002eda:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80002edc:	0007c863          	bltz	a5,80002eec <sys_pause_system+0x2a>
  return pause_system(seconds);
    80002ee0:	fec42503          	lw	a0,-20(s0)
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	702080e7          	jalr	1794(ra) # 800025e6 <pause_system>
}
    80002eec:	60e2                	ld	ra,24(sp)
    80002eee:	6442                	ld	s0,16(sp)
    80002ef0:	6105                	addi	sp,sp,32
    80002ef2:	8082                	ret

0000000080002ef4 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002ef4:	1141                	addi	sp,sp,-16
    80002ef6:	e406                	sd	ra,8(sp)
    80002ef8:	e022                	sd	s0,0(sp)
    80002efa:	0800                	addi	s0,sp,16
  return kill_system();
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	746080e7          	jalr	1862(ra) # 80002642 <kill_system>
}
    80002f04:	60a2                	ld	ra,8(sp)
    80002f06:	6402                	ld	s0,0(sp)
    80002f08:	0141                	addi	sp,sp,16
    80002f0a:	8082                	ret

0000000080002f0c <sys_debug>:

uint64
sys_debug(void)
{
    80002f0c:	1141                	addi	sp,sp,-16
    80002f0e:	e406                	sd	ra,8(sp)
    80002f10:	e022                	sd	s0,0(sp)
    80002f12:	0800                	addi	s0,sp,16
  debug();
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	78e080e7          	jalr	1934(ra) # 800026a2 <debug>
  return 0;
}
    80002f1c:	4501                	li	a0,0
    80002f1e:	60a2                	ld	ra,8(sp)
    80002f20:	6402                	ld	s0,0(sp)
    80002f22:	0141                	addi	sp,sp,16
    80002f24:	8082                	ret

0000000080002f26 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f26:	7179                	addi	sp,sp,-48
    80002f28:	f406                	sd	ra,40(sp)
    80002f2a:	f022                	sd	s0,32(sp)
    80002f2c:	ec26                	sd	s1,24(sp)
    80002f2e:	e84a                	sd	s2,16(sp)
    80002f30:	e44e                	sd	s3,8(sp)
    80002f32:	e052                	sd	s4,0(sp)
    80002f34:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f36:	00005597          	auipc	a1,0x5
    80002f3a:	5f258593          	addi	a1,a1,1522 # 80008528 <syscalls+0xc8>
    80002f3e:	00014517          	auipc	a0,0x14
    80002f42:	1aa50513          	addi	a0,a0,426 # 800170e8 <bcache>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	c0e080e7          	jalr	-1010(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f4e:	0001c797          	auipc	a5,0x1c
    80002f52:	19a78793          	addi	a5,a5,410 # 8001f0e8 <bcache+0x8000>
    80002f56:	0001c717          	auipc	a4,0x1c
    80002f5a:	3fa70713          	addi	a4,a4,1018 # 8001f350 <bcache+0x8268>
    80002f5e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f62:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f66:	00014497          	auipc	s1,0x14
    80002f6a:	19a48493          	addi	s1,s1,410 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f6e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f70:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f72:	00005a17          	auipc	s4,0x5
    80002f76:	5bea0a13          	addi	s4,s4,1470 # 80008530 <syscalls+0xd0>
    b->next = bcache.head.next;
    80002f7a:	2b893783          	ld	a5,696(s2)
    80002f7e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f80:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f84:	85d2                	mv	a1,s4
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	4bc080e7          	jalr	1212(ra) # 80004446 <initsleeplock>
    bcache.head.next->prev = b;
    80002f92:	2b893783          	ld	a5,696(s2)
    80002f96:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f98:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9c:	45848493          	addi	s1,s1,1112
    80002fa0:	fd349de3          	bne	s1,s3,80002f7a <binit+0x54>
  }
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6942                	ld	s2,16(sp)
    80002fac:	69a2                	ld	s3,8(sp)
    80002fae:	6a02                	ld	s4,0(sp)
    80002fb0:	6145                	addi	sp,sp,48
    80002fb2:	8082                	ret

0000000080002fb4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fb4:	7179                	addi	sp,sp,-48
    80002fb6:	f406                	sd	ra,40(sp)
    80002fb8:	f022                	sd	s0,32(sp)
    80002fba:	ec26                	sd	s1,24(sp)
    80002fbc:	e84a                	sd	s2,16(sp)
    80002fbe:	e44e                	sd	s3,8(sp)
    80002fc0:	1800                	addi	s0,sp,48
    80002fc2:	89aa                	mv	s3,a0
    80002fc4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fc6:	00014517          	auipc	a0,0x14
    80002fca:	12250513          	addi	a0,a0,290 # 800170e8 <bcache>
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	c16080e7          	jalr	-1002(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd6:	0001c497          	auipc	s1,0x1c
    80002fda:	3ca4b483          	ld	s1,970(s1) # 8001f3a0 <bcache+0x82b8>
    80002fde:	0001c797          	auipc	a5,0x1c
    80002fe2:	37278793          	addi	a5,a5,882 # 8001f350 <bcache+0x8268>
    80002fe6:	02f48f63          	beq	s1,a5,80003024 <bread+0x70>
    80002fea:	873e                	mv	a4,a5
    80002fec:	a021                	j	80002ff4 <bread+0x40>
    80002fee:	68a4                	ld	s1,80(s1)
    80002ff0:	02e48a63          	beq	s1,a4,80003024 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ff4:	449c                	lw	a5,8(s1)
    80002ff6:	ff379ce3          	bne	a5,s3,80002fee <bread+0x3a>
    80002ffa:	44dc                	lw	a5,12(s1)
    80002ffc:	ff2799e3          	bne	a5,s2,80002fee <bread+0x3a>
      b->refcnt++;
    80003000:	40bc                	lw	a5,64(s1)
    80003002:	2785                	addiw	a5,a5,1
    80003004:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003006:	00014517          	auipc	a0,0x14
    8000300a:	0e250513          	addi	a0,a0,226 # 800170e8 <bcache>
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	c8a080e7          	jalr	-886(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003016:	01048513          	addi	a0,s1,16
    8000301a:	00001097          	auipc	ra,0x1
    8000301e:	466080e7          	jalr	1126(ra) # 80004480 <acquiresleep>
      return b;
    80003022:	a8b9                	j	80003080 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003024:	0001c497          	auipc	s1,0x1c
    80003028:	3744b483          	ld	s1,884(s1) # 8001f398 <bcache+0x82b0>
    8000302c:	0001c797          	auipc	a5,0x1c
    80003030:	32478793          	addi	a5,a5,804 # 8001f350 <bcache+0x8268>
    80003034:	00f48863          	beq	s1,a5,80003044 <bread+0x90>
    80003038:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000303a:	40bc                	lw	a5,64(s1)
    8000303c:	cf81                	beqz	a5,80003054 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303e:	64a4                	ld	s1,72(s1)
    80003040:	fee49de3          	bne	s1,a4,8000303a <bread+0x86>
  panic("bget: no buffers");
    80003044:	00005517          	auipc	a0,0x5
    80003048:	4f450513          	addi	a0,a0,1268 # 80008538 <syscalls+0xd8>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	4f2080e7          	jalr	1266(ra) # 8000053e <panic>
      b->dev = dev;
    80003054:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003058:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000305c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003060:	4785                	li	a5,1
    80003062:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003064:	00014517          	auipc	a0,0x14
    80003068:	08450513          	addi	a0,a0,132 # 800170e8 <bcache>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	c2c080e7          	jalr	-980(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003074:	01048513          	addi	a0,s1,16
    80003078:	00001097          	auipc	ra,0x1
    8000307c:	408080e7          	jalr	1032(ra) # 80004480 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003080:	409c                	lw	a5,0(s1)
    80003082:	cb89                	beqz	a5,80003094 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003084:	8526                	mv	a0,s1
    80003086:	70a2                	ld	ra,40(sp)
    80003088:	7402                	ld	s0,32(sp)
    8000308a:	64e2                	ld	s1,24(sp)
    8000308c:	6942                	ld	s2,16(sp)
    8000308e:	69a2                	ld	s3,8(sp)
    80003090:	6145                	addi	sp,sp,48
    80003092:	8082                	ret
    virtio_disk_rw(b, 0);
    80003094:	4581                	li	a1,0
    80003096:	8526                	mv	a0,s1
    80003098:	00003097          	auipc	ra,0x3
    8000309c:	f0e080e7          	jalr	-242(ra) # 80005fa6 <virtio_disk_rw>
    b->valid = 1;
    800030a0:	4785                	li	a5,1
    800030a2:	c09c                	sw	a5,0(s1)
  return b;
    800030a4:	b7c5                	j	80003084 <bread+0xd0>

00000000800030a6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	1000                	addi	s0,sp,32
    800030b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b2:	0541                	addi	a0,a0,16
    800030b4:	00001097          	auipc	ra,0x1
    800030b8:	466080e7          	jalr	1126(ra) # 8000451a <holdingsleep>
    800030bc:	cd01                	beqz	a0,800030d4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030be:	4585                	li	a1,1
    800030c0:	8526                	mv	a0,s1
    800030c2:	00003097          	auipc	ra,0x3
    800030c6:	ee4080e7          	jalr	-284(ra) # 80005fa6 <virtio_disk_rw>
}
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	64a2                	ld	s1,8(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret
    panic("bwrite");
    800030d4:	00005517          	auipc	a0,0x5
    800030d8:	47c50513          	addi	a0,a0,1148 # 80008550 <syscalls+0xf0>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	462080e7          	jalr	1122(ra) # 8000053e <panic>

00000000800030e4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	e04a                	sd	s2,0(sp)
    800030ee:	1000                	addi	s0,sp,32
    800030f0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f2:	01050913          	addi	s2,a0,16
    800030f6:	854a                	mv	a0,s2
    800030f8:	00001097          	auipc	ra,0x1
    800030fc:	422080e7          	jalr	1058(ra) # 8000451a <holdingsleep>
    80003100:	c92d                	beqz	a0,80003172 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003102:	854a                	mv	a0,s2
    80003104:	00001097          	auipc	ra,0x1
    80003108:	3d2080e7          	jalr	978(ra) # 800044d6 <releasesleep>

  acquire(&bcache.lock);
    8000310c:	00014517          	auipc	a0,0x14
    80003110:	fdc50513          	addi	a0,a0,-36 # 800170e8 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	ad0080e7          	jalr	-1328(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	37fd                	addiw	a5,a5,-1
    80003120:	0007871b          	sext.w	a4,a5
    80003124:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003126:	eb05                	bnez	a4,80003156 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003128:	68bc                	ld	a5,80(s1)
    8000312a:	64b8                	ld	a4,72(s1)
    8000312c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000312e:	64bc                	ld	a5,72(s1)
    80003130:	68b8                	ld	a4,80(s1)
    80003132:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003134:	0001c797          	auipc	a5,0x1c
    80003138:	fb478793          	addi	a5,a5,-76 # 8001f0e8 <bcache+0x8000>
    8000313c:	2b87b703          	ld	a4,696(a5)
    80003140:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003142:	0001c717          	auipc	a4,0x1c
    80003146:	20e70713          	addi	a4,a4,526 # 8001f350 <bcache+0x8268>
    8000314a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000314c:	2b87b703          	ld	a4,696(a5)
    80003150:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003152:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003156:	00014517          	auipc	a0,0x14
    8000315a:	f9250513          	addi	a0,a0,-110 # 800170e8 <bcache>
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	b3a080e7          	jalr	-1222(ra) # 80000c98 <release>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6902                	ld	s2,0(sp)
    8000316e:	6105                	addi	sp,sp,32
    80003170:	8082                	ret
    panic("brelse");
    80003172:	00005517          	auipc	a0,0x5
    80003176:	3e650513          	addi	a0,a0,998 # 80008558 <syscalls+0xf8>
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	3c4080e7          	jalr	964(ra) # 8000053e <panic>

0000000080003182 <bpin>:

void
bpin(struct buf *b) {
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	e426                	sd	s1,8(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	f5a50513          	addi	a0,a0,-166 # 800170e8 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	a4e080e7          	jalr	-1458(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000319e:	40bc                	lw	a5,64(s1)
    800031a0:	2785                	addiw	a5,a5,1
    800031a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	f4450513          	addi	a0,a0,-188 # 800170e8 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	aec080e7          	jalr	-1300(ra) # 80000c98 <release>
}
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	64a2                	ld	s1,8(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret

00000000800031be <bunpin>:

void
bunpin(struct buf *b) {
    800031be:	1101                	addi	sp,sp,-32
    800031c0:	ec06                	sd	ra,24(sp)
    800031c2:	e822                	sd	s0,16(sp)
    800031c4:	e426                	sd	s1,8(sp)
    800031c6:	1000                	addi	s0,sp,32
    800031c8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ca:	00014517          	auipc	a0,0x14
    800031ce:	f1e50513          	addi	a0,a0,-226 # 800170e8 <bcache>
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	a12080e7          	jalr	-1518(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031da:	40bc                	lw	a5,64(s1)
    800031dc:	37fd                	addiw	a5,a5,-1
    800031de:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e0:	00014517          	auipc	a0,0x14
    800031e4:	f0850513          	addi	a0,a0,-248 # 800170e8 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	ab0080e7          	jalr	-1360(ra) # 80000c98 <release>
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6105                	addi	sp,sp,32
    800031f8:	8082                	ret

00000000800031fa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031fa:	1101                	addi	sp,sp,-32
    800031fc:	ec06                	sd	ra,24(sp)
    800031fe:	e822                	sd	s0,16(sp)
    80003200:	e426                	sd	s1,8(sp)
    80003202:	e04a                	sd	s2,0(sp)
    80003204:	1000                	addi	s0,sp,32
    80003206:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003208:	00d5d59b          	srliw	a1,a1,0xd
    8000320c:	0001c797          	auipc	a5,0x1c
    80003210:	5b87a783          	lw	a5,1464(a5) # 8001f7c4 <sb+0x1c>
    80003214:	9dbd                	addw	a1,a1,a5
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	d9e080e7          	jalr	-610(ra) # 80002fb4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000321e:	0074f713          	andi	a4,s1,7
    80003222:	4785                	li	a5,1
    80003224:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003228:	14ce                	slli	s1,s1,0x33
    8000322a:	90d9                	srli	s1,s1,0x36
    8000322c:	00950733          	add	a4,a0,s1
    80003230:	05874703          	lbu	a4,88(a4)
    80003234:	00e7f6b3          	and	a3,a5,a4
    80003238:	c69d                	beqz	a3,80003266 <bfree+0x6c>
    8000323a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000323c:	94aa                	add	s1,s1,a0
    8000323e:	fff7c793          	not	a5,a5
    80003242:	8ff9                	and	a5,a5,a4
    80003244:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003248:	00001097          	auipc	ra,0x1
    8000324c:	118080e7          	jalr	280(ra) # 80004360 <log_write>
  brelse(bp);
    80003250:	854a                	mv	a0,s2
    80003252:	00000097          	auipc	ra,0x0
    80003256:	e92080e7          	jalr	-366(ra) # 800030e4 <brelse>
}
    8000325a:	60e2                	ld	ra,24(sp)
    8000325c:	6442                	ld	s0,16(sp)
    8000325e:	64a2                	ld	s1,8(sp)
    80003260:	6902                	ld	s2,0(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret
    panic("freeing free block");
    80003266:	00005517          	auipc	a0,0x5
    8000326a:	2fa50513          	addi	a0,a0,762 # 80008560 <syscalls+0x100>
    8000326e:	ffffd097          	auipc	ra,0xffffd
    80003272:	2d0080e7          	jalr	720(ra) # 8000053e <panic>

0000000080003276 <balloc>:
{
    80003276:	711d                	addi	sp,sp,-96
    80003278:	ec86                	sd	ra,88(sp)
    8000327a:	e8a2                	sd	s0,80(sp)
    8000327c:	e4a6                	sd	s1,72(sp)
    8000327e:	e0ca                	sd	s2,64(sp)
    80003280:	fc4e                	sd	s3,56(sp)
    80003282:	f852                	sd	s4,48(sp)
    80003284:	f456                	sd	s5,40(sp)
    80003286:	f05a                	sd	s6,32(sp)
    80003288:	ec5e                	sd	s7,24(sp)
    8000328a:	e862                	sd	s8,16(sp)
    8000328c:	e466                	sd	s9,8(sp)
    8000328e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003290:	0001c797          	auipc	a5,0x1c
    80003294:	51c7a783          	lw	a5,1308(a5) # 8001f7ac <sb+0x4>
    80003298:	cbd1                	beqz	a5,8000332c <balloc+0xb6>
    8000329a:	8baa                	mv	s7,a0
    8000329c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000329e:	0001cb17          	auipc	s6,0x1c
    800032a2:	50ab0b13          	addi	s6,s6,1290 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032a8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032aa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032ac:	6c89                	lui	s9,0x2
    800032ae:	a831                	j	800032ca <balloc+0x54>
    brelse(bp);
    800032b0:	854a                	mv	a0,s2
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	e32080e7          	jalr	-462(ra) # 800030e4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032ba:	015c87bb          	addw	a5,s9,s5
    800032be:	00078a9b          	sext.w	s5,a5
    800032c2:	004b2703          	lw	a4,4(s6)
    800032c6:	06eaf363          	bgeu	s5,a4,8000332c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032ca:	41fad79b          	sraiw	a5,s5,0x1f
    800032ce:	0137d79b          	srliw	a5,a5,0x13
    800032d2:	015787bb          	addw	a5,a5,s5
    800032d6:	40d7d79b          	sraiw	a5,a5,0xd
    800032da:	01cb2583          	lw	a1,28(s6)
    800032de:	9dbd                	addw	a1,a1,a5
    800032e0:	855e                	mv	a0,s7
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	cd2080e7          	jalr	-814(ra) # 80002fb4 <bread>
    800032ea:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ec:	004b2503          	lw	a0,4(s6)
    800032f0:	000a849b          	sext.w	s1,s5
    800032f4:	8662                	mv	a2,s8
    800032f6:	faa4fde3          	bgeu	s1,a0,800032b0 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032fa:	41f6579b          	sraiw	a5,a2,0x1f
    800032fe:	01d7d69b          	srliw	a3,a5,0x1d
    80003302:	00c6873b          	addw	a4,a3,a2
    80003306:	00777793          	andi	a5,a4,7
    8000330a:	9f95                	subw	a5,a5,a3
    8000330c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003310:	4037571b          	sraiw	a4,a4,0x3
    80003314:	00e906b3          	add	a3,s2,a4
    80003318:	0586c683          	lbu	a3,88(a3)
    8000331c:	00d7f5b3          	and	a1,a5,a3
    80003320:	cd91                	beqz	a1,8000333c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003322:	2605                	addiw	a2,a2,1
    80003324:	2485                	addiw	s1,s1,1
    80003326:	fd4618e3          	bne	a2,s4,800032f6 <balloc+0x80>
    8000332a:	b759                	j	800032b0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000332c:	00005517          	auipc	a0,0x5
    80003330:	24c50513          	addi	a0,a0,588 # 80008578 <syscalls+0x118>
    80003334:	ffffd097          	auipc	ra,0xffffd
    80003338:	20a080e7          	jalr	522(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000333c:	974a                	add	a4,a4,s2
    8000333e:	8fd5                	or	a5,a5,a3
    80003340:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003344:	854a                	mv	a0,s2
    80003346:	00001097          	auipc	ra,0x1
    8000334a:	01a080e7          	jalr	26(ra) # 80004360 <log_write>
        brelse(bp);
    8000334e:	854a                	mv	a0,s2
    80003350:	00000097          	auipc	ra,0x0
    80003354:	d94080e7          	jalr	-620(ra) # 800030e4 <brelse>
  bp = bread(dev, bno);
    80003358:	85a6                	mv	a1,s1
    8000335a:	855e                	mv	a0,s7
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	c58080e7          	jalr	-936(ra) # 80002fb4 <bread>
    80003364:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003366:	40000613          	li	a2,1024
    8000336a:	4581                	li	a1,0
    8000336c:	05850513          	addi	a0,a0,88
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	970080e7          	jalr	-1680(ra) # 80000ce0 <memset>
  log_write(bp);
    80003378:	854a                	mv	a0,s2
    8000337a:	00001097          	auipc	ra,0x1
    8000337e:	fe6080e7          	jalr	-26(ra) # 80004360 <log_write>
  brelse(bp);
    80003382:	854a                	mv	a0,s2
    80003384:	00000097          	auipc	ra,0x0
    80003388:	d60080e7          	jalr	-672(ra) # 800030e4 <brelse>
}
    8000338c:	8526                	mv	a0,s1
    8000338e:	60e6                	ld	ra,88(sp)
    80003390:	6446                	ld	s0,80(sp)
    80003392:	64a6                	ld	s1,72(sp)
    80003394:	6906                	ld	s2,64(sp)
    80003396:	79e2                	ld	s3,56(sp)
    80003398:	7a42                	ld	s4,48(sp)
    8000339a:	7aa2                	ld	s5,40(sp)
    8000339c:	7b02                	ld	s6,32(sp)
    8000339e:	6be2                	ld	s7,24(sp)
    800033a0:	6c42                	ld	s8,16(sp)
    800033a2:	6ca2                	ld	s9,8(sp)
    800033a4:	6125                	addi	sp,sp,96
    800033a6:	8082                	ret

00000000800033a8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033a8:	7179                	addi	sp,sp,-48
    800033aa:	f406                	sd	ra,40(sp)
    800033ac:	f022                	sd	s0,32(sp)
    800033ae:	ec26                	sd	s1,24(sp)
    800033b0:	e84a                	sd	s2,16(sp)
    800033b2:	e44e                	sd	s3,8(sp)
    800033b4:	e052                	sd	s4,0(sp)
    800033b6:	1800                	addi	s0,sp,48
    800033b8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033ba:	47ad                	li	a5,11
    800033bc:	04b7fe63          	bgeu	a5,a1,80003418 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033c0:	ff45849b          	addiw	s1,a1,-12
    800033c4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033c8:	0ff00793          	li	a5,255
    800033cc:	0ae7e363          	bltu	a5,a4,80003472 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033d0:	08052583          	lw	a1,128(a0)
    800033d4:	c5ad                	beqz	a1,8000343e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033d6:	00092503          	lw	a0,0(s2)
    800033da:	00000097          	auipc	ra,0x0
    800033de:	bda080e7          	jalr	-1062(ra) # 80002fb4 <bread>
    800033e2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033e4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033e8:	02049593          	slli	a1,s1,0x20
    800033ec:	9181                	srli	a1,a1,0x20
    800033ee:	058a                	slli	a1,a1,0x2
    800033f0:	00b784b3          	add	s1,a5,a1
    800033f4:	0004a983          	lw	s3,0(s1)
    800033f8:	04098d63          	beqz	s3,80003452 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033fc:	8552                	mv	a0,s4
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	ce6080e7          	jalr	-794(ra) # 800030e4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003406:	854e                	mv	a0,s3
    80003408:	70a2                	ld	ra,40(sp)
    8000340a:	7402                	ld	s0,32(sp)
    8000340c:	64e2                	ld	s1,24(sp)
    8000340e:	6942                	ld	s2,16(sp)
    80003410:	69a2                	ld	s3,8(sp)
    80003412:	6a02                	ld	s4,0(sp)
    80003414:	6145                	addi	sp,sp,48
    80003416:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003418:	02059493          	slli	s1,a1,0x20
    8000341c:	9081                	srli	s1,s1,0x20
    8000341e:	048a                	slli	s1,s1,0x2
    80003420:	94aa                	add	s1,s1,a0
    80003422:	0504a983          	lw	s3,80(s1)
    80003426:	fe0990e3          	bnez	s3,80003406 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000342a:	4108                	lw	a0,0(a0)
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	e4a080e7          	jalr	-438(ra) # 80003276 <balloc>
    80003434:	0005099b          	sext.w	s3,a0
    80003438:	0534a823          	sw	s3,80(s1)
    8000343c:	b7e9                	j	80003406 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000343e:	4108                	lw	a0,0(a0)
    80003440:	00000097          	auipc	ra,0x0
    80003444:	e36080e7          	jalr	-458(ra) # 80003276 <balloc>
    80003448:	0005059b          	sext.w	a1,a0
    8000344c:	08b92023          	sw	a1,128(s2)
    80003450:	b759                	j	800033d6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003452:	00092503          	lw	a0,0(s2)
    80003456:	00000097          	auipc	ra,0x0
    8000345a:	e20080e7          	jalr	-480(ra) # 80003276 <balloc>
    8000345e:	0005099b          	sext.w	s3,a0
    80003462:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003466:	8552                	mv	a0,s4
    80003468:	00001097          	auipc	ra,0x1
    8000346c:	ef8080e7          	jalr	-264(ra) # 80004360 <log_write>
    80003470:	b771                	j	800033fc <bmap+0x54>
  panic("bmap: out of range");
    80003472:	00005517          	auipc	a0,0x5
    80003476:	11e50513          	addi	a0,a0,286 # 80008590 <syscalls+0x130>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>

0000000080003482 <iget>:
{
    80003482:	7179                	addi	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	e052                	sd	s4,0(sp)
    80003490:	1800                	addi	s0,sp,48
    80003492:	89aa                	mv	s3,a0
    80003494:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003496:	0001c517          	auipc	a0,0x1c
    8000349a:	33250513          	addi	a0,a0,818 # 8001f7c8 <itable>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	746080e7          	jalr	1862(ra) # 80000be4 <acquire>
  empty = 0;
    800034a6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034a8:	0001c497          	auipc	s1,0x1c
    800034ac:	33848493          	addi	s1,s1,824 # 8001f7e0 <itable+0x18>
    800034b0:	0001e697          	auipc	a3,0x1e
    800034b4:	dc068693          	addi	a3,a3,-576 # 80021270 <log>
    800034b8:	a039                	j	800034c6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ba:	02090b63          	beqz	s2,800034f0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034be:	08848493          	addi	s1,s1,136
    800034c2:	02d48a63          	beq	s1,a3,800034f6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034c6:	449c                	lw	a5,8(s1)
    800034c8:	fef059e3          	blez	a5,800034ba <iget+0x38>
    800034cc:	4098                	lw	a4,0(s1)
    800034ce:	ff3716e3          	bne	a4,s3,800034ba <iget+0x38>
    800034d2:	40d8                	lw	a4,4(s1)
    800034d4:	ff4713e3          	bne	a4,s4,800034ba <iget+0x38>
      ip->ref++;
    800034d8:	2785                	addiw	a5,a5,1
    800034da:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034dc:	0001c517          	auipc	a0,0x1c
    800034e0:	2ec50513          	addi	a0,a0,748 # 8001f7c8 <itable>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	7b4080e7          	jalr	1972(ra) # 80000c98 <release>
      return ip;
    800034ec:	8926                	mv	s2,s1
    800034ee:	a03d                	j	8000351c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f0:	f7f9                	bnez	a5,800034be <iget+0x3c>
    800034f2:	8926                	mv	s2,s1
    800034f4:	b7e9                	j	800034be <iget+0x3c>
  if(empty == 0)
    800034f6:	02090c63          	beqz	s2,8000352e <iget+0xac>
  ip->dev = dev;
    800034fa:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034fe:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003502:	4785                	li	a5,1
    80003504:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003508:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000350c:	0001c517          	auipc	a0,0x1c
    80003510:	2bc50513          	addi	a0,a0,700 # 8001f7c8 <itable>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
}
    8000351c:	854a                	mv	a0,s2
    8000351e:	70a2                	ld	ra,40(sp)
    80003520:	7402                	ld	s0,32(sp)
    80003522:	64e2                	ld	s1,24(sp)
    80003524:	6942                	ld	s2,16(sp)
    80003526:	69a2                	ld	s3,8(sp)
    80003528:	6a02                	ld	s4,0(sp)
    8000352a:	6145                	addi	sp,sp,48
    8000352c:	8082                	ret
    panic("iget: no inodes");
    8000352e:	00005517          	auipc	a0,0x5
    80003532:	07a50513          	addi	a0,a0,122 # 800085a8 <syscalls+0x148>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	008080e7          	jalr	8(ra) # 8000053e <panic>

000000008000353e <fsinit>:
fsinit(int dev) {
    8000353e:	7179                	addi	sp,sp,-48
    80003540:	f406                	sd	ra,40(sp)
    80003542:	f022                	sd	s0,32(sp)
    80003544:	ec26                	sd	s1,24(sp)
    80003546:	e84a                	sd	s2,16(sp)
    80003548:	e44e                	sd	s3,8(sp)
    8000354a:	1800                	addi	s0,sp,48
    8000354c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000354e:	4585                	li	a1,1
    80003550:	00000097          	auipc	ra,0x0
    80003554:	a64080e7          	jalr	-1436(ra) # 80002fb4 <bread>
    80003558:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000355a:	0001c997          	auipc	s3,0x1c
    8000355e:	24e98993          	addi	s3,s3,590 # 8001f7a8 <sb>
    80003562:	02000613          	li	a2,32
    80003566:	05850593          	addi	a1,a0,88
    8000356a:	854e                	mv	a0,s3
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	7d4080e7          	jalr	2004(ra) # 80000d40 <memmove>
  brelse(bp);
    80003574:	8526                	mv	a0,s1
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	b6e080e7          	jalr	-1170(ra) # 800030e4 <brelse>
  if(sb.magic != FSMAGIC)
    8000357e:	0009a703          	lw	a4,0(s3)
    80003582:	102037b7          	lui	a5,0x10203
    80003586:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000358a:	02f71263          	bne	a4,a5,800035ae <fsinit+0x70>
  initlog(dev, &sb);
    8000358e:	0001c597          	auipc	a1,0x1c
    80003592:	21a58593          	addi	a1,a1,538 # 8001f7a8 <sb>
    80003596:	854a                	mv	a0,s2
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	b4c080e7          	jalr	-1204(ra) # 800040e4 <initlog>
}
    800035a0:	70a2                	ld	ra,40(sp)
    800035a2:	7402                	ld	s0,32(sp)
    800035a4:	64e2                	ld	s1,24(sp)
    800035a6:	6942                	ld	s2,16(sp)
    800035a8:	69a2                	ld	s3,8(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret
    panic("invalid file system");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	00a50513          	addi	a0,a0,10 # 800085b8 <syscalls+0x158>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>

00000000800035be <iinit>:
{
    800035be:	7179                	addi	sp,sp,-48
    800035c0:	f406                	sd	ra,40(sp)
    800035c2:	f022                	sd	s0,32(sp)
    800035c4:	ec26                	sd	s1,24(sp)
    800035c6:	e84a                	sd	s2,16(sp)
    800035c8:	e44e                	sd	s3,8(sp)
    800035ca:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035cc:	00005597          	auipc	a1,0x5
    800035d0:	00458593          	addi	a1,a1,4 # 800085d0 <syscalls+0x170>
    800035d4:	0001c517          	auipc	a0,0x1c
    800035d8:	1f450513          	addi	a0,a0,500 # 8001f7c8 <itable>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	578080e7          	jalr	1400(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035e4:	0001c497          	auipc	s1,0x1c
    800035e8:	20c48493          	addi	s1,s1,524 # 8001f7f0 <itable+0x28>
    800035ec:	0001e997          	auipc	s3,0x1e
    800035f0:	c9498993          	addi	s3,s3,-876 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035f4:	00005917          	auipc	s2,0x5
    800035f8:	fe490913          	addi	s2,s2,-28 # 800085d8 <syscalls+0x178>
    800035fc:	85ca                	mv	a1,s2
    800035fe:	8526                	mv	a0,s1
    80003600:	00001097          	auipc	ra,0x1
    80003604:	e46080e7          	jalr	-442(ra) # 80004446 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003608:	08848493          	addi	s1,s1,136
    8000360c:	ff3498e3          	bne	s1,s3,800035fc <iinit+0x3e>
}
    80003610:	70a2                	ld	ra,40(sp)
    80003612:	7402                	ld	s0,32(sp)
    80003614:	64e2                	ld	s1,24(sp)
    80003616:	6942                	ld	s2,16(sp)
    80003618:	69a2                	ld	s3,8(sp)
    8000361a:	6145                	addi	sp,sp,48
    8000361c:	8082                	ret

000000008000361e <ialloc>:
{
    8000361e:	715d                	addi	sp,sp,-80
    80003620:	e486                	sd	ra,72(sp)
    80003622:	e0a2                	sd	s0,64(sp)
    80003624:	fc26                	sd	s1,56(sp)
    80003626:	f84a                	sd	s2,48(sp)
    80003628:	f44e                	sd	s3,40(sp)
    8000362a:	f052                	sd	s4,32(sp)
    8000362c:	ec56                	sd	s5,24(sp)
    8000362e:	e85a                	sd	s6,16(sp)
    80003630:	e45e                	sd	s7,8(sp)
    80003632:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003634:	0001c717          	auipc	a4,0x1c
    80003638:	18072703          	lw	a4,384(a4) # 8001f7b4 <sb+0xc>
    8000363c:	4785                	li	a5,1
    8000363e:	04e7fa63          	bgeu	a5,a4,80003692 <ialloc+0x74>
    80003642:	8aaa                	mv	s5,a0
    80003644:	8bae                	mv	s7,a1
    80003646:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003648:	0001ca17          	auipc	s4,0x1c
    8000364c:	160a0a13          	addi	s4,s4,352 # 8001f7a8 <sb>
    80003650:	00048b1b          	sext.w	s6,s1
    80003654:	0044d593          	srli	a1,s1,0x4
    80003658:	018a2783          	lw	a5,24(s4)
    8000365c:	9dbd                	addw	a1,a1,a5
    8000365e:	8556                	mv	a0,s5
    80003660:	00000097          	auipc	ra,0x0
    80003664:	954080e7          	jalr	-1708(ra) # 80002fb4 <bread>
    80003668:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000366a:	05850993          	addi	s3,a0,88
    8000366e:	00f4f793          	andi	a5,s1,15
    80003672:	079a                	slli	a5,a5,0x6
    80003674:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003676:	00099783          	lh	a5,0(s3)
    8000367a:	c785                	beqz	a5,800036a2 <ialloc+0x84>
    brelse(bp);
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	a68080e7          	jalr	-1432(ra) # 800030e4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003684:	0485                	addi	s1,s1,1
    80003686:	00ca2703          	lw	a4,12(s4)
    8000368a:	0004879b          	sext.w	a5,s1
    8000368e:	fce7e1e3          	bltu	a5,a4,80003650 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003692:	00005517          	auipc	a0,0x5
    80003696:	f4e50513          	addi	a0,a0,-178 # 800085e0 <syscalls+0x180>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	ea4080e7          	jalr	-348(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800036a2:	04000613          	li	a2,64
    800036a6:	4581                	li	a1,0
    800036a8:	854e                	mv	a0,s3
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	636080e7          	jalr	1590(ra) # 80000ce0 <memset>
      dip->type = type;
    800036b2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036b6:	854a                	mv	a0,s2
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	ca8080e7          	jalr	-856(ra) # 80004360 <log_write>
      brelse(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	a22080e7          	jalr	-1502(ra) # 800030e4 <brelse>
      return iget(dev, inum);
    800036ca:	85da                	mv	a1,s6
    800036cc:	8556                	mv	a0,s5
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	db4080e7          	jalr	-588(ra) # 80003482 <iget>
}
    800036d6:	60a6                	ld	ra,72(sp)
    800036d8:	6406                	ld	s0,64(sp)
    800036da:	74e2                	ld	s1,56(sp)
    800036dc:	7942                	ld	s2,48(sp)
    800036de:	79a2                	ld	s3,40(sp)
    800036e0:	7a02                	ld	s4,32(sp)
    800036e2:	6ae2                	ld	s5,24(sp)
    800036e4:	6b42                	ld	s6,16(sp)
    800036e6:	6ba2                	ld	s7,8(sp)
    800036e8:	6161                	addi	sp,sp,80
    800036ea:	8082                	ret

00000000800036ec <iupdate>:
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	e426                	sd	s1,8(sp)
    800036f4:	e04a                	sd	s2,0(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036fa:	415c                	lw	a5,4(a0)
    800036fc:	0047d79b          	srliw	a5,a5,0x4
    80003700:	0001c597          	auipc	a1,0x1c
    80003704:	0c05a583          	lw	a1,192(a1) # 8001f7c0 <sb+0x18>
    80003708:	9dbd                	addw	a1,a1,a5
    8000370a:	4108                	lw	a0,0(a0)
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	8a8080e7          	jalr	-1880(ra) # 80002fb4 <bread>
    80003714:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003716:	05850793          	addi	a5,a0,88
    8000371a:	40c8                	lw	a0,4(s1)
    8000371c:	893d                	andi	a0,a0,15
    8000371e:	051a                	slli	a0,a0,0x6
    80003720:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003722:	04449703          	lh	a4,68(s1)
    80003726:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000372a:	04649703          	lh	a4,70(s1)
    8000372e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003732:	04849703          	lh	a4,72(s1)
    80003736:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000373a:	04a49703          	lh	a4,74(s1)
    8000373e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003742:	44f8                	lw	a4,76(s1)
    80003744:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003746:	03400613          	li	a2,52
    8000374a:	05048593          	addi	a1,s1,80
    8000374e:	0531                	addi	a0,a0,12
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	5f0080e7          	jalr	1520(ra) # 80000d40 <memmove>
  log_write(bp);
    80003758:	854a                	mv	a0,s2
    8000375a:	00001097          	auipc	ra,0x1
    8000375e:	c06080e7          	jalr	-1018(ra) # 80004360 <log_write>
  brelse(bp);
    80003762:	854a                	mv	a0,s2
    80003764:	00000097          	auipc	ra,0x0
    80003768:	980080e7          	jalr	-1664(ra) # 800030e4 <brelse>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret

0000000080003778 <idup>:
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	1000                	addi	s0,sp,32
    80003782:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003784:	0001c517          	auipc	a0,0x1c
    80003788:	04450513          	addi	a0,a0,68 # 8001f7c8 <itable>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	458080e7          	jalr	1112(ra) # 80000be4 <acquire>
  ip->ref++;
    80003794:	449c                	lw	a5,8(s1)
    80003796:	2785                	addiw	a5,a5,1
    80003798:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000379a:	0001c517          	auipc	a0,0x1c
    8000379e:	02e50513          	addi	a0,a0,46 # 8001f7c8 <itable>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	4f6080e7          	jalr	1270(ra) # 80000c98 <release>
}
    800037aa:	8526                	mv	a0,s1
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	64a2                	ld	s1,8(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret

00000000800037b6 <ilock>:
{
    800037b6:	1101                	addi	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	e04a                	sd	s2,0(sp)
    800037c0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037c2:	c115                	beqz	a0,800037e6 <ilock+0x30>
    800037c4:	84aa                	mv	s1,a0
    800037c6:	451c                	lw	a5,8(a0)
    800037c8:	00f05f63          	blez	a5,800037e6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037cc:	0541                	addi	a0,a0,16
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	cb2080e7          	jalr	-846(ra) # 80004480 <acquiresleep>
  if(ip->valid == 0){
    800037d6:	40bc                	lw	a5,64(s1)
    800037d8:	cf99                	beqz	a5,800037f6 <ilock+0x40>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6902                	ld	s2,0(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret
    panic("ilock");
    800037e6:	00005517          	auipc	a0,0x5
    800037ea:	e1250513          	addi	a0,a0,-494 # 800085f8 <syscalls+0x198>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	d50080e7          	jalr	-688(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f6:	40dc                	lw	a5,4(s1)
    800037f8:	0047d79b          	srliw	a5,a5,0x4
    800037fc:	0001c597          	auipc	a1,0x1c
    80003800:	fc45a583          	lw	a1,-60(a1) # 8001f7c0 <sb+0x18>
    80003804:	9dbd                	addw	a1,a1,a5
    80003806:	4088                	lw	a0,0(s1)
    80003808:	fffff097          	auipc	ra,0xfffff
    8000380c:	7ac080e7          	jalr	1964(ra) # 80002fb4 <bread>
    80003810:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003812:	05850593          	addi	a1,a0,88
    80003816:	40dc                	lw	a5,4(s1)
    80003818:	8bbd                	andi	a5,a5,15
    8000381a:	079a                	slli	a5,a5,0x6
    8000381c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000381e:	00059783          	lh	a5,0(a1)
    80003822:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003826:	00259783          	lh	a5,2(a1)
    8000382a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000382e:	00459783          	lh	a5,4(a1)
    80003832:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003836:	00659783          	lh	a5,6(a1)
    8000383a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000383e:	459c                	lw	a5,8(a1)
    80003840:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003842:	03400613          	li	a2,52
    80003846:	05b1                	addi	a1,a1,12
    80003848:	05048513          	addi	a0,s1,80
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	4f4080e7          	jalr	1268(ra) # 80000d40 <memmove>
    brelse(bp);
    80003854:	854a                	mv	a0,s2
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	88e080e7          	jalr	-1906(ra) # 800030e4 <brelse>
    ip->valid = 1;
    8000385e:	4785                	li	a5,1
    80003860:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003862:	04449783          	lh	a5,68(s1)
    80003866:	fbb5                	bnez	a5,800037da <ilock+0x24>
      panic("ilock: no type");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	d9850513          	addi	a0,a0,-616 # 80008600 <syscalls+0x1a0>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	cce080e7          	jalr	-818(ra) # 8000053e <panic>

0000000080003878 <iunlock>:
{
    80003878:	1101                	addi	sp,sp,-32
    8000387a:	ec06                	sd	ra,24(sp)
    8000387c:	e822                	sd	s0,16(sp)
    8000387e:	e426                	sd	s1,8(sp)
    80003880:	e04a                	sd	s2,0(sp)
    80003882:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003884:	c905                	beqz	a0,800038b4 <iunlock+0x3c>
    80003886:	84aa                	mv	s1,a0
    80003888:	01050913          	addi	s2,a0,16
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	c8c080e7          	jalr	-884(ra) # 8000451a <holdingsleep>
    80003896:	cd19                	beqz	a0,800038b4 <iunlock+0x3c>
    80003898:	449c                	lw	a5,8(s1)
    8000389a:	00f05d63          	blez	a5,800038b4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	c36080e7          	jalr	-970(ra) # 800044d6 <releasesleep>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6902                	ld	s2,0(sp)
    800038b0:	6105                	addi	sp,sp,32
    800038b2:	8082                	ret
    panic("iunlock");
    800038b4:	00005517          	auipc	a0,0x5
    800038b8:	d5c50513          	addi	a0,a0,-676 # 80008610 <syscalls+0x1b0>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>

00000000800038c4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038c4:	7179                	addi	sp,sp,-48
    800038c6:	f406                	sd	ra,40(sp)
    800038c8:	f022                	sd	s0,32(sp)
    800038ca:	ec26                	sd	s1,24(sp)
    800038cc:	e84a                	sd	s2,16(sp)
    800038ce:	e44e                	sd	s3,8(sp)
    800038d0:	e052                	sd	s4,0(sp)
    800038d2:	1800                	addi	s0,sp,48
    800038d4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038d6:	05050493          	addi	s1,a0,80
    800038da:	08050913          	addi	s2,a0,128
    800038de:	a021                	j	800038e6 <itrunc+0x22>
    800038e0:	0491                	addi	s1,s1,4
    800038e2:	01248d63          	beq	s1,s2,800038fc <itrunc+0x38>
    if(ip->addrs[i]){
    800038e6:	408c                	lw	a1,0(s1)
    800038e8:	dde5                	beqz	a1,800038e0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ea:	0009a503          	lw	a0,0(s3)
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	90c080e7          	jalr	-1780(ra) # 800031fa <bfree>
      ip->addrs[i] = 0;
    800038f6:	0004a023          	sw	zero,0(s1)
    800038fa:	b7dd                	j	800038e0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038fc:	0809a583          	lw	a1,128(s3)
    80003900:	e185                	bnez	a1,80003920 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003902:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003906:	854e                	mv	a0,s3
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	de4080e7          	jalr	-540(ra) # 800036ec <iupdate>
}
    80003910:	70a2                	ld	ra,40(sp)
    80003912:	7402                	ld	s0,32(sp)
    80003914:	64e2                	ld	s1,24(sp)
    80003916:	6942                	ld	s2,16(sp)
    80003918:	69a2                	ld	s3,8(sp)
    8000391a:	6a02                	ld	s4,0(sp)
    8000391c:	6145                	addi	sp,sp,48
    8000391e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003920:	0009a503          	lw	a0,0(s3)
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	690080e7          	jalr	1680(ra) # 80002fb4 <bread>
    8000392c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000392e:	05850493          	addi	s1,a0,88
    80003932:	45850913          	addi	s2,a0,1112
    80003936:	a811                	j	8000394a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003938:	0009a503          	lw	a0,0(s3)
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	8be080e7          	jalr	-1858(ra) # 800031fa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003944:	0491                	addi	s1,s1,4
    80003946:	01248563          	beq	s1,s2,80003950 <itrunc+0x8c>
      if(a[j])
    8000394a:	408c                	lw	a1,0(s1)
    8000394c:	dde5                	beqz	a1,80003944 <itrunc+0x80>
    8000394e:	b7ed                	j	80003938 <itrunc+0x74>
    brelse(bp);
    80003950:	8552                	mv	a0,s4
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	792080e7          	jalr	1938(ra) # 800030e4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000395a:	0809a583          	lw	a1,128(s3)
    8000395e:	0009a503          	lw	a0,0(s3)
    80003962:	00000097          	auipc	ra,0x0
    80003966:	898080e7          	jalr	-1896(ra) # 800031fa <bfree>
    ip->addrs[NDIRECT] = 0;
    8000396a:	0809a023          	sw	zero,128(s3)
    8000396e:	bf51                	j	80003902 <itrunc+0x3e>

0000000080003970 <iput>:
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	e04a                	sd	s2,0(sp)
    8000397a:	1000                	addi	s0,sp,32
    8000397c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000397e:	0001c517          	auipc	a0,0x1c
    80003982:	e4a50513          	addi	a0,a0,-438 # 8001f7c8 <itable>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	25e080e7          	jalr	606(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000398e:	4498                	lw	a4,8(s1)
    80003990:	4785                	li	a5,1
    80003992:	02f70363          	beq	a4,a5,800039b8 <iput+0x48>
  ip->ref--;
    80003996:	449c                	lw	a5,8(s1)
    80003998:	37fd                	addiw	a5,a5,-1
    8000399a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000399c:	0001c517          	auipc	a0,0x1c
    800039a0:	e2c50513          	addi	a0,a0,-468 # 8001f7c8 <itable>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	2f4080e7          	jalr	756(ra) # 80000c98 <release>
}
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6902                	ld	s2,0(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b8:	40bc                	lw	a5,64(s1)
    800039ba:	dff1                	beqz	a5,80003996 <iput+0x26>
    800039bc:	04a49783          	lh	a5,74(s1)
    800039c0:	fbf9                	bnez	a5,80003996 <iput+0x26>
    acquiresleep(&ip->lock);
    800039c2:	01048913          	addi	s2,s1,16
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	ab8080e7          	jalr	-1352(ra) # 80004480 <acquiresleep>
    release(&itable.lock);
    800039d0:	0001c517          	auipc	a0,0x1c
    800039d4:	df850513          	addi	a0,a0,-520 # 8001f7c8 <itable>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	2c0080e7          	jalr	704(ra) # 80000c98 <release>
    itrunc(ip);
    800039e0:	8526                	mv	a0,s1
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	ee2080e7          	jalr	-286(ra) # 800038c4 <itrunc>
    ip->type = 0;
    800039ea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ee:	8526                	mv	a0,s1
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	cfc080e7          	jalr	-772(ra) # 800036ec <iupdate>
    ip->valid = 0;
    800039f8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039fc:	854a                	mv	a0,s2
    800039fe:	00001097          	auipc	ra,0x1
    80003a02:	ad8080e7          	jalr	-1320(ra) # 800044d6 <releasesleep>
    acquire(&itable.lock);
    80003a06:	0001c517          	auipc	a0,0x1c
    80003a0a:	dc250513          	addi	a0,a0,-574 # 8001f7c8 <itable>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	1d6080e7          	jalr	470(ra) # 80000be4 <acquire>
    80003a16:	b741                	j	80003996 <iput+0x26>

0000000080003a18 <iunlockput>:
{
    80003a18:	1101                	addi	sp,sp,-32
    80003a1a:	ec06                	sd	ra,24(sp)
    80003a1c:	e822                	sd	s0,16(sp)
    80003a1e:	e426                	sd	s1,8(sp)
    80003a20:	1000                	addi	s0,sp,32
    80003a22:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	e54080e7          	jalr	-428(ra) # 80003878 <iunlock>
  iput(ip);
    80003a2c:	8526                	mv	a0,s1
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	f42080e7          	jalr	-190(ra) # 80003970 <iput>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret

0000000080003a40 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a40:	1141                	addi	sp,sp,-16
    80003a42:	e422                	sd	s0,8(sp)
    80003a44:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a46:	411c                	lw	a5,0(a0)
    80003a48:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a4a:	415c                	lw	a5,4(a0)
    80003a4c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a4e:	04451783          	lh	a5,68(a0)
    80003a52:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a56:	04a51783          	lh	a5,74(a0)
    80003a5a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a5e:	04c56783          	lwu	a5,76(a0)
    80003a62:	e99c                	sd	a5,16(a1)
}
    80003a64:	6422                	ld	s0,8(sp)
    80003a66:	0141                	addi	sp,sp,16
    80003a68:	8082                	ret

0000000080003a6a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a6a:	457c                	lw	a5,76(a0)
    80003a6c:	0ed7e963          	bltu	a5,a3,80003b5e <readi+0xf4>
{
    80003a70:	7159                	addi	sp,sp,-112
    80003a72:	f486                	sd	ra,104(sp)
    80003a74:	f0a2                	sd	s0,96(sp)
    80003a76:	eca6                	sd	s1,88(sp)
    80003a78:	e8ca                	sd	s2,80(sp)
    80003a7a:	e4ce                	sd	s3,72(sp)
    80003a7c:	e0d2                	sd	s4,64(sp)
    80003a7e:	fc56                	sd	s5,56(sp)
    80003a80:	f85a                	sd	s6,48(sp)
    80003a82:	f45e                	sd	s7,40(sp)
    80003a84:	f062                	sd	s8,32(sp)
    80003a86:	ec66                	sd	s9,24(sp)
    80003a88:	e86a                	sd	s10,16(sp)
    80003a8a:	e46e                	sd	s11,8(sp)
    80003a8c:	1880                	addi	s0,sp,112
    80003a8e:	8baa                	mv	s7,a0
    80003a90:	8c2e                	mv	s8,a1
    80003a92:	8ab2                	mv	s5,a2
    80003a94:	84b6                	mv	s1,a3
    80003a96:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a98:	9f35                	addw	a4,a4,a3
    return 0;
    80003a9a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a9c:	0ad76063          	bltu	a4,a3,80003b3c <readi+0xd2>
  if(off + n > ip->size)
    80003aa0:	00e7f463          	bgeu	a5,a4,80003aa8 <readi+0x3e>
    n = ip->size - off;
    80003aa4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa8:	0a0b0963          	beqz	s6,80003b5a <readi+0xf0>
    80003aac:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aae:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ab2:	5cfd                	li	s9,-1
    80003ab4:	a82d                	j	80003aee <readi+0x84>
    80003ab6:	020a1d93          	slli	s11,s4,0x20
    80003aba:	020ddd93          	srli	s11,s11,0x20
    80003abe:	05890613          	addi	a2,s2,88
    80003ac2:	86ee                	mv	a3,s11
    80003ac4:	963a                	add	a2,a2,a4
    80003ac6:	85d6                	mv	a1,s5
    80003ac8:	8562                	mv	a0,s8
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	9c2080e7          	jalr	-1598(ra) # 8000248c <either_copyout>
    80003ad2:	05950d63          	beq	a0,s9,80003b2c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ad6:	854a                	mv	a0,s2
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	60c080e7          	jalr	1548(ra) # 800030e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae0:	013a09bb          	addw	s3,s4,s3
    80003ae4:	009a04bb          	addw	s1,s4,s1
    80003ae8:	9aee                	add	s5,s5,s11
    80003aea:	0569f763          	bgeu	s3,s6,80003b38 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aee:	000ba903          	lw	s2,0(s7)
    80003af2:	00a4d59b          	srliw	a1,s1,0xa
    80003af6:	855e                	mv	a0,s7
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	8b0080e7          	jalr	-1872(ra) # 800033a8 <bmap>
    80003b00:	0005059b          	sext.w	a1,a0
    80003b04:	854a                	mv	a0,s2
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	4ae080e7          	jalr	1198(ra) # 80002fb4 <bread>
    80003b0e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b10:	3ff4f713          	andi	a4,s1,1023
    80003b14:	40ed07bb          	subw	a5,s10,a4
    80003b18:	413b06bb          	subw	a3,s6,s3
    80003b1c:	8a3e                	mv	s4,a5
    80003b1e:	2781                	sext.w	a5,a5
    80003b20:	0006861b          	sext.w	a2,a3
    80003b24:	f8f679e3          	bgeu	a2,a5,80003ab6 <readi+0x4c>
    80003b28:	8a36                	mv	s4,a3
    80003b2a:	b771                	j	80003ab6 <readi+0x4c>
      brelse(bp);
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	5b6080e7          	jalr	1462(ra) # 800030e4 <brelse>
      tot = -1;
    80003b36:	59fd                	li	s3,-1
  }
  return tot;
    80003b38:	0009851b          	sext.w	a0,s3
}
    80003b3c:	70a6                	ld	ra,104(sp)
    80003b3e:	7406                	ld	s0,96(sp)
    80003b40:	64e6                	ld	s1,88(sp)
    80003b42:	6946                	ld	s2,80(sp)
    80003b44:	69a6                	ld	s3,72(sp)
    80003b46:	6a06                	ld	s4,64(sp)
    80003b48:	7ae2                	ld	s5,56(sp)
    80003b4a:	7b42                	ld	s6,48(sp)
    80003b4c:	7ba2                	ld	s7,40(sp)
    80003b4e:	7c02                	ld	s8,32(sp)
    80003b50:	6ce2                	ld	s9,24(sp)
    80003b52:	6d42                	ld	s10,16(sp)
    80003b54:	6da2                	ld	s11,8(sp)
    80003b56:	6165                	addi	sp,sp,112
    80003b58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5a:	89da                	mv	s3,s6
    80003b5c:	bff1                	j	80003b38 <readi+0xce>
    return 0;
    80003b5e:	4501                	li	a0,0
}
    80003b60:	8082                	ret

0000000080003b62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b62:	457c                	lw	a5,76(a0)
    80003b64:	10d7e863          	bltu	a5,a3,80003c74 <writei+0x112>
{
    80003b68:	7159                	addi	sp,sp,-112
    80003b6a:	f486                	sd	ra,104(sp)
    80003b6c:	f0a2                	sd	s0,96(sp)
    80003b6e:	eca6                	sd	s1,88(sp)
    80003b70:	e8ca                	sd	s2,80(sp)
    80003b72:	e4ce                	sd	s3,72(sp)
    80003b74:	e0d2                	sd	s4,64(sp)
    80003b76:	fc56                	sd	s5,56(sp)
    80003b78:	f85a                	sd	s6,48(sp)
    80003b7a:	f45e                	sd	s7,40(sp)
    80003b7c:	f062                	sd	s8,32(sp)
    80003b7e:	ec66                	sd	s9,24(sp)
    80003b80:	e86a                	sd	s10,16(sp)
    80003b82:	e46e                	sd	s11,8(sp)
    80003b84:	1880                	addi	s0,sp,112
    80003b86:	8b2a                	mv	s6,a0
    80003b88:	8c2e                	mv	s8,a1
    80003b8a:	8ab2                	mv	s5,a2
    80003b8c:	8936                	mv	s2,a3
    80003b8e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b90:	00e687bb          	addw	a5,a3,a4
    80003b94:	0ed7e263          	bltu	a5,a3,80003c78 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b98:	00043737          	lui	a4,0x43
    80003b9c:	0ef76063          	bltu	a4,a5,80003c7c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	0c0b8863          	beqz	s7,80003c70 <writei+0x10e>
    80003ba4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003baa:	5cfd                	li	s9,-1
    80003bac:	a091                	j	80003bf0 <writei+0x8e>
    80003bae:	02099d93          	slli	s11,s3,0x20
    80003bb2:	020ddd93          	srli	s11,s11,0x20
    80003bb6:	05848513          	addi	a0,s1,88
    80003bba:	86ee                	mv	a3,s11
    80003bbc:	8656                	mv	a2,s5
    80003bbe:	85e2                	mv	a1,s8
    80003bc0:	953a                	add	a0,a0,a4
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	920080e7          	jalr	-1760(ra) # 800024e2 <either_copyin>
    80003bca:	07950263          	beq	a0,s9,80003c2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bce:	8526                	mv	a0,s1
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	790080e7          	jalr	1936(ra) # 80004360 <log_write>
    brelse(bp);
    80003bd8:	8526                	mv	a0,s1
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	50a080e7          	jalr	1290(ra) # 800030e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be2:	01498a3b          	addw	s4,s3,s4
    80003be6:	0129893b          	addw	s2,s3,s2
    80003bea:	9aee                	add	s5,s5,s11
    80003bec:	057a7663          	bgeu	s4,s7,80003c38 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf0:	000b2483          	lw	s1,0(s6)
    80003bf4:	00a9559b          	srliw	a1,s2,0xa
    80003bf8:	855a                	mv	a0,s6
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	7ae080e7          	jalr	1966(ra) # 800033a8 <bmap>
    80003c02:	0005059b          	sext.w	a1,a0
    80003c06:	8526                	mv	a0,s1
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	3ac080e7          	jalr	940(ra) # 80002fb4 <bread>
    80003c10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c12:	3ff97713          	andi	a4,s2,1023
    80003c16:	40ed07bb          	subw	a5,s10,a4
    80003c1a:	414b86bb          	subw	a3,s7,s4
    80003c1e:	89be                	mv	s3,a5
    80003c20:	2781                	sext.w	a5,a5
    80003c22:	0006861b          	sext.w	a2,a3
    80003c26:	f8f674e3          	bgeu	a2,a5,80003bae <writei+0x4c>
    80003c2a:	89b6                	mv	s3,a3
    80003c2c:	b749                	j	80003bae <writei+0x4c>
      brelse(bp);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	4b4080e7          	jalr	1204(ra) # 800030e4 <brelse>
  }

  if(off > ip->size)
    80003c38:	04cb2783          	lw	a5,76(s6)
    80003c3c:	0127f463          	bgeu	a5,s2,80003c44 <writei+0xe2>
    ip->size = off;
    80003c40:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c44:	855a                	mv	a0,s6
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	aa6080e7          	jalr	-1370(ra) # 800036ec <iupdate>

  return tot;
    80003c4e:	000a051b          	sext.w	a0,s4
}
    80003c52:	70a6                	ld	ra,104(sp)
    80003c54:	7406                	ld	s0,96(sp)
    80003c56:	64e6                	ld	s1,88(sp)
    80003c58:	6946                	ld	s2,80(sp)
    80003c5a:	69a6                	ld	s3,72(sp)
    80003c5c:	6a06                	ld	s4,64(sp)
    80003c5e:	7ae2                	ld	s5,56(sp)
    80003c60:	7b42                	ld	s6,48(sp)
    80003c62:	7ba2                	ld	s7,40(sp)
    80003c64:	7c02                	ld	s8,32(sp)
    80003c66:	6ce2                	ld	s9,24(sp)
    80003c68:	6d42                	ld	s10,16(sp)
    80003c6a:	6da2                	ld	s11,8(sp)
    80003c6c:	6165                	addi	sp,sp,112
    80003c6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c70:	8a5e                	mv	s4,s7
    80003c72:	bfc9                	j	80003c44 <writei+0xe2>
    return -1;
    80003c74:	557d                	li	a0,-1
}
    80003c76:	8082                	ret
    return -1;
    80003c78:	557d                	li	a0,-1
    80003c7a:	bfe1                	j	80003c52 <writei+0xf0>
    return -1;
    80003c7c:	557d                	li	a0,-1
    80003c7e:	bfd1                	j	80003c52 <writei+0xf0>

0000000080003c80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c80:	1141                	addi	sp,sp,-16
    80003c82:	e406                	sd	ra,8(sp)
    80003c84:	e022                	sd	s0,0(sp)
    80003c86:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c88:	4639                	li	a2,14
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	12e080e7          	jalr	302(ra) # 80000db8 <strncmp>
}
    80003c92:	60a2                	ld	ra,8(sp)
    80003c94:	6402                	ld	s0,0(sp)
    80003c96:	0141                	addi	sp,sp,16
    80003c98:	8082                	ret

0000000080003c9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c9a:	7139                	addi	sp,sp,-64
    80003c9c:	fc06                	sd	ra,56(sp)
    80003c9e:	f822                	sd	s0,48(sp)
    80003ca0:	f426                	sd	s1,40(sp)
    80003ca2:	f04a                	sd	s2,32(sp)
    80003ca4:	ec4e                	sd	s3,24(sp)
    80003ca6:	e852                	sd	s4,16(sp)
    80003ca8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003caa:	04451703          	lh	a4,68(a0)
    80003cae:	4785                	li	a5,1
    80003cb0:	00f71a63          	bne	a4,a5,80003cc4 <dirlookup+0x2a>
    80003cb4:	892a                	mv	s2,a0
    80003cb6:	89ae                	mv	s3,a1
    80003cb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cba:	457c                	lw	a5,76(a0)
    80003cbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cbe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc0:	e79d                	bnez	a5,80003cee <dirlookup+0x54>
    80003cc2:	a8a5                	j	80003d3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cc4:	00005517          	auipc	a0,0x5
    80003cc8:	95450513          	addi	a0,a0,-1708 # 80008618 <syscalls+0x1b8>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	872080e7          	jalr	-1934(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cd4:	00005517          	auipc	a0,0x5
    80003cd8:	95c50513          	addi	a0,a0,-1700 # 80008630 <syscalls+0x1d0>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	862080e7          	jalr	-1950(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce4:	24c1                	addiw	s1,s1,16
    80003ce6:	04c92783          	lw	a5,76(s2)
    80003cea:	04f4f763          	bgeu	s1,a5,80003d38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cee:	4741                	li	a4,16
    80003cf0:	86a6                	mv	a3,s1
    80003cf2:	fc040613          	addi	a2,s0,-64
    80003cf6:	4581                	li	a1,0
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	d70080e7          	jalr	-656(ra) # 80003a6a <readi>
    80003d02:	47c1                	li	a5,16
    80003d04:	fcf518e3          	bne	a0,a5,80003cd4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d08:	fc045783          	lhu	a5,-64(s0)
    80003d0c:	dfe1                	beqz	a5,80003ce4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d0e:	fc240593          	addi	a1,s0,-62
    80003d12:	854e                	mv	a0,s3
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	f6c080e7          	jalr	-148(ra) # 80003c80 <namecmp>
    80003d1c:	f561                	bnez	a0,80003ce4 <dirlookup+0x4a>
      if(poff)
    80003d1e:	000a0463          	beqz	s4,80003d26 <dirlookup+0x8c>
        *poff = off;
    80003d22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d26:	fc045583          	lhu	a1,-64(s0)
    80003d2a:	00092503          	lw	a0,0(s2)
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	754080e7          	jalr	1876(ra) # 80003482 <iget>
    80003d36:	a011                	j	80003d3a <dirlookup+0xa0>
  return 0;
    80003d38:	4501                	li	a0,0
}
    80003d3a:	70e2                	ld	ra,56(sp)
    80003d3c:	7442                	ld	s0,48(sp)
    80003d3e:	74a2                	ld	s1,40(sp)
    80003d40:	7902                	ld	s2,32(sp)
    80003d42:	69e2                	ld	s3,24(sp)
    80003d44:	6a42                	ld	s4,16(sp)
    80003d46:	6121                	addi	sp,sp,64
    80003d48:	8082                	ret

0000000080003d4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d4a:	711d                	addi	sp,sp,-96
    80003d4c:	ec86                	sd	ra,88(sp)
    80003d4e:	e8a2                	sd	s0,80(sp)
    80003d50:	e4a6                	sd	s1,72(sp)
    80003d52:	e0ca                	sd	s2,64(sp)
    80003d54:	fc4e                	sd	s3,56(sp)
    80003d56:	f852                	sd	s4,48(sp)
    80003d58:	f456                	sd	s5,40(sp)
    80003d5a:	f05a                	sd	s6,32(sp)
    80003d5c:	ec5e                	sd	s7,24(sp)
    80003d5e:	e862                	sd	s8,16(sp)
    80003d60:	e466                	sd	s9,8(sp)
    80003d62:	1080                	addi	s0,sp,96
    80003d64:	84aa                	mv	s1,a0
    80003d66:	8b2e                	mv	s6,a1
    80003d68:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d6a:	00054703          	lbu	a4,0(a0)
    80003d6e:	02f00793          	li	a5,47
    80003d72:	02f70363          	beq	a4,a5,80003d98 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d76:	ffffe097          	auipc	ra,0xffffe
    80003d7a:	c3a080e7          	jalr	-966(ra) # 800019b0 <myproc>
    80003d7e:	15053503          	ld	a0,336(a0)
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	9f6080e7          	jalr	-1546(ra) # 80003778 <idup>
    80003d8a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d8c:	02f00913          	li	s2,47
  len = path - s;
    80003d90:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d92:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d94:	4c05                	li	s8,1
    80003d96:	a865                	j	80003e4e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d98:	4585                	li	a1,1
    80003d9a:	4505                	li	a0,1
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	6e6080e7          	jalr	1766(ra) # 80003482 <iget>
    80003da4:	89aa                	mv	s3,a0
    80003da6:	b7dd                	j	80003d8c <namex+0x42>
      iunlockput(ip);
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	c6e080e7          	jalr	-914(ra) # 80003a18 <iunlockput>
      return 0;
    80003db2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003db4:	854e                	mv	a0,s3
    80003db6:	60e6                	ld	ra,88(sp)
    80003db8:	6446                	ld	s0,80(sp)
    80003dba:	64a6                	ld	s1,72(sp)
    80003dbc:	6906                	ld	s2,64(sp)
    80003dbe:	79e2                	ld	s3,56(sp)
    80003dc0:	7a42                	ld	s4,48(sp)
    80003dc2:	7aa2                	ld	s5,40(sp)
    80003dc4:	7b02                	ld	s6,32(sp)
    80003dc6:	6be2                	ld	s7,24(sp)
    80003dc8:	6c42                	ld	s8,16(sp)
    80003dca:	6ca2                	ld	s9,8(sp)
    80003dcc:	6125                	addi	sp,sp,96
    80003dce:	8082                	ret
      iunlock(ip);
    80003dd0:	854e                	mv	a0,s3
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	aa6080e7          	jalr	-1370(ra) # 80003878 <iunlock>
      return ip;
    80003dda:	bfe9                	j	80003db4 <namex+0x6a>
      iunlockput(ip);
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	c3a080e7          	jalr	-966(ra) # 80003a18 <iunlockput>
      return 0;
    80003de6:	89d2                	mv	s3,s4
    80003de8:	b7f1                	j	80003db4 <namex+0x6a>
  len = path - s;
    80003dea:	40b48633          	sub	a2,s1,a1
    80003dee:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003df2:	094cd463          	bge	s9,s4,80003e7a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003df6:	4639                	li	a2,14
    80003df8:	8556                	mv	a0,s5
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	f46080e7          	jalr	-186(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	01279763          	bne	a5,s2,80003e14 <namex+0xca>
    path++;
    80003e0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	ff278de3          	beq	a5,s2,80003e0a <namex+0xc0>
    ilock(ip);
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	9a0080e7          	jalr	-1632(ra) # 800037b6 <ilock>
    if(ip->type != T_DIR){
    80003e1e:	04499783          	lh	a5,68(s3)
    80003e22:	f98793e3          	bne	a5,s8,80003da8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e26:	000b0563          	beqz	s6,80003e30 <namex+0xe6>
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	d3cd                	beqz	a5,80003dd0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e30:	865e                	mv	a2,s7
    80003e32:	85d6                	mv	a1,s5
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	e64080e7          	jalr	-412(ra) # 80003c9a <dirlookup>
    80003e3e:	8a2a                	mv	s4,a0
    80003e40:	dd51                	beqz	a0,80003ddc <namex+0x92>
    iunlockput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	bd4080e7          	jalr	-1068(ra) # 80003a18 <iunlockput>
    ip = next;
    80003e4c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	05279763          	bne	a5,s2,80003ea0 <namex+0x156>
    path++;
    80003e56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	ff278de3          	beq	a5,s2,80003e56 <namex+0x10c>
  if(*path == 0)
    80003e60:	c79d                	beqz	a5,80003e8e <namex+0x144>
    path++;
    80003e62:	85a6                	mv	a1,s1
  len = path - s;
    80003e64:	8a5e                	mv	s4,s7
    80003e66:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e68:	01278963          	beq	a5,s2,80003e7a <namex+0x130>
    80003e6c:	dfbd                	beqz	a5,80003dea <namex+0xa0>
    path++;
    80003e6e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	ff279ce3          	bne	a5,s2,80003e6c <namex+0x122>
    80003e78:	bf8d                	j	80003dea <namex+0xa0>
    memmove(name, s, len);
    80003e7a:	2601                	sext.w	a2,a2
    80003e7c:	8556                	mv	a0,s5
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	ec2080e7          	jalr	-318(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e86:	9a56                	add	s4,s4,s5
    80003e88:	000a0023          	sb	zero,0(s4)
    80003e8c:	bf9d                	j	80003e02 <namex+0xb8>
  if(nameiparent){
    80003e8e:	f20b03e3          	beqz	s6,80003db4 <namex+0x6a>
    iput(ip);
    80003e92:	854e                	mv	a0,s3
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	adc080e7          	jalr	-1316(ra) # 80003970 <iput>
    return 0;
    80003e9c:	4981                	li	s3,0
    80003e9e:	bf19                	j	80003db4 <namex+0x6a>
  if(*path == 0)
    80003ea0:	d7fd                	beqz	a5,80003e8e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ea2:	0004c783          	lbu	a5,0(s1)
    80003ea6:	85a6                	mv	a1,s1
    80003ea8:	b7d1                	j	80003e6c <namex+0x122>

0000000080003eaa <dirlink>:
{
    80003eaa:	7139                	addi	sp,sp,-64
    80003eac:	fc06                	sd	ra,56(sp)
    80003eae:	f822                	sd	s0,48(sp)
    80003eb0:	f426                	sd	s1,40(sp)
    80003eb2:	f04a                	sd	s2,32(sp)
    80003eb4:	ec4e                	sd	s3,24(sp)
    80003eb6:	e852                	sd	s4,16(sp)
    80003eb8:	0080                	addi	s0,sp,64
    80003eba:	892a                	mv	s2,a0
    80003ebc:	8a2e                	mv	s4,a1
    80003ebe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ec0:	4601                	li	a2,0
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	dd8080e7          	jalr	-552(ra) # 80003c9a <dirlookup>
    80003eca:	e93d                	bnez	a0,80003f40 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ecc:	04c92483          	lw	s1,76(s2)
    80003ed0:	c49d                	beqz	s1,80003efe <dirlink+0x54>
    80003ed2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed4:	4741                	li	a4,16
    80003ed6:	86a6                	mv	a3,s1
    80003ed8:	fc040613          	addi	a2,s0,-64
    80003edc:	4581                	li	a1,0
    80003ede:	854a                	mv	a0,s2
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	b8a080e7          	jalr	-1142(ra) # 80003a6a <readi>
    80003ee8:	47c1                	li	a5,16
    80003eea:	06f51163          	bne	a0,a5,80003f4c <dirlink+0xa2>
    if(de.inum == 0)
    80003eee:	fc045783          	lhu	a5,-64(s0)
    80003ef2:	c791                	beqz	a5,80003efe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	24c1                	addiw	s1,s1,16
    80003ef6:	04c92783          	lw	a5,76(s2)
    80003efa:	fcf4ede3          	bltu	s1,a5,80003ed4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003efe:	4639                	li	a2,14
    80003f00:	85d2                	mv	a1,s4
    80003f02:	fc240513          	addi	a0,s0,-62
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	eee080e7          	jalr	-274(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003f0e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f12:	4741                	li	a4,16
    80003f14:	86a6                	mv	a3,s1
    80003f16:	fc040613          	addi	a2,s0,-64
    80003f1a:	4581                	li	a1,0
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	c44080e7          	jalr	-956(ra) # 80003b62 <writei>
    80003f26:	872a                	mv	a4,a0
    80003f28:	47c1                	li	a5,16
  return 0;
    80003f2a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2c:	02f71863          	bne	a4,a5,80003f5c <dirlink+0xb2>
}
    80003f30:	70e2                	ld	ra,56(sp)
    80003f32:	7442                	ld	s0,48(sp)
    80003f34:	74a2                	ld	s1,40(sp)
    80003f36:	7902                	ld	s2,32(sp)
    80003f38:	69e2                	ld	s3,24(sp)
    80003f3a:	6a42                	ld	s4,16(sp)
    80003f3c:	6121                	addi	sp,sp,64
    80003f3e:	8082                	ret
    iput(ip);
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	a30080e7          	jalr	-1488(ra) # 80003970 <iput>
    return -1;
    80003f48:	557d                	li	a0,-1
    80003f4a:	b7dd                	j	80003f30 <dirlink+0x86>
      panic("dirlink read");
    80003f4c:	00004517          	auipc	a0,0x4
    80003f50:	6f450513          	addi	a0,a0,1780 # 80008640 <syscalls+0x1e0>
    80003f54:	ffffc097          	auipc	ra,0xffffc
    80003f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>
    panic("dirlink");
    80003f5c:	00004517          	auipc	a0,0x4
    80003f60:	7f450513          	addi	a0,a0,2036 # 80008750 <syscalls+0x2f0>
    80003f64:	ffffc097          	auipc	ra,0xffffc
    80003f68:	5da080e7          	jalr	1498(ra) # 8000053e <panic>

0000000080003f6c <namei>:

struct inode*
namei(char *path)
{
    80003f6c:	1101                	addi	sp,sp,-32
    80003f6e:	ec06                	sd	ra,24(sp)
    80003f70:	e822                	sd	s0,16(sp)
    80003f72:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f74:	fe040613          	addi	a2,s0,-32
    80003f78:	4581                	li	a1,0
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	dd0080e7          	jalr	-560(ra) # 80003d4a <namex>
}
    80003f82:	60e2                	ld	ra,24(sp)
    80003f84:	6442                	ld	s0,16(sp)
    80003f86:	6105                	addi	sp,sp,32
    80003f88:	8082                	ret

0000000080003f8a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f8a:	1141                	addi	sp,sp,-16
    80003f8c:	e406                	sd	ra,8(sp)
    80003f8e:	e022                	sd	s0,0(sp)
    80003f90:	0800                	addi	s0,sp,16
    80003f92:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f94:	4585                	li	a1,1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	db4080e7          	jalr	-588(ra) # 80003d4a <namex>
}
    80003f9e:	60a2                	ld	ra,8(sp)
    80003fa0:	6402                	ld	s0,0(sp)
    80003fa2:	0141                	addi	sp,sp,16
    80003fa4:	8082                	ret

0000000080003fa6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fa6:	1101                	addi	sp,sp,-32
    80003fa8:	ec06                	sd	ra,24(sp)
    80003faa:	e822                	sd	s0,16(sp)
    80003fac:	e426                	sd	s1,8(sp)
    80003fae:	e04a                	sd	s2,0(sp)
    80003fb0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fb2:	0001d917          	auipc	s2,0x1d
    80003fb6:	2be90913          	addi	s2,s2,702 # 80021270 <log>
    80003fba:	01892583          	lw	a1,24(s2)
    80003fbe:	02892503          	lw	a0,40(s2)
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	ff2080e7          	jalr	-14(ra) # 80002fb4 <bread>
    80003fca:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fcc:	02c92683          	lw	a3,44(s2)
    80003fd0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fd2:	02d05763          	blez	a3,80004000 <write_head+0x5a>
    80003fd6:	0001d797          	auipc	a5,0x1d
    80003fda:	2ca78793          	addi	a5,a5,714 # 800212a0 <log+0x30>
    80003fde:	05c50713          	addi	a4,a0,92
    80003fe2:	36fd                	addiw	a3,a3,-1
    80003fe4:	1682                	slli	a3,a3,0x20
    80003fe6:	9281                	srli	a3,a3,0x20
    80003fe8:	068a                	slli	a3,a3,0x2
    80003fea:	0001d617          	auipc	a2,0x1d
    80003fee:	2ba60613          	addi	a2,a2,698 # 800212a4 <log+0x34>
    80003ff2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ff4:	4390                	lw	a2,0(a5)
    80003ff6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff8:	0791                	addi	a5,a5,4
    80003ffa:	0711                	addi	a4,a4,4
    80003ffc:	fed79ce3          	bne	a5,a3,80003ff4 <write_head+0x4e>
  }
  bwrite(buf);
    80004000:	8526                	mv	a0,s1
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	0a4080e7          	jalr	164(ra) # 800030a6 <bwrite>
  brelse(buf);
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	0d8080e7          	jalr	216(ra) # 800030e4 <brelse>
}
    80004014:	60e2                	ld	ra,24(sp)
    80004016:	6442                	ld	s0,16(sp)
    80004018:	64a2                	ld	s1,8(sp)
    8000401a:	6902                	ld	s2,0(sp)
    8000401c:	6105                	addi	sp,sp,32
    8000401e:	8082                	ret

0000000080004020 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004020:	0001d797          	auipc	a5,0x1d
    80004024:	27c7a783          	lw	a5,636(a5) # 8002129c <log+0x2c>
    80004028:	0af05d63          	blez	a5,800040e2 <install_trans+0xc2>
{
    8000402c:	7139                	addi	sp,sp,-64
    8000402e:	fc06                	sd	ra,56(sp)
    80004030:	f822                	sd	s0,48(sp)
    80004032:	f426                	sd	s1,40(sp)
    80004034:	f04a                	sd	s2,32(sp)
    80004036:	ec4e                	sd	s3,24(sp)
    80004038:	e852                	sd	s4,16(sp)
    8000403a:	e456                	sd	s5,8(sp)
    8000403c:	e05a                	sd	s6,0(sp)
    8000403e:	0080                	addi	s0,sp,64
    80004040:	8b2a                	mv	s6,a0
    80004042:	0001da97          	auipc	s5,0x1d
    80004046:	25ea8a93          	addi	s5,s5,606 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000404c:	0001d997          	auipc	s3,0x1d
    80004050:	22498993          	addi	s3,s3,548 # 80021270 <log>
    80004054:	a035                	j	80004080 <install_trans+0x60>
      bunpin(dbuf);
    80004056:	8526                	mv	a0,s1
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	166080e7          	jalr	358(ra) # 800031be <bunpin>
    brelse(lbuf);
    80004060:	854a                	mv	a0,s2
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	082080e7          	jalr	130(ra) # 800030e4 <brelse>
    brelse(dbuf);
    8000406a:	8526                	mv	a0,s1
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	078080e7          	jalr	120(ra) # 800030e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004074:	2a05                	addiw	s4,s4,1
    80004076:	0a91                	addi	s5,s5,4
    80004078:	02c9a783          	lw	a5,44(s3)
    8000407c:	04fa5963          	bge	s4,a5,800040ce <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004080:	0189a583          	lw	a1,24(s3)
    80004084:	014585bb          	addw	a1,a1,s4
    80004088:	2585                	addiw	a1,a1,1
    8000408a:	0289a503          	lw	a0,40(s3)
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	f26080e7          	jalr	-218(ra) # 80002fb4 <bread>
    80004096:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004098:	000aa583          	lw	a1,0(s5)
    8000409c:	0289a503          	lw	a0,40(s3)
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	f14080e7          	jalr	-236(ra) # 80002fb4 <bread>
    800040a8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040aa:	40000613          	li	a2,1024
    800040ae:	05890593          	addi	a1,s2,88
    800040b2:	05850513          	addi	a0,a0,88
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	c8a080e7          	jalr	-886(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040be:	8526                	mv	a0,s1
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	fe6080e7          	jalr	-26(ra) # 800030a6 <bwrite>
    if(recovering == 0)
    800040c8:	f80b1ce3          	bnez	s6,80004060 <install_trans+0x40>
    800040cc:	b769                	j	80004056 <install_trans+0x36>
}
    800040ce:	70e2                	ld	ra,56(sp)
    800040d0:	7442                	ld	s0,48(sp)
    800040d2:	74a2                	ld	s1,40(sp)
    800040d4:	7902                	ld	s2,32(sp)
    800040d6:	69e2                	ld	s3,24(sp)
    800040d8:	6a42                	ld	s4,16(sp)
    800040da:	6aa2                	ld	s5,8(sp)
    800040dc:	6b02                	ld	s6,0(sp)
    800040de:	6121                	addi	sp,sp,64
    800040e0:	8082                	ret
    800040e2:	8082                	ret

00000000800040e4 <initlog>:
{
    800040e4:	7179                	addi	sp,sp,-48
    800040e6:	f406                	sd	ra,40(sp)
    800040e8:	f022                	sd	s0,32(sp)
    800040ea:	ec26                	sd	s1,24(sp)
    800040ec:	e84a                	sd	s2,16(sp)
    800040ee:	e44e                	sd	s3,8(sp)
    800040f0:	1800                	addi	s0,sp,48
    800040f2:	892a                	mv	s2,a0
    800040f4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040f6:	0001d497          	auipc	s1,0x1d
    800040fa:	17a48493          	addi	s1,s1,378 # 80021270 <log>
    800040fe:	00004597          	auipc	a1,0x4
    80004102:	55258593          	addi	a1,a1,1362 # 80008650 <syscalls+0x1f0>
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	a4c080e7          	jalr	-1460(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004110:	0149a583          	lw	a1,20(s3)
    80004114:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004116:	0109a783          	lw	a5,16(s3)
    8000411a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000411c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004120:	854a                	mv	a0,s2
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	e92080e7          	jalr	-366(ra) # 80002fb4 <bread>
  log.lh.n = lh->n;
    8000412a:	4d3c                	lw	a5,88(a0)
    8000412c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000412e:	02f05563          	blez	a5,80004158 <initlog+0x74>
    80004132:	05c50713          	addi	a4,a0,92
    80004136:	0001d697          	auipc	a3,0x1d
    8000413a:	16a68693          	addi	a3,a3,362 # 800212a0 <log+0x30>
    8000413e:	37fd                	addiw	a5,a5,-1
    80004140:	1782                	slli	a5,a5,0x20
    80004142:	9381                	srli	a5,a5,0x20
    80004144:	078a                	slli	a5,a5,0x2
    80004146:	06050613          	addi	a2,a0,96
    8000414a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000414c:	4310                	lw	a2,0(a4)
    8000414e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004150:	0711                	addi	a4,a4,4
    80004152:	0691                	addi	a3,a3,4
    80004154:	fef71ce3          	bne	a4,a5,8000414c <initlog+0x68>
  brelse(buf);
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	f8c080e7          	jalr	-116(ra) # 800030e4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004160:	4505                	li	a0,1
    80004162:	00000097          	auipc	ra,0x0
    80004166:	ebe080e7          	jalr	-322(ra) # 80004020 <install_trans>
  log.lh.n = 0;
    8000416a:	0001d797          	auipc	a5,0x1d
    8000416e:	1207a923          	sw	zero,306(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004172:	00000097          	auipc	ra,0x0
    80004176:	e34080e7          	jalr	-460(ra) # 80003fa6 <write_head>
}
    8000417a:	70a2                	ld	ra,40(sp)
    8000417c:	7402                	ld	s0,32(sp)
    8000417e:	64e2                	ld	s1,24(sp)
    80004180:	6942                	ld	s2,16(sp)
    80004182:	69a2                	ld	s3,8(sp)
    80004184:	6145                	addi	sp,sp,48
    80004186:	8082                	ret

0000000080004188 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004188:	1101                	addi	sp,sp,-32
    8000418a:	ec06                	sd	ra,24(sp)
    8000418c:	e822                	sd	s0,16(sp)
    8000418e:	e426                	sd	s1,8(sp)
    80004190:	e04a                	sd	s2,0(sp)
    80004192:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004194:	0001d517          	auipc	a0,0x1d
    80004198:	0dc50513          	addi	a0,a0,220 # 80021270 <log>
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	a48080e7          	jalr	-1464(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800041a4:	0001d497          	auipc	s1,0x1d
    800041a8:	0cc48493          	addi	s1,s1,204 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ac:	4979                	li	s2,30
    800041ae:	a039                	j	800041bc <begin_op+0x34>
      sleep(&log, &log.lock);
    800041b0:	85a6                	mv	a1,s1
    800041b2:	8526                	mv	a0,s1
    800041b4:	ffffe097          	auipc	ra,0xffffe
    800041b8:	f34080e7          	jalr	-204(ra) # 800020e8 <sleep>
    if(log.committing){
    800041bc:	50dc                	lw	a5,36(s1)
    800041be:	fbed                	bnez	a5,800041b0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c0:	509c                	lw	a5,32(s1)
    800041c2:	0017871b          	addiw	a4,a5,1
    800041c6:	0007069b          	sext.w	a3,a4
    800041ca:	0027179b          	slliw	a5,a4,0x2
    800041ce:	9fb9                	addw	a5,a5,a4
    800041d0:	0017979b          	slliw	a5,a5,0x1
    800041d4:	54d8                	lw	a4,44(s1)
    800041d6:	9fb9                	addw	a5,a5,a4
    800041d8:	00f95963          	bge	s2,a5,800041ea <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041dc:	85a6                	mv	a1,s1
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	f08080e7          	jalr	-248(ra) # 800020e8 <sleep>
    800041e8:	bfd1                	j	800041bc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041ea:	0001d517          	auipc	a0,0x1d
    800041ee:	08650513          	addi	a0,a0,134 # 80021270 <log>
    800041f2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	aa4080e7          	jalr	-1372(ra) # 80000c98 <release>
      break;
    }
  }
}
    800041fc:	60e2                	ld	ra,24(sp)
    800041fe:	6442                	ld	s0,16(sp)
    80004200:	64a2                	ld	s1,8(sp)
    80004202:	6902                	ld	s2,0(sp)
    80004204:	6105                	addi	sp,sp,32
    80004206:	8082                	ret

0000000080004208 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004208:	7139                	addi	sp,sp,-64
    8000420a:	fc06                	sd	ra,56(sp)
    8000420c:	f822                	sd	s0,48(sp)
    8000420e:	f426                	sd	s1,40(sp)
    80004210:	f04a                	sd	s2,32(sp)
    80004212:	ec4e                	sd	s3,24(sp)
    80004214:	e852                	sd	s4,16(sp)
    80004216:	e456                	sd	s5,8(sp)
    80004218:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000421a:	0001d497          	auipc	s1,0x1d
    8000421e:	05648493          	addi	s1,s1,86 # 80021270 <log>
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	9c0080e7          	jalr	-1600(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000422c:	509c                	lw	a5,32(s1)
    8000422e:	37fd                	addiw	a5,a5,-1
    80004230:	0007891b          	sext.w	s2,a5
    80004234:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004236:	50dc                	lw	a5,36(s1)
    80004238:	efb9                	bnez	a5,80004296 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000423a:	06091663          	bnez	s2,800042a6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000423e:	0001d497          	auipc	s1,0x1d
    80004242:	03248493          	addi	s1,s1,50 # 80021270 <log>
    80004246:	4785                	li	a5,1
    80004248:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	a4c080e7          	jalr	-1460(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004254:	54dc                	lw	a5,44(s1)
    80004256:	06f04763          	bgtz	a5,800042c4 <end_op+0xbc>
    acquire(&log.lock);
    8000425a:	0001d497          	auipc	s1,0x1d
    8000425e:	01648493          	addi	s1,s1,22 # 80021270 <log>
    80004262:	8526                	mv	a0,s1
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	980080e7          	jalr	-1664(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000426c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004270:	8526                	mv	a0,s1
    80004272:	ffffe097          	auipc	ra,0xffffe
    80004276:	002080e7          	jalr	2(ra) # 80002274 <wakeup>
    release(&log.lock);
    8000427a:	8526                	mv	a0,s1
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	a1c080e7          	jalr	-1508(ra) # 80000c98 <release>
}
    80004284:	70e2                	ld	ra,56(sp)
    80004286:	7442                	ld	s0,48(sp)
    80004288:	74a2                	ld	s1,40(sp)
    8000428a:	7902                	ld	s2,32(sp)
    8000428c:	69e2                	ld	s3,24(sp)
    8000428e:	6a42                	ld	s4,16(sp)
    80004290:	6aa2                	ld	s5,8(sp)
    80004292:	6121                	addi	sp,sp,64
    80004294:	8082                	ret
    panic("log.committing");
    80004296:	00004517          	auipc	a0,0x4
    8000429a:	3c250513          	addi	a0,a0,962 # 80008658 <syscalls+0x1f8>
    8000429e:	ffffc097          	auipc	ra,0xffffc
    800042a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    wakeup(&log);
    800042a6:	0001d497          	auipc	s1,0x1d
    800042aa:	fca48493          	addi	s1,s1,-54 # 80021270 <log>
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffe097          	auipc	ra,0xffffe
    800042b4:	fc4080e7          	jalr	-60(ra) # 80002274 <wakeup>
  release(&log.lock);
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	9de080e7          	jalr	-1570(ra) # 80000c98 <release>
  if(do_commit){
    800042c2:	b7c9                	j	80004284 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c4:	0001da97          	auipc	s5,0x1d
    800042c8:	fdca8a93          	addi	s5,s5,-36 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042cc:	0001da17          	auipc	s4,0x1d
    800042d0:	fa4a0a13          	addi	s4,s4,-92 # 80021270 <log>
    800042d4:	018a2583          	lw	a1,24(s4)
    800042d8:	012585bb          	addw	a1,a1,s2
    800042dc:	2585                	addiw	a1,a1,1
    800042de:	028a2503          	lw	a0,40(s4)
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	cd2080e7          	jalr	-814(ra) # 80002fb4 <bread>
    800042ea:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ec:	000aa583          	lw	a1,0(s5)
    800042f0:	028a2503          	lw	a0,40(s4)
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	cc0080e7          	jalr	-832(ra) # 80002fb4 <bread>
    800042fc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042fe:	40000613          	li	a2,1024
    80004302:	05850593          	addi	a1,a0,88
    80004306:	05848513          	addi	a0,s1,88
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	a36080e7          	jalr	-1482(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004312:	8526                	mv	a0,s1
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	d92080e7          	jalr	-622(ra) # 800030a6 <bwrite>
    brelse(from);
    8000431c:	854e                	mv	a0,s3
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	dc6080e7          	jalr	-570(ra) # 800030e4 <brelse>
    brelse(to);
    80004326:	8526                	mv	a0,s1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	dbc080e7          	jalr	-580(ra) # 800030e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004330:	2905                	addiw	s2,s2,1
    80004332:	0a91                	addi	s5,s5,4
    80004334:	02ca2783          	lw	a5,44(s4)
    80004338:	f8f94ee3          	blt	s2,a5,800042d4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	c6a080e7          	jalr	-918(ra) # 80003fa6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004344:	4501                	li	a0,0
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	cda080e7          	jalr	-806(ra) # 80004020 <install_trans>
    log.lh.n = 0;
    8000434e:	0001d797          	auipc	a5,0x1d
    80004352:	f407a723          	sw	zero,-178(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	c50080e7          	jalr	-944(ra) # 80003fa6 <write_head>
    8000435e:	bdf5                	j	8000425a <end_op+0x52>

0000000080004360 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004360:	1101                	addi	sp,sp,-32
    80004362:	ec06                	sd	ra,24(sp)
    80004364:	e822                	sd	s0,16(sp)
    80004366:	e426                	sd	s1,8(sp)
    80004368:	e04a                	sd	s2,0(sp)
    8000436a:	1000                	addi	s0,sp,32
    8000436c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000436e:	0001d917          	auipc	s2,0x1d
    80004372:	f0290913          	addi	s2,s2,-254 # 80021270 <log>
    80004376:	854a                	mv	a0,s2
    80004378:	ffffd097          	auipc	ra,0xffffd
    8000437c:	86c080e7          	jalr	-1940(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004380:	02c92603          	lw	a2,44(s2)
    80004384:	47f5                	li	a5,29
    80004386:	06c7c563          	blt	a5,a2,800043f0 <log_write+0x90>
    8000438a:	0001d797          	auipc	a5,0x1d
    8000438e:	f027a783          	lw	a5,-254(a5) # 8002128c <log+0x1c>
    80004392:	37fd                	addiw	a5,a5,-1
    80004394:	04f65e63          	bge	a2,a5,800043f0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004398:	0001d797          	auipc	a5,0x1d
    8000439c:	ef87a783          	lw	a5,-264(a5) # 80021290 <log+0x20>
    800043a0:	06f05063          	blez	a5,80004400 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043a4:	4781                	li	a5,0
    800043a6:	06c05563          	blez	a2,80004410 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043aa:	44cc                	lw	a1,12(s1)
    800043ac:	0001d717          	auipc	a4,0x1d
    800043b0:	ef470713          	addi	a4,a4,-268 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043b4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b6:	4314                	lw	a3,0(a4)
    800043b8:	04b68c63          	beq	a3,a1,80004410 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043bc:	2785                	addiw	a5,a5,1
    800043be:	0711                	addi	a4,a4,4
    800043c0:	fef61be3          	bne	a2,a5,800043b6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043c4:	0621                	addi	a2,a2,8
    800043c6:	060a                	slli	a2,a2,0x2
    800043c8:	0001d797          	auipc	a5,0x1d
    800043cc:	ea878793          	addi	a5,a5,-344 # 80021270 <log>
    800043d0:	963e                	add	a2,a2,a5
    800043d2:	44dc                	lw	a5,12(s1)
    800043d4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043d6:	8526                	mv	a0,s1
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	daa080e7          	jalr	-598(ra) # 80003182 <bpin>
    log.lh.n++;
    800043e0:	0001d717          	auipc	a4,0x1d
    800043e4:	e9070713          	addi	a4,a4,-368 # 80021270 <log>
    800043e8:	575c                	lw	a5,44(a4)
    800043ea:	2785                	addiw	a5,a5,1
    800043ec:	d75c                	sw	a5,44(a4)
    800043ee:	a835                	j	8000442a <log_write+0xca>
    panic("too big a transaction");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	27850513          	addi	a0,a0,632 # 80008668 <syscalls+0x208>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004400:	00004517          	auipc	a0,0x4
    80004404:	28050513          	addi	a0,a0,640 # 80008680 <syscalls+0x220>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	136080e7          	jalr	310(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004410:	00878713          	addi	a4,a5,8
    80004414:	00271693          	slli	a3,a4,0x2
    80004418:	0001d717          	auipc	a4,0x1d
    8000441c:	e5870713          	addi	a4,a4,-424 # 80021270 <log>
    80004420:	9736                	add	a4,a4,a3
    80004422:	44d4                	lw	a3,12(s1)
    80004424:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004426:	faf608e3          	beq	a2,a5,800043d6 <log_write+0x76>
  }
  release(&log.lock);
    8000442a:	0001d517          	auipc	a0,0x1d
    8000442e:	e4650513          	addi	a0,a0,-442 # 80021270 <log>
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	866080e7          	jalr	-1946(ra) # 80000c98 <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
    80004454:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004456:	00004597          	auipc	a1,0x4
    8000445a:	24a58593          	addi	a1,a1,586 # 800086a0 <syscalls+0x240>
    8000445e:	0521                	addi	a0,a0,8
    80004460:	ffffc097          	auipc	ra,0xffffc
    80004464:	6f4080e7          	jalr	1780(ra) # 80000b54 <initlock>
  lk->name = name;
    80004468:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000446c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004470:	0204a423          	sw	zero,40(s1)
}
    80004474:	60e2                	ld	ra,24(sp)
    80004476:	6442                	ld	s0,16(sp)
    80004478:	64a2                	ld	s1,8(sp)
    8000447a:	6902                	ld	s2,0(sp)
    8000447c:	6105                	addi	sp,sp,32
    8000447e:	8082                	ret

0000000080004480 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004480:	1101                	addi	sp,sp,-32
    80004482:	ec06                	sd	ra,24(sp)
    80004484:	e822                	sd	s0,16(sp)
    80004486:	e426                	sd	s1,8(sp)
    80004488:	e04a                	sd	s2,0(sp)
    8000448a:	1000                	addi	s0,sp,32
    8000448c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000448e:	00850913          	addi	s2,a0,8
    80004492:	854a                	mv	a0,s2
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	750080e7          	jalr	1872(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000449c:	409c                	lw	a5,0(s1)
    8000449e:	cb89                	beqz	a5,800044b0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a0:	85ca                	mv	a1,s2
    800044a2:	8526                	mv	a0,s1
    800044a4:	ffffe097          	auipc	ra,0xffffe
    800044a8:	c44080e7          	jalr	-956(ra) # 800020e8 <sleep>
  while (lk->locked) {
    800044ac:	409c                	lw	a5,0(s1)
    800044ae:	fbed                	bnez	a5,800044a0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b0:	4785                	li	a5,1
    800044b2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044b4:	ffffd097          	auipc	ra,0xffffd
    800044b8:	4fc080e7          	jalr	1276(ra) # 800019b0 <myproc>
    800044bc:	591c                	lw	a5,48(a0)
    800044be:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c0:	854a                	mv	a0,s2
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
}
    800044ca:	60e2                	ld	ra,24(sp)
    800044cc:	6442                	ld	s0,16(sp)
    800044ce:	64a2                	ld	s1,8(sp)
    800044d0:	6902                	ld	s2,0(sp)
    800044d2:	6105                	addi	sp,sp,32
    800044d4:	8082                	ret

00000000800044d6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044d6:	1101                	addi	sp,sp,-32
    800044d8:	ec06                	sd	ra,24(sp)
    800044da:	e822                	sd	s0,16(sp)
    800044dc:	e426                	sd	s1,8(sp)
    800044de:	e04a                	sd	s2,0(sp)
    800044e0:	1000                	addi	s0,sp,32
    800044e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e4:	00850913          	addi	s2,a0,8
    800044e8:	854a                	mv	a0,s2
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	6fa080e7          	jalr	1786(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800044f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffe097          	auipc	ra,0xffffe
    80004500:	d78080e7          	jalr	-648(ra) # 80002274 <wakeup>
  release(&lk->lk);
    80004504:	854a                	mv	a0,s2
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	792080e7          	jalr	1938(ra) # 80000c98 <release>
}
    8000450e:	60e2                	ld	ra,24(sp)
    80004510:	6442                	ld	s0,16(sp)
    80004512:	64a2                	ld	s1,8(sp)
    80004514:	6902                	ld	s2,0(sp)
    80004516:	6105                	addi	sp,sp,32
    80004518:	8082                	ret

000000008000451a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000451a:	7179                	addi	sp,sp,-48
    8000451c:	f406                	sd	ra,40(sp)
    8000451e:	f022                	sd	s0,32(sp)
    80004520:	ec26                	sd	s1,24(sp)
    80004522:	e84a                	sd	s2,16(sp)
    80004524:	e44e                	sd	s3,8(sp)
    80004526:	1800                	addi	s0,sp,48
    80004528:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000452a:	00850913          	addi	s2,a0,8
    8000452e:	854a                	mv	a0,s2
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004538:	409c                	lw	a5,0(s1)
    8000453a:	ef99                	bnez	a5,80004558 <holdingsleep+0x3e>
    8000453c:	4481                	li	s1,0
  release(&lk->lk);
    8000453e:	854a                	mv	a0,s2
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	758080e7          	jalr	1880(ra) # 80000c98 <release>
  return r;
}
    80004548:	8526                	mv	a0,s1
    8000454a:	70a2                	ld	ra,40(sp)
    8000454c:	7402                	ld	s0,32(sp)
    8000454e:	64e2                	ld	s1,24(sp)
    80004550:	6942                	ld	s2,16(sp)
    80004552:	69a2                	ld	s3,8(sp)
    80004554:	6145                	addi	sp,sp,48
    80004556:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004558:	0284a983          	lw	s3,40(s1)
    8000455c:	ffffd097          	auipc	ra,0xffffd
    80004560:	454080e7          	jalr	1108(ra) # 800019b0 <myproc>
    80004564:	5904                	lw	s1,48(a0)
    80004566:	413484b3          	sub	s1,s1,s3
    8000456a:	0014b493          	seqz	s1,s1
    8000456e:	bfc1                	j	8000453e <holdingsleep+0x24>

0000000080004570 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004570:	1141                	addi	sp,sp,-16
    80004572:	e406                	sd	ra,8(sp)
    80004574:	e022                	sd	s0,0(sp)
    80004576:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004578:	00004597          	auipc	a1,0x4
    8000457c:	13858593          	addi	a1,a1,312 # 800086b0 <syscalls+0x250>
    80004580:	0001d517          	auipc	a0,0x1d
    80004584:	e3850513          	addi	a0,a0,-456 # 800213b8 <ftable>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	5cc080e7          	jalr	1484(ra) # 80000b54 <initlock>
}
    80004590:	60a2                	ld	ra,8(sp)
    80004592:	6402                	ld	s0,0(sp)
    80004594:	0141                	addi	sp,sp,16
    80004596:	8082                	ret

0000000080004598 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004598:	1101                	addi	sp,sp,-32
    8000459a:	ec06                	sd	ra,24(sp)
    8000459c:	e822                	sd	s0,16(sp)
    8000459e:	e426                	sd	s1,8(sp)
    800045a0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045a2:	0001d517          	auipc	a0,0x1d
    800045a6:	e1650513          	addi	a0,a0,-490 # 800213b8 <ftable>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	63a080e7          	jalr	1594(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b2:	0001d497          	auipc	s1,0x1d
    800045b6:	e1e48493          	addi	s1,s1,-482 # 800213d0 <ftable+0x18>
    800045ba:	0001e717          	auipc	a4,0x1e
    800045be:	db670713          	addi	a4,a4,-586 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800045c2:	40dc                	lw	a5,4(s1)
    800045c4:	cf99                	beqz	a5,800045e2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c6:	02848493          	addi	s1,s1,40
    800045ca:	fee49ce3          	bne	s1,a4,800045c2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	dea50513          	addi	a0,a0,-534 # 800213b8 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
  return 0;
    800045de:	4481                	li	s1,0
    800045e0:	a819                	j	800045f6 <filealloc+0x5e>
      f->ref = 1;
    800045e2:	4785                	li	a5,1
    800045e4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045e6:	0001d517          	auipc	a0,0x1d
    800045ea:	dd250513          	addi	a0,a0,-558 # 800213b8 <ftable>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	6aa080e7          	jalr	1706(ra) # 80000c98 <release>
}
    800045f6:	8526                	mv	a0,s1
    800045f8:	60e2                	ld	ra,24(sp)
    800045fa:	6442                	ld	s0,16(sp)
    800045fc:	64a2                	ld	s1,8(sp)
    800045fe:	6105                	addi	sp,sp,32
    80004600:	8082                	ret

0000000080004602 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004602:	1101                	addi	sp,sp,-32
    80004604:	ec06                	sd	ra,24(sp)
    80004606:	e822                	sd	s0,16(sp)
    80004608:	e426                	sd	s1,8(sp)
    8000460a:	1000                	addi	s0,sp,32
    8000460c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000460e:	0001d517          	auipc	a0,0x1d
    80004612:	daa50513          	addi	a0,a0,-598 # 800213b8 <ftable>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	5ce080e7          	jalr	1486(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000461e:	40dc                	lw	a5,4(s1)
    80004620:	02f05263          	blez	a5,80004644 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004624:	2785                	addiw	a5,a5,1
    80004626:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004628:	0001d517          	auipc	a0,0x1d
    8000462c:	d9050513          	addi	a0,a0,-624 # 800213b8 <ftable>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	668080e7          	jalr	1640(ra) # 80000c98 <release>
  return f;
}
    80004638:	8526                	mv	a0,s1
    8000463a:	60e2                	ld	ra,24(sp)
    8000463c:	6442                	ld	s0,16(sp)
    8000463e:	64a2                	ld	s1,8(sp)
    80004640:	6105                	addi	sp,sp,32
    80004642:	8082                	ret
    panic("filedup");
    80004644:	00004517          	auipc	a0,0x4
    80004648:	07450513          	addi	a0,a0,116 # 800086b8 <syscalls+0x258>
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>

0000000080004654 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004654:	7139                	addi	sp,sp,-64
    80004656:	fc06                	sd	ra,56(sp)
    80004658:	f822                	sd	s0,48(sp)
    8000465a:	f426                	sd	s1,40(sp)
    8000465c:	f04a                	sd	s2,32(sp)
    8000465e:	ec4e                	sd	s3,24(sp)
    80004660:	e852                	sd	s4,16(sp)
    80004662:	e456                	sd	s5,8(sp)
    80004664:	0080                	addi	s0,sp,64
    80004666:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004668:	0001d517          	auipc	a0,0x1d
    8000466c:	d5050513          	addi	a0,a0,-688 # 800213b8 <ftable>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	574080e7          	jalr	1396(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004678:	40dc                	lw	a5,4(s1)
    8000467a:	06f05163          	blez	a5,800046dc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000467e:	37fd                	addiw	a5,a5,-1
    80004680:	0007871b          	sext.w	a4,a5
    80004684:	c0dc                	sw	a5,4(s1)
    80004686:	06e04363          	bgtz	a4,800046ec <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000468a:	0004a903          	lw	s2,0(s1)
    8000468e:	0094ca83          	lbu	s5,9(s1)
    80004692:	0104ba03          	ld	s4,16(s1)
    80004696:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000469a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000469e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046a2:	0001d517          	auipc	a0,0x1d
    800046a6:	d1650513          	addi	a0,a0,-746 # 800213b8 <ftable>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	5ee080e7          	jalr	1518(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800046b2:	4785                	li	a5,1
    800046b4:	04f90d63          	beq	s2,a5,8000470e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046b8:	3979                	addiw	s2,s2,-2
    800046ba:	4785                	li	a5,1
    800046bc:	0527e063          	bltu	a5,s2,800046fc <fileclose+0xa8>
    begin_op();
    800046c0:	00000097          	auipc	ra,0x0
    800046c4:	ac8080e7          	jalr	-1336(ra) # 80004188 <begin_op>
    iput(ff.ip);
    800046c8:	854e                	mv	a0,s3
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	2a6080e7          	jalr	678(ra) # 80003970 <iput>
    end_op();
    800046d2:	00000097          	auipc	ra,0x0
    800046d6:	b36080e7          	jalr	-1226(ra) # 80004208 <end_op>
    800046da:	a00d                	j	800046fc <fileclose+0xa8>
    panic("fileclose");
    800046dc:	00004517          	auipc	a0,0x4
    800046e0:	fe450513          	addi	a0,a0,-28 # 800086c0 <syscalls+0x260>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	e5a080e7          	jalr	-422(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046ec:	0001d517          	auipc	a0,0x1d
    800046f0:	ccc50513          	addi	a0,a0,-820 # 800213b8 <ftable>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
  }
}
    800046fc:	70e2                	ld	ra,56(sp)
    800046fe:	7442                	ld	s0,48(sp)
    80004700:	74a2                	ld	s1,40(sp)
    80004702:	7902                	ld	s2,32(sp)
    80004704:	69e2                	ld	s3,24(sp)
    80004706:	6a42                	ld	s4,16(sp)
    80004708:	6aa2                	ld	s5,8(sp)
    8000470a:	6121                	addi	sp,sp,64
    8000470c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000470e:	85d6                	mv	a1,s5
    80004710:	8552                	mv	a0,s4
    80004712:	00000097          	auipc	ra,0x0
    80004716:	34c080e7          	jalr	844(ra) # 80004a5e <pipeclose>
    8000471a:	b7cd                	j	800046fc <fileclose+0xa8>

000000008000471c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000471c:	715d                	addi	sp,sp,-80
    8000471e:	e486                	sd	ra,72(sp)
    80004720:	e0a2                	sd	s0,64(sp)
    80004722:	fc26                	sd	s1,56(sp)
    80004724:	f84a                	sd	s2,48(sp)
    80004726:	f44e                	sd	s3,40(sp)
    80004728:	0880                	addi	s0,sp,80
    8000472a:	84aa                	mv	s1,a0
    8000472c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000472e:	ffffd097          	auipc	ra,0xffffd
    80004732:	282080e7          	jalr	642(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004736:	409c                	lw	a5,0(s1)
    80004738:	37f9                	addiw	a5,a5,-2
    8000473a:	4705                	li	a4,1
    8000473c:	04f76763          	bltu	a4,a5,8000478a <filestat+0x6e>
    80004740:	892a                	mv	s2,a0
    ilock(f->ip);
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	072080e7          	jalr	114(ra) # 800037b6 <ilock>
    stati(f->ip, &st);
    8000474c:	fb840593          	addi	a1,s0,-72
    80004750:	6c88                	ld	a0,24(s1)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	2ee080e7          	jalr	750(ra) # 80003a40 <stati>
    iunlock(f->ip);
    8000475a:	6c88                	ld	a0,24(s1)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	11c080e7          	jalr	284(ra) # 80003878 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004764:	46e1                	li	a3,24
    80004766:	fb840613          	addi	a2,s0,-72
    8000476a:	85ce                	mv	a1,s3
    8000476c:	05093503          	ld	a0,80(s2)
    80004770:	ffffd097          	auipc	ra,0xffffd
    80004774:	f02080e7          	jalr	-254(ra) # 80001672 <copyout>
    80004778:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000477c:	60a6                	ld	ra,72(sp)
    8000477e:	6406                	ld	s0,64(sp)
    80004780:	74e2                	ld	s1,56(sp)
    80004782:	7942                	ld	s2,48(sp)
    80004784:	79a2                	ld	s3,40(sp)
    80004786:	6161                	addi	sp,sp,80
    80004788:	8082                	ret
  return -1;
    8000478a:	557d                	li	a0,-1
    8000478c:	bfc5                	j	8000477c <filestat+0x60>

000000008000478e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000478e:	7179                	addi	sp,sp,-48
    80004790:	f406                	sd	ra,40(sp)
    80004792:	f022                	sd	s0,32(sp)
    80004794:	ec26                	sd	s1,24(sp)
    80004796:	e84a                	sd	s2,16(sp)
    80004798:	e44e                	sd	s3,8(sp)
    8000479a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000479c:	00854783          	lbu	a5,8(a0)
    800047a0:	c3d5                	beqz	a5,80004844 <fileread+0xb6>
    800047a2:	84aa                	mv	s1,a0
    800047a4:	89ae                	mv	s3,a1
    800047a6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a8:	411c                	lw	a5,0(a0)
    800047aa:	4705                	li	a4,1
    800047ac:	04e78963          	beq	a5,a4,800047fe <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b0:	470d                	li	a4,3
    800047b2:	04e78d63          	beq	a5,a4,8000480c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b6:	4709                	li	a4,2
    800047b8:	06e79e63          	bne	a5,a4,80004834 <fileread+0xa6>
    ilock(f->ip);
    800047bc:	6d08                	ld	a0,24(a0)
    800047be:	fffff097          	auipc	ra,0xfffff
    800047c2:	ff8080e7          	jalr	-8(ra) # 800037b6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047c6:	874a                	mv	a4,s2
    800047c8:	5094                	lw	a3,32(s1)
    800047ca:	864e                	mv	a2,s3
    800047cc:	4585                	li	a1,1
    800047ce:	6c88                	ld	a0,24(s1)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	29a080e7          	jalr	666(ra) # 80003a6a <readi>
    800047d8:	892a                	mv	s2,a0
    800047da:	00a05563          	blez	a0,800047e4 <fileread+0x56>
      f->off += r;
    800047de:	509c                	lw	a5,32(s1)
    800047e0:	9fa9                	addw	a5,a5,a0
    800047e2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047e4:	6c88                	ld	a0,24(s1)
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	092080e7          	jalr	146(ra) # 80003878 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047ee:	854a                	mv	a0,s2
    800047f0:	70a2                	ld	ra,40(sp)
    800047f2:	7402                	ld	s0,32(sp)
    800047f4:	64e2                	ld	s1,24(sp)
    800047f6:	6942                	ld	s2,16(sp)
    800047f8:	69a2                	ld	s3,8(sp)
    800047fa:	6145                	addi	sp,sp,48
    800047fc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047fe:	6908                	ld	a0,16(a0)
    80004800:	00000097          	auipc	ra,0x0
    80004804:	3c8080e7          	jalr	968(ra) # 80004bc8 <piperead>
    80004808:	892a                	mv	s2,a0
    8000480a:	b7d5                	j	800047ee <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000480c:	02451783          	lh	a5,36(a0)
    80004810:	03079693          	slli	a3,a5,0x30
    80004814:	92c1                	srli	a3,a3,0x30
    80004816:	4725                	li	a4,9
    80004818:	02d76863          	bltu	a4,a3,80004848 <fileread+0xba>
    8000481c:	0792                	slli	a5,a5,0x4
    8000481e:	0001d717          	auipc	a4,0x1d
    80004822:	afa70713          	addi	a4,a4,-1286 # 80021318 <devsw>
    80004826:	97ba                	add	a5,a5,a4
    80004828:	639c                	ld	a5,0(a5)
    8000482a:	c38d                	beqz	a5,8000484c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000482c:	4505                	li	a0,1
    8000482e:	9782                	jalr	a5
    80004830:	892a                	mv	s2,a0
    80004832:	bf75                	j	800047ee <fileread+0x60>
    panic("fileread");
    80004834:	00004517          	auipc	a0,0x4
    80004838:	e9c50513          	addi	a0,a0,-356 # 800086d0 <syscalls+0x270>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	d02080e7          	jalr	-766(ra) # 8000053e <panic>
    return -1;
    80004844:	597d                	li	s2,-1
    80004846:	b765                	j	800047ee <fileread+0x60>
      return -1;
    80004848:	597d                	li	s2,-1
    8000484a:	b755                	j	800047ee <fileread+0x60>
    8000484c:	597d                	li	s2,-1
    8000484e:	b745                	j	800047ee <fileread+0x60>

0000000080004850 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004850:	715d                	addi	sp,sp,-80
    80004852:	e486                	sd	ra,72(sp)
    80004854:	e0a2                	sd	s0,64(sp)
    80004856:	fc26                	sd	s1,56(sp)
    80004858:	f84a                	sd	s2,48(sp)
    8000485a:	f44e                	sd	s3,40(sp)
    8000485c:	f052                	sd	s4,32(sp)
    8000485e:	ec56                	sd	s5,24(sp)
    80004860:	e85a                	sd	s6,16(sp)
    80004862:	e45e                	sd	s7,8(sp)
    80004864:	e062                	sd	s8,0(sp)
    80004866:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004868:	00954783          	lbu	a5,9(a0)
    8000486c:	10078663          	beqz	a5,80004978 <filewrite+0x128>
    80004870:	892a                	mv	s2,a0
    80004872:	8aae                	mv	s5,a1
    80004874:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004876:	411c                	lw	a5,0(a0)
    80004878:	4705                	li	a4,1
    8000487a:	02e78263          	beq	a5,a4,8000489e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000487e:	470d                	li	a4,3
    80004880:	02e78663          	beq	a5,a4,800048ac <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004884:	4709                	li	a4,2
    80004886:	0ee79163          	bne	a5,a4,80004968 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000488a:	0ac05d63          	blez	a2,80004944 <filewrite+0xf4>
    int i = 0;
    8000488e:	4981                	li	s3,0
    80004890:	6b05                	lui	s6,0x1
    80004892:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004896:	6b85                	lui	s7,0x1
    80004898:	c00b8b9b          	addiw	s7,s7,-1024
    8000489c:	a861                	j	80004934 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000489e:	6908                	ld	a0,16(a0)
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	22e080e7          	jalr	558(ra) # 80004ace <pipewrite>
    800048a8:	8a2a                	mv	s4,a0
    800048aa:	a045                	j	8000494a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048ac:	02451783          	lh	a5,36(a0)
    800048b0:	03079693          	slli	a3,a5,0x30
    800048b4:	92c1                	srli	a3,a3,0x30
    800048b6:	4725                	li	a4,9
    800048b8:	0cd76263          	bltu	a4,a3,8000497c <filewrite+0x12c>
    800048bc:	0792                	slli	a5,a5,0x4
    800048be:	0001d717          	auipc	a4,0x1d
    800048c2:	a5a70713          	addi	a4,a4,-1446 # 80021318 <devsw>
    800048c6:	97ba                	add	a5,a5,a4
    800048c8:	679c                	ld	a5,8(a5)
    800048ca:	cbdd                	beqz	a5,80004980 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048cc:	4505                	li	a0,1
    800048ce:	9782                	jalr	a5
    800048d0:	8a2a                	mv	s4,a0
    800048d2:	a8a5                	j	8000494a <filewrite+0xfa>
    800048d4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	8b0080e7          	jalr	-1872(ra) # 80004188 <begin_op>
      ilock(f->ip);
    800048e0:	01893503          	ld	a0,24(s2)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	ed2080e7          	jalr	-302(ra) # 800037b6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048ec:	8762                	mv	a4,s8
    800048ee:	02092683          	lw	a3,32(s2)
    800048f2:	01598633          	add	a2,s3,s5
    800048f6:	4585                	li	a1,1
    800048f8:	01893503          	ld	a0,24(s2)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	266080e7          	jalr	614(ra) # 80003b62 <writei>
    80004904:	84aa                	mv	s1,a0
    80004906:	00a05763          	blez	a0,80004914 <filewrite+0xc4>
        f->off += r;
    8000490a:	02092783          	lw	a5,32(s2)
    8000490e:	9fa9                	addw	a5,a5,a0
    80004910:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004914:	01893503          	ld	a0,24(s2)
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	f60080e7          	jalr	-160(ra) # 80003878 <iunlock>
      end_op();
    80004920:	00000097          	auipc	ra,0x0
    80004924:	8e8080e7          	jalr	-1816(ra) # 80004208 <end_op>

      if(r != n1){
    80004928:	009c1f63          	bne	s8,s1,80004946 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000492c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004930:	0149db63          	bge	s3,s4,80004946 <filewrite+0xf6>
      int n1 = n - i;
    80004934:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004938:	84be                	mv	s1,a5
    8000493a:	2781                	sext.w	a5,a5
    8000493c:	f8fb5ce3          	bge	s6,a5,800048d4 <filewrite+0x84>
    80004940:	84de                	mv	s1,s7
    80004942:	bf49                	j	800048d4 <filewrite+0x84>
    int i = 0;
    80004944:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004946:	013a1f63          	bne	s4,s3,80004964 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000494a:	8552                	mv	a0,s4
    8000494c:	60a6                	ld	ra,72(sp)
    8000494e:	6406                	ld	s0,64(sp)
    80004950:	74e2                	ld	s1,56(sp)
    80004952:	7942                	ld	s2,48(sp)
    80004954:	79a2                	ld	s3,40(sp)
    80004956:	7a02                	ld	s4,32(sp)
    80004958:	6ae2                	ld	s5,24(sp)
    8000495a:	6b42                	ld	s6,16(sp)
    8000495c:	6ba2                	ld	s7,8(sp)
    8000495e:	6c02                	ld	s8,0(sp)
    80004960:	6161                	addi	sp,sp,80
    80004962:	8082                	ret
    ret = (i == n ? n : -1);
    80004964:	5a7d                	li	s4,-1
    80004966:	b7d5                	j	8000494a <filewrite+0xfa>
    panic("filewrite");
    80004968:	00004517          	auipc	a0,0x4
    8000496c:	d7850513          	addi	a0,a0,-648 # 800086e0 <syscalls+0x280>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    return -1;
    80004978:	5a7d                	li	s4,-1
    8000497a:	bfc1                	j	8000494a <filewrite+0xfa>
      return -1;
    8000497c:	5a7d                	li	s4,-1
    8000497e:	b7f1                	j	8000494a <filewrite+0xfa>
    80004980:	5a7d                	li	s4,-1
    80004982:	b7e1                	j	8000494a <filewrite+0xfa>

0000000080004984 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004984:	7179                	addi	sp,sp,-48
    80004986:	f406                	sd	ra,40(sp)
    80004988:	f022                	sd	s0,32(sp)
    8000498a:	ec26                	sd	s1,24(sp)
    8000498c:	e84a                	sd	s2,16(sp)
    8000498e:	e44e                	sd	s3,8(sp)
    80004990:	e052                	sd	s4,0(sp)
    80004992:	1800                	addi	s0,sp,48
    80004994:	84aa                	mv	s1,a0
    80004996:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004998:	0005b023          	sd	zero,0(a1)
    8000499c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049a0:	00000097          	auipc	ra,0x0
    800049a4:	bf8080e7          	jalr	-1032(ra) # 80004598 <filealloc>
    800049a8:	e088                	sd	a0,0(s1)
    800049aa:	c551                	beqz	a0,80004a36 <pipealloc+0xb2>
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	bec080e7          	jalr	-1044(ra) # 80004598 <filealloc>
    800049b4:	00aa3023          	sd	a0,0(s4)
    800049b8:	c92d                	beqz	a0,80004a2a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	13a080e7          	jalr	314(ra) # 80000af4 <kalloc>
    800049c2:	892a                	mv	s2,a0
    800049c4:	c125                	beqz	a0,80004a24 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049c6:	4985                	li	s3,1
    800049c8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049cc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049d0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049d4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049d8:	00004597          	auipc	a1,0x4
    800049dc:	d1858593          	addi	a1,a1,-744 # 800086f0 <syscalls+0x290>
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	174080e7          	jalr	372(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800049e8:	609c                	ld	a5,0(s1)
    800049ea:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ee:	609c                	ld	a5,0(s1)
    800049f0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049f4:	609c                	ld	a5,0(s1)
    800049f6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049fa:	609c                	ld	a5,0(s1)
    800049fc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a00:	000a3783          	ld	a5,0(s4)
    80004a04:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a08:	000a3783          	ld	a5,0(s4)
    80004a0c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a10:	000a3783          	ld	a5,0(s4)
    80004a14:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a18:	000a3783          	ld	a5,0(s4)
    80004a1c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a20:	4501                	li	a0,0
    80004a22:	a025                	j	80004a4a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a24:	6088                	ld	a0,0(s1)
    80004a26:	e501                	bnez	a0,80004a2e <pipealloc+0xaa>
    80004a28:	a039                	j	80004a36 <pipealloc+0xb2>
    80004a2a:	6088                	ld	a0,0(s1)
    80004a2c:	c51d                	beqz	a0,80004a5a <pipealloc+0xd6>
    fileclose(*f0);
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	c26080e7          	jalr	-986(ra) # 80004654 <fileclose>
  if(*f1)
    80004a36:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a3a:	557d                	li	a0,-1
  if(*f1)
    80004a3c:	c799                	beqz	a5,80004a4a <pipealloc+0xc6>
    fileclose(*f1);
    80004a3e:	853e                	mv	a0,a5
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	c14080e7          	jalr	-1004(ra) # 80004654 <fileclose>
  return -1;
    80004a48:	557d                	li	a0,-1
}
    80004a4a:	70a2                	ld	ra,40(sp)
    80004a4c:	7402                	ld	s0,32(sp)
    80004a4e:	64e2                	ld	s1,24(sp)
    80004a50:	6942                	ld	s2,16(sp)
    80004a52:	69a2                	ld	s3,8(sp)
    80004a54:	6a02                	ld	s4,0(sp)
    80004a56:	6145                	addi	sp,sp,48
    80004a58:	8082                	ret
  return -1;
    80004a5a:	557d                	li	a0,-1
    80004a5c:	b7fd                	j	80004a4a <pipealloc+0xc6>

0000000080004a5e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a5e:	1101                	addi	sp,sp,-32
    80004a60:	ec06                	sd	ra,24(sp)
    80004a62:	e822                	sd	s0,16(sp)
    80004a64:	e426                	sd	s1,8(sp)
    80004a66:	e04a                	sd	s2,0(sp)
    80004a68:	1000                	addi	s0,sp,32
    80004a6a:	84aa                	mv	s1,a0
    80004a6c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	176080e7          	jalr	374(ra) # 80000be4 <acquire>
  if(writable){
    80004a76:	02090d63          	beqz	s2,80004ab0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a7a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a7e:	21848513          	addi	a0,s1,536
    80004a82:	ffffd097          	auipc	ra,0xffffd
    80004a86:	7f2080e7          	jalr	2034(ra) # 80002274 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a8a:	2204b783          	ld	a5,544(s1)
    80004a8e:	eb95                	bnez	a5,80004ac2 <pipeclose+0x64>
    release(&pi->lock);
    80004a90:	8526                	mv	a0,s1
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	206080e7          	jalr	518(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	f5c080e7          	jalr	-164(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004aa4:	60e2                	ld	ra,24(sp)
    80004aa6:	6442                	ld	s0,16(sp)
    80004aa8:	64a2                	ld	s1,8(sp)
    80004aaa:	6902                	ld	s2,0(sp)
    80004aac:	6105                	addi	sp,sp,32
    80004aae:	8082                	ret
    pi->readopen = 0;
    80004ab0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ab4:	21c48513          	addi	a0,s1,540
    80004ab8:	ffffd097          	auipc	ra,0xffffd
    80004abc:	7bc080e7          	jalr	1980(ra) # 80002274 <wakeup>
    80004ac0:	b7e9                	j	80004a8a <pipeclose+0x2c>
    release(&pi->lock);
    80004ac2:	8526                	mv	a0,s1
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	1d4080e7          	jalr	468(ra) # 80000c98 <release>
}
    80004acc:	bfe1                	j	80004aa4 <pipeclose+0x46>

0000000080004ace <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ace:	7159                	addi	sp,sp,-112
    80004ad0:	f486                	sd	ra,104(sp)
    80004ad2:	f0a2                	sd	s0,96(sp)
    80004ad4:	eca6                	sd	s1,88(sp)
    80004ad6:	e8ca                	sd	s2,80(sp)
    80004ad8:	e4ce                	sd	s3,72(sp)
    80004ada:	e0d2                	sd	s4,64(sp)
    80004adc:	fc56                	sd	s5,56(sp)
    80004ade:	f85a                	sd	s6,48(sp)
    80004ae0:	f45e                	sd	s7,40(sp)
    80004ae2:	f062                	sd	s8,32(sp)
    80004ae4:	ec66                	sd	s9,24(sp)
    80004ae6:	1880                	addi	s0,sp,112
    80004ae8:	84aa                	mv	s1,a0
    80004aea:	8aae                	mv	s5,a1
    80004aec:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004aee:	ffffd097          	auipc	ra,0xffffd
    80004af2:	ec2080e7          	jalr	-318(ra) # 800019b0 <myproc>
    80004af6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004af8:	8526                	mv	a0,s1
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	0ea080e7          	jalr	234(ra) # 80000be4 <acquire>
  while(i < n){
    80004b02:	0d405163          	blez	s4,80004bc4 <pipewrite+0xf6>
    80004b06:	8ba6                	mv	s7,s1
  int i = 0;
    80004b08:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b0a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b0c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b10:	21c48c13          	addi	s8,s1,540
    80004b14:	a08d                	j	80004b76 <pipewrite+0xa8>
      release(&pi->lock);
    80004b16:	8526                	mv	a0,s1
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	180080e7          	jalr	384(ra) # 80000c98 <release>
      return -1;
    80004b20:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b22:	854a                	mv	a0,s2
    80004b24:	70a6                	ld	ra,104(sp)
    80004b26:	7406                	ld	s0,96(sp)
    80004b28:	64e6                	ld	s1,88(sp)
    80004b2a:	6946                	ld	s2,80(sp)
    80004b2c:	69a6                	ld	s3,72(sp)
    80004b2e:	6a06                	ld	s4,64(sp)
    80004b30:	7ae2                	ld	s5,56(sp)
    80004b32:	7b42                	ld	s6,48(sp)
    80004b34:	7ba2                	ld	s7,40(sp)
    80004b36:	7c02                	ld	s8,32(sp)
    80004b38:	6ce2                	ld	s9,24(sp)
    80004b3a:	6165                	addi	sp,sp,112
    80004b3c:	8082                	ret
      wakeup(&pi->nread);
    80004b3e:	8566                	mv	a0,s9
    80004b40:	ffffd097          	auipc	ra,0xffffd
    80004b44:	734080e7          	jalr	1844(ra) # 80002274 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b48:	85de                	mv	a1,s7
    80004b4a:	8562                	mv	a0,s8
    80004b4c:	ffffd097          	auipc	ra,0xffffd
    80004b50:	59c080e7          	jalr	1436(ra) # 800020e8 <sleep>
    80004b54:	a839                	j	80004b72 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b56:	21c4a783          	lw	a5,540(s1)
    80004b5a:	0017871b          	addiw	a4,a5,1
    80004b5e:	20e4ae23          	sw	a4,540(s1)
    80004b62:	1ff7f793          	andi	a5,a5,511
    80004b66:	97a6                	add	a5,a5,s1
    80004b68:	f9f44703          	lbu	a4,-97(s0)
    80004b6c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b70:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b72:	03495d63          	bge	s2,s4,80004bac <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b76:	2204a783          	lw	a5,544(s1)
    80004b7a:	dfd1                	beqz	a5,80004b16 <pipewrite+0x48>
    80004b7c:	0289a783          	lw	a5,40(s3)
    80004b80:	fbd9                	bnez	a5,80004b16 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b82:	2184a783          	lw	a5,536(s1)
    80004b86:	21c4a703          	lw	a4,540(s1)
    80004b8a:	2007879b          	addiw	a5,a5,512
    80004b8e:	faf708e3          	beq	a4,a5,80004b3e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b92:	4685                	li	a3,1
    80004b94:	01590633          	add	a2,s2,s5
    80004b98:	f9f40593          	addi	a1,s0,-97
    80004b9c:	0509b503          	ld	a0,80(s3)
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	b5e080e7          	jalr	-1186(ra) # 800016fe <copyin>
    80004ba8:	fb6517e3          	bne	a0,s6,80004b56 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bac:	21848513          	addi	a0,s1,536
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	6c4080e7          	jalr	1732(ra) # 80002274 <wakeup>
  release(&pi->lock);
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	0de080e7          	jalr	222(ra) # 80000c98 <release>
  return i;
    80004bc2:	b785                	j	80004b22 <pipewrite+0x54>
  int i = 0;
    80004bc4:	4901                	li	s2,0
    80004bc6:	b7dd                	j	80004bac <pipewrite+0xde>

0000000080004bc8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bc8:	715d                	addi	sp,sp,-80
    80004bca:	e486                	sd	ra,72(sp)
    80004bcc:	e0a2                	sd	s0,64(sp)
    80004bce:	fc26                	sd	s1,56(sp)
    80004bd0:	f84a                	sd	s2,48(sp)
    80004bd2:	f44e                	sd	s3,40(sp)
    80004bd4:	f052                	sd	s4,32(sp)
    80004bd6:	ec56                	sd	s5,24(sp)
    80004bd8:	e85a                	sd	s6,16(sp)
    80004bda:	0880                	addi	s0,sp,80
    80004bdc:	84aa                	mv	s1,a0
    80004bde:	892e                	mv	s2,a1
    80004be0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004be2:	ffffd097          	auipc	ra,0xffffd
    80004be6:	dce080e7          	jalr	-562(ra) # 800019b0 <myproc>
    80004bea:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bec:	8b26                	mv	s6,s1
    80004bee:	8526                	mv	a0,s1
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf8:	2184a703          	lw	a4,536(s1)
    80004bfc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c00:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c04:	02f71463          	bne	a4,a5,80004c2c <piperead+0x64>
    80004c08:	2244a783          	lw	a5,548(s1)
    80004c0c:	c385                	beqz	a5,80004c2c <piperead+0x64>
    if(pr->killed){
    80004c0e:	028a2783          	lw	a5,40(s4)
    80004c12:	ebc1                	bnez	a5,80004ca2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c14:	85da                	mv	a1,s6
    80004c16:	854e                	mv	a0,s3
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	4d0080e7          	jalr	1232(ra) # 800020e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c20:	2184a703          	lw	a4,536(s1)
    80004c24:	21c4a783          	lw	a5,540(s1)
    80004c28:	fef700e3          	beq	a4,a5,80004c08 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c2c:	09505263          	blez	s5,80004cb0 <piperead+0xe8>
    80004c30:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c32:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c34:	2184a783          	lw	a5,536(s1)
    80004c38:	21c4a703          	lw	a4,540(s1)
    80004c3c:	02f70d63          	beq	a4,a5,80004c76 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c40:	0017871b          	addiw	a4,a5,1
    80004c44:	20e4ac23          	sw	a4,536(s1)
    80004c48:	1ff7f793          	andi	a5,a5,511
    80004c4c:	97a6                	add	a5,a5,s1
    80004c4e:	0187c783          	lbu	a5,24(a5)
    80004c52:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c56:	4685                	li	a3,1
    80004c58:	fbf40613          	addi	a2,s0,-65
    80004c5c:	85ca                	mv	a1,s2
    80004c5e:	050a3503          	ld	a0,80(s4)
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	a10080e7          	jalr	-1520(ra) # 80001672 <copyout>
    80004c6a:	01650663          	beq	a0,s6,80004c76 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6e:	2985                	addiw	s3,s3,1
    80004c70:	0905                	addi	s2,s2,1
    80004c72:	fd3a91e3          	bne	s5,s3,80004c34 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c76:	21c48513          	addi	a0,s1,540
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	5fa080e7          	jalr	1530(ra) # 80002274 <wakeup>
  release(&pi->lock);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	014080e7          	jalr	20(ra) # 80000c98 <release>
  return i;
}
    80004c8c:	854e                	mv	a0,s3
    80004c8e:	60a6                	ld	ra,72(sp)
    80004c90:	6406                	ld	s0,64(sp)
    80004c92:	74e2                	ld	s1,56(sp)
    80004c94:	7942                	ld	s2,48(sp)
    80004c96:	79a2                	ld	s3,40(sp)
    80004c98:	7a02                	ld	s4,32(sp)
    80004c9a:	6ae2                	ld	s5,24(sp)
    80004c9c:	6b42                	ld	s6,16(sp)
    80004c9e:	6161                	addi	sp,sp,80
    80004ca0:	8082                	ret
      release(&pi->lock);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	ff4080e7          	jalr	-12(ra) # 80000c98 <release>
      return -1;
    80004cac:	59fd                	li	s3,-1
    80004cae:	bff9                	j	80004c8c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb0:	4981                	li	s3,0
    80004cb2:	b7d1                	j	80004c76 <piperead+0xae>

0000000080004cb4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cb4:	df010113          	addi	sp,sp,-528
    80004cb8:	20113423          	sd	ra,520(sp)
    80004cbc:	20813023          	sd	s0,512(sp)
    80004cc0:	ffa6                	sd	s1,504(sp)
    80004cc2:	fbca                	sd	s2,496(sp)
    80004cc4:	f7ce                	sd	s3,488(sp)
    80004cc6:	f3d2                	sd	s4,480(sp)
    80004cc8:	efd6                	sd	s5,472(sp)
    80004cca:	ebda                	sd	s6,464(sp)
    80004ccc:	e7de                	sd	s7,456(sp)
    80004cce:	e3e2                	sd	s8,448(sp)
    80004cd0:	ff66                	sd	s9,440(sp)
    80004cd2:	fb6a                	sd	s10,432(sp)
    80004cd4:	f76e                	sd	s11,424(sp)
    80004cd6:	0c00                	addi	s0,sp,528
    80004cd8:	84aa                	mv	s1,a0
    80004cda:	dea43c23          	sd	a0,-520(s0)
    80004cde:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	cce080e7          	jalr	-818(ra) # 800019b0 <myproc>
    80004cea:	892a                	mv	s2,a0

  begin_op();
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	49c080e7          	jalr	1180(ra) # 80004188 <begin_op>

  if((ip = namei(path)) == 0){
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	276080e7          	jalr	630(ra) # 80003f6c <namei>
    80004cfe:	c92d                	beqz	a0,80004d70 <exec+0xbc>
    80004d00:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	ab4080e7          	jalr	-1356(ra) # 800037b6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d0a:	04000713          	li	a4,64
    80004d0e:	4681                	li	a3,0
    80004d10:	e5040613          	addi	a2,s0,-432
    80004d14:	4581                	li	a1,0
    80004d16:	8526                	mv	a0,s1
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	d52080e7          	jalr	-686(ra) # 80003a6a <readi>
    80004d20:	04000793          	li	a5,64
    80004d24:	00f51a63          	bne	a0,a5,80004d38 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d28:	e5042703          	lw	a4,-432(s0)
    80004d2c:	464c47b7          	lui	a5,0x464c4
    80004d30:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d34:	04f70463          	beq	a4,a5,80004d7c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d38:	8526                	mv	a0,s1
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	cde080e7          	jalr	-802(ra) # 80003a18 <iunlockput>
    end_op();
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	4c6080e7          	jalr	1222(ra) # 80004208 <end_op>
  }
  return -1;
    80004d4a:	557d                	li	a0,-1
}
    80004d4c:	20813083          	ld	ra,520(sp)
    80004d50:	20013403          	ld	s0,512(sp)
    80004d54:	74fe                	ld	s1,504(sp)
    80004d56:	795e                	ld	s2,496(sp)
    80004d58:	79be                	ld	s3,488(sp)
    80004d5a:	7a1e                	ld	s4,480(sp)
    80004d5c:	6afe                	ld	s5,472(sp)
    80004d5e:	6b5e                	ld	s6,464(sp)
    80004d60:	6bbe                	ld	s7,456(sp)
    80004d62:	6c1e                	ld	s8,448(sp)
    80004d64:	7cfa                	ld	s9,440(sp)
    80004d66:	7d5a                	ld	s10,432(sp)
    80004d68:	7dba                	ld	s11,424(sp)
    80004d6a:	21010113          	addi	sp,sp,528
    80004d6e:	8082                	ret
    end_op();
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	498080e7          	jalr	1176(ra) # 80004208 <end_op>
    return -1;
    80004d78:	557d                	li	a0,-1
    80004d7a:	bfc9                	j	80004d4c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d7c:	854a                	mv	a0,s2
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	cf6080e7          	jalr	-778(ra) # 80001a74 <proc_pagetable>
    80004d86:	8baa                	mv	s7,a0
    80004d88:	d945                	beqz	a0,80004d38 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8a:	e7042983          	lw	s3,-400(s0)
    80004d8e:	e8845783          	lhu	a5,-376(s0)
    80004d92:	c7ad                	beqz	a5,80004dfc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d94:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d96:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d98:	6c85                	lui	s9,0x1
    80004d9a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d9e:	def43823          	sd	a5,-528(s0)
    80004da2:	a42d                	j	80004fcc <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004da4:	00004517          	auipc	a0,0x4
    80004da8:	95450513          	addi	a0,a0,-1708 # 800086f8 <syscalls+0x298>
    80004dac:	ffffb097          	auipc	ra,0xffffb
    80004db0:	792080e7          	jalr	1938(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004db4:	8756                	mv	a4,s5
    80004db6:	012d86bb          	addw	a3,s11,s2
    80004dba:	4581                	li	a1,0
    80004dbc:	8526                	mv	a0,s1
    80004dbe:	fffff097          	auipc	ra,0xfffff
    80004dc2:	cac080e7          	jalr	-852(ra) # 80003a6a <readi>
    80004dc6:	2501                	sext.w	a0,a0
    80004dc8:	1aaa9963          	bne	s5,a0,80004f7a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dcc:	6785                	lui	a5,0x1
    80004dce:	0127893b          	addw	s2,a5,s2
    80004dd2:	77fd                	lui	a5,0xfffff
    80004dd4:	01478a3b          	addw	s4,a5,s4
    80004dd8:	1f897163          	bgeu	s2,s8,80004fba <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004ddc:	02091593          	slli	a1,s2,0x20
    80004de0:	9181                	srli	a1,a1,0x20
    80004de2:	95ea                	add	a1,a1,s10
    80004de4:	855e                	mv	a0,s7
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	288080e7          	jalr	648(ra) # 8000106e <walkaddr>
    80004dee:	862a                	mv	a2,a0
    if(pa == 0)
    80004df0:	d955                	beqz	a0,80004da4 <exec+0xf0>
      n = PGSIZE;
    80004df2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004df4:	fd9a70e3          	bgeu	s4,s9,80004db4 <exec+0x100>
      n = sz - i;
    80004df8:	8ad2                	mv	s5,s4
    80004dfa:	bf6d                	j	80004db4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dfc:	4901                	li	s2,0
  iunlockput(ip);
    80004dfe:	8526                	mv	a0,s1
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	c18080e7          	jalr	-1000(ra) # 80003a18 <iunlockput>
  end_op();
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	400080e7          	jalr	1024(ra) # 80004208 <end_op>
  p = myproc();
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	ba0080e7          	jalr	-1120(ra) # 800019b0 <myproc>
    80004e18:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e1a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e1e:	6785                	lui	a5,0x1
    80004e20:	17fd                	addi	a5,a5,-1
    80004e22:	993e                	add	s2,s2,a5
    80004e24:	757d                	lui	a0,0xfffff
    80004e26:	00a977b3          	and	a5,s2,a0
    80004e2a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e2e:	6609                	lui	a2,0x2
    80004e30:	963e                	add	a2,a2,a5
    80004e32:	85be                	mv	a1,a5
    80004e34:	855e                	mv	a0,s7
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	5ec080e7          	jalr	1516(ra) # 80001422 <uvmalloc>
    80004e3e:	8b2a                	mv	s6,a0
  ip = 0;
    80004e40:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e42:	12050c63          	beqz	a0,80004f7a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e46:	75f9                	lui	a1,0xffffe
    80004e48:	95aa                	add	a1,a1,a0
    80004e4a:	855e                	mv	a0,s7
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	7f4080e7          	jalr	2036(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e54:	7c7d                	lui	s8,0xfffff
    80004e56:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e58:	e0043783          	ld	a5,-512(s0)
    80004e5c:	6388                	ld	a0,0(a5)
    80004e5e:	c535                	beqz	a0,80004eca <exec+0x216>
    80004e60:	e9040993          	addi	s3,s0,-368
    80004e64:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e68:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	ffa080e7          	jalr	-6(ra) # 80000e64 <strlen>
    80004e72:	2505                	addiw	a0,a0,1
    80004e74:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e78:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e7c:	13896363          	bltu	s2,s8,80004fa2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e80:	e0043d83          	ld	s11,-512(s0)
    80004e84:	000dba03          	ld	s4,0(s11)
    80004e88:	8552                	mv	a0,s4
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	fda080e7          	jalr	-38(ra) # 80000e64 <strlen>
    80004e92:	0015069b          	addiw	a3,a0,1
    80004e96:	8652                	mv	a2,s4
    80004e98:	85ca                	mv	a1,s2
    80004e9a:	855e                	mv	a0,s7
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	7d6080e7          	jalr	2006(ra) # 80001672 <copyout>
    80004ea4:	10054363          	bltz	a0,80004faa <exec+0x2f6>
    ustack[argc] = sp;
    80004ea8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eac:	0485                	addi	s1,s1,1
    80004eae:	008d8793          	addi	a5,s11,8
    80004eb2:	e0f43023          	sd	a5,-512(s0)
    80004eb6:	008db503          	ld	a0,8(s11)
    80004eba:	c911                	beqz	a0,80004ece <exec+0x21a>
    if(argc >= MAXARG)
    80004ebc:	09a1                	addi	s3,s3,8
    80004ebe:	fb3c96e3          	bne	s9,s3,80004e6a <exec+0x1b6>
  sz = sz1;
    80004ec2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec6:	4481                	li	s1,0
    80004ec8:	a84d                	j	80004f7a <exec+0x2c6>
  sp = sz;
    80004eca:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ecc:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ece:	00349793          	slli	a5,s1,0x3
    80004ed2:	f9040713          	addi	a4,s0,-112
    80004ed6:	97ba                	add	a5,a5,a4
    80004ed8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004edc:	00148693          	addi	a3,s1,1
    80004ee0:	068e                	slli	a3,a3,0x3
    80004ee2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eea:	01897663          	bgeu	s2,s8,80004ef6 <exec+0x242>
  sz = sz1;
    80004eee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef2:	4481                	li	s1,0
    80004ef4:	a059                	j	80004f7a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef6:	e9040613          	addi	a2,s0,-368
    80004efa:	85ca                	mv	a1,s2
    80004efc:	855e                	mv	a0,s7
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	774080e7          	jalr	1908(ra) # 80001672 <copyout>
    80004f06:	0a054663          	bltz	a0,80004fb2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f0a:	058ab783          	ld	a5,88(s5)
    80004f0e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f12:	df843783          	ld	a5,-520(s0)
    80004f16:	0007c703          	lbu	a4,0(a5)
    80004f1a:	cf11                	beqz	a4,80004f36 <exec+0x282>
    80004f1c:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f1e:	02f00693          	li	a3,47
    80004f22:	a039                	j	80004f30 <exec+0x27c>
      last = s+1;
    80004f24:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f28:	0785                	addi	a5,a5,1
    80004f2a:	fff7c703          	lbu	a4,-1(a5)
    80004f2e:	c701                	beqz	a4,80004f36 <exec+0x282>
    if(*s == '/')
    80004f30:	fed71ce3          	bne	a4,a3,80004f28 <exec+0x274>
    80004f34:	bfc5                	j	80004f24 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f36:	4641                	li	a2,16
    80004f38:	df843583          	ld	a1,-520(s0)
    80004f3c:	158a8513          	addi	a0,s5,344
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	ef2080e7          	jalr	-270(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f48:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f4c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f50:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f54:	058ab783          	ld	a5,88(s5)
    80004f58:	e6843703          	ld	a4,-408(s0)
    80004f5c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f5e:	058ab783          	ld	a5,88(s5)
    80004f62:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f66:	85ea                	mv	a1,s10
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	ba8080e7          	jalr	-1112(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f70:	0004851b          	sext.w	a0,s1
    80004f74:	bbe1                	j	80004d4c <exec+0x98>
    80004f76:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f7a:	e0843583          	ld	a1,-504(s0)
    80004f7e:	855e                	mv	a0,s7
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	b90080e7          	jalr	-1136(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    80004f88:	da0498e3          	bnez	s1,80004d38 <exec+0x84>
  return -1;
    80004f8c:	557d                	li	a0,-1
    80004f8e:	bb7d                	j	80004d4c <exec+0x98>
    80004f90:	e1243423          	sd	s2,-504(s0)
    80004f94:	b7dd                	j	80004f7a <exec+0x2c6>
    80004f96:	e1243423          	sd	s2,-504(s0)
    80004f9a:	b7c5                	j	80004f7a <exec+0x2c6>
    80004f9c:	e1243423          	sd	s2,-504(s0)
    80004fa0:	bfe9                	j	80004f7a <exec+0x2c6>
  sz = sz1;
    80004fa2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa6:	4481                	li	s1,0
    80004fa8:	bfc9                	j	80004f7a <exec+0x2c6>
  sz = sz1;
    80004faa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fae:	4481                	li	s1,0
    80004fb0:	b7e9                	j	80004f7a <exec+0x2c6>
  sz = sz1;
    80004fb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb6:	4481                	li	s1,0
    80004fb8:	b7c9                	j	80004f7a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fba:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fbe:	2b05                	addiw	s6,s6,1
    80004fc0:	0389899b          	addiw	s3,s3,56
    80004fc4:	e8845783          	lhu	a5,-376(s0)
    80004fc8:	e2fb5be3          	bge	s6,a5,80004dfe <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fcc:	2981                	sext.w	s3,s3
    80004fce:	03800713          	li	a4,56
    80004fd2:	86ce                	mv	a3,s3
    80004fd4:	e1840613          	addi	a2,s0,-488
    80004fd8:	4581                	li	a1,0
    80004fda:	8526                	mv	a0,s1
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	a8e080e7          	jalr	-1394(ra) # 80003a6a <readi>
    80004fe4:	03800793          	li	a5,56
    80004fe8:	f8f517e3          	bne	a0,a5,80004f76 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fec:	e1842783          	lw	a5,-488(s0)
    80004ff0:	4705                	li	a4,1
    80004ff2:	fce796e3          	bne	a5,a4,80004fbe <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ff6:	e4043603          	ld	a2,-448(s0)
    80004ffa:	e3843783          	ld	a5,-456(s0)
    80004ffe:	f8f669e3          	bltu	a2,a5,80004f90 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005002:	e2843783          	ld	a5,-472(s0)
    80005006:	963e                	add	a2,a2,a5
    80005008:	f8f667e3          	bltu	a2,a5,80004f96 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000500c:	85ca                	mv	a1,s2
    8000500e:	855e                	mv	a0,s7
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	412080e7          	jalr	1042(ra) # 80001422 <uvmalloc>
    80005018:	e0a43423          	sd	a0,-504(s0)
    8000501c:	d141                	beqz	a0,80004f9c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000501e:	e2843d03          	ld	s10,-472(s0)
    80005022:	df043783          	ld	a5,-528(s0)
    80005026:	00fd77b3          	and	a5,s10,a5
    8000502a:	fba1                	bnez	a5,80004f7a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000502c:	e2042d83          	lw	s11,-480(s0)
    80005030:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005034:	f80c03e3          	beqz	s8,80004fba <exec+0x306>
    80005038:	8a62                	mv	s4,s8
    8000503a:	4901                	li	s2,0
    8000503c:	b345                	j	80004ddc <exec+0x128>

000000008000503e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000503e:	7179                	addi	sp,sp,-48
    80005040:	f406                	sd	ra,40(sp)
    80005042:	f022                	sd	s0,32(sp)
    80005044:	ec26                	sd	s1,24(sp)
    80005046:	e84a                	sd	s2,16(sp)
    80005048:	1800                	addi	s0,sp,48
    8000504a:	892e                	mv	s2,a1
    8000504c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000504e:	fdc40593          	addi	a1,s0,-36
    80005052:	ffffe097          	auipc	ra,0xffffe
    80005056:	b8e080e7          	jalr	-1138(ra) # 80002be0 <argint>
    8000505a:	04054063          	bltz	a0,8000509a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000505e:	fdc42703          	lw	a4,-36(s0)
    80005062:	47bd                	li	a5,15
    80005064:	02e7ed63          	bltu	a5,a4,8000509e <argfd+0x60>
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	948080e7          	jalr	-1720(ra) # 800019b0 <myproc>
    80005070:	fdc42703          	lw	a4,-36(s0)
    80005074:	01a70793          	addi	a5,a4,26
    80005078:	078e                	slli	a5,a5,0x3
    8000507a:	953e                	add	a0,a0,a5
    8000507c:	611c                	ld	a5,0(a0)
    8000507e:	c395                	beqz	a5,800050a2 <argfd+0x64>
    return -1;
  if(pfd)
    80005080:	00090463          	beqz	s2,80005088 <argfd+0x4a>
    *pfd = fd;
    80005084:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005088:	4501                	li	a0,0
  if(pf)
    8000508a:	c091                	beqz	s1,8000508e <argfd+0x50>
    *pf = f;
    8000508c:	e09c                	sd	a5,0(s1)
}
    8000508e:	70a2                	ld	ra,40(sp)
    80005090:	7402                	ld	s0,32(sp)
    80005092:	64e2                	ld	s1,24(sp)
    80005094:	6942                	ld	s2,16(sp)
    80005096:	6145                	addi	sp,sp,48
    80005098:	8082                	ret
    return -1;
    8000509a:	557d                	li	a0,-1
    8000509c:	bfcd                	j	8000508e <argfd+0x50>
    return -1;
    8000509e:	557d                	li	a0,-1
    800050a0:	b7fd                	j	8000508e <argfd+0x50>
    800050a2:	557d                	li	a0,-1
    800050a4:	b7ed                	j	8000508e <argfd+0x50>

00000000800050a6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050a6:	1101                	addi	sp,sp,-32
    800050a8:	ec06                	sd	ra,24(sp)
    800050aa:	e822                	sd	s0,16(sp)
    800050ac:	e426                	sd	s1,8(sp)
    800050ae:	1000                	addi	s0,sp,32
    800050b0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050b2:	ffffd097          	auipc	ra,0xffffd
    800050b6:	8fe080e7          	jalr	-1794(ra) # 800019b0 <myproc>
    800050ba:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050bc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050c0:	4501                	li	a0,0
    800050c2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050c4:	6398                	ld	a4,0(a5)
    800050c6:	cb19                	beqz	a4,800050dc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050c8:	2505                	addiw	a0,a0,1
    800050ca:	07a1                	addi	a5,a5,8
    800050cc:	fed51ce3          	bne	a0,a3,800050c4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050d0:	557d                	li	a0,-1
}
    800050d2:	60e2                	ld	ra,24(sp)
    800050d4:	6442                	ld	s0,16(sp)
    800050d6:	64a2                	ld	s1,8(sp)
    800050d8:	6105                	addi	sp,sp,32
    800050da:	8082                	ret
      p->ofile[fd] = f;
    800050dc:	01a50793          	addi	a5,a0,26
    800050e0:	078e                	slli	a5,a5,0x3
    800050e2:	963e                	add	a2,a2,a5
    800050e4:	e204                	sd	s1,0(a2)
      return fd;
    800050e6:	b7f5                	j	800050d2 <fdalloc+0x2c>

00000000800050e8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050e8:	715d                	addi	sp,sp,-80
    800050ea:	e486                	sd	ra,72(sp)
    800050ec:	e0a2                	sd	s0,64(sp)
    800050ee:	fc26                	sd	s1,56(sp)
    800050f0:	f84a                	sd	s2,48(sp)
    800050f2:	f44e                	sd	s3,40(sp)
    800050f4:	f052                	sd	s4,32(sp)
    800050f6:	ec56                	sd	s5,24(sp)
    800050f8:	0880                	addi	s0,sp,80
    800050fa:	89ae                	mv	s3,a1
    800050fc:	8ab2                	mv	s5,a2
    800050fe:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005100:	fb040593          	addi	a1,s0,-80
    80005104:	fffff097          	auipc	ra,0xfffff
    80005108:	e86080e7          	jalr	-378(ra) # 80003f8a <nameiparent>
    8000510c:	892a                	mv	s2,a0
    8000510e:	12050f63          	beqz	a0,8000524c <create+0x164>
    return 0;

  ilock(dp);
    80005112:	ffffe097          	auipc	ra,0xffffe
    80005116:	6a4080e7          	jalr	1700(ra) # 800037b6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000511a:	4601                	li	a2,0
    8000511c:	fb040593          	addi	a1,s0,-80
    80005120:	854a                	mv	a0,s2
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	b78080e7          	jalr	-1160(ra) # 80003c9a <dirlookup>
    8000512a:	84aa                	mv	s1,a0
    8000512c:	c921                	beqz	a0,8000517c <create+0x94>
    iunlockput(dp);
    8000512e:	854a                	mv	a0,s2
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	8e8080e7          	jalr	-1816(ra) # 80003a18 <iunlockput>
    ilock(ip);
    80005138:	8526                	mv	a0,s1
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	67c080e7          	jalr	1660(ra) # 800037b6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005142:	2981                	sext.w	s3,s3
    80005144:	4789                	li	a5,2
    80005146:	02f99463          	bne	s3,a5,8000516e <create+0x86>
    8000514a:	0444d783          	lhu	a5,68(s1)
    8000514e:	37f9                	addiw	a5,a5,-2
    80005150:	17c2                	slli	a5,a5,0x30
    80005152:	93c1                	srli	a5,a5,0x30
    80005154:	4705                	li	a4,1
    80005156:	00f76c63          	bltu	a4,a5,8000516e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000515a:	8526                	mv	a0,s1
    8000515c:	60a6                	ld	ra,72(sp)
    8000515e:	6406                	ld	s0,64(sp)
    80005160:	74e2                	ld	s1,56(sp)
    80005162:	7942                	ld	s2,48(sp)
    80005164:	79a2                	ld	s3,40(sp)
    80005166:	7a02                	ld	s4,32(sp)
    80005168:	6ae2                	ld	s5,24(sp)
    8000516a:	6161                	addi	sp,sp,80
    8000516c:	8082                	ret
    iunlockput(ip);
    8000516e:	8526                	mv	a0,s1
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	8a8080e7          	jalr	-1880(ra) # 80003a18 <iunlockput>
    return 0;
    80005178:	4481                	li	s1,0
    8000517a:	b7c5                	j	8000515a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000517c:	85ce                	mv	a1,s3
    8000517e:	00092503          	lw	a0,0(s2)
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	49c080e7          	jalr	1180(ra) # 8000361e <ialloc>
    8000518a:	84aa                	mv	s1,a0
    8000518c:	c529                	beqz	a0,800051d6 <create+0xee>
  ilock(ip);
    8000518e:	ffffe097          	auipc	ra,0xffffe
    80005192:	628080e7          	jalr	1576(ra) # 800037b6 <ilock>
  ip->major = major;
    80005196:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000519a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000519e:	4785                	li	a5,1
    800051a0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051a4:	8526                	mv	a0,s1
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	546080e7          	jalr	1350(ra) # 800036ec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051ae:	2981                	sext.w	s3,s3
    800051b0:	4785                	li	a5,1
    800051b2:	02f98a63          	beq	s3,a5,800051e6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051b6:	40d0                	lw	a2,4(s1)
    800051b8:	fb040593          	addi	a1,s0,-80
    800051bc:	854a                	mv	a0,s2
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	cec080e7          	jalr	-788(ra) # 80003eaa <dirlink>
    800051c6:	06054b63          	bltz	a0,8000523c <create+0x154>
  iunlockput(dp);
    800051ca:	854a                	mv	a0,s2
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	84c080e7          	jalr	-1972(ra) # 80003a18 <iunlockput>
  return ip;
    800051d4:	b759                	j	8000515a <create+0x72>
    panic("create: ialloc");
    800051d6:	00003517          	auipc	a0,0x3
    800051da:	54250513          	addi	a0,a0,1346 # 80008718 <syscalls+0x2b8>
    800051de:	ffffb097          	auipc	ra,0xffffb
    800051e2:	360080e7          	jalr	864(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051e6:	04a95783          	lhu	a5,74(s2)
    800051ea:	2785                	addiw	a5,a5,1
    800051ec:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051f0:	854a                	mv	a0,s2
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	4fa080e7          	jalr	1274(ra) # 800036ec <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051fa:	40d0                	lw	a2,4(s1)
    800051fc:	00003597          	auipc	a1,0x3
    80005200:	52c58593          	addi	a1,a1,1324 # 80008728 <syscalls+0x2c8>
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	ca4080e7          	jalr	-860(ra) # 80003eaa <dirlink>
    8000520e:	00054f63          	bltz	a0,8000522c <create+0x144>
    80005212:	00492603          	lw	a2,4(s2)
    80005216:	00003597          	auipc	a1,0x3
    8000521a:	51a58593          	addi	a1,a1,1306 # 80008730 <syscalls+0x2d0>
    8000521e:	8526                	mv	a0,s1
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	c8a080e7          	jalr	-886(ra) # 80003eaa <dirlink>
    80005228:	f80557e3          	bgez	a0,800051b6 <create+0xce>
      panic("create dots");
    8000522c:	00003517          	auipc	a0,0x3
    80005230:	50c50513          	addi	a0,a0,1292 # 80008738 <syscalls+0x2d8>
    80005234:	ffffb097          	auipc	ra,0xffffb
    80005238:	30a080e7          	jalr	778(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000523c:	00003517          	auipc	a0,0x3
    80005240:	50c50513          	addi	a0,a0,1292 # 80008748 <syscalls+0x2e8>
    80005244:	ffffb097          	auipc	ra,0xffffb
    80005248:	2fa080e7          	jalr	762(ra) # 8000053e <panic>
    return 0;
    8000524c:	84aa                	mv	s1,a0
    8000524e:	b731                	j	8000515a <create+0x72>

0000000080005250 <sys_dup>:
{
    80005250:	7179                	addi	sp,sp,-48
    80005252:	f406                	sd	ra,40(sp)
    80005254:	f022                	sd	s0,32(sp)
    80005256:	ec26                	sd	s1,24(sp)
    80005258:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000525a:	fd840613          	addi	a2,s0,-40
    8000525e:	4581                	li	a1,0
    80005260:	4501                	li	a0,0
    80005262:	00000097          	auipc	ra,0x0
    80005266:	ddc080e7          	jalr	-548(ra) # 8000503e <argfd>
    return -1;
    8000526a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000526c:	02054363          	bltz	a0,80005292 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005270:	fd843503          	ld	a0,-40(s0)
    80005274:	00000097          	auipc	ra,0x0
    80005278:	e32080e7          	jalr	-462(ra) # 800050a6 <fdalloc>
    8000527c:	84aa                	mv	s1,a0
    return -1;
    8000527e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005280:	00054963          	bltz	a0,80005292 <sys_dup+0x42>
  filedup(f);
    80005284:	fd843503          	ld	a0,-40(s0)
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	37a080e7          	jalr	890(ra) # 80004602 <filedup>
  return fd;
    80005290:	87a6                	mv	a5,s1
}
    80005292:	853e                	mv	a0,a5
    80005294:	70a2                	ld	ra,40(sp)
    80005296:	7402                	ld	s0,32(sp)
    80005298:	64e2                	ld	s1,24(sp)
    8000529a:	6145                	addi	sp,sp,48
    8000529c:	8082                	ret

000000008000529e <sys_read>:
{
    8000529e:	7179                	addi	sp,sp,-48
    800052a0:	f406                	sd	ra,40(sp)
    800052a2:	f022                	sd	s0,32(sp)
    800052a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a6:	fe840613          	addi	a2,s0,-24
    800052aa:	4581                	li	a1,0
    800052ac:	4501                	li	a0,0
    800052ae:	00000097          	auipc	ra,0x0
    800052b2:	d90080e7          	jalr	-624(ra) # 8000503e <argfd>
    return -1;
    800052b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b8:	04054163          	bltz	a0,800052fa <sys_read+0x5c>
    800052bc:	fe440593          	addi	a1,s0,-28
    800052c0:	4509                	li	a0,2
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	91e080e7          	jalr	-1762(ra) # 80002be0 <argint>
    return -1;
    800052ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052cc:	02054763          	bltz	a0,800052fa <sys_read+0x5c>
    800052d0:	fd840593          	addi	a1,s0,-40
    800052d4:	4505                	li	a0,1
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	92c080e7          	jalr	-1748(ra) # 80002c02 <argaddr>
    return -1;
    800052de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e0:	00054d63          	bltz	a0,800052fa <sys_read+0x5c>
  return fileread(f, p, n);
    800052e4:	fe442603          	lw	a2,-28(s0)
    800052e8:	fd843583          	ld	a1,-40(s0)
    800052ec:	fe843503          	ld	a0,-24(s0)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	49e080e7          	jalr	1182(ra) # 8000478e <fileread>
    800052f8:	87aa                	mv	a5,a0
}
    800052fa:	853e                	mv	a0,a5
    800052fc:	70a2                	ld	ra,40(sp)
    800052fe:	7402                	ld	s0,32(sp)
    80005300:	6145                	addi	sp,sp,48
    80005302:	8082                	ret

0000000080005304 <sys_write>:
{
    80005304:	7179                	addi	sp,sp,-48
    80005306:	f406                	sd	ra,40(sp)
    80005308:	f022                	sd	s0,32(sp)
    8000530a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530c:	fe840613          	addi	a2,s0,-24
    80005310:	4581                	li	a1,0
    80005312:	4501                	li	a0,0
    80005314:	00000097          	auipc	ra,0x0
    80005318:	d2a080e7          	jalr	-726(ra) # 8000503e <argfd>
    return -1;
    8000531c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531e:	04054163          	bltz	a0,80005360 <sys_write+0x5c>
    80005322:	fe440593          	addi	a1,s0,-28
    80005326:	4509                	li	a0,2
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	8b8080e7          	jalr	-1864(ra) # 80002be0 <argint>
    return -1;
    80005330:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005332:	02054763          	bltz	a0,80005360 <sys_write+0x5c>
    80005336:	fd840593          	addi	a1,s0,-40
    8000533a:	4505                	li	a0,1
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	8c6080e7          	jalr	-1850(ra) # 80002c02 <argaddr>
    return -1;
    80005344:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005346:	00054d63          	bltz	a0,80005360 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000534a:	fe442603          	lw	a2,-28(s0)
    8000534e:	fd843583          	ld	a1,-40(s0)
    80005352:	fe843503          	ld	a0,-24(s0)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	4fa080e7          	jalr	1274(ra) # 80004850 <filewrite>
    8000535e:	87aa                	mv	a5,a0
}
    80005360:	853e                	mv	a0,a5
    80005362:	70a2                	ld	ra,40(sp)
    80005364:	7402                	ld	s0,32(sp)
    80005366:	6145                	addi	sp,sp,48
    80005368:	8082                	ret

000000008000536a <sys_close>:
{
    8000536a:	1101                	addi	sp,sp,-32
    8000536c:	ec06                	sd	ra,24(sp)
    8000536e:	e822                	sd	s0,16(sp)
    80005370:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005372:	fe040613          	addi	a2,s0,-32
    80005376:	fec40593          	addi	a1,s0,-20
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	cc2080e7          	jalr	-830(ra) # 8000503e <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005386:	02054463          	bltz	a0,800053ae <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	626080e7          	jalr	1574(ra) # 800019b0 <myproc>
    80005392:	fec42783          	lw	a5,-20(s0)
    80005396:	07e9                	addi	a5,a5,26
    80005398:	078e                	slli	a5,a5,0x3
    8000539a:	97aa                	add	a5,a5,a0
    8000539c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053a0:	fe043503          	ld	a0,-32(s0)
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	2b0080e7          	jalr	688(ra) # 80004654 <fileclose>
  return 0;
    800053ac:	4781                	li	a5,0
}
    800053ae:	853e                	mv	a0,a5
    800053b0:	60e2                	ld	ra,24(sp)
    800053b2:	6442                	ld	s0,16(sp)
    800053b4:	6105                	addi	sp,sp,32
    800053b6:	8082                	ret

00000000800053b8 <sys_fstat>:
{
    800053b8:	1101                	addi	sp,sp,-32
    800053ba:	ec06                	sd	ra,24(sp)
    800053bc:	e822                	sd	s0,16(sp)
    800053be:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c0:	fe840613          	addi	a2,s0,-24
    800053c4:	4581                	li	a1,0
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	c76080e7          	jalr	-906(ra) # 8000503e <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d2:	02054563          	bltz	a0,800053fc <sys_fstat+0x44>
    800053d6:	fe040593          	addi	a1,s0,-32
    800053da:	4505                	li	a0,1
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	826080e7          	jalr	-2010(ra) # 80002c02 <argaddr>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e6:	00054b63          	bltz	a0,800053fc <sys_fstat+0x44>
  return filestat(f, st);
    800053ea:	fe043583          	ld	a1,-32(s0)
    800053ee:	fe843503          	ld	a0,-24(s0)
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	32a080e7          	jalr	810(ra) # 8000471c <filestat>
    800053fa:	87aa                	mv	a5,a0
}
    800053fc:	853e                	mv	a0,a5
    800053fe:	60e2                	ld	ra,24(sp)
    80005400:	6442                	ld	s0,16(sp)
    80005402:	6105                	addi	sp,sp,32
    80005404:	8082                	ret

0000000080005406 <sys_link>:
{
    80005406:	7169                	addi	sp,sp,-304
    80005408:	f606                	sd	ra,296(sp)
    8000540a:	f222                	sd	s0,288(sp)
    8000540c:	ee26                	sd	s1,280(sp)
    8000540e:	ea4a                	sd	s2,272(sp)
    80005410:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005412:	08000613          	li	a2,128
    80005416:	ed040593          	addi	a1,s0,-304
    8000541a:	4501                	li	a0,0
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	808080e7          	jalr	-2040(ra) # 80002c24 <argstr>
    return -1;
    80005424:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005426:	10054e63          	bltz	a0,80005542 <sys_link+0x13c>
    8000542a:	08000613          	li	a2,128
    8000542e:	f5040593          	addi	a1,s0,-176
    80005432:	4505                	li	a0,1
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	7f0080e7          	jalr	2032(ra) # 80002c24 <argstr>
    return -1;
    8000543c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543e:	10054263          	bltz	a0,80005542 <sys_link+0x13c>
  begin_op();
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	d46080e7          	jalr	-698(ra) # 80004188 <begin_op>
  if((ip = namei(old)) == 0){
    8000544a:	ed040513          	addi	a0,s0,-304
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	b1e080e7          	jalr	-1250(ra) # 80003f6c <namei>
    80005456:	84aa                	mv	s1,a0
    80005458:	c551                	beqz	a0,800054e4 <sys_link+0xde>
  ilock(ip);
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	35c080e7          	jalr	860(ra) # 800037b6 <ilock>
  if(ip->type == T_DIR){
    80005462:	04449703          	lh	a4,68(s1)
    80005466:	4785                	li	a5,1
    80005468:	08f70463          	beq	a4,a5,800054f0 <sys_link+0xea>
  ip->nlink++;
    8000546c:	04a4d783          	lhu	a5,74(s1)
    80005470:	2785                	addiw	a5,a5,1
    80005472:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	274080e7          	jalr	628(ra) # 800036ec <iupdate>
  iunlock(ip);
    80005480:	8526                	mv	a0,s1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	3f6080e7          	jalr	1014(ra) # 80003878 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000548a:	fd040593          	addi	a1,s0,-48
    8000548e:	f5040513          	addi	a0,s0,-176
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	af8080e7          	jalr	-1288(ra) # 80003f8a <nameiparent>
    8000549a:	892a                	mv	s2,a0
    8000549c:	c935                	beqz	a0,80005510 <sys_link+0x10a>
  ilock(dp);
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	318080e7          	jalr	792(ra) # 800037b6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054a6:	00092703          	lw	a4,0(s2)
    800054aa:	409c                	lw	a5,0(s1)
    800054ac:	04f71d63          	bne	a4,a5,80005506 <sys_link+0x100>
    800054b0:	40d0                	lw	a2,4(s1)
    800054b2:	fd040593          	addi	a1,s0,-48
    800054b6:	854a                	mv	a0,s2
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	9f2080e7          	jalr	-1550(ra) # 80003eaa <dirlink>
    800054c0:	04054363          	bltz	a0,80005506 <sys_link+0x100>
  iunlockput(dp);
    800054c4:	854a                	mv	a0,s2
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	552080e7          	jalr	1362(ra) # 80003a18 <iunlockput>
  iput(ip);
    800054ce:	8526                	mv	a0,s1
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	4a0080e7          	jalr	1184(ra) # 80003970 <iput>
  end_op();
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	d30080e7          	jalr	-720(ra) # 80004208 <end_op>
  return 0;
    800054e0:	4781                	li	a5,0
    800054e2:	a085                	j	80005542 <sys_link+0x13c>
    end_op();
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	d24080e7          	jalr	-732(ra) # 80004208 <end_op>
    return -1;
    800054ec:	57fd                	li	a5,-1
    800054ee:	a891                	j	80005542 <sys_link+0x13c>
    iunlockput(ip);
    800054f0:	8526                	mv	a0,s1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	526080e7          	jalr	1318(ra) # 80003a18 <iunlockput>
    end_op();
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	d0e080e7          	jalr	-754(ra) # 80004208 <end_op>
    return -1;
    80005502:	57fd                	li	a5,-1
    80005504:	a83d                	j	80005542 <sys_link+0x13c>
    iunlockput(dp);
    80005506:	854a                	mv	a0,s2
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	510080e7          	jalr	1296(ra) # 80003a18 <iunlockput>
  ilock(ip);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	2a4080e7          	jalr	676(ra) # 800037b6 <ilock>
  ip->nlink--;
    8000551a:	04a4d783          	lhu	a5,74(s1)
    8000551e:	37fd                	addiw	a5,a5,-1
    80005520:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	1c6080e7          	jalr	454(ra) # 800036ec <iupdate>
  iunlockput(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	4e8080e7          	jalr	1256(ra) # 80003a18 <iunlockput>
  end_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	cd0080e7          	jalr	-816(ra) # 80004208 <end_op>
  return -1;
    80005540:	57fd                	li	a5,-1
}
    80005542:	853e                	mv	a0,a5
    80005544:	70b2                	ld	ra,296(sp)
    80005546:	7412                	ld	s0,288(sp)
    80005548:	64f2                	ld	s1,280(sp)
    8000554a:	6952                	ld	s2,272(sp)
    8000554c:	6155                	addi	sp,sp,304
    8000554e:	8082                	ret

0000000080005550 <sys_unlink>:
{
    80005550:	7151                	addi	sp,sp,-240
    80005552:	f586                	sd	ra,232(sp)
    80005554:	f1a2                	sd	s0,224(sp)
    80005556:	eda6                	sd	s1,216(sp)
    80005558:	e9ca                	sd	s2,208(sp)
    8000555a:	e5ce                	sd	s3,200(sp)
    8000555c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000555e:	08000613          	li	a2,128
    80005562:	f3040593          	addi	a1,s0,-208
    80005566:	4501                	li	a0,0
    80005568:	ffffd097          	auipc	ra,0xffffd
    8000556c:	6bc080e7          	jalr	1724(ra) # 80002c24 <argstr>
    80005570:	18054163          	bltz	a0,800056f2 <sys_unlink+0x1a2>
  begin_op();
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	c14080e7          	jalr	-1004(ra) # 80004188 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000557c:	fb040593          	addi	a1,s0,-80
    80005580:	f3040513          	addi	a0,s0,-208
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	a06080e7          	jalr	-1530(ra) # 80003f8a <nameiparent>
    8000558c:	84aa                	mv	s1,a0
    8000558e:	c979                	beqz	a0,80005664 <sys_unlink+0x114>
  ilock(dp);
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	226080e7          	jalr	550(ra) # 800037b6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005598:	00003597          	auipc	a1,0x3
    8000559c:	19058593          	addi	a1,a1,400 # 80008728 <syscalls+0x2c8>
    800055a0:	fb040513          	addi	a0,s0,-80
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	6dc080e7          	jalr	1756(ra) # 80003c80 <namecmp>
    800055ac:	14050a63          	beqz	a0,80005700 <sys_unlink+0x1b0>
    800055b0:	00003597          	auipc	a1,0x3
    800055b4:	18058593          	addi	a1,a1,384 # 80008730 <syscalls+0x2d0>
    800055b8:	fb040513          	addi	a0,s0,-80
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	6c4080e7          	jalr	1732(ra) # 80003c80 <namecmp>
    800055c4:	12050e63          	beqz	a0,80005700 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055c8:	f2c40613          	addi	a2,s0,-212
    800055cc:	fb040593          	addi	a1,s0,-80
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	6c8080e7          	jalr	1736(ra) # 80003c9a <dirlookup>
    800055da:	892a                	mv	s2,a0
    800055dc:	12050263          	beqz	a0,80005700 <sys_unlink+0x1b0>
  ilock(ip);
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	1d6080e7          	jalr	470(ra) # 800037b6 <ilock>
  if(ip->nlink < 1)
    800055e8:	04a91783          	lh	a5,74(s2)
    800055ec:	08f05263          	blez	a5,80005670 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f0:	04491703          	lh	a4,68(s2)
    800055f4:	4785                	li	a5,1
    800055f6:	08f70563          	beq	a4,a5,80005680 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055fa:	4641                	li	a2,16
    800055fc:	4581                	li	a1,0
    800055fe:	fc040513          	addi	a0,s0,-64
    80005602:	ffffb097          	auipc	ra,0xffffb
    80005606:	6de080e7          	jalr	1758(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000560a:	4741                	li	a4,16
    8000560c:	f2c42683          	lw	a3,-212(s0)
    80005610:	fc040613          	addi	a2,s0,-64
    80005614:	4581                	li	a1,0
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	54a080e7          	jalr	1354(ra) # 80003b62 <writei>
    80005620:	47c1                	li	a5,16
    80005622:	0af51563          	bne	a0,a5,800056cc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005626:	04491703          	lh	a4,68(s2)
    8000562a:	4785                	li	a5,1
    8000562c:	0af70863          	beq	a4,a5,800056dc <sys_unlink+0x18c>
  iunlockput(dp);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	3e6080e7          	jalr	998(ra) # 80003a18 <iunlockput>
  ip->nlink--;
    8000563a:	04a95783          	lhu	a5,74(s2)
    8000563e:	37fd                	addiw	a5,a5,-1
    80005640:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005644:	854a                	mv	a0,s2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	0a6080e7          	jalr	166(ra) # 800036ec <iupdate>
  iunlockput(ip);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	3c8080e7          	jalr	968(ra) # 80003a18 <iunlockput>
  end_op();
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	bb0080e7          	jalr	-1104(ra) # 80004208 <end_op>
  return 0;
    80005660:	4501                	li	a0,0
    80005662:	a84d                	j	80005714 <sys_unlink+0x1c4>
    end_op();
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	ba4080e7          	jalr	-1116(ra) # 80004208 <end_op>
    return -1;
    8000566c:	557d                	li	a0,-1
    8000566e:	a05d                	j	80005714 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005670:	00003517          	auipc	a0,0x3
    80005674:	0e850513          	addi	a0,a0,232 # 80008758 <syscalls+0x2f8>
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	ec6080e7          	jalr	-314(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005680:	04c92703          	lw	a4,76(s2)
    80005684:	02000793          	li	a5,32
    80005688:	f6e7f9e3          	bgeu	a5,a4,800055fa <sys_unlink+0xaa>
    8000568c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005690:	4741                	li	a4,16
    80005692:	86ce                	mv	a3,s3
    80005694:	f1840613          	addi	a2,s0,-232
    80005698:	4581                	li	a1,0
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	3ce080e7          	jalr	974(ra) # 80003a6a <readi>
    800056a4:	47c1                	li	a5,16
    800056a6:	00f51b63          	bne	a0,a5,800056bc <sys_unlink+0x16c>
    if(de.inum != 0)
    800056aa:	f1845783          	lhu	a5,-232(s0)
    800056ae:	e7a1                	bnez	a5,800056f6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b0:	29c1                	addiw	s3,s3,16
    800056b2:	04c92783          	lw	a5,76(s2)
    800056b6:	fcf9ede3          	bltu	s3,a5,80005690 <sys_unlink+0x140>
    800056ba:	b781                	j	800055fa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056bc:	00003517          	auipc	a0,0x3
    800056c0:	0b450513          	addi	a0,a0,180 # 80008770 <syscalls+0x310>
    800056c4:	ffffb097          	auipc	ra,0xffffb
    800056c8:	e7a080e7          	jalr	-390(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056cc:	00003517          	auipc	a0,0x3
    800056d0:	0bc50513          	addi	a0,a0,188 # 80008788 <syscalls+0x328>
    800056d4:	ffffb097          	auipc	ra,0xffffb
    800056d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>
    dp->nlink--;
    800056dc:	04a4d783          	lhu	a5,74(s1)
    800056e0:	37fd                	addiw	a5,a5,-1
    800056e2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056e6:	8526                	mv	a0,s1
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	004080e7          	jalr	4(ra) # 800036ec <iupdate>
    800056f0:	b781                	j	80005630 <sys_unlink+0xe0>
    return -1;
    800056f2:	557d                	li	a0,-1
    800056f4:	a005                	j	80005714 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056f6:	854a                	mv	a0,s2
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	320080e7          	jalr	800(ra) # 80003a18 <iunlockput>
  iunlockput(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	316080e7          	jalr	790(ra) # 80003a18 <iunlockput>
  end_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	afe080e7          	jalr	-1282(ra) # 80004208 <end_op>
  return -1;
    80005712:	557d                	li	a0,-1
}
    80005714:	70ae                	ld	ra,232(sp)
    80005716:	740e                	ld	s0,224(sp)
    80005718:	64ee                	ld	s1,216(sp)
    8000571a:	694e                	ld	s2,208(sp)
    8000571c:	69ae                	ld	s3,200(sp)
    8000571e:	616d                	addi	sp,sp,240
    80005720:	8082                	ret

0000000080005722 <sys_open>:

uint64
sys_open(void)
{
    80005722:	7131                	addi	sp,sp,-192
    80005724:	fd06                	sd	ra,184(sp)
    80005726:	f922                	sd	s0,176(sp)
    80005728:	f526                	sd	s1,168(sp)
    8000572a:	f14a                	sd	s2,160(sp)
    8000572c:	ed4e                	sd	s3,152(sp)
    8000572e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005730:	08000613          	li	a2,128
    80005734:	f5040593          	addi	a1,s0,-176
    80005738:	4501                	li	a0,0
    8000573a:	ffffd097          	auipc	ra,0xffffd
    8000573e:	4ea080e7          	jalr	1258(ra) # 80002c24 <argstr>
    return -1;
    80005742:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005744:	0c054163          	bltz	a0,80005806 <sys_open+0xe4>
    80005748:	f4c40593          	addi	a1,s0,-180
    8000574c:	4505                	li	a0,1
    8000574e:	ffffd097          	auipc	ra,0xffffd
    80005752:	492080e7          	jalr	1170(ra) # 80002be0 <argint>
    80005756:	0a054863          	bltz	a0,80005806 <sys_open+0xe4>

  begin_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	a2e080e7          	jalr	-1490(ra) # 80004188 <begin_op>

  if(omode & O_CREATE){
    80005762:	f4c42783          	lw	a5,-180(s0)
    80005766:	2007f793          	andi	a5,a5,512
    8000576a:	cbdd                	beqz	a5,80005820 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000576c:	4681                	li	a3,0
    8000576e:	4601                	li	a2,0
    80005770:	4589                	li	a1,2
    80005772:	f5040513          	addi	a0,s0,-176
    80005776:	00000097          	auipc	ra,0x0
    8000577a:	972080e7          	jalr	-1678(ra) # 800050e8 <create>
    8000577e:	892a                	mv	s2,a0
    if(ip == 0){
    80005780:	c959                	beqz	a0,80005816 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005782:	04491703          	lh	a4,68(s2)
    80005786:	478d                	li	a5,3
    80005788:	00f71763          	bne	a4,a5,80005796 <sys_open+0x74>
    8000578c:	04695703          	lhu	a4,70(s2)
    80005790:	47a5                	li	a5,9
    80005792:	0ce7ec63          	bltu	a5,a4,8000586a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	e02080e7          	jalr	-510(ra) # 80004598 <filealloc>
    8000579e:	89aa                	mv	s3,a0
    800057a0:	10050263          	beqz	a0,800058a4 <sys_open+0x182>
    800057a4:	00000097          	auipc	ra,0x0
    800057a8:	902080e7          	jalr	-1790(ra) # 800050a6 <fdalloc>
    800057ac:	84aa                	mv	s1,a0
    800057ae:	0e054663          	bltz	a0,8000589a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057b2:	04491703          	lh	a4,68(s2)
    800057b6:	478d                	li	a5,3
    800057b8:	0cf70463          	beq	a4,a5,80005880 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057bc:	4789                	li	a5,2
    800057be:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057c2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057c6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057ca:	f4c42783          	lw	a5,-180(s0)
    800057ce:	0017c713          	xori	a4,a5,1
    800057d2:	8b05                	andi	a4,a4,1
    800057d4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057d8:	0037f713          	andi	a4,a5,3
    800057dc:	00e03733          	snez	a4,a4
    800057e0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057e4:	4007f793          	andi	a5,a5,1024
    800057e8:	c791                	beqz	a5,800057f4 <sys_open+0xd2>
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	4789                	li	a5,2
    800057f0:	08f70f63          	beq	a4,a5,8000588e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057f4:	854a                	mv	a0,s2
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	082080e7          	jalr	130(ra) # 80003878 <iunlock>
  end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	a0a080e7          	jalr	-1526(ra) # 80004208 <end_op>

  return fd;
}
    80005806:	8526                	mv	a0,s1
    80005808:	70ea                	ld	ra,184(sp)
    8000580a:	744a                	ld	s0,176(sp)
    8000580c:	74aa                	ld	s1,168(sp)
    8000580e:	790a                	ld	s2,160(sp)
    80005810:	69ea                	ld	s3,152(sp)
    80005812:	6129                	addi	sp,sp,192
    80005814:	8082                	ret
      end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	9f2080e7          	jalr	-1550(ra) # 80004208 <end_op>
      return -1;
    8000581e:	b7e5                	j	80005806 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005820:	f5040513          	addi	a0,s0,-176
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	748080e7          	jalr	1864(ra) # 80003f6c <namei>
    8000582c:	892a                	mv	s2,a0
    8000582e:	c905                	beqz	a0,8000585e <sys_open+0x13c>
    ilock(ip);
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	f86080e7          	jalr	-122(ra) # 800037b6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005838:	04491703          	lh	a4,68(s2)
    8000583c:	4785                	li	a5,1
    8000583e:	f4f712e3          	bne	a4,a5,80005782 <sys_open+0x60>
    80005842:	f4c42783          	lw	a5,-180(s0)
    80005846:	dba1                	beqz	a5,80005796 <sys_open+0x74>
      iunlockput(ip);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	1ce080e7          	jalr	462(ra) # 80003a18 <iunlockput>
      end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	9b6080e7          	jalr	-1610(ra) # 80004208 <end_op>
      return -1;
    8000585a:	54fd                	li	s1,-1
    8000585c:	b76d                	j	80005806 <sys_open+0xe4>
      end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	9aa080e7          	jalr	-1622(ra) # 80004208 <end_op>
      return -1;
    80005866:	54fd                	li	s1,-1
    80005868:	bf79                	j	80005806 <sys_open+0xe4>
    iunlockput(ip);
    8000586a:	854a                	mv	a0,s2
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	1ac080e7          	jalr	428(ra) # 80003a18 <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	994080e7          	jalr	-1644(ra) # 80004208 <end_op>
    return -1;
    8000587c:	54fd                	li	s1,-1
    8000587e:	b761                	j	80005806 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005880:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005884:	04691783          	lh	a5,70(s2)
    80005888:	02f99223          	sh	a5,36(s3)
    8000588c:	bf2d                	j	800057c6 <sys_open+0xa4>
    itrunc(ip);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	034080e7          	jalr	52(ra) # 800038c4 <itrunc>
    80005898:	bfb1                	j	800057f4 <sys_open+0xd2>
      fileclose(f);
    8000589a:	854e                	mv	a0,s3
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	db8080e7          	jalr	-584(ra) # 80004654 <fileclose>
    iunlockput(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	172080e7          	jalr	370(ra) # 80003a18 <iunlockput>
    end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	95a080e7          	jalr	-1702(ra) # 80004208 <end_op>
    return -1;
    800058b6:	54fd                	li	s1,-1
    800058b8:	b7b9                	j	80005806 <sys_open+0xe4>

00000000800058ba <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058ba:	7175                	addi	sp,sp,-144
    800058bc:	e506                	sd	ra,136(sp)
    800058be:	e122                	sd	s0,128(sp)
    800058c0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	8c6080e7          	jalr	-1850(ra) # 80004188 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058ca:	08000613          	li	a2,128
    800058ce:	f7040593          	addi	a1,s0,-144
    800058d2:	4501                	li	a0,0
    800058d4:	ffffd097          	auipc	ra,0xffffd
    800058d8:	350080e7          	jalr	848(ra) # 80002c24 <argstr>
    800058dc:	02054963          	bltz	a0,8000590e <sys_mkdir+0x54>
    800058e0:	4681                	li	a3,0
    800058e2:	4601                	li	a2,0
    800058e4:	4585                	li	a1,1
    800058e6:	f7040513          	addi	a0,s0,-144
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	7fe080e7          	jalr	2046(ra) # 800050e8 <create>
    800058f2:	cd11                	beqz	a0,8000590e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	124080e7          	jalr	292(ra) # 80003a18 <iunlockput>
  end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	90c080e7          	jalr	-1780(ra) # 80004208 <end_op>
  return 0;
    80005904:	4501                	li	a0,0
}
    80005906:	60aa                	ld	ra,136(sp)
    80005908:	640a                	ld	s0,128(sp)
    8000590a:	6149                	addi	sp,sp,144
    8000590c:	8082                	ret
    end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	8fa080e7          	jalr	-1798(ra) # 80004208 <end_op>
    return -1;
    80005916:	557d                	li	a0,-1
    80005918:	b7fd                	j	80005906 <sys_mkdir+0x4c>

000000008000591a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000591a:	7135                	addi	sp,sp,-160
    8000591c:	ed06                	sd	ra,152(sp)
    8000591e:	e922                	sd	s0,144(sp)
    80005920:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	866080e7          	jalr	-1946(ra) # 80004188 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000592a:	08000613          	li	a2,128
    8000592e:	f7040593          	addi	a1,s0,-144
    80005932:	4501                	li	a0,0
    80005934:	ffffd097          	auipc	ra,0xffffd
    80005938:	2f0080e7          	jalr	752(ra) # 80002c24 <argstr>
    8000593c:	04054a63          	bltz	a0,80005990 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005940:	f6c40593          	addi	a1,s0,-148
    80005944:	4505                	li	a0,1
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	29a080e7          	jalr	666(ra) # 80002be0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594e:	04054163          	bltz	a0,80005990 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005952:	f6840593          	addi	a1,s0,-152
    80005956:	4509                	li	a0,2
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	288080e7          	jalr	648(ra) # 80002be0 <argint>
     argint(1, &major) < 0 ||
    80005960:	02054863          	bltz	a0,80005990 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005964:	f6841683          	lh	a3,-152(s0)
    80005968:	f6c41603          	lh	a2,-148(s0)
    8000596c:	458d                	li	a1,3
    8000596e:	f7040513          	addi	a0,s0,-144
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	776080e7          	jalr	1910(ra) # 800050e8 <create>
     argint(2, &minor) < 0 ||
    8000597a:	c919                	beqz	a0,80005990 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	09c080e7          	jalr	156(ra) # 80003a18 <iunlockput>
  end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	884080e7          	jalr	-1916(ra) # 80004208 <end_op>
  return 0;
    8000598c:	4501                	li	a0,0
    8000598e:	a031                	j	8000599a <sys_mknod+0x80>
    end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	878080e7          	jalr	-1928(ra) # 80004208 <end_op>
    return -1;
    80005998:	557d                	li	a0,-1
}
    8000599a:	60ea                	ld	ra,152(sp)
    8000599c:	644a                	ld	s0,144(sp)
    8000599e:	610d                	addi	sp,sp,160
    800059a0:	8082                	ret

00000000800059a2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a2:	7135                	addi	sp,sp,-160
    800059a4:	ed06                	sd	ra,152(sp)
    800059a6:	e922                	sd	s0,144(sp)
    800059a8:	e526                	sd	s1,136(sp)
    800059aa:	e14a                	sd	s2,128(sp)
    800059ac:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059ae:	ffffc097          	auipc	ra,0xffffc
    800059b2:	002080e7          	jalr	2(ra) # 800019b0 <myproc>
    800059b6:	892a                	mv	s2,a0
  
  begin_op();
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	7d0080e7          	jalr	2000(ra) # 80004188 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c0:	08000613          	li	a2,128
    800059c4:	f6040593          	addi	a1,s0,-160
    800059c8:	4501                	li	a0,0
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	25a080e7          	jalr	602(ra) # 80002c24 <argstr>
    800059d2:	04054b63          	bltz	a0,80005a28 <sys_chdir+0x86>
    800059d6:	f6040513          	addi	a0,s0,-160
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	592080e7          	jalr	1426(ra) # 80003f6c <namei>
    800059e2:	84aa                	mv	s1,a0
    800059e4:	c131                	beqz	a0,80005a28 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	dd0080e7          	jalr	-560(ra) # 800037b6 <ilock>
  if(ip->type != T_DIR){
    800059ee:	04449703          	lh	a4,68(s1)
    800059f2:	4785                	li	a5,1
    800059f4:	04f71063          	bne	a4,a5,80005a34 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	e7e080e7          	jalr	-386(ra) # 80003878 <iunlock>
  iput(p->cwd);
    80005a02:	15093503          	ld	a0,336(s2)
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	f6a080e7          	jalr	-150(ra) # 80003970 <iput>
  end_op();
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	7fa080e7          	jalr	2042(ra) # 80004208 <end_op>
  p->cwd = ip;
    80005a16:	14993823          	sd	s1,336(s2)
  return 0;
    80005a1a:	4501                	li	a0,0
}
    80005a1c:	60ea                	ld	ra,152(sp)
    80005a1e:	644a                	ld	s0,144(sp)
    80005a20:	64aa                	ld	s1,136(sp)
    80005a22:	690a                	ld	s2,128(sp)
    80005a24:	610d                	addi	sp,sp,160
    80005a26:	8082                	ret
    end_op();
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	7e0080e7          	jalr	2016(ra) # 80004208 <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	b7ed                	j	80005a1c <sys_chdir+0x7a>
    iunlockput(ip);
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	fe2080e7          	jalr	-30(ra) # 80003a18 <iunlockput>
    end_op();
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	7ca080e7          	jalr	1994(ra) # 80004208 <end_op>
    return -1;
    80005a46:	557d                	li	a0,-1
    80005a48:	bfd1                	j	80005a1c <sys_chdir+0x7a>

0000000080005a4a <sys_exec>:

uint64
sys_exec(void)
{
    80005a4a:	7145                	addi	sp,sp,-464
    80005a4c:	e786                	sd	ra,456(sp)
    80005a4e:	e3a2                	sd	s0,448(sp)
    80005a50:	ff26                	sd	s1,440(sp)
    80005a52:	fb4a                	sd	s2,432(sp)
    80005a54:	f74e                	sd	s3,424(sp)
    80005a56:	f352                	sd	s4,416(sp)
    80005a58:	ef56                	sd	s5,408(sp)
    80005a5a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a5c:	08000613          	li	a2,128
    80005a60:	f4040593          	addi	a1,s0,-192
    80005a64:	4501                	li	a0,0
    80005a66:	ffffd097          	auipc	ra,0xffffd
    80005a6a:	1be080e7          	jalr	446(ra) # 80002c24 <argstr>
    return -1;
    80005a6e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a70:	0c054a63          	bltz	a0,80005b44 <sys_exec+0xfa>
    80005a74:	e3840593          	addi	a1,s0,-456
    80005a78:	4505                	li	a0,1
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	188080e7          	jalr	392(ra) # 80002c02 <argaddr>
    80005a82:	0c054163          	bltz	a0,80005b44 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a86:	10000613          	li	a2,256
    80005a8a:	4581                	li	a1,0
    80005a8c:	e4040513          	addi	a0,s0,-448
    80005a90:	ffffb097          	auipc	ra,0xffffb
    80005a94:	250080e7          	jalr	592(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a98:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a9c:	89a6                	mv	s3,s1
    80005a9e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa0:	02000a13          	li	s4,32
    80005aa4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aa8:	00391513          	slli	a0,s2,0x3
    80005aac:	e3040593          	addi	a1,s0,-464
    80005ab0:	e3843783          	ld	a5,-456(s0)
    80005ab4:	953e                	add	a0,a0,a5
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	090080e7          	jalr	144(ra) # 80002b46 <fetchaddr>
    80005abe:	02054a63          	bltz	a0,80005af2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ac2:	e3043783          	ld	a5,-464(s0)
    80005ac6:	c3b9                	beqz	a5,80005b0c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	02c080e7          	jalr	44(ra) # 80000af4 <kalloc>
    80005ad0:	85aa                	mv	a1,a0
    80005ad2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad6:	cd11                	beqz	a0,80005af2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ad8:	6605                	lui	a2,0x1
    80005ada:	e3043503          	ld	a0,-464(s0)
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	0ba080e7          	jalr	186(ra) # 80002b98 <fetchstr>
    80005ae6:	00054663          	bltz	a0,80005af2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005aea:	0905                	addi	s2,s2,1
    80005aec:	09a1                	addi	s3,s3,8
    80005aee:	fb491be3          	bne	s2,s4,80005aa4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af2:	10048913          	addi	s2,s1,256
    80005af6:	6088                	ld	a0,0(s1)
    80005af8:	c529                	beqz	a0,80005b42 <sys_exec+0xf8>
    kfree(argv[i]);
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	efe080e7          	jalr	-258(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b02:	04a1                	addi	s1,s1,8
    80005b04:	ff2499e3          	bne	s1,s2,80005af6 <sys_exec+0xac>
  return -1;
    80005b08:	597d                	li	s2,-1
    80005b0a:	a82d                	j	80005b44 <sys_exec+0xfa>
      argv[i] = 0;
    80005b0c:	0a8e                	slli	s5,s5,0x3
    80005b0e:	fc040793          	addi	a5,s0,-64
    80005b12:	9abe                	add	s5,s5,a5
    80005b14:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b18:	e4040593          	addi	a1,s0,-448
    80005b1c:	f4040513          	addi	a0,s0,-192
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	194080e7          	jalr	404(ra) # 80004cb4 <exec>
    80005b28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2a:	10048993          	addi	s3,s1,256
    80005b2e:	6088                	ld	a0,0(s1)
    80005b30:	c911                	beqz	a0,80005b44 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	ec6080e7          	jalr	-314(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3a:	04a1                	addi	s1,s1,8
    80005b3c:	ff3499e3          	bne	s1,s3,80005b2e <sys_exec+0xe4>
    80005b40:	a011                	j	80005b44 <sys_exec+0xfa>
  return -1;
    80005b42:	597d                	li	s2,-1
}
    80005b44:	854a                	mv	a0,s2
    80005b46:	60be                	ld	ra,456(sp)
    80005b48:	641e                	ld	s0,448(sp)
    80005b4a:	74fa                	ld	s1,440(sp)
    80005b4c:	795a                	ld	s2,432(sp)
    80005b4e:	79ba                	ld	s3,424(sp)
    80005b50:	7a1a                	ld	s4,416(sp)
    80005b52:	6afa                	ld	s5,408(sp)
    80005b54:	6179                	addi	sp,sp,464
    80005b56:	8082                	ret

0000000080005b58 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b58:	7139                	addi	sp,sp,-64
    80005b5a:	fc06                	sd	ra,56(sp)
    80005b5c:	f822                	sd	s0,48(sp)
    80005b5e:	f426                	sd	s1,40(sp)
    80005b60:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	e4e080e7          	jalr	-434(ra) # 800019b0 <myproc>
    80005b6a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b6c:	fd840593          	addi	a1,s0,-40
    80005b70:	4501                	li	a0,0
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	090080e7          	jalr	144(ra) # 80002c02 <argaddr>
    return -1;
    80005b7a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b7c:	0e054063          	bltz	a0,80005c5c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b80:	fc840593          	addi	a1,s0,-56
    80005b84:	fd040513          	addi	a0,s0,-48
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	dfc080e7          	jalr	-516(ra) # 80004984 <pipealloc>
    return -1;
    80005b90:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b92:	0c054563          	bltz	a0,80005c5c <sys_pipe+0x104>
  fd0 = -1;
    80005b96:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b9a:	fd043503          	ld	a0,-48(s0)
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	508080e7          	jalr	1288(ra) # 800050a6 <fdalloc>
    80005ba6:	fca42223          	sw	a0,-60(s0)
    80005baa:	08054c63          	bltz	a0,80005c42 <sys_pipe+0xea>
    80005bae:	fc843503          	ld	a0,-56(s0)
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	4f4080e7          	jalr	1268(ra) # 800050a6 <fdalloc>
    80005bba:	fca42023          	sw	a0,-64(s0)
    80005bbe:	06054863          	bltz	a0,80005c2e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc2:	4691                	li	a3,4
    80005bc4:	fc440613          	addi	a2,s0,-60
    80005bc8:	fd843583          	ld	a1,-40(s0)
    80005bcc:	68a8                	ld	a0,80(s1)
    80005bce:	ffffc097          	auipc	ra,0xffffc
    80005bd2:	aa4080e7          	jalr	-1372(ra) # 80001672 <copyout>
    80005bd6:	02054063          	bltz	a0,80005bf6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bda:	4691                	li	a3,4
    80005bdc:	fc040613          	addi	a2,s0,-64
    80005be0:	fd843583          	ld	a1,-40(s0)
    80005be4:	0591                	addi	a1,a1,4
    80005be6:	68a8                	ld	a0,80(s1)
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	a8a080e7          	jalr	-1398(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bf0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf2:	06055563          	bgez	a0,80005c5c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bf6:	fc442783          	lw	a5,-60(s0)
    80005bfa:	07e9                	addi	a5,a5,26
    80005bfc:	078e                	slli	a5,a5,0x3
    80005bfe:	97a6                	add	a5,a5,s1
    80005c00:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c04:	fc042503          	lw	a0,-64(s0)
    80005c08:	0569                	addi	a0,a0,26
    80005c0a:	050e                	slli	a0,a0,0x3
    80005c0c:	9526                	add	a0,a0,s1
    80005c0e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c12:	fd043503          	ld	a0,-48(s0)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	a3e080e7          	jalr	-1474(ra) # 80004654 <fileclose>
    fileclose(wf);
    80005c1e:	fc843503          	ld	a0,-56(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	a32080e7          	jalr	-1486(ra) # 80004654 <fileclose>
    return -1;
    80005c2a:	57fd                	li	a5,-1
    80005c2c:	a805                	j	80005c5c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c2e:	fc442783          	lw	a5,-60(s0)
    80005c32:	0007c863          	bltz	a5,80005c42 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c36:	01a78513          	addi	a0,a5,26
    80005c3a:	050e                	slli	a0,a0,0x3
    80005c3c:	9526                	add	a0,a0,s1
    80005c3e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c42:	fd043503          	ld	a0,-48(s0)
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	a0e080e7          	jalr	-1522(ra) # 80004654 <fileclose>
    fileclose(wf);
    80005c4e:	fc843503          	ld	a0,-56(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	a02080e7          	jalr	-1534(ra) # 80004654 <fileclose>
    return -1;
    80005c5a:	57fd                	li	a5,-1
}
    80005c5c:	853e                	mv	a0,a5
    80005c5e:	70e2                	ld	ra,56(sp)
    80005c60:	7442                	ld	s0,48(sp)
    80005c62:	74a2                	ld	s1,40(sp)
    80005c64:	6121                	addi	sp,sp,64
    80005c66:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	d63fc0ef          	jal	ra,80002a12 <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	6d0c                	ld	a1,24(a0)
    80005d0c:	7110                	ld	a2,32(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c3c080e7          	jalr	-964(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	c04080e7          	jalr	-1020(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	bdc080e7          	jalr	-1060(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	06a7c963          	blt	a5,a0,80005e42 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005dd4:	0001d797          	auipc	a5,0x1d
    80005dd8:	22c78793          	addi	a5,a5,556 # 80023000 <disk>
    80005ddc:	00a78733          	add	a4,a5,a0
    80005de0:	6789                	lui	a5,0x2
    80005de2:	97ba                	add	a5,a5,a4
    80005de4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de8:	e7ad                	bnez	a5,80005e52 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dea:	00451793          	slli	a5,a0,0x4
    80005dee:	0001f717          	auipc	a4,0x1f
    80005df2:	21270713          	addi	a4,a4,530 # 80025000 <disk+0x2000>
    80005df6:	6314                	ld	a3,0(a4)
    80005df8:	96be                	add	a3,a3,a5
    80005dfa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dfe:	6314                	ld	a3,0(a4)
    80005e00:	96be                	add	a3,a3,a5
    80005e02:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e06:	6314                	ld	a3,0(a4)
    80005e08:	96be                	add	a3,a3,a5
    80005e0a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e0e:	6318                	ld	a4,0(a4)
    80005e10:	97ba                	add	a5,a5,a4
    80005e12:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e16:	0001d797          	auipc	a5,0x1d
    80005e1a:	1ea78793          	addi	a5,a5,490 # 80023000 <disk>
    80005e1e:	97aa                	add	a5,a5,a0
    80005e20:	6509                	lui	a0,0x2
    80005e22:	953e                	add	a0,a0,a5
    80005e24:	4785                	li	a5,1
    80005e26:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e2a:	0001f517          	auipc	a0,0x1f
    80005e2e:	1ee50513          	addi	a0,a0,494 # 80025018 <disk+0x2018>
    80005e32:	ffffc097          	auipc	ra,0xffffc
    80005e36:	442080e7          	jalr	1090(ra) # 80002274 <wakeup>
}
    80005e3a:	60a2                	ld	ra,8(sp)
    80005e3c:	6402                	ld	s0,0(sp)
    80005e3e:	0141                	addi	sp,sp,16
    80005e40:	8082                	ret
    panic("free_desc 1");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	95650513          	addi	a0,a0,-1706 # 80008798 <syscalls+0x338>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	95650513          	addi	a0,a0,-1706 # 800087a8 <syscalls+0x348>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6e4080e7          	jalr	1764(ra) # 8000053e <panic>

0000000080005e62 <virtio_disk_init>:
{
    80005e62:	1101                	addi	sp,sp,-32
    80005e64:	ec06                	sd	ra,24(sp)
    80005e66:	e822                	sd	s0,16(sp)
    80005e68:	e426                	sd	s1,8(sp)
    80005e6a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e6c:	00003597          	auipc	a1,0x3
    80005e70:	94c58593          	addi	a1,a1,-1716 # 800087b8 <syscalls+0x358>
    80005e74:	0001f517          	auipc	a0,0x1f
    80005e78:	2b450513          	addi	a0,a0,692 # 80025128 <disk+0x2128>
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	cd8080e7          	jalr	-808(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e84:	100017b7          	lui	a5,0x10001
    80005e88:	4398                	lw	a4,0(a5)
    80005e8a:	2701                	sext.w	a4,a4
    80005e8c:	747277b7          	lui	a5,0x74727
    80005e90:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e94:	0ef71163          	bne	a4,a5,80005f76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e98:	100017b7          	lui	a5,0x10001
    80005e9c:	43dc                	lw	a5,4(a5)
    80005e9e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ea0:	4705                	li	a4,1
    80005ea2:	0ce79a63          	bne	a5,a4,80005f76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea6:	100017b7          	lui	a5,0x10001
    80005eaa:	479c                	lw	a5,8(a5)
    80005eac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eae:	4709                	li	a4,2
    80005eb0:	0ce79363          	bne	a5,a4,80005f76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eb4:	100017b7          	lui	a5,0x10001
    80005eb8:	47d8                	lw	a4,12(a5)
    80005eba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ebc:	554d47b7          	lui	a5,0x554d4
    80005ec0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005ec4:	0af71963          	bne	a4,a5,80005f76 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec8:	100017b7          	lui	a5,0x10001
    80005ecc:	4705                	li	a4,1
    80005ece:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed0:	470d                	li	a4,3
    80005ed2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ed4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ed6:	c7ffe737          	lui	a4,0xc7ffe
    80005eda:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ede:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ee0:	2701                	sext.w	a4,a4
    80005ee2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee4:	472d                	li	a4,11
    80005ee6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee8:	473d                	li	a4,15
    80005eea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005eec:	6705                	lui	a4,0x1
    80005eee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ef0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ef4:	5bdc                	lw	a5,52(a5)
    80005ef6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ef8:	c7d9                	beqz	a5,80005f86 <virtio_disk_init+0x124>
  if(max < NUM)
    80005efa:	471d                	li	a4,7
    80005efc:	08f77d63          	bgeu	a4,a5,80005f96 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f00:	100014b7          	lui	s1,0x10001
    80005f04:	47a1                	li	a5,8
    80005f06:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f08:	6609                	lui	a2,0x2
    80005f0a:	4581                	li	a1,0
    80005f0c:	0001d517          	auipc	a0,0x1d
    80005f10:	0f450513          	addi	a0,a0,244 # 80023000 <disk>
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	dcc080e7          	jalr	-564(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f1c:	0001d717          	auipc	a4,0x1d
    80005f20:	0e470713          	addi	a4,a4,228 # 80023000 <disk>
    80005f24:	00c75793          	srli	a5,a4,0xc
    80005f28:	2781                	sext.w	a5,a5
    80005f2a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f2c:	0001f797          	auipc	a5,0x1f
    80005f30:	0d478793          	addi	a5,a5,212 # 80025000 <disk+0x2000>
    80005f34:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f36:	0001d717          	auipc	a4,0x1d
    80005f3a:	14a70713          	addi	a4,a4,330 # 80023080 <disk+0x80>
    80005f3e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f40:	0001e717          	auipc	a4,0x1e
    80005f44:	0c070713          	addi	a4,a4,192 # 80024000 <disk+0x1000>
    80005f48:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f4a:	4705                	li	a4,1
    80005f4c:	00e78c23          	sb	a4,24(a5)
    80005f50:	00e78ca3          	sb	a4,25(a5)
    80005f54:	00e78d23          	sb	a4,26(a5)
    80005f58:	00e78da3          	sb	a4,27(a5)
    80005f5c:	00e78e23          	sb	a4,28(a5)
    80005f60:	00e78ea3          	sb	a4,29(a5)
    80005f64:	00e78f23          	sb	a4,30(a5)
    80005f68:	00e78fa3          	sb	a4,31(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret
    panic("could not find virtio disk");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	85250513          	addi	a0,a0,-1966 # 800087c8 <syscalls+0x368>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	86250513          	addi	a0,a0,-1950 # 800087e8 <syscalls+0x388>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f96:	00003517          	auipc	a0,0x3
    80005f9a:	87250513          	addi	a0,a0,-1934 # 80008808 <syscalls+0x3a8>
    80005f9e:	ffffa097          	auipc	ra,0xffffa
    80005fa2:	5a0080e7          	jalr	1440(ra) # 8000053e <panic>

0000000080005fa6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fa6:	7159                	addi	sp,sp,-112
    80005fa8:	f486                	sd	ra,104(sp)
    80005faa:	f0a2                	sd	s0,96(sp)
    80005fac:	eca6                	sd	s1,88(sp)
    80005fae:	e8ca                	sd	s2,80(sp)
    80005fb0:	e4ce                	sd	s3,72(sp)
    80005fb2:	e0d2                	sd	s4,64(sp)
    80005fb4:	fc56                	sd	s5,56(sp)
    80005fb6:	f85a                	sd	s6,48(sp)
    80005fb8:	f45e                	sd	s7,40(sp)
    80005fba:	f062                	sd	s8,32(sp)
    80005fbc:	ec66                	sd	s9,24(sp)
    80005fbe:	e86a                	sd	s10,16(sp)
    80005fc0:	1880                	addi	s0,sp,112
    80005fc2:	892a                	mv	s2,a0
    80005fc4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fc6:	00c52c83          	lw	s9,12(a0)
    80005fca:	001c9c9b          	slliw	s9,s9,0x1
    80005fce:	1c82                	slli	s9,s9,0x20
    80005fd0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fd4:	0001f517          	auipc	a0,0x1f
    80005fd8:	15450513          	addi	a0,a0,340 # 80025128 <disk+0x2128>
    80005fdc:	ffffb097          	auipc	ra,0xffffb
    80005fe0:	c08080e7          	jalr	-1016(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005fe4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fe6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fe8:	0001db97          	auipc	s7,0x1d
    80005fec:	018b8b93          	addi	s7,s7,24 # 80023000 <disk>
    80005ff0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ff2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005ff4:	8a4e                	mv	s4,s3
    80005ff6:	a051                	j	8000607a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ff8:	00fb86b3          	add	a3,s7,a5
    80005ffc:	96da                	add	a3,a3,s6
    80005ffe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006002:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006004:	0207c563          	bltz	a5,8000602e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006008:	2485                	addiw	s1,s1,1
    8000600a:	0711                	addi	a4,a4,4
    8000600c:	25548063          	beq	s1,s5,8000624c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006010:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006012:	0001f697          	auipc	a3,0x1f
    80006016:	00668693          	addi	a3,a3,6 # 80025018 <disk+0x2018>
    8000601a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000601c:	0006c583          	lbu	a1,0(a3)
    80006020:	fde1                	bnez	a1,80005ff8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006022:	2785                	addiw	a5,a5,1
    80006024:	0685                	addi	a3,a3,1
    80006026:	ff879be3          	bne	a5,s8,8000601c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000602a:	57fd                	li	a5,-1
    8000602c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000602e:	02905a63          	blez	s1,80006062 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006032:	f9042503          	lw	a0,-112(s0)
    80006036:	00000097          	auipc	ra,0x0
    8000603a:	d90080e7          	jalr	-624(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    8000603e:	4785                	li	a5,1
    80006040:	0297d163          	bge	a5,s1,80006062 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006044:	f9442503          	lw	a0,-108(s0)
    80006048:	00000097          	auipc	ra,0x0
    8000604c:	d7e080e7          	jalr	-642(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006050:	4789                	li	a5,2
    80006052:	0097d863          	bge	a5,s1,80006062 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006056:	f9842503          	lw	a0,-104(s0)
    8000605a:	00000097          	auipc	ra,0x0
    8000605e:	d6c080e7          	jalr	-660(ra) # 80005dc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006062:	0001f597          	auipc	a1,0x1f
    80006066:	0c658593          	addi	a1,a1,198 # 80025128 <disk+0x2128>
    8000606a:	0001f517          	auipc	a0,0x1f
    8000606e:	fae50513          	addi	a0,a0,-82 # 80025018 <disk+0x2018>
    80006072:	ffffc097          	auipc	ra,0xffffc
    80006076:	076080e7          	jalr	118(ra) # 800020e8 <sleep>
  for(int i = 0; i < 3; i++){
    8000607a:	f9040713          	addi	a4,s0,-112
    8000607e:	84ce                	mv	s1,s3
    80006080:	bf41                	j	80006010 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006082:	20058713          	addi	a4,a1,512
    80006086:	00471693          	slli	a3,a4,0x4
    8000608a:	0001d717          	auipc	a4,0x1d
    8000608e:	f7670713          	addi	a4,a4,-138 # 80023000 <disk>
    80006092:	9736                	add	a4,a4,a3
    80006094:	4685                	li	a3,1
    80006096:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000609a:	20058713          	addi	a4,a1,512
    8000609e:	00471693          	slli	a3,a4,0x4
    800060a2:	0001d717          	auipc	a4,0x1d
    800060a6:	f5e70713          	addi	a4,a4,-162 # 80023000 <disk>
    800060aa:	9736                	add	a4,a4,a3
    800060ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060b4:	7679                	lui	a2,0xffffe
    800060b6:	963e                	add	a2,a2,a5
    800060b8:	0001f697          	auipc	a3,0x1f
    800060bc:	f4868693          	addi	a3,a3,-184 # 80025000 <disk+0x2000>
    800060c0:	6298                	ld	a4,0(a3)
    800060c2:	9732                	add	a4,a4,a2
    800060c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060c6:	6298                	ld	a4,0(a3)
    800060c8:	9732                	add	a4,a4,a2
    800060ca:	4541                	li	a0,16
    800060cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060ce:	6298                	ld	a4,0(a3)
    800060d0:	9732                	add	a4,a4,a2
    800060d2:	4505                	li	a0,1
    800060d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060d8:	f9442703          	lw	a4,-108(s0)
    800060dc:	6288                	ld	a0,0(a3)
    800060de:	962a                	add	a2,a2,a0
    800060e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060e4:	0712                	slli	a4,a4,0x4
    800060e6:	6290                	ld	a2,0(a3)
    800060e8:	963a                	add	a2,a2,a4
    800060ea:	05890513          	addi	a0,s2,88
    800060ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060f0:	6294                	ld	a3,0(a3)
    800060f2:	96ba                	add	a3,a3,a4
    800060f4:	40000613          	li	a2,1024
    800060f8:	c690                	sw	a2,8(a3)
  if(write)
    800060fa:	140d0063          	beqz	s10,8000623a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060fe:	0001f697          	auipc	a3,0x1f
    80006102:	f026b683          	ld	a3,-254(a3) # 80025000 <disk+0x2000>
    80006106:	96ba                	add	a3,a3,a4
    80006108:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000610c:	0001d817          	auipc	a6,0x1d
    80006110:	ef480813          	addi	a6,a6,-268 # 80023000 <disk>
    80006114:	0001f517          	auipc	a0,0x1f
    80006118:	eec50513          	addi	a0,a0,-276 # 80025000 <disk+0x2000>
    8000611c:	6114                	ld	a3,0(a0)
    8000611e:	96ba                	add	a3,a3,a4
    80006120:	00c6d603          	lhu	a2,12(a3)
    80006124:	00166613          	ori	a2,a2,1
    80006128:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000612c:	f9842683          	lw	a3,-104(s0)
    80006130:	6110                	ld	a2,0(a0)
    80006132:	9732                	add	a4,a4,a2
    80006134:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006138:	20058613          	addi	a2,a1,512
    8000613c:	0612                	slli	a2,a2,0x4
    8000613e:	9642                	add	a2,a2,a6
    80006140:	577d                	li	a4,-1
    80006142:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006146:	00469713          	slli	a4,a3,0x4
    8000614a:	6114                	ld	a3,0(a0)
    8000614c:	96ba                	add	a3,a3,a4
    8000614e:	03078793          	addi	a5,a5,48
    80006152:	97c2                	add	a5,a5,a6
    80006154:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006156:	611c                	ld	a5,0(a0)
    80006158:	97ba                	add	a5,a5,a4
    8000615a:	4685                	li	a3,1
    8000615c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000615e:	611c                	ld	a5,0(a0)
    80006160:	97ba                	add	a5,a5,a4
    80006162:	4809                	li	a6,2
    80006164:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006168:	611c                	ld	a5,0(a0)
    8000616a:	973e                	add	a4,a4,a5
    8000616c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006170:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006174:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006178:	6518                	ld	a4,8(a0)
    8000617a:	00275783          	lhu	a5,2(a4)
    8000617e:	8b9d                	andi	a5,a5,7
    80006180:	0786                	slli	a5,a5,0x1
    80006182:	97ba                	add	a5,a5,a4
    80006184:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006188:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000618c:	6518                	ld	a4,8(a0)
    8000618e:	00275783          	lhu	a5,2(a4)
    80006192:	2785                	addiw	a5,a5,1
    80006194:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006198:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000619c:	100017b7          	lui	a5,0x10001
    800061a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061a4:	00492703          	lw	a4,4(s2)
    800061a8:	4785                	li	a5,1
    800061aa:	02f71163          	bne	a4,a5,800061cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800061ae:	0001f997          	auipc	s3,0x1f
    800061b2:	f7a98993          	addi	s3,s3,-134 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061b8:	85ce                	mv	a1,s3
    800061ba:	854a                	mv	a0,s2
    800061bc:	ffffc097          	auipc	ra,0xffffc
    800061c0:	f2c080e7          	jalr	-212(ra) # 800020e8 <sleep>
  while(b->disk == 1) {
    800061c4:	00492783          	lw	a5,4(s2)
    800061c8:	fe9788e3          	beq	a5,s1,800061b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061cc:	f9042903          	lw	s2,-112(s0)
    800061d0:	20090793          	addi	a5,s2,512
    800061d4:	00479713          	slli	a4,a5,0x4
    800061d8:	0001d797          	auipc	a5,0x1d
    800061dc:	e2878793          	addi	a5,a5,-472 # 80023000 <disk>
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061e6:	0001f997          	auipc	s3,0x1f
    800061ea:	e1a98993          	addi	s3,s3,-486 # 80025000 <disk+0x2000>
    800061ee:	00491713          	slli	a4,s2,0x4
    800061f2:	0009b783          	ld	a5,0(s3)
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061fc:	854a                	mv	a0,s2
    800061fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006202:	00000097          	auipc	ra,0x0
    80006206:	bc4080e7          	jalr	-1084(ra) # 80005dc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000620a:	8885                	andi	s1,s1,1
    8000620c:	f0ed                	bnez	s1,800061ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000620e:	0001f517          	auipc	a0,0x1f
    80006212:	f1a50513          	addi	a0,a0,-230 # 80025128 <disk+0x2128>
    80006216:	ffffb097          	auipc	ra,0xffffb
    8000621a:	a82080e7          	jalr	-1406(ra) # 80000c98 <release>
}
    8000621e:	70a6                	ld	ra,104(sp)
    80006220:	7406                	ld	s0,96(sp)
    80006222:	64e6                	ld	s1,88(sp)
    80006224:	6946                	ld	s2,80(sp)
    80006226:	69a6                	ld	s3,72(sp)
    80006228:	6a06                	ld	s4,64(sp)
    8000622a:	7ae2                	ld	s5,56(sp)
    8000622c:	7b42                	ld	s6,48(sp)
    8000622e:	7ba2                	ld	s7,40(sp)
    80006230:	7c02                	ld	s8,32(sp)
    80006232:	6ce2                	ld	s9,24(sp)
    80006234:	6d42                	ld	s10,16(sp)
    80006236:	6165                	addi	sp,sp,112
    80006238:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000623a:	0001f697          	auipc	a3,0x1f
    8000623e:	dc66b683          	ld	a3,-570(a3) # 80025000 <disk+0x2000>
    80006242:	96ba                	add	a3,a3,a4
    80006244:	4609                	li	a2,2
    80006246:	00c69623          	sh	a2,12(a3)
    8000624a:	b5c9                	j	8000610c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000624c:	f9042583          	lw	a1,-112(s0)
    80006250:	20058793          	addi	a5,a1,512
    80006254:	0792                	slli	a5,a5,0x4
    80006256:	0001d517          	auipc	a0,0x1d
    8000625a:	e5250513          	addi	a0,a0,-430 # 800230a8 <disk+0xa8>
    8000625e:	953e                	add	a0,a0,a5
  if(write)
    80006260:	e20d11e3          	bnez	s10,80006082 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006264:	20058713          	addi	a4,a1,512
    80006268:	00471693          	slli	a3,a4,0x4
    8000626c:	0001d717          	auipc	a4,0x1d
    80006270:	d9470713          	addi	a4,a4,-620 # 80023000 <disk>
    80006274:	9736                	add	a4,a4,a3
    80006276:	0a072423          	sw	zero,168(a4)
    8000627a:	b505                	j	8000609a <virtio_disk_rw+0xf4>

000000008000627c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000627c:	1101                	addi	sp,sp,-32
    8000627e:	ec06                	sd	ra,24(sp)
    80006280:	e822                	sd	s0,16(sp)
    80006282:	e426                	sd	s1,8(sp)
    80006284:	e04a                	sd	s2,0(sp)
    80006286:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006288:	0001f517          	auipc	a0,0x1f
    8000628c:	ea050513          	addi	a0,a0,-352 # 80025128 <disk+0x2128>
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	954080e7          	jalr	-1708(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006298:	10001737          	lui	a4,0x10001
    8000629c:	533c                	lw	a5,96(a4)
    8000629e:	8b8d                	andi	a5,a5,3
    800062a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062a6:	0001f797          	auipc	a5,0x1f
    800062aa:	d5a78793          	addi	a5,a5,-678 # 80025000 <disk+0x2000>
    800062ae:	6b94                	ld	a3,16(a5)
    800062b0:	0207d703          	lhu	a4,32(a5)
    800062b4:	0026d783          	lhu	a5,2(a3)
    800062b8:	06f70163          	beq	a4,a5,8000631a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062bc:	0001d917          	auipc	s2,0x1d
    800062c0:	d4490913          	addi	s2,s2,-700 # 80023000 <disk>
    800062c4:	0001f497          	auipc	s1,0x1f
    800062c8:	d3c48493          	addi	s1,s1,-708 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062d0:	6898                	ld	a4,16(s1)
    800062d2:	0204d783          	lhu	a5,32(s1)
    800062d6:	8b9d                	andi	a5,a5,7
    800062d8:	078e                	slli	a5,a5,0x3
    800062da:	97ba                	add	a5,a5,a4
    800062dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062de:	20078713          	addi	a4,a5,512
    800062e2:	0712                	slli	a4,a4,0x4
    800062e4:	974a                	add	a4,a4,s2
    800062e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062ea:	e731                	bnez	a4,80006336 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062ec:	20078793          	addi	a5,a5,512
    800062f0:	0792                	slli	a5,a5,0x4
    800062f2:	97ca                	add	a5,a5,s2
    800062f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062fa:	ffffc097          	auipc	ra,0xffffc
    800062fe:	f7a080e7          	jalr	-134(ra) # 80002274 <wakeup>

    disk.used_idx += 1;
    80006302:	0204d783          	lhu	a5,32(s1)
    80006306:	2785                	addiw	a5,a5,1
    80006308:	17c2                	slli	a5,a5,0x30
    8000630a:	93c1                	srli	a5,a5,0x30
    8000630c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006310:	6898                	ld	a4,16(s1)
    80006312:	00275703          	lhu	a4,2(a4)
    80006316:	faf71be3          	bne	a4,a5,800062cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000631a:	0001f517          	auipc	a0,0x1f
    8000631e:	e0e50513          	addi	a0,a0,-498 # 80025128 <disk+0x2128>
    80006322:	ffffb097          	auipc	ra,0xffffb
    80006326:	976080e7          	jalr	-1674(ra) # 80000c98 <release>
}
    8000632a:	60e2                	ld	ra,24(sp)
    8000632c:	6442                	ld	s0,16(sp)
    8000632e:	64a2                	ld	s1,8(sp)
    80006330:	6902                	ld	s2,0(sp)
    80006332:	6105                	addi	sp,sp,32
    80006334:	8082                	ret
      panic("virtio_disk_intr status");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	4f250513          	addi	a0,a0,1266 # 80008828 <syscalls+0x3c8>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	200080e7          	jalr	512(ra) # 8000053e <panic>
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
