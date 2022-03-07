#ifndef UTILS_CUH
#define UTILS_CUH

#include <vector>
#include <cstdlib>
#include <ctime>
#include <algorithm>
#include <numeric>
#include <cassert>
#include <thrust/sort.h>
#include <thrust/execution_policy.h>

#include "structure.cuh"

void generatePoints(Point* points, int length){
    std::srand(std::time(NULL));
    for (int i=0; i<length; i++){
        points[i].x = rand()%10;
        points[i].y = rand()%10;
        points[i].num = -1;
    }
}

void printTree(const std::vector<std::vector<Node>>& tree){
    for (int i=0; i<tree.size(); i++){
        std::cerr << "level " << i << "\n\n";
        for (int j=0; j<tree[i].size(); j++){
            Node node = tree[i][j];
            std::cerr << "Node " << i << "-" << j << ":\n";
            // std::cerr << "\tpath: " << node.getPath() << "\n";
            int x_min, y_min, x_max, y_max, idx_s, idx_e;
            node.getBottomLeftPoint(x_min, y_min);
            node.getTopRightPoint(x_max, y_max);
            node.getIdx(idx_s, idx_e);
            int childrenIdx[4]; node.getChildren(childrenIdx);
            std::cerr << "\tbounding box: (" << x_min << "," << y_min << ") , (" << x_max << "," << y_max << ")\n";
            std::cerr << "\tindices: [" << idx_s << "-" << idx_e << "]\n";
            std::cerr << "\tchildren: "; 
            for (int k=0; k<4; k++) std::cerr << childrenIdx[k] << " ";
            std::cerr << "\n";
            std::cerr << "\n";
        }
    }
}

__host__ __device__
void assignNumPoint(Point& point, int x_min, int y_min, int x_range, int y_range, int* counts){
    int xIndex = int(2.0*float(point.x-x_min)/(float(x_range)+0.01)); // margin is added
    int yIndex = int(2.0*float(point.y-y_min)/(float(y_range)+0.01)); // margin is added
    int number = 2*yIndex + xIndex;
    assert(number >= 0 && number < 4);
    counts[number]++;
    point.num = number;
}

__host__ __device__
void assignNumPoints(Point* points, Node anscestor, int* counts, int N){
    int x_min, y_min, x_max, y_max, idx_s, idx_e;
    anscestor.getBottomLeftPoint(x_min, y_min);
    anscestor.getTopRightPoint(x_max, y_max);
    anscestor.getIdx(idx_s, idx_e);
    assert(idx_e<N);
    assert(idx_s>=0);
    int x_range = x_max - x_min, y_range = y_max - y_min;
    
    for (int i=idx_s; i<idx_e+1; i++) // simple for loop because it's going to be called by the kernel
        assignNumPoint(points[i], x_min, y_min, x_range, y_range, counts);
}

void copyTree2Arr(const std::vector<std::vector<Node>>& tree, Node* nodes, int& nodeNum, int K_MAX){
    // the last level of the tree with the size of nodeNum will be copied to the nodes.
    nodeNum = 0;
    int size = tree.size();
    std::cerr << "size: " << size << "\n";
    std::cerr << "size of last level: " << tree[size-1].size() << "\n";
    std::copy_if(tree[size-1].begin(), tree[size-1].end(), nodes, [&](Node node){
        if (node.mustSplit(K_MAX)){
            nodeNum++;
            std::cerr << "yes\n";
            return true;
        }
        return false;
    });
}

void appendArr2Tree(std::vector<std::vector<Node>>& tree, Node* nodes, int nodeNum, int lengthMax, int K_MAX){
    // the first nodeNum nodes must be skipped because its assumed that those nodes already exist in the tree
    bool end = false;
    int left = 0, right = nodeNum;
    int ancestor_level = tree.size()-1, current_index;
    std::vector<int> indices;
    // the first nodeNum nodes will need to be split
    for (int i=0; i<nodeNum; i++)
        for (int j=0; j<4; j++)
            indices.push_back(i);
    
    while (!end && right+nodeNum*4<=lengthMax){

        current_index = 0; // index of nodes in tree in their specific level

        end = true;
        nodeNum *= 4;
        left = right;
        right = left+nodeNum;

        std::vector<Node> tmp_node;

        for (int i=left; i<right; i++){
            if(nodes[i].isInitialized()){
                tmp_node.push_back(nodes[i]);
                if ((i-left)%4 == 0){
                    // std::cout << "i: " << i << " - ancestor_level: " << ancestor_level << " -> ";
                    // std::cerr << "indices[i]: " << indices[i] << "\n";
                    Node& ancestor = tree[ancestor_level][indices[i]];
                    int childNodesIdx[4] = {current_index, current_index+1, current_index+2, current_index+3};
                    // for (int k=0; k<4; k++)
                    //     std::cerr << childNodesIdx[k] << " ";
                    // std::cerr << "\n";
                    ancestor.setChildren(childNodesIdx);
                }
                if (nodes[i].mustSplit(K_MAX)){
                    end = false;
                    for (int j=0; j<4; j++)
                        indices.push_back(current_index);
                }else{
                    for (int j=0; j<4; j++)
                        indices.push_back(-1);
                }
                current_index++;
            }else{
                for (int j=0; j<4; j++)
                    indices.push_back(-1);
            }
        }

        tree.push_back(tmp_node);
        ancestor_level++;
    }
}

__global__
void kernel(Point* dpoints, Node* dnodes, int pointNum, int nodeNum, int lengthMax, int K_MAX){
    /*
    pointNum: length of dpoints
    nodeNum: length of dnodes
    lengthMax: maximum number of nodes to be stored
    */
    // assuming that data is stored without padding!!!
    extern __shared__ Node shared[];
    Node* nShared = shared; // [0, lengthMax) dedicated to Nodes/ [0, nodeNum) is already filled
    Point* pShared = (Point*)&nShared[lengthMax]; // [lengthMax, lengthMax + pointNum) dedicated to points
    
    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    int stride = gridDim.x * blockDim.x;

    if (tid < nodeNum) // at first there are nodeNum nodes in nodes
        for (int i=tid; i<nodeNum; i+=stride)
            nShared[i] = dnodes[i];
    
    if (tid < pointNum) // number of points is always pointNum
        for (int i=tid; i<pointNum; i+=stride)
            pShared[i] = dpoints[i];
    __syncthreads();

    // ----------------------
    // Point* pShared = dpoints;
    // Node* nShared = dnodes;
    // ----------------------
            
    if (tid < lengthMax){
        int start = 0, end = nodeNum;
        while(end + nodeNum*4 <= lengthMax){
            for (int i=start+tid; i<end; i+=stride){
                Node node = nShared[i];
                if (node.mustSplit(K_MAX)){
                    int counts[4] = {0, 0, 0, 0};
                    assignNumPoints(pShared, node, counts, pointNum);

                    int idx_s, idx_e; node.getIdx(idx_s, idx_e);
                    // std::string path; node.getPath(path);
                    int x_s, y_s; node.getBottomLeftPoint(x_s, y_s);
                    int x_e, y_e; node.getTopRightPoint(x_e, y_e);
                    int x_m = (x_s+x_e)/2, y_m = (y_s+y_e)/2;
                    // sort
                    thrust::sort(thrust::seq, pShared+idx_s, pShared+idx_e+1, [](Point& p1, Point& p2){
                        return p1.num < p2.num;
                    });

                    Node node0; node0.initialize(x_s, y_s, x_m, y_m, idx_s, idx_s+counts[0]-1);
                    Node node1; node1.initialize(x_m, y_s, x_e, y_m, idx_s+counts[0], idx_s+counts[0]+counts[1]-1);
                    Node node2; node2.initialize(x_s, y_m, x_m, y_e, idx_s+counts[0]+counts[1], idx_s+counts[0]+counts[1]+counts[2]-1);
                    Node node3; node3.initialize(x_m, y_m, x_e, y_e, idx_s+counts[0]+counts[1]+counts[2], idx_s+counts[0]+counts[1]+counts[2]+counts[3]-1);

                    Node childNodesArr[] = {node0, node1, node2, node3};

                    int baseIdx = (i-start)*4 + end;
                    for (int j=0; j<4; j++)
                        nShared[baseIdx+j] = childNodesArr[j];
                    
                    // can be ignored in kernel because arr2tree handles this indices
                    int childNodesIdx[4] = {baseIdx, baseIdx+1, baseIdx+2, baseIdx+3};
                    node.setChildren(childNodesIdx);
                }
            }
            __syncthreads();
            nodeNum *= 4;
            start = end;
            end = start + nodeNum;
        }        
    }
    if (tid < lengthMax)
        for (int i=tid+nodeNum; i<lengthMax; i+=stride)
            dnodes[i] = nShared[i];
    
    if (tid < pointNum)
        for (int i=tid; i<pointNum; i+=stride)
            dpoints[i] = pShared[i];

}

bool mustSplitTree(std::vector<std::vector<Node>>& tree, int K_MAX){
    int h = tree.size(), w = tree[tree.size()-1].size();
    bool end = false;
    end = std::accumulate(tree[h-1].begin(), tree[h-1].end(), 0, [=](int sum, Node& node){
        return sum + node.mustSplit(K_MAX);
    });
    return 1 - end;
}

void constuctTree(std::vector<std::vector<Node>>& tree, Point* points, int K_MAX, int N){
    bool end = K_MAX >= N;
    /* 
    I decided to always add the first node to the tree on the CPU even if I'm going to
    fully utilize the GPU.
    */
    // collect metadata
    int x1 = std::numeric_limits<int>::max(), y1 = std::numeric_limits<int>::max(), \
    x2 = -1*std::numeric_limits<int>::max(), y2 = -1*std::numeric_limits<int>::max();
    std::for_each(points, points+N, [&](Point point){
        x1 = std::min(x1, point.x); y1 = std::min(y1, point.y); // bottom left
        x2 = std::max(x2, point.x); y2 = std::max(y2, point.y); // upper right
        // std::cerr << "x1: " << x1 << ", y1: " << y1 << ", x2: " << x2 << ", y2: " << y2 << "\n";
    });
        
    // insert the first level of the tree
    Node node; 
    node.initialize(x1, y1, x2, y2, 0, N-1);
    tree.push_back({node});

    // switch to the GPU
    int lengthMax = 100;
    Point* dpoints = new Point;
    cudaMalloc(&dpoints , N*sizeof(Point));
    cudaMemcpy(dpoints , points, N*sizeof(Point), cudaMemcpyHostToDevice);

    while(!end){
        // it's inside the while loop to make sure that obsolete nodes don't exist
        Node* dnodes = new Node;
        cudaMalloc(&dnodes, lengthMax*sizeof(Node)); // 100 is set arbitrarily!
        Node nodes[lengthMax]; // this size must be optimized!
        int nodeNum;
        copyTree2Arr(tree, nodes, nodeNum, K_MAX);
        assert(N+nodeNum <= lengthMax);

        for (int k=0; k<10; k++)
            std::cerr << nodes[k].isInitialized() << " ";
        std::cerr << "\n";
        std::cerr << "nodeNum: " << nodeNum << "\n";
        
        cudaMemcpy(dnodes , nodes, nodeNum*sizeof(Node), cudaMemcpyHostToDevice); // the first nodeNum nodes need to be copied
        
        // call the kernel
        int total_bytes = lengthMax*sizeof(Node) + N*sizeof(Point);
        // std::cerr << "size of Node: " << sizeof(Node) << ", lengthMax: " << lengthMax << " -> " << lengthMax*sizeof(Node) << "\n";
        // std::cerr << "size of Point: " << sizeof(Point) << ", N: " << N << " -> " << N*sizeof(Point) << "\n";
        // std::cerr << "Total bytes: " << total_bytes << "\n";
        dim3 gridDim(2, 1, 1);
        dim3 blockDim(3, 1, 1);
        kernel<<<gridDim, blockDim, total_bytes>>>(dpoints, dnodes, N, nodeNum, lengthMax, K_MAX);
        // cudaDeviceSynchronize();

        cudaMemcpy(nodes , dnodes, lengthMax*sizeof(Node), cudaMemcpyDeviceToHost);
        cudaFree(dnodes);
        appendArr2Tree(tree, nodes, nodeNum, lengthMax, K_MAX);
        end = mustSplitTree(tree, K_MAX);
        std::cerr << "tree info: " << tree.size() << " " << tree[tree.size()-1].size() << "\n";
    }
    cudaMemcpy(points , dpoints, N*sizeof(Point), cudaMemcpyDeviceToHost);
    cudaFree(dpoints);

}


#endif