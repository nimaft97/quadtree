#include <iostream>
#include <vector>
#include <limits>

#include "structure.hpp"
#include "utils.hpp"

int main(){

    int N = 10, K_MAX = 1;
    std::vector<std::vector<Node>> tree;
    std::vector<Point> points = generatePoints(N); // point(x, y, num) - initially, num = -1 

    std::cerr << "data: " << "\n";
    for (Point point : points)
        std::cerr << "(" << point[0] << "," << point[1] << ") ";
    std::cerr << "\n\n";

    constuctTree(tree, points, K_MAX);
    printTree(tree);
    
    for (Point point : points)
        std::cerr << "(" << point[0] << "," << point[1] << ") ";
    std::cerr << "\n\n";
}