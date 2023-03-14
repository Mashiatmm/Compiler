#include<iostream>
#include<cstring>
#include<vector>

using namespace std;

class FunctionParameter{

public:
    string returnType;
    int num_params;
    vector<string>* param_types;
    bool defined;

    FunctionParameter(string returnType, int num_params){
        this->returnType = returnType;
        this->num_params = num_params;
        this->param_types = new vector<string>();
        defined = false;
    }

};

class SymbolInfo
{

private:
    string name;
    string type;
    string DataType;
    int array;
    SymbolInfo* next;
    FunctionParameter* fp;

public:
    string code;
    string Symbol;

    SymbolInfo(string name, string type, string DataType)
    {
        this->type = type;
        this->name = name;
        this->DataType = DataType;
        next = nullptr;
        fp = nullptr;
        array = 0;
        code = "";
        Symbol = "";
    }

    void setDataType(string DataType){
        this->DataType += DataType;
    }

    void setArray(int value){
        array = value;
    }

    void setNext(SymbolInfo* s)
    {
        next = s;
    }

    string getName()
    {
        return name;
    }

    string getType()
    {
        return type;
    }

    string getDataType()
    {
        return DataType;
    }

    int getArray(){
        return array;
    }

    SymbolInfo* getNext()
    {
        return next;
    }

    void setFunctionParams(string returnType, int num_params){
        if(type.compare("ID") != 0 ) return;
        fp = new FunctionParameter(returnType, num_params);
    }

    FunctionParameter* getFunctionParams(){
        return fp;
    }

    ~SymbolInfo(){
        delete next;
    }

};
