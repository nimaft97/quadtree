#include <iostream>
#include <vector>
#include <limits>

#include "structure.cuh"
#include "utils.cuh"

int main(){

    int N = 10, K_MAX = 1;
    std::vector<std::vector<Node>> tree;
    Point points[N];
    generatePoints(points, N); // point(x, y, num) - initially, num = -1 

    std::cerr << "data: " << "\n";
    for (Point point : points)
        std::cerr << "(" << point.x << "," << point.y << ") ";
    std::cerr << "\n\n";

    constuctTree(tree, points, K_MAX, N);
    printTree(tree);
    
    for (Point point : points)
        std::cerr << "(" << point.x << "," << point.y << ") ";
    std::cerr << "\n\n";
}