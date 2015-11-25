
void print_string(char *);
void halt();

static void print_and_halt(char *str) {
        print_string(str);
        halt();
}


void dyld_stub_binder() {
print_and_halt("dyld_stub_binder");
}

void CFErrorGetTypeID() { print_and_halt("Calling CFErrorGetTypeID\n"); }

void CFGetTypeID() { print_and_halt("Calling CFGetTypeID\n"); }

void CFSetGetValues() { print_and_halt("Calling CFSetGetValues\n"); }

void CFStringCompare() { print_and_halt("Calling CFStringCompare\n"); }

void CFStringCreateCopy() { print_and_halt("Calling CFStringCreateCopy\n"); }

void CFStringCreateWithSubstring() { print_and_halt("Calling CFStringCreateWithSubstring\n"); }

void CFStringFindWithOptions() { print_and_halt("Calling CFStringFindWithOptions\n"); }

void CFStringGetCStringPtr() { print_and_halt("Calling CFStringGetCStringPtr\n"); }

void CFStringGetCharacterAtIndex() { print_and_halt("Calling CFStringGetCharacterAtIndex\n"); }

void CFStringGetCharacters() { print_and_halt("Calling CFStringGetCharacters\n"); }

void CFStringGetCharactersPtr() { print_and_halt("Calling CFStringGetCharactersPtr\n"); }

void CFStringGetLength() { print_and_halt("Calling CFStringGetLength\n"); }

void NSClassFromString() { print_and_halt("Calling NSClassFromString\n"); }

void OBJC_CLASS_$_NSArray() { print_and_halt("Calling OBJC_CLASS_$_NSArray\n"); }

void OBJC_CLASS_$_NSDictionary() { print_and_halt("Calling OBJC_CLASS_$_NSDictionary\n"); }

void OBJC_CLASS_$_NSEnumerator() { print_and_halt("Calling OBJC_CLASS_$_NSEnumerator\n"); }

void OBJC_CLASS_$_NSError() { print_and_halt("Calling OBJC_CLASS_$_NSError\n"); }

void OBJC_CLASS_$_NSNumber() { print_and_halt("Calling OBJC_CLASS_$_NSNumber\n"); }

void OBJC_CLASS_$_NSObject() { print_and_halt("Calling OBJC_CLASS_$_NSObject\n"); }

void OBJC_CLASS_$_NSProcessInfo() { print_and_halt("Calling OBJC_CLASS_$_NSProcessInfo\n"); }

void OBJC_CLASS_$_NSSet() { print_and_halt("Calling OBJC_CLASS_$_NSSet\n"); }

void OBJC_CLASS_$_NSString() { print_and_halt("Calling OBJC_CLASS_$_NSString\n"); }

void OBJC_METACLASS_$_NSArray() { print_and_halt("Calling OBJC_METACLASS_$_NSArray\n"); }

void OBJC_METACLASS_$_NSDictionary() { print_and_halt("Calling OBJC_METACLASS_$_NSDictionary\n"); }

void OBJC_METACLASS_$_NSEnumerator() { print_and_halt("Calling OBJC_METACLASS_$_NSEnumerator\n"); }

void OBJC_METACLASS_$_NSError() { print_and_halt("Calling OBJC_METACLASS_$_NSError\n"); }

void OBJC_METACLASS_$_NSObject() { print_and_halt("Calling OBJC_METACLASS_$_NSObject\n"); }

void OBJC_METACLASS_$_NSSet() { print_and_halt("Calling OBJC_METACLASS_$_NSSet\n"); }

void OBJC_METACLASS_$_NSString() { print_and_halt("Calling OBJC_METACLASS_$_NSString\n"); }

void _DefaultRuneLocale() { print_and_halt("Calling _DefaultRuneLocale\n"); }

void _NSConcreteGlobalBlock() { print_and_halt("Calling _NSConcreteGlobalBlock\n"); }

void _Unwind_Resume() { print_and_halt("Calling _Unwind_Resume\n"); }

void _ZNKSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7compareEPKc() { print_and_halt("Calling _ZNKSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7compareEPKc\n"); }

void _ZNKSt3__119__shared_weak_count13__get_deleterERKSt9type_info() { print_and_halt("Calling _ZNKSt3__119__shared_weak_count13__get_deleterERKSt9type_info\n"); }

void _ZNKSt3__120__vector_base_commonILb1EE20__throw_length_errorEv() { print_and_halt("Calling _ZNKSt3__120__vector_base_commonILb1EE20__throw_length_errorEv\n"); }

void _ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv() { print_and_halt("Calling _ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv\n"); }

void _ZNKSt3__16locale9use_facetERNS0_2idE() { print_and_halt("Calling _ZNKSt3__16locale9use_facetERNS0_2idE\n"); }

void _ZNKSt3__18ios_base6getlocEv() { print_and_halt("Calling _ZNKSt3__18ios_base6getlocEv\n"); }

void _ZNSt3__111__call_onceERVmPvPFvS2_E() { print_and_halt("Calling _ZNSt3__111__call_onceERVmPvPFvS2_E\n"); }

void _ZNSt3__112__next_primeEm() { print_and_halt("Calling _ZNSt3__112__next_primeEm\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEPKcm() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEPKcm\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEmc() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEmc\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6resizeEmc() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6resizeEmc\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7reserveEm() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7reserveEm\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9push_backEc() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9push_backEc\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED1Ev() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED1Ev\n"); }

void _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEaSERKS5_() { print_and_halt("Calling _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEaSERKS5_\n"); }

void _ZNSt3__113basic_istreamIcNS_11char_traitsIcEEED0Ev() { print_and_halt("Calling _ZNSt3__113basic_istreamIcNS_11char_traitsIcEEED0Ev\n"); }

void _ZNSt3__113basic_istreamIcNS_11char_traitsIcEEED1Ev() { print_and_halt("Calling _ZNSt3__113basic_istreamIcNS_11char_traitsIcEEED1Ev\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5writeEPKcl\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE6sentryC1ERS3_() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE6sentryC1ERS3_\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE6sentryD1Ev() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE6sentryD1Ev\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEED0Ev() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEED0Ev\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEED1Ev() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEED1Ev\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEED2Ev() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEED2Ev\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEm() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEm\n"); }

void _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEy() { print_and_halt("Calling _ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEy\n"); }

void _ZNSt3__114basic_iostreamIcNS_11char_traitsIcEEED0Ev() { print_and_halt("Calling _ZNSt3__114basic_iostreamIcNS_11char_traitsIcEEED0Ev\n"); }

void _ZNSt3__114basic_iostreamIcNS_11char_traitsIcEEED1Ev() { print_and_halt("Calling _ZNSt3__114basic_iostreamIcNS_11char_traitsIcEEED1Ev\n"); }

void _ZNSt3__114basic_iostreamIcNS_11char_traitsIcEEED2Ev() { print_and_halt("Calling _ZNSt3__114basic_iostreamIcNS_11char_traitsIcEEED2Ev\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE4syncEv() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE4syncEv\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE5imbueERKNS_6localeE() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE5imbueERKNS_6localeE\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE5uflowEv() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE5uflowEv\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE6setbufEPcl() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE6setbufEPcl\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE6xsgetnEPcl() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE6xsgetnEPcl\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE6xsputnEPKcl() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE6xsputnEPKcl\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE9showmanycEv() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEE9showmanycEv\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEEC2Ev() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEEC2Ev\n"); }

void _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEED2Ev() { print_and_halt("Calling _ZNSt3__115basic_streambufIcNS_11char_traitsIcEEED2Ev\n"); }

void _ZNSt3__119__shared_weak_count10__add_weakEv() { print_and_halt("Calling _ZNSt3__119__shared_weak_count10__add_weakEv\n"); }

void _ZNSt3__119__shared_weak_count12__add_sharedEv() { print_and_halt("Calling _ZNSt3__119__shared_weak_count12__add_sharedEv\n"); }

void _ZNSt3__119__shared_weak_count14__release_weakEv() { print_and_halt("Calling _ZNSt3__119__shared_weak_count14__release_weakEv\n"); }

void _ZNSt3__119__shared_weak_count16__release_sharedEv() { print_and_halt("Calling _ZNSt3__119__shared_weak_count16__release_sharedEv\n"); }

void _ZNSt3__119__shared_weak_countD2Ev() { print_and_halt("Calling _ZNSt3__119__shared_weak_countD2Ev\n"); }

void _ZNSt3__15ctypeIcE2idE() { print_and_halt("Calling _ZNSt3__15ctypeIcE2idE\n"); }

void _ZNSt3__15mutex4lockEv() { print_and_halt("Calling _ZNSt3__15mutex4lockEv\n"); }

void _ZNSt3__15mutex6unlockEv() { print_and_halt("Calling _ZNSt3__15mutex6unlockEv\n"); }

void _ZNSt3__16__sortIRNS_6__lessImmEEPmEEvT0_S5_T_() { print_and_halt("Calling _ZNSt3__16__sortIRNS_6__lessImmEEPmEEvT0_S5_T_\n"); }

void _ZNSt3__16localeD1Ev() { print_and_halt("Calling _ZNSt3__16localeD1Ev\n"); }

void _ZNSt3__18ios_base4initEPv() { print_and_halt("Calling _ZNSt3__18ios_base4initEPv\n"); }

void _ZNSt3__18ios_base5clearEj() { print_and_halt("Calling _ZNSt3__18ios_base5clearEj\n"); }

void _ZNSt3__19basic_iosIcNS_11char_traitsIcEEED2Ev() { print_and_halt("Calling _ZNSt3__19basic_iosIcNS_11char_traitsIcEEED2Ev\n"); }

void _ZThn16_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED0Ev() { print_and_halt("Calling _ZThn16_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED0Ev\n"); }

void _ZThn16_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED1Ev() { print_and_halt("Calling _ZThn16_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED1Ev\n"); }

void _ZTv0_n24_NSt3__113basic_istreamIcNS_11char_traitsIcEEED0Ev() { print_and_halt("Calling _ZTv0_n24_NSt3__113basic_istreamIcNS_11char_traitsIcEEED0Ev\n"); }

void _ZTv0_n24_NSt3__113basic_istreamIcNS_11char_traitsIcEEED1Ev() { print_and_halt("Calling _ZTv0_n24_NSt3__113basic_istreamIcNS_11char_traitsIcEEED1Ev\n"); }

void _ZTv0_n24_NSt3__113basic_ostreamIcNS_11char_traitsIcEEED0Ev() { print_and_halt("Calling _ZTv0_n24_NSt3__113basic_ostreamIcNS_11char_traitsIcEEED0Ev\n"); }

void _ZTv0_n24_NSt3__113basic_ostreamIcNS_11char_traitsIcEEED1Ev() { print_and_halt("Calling _ZTv0_n24_NSt3__113basic_ostreamIcNS_11char_traitsIcEEED1Ev\n"); }

void _ZTv0_n24_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED0Ev() { print_and_halt("Calling _ZTv0_n24_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED0Ev\n"); }

void _ZTv0_n24_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED1Ev() { print_and_halt("Calling _ZTv0_n24_NSt3__114basic_iostreamIcNS_11char_traitsIcEEED1Ev\n"); }

void _ZdaPv() { print_and_halt("Calling _ZdaPv\n"); }

void _ZdlPv() { print_and_halt("Calling _ZdlPv\n"); }

void _Znam() { print_and_halt("Calling _Znam\n"); }

void _Znwm() { print_and_halt("Calling _Znwm\n"); }

void __CFConstantStringClassReference() { print_and_halt("Calling __CFConstantStringClassReference\n"); }

void __assert_rtn() { print_and_halt("Calling __assert_rtn\n"); }

void __bzero() { print_and_halt("Calling __bzero\n"); }

void __cxa_guard_abort() { print_and_halt("Calling __cxa_guard_abort\n"); }

void __cxa_guard_acquire() { print_and_halt("Calling __cxa_guard_acquire\n"); }

void __cxa_guard_release() { print_and_halt("Calling __cxa_guard_release\n"); }

void __divti3() { print_and_halt("Calling __divti3\n"); }

void __error() { print_and_halt("Calling __error\n"); }

void __gxx_personality_v0() { print_and_halt("Calling __gxx_personality_v0\n"); }

void __stderrp() { print_and_halt("Calling __stderrp\n"); }

void __stdinp() { print_and_halt("Calling __stdinp\n"); }

void __stdoutp() { print_and_halt("Calling __stdoutp\n"); }

void _dyld_register_func_for_add_image() { print_and_halt("Calling _dyld_register_func_for_add_image\n"); }

void _objc_empty_cache() { print_and_halt("Calling _objc_empty_cache\n"); }

void _objc_rootAutorelease() { print_and_halt("Calling _objc_rootAutorelease\n"); }

void abort() { print_and_halt("Calling abort\n"); }

void asl_log() { print_and_halt("Calling asl_log\n"); }

void asprintf() { print_and_halt("Calling asprintf\n"); }

void ceil() { print_and_halt("Calling ceil\n"); }

void ceilf() { print_and_halt("Calling ceilf\n"); }

void class_conformsToProtocol() { print_and_halt("Calling class_conformsToProtocol\n"); }

void class_copyIvarList() { print_and_halt("Calling class_copyIvarList\n"); }

void class_createInstance() { print_and_halt("Calling class_createInstance\n"); }

void class_getInstanceSize() { print_and_halt("Calling class_getInstanceSize\n"); }

void class_getName() { print_and_halt("Calling class_getName\n"); }

void class_getSuperclass() { print_and_halt("Calling class_getSuperclass\n"); }

void class_isMetaClass() { print_and_halt("Calling class_isMetaClass\n"); }

void class_respondsToSelector() { print_and_halt("Calling class_respondsToSelector\n"); }

void cos() { print_and_halt("Calling cos\n"); }

void cosf() { print_and_halt("Calling cosf\n"); }

void dispatch_once() { print_and_halt("Calling dispatch_once\n"); }

void dispatch_once_f() { print_and_halt("Calling dispatch_once_f\n"); }

void dladdr() { print_and_halt("Calling dladdr\n"); }

void dlsym() { print_and_halt("Calling dlsym\n"); }

void exp() { print_and_halt("Calling exp\n"); }

void exp2() { print_and_halt("Calling exp2\n"); }

void exp2f() { print_and_halt("Calling exp2f\n"); }

void expf() { print_and_halt("Calling expf\n"); }

void flockfile() { print_and_halt("Calling flockfile\n"); }

void floor() { print_and_halt("Calling floor\n"); }

void floorf() { print_and_halt("Calling floorf\n"); }

void fmod() { print_and_halt("Calling fmod\n"); }

void fmodf() { print_and_halt("Calling fmodf\n"); }

void fmodl() { print_and_halt("Calling fmodl\n"); }

void fprintf() { print_and_halt("Calling fprintf\n"); }

void free() { print_and_halt("Calling free\n"); }

void freelocale() { print_and_halt("Calling freelocale\n"); }

void funlockfile() { print_and_halt("Calling funlockfile\n"); }

void getline() { print_and_halt("Calling getline\n"); }

void getsectiondata() { print_and_halt("Calling getsectiondata\n"); }

void ivar_getOffset() { print_and_halt("Calling ivar_getOffset\n"); }

void log() { print_and_halt("Calling log\n"); }

void log10() { print_and_halt("Calling log10\n"); }

void log10f() { print_and_halt("Calling log10f\n"); }

void log2() { print_and_halt("Calling log2\n"); }

void log2f() { print_and_halt("Calling log2f\n"); }

void logf() { print_and_halt("Calling logf\n"); }

void malloc() { print_and_halt("Calling malloc\n"); }

void malloc_default_zone() { print_and_halt("Calling malloc_default_zone\n"); }

void malloc_size() { print_and_halt("Calling malloc_size\n"); }

void malloc_zone_from_ptr() { print_and_halt("Calling malloc_zone_from_ptr\n"); }

void memchr() { print_and_halt("Calling memchr\n"); }

void memcmp() { print_and_halt("Calling memcmp\n"); }

void memcpy() { print_and_halt("Calling memcpy\n"); }

void memmove() { print_and_halt("Calling memmove\n"); }

void mmap() { print_and_halt("Calling mmap\n"); }

void nearbyint() { print_and_halt("Calling nearbyint\n"); }

void nearbyintf() { print_and_halt("Calling nearbyintf\n"); }

void newlocale() { print_and_halt("Calling newlocale\n"); }

void objc_autorelease() { print_and_halt("Calling objc_autorelease\n"); }

void objc_autoreleaseReturnValue() { print_and_halt("Calling objc_autoreleaseReturnValue\n"); }

void objc_copyWeak() { print_and_halt("Calling objc_copyWeak\n"); }

void objc_debug_isa_class_mask() { print_and_halt("Calling objc_debug_isa_class_mask\n"); }

void objc_destroyWeak() { print_and_halt("Calling objc_destroyWeak\n"); }

void objc_destructInstance() { print_and_halt("Calling objc_destructInstance\n"); }

void objc_initWeak() { print_and_halt("Calling objc_initWeak\n"); }

void objc_loadWeakRetained() { print_and_halt("Calling objc_loadWeakRetained\n"); }

void objc_moveWeak() { print_and_halt("Calling objc_moveWeak\n"); }

void objc_msgSend() { print_and_halt("Calling objc_msgSend\n"); }

void objc_msgSendSuper2() { print_and_halt("Calling objc_msgSendSuper2\n"); }

void objc_msgSend_stret() { print_and_halt("Calling objc_msgSend_stret\n"); }

void objc_readClassPair() { print_and_halt("Calling objc_readClassPair\n"); }

void objc_release() { print_and_halt("Calling objc_release\n"); }

void objc_retain() { print_and_halt("Calling objc_retain\n"); }

void objc_retainAutoreleasedReturnValue() { print_and_halt("Calling objc_retainAutoreleasedReturnValue\n"); }

void objc_storeStrong() { print_and_halt("Calling objc_storeStrong\n"); }

void objc_storeWeak() { print_and_halt("Calling objc_storeWeak\n"); }

void object_dispose() { print_and_halt("Calling object_dispose\n"); }

void object_getClass() { print_and_halt("Calling object_getClass\n"); }

void printf() { print_and_halt("Calling printf\n"); }

void protocol_getName() { print_and_halt("Calling protocol_getName\n"); }

void pthread_mutex_init() { print_and_halt("Calling pthread_mutex_init\n"); }

void pthread_mutex_lock() { print_and_halt("Calling pthread_mutex_lock\n"); }

void pthread_mutex_unlock() { print_and_halt("Calling pthread_mutex_unlock\n"); }

void putc() { print_and_halt("Calling putc\n"); }

void putchar() { print_and_halt("Calling putchar\n"); }

void rint() { print_and_halt("Calling rint\n"); }

void rintf() { print_and_halt("Calling rintf\n"); }

void round() { print_and_halt("Calling round\n"); }

void roundf() { print_and_halt("Calling roundf\n"); }

void sel_getName() { print_and_halt("Calling sel_getName\n"); }

void sin() { print_and_halt("Calling sin\n"); }

void sinf() { print_and_halt("Calling sinf\n"); }

void snprintf() { print_and_halt("Calling snprintf\n"); }

void snprintf_l() { print_and_halt("Calling snprintf_l\n"); }

void strchr() { print_and_halt("Calling strchr\n"); }

void strcmp() { print_and_halt("Calling strcmp\n"); }

void strdup() { print_and_halt("Calling strdup\n"); }

void strlen() { print_and_halt("Calling strlen\n"); }

void strncmp() { print_and_halt("Calling strncmp\n"); }

void strndup() { print_and_halt("Calling strndup\n"); }

void strtod_l() { print_and_halt("Calling strtod_l\n"); }

void strtof_l() { print_and_halt("Calling strtof_l\n"); }

void strtold_l() { print_and_halt("Calling strtold_l\n"); }

void sysconf() { print_and_halt("Calling sysconf\n"); }

void trunc() { print_and_halt("Calling trunc\n"); }

void truncf() { print_and_halt("Calling truncf\n"); }

void vasprintf() { print_and_halt("Calling vasprintf\n"); }

void vm_page_mask() { print_and_halt("Calling vm_page_mask\n"); }

void write() { print_and_halt("Calling write\n"); }
