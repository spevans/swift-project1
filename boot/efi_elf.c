#include <efi.h>
#include <klibc.h>
#include <elf.h>


static char *
string_entry(struct elf_file *file, Elf64_Shdr *strtab, unsigned int idx)
{
        if (idx >= strtab->sh_size) {
                uprintf("Cant find string at idx=%u\n", idx);
                return NULL;
        }

        return file->file_data + strtab->sh_offset + idx;
}


Elf64_Shdr *
elf_section_header(struct elf_file *file, size_t idx)
{
        if (idx > file->elf_hdr->e_shnum) {
                return NULL;
        }

        return file->section_headers + idx;
}


Elf64_Phdr *
elf_program_header(struct elf_file *file, size_t idx)
{
        if (idx >= file->elf_hdr->e_phnum) {
                uprintf("Error: accessing invalid program header: %lu\n", idx);
                return NULL;
        }
        return file->program_headers + idx;
}


void *
elf_program_data(struct elf_file *file, Elf64_Phdr *header)
{
        return file->file_data + header->p_offset;
}



static char *
section_name(struct elf_file *file, Elf64_Shdr *header)
{
        return string_entry(file, file->sh_string_table, header->sh_name);
}


static void
dump_section_header(struct elf_file *file, Elf64_Shdr *header)
{
        uprintf("%-30s", section_name(file, header));
        uprintf("%8x\t", header->sh_type);
        uprintf("%016lx\t", header->sh_addr);
        uprintf("%016lx\t", header->sh_offset);
        uprintf("%8lx\t", header->sh_size);
        uprintf("%8lx\t", header->sh_flags);
        uprintf("%u\t", header->sh_link);
        uprintf("%u\t", header->sh_info);
        uprintf("%lu\t", header->sh_addralign);
        uprintf("%lu\n", header->sh_entsize);
}


static void
dump_program_header(Elf64_Phdr *hdr)
{

        //char *type = "OTHER";
        char *seg_type = (hdr->p_flags & PF_X) ? "CODE " : "DATA ";

        //if (hdr->p_type < program_types_count) {
        //        type = program_types[hdr->p_type];
        //}
        uprintf("%2x %016lX   %016lX   %016lX   %016lX   %-10s %8lX\n",
               hdr->p_type, hdr->p_offset, hdr->p_vaddr, hdr->p_filesz,
               hdr->p_memsz, seg_type, hdr->p_align);
}


static void
dump_elf_header(struct elf_file *file)
{
        Elf64_Ehdr *elf_hdr = file->elf_hdr;
        uprintf("Entry point addr: 0x%16lX\n", elf_hdr->e_entry);
        uprintf("Program header table offset: 0x%-16lX\n", elf_hdr->e_phoff);
        uprintf("Section header table offset: 0x%-16lX\n", elf_hdr->e_shoff);
        uprintf("Processor flags: 0x%8.8X\n", elf_hdr->e_flags);
        uprintf("ELF header size: %u (%lu)\n", elf_hdr->e_ehsize,
                sizeof(Elf64_Ehdr));
        uprintf("Program header table entry size/count: %d/%d\n",
               elf_hdr->e_phentsize, elf_hdr->e_phnum);
        uprintf("Section header table entry size/count: %d/%d\n",
               elf_hdr->e_shentsize, elf_hdr->e_shnum);
        uprintf("Section header string table index: %d\n", elf_hdr->e_shstrndx);

        uprintf("\nProgram Headers:\n");

        for (int idx = 0; idx < elf_hdr->e_phnum; idx++) {
                dump_program_header(elf_program_header(file, idx));
        }
}


static int
find_tables(struct elf_file *file)
{
        Elf64_Ehdr *elf_hdr = file->elf_hdr;
        file->section_headers = file->file_data + elf_hdr->e_shoff;
        file->program_headers = file->file_data + elf_hdr->e_phoff;
        file->sh_string_table = file->section_headers + elf_hdr->e_shstrndx;
        size_t idx;

        for (idx = 0; idx < file->elf_hdr->e_shnum; idx++) {
                Elf64_Shdr *header = file->section_headers + idx;
                uprintf("[%2lu]: ", idx);
                dump_section_header(file, header);
                if (idx == file->elf_hdr->e_shstrndx) continue;
                if (header->sh_type == SHT_STRTAB) {
                        file->string_table = header;
                }
                else if (header->sh_type == SHT_SYMTAB) {
                        file->symbol_table = header;
                }
        }
        uprintf("\n");
        if (file->string_table == NULL) {
                uprintf("Cant find string table\n");
                return 0;
        }
        if (file->symbol_table == NULL) {
                uprintf("Cant find symbol table\n");
                return 0;
        }

        return 1;
}


static int
validate_elf_header(struct elf_file *file)
{
        Elf64_Ehdr *elf_hdr = file->elf_hdr;
        unsigned char *e_ident = elf_hdr->e_ident;

        if (e_ident[0] != ELFMAG0 || e_ident[1] != ELFMAG1
            || e_ident[2] != ELFMAG2 || e_ident[3] != ELFMAG3) {
                uprintf("Error: not an ELF file\n");
                return 0;
        }

        if (e_ident[EI_CLASS] != ELFCLASS64) {
                uprintf("Error: not a 64bit file\n");
                return 0;
        }

        if (e_ident[EI_DATA] != ELFDATA2LSB) {
                uprintf("Error: not little endian\n");
                return 0;
        }

        if (e_ident[EI_VERSION] != EV_CURRENT) {
                uprintf("Error: version is not current\n");
                return 0;
        }

        if (e_ident[EI_OSABI] != ELFOSABI_SYSV) {
                uprintf("Error: OS ABI is not linux\n");
                return 0;
        }

        if (elf_hdr->e_machine != EM_X86_64) {
                uprintf("Machine (%d) is not a x86_64\n", elf_hdr->e_machine);
                return 0;
        }

        if (elf_hdr->e_version != EV_CURRENT) {
                uprintf("Version (%d) is not EV_CURRENT\n",
                        elf_hdr->e_version);
                return 0;
        }

        if (sizeof(Elf64_Shdr) != elf_hdr->e_shentsize) {
                uprintf("Section header table entry size is wrong (%u != %lu)\n",
                        elf_hdr->e_shentsize, sizeof(Elf64_Shdr));
                return 0;
        }

        return 1;
}


efi_status_t
elf_init_file(struct elf_file *kernel_image)
{
        kernel_image->elf_hdr = (Elf64_Ehdr *)(kernel_image->file_data);
        if (!validate_elf_header(kernel_image)) {
                uprintf("Invalid ELF header\n");
                return EFI_COMPROMISED_DATA;
        }


        if (!find_tables(kernel_image)) {
                uprintf("Cant find tables\n");
                return EFI_LOAD_ERROR;
        }
        dump_elf_header(kernel_image);

        return EFI_SUCCESS;
}
