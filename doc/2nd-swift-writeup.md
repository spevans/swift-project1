
## throw v nil

Swift has two mechanisms for returning errors from functions; throwing exceptions
and returning optional values with nil. I still havent decided which I prefer for
error returns but here are some random thoughts:

1. The iOS APIs mostly return nil (to be compatible with Objective-C) but some
are using throws instead. I dont know if Apple eventually intends to convert
everything to throws but it would be good to know what the Swift developers
intend to do.

2. throws is better if the error needs to be propagated through multiple levels
since it is done automatically. With optionals it will need be to be propagated
manually.

3.

## Notes on memory allocation

## malloc() / realloc() (varargs, print(x,y,z) v print("\(x) \(y) \(z)")



- Notes on memory allocation
- Other swift/C notes, Swift v C
