
// 浮点数区分大小端
//
// 查看舍入模式: fegetround()
// 设置舍入模式: fesetround(...)
// 舍入模式 
// * 向下舍入: std::floor
// * 向上舍入: std::ceil
// * 向零舍入: std::trunc, 浮点数-->整数
// * 最近舍入: 四舍六入五取偶
// * 四舍五入: std::round
// * 由舍入模式决定: std::rint, std::nearbyint, printf 等
//
// 浮点数字符串 --> 浮点数二进制, 可能会损失精度
// 浮点数二进制 --> 浮点数字符串,   不会损失精度
//
// TODO: 16 位精度究竟是什么意思?

#include <iostream>
#include <string>
#include <iomanip>
#include <cfenv>
#include <map>
#include <vector>
#include <cstdio>
#include <cstdlib>
#include <cstdio>
#include <bitset>
#include <ctype.h>
#include <algorithm>
#include <sstream>

using namespace std;

// 存储 2 的幂次
// 2 的 10 次 1024
// 2 的  0 次 1
// 2 的 -1 次 5
// 2 的 -2 次 25
map<int, string> dict;
map<int, string> name;
void init_dict(int n);

// 移除所有的 空字符
string trim(const string& str) {
    string result;
    for (char ch : str)
        if (!isspace(ch))
            result += ch;
    return result;
}

// 计算机计算的结果
union Node {
    double   x;
    uint64_t y;
    char     s[8];

    void     set_double(double   v) {    x = v; }
    double   get_double()           { return x; }

    void     set_ulong(uint64_t v)  {    y = v; }
    uint64_t get_ulong()            { return y; }

    void set_str(const string& str) {
        stringstream tmp(str);
        tmp >> x;
    }

    string get_str() {
        stringstream tmp;
        tmp << setprecision(2000) << fixed << x; // TODO: 两千够吗?
        string result = tmp.str();
        size_t index = result.find_last_not_of('0');

        if (result[index] == '.')
            --index;
        return result.substr(0, index + 1);
    }

    void set_bit(const string& bit) {
        y = bitset<64>(trim(bit)).to_ulong();
    }

    string get_bit() {
        string str = bitset<64>(y).to_string();
        string result;
        for (int i = 0; i < 64; i += 8)
            result += str.substr(i, 8) + " ";
        return result;
    }

    // 计算机 实际存储
    string get_mem() {
        string result;
        for (int i = 0; i < 8; ++i)
            result += bitset<8>((unsigned char)s[i]).to_string() + " ";
        return result;
    }

    void output(int n = 2) {
        cout << "计算机   舍入方向: " << name[fegetround()] << endl;
        cout << "计算机     二进制: " << get_bit() << endl;
        cout << "计算机   实际存储: " << get_mem() << endl;
        cout << "计算机 精确十进制: " << get_str() << endl;
        cout << fixed << setprecision(n);
        cout << "计算机     近似值: " << get_double() << endl;
    }
};

// 手动获取浮点数的精确值
string get_string_double_by_hand_double(double x);
string get_string_double_by_hand_str(const string& str);
string get_string_double_by_hand_bit(const string& bit);

// 输出
void output_by_double(double x);
void output_by_bit(const string& bit);
void output_by_string(const string& str);

int main() {
    init_dict(2000);


    name[FE_DOWNWARD]   = "向下舍入";
    name[FE_TONEAREST]  = "最近舍入";
    name[FE_TOWARDZERO] = "向零舍入";
    name[FE_UPWARD]     = "向上舍入";

    Node node;

    node.set_double(0.125);
    node.output(2);

    return 0;
}

void init_dict(int n) {
    string str;

    str = "5";
    for (int i = -1; i >= -n; --i) {
        dict[i] = str;

        str = "";
        int sum = 0;
        for (char ch : dict[i]){
            sum = sum * 10 + (ch - '0');
            str += string(1, sum / 2 + '0');
            sum %= 2;
        }
        if (sum != 0) {
            str += "5";
        }
    }

    str = "1";
    for (int i = 0; i <= n; ++i) {
        dict[i] = str;

        str = "";
        int sum = 0;
        for (int j = (int)dict[i].size() - 1; j >= 0; --j){
            sum += (dict[i][j] - '0') * 2;
            str  = string(1, sum % 10 + '0') + str;
            sum /= 10;
        }
        if (sum != 0) {
            str = string(1, sum + '0') + str;
        }
    }
}


// 手动计算的结果
// 两个数的加法
// type 为 0 表示整数加法 1 表示小数加法
string add(string x, string y, int type = 0) {
    if (x.size() > y.size()) swap(x, y);

    if (type == 0) {
        // 整数
        x = string(y.size() - x.size(), '0') + x;
    } else {
        // 小数
        x = x + string(y.size() - x.size(), '0');
    }

    int sum = 0;
    string z;

    for (int i = (int)x.size() - 1; i >= 0; --i) {
        sum += (x[i] - '0') + (y[i] - '0');
        z  = string(1, '0' + sum%10) + z;
        sum /= 10;
    }
    if (sum != 0)
        z = string(1, '0' + sum) + z;
    return z;
}

// 二进制的浮点数转化为 十进制,
// str_int --> 整数部分, str_dec --> 小数部分
string bit_to_double(const string& str_int, const string& str_dec) {
    string result_int = "0";
    for (int i = 0; i < (int)str_int.size(); ++i)
        if (str_int[i] == '1')
            result_int = add(result_int, dict[str_int.size() - 1 - i]);

    string result_dec;
    for (int i = 0; i < (int)str_dec.size(); ++i)
        if (str_dec[i] == '1')
            result_dec = add(result_dec, dict[- 1 - i], 1);

    if (result_dec.empty())
        return result_int;
    else
        return result_int + "." + result_dec;
}

// 二进制的浮点数转化为 十进制
string bit_to_double(const string& str) {
    string s_str = str.substr(0, 1);
    string e_str = str.substr(1, 11);
    string f_str = str.substr(12);

    bitset<11> e_bit(e_str);
    int e_int = e_bit.to_ulong();

    bitset<52> f_bit(f_str);

    // 阶码都为 1, 尾码都为 0
    if (e_bit.all()  && f_bit.none())     return s_str == "1" ? "负无穷" : "正无穷";

    // 阶码都为 1, 尾码不都为 0
    if (e_bit.all()  && not f_bit.none()) return "非数字";

    // 阶码都为 0, 尾码都为 0
    if (e_bit.none() && f_bit.none())     return  s_str == "1" ? "负零" : "正零";

    string str_int;         // 尾码的整数部分
    string str_dec = f_str; // 尾码的小数部分

    if (e_bit.none() && not f_bit.none()) {
        // 阶码都为 0, 尾码不都为 0
        // 非规约数字
        f_str = "0." + f_str;
        e_int -= 1022;
    } else {
        // 阶码不都为 0, 也不都为 1
        // 规约数字
        f_str = "1." + f_str;
        e_int -= 1023;
        str_int = "1";
    }

    // 处理 阶码 的移位
    if (e_int > 0) {
        if ((int)str_dec.size() < e_int) {
            str_dec += string(e_int - str_dec.size(), 0);
        }

        str_int += str_dec.substr(0, e_int);
        str_dec  = str_dec.substr(e_int);
    } else if (e_int < 0) {
        if (!str_int.empty()) {
            str_dec = string(-e_int - 1 , '0') + str_int +  str_dec;
        } else {
            str_dec = string(-e_int , '0') +  str_dec;
        }
        str_int = "";
    }
    string result = bit_to_double(str_int, str_dec);
    if (s_str == "1") {
        result = "-" + result;
    }
    return result;
}

/////////////////////////////////////////////////////////////////////////////////

//
// 原码: 正数: 最高位添加 0, 负数: 最高位添加 1
// 反码: 正数: 等于原码, 负数: 在原码的基础上, 除符号位外, 各位取反
// 补码: 正数: 等于原码, 负数: 在反码的基础上, 加 1
// 移码: 加上指定数字, 使其全部变正
//
// 格式:    1-符号位 11-阶码(偏移量 1023) 52-尾码
// +0,-0             00000000000          全为0   非规约, 没有前置 1
// +1,-1             01111111111          全为0     规约,   有前置 1
// 无穷              11111111111          全为0   实际输出 -inf 或 inf
// 异常数字          11111111111        非全为0   实际输出 -nan 或 nan
// 非规约数          00000000000        非全为0   非规约, 没有前置 0
//
// 十进制数字   --> 二进制字符串  bitset<64>( 123 ).to_string()
// 二进制字符串 --> 十进制数字    bitset<64>("111").to_ulong()
//
// 为什么使用偏移量: 方便比较大小

// 大小端
// 最大, 最小值
// 0 +0 -0
// 溢出
// 精度



//    //    cout << setprecision(2000) << fixed;
//        cout << "            二进制: " << node.get_bit() << endl;
//        cout << "    计算机实际存储: " << node.get_real_memory() << endl;
//        cout << "      有符号的整数: " << node.x << endl;
//        cout << "      无符号的整数: " << node.y << endl;
//        cout << "计算机计算的浮点数: " << node.get_double_by_cs() << endl;
//        cout << "  人工计算的浮点数: " << node.get_double_by_hand() << endl;
//
//    //    void output() {
//    //        cout << "              符号位: " << s_str      << endl;
//    //        cout << "                阶码: " << e_str      << endl;
//    //        cout << "          十进制阶码: " << e_int      << endl;
//    //        cout << "    真实的十进制阶码: " << e_int_real << endl;
//    //        cout << "                尾码: " << f_str      << endl;
//    //        cout << "          真实的尾码: " << f_str_real << endl;
//    //        cout << "      二进制完整格式: " << arg        << endl;
//    //        cout << "计算机实际存储的小数: " << bit_to_double_by_cs(arg) << endl;
//    //        cout << "        手动计算结果: " << result     << endl;
//    //    }
//    }
//
//    return 0;
//}
//
//
