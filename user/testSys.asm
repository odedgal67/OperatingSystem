
user/_testSys:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <example_kill_system>:
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"


void example_kill_system(int interval, int loop_size) {
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	e852                	sd	s4,16(sp)
   e:	e456                	sd	s5,8(sp)
  10:	e05a                	sd	s6,0(sp)
  12:	0080                	addi	s0,sp,64
  14:	8a2a                	mv	s4,a0
  16:	892e                	mv	s2,a1
    int pid = getpid();
  18:	00000097          	auipc	ra,0x0
  1c:	446080e7          	jalr	1094(ra) # 45e <getpid>
    for (int i = 0; i < loop_size; i++) {
  20:	05205a63          	blez	s2,74 <example_kill_system+0x74>
  24:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  26:	01f9599b          	srliw	s3,s2,0x1f
  2a:	012989bb          	addw	s3,s3,s2
  2e:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  32:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  34:	00001b17          	auipc	s6,0x1
  38:	8e4b0b13          	addi	s6,s6,-1820 # 918 <malloc+0xe4>
  3c:	a031                	j	48 <example_kill_system+0x48>
        if (i == loop_size / 2) {
  3e:	02998663          	beq	s3,s1,6a <example_kill_system+0x6a>
    for (int i = 0; i < loop_size; i++) {
  42:	2485                	addiw	s1,s1,1
  44:	02990863          	beq	s2,s1,74 <example_kill_system+0x74>
        if (i % interval == 0 && pid == getpid()) {
  48:	0344e7bb          	remw	a5,s1,s4
  4c:	fbed                	bnez	a5,3e <example_kill_system+0x3e>
  4e:	00000097          	auipc	ra,0x0
  52:	410080e7          	jalr	1040(ra) # 45e <getpid>
  56:	ff5514e3          	bne	a0,s5,3e <example_kill_system+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  5a:	864a                	mv	a2,s2
  5c:	85a6                	mv	a1,s1
  5e:	855a                	mv	a0,s6
  60:	00000097          	auipc	ra,0x0
  64:	716080e7          	jalr	1814(ra) # 776 <printf>
  68:	bfd9                	j	3e <example_kill_system+0x3e>
            kill_system();
  6a:	00000097          	auipc	ra,0x0
  6e:	41c080e7          	jalr	1052(ra) # 486 <kill_system>
  72:	bfc1                	j	42 <example_kill_system+0x42>
        }
    }
    printf("\n");
  74:	00001517          	auipc	a0,0x1
  78:	8c450513          	addi	a0,a0,-1852 # 938 <malloc+0x104>
  7c:	00000097          	auipc	ra,0x0
  80:	6fa080e7          	jalr	1786(ra) # 776 <printf>
}
  84:	70e2                	ld	ra,56(sp)
  86:	7442                	ld	s0,48(sp)
  88:	74a2                	ld	s1,40(sp)
  8a:	7902                	ld	s2,32(sp)
  8c:	69e2                	ld	s3,24(sp)
  8e:	6a42                	ld	s4,16(sp)
  90:	6aa2                	ld	s5,8(sp)
  92:	6b02                	ld	s6,0(sp)
  94:	6121                	addi	sp,sp,64
  96:	8082                	ret

0000000000000098 <pause_system_dem>:

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
  98:	715d                	addi	sp,sp,-80
  9a:	e486                	sd	ra,72(sp)
  9c:	e0a2                	sd	s0,64(sp)
  9e:	fc26                	sd	s1,56(sp)
  a0:	f84a                	sd	s2,48(sp)
  a2:	f44e                	sd	s3,40(sp)
  a4:	f052                	sd	s4,32(sp)
  a6:	ec56                	sd	s5,24(sp)
  a8:	e85a                	sd	s6,16(sp)
  aa:	e45e                	sd	s7,8(sp)
  ac:	0880                	addi	s0,sp,80
  ae:	8a2a                	mv	s4,a0
  b0:	8b2e                	mv	s6,a1
  b2:	8932                	mv	s2,a2
    int pid = getpid();
  b4:	00000097          	auipc	ra,0x0
  b8:	3aa080e7          	jalr	938(ra) # 45e <getpid>
    for (int i = 0; i < loop_size; i++) {
  bc:	05205b63          	blez	s2,112 <pause_system_dem+0x7a>
  c0:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  c2:	01f9599b          	srliw	s3,s2,0x1f
  c6:	012989bb          	addw	s3,s3,s2
  ca:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  ce:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
  d0:	00001b97          	auipc	s7,0x1
  d4:	870b8b93          	addi	s7,s7,-1936 # 940 <malloc+0x10c>
  d8:	a031                	j	e4 <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
  da:	02998663          	beq	s3,s1,106 <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
  de:	2485                	addiw	s1,s1,1
  e0:	02990963          	beq	s2,s1,112 <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
  e4:	0344e7bb          	remw	a5,s1,s4
  e8:	fbed                	bnez	a5,da <pause_system_dem+0x42>
  ea:	00000097          	auipc	ra,0x0
  ee:	374080e7          	jalr	884(ra) # 45e <getpid>
  f2:	ff5514e3          	bne	a0,s5,da <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
  f6:	864a                	mv	a2,s2
  f8:	85a6                	mv	a1,s1
  fa:	855e                	mv	a0,s7
  fc:	00000097          	auipc	ra,0x0
 100:	67a080e7          	jalr	1658(ra) # 776 <printf>
 104:	bfd9                	j	da <pause_system_dem+0x42>
            pause_system(pause_seconds);
 106:	855a                	mv	a0,s6
 108:	00000097          	auipc	ra,0x0
 10c:	376080e7          	jalr	886(ra) # 47e <pause_system>
 110:	b7f9                	j	de <pause_system_dem+0x46>
        }
    }
    printf("\n");
 112:	00001517          	auipc	a0,0x1
 116:	82650513          	addi	a0,a0,-2010 # 938 <malloc+0x104>
 11a:	00000097          	auipc	ra,0x0
 11e:	65c080e7          	jalr	1628(ra) # 776 <printf>
}
 122:	60a6                	ld	ra,72(sp)
 124:	6406                	ld	s0,64(sp)
 126:	74e2                	ld	s1,56(sp)
 128:	7942                	ld	s2,48(sp)
 12a:	79a2                	ld	s3,40(sp)
 12c:	7a02                	ld	s4,32(sp)
 12e:	6ae2                	ld	s5,24(sp)
 130:	6b42                	ld	s6,16(sp)
 132:	6ba2                	ld	s7,8(sp)
 134:	6161                	addi	sp,sp,80
 136:	8082                	ret

0000000000000138 <main>:

int main(int argc, char** argv)
{
 138:	1141                	addi	sp,sp,-16
 13a:	e406                	sd	ra,8(sp)
 13c:	e022                	sd	s0,0(sp)
 13e:	0800                	addi	s0,sp,16
  pause_system_dem(10,10,100);
 140:	06400613          	li	a2,100
 144:	45a9                	li	a1,10
 146:	4529                	li	a0,10
 148:	00000097          	auipc	ra,0x0
 14c:	f50080e7          	jalr	-176(ra) # 98 <pause_system_dem>
  example_kill_system(10,100);
 150:	06400593          	li	a1,100
 154:	4529                	li	a0,10
 156:	00000097          	auipc	ra,0x0
 15a:	eaa080e7          	jalr	-342(ra) # 0 <example_kill_system>
  exit(0);
 15e:	4501                	li	a0,0
 160:	00000097          	auipc	ra,0x0
 164:	27e080e7          	jalr	638(ra) # 3de <exit>

0000000000000168 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 168:	1141                	addi	sp,sp,-16
 16a:	e422                	sd	s0,8(sp)
 16c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 16e:	87aa                	mv	a5,a0
 170:	0585                	addi	a1,a1,1
 172:	0785                	addi	a5,a5,1
 174:	fff5c703          	lbu	a4,-1(a1)
 178:	fee78fa3          	sb	a4,-1(a5)
 17c:	fb75                	bnez	a4,170 <strcpy+0x8>
    ;
  return os;
}
 17e:	6422                	ld	s0,8(sp)
 180:	0141                	addi	sp,sp,16
 182:	8082                	ret

0000000000000184 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 184:	1141                	addi	sp,sp,-16
 186:	e422                	sd	s0,8(sp)
 188:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 18a:	00054783          	lbu	a5,0(a0)
 18e:	cb91                	beqz	a5,1a2 <strcmp+0x1e>
 190:	0005c703          	lbu	a4,0(a1)
 194:	00f71763          	bne	a4,a5,1a2 <strcmp+0x1e>
    p++, q++;
 198:	0505                	addi	a0,a0,1
 19a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 19c:	00054783          	lbu	a5,0(a0)
 1a0:	fbe5                	bnez	a5,190 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1a2:	0005c503          	lbu	a0,0(a1)
}
 1a6:	40a7853b          	subw	a0,a5,a0
 1aa:	6422                	ld	s0,8(sp)
 1ac:	0141                	addi	sp,sp,16
 1ae:	8082                	ret

00000000000001b0 <strlen>:

uint
strlen(const char *s)
{
 1b0:	1141                	addi	sp,sp,-16
 1b2:	e422                	sd	s0,8(sp)
 1b4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1b6:	00054783          	lbu	a5,0(a0)
 1ba:	cf91                	beqz	a5,1d6 <strlen+0x26>
 1bc:	0505                	addi	a0,a0,1
 1be:	87aa                	mv	a5,a0
 1c0:	4685                	li	a3,1
 1c2:	9e89                	subw	a3,a3,a0
 1c4:	00f6853b          	addw	a0,a3,a5
 1c8:	0785                	addi	a5,a5,1
 1ca:	fff7c703          	lbu	a4,-1(a5)
 1ce:	fb7d                	bnez	a4,1c4 <strlen+0x14>
    ;
  return n;
}
 1d0:	6422                	ld	s0,8(sp)
 1d2:	0141                	addi	sp,sp,16
 1d4:	8082                	ret
  for(n = 0; s[n]; n++)
 1d6:	4501                	li	a0,0
 1d8:	bfe5                	j	1d0 <strlen+0x20>

00000000000001da <memset>:

void*
memset(void *dst, int c, uint n)
{
 1da:	1141                	addi	sp,sp,-16
 1dc:	e422                	sd	s0,8(sp)
 1de:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1e0:	ce09                	beqz	a2,1fa <memset+0x20>
 1e2:	87aa                	mv	a5,a0
 1e4:	fff6071b          	addiw	a4,a2,-1
 1e8:	1702                	slli	a4,a4,0x20
 1ea:	9301                	srli	a4,a4,0x20
 1ec:	0705                	addi	a4,a4,1
 1ee:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1f0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1f4:	0785                	addi	a5,a5,1
 1f6:	fee79de3          	bne	a5,a4,1f0 <memset+0x16>
  }
  return dst;
}
 1fa:	6422                	ld	s0,8(sp)
 1fc:	0141                	addi	sp,sp,16
 1fe:	8082                	ret

0000000000000200 <strchr>:

char*
strchr(const char *s, char c)
{
 200:	1141                	addi	sp,sp,-16
 202:	e422                	sd	s0,8(sp)
 204:	0800                	addi	s0,sp,16
  for(; *s; s++)
 206:	00054783          	lbu	a5,0(a0)
 20a:	cb99                	beqz	a5,220 <strchr+0x20>
    if(*s == c)
 20c:	00f58763          	beq	a1,a5,21a <strchr+0x1a>
  for(; *s; s++)
 210:	0505                	addi	a0,a0,1
 212:	00054783          	lbu	a5,0(a0)
 216:	fbfd                	bnez	a5,20c <strchr+0xc>
      return (char*)s;
  return 0;
 218:	4501                	li	a0,0
}
 21a:	6422                	ld	s0,8(sp)
 21c:	0141                	addi	sp,sp,16
 21e:	8082                	ret
  return 0;
 220:	4501                	li	a0,0
 222:	bfe5                	j	21a <strchr+0x1a>

0000000000000224 <gets>:

char*
gets(char *buf, int max)
{
 224:	711d                	addi	sp,sp,-96
 226:	ec86                	sd	ra,88(sp)
 228:	e8a2                	sd	s0,80(sp)
 22a:	e4a6                	sd	s1,72(sp)
 22c:	e0ca                	sd	s2,64(sp)
 22e:	fc4e                	sd	s3,56(sp)
 230:	f852                	sd	s4,48(sp)
 232:	f456                	sd	s5,40(sp)
 234:	f05a                	sd	s6,32(sp)
 236:	ec5e                	sd	s7,24(sp)
 238:	1080                	addi	s0,sp,96
 23a:	8baa                	mv	s7,a0
 23c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 23e:	892a                	mv	s2,a0
 240:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 242:	4aa9                	li	s5,10
 244:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 246:	89a6                	mv	s3,s1
 248:	2485                	addiw	s1,s1,1
 24a:	0344d863          	bge	s1,s4,27a <gets+0x56>
    cc = read(0, &c, 1);
 24e:	4605                	li	a2,1
 250:	faf40593          	addi	a1,s0,-81
 254:	4501                	li	a0,0
 256:	00000097          	auipc	ra,0x0
 25a:	1a0080e7          	jalr	416(ra) # 3f6 <read>
    if(cc < 1)
 25e:	00a05e63          	blez	a0,27a <gets+0x56>
    buf[i++] = c;
 262:	faf44783          	lbu	a5,-81(s0)
 266:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 26a:	01578763          	beq	a5,s5,278 <gets+0x54>
 26e:	0905                	addi	s2,s2,1
 270:	fd679be3          	bne	a5,s6,246 <gets+0x22>
  for(i=0; i+1 < max; ){
 274:	89a6                	mv	s3,s1
 276:	a011                	j	27a <gets+0x56>
 278:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 27a:	99de                	add	s3,s3,s7
 27c:	00098023          	sb	zero,0(s3)
  return buf;
}
 280:	855e                	mv	a0,s7
 282:	60e6                	ld	ra,88(sp)
 284:	6446                	ld	s0,80(sp)
 286:	64a6                	ld	s1,72(sp)
 288:	6906                	ld	s2,64(sp)
 28a:	79e2                	ld	s3,56(sp)
 28c:	7a42                	ld	s4,48(sp)
 28e:	7aa2                	ld	s5,40(sp)
 290:	7b02                	ld	s6,32(sp)
 292:	6be2                	ld	s7,24(sp)
 294:	6125                	addi	sp,sp,96
 296:	8082                	ret

0000000000000298 <stat>:

int
stat(const char *n, struct stat *st)
{
 298:	1101                	addi	sp,sp,-32
 29a:	ec06                	sd	ra,24(sp)
 29c:	e822                	sd	s0,16(sp)
 29e:	e426                	sd	s1,8(sp)
 2a0:	e04a                	sd	s2,0(sp)
 2a2:	1000                	addi	s0,sp,32
 2a4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2a6:	4581                	li	a1,0
 2a8:	00000097          	auipc	ra,0x0
 2ac:	176080e7          	jalr	374(ra) # 41e <open>
  if(fd < 0)
 2b0:	02054563          	bltz	a0,2da <stat+0x42>
 2b4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2b6:	85ca                	mv	a1,s2
 2b8:	00000097          	auipc	ra,0x0
 2bc:	17e080e7          	jalr	382(ra) # 436 <fstat>
 2c0:	892a                	mv	s2,a0
  close(fd);
 2c2:	8526                	mv	a0,s1
 2c4:	00000097          	auipc	ra,0x0
 2c8:	142080e7          	jalr	322(ra) # 406 <close>
  return r;
}
 2cc:	854a                	mv	a0,s2
 2ce:	60e2                	ld	ra,24(sp)
 2d0:	6442                	ld	s0,16(sp)
 2d2:	64a2                	ld	s1,8(sp)
 2d4:	6902                	ld	s2,0(sp)
 2d6:	6105                	addi	sp,sp,32
 2d8:	8082                	ret
    return -1;
 2da:	597d                	li	s2,-1
 2dc:	bfc5                	j	2cc <stat+0x34>

00000000000002de <atoi>:

int
atoi(const char *s)
{
 2de:	1141                	addi	sp,sp,-16
 2e0:	e422                	sd	s0,8(sp)
 2e2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2e4:	00054603          	lbu	a2,0(a0)
 2e8:	fd06079b          	addiw	a5,a2,-48
 2ec:	0ff7f793          	andi	a5,a5,255
 2f0:	4725                	li	a4,9
 2f2:	02f76963          	bltu	a4,a5,324 <atoi+0x46>
 2f6:	86aa                	mv	a3,a0
  n = 0;
 2f8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2fa:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2fc:	0685                	addi	a3,a3,1
 2fe:	0025179b          	slliw	a5,a0,0x2
 302:	9fa9                	addw	a5,a5,a0
 304:	0017979b          	slliw	a5,a5,0x1
 308:	9fb1                	addw	a5,a5,a2
 30a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 30e:	0006c603          	lbu	a2,0(a3)
 312:	fd06071b          	addiw	a4,a2,-48
 316:	0ff77713          	andi	a4,a4,255
 31a:	fee5f1e3          	bgeu	a1,a4,2fc <atoi+0x1e>
  return n;
}
 31e:	6422                	ld	s0,8(sp)
 320:	0141                	addi	sp,sp,16
 322:	8082                	ret
  n = 0;
 324:	4501                	li	a0,0
 326:	bfe5                	j	31e <atoi+0x40>

0000000000000328 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 328:	1141                	addi	sp,sp,-16
 32a:	e422                	sd	s0,8(sp)
 32c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 32e:	02b57663          	bgeu	a0,a1,35a <memmove+0x32>
    while(n-- > 0)
 332:	02c05163          	blez	a2,354 <memmove+0x2c>
 336:	fff6079b          	addiw	a5,a2,-1
 33a:	1782                	slli	a5,a5,0x20
 33c:	9381                	srli	a5,a5,0x20
 33e:	0785                	addi	a5,a5,1
 340:	97aa                	add	a5,a5,a0
  dst = vdst;
 342:	872a                	mv	a4,a0
      *dst++ = *src++;
 344:	0585                	addi	a1,a1,1
 346:	0705                	addi	a4,a4,1
 348:	fff5c683          	lbu	a3,-1(a1)
 34c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 350:	fee79ae3          	bne	a5,a4,344 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 354:	6422                	ld	s0,8(sp)
 356:	0141                	addi	sp,sp,16
 358:	8082                	ret
    dst += n;
 35a:	00c50733          	add	a4,a0,a2
    src += n;
 35e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 360:	fec05ae3          	blez	a2,354 <memmove+0x2c>
 364:	fff6079b          	addiw	a5,a2,-1
 368:	1782                	slli	a5,a5,0x20
 36a:	9381                	srli	a5,a5,0x20
 36c:	fff7c793          	not	a5,a5
 370:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 372:	15fd                	addi	a1,a1,-1
 374:	177d                	addi	a4,a4,-1
 376:	0005c683          	lbu	a3,0(a1)
 37a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 37e:	fee79ae3          	bne	a5,a4,372 <memmove+0x4a>
 382:	bfc9                	j	354 <memmove+0x2c>

0000000000000384 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 384:	1141                	addi	sp,sp,-16
 386:	e422                	sd	s0,8(sp)
 388:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 38a:	ca05                	beqz	a2,3ba <memcmp+0x36>
 38c:	fff6069b          	addiw	a3,a2,-1
 390:	1682                	slli	a3,a3,0x20
 392:	9281                	srli	a3,a3,0x20
 394:	0685                	addi	a3,a3,1
 396:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 398:	00054783          	lbu	a5,0(a0)
 39c:	0005c703          	lbu	a4,0(a1)
 3a0:	00e79863          	bne	a5,a4,3b0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3a4:	0505                	addi	a0,a0,1
    p2++;
 3a6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3a8:	fed518e3          	bne	a0,a3,398 <memcmp+0x14>
  }
  return 0;
 3ac:	4501                	li	a0,0
 3ae:	a019                	j	3b4 <memcmp+0x30>
      return *p1 - *p2;
 3b0:	40e7853b          	subw	a0,a5,a4
}
 3b4:	6422                	ld	s0,8(sp)
 3b6:	0141                	addi	sp,sp,16
 3b8:	8082                	ret
  return 0;
 3ba:	4501                	li	a0,0
 3bc:	bfe5                	j	3b4 <memcmp+0x30>

00000000000003be <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3be:	1141                	addi	sp,sp,-16
 3c0:	e406                	sd	ra,8(sp)
 3c2:	e022                	sd	s0,0(sp)
 3c4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3c6:	00000097          	auipc	ra,0x0
 3ca:	f62080e7          	jalr	-158(ra) # 328 <memmove>
}
 3ce:	60a2                	ld	ra,8(sp)
 3d0:	6402                	ld	s0,0(sp)
 3d2:	0141                	addi	sp,sp,16
 3d4:	8082                	ret

00000000000003d6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3d6:	4885                	li	a7,1
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <exit>:
.global exit
exit:
 li a7, SYS_exit
 3de:	4889                	li	a7,2
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3e6:	488d                	li	a7,3
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3ee:	4891                	li	a7,4
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <read>:
.global read
read:
 li a7, SYS_read
 3f6:	4895                	li	a7,5
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <write>:
.global write
write:
 li a7, SYS_write
 3fe:	48c1                	li	a7,16
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <close>:
.global close
close:
 li a7, SYS_close
 406:	48d5                	li	a7,21
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <kill>:
.global kill
kill:
 li a7, SYS_kill
 40e:	4899                	li	a7,6
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <exec>:
.global exec
exec:
 li a7, SYS_exec
 416:	489d                	li	a7,7
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <open>:
.global open
open:
 li a7, SYS_open
 41e:	48bd                	li	a7,15
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 426:	48c5                	li	a7,17
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 42e:	48c9                	li	a7,18
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 436:	48a1                	li	a7,8
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <link>:
.global link
link:
 li a7, SYS_link
 43e:	48cd                	li	a7,19
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 446:	48d1                	li	a7,20
 ecall
 448:	00000073          	ecall
 ret
 44c:	8082                	ret

000000000000044e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 44e:	48a5                	li	a7,9
 ecall
 450:	00000073          	ecall
 ret
 454:	8082                	ret

0000000000000456 <dup>:
.global dup
dup:
 li a7, SYS_dup
 456:	48a9                	li	a7,10
 ecall
 458:	00000073          	ecall
 ret
 45c:	8082                	ret

000000000000045e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 45e:	48ad                	li	a7,11
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 466:	48b1                	li	a7,12
 ecall
 468:	00000073          	ecall
 ret
 46c:	8082                	ret

000000000000046e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 46e:	48b5                	li	a7,13
 ecall
 470:	00000073          	ecall
 ret
 474:	8082                	ret

0000000000000476 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 476:	48b9                	li	a7,14
 ecall
 478:	00000073          	ecall
 ret
 47c:	8082                	ret

000000000000047e <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 47e:	48d9                	li	a7,22
 ecall
 480:	00000073          	ecall
 ret
 484:	8082                	ret

0000000000000486 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 486:	48dd                	li	a7,23
 ecall
 488:	00000073          	ecall
 ret
 48c:	8082                	ret

000000000000048e <debug>:
.global debug
debug:
 li a7, SYS_debug
 48e:	48e1                	li	a7,24
 ecall
 490:	00000073          	ecall
 ret
 494:	8082                	ret

0000000000000496 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 496:	48e5                	li	a7,25
 ecall
 498:	00000073          	ecall
 ret
 49c:	8082                	ret

000000000000049e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 49e:	1101                	addi	sp,sp,-32
 4a0:	ec06                	sd	ra,24(sp)
 4a2:	e822                	sd	s0,16(sp)
 4a4:	1000                	addi	s0,sp,32
 4a6:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4aa:	4605                	li	a2,1
 4ac:	fef40593          	addi	a1,s0,-17
 4b0:	00000097          	auipc	ra,0x0
 4b4:	f4e080e7          	jalr	-178(ra) # 3fe <write>
}
 4b8:	60e2                	ld	ra,24(sp)
 4ba:	6442                	ld	s0,16(sp)
 4bc:	6105                	addi	sp,sp,32
 4be:	8082                	ret

00000000000004c0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4c0:	7139                	addi	sp,sp,-64
 4c2:	fc06                	sd	ra,56(sp)
 4c4:	f822                	sd	s0,48(sp)
 4c6:	f426                	sd	s1,40(sp)
 4c8:	f04a                	sd	s2,32(sp)
 4ca:	ec4e                	sd	s3,24(sp)
 4cc:	0080                	addi	s0,sp,64
 4ce:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4d0:	c299                	beqz	a3,4d6 <printint+0x16>
 4d2:	0805c863          	bltz	a1,562 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4d6:	2581                	sext.w	a1,a1
  neg = 0;
 4d8:	4881                	li	a7,0
 4da:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4de:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4e0:	2601                	sext.w	a2,a2
 4e2:	00000517          	auipc	a0,0x0
 4e6:	48650513          	addi	a0,a0,1158 # 968 <digits>
 4ea:	883a                	mv	a6,a4
 4ec:	2705                	addiw	a4,a4,1
 4ee:	02c5f7bb          	remuw	a5,a1,a2
 4f2:	1782                	slli	a5,a5,0x20
 4f4:	9381                	srli	a5,a5,0x20
 4f6:	97aa                	add	a5,a5,a0
 4f8:	0007c783          	lbu	a5,0(a5)
 4fc:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 500:	0005879b          	sext.w	a5,a1
 504:	02c5d5bb          	divuw	a1,a1,a2
 508:	0685                	addi	a3,a3,1
 50a:	fec7f0e3          	bgeu	a5,a2,4ea <printint+0x2a>
  if(neg)
 50e:	00088b63          	beqz	a7,524 <printint+0x64>
    buf[i++] = '-';
 512:	fd040793          	addi	a5,s0,-48
 516:	973e                	add	a4,a4,a5
 518:	02d00793          	li	a5,45
 51c:	fef70823          	sb	a5,-16(a4)
 520:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 524:	02e05863          	blez	a4,554 <printint+0x94>
 528:	fc040793          	addi	a5,s0,-64
 52c:	00e78933          	add	s2,a5,a4
 530:	fff78993          	addi	s3,a5,-1
 534:	99ba                	add	s3,s3,a4
 536:	377d                	addiw	a4,a4,-1
 538:	1702                	slli	a4,a4,0x20
 53a:	9301                	srli	a4,a4,0x20
 53c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 540:	fff94583          	lbu	a1,-1(s2)
 544:	8526                	mv	a0,s1
 546:	00000097          	auipc	ra,0x0
 54a:	f58080e7          	jalr	-168(ra) # 49e <putc>
  while(--i >= 0)
 54e:	197d                	addi	s2,s2,-1
 550:	ff3918e3          	bne	s2,s3,540 <printint+0x80>
}
 554:	70e2                	ld	ra,56(sp)
 556:	7442                	ld	s0,48(sp)
 558:	74a2                	ld	s1,40(sp)
 55a:	7902                	ld	s2,32(sp)
 55c:	69e2                	ld	s3,24(sp)
 55e:	6121                	addi	sp,sp,64
 560:	8082                	ret
    x = -xx;
 562:	40b005bb          	negw	a1,a1
    neg = 1;
 566:	4885                	li	a7,1
    x = -xx;
 568:	bf8d                	j	4da <printint+0x1a>

000000000000056a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 56a:	7119                	addi	sp,sp,-128
 56c:	fc86                	sd	ra,120(sp)
 56e:	f8a2                	sd	s0,112(sp)
 570:	f4a6                	sd	s1,104(sp)
 572:	f0ca                	sd	s2,96(sp)
 574:	ecce                	sd	s3,88(sp)
 576:	e8d2                	sd	s4,80(sp)
 578:	e4d6                	sd	s5,72(sp)
 57a:	e0da                	sd	s6,64(sp)
 57c:	fc5e                	sd	s7,56(sp)
 57e:	f862                	sd	s8,48(sp)
 580:	f466                	sd	s9,40(sp)
 582:	f06a                	sd	s10,32(sp)
 584:	ec6e                	sd	s11,24(sp)
 586:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 588:	0005c903          	lbu	s2,0(a1)
 58c:	18090f63          	beqz	s2,72a <vprintf+0x1c0>
 590:	8aaa                	mv	s5,a0
 592:	8b32                	mv	s6,a2
 594:	00158493          	addi	s1,a1,1
  state = 0;
 598:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 59a:	02500a13          	li	s4,37
      if(c == 'd'){
 59e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5a2:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5a6:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5aa:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ae:	00000b97          	auipc	s7,0x0
 5b2:	3bab8b93          	addi	s7,s7,954 # 968 <digits>
 5b6:	a839                	j	5d4 <vprintf+0x6a>
        putc(fd, c);
 5b8:	85ca                	mv	a1,s2
 5ba:	8556                	mv	a0,s5
 5bc:	00000097          	auipc	ra,0x0
 5c0:	ee2080e7          	jalr	-286(ra) # 49e <putc>
 5c4:	a019                	j	5ca <vprintf+0x60>
    } else if(state == '%'){
 5c6:	01498f63          	beq	s3,s4,5e4 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5ca:	0485                	addi	s1,s1,1
 5cc:	fff4c903          	lbu	s2,-1(s1)
 5d0:	14090d63          	beqz	s2,72a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5d4:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5d8:	fe0997e3          	bnez	s3,5c6 <vprintf+0x5c>
      if(c == '%'){
 5dc:	fd479ee3          	bne	a5,s4,5b8 <vprintf+0x4e>
        state = '%';
 5e0:	89be                	mv	s3,a5
 5e2:	b7e5                	j	5ca <vprintf+0x60>
      if(c == 'd'){
 5e4:	05878063          	beq	a5,s8,624 <vprintf+0xba>
      } else if(c == 'l') {
 5e8:	05978c63          	beq	a5,s9,640 <vprintf+0xd6>
      } else if(c == 'x') {
 5ec:	07a78863          	beq	a5,s10,65c <vprintf+0xf2>
      } else if(c == 'p') {
 5f0:	09b78463          	beq	a5,s11,678 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5f4:	07300713          	li	a4,115
 5f8:	0ce78663          	beq	a5,a4,6c4 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5fc:	06300713          	li	a4,99
 600:	0ee78e63          	beq	a5,a4,6fc <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 604:	11478863          	beq	a5,s4,714 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 608:	85d2                	mv	a1,s4
 60a:	8556                	mv	a0,s5
 60c:	00000097          	auipc	ra,0x0
 610:	e92080e7          	jalr	-366(ra) # 49e <putc>
        putc(fd, c);
 614:	85ca                	mv	a1,s2
 616:	8556                	mv	a0,s5
 618:	00000097          	auipc	ra,0x0
 61c:	e86080e7          	jalr	-378(ra) # 49e <putc>
      }
      state = 0;
 620:	4981                	li	s3,0
 622:	b765                	j	5ca <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 624:	008b0913          	addi	s2,s6,8
 628:	4685                	li	a3,1
 62a:	4629                	li	a2,10
 62c:	000b2583          	lw	a1,0(s6)
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e8e080e7          	jalr	-370(ra) # 4c0 <printint>
 63a:	8b4a                	mv	s6,s2
      state = 0;
 63c:	4981                	li	s3,0
 63e:	b771                	j	5ca <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 640:	008b0913          	addi	s2,s6,8
 644:	4681                	li	a3,0
 646:	4629                	li	a2,10
 648:	000b2583          	lw	a1,0(s6)
 64c:	8556                	mv	a0,s5
 64e:	00000097          	auipc	ra,0x0
 652:	e72080e7          	jalr	-398(ra) # 4c0 <printint>
 656:	8b4a                	mv	s6,s2
      state = 0;
 658:	4981                	li	s3,0
 65a:	bf85                	j	5ca <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 65c:	008b0913          	addi	s2,s6,8
 660:	4681                	li	a3,0
 662:	4641                	li	a2,16
 664:	000b2583          	lw	a1,0(s6)
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	e56080e7          	jalr	-426(ra) # 4c0 <printint>
 672:	8b4a                	mv	s6,s2
      state = 0;
 674:	4981                	li	s3,0
 676:	bf91                	j	5ca <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 678:	008b0793          	addi	a5,s6,8
 67c:	f8f43423          	sd	a5,-120(s0)
 680:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 684:	03000593          	li	a1,48
 688:	8556                	mv	a0,s5
 68a:	00000097          	auipc	ra,0x0
 68e:	e14080e7          	jalr	-492(ra) # 49e <putc>
  putc(fd, 'x');
 692:	85ea                	mv	a1,s10
 694:	8556                	mv	a0,s5
 696:	00000097          	auipc	ra,0x0
 69a:	e08080e7          	jalr	-504(ra) # 49e <putc>
 69e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6a0:	03c9d793          	srli	a5,s3,0x3c
 6a4:	97de                	add	a5,a5,s7
 6a6:	0007c583          	lbu	a1,0(a5)
 6aa:	8556                	mv	a0,s5
 6ac:	00000097          	auipc	ra,0x0
 6b0:	df2080e7          	jalr	-526(ra) # 49e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6b4:	0992                	slli	s3,s3,0x4
 6b6:	397d                	addiw	s2,s2,-1
 6b8:	fe0914e3          	bnez	s2,6a0 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6bc:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6c0:	4981                	li	s3,0
 6c2:	b721                	j	5ca <vprintf+0x60>
        s = va_arg(ap, char*);
 6c4:	008b0993          	addi	s3,s6,8
 6c8:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6cc:	02090163          	beqz	s2,6ee <vprintf+0x184>
        while(*s != 0){
 6d0:	00094583          	lbu	a1,0(s2)
 6d4:	c9a1                	beqz	a1,724 <vprintf+0x1ba>
          putc(fd, *s);
 6d6:	8556                	mv	a0,s5
 6d8:	00000097          	auipc	ra,0x0
 6dc:	dc6080e7          	jalr	-570(ra) # 49e <putc>
          s++;
 6e0:	0905                	addi	s2,s2,1
        while(*s != 0){
 6e2:	00094583          	lbu	a1,0(s2)
 6e6:	f9e5                	bnez	a1,6d6 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6e8:	8b4e                	mv	s6,s3
      state = 0;
 6ea:	4981                	li	s3,0
 6ec:	bdf9                	j	5ca <vprintf+0x60>
          s = "(null)";
 6ee:	00000917          	auipc	s2,0x0
 6f2:	27290913          	addi	s2,s2,626 # 960 <malloc+0x12c>
        while(*s != 0){
 6f6:	02800593          	li	a1,40
 6fa:	bff1                	j	6d6 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6fc:	008b0913          	addi	s2,s6,8
 700:	000b4583          	lbu	a1,0(s6)
 704:	8556                	mv	a0,s5
 706:	00000097          	auipc	ra,0x0
 70a:	d98080e7          	jalr	-616(ra) # 49e <putc>
 70e:	8b4a                	mv	s6,s2
      state = 0;
 710:	4981                	li	s3,0
 712:	bd65                	j	5ca <vprintf+0x60>
        putc(fd, c);
 714:	85d2                	mv	a1,s4
 716:	8556                	mv	a0,s5
 718:	00000097          	auipc	ra,0x0
 71c:	d86080e7          	jalr	-634(ra) # 49e <putc>
      state = 0;
 720:	4981                	li	s3,0
 722:	b565                	j	5ca <vprintf+0x60>
        s = va_arg(ap, char*);
 724:	8b4e                	mv	s6,s3
      state = 0;
 726:	4981                	li	s3,0
 728:	b54d                	j	5ca <vprintf+0x60>
    }
  }
}
 72a:	70e6                	ld	ra,120(sp)
 72c:	7446                	ld	s0,112(sp)
 72e:	74a6                	ld	s1,104(sp)
 730:	7906                	ld	s2,96(sp)
 732:	69e6                	ld	s3,88(sp)
 734:	6a46                	ld	s4,80(sp)
 736:	6aa6                	ld	s5,72(sp)
 738:	6b06                	ld	s6,64(sp)
 73a:	7be2                	ld	s7,56(sp)
 73c:	7c42                	ld	s8,48(sp)
 73e:	7ca2                	ld	s9,40(sp)
 740:	7d02                	ld	s10,32(sp)
 742:	6de2                	ld	s11,24(sp)
 744:	6109                	addi	sp,sp,128
 746:	8082                	ret

0000000000000748 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 748:	715d                	addi	sp,sp,-80
 74a:	ec06                	sd	ra,24(sp)
 74c:	e822                	sd	s0,16(sp)
 74e:	1000                	addi	s0,sp,32
 750:	e010                	sd	a2,0(s0)
 752:	e414                	sd	a3,8(s0)
 754:	e818                	sd	a4,16(s0)
 756:	ec1c                	sd	a5,24(s0)
 758:	03043023          	sd	a6,32(s0)
 75c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 760:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 764:	8622                	mv	a2,s0
 766:	00000097          	auipc	ra,0x0
 76a:	e04080e7          	jalr	-508(ra) # 56a <vprintf>
}
 76e:	60e2                	ld	ra,24(sp)
 770:	6442                	ld	s0,16(sp)
 772:	6161                	addi	sp,sp,80
 774:	8082                	ret

0000000000000776 <printf>:

void
printf(const char *fmt, ...)
{
 776:	711d                	addi	sp,sp,-96
 778:	ec06                	sd	ra,24(sp)
 77a:	e822                	sd	s0,16(sp)
 77c:	1000                	addi	s0,sp,32
 77e:	e40c                	sd	a1,8(s0)
 780:	e810                	sd	a2,16(s0)
 782:	ec14                	sd	a3,24(s0)
 784:	f018                	sd	a4,32(s0)
 786:	f41c                	sd	a5,40(s0)
 788:	03043823          	sd	a6,48(s0)
 78c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 790:	00840613          	addi	a2,s0,8
 794:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 798:	85aa                	mv	a1,a0
 79a:	4505                	li	a0,1
 79c:	00000097          	auipc	ra,0x0
 7a0:	dce080e7          	jalr	-562(ra) # 56a <vprintf>
}
 7a4:	60e2                	ld	ra,24(sp)
 7a6:	6442                	ld	s0,16(sp)
 7a8:	6125                	addi	sp,sp,96
 7aa:	8082                	ret

00000000000007ac <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ac:	1141                	addi	sp,sp,-16
 7ae:	e422                	sd	s0,8(sp)
 7b0:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7b2:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7b6:	00000797          	auipc	a5,0x0
 7ba:	1ca7b783          	ld	a5,458(a5) # 980 <freep>
 7be:	a805                	j	7ee <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7c0:	4618                	lw	a4,8(a2)
 7c2:	9db9                	addw	a1,a1,a4
 7c4:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7c8:	6398                	ld	a4,0(a5)
 7ca:	6318                	ld	a4,0(a4)
 7cc:	fee53823          	sd	a4,-16(a0)
 7d0:	a091                	j	814 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7d2:	ff852703          	lw	a4,-8(a0)
 7d6:	9e39                	addw	a2,a2,a4
 7d8:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7da:	ff053703          	ld	a4,-16(a0)
 7de:	e398                	sd	a4,0(a5)
 7e0:	a099                	j	826 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7e2:	6398                	ld	a4,0(a5)
 7e4:	00e7e463          	bltu	a5,a4,7ec <free+0x40>
 7e8:	00e6ea63          	bltu	a3,a4,7fc <free+0x50>
{
 7ec:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7ee:	fed7fae3          	bgeu	a5,a3,7e2 <free+0x36>
 7f2:	6398                	ld	a4,0(a5)
 7f4:	00e6e463          	bltu	a3,a4,7fc <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7f8:	fee7eae3          	bltu	a5,a4,7ec <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7fc:	ff852583          	lw	a1,-8(a0)
 800:	6390                	ld	a2,0(a5)
 802:	02059713          	slli	a4,a1,0x20
 806:	9301                	srli	a4,a4,0x20
 808:	0712                	slli	a4,a4,0x4
 80a:	9736                	add	a4,a4,a3
 80c:	fae60ae3          	beq	a2,a4,7c0 <free+0x14>
    bp->s.ptr = p->s.ptr;
 810:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 814:	4790                	lw	a2,8(a5)
 816:	02061713          	slli	a4,a2,0x20
 81a:	9301                	srli	a4,a4,0x20
 81c:	0712                	slli	a4,a4,0x4
 81e:	973e                	add	a4,a4,a5
 820:	fae689e3          	beq	a3,a4,7d2 <free+0x26>
  } else
    p->s.ptr = bp;
 824:	e394                	sd	a3,0(a5)
  freep = p;
 826:	00000717          	auipc	a4,0x0
 82a:	14f73d23          	sd	a5,346(a4) # 980 <freep>
}
 82e:	6422                	ld	s0,8(sp)
 830:	0141                	addi	sp,sp,16
 832:	8082                	ret

0000000000000834 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 834:	7139                	addi	sp,sp,-64
 836:	fc06                	sd	ra,56(sp)
 838:	f822                	sd	s0,48(sp)
 83a:	f426                	sd	s1,40(sp)
 83c:	f04a                	sd	s2,32(sp)
 83e:	ec4e                	sd	s3,24(sp)
 840:	e852                	sd	s4,16(sp)
 842:	e456                	sd	s5,8(sp)
 844:	e05a                	sd	s6,0(sp)
 846:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 848:	02051493          	slli	s1,a0,0x20
 84c:	9081                	srli	s1,s1,0x20
 84e:	04bd                	addi	s1,s1,15
 850:	8091                	srli	s1,s1,0x4
 852:	0014899b          	addiw	s3,s1,1
 856:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 858:	00000517          	auipc	a0,0x0
 85c:	12853503          	ld	a0,296(a0) # 980 <freep>
 860:	c515                	beqz	a0,88c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 862:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 864:	4798                	lw	a4,8(a5)
 866:	02977f63          	bgeu	a4,s1,8a4 <malloc+0x70>
 86a:	8a4e                	mv	s4,s3
 86c:	0009871b          	sext.w	a4,s3
 870:	6685                	lui	a3,0x1
 872:	00d77363          	bgeu	a4,a3,878 <malloc+0x44>
 876:	6a05                	lui	s4,0x1
 878:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 87c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 880:	00000917          	auipc	s2,0x0
 884:	10090913          	addi	s2,s2,256 # 980 <freep>
  if(p == (char*)-1)
 888:	5afd                	li	s5,-1
 88a:	a88d                	j	8fc <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 88c:	00000797          	auipc	a5,0x0
 890:	0fc78793          	addi	a5,a5,252 # 988 <base>
 894:	00000717          	auipc	a4,0x0
 898:	0ef73623          	sd	a5,236(a4) # 980 <freep>
 89c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 89e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8a2:	b7e1                	j	86a <malloc+0x36>
      if(p->s.size == nunits)
 8a4:	02e48b63          	beq	s1,a4,8da <malloc+0xa6>
        p->s.size -= nunits;
 8a8:	4137073b          	subw	a4,a4,s3
 8ac:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8ae:	1702                	slli	a4,a4,0x20
 8b0:	9301                	srli	a4,a4,0x20
 8b2:	0712                	slli	a4,a4,0x4
 8b4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8b6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8ba:	00000717          	auipc	a4,0x0
 8be:	0ca73323          	sd	a0,198(a4) # 980 <freep>
      return (void*)(p + 1);
 8c2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8c6:	70e2                	ld	ra,56(sp)
 8c8:	7442                	ld	s0,48(sp)
 8ca:	74a2                	ld	s1,40(sp)
 8cc:	7902                	ld	s2,32(sp)
 8ce:	69e2                	ld	s3,24(sp)
 8d0:	6a42                	ld	s4,16(sp)
 8d2:	6aa2                	ld	s5,8(sp)
 8d4:	6b02                	ld	s6,0(sp)
 8d6:	6121                	addi	sp,sp,64
 8d8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8da:	6398                	ld	a4,0(a5)
 8dc:	e118                	sd	a4,0(a0)
 8de:	bff1                	j	8ba <malloc+0x86>
  hp->s.size = nu;
 8e0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8e4:	0541                	addi	a0,a0,16
 8e6:	00000097          	auipc	ra,0x0
 8ea:	ec6080e7          	jalr	-314(ra) # 7ac <free>
  return freep;
 8ee:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8f2:	d971                	beqz	a0,8c6 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8f4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8f6:	4798                	lw	a4,8(a5)
 8f8:	fa9776e3          	bgeu	a4,s1,8a4 <malloc+0x70>
    if(p == freep)
 8fc:	00093703          	ld	a4,0(s2)
 900:	853e                	mv	a0,a5
 902:	fef719e3          	bne	a4,a5,8f4 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 906:	8552                	mv	a0,s4
 908:	00000097          	auipc	ra,0x0
 90c:	b5e080e7          	jalr	-1186(ra) # 466 <sbrk>
  if(p == (char*)-1)
 910:	fd5518e3          	bne	a0,s5,8e0 <malloc+0xac>
        return 0;
 914:	4501                	li	a0,0
 916:	bf45                	j	8c6 <malloc+0x92>
