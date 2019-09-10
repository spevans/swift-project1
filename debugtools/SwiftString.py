#!/usr/bin/python


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
