# BCOS Wasm合约接口规范

BCOS Wasm合约接口（BCOS Wasm Contract Interface，BWCI）规范用于规范合约中的内容及结构。

## 传输格式

所有的合约必须已[WebAssembly二进制编码](https://github.com/WebAssembly/design/blob/master/BinaryEncoding.md)格式保存即传输，即Wasm格式字节码。

## 导入

合约仅能导入在[BCOS环境接口规范](./bei.html)中定义的符号。所有的符号都需要从名为`bcos`的命名空间中导入，若导入的符号是函数，则函数的签名必须与[BCOS环境接口规范](./bei.html)中所声明的函数签名保持一致。

除了`bcos`命令空间外，还有一个名为`debug`的特殊的命名空间。这个命名空间中所声明的函数的主要用于虚拟机的调试模式，在正式的生产环境中这个命名空间不会被启用。

## 调试模式

调试模式是一种用于调试虚拟机的特殊模式，通过`debug`命名空间为合约提供了一组额外调试接口。但是在正式的生产环境中，若合约字节码尝试从`debug`命名空间中导入符号，则会被拒绝部署。

`debug`命名空间中可用的接口如下：

- `print32(value: i32)`：输出一个`i32`类型的值
- `print64(value: i64)`：输出一个`i64`类型的值
- `printMem(offset: i32, len: i32)`：以可打印字符形式输出虚拟机中一段内存区域中的内容，其中`offset`为该内存区域的起始地址，`len`为该内存区域的长度
- `printMemHex(offset: i32, len: i32)`：以16进制字符串的形式输出虚拟机中一段内存区域中的内容，其中`offset`为该内存区域的起始地址，`len`为该内存区域的长度

## 导出

合约必须恰好导出3个符号：

- `memory`：共享内存，用于提供给[BCOS环境接口规范](./bei.html)中的接口向其中写入数据。
- `deploy`：用于调用合约构造函数的函数，无参数且无返回值。
- `main`：用于处理合约交易的函数，无参数且无返回值。

## 合约入口

当执行交易时，虚拟机会调用合约字节码中的`main`函数，由`main`函数负责实现读入交易输出、合约方法分发等逻辑。当交易成功执行时，`main`函数正常退出，否则`main`函数调用[BCOS环境接口规范](./bei.html)中的`revert`函数回滚交易并向宿主环境报告错误原因。

## Start function

合约字节码中不允许存在[start function](https://webassembly.github.io/spec/core/syntax/modules.html#start-function)，这是由于宿主环境必须要在合约字节码执行前就获取虚拟机所使用的内存空间的访问权限，而start function会在虚拟机载入合约字节码时自动执行，导致此时宿主环境无法及时获取虚拟机提供的共享内存的访问权限。

## Traps

如果合约的执行过程中触发了Wasm的`trap`（如执行了`unreachable`指令、共享内存访问越界等），则合约的执行会立即终止。
