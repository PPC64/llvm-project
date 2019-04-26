# RUN: llvm-mc -triple powerpc64-unknown-unknown -filetype=obj %s -o %t
# RUN: llvm-objdump -s -j .symtab %t | FileCheck %s

	.text
	.abiversion 2

	.globl	func
	# Mimick FreeBSD weak function/reference
	.weak	weak_func
	.equ	weak_func, func

	.p2align	2
	.type	func,@function
func:
.Lfunc_begin0:
.Lfunc_gep0:
	addis 2, 12, .TOC.-.Lfunc_gep0@ha
	addi 2, 2, .TOC.-.Lfunc_gep0@l
.Lfunc_lep0:
	.localentry	func, .Lfunc_lep0-.Lfunc_gep0
	# Simple access to global var to force TOC usage:
	# return g_var++;
	addis 3, 2, g_var@toc@ha
	addi 3, 3, g_var@toc@l
	lwz 4, 0(3)
	addi 5, 4, 1
	stw 5, 0(3)
	extsw 3, 4
	blr
	.long	0
	.quad	0
.Lfunc_end0:
	.size	func, .Lfunc_end0-.Lfunc_begin0
	.type	g_var,@object
	.lcomm	g_var,4,4

	.addrsig
	.addrsig_sym g_var

# We expect the st_other byte of the weak_func symbol to be 0x60
# (localentry = gep + 2 instructions)
#
# Currently, llvm-objdump does not support displaying
# st_other's PPC64 specific flags, thus we check the
# result of the hexdump of .symtab section instead.
#
# Elf64_Sym:
#	Elf64_Word	st_name  = 0x00000025 ("weak_func" offset in strtab)
#	unsigned char	st_info  = 0x22 (bind = STB_WEAK, type = STT_FUNC)
#	unsigned char	st_other = 0x60
#		(localentry = 0b011 (gep + 2 instructions),
#		 reserved   = 0b000,
#		 visibility = 0b00 (STV_DEFAULT))
#	Elf64_Half	st_shndx = 0x0002
#	Elf64_Addr	st_value = 0x0000000000000000
#	Elf64_Xword	st_size  = 0x0000000000000030

# CHECK:  0070 00000000 00000030 00000025 22600002
