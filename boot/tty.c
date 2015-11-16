void print_string(char *str)
{
        char *screen = (char *)0xB8000;
        while(*str) {
                *screen++ = *str++;
                *screen++ = 0x7;
        }
}

void init_tty()
{
        print_string("init_tty()");
}
