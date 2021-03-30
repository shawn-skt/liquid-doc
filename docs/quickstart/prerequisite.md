# 环境配置

```eval_rst
.. admonition:: 注意

   受限于网络情况及机器性能，本小节中部分依赖项的安装过程可能较为耗时，请耐心等待。必要时可能需要配置网络代理。
```

## 部署 Rust 编译环境

Liquid 智能合约的构建过程主要依赖 Rust 语言编译器`rustc`及代码组织管理工具`cargo`，且均要求版本号大于或等与 1.50.0。如果此前从未安装过`rustc`及`cargo`，可参考下列步骤进行安装：

-   对于 Mac 或 Linux 用户，请在终端中执行以下命令；

    ```shell
    # 此命令将会自动安装 rustup，rustup 会自动安装 rustc 及 cargo
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```

-   对于 32 位 Windows 用户，请从[此处](https://static.rust-lang.org/rustup/dist/i686-pc-windows-msvc/rustup-init.exe)下载安装 32 位版本安装程序。

-   对于 64 位 Windows 用户，请从[此处](https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe)下载安装 64 位版本安装程序。

如果此前安装过`rustc`及`cargo`，但是未能最低版本要求，则可在终端中执行以下命令进行更新：

```shell
rustup update
```

安装完毕后，分别执行以下命令验证已安装正确版本的 `rustc` 及 `cargo`：

```shell
rustc --version
cargo --version
```

此外需要安装以下工具链组件：

```shell
rustup toolchain install nightly
rustup target add wasm32-unknown-unknown --toolchain stable
rustup target add wasm32-unknown-unknown --toolchain nightly
rustup component add rust-src --toolchain stable
rustup component add rust-src --toolchain nightly
```

```eval_rst
.. admonition:: 注意

   由于Liquid使用了少量目前尚不稳定的Rust语言特性，因此在构建时需要依赖nightly版本的 ``rustc`` 。但是这些特性目前已经被广泛应用在Rust项目中，因此其可靠性值得信赖。随着Rust语言迭代演进，这些特性终将变为稳定特性。
```

```eval_rst
.. admonition:: 注意

   所有可执行程序都会被安装于 ``$HOME/cargo/bin`` 目录下，包括 ``rustc`` 、 ``cargo`` 及 ``rustup`` 等。为方便使用，需要将 ``$HOME/cargo/bin`` 目录加入到操作系统的 ``PATH`` 环境变量中。在安装过程中， ``rustup`` 会尝试自动配置 ``PATH`` 环境变量，但是由于权限等原因，该过程可能会失败。当发现 ``rustc`` 或 ``cargo`` 无法正常执行时，可能需要手动配置该环境变量。
```

```eval_rst
.. admonition:: 注意

   如果当前网络无法访问Rustup官方镜像，请参考 `Rustup 镜像安装帮助 <https://mirrors.tuna.tsinghua.edu.cn/help/rustup/>`_ 更换镜像源。
```

构建 Liquid 智能合约的过程中需要下载大量第三方依赖，若当前网络无法正常访问 crates.io 官方镜像源，则按照以下步骤为 `cargo` 更换镜像源：

```shell
# 编辑cargo配置文件，若没有则新建
vim $HOME/.cargo/config
```

并在配置文件中添加以下内容：

```ini
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'ustc'
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"
```

## 安装 cargo-liquid

`cargo-liquid` 是用于辅助开发 Liquid 智能合约的命令行工具，在终端中执行以下命令安装：

```shell
cargo install --git https://github.com/WeBankBlockchain/cargo-liquid --tag v1.0.0-rc1 --force
```

```eval_rst
.. admonition:: 注意

   若无法正常访问GitHub，则请执行 ``cargo install --git https://gitee.com/WeBankBlockchain/cargo-liquid --tag v1.0.0-rc1 --force`` 命令进行安装。
```

## 安装 Binaryen（可选）

Binaryen 项目中包含了一系列 Wasm 字节码分析及优化工具，其中如 `wasm-opt` 等工具会在 Liquid 智能合约的构建过程中使用。目前 Binaryen 仅提供了编译安装的方式，请参考其[官方文档](https://github.com/WebAssembly/binaryen#building)，根据所使用的操作系统选择对应的编译安装方式。
