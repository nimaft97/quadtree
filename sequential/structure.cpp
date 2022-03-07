#include <algorithm>
#include <iterator>

#include "structure.hpp"

Node::Node(float x, float y, float X, float Y, int idx1, int idx2, std::string s): \
x_min(x), y_min(y), x_max(X), y_max(Y), idx_s(idx1), idx_e(idx2), path(s){
    std::fill(children, children+4, nullptr);
}

Node::Node(const Node& node): x_min(node.x_min), y_min(node.y_min), x_max(node.x_max), y_max(node.y_max),\
idx_s(node.idx_s), idx_e(node.idx_e), path(node.path){
    std::fill(children, children+4, nullptr);
}

bool Node::mustSplit(int K_MAX){
        return (idx_e - idx_s + 1) > K_MAX;
}

std::vector<int> Node::getIdx(){
    return {idx_s, idx_e};
}

Point Node::getBottomLeftPoint(){
    return {x_min, y_min};
}

Point Node::getTopRightPoint(){
    return {x_max, y_max};
}

void Node::setChildren(Node childNodesArr[4]){
    std::transform(childNodesArr, childNodesArr+4, children, [](Node node){
        return new Node(node);
    });
}

void Node::setBottomLeftPoint(int x, int y){

    x_min = x;
    y_min = y;
}

void Node::setTopRightPoint(int x, int y){

    x_max = x;
    y_max = y;
}

std::string Node::getPath(){
    return path;
}