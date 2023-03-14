%option noyywrap

%x CHECKCHAR
%x ENDCHAR
%x CHECKSTRING
%x MULTILINESTRING
%x MULTILINECOMMENT
%x MULTICOMMENT2

%{
#include<iostream>
#include<fstream>
#include<bits/stdc++.h>
#include"SymbolTable.cpp"

using namespace std;

ofstream logout;
ofstream tokenout;

SymbolTable *s = new SymbolTable(7);

string tempchar = "";
string rawstr = "";
int errors = 0;
int lines = 0;
int initialLine = 0;
char tempc ;

%}

AlphaNumeric [a-zA-Z0-9_]
KeyWord "if"|"else"|"for"|"while"|"do"|"break"|"int"|"char"|"float"|"double"|"void"|"return"|"switch"|"case"|"default"|"continue"
Digit [0-9]
Alphabet [a-zA-Z]
Integer {Digit}+
Exponential [Ee][+-]?{Digit}+
Float {Digit}*\.{Digit}+{Exponential}?|{Digit}+{Exponential}
Character [^\n\t\']
SpecialCharacter \\(n|t|\\|'|a|f|r|b|v|0|\"|\?)
SingleQuote (')
DoubleQuote (\")
Identifier ({Alphabet}|_){AlphaNumeric}*
InvalidID {Digit}+({Alphabet}|_)+{Digit}*
IllFormed ({Digit}*{Exponential}((\.{Digit}+)|{Exponential})+)|({Digit}+\.)|({Digit}+[Ee][+-]?)
%%

[ \t]+    {}
[\n]	{ lines++;	}
{KeyWord}  {	
		//transform lowercase keyword to uppercase
		string temp = yytext;
		transform(temp.begin(), temp.end(), temp.begin(), ::toupper);
		tokenout<<"<"<<temp<<"> ";
		logout<<"Line no "<<lines<<": Token <"<<temp<<"> Lexeme "<<yytext<<" found "<<endl;
	  }
{Float}   {
		tokenout<<"<CONST_FLOAT, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found "<<endl;
		bool check = s->Insert(yytext, "CONST_FLOAT");
		if(check == true){
			s->PrintAllScopes(logout);
		}
			
	  }
{Integer}  {
		tokenout<<"<CONST_INT, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <CONST_INT> Lexeme "<<yytext<<" found "<<endl;
		bool check  = s->Insert(yytext, "CONST_INT");
		if(check == true) s->PrintAllScopes(logout);
	   }



"++"|"--"	{
		tokenout<<"<INCOP, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <INCOP> Lexeme "<<yytext<<" found "<<endl;
		}
	   
"+"|"-"	{
		tokenout<<"<ADDOP, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <ADDOP> Lexeme "<<yytext<<" found "<<endl;
	}
	
"*"|"/"|"%"	{
		tokenout<<"<MULOP, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <MULOP> Lexeme "<<yytext<<" found "<<endl;
	}

"<"|"<="|">"|">="|"=="|"!="	{
		tokenout<<"<RELOP, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <RELOP> Lexeme "<<yytext<<" found "<<endl;
		}

"="		{
		tokenout<<"<ASSIGNOP, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <ASSIGNOP> Lexeme "<<yytext<<" found "<<endl;
		}

"&&"|"||"	{
		tokenout<<"<LOGICOP, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <LOGICOP> Lexeme "<<yytext<<" found "<<endl;
		}
		
"!"		{
		tokenout<<"<NOT, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <NOT> Lexeme "<<yytext<<" found "<<endl;
		}

"("|")"	{
		string temp = yytext;
		string token = "LPAREN";
		if(temp.compare(")") == 0) token = "RPAREN";
		tokenout<<"<"<<token<<", "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <"<<token<<"> Lexeme "<<yytext<<" found "<<endl;
		}
		
"["|"]"	{
		string temp = yytext;
		string token = "LTHIRD";
		if(temp.compare("]") == 0) token = "RTHIRD";
		tokenout<<"<"<<token<<", "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <"<<token<<"> Lexeme "<<yytext<<" found "<<endl;
		}
		
","		{
		tokenout<<"<COMMA, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <COMMA> Lexeme "<<yytext<<" found "<<endl;
		}
		
";"		{
		tokenout<<"<SEMICOLON, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <SEMICOLON> Lexeme "<<yytext<<" found "<<endl;
		}
		
"{"|"}"	{
		string temp = yytext;
		string token = "LCURL";
		if(temp.compare("}") == 0){
		 		token = "RCURL";
		 		s->ExitScope();
		 	}
		else s->EnterScope();
		tokenout<<"<"<<token<<", "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <"<<token<<"> Lexeme "<<yytext<<" found "<<endl;
		}
			   
{SingleQuote}	{
		tempchar = "";
		BEGIN CHECKCHAR;
		}
	
{DoubleQuote}	{
		tempchar = yytext;
		rawstr = yytext;
		initialLine = lines;
		BEGIN CHECKSTRING;
		}

"//"[^\n]+	{
		tempchar = yytext;
		if(yytext[yyleng-1] == '\\'){
				initialLine = lines;
				BEGIN MULTILINECOMMENT;
			}
		else logout<<"Line no "<<lines<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
		}
		
"/*"		{
		tempchar = yytext;
		initialLine = lines;
		BEGIN MULTICOMMENT2;
		}

{Identifier}	{
		tokenout<<"<ID, "<<yytext<<"> ";
		logout<<"Line no "<<lines<<": Token <ID> Lexeme "<<yytext<<" found "<<endl;
		bool check = s->Insert(yytext, "ID");
		if(check == true) s->PrintAllScopes(logout);
		}

{InvalidID}	{
		errors++;
		logout<<"Error at line no "<<lines<<": Invalid prefix on ID or invalid suffix on Number "<<yytext<<endl;
		}
		

{Digit}*\.({Digit}*\.)+{Digit}*	{
		errors++;
		logout<<"Error at line no "<<lines<<": Too many decimal points "<<yytext<<endl;
	}
	

{IllFormed}	{
		errors++;
		logout<<"Error at line no "<<lines<<": Ill formed number "<<yytext<<endl;
	}
	
	
	
	    
<CHECKCHAR>{SpecialCharacter} {
		tempchar = yytext;
		
		if(tempchar[1] == 'n') tempc = '\n';
		else if(tempchar[1] == 't') tempc = '\t';
		else if(tempchar[1] == '\\') tempc = '\\';
		else if(tempchar[1] == '\'') tempc = '\'';
		else if(tempchar[1] == 'a') tempc = '\a';
		else if(tempchar[1] == 'f') tempc = '\f';
		else if(tempchar[1] == 'r') tempc = '\r';
		else if(tempchar[1] == 'b') tempc = '\b';
		else if(tempchar[1] == 'v') tempc = '\v';
		else if(tempchar[1] == '0') tempc = '\n';
		else if(tempchar[1] == '\"') tempc = '\"';
		else if(tempchar[1] == '\?') tempc ='\?';
		
		BEGIN ENDCHAR;
	}


<CHECKCHAR>{Character} {
		tempchar = yytext;
		tempc = tempchar[0];
		BEGIN ENDCHAR;

	}
	
<CHECKCHAR>{SingleQuote} {
		errors++;
		logout<<"Error at line no "<<lines<<":	Empty character constant error '"<<yytext<<endl;
		tempchar = "";
		BEGIN INITIAL;
		
	    }
	    
<CHECKCHAR>[\n] {
		errors++;
		logout<<"Error at line no "<<lines<<": Unterminated character '"<<yytext<<endl;
		tempchar = "";
		lines++;
		BEGIN INITIAL;
		
	    }

<CHECKCHAR>. {
		errors++;
		logout<<"Error at line no "<<lines<<": Unrecognized character "<<yytext<<endl;
		tempchar = "";
		BEGIN INITIAL;
		
	    }
	    
<ENDCHAR>{SingleQuote} {
		tokenout<<"<CONST_CHAR, "<<tempc<<"> ";
		logout<<"Line no "<<lines<<": Token <CONST_CHAR> Lexeme '"<<tempchar<<"' found --> <CONST_CHAR, "<<tempc<<">"<<endl ;
		bool check = s->Insert("'" + tempchar + "'", "CONST_CHAR");
		if(check == true) s->PrintAllScopes(logout);
		tempchar = "";
		BEGIN INITIAL;
	   }

<ENDCHAR>{Character}+(') {
		errors++;
		logout<<"Error at line no "<<lines<<": Multi character constant error '"<<tempchar+yytext<<endl;
		tempchar = "";
		BEGIN INITIAL;
		
	   }
	   
<ENDCHAR>[\n] {
		errors++;
		logout<<"Error at line no "<<lines<<": Unterminated character '"<<tempchar<<endl;
		tempchar = "";
		lines++;
		BEGIN INITIAL;

	}
		   
<ENDCHAR>. {
		tempchar += yytext;

	}

<CHECKSTRING>[^\n\"\\]*	{
		rawstr += yytext;
		tempchar += yytext;
	}

<CHECKSTRING>{SpecialCharacter}	{
		
		if(yytext[1] == 'n') tempchar += '\n';
		else if(yytext[1] == 't') tempchar += '\t';
		else if(yytext[1] == '\\') tempchar += '\\';
		else if(yytext[1] == '\'') tempchar += '\'';
		else if(yytext[1] == 'a') tempchar += '\a';
		else if(yytext[1] == 'f') tempchar += '\f';
		else if(yytext[1] == 'r') tempchar += '\r';
		else if(yytext[1] == 'b') tempchar += '\b';
		else if(yytext[1] == 'v') tempchar += '\v';
		else if(yytext[1] == '0') tempchar += '\n';
		else if(yytext[1] == '\"') tempchar += '\"';
		else if(yytext[1] == '\?') tempchar += '\?';
		
		rawstr += yytext;

	}

<CHECKSTRING>"\\"	{
		rawstr += yytext;
		BEGIN MULTILINESTRING;
	}

<CHECKSTRING>{DoubleQuote}	{
		tempchar += yytext;
		rawstr += yytext;
		tokenout<<"<STRING, "<<tempchar<<"> ";
		logout<<"Line no "<<initialLine<<": Token <STRING> Lexeme "<<rawstr<<" found --> <STRING, "<<tempchar<<">"<<endl ;
		tempchar = "";
		rawstr = "";
		BEGIN INITIAL;
	}

<CHECKSTRING>[\n]	{
		errors++;
		logout<<"Error at line no "<<initialLine<<": Unterminated String "<<rawstr<<endl;
		tempchar = "";
		rawstr = "";
		lines++;
		BEGIN INITIAL;
	}

			
	
<MULTILINESTRING>[\n]	{
		rawstr += yytext;
		lines++;
		BEGIN CHECKSTRING;
	}
	
<MULTILINESTRING>.	{
		tempchar += '\\';
		tempchar += yytext;
		rawstr += yytext;
		BEGIN CHECKSTRING;	
	}
	
<MULTILINECOMMENT>[\n][^\n]+	{
		lines++;
		tempchar += yytext;
		if(yytext[yyleng-1] != '\\'){
			logout<<"Line no "<<initialLine<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
			tempchar = "";
			BEGIN INITIAL;
		}
	}

<MULTILINECOMMENT>[\n]	{
		lines++;
		logout<<"Line no "<<initialLine<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
		tempchar = "";
		BEGIN INITIAL;
	}
	
<MULTICOMMENT2>[\n]	{
		lines++;
		tempchar += yytext;
	}

<MULTICOMMENT2>"*/"	{
		tempchar += yytext;
		logout<<"Line no "<<initialLine<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
		tempchar = "";
		BEGIN INITIAL;
	}

<MULTICOMMENT2><<EOF>>	{
		errors++;
		logout<<"Error at line no "<<initialLine<<": Unterminated Comment "<<tempchar<<endl;
		tempchar = "";
		BEGIN INITIAL;
	}
	
<MULTICOMMENT2>.	{
		tempchar += yytext;
	}


.	{
		errors++;
		logout<<"Error at line no "<<lines<<": Unrecognized character "<<yytext<<endl;
	}
	
<<EOF>>	{
		s->PrintAllScopes(logout);
		logout<<"Total lines: "<<lines<<endl;
		logout<<"Total errors: "<<errors<<endl;
		return 0;
	}	

%%
int main(int argc,char *argv[]){
	
	if(argc!=2){
		cout<<"Please provide input file name and try again"<<endl;
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		cout<<"Cannot open specified file\n";
		return 0;
	}
	
	logout.open ("1705005_log.txt");
	tokenout.open("1705005_token.txt");
  	
	yyin= fin;
	
	lines = 1;
	yylex();
	fclose(yyin);
	
	logout.close();
	tokenout.close();
}
