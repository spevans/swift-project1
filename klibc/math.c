/*
 * klibc/math.c
 *
 * Created by Simon Evans on 21/05/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Fake math calls used by libswiftCore
 *
 */


/* Floating point functions.
 * If using stdlib without FP functions these are not needed and MMX,SSE can
 * be disabled
 */

#if USE_FP
UNIMPLEMENTED(arc4random)
UNIMPLEMENTED(arc4random_uniform)
UNIMPLEMENTED(ceil)


float ceilf(float f)
{
        long result = (long)f;
        if ((float)result < f) {
                result++;
        }
        float resultf = (float)result;
        debugf("ceilf(%ld)=%ld\n", (long)f, (long)resultf);

        return resultf;
}

UNIMPLEMENTED(cos)
UNIMPLEMENTED(cosf)
UNIMPLEMENTED(exp)
UNIMPLEMENTED(exp2)
UNIMPLEMENTED(exp2f)
UNIMPLEMENTED(expf)
UNIMPLEMENTED(floor)
UNIMPLEMENTED(floorf)
UNIMPLEMENTED(fmod)
UNIMPLEMENTED(fmodf)
UNIMPLEMENTED(fmodl)
UNIMPLEMENTED(log)
UNIMPLEMENTED(log10)
UNIMPLEMENTED(log10f)
UNIMPLEMENTED(log2)
UNIMPLEMENTED(log2f)
UNIMPLEMENTED(logf)
UNIMPLEMENTED(nearbyint)
UNIMPLEMENTED(nearbyintf)
UNIMPLEMENTED(rint)
UNIMPLEMENTED(rintf)
UNIMPLEMENTED(round)
UNIMPLEMENTED(roundf)
UNIMPLEMENTED(sin)
UNIMPLEMENTED(sinf)
UNIMPLEMENTED(strtod_l)
UNIMPLEMENTED(strtof_l)
UNIMPLEMENTED(strtold_l)
UNIMPLEMENTED(trunc)
UNIMPLEMENTED(truncf)

#endif
