#include <iostream>
#include <unordered_map>

using namespace std;

void bftosf(string &bfcode){
    unordered_map<char , string> db{{'>',"е"},{'<',"ɘ"},{'+',"é"},{'-',"è"},{'.',"ē"},{',',"ę"},{'[',"ё"},{']',"ė"}};
    string sfcode = "";
    for(char c : bfcode){
        sfcode+=db[c];
    }
    cout << sfcode;
}

int main(){
    string bfcode;
    cin >> bfcode;
    bftosf(bfcode);
    return 0;
}