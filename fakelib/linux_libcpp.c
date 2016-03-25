/*
 * fakelib/linux_libcpp.c
 *
 * Created by Simon Evans on 07/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Fake libcpp calls used by Linux/ELF libswiftCore
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-variable"


/*
 * memory
 */

//_operator delete(void*)
void _ZdlPv(void *this) {
        debugf("%p->delete()\n", this);
        free(this);
}


//_operator new(unsigned long)
void *_Znwm(unsigned long size) {

        void *result = malloc(size);
        debugf("(_Znwm)new(%lu)=%p\n", size, result);
        return result;
}


// std::__throw_length_error(char const*)
void
_ZSt20__throw_length_errorPKc(char const *error)
{
        koops("OOPS! Length error: %s", error);
}


// std::__throw_bad_alloc()
void
_ZSt17__throw_bad_allocv()
{
        koops("Bad Alloc");
}


// std::__throw_system_error(int)
void
_ZSt20__throw_system_errori(int error)
{
        print_string("System error: ");
        print_dword(error);
        asm volatile ("hlt" : : : "memory");
}


//std::__throw_out_of_range(char const*)
void
_ZSt20__throw_out_of_rangePKc(char const *error)
{
        koops("Out of range: %s", error);
}


/*
 * std::string / std::basic_string
 *
 */

// 24 bytes
struct basic_string {
        uint64_t length;
        uint64_t capacity;
        int refcount;           // Atomic_word
        char padding[4];
        char data[0];           // this pointer for std::basic_string -> end of basic_string
};


// std::string::_Rep::_S_empty_rep_storage
// Empty string with all fields set to 0
struct basic_string _ZNSs4_Rep20_S_empty_rep_storageE[2] = {};

// std::string::_Rep::_S_terminal Terminating character
char _ZNSs4_Rep11_S_terminalE = '\0';

static const size_t str_max_size = 0x3ffffffffffffff9;
static const size_t npos = 0xffffffffffffffff;


static inline int
is_string_shared(struct basic_string *str)
{
        return str->refcount > 0;
}


static inline void
string_set_shareable(struct basic_string *str)
{
        str->refcount = 0;
}


static inline void
dump_basic_string(struct basic_string *this)
{
        debugf("DBS %p->(%lu,%lu,%d,\"%s\")\n", this, this->length, this->capacity, this->refcount, this->data);
}


// Returns pointer to basic_string structure (Rep)
// std::string::_Rep::_S_create(unsigned long, unsigned long, std::allocator<char> const&)
struct basic_string * __attribute__((noinline))
_ZNSs4_Rep9_S_createEmmRKSaIcE(size_t capacity, size_t old_capacity, void *allocator)
{
        debugf("_ZNSs4_Rep9_S_createEmmRKSaIcE(%lu,%lu,%p)\n", capacity, old_capacity, allocator);
        if (capacity > str_max_size) {
                _ZSt20__throw_length_errorPKc("string too long");
        }

        if (capacity > old_capacity && capacity < 2 * old_capacity) {
                capacity = 2 * old_capacity;
        }

        if (capacity > str_max_size) {
                capacity = str_max_size;
        }

        size_t size = sizeof(struct basic_string) + capacity + 1;
        debugf("creating string size= %lu capacity = %lu\n", size, capacity);

        struct basic_string *result = _Znwm(size); // new
        result->capacity = capacity;
        result->refcount = 0;
        debugf("_S_create(%lu,%lu,%p)=%p\n", capacity, old_capacity, allocator, result);

        return result;
}


// std::string::_Rep::_M_clone(std::allocator<char> const&, unsigned long)
struct basic_string *
_ZNSs4_Rep8_M_cloneERKSaIcEm(struct basic_string *this, void *allocator, size_t len)
{
        struct basic_string *result;

        size_t capacity = len + this->length;
        result = _ZNSs4_Rep9_S_createEmmRKSaIcE(capacity, this->capacity, allocator);

        if (unlikely(this->length == 0)) {
                return result + 1;
        }

        if (likely(this->length != 1)) {
                memcpy(result->data, this->data, this->length);
        } else {
                result->data[0] = this->data[0];
        }

        if (likely(result != _ZNSs4_Rep20_S_empty_rep_storageE)) {
                result->length = this->length;
                result->refcount = 0;
                result->data[this->length] = '\0';
        }

        return result + 1;
}


// this = pointer to basic_string structure (Rep)
// std::string::_Rep::_M_destroy(std::allocator<char> const&)
void
_ZNSs4_Rep10_M_destroyERKSaIcE(struct basic_string *this, void *allocator)
{
        dump_basic_string(this);
        free(this);
}


// std::string::_M_mutate(unsigned long, unsigned long, unsigned long)
void
_ZNSs9_M_mutateEmmm(struct basic_string *this, size_t pos, size_t len1, size_t len2)
{
        debugf("UNIMPLEMENTED:%p->_ZNSs9_M_mutateEmmm(%lu, %lu, %lu)\n", this, pos, len1, len2);
        hlt();
}


// char* std::string::_S_construct<char const*>(char const*, char const*, std::allocator<char> const&, std::forward_iterator_tag)
struct basic_string *
_ZNSs12_S_constructIPKcEEPcT_S3_RKSaIcESt20forward_iterator_tag(const char *str_start, const char *str_end, void *allocator, int tag)
{
        debugf("_S_construct(%s, %s, %p, %p, %p, %d) sizeof=%lu\n", str_start, str_end, str_start, str_end, allocator, tag, sizeof(struct basic_string));

        if (str_start == str_end) {
                // return statically allocated empty string
                debugf("returning empty storage %p", _ZNSs4_Rep20_S_empty_rep_storageE + 1);
                dump_basic_string(_ZNSs4_Rep20_S_empty_rep_storageE);
                return _ZNSs4_Rep20_S_empty_rep_storageE + 1;
        }
        if (str_start == NULL && str_end != NULL) {
                koops("_S_construct with null start");
        }

        size_t size = str_end - str_start;

        struct basic_string *result = _ZNSs4_Rep9_S_createEmmRKSaIcE(size, 0, allocator);
        if (likely(size != 1)) {
                memcpy(result->data, str_start, size);
        } else {
                result->data[0] = str_start[0];
        }

        if (likely(result != _ZNSs4_Rep20_S_empty_rep_storageE)) {
                 result->length = size;
                 result->refcount = 0;
                 result->data[size] = '\0';
        }
        dump_basic_string(result);

        return result+1;   // return pointer to end
}


// std::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(char const*, unsigned long, std::allocator<char> const&)
void
_ZNSsC1EPKcmRKSaIcE(struct basic_string **this_p, char const *string, unsigned int len, void **allocator)
{
        debugf("_ZNSsC1EPKcmRKSaIcE(%p,%s,%u,%p)\n", this_p, string, len, allocator);
        struct basic_string *result = _ZNSs12_S_constructIPKcEEPcT_S3_RKSaIcESt20forward_iterator_tag(string, string + len, allocator, 0);
        dump_basic_string(result - 1);
        *this_p = result;
}


// std::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(std::string const&)
void
_ZNSsC1ERKSs(struct basic_string **this_p, struct basic_string **that_p)
{
        struct basic_string *this = (*this_p) - 1;
        struct basic_string *that = (*that_p) - 1;
        debugf("_ZNSsC1ERKSs(%p[%p],%p[%p]): ", this_p, this, that_p, that);

        if (that->refcount >= 0) {
                if (that == _ZNSs4_Rep20_S_empty_rep_storageE) {
                        *this_p = *that_p;
                } else {
                        __atomic_fetch_add(&that->refcount, 1, __ATOMIC_RELAXED);
                        *this_p = *that_p;
                }
        } else {
                *this_p = _ZNSs4_Rep8_M_cloneERKSaIcEm(that, NULL, 0);
        }
        debugf("= %p\n", *this_p);
}


//std::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(char const*, std::allocator<char> const&)
void
_ZNSsC1EPKcRKSaIcE(struct basic_string **this_p, char const *string, void *allocator)
{
        struct basic_string *this = (*this_p)-1;
        debugf("%p->basic_string(%s,%p)", this, string, allocator);
        char const *end =  string;
        end += (string != NULL) ? strlen(string) : npos;

        struct basic_string *result = _ZNSs12_S_constructIPKcEEPcT_S3_RKSaIcESt20forward_iterator_tag(string, end, allocator, 0);
        dump_basic_string(result - 1);
        *this_p = result;
        print_string("_ZNSsC1EPKcRKSaIcE finished\n");
        hlt();
}


// std::string::find(char const*, unsigned long, unsigned long) const
size_t
_ZNKSs4findEPKcmm(struct basic_string **this_p, const char *string, size_t pos, size_t len)
{
        struct basic_string *this = (*this_p)-1;
        char *string_data = (char *)(*this_p);
        size_t size = this->length;

        debugf("find(%s, %s, %lu,%lu)\n", (char *)this_p, string, pos, len);
        hlt();
        dump_basic_string(this);
        if (len == 0) {
                return pos < size ? pos : npos;
        }

        //char *data = this->data;
        if (len < size) {
                for ( ; pos < size - len; pos++) {
                        if (string_data[pos] == string[0] &&
                            (memcmp(string_data+pos+1, string + 1, len -1) == 0)) {
                                    return pos;
                        }
                }
        }

        return npos;
}


// std::string::compare(char const*) const
int
_ZNKSs7compareEPKc(struct basic_string **this_p, const char *string)
{
        struct basic_string *this = (*this_p)-1;
        char *string_data = (char *)(*this_p);

        size_t size = this->length;
        size_t osize = strlen(string);
        size_t len = size < osize ? size : osize;

        debugf("compare(%s, %s, %lu)\n", (char *)this_p, string, size);
        hlt();
        dump_basic_string(this);

        int result = memcmp(string_data, string, len);
        if (!result) {
                int64_t diff = size - osize;
                if (diff > INT_MAX) {
                        result = INT_MAX;
                } else if (diff < INT_MIN) {
                        result = INT_MIN;
                } else {
                        result = (int)diff;
                }
        }
        return result;
}


// std::string::reserve(unsigned long)
void
_ZNSs7reserveEm(struct basic_string **this_p, size_t capacity)
{
        struct basic_string *this = (*this_p)-1;
        debugf("reserve: %lu: ", capacity);
        dump_basic_string(this);

        if (capacity != this->capacity || is_string_shared(this)) {
                if (capacity < this->length) {
                        capacity = this->length;
                }

                *this_p = _ZNSs4_Rep8_M_cloneERKSaIcEm(this, NULL, capacity - this->length);

                if (this != _ZNSs4_Rep20_S_empty_rep_storageE) {
                        if (__atomic_fetch_sub(&this->refcount, 1, __ATOMIC_RELAXED) == 0) {
                                free(this);
                        }
                }
        }
}


// std::string::append(char const*, unsigned long)
struct basic_string *
_ZNSs6appendEPKcm(struct basic_string **this_p, char const *string, size_t len)
{
        struct basic_string *this = (*this_p)-1;
        char *string_data = (char *)(*this_p);
        size_t oldlen = this->length;

        debugf("%p->_ZNSs6appendEPKcm(%s,%lu)\n", this, string, len);
        dump_basic_string(this);

        if (len) {
                if (len > str_max_size) {
                        _ZSt20__throw_length_errorPKc("basic_string::append");
                }
                size_t newlen = len + this->length;
                if (newlen > this->capacity || is_string_shared(this)) {
                        newlen++;
                        if (string < string_data || string > string_data + this->length) {
                                _ZNSs7reserveEm(this_p, newlen);
                        } else {
                                size_t offset = string - string_data;
                                _ZNSs7reserveEm(this_p, newlen);
                                string = string_data + offset;
                        }
                        // Update ptrs after reserve
                        this = (*this_p)-1;
                        string_data = (char *)(*this_p);
                        dump_basic_string(this);

                        memcpy(string_data + oldlen, string, len);
                        string_data[oldlen + len] = '\0';
                        string_set_shareable(this);
                        this->length = newlen;
                }
                dump_basic_string(this);
        }

        return *this_p;
}


// std::string::append(std::string const&)
struct basic_string *
_ZNSs6appendERKSs(struct basic_string **this_p, struct basic_string **that_p)
{
        struct basic_string *this = (*this_p) - 1;
        struct basic_string *that = (*that_p) - 1;
        debugf("_ZNSs6appendERKSs(%p[%p],%p[%p])\n", this_p, this, that_p, that);
        return _ZNSs6appendEPKcm(this_p, that->data, that->length);
}


// std::string::swap(std::string&)
struct basic_string *
_ZNSs4swapERSs(struct  basic_string **this_p)
{
        koops("_ZNSs4swapERSs");
}


int
__cxa_guard_acquire(void *guard)
{
        debugf("__cxa_guard_acquire(%p)\n", guard);
        return 0;
}

void __cxa_guard_release(void *guard)
{
        debugf("__cxa_guard_release(%p)\n", guard);
}

UNIMPLEMENTED(__cxa_demangle)
UNIMPLEMENTED(__overflow)


// std::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(std::string const&, unsigned long, unsigned long)
UNIMPLEMENTED(_ZNSsC1ERKSsmm);

// std::string::replace(unsigned long, unsigned long, char const*, unsigned long)
UNIMPLEMENTED(_ZNSs7replaceEmmPKcm);

// std::string::assign(std::string const&)
UNIMPLEMENTED(_ZNSs6assignERKSs);

//std::__throw_out_of_range_fmt(char const*, ...)
UNIMPLEMENTED(_ZSt24__throw_out_of_range_fmtPKcz);

// std::string::assign(char const*, unsigned long)
UNIMPLEMENTED(_ZNSs6assignEPKcm);

// std::string::_M_leak_hard()
UNIMPLEMENTED(_ZNSs12_M_leak_hardEv)

// demangledLinePrefix(std::string, std::string, std::string&, bool (*)(std::string, std::string&))
UNIMPLEMENTED(_ZZL13demangledLineSsEN3$_08__invokeESsRSs);


#if DEBUG_BUILD
UNIMPLEMENTED(__cxa_demangle);
UNIMPLEMENTED(__cxa_pure_virtual)

//std::string::data() const
UNIMPLEMENTED(_ZNKSs4dataEv)

//std::string::size() const
UNIMPLEMENTED(_ZNKSs4sizeEv)

//std::string::c_str() const
UNIMPLEMENTED(_ZNKSs5c_strEv)

//std::string::length() const
UNIMPLEMENTED(_ZNKSs6lengthEv)

//std::string::substr(unsigned long, unsigned long) const
UNIMPLEMENTED(_ZNKSs6substrEmm)

//std::allocator<char>::allocator()
UNIMPLEMENTED(_ZNSaIcEC1Ev)

//std::allocator<char>::~allocator()
UNIMPLEMENTED(_ZNSaIcED1Ev)

//std::string::replace(unsigned long, unsigned long, std::string const&)
UNIMPLEMENTED(_ZNSs7replaceEmmRKSs)

//std::string::operator=(char const*)
UNIMPLEMENTED(_ZNSsaSEPKc)

//std::string::operator=(std::string const&)
UNIMPLEMENTED(_ZNSsaSERKSs)

//std::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(std::string&&)
UNIMPLEMENTED(_ZNSsC1EOSs)

//std::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string()
UNIMPLEMENTED(_ZNSsC1Ev)

//std::basic_string<char, std::char_traits<char>, std::allocator<char> >::~basic_string()
UNIMPLEMENTED(_ZNSsD1Ev)

//std::string::operator[](unsigned long)
UNIMPLEMENTED(_ZNSsixEm)

//std::string::operator+=(std::string const&)
UNIMPLEMENTED(_ZNSspLERKSs)

//std::string::operator+=(char const*)
UNIMPLEMENTED(_ZNSspLEPKc)

//std::string::append(char const*)
UNIMPLEMENTED(_ZNSs6appendEPKc)

//std::string::empty() const
UNIMPLEMENTED(_ZNKSs5emptyEv)

//std::string::clear()
UNIMPLEMENTED(_ZNSs5clearEv)

//std::string::push_back(char)
UNIMPLEMENTED(_ZNSs9push_backEc)

//std::string::begin() const
UNIMPLEMENTED(_ZNKSs5beginEv)

//std::string::end() const
UNIMPLEMENTED(_ZNKSs3endEv)

//std::string::find(char const*, unsigned long) const
UNIMPLEMENTED(_ZNKSs4findEPKcm)

//std::string::operator=(std::string&&)
UNIMPLEMENTED(_ZNSsaSEOSs)
#endif


//std::condition_variable::condition_variable()
void
_ZNSt18condition_variableC1Ev(void *cv)
{
        memset(cv, 0, 48);
        debugf("creating condition variable @ %p\n", cv);
}


//std::condition_variable::notify_all()
void
_ZNSt18condition_variable10notify_allEv(void *cv)
{
        debugf("notify_all called on %p\n", cv);
}

//std::condition_variable::wait(std::unique_lock<std::mutex>&)
UNIMPLEMENTED(_ZNSt18condition_variable4waitERSt11unique_lockISt5mutexE)
