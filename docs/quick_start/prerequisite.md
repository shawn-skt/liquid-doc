# 搭建开发环境

本节介绍使用Liquid进行智能合约开发所需的必要配置。

```eval_rst
.. admonition:: 注意

   受限于您使用的网络的情况及机器的性能，部分组件的编译过程可能较为耗时，请耐心等待，必要时您可能需要为您的网络配置代理。
```

## 部署Rust编译环境

Liquid智能合约的编译主要依赖rustc（Rust语言编译器）及cargo（Rust语言的包管理器及构建系统)。其中，rustc的版本需要大于等于1.46.0、cargo的版本需要大于等于1.45.1。

- 如果您从未在您的机器上安装rustc及cargo：

  - 如果您是Mac或Linux用户，请在命令行中执行以下命令：

    ```bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```

    此命令将会自动安装rustup工具，rustup会自动为您安装rustc及cargo。

  - 如果您是32位Windows用户，请访问[此处](https://static.rust-lang.org/rustup/dist/i686-pc-windows-msvc/rustup-init.exe)下载安装32位版本安装程序。

  - 如果您是64位Windows用户，请访问[此处](https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe)下载安装64位版本安装程序。

- 如果您在您的机器上安装过rustc及cargo，但是版本未达到最低要求，则请在命令行中执行以下命令更新rustc及cargo：

  ```bash
  rustup update
  ```

此外，还需要安装以下组件，以使rustc能够将Liquid合约代码编译Wasm格式字节码：

```bash
rustup toolchain install nightly
rustup target add wasm32-unknown-unknown --toolchain stable
rustup target add wasm32-unknown-unknown --toolchain nightly
rustup component add rust-src --toolchain stable
rustup component add rust-src --toolchain nightly
```

```eval_rst
.. admonition:: 注意

   由于Liquid的用到了少量尚不稳定的Rust语言特性，因此在构建Liquid合约时需要依赖nightly版本的rustc。但是请您放心，这些特性已经被广泛使用在Rust社区中，因此其可靠性值得信赖。随着rust版本迭代演进，这些特性终会变为稳定特性。
```

安装完毕后，执行以下命令以验证rustc及cargo已正确安装：

```bash
rustc --version
cargo --version
```

```eval_rst
.. admonition:: 注意

   所有可执行程序都会被安装于`$HOME/cargo/bin`目录下，包括rustc、cargo及rustup等。为方便使用，您需要将`$HOME/cargo/bin`目录加入到系统的`PATH`环境变量中。在安装过程中，rustup会尝试自动配置`PATH`环境变量，但是由于权限或平台特性不同的原因，自动配置可能会失败。当您发现rustc或cargo无法正常执行时，您可能需要手动配置该环境变量。
```

编译Liquid合约的过程中需要下载大量依赖，若您使用的网络无法正常访问crates.io官方镜像，请为cargo更换源：

```bash
# 编辑cargo配置文件，若没有则新建
vim $HOME/.cargo/config
```

在配置文件中添加以下内容，将cargo源更换为中科大镜像：

```ini
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'ustc'
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"
```

## 命令行工具cargo-liquid

为方便合约开发与编译，Liquid提供了命令行工具cargo-liquid，在命令行中执行以下命令安装：

```bash
cargo install --git https://github.com/vita-dounai/cargo-liquid --force
```

## 编译FISCO BCOS

FISCO BCOS对Wasm虚拟机的支持目前尚未合入主干版本，因此启用Wasm虚拟机需要手动编译FISCO BCOS源码。

在命中行中执行克隆FISCO BCOS源代码：

```bash
git clone https://github.com/bxq2011hust/FISCO-BCOS-1
```

编译FISCO BCOS：

```bash
cd FISCO-BCOS-1
git checkout dev-hera
mkdir build && cd build
cmake ..
make -j4
```

编译过程中还会包含对hera及wasmer项目的编译，因此耗时相对于编译常规FISCO BCOS源码较长，请耐心等待。编译完成后，带Wasm虚拟机FISCO BCOS二进制程序会存放于`FISCO-BCOS-1/build/bin`目录下。

## 建链

建链方式可参考一键建链工具[build_chain.sh](https://fisco-bcos-documentation.readthedocs.io/zh_CN/latest/docs/installation.html#)。需要注意的是，建链过程中务必不要使用build_chain.sh自动下载的FISCO BCOS二进制程序，而应当使用`-e`选项来指定使用上一步中我们手动编译出的FISCO BCOS二进制程序，同时，需要使用`-v`选项指定兼容版本号大于等于2.6.0。关于build_chain.sh及相关选项的使用方式请参考上述文档链接。

## 部署Node.js SDK

目前仅有FISCO BCOS Node.js SDK提供的CLI命令行工具支持以Wasm字节码格式的形式部署合约，因此，需要您在本地部署该SDK。部署方式可参考[Node.js SDK文档](https://github.com/FISCO-BCOS/nodejs-sdk/blob/master/README.md)。但需要注意的是，部署Wasm字节码合约功能同样未合入主干版本。因此在部署过程中，当您克隆了Node.js SDK的源码后，需要手动切换到`wasm`分支，即按照如下方式操作：

```bash
# 下列步骤来自于https://github.com/FISCO-BCOS/nodejs-sdk/blob/master/README.md#%E4%BA%8Ccli%E5%B7%A5%E5%85%B7
git clone https://github.com/FISCO-BCOS/nodejs-sdk.git
cd nodejs-sdk
# 注意！需要添加这一步
git checkout wasm
...
```

关于如何使用Node.js SDK提供的CLI命令行工具部署Liquid合约，我们将在下一节**基本开发流程**中进行介绍。


## 安装Binaryen

Binaryen项目中包含一系列有用的Wasm字节码分析及优化工具，其中有些工具（如`wasm-opt`等）对于构建Liquid合约极为重要。目前Binaryen进仅提供了编译安装的方式，请参考其[官方文档](https://github.com/WebAssembly/binaryen#building)，根据您所使用的操作系统平台选择相应的编译安装方式。
