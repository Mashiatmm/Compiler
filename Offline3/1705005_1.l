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
#include "y.tab.h"

using namespace std;
extern YYSTYPE yylval;
extern SymbolTable *s;
extern ofstream logout;
extern ofstream errorout;
void yyerror(char *);

string tempchar = "";
string rawstr = "";
int errors = 0;
int lines = 1;
int initialLine = 0;
char tempc ;

%}

AlphaNumeric [a-zA-Z0-9_]
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

[ \t\r]+    {}
[\n]		{ lines++;}

"if" 		{ yylval.str = "if ";	return IF;}

"else" 	{ yylval.str = "else "; return ELSE;}

"for" 		{ yylval.str = "for "; return FOR;}

"while" 	{ yylval.str = "while "; return WHILE;}

"do" 		{ yylval.str = "do "; return DO;}

"break" 	{ yylval.str = "break "; return BREAK;}

"int" 		{ yylval.str = "int "; return INT;}

"char" 	{ yylval.str = "char "; return CHAR;}

"float" 	{ yylval.str = "float " ; return FLOAT;}

"double" 	{ yylval.str = "double " ; return DOUBLE;}

"void" 	{ yylval.str = "void "; return VOID;}

"return" 	{ yylval.str = "return "; return RETURN;}

"switch" 	{ yylval.str = "switch " ; return SWITCH;}

"case" 	{ yylval.str = "case "; return CASE;}

"default" 	{ yylval.str = "default " ; return DEFAULT;}

"continue" 	{ yylval.str = "continue "; return CONTINUE;}

"main"		{yylval.si = new SymbolInfo("main", "ID", "keyword") ; return ID;}

"println"|"printf"	{yylval.str = "println "; return PRINTLN;}

{Float}   {
		SymbolInfo *symbol = new SymbolInfo(yytext, "CONST_FLOAT", "float");
		yylval.si = symbol;
		return CONST_FLOAT;
			
	  }
{Integer}  {
		SymbolInfo *symbol = new SymbolInfo(yytext, "CONST_INT", "int");
		yylval.si = symbol;
		return CONST_INT;
	   }



"++"		{ yylval.si = new SymbolInfo(yytext,"INCOP", "");	return INCOP; }

"--"		{ yylval.si = new SymbolInfo(yytext,"DECOP", "");	return DECOP; }
		
"+"|"-"	{ yylval.si = new SymbolInfo(yytext,"ADDOP", "");	return ADDOP; }
	
"*"|"/"|"%"	{ yylval.si = new SymbolInfo(yytext,"MULOP", "");	return MULOP; }

"<"|"<="|">"|">="|"=="|"!="	{ yylval.si = new SymbolInfo(yytext,"RELOP", "");	return RELOP; }
		
"="		{ yylval.si = new SymbolInfo(yytext,"ASSIGNOP", "");	return ASSIGNOP; }

"&&"|"||"	{	yylval.si = new SymbolInfo(yytext,"LOGICOP", "");	 return LOGICOP; }
		
"!"		{	yylval.si = new SymbolInfo(yytext,"NOT", "");	return NOT; }

"("		{ yylval.si = new SymbolInfo("(","LPAREN", ""); return LPAREN; }

")"		{ yylval.si = new SymbolInfo(")","RPAREN", ""); return RPAREN; }

"[" 	{ yylval.si = new SymbolInfo("[","LTHIRD", ""); return LTHIRD; }
		
"]"		{ yylval.si = new SymbolInfo("]","RTHIRD", ""); return RTHIRD; }
		
","		{ yylval.si = new SymbolInfo(",","COMMA", ""); return COMMA; }
		
";"		{ yylval.si = new SymbolInfo(";","SEMICOLON", ""); return SEMICOLON; }

"{"		{ yylval.si = new SymbolInfo("{","LCURL", ""); return LCURL; } 
		
"}"		{ yylval.si = new SymbolInfo("}","RCURL", ""); return RCURL; } 
			   
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
		//else logout<<"Line no "<<lines<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
		}
		
"/*"		{
		tempchar = yytext;
		initialLine = lines;
		BEGIN MULTICOMMENT2;
		}

{Identifier}	{

		yylval.si = new SymbolInfo(yytext, "ID", "");
		
		return ID;
		/*bool check = s->Insert(yytext, "ID");
		if(check == true) s->PrintAllScopes(logout);*/
		}

{InvalidID}	{
		errors++;
		logout<<"Error at line "<<lines<<": Invalid prefix on ID or invalid suffix on Number "<<yytext<<endl;
		errorout<<"Error at line "<<lines<<": Invalid prefix on ID or invalid suffix on Number "<<yytext<<endl;
		}
		

{Digit}*\.({Digit}*\.)+{Digit}*	{
		errors++;
		logout<<"Error at line "<<lines<<": Too many decimal points "<<yytext<<endl;
		errorout<<"Error at line "<<lines<<": Too many decimal points "<<yytext<<endl;
	}
	

{IllFormed}	{
		errors++;
		logout<<"Error at line "<<lines<<": Ill formed number "<<yytext<<endl;
		errorout<<"Error at line "<<lines<<": Ill formed number "<<yytext<<endl;
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
		logout<<"Error at line "<<lines<<":	Empty character constant error '"<<yytext<<endl;
		errorout<<"Error at line "<<lines<<":	Empty character constant error '"<<yytext<<endl;
		tempchar = "";
		BEGIN INITIAL;
		
	    }
	    
<CHECKCHAR>[\n] {
		errors++;
		logout<<"Error at line "<<lines<<": Unterminated character '"<<yytext<<endl;
		errorout<<"Error at line "<<lines<<": Unterminated character '"<<yytext<<endl;
		tempchar = "";
		lines++;
		BEGIN INITIAL;
		
	    }

<CHECKCHAR>. {
		errors++;
		logout<<"Error at line "<<lines<<": Unrecognized character "<<yytext<<endl;
		errorout<<"Error at line "<<lines<<": Unrecognized character "<<yytext<<endl;
		tempchar = "";
		BEGIN INITIAL;
		
	    }
	    
<ENDCHAR>{SingleQuote} {
		SymbolInfo *symbol = new SymbolInfo("'" + tempchar + "'", "CONST_CHAR", "char");
		yylval.si = symbol;
		//if(check == true) s->PrintAllScopes(logout);
		tempchar = "";
		BEGIN INITIAL;
		return CONST_CHAR;
	   }

<ENDCHAR>{Character}+(') {
		errors++;
		logout<<"Error at line "<<lines<<": Multi character constant error '"<<tempchar+yytext<<endl;
		errorout<<"Error at line "<<lines<<": Multi character constant error '"<<tempchar+yytext<<endl;
		tempchar = "";
		BEGIN INITIAL;
		
	   }
	   
<ENDCHAR>[\n] {
		errors++;
		logout<<"Error at line "<<lines<<": Unterminated character '"<<tempchar<<endl;
		errorout<<"Error at line "<<lines<<": Unterminated character '"<<tempchar<<endl;
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
		//tokenout<<"<STRING, "<<tempchar<<"> ";
		//logout<<"Line no "<<initialLine<<": Token <STRING> Lexeme "<<rawstr<<" found --> <STRING, "<<tempchar<<">"<<endl ;
		tempchar = "";
		rawstr = "";
		BEGIN INITIAL;
	}

<CHECKSTRING>[\n]	{
		errors++;
		logout<<"Error at line "<<initialLine<<": Unterminated String "<<rawstr<<endl;
		errorout<<"Error at line "<<initialLine<<": Unterminated String "<<rawstr<<endl;
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
			//logout<<"Line no "<<initialLine<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
			tempchar = "";
			BEGIN INITIAL;
		}
	}

<MULTILINECOMMENT>[\n]	{
		lines++;
		//logout<<"Line no "<<initialLine<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
		tempchar = "";
		BEGIN INITIAL;
	}
	
<MULTICOMMENT2>[\n]	{
		lines++;
		tempchar += yytext;
	}

<MULTICOMMENT2>"*/"	{
		tempchar += yytext;
		//logout<<"Line no "<<initialLine<<": Token <COMMENT> Lexeme "<<tempchar<<" found"<<endl ;
		tempchar = "";
		BEGIN INITIAL;
	}

<MULTICOMMENT2><<EOF>>	{
		errors++;
		logout<<"Error at line "<<initialLine<<": Unterminated Comment "<<tempchar<<endl;
		errorout<<"Error at line "<<initialLine<<": Unterminated Comment "<<tempchar<<endl;
		tempchar = "";
		BEGIN INITIAL;
	}
	
<MULTICOMMENT2>.	{
		tempchar += yytext;
	}


.	{
		errors++;
		logout<<"Error at line "<<lines<<": Unrecognized character "<<yytext<<endl;
		errorout<<"Error at line "<<lines<<": Unrecognized character "<<yytext<<endl;
	}
	
<<EOF>>	{
		//s->PrintAllScopes(logout);
		//logout<<"Total lines: "<<lines<<endl;
		//logout<<"Total errors: "<<errors<<endl;
		return 0;
	}	

%%


