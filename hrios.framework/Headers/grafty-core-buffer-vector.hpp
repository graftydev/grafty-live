//
//  HRBufferVector.hpp
//  hrios
//
//  Created by Manish Mukherjee on 10/19/15.
//  Copyright © 2015 Grafty. All rights reserved.
//

#ifndef HRBufferVector_hpp
#define HRBufferVector_hpp

#include <stdio.h>
#include <deque>

#endif /* HRBufferVector_hpp */


class HRBufferVector {
private:
    std::deque<float>  bufferVector;
    float maxIdx;
    float minIdx;
    int find_max();
    int find_min();
    
public:
    HRBufferVector(void);
    float push_back(float);
    void  pop_front();
    void  clear();
    inline size_t   size() {
        return this->bufferVector.size();
    };
    float min();
    float max();
    inline float at(size_t i) {
        return this->bufferVector[i];
    };
};

