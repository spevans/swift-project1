/*
 * klibc/std_cx11_string.c
 *
 * Created by Simon Evans on 27/12/2016.
 * Copyright © 2016 - 2019 Simon Evans. All rights reserved.
 *
 * libcpp std::string / std::basic_string calls used by Linux libswiftCore.
 * Based on glibc libstdc++ C++11 with no refcounting.
 *
 */

#define DEBUG 0
#include "klibc.h"
#include <assert.h>

#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-variable"


struct basic_string {
        char *string;
        unsigned long length;
        union {
                unsigned long capacity;
                char short_string[16];
        };
};


static const size_t short_string_capacity = 15;
static const size_t max_string_size = LONG_MAX;

static inline int
is_short_string(const struct basic_string *this)
{
        return (this->string == this->short_string);
}

static inline size_t
capacity(const struct basic_string *this)
{
        return is_short_string(this) ? short_string_capacity : this->capacity;
}

static inline void
dump_basic_string(const struct basic_string *this)
{
        debugf("DBS %p->(len: %lu, cap: %zu, str: addr=%p \"%s\") is_short: %d\n", this,
               this->length, capacity(this), this->string, this->string, is_short_string(this));
}


static char *
__create_storage( struct basic_string *this,
        size_t *capacity,
        size_t old_capacity)
{
        debugf("__create_storage(%zu, %zu)\n", *capacity, old_capacity);
        if (*capacity > max_string_size) {
                koops("Alloc of string > max_string_size");
        }
        if (*capacity > old_capacity) {
                old_capacity *= 2;
                if (*capacity >= old_capacity) {
                        return malloc(*capacity + 1);
                }
                if (old_capacity <= max_string_size) {
                        *capacity = old_capacity;
                        return malloc(*capacity + 1);
                } else {
                        *capacity = max_string_size;
                        return malloc(max_string_size + 1);
                }
        }
        return malloc(*capacity + 1);
}


// Resize the underlying storage to hold a new size (capacity may still be
// greater). If shrinking the string it may be converted to a short string.
// If a heap stored string will still be a heap stored string after shrinking,
// dont bother to reallocate the storage just keep it the same size/capacity.
// If length is increased, the extra storage will contained undefined data
// but will still be nul terminated.
// The old string data is returned if not copied and freed.
static char *
__resize_string(struct basic_string *this, size_t new_size, int copy_and_free)
{
        char *result = NULL;

        debugf("__resize_string(%p, %zu, %d)\n", this, new_size, copy_and_free);
        dump_basic_string(this);
        if (new_size < this->length) {
                debugf("new_size (%zu) < length (%zu)\n", new_size, this->length);
                // Can it be converted to a short string? Convert if so,
                // otherwise dont bother to shrink the allocated string.
                if (new_size <= short_string_capacity) {
                        if (!is_short_string(this)) {
                                if (copy_and_free) {
                                        memcpy(this->short_string, this->string,
                                               new_size);
                                        free(this->string);
                                } else {
                                        result = this->string;
                                }
                                this->string = this->short_string;
                        }
                }
        } else if (new_size > capacity(this)) {
                size_t new_capacity = new_size;
                char *new_string = __create_storage(this, &new_capacity,
                                                    capacity(this));
                if (!new_string) {
                        koops("malloc");
                }
                if (copy_and_free) {
                        memcpy(new_string, this->string, this->length);
                        if (!is_short_string(this)) {
                                free(this->string);
                        }
                } else {
                        result = this->string;
                }
                this->capacity = malloc_usable_size(new_string) - 1;
                this->string = new_string;
        }
        // The bytes between the old length and the new will be undefined
        this->string[this->length] = '\0';
        dump_basic_string(this);

        return result;
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::swap(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >&)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4swapERS4_(
        struct basic_string *this,
        struct basic_string *other)
{
        debugf("swap: %p->(%p)\n", this, other);
        dump_basic_string(this);
        dump_basic_string(other);
        if (this != other) {
                struct basic_string tmp = *this;
                int ss = is_short_string(this);
                *this = *other;
                if (is_short_string(other)) {
                        this->string = this->short_string;
                }
                *other = tmp;
                if (ss) {
                        other->string = other->short_string;
                }
        }
        dump_basic_string(this);
        dump_basic_string(other);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::reserve(unsigned long)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7reserveEm(
        struct basic_string *this,
        size_t len)
{
        koops("UNIMPLEMENTED: reserve(%p, %zu)\n", this, len);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_create(unsigned long&, unsigned long)
char *
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(
        struct basic_string *this,
        size_t *capacity,
        size_t old_capacity)
{
        debugf("%p->_M_create(%zu, %zu)\n", this, *capacity, old_capacity);

        size_t new_capacity = *capacity;
        if (new_capacity > max_string_size) {
                koops("_M_create string legnth too large");
        }

        if (new_capacity > old_capacity && new_capacity < old_capacity * 2) {
                new_capacity = old_capacity * 2;
                if (new_capacity > max_string_size) {
                        new_capacity = max_string_size;
                }
        }
        *capacity = new_capacity;
        return malloc(new_capacity + 1);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_append(char const*, unsigned long)
struct basic_string *
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_appendEPKcm(
        struct basic_string *this,
        const char *str,
        size_t len)
{
        debugf("%p->_M_append('%s', %zu)\n", this, str, len);
        dump_basic_string(this);

        if (len > 0) {
                size_t length = this->length;
                __resize_string(this, length + len + 1, 1);
                memcpy(this->string + length, str, len);
                this->length += len;
                this->string[this->length] = '\0';
        }
        dump_basic_string(this);
        return this;
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_mutate(unsigned long, unsigned long, char const*, unsigned long)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEmmPKcm(
        struct basic_string *this,
        size_t pos,
        size_t len1,
        char const *str,
        size_t len2)
{
        debugf("_M_mutate(%p, pos: %zu, len1: %zu, '%s', len2: %zu\n", this, pos, len1, str, len2);
        dump_basic_string(this);
        size_t how_much = this->length - pos - len1;
        size_t new_capacity = this->length + len2 - len1;
        size_t new_length = new_capacity;
        char *data = _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(this, &new_capacity, capacity(this));
        if (pos) { memcpy(data, this->string, pos); }
        if (str && len2) { memcpy(data + pos, str, len2); }
        if (how_much) {
                memcpy(data + pos + len2, this->string + pos + len1, how_much);
        }
        if (!is_short_string(this)) {
                free(this->string);
                this->capacity = new_capacity;
                this->string = data;
        }
        this->length = new_length;
        this->string[this->length] = '\0';

        dump_basic_string(this);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_replace(unsigned long, unsigned long, char const*, unsigned long)
struct basic_string *
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_replaceEmmPKcm(
        struct basic_string *this,
        size_t pos,
        size_t len1,
        const char *str,
        size_t len2)
{
        debugf("_M_replace(%p, %zu, %zu, '%s', %zu)\n", this, pos, len1, str, len2);
        dump_basic_string(this);
        size_t __old_size = this->length;
        size_t __new_size = __old_size + len2 - len1;

        // TODO: Should do in buffer replacement if buffer is big enough, only
        // falling back got _M_mutate if not.
        _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEmmPKcm(
               this, pos, len1, str, len2);
        dump_basic_string(this);
        return this;
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::resize(unsigned long, char)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6resizeEmc(
        struct basic_string *this,
        size_t new_size,
        char ch)
{
        koops("UNIMPLEMENTED: %p->resize(%zu, '%c')\n", this, new_size, ch);
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_assign(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_assignERKS4_(
        struct basic_string *this,
        const struct basic_string *other)
{
        debugf("%p->_M_assign(%p)\n", this, other);
        dump_basic_string(other);
        if (this == other) {
                return;
        }

        if (other->length > capacity(this)) {
                size_t new_capacity = other->length;
                char *data = _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(this, &new_capacity, capacity(this));
                if(!is_short_string(this)) {
                        free(this->string);
                }
                this->string = data;
                this->capacity = new_capacity;
        }
        this->length = other->length;
        if (this->length > 0) {
                memcpy(this->string, other->string, this->length);
        }
        this->string[this->length] = '\0';
        dump_basic_string(this);
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_replace_aux(unsigned long, unsigned long, unsigned long, char)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE14_M_replace_auxEmmmc(
        struct basic_string *this,
        unsigned long pos1,
        unsigned long size1,
        unsigned long size2,
        char ch) {
        dump_basic_string(this);

        debugf("%p->_M_replace_aux(%lu, %lu, %lu, '%c')\n",
               this, pos1, size1, size2, ch);

        size_t new_size = this->length + size2 - size1;
        if (new_size <= capacity(this)) {
                char * p = this->string + pos1;
                size_t how_much = this->length - pos1 - size1;
                if (how_much && size1 != size2) {
                        memcpy(p + size2, p + size1, how_much);
                }
        } else {
                _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_mutateEmmPKcm(this, pos1, size1, NULL, size2);
        }

        if (size2) {
                memset(this->string + pos1, ch, size2);
        }
        this->length = new_size;
        dump_basic_string(this);
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::operator=(char const*)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEPKc (
        struct basic_string *this,
        char const *str) {

        dump_basic_string(this);
        size_t len = strlen(str);
        __resize_string(this, len + 1, 1);
        memcpy(this->string, str, len);
        this->length = len;
        this->string[this->length] = '\0';
        dump_basic_string(this);
}


/***** DEBUG ONLY - These functions are only used then the swift runtime is compiled with -g, normally these are inlined by the string header file ******/

// std::allocator<char>::allocator()
void _ZNSaIcEC1Ev() {}

// std::allocator<char>::~allocator()
void _ZNSaIcED1Ev() {}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string()
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(
        struct basic_string *this
        )
{
        debugf("%p->()\n", this);
        this->length = 0;
        this->string = this->short_string;
        this->short_string[0] = '\0';
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::~basic_string()
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(
        struct basic_string *this
        )
{
        debugf("%p->~()\n", this);
        if (!is_short_string(this)) {
                free(this->string);
                this->string = this->short_string;
        }
        this->length = 0;
        this->short_string[0] = '\0';
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::data() const
const char *
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4dataEv(
        struct basic_string *this)
{
        debugf("%p->data()\n", this);
        dump_basic_string(this);
        return this->string;
}

// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::size() const
size_t
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv(
        struct basic_string *this)
{
        debugf("%p->size()\n", this);
        dump_basic_string(this);
        return this->length;
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::c_str() const
const char *
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5c_strEv(
        struct basic_string *this)
{
        debugf("%p->c_str()\n", this);
        dump_basic_string(this);
        return this->string;
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::empty() const
int
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5emptyEv(
        struct basic_string *this)
{
        debugf("%p->empty()\n", this);
        dump_basic_string(this);
        return this->length == 0;
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::length() const
size_t
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv(
        struct basic_string *this)
{
        debugf("%p->length()\n", this);
        dump_basic_string(this);
        return this->length;
}

// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::capacity() const
size_t
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE8capacityEv(
        struct basic_string *this)
{
        debugf("%p->capacity()\n", this);
        dump_basic_string(this);
        return capacity(this);
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::clear()
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5clearEv(
        struct basic_string *this)
{
        debugf("%p->clear()\n", this);
        this->length = 0;
        this->string[0] = '\0';
        dump_basic_string(this);
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::append(char const *)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6appendEPKc(
        struct basic_string *this,
        char const *string)
{
        debugf("%p->append('%s')\n", this, string);
        dump_basic_string(this);
        size_t length = strlen(string);
        _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_appendEPKcm(this, string, length);
        dump_basic_string(this);
}


//std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::append(char const *, unsigned long)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6appendEPKcm(
        struct basic_string *this,
        char const *string,
        size_t length)
{
        debugf("%p->append('%s', %zu)\n", this, string, length);
        dump_basic_string(this);
        _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_appendEPKcm(this, string, length);
        dump_basic_string(this);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::push_back(char)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9push_backEc(
        struct basic_string *this,
        char ch)
{
        debugf("%p->push_back('%c')\n", this, ch);
        dump_basic_string(this);
        if (this->length == capacity(this)) {
                __resize_string(this, this->length + 1, 1);
        }
        this->string[this->length] = ch;
        this->length++;
        this->string[this->length] = '\0';
        dump_basic_string(this);
}

// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1ERKS4_(
        struct basic_string *this,
        struct basic_string *other)
{
        // copy constructor
        debugf("%p->copy(%p)\n", this, other);
        dump_basic_string(other);
        size_t copy_len;
        if(is_short_string(other)) {
                this->string = this->short_string;
                copy_len = sizeof(this->short_string);
        } else {
                copy_len = other->length + 1;
                this->string = malloc(copy_len);
                size_t new_capacity = malloc_usable_size(this->string) - 1;
                assert(new_capacity > 0);
                this->capacity = new_capacity;
        }
        this->length = other->length;
        memcpy(this->string, other->string, copy_len);
        dump_basic_string(this);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::operator=(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >&&)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEOS4_(
        struct basic_string *this,
        struct basic_string *other)
{
        // operator=
        debugf("%p->operator=(%p)\n", this, other);
        dump_basic_string(other);
        if (is_short_string(other)) {
                this->string = this->short_string;
                memcpy(this->short_string, other->short_string, sizeof(this->short_string));
        } else {
                this->string = other->string;
                this->capacity = other->capacity;
                other->string = other->short_string;
        }
        this->length = other->length;
        other->length = 0;
        other->string = other->short_string;
        other->string[0] = '\0';
        dump_basic_string(this);
        dump_basic_string(other);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >&&)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EOS4_(
        struct basic_string *this,
        struct basic_string *other)
{
        // Move the string from other to this
        debugf("%p->move(%p)\n", this, other);
        dump_basic_string(other);
        if (is_short_string(other)) {
                this->string = this->short_string;
                memcpy(this->short_string, other->short_string, sizeof(this->short_string));
        } else {
                this->string = other->string;
                this->capacity = other->capacity;
                other->string = other->short_string;
        }
        this->length = other->length;
        other->length = 0;
        other->string[0] = '\0';
        dump_basic_string(this);
        dump_basic_string(other);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(char const*, unsigned long, std::allocator<char> const&)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EPKcmRKS3_(
        struct basic_string *this,
        char const *string,
        size_t length,
        void *allocator)
{
        debugf("%p->('%s', %zu, allocator)\n", this, string, length);
        if (length > short_string_capacity) {
                this->string = malloc(length + 1);
                size_t size = malloc_usable_size(this->string);
                assert(size > 0);
                this->capacity = size - 1;
        } else {
                this->string = this->short_string;
        }
        memcpy(this->string, string, length);
        this->length = length;
        this->string[length] = '\0';
        dump_basic_string(this);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::append(unsigned long, char)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6appendEmc(
        struct basic_string *this,
        size_t count,
        char ch)
{
        debugf("%p->append(%zu, '%c')\n", this, count, ch);
        dump_basic_string(this);
        size_t length = this->length;
        __resize_string(this, length + count + 1, 1);
        while (count--) {
                this->string[length++] = ch;
        }
        this->string[length] = '\0';
        this->length = length;
        dump_basic_string(this);
}

// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::operator+=(char)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLEc(
        struct basic_string *this,
        char ch)
{
        debugf("%p->+=('%c')\n", this, ch);
        dump_basic_string(this);
        size_t length = this->length;
        __resize_string(this, length + 1, 1);
        this->string[length++] = ch;
        this->string[length] = '\0';
        this->length = length;
        dump_basic_string(this);
}


UNIMPLEMENTED(_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE3endEv);
UNIMPLEMENTED(_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE5beginEv);
UNIMPLEMENTED(_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6appendERKS4_);
UNIMPLEMENTED(_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6insertEmRKS4_);
UNIMPLEMENTED(_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6resizeEm);
UNIMPLEMENTED(_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EPKcRKS3_);
UNIMPLEMENTED(_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEixEm);
UNIMPLEMENTED(_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLEPKc);
UNIMPLEMENTED(_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEpLERKS4_);
