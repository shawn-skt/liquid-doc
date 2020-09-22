# 更复杂的合约示例

本节展示的合约示例较为复杂，但能够展示Liquid提供的大部分特性。

## 投票合约

> 本节所展示的投票合约来自于[Solidity by Example](https://solidity.readthedocs.io/en/latest/solidity-by-example.html#voting)。

传统电子投票的主要问题是如何将投票权分配给正确的参与者以及如何防止投票过程被操纵。我们不会在这个示例中试图解决所有，但我们至少会展示如何使用智能合约进行委托投票，同时保证计票是完全自动和透明的。

投票合约的思路是：每发起一个新的投票，都在区块链上部署一份投票合约，部署时可以指定本次投票中能够为哪些提案投票。合约的部署者自动成为本次投票的主席，主席能够为每个独立的账户地址分配投票权。当投票结束时，调用投票合约的`winning_propoal`方法即可返回投票最多的提案。

```rust
#![cfg_attr(not(feature = "std"), no_std)]

use liquid_lang as liquid;

/// 投票合约主体
#[liquid::contract(version = "0.1.0")]
mod ballot {
    // 导入`InOut`及`State`宏，用于稍后在
    // 合约方法参数、返回值及合约状态变量的
    // 类型声明中使用自定义结构体
    use liquid_lang::{InOut, State};

    /// 这里声明了一个新的结构体类型，用于
    /// 表示一个投票人。注意它同时derive了
    /// `State`及`InOut`，表示这个类型既可
    /// 以用于定义状态变量，也可以用于方法参数
    /// 及返回值中。
    #[derive(State, InOut, Clone)]
    #[cfg_attr(feature = "std", derive(Debug, PartialEq, Eq))]
    pub struct Voter {
        /// 投票人的计票权重
        weight: u32,
        /// 如果为真，则表示该投票人已经投过票
        voted: bool,
        /// 投票权的委托对象
        delegate: Address,
        /// 该投票人参与投票的提案的索引
        vote: u32,
    }

    /// 这里声明了一个新的结构体类型，用于
    /// 表示一个提案。
    #[derive(State, InOut, Clone)]
    #[cfg_attr(feature = "std", derive(Debug, PartialEq, Eq))]
    pub struct Proposal {
        /// 提案的名称
        name: String,
        /// 该提案获得的投票总数
        vote_count: u32,
    }

    use liquid_core::storage;

    /// 这里定义了投票合约要使用到的状态变量
    #[liquid(storage)]
    struct Ballot {
        /// 本次投票中的主席
        pub chairperson: storage::Value<Address>,
        /// `voters`将参与投票的链上账户地址映射为一个投票人
        pub voters: storage::Mapping<Address, Voter>,
        /// `proposals`中存储了所有的提案
        pub proposals: storage::Vec<Proposal>,
    }

    /// 这里定义了投票合约中所有的合约方法
    #[liquid(methods)]
    impl Ballot {
        /// 构造函数，其参数是一个包含所有提案名称的动态数组
        pub fn new(&mut self, proposal_names: Vec<String>) {
            // 获取合约部署者的账户地址
            let chairperson = self.env().get_caller();
            // 将合约部署者指定为投票主席
            self.chairperson.initialize(chairperson);

            // 初始化状态变量`voters`
            self.voters.initialize();
            // 为投票主席分配投票权
            self.voters.insert(
                &chairperson,
                Voter {
                    weight: 1,
                    voted: false,
                    delegate: Address::empty(),
                    vote: 0,
                },
            );

            // 初始化状态变量`proposals`
            self.proposals.initialize();
            // 为每一个提案名创建一个新的提案，并添加至
            // `proposals`尾部
            for name in proposal_names {
                // `Proposal{...}` 创建了一个临时的`Proposal`对象
                self.proposals.push(Proposal {
                    name,
                    vote_count: 0,
                });
            }
        }

        /// 授予 `voter`在本次投票中的投票权，本方法仅限
        /// 投票主席调用
        pub fn give_right_to_vote(&mut self, voter: Address) {
            // 若`require`函数的第一个参数的计算结果为`false`，
            // 则交易终止执行，并通过第二个参数向用户提供一个
            // 错误解释。使用`require`进行断言是一个保证方法
            // 被正确使用的好习惯。
            require(
                self.env().get_caller() == *self.chairperson,
                "Only chairperson can give right to vote.",
            );

            if let Some(voter) = self.voters.get_mut(&voter) {
                require(!voter.voted, "The voter already voted.");
                require(voter.weight == 0, "The weight of voter is not zero.");
                voter.weight = 1;
            } else {
                self.voters.insert(
                    &voter,
                    Voter {
                        weight: 1,
                        voted: false,
                        delegate: Address::empty(),
                        vote: 0,
                    },
                );
            }
        }

        ///将您的投票权委托给`to`
        pub fn delegate(&mut self, mut to: Address) {
            // 不允许自我委托
            require(
                to != self.env().get_caller(),
                "Self-delegation is disallowed.",
            );
            // 不允许将投票权委托给一个不存在的投票人
            require(
                self.voters.contains_key(&to),
                "Can not delegate to an inexistent voter.",
            );

            let caller = &self.env().get_caller();
            let sender = &self.voters[caller];
            // 投票之后不允许再将投票权委托
            require(!sender.voted, "You already voted.");

            // 委托是可以传递的，只要被委托者 `to` 也设置了委托
            while self.voters[&to].delegate != Address::empty() {
                to = self.voters[&to].delegate;

                // 不允许委托关系中出现“环”，否则会让合约陷入无限循环中
                require(to != self.env().get_caller(), "Found loop in delegation.");
            }

            // 由于此处`sender`是一个可变引用, 因此修改`sender`将
            // 直接修改`self.voters`
            let sender = &mut self.voters[caller];
            sender.voted = true;
            sender.delegate = to;

            let weight = sender.weight;
            let delegate_ = &mut self.voters[&to];
            if delegate_.voted {
                // 如果被委托者已经投过票了，则直接增加其投票的提案的得票数
                self.proposals[delegate_.vote].vote_count += weight;
            } else {
                // 如果被委托者还没投票，则增加被委托者的权重
                delegate_.weight += weight;
            }
        }

        /// 为某个提案投出你的选票
        pub fn vote(&mut self, proposal: u32) {
            let caller = self.env().get_caller();
            let sender = &mut self.voters[&caller];
            require(sender.weight != 0, "Has no right to vote");
            require(!sender.voted, "Already voted.");
            sender.voted = true;
            sender.vote = proposal;

            // 如果`proposal`越界，会导致panic并引发交易回滚
            self.proposals[proposal].vote_count += sender.weight;
        }

        /// 根据最终的投票结果，计算出胜出的提案的索引
        pub fn winning_proposal(&self) -> u32 {
            let mut winning_vote_count = 0;
            let mut winning_proposal = 0;

            for p in 0..self.proposals.len() {
                if self.proposals[p].vote_count > winning_vote_count {
                    winning_vote_count = self.proposals[p].vote_count;
                    winning_proposal = p;
                }
            }

            winning_proposal
        }

        /// 调用`winningProposal()`方法获取获胜提案的索引，
        /// 然后返回获胜提案的名称
        pub fn winner_name(&self) -> String {
            self.proposals[self.winning_proposal()].name.clone()
        }
    }
}
```
