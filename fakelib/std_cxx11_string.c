/*
 * fakelib/std_cx11_string.c
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
        unsigned long capacity;
};


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
        struct basic_string *str)
{
        koops("UNIMPLEMENTED: swap(%p, %p)\n", this, str);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::reserve(unsigned long)
void
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7reserveEm(
        struct basic_string *this,
        size_t len)
{
        koops("UNIMPLEMENTED: reserve(%p, %zu)\n", this, len);
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_append(char const*, unsigned long)
struct basic_string *
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_appendEPKcm(
        struct basic_string *this,
        const char *str,
        size_t len)
{
        koops("UNIMPLEMENTED: append(%p, '%s', %zu)\n", this, str, len);
        return this;
}


// std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::_M_create(unsigned long&, unsigned long)
char *
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(
        struct basic_string *this,
        size_t *capacity,
        size_t old_capacity)
{
        koops("UNIMPLEMENTED: _M_create(%p, %zu, %zu)\n", this, *capacity,
              old_capacity);
        return malloc(*capacity);
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
