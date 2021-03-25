# 简介

当使用区块链上的智能合约管理资产时，我们希望合约语言保证资产能够被灵活管理的同时安全的转移。liquid 提供一种安全的资产模型，允许用户定义资产类型，资产类型模拟现实中资产的行为，提供一系列安全特性，包括用户声明的资产类型在 liquid 合约中不可以被复制、代码块中的资产实例在生命周期结束前必须被存储到某个账户、资产存储在用户的账户内、自带溢出检查。

# 资产类型声明

Liquid 线性资产模型提供合约中资产的定义语法，用户在合约中定义资产后，liquid 自动解析用户定义的资产名、资产类型、发行者、描述信息、发行总量等属性，为用户生成资产类型定义、资产类型内置接口、资产注册调用代码、合约支持的资产接口的 Rust 代码。使用方式如下：

```rust
#[liquid(asset(
        issuer = "0x83309d045a19c44dc3722d15a6abd472f95866ac", // 发行者的账户地址
        fungible = true,
        total = 1000000000,
        description = "资产描述"
    ))]
struct SomeAsset;
```

-   结构体 SomeAsset 上的#[liquid(asset(…))]用于声明结构体是资产类型，声明为资产类型的结构体不需要有定义
-   issuer 指定资产类型 Erc20Token 的发行者，只有发行者有权限发行新的 Erc20Token 资产
-   total 指定资产发行的总量，用户不指定则默认为 64 位无符号整数的最大值
-   fungible 表示资产是否是同质资产，true 表示同质资产，false 表示非同质资产，用户不指定则默认为 true
-   description 是对资产类型的描述
-   合约中可以声明多种资产类型
-   同质资产只有数值的不同，非同质资产代表某种唯一的、不可替代的商品。

# 代码生成

## 同质资产

当用户声明资产类型时，fungible 为 true，则表明该资产类型是同质资产类型，同质资产类型提供下述接口。

-   total_supply
    签名：`pub fn total_supply() -> bool;`
    功能：获取资产总发行量
-   issuer
    签名：`pub fn issuer() -> address;`
    功能：获取发行者账户地址
-   description
    签名：`pub fn description() -> &'a str;`
    功能：获取资产描述信息
-   balance_of
    签名：`pub fn balance_of(owner: &address) -> u64;`
    功能：获取某个账户中此资产的总量
-   issue_to
    签名：`pub fn issue_to(to: &address, amount: u64) -> bool;`
    功能：为某个充值资产，只有签发者账号可操作
-   withdraw_from_caller
    签名：`pub fn withdraw_from_caller(amount: u64) -> Option<Self>;`
    功能：从调用者账户中取出资产，构造相应的对象
-   withdraw_from_self
    签名：`pub fn withdraw_from_self(amount: u64) -> Option<Self>;`
    功能：从合约账户中取出资产，构造相应的对象
-   value
    签名：`pub fn value(&self) -> u64;`
    功能：获取某个资产对象的值
-   deposit
    签名：`pub fn deposit(mut self, to: &address);`
    功能：将资产存储到某个账户中，资产生命周期结束前，必须调用此函数

## 非同质资产

当用户声明资产类型时，fungible 为 false，则表明该资产类型是非同质资产类型。

-   total_supply
    签名：`pub fn total_supply() -> bool;`
    功能：获取资产总发行量
-   issuer
    签名：`pub fn issuer() -> address;`
    功能：获取发行者账户地址
-   description
    签名：`pub fn description() -> &'a str;`
    功能：获取资产描述信息
-   balance_of
    签名：`pub fn balance_of(owner: &address) -> u64;`
    功能：获取某个账户中此资产的总个数
-   tokens_of
    签名：`pub fn tokens_of(owner: &address) -> Vec<u64>;`
    功能：获取某个账户中所有此种资产的 id
-   issue_to
    签名：`pub fn issue_to(to: &address, amount: u64) -> bool;`
    功能：为某个充值资产，只有签发者账号可操作
-   withdraw_from_caller
    签名：`pub fn withdraw_from_caller(id: u64) -> Option<Self>;`
    功能：从调用者账户中取出资产，构造相应的对象
-   withdraw_from_self
    签名：`pub fn withdraw_from_self(id: u64) -> Option<Self>;`
    功能：从合约账户中取出资产，构造相应的对象
-   uri
    签名：`pub fn uri(&self) -> &String;`
    功能：获取资产对象的 uri
-   id
    签名：`pub fn id(&self) -> u64;`
    功能：获取资产对象的 id
-   deposit
    签名：`pub fn deposit(mut self, to: &address);`

# 使用举例

## 声明资产

资产类型的声明需要在合约的 mod 中，用户只需要定义资产所需的属性和类型名，由 liquid 生成资产类型的实现和方法。资产类型由名称区分，在链上唯一，重复声明同名资产类型会导致合约回滚。资产类型声明后，由发行者通过资产的发行借口发行到不同账户，每个账户的状态空间中会存储资产的相关信息。

下面的代码演示在合约中声明一个资产类型，合约中支持用户声明多个资产类型。

```rust
mod contract {
    use liquid_lang::storage;

    /// Defines the storage of your contract.
    #[liquid(storage)]
    struct Contract {
        allowances: storage::Mapping<(address, address), u64>,
    }

    #[liquid(asset(
            issuer = "发行者的账户地址",
            fungible = true,
            total = 1000000000,
            description = "资产描述"
        ))]
    struct SomeAsset;
    #[liquid(methods)]
    impl Contract {
     // ...省略
    }
}
```

## 合约中构造资产对象

资产类型提供`withdraw_from_caller`和`withdraw_from_self`两个方法用于构造资产类型的实例，`withdraw_from_caller`会从调用者的账户中构造资产实例，如果调用者账户中的此类资产不足，则构造失败。`withdraw_from_self`从合约账户自身构造资产类型，如果合约中的此类资产不足则构造失败。

```rust
let amount = 500;
if let Some(token) == SomeAsset::withdraw_from_caller(amount) {
    //do something
} else{
    // process error
}
```

## 资产实例的销毁

为保证资产实例不能被随意丢弃，资产实例的生命周期结束之前，必须妥善的将资产实例存储到某个账户中，否则会导致交易会滚。

```rust
let amount = 500;
let recipient:address = "0x11111".parse().unwrap();
if let Some(token) == SomeAsset::withdraw_from_self(amount) {
    //do something
    token.deposit(&recipient);
} else{
    // process error
}
```

## 查询资产相关信息

资产类型提供一系列查询接口，方便用户查询资产相关信息。

```rust
let total = SomeAsset::total_supply();
let user : address = "0x11112".parse().unwrap();
let balance = SomeAsset::balance_of(user);
let description = SomeAsset::description().into();
let issuer = SomeAsset::issuer();
```

## 合约托管资产

为方便用户对资产的灵活操作，用户可以将其持有的资产转给某个合约，由合约逻辑来管理资产。如下的例子，可以允许用户将自己的 SomeAsset 资产授权给其他用户使用。

```rust
mod contract {
    use liquid_lang::storage;

    /// Defines the storage of your contract.
    #[liquid(storage)]
    struct Contract {
        allowances: storage::Mapping<address, u64>,
        owner: storage::Value<address>,
    }

    #[liquid(asset(
            issuer = "发行者的账户地址", fungible = true,
            total = 1000000000, description = "资产描述"
        ))]
    struct SomeAsset;
    #[liquid(methods)]
    impl Contract {
        pub fn new(&mut self, owner: address) {
            self.allowances.initialize();
            self.owner.initialize(owner);
        }
        pub fn approve(&mut self, spender: address, amount: u64) -> bool {
            match SomeAsset::withdraw_from_caller(amount) {
                None => false,
                Some(token) => {
                    token.deposit(&self.env().get_address());
                    let caller = self.env().get_caller();
                    let allowance =
                        *self.allowances.get(&spender).unwrap_or(&0);
                    self.allowances
                        .insert(&spender, allowance + amount);
                    true
                }
            }
        }
        pub fn transfer(
            &mut self,
            recipient: address,
            amount: u64,
        ) -> bool {
            let caller = self.env().get_caller();
            let allowance = *self.allowances.get(&caller).unwrap_or(&0);
            if allowance >= amount {
                self.allowances.insert(&caller, allowance - amount);
                return match SomeAsset::withdraw_from_self(amount) {
                    None => false,
                    Some(token) => {
                        token.deposit(&recipient);
                        true
                    }
                };
            }
            false
        }
    }
}
```
