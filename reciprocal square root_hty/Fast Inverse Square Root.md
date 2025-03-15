# 倒数平方根  
关于倒数平方根的算法，经查询常用的快速算法是引入常数**0x5f3759df**将浮点数整体移位后再使用牛顿迭代，这一方案较传统的直接使用牛顿迭代求平方根再求倒数更为快捷，使用更少的硬件资源  
将求 $\frac{1}{\sqrt{x}}$ 转化为求 f(y)= $\frac{1}{y^2} -x$ 的一个正根  
根据牛顿迭代法的思想：给出一个根的合适近似 y_n ，那么一个更加近似的根 $y_{n+1} = y_n-\frac{f(y_n)}{f'(y_n)}$  
[参考求解文章](https://zhuanlan.zhihu.com/p/571321688)  
## C语言代码实现  
```
float Q_rsqrt(float x)
{
    union {
        float    f;
        uint32_t i;
    } conv = { .f = number };
    conv.i  = 0x5f3759df - (conv.i >> 1);
    conv.f *= 1.5F - (number * 0.5F * conv.f * conv.f);
    return conv.f;
}  
```
## 更新-3.8
### Verilog代码  
```
module fast_inverse_sqrt (
    input wire [31:0] number,
    output wire [31:0] result
);

    wire [31:0] i;
    wire [31:0] x2;
    wire [31:0] y;
    wire [31:0] magic;
    wire [31:0] new_y;
    wire [31:0] correction;

    assign x2 = {number[31], number[30:23] - 1, number[22:0]} >> 1;
    assign y = number;
    assign i = 32'h5f3759df - (y >> 1);
    assign magic = i;
    assign new_y = magic;
    assign correction = 32'h3fc00000 - (x2 * new_y * new_y);
    assign result = new_y * correction;

endmodule  
```
### 误差分析
我们近似的认为: $\log _{2}(1+x) \approx x+\sigma$  
根据切比雪夫公式: $\log _{2}(1+x) \approx x+\sigma \sigma=\frac{\log _{2}\left(\frac{1}{\ln 2}\right)-\frac{1}{\ln 2}+1}{2} \approx 0.043$  
![拟合线](https://pic2.zhimg.com/v2-8507040a883bf269a4bd20ed8db6f019_r.jpg)  
### 优化方向
可以看到:该法的误差来源于上图中拟合线与实际曲线的误差，因此，后续优化可从此角度入手（？）  
### 硬件资源
| 资源项         | 详细描述                                                                                     | 数量         |
|---------------|----------------------------------------------------------------------------------------------|------------|
| 寄存器         | 用于存储中间和最终计算结果的 32 位寄存器                                                      | 7          |
| 查找表 (LUT)   | 没有使用查找表                                                                               | 0          |
| 乘法器         | 用于乘法运算的 DSP 单元                                                                      | 3          |
| 减法器         | 用于减法运算的 DSP 单元                                                                      | 3          |
| 右移操作       | 用于右移操作的逻辑单元                                                                      | 2          |
| 控制逻辑       | 用于控制时序和操作的逻辑单元                                                                | 若干        |

## 更新-3.15
将代码做了点小调整，在快速算法的基础上，加入一个容量为16的查找表，存放了前16个质数的倒数平方根用于加速计算，同时保留牛顿迭代（暂定为2次）  
同时补充了上次更新中没有的硬件资源分析。
### 代码更新 
```
module reciprocal_sqrt (
    input wire clk,
    input wire reset,
    input wire [31:0] in,
    output reg [31:0] out
);

reg [31:0] y; // 当前估算值
reg [31:0] x2; // 输入数值的一半
reg [31:0] magic; // 魔术常数
reg [31:0] temp;

// 初始估算值查找表
reg [31:0] lookup_table [0:15];
initial begin
    lookup_table[0] = 32'h3f800000; // 1.0 (2的倒数平方根)
    lookup_table[1] = 32'h3f5db3d7; // 0.707106781 (3的倒数平方根)
    lookup_table[2] = 32'h3f3504f3; // 0.577350269 (5的倒数平方根)
    lookup_table[3] = 32'h3f1db3d7; // 0.5 (7的倒数平方根)
    lookup_table[4] = 32'h3f0a8b14; // 0.40824829 (11的倒数平方根)
    lookup_table[5] = 32'h3ef62e43; // 0.35355339 (13的倒数平方根)
    lookup_table[6] = 32'h3ee4f8b5; // 0.30151134 (17的倒数平方根)
    lookup_table[7] = 32'h3ed2b2a5; // 0.27386128 (19的倒数平方根)
    lookup_table[8] = 32'h3ec1f0f1; // 0.23570226 (23的倒数平方根)
    lookup_table[9] = 32'h3eb5db3d; // 0.22360680 (29的倒数平方根)
    lookup_table[10] = 32'h3ea3d70a; // 0.20412415 (31的倒数平方根)
    lookup_table[11] = 32'h3e91d0b2; // 0.19245009 (37的倒数平方根)
    lookup_table[12] = 32'h3e82d0e5; // 0.18257419 (41的倒数平方根)
    lookup_table[13] = 32'h3e74d0a5; // 0.17407766 (43的倒数平方根)
    lookup_table[14] = 32'h3e63d70a; // 0.16222142 (47的倒数平方根)
    lookup_table[15] = 32'h3e55d0b2; // 0.15430335 (53的倒数平方根)
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        y <= lookup_table[(in >> 23) & 4'hF]; // 使用查表法生成初始估算值
        x2 <= {1'b0, in[22:0]} >> 1;
        temp <= 0;
    end else begin
        y <= temp;
        x2 <= {1'b0, in[22:0]} >> 1;
    end
end

// 牛顿迭代法修正估算值 (减少迭代次数)
always @(posedge clk or posedge reset) begin
    if (reset) begin
        out <= 0;
    end else begin
        temp <= y * (32'h3f000000 - (x2 * y * y)); // 进行一次迭代
        y <= temp * (32'h3f000000 - (x2 * temp * temp)); // 进行第二次迭代
        out <= y;
    end
end

endmodule
```
### 资源占用
使用ai分析硬件使用情况，可能与实际存在出入  
| 资源项         | 详细描述                                                                                     | 数量         |
|---------------|----------------------------------------------------------------------------------------------|------------|
| 寄存器         | 用于存储 `y`, `x2`, `magic`, 和 `temp` 的 32 位寄存器                                           | 4          |
| 查找表         | 一个大小为 16 的 32 位寄存器数组，用于存储预计算的倒数平方根常数                                 | 16         |
| 加法器         | 右移操作 (`x2 <= in >> 1;`) 需要的加法器                                                       | 1          |
| 乘法器         | 牛顿迭代法中需要的多个乘法操作 (`temp <= y * (32'h3f000000 - (x2 * y * y));` 和 `y <= temp * (32'h3f000000 - (x2 * temp * temp));`) | 6          |
| 控制逻辑       | 用于控制复位和时钟上升沿触发的逻辑                                                             | 若干        |  