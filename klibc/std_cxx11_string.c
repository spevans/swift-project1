/*
 * klibc/std_cx11_string.c
 *
 * Created by Simon Evans on 27/12/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * libcpp std::string / std::basic_string calls used by Linux libswiftCore.
 * Based on glibc libstdc++ C++11 with no refcounting.
 *
 * Currently unimplemented as none of the functions are actually called
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-variable"

static const size_t npos = -1;

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
is_short_string(struct basic_string *this)
{
        return (this->string == this->short_string);
}

static inline size_t
capacity(struct basic_string *this)
{
        return is_short_string(this) ? short_string_capacity : this->capacity;
}

static inline void
dump_basic_string(struct basic_string *this)
{
        debugf("DBS %p->(%lu, %zu, addr=%p \"%s\")\n", this,
               this->length, capacity(this), this->string, this->string);
}



// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::find(char const*, unsigned long, unsigned long) const
size_t
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4findEPKcmm(
        struct basic_string *this,
        char const *str,
        size_t pos,
        size_t len)
{
        koops("UNIMPLEMENTED: find(%p, str='%s', pos=%ld, len=%ld)\n", this,
              str, pos, len);
        return npos;
}



// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::compare(char const*) const
int
_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7compareEPKc(
        struct basic_string *this,
        const char *str)
{
        koops("UNIMPLEMENTED: compare(%p, str='%s')\n", this, str);
        return 0;
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
        koops("UNIMPLEMENTED: replace(%p, %zu, %zu, '%s', %zu)\n", this, pos, len1,
              str, len2);
        return this;
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


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string(std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > const&, unsigned long, unsigned long)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC2ERKS4_mm(
        struct basic_string *this,
        struct basic_string *that,
        unsigned long l1, unsigned long l2)
{
        koops("UNIMPLEMENTED: _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC2ERKS4_mm");
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_create(unsigned long&, unsigned long)
char *
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(
        struct basic_string *this,
        size_t *capacity,
        size_t old_capacity)
{
        debugf("_M_create(%p, %zu, %zu)\n", this, *capacity, old_capacity);
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


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_append(char const*, unsigned long)
struct basic_string *
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_appendEPKcm(
        struct basic_string *this,
        const char *str,
        size_t len)
{
        debugf("append: %p->('%s', %zu)\n", this, str, len);
        dump_basic_string(this);

        if (len > 0) {
                size_t new_length = this->length + len;
                if (new_length > capacity(this)) {
                        size_t new_capacity = new_length;
                        char *new_string = _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(this, &new_capacity, capacity(this));
                        if (!new_string) {
                                koops("malloc");
                        }
                        if (this->length > 0) {
                                memcpy(new_string, this->string, this->length);
                        }
                        if (!is_short_string(this)) {
                                free(this->string);
                        }
                        this->string = new_string;
                        this->capacity = new_capacity;
                }
                memcpy(this->string + this->length, str, len);
                this->string[new_length] = '\0';
                this->length = new_length;
        }
        dump_basic_string(this);

        //  koops("UNIMPLEMENTED: append(%p, '%s', %zu)\n", this, str, len);
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
        koops("UNIMPLEMENTED: _M_mutate(%p, %zu, %zu, %s, %zu)\n", this, pos,
              len1, str, len2);
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
