# 状态变量与容器

状态变量用于在区块链存储上永久存储状态值，是Liquid合约重要的组成部分。在[HelloWorld合约](../quick_start/introduction.html#hello-world)中，我们已经初步了解了状态变量的定义方式及容器的使用方式，事实上在Liquid合约中，状态变量与容器的关系极为密切，我们将在本节中分别对两者进行介绍。

## 状态变量

Liquid中使用结构体语法对状态变量定义进行封装，以`struct`关键字表示。为向Liquid表明该此结构体中包含了状态变量的定义，您需要为此结构体添加`liquid(storage)`属性：

```rust
#[liquid(storage)]
struct HelloWorld {
    name: storage::Value<String>,   // 状态变量
    ...
}
```

在上述代码中我们可以看出，合约的每个状态变量都是结构体中的一个成员，其中状态变量的名称位于英语冒号`:`的左侧，而其类型位于右侧，状态变量之间使用英语逗号`,`分隔。虽然在合约的设计上，状态变量`name`的实际类型为`String`，但是我们仍然需要状态变量的实际类型包裹于容器`storage::Value`中。究其原因，是由于状态变量实际上映射了区块链存储上的某一位置，因此我们对状态变量的读取、写入都需要转化为对区块链存储上的读取写入，这也是状态变量区别于代码中其他普通变量的重要差异。而Liquid中的容器替我们封装了这些细节，从而能够是我们能够像使用普通变量那样使用状态变量。可以认为，容器是连接智能合约与区块链平台桥梁。

正是由于容器对于状态变量至关重要，因此若您忘记使用容器封装状态变量实际类型，Liquid将会拒绝编译合约。为了使用容器，您需要在定义状态变量之前先引入`liquid_core`模块中的`storage`模块：

```rust
use liquid_core::storage;
```

在Liquid中，定义状态变量的结构体定义需要满足以下限制：

- 用于定义状态变量的结构体在Liquid合约中能且仅能出现一次，因此您不能将状态变量的定义分散在不同的、用`#[liquid(storage)]`属性标记的结构体中。
- 您的合约中至少需要有一个状态变量的定义，因此您不能将定义状态变量的结构体定义为[unit类型](https://doc.rust-lang.org/std/primitive.unit.html):

    ```rust
    // Forbidden!
    #[liquid(storage)]
    struct HelloWorld();
    ```

- 每个状态变量都需要一个有效的名字，因此您不能将定义状态变量的结构体定义为[元组类型](https://doc.rust-lang.org/stable/rust-by-example/primitives/tuples.html)：

    ```rust
    // Forbidden!
    #[liquid(storage)]
    struct HelloWorld(u8, u32);
    ```

- 不能为定义状态变量的结构体声明模板参数，即您不能在该结构体中使用泛型。

- 您不能为`#[liquid(storage)]`属性标记的结构体添加任何可见性声明，但是您可以在状态变量的定义之前添加一个`pub`可见性声明：

    ```rust
    #[liquid(storage)]
    struct HelloWorld {
        pub name: storage::Value<String>,   // 我们为`name`状态变量添加了`pub`可见性
        ...
    }
    ```

    `pub`可见性意为外界可以访问该状态变量，Liquid会自动为此类状态变量生成一个访问器。关于访问器的更多细节可参考[合约方法](./method.html)一节。但是除了`pub`可见性，您不能为状态变量声明其他类型的可见性。

- 能够用作状态变量数据类型是受限的，具体可参考[类型](./types.html)一节。

## 容器

Liquid中所有可用容器的定义均位于`liquid_core::storage`模块中，主要包括基本容器（`Value`）、序列容器（`Vec`）、映射容器（`Mapping`）即可迭代映射容器（`IterableMapping`)。

```eval_rst
.. admonition:: 注意

   Liquid中所有容器均没有实现拷贝语义，因此您无法拷贝容器。同时，Liquid限制了您不能移动容器，因此在合约中，您只能通过引用的方式使用容器。
```

### 基本容器

基本容器的类型定义为`Value<T>`。当状态变量类型定义为基本容器时，可以像使用普通变量一般使用该状态变量。使用基本容器时需要通过模板参数传入状态变量的实际类型，如`Value<bool>`、`Value<String>`等。基本容器提供的接口如下：

- `initialize`

  签名：`initialize(&mut self, input: T)`

  功能：用于在构造函数中使用提供的初始值初始化基本容器。您应当只在构造函数中使用该接口，且仅使用一次。若状态变量初始化后再调用`initialize`接口，则不会产生任何效果。

- `set`

  签名：`set(&mut self, new_val: T)`

  功能：用一个新的值更新状态变量的值。

- `mutate_with`

  签名：`mutate_with<F>(&mut self, f: F) -> &T where F: FnOnce(&mut T)`

  功能：允许用户传入一个用于修改状态变量的函数，在修改完状态变量后，返回状态变量的引用。当状态变量未初始化时，调用`mutate_with`会导致交易异常。
- `get`

  签名：`get(&self) -> &T`

  功能：返回状态变量的只读引用。

- `get_mut`

  签名：`get_mut(&mut self) -> &mut T`

  功能：返回状态变量的可变引用，后续您可以通过该可变引用直接修改状态变量的值。

除了上述基本接口外，基本容器还实现了大量的运算符重载（通过实现`core::ops`中的运算符trait实现），从而让您更加方便地使用基本容器，这些运算符包括：

|运算符|trait|功能|备注|
|:---|:--|:--|:--|
|*|Deref|解引用|通过容器的只读引用返回`&T`，借助Rust语言的[解引用强制多态](https://doc.rust-lang.org/reference/type-coercions.html)特性，您可以像操作普通变量那样操作基本容器。例如：若状态变量`name`的类型为`Value<String>`，为获取`name`的长度，您可以直接使用`name.len()`，而无需使用`name.get().len()`|
|*|DerefMut|解引用|通过容器的可变引用返回`&mut T`|
|+|Add|加|需要`T`自身支持`+`运算，例如：若状态变量`len`的类型为`Value<u8>`，则可以在合约代码中直接使用`len + 1`，而无需使用`len.get() + 1`|
|+=|AddAssign|加且赋值|需要`T`自身支持`+=`运算|
|-|Sub|减|需要`T`自身支持双目`-`运算|
|-=|SubAssign|减且赋值|需要`T`自身支持`-=`运算|
|*|Mul|乘|需要`T`自身支持`*`运算|
|*=|MulAssign|乘且赋值|需要`T`自身支持`*=`运算|
|/|Div|除|需要`T`自身支持`/`运算|
|/=|DivAssign|除且赋值|需要`T`自身支持`/=`运算|
|%|Rem|求模|需要`T`自身支持`%`运算|
|%=|RemAssign|求模且赋值|需要`T`自身支持`%=`运算|
|&|BitAnd|按位与|需要`T`自身支持`&`运算|
|&=|BitAndAssign|按位与且赋值|需要`T`自身支持`&=`运算|
|\||BitOr|按位或|需要`T`自身支持`|`运算|
|\|=|BitOrAssign|按位或且赋值|需要`T`自身支持`|=`运算|
|^|BitXor|按位异或|需要`T`自身支持`^`运算|
|^=|BitXorAssign|按位异或且赋值|需要`T`自身支持`^=`运算|
|<<|Shl|左移|需要`T`自身支持`<<`运算|
|<<=|ShlAssign|左移且赋值|需要`T`自身支持`<<=`运算|
|>>|Shr|右移|需要`T`自身支持`>>`运算|
|>>=|ShrAssign|右移且赋值|需要`T`自身支持`>>=`运算|
|-|Neg|取负|需要`T`自身支持单目`-`运算|
|!|Not|取反|需要`T`自身支持`!`运算|
|[]|Index|下标运算|需要`T`自身支持按下标进行索引|
|[]|IndexMut|同上，但是用于可变引用上下文中|同上，但是用于可变引用上下文中|
|==、>、>=、<、<=|PartialEq、PartialOrd、Ord|比较运算|需要`T`自身支持相应的比较运算|

### 序列容器

序列容器的类型定义为`Vec<T>`。当状态变量类型定义为序列容器时，可以像使用动态数组一般的方式使用该状态变量。在序列容器中，所有元素按照严格的线性顺序排序，以通过元素在序列中的位置访问对应的元素。使用序列容器时需要通过模板参数传入元素的实际类型，如`Vec<bool>`、`Vec<String>`等。序列容器提供的接口如下：

- `initialize`

  签名：`initialize(&mut self)`

  功能：用于在构造函数中初始化序列容器。您应当只在构造函数中使用该接口，且仅使用一次。若序列容器初始化后再调用`initialize`接口，则不会产生任何效果。

- `len`

  签名：`len(&self) -> u32`

  功能：返回序列容器中元素的个数。

- `is_empty`

  签名：`is_empty(&self) -> bool`

  功能：检查序列容器是否为空。

- `get`

  签名：`get(&self, n: u32) -> Option<&T>`
  
  功能：返回序列容器中第`n`个元素的只读引用。若`n`越界，则返回`None`。

- `get_mut`

  签名：`get_mut(&mut self, n: u32) -> Option<&mut T>`
  
  功能：返回序列容器中第`n`个元素的可变引用。若`n`越界，则返回`None`。

- `mutate_with`

  签名：`mutate_with<F>(&mut self, n: u32, f: F) -> Option<&T>`

  功能：允许用户传入一个用于修改序列容器中第`n`个元素的值的函数，在修改完毕后，返回该元素的只读引用。若`n`越界，则返回`None`。

- `push`

  签名：`push(&mut self, val: T)`

  功能：向序列容器的尾部插入一个新元素。当插入前序列容器的长度等于2<sup>32</sup> - 1时，引发panic。

- `pop`

  签名：`pop(&mut self) -> Option<T>`

  功能：移除序列容器的最后一个元素并将其返回。若序列容器为空，则返回`None`。

- `swap`

  签名：`swap(&mut self, a: u32, b: u32)`

  功能：交换序列容器中第`a`个及第`b`个元素。若`a`或`b`越界，则引发panic。

- `swap_remove`

  签名：`swap_remove(&mut self, n: u32) -> Option<T>`

  功能：从序列容器中移除第`n`个元素，并将最后一个元素移动至第`n`个元素所在的位置，随后返回被移除元素的引用。若`n`越界，则返回`None`；若第`n`个元素就是序列容器中的最后一个元素，则效果等同于`pop`接口。

- `extend`

  签名：`extend<I>(&mut self, iter: I)`，其中`iter`为元素类型为`T`或`&T`的迭代器

  功能：按顺序遍历迭代器，并将迭代器所访问的元素依次插入到序列容器的尾部。

序列容器支持迭代。在迭代时，需要先调用序列容器的`iter`接口生成迭代器，并配合`for ... in ...`等语法完成对序列容器的迭代，如下列代码所示：

```rust
// 假设我们有一个名为elems的序列容器，且元素类型为u32。
// 我们对elems中所有的元素值进行求和，此处我们暂时不考虑算术溢出的问题。
let sum = 0u32;
for elem in elems.iter() {
    sum += elem;
}
```

```eval_rst
.. admonition:: 注意

   序列容器支持使用下标对序列中的任意元素进行快速直接访问，下标的类型为`u32`。但是若您的提供的下标越界，则会导致您的合约直接panic，因此，若您不确定下标是否越界，则请使用序列容器提供的`get`或`get_mut`接口访问相应的元素。
```

```eval_rst
.. admonition:: 注意

   序列容器的长度并不能无限增长，其上限为2^32 - 1（4294967295，约为42亿）。
```

### 映射容器

映射容器的类型定义为`Mapping<K, V>`。映射容器是键值对集合，当状态变量类型为映射容器时，能够通过键来获取一个值。使用映射容器时需要通过模板参数传入键和值的实际类型，如`Mapping<u8, bool>`、`Mapping<String, u32>`等。映射提供的接口如下：

- `initialize`

  签名：`initialize(&mut self)`

  功能：用于在构造函数中初始化映射容器。您应当只在构造函数中使用该接口，且仅使用一次。若映射容器初始化后再调用`initialize`接口，则不会产生任何效果。

  - `len`

  签名：`len(&self) -> u32`

  功能：返回映射容器中键值对的个数。

- `is_empty`

  签名：`is_empty(&self) -> bool`

  功能：检查映射容器是否为空。

- `insert`

  签名：`insert<Q>(&mut self, key: &Q, val: V) -> Option<V>`

  功能：向映射容器中插入一个由`key`、`val`组成的键值对，注意`key`的类型为一个引用。当`key`在之前的映射容器中不存在时，返回`None`；否则返回之前的`key`所对应的值。

- `mutate_with`

  签名：`mutate_with<Q, F>(&mut self, key: &Q, f: F) -> Option<&V>`

  功能：允许用户传入一个用于修改映射容器中`key`所对应的值的函数，在修改完毕后，返回值的只读引用。若`key`在映射容器中不存在，则返回`None`。

- `remove`

  签名：`remove<Q>(&mut self, key: &Q) -> Option<V>`

  功能：从映射容器中移除`key`及对应的值，并返回被移除的值。若`key`在映射容器中不存在，则返回`None`。

- `get`

  签名：`get<Q>(&self, key: &Q) -> Option<&V>`

  功能：返回映射容器中`key`所对应的值的只读引用。若`key`在映射容器中不存在，则返回`None`。

- `get_mut`

  签名：`get_mut<Q>(&mut self, key: &Q) -> Option<&mut V>`

  功能：返回映射容器中`key`所对应的值的可变引用。若`key`在映射容器中不存在，则返回`None`。

- `contains_key`

  签名：`contains_key<Q>(&self, key: &Q) -> bool`

  功能：检查`key`在映射容器中是否存在。

- `extend`

  签名：`extend<I>(&mut self, iter: I)`，其中`iter`为元素类型为`(K, V)`或`(&K, &V)`的迭代器

  功能：按顺序遍历迭代器，并将迭代器所访问的元素拆解为键、值并插入到映射容器中。

```eval_rst
.. admonition:: 注意

   映射容器支持使用下标对容器中的值进行访问，下标的类型为任意可以转换至`&K`的类型。但是若您的提供的键在映射容器中不存在，则会导致您的合约直接panic，因此，若您不确定键是否在映射容器中存在，则请使用映射容器提供的`get`或`get_mut`接口访问相应的值。
```

```eval_rst
.. admonition:: 注意

   映射容器中键值对的个数并不能无限增长，其上限为2^32 - 1（4294967295，约为42亿）。
```

```eval_rst
.. admonition:: 注意

   映射容器不支持迭代，如果需要迭代映射容器，请使用可迭代映射容器。
```

### 可迭代映射容器

可迭代映射容器的类型定义为`IterableMapping<K, V>`，其功能与映射容器基本类似，但是提供了迭代功能。使用可迭代映射容器时需要通过模板参数传入键和值的实际类型，如`IterableMapping<u8, bool>`、`IterableMapping<String, u32>`等。

可迭代映射容器支持迭代。在迭代时，需要先调用可迭代映射容器的`iter`接口生成迭代器，迭代器在迭代时会不断返回由键的引用及对应的值的引用组成的元组，可配合`for ... in ...`等语法完成对可迭代映射容器的迭代，如下列代码所示：

```rust
// 假设我们有一个名为elems的可迭代映射容器，其键类型为String，值类型为u32。
// 我们对elems中所有的值进行求和，此处我们暂时不考虑算术溢出的问题。
let sum = 0u32;
for (_k, elem) in elems.iter() {
    sum += elem;
}
```

此外，可迭代映射容器的`insert`接口与映射容器略有不同，其签名为`insert(&mut self, key: K, val: V) -> Option<V>`，注意`key`的类型与映射容器不同，是拥有所有权的值，而不是引用。

```eval_rst
.. admonition:: 注意

   为实现迭代功能，可迭代映射容器在内部存储了所有的键，且受限于区块链特性，这些键不会被删除。因此，可迭代容器的性能及存储开销较大，请根据应用需求谨慎选择使用。
```
