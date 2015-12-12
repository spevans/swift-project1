/*
 * fakelib/osx_libcpp.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Fake libcpp calls used by OSX/Mach-O libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"


/*
 * memory
 */

struct ptr {
        unsigned long r1;
        unsigned long shared_count;
        unsigned long weak_count;
};


//_operator new(unsigned long)
void *
_Znwm(unsigned long size) {

        void *result = malloc(size);
        //kprintf("(_Znwm)new(%lu)=%p\n", size, result);
        return result;
}


//_operator delete(void*)
void
_ZdlPv(void *this) {
        //kprintf("%p->delete()\n", this);
}


//_operator new[](unsigned long)
void *_Znam(unsigned long size) {
        kprintf("(_Znam)new[](%lu)", size);
        void *result = malloc(size);
        return result;
}


// _operator delete[](void*)
void
_ZdaPv(void *this) {
        kprintf("%p->delete[]()\n", this);
}


UNIMPLEMENTED(_ZTVNSt3__114__shared_countE)
UNIMPLEMENTED(_ZTVNSt3__119__shared_weak_countE)


void
_ZNSt3__119__shared_weak_count10__add_weakEv(struct ptr *this)
{
        //kprintf("%p->_ZNSt3__119__shared_weak_count10__add_weakEv()\n", this);
        // FIXME: should use LOCK
        __atomic_fetch_add(&this->weak_count, 1, __ATOMIC_RELAXED);
}


void
_ZNSt3__119__shared_weak_count12__add_sharedEv(struct ptr *this)
{
        //kprintf("%p->_ZNSt3__119__shared_weak_count12__add_sharedEv()\n", this);
        // FIXME: needs locking
        this->shared_count++;
}


UNIMPLEMENTED(_ZNSt3__119__shared_weak_count14__release_weakEv)
UNIMPLEMENTED(_ZNSt3__119__shared_weak_count16__release_sharedEv)
UNIMPLEMENTED(_ZNSt3__119__shared_weak_countD2Ev)
UNIMPLEMENTED(_ZNKSt3__119__shared_weak_count13__get_deleterERKSt9type_info)
UNIMPLEMENTED(_ZNKSt3__120__vector_base_commonILb1EE20__throw_length_errorEv)


/*
 * basic_string
 *
 */


// 24bytes
const size_t SMALL_STR_CAPACITY = 23;
static const size_t MAX_STRING_SIZE = SIZE_MAX - 3;  // allow lowest bit to be used for flag

struct short_string {
        uint8_t len;
        char string[SMALL_STR_CAPACITY];
};

struct long_string {
        size_t capacity;        // size of malloc'd 'data'
        size_t curlen;
        char *data;
};


struct basic_string {
        // bit 0 of len/capacity = 0 is an inline_string 1 if an allocated_string
        union {
                struct short_string ss;
                struct long_string ls;
        };
};


static inline int
is_long_string(struct basic_string *this)
{
        return this->ss.len & 1;
}


/* string capacity */

static inline size_t
best_str_capacity(size_t len)
{
        return (len + 16) & ~0xf;
}


static inline size_t
get_long_str_capacity(struct basic_string *this)
{
        return this->ls.capacity;
}


static inline size_t
get_short_str_capacity(struct basic_string *this)
{
        return SMALL_STR_CAPACITY;
}


static inline size_t
get_str_capacity(struct basic_string *this)
{
        size_t capacity = is_long_string(this) ? get_long_str_capacity(this) : get_short_str_capacity(this);
        return capacity - 1;
}


static inline void
set_long_str_capacity(struct basic_string *this, size_t capacity)
{
        this->ls.capacity = capacity | 1;
}


static inline size_t
get_str_size(struct basic_string *this)
{
        return is_long_string(this) ? this->ls.curlen : this->ss.len >> 1;
}


static inline void
set_short_str_size(struct basic_string *this, size_t len)
{
        this->ss.len = len << 1;
}


static inline void
set_long_str_size(struct basic_string *this, size_t len)
{
        this->ls.curlen = len;
}


static inline void
set_str_size(struct basic_string *this, size_t size)
{
        if (is_long_string(this)) {
                set_long_str_size(this, size);
        } else {
                set_short_str_size(this, size);
        }
}


static inline char *
get_short_str_ptr(struct basic_string *this)
{
        return this->ss.string;
}


static inline char *
get_long_str_ptr(struct basic_string *this)
{
        return this->ls.data;
}


static inline char *
get_str_ptr(struct basic_string *this)
{
        return is_long_string(this) ? get_long_str_ptr(this) : get_short_str_ptr(this);
}


static inline void
set_long_str_ptr(struct basic_string *this, char *p)
{
        this->ls.data = p;
}


void
_ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv(struct basic_string *this)
{
        koops("string too long!");
        __builtin_unreachable ();
}


int
_ZNKSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7compareEPKc(struct basic_string *this,
                                                                             const char *str)
{
        kprintf("%p->compare(%s)=", this, str);
        int result = strcmp(get_str_ptr(this), str);
        kprintf("%d\n", result);

        return result;
}


// std::__1::basic_string<char, std::__1::char_traits<char>,
void
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEPKcm(struct basic_string *this,
                                                                                 char const *str,
                                                                                 uint32_t len)
{
        kprintf("%p->_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_"
                "9allocatorIcEEE6__initEPKcm(%s, %u)\n",
                this, str, len);
        char *dest;

        if (unlikely(len == (uint32_t)~0)) {
                _ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv(this);
                __builtin_unreachable ();
        }


        else if (likely(len <= SMALL_STR_CAPACITY)) {
                dest = get_short_str_ptr(this);
                set_short_str_size(this, len);
        } else {
                size_t capacity = best_str_capacity(len);
                dest = malloc(capacity+1);
                set_long_str_capacity(this, capacity+1);
                set_long_str_ptr(this, dest);
                set_long_str_size(this, len);
        }
        __memcpy(dest, str, len);
        dest[len+1] = '\0';
}


// std::__1::allocator<char> >::__init(char const*, unsigned long)
void
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEmc(struct basic_string *this,
                                                                               uint32_t len,
                                                                               char ch)
{
        kprintf("%p->_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_"
                "9allocatorIcEEE6__initEmc(%u, %d)\n", this, len, ch);

        if (len > MAX_STRING_SIZE) {
                _ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv(this);
        }

        char *dest;
        if (len < SMALL_STR_CAPACITY) {
                set_short_str_size(this, len);
                dest = get_short_str_ptr(this);
        } else {
                size_t capacity = best_str_capacity(len);
                dest = malloc(capacity+1);
                set_long_str_ptr(this, dest);
                set_long_str_capacity(this, capacity+1);
                set_long_str_size(this, len);
        }
}


void
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE21__grow_by_and_replaceEmmmmmmPKc(struct basic_string *this,
                                                                                                  size_t old_capacity,
                                                                                                  size_t extra_capacity,
                                                                                                  size_t cursize,
                                                                                                  size_t bytes_to_copy,
                                                                                                  size_t bytes_to_del,
                                                                                                  size_t bytes_to_add,
                                                                                                  const char *string)
{
        kprintf("%p->__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE21__grow_by_and_replaceEmmmmmmPKc(%ld,%ld,%ld,%ld,%ld,%ld,%s)\n",
                this, old_capacity, extra_capacity, cursize, bytes_to_copy, bytes_to_del, bytes_to_add, string);

        if (old_capacity + extra_capacity > MAX_STRING_SIZE) {
                _ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv(this);
        }

        size_t new_capacity = old_capacity + extra_capacity;
        char *old_str = get_str_ptr(this);
        char *p = malloc(new_capacity + 1);
        if (bytes_to_copy != 0) {
                __memcpy(p, old_str, bytes_to_copy);
                p[bytes_to_copy] = '\0';
        }
        if (bytes_to_add != 0) {
                __memcpy(p + bytes_to_copy, string, bytes_to_add);
                p[bytes_to_copy + bytes_to_add] = '\0';
        }
        size_t sec_cp_sz = cursize - bytes_to_del - bytes_to_copy;
        if (sec_cp_sz != 0) {
                __memcpy(p + bytes_to_copy + bytes_to_add, old_str + bytes_to_copy + bytes_to_del, sec_cp_sz);
                p[bytes_to_copy + bytes_to_add + sec_cp_sz] = '\0';
        }
        if (is_long_string(this)) {
                free(old_str);
        }
        set_long_str_ptr(this, p);
        set_long_str_capacity(this, new_capacity + 1);
        set_long_str_size(this, bytes_to_copy + bytes_to_add + sec_cp_sz);
}


struct basic_string *
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm(struct basic_string *this,
                                                                            const char *string,
                                                                            uint32_t len)
{
        kprintf("%p->append(%s, %u)\n",
                this, string, len);
        size_t size = get_str_size(this);
        size_t capacity = get_str_capacity(this);
        if (capacity - size >= len) {
                if (len) {
                        char *p = get_str_ptr(this);
                        __memcpy(p + size, string, len);
                        p[size + len] = '\0';
                        set_str_size(this, size + len);
                }
        } else {
                __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE21__grow_by_and_replaceEmmmmmmPKc(this,
                                                                                                                  capacity,
                                                                                                                  size + len - capacity,
                                                                                                                  size,
                                                                                                                  size,
                                                                                                                  0,
                                                                                                                  len,
                                                                                                                  string);
        }
        return this;
}


struct basic_string *
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKc(struct basic_string *this,
                                                                           const char *string)
{
        kprintf("%p->append(%s)\n", this, string);
        _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm(this, string, strlen(string));
        return this;
}


struct basic_string *
_ZNSsC1EPKcmRKSaIcE(struct basic_string *this, const char *string, uint32_t len, void *allocator)
{
        kprintf("%p->%s(%s, %u)", this, __func__, string, len);
        return _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm(this, string, len);
}


void
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9__grow_byEmmmmmm(struct basic_string *this,
                                                                                  size_t old_capacity,
                                                                                  size_t extra_capacity,
                                                                                  size_t cursize,
                                                                                  size_t bytes_to_copy,
                                                                                  size_t bytes_to_del,
                                                                                  size_t bytes_to_add)
{
        kprintf("%p->__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9__grow_byEmmmmmm(%ld,%ld,%ld,%ld,%ld,%ld)\n",
                this, old_capacity, extra_capacity, cursize, bytes_to_copy, bytes_to_del, bytes_to_add);

        if (old_capacity + extra_capacity > MAX_STRING_SIZE) {
                _ZNKSt3__121__basic_string_commonILb1EE20__throw_length_errorEv(this);
        }

        size_t new_capacity = best_str_capacity(old_capacity + extra_capacity);
        char *p = malloc(new_capacity + 1);
        char *old_str = get_str_ptr(this);
        if (bytes_to_copy != 0) {
                __memcpy(p, old_str, bytes_to_copy);
                p[bytes_to_copy] = '\0';
        }
        size_t sec_cp_sz = cursize - bytes_to_del - bytes_to_copy;
        if (sec_cp_sz !=  0) {
                __memcpy(p + bytes_to_copy + bytes_to_add, old_str + bytes_to_copy + bytes_to_del, sec_cp_sz);
                p[bytes_to_copy + bytes_to_add + sec_cp_sz] = '\0';
        }
        if (is_long_string(this)) {
                free(old_str);
        }
        set_long_str_ptr(this, p);
        set_long_str_capacity(this, new_capacity + 1);
}


struct basic_string *
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEmc(struct basic_string *this,
                                                                           unsigned long newlen, char ch)
{
        kprintf("%p->__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEmc(%lu,%d)",
                this, newlen, ch);

        if (newlen) {
                size_t capacity = get_str_capacity(this);
                size_t size = get_str_size(this);
                if (capacity - size < newlen) {
                        __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9__grow_byEmmmmmm(this, capacity,
                                                                                                          size + newlen - capacity,
                                                                                                          size, size, 0, 0);
                        //char *p = get_str_ptr(this);
                        set_str_size(this, size + newlen);
                }
        }
        return this;
}


void
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6resizeEmc(struct basic_string *this,
                                                                          unsigned long newlen, char ch)
{

        kprintf("%p->_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_"
                "9allocatorIcEEE6resizeEmc(%ld,%d)\n", this, newlen, ch);

        size_t size = get_str_size(this);
        if (size < newlen) {
                char *p = get_str_ptr(this);
                p[newlen+1] = '\0';
        } else {
                __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEmc(this, newlen - size, ch);
        }
}


void
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7reserveEm()
{
        koops("Calling "
                       "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_"
                       "9allocatorIcEEE7reserveEm\n");
}


void
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9push_backEc(struct basic_string *this, char ch)
{
        kprintf("%p->push_back(%c)", this, ch);
        size_t capacity = get_str_capacity(this);
        size_t size = get_str_size(this);
        if (size == capacity) {
                __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9__grow_byEmmmmmm(this, capacity, 1, size, size, 0, 0);
        }
        set_str_size(this, size + 1);
        char *p = get_str_ptr(this);
        p[size] = ch;
        p[size + 1] = '\0';
        kprintf("=[%u,%s]\n", (uint32_t)get_str_size(this), get_str_ptr(this));
}


void
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_() {
        koops("Calling "
                       "_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_"
                       "9allocatorIcEEEC1ERKS5_\n");
}


void
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED1Ev(struct basic_string *this)
{
        kprintf("%p->_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_"
                "9allocatorIcEEED1Ev\n", this);

        if (likely(is_long_string(this))) {
                free(get_str_ptr(this));
        }
}


struct basic_string *
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6assignEPKcm(struct basic_string *this,
                                                                             const char *string,
                                                                             size_t len)
{
        kprintf("%p->__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6assignEPKcm(%s, %lu)",
                this, string, len);

        size_t capacity = get_str_capacity(this);
        if (capacity >= len) {
                char *p = get_str_ptr(this);
                __memcpy(p, string, len);
                p[len] = '\0';
                set_str_size(this, len);
        } else {
                size_t size = get_str_size(this);
                __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE21__grow_by_and_replaceEmmmmmmPKc(this,
                                                                                                                  capacity,
                                                                                                                  len - capacity,
                                                                                                                  size,
                                                                                                                  0,
                                                                                                                  size,
                                                                                                                  len,
                                                                                                                  string);
        }
        return this;
}


// std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::operator=(std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> > const&)
struct basic_string *
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEaSERKS5_(struct basic_string *this,
                                                                        struct basic_string *that)
{
        kprintf("%p->_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_"
                "9allocatorIcEEEaSERKS5_(%p)\n", this, that);

        if (this != that) {
                __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6assignEPKcm(this,
                                                                                             get_str_ptr(that),
                                                                                             get_str_size(that));
        }
        return this;
}


// std::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(std::string const&)
void
_ZNSsC1ERKSs(struct basic_string *this, struct basic_string *that)
{
        kprintf("%p->%s(%p)", this, __func__, that);
        if (is_long_string(that)) {
                _ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEPKcm(this,
                                                                                            get_long_str_ptr(that),
                                                                                            get_str_size(that));
        } else {
                this->ss = that->ss;
        }
        kprintf("COPY: %s=%s\n", get_str_ptr(this), get_str_ptr(that));
}


UNIMPLEMENTED(__cxa_guard_abort)
UNIMPLEMENTED(__cxa_guard_acquire)
UNIMPLEMENTED(__cxa_guard_release)
UNIMPLEMENTED(__gxx_personality_v0)
UNIMPLEMENTED(_Unwind_Resume)


/*
 * mutex
 */



// std::__1::mutex::lock()
void _ZNSt3__15mutex4lockEv(void *this) {
        kprintf("(_ZNSt3__15mutex4lockEv)mutex_lock this=%p\n", this);
}

void _ZNSt3__15mutex6unlockEv(void *this) {
        kprintf("(_ZNSt3__15mutex6unlockEv)mutex_unlock this=%p\n", this);
}

void _ZNSt3__111__call_onceERVmPvPFvS2_E() {
        koops("Calling _ZNSt3__111__call_onceERVmPvPFvS2_E\n");
}


/*
 * hash
 */

UNIMPLEMENTED(_ZNSt3__112__next_primeEm)


void _ZNSt3__16__sortIRNS_6__lessImmEEPmEEvT0_S5_T_(unsigned long *start,
                                                    unsigned long *end,
                                                    void *cmpfunc)
{
        kprintf("Calling _ZNSt3__16__sortIRNS_6__lessImmEEPmEEvT0_S5_T_(%p, %p, %p)\n",
                start, end, cmpfunc);
        if (start == end) {
                return; // no sort needed
        } else {
                hlt();
        }
}
