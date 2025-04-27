#!/usr/bin/python

from __future__ import print_function

import inspect
#import lldb
import gdb
import optparse
import shlex
import sys
#from SwiftString import SwiftString

class DumpSwiftString:
    program = 'dumpswiftstring'

    @classmethod
    def register_lldb_command(cls, debugger, module_name):
        parser = cls.create_options()
        cls.__doc__ = parser.format_help()
        # Add any commands contained in this module to LLDB
        command = 'command script add -c %s.%s %s' % (module_name,
                                                      cls.__name__,
                                                      cls.program)
        debugger.HandleCommand(command)
        print('The "{0}" command has been installed, type "help {0}" or "{0} '
              '--help" for detailed help.'.format(cls.program))

    @classmethod
    def create_options(cls):

        usage = "usage: %prog [<hi word register> <lo word register>] "
        description = ('This command is meant to be an example of how to make '
                       'an LLDB command that does something useful, follows '
                       'best practices, and exploits the SB API. '
                       'Specifically, this command computes the aggregate '
                       'and average size of the variables in the current '
                       'frame and allows you to tweak exactly which variables '
                       'are to be accounted in the computation.')

        # Pass add_help_option = False, since this keeps the command in line
        #  with lldb commands, and we wire up "help command" to work by
        # providing the long & short help methods below.
        parser = optparse.OptionParser(
            description=description,
            prog=cls.program,
            usage=usage,
            add_help_option=False)

        return parser

    def get_short_help(self):
        return "Example command for use in debugging"

    def get_long_help(self):
        return self.help_string

    def __init__(self, debugger, unused):
        self.parser = self.create_options()
        self.help_string = self.parser.format_help()

    def __call__(self, debugger, command, exe_ctx, result):
        # Use the Shell Lexer to properly parse up command options just like a
        # shell would
        command_args = shlex.split(command)

        try:
            (options, args) = self.parser.parse_args(command_args)
        except:
            # if you don't handle exceptions, passing an incorrect argument to
            # the OptionParser will cause LLDB to exit (courtesy of OptParse
            # dealing with argument errors by throwing SystemExit)
            result.SetError("option parsing failed")
            return

        # Always get program state from the lldb.SBExecutionContext passed
        # in as exe_ctx
        frame = exe_ctx.GetFrame()
        if not frame.IsValid():
            result.SetError("invalid frame")
            return

        argc = len(args)

        if argc == 0:
            hi_reg = "rsi"
            lo_reg = "rdi"
        elif argc == 2:
            hi_reg = args[0]
            lo_reg = args[1]
        else:
            print("Invalid arguments")
            return

        hi_word = int(exe_ctx.frame.register[hi_reg].value, 16)
        lo_word = int(exe_ctx.frame.register[lo_reg].value, 16)
        string = SwiftString(hi_word, lo_word)
        string.dump()



def __lldb_init_module(debugger, dict):
    # Register all classes that have a register_lldb_command method
    for _name, cls in inspect.getmembers(sys.modules[__name__]):
        if inspect.isclass(cls) and callable(getattr(cls,
                                                     "register_lldb_command",
                                                     None)):
            cls.register_lldb_command(debugger, __name__)




class SwiftString:
    def __init__(self, hi_word, lo_word):
        self.hi_word = hi_word
        self.lo_word = lo_word


    def is_small(self):
        return (self.hi_word & (1 << 61) != 0)


    def is_large(self):
        return not self.is_small()


    def is_immortal(self):
        return (self.hi_word & (1 << 63) == 0)


    def is_mortal(self):
        return not self.is_immortal()


    def is_ascii(self):
        if self.is_small():
            return (self.hi_word & (1 << 62) != 0)
        else:
            return (self.lo_word & (1 << 63) != 0)


    def count(self):
        if self.is_small():
            return (self.hi_word >> 56) & 0xf
        else:
            return (self.lo_word & 0x0000ffffffffffff)


    def is_nfc(self):
        if self.is_small():
            return None
        else:
            return (self.lo_word & (1 << 62) != 0)


    def is_natively_stored(self):
        if self.is_small():
            return None
        else:
            return (self.lo_word & (1 << 61) != 0)


    def is_tail_allocated(self):
        if self.is_small():
            return None
        else:
            return (self.lo_word & (1 << 60) != 0)


    def is_foreign(self):
        return (self.hi_word & (1 << 60) != 0)


    def is_bridged(self):
        return self.is_large() and ((self.hi_word & 1 << 62) != 0)


    def objectaddress(self):
        if self.is_large():
            return self.hi_word & 0x00ffffffffffffffff
        else:
            return None


    def byte_buffer(self):
        if self.is_small():
            buffer = []
            for i in range(0, 8):
                byte = (self.lo_word >> (i * 8)) & 0xff
                buffer.append(byte)

            for i in range(0, 7):
                byte = (self.hi_word >> (i * 8)) & 0xff
                buffer.append(byte)

            return buffer
        else:
            return None


    def dump(self):
        print("HI: 0x%016x LO: 0x%016x" % (self.hi_word, self.lo_word))
        if self.is_small():
            print("Small String")
        else:
            print("Large String")

        print("Immortal: %s" % self.is_immortal())
        print("ASCII:    %s" % self.is_ascii())
        print("Count:    %d" % self.count())

        if self.is_small():
            buffer = self.byte_buffer()
            print("Bytes:    [%s]" % ', '.join(map(str, buffer)))
            print("String:   '%s'" % ''.join(map(chr, buffer)))
        else:
            print("NFC:      %s" % self.is_nfc())
            print("Foreign:  %s" % self.is_foreign())
            print("Address:  %016x" % self.objectaddress())
