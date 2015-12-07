#include "klib.h"

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



void _objc_empty_cache() { print_and_halt("Calling _objc_empty_cache\n"); }

void _objc_rootAutorelease() { print_and_halt("Calling _objc_rootAutorelease\n"); }


void class_conformsToProtocol() { print_and_halt("Calling class_conformsToProtocol\n"); }

void class_copyIvarList() { print_and_halt("Calling class_copyIvarList\n"); }

void class_createInstance() { print_and_halt("Calling class_createInstance\n"); }

void class_getInstanceSize() { print_and_halt("Calling class_getInstanceSize\n"); }

void class_getName() { print_and_halt("Calling class_getName\n"); }

void *
class_getSuperclass(void *self)
{
        // FIXME
        kprintf("%p->class_getSuperclass()\n", self);
        return NULL;
}


void class_isMetaClass() { print_and_halt("Calling class_isMetaClass\n"); }

void class_respondsToSelector() { print_and_halt("Calling class_respondsToSelector\n"); }


void ivar_getOffset() { print_and_halt("Calling ivar_getOffset\n"); }



void objc_autorelease() { print_and_halt("Calling objc_autorelease\n"); }

void objc_autoreleaseReturnValue() { print_and_halt("Calling objc_autoreleaseReturnValue\n"); }

void objc_copyWeak() { print_and_halt("Calling objc_copyWeak\n"); }

void objc_debug_isa_class_mask() { print_and_halt("Calling objc_debug_isa_class_mask\n"); }

void objc_destroyWeak() { print_and_halt("Calling objc_destroyWeak\n"); }

void objc_destructInstance() { print_and_halt("Calling objc_destructInstance\n"); }

void objc_initWeak() { print_and_halt("Calling objc_initWeak\n"); }

void objc_loadWeakRetained() { print_and_halt("Calling objc_loadWeakRetained\n"); }

void objc_moveWeak() { print_and_halt("Calling objc_moveWeak\n"); }

void *
objc_msgSend(void *self, void *sel) {
        kprintf("%p->objc_msgSend(%p)\n", self, sel);
        return 0;
}

void objc_msgSendSuper2() { print_and_halt("Calling objc_msgSendSuper2\n"); }

void objc_msgSend_stret() { print_and_halt("Calling objc_msgSend_stret\n"); }

void *
objc_readClassPair(void *this, void *class)
{
        kprintf("%p->objc_readClasPair(%p)\n", this, class);
        return NULL;
}


void objc_release() { print_and_halt("Calling objc_release\n"); }

void objc_retain() { print_and_halt("Calling objc_retain\n"); }

void objc_retainAutoreleasedReturnValue() { print_and_halt("Calling objc_retainAutoreleasedReturnValue\n"); }

void objc_storeWeak() { print_and_halt("Calling objc_storeWeak\n"); }


void sel_getName() { print_and_halt("Calling sel_getName\n"); }

void __CFConstantStringClassReference() {
        print_and_halt("Calling __CFConstantStringClassReference\n");
}


void object_dispose()
{
        koops("object_dispose");
}


void object_getClass()
{
        koops("object_getClass()");
}

void protocol_getName()
{
        koops("protocol_getName()");
}


void arc4random()
{
        koops("arc4random");
}


void arc4random_uniform()
{
        koops("arc4random_uniform");
}


void close()
{
        koops("close");
}
