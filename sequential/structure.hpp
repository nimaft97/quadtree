#ifndef STRUCTURE_HPP
#define STRUCTURE_HPP

#include <iostream>
#include <vector>

typedef std::vector<int> Point;

struct Node{
private:
    std::string path;
    int x_min, y_min, x_max, y_max;
    Node* children[4];
    int idx_s, idx_e; // inclusive

public:
    Node(float x, float y, float X, float Y, int idx1, int idx2, std::string s);
    Node(const Node& node);
    bool mustSplit(int K_MAX);
    std::vector<int> getIdx();
    Point getBottomLeftPoint();
    Point getTopRightPoint();
    std::string getPath();
    void setBottomLeftPoint(int x, int y);
    void setTopRightPoint(int x, int y);
    void setChildren(Node childNodesArr[4]);
};

extern std::vector<std::vector<Node>> tree;

#endif