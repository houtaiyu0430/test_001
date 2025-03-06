<h1>sin_cos的快速算法</h1>
<h3>多项式拟合:</h3>
<p>首先是利用<strong>泰勒展开</strong>或者<strong>Chebyshev 逼近</strong>进行多项式拟合。</p>
$$
\sin(x) = x - \frac{x^3}{3!} + \frac{x^5}{5!} - \frac{x^7}{7!}
$$
<p align="center">
    <img scr="./picture/taylor.png" alt="1">
</p>
<p>在pi/2之前的效果还是很好的，但是在pi处的值比原来的0多了0.075，可以继续增加泰勒级数项的个数来减小误差。但是用4项的泰勒级数展开式就已经需要进行7次乘法和3次加法，资源占用很大。</p>
<p>为了减少资源的占用，还可以用<strong>抛物线</strong>来拟合</p>
<p align="center">
    <img scr="parabola.png" alt="2">
</p>
$$
\y = 4/pi x - 4/pi^2 x^2
$$
<p>这种方法的最大误差是0.056，而且这种方法没有累计误差。</p>
<p>为了使图像在[-pi, pi]之间都有抛物线的拟合，可以用<br>
```if(x > 0) { y = 4/pi x - 4/pi^2 x^2; } else { y = 4/pi x + 4/pi^2 x^2; }```进行拟合。</p>
<p>但是这个if判断会综合出两个乘法器、一个加法器和一个减法器，加上一个比较器，还是比较占用资源，再用绝对值优化：4/pi x - x / abs(x) 4/pi^2 x^2，这样综合出条件反转逻辑，两个乘法器和一个减法器优化了资源利用</p>
<p>对于cos(x)，只需要考虑相位变化就好了。<br>
```x += pi/2;
x -= (x > pi) & (2 * pi);
y=sin(x);
```<br>
<p>规避掉了一个if的判断</p>
<p>对于更高精度的要求，可以利用高次方把sinx的图像“按下去”</p>
```Q (4/pi x - 4/pi^2 x^2) + P (4/pi x - 4/pi^2 x^2)^2```
<p align="center">
    <img scr="squared.jpg" alt="3">
</p>
<p>绝对误差的最佳权值是：Q = 0.775, P = 0.225 ；相对误差的最佳权值是：Q = 0.782，P = 0.218 </p> 
<p align="center">
    <img scr="average.jpg" alt="4">
</p>
<p>最大误差是<strong>0.001</strong></p>
<p>考虑全周期的sin(x)，<br>
```float sine(float x) 
const float B = 4/pi; 
const float C = -4/(pi*pi);
float y = B * x + C * x * abs(x);
const float P = 0.225; 
y = P * (y * abs(y) - y) + y```<br>
最终的速度也比4项泰勒级数展开式快，更精准。</p>
<p>此算法综合出的硬件结构只需要用1 个 ABS、2 个乘法、2 个加法单元就可以完成三角函数的运算，并且，在寻优平台中可以根据精度和速度要求用移位和LUT进一步调整ppa的要求(如4/π 可以用移位替代:(x << 1) + (x >> 2))。</p>
<p>若对精度有更进一步的要求，可以增加多项式次数<br>
在[0,90°]范围用5次多项式：<br>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Fixed-Point Sine and Cosine</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f4f4f4;
        }
        pre {
            background-color: #272822;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        code {
            font-family: "Courier New", monospace;
        }
    </style>
</head>
<body>
    <pre><code>#include &lt;stdint.h&gt;

#define Q16_SHIFT 16
#define Q16_ONE   (1 << Q16_SHIFT)   // 1.0 in Q16.16 format
#define Q16_PI_2  102944             // π/2 ≈ 1.5708 * 2^16

// Coefficients in Q16.16 format
#define Q16_W0  0x00000014  // 1.260e-5 * 2^16 ≈ 0x14
#define Q16_W1  0x0000FFF9  // 0.9996 * 2^16 ≈ 0xFFF9
#define Q16_W2  0x00009438  // 0.002307 * 2^16 ≈ 0x9438
#define Q16_W3  (-0x02CFCF) // -0.1723 * 2^16 ≈ -0x2CFCF
#define Q16_W4  0x000018E4  // 0.006044 * 2^16 ≈ 0x18E4
#define Q16_W5  0x00001796  // 0.005752 * 2^16 ≈ 0x1796

// Q16.16 Fixed-Point Sine Calculation
int32_t q16_sine(int32_t x) {
    int64_t res = Q16_W0;
    res += ((int64_t)Q16_W1 * x) >> Q16_SHIFT;
    res += ((int64_t)Q16_W2 * x >> Q16_SHIFT) * x >> Q16_SHIFT;
    res += ((int64_t)Q16_W3 * x >> Q16_SHIFT) * x >> Q16_SHIFT * x >> Q16_SHIFT;
    res += ((int64_t)Q16_W4 * x >> Q16_SHIFT) * x >> Q16_SHIFT * x >> Q16_SHIFT * x >> Q16_SHIFT;
    res += ((int64_t)Q16_W5 * x >> Q16_SHIFT) * x >> Q16_SHIFT * x >> Q16_SHIFT * x >> Q16_SHIFT * x >> Q16_SHIFT;
    return (int32_t)res;
}

// Q16.16 Fixed-Point Cosine Calculation
int32_t q16_cose(int32_t x) {
    return q16_sine(Q16_PI_2 - x);
}</code></pre>
</body>
</html>
<p>最大误差大约在<strong>0.000128</strong></p >
</p>
<h3>线性插值:</h3>
<p>利用对称性将三角函数的范围约束在[0,90°]， 用查找表分别储存sin(10°)，sin(20°)...sin(80°)以及cos(1°)，cos(2°)...cos(10°)的值，利用和角公式的近似式<br>
```sin(A+B)=sin(A)cos(B)+B \frac{π}{180°}sin(90°-A)```
误差值完全来自sin(B)和B以及cosB的近似误差。</p>
<p>代码如下:</p>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Fixed-Point Sine and Cosine</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f4f4f4;
        }
        pre {
            background-color:rgb(226, 228, 217);
            color: #f8f8f2;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
        code {
            font-family: "Courier New", monospace;
        }
    </style>
</head>
<body>
    <pre><code>#include &lt;stdint.h&gt;
#include &lt;stdint.h&gt;
// 定义 Q16.16 相关宏
#define Q16_SHIFT 16
#define Q16_ONE   (1 << Q16_SHIFT)     // 1.0 = 0x00010000
#define Q16_PI    205887               // π ≈ 3.1415926 × 2^16
#define Q16_2PI   411775               // 2π ≈ 6.2831853 × 2^16
#define Q16_HALFPI 102943              // π/2 ≈ 1.5707963 × 2^16
#define Q16_INVPI  20861               // 1/π ≈ 0.3183099 × 2^16
#define Q16_INV2PI 10430               // 1/2π ≈ 0.1591549 × 2^16

// 预计算 sin_table 和 cos_table (Q16.16 格式)
const int32_t sin_table[] = {
    0,        11308,   22460,   32768,   41793,   49245,   54938,   58702,   60456,   61166
};

const int32_t cos_table[] = {
    Q16_ONE,  65530,   65506,   65453,   65373,   65265,   65130,   64967,   64778,   64562
};

// hollyst = 0.017453292519943295769236907684886 * 2^16
#define Q16_HOLLYST 1144  

int32_t qfsind(int32_t x) {
    int sig = 0;

    // 角度归一化到 [0, 360)
    while (x >= (360 << Q16_SHIFT)) x -= (360 << Q16_SHIFT);
    while (x < 0) x += (360 << Q16_SHIFT);

    // 角度映射到 [0, 180)
    if (x >= (180 << Q16_SHIFT)) {
        sig = 1;
        x -= (180 << Q16_SHIFT);
    }

    // 映射到 [0, 90]
    if (x > (90 << Q16_SHIFT)) x = (180 << Q16_SHIFT) - x;

    // 计算整数部分和小数部分
    int a = (x >> (Q16_SHIFT + 3));  // x / 10（定点）
    int32_t b = x - (a * (10 << Q16_SHIFT)); // 小数部分 b = x - 10a

    // 计算 sin(x) ≈ sin_table[a] * cos_table[b] + b * hollyst * sin_table[9 - a]
    int32_t y1 = (sin_table[a] * cos_table[b >> Q16_SHIFT]) >> Q16_SHIFT;
    int32_t y2 = ((b * Q16_HOLLYST) >> Q16_SHIFT) * sin_table[9 - a];
    int32_t y = y1 + (y2 >> Q16_SHIFT);

    return sig ? -y : y;
}</code></pre>
</body>
</html>
<br>
<p>取为间隔0.01°数据对比，最大误差为0.002980569311522，综合后资源占用如下<br>
<style>
    table {
        width: 50%;
        border-collapse: collapse;
        margin: 20px 0;
        font-size: 18px;
        text-align: left;
    }
    th, td {
        padding: 12px;
        border: 1px solid #ddd;
    }
    th {
        background-color: #f4f4f4;
    }
    tr:hover {
        background-color: #f1f1f1;
    }
</style>

<table>
    <thead>
        <tr>
            <th>资源类型</th>
            <th>估算数量</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><strong>LUT</strong></td>
            <td>10 ~ 40</td>
        </tr>
        <tr>
            <td><strong>DSP 乘法器</strong></td>
            <td>1 ~ 2</td>
        </tr>
        <tr>
            <td><strong>加法器（LUT + FF）</strong></td>
            <td>3 ~ 5</td>
        </tr>
        <tr>
            <td><strong>寄存器（FF）</strong></td>
            <td>150 ~ 200</td>
        </tr>
        <tr>
            <td><strong>MUX（选择逻辑）</strong></td>
            <td>2 ~ 4</td>
        </tr>
    </tbody>
</table>
</p>
<h3>CORDIC算法</h3>
<p>本身是利用收敛的移位操作替代旋转，在修正模长后计算得出正余弦值。</p>
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cordic Sin 计算 (定点数 Q16.16)</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin: 50px; }
        input, button { font-size: 16px; padding: 5px; }
        #result { margin-top: 20px; font-size: 20px; font-weight: bold; }
    </style>
</head>
<body>
    <h2></h2>
    <div id="result"></div>
    
    <script>
        const Q16_SHIFT = 16;
        const Q16_ONE = 1 << Q16_SHIFT;
        const Q16_K = 0x00009B74; // CORDIC 缩放因子 k ≈ 0.60723 (Q16.16)
        
        const cordicAngles = [
            0x002D0000, 0x001AAC5A, 0x000E0F5E, 0x00071687,
            0x00039BBC, 0x0001CE4D, 0x0000E744, 0x00007398,
            0x000039CC, 0x00001CE6, 0x00000E73, 0x00000739
        ];
        
        function normalizeAngle(x) {
            while (x >= (360 << Q16_SHIFT)) x -= (360 << Q16_SHIFT);
            while (x < 0) x += (360 << Q16_SHIFT);
            return x;
        }
        
        function cordicSinQ16(angle) {
            angle = normalizeAngle(angle);
            let x = Q16_ONE;
            let y = 0;
            let z = angle;
            
            for (let i = 0; i < 12; i++) {
                let xNew, yNew;
                if (z >= 0) {
                    xNew = x - (y >> i);
                    yNew = y + (x >> i);
                    z -= cordicAngles[i];
                } else {
                    xNew = x + (y >> i);
                    yNew = y - (x >> i);
                    z += cordicAngles[i];
                }
                x = xNew;
                y = yNew;
            }
            return (y * Q16_K) >> Q16_SHIFT;
        }
        
        function calculateSin() {
            let angleDeg = parseInt(document.getElementById("angle").value, 10);
            let angleQ16 = angleDeg << Q16_SHIFT;
            let sinQ16 = cordicSinQ16(angleQ16);
            let sinFloat = sinQ16 / (1 << Q16_SHIFT);
            document.getElementById("result").innerText = `sin(${angleDeg}°) ≈ ${sinFloat.toFixed(5)}`;
        }
    </script>
</body>
</html>
<!DOCTYPE html>
<html lang="zh">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>硬件资源需求</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; text-align: center; }
        table { width: 50%; margin: 0 auto; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; font-size: 16px; }
        th { background-color: #f4f4f4; }
    </style>
</head>
<body>

<table>
    <tr>
        <th>资源类型</th>
        <th>数量</th>
    </tr>
    <tr>
        <td>查找表 (LUTs)</td>
        <td>120</td>
    </tr>
    <tr>
        <td>触发器 (FFs)</td>
        <td>80</td>
    </tr>
    <tr>
        <td>DSP 块</td>
        <td>2</td>
    </tr>
    <tr>
        <td>块存储器 (BRAM)</td>
        <td>0</td>
    </tr>
    <tr>
        <td>乘法器</td>
        <td>2</td>
    </tr>
    <tr>
        <td>加法/减法单元</td>
        <td>3</td>
    </tr>
</table>

</body>
</html>

