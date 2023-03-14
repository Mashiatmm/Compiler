#include<iostream>
#include<cstring>
#include<vector>
#include<fstream>

using namespace std;

class SymbolInfo
{

private:
    string name;
    string type;
    SymbolInfo* next;

public:
    SymbolInfo(string name, string type)
    {
        this->type = type;
        this->name = name;
        next = nullptr;
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

    SymbolInfo* getNext()
    {
        return next;
    }

    ~SymbolInfo(){
        delete next;
    }

};


class ScopeTable
{

private:
    SymbolInfo** scope;
    int buckets;
    ScopeTable* parentScope;
    string id;
    int children;

public:
    ScopeTable(int n)
    {
        buckets = n;
        scope = new SymbolInfo*[n];
        parentScope = nullptr;
        children = 0;

        for(int i = 0 ; i<n ; i++)
        {
            scope[i] = nullptr;
        }
    }

    void setParentScope(ScopeTable* s)
    {
        parentScope = s;
        if(s == nullptr)
        {
            setID("", 0);
        }
        else
        {
            setID(parentScope->getID(), parentScope->getChildren());
        }
    }

    void setID(string parentID, int prevSerial)
    {
        if(parentID != "")
            id = parentID + "." + to_string(prevSerial+1);
        else
            id = to_string(prevSerial+1);
        if(parentScope != nullptr)
            parentScope->incChild();
    }

    void incChild()
    {
        children++;
    }

    string getID()
    {
        return id;
    }

    int getChildren()
    {
        return children;
    }

    ScopeTable* getParentScope()
    {
        return parentScope;
    }

    int hash(string name)
    {
        int sum_ascii = 0;
        for(int i = 0; i < name.length(); i++)
        {
            sum_ascii += name[i];
        }
        return sum_ascii%buckets;
    }

    bool Insert(string name, string type)
    {
        int i = 0;
        SymbolInfo* temp = new SymbolInfo(name, type);
        int idx = hash(name);
        if(scope[idx] == nullptr)
        {
            scope[idx] = temp;
        }
        else
        {
            SymbolInfo* current = scope[idx];
            SymbolInfo* prev = nullptr;

            while(current != nullptr)
            {
                i++;
                if(current->getName() == name)
                {
                    return false;
                }
                prev = current;
                current = current->getNext();
            }

            prev->setNext(temp);

        }
        //output<<"Inserted in ScopeTable# "<< id<<" at position "<< idx<<", "<<i<<"\n";
        //cout<<"Inserted in ScopeTable# "<< id<<" at position "<< idx<<", "<<i<<endl;
        return true;

    }

    SymbolInfo* LookUp(string name)
    {
        int i = 0;
        int idx = hash(name);
        SymbolInfo* current = scope[idx];

        if(current != nullptr)
        {
            while(current->getName() != name)
            {
                current = current->getNext();
                i++;
                if(current == nullptr)
                {
                    break;
                }
            }
        }
        if(current != nullptr){
            //output<<"Found in ScopeTable# "<<id<<" at position "<<idx<<", "<<i<<"\n";
            //cout<<"Found in ScopeTable# "<<id<<" at position "<<idx<<", "<<i<<endl;
        }
        return current;
    }

    bool Delete(string name)
    {
        int i = 0;
        int idx = hash(name);
        SymbolInfo* current = scope[idx];
        SymbolInfo* prev = nullptr;
        if(current == nullptr) return false;

        while(current->getName() != name)
        {
            i++;
            prev = current;
            current = current->getNext();
            if(current == nullptr){
                return false;
            }
        }

        if(prev != nullptr)
            prev->setNext(current->getNext());
        else
            scope[idx] = current->getNext();

        current->setNext(nullptr);
        delete current;
        //output<<"Deleted Entry "<<idx<<", "<<i<<" from current ScopeTable\n";
        //cout<<"Deleted Entry "<<idx<<", "<<i<<" from current ScopeTable"<<endl;
        return true;
    }

    void Print(ofstream &output)
    {
        output<<"ScopeTable # "<<id<<"\n";
        //cout<<"ScopeTable # "<<id<<endl;
        for(int i = 0; i < buckets ; i++)
        {
            if(scope[i] == nullptr) continue;
            output<<i<<" --> ";
            //cout<<i<<" --> ";
            SymbolInfo* temp = scope[i];
            while(temp != nullptr)
            {
                output<<" < "<<temp->getName()<<" : "<<temp->getType()<<">";
                temp = temp->getNext();
            }
            //cout<<endl;
            output<<"\n";

        }
        output<<"\n";
        //cout<<endl;
    }

    ~ScopeTable()
    {
        for(int i = 0; i < buckets; i++)
        {
            delete scope[i];
        }
        delete scope;
    }
};


class SymbolTable
{

private:
    ScopeTable* currentScope;
    int n;

public:

    SymbolTable(int n)
    {
        this->n = n;
        currentScope =  new ScopeTable(n);
        currentScope->setParentScope(nullptr);
    }

    void EnterScope()
    {
        ScopeTable* s = new ScopeTable(n);
        if(currentScope != nullptr)
        {
            s->setParentScope(currentScope);
        }
        currentScope = s;
        //output<<"New ScopeTable with id "<<s->getID()<<" created\n";
        //cout<<"New ScopeTable with id "<<s->getID()<<" created"<<endl;
    }

    void ExitScope()
    {
        if(currentScope == nullptr) return;
        string id = currentScope->getID();
        ScopeTable* temp = currentScope;
        currentScope = currentScope->getParentScope();
        delete temp;
        //output<<"ScopeTable with id "<<id<<" removed\n";
        //cout<<"ScopeTable with id "<<id<<" removed"<<endl;
    }

    bool Insert(string name, string type)
    {
        if(currentScope == nullptr) return false;
        bool check = currentScope->Insert(name, type);
        if(check == false){
            //output<<" "<<name<<" already exists in current ScopeTable\n";
            //cout<<"<"<<name<<","<<type<<"> already exists in current ScopeTable"<<endl;
        }
        return check;
    }

    bool Remove(string name)
    {
        if(currentScope == nullptr) return false;
        bool deleted = currentScope->Delete(name);
        if(!deleted){
            //output<<name<<" not found\n";
            //cout<<name<<" not found"<<endl;
        }
        return deleted;
    }

    SymbolInfo* LookUp(string name)
    {
        ScopeTable* current = currentScope;
        if(current == nullptr) return nullptr;

        SymbolInfo* temp = current->LookUp(name);
        while(temp == nullptr)
        {
            current = current->getParentScope();
            if(current == nullptr){
                break;
            }
            temp = current->LookUp(name);
        }
        if(temp == nullptr){
            //output<<"Not found\n";
            //cout<<"Not found"<<endl;
        }
        return temp;
    }

    void PrintCurrentScope(ofstream &output)
    {
        if(currentScope == nullptr) return;
        currentScope->Print(output);
    }

    void PrintAllScopes(ofstream &output)
    {
        ScopeTable* temp = currentScope;
        while(temp != nullptr)
        {
            temp->Print(output);
            temp = temp->getParentScope();
        }
    }

    ~SymbolTable()
    {
        ScopeTable* temp = currentScope;

        while(temp != nullptr)
        {
            temp = temp->getParentScope();
            delete currentScope;
            currentScope = temp;
        }
    }

};


