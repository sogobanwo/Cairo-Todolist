use starknet::ContractAddress;

#[starknet::interface]
trait ITodoList<TContractState> {
    fn addTodo(ref self: TContractState, description: felt252, deadline: u32) -> bool;
    fn updateTodo(ref self: TContractState, index: u8, description: felt252, deadline: u32) -> bool;
    fn getTodos(self: @TContractState) -> Array<Todo::Todo>;
    fn getTodo(self: @TContractState, index: u8) -> Todo::Todo;
}

#[starknet::contract]
mod Todo {
    use starknet::{ContractAddress, get_caller_address};
    use array::ArrayTrait;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        todolist: LegacyMap::<u8, Todo>,
        todoId: u8
    }

    #[derive(Drop, Serde, starknet::Store)]
    struct Todo {
        id: u8,
        description: felt252,
        deadline: u32
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner)
    }

    #[abi(embed_v0)]
    impl Todolist of super::ITodoList<ContractState> {
        fn addTodo(ref self: ContractState, description: felt252, deadline: u32) -> bool {
            self._addTodo(description, deadline);
            true
        }

        fn getTodos(self: @ContractState) -> Array<Todo> {
            let mut todos = ArrayTrait::new();
            let count = self.todoId.read();
            let mut index: u8 = 1;

            while index < count
                + 1 {
                    let readTodo = self.todolist.read(index);
                    todos.append(readTodo);
                    index += 1;
                };

            todos
        }

        fn getTodo(self: @ContractState, index: u8) -> Todo {
            self.todolist.read(index)
        }

        fn updateTodo(
            ref self: ContractState, index: u8, description: felt252, deadline: u32
        ) -> bool {
            self
                .todolist
                .write(index, Todo { id: index, description: description, deadline: deadline });
            true
        }
    }


    #[generate_trait]
    impl PrivateImpl of PrivateImplTrait {
        fn _addTodo(ref self: ContractState, description: felt252, deadline: u32) {
            let id = self.todoId.read();
            let currentId = id + 1;
            let todo = Todo { id: currentId, description: description, deadline: deadline };
            self.todolist.write(currentId, todo);
            self.todoId.write(currentId)
        }
    }
}
