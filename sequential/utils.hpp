#ifndef UTILS_HPP
#define UTILS_HPP

#include <vector>
#include <cstdlib>
#include <ctime>
#include <algorithm>
#include <cassert>

#include "structure.hpp"

std::vector<Point> generatePoints(int length){
    std::srand(std::time(NULL));
    std::vector<Point> points(length);
    std::generate(points.begin(), points.end(), [](){
        Point point;
        point.push_back(rand()%10);
        point.push_back(rand()%10);
        point.push_back(-1);
        return point;
    });
    return points;
}

Point assignNumPoint(const Point& point, int x_min, int y_min, int x_range, int y_range, std::vector<int>& counts){
    int xIndex = int(2.0*float(point[0]-x_min)/(float(x_range)+0.01)); // margin is added
    int yIndex = int(2.0*float(point[1]-y_min)/(float(y_range)+0.01)); // margin is added
    int number = 2*yIndex + xIndex;
    // std::cerr << "number = " << number << ": " << x_min << " " << y_min << " " << x_range << " " << y_range << " " << point[0] << " " << point[1] << "\n";
    counts.at(number)++; // used .art() instead of assert and []
    return {point[0], point[1], number};
}

std::vector<int> assignNumPoints(std::vector<Point>& points, Node anscestor){
    std::vector<int> counts(4, 0);
    Point bottomLeftPoint = anscestor.getBottomLeftPoint();
    int x_min = bottomLeftPoint[0], y_min = bottomLeftPoint[1];

    Point topRightPoint = anscestor.getTopRightPoint();
    int x_max = topRightPoint[0], y_max = topRightPoint[1];

    int x_range = x_max - x_min, y_range = y_max - y_min;
    // std::cerr << "x_min: " << x_min << " y_min: " << y_min << ", x_max: " << x_max << " y_max: " << y_max << "\n";

    std::vector<int> idx_arr = anscestor.getIdx();
    int idx_s = idx_arr[0], idx_e = idx_arr[1];
    std::transform(points.begin()+idx_s, points.begin()+idx_e+1, points.begin()+idx_s, [&](Point& point){
        return assignNumPoint(point, x_min, y_min, x_range, y_range, counts);
    });
    return counts;
}

void constuctTree(std::vector<std::vector<Node>>& tree, std::vector<Point>& points, int K_MAX){
    int N = points.size();
    bool end = K_MAX >= N;
    if (!end){ 
        // collect metadata
        int x1=std::numeric_limits<int>::max(), y1=std::numeric_limits<int>::max(), \
        x2=-1*std::numeric_limits<int>::max(), y2=-1*std::numeric_limits<int>::max();
        std::for_each(points.begin(), points.end(), [&](Point point){
            x1 = std::min(x1, point[0]); y1 = std::min(y1, point[1]); // bottom left
            x2 = std::max(x2, point[0]); y2 = std::max(y2, point[1]); // upper right

            // std::cerr << "x1: " << x1 << ", y1: " << y1 << ", x2: " << x2 << ", y2: " << y2 << "\n";
        });
        // x2 += 1, y2 += 1; // the smallest possible margin when data is of type int to be added to make sure that all points are covered
        
        // insert the first level of the tree
        tree.push_back({Node(x1, y1, x2, y2, 0, N-1, "")});
    }
    while (!end){ // at least one node contains more points than K_MAX
        std::vector<Node> level_new;
        for (Node node : tree[tree.size()-1]){ // iterating over the nodes in last level of the tree
            if (node.mustSplit(K_MAX)){ // this node has contains more data than K_MAX
                std::vector<int> counts = assignNumPoints(points, node);
                std::vector<int> idx_arr = node.getIdx();
                int idx_s = idx_arr[0], idx_e = idx_arr[1];

                std::string path = node.getPath();

                Point point_s = node.getBottomLeftPoint();
                int x_s = point_s[0], y_s = point_s[1];

                Point point_e = node.getTopRightPoint();
                int x_e = point_e[0], y_e = point_e[1];

                int x_m = (x_s+x_e)/2, y_m = (y_s+y_e)/2;

                // std::cerr << "\n\n x_s: " << x_s << ", y_s: " << y_s << ", x_e: " << x_e << ", y_e: " << y_e << ", x_m: " << x_m << ", y_m: " << y_m << "\n\n";

                std::sort(points.begin()+idx_s, points.begin()+idx_e+1, [](const Point& a, const Point& b){
                    return a[2] < b[2];
                });
                
                Node node0(x_s, y_s, x_m, y_m, idx_s, idx_s+counts[0]-1, path+"0");
                Node node1(x_m, y_s, x_e, y_m, idx_s+counts[0], idx_s+counts[0]+counts[1]-1, path+"1");
                Node node2(x_s, y_m, x_m, y_e, idx_s+counts[0]+counts[1], idx_s+counts[0]+counts[1]+counts[2]-1, path+"2");
                Node node3(x_m, y_m, x_e, y_e, idx_s+counts[0]+counts[1]+counts[2], idx_s+counts[0]+counts[1]+counts[2]+counts[3]-1, path+"3");

                Node childNodesArr[] = {node0, node1, node2, node3};
                node.setChildren(childNodesArr);
                std::copy(childNodesArr, childNodesArr+4, std::back_inserter(level_new));
                // level_new.push_back(node0); level_new.push_back(node1);
                // level_new.push_back(node2); level_new.push_back(node3);

            }
        }
        if (level_new.size()==0)
            end = true;
        else
            tree.push_back(level_new);
    }

}

void printTree(const std::vector<std::vector<Node>>& tree){
    for (int i=0; i<tree.size(); i++){
        std::cerr << "level " << i << "\n\n";
        for (int j=0; j<tree[i].size(); j++){
            Node node = tree[i][j];
            std::cerr << "Node " << i << "-" << j << ":\n";
            std::cerr << "\tpath: " << node.getPath() << "\n";
            std::cerr << "\tbounding box: (" << node.getBottomLeftPoint()[0] << "," << node.getBottomLeftPoint()[1] << ") , (" << node.getTopRightPoint()[0] << "," << node.getTopRightPoint()[1] << ")\n";
            std::cerr << "\tindices: [" << node.getIdx()[0] << "-" << node.getIdx()[1] << "]\n";
            std::cerr << "\n";
        }
    }
}

#endif