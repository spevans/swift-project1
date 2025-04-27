set step-mode on
set disassemble-next-line on
display/i $pc
set architecture i386:x86-64
set disassembly-flavor intel
break abort
break debugger_hook
define trem
target remote localhost:1234
end
