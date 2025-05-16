boot.bin: boot.asm print.inc
	nasm boot.asm -f bin -o boot.bin

run:
	qemu-system-i386 -hda boot.bin

tester: tester.o
	ld tester.o -melf_i386 -o test
tester.o:tester.asm
	nasm tester.asm -g -felf32 -l tester.lst -o tester.o
