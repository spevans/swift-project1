#ifndef _ELF_H
#define _ELF_H


/* 64-bit ELF base types. */
typedef uint64_t	Elf64_Addr;
typedef uint16_t	Elf64_Half;
typedef int16_t     Elf64_SHalf;
typedef uint64_t	Elf64_Off;
typedef int32_t     Elf64_Sword;
typedef uint32_t	Elf64_Word;
typedef uint64_t	Elf64_Xword;
typedef int64_t     Elf64_Sxword;

#define EI_NIDENT	16

typedef struct elf64_rela {
        Elf64_Addr r_offset;	/* Location at which to apply the action */
        Elf64_Xword r_info;	/* index and type of relocation */
        Elf64_Sxword r_addend;	/* Constant addend used to compute value */
} Elf64_Rela;


#define ELF64_R_SYM(i)			((i) >> 32)
#define ELF64_R_TYPE(i)			((i) & 0xffffffff)
#define R_X86_64_IRELATIVE      37      /* Adjust indirectly by program base */



typedef struct elf64_sym {
        Elf64_Word      st_name;	/* Symbol name, index in string tbl */
        unsigned char	st_info;	/* Type and binding attributes */
        unsigned char	st_other;	/* No defined meaning, 0 */
        Elf64_Half      st_shndx;	/* Associated section index */
        Elf64_Addr      st_value;	/* Value of the symbol */
        Elf64_Xword     st_size;	/* Associated symbol size */
} Elf64_Sym;

typedef struct elf64_hdr {
        unsigned char	e_ident[EI_NIDENT];	/* ELF "magic number" */
        Elf64_Half      e_type;
        Elf64_Half      e_machine;
        Elf64_Word      e_version;
        Elf64_Addr      e_entry;		/* Entry point virtual address */
        Elf64_Off       e_phoff;		/* Program header table file offset */
        Elf64_Off       e_shoff;		/* Section header table file offset */
        Elf64_Word      e_flags;
        Elf64_Half      e_ehsize;
        Elf64_Half      e_phentsize;
        Elf64_Half      e_phnum;
        Elf64_Half      e_shentsize;
        Elf64_Half      e_shnum;
        Elf64_Half      e_shstrndx;
} Elf64_Ehdr;


typedef struct elf64_phdr {
        Elf64_Word p_type;
        Elf64_Word p_flags;
        Elf64_Off  p_offset;		/* Segment file offset */
        Elf64_Addr p_vaddr;		/* Segment virtual address */
        Elf64_Addr p_paddr;		/* Segment physical address */
        Elf64_Xword p_filesz;		/* Segment size in file */
        Elf64_Xword p_memsz;		/* Segment size in memory */
        Elf64_Xword p_align;		/* Segment alignment, file & memory */
} Elf64_Phdr;


typedef struct elf64_shdr {
        Elf64_Word sh_name;		/* Section name, index in string tbl */
        Elf64_Word sh_type;		/* Type of section */
        Elf64_Xword sh_flags;		/* Miscellaneous section attributes */
        Elf64_Addr sh_addr;		/* Section virtual addr at execution */
        Elf64_Off sh_offset;		/* Section file offset */
        Elf64_Xword sh_size;		/* Size of section in bytes */
        Elf64_Word sh_link;		/* Index of another section */
        Elf64_Word sh_info;		/* Additional section information */
        Elf64_Xword sh_addralign;	/* Section alignment */
        Elf64_Xword sh_entsize;	/* Entry size if section holds table */
} Elf64_Shdr;

/* These constants define the permissions on sections in the program
   header, p_flags. */
#define PF_R		0x4
#define PF_W		0x2
#define PF_X		0x1

/* sh_type */
#define SHT_NULL        0
#define SHT_PROGBITS	1
#define SHT_SYMTAB      2
#define SHT_STRTAB      3
#define SHT_RELA        4
#define SHT_HASH        5
#define SHT_DYNAMIC     6
#define SHT_NOTE        7
#define SHT_NOBITS      8
#define SHT_REL         9
#define SHT_SHLIB       10
#define SHT_DYNSYM      11
#define SHT_NUM         12
#define SHT_LOPROC      0x70000000
#define SHT_HIPROC      0x7fffffff
#define SHT_LOUSER      0x80000000
#define SHT_HIUSER      0xffffffff

#define	EI_MAG0		0		/* e_ident[] indexes */
#define	EI_MAG1		1
#define	EI_MAG2		2
#define	EI_MAG3		3
#define	EI_CLASS	4
#define	EI_DATA		5
#define	EI_VERSION	6
#define	EI_OSABI	7
#define	EI_PAD		8

#define	ELFMAG0		0x7f		/* EI_MAG */
#define	ELFMAG1		'E'
#define	ELFMAG2		'L'
#define	ELFMAG3		'F'
#define	ELFMAG		"\177ELF"
#define	SELFMAG		4

#define	ELFCLASSNONE	0		/* EI_CLASS */
#define	ELFCLASS32      1
#define	ELFCLASS64      2
#define	ELFCLASSNUM     3

#define ELFDATANONE	0		/* e_ident[EI_DATA] */
#define ELFDATA2LSB	1
#define ELFDATA2MSB	2

#define EV_NONE		0		/* e_version, EI_VERSION */
#define EV_CURRENT	1
#define EV_NUM		2

/* e_ident[EI_OSABI] */
#define ELFOSABI_NONE	0
#define ELFOSABI_LINUX	3

/* e_machine */
#define EM_X86_64       62      /* AMD x86-64 architecture */

#endif /* _ELF_H */
