#!/usr/bin/python

from __future__ import print_function

import inspect
import lldb
import optparse
import shlex
import sys
from SwiftString import SwiftString

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
