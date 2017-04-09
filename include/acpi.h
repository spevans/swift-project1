/*
 * include/acpi.h
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Definitions of ACPI headers and tables
 *
 */

#ifndef __ACPI_H__
#define __ACPI_H__

#include <stdint.h>


struct rsdp1_header {
        char signature[8];
        uint8_t checksum;
        char oem_id[6];
        uint8_t revision;
        uint32_t rsdt_addr;
} __attribute__((packed));


struct rsdp2_header {
        struct rsdp1_header rsdp1;
        uint32_t length;
        uint64_t xsdt_addr;
        uint8_t checksum;
        uint8_t reserved[3];
} __attribute__((packed));


// Generic Address Structure
struct acpi_gas {
    uint8_t address_space_id;
    uint8_t register_bit_width;
    uint8_t register_bit_offset;
    uint8_t access_size;
    uint64_t address;
} __attribute__((packed));


// Firmware ACPI Control Structure (FACS)
struct acpi_facs_table {
        char signature[4];      // FACS
        uint32_t length;
        uint32_t hardware_signature;
        uint32_t firmware_waking_vector;
        uint32_t global_lock;
        uint32_t firmware_ctl_flags;
        uint64_t x_firmware_waking_vector;
        uint8_t version;
        uint8_t reserved1[3];
        uint32_t ospm_flags;
        uint8_t reserved2[24];
}__attribute__((packed));


// System description table header
struct acpi_sdt_header {
        char signature[4];
        uint32_t length;
        uint8_t revision;
        uint8_t checksum;
        char oem_id[6];
        char oem_table_id[8];
        uint32_t oem_revision;
        char creator_id[4];
        uint32_t creator_rev;
} __attribute__((packed));


// PCI Memory Configuration Table (MCFG)
struct acpi_mcfg_table {
        struct acpi_sdt_header header;
        char reserved[8];
        // multiple struct acpi_mcfg_config_entry
} __attribute__((packed));

struct acpi_mcfg_config_entry {
        uint64_t base_address;
        uint16_t segment_group;
        uint8_t start_bus;
        uint8_t end_bus;
        char reserved[4];
} __attribute__((packed));


// Fixed ACPI description Table (FACP)
struct acpi_facp_table {
        struct acpi_sdt_header header;  // 'FACP' signature
        uint32_t firmware_ctrl; // 32bit address
        uint32_t dsdt;          // 32bit address
        uint8_t reserved1;
        uint8_t preferred_pm_profile;
        uint16_t sci_int;
        uint32_t smi_cmd;
        uint8_t acpi_enable;
        uint8_t acpi_disable;
        uint8_t s4bios_req;
        uint8_t pstate_cnt;
        uint32_t pm1a_evt_blk;
        uint32_t pm1b_evt_blk;
        uint32_t pm1a_cnt_blk;
        uint32_t pm1b_cnt_blk;
        uint32_t pm2_cnt_blk;
        uint32_t pm_tmr_blk;
        uint32_t gpe0_blk;
        uint32_t gpe1_blk;
        uint8_t pm1_evt_len;
        uint8_t pm1_cnt_len;
        uint8_t pm2_cnt_len;
        uint8_t pm_tmr_len;
        uint8_t gpe0_blk_len;
        uint8_t gpe1_blk_len;
        uint8_t gpe1_base;
        uint8_t cst_cnt;
        uint16_t p_lvl2_lat;
        uint16_t p_lvl3_lat;
        uint16_t flush_size;
        uint16_t flush_stride;
        uint8_t duty_offset;
        uint8_t duty_width;
        uint8_t day_alrm;
        uint8_t mon_alrm;
        uint8_t century;
        uint16_t iapc_boot_arch;
        uint8_t reserved2;
        uint32_t feature_flags;
        struct acpi_gas reset_reg;
        uint8_t reset_value;
        uint16_t arm_boot_arch;
        uint8_t fadt_minor_version;
        uint64_t x_firmware_ctrl;
        uint64_t x_dsdt;
        struct acpi_gas x_pm1a_evt_blk;
        struct acpi_gas x_pm1b_evt_blk;
        struct acpi_gas x_pm1a_cnt_blk;
        struct acpi_gas x_pm1b_cnt_blk;
        struct acpi_gas x_pm2_cnt_blk;
        struct acpi_gas x_pm_tmr_blk;
        struct acpi_gas x_gpe0_blk;
        struct acpi_gas x_gpe1_blk;
        struct acpi_gas sleep_control_reg;
        struct acpi_gas sleep_status_reg;
        uint8_t hypervisor_vendor_id[8];
} __attribute__((packed));


// Multiple APIC Description Table (MADT)
struct acpi_madt_table {
        struct acpi_sdt_header header; // 'APIC' signature
        uint32_t local_int_controller_addr;
        uint32_t multiple_apic_flags;
} __attribute__((packed));


// High Precision Event Timers Table (HPET)
struct acpi_hpet_table {
        struct acpi_sdt_header header;  // 'HPET' signature
        uint32_t timer_block_id;
        struct acpi_gas base_address;   // Lower 32bit of address
        uint8_t hpet_number;
        uint16_t min_clock_ticks;
        uint8_t page_protection;
} __attribute__((packed));


// Embedded Controller Boot Resources Table (ECDT)
struct acpi_ecdt_table {
        struct acpi_sdt_header header;  // 'ECDT' signature
        struct acpi_gas ec_control;
        struct acpi_gas ec_data;
        uint32_t uid;
        uint8_t gpe_bit;
        // char ec_id asciiz name
} __attribute__((packed));


// Smart Battery Table (SBST)
struct acpi_sbst_table {
        struct acpi_sdt_header header; // 'SBST' signature
        uint32_t warning_energy_level; // values in mWh
        uint32_t low_energy_level;
        uint32_t critical_energy_level;
} __attribute__((packed));


// Windows ACPI Enlightenment Table (WAET)
struct acpi_waet_table {
        struct acpi_sdt_header header; // 'WAET' signature
        uint32_t device_flags;
} __attribute__((packed));


struct acpi_boot_table {
        struct acpi_sdt_header header; // 'BOOT' signature
        uint8_t cmos_index;
        uint8_t reserved[3];
} __attribute__((packed));


struct acpi_srat_table {
        struct acpi_sdt_header header; // 'SRAT' signature
        uint32_t table_revision;
        uint8_t reserved[8];
} __attribute__((packed));

// SRAT structures
struct srat_apic_affinity {
        uint8_t type;   // 0
        uint8_t length; // 16
        uint8_t proximity_domain_0_7;
        uint8_t apic_id;
        uint32_t flags;
        uint8_t local_sapic_eid;
        uint8_t proximity_domain_8_15;
        uint8_t proximity_domain_16_23;
        uint8_t proximity_domain_24_31;
        uint32_t clock_domain;
} __attribute__((packed));

struct srat_memory_affinity {
        uint8_t type;   // 1
        uint8_t length; // 40
        uint32_t proximity_domain;
        uint16_t reserved;
        uint32_t base_address_low;
        uint32_t base_address_high;
        uint32_t length_low;
        uint32_t length_high;
        uint32_t reserved2;
        uint32_t flags;
        uint64_t reserved3;
} __attribute__((packed));

struct srat_x2apic_affinity {
        uint8_t type;   // 2
        uint8_t length; // 24
        uint16_t reserved;
        uint32_t proximity_domain;
        uint32_t x2apic_id;
        uint32_t flags;
        uint32_t clock_domain;
        uint32_t reserved2;
} __attribute__((packed));

struct srat_gicc_affinity {
        uint8_t type;   // 3
        uint8_t length; // 18
        uint32_t proximity_domain;
        uint32_t acpi_processor_uid;
        uint32_t flags;
        uint32_t clock_domain;
} __attribute__((packed));


#endif  // __ACPI_H__
