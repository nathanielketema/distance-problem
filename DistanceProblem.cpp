#include <cmath>
#include <iostream>
#include <fstream>
#include <unordered_set>
#include <utility>
using namespace std; 

const long DISTANCE = 1234;

struct customHash {
    long operator () (const pair<long, long>& p) const {
        auto h1 = hash<long>{}(p.first);
        auto h2 = hash<long>{}(p.second);

        return h1 ^ (h2 + 0x9e3779b9 + (h1 << 6) + (h1 >> 2));
    }
};


int main(int argc, char *argv[])
{
    if (argc != 2) {
        cout << "Input file not provided!" << endl;
        return 1;
    }

    ifstream inputFile;
    inputFile.open(argv[1]);
    
    long n; 
    long x, y;
    unordered_set<pair<long, long>, customHash> points;

    inputFile >> n;
    for (long i = 0; i < n; i++) {
        inputFile >> x >> y;
        points.emplace(x, y);
    }

    unordered_set<pair<long, long>, customHash> deltaSet;
    long long distanceSquare, dy_Square; 
    long dy;

    distanceSquare = DISTANCE * DISTANCE;
    for (long dx = 0; dx <= DISTANCE; dx++) {
        dy_Square = distanceSquare - (dx * dx);
        dy = int(sqrt(dy_Square));

        // check if it's a perfect square 
        if (dy * dy == dy_Square) {
            deltaSet.insert({dx, dy});
            if (dy != 0) {
                deltaSet.insert({dx, -dy});
            }
            if (dx != 0) {
                deltaSet.insert({-dx, dy});
                if (dy != 0) {
                    deltaSet.insert({-dx, -dy});
                }
            }
        }
    }

    long count = 0;
    pair<long, long> point2;
    for (const auto& point1: points) {
        for (const auto& delta : deltaSet) {
            // p2 = (x + dx), (y + dy)
            point2 = {point1.first + delta.first, point1.second + delta.second};
            if (points.count(point2)) {
                count++;
            }
        }
    }

    cout << count / 2 << endl;

    return 0;
}
