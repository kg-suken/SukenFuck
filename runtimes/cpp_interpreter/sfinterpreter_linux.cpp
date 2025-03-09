#include <iostream>
#include <vector>
#include <stack>
#include <unordered_map>
#include <termios.h>
#include <unistd.h>
using namespace std;

string sftobf(string& s){
    string bfcode = "";
    size_t index = 0;
    unordered_map<string , char> db{{"е",'>'},{"ɘ",'<'},{"é",'+'},{"è",'-'},{"ē",'.'},{"ę",','},{"ё",'['},{"ė",']'}};
    while(index < s.size()){
        if(db.find(s.substr(index , 2))!=db.end()){
            bfcode+=db[s.substr(index , 2)];
            index+=2;
        }else{
            index++;
        }
    }
    return bfcode;
}

int getch(void)
{
    struct termios oldattr, newattr;
    int ch;
    tcgetattr( STDIN_FILENO, &oldattr );
    newattr = oldattr;
    newattr.c_lflag &= ~( ICANON | ECHO );
    tcsetattr( STDIN_FILENO, TCSANOW, &newattr );
    ch = getchar();
    tcsetattr( STDIN_FILENO, TCSANOW, &oldattr );
    return ch;
}

void mapping(string S , auto& M){
    stack<int> tmp;
    for(int i = 0; i < S.length(); i++){
        if(S[i] == '['){
            tmp.push(i);
        }else if(S[i] == ']'){
            M[i] = tmp.top();
            M[tmp.top()] = i;
            tmp.pop();
        }
    }
}

void interpret(string &code , auto& M){
    vector<int> memory(30000 , 0);
    int memptr = 0 , codeptr = 0;
    char com;
    while(codeptr < code.length()){
        com = code[codeptr];
        if(com == '>'){
            if(memptr > 29998){
                break;
            }
            memptr++;
        }else if(com == '<'){
            if(memptr < 1){
                break;
            }
            memptr--;
        }else if(com == '+'){
            memory[memptr]++;
            memory[memptr] = (memory[memptr] + 256) % 256;
        }else if(com == '-'){
            memory[memptr]--;
            memory[memptr] = (memory[memptr] + 256) % 256;
        }else if(com == '.'){
            cout << (char)memory[memptr];
        }else if(com == ','){
            char c = getch();
            memory[memptr] = (int)c;
        }else if(com == '['){
            if(!memory[memptr]){
                codeptr = M[codeptr];
            }
        }else if(com == ']'){
            if(memory[memptr]){
                codeptr = M[codeptr];
            }
        }
        codeptr++;
    }
}

int main(){
    string program;
    cin >> program;
    unordered_map<int , int> map;
    string programtobf = sftobf(program);
    mapping(programtobf , map);
    interpret(programtobf , map);
    return 0;
}
