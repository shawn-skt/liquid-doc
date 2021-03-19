# 状态变量与容器

状态变量用于在区块链存储上永久存储状态值，是 Liquid 合约重要的组成部分。在[HelloWorld 合约](../quickstart/example.html#id3)中，我们已经初步接触了状态变量的定义方式及容器的使用方式。 在 Liquid 合约中，状态变量与容器的关系极为密切，我们将在本节中分别对两者进行介绍。

## 状态变量

Liquid 中使用结构体语法（`struct`）对状态变量定义进行封装，并且该结构体需要使用`liquid(storage)`属性进行标注，以告知 Liquid 该结构体中包含了状态变量的定义，例如：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   #[liquid(storage)]
   struct HelloWorld {
       name: storage::Value<String>,
   }
```

在上述代码中可以看出，结构体中每个成员各自对应一个状态变量的定义。状态变量的名称位于冒号`:`的左侧，而类型位于右侧，状态变量定义之间使用英语逗号`,`分隔。虽然在合约的设计上，状态变量`name`的实际类型应当为`String`，但是在定义时需要实际类型包裹于容器类型`storage::Value`中。之所以要使用容器类型，是因为状态变量实际上是区块链存储系统某一存储位置的引用，对状态变量的读取、写入都需要转化为对区块链存储系统的读取、写入，这是状态变量区别于其他普通变量最重要的差异。容器是连接智能合约与区块链底层平台的桥梁，Liquid 通过容器替封装了区块链存储系统的访问细节，使得能够像使用普通变量一般使用状态变量。若没有使用容器封装状态变量的实际类型，将会引发编译时报错，例如：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 3

   #[liquid(storage)]
   struct HelloWorld {
       name: String,
   }
```

</div>

所有容器的定义均位于`liquid_lang`库的`storage`模块中，需要预先引入该模块：

```eval_rst
.. code-block:: rust
   :linenos:

   use liquid_lang as liquid;
   use liquid::storage;
```

用于封装状态变量定义的结构体在合约中能且仅能出现一次，因此不能将状态变量定义分散在不同的、用`#[liquid(storage)]`属性标注的结构体中：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 8-11

   #[liquid::contract]
   mod hello_world {
       #[liquid(storage)]
       struct HelloWorld {
           ...
       }

       #[liquid(storage)]
       struct Another {
           ...
       }
   }
```

</div>

被`#[liquid(storage)]`属性标注的结构体中至少需要一个状态变量定义，因此不能将其定义为[unit 类型](https://doc.rust-lang.org/std/primitive.unit.html)；同时，由于每个状态变量均需要一个有效的名称，也不能将其定义为[元组类型](https://doc.rust-lang.org/stable/rust-by-example/primitives/tuples.html)。此外，不能为被`#[liquid(storage)]`属性标的结构体声明任何模板参数，即不能在该结构体中使用泛型，也不能为其添加任何可见性声明。下列代码了展示部分错误的使用方式：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 3, 7, 11, 17

   // Unit is not allowed.
   #[liquid(storage)]
   struct HelloWorld();

   // Tuple is not allowed.
   #[liquid(storage)]
   struct HelloWorld(u8, u32);

   // Generic is not allowed.
   #[liquid(storage)]
   struct HelloWorld<T, E> {
       ...
   }

   // Visibility is not allowed.
   #[liquid(storage)]
   pub struct HelloWorld {
       ...
   }
```

</div>

但是可以在状态变量的定义之前添加`pub`可见性声明：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 3

   #[liquid(storage)]
   pub struct HelloWorld {
       pub name: storage::Value<String>,
   }
```

`pub`可见性代表外界可以直接访问该状态变量，Liquid 会自动为此类状态变量生成一个公开的访问器。关于访问器的更多细节可参考[合约方法](./method.html#id8)一节。但是除了`pub`可见性以外，其他种类的可见性声明均不能使用。

## 容器

Liquid 中的容器包括单值容器（`Value`）、向量容器（`Vec`）、映射容器（`Mapping`）及可迭代映射容器（`IterableMapping`)。

```eval_rst
.. admonition:: 注意

   Liquid中所有容器均没有实现拷贝语义，因此无法拷贝容器。同时，Liquid限制了您不能移动容器的所有权，因此在合约中只能通过引用的方式使用容器。
```

### 单值容器

单值容器的类型定义为`Value<T>`。当状态变量类型定义为单值容器时，可以像使用普通变量一般使用该状态变量。使用单值容器时需要通过模板参数传入状态变量的实际类型，如`Value<bool>`、`Value<String>`等。基本容器提供下列方法：

<ul class="method-introduction">
<li>

```rust
pub fn initialize(&mut self, input: T)
```

</li>
<p>

用于在合约构造函数中使用提供的初始值初始化单值容器。此方法应当只在构造函数中使用，且只使用一次。若状态变量初始化后再次调用`initialize`方法将不会产生任何效果。

</p>
<li>

```rust
pub fn set(&mut self, new_val: T)
```

</li>
<p>

用一个新的值更新状态变量的值。

</p>
<li>

```rust
pub fn mutate_with<F>(&mut self, f: F) -> &T
where
    F: FnOnce(&mut T),
```

</li>
<p>

允许传入一个用于修改状态变量的函数，在修改完状态变量后，返回状态变量的引用。当状态变量未初始化时，调用`mutate_with`会引发运行时异常并导致交易回滚。

</p>
<li>

```rust
pub fn get(&self) -> &T
```

</li>
<p>

返回状态变量的只读引用。

</p>
<li>

```rust
pub fn get_mut(&mut self) -> &mut T
```

</li>
<p>

返回状态变量的可变引用，可以通过该可变引用直接修改状态变量的值。

</p>
</ul>

除了上述基本接口外，单值容器还通过实现`core::ops`中的运算符 trait，对大量的运算符进行了重载，从而能够直接使用容器进行运算。单值容器重载的运算符包括：

```eval_rst
.. list-table::
   :widths: 15 10 15 60
   :header-rows: 1

   * - 运算符
     - trait
     - 功能
     - 备注
   * - \*
     - Deref
     - 解引用
     - 通过容器的只读引用返回 ``&T`` ，借助 Rust 语言的 `解引用强制多态 <https://doc.rust-lang.org/reference/type-coercions.html>`_ ，可以像操作普通变量那样操单值容器。例如：若状态变量 ``name`` 的类型为 ``Value<String>``，如需获取 ``name`` 的长度，则可以直接使用 ``name.len()``
   * - \*
     - DerefMut
     - 解引用
     - 通过容器的可变引用返回 ``&mut T``
   * - \+
     - Add
     - 加
     - 需要 ``T`` 自身支持双目 ``+`` 运算，例如：若状态变量 ``len`` 的类型为 ``Value<u8>``，则可以直接使用 ``len + 1``
   * - \+=
     - AddAssign
     - 加并赋值
     - 需要 ``T`` 自身支持 ``+=`` 运算
   * - \-
     - Sub
     - 减
     - 需要 ``T`` 自身支持双目 ``-`` 运算
   * - \-=
     - SubAssign
     - 减并赋值
     - 需要 ``T`` 自身支持 ``-=`` 运算
   * - \*
     - Mul
     - 乘
     - 需要 ``T`` 自身支持 ``*`` 运算
   * - \*=
     - MulAssign
     - 乘并赋值
     - 需要 ``T`` 自身支持 ``*=`` 运算
   * - /
     - Div
     - 除
     - 需要 ``T`` 自身支持 ``/`` 运算
   * - /=
     - DivAssign
     - 除并赋值
     - 需要 ``T`` 自身支持 ``/=`` 运算
   * - %
     - Rem
     - 求模
     - 需要 ``T`` 自身支持 ``%`` 运算
   * - %=
     - RemAssign
     - 求模并赋值
     - 需要 ``T`` 自身支持 ``%=`` 运算
   * - &
     - BitAnd
     - 按位与
     - 需要 ``T`` 自身支持 ``&`` 运算
   * - &=
     - BitAndAssign
     - 按位与并赋值
     - 需要 ``T`` 自身支持 ``&=`` 运算
   * - \|
     - BitOr
     - 按位或
     - 需要 ``T`` 自身支持 ``|`` 运算
   * - \|=
     - BitOrAssign
     - 按位或并赋值
     - 需要 ``T`` 自身支持 ``|=`` 运算
   * - ^
     - BitXor
     - 按位异或
     - 需要 ``T`` 自身支持 ``^`` 运算
   * - ^=
     - BitXorAssign
     - 按位异或并赋值
     - 需要 ``T`` 自身支持 ``^=`` 运算
   * - <<
     - Shl
     - 左移
     - 需要 ``T`` 自身支持 ``<<`` 运算
   * - <<=
     - ShlAssign
     - 左移并赋值
     - 需要 ``T`` 自身支持 ``<<=`` 运算
   * - >>
     - Shr
     - 右移
     - 需要 ``T`` 自身支持 ``>>`` 运算
   * - >>=
     - ShrAssign
     - 右移并赋值
     - 需要 ``T`` 自身支持 ``>>=`` 运算
   * - \-
     - Neg
     - 取负
     - 需要 ``T`` 自身支持单目 ``-`` 运算
   * - !
     - Not
     - 取反
     - 需要 ``T`` 自身支持 ``!`` 运算
   * - []
     - Index
     - 下标运算
     - 需要 ``T`` 自身支持按下标进行索引
   * - []
     - IndexMut
     - 下标运算
     - 同上，但是用于可变引用上下文中
   * -  ==、!=、>、>=、<、<=
     - PartialEq、PartialOrd、Ord
     - 比较运算
     - 需要 ``T`` 自身支持相应的比较运算
```

### 向量容器

向量容器的类型定义为`Vec<T>`。当状态变量类型为向量容器时，可以像使用动态数组一般的方式使用该状态变量。在向量容器中，所有元素按照严格的线性顺序排序，可以通过元素在序列中的位置访问对应的元素。使用向量容器时需要通过模板参数传入元素的实际类型，如`Vec<bool>`、`Vec<String>`等。向量容器提供下列方法：

<ul class="method-introduction">
<li>

```rust
pub fn initialize(&mut self)
```

</li>
<p>

用于在构造函数中初始化向量容器。若向量容器初始化后再调用`initialize`接口，则不会产生任何效果。

</p>
<li>

```rust
pub fn len(&self) -> u32
```

</li>
<p>

返回向量容器中元素的个数。

</p>
<li>

```rust
pub fn is_empty(&self) -> bool
```

</li>
<p>

检查向量容器是否为空。

</p>
<li>

```rust
pub fn get(&self, n: u32) -> Option<&T>
```

</li>
<p>

返回向量容器中第`n`个元素的只读引用。若`n`越界，则返回`None`。

</p>
<li>

```rust
pub fn get_mut(&mut self, n: u32) -> Option<&mut T>
```

</li>
<p>

返回向量容器中第`n`个元素的可变引用。若`n`越界，则返回`None`。

</p>
<li>

```rust
pub fn mutate_with<F>(&mut self, n: u32, f: F) -> Option<&T>
where
    F: FnOnce(&mut T),
```

</li>
<p>

允许传入一个用于修改向量容器中第`n`个元素的值的函数，在修改完毕后，返回该元素的只读引用。若`n`越界，则返回`None`。

</p>
<li>

```rust
pub fn push(&mut self, val: T)
```

</li>
<p>

向向量容器的尾部插入一个新元素。当插入前向量容器的长度等于 2<sup>32</sup> - 1 时，引发 panic。

</p>
<li>

```rust
pub fn pop(&mut self) -> Option<T>
```

</li>
<p>

移除向量容器的最后一个元素并将其返回。若向量容器为空，则返回`None`。

</p>
<li>

```rust
pub fn swap(&mut self, a: u32, b: u32)
```

</li>
<p>

交换向量容器中第`a`个及第`b`个元素。若`a`或`b`越界，则引发 panic。

</p>
<li>

```rust
pub fn swap_remove(&mut self, n: u32) -> Option<T>
```

</li>
<p>

从向量容器中移除第`n`个元素，并将最后一个元素移动至第`n`个元素所在的位置，随后返回被移除元素的引用。若`n`越界，则返回`None`；若第`n`个元素就是向量容器中的最后一个元素，则效果等同于`pop`接口。

</p>
</ul>

同时，向量容器实现了以下 trait：

<ul class="method-introduction">
<li>

```rust
impl<T> Extend<T> for Vec<T>
{
    fn extend<I>(&mut self, iter: I)
    where
        I: IntoIterator<Item = T>;
}
```

</li>
<p>

按顺序遍历迭代器，并将迭代器所访问的元素依次插入到向量容器的尾部。

</p>
<li>

```rust
impl<'a, T> Extend<&'a T> for Vec<T>
where
    T: Copy + 'a,
{
    fn extend<I>(&mut self, iter: I)
    where
        I: IntoIterator<Item = &'a T>;
}
```

</li>
<p>

按顺序遍历迭代器，并将迭代器所访问的元素依次插入到向量容器的尾部。

</p>

<li>

```rust
impl<T> core::ops::Index<u32> for Vec<T>
{
    type Output = T;

    fn index(&self, index: u32) -> &Self::Output;
}
```

</li>
<p>

使用下标对序列中的任意元素进行快速直接访问，下标的类型为`u32`，返回元素的只读引用。若下标越界，则会引发运行时异常并导致交易回滚。

</p>
<li>

```rust
impl<T> core::ops::IndexMut<u32> for Vec<T>
{
    fn index_mut(&mut self, index: u32) -> &mut Self::Output;
}
```

</li>
<p>

使用下标对序列中的任意元素进行快速直接访问，下标的类型为`u32`，返回元素的可变引用。若下标越界，则会引发运行时异常并导致交易回滚。

</p>
</ul>

向量容器支持迭代。在迭代时，需要先调用向量容器的`iter`方法生成迭代器，并配合`for ... in ...`等语法完成对向量容器的迭代，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 10

   #[liquid(storage)]
   struct Sum {
       value: storage::Vec<u32>,
   }

   ...

   pub fn sum(&self) -> u32 {
       let mut ret = 0u32;
       for elem in self.value.iter() {
           ret += elem;
       }
       ret
   }
```

```eval_rst
.. admonition:: 注意

   向量容器的长度并不能无限增长，其上限为2 \ :sup:`32` - 1（4294967295，约为42亿）。
```

### 映射容器

映射容器的类型定义为`Mapping<K, V>`。映射容器是键值对集合，当状态变量类型为映射容器时，能够通过键来获取一个值。使用映射容器时需要通过模板参数传入键和值的实际类型，如`Mapping<u8, bool>`、`Mapping<String, u32>`等。映射容器提供下列方法：

<ul class="method-introduction">
<li>

```rust
pub fn initialize(&mut self)
```

</li>
<p>

用于在构造函数中初始化映射容器。若映射容器初始化后再调用`initialize`接口，则不会产生任何效果。

</p>
<li>

```rust
pub fn len(&self) -> u32
```

</li>
<p>

返回映射容器中元素的个数。

</p>
<li>

```rust
pub fn is_empty(&self) -> bool
```

</li>
<p>

检查映射容器是否为空。

</p>
<li>

```rust
pub fn insert<Q>(&mut self, key: &Q, val: V) -> Option<V>
```

</li>
<p>

</p>
<p>

向映射容器中插入一个由`key`、`val`组成的键值对，注意`key`的类型为一个引用。当`key`在之前的映射容器中不存在时，返回`None`；否则返回之前的`key`所对应的值。

</p>
<li>

```rust
pub fn mutate_with<Q, F>(&mut self, key: &Q, f: F) -> Option<&V>
where
    K: Borrow<Q>,
    F: FnOnce(&mut V),
```

</li>

<p>

允许传入一个用于修改映射容器中`key`所对应的值的函数，在修改完毕后，返回值的只读引用。若`key`在映射容器中不存在，则返回`None`。

</p>
<li>

```rust
pub fn remove<Q>(&mut self, key: &Q) -> Option<V>
where
    K: Borrow<Q>,
```

</li>
<p>

从映射容器中移除`key`及对应的值，并返回被移除的值。若`key`在映射容器中不存在，则返回`None`。

</p>
<li>

```rust
pub fn get<Q>(&self, key: &Q) -> Option<&V>
```

</li>
<p>

返回映射容器中`key`所对应的值的只读引用。若`key`在映射容器中不存在，则返回`None`。

</p>
<li>

```rust
pub fn get_mut<Q>(&mut self, key: &Q) -> Option<&mut V>
```

</li>
<p>

返回映射容器中`key`所对应的值的可变引用。若`key`在映射容器中不存在，则返回`None`。

</p>
<li>

```rust
pub fn contains_key<Q>(&self, key: &Q) -> bool
```

</li>
<p>

检查`key`在映射容器中是否存在。

</p>
</ul>

同时，映射容器实现了以下 trait：

<ul>
<li>

```rust
impl<K, V> Extend<(K, V)> for Mapping<K, V>
{
    fn extend<I>(&mut self, iter: I)
    where
        I: IntoIterator<Item = (K, V)>;
}
```

</li>
<p>

按顺序遍历迭代器，并将迭代器所访问的键值对依次插入到映射容器中。

</p>
<li>

```rust
impl<'a, K, V> Extend<(&'a K, &'a V)> for Mapping<K, V>
where
    K: Copy,
    V: Copy,
{
    fn extend<I>(&mut self, iter: I)
    where
        I: IntoIterator<Item = (&'a K, &'a V)>;
}

```

</li>
<p>

按顺序遍历迭代器，并将迭代器所访问的键值对依次插入到映射容器中。

</p>
<li>

```rust
impl<'a, K, Q, V> core::ops::Index<&'a Q> for Mapping<K, V>
where
    K: Borrow<Q>,
{
    type Output = V;

    fn index(&self, index: &'a Q) -> &Self::Output;
}

```

</li>
<p>

以键为索引访问映射容器中对应的值，索引类型为`&Q`，返回值的只读引用。若索引不存在，则会引发运行时异常并导致交易回滚。

</p>
<li>

```rust
impl<'a, K, Q, V> core::ops::IndexMut<&'a Q> for Mapping<K, V>
where
    K: Borrow<Q>,
{
    fn index_mut(&mut self, index: &'a Q) -> &mut Self::Output;
}
```

</li>
<p>

以键为索引访问映射容器中对应的值，索引类型为`&Q`，返回值的可变引用。若索引不存在，则会引发运行时异常并导致交易回滚。

</p>
</ul>

```eval_rst
.. admonition:: 注意

   映射容器的容量大小并不能无限增长，其上限为2 \ :sup:`32` - 1（4294967295，约为42亿）。
```

```eval_rst
.. admonition:: 注意

   映射容器不支持迭代，如果需要迭代映射容器，请使用可迭代映射容器。
```

### 可迭代映射容器

可迭代映射容器的类型定义为`IterableMapping<K, V>`，其功能与映射容器基本类似，但是提供了迭代功能。使用可迭代映射容器时需要通过模板参数传入键和值的实际类型，如`IterableMapping<u8, bool>`、`IterableMapping<String, u32>`等。

可迭代映射容器支持迭代。在迭代时，需要先调用可迭代映射容器的`iter`方法生成迭代器，迭代器在迭代时会不断返回由键的引用及对应的值的引用组成的元组，可配合`for ... in ...`等语法完成对可迭代映射容器的迭代，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 10

   #[liquid(storage)]
   struct Sum {
       values: storage::IterableMapping<String, u32>,
   }

   ...

   pub fn sum(&self) -> u32 {
       let mut ret = 0u32;
       for (_, v) in self.values.iter() {
           ret += v;
       }
       ret
   }
```

此外，可迭代映射容器的`insert`方法与映射容器略有不同，其描述如下：

<ul class="method-introduction">
<li>

```rust
pub fn insert(&mut self, key: K, val: V) -> Option<V>
```

</li>
<p>

其功能与映射容器的`insert`方法相同，但是其参数并不`K`类型的引用。

</p>
</ul>

```eval_rst
.. admonition:: 注意

   可迭代映射容器的容量大小并不能无限增长，其上限为2 \ :sup:`32` - 1（4294967295，约为42亿）。
```

```eval_rst
.. admonition:: 注意

   为实现迭代功能，可迭代映射容器在内部存储了所有的键，且受限于区块链特性，这些键不会被删除。因此，可迭代容器的性能及存储开销较大，请根据应用需求谨慎选择使用。
```
