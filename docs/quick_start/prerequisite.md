# 搭建Liquid开发环境

本章介绍使用Liquid进行智能合约开发所需的必要配置，包括：

- 准备Rust编译环境；

- 安装命令行工具cargo-liquid；

- 编译集成Wasm虚拟机的FISCO BCOS节点

- 搭建区块链环境

- 安装合约部署工具

为更好地编写Liquid智能合约，需要您对Rust有基本地了解，可以参考[Rust官方教程](https://doc.rust-lang.org/book/index.html)

```eval_rst
.. admonition:: 注意

首先于网络原因及机器性能，编译过程可能较慢
```

## Rust编译环境

编译Liquid智能合约主要依赖Rust编译器rustc及Rust的构建系统及包管理器Cargo，其中。rustc版本要求 >= 1.46.0，cargo版本要求>= 1.45.1

如果您未安装过rustc及Cargo，如果您是Mac或Linux用户，请在命令行中执行：

```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

安装rustup工具以对rust编译进行管理

如果您是Windows的用户，而可以根据您的操作系统位数从[此处](https://static.rust-lang.org/rustup/dist/i686-pc-windows-msvc/rustup-init.exe)下载32位版本安装程序或从[此处](https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe)下载64位版本安装程序。

如果您安装过rustc及cargo但是版本未达到最低要求，您需要在命令行中执行：

```shell
rustup update
```

安装必要的编译工具链：

```shell
# 目前部分功能需要在迭代更新较快的Nightly版本中才能编译成功
rustup toolchain install nightly
rustup target add wasm32-unknown-unknown --toolchain stable
rustup component add rust-src --toolchain nightly
rustup target add wasm32-unknown-unknown --toolchain nightly
```

安装完毕后，执行以下命令以验证已经正确安装：

```shell
cargo --version
```

```eval_rst
.. admonition:: 注意

所有必要组件安装完毕后，所有的组件都被安装在`./cargo/bin`目录下，包括rustc、cargo、rustup等。为方便使用，需要将`./cargo/bin`加入到系统的`PATH`环境变量中，在安装过程中，rustup会尝试自动配置`PATH`环境变量，但是由
```

```eval_rst
.. admonition:: 注意

为cargo更换源
```

## 命令行工具cargo-liquid

为方便合约开发与编译，Liquid提供了命令行工具cargo-liquid，在命令行中执行以下命令安装：

```shell
cargo install --git https://github.com/vita-dounai/cargo-liquid --force
```

## 编译FISCO BCOS with Wasm

作为实验性功能，需要手动编译FISCO BCOS方能启用Wasm虚拟机，

克隆FISCO BCOS源代码
```shell
cd clone https://github.com/bxq2011hust/FISCO-BCOS-1
```

```shell
cd FISCO-BCOS-1
mkdir build
cmake -DARCH_NATIVE=on ..
make -j4
```

cmake的最小版本

指定build_chain.sh的support version

## SDK部署

Liquid在设计上的ABI与的Solidity一致，因此SDK无需关心链上是Solidity合约或是Liquid合约，为方便部署