//
//  grafty_core_fft.h
//  grafty-hr
//
//  Created by Manish Mukherjee on 6/10/15.
//  Copyright (c) 2015 Grafty. All rights reserved.
//

#ifndef __grafty_vp__grafty_core_fft__
#define __grafty_vp__grafty_core_fft__

#include <stdio.h>
#include <complex>
#include <iostream>
#include <valarray>
#include "grafty-core-utils.h"


typedef std::complex<double>   ComplexT;
typedef std::valarray<ComplexT> CArray;
extern void fft(CArray& x);


#endif /* defined(__grafty_vp__grafty_core_fft__) */
