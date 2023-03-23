#include<iostream>
#include<vector>
#include<string>
#include<algorithm>
using namespace std;
class info {
public:
	string id;
	string type;//string type; //0 void 1val 2var 3array
	int datatype; //0 void 1 int 2 string 3 bool 4 float
	bool init = true;
	bool array = false;

};
class argument {
public:
	string id;
	int datatype;
	argument(string id, int datatype) {
		this->id = id;
		this->datatype = datatype;
	}
};
class symboltable
{
public:
	string id;
	string type;//class fun procedure
	int returnType;
	vector<argument> argu;//check return type
	vector<info>symbol;
	symboltable(string id, string type, int returnType) {
		this->id = id;
		this->type = type;
		this->returnType = returnType;
	}
	void insert(string id, string type, int datatype) {
		info newsymbol;
		newsymbol.id = id;
		newsymbol.type = type;
		newsymbol.datatype = datatype;
		symbol.push_back(newsymbol);
	}
	void addReturn(int returnType) {
		this->returnType = returnType;
	}
	void addArgu(vector<argument>curArg) {
		argu = curArg;
	}
	int lookup(string id) {
		if (!symbol.empty()|!argu.empty()) {
			for (int i = 0; i < symbol.size(); i++) {
				if (symbol[i].id == id) {
					return symbol[i].datatype;
				}

			}
			for (int i = 0; i < argu.size(); i++) {
				if (argu[i].id == id) {
					return argu[i].datatype;
				}
			}
		}
		return 0;
	}
	void display() {
		cout << id << ":" << type << " return:" << intToStr(returnType);

		cout << " arguments:";
		for (int i = 0; i < argu.size(); i++) {
			cout << argu[i].id << ":" << intToStr(argu[i].datatype) << " ";
		}
		cout << endl;

		for (int i = 0; i < symbol.size(); i++) {
			cout << symbol[i].id << " " << symbol[i].type << " " << intToStr(symbol[i].datatype) << endl;
		}

	}
	void showFun() {
		cout << id << ":" << type << " return:" << intToStr(returnType);
		for (int i = 0; i < argu.size(); i++) {
			cout << argu[i].id << ":" << intToStr(argu[i].datatype) << " ";
		}
		cout << endl;
	}
	string intToStr(int num) {
		if (num == 0) {
			return "void";
		}
		if (num == 1) {
			return "int";
		}
		else if (num == 2)
		{
			return"string";
		}
		else if (num == 3)
		{
			return"bool";
		}
		else
		{
			return"float";
		}
	}
	bool paraCheck(vector<int>actual) {
		int size = actual.size();
		if (argu.size() < size) {
			size = argu.size();
		}
		for (int i = 0; i < size; i++) {
			if (argu[i].datatype != actual[i]) {
				return false;
			}
		}
		return true;
	}
	bool checkInit(string id) {
		for (int i = 0; i < symbol.size(); i++) {
			if (symbol[i].id == id) {
				return symbol[i].init;
			}
		}
	}
	void notInit() {
		symbol.back().init = false;
	}
	bool isConst(string id) {
		for (int i = 0; i < symbol.size(); i++) {
			if (symbol[i].id == id && symbol[i].type == "val") {
				return true;
			}
		}
		return false;
	}
	bool isInit(string id) {
		for (int i = 0; i < symbol.size(); i++) {
			if (symbol[i].id == id) {
				return symbol[i].init;
			}
		}
		for (int i = 0; i < argu.size(); i++) { //function不用initial
			if (argu[i].id == id) {
				return true;
			}
		}
	}
	void init(string id) {
		for (int i = 0; i < symbol.size(); i++) {
			if (symbol[i].id == id) {
				symbol[i].init = true;
			}
		}
	}
	void addArr() {
		symbol.back().array = true;
	}

	bool isArr(string id) {
		for (int i = 0; i < symbol.size(); i++) {
			if (symbol[i].id == id) {
				return symbol[i].array;
			}
		}
	}


};
/**/
class symboltablelist
{
public:
	int back = -1;//判斷是倒出class
	vector<symboltable>stb;
	void create(string id, string type, int returnType) {
		back += 1;
		symboltable newtable(id, type, returnType);
		stb.push_back(newtable);
	}
	void insert(string id, string type, int datatype) {
		stb.back().insert(id, type, datatype);
	}
	void addArgu(vector<argument>curArg) {
		stb.back().addArgu(curArg);
	}
	int lookup(string id) {
		if (!stb.empty()) {
			if (stb.back().lookup(id)) {
				return stb.back().lookup(id);
			}
			else {
				return stb.front().lookup(id);
			}
		}
		return 0;
	}
	void addReturn(int returnType) {
		stb.back().addReturn(returnType);
	}
	void pop() {
		cout << "-------------------------------" << endl;
		if (back == 0) {
			stb[0].display();
			cout << "function:" << endl;
			for (int i = 1; i < stb.size(); i++) {
				stb[i].showFun();
			}
			stb.clear();
			back = 0;
		}
		else {
			stb.back().display();
		}
		cout << "-------------------------------" << endl;
		back--;

	}
	void display() {
		for (int i = 0; i < stb.size(); i++) {
			stb[i].display();
		}
	}
	int isFun(string id) {
		for (int i = 1; i < stb.size(); i++) {
			if (stb[i].id == id) {
				return stb[i].returnType;
			}
		}
		return 0;
	}
	bool paraCheck(string id, vector<int>actual) {
		for (int i = 1; i < stb.size(); i++) {
			if (stb[i].id == id) {
				return stb[i].paraCheck(actual);
			}
		}
		return false;
	}
	bool checkInit(string id) {
		return stb.back().checkInit(id);
	}
	void notInit() {
		stb.back().notInit();
	}
	bool isConst(string id) {
		return stb.back().isConst(id);
	}
	bool isInit(string id) {
		if (stb.back().isInit(id)) {
			return true;
		}
		return stb.front().isInit(id);
	}
	void init(string id) {
		stb.back().init(id);
		stb.front().init(id);

	}
	void addArr() {
		stb.back().addArr();
	}
	bool isArr(string id) {
		if (stb.back().isArr(id)) {
			return true;
		}
		return stb.front().isArr(id);
	}
};
