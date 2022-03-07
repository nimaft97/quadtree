#ifndef STRUCTURE_CUH
#define STRUCTURE_CUH

#include <iostream>
#include <vector>

struct Point{
public:
    int x;
    int y;
    int num;
};

struct Node{
private:
    
    bool initialized = false;
    int x_min, y_min, x_max, y_max;
    int children[4] = {-1, -1, -1, -1}; // indices of children - either the index in GPU or CPU
    int idx_s = -1, idx_e = -1; // inclusive

public:

    __host__ __device__
    bool isInitialized();
    __host__ __device__
    bool mustSplit(int);
    __host__ __device__
    void getIdx(int&, int&);
    __host__ __device__
    void getBottomLeftPoint(int&, int&);
    __host__ __device__
    void getTopRightPoint(int&, int&);
    __host__ __device__
    void setIdx(int, int);
    __host__ __device__
    void setBottomLeftPoint(int x, int y);
    __host__ __device__
    void setTopRightPoint(int x, int y);
    __host__ __device__
    void setChildren(int* childNodesArr);
    __host__ __device__
    void initialize(int, int, int, int, int, int); // instead of constructor
    __host__ __device__
    void getChildren(int*);
};

extern std::vector<std::vector<Node>> tree;

#endif