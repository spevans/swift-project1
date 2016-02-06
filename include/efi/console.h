#ifndef __EFI_CONSOLE_H__
#define __EFI_CONSOLE_H__

#define EFI_CONSOLE_CONTROL_GUID        \
        { 0xf42f7782, 0x12e, 0x4c12, { 0x99, 0x56, 0x49, 0xf9, 0x43, 0x4, 0xf7, 0x21 }}


typedef struct {
        uint16_t scan_code;
        uint16_t unicode_char;
} efi_input_key_t;


struct _efi_simple_input;

typedef
efi_status_t (*efi_input_reset_t)(struct _efi_simple_input *this,
                                  efi_boolean extra_tests);

typedef
efi_status_t (*efi_input_read_key)(struct _efi_simple_input *this,
                                   efi_input_key_t *key);


typedef struct _efi_simple_input {
        efi_input_reset_t reset;
        efi_input_read_key read_key;
        void *wait_for_key;
} efi_simple_input_t;


struct _efi_simple_output;

typedef
efi_status_t (*efi_text_reset_t)(struct _efi_simple_output *this,
                                 efi_boolean extra_tests);

typedef
efi_status_t (*efi_text_output_string_t)(struct _efi_simple_output *this,
                                         uint16_t *string);

typedef
efi_status_t (*efi_text_test_string_t)(struct _efi_simple_output *this,
                                       uint16_t *string);


typedef
efi_status_t (*efi_text_query_mode_t)(struct _efi_simple_output *this,
                                      unsigned int mode, unsigned int *columns,
                                      unsigned int *rows);

typedef
efi_status_t (*efi_text_set_mode_t)(struct _efi_simple_output *this,
                                    unsigned int mode);

typedef
efi_status_t (*efi_text_set_attribute_t)(struct _efi_simple_output *this,
                                         unsigned int attribute);

typedef
efi_status_t (*efi_text_clear_screen_t)(struct _efi_simple_output *this);

typedef
efi_status_t (*efi_text_set_cursor_t)(struct _efi_simple_output *this,
                                      unsigned int column, unsigned int row);

typedef
efi_status_t (*efi_text_enable_cursor_t)(struct _efi_simple_output *this,
                                         efi_boolean enable);

typedef struct {
        int32_t max_mode;
        int32_t mode;
        int32_t attribute;
        int32_t cursor_col;
        int32_t cursor_row;
        efi_boolean cursor_visable;
} efi_text_output_mode_t;


typedef struct _efi_simple_output {
        efi_text_reset_t reset;
        efi_text_output_string_t output_string;
        efi_text_test_string_t test_string;
        efi_text_query_mode_t query_mode;
        efi_text_set_mode_t set_mode;
        efi_text_set_attribute_t set_attribute;
        efi_text_clear_screen_t clear_screen;
        efi_text_set_cursor_t set_cursor;
        efi_text_enable_cursor_t enable_cursor;
        efi_text_output_mode_t *current_mode;
} efi_simple_output_t;


struct _efi_console_control_interface;

typedef enum {
        efi_screen_text,
        efi_screen_graphics,
        efi_screen_test_max_value
} efi_console_screen_mode_t;

typedef
efi_status_t (*efi_console_get_mode_t)(struct _efi_console_control_interface *this,
                                       efi_console_screen_mode_t *mode,
                                       efi_boolean *uga_exists,
                                       efi_boolean *stdin_locked);

typedef
efi_status_t (*efi_console_set_mode_t)(struct _efi_console_control_interface *this,
                                       efi_console_screen_mode_t *mode);

typedef struct _efi_console_control_interface {
        efi_console_get_mode_t get_mode;
        efi_console_set_mode_t set_mode;
} efi_console_control_interface_t;

#endif  // __EFI_CONSOLE_H__
