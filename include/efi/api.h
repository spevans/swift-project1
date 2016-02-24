#ifndef __EFI_API_H__
#define __EFI_API_H__

typedef struct {
        efi_table_header_t hdr;

        //
        // Time services
        //
        void *get_Time;
        void *set_time;
        void *get_wakeup_time;
        void *set_wakeup_time;

        //
        // Virtual memory services
        //
        void *set_virtual_address_map;
        void *convert_pointer;

        //
        // Variable serviers
        //
        void *get_variable;
        void *get_next_variable_name;
        void *set_variable;

        //
        // Misc
        //
        void *get_next_high_monotonic_count;
        void *reset_system;
} efi_runtime_services_t;


typedef struct {
        efi_table_header_t hdr;

        //
        // Task priority functions
        //
        void *raise_t_p_l;
        void *restore_t_p_l;

        //
        // Memory functions
        //
        void *allocate_pages;
        void *free_pages;
        void *get_memory_map;
        void *allocate_pool;
        void *free_pool;

        //
        // Event & timer functions
        //
        void *create_event;
        void *set_timer;
        void *wait_for_event;
        void *signal_event;
        void *close_event;
        void *check_event;

        //
        // Protocol handler functions
        //
        void *install_protocol_interface;
        void *reinstall_protocol_interface;
        void *uninstall_protocol_interface;
        void *handle_protocol;
        void *p_c_handle_protocol;
        void *register_protocol_notify;
        void *locate_handle;
        void *locate_device_path;
        void *install_configuration_table;

        //
        // Image functions
        //
        void *load_image;
        void *start_image;
        void *exit;
        void *unload_image;
        void *exit_boot_services;

        //
        // Misc functions
        //
        void *get_next_monotonic_count;
        void *stall;
        void *set_watchdog_timer;

        //
        // DriverSupport Services
        //
        void *connect_controller;
        void *disconnect_controller;

        //
        // Open and Close Protocol Services
        //
        void *open_protocol;
        void *close_protocol;
        void *open_protocol_information;

        //
        // Library Services
        //
        void *protocols_per_handle;
        void *locate_handle_buffer;
        void *locate_protocol;
        void *install_multiple_protocol_interfaces;
        void *uninstall_multiple_protocol_interfaces;

        //
        // 32-bit CRC Services
        //
        void *calculate_crc32;

        //
        // Misc Services
        //
        void *copy_mem;
        void *set_mem;
        void *create_event_ex;

} efi_boot_services_t;


typedef struct {
        efi_guid_t vendor_guid;
        void *vendor_table;
} efi_config_table_t;


typedef struct {
        efi_table_header_t hdr;
        uint16_t *fw_vendor;    // uint64_t ptr to CHAR16
        uint32_t fw_revision;   // 16.16 major.minor
        uint32_t _pad;
        void *con_in_handle;
        efi_simple_input_t *con_in;
        void *con_out_handle;
        efi_simple_output_t *con_out;
        void *std_err_handle;
        efi_simple_output_t *std_err;
        efi_runtime_services_t *runtime_services;
        efi_boot_services_t *boot_services;
        uint64_t nr_entries;
        efi_config_table_t *config_table;
} efi_system_table_t;


extern efi_status_t
efi_call2(void *func, uint64_t data1, uint64_t data2);

extern efi_status_t
efi_call3(void *func, uint64_t data1, uint64_t data2, uint64_t data3);

extern efi_status_t
efi_call4(void *func, uint64_t data1, uint64_t data2, uint64_t data3,
          uint64_t data4);

extern efi_status_t
efi_call5(void *func, uint64_t data1, uint64_t data2, uint64_t data3,
          uint64_t data4, uint64_t data5);


#endif  // __EFI_API_H__
