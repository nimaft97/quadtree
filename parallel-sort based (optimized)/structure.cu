#include <algorithm>
#include <iterator>

#include "structure.cuh"

__host__ __device__
void Node::initialize(int x1, int y1, int x2, int y2, int left, int right){
    initialized = true;
    setBottomLeftPoint(x1, y1);
    setTopRightPoint(x2, y2);
    setIdx(left, right);
}

__host__ __device__
void Node::setIdx(int left, int right){
    idx_s = left;
    idx_e = right;
}

__host__ __device__
bool Node::isInitialized(){
    return initialized;
}

__host__ __device__
bool Node::mustSplit(int K_MAX){
        return (idx_e - idx_s + 1) > K_MAX;
}

__host__ __device__
void Node::getIdx(int& left, int& right){
    left = idx_s;
    right = idx_e;
}

__host__ __device__
void Node::getBottomLeftPoint(int& x, int& y){
    x = x_min;
    y = y_min;
}

__host__ __device__
void Node::getTopRightPoint(int& x, int& y){
    x = x_max;
    y = y_max;
}

__host__ __device__
void Node::setChildren(int* childNodesArr){
    for (int i=0; i<4; i++)
        children[i] = childNodesArr[i];
}

__host__ __device__
void Node::setBottomLeftPoint(int x, int y){

    x_min = x;
    y_min = y;
}

__host__ __device__
void Node::setTopRightPoint(int x, int y){

    x_max = x;
    y_max = y;
}

__host__ __device__
void Node::getChildren(int* arr){
    for (int i=0; i<4; i++)
        arr[i] = children[i];
}   