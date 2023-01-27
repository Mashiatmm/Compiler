%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<fstream>
#include <algorithm>
#include<sstream>
#include <map>
#include "SymbolTable.cpp"


using namespace std;

int yyparse(void);
int yylex(void);

extern FILE *yyin;
extern int lines;
extern int initialLine;
extern int errors;
SymbolTable *s = new SymbolTable(30);
ofstream logout;
ofstream errorout;
ofstream assembly;
ofstream optimized;
string space = " ";
char newline = '\n';

string returnType;
SymbolInfo* funcID;
vector<SymbolInfo*>* Parameters;
bool function = false;


int labelCount=0;
int tempCount=0;
bool print = false;
string param_decl = "";
string func_id = "";
map<string, string> func_params;


char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}


void OptimizedCode(){
	optimized.open("optimized_code.asm");
	ifstream myfile;
	myfile.open ("code.asm");
	string prevline = "";
	string copyline, copyprevline;
	string line;
	while (getline(myfile, line))
	{
		copyline = line;
		copyprevline = prevline;

		replace(copyline.begin(), copyline.end(), ',', ' ');
		replace(copyprevline.begin(), copyprevline.end(), ',', ' ');   

		vector<string> vecLine;
		vector<string> vecPrevLine;

		stringstream ss(copyline); 
		for (string i; ss >> i;){ 
			vecLine.push_back(i);
		}

		stringstream ssp(copyprevline); 
		for (string i; ssp >> i;){
			vecPrevLine.push_back(i);
		}

		if(vecLine.size() > 0 && vecPrevLine.size() >0){
			if((vecLine[0].compare("MOV") == 0) && (vecPrevLine[0].compare("MOV") == 0)){
				if((vecLine[1].compare(vecPrevLine[2]) == 0) && (vecLine[2].compare(vecPrevLine[1]) == 0)){
					line = "";
				}	
			}
		}
		
		
		prevline = line;
		optimized<<prevline<<endl;
	}
}

void printlnFunction(){
	
	assembly<< "; PRINT FUNCTION \n\
	PRINT PROC \n\
	POP BX\n\
	POP AX\n\
	PUSH BX\n\
	; CHECK IF NUMBER IS NEGATIVE\n\
    TEST AX, AX\n\
    JNS PROCEED  ; SIGN IS NOT NEGATIVE\n\
	; 2'S COMPLEMENT\n\
    MOV BX, 0FFFFH\n\
    SUB BX, AX\n\
    ADD BX, 1\n\
    PUSH BX\n\
    MOV DL, '-'\n\
    MOV AH, 2\n\
    INT 21H \n\
	POP AX\n\  
    PROCEED:\n\           
    ; PUSH EACH DIGIT TO STACK   \n\
    MOV CX, 0\n\
    MOV DX, 0  \n\
    START: \n\  
    ; CHECK IF TEMP IS ZERO\n\
    CMP AX, 0H\n\
    JE CHECK_ZERO \n\
    ; DIVIDE BY 10 AND PUSH THE REMAINDER IN STACK  \n\
    MOV BX, 10 \n\
    DIV BX\n\
    PUSH DX\n\
    XOR DX, DX\n\
    INC CX \n\ 
    JMP START \n\
    ; CHECK IF INPUT WAS ZERO\n\
    CHECK_ZERO: \n\
    CMP CX, 0H\n\
    JNE PRINT_LOOP\n\
    MOV DL, '0'\n\
    MOV AH, 2\n\
    INT 21H\n\
    JMP END_PRINT\n\
    ; POP FROM STACK AND PRINT\n\
    PRINT_LOOP:\n\
    POP DX\n\
    ADD DX, 30H\n\
    MOV AH, 2\n\
    INT 21H  \n\
    LOOP PRINT_LOOP \n\ 
    END_PRINT: \n\
	CALL NEWLINE\n\
    RET \n\
	PRINT ENDP\n\n\
	; NEW LINE FUNCTION\n\
	NEWLINE PROC \n\
    ; PRINTING NEW LINE \n\
    MOV DL, LF   \n\   
    MOV AH, 2\n\
    INT 21h\n\
    MOV DL, CR\n\
    MOV AH, 2\n\
    INT 21h\n\
    RET\n\
	NEWLINE ENDP  \n"<<endl;
}

void yyerror(string errorline)
{
	//write your code
	errors++;
	logout<<"Error at line "<<lines<<": "<<errorline<<endl<<endl;
	errorout<<"Error at line "<<lines<<": "<<errorline<<endl<<endl;
}

void funcInfunc()
{
	errors++;
	logout<<"Error at line "<<lines<<": A function is defined inside a function"<<endl<<endl;
	errorout<<"Error at line "<<lines<<": A function is defined inside a function"<<endl<<endl;
}

void FuncDefinitionNoParameterName(int i, string funcName){
	errors++;
	logout<<"Error at line "<<initialLine<<": "<<i<<"th parameter's name not given in function definition of "<<funcName<<endl<<endl;
	errorout<<"Error at line "<<initialLine<<": "<<i<<"th parameter's name not given in function definition of "<<funcName<<endl<<endl;
}

bool checkVoidTypeError(string type){
	if(type.compare("void") == 0){
		errors++;
		logout<<"Error at line "<<lines<<": Variable type cannot be void "<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Variable type cannot be void "<<endl<<endl;
		return true;
	}
	return false;
}

void unknown_var_error(string s){
	logout<<"Error at line "<<lines<<": Undeclared variable "<<s<<endl<<endl;
	errorout<<"Error at line "<<lines<<": Undeclared variable "<<s<<endl<<endl;
	errors++;
}

void checkMultipleDeclaration(string name, int linecount, string extra){
	//Multiple Declaration check only in currentScope
	SymbolInfo* exists = s->CurrentScopeLookUp(name);
	if(exists != nullptr){
		errors++;
		logout<<"Error at line "<<linecount<<": Multiple declaration of "<<name<<" "<<extra<<endl<<endl;
		errorout<<"Error at line "<<linecount<<": Multiple declaration of "<<name<<" "<<extra<<endl<<endl;
	}
}

void functionError(string name){
	logout<<"Error at line "<<lines<<": Invalid Function Call: "<<name<<endl<<endl;
	errorout<<"Error at line "<<lines<<": Invalid Function Call: "<<name<<endl<<endl;
	errors++;
}

bool assignment_type_check(string left, string right){
	if(left.compare(right) == 0) return true;
	if(left.compare("float") == 0 && right.compare("int") == 0){
		//logout<<"Line "<<lines<<": Type Conversion : Float to int"<<endl<<endl;
		return true;
	}
	if(right.compare("void") == 0){
		errors++;
		logout<<"Error at line "<<lines<<": Void function used in expression"<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Void function used in expression"<<endl<<endl;
		return false;
	}
	logout<<"Error at line "<<lines<<": Type Mismatch"<<endl<<endl;
	errorout<<"Error at line "<<lines<<": Type Mismatch"<<endl<<endl;
	errors++;
	return false;
}

void array_mismatch(string var, bool val){
	if(val == true){
		logout<<"Error at line "<<lines<<": Type mismatch, "<<var<<" is an array"<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Type mismatch, "<<var<<" is an array"<<endl<<endl;
	}
	else{
		logout<<"Error at line "<<lines<<": "<<var<<" not an array"<<endl<<endl;
		errorout<<"Error at line "<<lines<<": "<<var<<" not an array"<<endl<<endl;
	}
	errors++;
}

string type_convert(string left , string right){
	if(left.compare(right) == 0) return left;
	if(left.compare("float") == 0 | right.compare("float") == 0) return "float";
	return "int";
}

void checkIndexError(string type){
	if(type != "int"){
		errors++;
		logout<<"Error at line "<<lines<<": Expression inside third brackets not an integer"<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Expression inside third brackets not an integer"<<endl<<endl;
	}
}

void checkModulusError(string left, string right){
	if(left.compare("int") != 0 | right.compare("int") != 0){
		errors++;
		logout<<"Error at line "<<lines<<": Non-Integer operand on modulus operator"<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Non-Integer operand on modulus operator"<<endl<<endl;
	}
}

void checkZeroError(string num){
	if(num.compare("0") == 0){
		errors++;
		logout<<"Error at line "<<lines<<": Modulus by Zero"<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Modulus by Zero"<<endl<<endl;
	}
}

bool voidFuncExpression(string num1, string num2){
	if(num1.compare("void") == 0 | num2.compare("void") == 0){
		errors++;
		logout<<"Error at line "<<lines<<": Void function used in expression"<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Void function used in expression"<<endl<<endl;
		return true;
	}
	return false;
}

bool checkFuncParameters(SymbolInfo* func, vector<SymbolInfo*>* paramList){
	if(func == nullptr){
		functionError(func->getName());
		return true;
	}
	FunctionParameter* fp = func->getFunctionParams();
	if(fp == nullptr){
		functionError(func->getName());
		return true;
	}
	if(fp->num_params != paramList->size()-1){
		errors++;
		logout<<"Error at line "<<lines<<": Total number of arguments mismatch in function "<<func->getName()<<endl<<endl;
		errorout<<"Error at line "<<lines<<": Total number of arguments mismatch in function "<<func->getName()<<endl<<endl;
		return true;
	}
	for(int i = 1 ; i<paramList->size() ; i++){
		if(paramList->at(i)->getDataType().compare(fp->param_types->at(i-1)) != 0){
			//PASS INT VALUE TO FLOAT OKAY...
			if(paramList->at(i)->getDataType().compare("int") == 0 && fp->param_types->at(i-1).compare("float") == 0){
				continue;
			}
			errors++;
			logout<<"Error at line "<<lines<<": "<<i<<"th argument mismatch in function "<<func->getName()<<endl<<endl;
			errorout<<"Error at line "<<lines<<": "<<i<<"th argument mismatch in function "<<func->getName()<<endl<<endl;
			return true;
		}
	}

	return false;
}

bool checkFunctionParameters(SymbolInfo *func,  string returnType, vector<SymbolInfo*>* paramList){
	FunctionParameter* fp = func->getFunctionParams();
	if(fp == nullptr) return false;
	if(fp->returnType.compare(returnType) != 0){
		logout<<"Error at line "<<lines-1<<": Return type mismatch with function declaration in function "<<func->getName()<<endl<<endl;
		errorout<<"Error at line "<<lines-1<<": Return type mismatch with function declaration in function "<<func->getName()<<endl<<endl;
		errors++;
		return false;
	} 
	if(paramList->size() == 0){
		if(fp->num_params == 0) return true;
		else{
			logout<<"Error at line "<<lines-1<<": Total number of arguments mismatch with declaration in function "<<func->getName()<<endl<<endl;
			errorout<<"Error at line "<<lines-1<<": Total number of arguments mismatch with declaration in function "<<func->getName()<<endl<<endl;
			errors++;
			return false;
		}
	}
	if(fp->num_params != paramList->size()-1){
		logout<<"Error at line "<<lines-1<<": Total number of arguments mismatch with declaration in function "<<func->getName()<<endl<<endl;
		errorout<<"Error at line "<<lines-1<<": Total number of arguments mismatch with declaration in function "<<func->getName()<<endl<<endl;
		errors++;
		return false;
	}
	for(int i = 1 ; i<paramList->size() ; i++){
		if(paramList->at(i)->getType().compare(fp->param_types->at(i-1)) != 0){
			logout<<"Error at line "<<lines-1<<": "<<i<<"th argument mismatch in function "<<func->getName()<<endl<<endl;
			errorout<<"Error at line "<<lines-1<<": "<<i<<"th argument mismatch in function "<<func->getName()<<endl<<endl;
			errors++;
			return false;
		} 
	}
	return true;
}

void defineFunctionParams(string returnType, SymbolInfo* funcID, vector<SymbolInfo*>* ParamList, bool definition)
{	
	bool check = s->Insert(funcID->getName(), funcID->getType(), returnType);
	SymbolInfo* func = s->LookUp(funcID->getName());
	if(check == true){
		//insertion successful, set function parameters
		func->setFunctionParams(returnType, ParamList->size()-1);
		FunctionParameter* fp = func->getFunctionParams();
	
		if(definition == true){
			fp->defined = true;		
		}
		for(int i = 1; i<ParamList->size() ; i++){
			// check if insertion was succesful then set function parameter types
			fp->param_types->push_back(ParamList->at(i)->getType());	
		} 
	}
	else{
		//check for errors
		if(definition == true){
			FunctionParameter* fp = func->getFunctionParams();
			//check if function ID is of different type
			if(fp == nullptr){
				checkMultipleDeclaration(funcID->getName(), lines-1,"" );
			}
			else if(fp->defined == true){
				checkMultipleDeclaration(funcID->getName(), lines-1,"" );
			}
			else{
				fp->defined = true;
				bool validity = checkFunctionParameters(func, returnType, ParamList);
			}
		}
		else{
			//function already declared once in a declaration
			checkMultipleDeclaration(funcID->getName(), lines,"" );
		}
				
	}

	if(definition == true){
		s->EnterScope(logout);
		func_id = s->currentScopeID();
		int offset = 4;
		for(int i = 1; i<ParamList->size() ; i++){
			//check if no parameter is passed in the function
			if(ParamList->at(i)->getName().compare("") != 0){
				bool success = s->Insert(ParamList->at(i)->getName(), "ID" , ParamList->at(i)->getType());
				if(success == false) checkMultipleDeclaration(ParamList->at(i)->getName(), lines-1, "in parameter");

				//param_decl += ParamList->at(i)->getName() + "_" + func_id + " DW ?\n";
				func_params.insert(pair<string, string>(ParamList->at(i)->getName() + "_" + func_id, "[BP + " + to_string(offset) + "]"));
				offset += 2;
			}
			else{
				FuncDefinitionNoParameterName(i, funcID->getName());
			}	
		} 
	}

	funcID = nullptr;
	returnType = "";
	Parameters = nullptr;
}	


%}

%union{
	SymbolInfo* si;
	char* str;
	vector<SymbolInfo*>* v;
}

%token <str> IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN 
%token <si> MAIN INCOP DECOP ADDOP MULOP RELOP ASSIGNOP LOGICOP NOT CONST_FLOAT CONST_INT ID CONST_CHAR LPAREN RPAREN LTHIRD RTHIRD COMMA SEMICOLON LCURL RCURL 
%type <str> type_specifier
%type <si> start program unit func_declaration func_definition compound_statement var_declaration statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor
%type <v> parameter_list declaration_list argument_list arguments

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		//write your code in this block in all the similar blocks below
		logout<<"Line "<<lines<<": start : program"<<endl<<endl;
		s->PrintAllScopes(logout);
		logout<<"Total lines: "<<lines<<endl<<endl;
		logout<<"Total errors: "<<errors<<endl<<endl;

		if(errors == 0){
			assembly<<".MODEL SMALL\n.STACK 100H"<<endl;
			assembly<<".DATA\n"<<endl;
			assembly<<"CR EQU 0DH\nLF EQU 0AH"<<endl;
			assembly<<param_decl<<endl;
			assembly<<".CODE\n"<<endl;
			assembly<<$1->code<<endl;
			if(print == true) printlnFunction();
			assembly<<"END MAIN"<<endl<<endl;
			OptimizedCode();
		}
		
	}
	;

program : program unit 
	{
		logout<<"Line  "<<lines<<":  program : program unit"<<endl<<endl;
		string name = $1->getName() + '\n' + $2->getName();
		$$ = new SymbolInfo(name, "program",  "");
		logout<<$$->getName()<<endl<<endl;

		$$->code = $1->code + $2->code;

		delete $1,$2;
	}
	| unit
	{
		logout<<"Line  "<<lines<<":  program : unit"<<endl<<endl;
		string name = $1->getName();
		$$ = new SymbolInfo(name, "program",  "");
		logout<<$$->getName()<<endl<<endl;

		$$->code = $1->code;

		delete $1;
	}
	;
	
unit : var_declaration	
	{
		logout<<"Line  "<<lines<<":  unit : var_declaration "<<endl<<endl;
		
		$$ = new SymbolInfo($1->getName(), "unit",  "");
		logout<<$$->getName()<<endl<<endl;

		$$->code = $1->code;

		delete $1;
		
	}
     | func_declaration
	{
		logout<<"Line  "<<lines<<":  unit : func_declaration "<<endl<<endl;
		$$ = new SymbolInfo($1->getName(), "unit",  "");	
		logout<<$$->getName()<<endl<<endl;	

		$$->code = $1->code;

		delete $1;	
	}
     | func_definition
	{	
		logout<<"Line  "<<lines<<":  unit : func_definition "<<endl<<endl;
		$$ = new SymbolInfo($1->getName(), "unit",  "");	
		logout<<$$->getName()<<endl<<endl;	

		$$->code = $1->code;
		
		delete $1;
	}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
		{
			logout<<"Line  "<<lines<<":  func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON"<<endl<<endl;
			defineFunctionParams($1, $2, $4, false);
			
			string name = $1  + space + $2->getName() + $3->getName() + $4->at(0)->getName() + $5->getName() + $6->getName();
			$$ = new SymbolInfo(name, "func_declaration",  "");
			logout<<$$->getName()<<endl<<endl;
			delete $2, $3, $4, $5, $6;
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			logout<<"Line  "<<lines<<":  func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON"<<endl<<endl;
			
			vector<SymbolInfo*>* vs = new vector<SymbolInfo*>(1);
			defineFunctionParams($1, $2, vs, false);

			string name = $1  + space + $2->getName() + $3->getName() + $4->getName() + $5->getName();
			$$ = new SymbolInfo(name, "func_declaration",  "");
			logout<<$$->getName()<<endl<<endl;
			delete $2, $3, $4, $5;
		}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN 
		{	
			function = true;
			returnType = $1;
			funcID = $2;
			Parameters = $4;
			initialLine = lines;
			//defineFunctionParams($1, $2, $4, true);
			
		} 
		compound_statement
		{
			logout<<"Line  "<<lines<<":  func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement"<<endl<<endl;
			string name = $1  + space + $2->getName() + $3->getName() + $4->at(0)->getName() + $5->getName() + $7->getName();
			//bool returntype = assignment_type_check($1, $7->getDataType());
			$$ = new SymbolInfo(name, "func_definition",  "");
			logout<<$$->getName()<<endl<<endl;

			$$->code += $2->getName() + " PROC\n";
			//$$->code += "POP BX\n";	//return address store in BX
			//for(int i = 1; i < $4->size() ; i++){
			//	$$->code += "POP " + $4->at(i)->getName() + "_" + func_id + "\n";
			//}
			//$$->code += "PUSH BX\n"; //return address push

			$$->code += "PUSH BP\nMOV BP, SP\n";


			$$->code += $7->code;
			$$->code += "POP BP\n";
			$$->code += "RET " + to_string(($4->size()-1)*2) + "\n";
			$$->code +=  $2->getName() + " ENDP\n\n";
			func_id = "";

			delete $2, $3, $4, $5, $7;
		}
		| type_specifier ID LPAREN RPAREN
		{
			vector<SymbolInfo*>* vs = new vector<SymbolInfo*>(1);
			function = true;
			returnType = $1;
			funcID = $2;
			Parameters = vs;
			//defineFunctionParams($1, $2, vs, true);
			
		} 
		compound_statement
		{
			logout<<"Line  "<<lines<<":  func_definition : type_specifier ID LPAREN RPAREN compound_statement"<<endl<<endl;
			string name = $1  + space + $2->getName() + $3->getName() + $4->getName() + $6->getName();
			//bool returntype = assignment_type_check($1, $6->getDataType());
			$$ = new SymbolInfo(name, "func_definition",  "");
			logout<<$$->getName()<<endl<<endl;

			$$->code += $2->getName() + " PROC\n";
			if($2->getName().compare("main") == 0){
				$$->code += ";DATA SEGMENT INITIALIZATION\nMOV AX, @DATA\nMOV DS, AX\n";
				$$->code += $6->code;
				$$->code += "; DOS EXIT\nEXIT:\nMOV AH, 4CH\nINT 21H\n";
			}
			else{
				$$->code += "PUSH BP\nMOV BP, SP\n";
				$$->code += $6->code;
				$$->code += "POP BP\n";
				$$->code += "RET\n";
			}

			$$->code +=  $2->getName() + " ENDP\n";

			delete $2, $3, $4, $6;
		}
		| type_specifier ID LPAREN RPAREN error
		{
			$$ = new SymbolInfo("", "",  "");
		}
		| type_specifier ID LPAREN parameter_list RPAREN error
		{
			$$ = new SymbolInfo("", "",  "");
		}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID
		{
			logout<<"Line  "<<lines<<":  parameter_list  : parameter_list COMMA type_specifier ID"<<endl<<endl;
			bool voidtype = checkVoidTypeError($3);
			string name = "";
			if($1->size()>0)	name += $1->at(0)->getName();
			name += $2->getName() + $3  + space + $4->getName();
			logout<<name<<endl<<endl;
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo(name, "parameter_list",  ""));
			for(int i = 1; i<$1->size() ; i++){
				$$->push_back($1->at(i));
			}
			if(voidtype == false) $$->push_back(new SymbolInfo($4->getName(), $3,  ""));	
			delete $1, $2, $4;
			
		}
		| parameter_list COMMA type_specifier
		{
			logout<<"Line  "<<lines<<":  parameter_list  : parameter_list COMMA type_specifier"<<endl<<endl;
			bool voidtype = checkVoidTypeError($3);
			string name = "";
			if($1->size()>0)	name += $1->at(0)->getName();
			name += $2->getName() + $3 + space;
			logout<<name<<endl<<endl;
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo(name, "parameter_list",  ""));
			for(int i = 1; i<$1->size() ; i++){
				$$->push_back($1->at(i));
			}
			$$->push_back(new SymbolInfo("", $3,  ""));	
			delete $1, $2;
			
		}
 		| type_specifier ID
		{
			logout<<"Line  "<<lines<<":  parameter_list  : type_specifier ID"<<endl<<endl;
			bool voidtype = checkVoidTypeError($1);
			string name = $1  + space + $2->getName();
			logout<<name<<endl<<endl;
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo(name, "parameter_list",  ""));
			if(voidtype == false) $$->push_back(new SymbolInfo($2->getName(), $1, ""));
			delete $2;

		}
		| type_specifier 
		{
			logout<<"Line  "<<lines<<":  parameter_list  : type_specifier"<<endl<<endl;
			string name = $1 ;
			logout<<name<<endl<<endl;
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo(name, "parameter_list", ""));
			$$->push_back(new SymbolInfo("", $1, ""));
			
		}
		| parameter_list error 
		{
			string name = $1->at(0)->getName() ;
			logout<<name<<endl<<endl;
			$$ = $1;
		}
 		;

 		
compound_statement : LCURL 
			{
				if(function == true){
					defineFunctionParams(returnType, funcID, Parameters, true);
				}	
				else s->EnterScope(logout);
				function = false;
			}
			statements RCURL
			{
			   logout<<"Line  "<<lines<<":  compound_statement : LCURL statements RCURL"<<endl<<endl; 
			   string name = $1->getName()  + newline + $3->getName() + $4->getName();
			   $$ = new SymbolInfo(name, "compound_statement", $3->getDataType());
			   logout<<$$->getName()<<endl<<endl;
			   s->PrintAllScopes(logout);	
			   s->ExitScope(logout);

			   $$->code += $3->code;

			   delete $1, $3, $4;
			}
 		    | LCURL 
			 {
				if(function == true){
					defineFunctionParams(returnType, funcID, Parameters, true);
				}	
				else s->EnterScope(logout);
				function = false;
			 }
			 
			 RCURL
			 {
			   logout<<"Line  "<<lines<<":  compound_statement : LCURL RCURL"<<endl<<endl; 
			   string name = $1->getName() + newline + $3->getName();
			   $$ = new SymbolInfo(name, "compound_statement", "void");
			   logout<<$$->getName()<<endl<<endl;
			   s->PrintAllScopes(logout);
			   s->ExitScope(logout);
			   delete $1, $3;
			}
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON	
		{
			logout<<"Line  "<<lines<<":  var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;

			bool voidtype = checkVoidTypeError($1);

			if(voidtype == false){
				for(int i = 1; i<$2->size(); i++){
					bool success = s->Insert($2->at(i)->getName(), $2->at(i)->getType(),$1);

					if(success == true){

						param_decl += $2->at(i)->getName() + "_" + s->getScopeID($2->at(i)->getName()) + " DW";
						if($2->at(i)->getArray() != 0){
							int length = $2->at(i)->getArray();
							for(int j = 0; j<length-1; j++){
								param_decl += " ?,";
							}
							param_decl += " ?\n";
						}
						else{ param_decl += " ?\n";	}

						//set if it is an array or not
						SymbolInfo* temp = s->LookUp($2->at(i)->getName());
						temp->setArray($2->at(i)->getArray());
					}
				}
			}
			
			
			string name = $1 + space + $2->at(0)->getName() + $3->getName();
			$$ = new SymbolInfo(name, "var_declaration", "void");
			logout<<$$->getName()<<endl<<endl;
			delete $2, $3; 
		}
 		 ;
 		 
type_specifier	: INT						
		{
			logout<<"Line  "<<lines<<":  type_specifier : INT "<<endl<<endl; $$ = "int";
			logout<<$$<<endl<<endl;
		}
 		| FLOAT	
		{
			logout<<"Line  "<<lines<<":  type_specifier : FLOAT "<<endl<<endl; $$ = "float";
			logout<<$1<<endl<<endl;
		}							
 		| VOID
		{
			logout<<"Line  "<<lines<<":  type_specifier : VOID "<<endl<<endl; $$ = "void";
			logout<<$1<<endl<<endl;
		}								
 		;
 		
declaration_list : declaration_list COMMA ID				
			{
			   checkMultipleDeclaration($3->getName(), lines, "");
			   logout<<"Line  "<<lines<<":  declaration_list : declaration_list COMMA ID"<<endl<<endl; 
			   string name = $1->at(0)->getName() + $2->getName() + $3->getName();
			   $$ = new vector<SymbolInfo*>();
			   $$->push_back(new SymbolInfo(name, "declaration_list", ""));

			   for(int i = 1; i< $1->size(); i++){
				   $$->push_back($1->at(i));
			   } 
			   $$->push_back($3);
			   logout<<name<<endl<<endl;
			   delete $2;
			}

 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		   {
			   checkMultipleDeclaration($3->getName(), lines, "");
			   logout<<"Line  "<<lines<<":  declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl; 
			   string name = $1->at(0)->getName() + $2->getName() + $3->getName() + $4->getName() + $5->getName() +$6->getName();
		
			   $$ = new vector<SymbolInfo*>();
			   $$->push_back(new SymbolInfo(name, "declaration_list", ""));
			   for(int i = 1; i< $1->size(); i++){
				   $$->push_back($1->at(i));
			   } 
			   $3->setArray(stoi($5->getName()));
			   $$->push_back($3);
			   logout<<name<<endl<<endl;
			   delete $2, $4, $5, $6;
		   }

 		  | ID							
			{
				checkMultipleDeclaration($1->getName(), lines, "");
				logout<<"Line  "<<lines<<":  declaration_list : ID "<<endl<<endl; 
				$$ = new vector<SymbolInfo*>();
			   	$$->push_back(new SymbolInfo($1->getName(), "declaration_list", ""));
			   	$$->push_back($1);
			    logout<<$1->getName()<<endl<<endl;
			}

 		  | ID LTHIRD CONST_INT RTHIRD
		   	{
				checkMultipleDeclaration($1->getName(), lines, "");
				logout<<"Line  "<<lines<<":  declaration_list :ID LTHIRD CONST_INT RTHIRD"<<endl<<endl;
				string name = $1->getName() + $2->getName() + $3->getName() + $4->getName();
			   	$$ = new vector<SymbolInfo*>();
			   	$$->push_back(new SymbolInfo(name, "declaration_list", ""));
			    $1->setArray(stoi($3->getName()));
			   	$$->push_back($1);
			    logout<<name<<endl<<endl;
				delete $2, $3, $4;
			}
		  | declaration_list error
		  {
			  	string name = $1->at(0)->getName() ;
				logout<<name<<endl<<endl;
				$$ = $1;
		  }
 		  ;
 		  
statements : statement
		{
			logout<<"Line  "<<lines<<":  statements : statement"<<endl<<endl;
			$$ = new SymbolInfo($1->getName() + '\n',"statements", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code += $1->code;

			delete $1;
		}
	   | statements statement
	   {
			logout<<"Line  "<<lines<<":  statements : statements statement"<<endl<<endl;
			string name = $1->getName()+$2->getName()+'\n';
			$$ = new SymbolInfo(name ,"statements", $2->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code += $1->code + $2->code;

			delete $1, $2;
		}
		| statements error
		{
			$$ = $1;
			logout<<$$->getName()<<endl<<endl;
		}
		| error
		{
			$$ = new SymbolInfo("","","");
		}
	   ;
	   
statement : var_declaration
		{
			logout<<"Line  "<<lines<<":  statement : var_declaration"<<endl<<endl;
			$$ = new SymbolInfo($1->getName(),"statement", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;
			delete $1;
		}
	  | expression_statement
	    {
			logout<<"Line  "<<lines<<":  statement : expression_statement"<<endl<<endl;
			$$ = new SymbolInfo($1->getName(),"statement", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1;
		}
	  | compound_statement
	    {
			logout<<"Line  "<<lines<<":  statement : compound_statement"<<endl<<endl;
			$$ = new SymbolInfo($1->getName(),"statement", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1;
		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		  	logout<<"Line  "<<lines<<":  statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement"<<endl<<endl;
		 	string name = $1  + $2->getName() + $3->getName() + $4->getName() + $5->getName() + $6->getName() + $7->getName(); 
			$$ = new SymbolInfo(name,"statement", "void");
			logout<<$$->getName()<<endl<<endl;

			string label1 = newLabel();
			string label2 = newLabel();
			$$->code = ";for loop \n";
			$$->code += $3->code;
			$$->code += label1 + ":\n" + $4->code;
			$$->code += "CMP AX, 0H\nJE " + label2 + "\n";
			$$->code += $7->code + $5->code;
			$$->code += "JMP " + label1 + "\n";
			$$->code += label2 + ":\n";



			delete $2, $3, $4, $5, $6, $7;
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
		  	logout<<"Line  "<<lines<<":  statement : IF LPAREN expression RPAREN statement"<<endl<<endl;
		 	string name = $1  + $2->getName() + $3->getName() + $4->getName() + $5->getName(); 
			$$ = new SymbolInfo(name,"statement", "void");
			logout<<$$->getName()<<endl<<endl;

			string label1 = newLabel();
			$$->code += $3->code;
			$$->code += ";" + name + "\n";
			$$->code += "CMP AX, 0H\nJE " + label1 + "\n";
			$$->code += $5->code;
			$$->code += label1 + ":\n";

			delete $2, $3, $4, $5;
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		  	logout<<"Line  "<<lines<<":  statement : IF LPAREN expression RPAREN statement ELSE statement"<<endl<<endl;
		 	string name = $1  + $2->getName() + $3->getName() + $4->getName() + $5->getName() + newline + $6  + $7->getName(); 
			$$ = new SymbolInfo(name,"statement", "void");
			logout<<$$->getName()<<endl<<endl;

			string label1 = newLabel();
			string label2 = newLabel();
			$$->code += $3->code;
			$$->code += ";if"  + $2->getName() + $3->getName() + $4->getName() + $5->getName() + " else"  + $7->getName()+ "\n";
			$$->code += "CMP AX, 0H\nJE " + label1 + "\n";
			$$->code += $5->code;
			$$->code += "JMP " + label2 + "\n";
			$$->code += label1 + ":\n";
			$$->code += $7->code;
			$$->code += label2 + ":\n";

			delete $2, $3, $4, $5, $7;
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		  	logout<<"Line  "<<lines<<":  statement : WHILE LPAREN expression RPAREN statement"<<endl<<endl;
		 	string name = $1  + $2->getName() + $3->getName() + $4->getName() + $5->getName(); 
			$$ = new SymbolInfo(name,"statement", "void");
			logout<<$$->getName()<<endl<<endl;

			string label1 = newLabel();
			string label2 = newLabel();
			$$->code += ";while loop\n";
			$$->code += label1 + ":\n";
			$$->code += $3->code;
			if($3->Symbol.compare("AX") != 0){
				$$->code += "MOV AX, " + $3->Symbol + "\n";
			}
			$$->code += "CMP AX, 0H\nJE " + label2 + "\n";
			$$->code += $5->code;
			$$->code += "JMP " + label1 + "\n";
			$$->code += label2 + ":\n";

			delete $2, $3, $4, $5;
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		  	logout<<"Line  "<<lines<<":  statement : PRINTLN LPAREN ID RPAREN SEMICOLON"<<endl<<endl;
			SymbolInfo* exists = s->LookUp($3->getName());
			if(exists == nullptr) unknown_var_error($3->getName());
		 	string name = $1 + $2->getName() + $3->getName() + $4->getName() + $5->getName(); 
			$$ = new SymbolInfo(name,"statement", "void");
			logout<<$$->getName()<<endl<<endl;

			$$->code = "PUSH " + $3->getName() + "_" + s->getScopeID($3->getName()) +"\n";
			$$->code += "CALL PRINT\n";
			print = true;

			delete $2, $3, $4, $5;
	  }
	  | RETURN expression SEMICOLON
	  {
		  	logout<<"Line  "<<lines<<":  statement : RETURN expression SEMICOLON"<<endl<<endl;
		 	string name = $1  + $2->getName() + $3->getName() ; 
			$$ = new SymbolInfo(name,"statement", $2->getDataType());
			logout<<$$->getName()<<endl<<endl;
			
			$$->code += $2->code;
			if($2->Symbol.compare("AX") != 0){
				$$->code += "MOV AX, " + $2->Symbol  + "\n";
			}
			// $$->code += "RET\n";

			delete $2, $3;
	  }
	  | func_declaration
		{
			logout<<"Line  "<<lines<<":  statement : func_declaration"<<endl<<endl; 
			$$ = $1;
			logout<<$$->getName()<<endl<<endl;
			funcInfunc();
		}
	  | func_definition
		{
			logout<<"Line  "<<lines<<":  statement : func_definition"<<endl<<endl; 
			$$ = $1;
			logout<<$$->getName()<<endl<<endl;
			funcInfunc();
		}

	  ;
	  
expression_statement 	: SEMICOLON		
		{
			logout<<"Line  "<<lines<<":  expression_statement : SEMICOLON"<<endl<<endl;
			$$ = new SymbolInfo($1->getName(),"expression_statement", "void");
			logout<<$$->getName()<<endl<<endl;
			delete $1;
		}	
			| expression SEMICOLON 
		{
			logout<<"Line  "<<lines<<":  expression_statement : expression SEMICOLON"<<endl<<endl;
			string name = $1->getName() + $2->getName();
			$$ = new SymbolInfo(name,"expression_statement", "void");
			logout<<$$->getName()<<endl<<endl;

			$$->code = $1->code;

			delete $1, $2;
		}	
		;
	  
variable : ID 				
	{
		logout<<"Line  "<<lines<<":  variable : ID"<<endl<<endl; 
		string name = $1->getName();
		SymbolInfo* exists = s->LookUp(name);
		if(exists == NULL) {
			unknown_var_error(name);
			$$ = new SymbolInfo($1->getName(),"variable", "");
		}
		else{
			$$ = new SymbolInfo($1->getName(),"variable", exists->getDataType());
			if(exists->getArray() != 0) array_mismatch($1->getName(), true);
		}
		
		logout<<$$->getName()<<endl<<endl;

		auto it = func_params.find($1->getName() + "_" + s->getScopeID($1->getName()));
		if (it != func_params.end()){
			$$->Symbol = it->second;
		}
		else{
			$$->Symbol = $1->getName() + "_" + s->getScopeID($1->getName());
		}

		delete $1;
	}	
	 | ID LTHIRD expression RTHIRD 
	 {
		logout<<"Line  "<<lines<<":  variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		SymbolInfo* exists = s->LookUp($1->getName());
		if(exists == nullptr) unknown_var_error($1->getName());
		checkIndexError($3->getDataType());
		string name = $1->getName() + $2->getName() + $3->getName() + $4->getName(); 
		if(exists == nullptr){
			$$ = new SymbolInfo(name,"variable", "");
		}
		else if(exists->getArray() == 0){
			array_mismatch($1->getName(), false);
			$$ = new SymbolInfo(name,"variable", "");
		} 
		else $$ = new SymbolInfo(name,"variable", exists->getDataType());
		
		logout<<$$->getName()<<endl<<endl;

		$$->setArray(1);
		$$->code = $3->code;
		if($3->Symbol.compare("AX") != 0){	
			$$->code += "MOV AX, " + $3->Symbol + "\n";
			$$->code += "MOV BX, 2\nIMUL BX\nXOR DX, DX\n";
		}
		$$->code += "MOV SI, AX\n";
		$$->Symbol = $1->getName() + "_" + s->getScopeID($1->getName());

		delete $1, $2, $3, $4;
	 }
	 ;
	 
expression : logic_expression	
		{
			logout<<"Line  "<<lines<<":  expression : logic_expression"<<endl<<endl;
			$$ = new SymbolInfo($1->getName(), "expression", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code = $1->code;
			$$->Symbol = $1->Symbol;

			delete $1;
		}
	   | variable ASSIGNOP logic_expression 
	   {
			logout<<"Line  "<<lines<<":  expression : variable ASSIGNOP logic_expression"<<endl<<endl;
			string name = $1->getName() + $2->getName() + $3->getName();
			$$ = new SymbolInfo(name, "expression", $1->getDataType());
			//if($1->getArray() != 0) array_mismatch($1->getName(), true);
			if($1->getDataType().compare("") != 0 && $3->getDataType().compare("") != 0) bool error = assignment_type_check($1->getDataType(), $3->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code += ";"+name + "\n";
			$$->code += $3->code;
			if($1->getArray() != 0){
				$$->code += $1->code;
				$$->code += "MOV " + $1->Symbol + "[SI], " + $3->Symbol + "\n";
			}
			else{
				$$->code += "MOV " + $1->Symbol + ", " + $3->Symbol + "\n";
			}

			delete $1,$2,$3;
	   }	
	   ;
			
logic_expression : rel_expression 
		{
			logout<<"Line  "<<lines<<":  logic_expression : rel_expression  "<<endl<<endl;
			$$ = new SymbolInfo($1->getName(), "logic_expression", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code = $1->code;
			$$->Symbol = $1->Symbol;

			delete $1;
		}	
		 | rel_expression LOGICOP rel_expression 
		 {
			logout<<"Line  "<<lines<<":  logic_expression : rel_expression LOGICOP rel_expression"<<endl<<endl;
			string name = $1->getName() + $2->getName() + $3->getName();
			bool voidcheck = voidFuncExpression($1->getDataType(), $3->getDataType());
			if(voidcheck == false) $$ = new SymbolInfo(name, "logic_expression", "int");
			else $$ = new SymbolInfo(name, "logic_expression", "");
			logout<<$$->getName()<<endl<<endl;

			string label1 = newLabel();
			string label2 = newLabel();	

			$$->code = $1->code;
			$$->code = ";" + name + "\n";
			// $$->code += "MOV CX, " + $1->Symbol + "\n";
			$$->code += "PUSH " + $1->Symbol + "\n";
			$$->code += $3->code;
			$$->code += "POP CX\n";
			if($2->getName().compare("&&") == 0){
				$$->code += "CMP CX, 1H\n";
				$$->code += "JL " + label1 + "\n";
				if($3->Symbol.compare("AX") != 0){
					$$->code += "MOV AX, " + $3->Symbol + "\n";
				}
				$$->code += "CMP AX, 1H\n";
				$$->code += "JL " + label1 + "\n";
				$$->code += "MOV AX, 1H\nJMP " + label2 + "\n";
				$$->code += label1 + ":\nMOV AX, 0H\n";
				$$->code += label2 + ":\n";

			}
			else{
				$$->code += "CMP CX, 1H\n";
				$$->code += "JGE " + label1 + "\n";
				if($3->Symbol.compare("AX") != 0){
					$$->code += "MOV AX, " + $3->Symbol + "\n";
				}
				$$->code += "CMP AX, 1H\n";
				$$->code += "JGE " + label1 + "\n";
				$$->code += "MOV AX, 0H\nJMP " + label2 + "\n";
				$$->code += label1 + ":\nMOV AX, 1H\n";
				$$->code += label2 + ":\n";
				
			}
			$$->Symbol = "AX";

			delete $1,$2,$3;
		 }	
		 ;
			
rel_expression	: simple_expression 
		{
			logout<<"Line  "<<lines<<":  rel_expression : simple_expression "<<endl<<endl;
			$$ = new SymbolInfo($1->getName(), "rel_expression", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->code = $1->code;
			$$->Symbol = $1->Symbol;

			delete $1;
		
		}
		| simple_expression RELOP simple_expression	
		{
			logout<<"Line  "<<lines<<":  rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			string name = $1->getName() + $2->getName() + $3->getName();
			bool voidcheck = voidFuncExpression($1->getDataType(), $3->getDataType());
			if(voidcheck == false) $$ = new SymbolInfo(name, "rel_expression", "int");
			else $$ = new SymbolInfo(name, "rel_expression", "");
			logout<<$$->getName()<<endl<<endl;

			string label1 = newLabel();
			string label2 = newLabel();
			$$->code = ";" + name + "\n";
			
			$$->code += $1->code;
			// $$->code += "MOV CX, " + $1->Symbol + "\n";
			$$->code += "PUSH " + $1->Symbol + "\n";
			$$->code += $3->code;
			if($3->Symbol.compare("AX") != 0){
				$$->code += "MOV AX, "+ $3->Symbol + "\n";
			}
			$$->code += "POP CX\n";
			$$->code += "CMP CX, AX\n";
			if($2->getName().compare("<") == 0){	$$->code += "JL " + label1 + "\n";}
			else if($2->getName().compare(">") == 0){	$$->code += "JG " + label1 + "\n";}
			else if($2->getName().compare("<=") == 0){	$$->code += "JLE " + label1 + "\n";}
			else if($2->getName().compare(">=") == 0){	$$->code += "JGE " + label1 + "\n";}
			else if($2->getName().compare("==") == 0){	$$->code += "JE " + label1 + "\n";}
			else if($2->getName().compare("!=") == 0){	$$->code += "JNE " + label1 + "\n";}
			$$->code += "MOV AX, 0\nJMP " + label2 + "\n";
			$$->code += label1 + ":\n" + "MOV AX, 1\n";
			$$->code += label2 + ":\n";
			$$->Symbol = "AX";

			delete $1,$2,$3;
		}
		;
				
simple_expression : term 
		{
			logout<<"Line  "<<lines<<":  simple_expression : term  "<<endl<<endl;
			$$ = new SymbolInfo($1->getName(), "simple_expression",$1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->Symbol = $1->Symbol;
			$$->code = $1->code;

			delete $1;
		}
		  | simple_expression ADDOP term 
		{
			logout<<"Line  "<<lines<<":  simple_expression : simple_expression ADDOP term "<<endl<<endl;
			string name = $1->getName() + $2->getName() + $3->getName();
			string datatype = type_convert($1->getDataType(), $3->getDataType());
			$$ = new SymbolInfo(name, "simple_expression", datatype);
			logout<<$$->getName()<<endl<<endl;

			
			$$->code += $1->code;
			$$->code += "PUSH " + $1->Symbol + "\n";
			$$->code += $3->code;
			$$->code += ";" + $$->getName() + "\n";
			$$->code += "MOV BX, " + $3->Symbol + "\n";
			$$->code += "POP AX\n";
			if($2->getName().compare("+") == 0) $$->code += "ADD AX, BX\n";
			else $$->code += "SUB AX, BX\n";
 
			$$->Symbol = "AX";

			delete $1,$2,$3;
		}
		  ;
					
term :	unary_expression
	{
		logout<<"Line  "<<lines<<":  term :	unary_expression "<<endl<<endl;
		$$ = new SymbolInfo($1->getName(), "term", $1->getDataType());
		logout<<$$->getName()<<endl<<endl;

		$$->Symbol = $1->Symbol;
		$$->code = $1->code;

		delete $1;
	}
     |  term MULOP unary_expression
	{
		logout<<"Line  "<<lines<<":  term : term MULOP unary_expression  "<<endl<<endl;
		string name = $1->getName() + $2->getName() + $3->getName();
		string datatype = type_convert($1->getDataType(), $3->getDataType());
		bool voidcheck = voidFuncExpression($1->getDataType(), $3->getDataType());
		if($2->getName().compare("%") == 0) {
			checkZeroError($3->getName());
			checkModulusError($1->getDataType(), $3->getDataType());
			datatype = "int";
		}
		//else{
		//	assignment_type_check($1->getDataType(), $3->getDataType());
		//}
		if(voidcheck == true) datatype = "";
		$$ = new SymbolInfo(name, "unary_expression", datatype);
		logout<<$$->getName()<<endl<<endl;

		$$->code += $1->code;
		$$->code += "PUSH " + $1->Symbol + "\n";
		$$->code += $3->code;
		$$->code += "MOV BX, " + $3->Symbol + "\n";
		$$->code += "POP AX\n";
		$$->code += ";" + name + "\n";
		
		if($2->getName().compare("*") == 0){	$$->code += "IMUL BX\nXOR DX, DX\n";	}
		else{
			$$->code += "IDIV BX\n";
			if($2->getName().compare("%") == 0){	
				$$->code += "MOV AX, DX\n";	
			}
		}

		$$->Symbol = "AX";

		delete $1,$2,$3;
	}
     ;

unary_expression : ADDOP unary_expression  
		{
			logout<<"Line  "<<lines<<":  unary_expression : ADDOP unary_expression  "<<endl<<endl;
			string name = $1->getName() + $2->getName();
			$$ = new SymbolInfo(name, "unary_expression", $2->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->Symbol = $2->Symbol;
			if($1->getName().compare("-") == 0){
				$$->code += ";" + name + "\n";
				$$->code += "MOV AX, " + $2->Symbol + "\n";
				$$->code += "NEG AX\n";
				$$->Symbol = "AX";
			}

			delete $1,$2;
		}
		 | NOT unary_expression 
		 {
			logout<<"Line  "<<lines<<":  unary_expression : NOT unary_expression  "<<endl<<endl;
			string name = $1->getName() + $2->getName();
			$$ = new SymbolInfo(name, "unary_expression", "int");
			logout<<$$->getName()<<endl<<endl;

			$$->code += ";" + name + "\n";
			$$->code += "MOV AX, " + $2->Symbol + "\n";
			$$->code += "NOT AX\n";
			$$->Symbol = "AX";

			delete $1,$2;
		}
		 | factor 
		 {
			logout<<"Line  "<<lines<<":  unary_expression : factor  "<<endl<<endl;
			$$ = new SymbolInfo($1->getName(), "unary_expression", $1->getDataType());
			logout<<$$->getName()<<endl<<endl;

			$$->Symbol = $1->Symbol;
			$$->code = $1->code;

			delete $1;
		 }
		 ;
	
factor	: variable 
	{
		//check if factor and variable is array???? exactly where????


		logout<<"Line  "<<lines<<":  factor : variable "<<endl<<endl;
		$$ = new SymbolInfo($1->getName(),"factor", $1->getDataType());
		logout<<$$->getName()<<endl<<endl;

		$$->code = $1->code;
		$$->Symbol = $1->Symbol ;
		if($1->getArray() != 0){
			$$->code += "MOV AX, " + $1->Symbol + "[SI]\n";
			$$->Symbol = "AX";
		}

		delete $1;
	}
	| ID LPAREN argument_list RPAREN
	{
		logout<<"Line  "<<lines<<":  factor : ID LPAREN argument_list RPAREN"<<endl<<endl;
		string name = $1->getName() + $2->getName() + $3->at(0)->getName() + $4->getName();
		string datatype = "";
		SymbolInfo* exists = s->LookUp($1->getName());
		if(exists == nullptr)	unknown_var_error($1->getName());
		else{
			//check if argument types and parameters of function match
			bool check = checkFuncParameters(exists, $3);
			if(check == false) datatype = exists->getDataType();
		}
		
		$$ = new SymbolInfo(name,"factor", datatype);
		logout<<$$->getName()<<endl<<endl;

		for(int i = $3->size() - 1; i>=1; i--){
			//$$->code += "PUSH " + $3->at(i)->getName() + "_" + s->getScopeID($3->at(i)->getName()) + "\n";
			$$->code += "PUSH " + $3->at(i)->Symbol + "\n";
		}
		$$->code += "CALL " + $1->getName() + "\n";
		$$->Symbol = "AX";

		delete $1, $2, $3, $4;
	}
	| LPAREN expression RPAREN
	{
		logout<<"Line  "<<lines<<":  factor : LPAREN expression RPAREN"<<endl<<endl;
		string name = $1->getName() + $2->getName() + $3->getName();
		$$ = new SymbolInfo(name,"factor", $2->getDataType());
		logout<<$$->getName()<<endl<<endl;

		$$->code = $2->code;
		$$->Symbol = $2->Symbol;

		delete $1, $2, $3;
	}
	| CONST_INT 			
	{ 
		logout<<"Line  "<<lines<<":  factor	: CONST_INT "<<endl<<endl;
		$$ = new SymbolInfo($1->getName(),"factor", $1->getDataType());
		logout<<$$->getName()<<endl<<endl;

		$$->Symbol = $1->getName();

		delete $1; 
	}
	| CONST_FLOAT			
	{
		logout<<"Line  "<<lines<<":  factor	: CONST_FLOAT "<<endl<<endl;
		$$ = new SymbolInfo($1->getName(),"factor", $1->getDataType());
		logout<<$$->getName()<<endl<<endl;

		$$->Symbol = $1->getName();

		delete $1; 
	}
	| variable INCOP
	{
		logout<<"Line  "<<lines<<":  factor	: variable INCOP "<<endl<<endl;
		string name = $1->getName() + $2->getName();
		$$ = new SymbolInfo(name,"factor", $1->getDataType());
		//check if variable is an array
		//if($1->getArray() != 0) array_mismatch($1->getName(), true);
		logout<<$$->getName()<<endl<<endl;

		$$->code += ";"+name + "\n";
		if($1->getArray() != 0){
			$$->code += $1->code;
			$$->code += "MOV AX, " + $1->Symbol + "[SI]\n";
			$$->code += "INC " + $1->Symbol + "[SI]\n";
		}
		else{
			$$->code += "MOV AX, " + $1->Symbol + "\n";
			$$->code += "INC " + $1->Symbol + "\n";
		}
		$$->Symbol = "AX";

		delete $1, $2;
	}
	| variable DECOP 
	{
		logout<<"Line  "<<lines<<":  factor	: variable DECOP "<<endl<<endl;
		string name = $1->getName() + $2->getName();
		$$ = new SymbolInfo(name,"factor", $1->getDataType());
		//check if variable is an array
		//if($1->getArray() != 0) array_mismatch($1->getName(), true);

		logout<<$$->getName()<<endl<<endl;

		$$->code += ";"+name + "\n";
		if($1->getArray() != 0){
			$$->code += $1->code;
			$$->code += "MOV AX, " + $1->Symbol + "[SI]\n";
			$$->code += "DEC " + $1->Symbol + "[SI]\n";
		}
		else{
			$$->code += "MOV AX, " + $1->Symbol + "\n";
			$$->code += "DEC " + $1->Symbol + "\n";
		}
		$$->Symbol = "AX";

		delete $1, $2;
	}
	;
	
argument_list : arguments
				{
					//function parameters
					logout<<"Line  "<<lines<<":  argument_list : arguments"<<endl<<endl;
					$$ = $1;
					logout<<$$->at(0)->getName()<<endl<<endl;
				}
			  |
			  {
				   //function parameters
				   logout<<"Line  "<<lines<<":  argument_list : "<<endl<<endl;
					$$ = new vector<SymbolInfo*>();
					$$->push_back(new SymbolInfo("","arguments", ""));
					logout<<$$->at(0)->getName()<<endl<<endl;
			  }
			  ;
	
arguments : arguments COMMA logic_expression
			{
				//function parameters
				logout<<"Line  "<<lines<<":  arguments : arguments COMMA logic_expression"<<endl<<endl;
				string name = $1->at(0)->getName() + $2->getName() + $3->getName();
				$$ = new vector<SymbolInfo*>();
				$$->push_back(new SymbolInfo(name,"arguments", ""));
				for(int i = 1; i<$1->size(); i++){
					$$->push_back($1->at(i));
				}
				$$->push_back($3);
				logout<<name<<endl<<endl;
				delete $2;
			}
	      | logic_expression
		  {
			  	//function parameters match
				logout<<"Line  "<<lines<<":  arguments : logic_expression"<<endl<<endl;
				string name = $1->getName();
				$$ = new vector<SymbolInfo*>();
				$$->push_back(new SymbolInfo(name,"arguments", ""));
				$$->push_back($1);
				logout<<name<<endl<<endl;
		  }
		  | arguments COMMA error
		  {
			  	$$ = $1;
				//logout<<name<<endl<<endl;
		  }
	      ;

	


%%
main(int argc,char *argv[])
{
    if(argc!=2){
		logout<<"Please provide input file name and try again"<<endl<<endl;
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		logout<<"Cannot open specified file\n";
		return 0;
	}
	logout.open ("log.txt");
	errorout.open("error.txt");
	assembly.open("code.asm");
  	
	yyin= fin;
	yyparse();
}

