# 倒数平方根  
关于倒数平方根的算法，经查询常用的快速算法是引入常数**0x5f3759df**将浮点数整体移位后再使用牛顿迭代，这一方案较传统的直接使用牛顿迭代求平方根再求倒数更为快捷，使用更少的硬件资源  
将求 $\frac{1}{\sqrt{x}}$ 转化为求 f(y)= $\frac{1}{y^2} -x$ 的一个正根  
根据牛顿迭代法的思想：给出一个根的合适近似 y_n ，那么一个更加近似的根 $y_{n+1} = y_n-\frac{f(y_n)}{f(y_n)}'$  
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
## Verilog代码  
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
## 误差分析
我们近似的认为: $\log _{2}(1+x) \approx x+\sigma$  
根据切比雪夫公式: $\log _{2}(1+x) \approx x+\sigma \sigma=\frac{\log _{2}\left(\frac{1}{\ln 2}\right)-\frac{1}{\ln 2}+1}{2} \approx 0.043$  
![拟合线](https://pic2.zhimg.com/v2-8507040a883bf269a4bd20ed8db6f019_r.jpg)  
## 优化方向
可以看到:该法的误差来源于上图中拟合线与实际曲线的误差，因此，后续优化可从此角度入手（？）  
## 硬件资源
（暂未研究）
